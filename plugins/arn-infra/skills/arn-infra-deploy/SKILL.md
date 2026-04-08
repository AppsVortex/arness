---
name: arn-infra-deploy
description: >-
  This skill should be used when the user says "deploy", "deploy to staging",
  "deploy to production", "promote to production", "infra deploy", "arn infra deploy",
  "deploy infrastructure", "apply infrastructure", "push to prod", "go live",
  "tofu apply", "terraform apply", "pulumi up", "cdk deploy", "fly deploy",
  "deploy to railway", "release to prod", "promote environment", or wants to
  execute a deployment of their infrastructure to a target environment. This skill
  handles environment promotion, CI/CD enforcement, cost gates, safety layers,
  and resource tracking.
version: 1.0.0
---

# Arness Infra Deploy

Execute infrastructure deployment to a target environment with environment promotion enforcement, CI/CD pipeline awareness, cost gates, safety layers, and post-deployment resource tracking. This skill orchestrates the actual apply/deploy step, producing handoff files with secret references and updating the issue lifecycle.

This skill is expertise-adaptive: beginner users deploy via platform CLI commands (`fly deploy`, `railway up`), while intermediate and expert users deploy via IaC tools (`tofu apply`, `pulumi up`). All experience levels receive the same safety protections.

## Prerequisites

Read `## Arness` from the project's CLAUDE.md. If no `## Arness` section exists or Arness Infra fields are missing, inform the user: "Arness Infra is not configured for this project yet. Run `/arn-infra-wizard` to get started — it will set everything up automatically." Do not proceed without it.

Extract:
- **Deferred** -- if `yes`, inform the user that infrastructure is deferred and suggest running `/arn-infra-assess` first. Stop.
- **Experience level** -- derived from user profile. Read `~/.arness/user-profile.yaml` (or `.claude/arness-profile.local.md` if it exists — project override takes precedence). Apply the experience derivation mapping from `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-ensure-config/references/experience-derivation.md`. If no profile exists, check for legacy `Experience level` in `## Arness` as fallback.
- **Providers** -- which cloud providers are configured
- **Providers config** -- path to `providers.md` for per-provider details and IaC tool overrides
- **Default IaC tool** -- the default IaC tool to use when no per-provider override exists
- **Environments** -- environment names in promotion order
- **Environments config** -- path to `environments.md` for promotion pipeline and deployment state
- **Tooling manifest** -- path to `tooling-manifest.json` for tool availability checks
- **Resource manifest** -- path to `active-resources.json` for resource tracking
- **Cost threshold** -- monthly budget limit for cost gate warnings
- **Validation ceiling** -- maximum validation level before requiring explicit approval
- **Platform** -- for issue label management
- **Issue tracker** -- for issue lifecycle transitions
- **Infra specs directory** -- from `## Arness` config, for locating INFRA spec and handoff files (default: `.arness/infra-specs`)

Read the provider configuration:

```
Read <providers-config-path>
```

Read the environment configuration:

```
Read <environments-config-path>
```

---

## Workflow

### Step 1: Determine Target Environment and Promotion Validation

Ask the user which environment they want to deploy to (if not already specified in the invocation):

"Which environment would you like to deploy to? [list environments from config in promotion order]"

**Environment promotion enforcement:**

Read the promotion pipeline from `environments.md`. Enforce the following rules:

1. **No skipping stages:** If the promotion pipeline is `dev --> staging --> production`, the user cannot deploy directly to production unless staging has been deployed and verified. Check the `Last deployed` field for each environment in the pipeline.

2. **Refuse direct-to-prod when staging exists:** If the promotion pipeline includes a staging environment and the user requests deployment to production:
   - Check if staging has been deployed (has a `Last deployed` timestamp)
   - Check if staging has been verified (has `arn-infra-verified` label or `lastVerified` in resource manifest)
   - If staging has NOT been deployed or verified: refuse with "Production deployment requires staging to be deployed and verified first. Run `/arn-infra-deploy` targeting staging, then `/arn-infra-verify` to validate it."
   - If staging IS verified: proceed with production deployment

