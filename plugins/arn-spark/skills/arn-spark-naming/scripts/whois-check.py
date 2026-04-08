#!/usr/bin/env python3
"""
Domain availability checker using RDAP (primary) with WHOIS fallback.
Reads JSON from stdin, outputs JSON to stdout.
Uses only Python stdlib (urllib, socket, json, sys, time, subprocess, shutil).

RDAP (Registration Data Access Protocol) is the IETF standard replacement
for port-43 WHOIS. It returns structured JSON over HTTPS, with 404 = available.
IANA bootstrap file provides RDAP servers for all TLDs — no hardcoded map needed.

Fallback chain per domain:
  1. RDAP via IANA bootstrap → structured JSON, 200=taken, 404=available
  2. Port-43 WHOIS via socket → pattern matching (same as whois-check.py)
  3. System `whois` command → pattern matching on stdout

Circuit breaker: stops ALL remaining queries on RATE LIMIT responses only.
DNS/connection errors are per-domain — they try the next fallback, not break the batch.

Input:  {"domains": ["example.com", ...], "delay_seconds": 2}
Output: [{"domain": "example.com", "tld": "com", "available": true, ...}, ...]

Exit code 0 = all queries completed. Exit code 1 = stopped early (rate limit).
Exit code 2 = invalid input.
"""

import json
import socket
import subprocess
import shutil
import ssl
import sys
import time
import urllib.error
import urllib.request

# ─── RDAP Bootstrap ──────────────────────────────────────────────────────────

IANA_BOOTSTRAP_URL = "https://data.iana.org/rdap/dns.json"

# Cache: populated once from IANA bootstrap, maps TLD → RDAP base URL
_rdap_servers = {}
_bootstrap_loaded = False


def load_rdap_bootstrap():
    """
    Fetch the IANA RDAP bootstrap file and build a TLD → RDAP server map.
    Called once at startup. Failures are non-fatal — we fall back to WHOIS.
    """
    global _rdap_servers, _bootstrap_loaded
    if _bootstrap_loaded:
        return

    try:
        log("Loading IANA RDAP bootstrap...")
        req = urllib.request.Request(IANA_BOOTSTRAP_URL)
        ctx = ssl.create_default_context()
        with urllib.request.urlopen(req, timeout=10, context=ctx) as resp:
            data = json.loads(resp.read())

        for service in data.get("services", []):
            tlds = service[0]  # list of TLD strings
            servers = service[1]  # list of RDAP base URLs
            if servers:
                base_url = servers[0].rstrip("/")
                for tld in tlds:
                    _rdap_servers[tld.lower()] = base_url

        log(f"  Loaded {len(_rdap_servers)} TLD RDAP servers from bootstrap")
        _bootstrap_loaded = True
    except Exception as e:
        log(f"  WARNING: RDAP bootstrap failed ({e}). Will use WHOIS fallback for all domains.")
        _bootstrap_loaded = True  # Don't retry


def get_rdap_server(tld):
    """Look up the RDAP base URL for a TLD from the bootstrap cache."""
    return _rdap_servers.get(tld.lower())


# ─── Port-43 WHOIS (fallback) ────────────────────────────────────────────────

