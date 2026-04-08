# WHOIS & RDAP Server Map

The scripts use **RDAP as the primary lookup method** with port-43 WHOIS as a fallback. RDAP servers are discovered dynamically via the IANA bootstrap file (`https://data.iana.org/rdap/dns.json`) which covers 1,198+ TLDs. The WHOIS server map below is used only as a fallback when RDAP is unavailable for a TLD.

Since January 2025 (ICANN sunset), 374+ gTLDs have dropped port-43 WHOIS entirely. TLDs like `.dev`, `.app`, and `.land` are RDAP-only.

## TLD to WHOIS Server (Fallback)

| TLD | WHOIS Server | Port | Notes |
|-----|-------------|------|-------|
| `.com` | `whois.verisign-grs.com` | 43 | Also handles `.net` |
| `.net` | `whois.verisign-grs.com` | 43 | Same server as `.com` |
| `.org` | `whois.pir.org` | 43 | Public Interest Registry |
| `.io` | `whois.nic.io` | 43 | Popular for tech products |
| `.co` | `whois.registry.co` | 43 | Colombia ccTLD, used as generic. Note: `whois.nic.co` is NXDOMAIN — use `whois.registry.co` |
| `.dev` | — | — | **RDAP-only** (`pubapi.registry.google/rdap/`). No port-43 WHOIS server exists |
| `.app` | — | — | **RDAP-only** (`pubapi.registry.google/rdap/`). No port-43 WHOIS server exists |
| `.ai` | `whois.nic.ai` | 43 | Anguilla ccTLD, popular for AI products |
| `.me` | `whois.nic.me` | 43 | Montenegro ccTLD, used for personal brands |
| `.xyz` | `whois.nic.xyz` | 43 | Generic TLD |
| `.tech` | `whois.nic.tech` | 43 | Tech-focused TLD |
| `.so` | `whois.nic.so` | 43 | Somalia ccTLD |
| `.sh` | `whois.nic.sh` | 43 | Saint Helena ccTLD |
| `.to` | `whois.tonic.to` | 43 | Tonga ccTLD |
| `.gg` | `whois.gg` | 43 | Guernsey ccTLD |
| `.ly` | `whois.nic.ly` | 43 | Libya ccTLD, used for -ly names |
| `.is` | `whois.isnic.is` | 43 | Iceland ccTLD |
| `.fm` | `whois.nic.fm` | 43 | Micronesia ccTLD |
| `.tv` | `whois.nic.tv` | 43 | Tuvalu ccTLD, media use |
| `.cc` | `ccwhois.verisign-grs.com` | 43 | Cocos Islands ccTLD |

### Country-Code TLDs (Single-Part)

| TLD | WHOIS Server | Port | Notes |
|-----|-------------|------|-------|
| `.de` | `whois.denic.de` | 43 | Germany |
| `.fr` | `whois.nic.fr` | 43 | France |
| `.it` | `whois.nic.it` | 43 | Italy |
| `.es` | `whois.nic.es` | 43 | Spain |
| `.nl` | `whois.sidn.nl` | 43 | Netherlands |
| `.eu` | `whois.eu` | 43 | European Union |
| `.us` | `whois.nic.us` | 43 | United States |
| `.ca` | `whois.cira.ca` | 43 | Canada |
| `.br` | `whois.registro.br` | 43 | Brazil |
| `.jp` | `whois.jprs.jp` | 43 | Japan |
| `.in` | `whois.registry.in` | 43 | India |
| `.au` | `whois.auda.org.au` | 43 | Australia |
| `.pt` | `whois.dns.pt` | 43 | Portugal |
| `.pl` | `whois.dns.pl` | 43 | Poland |
| `.se` | `whois.iis.se` | 43 | Sweden |
| `.ch` | `whois.nic.ch` | 43 | Switzerland |
| `.at` | `whois.nic.at` | 43 | Austria |
| `.be` | `whois.dns.be` | 43 | Belgium |
| `.mx` | `whois.mx` | 43 | Mexico |
| `.ar` | `whois.nic.ar` | 43 | Argentina |
| `.cl` | `whois.nic.cl` | 43 | Chile |
| `.kr` | `whois.kr` | 43 | South Korea |

### Compound Country-Code TLDs

These have two-part TLD structures. The scripts check compound TLDs before single-part to ensure correct server routing (e.g., `example.com.br` → `com.br`, not `br`).

