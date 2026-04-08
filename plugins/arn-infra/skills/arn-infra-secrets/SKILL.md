---
name: arn-infra-secrets
description: >-
  This skill should be used when the user says "manage secrets", "arn infra secrets",
  "infra secrets", "secrets management", "set up secrets", "configure secrets",
  "audit secrets", "secrets audit", "rotate secrets", "secret storage",
  "vault setup", "key management", "credential management", "secrets scan",
  "check for exposed secrets", "secrets provider", "arn-infra-secrets",
  "set up secret manager", "configure secret injection", "environment variables",
  "env vars", "secure env vars", or wants to set up,
  configure, audit, or manage secrets and credential storage for their
  infrastructure deployment.
version: 1.0.0
---

# Arness Infra Secrets

Set up, configure, and audit secrets management for infrastructure deployments. This skill scans the project for secrets exposure, recommends a secrets management provider, guides setup, configures injection into deployments, and produces a secrets audit report.

This skill addresses the complete secrets lifecycle: discovery of existing patterns, provider selection, configuration, injection into applications and CI/CD, and ongoing audit verification.

## Prerequisites

Read `## Arness` from the project's CLAUDE.md. If no `## Arness` section exists or Arness Infra fields are missing, inform the user: "Arness Infra is not configured for this project yet. Run `/arn-infra-wizard` to get started — it will set everything up automatically." Do not proceed without it.

Check the **Deferred** field. If `Deferred: yes`, inform the user: "Infrastructure is in deferred mode. Secrets management is not available until infrastructure is fully configured. Run `/arn-infra-assess` to un-defer." Stop.

Extract:
- **Experience level** -- derived from user profile. Read `~/.arness/user-profile.yaml` (or `.claude/arness-profile.local.md` if it exists — project override takes precedence). Apply the experience derivation mapping from `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-ensure-config/references/experience-derivation.md`. If no profile exists, check for legacy `Experience level` in `## Arness` as fallback.
- **Providers** -- cloud providers in use (determines available secrets services)
- **Providers config** -- path to `providers.md` for per-provider details
- **Default IaC tool** -- for generating secrets manager IaC
- **Environments** -- environment list for per-environment secret scoping
- **Environments config** -- path to `environments.md`
- **Tooling manifest** -- path to `tooling-manifest.json` for available scanning tools
- **CI/CD platform** -- for pipeline secret injection (github-actions, gitlab-ci, bitbucket-pipelines, none)

---

## Workflow

### Step 1: Scan for Existing Secrets Patterns

Invoke the `arn-infra-security-auditor` agent via the Task tool with:

--- FILES TO AUDIT ---
Scan the entire project for secrets patterns:
- `.env` files, `.env.*` files
- Configuration files (config.*, settings.*, application.*)
- Dockerfiles and docker-compose files
- IaC files (*.tf, *.hcl, Pulumi.*, cdk.json, *.bicep)
- CI/CD pipeline files (.github/workflows/*, .gitlab-ci.yml)
- Source code files (look for hardcoded connection strings, API keys, tokens)
--- END FILES TO AUDIT ---

--- AUDIT CONTEXT ---
Audit type: Secrets exposure scan
Focus: Identify all secrets, credentials, API keys, tokens, connection strings, and passwords
Check: .env files committed to git, secrets in Dockerfile build args, hardcoded values in IaC
--- END AUDIT CONTEXT ---

--- INSTRUCTIONS ---
Perform a comprehensive secrets scan:
1. Check if .env files are committed to git (vs. .gitignore'd)
2. Scan Dockerfiles for secrets in ARG, ENV, or COPY directives
3. Scan IaC files for hardcoded values (passwords, keys, connection strings)
4. Scan CI/CD pipelines for exposed secrets in logs or artifacts
5. Check for TruffleHog/Gitleaks availability and run if found
6. Identify all environment variables that contain sensitive values
7. List all secrets that need to be managed
--- END INSTRUCTIONS ---

After the agent returns its scan report, present the findings to the user using this format:
"I scanned your project for secrets patterns. Here is what I found:
- **Secrets found:** [count] potential secrets in [count] files
- **High risk:** [list critical findings -- e.g., committed .env files, hardcoded passwords]
- **Medium risk:** [list moderate findings]
- **Current secrets management:** [detected approach, or 'none']"

---

### Step 2: Recommend Secrets Provider

> Read the local override or plugin default for `secrets-providers.md`.

Based on the configured cloud provider(s) and experience level, recommend a secrets management approach:

**Expert:**
Present all options with comparison:
"Here are the secrets management options for your setup:

| Provider | Cost | Integration | Features | Recommendation |
|----------|------|-------------|----------|----------------|
[comparison table from reference]

Which would you prefer?"

**Intermediate:**
Present the top 2 recommendations:

Ask (using `AskUserQuestion`):

**"Which secrets provider do you prefer for your [provider] setup?"**

Options:
1. **[Native option]** -- Tightest integration with [provider], [cost]. Best if you're staying single-cloud.
2. **[Cross-cloud option]** -- Works across providers, [cost]. Best if you have multi-cloud plans.

**Beginner:**
Make a direct recommendation:
"For your setup, I recommend using [provider's native secrets manager / Doppler] because [rationale]. It is the simplest option that provides secure secrets storage."

**Provider mapping:**
- AWS --> AWS Secrets Manager (or SSM Parameter Store for simpler needs)
- GCP --> GCP Secret Manager
- Azure --> Azure Key Vault
- Multi-cloud --> HashiCorp Vault or Doppler
- PaaS (Fly.io, Railway, etc.) --> Platform-native environment variables with CI/CD secrets
- All providers --> SOPS for encrypted files in git (complement to a secrets manager)

---

### Step 3: Guide Secrets Provider Setup

Based on the user's choice, guide the setup:

**For cloud-native secrets managers (AWS Secrets Manager, GCP Secret Manager, Azure Key Vault):**
1. Verify provider CLI is authenticated (from tooling manifest)
2. Create the secrets manager resource via IaC or CLI
3. Set up IAM permissions for application access
4. Create initial secrets (database passwords, API keys, etc.)
5. Configure rotation policies (if supported)

**For third-party providers (Vault, Doppler, 1Password):**
1. Guide installation and account setup
2. Configure project/environment structure
3. Set up integration with the cloud provider
4. Import existing secrets from the scan findings

**For SOPS (encrypted files in git):**
1. Install SOPS and configure encryption keys (AWS KMS, GCP KMS, age)
2. Create encrypted secrets files per environment
3. Add `.sops.yaml` configuration
4. Verify decryption works in CI/CD

For beginners, simplify guidance to the most common pattern only. For experts, show all available options with configuration details.

Before executing any setup actions, present the plan: "Here is the setup plan for [provider]: [numbered list of actions from above]. Proceed?" Wait for user confirmation before executing.

---

### Step 4: Configure Secrets Injection

Configure how secrets are injected into the deployment:

**Container deployments:**
- Environment variables via secrets manager references
- Mounted volumes (for certificate files, config files)
- Init containers that fetch secrets at startup

**IaC references:**
- OpenTofu/Terraform: `data "aws_secretsmanager_secret_version"` / `data "google_secret_manager_secret_version"`
- Pulumi: `pulumi.secret()` / provider-specific secret resources
- CDK: `secretsmanager.Secret.fromSecretNameV2()`
- Bicep: `reference(keyVaultId, 'secrets', secretName)`

**CI/CD pipeline injection:**
- GitHub Actions: Repository secrets, environment secrets, OIDC-fetched secrets
- GitLab CI: CI/CD variables (masked, protected), environment-scoped variables
- Bitbucket: Repository variables, deployment variables

**Platform-native (PaaS):**
- Fly.io: `fly secrets set KEY=value`
- Railway: Environment variables in project settings
- Render: Environment variables per service
- Vercel: Environment variables (production, preview, development scopes)

For beginners, simplify guidance to the most common pattern only. For experts, show all available options with configuration details.

Present the injection configuration for user approval before applying.

---

### Step 5: Run Secrets Audit

> Read the local override or plugin default for `secrets-audit-checklist.md`.

For beginners, simplify guidance to the most common pattern only. For experts, show all available options with configuration details.

Run the audit checklist against the project's current state:

For each checklist item, verify and report:
- **Pass** -- requirement is met
- **Fail** -- requirement is not met (with remediation steps)
- **N/A** -- not applicable to this project's setup

Produce the secrets audit report using the **Audit Report Template** from the `secrets-audit-checklist.md` reference. Populate all fields from the scan and audit results.

---

### Step 6: Present Summary and Next Steps

**Secrets Management Summary:**
- **Provider:** [chosen secrets provider]
- **Secrets found and migrated:** [count]
- **Injection method:** [env vars / mounted volumes / provider-specific]
- **Audit result:** [passed / N failures requiring remediation]
- **Files created/modified:** [list]

**Recommended next steps:**

"Secrets management is configured. Here is the recommended path:

1. **Remediate findings** (if any audit failures) -- Address the failed audit checks listed above
2. **Set up CI/CD:** Run `/arn-infra-pipeline` to configure secret injection in your deployment pipelines
3. **Set up monitoring:** Run `/arn-infra-monitor` to configure alerting for secret access patterns
4. **Deploy:** Run `/arn-infra-deploy` to deploy with the new secrets configuration

Or run `/arn-infra-wizard` for the full guided pipeline."

---

## Error Handling

- **`## Arness` config missing:** Suggest running `/arn-infra-wizard` to get started. Stop.
- **Security auditor agent fails:** Fall back to manual scanning using `Grep` for common patterns (.env files, hardcoded strings). Present: "Automated scan unavailable -- performed basic pattern scan instead. Install TruffleHog or Gitleaks for thorough scanning."
- **Security auditor returns empty output:** Inform the user: "No secrets patterns were detected. This may mean secrets are well-managed, or the scan could not access all project files." Proceed to setup with an empty findings list.
- **Provider CLI not authenticated:** Warn that secrets manager creation will be limited. Suggest running `/arn-infra-discover` to configure provider access.
- **Chosen secrets provider requires paid plan:** Inform the user of the cost and confirm before proceeding. Suggest free alternatives if available (e.g., SSM Parameter Store instead of Secrets Manager for AWS).
- **SOPS key not available:** Guide the user through key creation (age key generation, KMS key creation). Do not proceed until encryption is verified.
- **Existing secrets found in git history:** Warn: "Secrets were found in committed files. Even after removing them from current files, they remain in git history. Consider: (1) rotating all affected credentials, (2) using git-filter-repo to clean history (destructive), (3) treating them as compromised."
- **Re-running is safe:** The skill re-scans the project and presents updated audit results. Existing secrets configuration is preserved. The audit report is regenerated with current state.