WHOIS_SERVERS = {
    "com": "whois.verisign-grs.com",
    "net": "whois.verisign-grs.com",
    "org": "whois.pir.org",
    "io": "whois.nic.io",
    "co": "whois.registry.co",
    # .dev and .app are RDAP-only — no port-43 WHOIS server exists
    "ai": "whois.nic.ai",
    "me": "whois.nic.me",
    "xyz": "whois.nic.xyz",
    "tech": "whois.nic.tech",
    "so": "whois.nic.so",
    "sh": "whois.nic.sh",
    "to": "whois.tonic.to",
    "gg": "whois.gg",
    "ly": "whois.nic.ly",
    "is": "whois.isnic.is",
    "fm": "whois.nic.fm",
    "tv": "whois.nic.tv",
    "cc": "ccwhois.verisign-grs.com",
    "de": "whois.denic.de",
    "fr": "whois.nic.fr",
    "eu": "whois.eu",
    "us": "whois.nic.us",
    "ca": "whois.cira.ca",
    "uk": "whois.nic.uk",
    "co.uk": "whois.nic.uk",
    "org.uk": "whois.nic.uk",
    # EU market TLDs
    "it": "whois.nic.it",
    "es": "whois.nic.es",
    "nl": "whois.domain-registry.nl",
    "pt": "whois.dns.pt",
    "pl": "whois.dns.pl",
    "se": "whois.iis.se",
    "ch": "whois.nic.ch",
    "at": "whois.nic.at",
    "be": "whois.dns.be",
    # Asia-Pacific TLDs
    "jp": "whois.jprs.jp",
    "in": "whois.registry.in",
    "au": "whois.auda.org.au",
    "kr": "whois.kr",
    # Latin America TLDs
    "br": "whois.registro.br",
    "mx": "whois.mx",
    "ar": "whois.nic.ar",
    "cl": "whois.nic.cl",
    # Compound ccTLDs
    "com.br": "whois.registro.br",
    "com.au": "whois.auda.org.au",
    "co.jp": "whois.jprs.jp",
    "co.in": "whois.registry.in",
    "com.mx": "whois.mx",
    "com.ar": "whois.nic.ar",
    "co.kr": "whois.kr",
    "com.pt": "whois.dns.pt",
}

AVAILABLE_PATTERNS = [
    "no match for", "not found", "no entries found", "no data found",
    "domain not found", "no information available", "status: available",
    "the queried object does not exist", "no object found",
    "is available for", "domain name has not been registered",
    "status: free",
]

TAKEN_PATTERNS = [
    "domain name:", "registrar:", "creation date:", "registry expiry date:",
    "updated date:", "name server:", "registrant:", "status: ok",
    "status: active", "status: clienttransferprohibited",
    "nserver:", "status: connect", "registered on:", "expires on:",
]

RATE_LIMIT_PATTERNS = [
    "quota exceeded", "rate limit", "too many requests",
    "please try again later", "your request has been throttled",
    "connection limit reached", "access denied", "query rate exceeded",
]

NOT_SUPPORTED_PATTERNS = [
    "tld is not supported", "this tld has no whois server",
    "no whois server is known", "unknown tld",
]

QUERY_TIMEOUT = 10
DNS_TIMEOUT = 5


# ─── Shared Utilities ────────────────────────────────────────────────────────

def log(msg):
    print(msg, file=sys.stderr, flush=True)


def get_tld(domain):
    parts = domain.lower().split(".")
    if len(parts) < 2:
        return None
    if len(parts) >= 3:
        compound = parts[-2] + "." + parts[-1]
        if compound in WHOIS_SERVERS or compound in _rdap_servers:
            return compound
    return parts[-1]


def manual_check_url(domain):
    return f"https://www.whois.com/whois/{domain}"


class RateLimitError(Exception):
    pass


# ─── RDAP Query ──────────────────────────────────────────────────────────────

def rdap_query(domain, tld):
    """
    Query RDAP for a domain. Returns a result dict.
    Raises RateLimitError on 429. Returns None on failure (fall through to WHOIS).
    """
    base_url = get_rdap_server(tld)
    if not base_url:
        return None  # No RDAP server known — fall through

    url = f"{base_url}/domain/{domain}"

    try:
        req = urllib.request.Request(url, headers={
            "Accept": "application/rdap+json, application/json",
        })
        ctx = ssl.create_default_context()
        with urllib.request.urlopen(req, timeout=QUERY_TIMEOUT, context=ctx) as resp:
            data = json.loads(resp.read())

        # 200 = domain exists (taken)
        registrar = None
        entities = data.get("entities", [])
        for entity in entities:
            roles = entity.get("roles", [])
            if "registrar" in roles:
                vcard = entity.get("vcardArray", [])
                if len(vcard) >= 2:
                    for field in vcard[1]:
                        if field[0] == "fn":
                            registrar = field[3]
                            break
                if not registrar:
                    registrar = entity.get("handle", None)

        return {
            "domain": domain,
            "tld": tld,
            "available": False,
            "registrar": registrar,
            "method": "rdap",
            "error": None,
        }

    except urllib.error.HTTPError as e:
        if e.code == 404:
            # 404 = domain not found in registry = available
            return {
                "domain": domain,
                "tld": tld,
                "available": True,
                "registrar": None,
                "method": "rdap",
                "error": None,
            }
        if e.code == 429:
            raise RateLimitError(f"RDAP rate limit (429) from {base_url} for {domain}")
        # Other HTTP errors — fall through to WHOIS
        log(f"  RDAP HTTP {e.code} for {domain}, falling back to WHOIS...")
        return None

    except (urllib.error.URLError, socket.timeout, OSError) as e:
        # DNS or connection error — fall through to WHOIS
        log(f"  RDAP failed for {domain} ({e}), falling back to WHOIS...")
        return None


