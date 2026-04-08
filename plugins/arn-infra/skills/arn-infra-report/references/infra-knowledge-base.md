# Arness Infra Knowledge Base

Reference documentation for the `arn-infra-doctor` agent. Describes the Arness Infra plugin's pipeline modes, configuration requirements, expected file structures, common failure modes, and inter-skill data flow.

## Pipeline Maps

Arness Infra operates in two distinct modes depending on the complexity and governance requirements of the infrastructure change.

### Quick Mode (Interactive)

For ad-hoc infrastructure tasks — containerization, IaC generation, deployment, and monitoring. Each skill can be invoked independently.

```
arn-infra-discover → arn-infra-containerize → arn-infra-define → arn-infra-env → arn-infra-secrets → arn-infra-pipeline → arn-infra-deploy → arn-infra-verify → arn-infra-monitor
```

### Full Pipeline Mode (Structured Change Management)

For tracked infrastructure changes with phases, rollback checkpoints, and review gates.

```
arn-infra-change-spec → arn-infra-change-plan → arn-infra-save-plan → arn-infra-execute-change → arn-infra-review-change → arn-infra-document-change
```

### Standalone Skills

These skills operate outside both pipeline modes:
- `/arn-infra-wizard` — guided pipeline orchestrator (sequences either Quick or Full Pipeline mode)
- `/arn-infra-assess` — comprehensive infrastructure assessment, un-deferral, backlog generation
- `/arn-infra-cleanup` — TTL-based resource expiry and destruction
- `/arn-infra-migrate` — provider migration, PaaS graduation, consolidation
- `/arn-infra-refresh` — update evolving reference files via online research
- `/arn-infra-triage` — process incoming infrastructure request issues from Arness Code
- `/arn-infra-help` — pipeline position detection and next-step guidance
- `/arn-infra-init` — optional provider/environment/IaC tool configuration
- `/arn-infra-report` — diagnostic reporting (this skill)

## Config Requirements

The `## Arness` section in CLAUDE.md can contain up to 25 infrastructure-specific fields. Each skill reads specific fields:

### Core Fields

| Field | Description | Default |
|-------|-------------|---------|
| Infra plans directory | Structured change plan projects | `.arness/infra-plans` |
| Infra specs directory | Change specifications | `.arness/infra-specs` |
| Infra docs directory | Operational documentation | `.arness/infra-docs` |
| Infra report templates | Template set name | `default` |
| Infra template path | Where report templates are stored | `.arness/infra-templates` |
| Infra template version | Template version for checksum tracking | (from plugin) |
| Infra template updates | Update behavior: ask, auto, manual | `ask` |

### Domain Fields

| Field | Description | Default |
|-------|-------------|---------|
| Providers | Cloud providers (aws, gcp, azure, fly, railway, etc.) | (detected) |
| Providers config | Path to `providers.md` | `.arness/infra/providers.md` |
| Environments | Environment names in promotion order | `dev, staging, production` |
| Environments config | Path to `environments.md` | `.arness/infra/environments.md` |
| Default IaC tool | IaC tool: opentofu, pulumi, cdk, bicep, kubectl | (detected) |
| Project topology | monorepo, separate-repo, infra-only | (detected) |
| Application path | Path to application project root | `.` |
| Tooling manifest | Path to `tooling-manifest.json` | `.arness/infra/tooling-manifest.json` |
| Resource manifest | Path to `active-resources.json` | `.arness/infra/active-resources.json` |
| Cost threshold | Monthly budget limit for cost gate warnings | `100` |
| Validation ceiling | Maximum validation level before manual approval | `3` |
| CI/CD platform | Pipeline platform: github-actions, gitlab-ci, bitbucket-pipelines, none | (detected) |
| Reference overrides | Path to local reference file overrides | `.arness/infra/references` |
| Reference version | Version of reference files | (from plugin) |
| Reference updates | Update behavior: ask, auto, manual | `ask` |
| Deferred | Whether infra planning is deferred | `no` |

### Platform Fields

| Field | Description | Default |
|-------|-------------|---------|
| Git | Git repository detected | (detected) |
| Platform | github, bitbucket, none | (detected) |
| Issue tracker | github, jira, none | (detected) |

### Skill-to-Config Field Map

