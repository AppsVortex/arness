# Secrets Audit Checklist

Comprehensive checklist for auditing secrets management in infrastructure projects. Each item should be verified and reported as Pass, Fail, or N/A.

---

## 1. No Committed .env Files

**Check:** Verify that `.env` files containing secrets are not committed to the git repository.

**How to verify:**
```bash
# Check if .env is in .gitignore
grep -q "\.env" .gitignore && echo "PASS: .env in .gitignore" || echo "FAIL: .env not in .gitignore"

# Check if .env files are tracked by git
git ls-files | grep -E "^\.env$|^\.env\." | head -20
# If output is non-empty: FAIL

# Check git history for previously committed .env files
git log --all --diff-filter=A -- ".env" ".env.*" --oneline | head -10
```

**Remediation if failed:**
1. Add `.env`, `.env.*`, `.env.local` to `.gitignore`
2. Remove tracked .env files: `git rm --cached .env`
3. Rotate all secrets that were committed
4. Consider cleaning git history with `git-filter-repo`

---

## 2. No Dockerfile Secrets

**Check:** Verify that Dockerfiles do not contain secrets in `ARG`, `ENV`, or `COPY` directives.

**How to verify:**
```bash
# Scan Dockerfiles for common secret patterns
grep -rn "ARG.*PASSWORD\|ARG.*SECRET\|ARG.*KEY\|ARG.*TOKEN" Dockerfile* docker-compose*
grep -rn "ENV.*PASSWORD=\|ENV.*SECRET=\|ENV.*KEY=\|ENV.*TOKEN=" Dockerfile*

# Check for COPY of secrets files
grep -rn "COPY.*\.env\|COPY.*credentials\|COPY.*\.key\|COPY.*\.pem" Dockerfile*
```

**Secure alternatives:**
```dockerfile
# BAD: Secret in build arg (visible in image layers)
ARG DB_PASSWORD
ENV DB_PASSWORD=${DB_PASSWORD}

# GOOD: BuildKit secret mount (not stored in layers)
RUN --mount=type=secret,id=db_password cat /run/secrets/db_password

# GOOD: Runtime injection via environment variable
# (set at container start, not build time)
ENV DB_PASSWORD_FILE=/run/secrets/db_password
```

**Remediation if failed:**
1. Replace `ARG`/`ENV` secrets with BuildKit secret mounts
2. Use multi-stage builds to avoid copying secrets into final image
3. Inject secrets at runtime via environment variables or mounted volumes

---

## 3. No IaC Hardcoded Secrets

**Check:** Verify that IaC files do not contain hardcoded secrets, passwords, or API keys.

**How to verify:**
```bash
# Scan IaC files for hardcoded values
grep -rn "password\s*=\s*\"[^$]" *.tf *.hcl 2>/dev/null
grep -rn "secret\s*=\s*\"[^$]" *.tf *.hcl 2>/dev/null
grep -rn "api_key\s*=\s*\"" *.tf *.hcl 2>/dev/null
grep -rn "token\s*=\s*\"" *.tf *.hcl 2>/dev/null

# Check for default values in variable definitions
grep -A2 "variable.*password\|variable.*secret\|variable.*key" *.tf 2>/dev/null | grep "default"
```

**Secure alternatives:**
```hcl
# BAD: Hardcoded password
resource "aws_db_instance" "db" {
  password = "mysecretpassword123"
}

# GOOD: Variable reference (set via tfvars, env var, or secrets manager)
resource "aws_db_instance" "db" {
  password = var.db_password
}

# GOOD: Secrets manager reference
data "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db_password.id
}

resource "aws_db_instance" "db" {
  password = data.aws_secretsmanager_secret_version.db.secret_string
}
```

**Remediation if failed:**
1. Replace hardcoded values with variable references
2. Use `sensitive = true` on variable definitions
3. Reference secrets from a secrets manager via data sources
4. Remove default values from sensitive variable definitions

---

## 4. Rotation Policy Defined

**Check:** Verify that a rotation policy exists for all managed secrets.

**How to verify:**
- Confirm that the chosen secrets provider has rotation configured
- Check rotation intervals (recommended: 90 days for most secrets, 30 days for database credentials)
- Verify that rotation does not cause service disruption (graceful handoff)

