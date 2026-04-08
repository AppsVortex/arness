---
name: arn-code-save-plan
description: >-
  This skill should be used when the user says "save plan", "save the plan",
  "arness code save plan", "structure this plan", "create project from plan",
  "export plan", "export project plan", "organize this plan",
  "set up project structure", "turn this into a project",
  "generate project structure", "finalize the plan", or wants to convert a
  planning
  conversation into an actionable phased project structure with implementation
  and testing plans.
version: 2.0.0
---

# Arness Save Plan

Convert a planning conversation into a structured, executable project with phased implementation plans, testing plans, task lists, and progress tracking.

This skill requires Arness to be configured in the target project. If Arness configuration is not found in the project's CLAUDE.md, the user should run `/arn-planning` to get started.

## Workflow

### Step 1: Check Arness Configuration

Read the project's CLAUDE.md and look for a `## Arness` section. Also check for a legacy `## Arness Save Plan` section (from earlier versions of this skill).

**If `## Arness` is found**, extract:
- **Plans directory** -- base path where project plans are saved
- **Specs directory** -- path to the directory containing specification files
- **Report templates** -- `default` or `custom`
- **Template path** -- path to the report template set (JSON templates)
- **Template version** -- plugin version the templates were copied from (if present)
- **Template updates** -- user preference: `ask`, `auto`, or `manual` (if present)
- **Code patterns** -- path to the directory containing stored pattern documentation

Validate that all paths exist on disk. If any path is missing, warn the user before proceeding.

#### Template Version Check

If the `## Arness` section contains `Template version` and `Template updates` fields, compare the project's template version against the plugin version. If they differ, check for user modifications via checksums and either auto-update, prompt the user, or skip based on the configured preference. If `## Arness` does NOT contain these fields, treat as legacy and skip.

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-save-plan/references/template-versioning.md` for the full template version check procedure.

**If legacy `## Arness Save Plan` is found but no `## Arness`**, offer to migrate:
1. Inform the user: "I found a legacy `## Arness Save Plan` section. Arness now uses a unified `## Arness` configuration section."
2. Ask (using `AskUserQuestion`):

   **"Should I migrate this to the new format?"**

   Options:
   1. **Yes, migrate** -- Rename the section and add new fields
   2. **No, keep legacy** -- Proceed using legacy values

3. If **Yes, migrate**:
   - Rename the section to `## Arness`
   - Add the **Code patterns** field with a default value of `.arness/`
   - Update the section in CLAUDE.md in place
4. If **No, keep legacy**: proceed using the legacy values, treating the missing Code patterns path as `.arness/`

**If NEITHER section is found**, Arness has not been configured:
1. Inform the user: "Arness is not configured for this project yet. Run `/arn-planning` to get started — it will set everything up automatically." Do not proceed without it.

---

### Step 2: Initialize Project Structure

Ask the user for `PROJECT_NAME` if not already provided in the conversation.

#### Resolve the Plan File

Look for a PLAN_PREVIEW file in the plans directory:

1. Search for files matching `PLAN_PREVIEW_*.md` in `<plans-dir>/`
2. **If exactly one PLAN_PREVIEW file exists:** use it automatically. If PROJECT_NAME was not provided, derive it from the preview filename (e.g., `PLAN_PREVIEW_websocket-notifications.md` → `websocket-notifications`).
3. **If multiple PLAN_PREVIEW files exist:** list them and ask the user to choose.
4. **If no PLAN_PREVIEW files exist:** check `~/.claude/plans/` as a legacy fallback. If plans are found there, show the most recent and ask the user to confirm. If nothing is found anywhere, inform the user: "No plan found. Run `/arn-code-plan` to create one first."

#### Create Project Structure

