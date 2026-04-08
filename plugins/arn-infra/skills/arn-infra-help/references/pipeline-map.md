# Infrastructure Pipeline Map

Reference for the `arn-infra-help` skill. Contains pipeline templates, stage detection rules, and next-step suggestions for both the **Quick mode** (interactive skills) and the **Full Pipeline mode** (structured change management).

---

## Mode Classification

Arness Infra has two operational modes, detected by the presence of artifacts in specific directories:

| Mode | Config Fields (determine artifact locations) | Artifact Indicators |
|------|----------------------------------------------|---------------------|
| **Full Pipeline** | Infra specs directory, Infra plans directory, Infra docs directory | `INFRA_CHANGE_*.md`, `PLAN_PREVIEW_INFRA_*.md`, plan project directories, `INFRA_CHANGE_REPORT_*.json`, `INFRA_REVIEW_REPORT.json` |
| **Quick** | Providers config, Tooling manifest, Resource manifest | `tooling-manifest.json`, IaC files, container configs, deploy artifacts, monitoring configs |

**Classification:**

| Full Pipeline Artifacts | Quick Artifacts | Active Mode | Rendering Focus |
|------------------------|-----------------|-------------|-----------------|
| Present | Absent | `full-pipeline` | Full Pipeline diagram |
| Absent | Present | `quick` | Quick mode diagram |
| Present | Present | `dual` | Both diagrams with position markers |
| Absent | Absent | `initialized` | Both diagrams unmarked, suggest wizard |

---

## Full Pipeline Template

The Full Pipeline provides structured change management for infrastructure. Changes go through specification, planning, review, and documentation stages.

```
Full Infrastructure Pipeline
==============================

  change-spec --> change-plan --> save-plan --> execute-change --> review-change --> document-change

  Agents:    change-planner (planning), change-reviewer (review)
  Guided:    /arn-infra-wizard (Full Pipeline mode)
```

### Full Pipeline Stage-to-Skill Mapping

| Stage | Primary Skill | Notes |
|-------|--------------|-------|
| `specced` | `/arn-infra-change-spec` | Creates INFRA_CHANGE_*.md spec in infra-specs directory |
| `planned` | `/arn-infra-change-plan` | Invokes change-planner agent; writes PLAN_PREVIEW_INFRA_*.md |
| `saved` | `/arn-infra-save-plan` | Structures plan into project directory with INTRODUCTION.md and PHASE_N_PLAN.md |
| `executing` | `/arn-infra-execute-change` | Executes plan phases; writes INFRA_CHANGE_REPORT_PHASE_N.json |
| `reviewed` | `/arn-infra-review-change` | Invokes change-reviewer agent; writes INFRA_REVIEW_REPORT.json |
| `documented` | `/arn-infra-document-change` | Produces runbooks, changelogs, architecture docs in infra-docs directory |

### Full Pipeline Annotation Instructions

1. Identify the user's current stage using the Full Pipeline detection rules below.
2. Place the `YOU ARE HERE` marker directly below the matching stage label in the diagram.
3. If multiple plan projects exist (subdirectories under the infra plans directory), render a separate annotated diagram for each project, prefixed with the project name.
4. If no Full Pipeline artifacts exist, show the diagram unmarked.

**Single-project example:**

```
Full Infrastructure Pipeline
==============================

  change-spec --> change-plan --> save-plan --> execute-change --> review-change --> document-change
                                                ^^^^^^^^^^^^^^
                                              YOU ARE HERE

  Agents:    change-planner (planning), change-reviewer (review)
  Guided:    /arn-infra-wizard (Full Pipeline mode)
```

**Multi-project example:**

```
Project: vpc-migration

  change-spec --> change-plan --> save-plan --> execute-change --> review-change --> document-change
                                                ^^^^^^^^^^^^^^
                                              YOU ARE HERE

Project: database-scaling

  change-spec --> change-plan --> save-plan --> execute-change --> review-change --> document-change
                  ^^^^^^^^^^^
                YOU ARE HERE
```

---

## Quick Mode Template

Quick mode uses existing interactive skills for direct infrastructure operations without specs, plans, or review gates.

```
Quick Infrastructure Mode
===========================

  init --> discover --> containerize --> define --> deploy --> verify --> monitor

  Standalone: arn-infra-triage, arn-infra-assess, arn-infra-secrets, arn-infra-env, arn-infra-migrate, arn-infra-cleanup
  Guided:     /arn-infra-wizard (Quick mode)
```

### Quick Mode Stage-to-Skill Mapping

| Stage | Primary Skill | Notes |
|-------|--------------|-------|
| `initialized` | `/arn-infra-init` | `## Arness` exists but no artifacts |
| `discovered` | `/arn-infra-discover` | Tooling manifest populated |
| `containerized` | `/arn-infra-containerize` | Dockerfile, docker-compose.* exist |
| `defined` | `/arn-infra-define` | IaC files generated |
| `deployed` | `/arn-infra-deploy` | Resources deployed |
| `verified` | `/arn-infra-verify` | Health checks passed |
| `monitored` | `/arn-infra-monitor` | Monitoring configured |

