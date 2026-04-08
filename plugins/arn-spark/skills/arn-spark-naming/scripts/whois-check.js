#!/usr/bin/env node
/**
 * Domain availability checker using RDAP (primary) with WHOIS fallback.
 * Reads JSON from stdin, outputs JSON to stdout.
 * Uses only Node.js stdlib (https, net, child_process).
 *
 * RDAP (Registration Data Access Protocol) is the IETF standard replacement
 * for port-43 WHOIS. It returns structured JSON over HTTPS, with 404 = available.
 * IANA bootstrap file provides RDAP servers for all TLDs — no hardcoded map needed.
 *
 * Fallback chain per domain:
 *   1. RDAP via IANA bootstrap → structured JSON, 200=taken, 404=available
 *   2. Port-43 WHOIS via socket → pattern matching
 *   3. System `whois` command → pattern matching on stdout
 *
 * Circuit breaker: stops ALL remaining queries on RDAP 429 only.
 * Port-43 rate limits are per-server — they skip the domain, not the batch.
 *
 * Input:  {"domains": ["example.com", ...], "delay_seconds": 2}
 * Output: [{"domain": "example.com", "tld": "com", "available": true, ...}, ...]
 *
 * Exit code 0 = all queries completed. Exit code 1 = stopped early (rate limit).
 * Exit code 2 = invalid input.
 */

const https = require('https');
const net = require('net');
const { execFileSync, execSync } = require('child_process');

// ─── RDAP Bootstrap ──────────────────────────────────────────────────────────

const IANA_BOOTSTRAP_URL = 'https://data.iana.org/rdap/dns.json';
const rdapServers = {};
let bootstrapLoaded = false;

function loadRdapBootstrap() {
  return new Promise((resolve) => {
    if (bootstrapLoaded) return resolve();

    log('Loading IANA RDAP bootstrap...');
    httpsGetJson(IANA_BOOTSTRAP_URL)
      .then((data) => {
        for (const service of data.services || []) {
          const tlds = service[0];
          const servers = service[1];
          if (servers && servers.length > 0) {
            const baseUrl = servers[0].replace(/\/+$/, '');
            for (const tld of tlds) {
              rdapServers[tld.toLowerCase()] = baseUrl;
            }
          }
        }
        log(`  Loaded ${Object.keys(rdapServers).length} TLD RDAP servers from bootstrap`);
        bootstrapLoaded = true;
        resolve();
      })
      .catch((err) => {
        log(`  WARNING: RDAP bootstrap failed (${err.message}). Will use WHOIS fallback.`);
        bootstrapLoaded = true;
        resolve();
      });
  });
}

function getRdapServer(tld) {
  return rdapServers[tld.toLowerCase()] || null;
}

// ─── Port-43 WHOIS (fallback) ────────────────────────────────────────────────

const WHOIS_SERVERS = {
  com: 'whois.verisign-grs.com',
  net: 'whois.verisign-grs.com',
  org: 'whois.pir.org',
  io: 'whois.nic.io',
  co: 'whois.registry.co',
  // .dev and .app are RDAP-only — no port-43 WHOIS server exists
  ai: 'whois.nic.ai',
  me: 'whois.nic.me',
  xyz: 'whois.nic.xyz',
  tech: 'whois.nic.tech',
  so: 'whois.nic.so',
  sh: 'whois.nic.sh',
  to: 'whois.tonic.to',
  gg: 'whois.gg',
  ly: 'whois.nic.ly',
  is: 'whois.isnic.is',
  fm: 'whois.nic.fm',
  tv: 'whois.nic.tv',
  cc: 'ccwhois.verisign-grs.com',
  de: 'whois.denic.de',
  fr: 'whois.nic.fr',
  eu: 'whois.eu',
  us: 'whois.nic.us',
  ca: 'whois.cira.ca',
  uk: 'whois.nic.uk',
  'co.uk': 'whois.nic.uk',
  'org.uk': 'whois.nic.uk',
  // EU market TLDs
  it: 'whois.nic.it',
  es: 'whois.nic.es',
  nl: 'whois.domain-registry.nl',
  pt: 'whois.dns.pt',
  pl: 'whois.dns.pl',
  se: 'whois.iis.se',
  ch: 'whois.nic.ch',
  at: 'whois.nic.at',
  be: 'whois.dns.be',
  // Asia-Pacific TLDs
  jp: 'whois.jprs.jp',
  in: 'whois.registry.in',
  au: 'whois.auda.org.au',
  kr: 'whois.kr',
  // Latin America TLDs
  br: 'whois.registro.br',
  mx: 'whois.mx',
  ar: 'whois.nic.ar',
  cl: 'whois.nic.cl',
  // Compound ccTLDs
  'com.br': 'whois.registro.br',
  'com.au': 'whois.auda.org.au',
  'co.jp': 'whois.jprs.jp',
  'co.in': 'whois.registry.in',
  'com.mx': 'whois.mx',
  'com.ar': 'whois.nic.ar',
  'co.kr': 'whois.kr',
  'com.pt': 'whois.dns.pt',
};

