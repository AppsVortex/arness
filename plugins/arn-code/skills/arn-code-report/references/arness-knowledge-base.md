# Arness Knowledge Base

Reference documentation for the `arn-code-doctor` agent. Describes the Arness plugin's pipeline, configuration requirements, expected file structures, common failure modes, and inter-skill data flow.

## Pipeline Map

```
arn-code-init → arn-code-feature-spec / arn-code-bug-spec → arn-code-plan → arn-code-save-plan → arn-code-review-plan → arn-code-taskify → arn-code-execute-plan → arn-code-review-implementation → arn-code-document-project → arn-code-ship
```

Three ceremony tiers (selected by scope router in arn-planning):
- **Swift** (low ceremony): `arn-code-swift` — quick assessment → plan → execute → simplify → verify → ship (1-8 files)
- **Standard** (medium ceremony): `arn-code-standard` — spec-lite → plan → execute → review-lite → ship (collapsed pipeline)
- **Thorough** (full ceremony): Full pipeline above (spec → plan → save → taskify → execute → review → docs → ship)

Alternative paths:
- `/arn-code-feature-spec-teams` — team debate variant of feature spec
- `/arn-code-execute-plan-teams` — Agent Teams variant of execution (requires CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1)
- `/arn-code-execute-task` — single task execution (alternative to full plan execution)
- `/arn-code-standard` — collapsed spec-plan-execute for medium complexity (standard tier)
- `/arn-code-review-pr` — PR feedback loop (standalone, requires Platform: github or bitbucket)
- `/arn-code-create-issue` / `/arn-code-pick-issue` — issue management (standalone, requires Issue tracker: github or jira)
- `/arn-code-catch-up` -- retroactive documentation of out-of-pipeline commits (standalone)
- `/arn-code-report` — diagnostic reporting (standalone)

## Config Requirements

The `## Arness` section in CLAUDE.md can have up to 14 fields (11 core + 3 conditional: 2 Jira + 1 Task list ID). Each skill reads specific fields:

| Skill | Plans dir | Specs dir | Templates | Code patterns | Docs dir | Git | Platform | Issue tracker | Jira site | Jira project | Task list ID |
|-------|-----------|-----------|-----------|---------------|----------|-----|----------|---------------|-----------|--------------|--------------|
| arn-code-init | creates | creates | creates | creates | creates | detects | detects | detects | detects | detects | creates |
| arn-code-feature-spec | - | writes to | - | reads | - | - | - | - | - | - | - |
| arn-code-bug-spec | - | writes to | - | reads | - | - | - | - | - | - | - |
| arn-code-save-plan | reads | reads | reads | reads | - | - | - | - | - | - | - |
| arn-code-review-plan | reads | - | - | reads | - | - | - | - | - | - | - |
| arn-code-taskify | reads | - | - | - | - | - | - | - | - | - | reads |
| arn-code-execute-plan | reads | reads | reads | reads | - | - | - | - | - | - | reads |
| arn-code-execute-task | reads | reads | reads | reads | - | - | - | - | - | - | - |
| arn-code-review-implementation | reads | - | - | reads | - | - | - | - | - | - | - |
| arn-code-document-project | reads | reads | - | reads | writes to | reads | - | - | - | - | - |
| arn-code-ship | - | - | - | - | - | required | github or bitbucket | - | - | - | - |
| arn-code-review-pr | - | - | - | - | - | - | github or bitbucket | (optional) | - | - | - |
| arn-code-create-issue | - | - | - | - | - | - | - | github or jira | reads | reads | - |
| arn-code-pick-issue | - | - | - | - | - | - | - | github or jira | reads | reads | - |
| arn-code-standard | reads | - | reads | reads | - | - | - | - | - | - | - |
| arn-code-catch-up | reads | - | reads | reads | - | reads | - | - | - | - | - |

## Expected ## Arness Config Format

```markdown
## Arness
- **Plans directory:** <path>
- **Specs directory:** <path>
- **Report templates:** default | custom
- **Template path:** <path>
- **Template version:** <semver>
- **Template updates:** ask | auto | manual
- **Code patterns:** <path>
- **Docs directory:** <path>
- **Git:** yes | no
- **Platform:** github | bitbucket | none
- **Issue tracker:** github | jira | none
- **Jira site:** <site>.atlassian.net          ← only if Issue tracker: jira
- **Jira project:** <KEY>                      ← only if Issue tracker: jira
- **Task list ID:** <id>                        ← only if user opted in during init Step 9b
```

