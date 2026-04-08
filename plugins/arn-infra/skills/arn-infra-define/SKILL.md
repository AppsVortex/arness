---
name: arn-infra-define
description: >-
  This skill should be used when the user says "define infrastructure", "generate IaC",
  "infra define", "arn infra define", "generate terraform", "generate opentofu",
  "generate pulumi", "generate cdk", "generate bicep", "create kubernetes manifests",
  "provision cloud resources", "create IaC", "infrastructure as code", or wants to
  generate infrastructure-as-code in their chosen IaC tool for configured cloud
  provider(s). It produces provider-specific infrastructure code, validates it
  through a multi-level validation ladder, and writes an infrastructure architecture
  spec.
version: 1.0.0
---

# Arness Infra Define

Generate infrastructure-as-code in the user's chosen IaC tool for their configured cloud provider(s). This is the central skill in the Arness Infra pipeline -- it reads the project's infrastructure configuration, resolves the application context, generates per-provider IaC code, validates it through a multi-level validation ladder, and produces an infrastructure architecture specification.

This skill is expertise-adaptive: beginner users receive platform-native configurations (e.g., `fly.toml`, `vercel.json`) instead of full IaC. Intermediate and expert users receive IaC in their chosen tool (OpenTofu, Pulumi, CDK, Bicep, kubectl/Helm).

If a triage implications brief exists (from `arn-infra-triage`), this skill uses it as the primary input for infrastructure decisions, skipping redundant codebase analysis.

## Prerequisites

Read the `## Arness` section from the project's CLAUDE.md. If no `## Arness` section exists or Arness Infra fields are missing, inform the user: "Arness Infra is not configured for this project yet. Run `/arn-infra-wizard` to get started — it will set everything up automatically." Do not proceed without it.

Extract:
- **Deferred** -- if `yes`, inform the user that infrastructure is deferred and suggest running `/arn-infra-assess` first
- **Experience level** -- derived from user profile. Read `~/.arness/user-profile.yaml` (or `.claude/arness-profile.local.md` if it exists — project override takes precedence). Apply the experience derivation mapping from `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-ensure-config/references/experience-derivation.md`. If no profile exists, check for legacy `Experience level` in `## Arness` as fallback.
- **Providers** -- which cloud providers to generate IaC for
- **Providers config** -- path to `providers.md` for per-provider scope and IaC tool overrides
- **Default IaC tool** -- the default IaC tool to use when no per-provider override exists
- **Environments** -- environment names (for environment-specific configurations)
- **Environments config** -- path to `environments.md`
- **Tooling manifest** -- path to `tooling-manifest.json` for tool availability checks
- **Cost threshold** -- monthly budget limit for cost gate warnings
- **Validation ceiling** -- maximum validation level before requiring explicit approval
- **Infra plans directory** -- from `## Arness` config, for locating triage briefs (default: `.arness/infra-plans`)
- **Infra specs directory** -- from `## Arness` config, for writing the INFRA spec (default: `.arness/infra-specs`)

---

## Workflow

### Step 1: Read Provider and Tooling Configuration

Read the provider configuration:

> Read `<providers-config-path>`

For each provider, extract:
- Provider name and scope (which application components it serves)
- IaC tool override (or use the default)
- Status (active, inactive, migrating)
- Migration notes (if any)

Read the environment configuration:

> Read <environments-config-path>

For each environment, extract: environment name, purpose, promotion order, and environment-specific sizing or feature flags.

Read the tooling manifest:

> Read `<tooling-manifest-path>`

Check tool readiness for each provider's IaC tool:
- Is the IaC binary installed? (e.g., `tofu`, `pulumi`, `cdk`)
- Is the provider CLI installed and authenticated?
- Are validation tools available? (e.g., `checkov`, `trivy`, `infracost`)

**If a required IaC tool is missing:**
Warn: "The IaC tool `[tool]` is not installed. Arness Infra cannot generate or validate `[tool]` code without it. Run `/arn-infra-discover` to check and install required tools."
Ask whether to continue (generate code that cannot be locally validated) or stop.

---

### Step 2: Check for Triage Brief

Check for an existing triage implications brief in the infra plans directory:

```
Glob <infra-plans-dir>/**/triage-brief*.md
Glob <infra-plans-dir>/**/implications-brief*.md
```

**If a triage brief exists:**
Read the brief. Extract infrastructure implications, resource requirements, and architectural decisions. Present: "I found a triage brief with infrastructure implications. Using it as the primary input for infrastructure generation."
Skip Step 3 (application context resolution) -- the triage brief already contains the analyzed requirements.

**If no triage brief exists:**
Continue to Step 3 for full application context resolution.

---

### Step 3: Resolve Application Context

Resolve the application's architecture, services, and resource requirements. This step is skipped if a triage brief was found in Step 2.

Read the `Project topology` from `## Arness`:

**Monorepo:**
- Read `code-patterns.md` and `architecture.md` from the code patterns directory (path from `## Arness` config)
- Scan for application entry points, services, databases, caches, and external dependencies
- Map application components to infrastructure resources

