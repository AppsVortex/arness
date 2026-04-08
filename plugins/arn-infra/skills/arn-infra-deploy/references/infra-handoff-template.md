# Infrastructure Handoff Template

Template for `INFRA_HANDOFF_<environment>.md` files generated after each successful deployment. The handoff file provides all information needed to connect to, operate, and maintain the deployed infrastructure.

**SECURITY RULE:** All secret values (passwords, tokens, connection strings, API keys) MUST be referenced by their storage location, NEVER written as raw values. This file may be committed to version control.

---

## Template

```markdown
# Infrastructure Handoff: [Environment Name]

**Deployed:** [ISO 8601 timestamp]
**Provider(s):** [provider list]
**IaC Tool:** [tool]
**Deployer:** [arn-infra-deploy / CI/CD pipeline name]
**TTL:** [expiry timestamp if ephemeral, "permanent" if persistent]

---

## Endpoints

| Service | URL | Type | Health Check |
|---------|-----|------|-------------|
| [service-name] | [url] | HTTP/HTTPS/TCP | [health check path or "none"] |

---

## Connection Strings

> All values are secret references. Retrieve actual values from the referenced secret store.

| Resource | Secret Reference |
|----------|-----------------|
| [database-name] | See [secret store] at `[reference path]` |
| [cache-name] | See [secret store] at `[reference path]` |
| [queue-name] | See [secret store] at `[reference path]` |

### Secret Reference Formats by Provider

- **AWS Secrets Manager:** `arn:aws:secretsmanager:<region>:<account>:secret:<name>`
- **AWS SSM Parameter Store:** `arn:aws:ssm:<region>:<account>:parameter/<name>`
- **GCP Secret Manager:** `projects/<project>/secrets/<name>/versions/latest`
- **Azure Key Vault:** `https://<vault>.vault.azure.net/secrets/<name>`
- **HashiCorp Vault:** `secret/data/<path>`
- **Fly.io Secrets:** `fly secrets list --app <app>` (set via `fly secrets set`)
- **Railway Variables:** Railway dashboard > Service > Variables
- **Vercel Env Vars:** Vercel dashboard > Project > Settings > Environment Variables
- **Netlify Env Vars:** Netlify dashboard > Site > Site configuration > Environment variables
- **Render Env Groups:** Render dashboard > Env Groups

---

## Environment Variables

| Variable | Description | Source |
|----------|-------------|--------|
| [VAR_NAME] | [what it configures] | [where the value comes from: secret store, platform config, hardcoded] |

---

## Access Instructions

### [Service/Resource Name]

**Type:** [compute / database / storage / etc.]
**Access method:** [SSH / kubectl / platform CLI / web console]

```bash
# [access command]
[example command to connect]
```

---

## Monitoring

| Type | URL/Command | Notes |
|------|------------|-------|
| Health check | [URL] | Expect HTTP 200 |
| Logs | [command or URL] | [log aggregation service or CLI command] |
| Metrics | [URL] | [metrics dashboard or CLI command] |
| Alerts | [URL or configuration] | [alerting service] |

---

## Rollback Procedure

**Last known good state:** [commit hash or deployment ID]

Steps to rollback this environment:

1. [Step 1: specific rollback command for the IaC tool in use]
2. [Step 2: verify rollback success]
3. [Step 3: update issue tracker / notify team]

**Data preservation notes:**
- [any databases that need snapshots before rollback]
- [any storage that needs backup]

---

## Resource Inventory

| Resource | Type | ID/ARN | Region | Monthly Cost |
|----------|------|--------|--------|-------------|
| [name] | [type] | [provider-specific ID] | [region] | $[amount] |

**Total estimated monthly cost:** $[total]

---

## Notes

[Any deployment-specific notes, known issues, or temporary workarounds]
```

---

## Usage Rules

1. **One file per environment:** Each environment gets its own handoff file: `INFRA_HANDOFF_staging.md`, `INFRA_HANDOFF_production.md`, etc.

2. **Overwrite on re-deploy:** Each deployment overwrites the handoff file for the target environment with current state. The previous version is preserved in git history.

3. **Never include raw secrets:** Every connection string, password, token, and API key must be a reference to its storage location. If a secret is not stored in a secret manager, the handoff file should note where the user needs to retrieve it (e.g., "set manually via `fly secrets set DB_URL=...`").

4. **Output location:** Write to the `Infra specs directory` from `## Arness` config. Example: `.arness/infra-specs/INFRA_HANDOFF_staging.md`.

5. **Cross-reference the INFRA spec:** The handoff file references the environment-specific state. The `INFRA_<project>.md` spec (from `arn-infra-define`) describes the overall architecture. These are complementary documents.