### Quick Mode Annotation Instructions

1. Identify the user's current stage using the Quick mode detection rules below.
2. Place the `YOU ARE HERE` marker directly below the matching stage label.
3. Quick mode is a single-track pipeline (no per-project subdirectories).

**Example:**

```
Quick Infrastructure Mode
===========================

  init --> discover --> containerize --> define --> deploy --> verify --> monitor
                                        ^^^^^^
                                     YOU ARE HERE

  Standalone: arn-infra-triage, arn-infra-assess, arn-infra-secrets, arn-infra-env, arn-infra-migrate, arn-infra-cleanup
  Guided:     /arn-infra-wizard (Quick mode)
```

---

## Full Pipeline Stage Detection Rules

Check stages from **most advanced to least advanced**. The first matching rule determines the current stage. For per-project detection, scan each subdirectory under the infra plans directory independently.

| Stage | Key | Detection Rule | Artifacts Checked |
|-------|-----|----------------|-------------------|
| Documented | `documented` | At least one file exists in the infra docs directory (runbooks, changelogs, architecture decision records) that corresponds to the change | `<infra-docs-dir>/*.md`, `<infra-docs-dir>/<project>/` |
| Reviewed | `reviewed` | An `INFRA_REVIEW_REPORT.json` file exists in the plan project's `reports/` directory | `<infra-plans-dir>/<project>/reports/INFRA_REVIEW_REPORT.json` |
| Executed | `executed` | All `INFRA_CHANGE_REPORT_PHASE_N.json` files exist (one per plan phase) and `PROGRESS_TRACKER.json` shows all phases complete, but no review report exists | `<infra-plans-dir>/<project>/reports/INFRA_CHANGE_REPORT_*.json` count matches phase count, `PROGRESS_TRACKER.json` status = complete, no `INFRA_REVIEW_REPORT.json` |
| Executing | `executing` | At least one `INFRA_CHANGE_REPORT_PHASE_N.json` file exists in the plan project's `reports/` directory | `<infra-plans-dir>/<project>/reports/INFRA_CHANGE_REPORT_*.json` |
| Plan saved | `saved` | A project subdirectory exists under the infra plans directory containing `INTRODUCTION.md` and at least one `PHASE_N_PLAN.md` | `<infra-plans-dir>/<project>/INTRODUCTION.md` + `<infra-plans-dir>/<project>/plans/PHASE_N_PLAN.md` |
| Plan generated | `planned` | At least one file matching `PLAN_PREVIEW_INFRA_*.md` exists in the infra plans directory | `<infra-plans-dir>/PLAN_PREVIEW_INFRA_*.md` |
| Spec written | `specced` | At least one file matching `INFRA_CHANGE_*.md` exists in the infra specs directory | `<infra-specs-dir>/INFRA_CHANGE_*.md` |
| No pipeline artifacts | -- | No Full Pipeline artifacts found | Fall through to Quick mode detection |

### Per-Project Detection (Full Pipeline)

When the infra plans directory contains multiple project subdirectories, detect the stage for each project independently:

1. Read `## Arness` from CLAUDE.md to get `Infra plans directory`, `Infra specs directory`, and `Infra docs directory`.
2. List subdirectories under the infra plans directory. Each subdirectory is a plan project.
3. For each project subdirectory, apply the detection rules starting from `documented` down to `saved`.
4. For global stages (`specced`, `planned`), these apply to the workspace as a whole, not to individual projects.

### Detection Precedence

- Per-project stages (`saved` through `documented`) override global stages.
- If at least one project exists, show per-project diagrams.
- If no projects exist, show a single diagram with the global stage (`specced`, `planned`, or unmarked).

---

## Quick Mode Stage Detection Rules

Check stages from **most advanced to least advanced**. The first matching rule determines the current stage.

| Stage | Key | Detection Rule | Artifacts Checked |
|-------|-----|----------------|-------------------|
| Monitored | `monitored` | Monitoring configurations exist (alerting rules, dashboard configs, observability stack configs) | Alerting config files, monitoring dashboard definitions, observability tool configs |
| Verified | `verified` | Verification reports or health check results exist | Health check reports, verification logs, `arn-infra-verify` output artifacts |
| Deployed | `deployed` | Resource manifest contains deployed resources with non-empty state | `<resource-manifest>` (default: `.arness/infra/active-resources.json`) with resources in deployed state |
| Defined | `defined` | IaC files exist in the project | `*.tf`, `*.hcl`, `Pulumi.*`, `cdk.json`, `*.bicep`, `main.tf`, `infrastructure/` |
| Containerized | `containerized` | Container configuration files exist | `Dockerfile`, `docker-compose.*`, `.dockerignore` |
| Discovered | `discovered` | Tooling manifest exists and is populated | `<tooling-manifest>` (default: `.arness/infra/tooling-manifest.json`) exists and contains entries |
| Initialized | `initialized` | `## Arness` exists in CLAUDE.md but none of the above artifacts found | `CLAUDE.md` contains `## Arness`, no tool/container/IaC/deploy/monitor artifacts |
| Not initialized | `none` | No `## Arness` section found in CLAUDE.md | `CLAUDE.md` missing or lacks `## Arness` |