const AVAILABLE_PATTERNS = [
  'no match for', 'not found', 'no entries found', 'no data found',
  'domain not found', 'no information available', 'status: available',
  'the queried object does not exist', 'no object found',
  'is available for', 'domain name has not been registered',
  'status: free',
];

const TAKEN_PATTERNS = [
  'domain name:', 'registrar:', 'creation date:', 'registry expiry date:',
  'updated date:', 'name server:', 'registrant:', 'status: ok',
  'status: active', 'status: clienttransferprohibited',
  'nserver:', 'status: connect', 'registered on:', 'expires on:',
];

const RATE_LIMIT_PATTERNS = [
  'quota exceeded', 'rate limit', 'too many requests',
  'please try again later', 'your request has been throttled',
  'connection limit reached', 'access denied', 'query rate exceeded',
];

const NOT_SUPPORTED_PATTERNS = [
  'tld is not supported', 'this tld has no whois server',
  'no whois server is known', 'unknown tld',
];

const QUERY_TIMEOUT = 10000;

// ─── Shared Utilities ────────────────────────────────────────────────────────

function log(msg) {
  process.stderr.write(msg + '\n');
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function getTld(domain) {
  const parts = domain.toLowerCase().split('.');
  if (parts.length < 2) return null;
  if (parts.length >= 3) {
    const compound = parts[parts.length - 2] + '.' + parts[parts.length - 1];
    if (WHOIS_SERVERS[compound] || rdapServers[compound]) return compound;
  }
  return parts[parts.length - 1];
}

function manualCheckUrl(domain) {
  return `https://www.whois.com/whois/${domain}`;
}

class RateLimitError extends Error {
  constructor(message) {
    super(message);
    this.name = 'RateLimitError';
  }
}

// ─── HTTPS GET helper ────────────────────────────────────────────────────────

function httpsGetJson(url, timeout = QUERY_TIMEOUT) {
  return new Promise((resolve, reject) => {
    const req = https.get(url, { headers: { Accept: 'application/rdap+json, application/json' }, timeout }, (res) => {
      if (res.statusCode === 301 || res.statusCode === 302) {
        // Follow redirects (rdap.org uses 302)
        const location = res.headers.location;
        if (location) {
          httpsGetJson(location, timeout).then(resolve).catch(reject);
          return;
        }
      }

      if (res.statusCode === 404) {
        reject({ code: 404 });
        return;
      }
      if (res.statusCode === 429) {
        reject({ code: 429 });
        return;
      }
      if (res.statusCode >= 400) {
        reject({ code: res.statusCode });
        return;
      }

      let body = '';
      res.on('data', (chunk) => { body += chunk; });
      res.on('end', () => {
        try {
          resolve(JSON.parse(body));
        } catch (e) {
          reject(new Error(`Invalid JSON from ${url}`));
        }
      });
    });

    req.on('error', reject);
    req.on('timeout', () => {
      req.destroy();
      reject(new Error(`Timeout fetching ${url}`));
    });
  });
}

// ─── RDAP Query ──────────────────────────────────────────────────────────────

async function rdapQuery(domain, tld) {
  const baseUrl = getRdapServer(tld);
  if (!baseUrl) return null;

  const url = `${baseUrl}/domain/${domain}`;

  try {
    const data = await httpsGetJson(url);

    // 200 = domain exists (taken)
    let registrar = null;
    for (const entity of data.entities || []) {
      if ((entity.roles || []).includes('registrar')) {
        const vcard = entity.vcardArray;
        if (Array.isArray(vcard) && vcard.length >= 2) {
          for (const field of vcard[1]) {
            if (field[0] === 'fn') { registrar = field[3]; break; }
          }
        }
        if (!registrar) registrar = entity.handle || null;
      }
    }

    return { domain, tld, available: false, registrar, method: 'rdap', error: null };
  } catch (err) {
    if (err.code === 404) {
      return { domain, tld, available: true, registrar: null, method: 'rdap', error: null };
    }
    if (err.code === 429) {
      throw new RateLimitError(`RDAP rate limit (429) from ${baseUrl} for ${domain}`);
    }
    // Other errors — fall through to WHOIS
    log(`  RDAP failed for ${domain} (${err.message || err.code}), falling back to WHOIS...`);
    return null;
  }
}

// ─── Port-43 WHOIS Query ─────────────────────────────────────────────────────

function whoisQuery(domain, server, port = 43, timeout = QUERY_TIMEOUT) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    const client = new net.Socket();

    const timer = setTimeout(() => {
      client.destroy();
      reject(new Error(`Timeout connecting to ${server}`));
    }, timeout);

    client.on('error', (err) => {
      clearTimeout(timer);
      reject(err);
    });

    client.on('data', (data) => { chunks.push(data); });

    client.on('end', () => {
      clearTimeout(timer);
      resolve(Buffer.concat(chunks).toString('utf-8'));
    });

    client.connect(port, server, () => {
      client.write(domain + '\r\n');
    });
  });
}

