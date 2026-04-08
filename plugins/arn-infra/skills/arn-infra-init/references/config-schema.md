# Arness Infra Config Schema

Full documentation of every infra field in the `## Arness` section of CLAUDE.md.

## Fields

### Deferred
- **Type:** `yes | no`
- **Default:** `no`
- **Set by:** `arn-infra-init` Step 1b
- **Read by:** All skills (check before executing -- if `yes`, most skills are inactive except for deferred backlog accumulation)
- **Description:** When `yes`, only minimal config is written and skills are inactive. Arness Core accumulates infrastructure observations in `.arness/infra/deferred-backlog.md`. When the user un-defers (re-runs init or runs `arn-infra-assess`), the backlog seeds a comprehensive infrastructure assessment.

### Experience level (REMOVED)

Experience level is now derived from the user profile and is no longer stored in `## Arness`. The derivation mapping is documented in `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-ensure-config/references/experience-derivation.md`. All Arness Infra skills and agents read the user profile (`~/.arness/user-profile.yaml` or `.claude/arness-profile.local.md`) and apply the derivation rules at runtime. For backward compatibility, if no user profile exists, skills check for a legacy `Experience level` field in `## Arness` as fallback.

### Project topology
- **Type:** `monorepo | separate-repo | infra-only`
- **Default:** none (must be assessed)
- **Set by:** `arn-infra-init` Step 4
- **Read by:** All skills that resolve application context
- **Description:** How the infrastructure project relates to the application code:
  - **monorepo:** App and infra in the same repository. Application path is `.`
  - **separate-repo:** App and infra in different repositories/folders. Application path points to the app.
  - **infra-only:** Standalone infrastructure project with no application.

### Application path
- **Type:** relative path
- **Default:** `.` for monorepo, omitted for infra-only
- **Set by:** `arn-infra-init` Step 4
- **Read by:** Skills that need application context (`arn-infra-triage`, `arn-infra-assess`, `arn-infra-containerize`, `arn-infra-define`)
- **Description:** Path to the application project root. Used by the `arn-infra-request-analyzer` agent to navigate to Core artifacts.

### Providers
- **Type:** comma-separated list of provider names
- **Default:** none (must be configured)
- **Set by:** `arn-infra-init` Step 3
- **Read by:** All provider-aware skills
- **Description:** Quick-reference list of configured providers (e.g., `aws, vercel, fly`). Detailed per-provider config is in `providers.md`.

### Providers config
- **Type:** relative path
- **Default:** `.arness/infra/providers.md`
- **Set by:** `arn-infra-init` Step 8
- **Read by:** All provider-aware skills
- **Description:** Path to the per-provider configuration file. Each provider entry includes scope, IaC tool, confidence rating, status, and migration state.

