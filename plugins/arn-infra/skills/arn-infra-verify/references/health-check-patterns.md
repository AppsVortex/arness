# Health Check Patterns

Verification procedures for post-deployment infrastructure health checks. Each pattern covers what to check, how to check it, expected results, and common failure causes.

---

## HTTP Health Checks

### Basic Availability

```bash
# Simple health check (expect HTTP 200)
curl -s -o /dev/null -w "%{http_code}" https://<endpoint>/health

# With timeout (5 second timeout, fail fast)
curl -s -o /dev/null -w "%{http_code}" --max-time 5 https://<endpoint>/health

# With response body inspection
curl -s --max-time 5 https://<endpoint>/health | jq .
```

**Expected results:**
- HTTP 200 (or configured healthy status code)
- Response time < 5 seconds
- Response body indicates healthy state (if JSON health endpoint)

**Health endpoint patterns by framework:**

| Framework | Typical Path | Response Format |
|-----------|-------------|-----------------|
| Express.js | `/health` or `/healthz` | `{ "status": "ok" }` |
| Django | `/health/` | `{ "status": "healthy" }` |
| Spring Boot | `/actuator/health` | `{ "status": "UP" }` |
| FastAPI | `/health` | `{ "status": "healthy" }` |
| Rails | `/up` or `/health` | `{ "status": "ok" }` |
| Go (stdlib) | `/healthz` or `/readyz` | `ok` (plain text) |
| ASP.NET | `/health` | `{ "status": "Healthy" }` |

### Readiness vs Liveness

**Liveness:** Is the process running?
```bash
# Liveness check (the service responds at all)
curl -s -o /dev/null -w "%{http_code}" --max-time 3 https://<endpoint>/
```

**Readiness:** Can the service handle requests?
```bash
# Readiness check (the service is fully initialized and connected to dependencies)
curl -s --max-time 5 https://<endpoint>/ready
```

Check both when available. A service can be live but not ready (still connecting to database, loading caches).

### HTTPS Redirect Verification

```bash
# Verify HTTP redirects to HTTPS
curl -s -o /dev/null -w "%{http_code} -> %{redirect_url}" http://<endpoint>/

# Expected: 301 or 308 redirect to https://<endpoint>/
```

### Response Time Monitoring

```bash
# Measure response time breakdown
curl -s -o /dev/null -w "DNS: %{time_namelookup}s\nConnect: %{time_connect}s\nTLS: %{time_appconnect}s\nFirstByte: %{time_starttransfer}s\nTotal: %{time_total}s\n" https://<endpoint>/health
```

**Thresholds:**
- Total < 1s: excellent
- Total 1-3s: acceptable
- Total 3-5s: warning (may indicate performance issues)
- Total > 5s: critical (likely timeout for end users)

---

## DNS Verification

### Resolution Check

```bash
# Verify DNS resolution
dig +short <domain>

# With specific record type
dig +short A <domain>
dig +short CNAME <domain>
dig +short AAAA <domain>

# Alternative using nslookup
nslookup <domain>
```

**Expected results:**
- DNS resolves to the expected IP address or CNAME
- Response is not NXDOMAIN (domain does not exist)
- Response is not SERVFAIL (DNS server error)

### TTL Verification

```bash
# Check TTL values
dig <domain> | grep -A1 "ANSWER SECTION"
```

**TTL guidelines:**
- Production: TTL 300-3600 seconds (5 min to 1 hour) -- balance between performance and update speed
- Staging: TTL 60-300 seconds -- faster updates for testing
- Dev: TTL 30-60 seconds -- rapid iteration
- During migration: TTL 60 seconds (set low before migration, increase after verification)

### Propagation Verification

DNS changes can take up to 48 hours to propagate globally. For recent deployments:

```bash
# Check against specific DNS servers to verify propagation
dig @8.8.8.8 <domain>        # Google
dig @1.1.1.1 <domain>        # Cloudflare
dig @9.9.9.9 <domain>        # Quad9
dig @208.67.222.222 <domain> # OpenDNS
```

If results differ across DNS servers, propagation is still in progress.

---

## SSL/TLS Validation

### Certificate Check

```bash
# Check certificate details
echo | openssl s_client -connect <domain>:443 -servername <domain> 2>/dev/null | openssl x509 -noout -dates -subject -issuer

# Check certificate expiry
echo | openssl s_client -connect <domain>:443 -servername <domain> 2>/dev/null | openssl x509 -noout -enddate
```

**Expected results:**
- Certificate is not expired (`notAfter` is in the future)
- Certificate is not expiring within 30 days (warning threshold)
- Certificate covers the correct domain (Subject or SAN matches)
- Certificate is issued by a trusted CA (not self-signed in staging/prod)