---

## Next-Step Tables

### Full Pipeline Next Steps

| Detected Stage | Next Command | Description |
|----------------|--------------|-------------|
| `none` | `/arn-infra-init` | Initialize Arness Infra configuration |
| `initialized` | `/arn-infra-change-spec` | Write an infrastructure change specification |
| `specced` | `/arn-infra-change-plan` | Generate a phased plan from the change spec |
| `planned` | `/arn-infra-save-plan` | Structure the plan into a project with phases |
| `saved` | `/arn-infra-execute-change` | Execute the plan phases |
| `executing` | `/arn-infra-execute-change` | Continue executing remaining plan phases |
| `executed` | `/arn-infra-review-change` | Review the completed infrastructure change |
| `reviewed` | `/arn-infra-document-change` | Document the change (runbooks, changelogs) |
| `documented` | `/arn-infra-change-spec` | Pipeline complete. Start a new change, or run `/arn-infra-verify` to re-validate. |

**Note:** The `executing` stage persists as long as execution is in progress (not all phases complete). When all phases are done, detection advances to `executed`, which routes to review.

### Quick Mode Next Steps

| Detected Stage | Next Command | Description |
|----------------|--------------|-------------|
| `none` | `/arn-infra-init` | Initialize Arness Infra configuration |
| `initialized` | `/arn-infra-discover` | Audit installed tools and configure provider access |
| `discovered` | `/arn-infra-containerize` | Generate Docker configurations |
| `containerized` | `/arn-infra-define` | Generate IaC in the chosen tool |
| `defined` | `/arn-infra-deploy` | Deploy to environments |
| `deployed` | `/arn-infra-verify` | Validate the deployment |
| `verified` | `/arn-infra-monitor` | Configure monitoring and alerting |
| `monitored` | `/arn-infra-verify` | Pipeline complete. Re-verify periodically, or start a structured change with `/arn-infra-change-spec`. |

---

## Dual-Mode Rendering Rules

When artifacts from both Quick mode and Full Pipeline mode are detected:

| Quick Mode State | Full Pipeline State | Rendering |
|------------------|-------------------|-----------|
| Any stage | Active (artifacts exist) | Show Full Pipeline diagram with position first, then Quick mode diagram with position. Note: "Both interactive and structured pipeline artifacts detected." |
| Active | No artifacts | Show Quick mode diagram with position only |
| No artifacts | Active | Show Full Pipeline diagram with position only |
| `initialized` | `initialized` | Show both diagrams unmarked. Suggest: "Run `/arn-infra-wizard` to choose Quick mode or Full Pipeline mode." |

**Mode upgrade hint:** When showing Quick mode and the user is at `defined` or later, add: "For complex infrastructure changes, consider switching to the Full Pipeline with `/arn-infra-change-spec` for structured planning and review gates."

---

## Experience Level Presentation

### Expert

Show the diagram(s), the detected stage key, and the next command. Example:

```
Quick mode: defined
Next: /arn-infra-deploy
```

### Intermediate

Show the diagram(s) with position marker, a one-line description, and the next command with a brief explanation. Example:

```
Quick Infrastructure Mode
===========================

  init --> discover --> containerize --> define --> deploy --> verify --> monitor
                                        ^^^^^^
                                     YOU ARE HERE

Current stage: Infrastructure code defined (IaC files generated)
Next step: /arn-infra-deploy -- deploy your infrastructure to the configured environments
```

### Beginner

Show the diagram(s) with position marker, explain the current stage, list what has been completed, and describe the next step with full context. Example:

```
Quick Infrastructure Mode
===========================

  init --> discover --> containerize --> define --> deploy --> verify --> monitor
                                        ^^^^^^
                                     YOU ARE HERE

Current stage: Infrastructure code defined
What's done: You've initialized Arness Infra, discovered your tools, containerized your application, and generated infrastructure-as-code files for your chosen provider.
Next step: Deploy your infrastructure to your environments.
Run: /arn-infra-deploy
This will apply your IaC definitions to create cloud resources in your staging environment first, then promote to production after verification.
```

---

## Cross-Plugin Hints

When Step 0 detects other plugin activity, append these hints at the bottom of the status output.

**Code active:**
"Development pipeline: active — run `/arn-code-help` for details."

**Spark active:**
"Spark exploration: active — run `/arn-spark-help` for details."

**Not configured (no ## Arness):**
After suggesting `/arn-infra-wizard`:
"Looking for development workflows? Try `/arn-code-help`. Starting a new product? Try `/arn-spark-help`."

**Own pipeline complete:**
"Infrastructure pipeline complete. Start a new change with `/arn-infra-change-spec`."
If Code is configured: "Build more features with `/arn-planning`."