3. **First deployment to any environment is allowed:** If no environment in the pipeline has been deployed yet, allow deployment to the first environment in the pipeline (typically dev or staging).

---

### Step 2: CI/CD Enforcement

Check whether CI/CD pipelines exist for the target environment.

Scan for pipeline configurations:
- `.github/workflows/` -- GitHub Actions
- `.gitlab-ci.yml` -- GitLab CI
- `bitbucket-pipelines.yml` -- Bitbucket Pipelines

**If pipelines exist AND the target is staging or production:**

Warn: "I detected CI/CD pipelines in this project. For staging and production deployments, CI/CD is the recommended deployment method -- it ensures reproducibility, audit trails, and team visibility."

Ask (using `AskUserQuestion`):

**"How would you like to deploy?"**

Options:
1. **Use CI/CD** -- Trigger the pipeline (I will help you push and monitor)
2. **Deploy locally** -- Proceed with local deployment (not recommended for staging/prod)
3. **Cancel** -- Do not deploy

If the user chooses CI/CD: help them trigger the pipeline (e.g., `git push`, `gh workflow run`) and monitor the deployment. Skip to Step 8 for post-deployment tracking.

If the user chooses local deployment: proceed with a warning logged and continue to Step 3.

**If no pipelines exist OR the target is dev:**
Continue to Step 3 without CI/CD enforcement.

---

### Step 3: Pre-Deployment Safety Checklist

> Read the local override or plugin default for `deployment-safety-checklist.md`.

Run the pre-deployment safety checklist. For each gate:

1. **IaC validation:** Has the IaC been validated? Check if `arn-infra-define` has been run and the validation ladder passed. If not, suggest running `/arn-infra-define` first.

2. **Security scan:** Has a security scan been performed? (Level 2 validation). If the validation ceiling is >= 2 and no scan has been run, warn.

3. **Cost estimation:** Has a cost estimate been produced? Compare against the cost threshold. If the estimate exceeds the threshold, present a cost gate warning requiring explicit acknowledgment.

4. **State lock check:** For IaC tools that support state locking (OpenTofu, Terraform, Pulumi), verify that the state is not locked by another deployment. If locked, warn and ask whether to wait or force-unlock.

5. **Rollback plan:** Ensure a rollback strategy exists. Load the rollback patterns reference:

   > Read the local override or plugin default for `rollback-patterns.md`.

6. **Pending changes diff:** Show the user what will change compared to the current deployed state. For IaC tools, use plan/preview output and save the plan file for exact apply:
   - OpenTofu: `tofu plan -var-file=environments/<env>.tfvars -out=deploy.tfplan`
   - Terraform: `terraform plan -var-file=environments/<env>.tfvars -out=deploy.tfplan`
   - For PaaS, show config diffs.

**CDK users:** The deployment will use `--require-approval never` because CDK does not support saved plan files. The safety checklist above replaces CDK's built-in approval prompt.

Present the checklist results:

"**Pre-deployment checklist for [environment]:**
- [ ] IaC validated: [status]
- [ ] Security scan: [status]
- [ ] Cost estimate: [$X/month] vs threshold [$Y/month] -- [PASS/EXCEEDED]
- [ ] State lock: [free/locked]
- [ ] Rollback plan: [available/not available]
- [ ] Changes: [summary of resources to create/modify/destroy]

Proceed with deployment?"

**User confirmation is required for ALL deployments.** Never auto-deploy.

---

### Step 4: Execute Deployment

Based on the experience level and provider configuration, execute the deployment.

**Beginner path (platform CLI):**

Map the provider to the appropriate deploy command:
- Fly.io: `fly deploy --app <app-name> [--env <environment>]`
- Railway: `railway up [--environment <environment>]`
- Render: deploy via dashboard or `render deploy` (if CLI available)
- Vercel: `vercel --prod` (production) or `vercel` (preview)
- Netlify: `netlify deploy --prod` (production) or `netlify deploy` (draft)

Run the command and stream output to the user.

**Intermediate / Expert path (IaC tool):**

Map the IaC tool to the appropriate apply command:

| IaC Tool | Apply Command |
|----------|---------------|
| OpenTofu | `tofu apply deploy.tfplan` |
| Terraform | `terraform apply deploy.tfplan` |
| Pulumi | `pulumi up --stack <env> --yes` |
| CDK | `cdk deploy --context env=<env> --require-approval never` |
| Bicep | `az deployment group create --resource-group <rg> --template-file main.bicep --parameters @<env>.parameters.json` |
| kubectl | `kubectl apply -k environments/<env>/` or `kubectl apply -f <manifests>` |
| Helm | `helm upgrade --install <release> <chart> -f values-<env>.yaml --namespace <env>` |

**Important:** For OpenTofu/Terraform, the saved plan file (`deploy.tfplan`) from Step 3's pending changes diff is applied directly. This guarantees the user approves exactly what gets deployed, eliminating plan-apply drift. No `-auto-approve` flag is needed — saved plan files apply without prompting. For Pulumi and CDK, `--yes`/`--require-approval never` flags are used because these tools do not support saved plan files; the user has already confirmed in Step 3.

**Ephemeral deployments (environments with a TTL):**
Before executing, set a TTL for the deployment:

Ask: "This is an ephemeral deployment. How long should these resources live? (e.g., 2h, 24h, 7d)"

Record the TTL. After deployment:
1. Add TTL metadata to the resource manifest (`active-resources.json`)
2. Create a cleanup issue with the `arn-infra-cleanup` label:
   - Title: "Cleanup: [environment] ephemeral deployment (expires [TTL expiry time])"
   - Body: resource list, TTL expiry, cost estimate, destroy commands

**Persistent deployments (long-lived environments):**
Execute with state locking enabled. Ensure the state backend is configured for team collaboration (remote state in S3, GCS, Azure Blob, Pulumi Cloud, etc.).

---

### Step 5: Monitor Deployment Progress

Stream deployment output and monitor for errors.

**Success indicators by tool:**
- OpenTofu/Terraform: "Apply complete! Resources: N added, N changed, N destroyed."
- Pulumi: "update complete" with resource summary
- CDK: "Stack ARN" output with deployment status
- Fly.io: "deployed successfully" or "Monitoring deployment" with health check pass
- Railway: deployment status showing "active"
- Vercel: deployment URL with "Ready" status
- Netlify: "Deploy is live!" with URL

**If deployment fails:**
1. Capture the error output
2. Categorize the failure (authentication, quota, permission, resource conflict, timeout, network)
3. Present the error with remediation suggestions
4. Ask (using `AskUserQuestion`):

   **"Deployment failed. What would you like to do?"**

   Options:
   1. **Retry** -- Retry the deployment
   2. **Rollback** -- Execute rollback using the patterns from the rollback reference
   3. **Cancel** -- Stop and leave current state
5. Update issue label to `arn-infra-failed` if issue tracking is configured
6. Skip to Step 8 to record the failure

**If deployment shows no progress for 30 minutes:** Present: "Deployment appears to be stalled -- no progress for 30 minutes." Offer options: continue waiting / cancel the deployment / investigate the stuck resource.

---

### Step 6: Update Resource Manifest

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-deploy/references/resource-manifest-schema.md` for the `active-resources.json` schema.

After successful deployment, update `active-resources.json` (path from `## Arness` Resource manifest field):

For each deployed resource, record:
- Resource ID (provider-specific)
- Resource type (compute, database, storage, network, etc.)
- Provider
- Environment
- Region
- Created timestamp
- TTL (if ephemeral)
- Cost estimate (monthly)
- IaC tool and state file location
- Tags

If `active-resources.json` does not exist, create it with the initial resource entries.

---

### Step 7: Generate Infrastructure Handoff File

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-deploy/references/infra-handoff-template.md` for the handoff file template.

Generate `INFRA_HANDOFF_<environment>.md` in the `Infra specs directory` (from `## Arness` config, default: `.arness/infra-specs`).

Generate the handoff file using the template from the reference. The handoff includes deployment summary, endpoints, connection strings, environment variables, access instructions, monitoring endpoints, and rollback procedures.