function parseWhoisAvailability(response, tld) {
  if (!response || !response.trim()) return null;
  const lower = response.toLowerCase();

  for (const p of NOT_SUPPORTED_PATTERNS) { if (lower.includes(p)) return null; }
  for (const p of RATE_LIMIT_PATTERNS) { if (lower.includes(p)) return null; }

  const availCount = AVAILABLE_PATTERNS.filter((p) => lower.includes(p)).length;
  const takenCount = TAKEN_PATTERNS.filter((p) => lower.includes(p)).length;

  // Verisign fix: .com/.net/.cc require zero TAKEN patterns alongside AVAILABLE
  if (['com', 'net', 'cc'].includes(tld)) {
    if (availCount > 0 && takenCount === 0) return true;
    if (takenCount >= 1) return false;
    return null;
  }

  if (availCount > 0 && takenCount === 0) return true;
  if (takenCount >= 2) return false;
  if (availCount > 0 && takenCount > 0) return takenCount >= 2 ? false : null;
  if (takenCount >= 1) return false;
  return null;
}

function extractRegistrar(response) {
  for (const line of response.split('\n')) {
    const stripped = line.trim();
    if (stripped.toLowerCase().startsWith('registrar:')) {
      return stripped.split(':').slice(1).join(':').trim();
    }
  }
  return null;
}

async function whoisPort43Query(domain, tld) {
  const server = WHOIS_SERVERS[tld];
  if (!server) return null;

  let response;
  try {
    response = await whoisQuery(domain, server);
  } catch (err) {
    log(`  WHOIS port-43 failed for ${domain} via ${server}: ${err.message}`);
    return null;
  }

  if (!response || !response.trim()) return null;

  // Per-server rate limit — NOT circuit-breaking
  const lower = response.toLowerCase();
  for (const p of RATE_LIMIT_PATTERNS) {
    if (lower.includes(p)) {
      log(`  WHOIS rate limit from ${server} for ${domain} (per-server, continuing batch)`);
      return { domain, tld, available: null, registrar: null, method: 'whois', error: `Rate limited by ${server}` };
    }
  }

  const available = parseWhoisAvailability(response, tld);
  const registrar = !available ? extractRegistrar(response) : null;

  return { domain, tld, available, registrar, method: 'whois', error: null };
}

// ─── System WHOIS Fallback ───────────────────────────────────────────────────