### Default IaC tool
- **Type:** `opentofu | terragrunt | pulumi | cdk | bicep | kubectl | terraform | none`
- **Default:** varies by experience level (beginner: `none`, intermediate: `opentofu`, expert: user's choice)
- **Set by:** `arn-infra-init` Step 3
- **Read by:** `arn-infra-define`, `arn-infra-specialist`
- **Description:** Default IaC engine across all providers. Per-provider overrides live in `providers.md`. When set to `none`, platform-native configs are generated (e.g., `fly.toml`, `railway.json`).

### Environments
- **Type:** comma-separated list in promotion order
- **Default:** `staging, prod`
- **Set by:** `arn-infra-init` Step 6
- **Read by:** `arn-infra-deploy`, `arn-infra-pipeline`, `arn-infra-env`
- **Description:** Environment names in promotion order. Deployment flows enforce this order -- changes must promote through each stage.

### Environments config
- **Type:** relative path
- **Default:** `.arness/infra/environments.md`
- **Set by:** `arn-infra-init` Step 8
- **Read by:** `arn-infra-deploy`, `arn-infra-pipeline`, `arn-infra-env`
- **Description:** Path to the per-environment configuration file. Tracks deployment status, promotion state, and pending changes per environment.

### Tooling manifest
- **Type:** relative path
- **Default:** `.arness/infra/tooling-manifest.json`
- **Set by:** `arn-infra-init` Step 8 (path only); populated by `arn-infra-discover`
- **Read by:** `arn-infra-specialist`, `arn-infra-define`, `arn-infra-deploy`, `arn-infra-pipeline`, `arn-infra-monitor`
- **Description:** Path to the tooling manifest JSON. Contains installed tools, confidence ratings, and recommended tools not yet installed.

### Resource manifest
- **Type:** relative path
- **Default:** `.arness/infra/active-resources.json`
- **Set by:** `arn-infra-init` Step 8 (path only); populated by `arn-infra-deploy`
- **Read by:** `arn-infra-verify`, `arn-infra-cleanup`, `arn-infra-cost-analyst`, `arn-infra-monitor`
- **Description:** Path to the active resources manifest. Tracks deployed cloud resources with TTL, cost, and state information.

### Cost threshold
- **Type:** integer (USD) or `none`
- **Default:** beginner: `25`, intermediate: `100`, expert: `500`
- **Set by:** `arn-infra-init` Step 7
- **Read by:** `arn-infra-deploy`, `arn-infra-cost-analyst`, `arn-infra-monitor`
- **Description:** Monthly USD threshold for spend alerts. Deployments that would exceed this threshold require explicit user approval.

### Validation ceiling
- **Type:** integer `0-4`
- **Default:** `2`
- **Set by:** `arn-infra-init` Step 7
- **Read by:** `arn-infra-define`, `arn-infra-deploy`, `arn-infra-pipeline`
- **Description:** Maximum validation level without explicit approval:
  - **0:** Static analysis / syntax validation (`tofu validate`, `cdk synth`, etc.)
  - **1:** Local validation (format check, linting, module dependency resolution)
  - **2:** Security scan + cost estimation (Checkov/Trivy + Infracost)
  - **3:** Cloud dry-run (`tofu plan`, `pulumi preview`, etc.)
  - **4:** Full apply

### Infra plans directory
- **Type:** relative path
- **Default:** `.arness/infra-plans`
- **Set by:** `arn-infra-init` Step 8
- **Read by:** `arn-infra-change-plan`, `arn-infra-save-plan`, `arn-infra-execute-change`, `arn-infra-review-change`, `arn-infra-help`
- **Description:** Directory where infrastructure change plans are stored. Contains `PLAN_PREVIEW_INFRA_*.md` plan previews and structured plan project directories (with `INTRODUCTION.md`, `PHASE_N_PLAN.md`, etc.). This is the infrastructure-specific equivalent of Arness Core's `Plans directory`.
- **Backward Compatibility:** Missing field defaults to `.arness/infra-plans`. Projects initialized before this feature will use the default path automatically.

### Infra specs directory
- **Type:** relative path
- **Default:** `.arness/infra-specs`
- **Set by:** `arn-infra-init` Step 8
- **Read by:** `arn-infra-change-spec`, `arn-infra-change-plan`, `arn-infra-help`
- **Description:** Directory where infrastructure change specifications are stored. Contains `INFRA_CHANGE_*.md` spec files that describe infrastructure changes to be planned and executed. This is the infrastructure-specific equivalent of Arness Core's `Specs directory`.
- **Backward Compatibility:** Missing field defaults to `.arness/infra-specs`. Projects initialized before this feature will use the default path automatically.

### Infra docs directory
- **Type:** relative path
- **Default:** `.arness/infra-docs`
- **Set by:** `arn-infra-init` Step 8
- **Read by:** `arn-infra-document-change`, `arn-infra-help`
- **Description:** Directory where infrastructure documentation artifacts are stored. Contains runbooks, changelogs, architecture decision records, and other documentation produced by the infrastructure change pipeline. This is the infrastructure-specific equivalent of Arness Core's `Docs directory`.
- **Backward Compatibility:** Missing field defaults to `.arness/infra-docs`. Projects initialized before this feature will use the default path automatically.

### Infra report templates
- **Type:** string
- **Default:** `default`
- **Set by:** `arn-infra-init` Step 8
- **Read by:** `arn-infra-save-plan`
- **Description:** Which report template set to use for infrastructure change reports. The `default` set includes infrastructure-specific report templates (change execution reports, review reports, documentation reports) with camelCase JSON fields. Custom template sets can be created in the Infra template path.
- **Backward Compatibility:** Missing field defaults to `default`. Projects initialized before this feature will use the default template set automatically.

### Infra template path
- **Type:** relative path
- **Default:** `.arness/infra-templates`
- **Set by:** `arn-infra-init` Step 8
- **Read by:** `arn-infra-save-plan`
- **Description:** Directory where infrastructure report templates are stored locally. Templates are copied here during init and used by pipeline skills to structure execution reports. This is the infrastructure-specific equivalent of Arness Core's `Template path`.
- **Backward Compatibility:** Missing field defaults to `.arness/infra-templates`. Projects initialized before this feature will use the default path automatically.

### Infra template version
- **Type:** semver string
- **Default:** `<version from plugin.json at time of init>`
- **Set by:** `arn-infra-init` Step 8
- **Read by:** `arn-infra-save-plan`
- **Description:** Plugin version the infrastructure report templates were last synchronized from. Used to detect whether template updates are available when the plugin is updated. Follows the same versioning pattern as Arness Core's `Template version`.
- **Backward Compatibility:** Missing field defaults to the current plugin version. Projects initialized before this feature will get the latest templates on next init update.

### Git
- **Type:** `yes | no`
- **Default:** auto-detected
- **Set by:** `arn-infra-init` Step 5
- **Read by:** Skills that need version control context
- **Description:** Whether the infra project is in a git repository. Auto-detected. In monorepo topology, reuses the existing value if already present in `## Arness` from arn-code-init. In separate-repo topology, detected independently for the infra repo.

### Platform
- **Type:** `github | bitbucket | none`
- **Default:** auto-detected
- **Set by:** `arn-infra-init` Step 5
- **Read by:** label management
- **Description:** Code hosting platform for the infra project. Auto-detected from git remote. This field represents where the code is hosted, NOT the CI/CD system in use. See `CI/CD platform` for CI/CD routing.

### CI/CD platform
- **Type:** `github-actions | gitlab-ci | bitbucket-pipelines | none`
- **Default:** auto-detected
- **Set by:** `arn-infra-init` Step 5
- **Read by:** `arn-infra-pipeline`
- **Description:** CI/CD platform for the infra project. Auto-detected by scanning for CI configuration files (`.github/workflows/`, `.gitlab-ci.yml`, `bitbucket-pipelines.yml`). Independent of the code hosting Platform -- a GitHub-hosted project can use GitLab CI.
- **Backward Compatibility:** Missing field triggers auto-detection. Projects initialized before this field was added will have it detected and written on the next `arn-infra-init` run (Update flow).

### Issue tracker
- **Type:** `github | jira | none`
- **Default:** auto-detected
- **Set by:** `arn-infra-init` Step 5
- **Read by:** `arn-infra-triage`, `arn-infra-assess`, label management
- **Description:** Issue tracking system for the project. In monorepo topology, reuses the existing value if already present from arn-code-init. In separate-repo topology, detected independently for the infra repo.

### Jira site
- **Type:** string (URL)
- **Default:** none
- **Conditional:** Only written when Issue tracker is `jira`
- **Set by:** `arn-infra-init` Step 5
- **Read by:** Skills that interact with Jira
- **Description:** Atlassian site URL (e.g., `mycompany.atlassian.net`).

### Jira project
- **Type:** string (project key)
- **Default:** none
- **Conditional:** Only written when Issue tracker is `jira`
- **Set by:** `arn-infra-init` Step 5
- **Read by:** Skills that interact with Jira
- **Description:** Jira project key (e.g., `INFRA`).

### Reference overrides
- **Type:** relative path
- **Default:** `.arness/infra-references`
- **Set by:** `arn-infra-init` Step 8b
- **Read by:** All skills that load evolving reference files (via the "local override or plugin default" read convention)
- **Description:** Directory where evolving reference files are stored locally. Created during init with copies of all 28 evolving files from the plugin. Skills read from this path first, falling back to plugin defaults if a file is not found. The directory survives plugin updates, allowing user customizations and research-driven updates to persist.

### Reference version
- **Type:** semver string
- **Default:** (plugin version at time of init)
- **Set by:** `arn-infra-init` Step 8b (fresh), Step U1 (upgrade)
- **Read by:** `arn-infra-init` Step U1 (version comparison during upgrade)
- **Description:** Plugin version the reference files were last synchronized from. Used during the Update flow to detect whether the plugin has been updated and new reference file versions are available. When this differs from the current plugin version, the reference upgrade logic in Step U1 is triggered.

### Reference updates
- **Type:** enum (`ask` | `auto` | `manual`)
- **Default:** `ask`
- **Set by:** `arn-infra-init` Step 8b (fresh), Step U1 (can be changed during upgrade)
- **Read by:** `arn-infra-init` Step U1 (governs upgrade behavior)
- **Description:** How to handle reference file updates when the plugin version changes.
  - `ask` -- Prompt the user during upgrade, showing which files changed and which have local customizations. Offers options to update now, skip, switch to auto, or switch to manual.
  - `auto` -- Automatically update files that have not been customized (checksum matches stored value). Customized files are preserved with a warning.
  - `manual` -- Never auto-update. Inform the user that new versions are available but do not touch files.

---

## Config File Schemas

### providers.md

```markdown
# Providers

## [provider-name]
- **Scope:** [comma-separated components: frontend, backend, api, database, workers, storage, cdn]
- **IaC tool:** [tool name or "none" -- overrides Default IaC tool for this provider]
- **Confidence:** [A | B | C | D -- set by arn-infra-discover based on available tooling]
- **Status:** [active | pending | deferred]
- **Migration:** [none | migration-id if migration in progress]
```

Confidence ratings (set by `arn-infra-discover`):
- **A:** Official MCP + CLI + authenticated
- **B:** CLI + authenticated (no MCP)
- **C:** CLI installed but not authenticated
- **D:** No direct tooling (config generation only)

### environments.md

```markdown
# Environments

## Promotion Pipeline
[env1] --> [env2] --> [env3]

## [environment-name]
- **Auto-deploy:** [yes | no]
- **Approval required:** [yes | no]
- **Last deployed:** [ISO 8601 timestamp or "--"]
- **Pending changes:** [none | list of issue references]
```

---

## Read Convention for Evolving References

When a skill says "Read the local override or plugin default for `<filename>`":
1. If Reference overrides is configured in `## Arness`, check `<Reference overrides>/<filename>`
2. If the file exists there, read it
3. Otherwise, fall back to `${CLAUDE_PLUGIN_ROOT}/skills/<owning-skill>/references/<filename>`

This convention applies to the 28 evolving reference files cataloged in the reference manifest. Static files (templates, schemas, stable checklists) continue using direct `${CLAUDE_PLUGIN_ROOT}` paths.

---

## Backward Compatibility

- Missing `Deferred` field defaults to `no`
- Missing `Providers config` defaults to single-provider mode using a legacy `Provider` field (if present)
- Missing `Environments config` defaults to `staging, prod` pipeline
- Missing `Cost threshold` defaults to `100`
- Missing `Validation ceiling` defaults to `2`
- Missing `Infra plans directory` defaults to `.arness/infra-plans`
- Missing `Infra specs directory` defaults to `.arness/infra-specs`
- Missing `Infra docs directory` defaults to `.arness/infra-docs`
- Missing `Infra report templates` defaults to `default`
- Missing `Infra template path` defaults to `.arness/infra-templates`
- Missing `Infra template version` defaults to the current plugin version
- Missing `Git`/`Platform`/`Issue tracker` fields default to runtime detection
- Missing `Reference overrides` defaults to `.arness/infra-references`
- Missing `Reference version` triggers fresh reference initialization during Update flow (Step 8b)
- Missing `Reference updates` defaults to `ask`

---

## Reverse Pointer

When topology is `monorepo` or `separate-repo`, `arn-infra-init` offers to add a reverse pointer to the application project's `## Arness` section:

```markdown
- **Infrastructure:** [relative-path-to-infra-project]
```

This enables Arness Core to detect infra availability and offer cross-plugin features (infra issue creation, handoff documents).