| TLD | WHOIS Server | Port | Notes |
|-----|-------------|------|-------|
| `.co.uk` | `whois.nic.uk` | 43 | United Kingdom |
| `.org.uk` | `whois.nic.uk` | 43 | United Kingdom |
| `.com.br` | `whois.registro.br` | 43 | Brazil |
| `.com.au` | `whois.auda.org.au` | 43 | Australia |
| `.co.jp` | `whois.jprs.jp` | 43 | Japan |
| `.co.in` | `whois.registry.in` | 43 | India |
| `.com.mx` | `whois.mx` | 43 | Mexico |
| `.com.ar` | `whois.nic.ar` | 43 | Argentina |
| `.co.kr` | `whois.kr` | 43 | South Korea |
| `.com.pt` | `whois.dns.pt` | 43 | Portugal |

## Target Market to Suggested TLDs

| Target Market | TLDs to Check |
|--------------|---------------|
| United States | `.com`, `.io`, `.co`, `.dev`, `.app`, `.ai`, `.us` |
| European Union | `.com`, `.io`, `.eu`, `.de`, `.fr`, `.it`, `.es`, `.nl` |
| United Kingdom | `.com`, `.io`, `.co.uk`, `.org.uk` |
| Brazil | `.com`, `.com.br` |
| Australia | `.com`, `.com.au`, `.io` |
| Canada | `.com`, `.ca`, `.io` |
| Japan | `.com`, `.jp`, `.co.jp` |
| India | `.com`, `.in`, `.co.in` |
| Global / Multiple | `.com`, `.io`, `.co`, `.dev`, `.app`, `.ai` + relevant local TLDs |

## RDAP (Primary Method)

RDAP (Registration Data Access Protocol) is the IETF standard replacement for port-43 WHOIS. It uses HTTPS and returns structured JSON:
- **HTTP 200** = domain is registered (taken). Response includes registrar, status, dates.
- **HTTP 404** = domain not found in registry (available).
- **HTTP 429** = rate limited (circuit breaker trigger).

The IANA bootstrap file at `https://data.iana.org/rdap/dns.json` maps 1,198+ TLDs to their RDAP endpoints. Scripts load this once at startup — no hardcoded RDAP map needed.

## Fallback for Unknown TLDs

For RDAP: the IANA bootstrap covers most TLDs. If a TLD is not in the bootstrap, the scripts fall through to port-43 WHOIS.

For port-43 WHOIS: query `whois.iana.org` with the TLD (e.g., send `example\r\n`). The response includes the authoritative WHOIS server under the "whois:" field. Some TLDs return an empty "whois:" field — these are RDAP-only.

## Availability Indicator Patterns

### Patterns Indicating AVAILABLE (domain not registered)

```
No match for
NOT FOUND
No entries found
No Data Found
Domain not found
No information available
Status: AVAILABLE
The queried object does not exist
No Object Found
DOMAIN NOT FOUND
is available for
```

### Patterns Indicating TAKEN (domain registered)

```
Domain Name:
Registrar:
Creation Date:
Registry Expiry Date:
Updated Date:
Name Server:
Registrant:
Status: ok
Status: clientTransferProhibited
```

### Ambiguous / Rate Limit Patterns

```
quota exceeded
rate limit
too many requests
Please try again later
Your request has been throttled
Connection limit reached
Access denied
```

When an ambiguous or rate limit response is received, the domain status should be reported as `null` (unknown) and the circuit breaker should activate.

## Known Rate Limit Policies

These are approximate and should be verified via WebSearch before each run:

| Server | Known Limit | Safe Delay |
|--------|-----------|-----------|
| `whois.verisign-grs.com` (.com/.net) | ~1 query/second per IP | 2s |
| `whois.pir.org` (.org) | Not published; conservative recommended | 3s |
| `whois.nic.io` (.io) | Aggressive limiting reported | 3s |
| `whois.nic.google` (.dev/.app) | Not published | 2s |
| `whois.nic.ai` (.ai) | Known for slow responses | 3s |
| General recommendation | 1-2 queries/second typical | 2-3s |

**Important:** Rate limits change. Before running batch queries, use WebSearch to check current policies for the target TLD's WHOIS server. The delay_seconds parameter should be set to the most conservative limit discovered across all target TLDs.
