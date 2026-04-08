---
name: arn-infra-discover
description: >-
  This skill should be used when the user says "discover tools", "infra discover",
  "arn infra discover", "arn-infra-discover", "audit tools", "check installed tools",
  "what tools do I have", "scan for MCPs", "check provider tools", "tool discovery",
  "discover infrastructure tools", "check my setup", "infra tooling",
  or wants to audit their installed infrastructure
  tools (MCPs, CLIs, Claude Code plugins), check authentication state, search for
  new official tools online, and produce a tooling manifest for the infrastructure
  workflow.
version: 1.0.0
---

# Arness Infra Discover

Proactively audit installed infrastructure tools (MCPs, CLIs, Claude Code plugins), check authentication state, search online for new official tools, generate installation recommendations, and produce a tooling manifest. This is the second step after `arn-infra-init` -- it ensures the user has the right tools configured before generating infrastructure code.

This skill is proactive: it does not just check what is installed, but actively recommends what should be installed based on the user's provider configuration. It distinguishes between official (first-party from the cloud provider) and community tools, prioritizing official tools in recommendations.

## Prerequisites

Read `## Arness` from the project's CLAUDE.md. If no `## Arness` section exists or Arness Infra fields are missing, inform the user: "Arness Infra is not configured for this project yet. Run `/arn-infra-wizard` to get started — it will set everything up automatically." Do not proceed without it.

Extract:
- **Providers** -- which providers to discover tools for
- **Default IaC tool** -- which IaC tooling to check
- **Experience level** -- derived from user profile. Read `~/.arness/user-profile.yaml` (or `.claude/arness-profile.local.md` if it exists — project override takes precedence). Apply the experience derivation mapping from `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-ensure-config/references/experience-derivation.md`. If no profile exists, check for legacy `Experience level` in `## Arness` as fallback.
- **Tooling manifest** -- path where the manifest will be written

## Workflow

### Phase A: Detect Installed Tools

For each provider in the `Providers` list, check what is already installed.

> Read the local override or plugin default for `mcp-registry.md`.
> Read the local override or plugin default for `cli-registry.md`.
> Read the local override or plugin default for `plugin-registry.md`.

