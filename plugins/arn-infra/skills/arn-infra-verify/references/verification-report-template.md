# Verification Report Template

Template for the structured verification report produced by the `arn-infra-verifier` agent and processed by `arn-infra-verify`. The report captures all verification check results with a clear pass/warn/fail verdict.

---

## Report Format

```markdown
## Verification Report

**Environment:** [environment name]
**Timestamp:** [ISO 8601]
**Overall Status:** PASS | WARN | FAIL

---

### Health Checks

| # | Endpoint | Method | Expected | Actual | Response Time | Result |
|---|----------|--------|----------|--------|---------------|--------|
| 1 | https://api.example.com/health | GET | 200 | 200 | 120ms | PASS |
| 2 | https://app.example.com/ | GET | 200 | 200 | 350ms | PASS |
| 3 | http://api.example.com/ | GET | 301 (redirect to HTTPS) | 301 | 45ms | PASS |

**Health Check Summary:** [N/N passed]

---

### DNS Verification

| # | Domain | Record Type | Expected Target | Actual Target | TTL | Result |
|---|--------|-------------|----------------|---------------|-----|--------|
| 1 | api.example.com | A | 203.0.113.10 | 203.0.113.10 | 300 | PASS |
| 2 | app.example.com | CNAME | app.fly.dev | app.fly.dev | 3600 | PASS |

**DNS Summary:** [N/N resolved correctly]

---

### SSL/TLS Validation

| # | Domain | Issuer | Expiry | Days Remaining | Chain Valid | Protocol | Result |
|---|--------|--------|--------|----------------|------------|----------|--------|
| 1 | api.example.com | Let's Encrypt | 2026-06-11 | 92 | Yes | TLS 1.3 | PASS |
| 2 | app.example.com | Let's Encrypt | 2026-06-11 | 92 | Yes | TLS 1.3 | PASS |

**SSL Summary:** [N/N valid]

---

### Resource State Comparison

| # | Resource | Type | Expected State | Actual State | Configuration Match | Result |
|---|----------|------|---------------|-------------|-------------------|--------|
| 1 | api-server | compute | running | running | Yes | PASS |
| 2 | postgres-db | database | available | available | Yes | PASS |
| 3 | redis-cache | cache | available | available | Yes | PASS |
| 4 | cdn-distribution | cdn | deployed | deployed | Yes | PASS |

**Resource Summary:** [N/N matched], [N drifted], [N missing]

---

### Database Connectivity

| # | Database | Type | Port Reachable | Connection Pool | Result |
|---|----------|------|---------------|----------------|--------|
| 1 | postgres-db | PostgreSQL | Yes | Healthy (5/20 active) | PASS |
| 2 | redis-cache | Redis | Yes | N/A | PASS |

**Database Summary:** [N/N connected]

---

### Environment Variables

| # | Variable Group | Expected Count | Configured Count | Missing | Result |
|---|---------------|---------------|-----------------|---------|--------|
| 1 | Database secrets | 3 | 3 | 0 | PASS |
| 2 | API keys | 2 | 2 | 0 | PASS |
| 3 | Application config | 5 | 5 | 0 | PASS |

**Env Var Summary:** [N/N configured]

---

### Overall Verdict

**Status:** [PASS | WARN | FAIL]

[If PASS:]
All verification checks passed. The deployment is healthy and ready for traffic.

[If WARN:]
The deployment is functional but the following non-critical issues were detected:
- [Warning 1: description and impact]
- [Warning 2: description and impact]

Recommended actions:
- [Action 1]
- [Action 2]

[If FAIL:]
Verification failed. The following critical issues were detected:
- [Failure 1: description, impact, and remediation]
- [Failure 2: description, impact, and remediation]

Recommended action: [Rollback | Fix and re-deploy | Investigate]

---

### Checks Skipped

| Check | Reason |
|-------|--------|
| [check name] | [reason: tool not available, not applicable, etc.] |
```

---

## Verdict Logic

### PASS Criteria
All of the following must be true:
- All HTTP health checks return expected status codes
- All DNS names resolve to expected targets
- All SSL certificates are valid and not expiring within 30 days
- All expected resources exist and match expected state
- All databases are reachable
- All required environment variables are configured

### WARN Criteria
Any of the following triggers a WARN (but not FAIL):
- Response times exceed 3 seconds but service is reachable
- SSL certificate expiring within 30 days (but not expired)
- Minor resource configuration drift (non-critical parameters differ)
- DNS TTL values are outside recommended range
- Some verification checks were skipped due to missing tools

### FAIL Criteria
Any of the following triggers a FAIL:
- HTTP health check returns non-200 status or times out
- DNS name does not resolve (NXDOMAIN or SERVFAIL)
- SSL certificate is expired or invalid
- Expected resource is missing or in an error state
- Database is unreachable
- Critical environment variables are not configured
- Self-signed certificate in staging or production environment

---

## Report Storage

The verification report is:
1. Presented to the user in the conversation
2. Summarized in `environments.md` under the verified environment
3. Referenced via `lastVerified` timestamp in `active-resources.json`

The full report is not persisted as a separate file -- it exists in the conversation history and as summary fields in environments.md and the resource manifest. If the user needs a persistent record, they can copy the report from the conversation.