Backward compatibility: Missing `Docs directory` defaults to `.arness/docs/`. Missing `Git` defaults to runtime detection. Legacy `GitHub: yes` is auto-migrated to `Platform: github` + `Issue tracker: github` by the upgrade flow. Missing `Task list ID` means tasks are session-scoped — the upgrade flow (Step U8) offers to enable persistence.

## Expected Directory/File Structure

### After arn-code-init

```
<project-root>/
├── CLAUDE.md (with ## Arness section — up to 14 fields)
├── <code-patterns-dir>/
│   ├── code-patterns.md
│   ├── testing-patterns.md
│   ├── architecture.md
│   └── ui-patterns.md (frontend/fullstack only)
├── <specs-dir>/ (empty, ready for specs)
├── <plans-dir>/ (empty, ready for projects)
├── <docs-dir>/ (empty, ready for documentation)
└── <template-path>/
    ├── BUGFIX_REPORT_TEMPLATE.json
    ├── CATCHUP_REPORT_TEMPLATE.json
    ├── CHANGE_RECORD_TEMPLATE.json
    ├── IMPLEMENTATION_REPORT_TEMPLATE.json
    ├── PROJECT_PROGRESS_REPORT_TEMPLATE.json
    ├── REVIEW_REPORT_TEMPLATE.json
    ├── SIMPLIFICATION_REPORT_TEMPLATE.json
    ├── STANDARD_REPORT_TEMPLATE.json
    ├── SWIFT_REPORT_TEMPLATE.json
    ├── TASK_REVIEW_REPORT_TEMPLATE.json
    ├── TESTING_REPORT_TEMPLATE.json
    └── .checksums.json
```

### After arn-code-save-plan

```
<plans-dir>/<PROJECT_NAME>/
├── INTRODUCTION.md
├── SOURCE_PLAN.md
├── TASKS.md
├── PROGRESS_TRACKER.json
├── plans/
│   └── PHASE_*.md (one per phase — implementation and testing plans)
└── reports/ (empty, ready for execution reports)
```

### After arn-code-standard

```
<plans-dir>/STANDARD_<name>/
├── STANDARD_<name>.md (combined spec-lite + plan)
├── STANDARD_REPORT.json (execution report)
└── CHANGE_RECORD.json (unified change envelope)
```

### After arn-code-swift (updated)

The swift directory now also includes a CHANGE_RECORD.json:

```
<plans-dir>/SWIFT_<name>/
├── SWIFT_<name>.md (assessment + plan)
├── SWIFT_REPORT.json (execution report)
└── CHANGE_RECORD.json (unified change envelope)
```

### After arn-code-catch-up

```
<plans-dir>/CATCHUP_<name>/
  CATCHUP_<name>.md (what we know / what we don't know summary)
  CHANGE_RECORD.json (unified change envelope with catchup extension)
```

### After arn-code-execute-plan (thorough tier)

```
<plans-dir>/<PROJECT_NAME>/reports/
├── IMPLEMENTATION_REPORT_PHASE_*.json
├── TESTING_REPORT_PHASE_*.json
└── TASK_REVIEW_REPORT_*.json (one per reviewed task)
```

The thorough tier also produces a CHANGE_RECORD.json in the project root:

```
<plans-dir>/<PROJECT_NAME>/
├── ... (existing project files)
└── CHANGE_RECORD.json (unified change envelope)
```

## Common Failure Modes