# ─── Port-43 WHOIS Query ─────────────────────────────────────────────────────

def whois_query(domain, server, port=43, timeout=QUERY_TIMEOUT):
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(timeout)
    try:
        sock.connect((server, port))
        sock.sendall((domain + "\r\n").encode("utf-8"))
        response = b""
        while True:
            chunk = sock.recv(4096)
            if not chunk:
                break
            response += chunk
        return response.decode("utf-8", errors="replace")
    finally:
        sock.close()


def parse_whois_availability(response, tld=None):
    if not response or not response.strip():
        return None

    lower = response.lower()

    for pattern in NOT_SUPPORTED_PATTERNS:
        if pattern in lower:
            return None

    for pattern in RATE_LIMIT_PATTERNS:
        if pattern in lower:
            return None

    available_matches = sum(1 for p in AVAILABLE_PATTERNS if p in lower)
    taken_matches = sum(1 for p in TAKEN_PATTERNS if p in lower)

    # Verisign fix: require no TAKEN patterns alongside AVAILABLE
    if tld in {"com", "net", "cc"}:
        if available_matches > 0 and taken_matches == 0:
            return True
        if taken_matches >= 1:
            return False
        return None

    if available_matches > 0 and taken_matches == 0:
        return True
    if taken_matches >= 2:
        return False
    if available_matches > 0 and taken_matches > 0:
        return False if taken_matches >= 2 else None
    if taken_matches >= 1:
        return False
    return None


def extract_registrar(response):
    for line in response.splitlines():
        stripped = line.strip()
        if stripped.lower().startswith("registrar:"):
            return stripped.split(":", 1)[1].strip()
    return None


def whois_port43_query(domain, tld):
    """
    Query port-43 WHOIS. Returns a result dict or None on failure.
    Raises RateLimitError on rate limit response.
    """
    server = WHOIS_SERVERS.get(tld)
    if not server:
        return None

    # Check DNS resolution first
    try:
        socket.setdefaulttimeout(DNS_TIMEOUT)
        socket.getaddrinfo(server, 43)
    except (socket.gaierror, socket.timeout, OSError):
        log(f"  WHOIS DNS failed for {server}, skipping port-43...")
        return None

    try:
        response = whois_query(domain, server)
    except (socket.timeout, ConnectionRefusedError, OSError):
        return None

    if not response or not response.strip():
        return None

    # Check rate limit — for port-43 WHOIS, rate limits are per-server,
    # so we return unknown instead of triggering the global circuit breaker.
    # Only RDAP 429 (which affects all queries from the same IP) triggers circuit break.
    lower = response.lower()
    for pattern in RATE_LIMIT_PATTERNS:
        if pattern in lower:
            log(f"  WHOIS rate limit from {server} for {domain} (per-server, not circuit-breaking)")
            return {
                "domain": domain, "tld": tld, "available": None,
                "registrar": None, "method": "whois",
                "error": f"Rate limited by {server}",
            }

    available = parse_whois_availability(response, tld)
    registrar = extract_registrar(response) if not available else None

    return {
        "domain": domain,
        "tld": tld,
        "available": available,
        "registrar": registrar,
        "method": "whois",
        "error": None,
    }


# ─── System WHOIS Fallback ───────────────────────────────────────────────────

def system_whois_query(domain, tld):
    """Last resort: system `whois` command."""
    whois_cmd = shutil.which("whois")
    if not whois_cmd:
        return None

    try:
        result = subprocess.run(
            [whois_cmd, domain],
            capture_output=True, text=True, timeout=15,
        )
        response = result.stdout
        if not response or not response.strip():
            return None

        available = parse_whois_availability(response, tld)
        registrar = extract_registrar(response) if not available else None

        return {
            "domain": domain,
            "tld": tld,
            "available": available,
            "registrar": registrar,
            "method": "system-whois",
            "error": None,
        }
    except (subprocess.TimeoutExpired, FileNotFoundError, OSError):
        return None