### Certificate Chain Verification

```bash
# Verify the full chain
echo | openssl s_client -connect <domain>:443 -servername <domain> 2>/dev/null | openssl x509 -noout -text | grep -A1 "Issuer"

# Check chain completeness
openssl s_client -connect <domain>:443 -servername <domain> -showcerts 2>/dev/null
```

**Common chain issues:**
- Missing intermediate certificate (browser shows "certificate not trusted")
- Expired intermediate certificate
- Wrong certificate order (leaf must be first, then intermediates, then root)

### Protocol Version Check

```bash
# Verify TLS version (should support TLS 1.2 minimum, TLS 1.3 preferred)
openssl s_client -connect <domain>:443 -servername <domain> -tls1_2 2>/dev/null
openssl s_client -connect <domain>:443 -servername <domain> -tls1_3 2>/dev/null

# Verify old protocols are disabled
openssl s_client -connect <domain>:443 -servername <domain> -tls1 2>/dev/null
# Should fail (TLS 1.0 should be disabled)
```

---

## Database Connectivity

### Connection Verification

Do NOT connect with raw credentials. Instead, verify connectivity indirectly:

```bash
# TCP port reachability (does the database accept connections?)
nc -zv <host> <port> -w 5

# Or using bash
timeout 5 bash -c 'echo > /dev/tcp/<host>/<port>' && echo "reachable" || echo "unreachable"
```

### Provider-Specific Checks

| Provider | Check Command | What It Verifies |
|----------|--------------|-----------------|
| AWS RDS | `aws rds describe-db-instances --db-instance-identifier <id>` | Instance status, endpoint, availability |
| GCP Cloud SQL | `gcloud sql instances describe <id>` | Instance state, connection name |
| Azure SQL | `az sql db show --name <db> --server <server> --resource-group <rg>` | Database status, availability |
| Fly.io Postgres | `fly postgres connect --app <app>` | Connectivity test |
| Railway | Check via Railway dashboard API | Database service status |

### Connection Pool Verification

If the application exposes connection pool metrics:
```bash
# Check connection pool via health endpoint
curl -s https://<endpoint>/health | jq '.database'
# Expected: { "status": "connected", "pool": { "active": N, "idle": N, "max": N } }
```

---

## Resource State Comparison

### Provider CLI Commands

| Provider | Command | What It Shows |
|----------|---------|--------------|
| AWS | `aws resourcegroupstaggingapi get-resources --tag-filters Key=managed-by,Values=arn-infra` | All tagged resources |
| GCP | `gcloud asset list --project <project> --filter "labels.managed-by=arn-infra"` | All labeled resources |
| Azure | `az resource list --tag managed-by=arn-infra` | All tagged resources |
| Fly.io | `fly apps list` / `fly status --app <app>` | App status and machines |
| Kubernetes | `kubectl get all -n <namespace> -l managed-by=arn-infra` | All labeled resources |

### Drift Detection

Compare actual resource state against expected state:

1. **Count comparison:** Are the expected number of resources present?
2. **Type comparison:** Are the resource types correct?
3. **Configuration comparison:** Do resource configurations match? (instance size, region, networking)
4. **Status comparison:** Are all resources in a healthy/active state?

### IaC State Comparison

For IaC-managed resources:
```bash
# OpenTofu/Terraform: detect drift
tofu plan -var-file=environments/<env>.tfvars -detailed-exitcode
# Exit code 0 = no changes, 1 = error, 2 = changes detected (drift)

# Pulumi: detect drift
pulumi refresh --stack <env> --preview-only
```

---

## Environment Variable Injection

### Verification Approach

Do NOT read actual secret values. Instead, verify that the application has its required environment variables set:

```bash
# Check if the application's health endpoint reports env var status
curl -s https://<endpoint>/health | jq '.config'
# Expected: { "database_configured": true, "cache_configured": true, ... }
```

For PaaS platforms:
```bash
# Fly.io: list secrets (shows names only, not values)
fly secrets list --app <app>

# Railway: check environment via dashboard or API

# Vercel: list env vars (names only)
vercel env ls

# Netlify: list env vars via CLI
netlify env:list
```

---

## Verification Timing

**Immediate checks (run right after deployment):**
- HTTP health checks (endpoints should be reachable)
- Resource state comparison
- Environment variable injection

**Delayed checks (may need time to propagate):**
- DNS resolution (up to 48h for propagation, typically 5-30 minutes)
- SSL certificate provisioning (1-5 minutes for Let's Encrypt, up to 24h for CA-issued)

**Recommendation:** Run immediate checks right after deployment. If DNS or SSL checks fail, suggest re-running verification after a delay: "DNS/SSL checks may need time to propagate. Re-run `/arn-infra-verify` in [estimated time]."