**Separate repo:**
- Navigate to `Application path` and read the application's `## Arness` config, patterns, and architecture
- If unreachable, ask the user to describe the application stack manually

**Infra-only:**
- Ask the user to describe: services, databases, caches, networking requirements, expected traffic patterns
- Record the user-provided context for IaC generation

---

### Step 4: Determine Generation Strategy

Based on experience level and provider configuration, determine what to generate.

**Beginner path (Experience level: beginner):**
Generate platform-native configurations instead of IaC. Load the PaaS config patterns:

> Read the local override or plugin default for `paas-config-patterns.md`.

Map the user's provider to the appropriate config format:
- Fly.io --> `fly.toml`
- Railway --> `railway.json`
- Render --> `render.yaml`
- Vercel --> `vercel.json`
- Netlify --> `netlify.toml`

If the beginner has chosen an IaC-required provider (AWS, GCP, Azure), suggest simpler alternatives or generate simplified IaC with extensive comments.

**Intermediate / Expert path:**
Generate full IaC code. Load the appropriate tool-specific reference:

| IaC Tool | Reference |
|----------|-----------|
| OpenTofu / Terraform | Read the local override or plugin default for `opentofu-patterns.md`. |
| Pulumi | Read the local override or plugin default for `pulumi-patterns.md`. |
| CDK | Read the local override or plugin default for `cdk-patterns.md`. |
| Bicep | Read the local override or plugin default for `bicep-patterns.md`. |
| Kubernetes (kubectl/Helm) | Read the local override or plugin default for `kubernetes-patterns.md`. |

For multi-provider setups:

Ask (using `AskUserQuestion`):

**"You have multiple providers configured: [list]. Which provider(s) would you like to generate IaC for now?"**

Options:
1. **All** -- Generate per-provider IaC in separate directories
2. **Specific provider(s)** -- Choose which providers to generate for

---

### Step 5: Invoke Specialist Agent for IaC Generation

Invoke the `arn-infra-specialist` agent via the Task tool with:

--- APPLICATION CONTEXT ---
[Application architecture from Step 3, or triage brief content from Step 2]
Services: [list of services with roles]
Databases: [required databases and their types]
Caches: [required caching layers]
External services: [third-party integrations, APIs]
Traffic patterns: [expected request volume, scaling requirements]
--- END APPLICATION CONTEXT ---

--- PROVIDER CONFIGURATION ---
[For each provider being generated:]
Provider: [name]
Scope: [which components this provider handles]
IaC tool: [tool name]
[Tool-specific patterns from the loaded reference file]
--- END PROVIDER CONFIGURATION ---

--- ENVIRONMENT CONFIGURATION ---
Environments: [from environments config]
Promotion pipeline: [env1 --> env2 --> env3]
--- END ENVIRONMENT CONFIGURATION ---