**Checklist:**
- [ ] Database credentials have rotation configured
- [ ] API keys have rotation schedule documented
- [ ] Service account keys are rotated regularly
- [ ] TLS certificates have renewal automation (e.g., Let's Encrypt, ACM)
- [ ] Rotation procedure is tested (not just documented)

**Remediation if failed:**
1. Enable automatic rotation in the secrets provider (AWS SM, GCP SM, Vault)
2. For manual rotation: document the rotation procedure with a schedule
3. Set up calendar reminders or automated alerts for rotation deadlines
4. Test rotation in staging before production

---

## 5. Least-Privilege Access

**Check:** Verify that secrets access follows the principle of least privilege.

**How to verify:**
- Review IAM policies that grant access to secrets
- Confirm applications only have access to the secrets they need
- Confirm environment isolation (staging cannot read production secrets)
- Confirm CI/CD has separate secret scopes per environment

**Checklist:**
- [ ] Applications access only their own secrets (not all secrets)
- [ ] Secrets are scoped by environment (dev secrets separate from prod)
- [ ] CI/CD pipeline has environment-scoped secret access
- [ ] No wildcard (`*`) permissions on secrets resources
- [ ] Human access to production secrets is restricted and logged
- [ ] Break-glass procedure documented for emergency access

**Remediation if failed:**
1. Restrict IAM policies to specific secret ARNs/names
2. Use resource-based policies with condition keys
3. Implement environment-scoped access (prefix-based or tag-based)
4. Enable audit logging for all secret access

---

## 6. Injection Method Verified

**Check:** Verify that secrets are properly injected into all environments.

**How to verify:**
- Confirm the application can read secrets in each environment
- Confirm secrets are available at runtime (not just build time)
- Confirm secrets are not exposed in application logs or error messages

**Checklist:**
- [ ] Application reads secrets from environment variables or mounted files
- [ ] Secrets are available in all configured environments (dev, staging, prod)
- [ ] Application startup fails gracefully if required secrets are missing
- [ ] Secrets values are not logged at any log level (including debug)
- [ ] Error messages do not include secret values
- [ ] Health check endpoints do not expose secrets

**Remediation if failed:**
1. Verify injection configuration in the deployment (env vars, volume mounts)
2. Add startup validation that checks for required secrets
3. Add log filtering to prevent secret exposure
4. Test injection in each environment independently

---

## 7. Secret Scanner Clean

**Check:** Verify that automated secret scanning tools report no findings.

**How to verify:**
```bash
# TruffleHog (filesystem scan)
trufflehog filesystem . --json 2>/dev/null | jq -r '.RawV2' | head -5
# Empty output = PASS

# Gitleaks (git history scan)
gitleaks detect --source . --report-format json --report-path /tmp/gitleaks.json 2>/dev/null
# Check exit code: 0 = PASS, 1 = FAIL (leaks found)

# If neither tool is installed
echo "WARN: No secret scanner available. Install TruffleHog or Gitleaks for automated scanning."
```

**Remediation if failed:**
1. Review each finding to determine if it is a true positive
2. Rotate any confirmed exposed secrets immediately
3. Remove or encrypt the files containing secrets
4. Add pre-commit hooks to prevent future commits of secrets:
   ```bash
   # .pre-commit-config.yaml
   - repo: https://github.com/gitleaks/gitleaks
     hooks:
       - id: gitleaks
   ```

---

## CI/CD Pipeline Secrets

Additional checks for CI/CD pipeline configurations:

- [ ] **No secrets in pipeline logs.** Commands use `--no-color` and avoid `echo $SECRET`. GitHub Actions uses `::add-mask::` for dynamic secrets. GitLab CI marks variables as "masked."
- [ ] **Secrets are not stored in pipeline artifacts.** Plan files, deployment logs, and build outputs do not contain secret values.
- [ ] **Pipeline secrets are environment-scoped.** Production secrets are not accessible from staging pipeline runs.
- [ ] **OIDC is used where available.** Cloud provider authentication uses OIDC token exchange, not stored API keys.

---

## Audit Report Template

Use this template for the secrets audit report output. This is the single authoritative template — the SKILL.md references this section rather than inlining it.

```markdown
## Secrets Audit Report

**Date:** [date]
**Project:** [name]
**Secrets provider:** [provider]
**Scanner used:** [TruffleHog / Gitleaks / Manual / None]
**Environments audited:** [list]

### Results

| # | Check | Status | Details |
|---|-------|--------|---------|
| 1 | No committed .env files | [Pass/Fail/N/A] | [details] |
| 2 | No Dockerfile secrets | [Pass/Fail/N/A] | [details] |
| 3 | No IaC hardcoded secrets | [Pass/Fail/N/A] | [details] |
| 4 | Rotation policy defined | [Pass/Fail/N/A] | [details] |
| 5 | Least-privilege access | [Pass/Fail/N/A] | [details] |
| 6 | Injection verified | [Pass/Fail/N/A] | [details] |
| 7 | Secret scanner clean | [Pass/Fail/N/A] | [details] |

### Summary
- **Passed:** [count] / [total]
- **Failed:** [count]
- **Overall status:** [Secure / Needs Remediation]

### Remediation Priority
1. [Critical items first]
2. [High items next]
3. [Medium items last]
```
