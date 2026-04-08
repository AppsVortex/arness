---
name: arn-infra-save-plan
description: >-
  This skill should be used when the user says "save infra plan",
  "save infrastructure plan", "structure infra plan", "create infra project",
  "finalize infra plan", "arn infra save plan", "infra save plan",
  "save change plan", "structure infrastructure plan", "finalize infrastructure plan",
  "arn-infra-save-plan", or wants to convert a PLAN_PREVIEW_INFRA_*.md into
  a structured project directory with infrastructure-specific templates,
  report templates, and progress tracking.
version: 1.0.0
---

# Arness Infra Save Plan

Convert a `PLAN_PREVIEW_INFRA_*.md` plan preview into a structured project directory with infrastructure-specific INTRODUCTION.md, per-phase PHASE_N_PLAN.md files, TASKS.md, report templates, and a PROGRESS_TRACKER.json for execution tracking. This is the bridge between change-plan (which produces the preview) and execute-change (which consumes the structured project).

Pipeline position:
```
arn-infra-init -> arn-infra-change-spec -> arn-infra-change-plan -> **arn-infra-save-plan** -> arn-infra-execute-change -> arn-infra-review-change -> arn-infra-document-change
```

## Prerequisites

Read `## Arness` from the project's CLAUDE.md. If no `## Arness` section exists or Arness Infra fields are missing, inform the user: "Arness Infra is not configured for this project yet. Run `/arn-infra-wizard` to get started — it will set everything up automatically." Do not proceed without it.

Check the **Deferred** field. If `Deferred: yes`, inform the user: "Infrastructure is in deferred mode. Plan structuring is not available until infrastructure is fully configured. Run `/arn-infra-assess` to un-defer." Stop.

Extract:
- **Infra plans directory** -- where structured plan projects live (e.g., `.arness/infra-plans`)
- **Infra report templates** -- which report template set to use (default: `default`)
- **Infra template path** -- where to copy report templates for the project (e.g., `.arness/infra-templates`)
- **Infra template version** -- current template version for checksum tracking
- **Experience level** -- derived from user profile. Read `~/.arness/user-profile.yaml` (or `.claude/arness-profile.local.md` if it exists — project override takes precedence). Apply the experience derivation mapping from `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-ensure-config/references/experience-derivation.md`. If no profile exists, check for legacy `Experience level` in `## Arness` as fallback.

If **Infra plans directory** is not configured, stop and instruct the user: "Infra plans directory is not configured. Run `/arn-infra-init` to set up infrastructure pipeline configuration."

---

## Workflow

### Step 1: Locate Plan Preview

Search for `PLAN_PREVIEW_INFRA_*.md` files in the **Infra plans directory**.

```
Glob <infra-plans-dir>/PLAN_PREVIEW_INFRA_*.md
```

**If no preview found:**
Also check the project root:
```
Glob PLAN_PREVIEW_INFRA_*.md
```

**If exactly one preview found:** Auto-select it and present: "Found plan preview: `[filename]`. Proceeding to structure this plan."

**If multiple previews found:** Present the list:

Ask (using `AskUserQuestion`):

**"Which plan would you like to structure?"**

Options:
1. **[filename1]** -- [first line or title]
2. **[filename2]** -- [first line or title]
...

**If still no preview found:** Inform the user: "No PLAN_PREVIEW_INFRA_*.md found. Run `/arn-infra-change-plan` first to generate a plan preview."

---

### Step 2: Extract Plan Metadata

Read the selected plan preview file. Extract:
- **Project name** -- from the plan title (convert to kebab-case for directory name)
- **Phase count** -- number of phases defined
- **Phase titles** -- per-phase title and target environment
- **Total resources** -- count of resources across all phases
- **Blast radius summary** -- per-phase blast radius classification
- **Environment promotion order** -- environments in deployment sequence

Present a summary:

"**Plan Summary:**
- **Project:** [project name]
- **Phases:** [count]
- **Resources:** [total count]
- **Environments:** [list in promotion order]
- **Blast radius:** [summary]

Ask (using `AskUserQuestion`):

**"Proceed with structuring this plan?"**

Options:
1. **Yes** -- Structure the plan into a project directory
2. **No** -- Cancel

---

### Step 3: Create Project Directory Structure

Run the `save_infra_plan.sh` script to create the project directory:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-save-plan/scripts/save_infra_plan.sh "<project-name>" "<infra-plans-dir>" "<plan-preview-path>"
```

This creates:
```
<infra-plans-dir>/<project-name>/
├── SOURCE_PLAN.md          (copy of the original preview)
├── plans/                  (phase plan directory)
└── reports/                (execution report directory)
```

---

### Step 4: Generate INTRODUCTION.md

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-save-plan/references/infra-templates.md` for the INTRODUCTION.md template structure.

Generate `INTRODUCTION.md` in the project directory using the template from `infra-templates.md`. Populate all sections from the plan preview content:

- **Change Overview** -- what is changing and why
- **Infrastructure Context** -- providers, IaC tools, current state summary
- **Current State** -- existing resources, environment status
- **Target State** -- desired end state
- **Blast Radius Summary** -- per-phase classification
- **Rollback Strategy** -- checkpoint locations, rollback procedures
- **Environment Promotion Pipeline** -- promotion order, gates between environments
- **Cost Budget** -- per-phase estimates, total budget
- **Security Requirements** -- compliance frameworks, access controls