--- INFRASTRUCTURE CONFIG ---
Experience level: [derived from user profile]
Validation ceiling: [from ## Arness]
Cost threshold: [from ## Arness]
--- END INFRASTRUCTURE CONFIG ---

--- INSTRUCTIONS ---
Generate infrastructure code for the specified provider(s) and IaC tool(s).

For each provider, generate:
1. Resource definitions for all required infrastructure (compute, storage, networking, databases, caches)
2. Environment-specific configurations (variable files per environment)
3. State backend configuration (remote state for team collaboration)
4. Variable definitions with descriptions and validation rules
5. Output definitions for key resource attributes (endpoints, IDs, connection strings)

Follow these rules:
- Never hardcode secrets or credentials -- use variable references or secret manager
- Include resource tagging for cost tracking and environment identification
- Generate separate, independently deployable modules per logical group
- Include comments explaining each resource (depth based on experience level)
- For OpenTofu/Terraform: warn about BSL license if Terraform is used
- For multi-provider: keep provider-specific code isolated in separate directories
--- END INSTRUCTIONS ---

---

### Step 6: Run Validation Ladder

Run the validation ladder up to the configured validation ceiling. Each level builds on the previous.

> Read the local override or plugin default for `validation-ladder.md`.

**Level 0 -- Static Analysis (always run):**
- Syntax validation of generated files
- For OpenTofu/Terraform: `tofu validate` or `terraform validate`
- For Pulumi: `pulumi preview --diff` (dry run)
- For CDK: `cdk synth` (synthesize CloudFormation)
- For Bicep: `az bicep build` (compile to ARM)
- For Kubernetes: `kubectl apply --dry-run=client`
- For PaaS configs: schema validation where available

**Level 1 -- Local Validation (if ceiling >= 1):**
- Format checking: `tofu fmt -check`, `pulumi up --preview-only`
- Linting: apply tool-specific linters if available
- Module dependency resolution

**Level 2 -- Security Scan and Cost Estimation (if ceiling >= 2):**
- Run `checkov` or `trivy` on the generated IaC if available
- Invoke the `arn-infra-cost-analyst` agent for cost estimation:

  Invoke the `arn-infra-cost-analyst` agent via the Task tool with:

  --- INFRASTRUCTURE CODE ---
  [generated IaC files]
  --- END INFRASTRUCTURE CODE ---

  --- COST CONTEXT ---
  Provider(s): [list]
  Cost threshold: [from ## Arness]
  Environment: [target environment]
  --- END COST CONTEXT ---

  --- INSTRUCTIONS ---
  Estimate the monthly cost of the defined infrastructure. Compare against the configured
  cost threshold. If the estimate exceeds the threshold, flag as a cost gate warning.
  --- END INSTRUCTIONS ---

**If validation ceiling is reached and user wants to go higher:**
Ask: "The configured validation ceiling is Level [N]. Running Level [N+1] would [describe what it does and any costs]. Would you like to proceed?"
Require explicit approval before exceeding the ceiling.

**If validation fails at any level:**
Present the errors with fix suggestions. Offer to auto-fix and re-validate, or let the user address manually.

---

### Step 7: Write Infrastructure Architecture Spec

Load the spec template:

> Read the local override or plugin default for `infra-architecture-template.md`.

Write `INFRA_<project-name>.md` to the `Infra specs directory` (from `## Arness` config, default: `.arness/infra-specs`).

The spec captures:
- Infrastructure overview and architecture diagram (text-based)
- Cloud resources per provider (compute, storage, networking, databases)
- Network topology and security groups
- Environment configuration and promotion pipeline
- Security considerations (IAM, encryption, network policies)
- Cost estimate summary
- Deployment instructions and prerequisites

---

### Step 8: Present Generated Code for Approval

Present each generated file to the user with the provider and tool context:

"Here is the generated infrastructure code:

**Provider:** [name]
**IaC Tool:** [tool]
**Validation:** Level [N] passed

[For each file:]
**[filename]:**
```[language]
[generated content]
```

**Validation results:** [summary]
**Cost estimate:** [if Level 2+ was run]

Ask (using `AskUserQuestion`):

**"How would you like to proceed with the generated infrastructure code?"**

Options:
1. **Approve and write** -- Write all files to the project
2. **Edit** -- Make changes before writing
3. **Regenerate** -- Adjust the configuration and regenerate
4. **Skip provider** -- Skip this provider (for multi-provider)

---

### Step 9: Write Files and Summarize

Upon user approval, write generated files to the appropriate locations:
- IaC files: project root or a dedicated `infra/` directory
- Environment-specific configs: alongside the IaC files or in an `environments/` subdirectory
- State backend config: with the IaC files

Present the summary:

**Infrastructure Definition Summary:**
- **Providers:** [list with IaC tools used]
- **Files created:** [list with paths]
- **Validation:** Level [N] passed for all providers
- **Cost estimate:** [$amount/month] (if available)
- **Spec written:** [path to INFRA spec]

**Recommended next steps:**

"Infrastructure code is ready. Here is the recommended path:

1. **Review the spec:** Read `[INFRA spec path]` for the full infrastructure architecture overview
2. **Deploy:** Run `/arn-infra-deploy` to deploy to your first environment
3. **Set up CI/CD:** Run `/arn-infra-pipeline` to generate a deployment pipeline
4. **Manage environments:** Run `/arn-infra-env` to configure environment promotion

Or run `/arn-infra-wizard` for the full guided pipeline."

---

## Error Handling

- **`## Arness` config missing:** Suggest running `/arn-infra-wizard` to get started. Stop.
- **Infrastructure deferred (`Deferred: yes`):** Inform the user that infrastructure is deferred. Suggest running `/arn-infra-assess` to produce a full infrastructure plan first, then re-running define.
- **No providers configured:** Suggest running `/arn-infra-init` to configure providers. Stop.
- **Required IaC tool not installed:** Warn about the missing tool. Offer to continue (generate code without local validation) or stop and run `/arn-infra-discover`.
- **Specialist agent fails:** Report the error. Fall back to generating basic IaC directly using the loaded reference patterns. Present with a note: "Generated using fallback patterns -- review carefully before use."
- **Specialist agent returns empty output:** Inform the user and ask for more details about requirements. Retry with additional context.
- **Cost analyst agent fails:** Present the generated code without cost estimation. Warn: "Cost estimation could not be performed. Review the resources manually against your budget before deploying."
- **Validation fails at Level 0 (syntax errors):** Auto-fix if possible, otherwise present errors and ask the user to resolve before proceeding.
- **Validation fails at Level 1+ (semantic errors):** Present errors with fix suggestions. Do not write files until validation passes.
- **Cost threshold exceeded:** Present the cost estimate with a clear warning. Require explicit user acknowledgment before proceeding. Suggest cost-reduction alternatives (smaller instances, reserved pricing, PaaS migration).
- **Multiple providers and one fails:** Complete successful providers, report the failure for the problematic provider. Do not block the entire operation.
- **Triage brief is outdated or references changed requirements:** Note the discrepancy and ask the user whether to proceed with the brief or re-analyze the application context.
- **Provider or environment config file not found:** Warn that the referenced file does not exist. Suggest re-running `/arn-infra-init` to regenerate configuration files. Stop.
- **Re-running is safe:** Re-running regenerates IaC files (after user approval). The INFRA spec is overwritten with the latest state. Existing manually customized IaC files are shown in a diff before overwriting.