| Symptom | Likely Cause | Diagnostic Check |
|---------|-------------|------------------|
| "## Arness section not found" | arn-code-init was not run, or CLAUDE.md was deleted/overwritten | Check CLAUDE.md exists at project root and contains `## Arness` |
| Templates not found | Template directory missing or empty after init | Check `<template-path>/` exists and contains JSON files |
| Checksums missing | arn-code-init completed but the checksum generation step was skipped or failed | Check `.checksums.json` exists in template directory |
| Spec not found by arn-code-plan | Specs directory misconfigured, or spec was saved with wrong name/path | Check `<specs-dir>/` exists and list its contents |
| Plan preview not found by save-plan | /arn-code-plan was not run, or plan was not approved | Check `<plans-dir>/` for PLAN_PREVIEW_*.md files |
| arn-code-save-plan fails | Plans directory doesn't exist | Check `<plans-dir>/` exists via `ls` |
| TASKS.md has no parseable tasks | TASKS.md format doesn't match expected `### Task N:` heading pattern | Check TASKS.md exists and has correct format |
| Task list empty after arn-code-taskify | TASKS.md was empty or had parsing errors during taskify | Check TASKS.md content for task entries |
| Executor agent fails | Missing phase plan file, INTRODUCTION.md, or project directory structure incomplete | Verify all required project files exist |
| GitHub-dependent skills fail | gh CLI not installed, not authenticated, or no GitHub remote | Run `gh auth status` and `git remote -v` |
| Labels not created during arn-code-init | gh auth lacks permission, or GitHub detection returned no | Check Git/GitHub fields in config, run `gh auth status` |
| PR creation fails in arn-code-ship | Not on a feature branch, no commits ahead of main, or gh not authenticated | Check `git branch --show-current`, `git log main..HEAD`, `gh auth status` |
| Template version mismatch | Plugin was updated but project templates are from an older version | Compare `Template version` in config with version in plugin.json |
| Pattern docs incomplete | arn-code-codebase-analyzer or arn-code-pattern-architect returned partial output | Check pattern doc files exist and have content |
| Bitbucket skills fail | `bkt` not installed or not authenticated | Run `bkt --version` and `bkt auth status` |
| Jira skills fail | Atlassian MCP server not configured or auth expired | Run `/mcp` to check server status, check `.mcp.json` |
| Jira project not found | Wrong project key or MCP auth issue | Verify `Jira project` in config, re-run `/arn-planning` to reconfigure |
| PR creation fails on Bitbucket | `bkt` auth expired or wrong workspace | Check `bkt auth status`, verify remote URL |
| Old `GitHub: yes` config | Pre-0.9.0 config not migrated | Run any entry-point skill (e.g., `/arn-planning`) — ensure-config auto-migrates legacy fields |
| STANDARD_* artifacts not detected | arn-code-standard directory uses wrong prefix or naming | Check `<plans-dir>/` for directories matching `STANDARD_*` pattern; verify `STANDARD_<name>.md` exists inside |
| CHANGE_RECORD.json missing | Tier skill completed but did not generate the unified change envelope | Check the tier output directory (SWIFT_*, STANDARD_*, or project root) for CHANGE_RECORD.json; re-run the tier skill if missing |
| Standard tier not offered by scope router | Scope router criteria not updated or severity score calculation incorrect | Check `references/scope-router-criteria.md` in arn-planning for the 6-criterion weighted scoring thresholds |

## Inter-Skill Data Flow