Run the setup script with the resolved plan file path:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/arn-code-save-plan/scripts/save_plan.sh <PROJECT_NAME> <OUTPUT_DIR> <resolved-plan-file-path>
```

This creates:
```
<OUTPUT_DIR>/<PROJECT_NAME>/
├── SOURCE_PLAN.md
├── plans/
└── reports/
```

If the script fails (non-zero exit code), report the error output to the user. Common causes: output directory does not exist, disk permissions, or PROJECT_NAME contains invalid characters. Do not proceed to Step 3 until the project structure is successfully created.

---

### Step 3: Write INTRODUCTION.md

Create `<OUTPUT_DIR>/<PROJECT_NAME>/INTRODUCTION.md` using the template from `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-save-plan/references/templates.md`.

#### Source Material

The INTRODUCTION.md draws from up to THREE sources:

1. **SOURCE_PLAN.md** — the plan (execution structure, phases/steps)
2. **Specification file (optional)** — for architectural context and decisions
3. **Stored pattern documentation** — for codebase patterns and references

**Finding the specification:**
- Search SOURCE_PLAN.md for a line matching `Spec: <path>` — if found, read that file
- If not found, search the specs directory (from `## Arness` config) for files whose name matches the PROJECT_NAME pattern (e.g., project `websocket-notifications` matches spec `FEATURE_websocket-notifications.md` or `BUGFIX_websocket-notifications.md`)
- If multiple matches, ask the user which spec applies
- If no spec is found, proceed using only SOURCE_PLAN.md and pattern docs

#### Populating Sections

Use Claude's intelligence to interpret the source material and populate each INTRODUCTION.md section. Do NOT rely on exact section name matching — extract the relevant information regardless of how the source material is structured.

| INTRODUCTION.md Section | Primary Source | Fallback |
|------------------------|---------------|----------|
| Project Overview | Spec (Problem Statement / Bug Report) | Plan (any overview/summary content) |
| Architectural Definition | Spec (Architectural Assessment) | Plan (any architecture/design content) |
| Codebase Patterns | Stored pattern docs (code-patterns.md, testing-patterns.md, ui-patterns.md if present) | Stored pattern docs (code-patterns.md, testing-patterns.md) |
| Codebase References | Stored pattern docs (architecture.md) | Stored pattern docs (architecture.md) |
| Sketch Artifacts (conditional) | Spec (Sketch Reference section) | Scan `arness-sketches/` for matching manifests |
| Scope & Boundaries | Spec (Scope & Boundaries) | Plan (any scope content) |
| Dependencies | Spec or Plan | Infer from components mentioned |
| Phase Overview | Plan (logical phases/steps) | Single phase if plan has no explicit phases |

**Phase identification from SOURCE_PLAN.md:** Plans may use any structure. Identify logical phases by looking for:
- Explicit phase/step headers (any naming convention)
- Numbered task groups
- Sections that describe sequential work with dependencies
- If the plan is a flat task list, group related tasks into logical phases
- If no phases are identifiable, treat the entire plan as a single phase

**Finding sketch artifacts:** Check whether the specification file (if found) contains a `## Sketch Reference` section. If it does, extract the sketch directory path, manifest path, blueprint path, and component mapping table from that section and populate the `### Sketch Artifacts` subsection in the Codebase References section of INTRODUCTION.md. If no spec is found or the spec has no Sketch Reference section, fall back to scanning the project root for a `arness-sketches/` directory. If a `arness-sketches/` directory exists, look for a subdirectory whose name matches the PROJECT_NAME (by name or keyword overlap). If a matching sketch directory is found with a `sketch-manifest.json` containing `componentMapping` and `composition` fields, populate the Sketch Artifacts subsection from the manifest data. If no sketch is found through either method, omit the Sketch Artifacts subsection entirely.

Every pattern in INTRODUCTION.md MUST reference real files and real code from the codebase. Do not use placeholder content — the INTRODUCTION.md is the ground truth that all phase plans reference.

---

### Step 4: Create Phase Plans

For each phase identified in Step 3's Phase Overview, create `<OUTPUT_DIR>/<PROJECT_NAME>/plans/PHASE_<N>_PLAN.md` using the combined template from `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-save-plan/references/templates.md`.

**Extracting phase content from SOURCE_PLAN.md:** The plan may use any structure. For each phase identified in Step 3:
- Find the corresponding content in SOURCE_PLAN.md by matching headers, numbered sections, or task groups
- Extract deliverables, tasks, and any dependency information
- If the plan lists tasks without explicit phases, use the grouping established in Step 3's Phase Overview

