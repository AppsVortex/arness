---
name: arn-infra-env
description: >-
  This skill should be used when the user says "manage environments", "arn infra env",
  "infra env", "environment setup", "configure environments", "set up staging",
  "set up production", "environment management", "create environment",
  "environment promotion", "promote to staging", "promote to production",
  "environment isolation", "configure dev staging prod",
  "environment-specific config", "tfvars per environment", "arn-infra-env",
  or wants to configure, create, or manage infrastructure environments
  (dev/staging/production) with isolation strategies, variable overrides,
  and promotion rules.
version: 1.0.0
---

# Arness Infra Env

Configure and manage infrastructure environments (dev, staging, production) with provider-specific isolation strategies, environment-specific variable overrides, resource sizing, and promotion rules. This skill generates environment-specific IaC configurations and updates the environment promotion pipeline.

This skill is expertise-adaptive: beginner users get simplified environment setups with opinionated defaults, while expert users have full control over isolation strategies and promotion configurations.

## Prerequisites

Read `## Arness` from the project's CLAUDE.md. If no `## Arness` section exists or Arness Infra fields are missing, inform the user: "Arness Infra is not configured for this project yet. Run `/arn-infra-wizard` to get started — it will set everything up automatically." Do not proceed without it.

Check the **Deferred** field. If `Deferred: yes`, inform the user: "Infrastructure is in deferred mode. Environment management is not available until infrastructure is fully configured. Run `/arn-infra-assess` to un-defer." Stop.

Extract:
- **Experience level** -- derived from user profile. Read `~/.arness/user-profile.yaml` (or `.claude/arness-profile.local.md` if it exists — project override takes precedence). Apply the experience derivation mapping from `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-ensure-config/references/experience-derivation.md`. If no profile exists, check for legacy `Experience level` in `## Arness` as fallback.
- **Providers** -- cloud providers in use
- **Providers config** -- path to `providers.md` for per-provider details
- **Default IaC tool** -- the default IaC tool
- **Environments** -- current environment list in promotion order
- **Environments config** -- path to `environments.md`

---

## Workflow

### Step 1: Read Current Environment Configuration

Read the environment configuration:

```
Read <environments-config-path>
```

Extract the current state:
- Promotion pipeline order
- Per-environment settings (auto-deploy, approval required, last deployed, pending changes)

Read the provider configuration:

```
Read <providers-config-path>
```

Extract per-provider scope and IaC tool for environment-specific config generation.

**Present current state:**
"Your current environment pipeline: [env1] --> [env2] --> [env3]

| Environment | Auto-deploy | Approval | Last deployed |
|-------------|-------------|----------|---------------|
[table of environments]"

Ask (using `AskUserQuestion`):

**"What would you like to do?"**

Options:
1. **Full environment setup** -- Run through all environment tasks sequentially
2. **Specific task** -- Choose a specific environment task

If **Full environment setup**: proceed through Steps 2-5 sequentially, pausing for user confirmation at each decision point.

If **Specific task**:

Ask (using `AskUserQuestion`):

**"Which task?"**

Options:
1. **Add environment** -- Add a new environment to the pipeline
2. **Configure environment** -- Set up isolation, variables, and sizing
3. **Configure promotion** -- Set up or update promotion rules between environments
4. **Generate configs** -- Generate environment-specific IaC configurations

Route each specific task to its corresponding step: Add environment maps to Step 2, Configure environment maps to Step 3, Configure promotion maps to Step 5, Generate configs maps to Step 4.

---

### Step 2: Environment Isolation Strategy

> Read the local override or plugin default for `environment-patterns.md`.

For each provider, recommend an isolation strategy based on experience level:

**Expert:**
Present all isolation options with trade-offs and let the user choose:

Ask (using `AskUserQuestion`):

**"For [provider], choose your isolation strategy:"**

Options:
1. **Account/project separation** -- Strongest isolation, separate billing, higher overhead
2. **VPC/network separation** -- Good isolation within same account, shared billing
3. **Namespace separation** -- Lightweight, shared resources, weakest isolation
4. **Resource naming** -- Minimal isolation, environments share everything

**Intermediate:**
Present the recommended option with a brief alternative:
"For [provider], I recommend [strategy] because [rationale]. An alternative would be [other option] which trades [trade-off]."

**Beginner:**
Make the recommendation directly:
"For [provider], I'll use [simplest appropriate strategy]. This gives you separate environments without extra complexity."

---

### Step 3: Environment-Specific Variables and Sizing

For each environment, configure:

**Variable overrides:**
- Instance sizes (e.g., `t3.micro` for dev, `t3.medium` for staging, `t3.large` for prod)
- Replica counts (e.g., 1 for dev, 2 for staging, 3 for prod)
- Database tiers (e.g., `db.t3.micro` for dev, `db.r6g.large` for prod)
- Feature flags (e.g., debug mode on for dev, off for prod)
- Domain names and URLs per environment
- Log levels and retention periods

**Resource sizing guidance per experience level:**

**Expert:** Ask for specific resource specifications per environment.

**Intermediate:** Suggest a sizing matrix and ask for approval:
"Here's a recommended sizing matrix:
| Resource | Dev | Staging | Prod |
|----------|-----|---------|------|
| Compute | [small] | [medium] | [large] |
| Database | [small] | [medium] | [large] |
| Replicas | 1 | 2 | 3 |
Adjust as needed."

**Beginner:** Apply defaults automatically:
"I'll use small resources for dev, medium for staging, and appropriately sized resources for production. This keeps costs low during development."

---

### Step 4: Generate Environment-Specific IaC Configurations