```
arn-code-init
  outputs: ## Arness config in CLAUDE.md, pattern docs (code-patterns.md, testing-patterns.md,
           architecture.md, ui-patterns.md), template files + checksums, directories created
  consumed by: all other skills read ## Arness config

arn-code-feature-spec / arn-code-bug-spec
  outputs: spec file in <specs-dir>/ (e.g., FEATURE_websocket.md, BUGFIX_checkout-500.md)
  intermediate: DRAFT_FEATURE_<name>.md written during exploration (auto-deleted on finalization)
  consumed by: /arn-code-plan (loads finalized spec as context for plan writing)

/arn-code-plan (skill, invokes arn-code-feature-planner agent)
  outputs: PLAN_PREVIEW_<spec-name>.md written to <plans-dir>/
  consumed by: arn-code-save-plan (reads PLAN_PREVIEW from plans directory)

arn-code-save-plan
  inputs: PLAN_PREVIEW_<spec-name>.md from <plans-dir>/, spec file from <specs-dir>/
  outputs: project directory with INTRODUCTION.md, SOURCE_PLAN.md, TASKS.md, phase plans
  consumed by: arn-code-review-plan, arn-code-taskify, arn-code-execute-plan

arn-code-review-plan
  inputs: project directory (phase plans, INTRODUCTION.md)
  outputs: review findings (presented to user, not saved to file)
  consumed by: user decision (proceed or revise)

arn-code-taskify
  inputs: TASKS.md from project directory
  outputs: Claude Code task list with dependencies (via TaskCreate/TaskUpdate)
  consumed by: arn-code-execute-plan, arn-code-execute-task, arn-code-execute-plan-teams

arn-code-execute-plan / arn-code-execute-plan-teams / arn-code-execute-task
  inputs: task list, project directory, pattern docs, report templates
  outputs: execution reports in <project>/reports/ (implementation, testing, review) + updated <project>/PROGRESS_TRACKER.json
  consumed by: arn-code-review-implementation, arn-code-document-project

arn-code-review-implementation
  inputs: project directory, reports, pattern docs
  outputs: review findings with verdict (PASS / PASS WITH WARNINGS / NEEDS FIXES)
  consumed by: user decision (proceed or fix)

arn-code-document-project
  inputs: project directory, reports, spec, git diff
  outputs: documentation in <docs-dir>/
  consumed by: user (final documentation)

arn-code-standard
  inputs: user request, ## Arness config, pattern docs, report templates
  outputs: STANDARD_<name>.md (combined spec-lite + plan), STANDARD_REPORT.json, CHANGE_RECORD.json in <plans-dir>/STANDARD_<name>/
  consumed by: arn-code-ship (reads CHANGE_RECORD.json for PR context)

arn-code-ship
  inputs: git state, Arness context (optional), CHANGE_RECORD.json (if present)
  outputs: commit, push, PR (optional)
  consumed by: arn-code-review-pr (after PR receives feedback)

arn-planning (entry point)
  inputs: detects current pipeline state from artifacts on disk
  outputs: drives spec → plan → build → ship for new features or bug fixes
  consumed by: user (full development workflow)

arn-implementing (entry point)
  inputs: existing plan artifacts in plans directory
  outputs: resumes or executes plan through build → review → ship; generates CHANGE_RECORD.json for thorough-tier projects at completion (G5)
  consumed by: arn-code-ship (reads CHANGE_RECORD.json for PR context), user (implementation workflow)

arn-shipping (entry point)
  inputs: git state, Arness context (optional)
  outputs: commit, push, PR
  consumed by: user (shipping workflow)

arn-reviewing-pr (entry point)
  inputs: PR feedback from GitHub/Bitbucket
  outputs: validated findings, fixes or deferrals
  consumed by: user (PR review workflow)

arn-assessing (entry point)
  inputs: codebase, pattern docs
  outputs: assessment findings, guided improvement execution
  consumed by: user (assessment-driven improvement workflow)
```

## Version Upgrade History

Maintainers update this section when bumping the plugin version to document what changed.

### 0.4.0 → 0.5.0
- New config fields: Git, GitHub, Docs directory (7 → 10 fields)
- New directories: docs directory
- New GitHub labels: 7 arness-* labels
- New skills: arn-code-document-project, arn-code-review-pr, arn-code-ship, arn-code-create-issue, arn-code-pick-issue, arn-code-report
- New agent: arn-code-doctor

### 0.5.0 → 0.6.0
- Added upgrade mode to arn-code-init (diagnose + fix gaps instead of full re-init)
- arn-code-doctor now supports comprehensive health checks for upgrade mode

### 0.8.0 → 0.9.0
- New config fields: Platform, Issue tracker, Jira site, Jira project
- Removed config field: GitHub (replaced by Platform + Issue tracker)
- Auto-migration in upgrade flow: `GitHub: yes` becomes `Platform: github` + `Issue tracker: github`
- New prerequisites: `bkt` CLI (Bitbucket), Atlassian MCP Server (Jira)
- Bitbucket Cloud support for PR operations via `bkt` CLI
- Jira Cloud support for issue operations via Atlassian Remote MCP Server

### 0.12.0 → 0.13.0
- Simplified PROGRESS_TRACKER.json schema (removed duplicated per-task/test detail, references per-phase reports instead)
- Progress tracker now updated during execution (arn-code-execute-plan, arn-code-execute-task, arn-code-execute-plan-teams)
- Fixed PROGRESS_TRACKER.json location: project root (not reports/)
- Fixed template name reference: PROJECT_PROGRESS_REPORT_TEMPLATE.json (was PROGRESS_TRACKER_TEMPLATE.json)
- Execution-complete detection now checks `overallStatus` field instead of file presence