| Skill | Key Config Fields Read |
|-------|----------------------|
| arn-infra-init | Creates/updates all infra fields |
| arn-infra-ensure-config | Creates minimal defaults on first invocation |
| arn-infra-discover | Providers, Default IaC tool, Tooling manifest |
| arn-infra-containerize | Project topology, Application path |
| arn-infra-define | Providers, Providers config, Default IaC tool, Validation ceiling |
| arn-infra-env | Providers, Environments, Environments config |
| arn-infra-secrets | Providers, Providers config |
| arn-infra-pipeline | Providers, CI/CD platform, Environments |
| arn-infra-deploy | Providers, Environments, Environments config, Cost threshold, Resource manifest, Tooling manifest |
| arn-infra-verify | Providers, Environments, Environments config, Resource manifest |
| arn-infra-monitor | Providers, Providers config |
| arn-infra-change-spec | Infra specs directory, Providers |
| arn-infra-change-plan | Infra plans directory, Infra specs directory, Providers, Environments |
| arn-infra-save-plan | Infra plans directory, Infra report templates, Infra template path, Infra template version |
| arn-infra-execute-change | Infra plans directory, Providers, Environments, Cost threshold, Default IaC tool, Tooling manifest, Resource manifest |
| arn-infra-review-change | Infra plans directory, Infra specs directory, Providers, Environments |
| arn-infra-document-change | Infra docs directory, Infra plans directory, Infra specs directory, Providers |
| arn-infra-cleanup | Resource manifest, Environments, Issue tracker |
| arn-infra-migrate | Providers, Providers config, Environments, Default IaC tool |
| arn-infra-triage | Infra specs directory, Providers, Issue tracker |
| arn-infra-assess | Providers, Project topology, Deferred, Issue tracker |
| arn-infra-wizard | All fields (sequences other skills) |
| arn-infra-help | Infra plans directory, Infra specs directory, Infra docs directory, Providers |
| arn-infra-refresh | Reference overrides, Reference version, Reference updates |

## Expected Directory/File Structure

### After arn-infra-init (or ensure-config auto-setup)

```
<project-root>/
├── CLAUDE.md (with ## Arness section — infra fields appended or merged)
├── .arness/infra/
│   ├── providers.md
│   ├── environments.md
│   ├── tooling-manifest.json
│   └── active-resources.json (created after first deploy)
├── .arness/infra-specs/ (empty, ready for change specs)
├── .arness/infra-plans/ (empty, ready for plan projects)
├── .arness/infra-docs/ (empty, ready for documentation)
└── .arness/infra-templates/
    ├── INFRA_CHANGE_REPORT_TEMPLATE.json
    ├── INFRA_REVIEW_REPORT_TEMPLATE.json
    └── .checksums.json
```

### After arn-infra-containerize

```
<application-root>/
├── Dockerfile (or Dockerfile.<service>)
├── docker-compose.yml (if multi-service)
└── .dockerignore
```

### After arn-infra-define

```
<project-root>/
├── infra/ (or terraform/, pulumi/, cdk/, etc.)
│   ├── <provider-specific IaC files>
│   ├── variables.tf / Pulumi.yaml / etc.
│   └── outputs.tf / stack outputs / etc.
└── .arness/infra/
    └── active-resources.json (updated with defined resources)
```

### After arn-infra-deploy

```
.arness/infra/
├── active-resources.json (updated with deployed resources)
└── environments.md (updated with deployment state)
```

### After arn-infra-save-plan (Full Pipeline)

```
<infra-plans-dir>/<PROJECT_NAME>/
├── INTRODUCTION.md
├── SOURCE_PLAN.md
├── TASKS.md
├── PROGRESS_TRACKER.json
├── plans/
│   └── PHASE_N_PLAN.md (one per phase)
└── reports/ (empty, ready for execution reports)
```

### After arn-infra-execute-change (Full Pipeline)

```
<infra-plans-dir>/<PROJECT_NAME>/reports/
├── INFRA_CHANGE_REPORT_PHASE_N.json (one per phase)
└── PROGRESS_TRACKER.json (updated with phase results)
```

### Reference Files Directory (28 evolving files)