Based on the IaC tool, generate environment-specific configuration files:

| IaC Tool | Config Format | Example |
|----------|--------------|---------|
| OpenTofu / Terraform | `environments/<env>.tfvars` | `instance_type = "t3.small"` |
| Pulumi | `Pulumi.<env>.yaml` stack config | `config: app:instanceType: t3.small` |
| CDK | Environment props in `cdk.json` or separate env file | `{ "env": { "account": "...", "region": "..." } }` |
| Bicep | `environments/<env>.parameters.json` | `{ "parameters": { "instanceType": { "value": "..." } } }` |
| Kubernetes | `environments/<env>/kustomization.yaml` or `values-<env>.yaml` | Kustomize overlays or Helm value overrides |
| PaaS (none) | Platform-native env config | Environment-specific sections in `fly.toml`, `vercel.json` |

Invoke the `arn-infra-specialist` agent via the Task tool with:

--- ENVIRONMENT CONTEXT ---
Environments: [list in promotion order]
[For each environment:]
Environment: [name]
Isolation strategy: [strategy]
Variable overrides: [key-value pairs]
Resource sizing: [specifications]
--- END ENVIRONMENT CONTEXT ---

--- PROVIDER CONFIGURATION ---
[For each provider:]
Provider: [name]
IaC tool: [tool]
Scope: [components]
--- END PROVIDER CONFIGURATION ---

--- INFRASTRUCTURE CONFIG ---
Experience level: [derived from user profile]
--- END INFRASTRUCTURE CONFIG ---

--- INSTRUCTIONS ---
Generate environment-specific configuration files for each environment and provider combination.

For each environment:
1. Generate the appropriate config file format for the IaC tool
2. Include all variable overrides (instance sizes, replicas, domains, feature flags)
3. Include environment-specific tags/labels for resource identification
4. Reference shared modules/resources -- environments differ only in configuration values

Follow these rules:
- Adapt comment verbosity and configuration complexity to the experience level
- Never hardcode secrets in config files -- use variable references or secret manager
- Include comments explaining environment-specific choices
- For the production environment, include higher-availability settings (multi-AZ, auto-scaling)
- For development, optimize for cost (smallest viable resources, single-AZ)
--- END INSTRUCTIONS ---

---

### Step 5: Configure Promotion Rules

> Read the local override or plugin default for `promotion-patterns.md`.

Configure the promotion pipeline between environments:

**Default promotion rules:**
- **Dev** --> Auto-deploy on merge to development branch
- **Staging** --> Manual trigger (or auto-deploy on merge to main)
- **Production** --> Manual trigger with approval gate

For each promotion step, configure:
- Trigger method (auto-deploy, manual trigger, scheduled)
- Approval requirements (none, single reviewer, team approval)
- Deployment strategy (rolling update, blue-green, canary)
- Rollback policy (auto-rollback on health check failure, manual rollback)

**Expert:** Present all strategy options and let the user choose per transition.

**Intermediate:** Recommend rolling updates with manual approval for production:
"I recommend auto-deploying to staging on merge, with manual approval and rolling updates for production. Would you like to adjust?"

**Beginner:** Apply safe defaults:
"I'll set up auto-deploy to staging when you merge code, and manual approval before deploying to production. This gives you a safety net."

---

### Step 6: Update Configuration

Update `environments.md` with the configured environments:

```markdown
# Environments

## Promotion Pipeline
[env1] --> [env2] --> [env3]

## [environment-name]
- **Isolation:** [strategy]
- **Auto-deploy:** [yes | no]
- **Approval required:** [yes | no]
- **Deploy strategy:** [rolling | blue-green | canary]
- **Rollback policy:** [auto | manual]
- **Last deployed:** --
- **Pending changes:** none
```

Update `## Arness` in CLAUDE.md with the finalized environment list if it has changed:
- Update the **Environments** field with the new comma-separated list

---

### Step 7: Present Summary and Next Steps

**Environment Configuration Summary:**
- **Environments:** [list with isolation strategies]
- **Promotion pipeline:** [env1 --> env2 --> env3]
- **Config files created:** [list with paths]
- **Promotion rules:** [summary per transition]

**Recommended next steps:**

"Environments are configured. Here is the recommended path:

1. **Set up CI/CD:** Run `/arn-infra-pipeline` to generate environment-aware deployment pipelines
2. **Manage secrets:** Run `/arn-infra-secrets` to configure per-environment secrets
3. **Deploy:** Run `/arn-infra-deploy` to deploy to your first environment

Or run `/arn-infra-wizard` for the full guided pipeline."

---

## Error Handling

- **`## Arness` config missing:** Suggest running `/arn-infra-wizard` to get started. Stop.
- **No providers configured:** Suggest running `/arn-infra-init` to configure providers. Stop.
- **No IaC tool selected:** If the default IaC tool is `none` and no per-provider IaC tools are configured, skip IaC config generation. Inform the user that platform-native environment configurations will be used.
- **Specialist agent fails:** Report the error. Fall back to generating basic environment config files directly using the loaded reference patterns. Present with a note: "Generated using fallback patterns -- review carefully."
- **Specialist agent returns empty output:** Inform the user and retry with additional context. If retry fails, generate minimal config files with placeholder values.
- **Isolation strategy not supported for provider:** Fall back to the next best option. For example, if separate accounts are not feasible, suggest VPC separation with a note explaining the trade-off.
- **Environment already exists:** Present the existing configuration and offer to update it. Do not create duplicates.
- **Re-running is safe:** Re-running presents the current state and offers update options. Existing config files are shown in a diff before overwriting. The environments.md file is updated, not duplicated.