### 0.13.1 → 0.14.0
- Converted arn-code-plan from command to skill with planner feedback loop
- Rewrote arn-code-feature-planner agent to generate and write plans to PLAN_PREVIEW files
- Updated arn-code-save-plan to read from PLAN_PREVIEW_*.md in plans directory (legacy fallback to ~/.claude/plans/)
- New skill: arn-code-wizard — guided pipeline orchestrator (later replaced by 5 entry points: arn-planning, arn-implementing, arn-shipping, arn-reviewing-pr, arn-assessing)
- Removed all plan mode (Shift+Tab) references from pipeline documentation

### 0.14.0 → 0.15.0
- Added draft pattern to arn-code-feature-spec: writes DRAFT_FEATURE_<name>.md after initial analysis, updates during exploration, finalizes to FEATURE_<name>.md
- Draft resume detection: skill detects existing DRAFT files and offers to resume exploration
- New pipeline stage: `spec-draft` detected by arn-code-help when a draft spec exists but is not yet finalized

### 0.15.0 → 0.16.0
- Comprehensive skill review: fixed 3 critical, 16 major, and 30+ minor issues across 20 skills
- Fixed config field count documentation (10 → 13 fields including conditional Jira fields)
- Added Jira site/project columns to config requirements table
- Fixed step reference errors in arn-code-feature-spec (Step 1c → Step 1d)
- Fixed validation range in arn-code-review-plan (sections 1-4, 6-7 → 1-4, 6-8)
- Added PROGRESS_TRACKER.json to arn-code-execute-plan-teams Step 2 directory listing
- Removed stale XML artifact from arn-code-save-plan
- Progressive disclosure: extracted greenfield-loading.md, xl-decomposition.md, agent-invocation-guide.md from arn-code-feature-spec
- Progressive disclosure: extracted greenfield-backlog-resolution.md from arn-code-pick-issue
- Progressive disclosure: extracted feature-tracker-update.md from arn-code-ship
- Added Bitbucket/Jira parity to arn-code-review-pr (description, Steps 5-6)
- Added negative triggers to arn-code-review-implementation description
- Added missing-patterns fallback to arn-code-plan
- Added batch size limit (5 concurrent) to arn-code-execute-plan dispatch loop
- Added trigger phrases across 13 skills for better discovery
- Added limitations documentation to arn-code-feature-spec-teams (no greenfield, no XL, no drafts)
- Added commit convention detection to arn-code-ship
- Added trigger message inference to arn-code-create-issue
- Standardized AskUserQuestion references in arn-code-review-plan
- Fixed fragile cross-reference in arn-code-bug-spec (now points to template-versioning.md)
- Added fallback file naming convention (arness-report-YYYY-MM-DD.md) to arn-code-report
- Fixed hardcoded template count in arn-code-init ("6 JSON templates" → "all JSON templates")

### 2.1.1 → 2.2.0
- New skill: `arn-code-standard` — collapsed spec-plan-execute for medium complexity (standard ceremony tier)
- New artifacts: `STANDARD_<name>.md` (combined spec-lite + plan), `STANDARD_REPORT.json` (standard execution report), `CHANGE_RECORD.json` (unified change envelope produced by all three tiers)
- New templates: `STANDARD_REPORT_TEMPLATE.json`, `CHANGE_RECORD_TEMPLATE.json` (8 → 10 templates)
- Modified skill: `arn-planning` — Step 3 replaced with 6-criterion severity-weighted scope router (file count, domain sensitivity, arch change, cross-module, reversibility, test infra); recommends swift/standard/thorough tier
- Modified skill: `arn-implementing` — state detection updated to recognize STANDARD_* artifacts; routes to arn-code-standard for standard tier
- Modified skill: `arn-code-swift` — now produces CHANGE_RECORD.json alongside SWIFT_REPORT.json
- Modified skill: `arn-code-ship` — consumes CHANGE_RECORD.json for PR context enrichment
- Modified reference: `template-setup.md` — template list updated from 8 to 10
- Modified reference: `pipeline-map.md` — three-tier diagram, STANDARD_* detection rules, standard next-step suggestions
- Modified reference: `arness-knowledge-base.md` — this file; pipeline map, config table, directory structure, failure modes, data flow, version history
- New reference: `scope-router-criteria.md` — externalized 6-criterion weighted scoring for scope router
- New reference: `standard-plan-template.md` — template for standard tier combined spec-lite + plan

## Version Information

- Plugin version is in `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json` (field: `version`)
- Template version in user config tracks which plugin version templates were copied from
- Skill versions are in each SKILL.md frontmatter (field: `version`)