Write to: `<infra-plans-dir>/<project-name>/INTRODUCTION.md`

---

### Step 5: Generate PHASE_N_PLAN.md Files

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-save-plan/references/infra-templates.md` for the PHASE_N_PLAN.md template structure.

For each phase in the plan preview, generate a `PHASE_N_PLAN.md` file in the `plans/` directory using the infrastructure-specific template. Each phase plan includes:

- Phase Overview and target environment
- Resources table (create/modify/destroy with resource type, provider, action)
- Blast Radius classification and justification
- Rollback Checkpoint (what to snapshot, restore procedure)
- Security Requirements for this phase
- Cost Estimate (monthly delta)
- Dependencies
- Tasks (implementation task list)
- Acceptance Criteria

Write to: `<infra-plans-dir>/<project-name>/plans/PHASE_N_PLAN.md` (one per phase)

---

### Step 6: Generate TASKS.md

Generate `TASKS.md` with the consolidated task list from all phases. Format:

```markdown
# Tasks

## Phase 1: [title]
- [ ] TASK-P1-001: [description]
- [ ] TASK-P1-002: [description]

## Phase 2: [title]
- [ ] TASK-P2-001: [description]
...
```

Write to: `<infra-plans-dir>/<project-name>/TASKS.md`

---

### Step 7: Copy Report Templates

Copy the 3 infrastructure report templates from the plugin to the project's **Infra template path**:

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-save-plan/report-templates/default/INFRA_CHANGE_REPORT_TEMPLATE.json`
> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-save-plan/report-templates/default/INFRA_REVIEW_REPORT_TEMPLATE.json`
> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-save-plan/report-templates/default/INFRA_PROGRESS_REPORT_TEMPLATE.json`

Write each template to the **Infra template path** directory. Generate SHA-256 checksums for each copied template using `sha256sum` or `shasum -a 256` for future update detection.

Store checksums in `<infra-template-path>/.checksums.json`:
```json
{
  "version": "<infra-template-version>",
  "files": {
    "INFRA_CHANGE_REPORT_TEMPLATE.json": "<sha256>",
    "INFRA_REVIEW_REPORT_TEMPLATE.json": "<sha256>",
    "INFRA_PROGRESS_REPORT_TEMPLATE.json": "<sha256>"
  }
}
```

---

### Step 8: Generate PROGRESS_TRACKER.json

Generate `PROGRESS_TRACKER.json` in the project directory following the `INFRA_PROGRESS_REPORT_TEMPLATE.json` schema. Initialize all phases with `not_started` status:

```json
{
  "reportType": "infra-progress",
  "projectName": "<project-name>",
  "lastUpdated": "<current-iso-timestamp>",
  "overallStatus": "not_started",
  "totalPhases": <N>,
  "changeSpec": "<path-to-spec>",
  "changePlan": "<path-to-SOURCE_PLAN.md>",
  "phases": [
    {
      "phaseNumber": 1,
      "phaseTitle": "<title>",
      "planFile": "plans/PHASE_1_PLAN.md",
      "environment": "<target-env>",
      "blastRadius": "<classification>",
      "execution": { "status": "not_started", "reportFile": "reports/INFRA_CHANGE_REPORT_PHASE_1.json" },
      "securityGate": { "status": "not_started" },
      "costGate": { "status": "not_started" },
      "verification": { "status": "not_started" },
      "review": { "verdict": "", "reportFile": "" }
    }
  ],
  "notes": []
}
```

Write to: `<infra-plans-dir>/<project-name>/PROGRESS_TRACKER.json`

---

### Step 9: Present Summary

Adapt the summary presentation to the user's experience level.

**Expert:**
"**Structured project created:** `<infra-plans-dir>/<project-name>/`
- INTRODUCTION.md, [N] phase plans, TASKS.md, PROGRESS_TRACKER.json
- Report templates copied to `<infra-template-path>/`
- Run `/arn-infra-execute-change` to begin execution."

**Intermediate:**
Present the file tree with brief descriptions of each artifact and suggest the next step.

**Beginner:**
Present the file tree with explanations of what each file is for and a step-by-step guide for what to do next.

**Next steps:**
1. **Execute the plan** -- Run `/arn-infra-execute-change` to begin phased execution
2. **Review a phase plan** -- Read any `PHASE_N_PLAN.md` to review before execution
3. **Edit the plan** -- Modify any phase plan or INTRODUCTION.md before proceeding

---

## Error Handling

- **`## Arness` config missing:** Suggest running `/arn-infra-wizard` to get started. Stop.
- **No PLAN_PREVIEW_INFRA_*.md found:** Suggest running `/arn-infra-change-plan` to generate a plan preview first. Stop.
- **Directory creation fails:** Report the error with the path that failed. Check permissions and disk space.
- **Script execution fails:** Report the script error. Fall back to creating the directory structure manually using `mkdir -p`.
- **Template copy fails:** Report which template failed to copy. The project can still function -- templates can be copied manually later.
- **Checksum generation fails:** Warn: "Could not generate template checksums. Template update detection will not work until checksums are regenerated." Continue without checksums.
- **Re-running is safe:** Re-running overwrites INTRODUCTION.md, PHASE_N_PLAN.md files, TASKS.md, and PROGRESS_TRACKER.json. Report templates are only re-copied if checksums indicate they have not been customized. If checksums mismatch, ask the user: "Report templates have been customized. Overwrite with the latest versions, or keep your customizations?"