*The three registry files above are evolving references (read from the user's local `.arness/infra-references/` override if it exists, otherwise from the plugin default). The tooling manifest schema referenced in Phase D is a static reference always read directly from the plugin.*

**A.1. MCP Detection:**
- Read the project's `.mcp.json` for configured MCP servers
- Cross-reference with the curated `mcp-registry.md` to identify known provider MCPs
- For each found MCP, record: name, provider, official status, capabilities

**A.2. CLI Detection:**
- For each provider and IaC tool, run detection commands from `cli-registry.md`:
  - Provider CLIs: `aws --version`, `gcloud --version`, `az --version`, `doctl version`, `fly version`, `vercel --version`, `netlify --version`, `railway version`, `scw version`, `wrangler --version`
  - IaC CLIs: `tofu --version`, `terraform --version`, `pulumi version`, `cdk --version`
  - Validation tools: `checkov --version`, `trivy --version`, `infracost --version`
  - Security scanners: `trufflehog --version`, `gitleaks version`
- For each found CLI, record: name, version, provider, official status

**A.3. Authentication Check:**
- For each detected CLI, run auth-check commands:
  - AWS: `aws sts get-caller-identity`
  - GCP: `gcloud auth list`
  - Azure: `az account show`
  - DigitalOcean: `doctl account get`
  - Fly.io: `fly auth whoami`
  - Vercel: `vercel whoami`
  - Netlify: `netlify status`
- Record auth status: authenticated | not authenticated | unknown

**A.4. Terraform License Check:**
- If `terraform` is found without `tofu`: flag the BSL licensing issue and recommend OpenTofu migration
- If both `terraform` and `tofu` are found: note both, recommend using `tofu`

**A.5. Plugin Detection:**
- Check for known Claude Code provider plugins from `plugin-registry.md`
- Record: name, provider, official status, installed status

---

### Phase B: Online Check for New Official Tools (WebSearch)

For each provider in the user's configuration, use WebSearch to check for:

1. **Official MCP servers** not in the curated registry:
   - Search: `"[provider]" official MCP server "Claude Code"` or `"[provider]" MCP server npm`
2. **Official Claude Code plugins:**
   - Search: `"[provider]" Claude Code plugin official`
3. **New CLIs or CLI updates** with structured output:
   - Search: `"[provider]" CLI latest version features`

**Important constraints:**
- Focus exclusively on **official, first-party tools** from the cloud provider themselves
- Do not recommend community or third-party tools in this phase
- Cross-reference findings with Phase A results to avoid duplicates
- If a new official tool is found not in the curated registry, flag it as a new discovery

---

### Phase C: Proactive Installation Recommendations

Compare what is installed (Phase A) with what is available (registries + Phase B) to produce recommendations.

For each tool category (MCP, CLI, Plugin, IaC, Validation) relevant to the user's providers:

**MCPs not installed:**
"The official [Provider] MCP server is available but not configured. It enables [capabilities]. Install: `[install command]` and add to `.mcp.json`:"
```json
{
  "[provider]-mcp": {
    "command": "[command]",
    "args": ["[args]"]
  }
}
```
Offer to auto-add to `.mcp.json` with user approval.

**CLIs not installed:**
"The official [Provider] CLI (`[binary]`) is not installed. It enables [capabilities]. Install: `[install command for user's OS]`."

**Claude Code plugins not installed:**
"The official [Provider] Claude Code plugin (`[plugin-name]`) is available. It handles [operations] and Arness Infra can delegate to it."

**IaC/validation tools not installed:**
Same pattern -- detect what is missing from the chosen workflow, recommend with install commands.

**Priority tagging:**
- **Required:** Blocks a workflow step (e.g., `tofu` binary missing when IaC tool is `opentofu`)
- **Recommended:** Significantly improves the workflow (e.g., official MCP available, security scanner)
- **Optional:** Nice-to-have enhancement (e.g., Infracost for cost estimation)

For tools tagged **Required**, warn: "Without [tool], Arness Infra cannot perform [operation]. Install it before proceeding."

---

### Phase D: Produce Tooling Manifest and Present Summary

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-discover/references/tooling-manifest-schema.md` for the manifest JSON schema.

**D.1. Write tooling manifest:**
Write `tooling-manifest.json` to the path configured in `## Arness` (default: `.arness/infra/tooling-manifest.json`).

The manifest includes:
- **Installed tools** per provider with confidence ratings
- **Recommended tools** not yet installed with install commands and priority

**Confidence ratings** per provider:
- **A:** Official MCP + CLI + authenticated
- **B:** CLI + authenticated (no MCP)
- **C:** CLI installed but not authenticated
- **D:** No direct tooling (config generation only)

**Exception:** If an official Claude Code plugin is installed for a provider, the confidence is at least B regardless of other tooling.

**D.2. Present summary to the user in two sections.**

Adapt output detail to experience level:

- **Expert:** Show raw version details, CLI paths, and configuration snippets.
- **Intermediate:** Show tool names, versions, and brief usage notes.
- **Beginner:** Show simplified output with plain-language explanations of what each tool does and why it matters.



**Section 1: Installed and Ready**

| Tool | Type | Provider | Version | Auth Status | Official |
|------|------|----------|---------|-------------|----------|
| ... | MCP/CLI/Plugin | ... | ... | Yes/No | Yes/No |

**Section 2: Recommended Installations**

| Tool | Type | Provider | Official | Priority | Install Command | What It Enables |
|------|------|----------|----------|----------|-----------------|-----------------|
| ... | MCP/CLI/Plugin | ... | Yes/No | Required/Recommended/Optional | ... | ... |

**D.3. Show per-provider confidence:**

| Provider | Confidence | Reason |
|----------|------------|--------|
| aws | A | Official MCP + AWS CLI authenticated |
| vercel | B | Vercel CLI authenticated, no MCP |
| ... | ... | ... |

**D.4. Auto-configure MCP offers:**
For each recommended MCP:

Ask (using `AskUserQuestion`):

**"Would you like me to add the [Provider] MCP to your `.mcp.json`?"**

Options:
1. **Yes** -- Add the MCP configuration entry
2. **No** -- Skip this MCP

If approved, add the MCP configuration entry to the project's `.mcp.json`.

**D.5. Update providers.md:**
Update each provider's `Confidence` rating in `.arness/infra/providers.md` based on the discovery results.

---

## Error Handling

- **`## Arness` config missing:** Suggest running `/arn-infra-wizard` to get started. Stop.
- **CLI detection command fails:** Record the tool as "not installed." Do not crash on individual detection failures.
- **Auth check fails:** Record as "not authenticated." Suggest the auth command (e.g., `aws configure`, `gcloud auth login`).
- **WebSearch unavailable:** Skip Phase B. Note in the summary: "Online check skipped -- WebSearch not available. Results are based on curated registries only."
- **`.mcp.json` does not exist:** Create it if the user approves an MCP auto-add. Start with `{}`.
- **Tooling manifest path does not exist:** Create the directory: `mkdir -p` the parent path.
- **All tools missing for a provider:** Lower the confidence to D and strongly recommend at least the CLI. If the user is a beginner, suggest switching to a PaaS provider with simpler tooling.
- **Re-running is safe:** Discovery overwrites the tooling manifest with current state. No data is lost.