function systemWhoisQuery(domain, tld) {
  try {
    // Check if whois is available (cross-platform)
    const whichCmd = process.platform === 'win32' ? 'where' : 'which';
    execSync(`${whichCmd} whois`, { stdio: 'pipe' });
  } catch {
    return null; // whois not available (normal on Windows)
  }

  try {
    const output = execFileSync('whois', [domain], { timeout: 15000, encoding: 'utf-8', stdio: ['pipe', 'pipe', 'pipe'] });
    if (!output || !output.trim()) return null;

    const available = parseWhoisAvailability(output, tld);
    const registrar = !available ? extractRegistrar(output) : null;

    return { domain, tld, available, registrar, method: 'system-whois', error: null };
  } catch {
    return null;
  }
}

// ─── Main Check (cascading fallback) ─────────────────────────────────────────

async function checkDomain(domain) {
  const tld = getTld(domain);
  if (!tld) {
    return { domain, tld: null, available: null, registrar: null, method: 'none', error: 'Could not extract TLD' };
  }

  log(`Checking ${domain}...`);

  // 1. Try RDAP (primary)
  const rdapResult = await rdapQuery(domain, tld);
  if (rdapResult) {
    const status = rdapResult.available === true ? 'available' : rdapResult.available === false ? 'taken' : 'unknown';
    log(`  ${domain}: ${status} (via RDAP)`);
    return rdapResult;
  }

  // 2. Try port-43 WHOIS (fallback)
  const whoisResult = await whoisPort43Query(domain, tld);
  if (whoisResult) {
    const status = whoisResult.available === true ? 'available' : whoisResult.available === false ? 'taken' : 'unknown';
    log(`  ${domain}: ${status} (via WHOIS)`);
    return whoisResult;
  }

  // 3. Try system whois (last resort)
  const sysResult = systemWhoisQuery(domain, tld);
  if (sysResult) {
    const status = sysResult.available === true ? 'available' : sysResult.available === false ? 'taken' : 'unknown';
    log(`  ${domain}: ${status} (via system whois)`);
    return sysResult;
  }

  log(`  ${domain}: UNKNOWN (all methods failed)`);
  return { domain, tld, available: null, registrar: null, method: 'none', error: 'All lookup methods failed' };
}

// ─── Entry Point ─────────────────────────────────────────────────────────────

async function main() {
  let raw = '';
  for await (const chunk of process.stdin) { raw += chunk; }

  let config;
  try {
    config = JSON.parse(raw);
  } catch (e) {
    log(`ERROR: Invalid JSON input: ${e.message}`);
    process.exit(2);
  }

  const domains = config.domains || [];
  let delaySeconds = config.delay_seconds || 2;

  if (!domains.length) {
    process.stdout.write('[]\n');
    process.exit(0);
  }
  if (delaySeconds < 1) delaySeconds = 1;

  await loadRdapBootstrap();

  log(`Checking ${domains.length} domain(s) with ${delaySeconds}s delay...`);
  log(`RDAP servers loaded: ${Object.keys(rdapServers).length} TLDs`);

  const results = [];
  let circuitBroken = false;

  for (let i = 0; i < domains.length; i++) {
    const domain = domains[i].trim().toLowerCase();
    if (!domain) continue;

    try {
      const result = await checkDomain(domain);
      if (result.available === null && result.error) {
        result.manual_url = manualCheckUrl(domain);
      }
      results.push(result);
    } catch (err) {
      if (err instanceof RateLimitError) {
        log(`  CIRCUIT BREAKER (rate limit): ${err.message}`);
        log(`  Stopping. ${domains.length - i - 1} domain(s) not checked.`);
        results.push({
          domain, tld: getTld(domain), available: null, registrar: null,
          method: 'none', error: err.message, manual_url: manualCheckUrl(domain),
        });
        circuitBroken = true;
        break;
      }
      throw err;
    }

    if (i < domains.length - 1) await sleep(delaySeconds * 1000);
  }

  process.stdout.write(JSON.stringify(results, null, 2) + '\n');

  // Summary
  const available = results.filter((r) => r.available === true).length;
  const taken = results.filter((r) => r.available === false).length;
  const unknown = results.filter((r) => r.available === null).length;
  const methods = {};
  for (const r of results) { methods[r.method] = (methods[r.method] || 0) + 1; }

  log(`\nResults: ${results.length} checked — ${available} available, ${taken} taken, ${unknown} unknown`);
  log(`Methods: ${Object.entries(methods).sort().map(([m, c]) => `${m}=${c}`).join(', ')}`);

  process.exit(circuitBroken ? 1 : 0);
}

main();