```
${CLAUDE_PLUGIN_ROOT}/
├── skills/arn-infra-discover/references/
│   ├── mcp-registry.md
│   ├── cli-registry.md
│   └── plugin-registry.md
├── skills/arn-infra-containerize/references/
│   ├── dockerfile-patterns.md
│   └── compose-patterns.md
├── skills/arn-infra-define/references/
│   ├── opentofu-patterns.md
│   ├── pulumi-patterns.md
│   ├── cdk-patterns.md
│   ├── bicep-patterns.md
│   ├── kubernetes-patterns.md
│   ├── paas-config-patterns.md
│   └── validation-ladder.md
├── skills/arn-infra-pipeline/references/
│   ├── github-actions-patterns.md
│   ├── gitlab-ci-patterns.md
│   ├── bitbucket-pipelines-patterns.md
│   └── pipeline-security-checklist.md
├── skills/arn-infra-secrets/references/
│   └── secrets-providers.md
└── ... (plus cloud-patterns and infra-guides across other skills)
```

## Common Failure Modes

| Symptom | Likely Cause | Diagnostic Check |
|---------|-------------|------------------|
| "Arness Infra not configured" | arn-infra-init/ensure-config not run, or CLAUDE.md overwritten | Check CLAUDE.md for `## Arness` with infra fields |
| Provider not configured | No `Providers` field or empty providers list | Check `Providers` in `## Arness` |
| IaC tool not installed | terraform/tofu/pulumi/cdk/bicep not on PATH | Run `tofu version`, `terraform version`, `pulumi version` |
| Docker not available | Docker daemon not running or not installed | Run `docker --version`, `docker compose version` |
| Cloud CLI auth failure | aws/gcloud/az not authenticated or token expired | Run `aws sts get-caller-identity`, `gcloud auth list`, `az account show` |
| Deployment to wrong environment | Environments config incorrect or promotion order violated | Check `Environments` field and `environments.md` |
| Cost threshold exceeded during deploy | Estimated cost exceeds `Cost threshold` | Check `Cost threshold` in config and cost-analyst output |
| Security audit blocks deployment | Checkov/Trivy findings at blocking severity | Check validation-ladder.md and `Validation ceiling` field |
| Verification fails | Health check, DNS, or SSL validation failure post-deploy | Check `environments.md` for verification state |
| Change plan execution phase fails mid-way | Phase dependency failure, IaC apply error, or rollback triggered | Check PROGRESS_TRACKER.json for phase status |
| Rollback checkpoint not created | execute-change skipped checkpoint step or disk write failed | Check `<project>/reports/` for rollback artifacts |
| Reference files stale | Reference version mismatch after plugin update | Compare `Reference version` with plugin version |
| Resource manifest out of sync | Manual changes outside Arness or failed deploy left stale state | Check `active-resources.json` vs actual cloud state |
| CI/CD pipeline generation fails | CI/CD platform not configured or unsupported | Check `CI/CD platform` field in config |
| Secrets scan finds exposed credentials | Hardcoded secrets in IaC or config files | Check secrets-audit output, not source code |
| Cleanup skill finds no TTL resources | Resource manifest empty or no TTL tags configured | Check `active-resources.json` for TTL fields |
| Migration fails at cutover step | Target provider not reachable or DNS propagation incomplete | Check migrate skill output for cutover errors |
| Tooling manifest empty after discover | Discover skill completed but no tools detected | Check `tooling-manifest.json` for entries |
| Save-plan can't find PLAN_PREVIEW_INFRA_*.md | change-plan was not run, or plan was not approved | Check `<infra-plans-dir>/` for PLAN_PREVIEW_INFRA_*.md files |
| Environment promotion blocked | Staging not verified or verification failed | Check `environments.md` for staging verification state |
| Labels not created on GitHub | gh auth lacks permission or Platform not github | Check `Platform` field, run `gh auth status` |

## Inter-Skill Data Flow

### Quick Mode