**CRITICAL SECURITY RULE:** Handoff files must NEVER contain raw secret values. All connection strings, passwords, tokens, and API keys must be referenced by their storage location (secret manager ARN, Vault path, environment variable name, platform secret reference). This is non-negotiable.

---

### Step 8: Update Issue Tracker and Environments Config

**Update issue labels (if issue tracking is configured):**

On successful deployment:
- **Staging:** Add label `arn-infra-staging`
- **Production:** Add label `arn-infra-production`
- Remove any `arn-infra-failed` label from previous attempts

On failed deployment:
- Add label `arn-infra-failed`
- Add a comment with the error summary and remediation steps

**Update environments.md:**

Update the target environment entry in `environments.md`:
- **Last deployed:** [current ISO 8601 timestamp]
- **Pending changes:** none (or list remaining changes if partial deployment)

---

### Step 9: Summarize and Recommend Next Steps

Present the deployment summary:

"**Deployment Summary:**
- **Environment:** [name]
- **Provider:** [provider(s)]
- **Status:** [SUCCESS / FAILED / PARTIAL]
- **Resources:** [N created, N modified, N destroyed]
- **Cost estimate:** [$X/month]
- **Handoff file:** [path to INFRA_HANDOFF_<env>.md]
- **TTL:** [expiry time, if ephemeral]

**Files created/modified:**
- [list all files]

**Recommended next steps:**

1. **Verify deployment:** Run `/arn-infra-verify` to validate health checks, DNS, SSL, and resource state
2. **Set up CI/CD:** Run `/arn-infra-pipeline` to automate future deployments
3. **Promote to next environment:** Run `/arn-infra-deploy` targeting [next environment]
4. **Monitor:** Run `/arn-infra-monitor` to set up observability

Or run `/arn-infra-wizard` for the full guided pipeline."

---

## Error Handling

- **`## Arness` config missing:** Suggest running `/arn-infra-wizard` to get started. Stop.
- **Infrastructure deferred (`Deferred: yes`):** Inform the user that infrastructure is deferred. Suggest running `/arn-infra-assess` to produce a full infrastructure plan first, then `/arn-infra-define` to generate IaC, then re-running deploy. Stop.
- **No IaC code found:** Suggest running `/arn-infra-define` to generate infrastructure code before deploying. Stop.
- **No providers configured:** Suggest running `/arn-infra-init` to configure providers. Stop.
- **Required IaC tool not installed:** Warn about the missing tool. Suggest running `/arn-infra-discover` to check and install required tools. Stop.
- **Cloud credentials expired or invalid:** Present the specific authentication error. Suggest re-authenticating with the provider-specific command (`aws sso login`, `gcloud auth login`, `az login`, `fly auth login`, etc.) and retrying. Do not retry automatically. Stop.
- **State lock held by another process:** Present the lock details (who, when, operation). Offer to wait (poll every 30 seconds) or force-unlock (with a warning about potential state corruption). Never force-unlock without explicit user confirmation.
- **Cost threshold exceeded:** Present the cost estimate with a clear warning. Require explicit user acknowledgment before proceeding. Suggest cost-reduction alternatives (smaller instances, reserved pricing, PaaS migration, environment cleanup).
- **Deployment fails mid-apply:** Capture error output, present remediation suggestions, and offer retry/rollback/cancel. Update issue with `arn-infra-failed` label. The state file reflects the partial state -- subsequent applies will reconcile.
- **Rollback fails:** Present the rollback error. Suggest manual intervention with the specific CLI commands to run. Do not attempt automated recovery from a failed rollback.
- **Handoff file write fails:** Print the handoff content in the conversation so the user can save it manually. Warn about the failure.
- **Issue tracker unavailable:** Skip label updates and issue creation. Log the deployment in environments.md only.
- **environments.md missing:** Create it with the current deployment as the first entry. Warn that the promotion pipeline is not configured and suggest running `/arn-infra-init` to set it up.
- **Re-running is safe:** Re-running updates the resource manifest and environments.md. IaC tools are idempotent -- re-applying the same configuration is a no-op. Handoff files are overwritten with current state.