# ─── Main Check (cascading fallback) ─────────────────────────────────────────

def check_domain(domain):
    """
    Check a single domain using the fallback chain: RDAP → WHOIS → system whois.
    Returns a result dict. Raises RateLimitError on rate limit (circuit breaker).
    """
    tld = get_tld(domain)
    if not tld:
        return {
            "domain": domain, "tld": None, "available": None,
            "registrar": None, "method": "none",
            "error": "Could not extract TLD from domain",
        }

    # 1. Try RDAP (primary)
    log(f"Checking {domain}...")
    result = rdap_query(domain, tld)
    if result is not None:
        status = "available" if result["available"] else ("taken" if result["available"] is False else "unknown")
        log(f"  {domain}: {status} (via RDAP)")
        return result

    # 2. Try port-43 WHOIS (fallback)
    result = whois_port43_query(domain, tld)
    if result is not None:
        status = "available" if result["available"] else ("taken" if result["available"] is False else "unknown")
        log(f"  {domain}: {status} (via WHOIS)")
        return result

    # 3. Try system whois (last resort)
    result = system_whois_query(domain, tld)
    if result is not None:
        status = "available" if result["available"] else ("taken" if result["available"] is False else "unknown")
        log(f"  {domain}: {status} (via system whois)")
        return result

    # All methods failed
    log(f"  {domain}: UNKNOWN (all methods failed)")
    return {
        "domain": domain, "tld": tld, "available": None,
        "registrar": None, "method": "none",
        "error": "All lookup methods failed (RDAP, WHOIS port-43, system whois)",
    }


# ─── Entry Point ─────────────────────────────────────────────────────────────

def main():
    try:
        raw = sys.stdin.read()
        config = json.loads(raw)
    except (json.JSONDecodeError, ValueError) as e:
        log(f"ERROR: Invalid JSON input: {e}")
        sys.exit(2)

    domains = config.get("domains", [])
    delay_seconds = config.get("delay_seconds", 2)

    if not domains:
        log("No domains provided")
        json.dump([], sys.stdout, indent=2)
        sys.exit(0)

    if delay_seconds < 1:
        delay_seconds = 1

    # Load RDAP bootstrap
    load_rdap_bootstrap()

    log(f"Checking {len(domains)} domain(s) with {delay_seconds}s delay...")
    log(f"RDAP servers loaded: {len(_rdap_servers)} TLDs")
    log(f"System whois available: {shutil.which('whois') is not None}")

    results = []
    circuit_broken = False

    for i, domain in enumerate(domains):
        domain = domain.strip().lower()
        if not domain:
            continue

        try:
            result = check_domain(domain)
            if result.get("available") is None and result.get("error"):
                result["manual_url"] = manual_check_url(domain)
            results.append(result)
        except RateLimitError as e:
            log(f"  CIRCUIT BREAKER (rate limit): {e}")
            log(f"  Stopping. {len(domains) - i - 1} domain(s) not checked.")
            results.append({
                "domain": domain, "tld": get_tld(domain), "available": None,
                "registrar": None, "method": "none",
                "error": str(e), "manual_url": manual_check_url(domain),
            })
            circuit_broken = True
            break

        if i < len(domains) - 1:
            time.sleep(delay_seconds)

    json.dump(results, sys.stdout, indent=2)
    print()

    # Summary stats
    available = sum(1 for r in results if r["available"] is True)
    taken = sum(1 for r in results if r["available"] is False)
    unknown = sum(1 for r in results if r["available"] is None)
    methods = {}
    for r in results:
        m = r.get("method", "none")
        methods[m] = methods.get(m, 0) + 1

    log(f"\nResults: {len(results)} checked — {available} available, {taken} taken, {unknown} unknown")
    log(f"Methods: {', '.join(f'{m}={c}' for m, c in sorted(methods.items()))}")

    if circuit_broken:
        sys.exit(1)
    sys.exit(0)


if __name__ == "__main__":
    main()
