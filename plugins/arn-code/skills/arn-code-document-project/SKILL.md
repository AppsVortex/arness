---
name: arn-code-document-project
description: >-
  This skill should be used when the user says "document project", "generate
  docs", "create documentation", "write docs", "arness code document", "arn-code-document-project", "document this
  feature", "document this fix", or wants to generate developer documentation
  for a completed feature or bug fix. Reads plan artifacts, spec files,
  execution reports, and git diff to produce accurate documentation. Do NOT use
  this for general-purpose documentation — this is specifically for Arness pipeline
  projects.
version: 1.0.0
---

# Arness Document Project

Generate developer documentation for a completed feature or bug fix by reading plan artifacts, spec files, execution reports, and git diff to produce accurate, reference-heavy documentation.

Pipeline position:
```
arn-code-execute-plan -> arn-code-review-implementation -> **arn-code-document-project** -> arn-code-ship
```

This skill produces a single documentation file (or directory for complex projects) that captures what was actually built, how it diverges from the original plan, and where to find everything in the codebase.

## Workflow

### Step 1: Load Configuration

1. Read the project's CLAUDE.md and extract the `## Arness` section to find:
   - **Plans directory** -- base path where project plans are saved
   - **Specs directory** -- path to the directory containing specification files
   - **Code patterns** -- path to the directory containing stored pattern documentation
   - **Docs directory** -- path to the directory where documentation is written
2. **Template version check**: If `Template version` and `Template updates` fields are present in the `## Arness` section, run the template version check procedure from `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-save-plan/references/template-versioning.md` before proceeding. If these fields are not present, treat as legacy and skip.
3. Ask for `PROJECT_NAME` if not provided in the trigger message.
4. Verify the project directory exists with reports: `<plans-dir>/<PROJECT_NAME>/reports/`
5. If Docs directory is not in config, default to `.arness/docs/`

---

### Step 2: Read Plan Artifacts

Read these files from `<plans-dir>/<PROJECT_NAME>/`:

1. **INTRODUCTION.md** -- project overview, goals, key decisions
2. **SOURCE_PLAN.md** -- original implementation plan
3. **All phase plans** in `plans/PHASE_*.md` -- acceptance criteria, expected files
4. **All reports** in `reports/` -- implementation reports, testing reports
5. **PROGRESS_TRACKER.json** -- overall completion status (if it exists)

If reports are missing, warn the user that the project may not have been fully executed yet and:

Ask (using `AskUserQuestion`):

**"Some reports are missing. The project may not have been fully executed yet. Proceed with available data?"**

Options:
1. **Yes, proceed** -- Generate documentation from the available data
2. **No, stop** -- Run execution first before generating documentation

---

### Step 3: Read Specification

Find the original specification:

1. Check SOURCE_PLAN.md for a `Spec:` line referencing the spec file path
2. If not found, try name-matching files in `<specs-dir>/` against the project name
3. If found, read the spec to extract: problem statement, key decisions, scope, components

If no spec is found, proceed without it (some projects may not have specs).

---

### Step 4: Analyze Git Diff

If Git is available (check `## Arness` config or run `git rev-parse --is-inside-work-tree`):

1. Determine the default branch (`git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'`, falling back to `main`), then find the merge base: `git merge-base HEAD <default-branch>`
2. Get change summary: `git diff --stat <merge-base>..HEAD`
3. Get file status: `git diff --name-status <merge-base>..HEAD`

Focus on key entry points -- don't read every changed file. Prioritize:
- **New files** (Added status)
- **Core implementation files** (models, services, API endpoints, configuration)
- **Test files** (for test coverage summary)

If Git is not available, skip this step and rely on report data only.

---

### Step 5: Identify Divergences

Compare what was planned (INTRODUCTION.md, phase plans, spec) with what was built (reports, git diff):

- Features planned but not implemented
- Features implemented differently than planned
- Additional features not in the original plan (scope additions)
- Bugs found and fixed during testing (from `bugsFixed` in reports)
- Different architectural approaches than specified

---

### Step 6: Generate Documentation

Use the template from `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-document-project/references/doc-template.md`.

**Single file** for simple projects (fewer than 15 changed files AND 3 or fewer phases):
- Write to `<docs-dir>/<PROJECT_NAME>.md`

**Directory** for complex projects:
- Write to `<docs-dir>/<PROJECT_NAME>/README.md` with subtopic files as needed

Doc name is derived from the project name (lowercase, hyphens).

---

### Step 7: Verify and Report

After writing:

1. Verify all file paths referenced in the documentation actually exist
2. Verify class/function names mentioned are accurate
3. Report to the user:
   - Documentation location and file(s) created
   - Key divergences found (plan vs reality)
   - Any gaps or concerns (e.g., missing reports, incomplete spec)

Suggest next step: "Run `/arn-code-ship` to commit your changes and create a pull request."

---

## Error Handling

- **`## Arness` config missing in CLAUDE.md** -- inform the user: "Arness is not configured for this project yet. Run `/arn-implementing` or `/arn-shipping` to get started — it will set everything up automatically."
- **Project directory missing** -- suggest running `/arn-code-save-plan` and `/arn-code-execute-plan` first.
- **Reports directory empty** -- suggest running `/arn-code-execute-plan` to generate reports.
- **Docs directory does not exist** -- create it with `mkdir -p`.
- **Git not available** -- skip git diff analysis, rely on report data only.