```
arn-infra-init / arn-infra-ensure-config
  outputs: ## Arness config (infra fields), .arness/infra/ directory, providers.md, environments.md
  consumed by: all other infra skills read ## Arness config

arn-infra-discover
  outputs: tooling-manifest.json (MCPs, CLIs, plugins with auth state)
  consumed by: arn-infra-define (tool availability), arn-infra-deploy (tool availability), arn-infra-execute-change

arn-infra-containerize
  outputs: Dockerfile(s), docker-compose.yml, .dockerignore
  consumed by: arn-infra-define (containerized app context), arn-infra-pipeline (Docker build steps)

arn-infra-define
  outputs: IaC files (*.tf, Pulumi.*, cdk, bicep, k8s manifests), active-resources.json (updated)
  consumed by: arn-infra-env (base IaC for environment variants), arn-infra-deploy (IaC to apply)

arn-infra-env
  outputs: environment-specific variable files (*.tfvars, Pulumi.<env>.yaml), environments.md (updated)
  consumed by: arn-infra-deploy (per-environment configs), arn-infra-pipeline (environment stages)

arn-infra-secrets
  outputs: secrets configuration, secrets audit report
  consumed by: arn-infra-deploy (secret injection), arn-infra-pipeline (secret references)

arn-infra-pipeline
  outputs: CI/CD workflow files (.github/workflows/, .gitlab-ci.yml, bitbucket-pipelines.yml)
  consumed by: user (automated deployments)

arn-infra-deploy
  outputs: active-resources.json (updated), environments.md (deployment state updated)
  consumed by: arn-infra-verify (what to verify), arn-infra-cleanup (what to track)

arn-infra-verify
  outputs: verification report, environments.md (verification state updated)
  consumed by: arn-infra-deploy (promotion gate for next environment)

arn-infra-monitor
  outputs: monitoring IaC (CloudWatch/Stackdriver/etc.), alert configs
  consumed by: user (operational monitoring)
```

### Full Pipeline Mode

```
arn-infra-change-spec
  outputs: INFRA_CHANGE_SPEC_<name>.md in infra-specs directory
  consumed by: arn-infra-change-plan (loads spec for plan generation)

arn-infra-change-plan
  outputs: PLAN_PREVIEW_INFRA_<spec-name>.md in infra-plans directory
  consumed by: arn-infra-save-plan (reads plan preview)

arn-infra-save-plan
  outputs: structured project directory (INTRODUCTION.md, SOURCE_PLAN.md, TASKS.md, PHASE_N_PLAN.md, PROGRESS_TRACKER.json)
  consumed by: arn-infra-execute-change (consumes structured project)

arn-infra-execute-change
  outputs: INFRA_CHANGE_REPORT_PHASE_N.json per phase, PROGRESS_TRACKER.json (updated), active-resources.json (updated)
  consumed by: arn-infra-review-change (reads all phase reports)

arn-infra-review-change
  outputs: review report with PASS/WARN/NEEDS_FIXES verdict
  consumed by: arn-infra-document-change (proceeds on PASS/WARN)

arn-infra-document-change
  outputs: runbooks, architecture docs, changelogs, environment docs in infra-docs directory
  consumed by: user (operational documentation)
```

### Standalone Skill Data Flow

```
arn-infra-assess
  inputs: application codebase (read-only), deferred backlog (if exists)
  outputs: prioritized infrastructure backlog as issues, un-defers config

arn-infra-cleanup
  inputs: active-resources.json, issue tracker (TTL labels), TTL registry
  outputs: destroyed resources, updated active-resources.json

arn-infra-migrate
  inputs: current provider config, target provider selection
  outputs: migration parent issue, task issues, IaC for target provider

arn-infra-triage
  inputs: infrastructure request issue (from Arness Code)
  outputs: implications brief, updated issue labels

arn-infra-refresh
  inputs: 28 evolving reference files, reference-manifest.md
  outputs: updated reference files, reference-checksums.json, Reference version bump
```

## Version History

Maintainers update this section when bumping the plugin version to document what changed.

### 1.0.0 (Initial Release)
- 23 skills: init, ensure-config, discover, containerize, define, env, secrets, pipeline, deploy, verify, monitor, change-spec, change-plan, save-plan, execute-change, review-change, document-change, wizard, assess, cleanup, migrate, triage, help
- 9 agents: request-analyzer, specialist, cost-analyst, security-auditor, verifier, reference-researcher, pipeline-builder, change-reviewer, change-planner
- Progressive zero-config init via ensure-config
- Two pipeline modes: Quick (interactive) and Full Pipeline (structured change management)
- 28 evolving reference files with refresh support
- Expertise-adaptive behavior derived from user profile

### 2.0.0 (Nova-to-Arness Rebrand)
- All skills and agents renamed from nova-infra-* to arn-infra-*
- Configuration directories renamed from .nova/ to .arness/
- Config section renamed from ## Nova to ## Arness

### 2.1.0
- Added arn-infra-refresh skill for reference file updates
- Added arn-infra-help skill for pipeline position detection

### 2.1.1
- Bug fixes and minor wording changes

## Version Information

- Plugin version is in `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json` (field: `version`)
- Template version in user config tracks which plugin version templates were copied from
- Skill versions are in each SKILL.md frontmatter (field: `version`)
- Reference version tracks the evolving reference file set version