**If SOURCE_PLAN.md has no explicit phases:** Treat the entire plan as Phase 1, or intelligently split it into phases based on logical groupings (e.g., infrastructure first, then features, then integration).

Each phase plan always has an Implementation section. Include a Testing section only if the SOURCE_PLAN.md describes tests, test cases, or test infrastructure for that phase. If the source plan contains no testing content, omit the Testing section entirely.

**Implementation section:**
- Tasks with pattern-specific instructions referencing INTRODUCTION.md
- Every task references concrete files and patterns (with file paths and line numbers)
- Include class/function structure, method signatures, integration points
- Report directive pointing to the configured template path

**Testing section (when applicable):**
- Test cases referencing the test infrastructure from INTRODUCTION.md
- Every test references concrete fixtures, helpers, and markers
- Include the self-healing directive: if tests reveal implementation bugs, fix them, document in the report with "FIXED:" prefix, and re-run until all tests pass
- Report directive pointing to the configured template path

---

### Step 5: Generate TASKS.md and PROGRESS_TRACKER.json

**TASKS.md** — Create `<OUTPUT_DIR>/<PROJECT_NAME>/TASKS.md` using the template from `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-save-plan/references/templates.md`.

Rules:
- Sequential task numbering (Task 1, Task 2, Task 3...)
- Implementation tasks first. If any phase plans have Testing sections, add testing tasks after all implementation tasks
- Each task specifies: project folder, plan file + section, dependencies
- Each test task depends on its corresponding implementation task AND the previous test task
- If no phase plans have Testing sections, omit the "Testing Tasks" section entirely
- No worker IDs — all tasks are sequential

**PROGRESS_TRACKER.json** — Create `<OUTPUT_DIR>/<PROJECT_NAME>/PROGRESS_TRACKER.json` using `PROJECT_PROGRESS_REPORT_TEMPLATE.json` from the configured template path as the schema.

Populate with:
- `projectName`: the PROJECT_NAME
- `lastUpdated`: current ISO 8601 timestamp
- `overallStatus`: `"not_started"`
- `totalPhases`: count of phases
- One entry per phase in `phases[]`:
  - `phaseNumber`, `phaseTitle`, `planFile` from the phase plans
  - `implementation.status`: `"not_started"`, `implementation.taskId`: the implementation task number from TASKS.md for this phase, `implementation.reportFile`: `reports/IMPLEMENTATION_REPORT_PHASE_N.json`
  - `testing.status`: `"not_started"` if the phase has a Testing section, or `"none"` if it does not. `testing.taskId`: the testing task number from TASKS.md (or `null` if no testing), `testing.reportFile`: `reports/TESTING_REPORT_PHASE_N.json`
  - `review.verdict`: empty string, `review.reviewCycles`: `0`, `review.reportFile`: `reports/TASK_REVIEW_TASK_N.json`

---

### Step 6: Verify Completion

Review all created files and confirm with the user:

- [ ] SOURCE_PLAN.md copied from the selected plan
- [ ] INTRODUCTION.md has real codebase patterns with file paths and code snippets
- [ ] Each PHASE_N_PLAN.md has concrete implementation instructions (and testing instructions if the source plan includes testing)
- [ ] TASKS.md has the correct sequential dependency chain
- [ ] PROGRESS_TRACKER.json is populated with all phases and tasks
- [ ] CLAUDE.md has `## Arness` configuration section

List all created files with their paths.

**Next steps:**
- Optionally run `/arn-code-review-plan` to validate the plan before execution
- Run `/arn-code-taskify` to convert TASKS.md into a Claude Code task list

## Output Structure

```
<OUTPUT_DIR>/<PROJECT_NAME>/
├── SOURCE_PLAN.md
├── INTRODUCTION.md
├── TASKS.md
├── PROGRESS_TRACKER.json
├── plans/
│   ├── PHASE_1_PLAN.md
│   ├── PHASE_2_PLAN.md
│   └── ...
└── reports/
    └── (populated during execution)
```
