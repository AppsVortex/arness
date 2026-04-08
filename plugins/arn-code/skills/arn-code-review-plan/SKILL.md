---
name: arn-code-review-plan
description: >-
  This skill should be used when the user says "review plan", "validate plan",
  "check plan", "sanity check the plan", "verify plan", "review my plan",
  "audit plan", "is my plan ready", or
  wants to validate a structured project plan for completeness, correctness,
  and pattern compliance before execution. Checks structural completeness,
  document quality, dependency graph consistency, codebase reference validity,
  and pattern compliance. Offers to fix found issues interactively and can
  proceed directly to arn-code-taskify when the plan passes.
version: 1.0.0
---

# Arness Review Plan

Validate and review a structured project plan for completeness, correctness, and pattern compliance before execution. Reports issues with severity classification and actionable fix suggestions, offers interactive remediation, and optionally proceeds to task creation.

## Workflow

### Step 1: Load the Project

Read the project's CLAUDE.md and look for a `## Arness` section. Extract:
- **Plans directory** — base path where project plans are saved
- **Code patterns** — path to the directory containing stored pattern documentation
- **Template path** — path to the report template set (JSON templates)

**If `## Arness` is not found:** inform the user: "Arness is not configured for this project yet. Run `/arn-planning` to get started — it will set everything up automatically." Do not proceed.

Ask the user for `PROJECT_NAME` if not provided in the conversation.

Read all project files from `<plans-dir>/<PROJECT_NAME>/`:

```
<plans-dir>/<PROJECT_NAME>/
├── SOURCE_PLAN.md
├── INTRODUCTION.md
├── TASKS.md
├── PROGRESS_TRACKER.json
└── plans/PHASE_*.md
```

If any critical files are missing (`SOURCE_PLAN.md`, `INTRODUCTION.md`, `TASKS.md`, or any `PHASE_*.md`), report the missing files immediately. Do not attempt to run checks against missing files — instead, note the missing file as an ERROR finding and continue checking the files that do exist.

---

### Step 2: Run Structural and Document Checks

Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-review-plan/references/validation-checks.md` and execute all generic checks (sections 1-4, 6-8) against the project files.

Classify each finding by severity:
- **ERROR** — Must fix before execution (missing files, broken dependencies, placeholder content)
- **WARNING** — Likely problems that should be addressed (missing patterns, incomplete coverage)
- **INFO** — Suggestions for improvement (optional enhancements)

For each finding, record:
- **Check ID** — the identifier from validation-checks.md (e.g., S001, I010, T015)
- **Severity** — ERROR, WARNING, or INFO
- **Description** — what the check found
- **File** — which project file the finding applies to
- **Location** — line number or section name within the file
- **Suggestion** — an actionable fix description

Suggested fixes must be specific and actionable. Examples:
- "Add 'Scope & Boundaries' section to INTRODUCTION.md after the Dependencies section"
- "Fix dependency: Task 4 references non-existent Task 9 — update to a valid task number"
- "Add report save path directive to Phase 2 Implementation section: `reports/IMPLEMENTATION_REPORT_PHASE_2.json`"

---

### Step 3: Verify Against Codebase

Validate that references in the plan actually exist in the codebase:

1. **Codebase References table** — Check that file paths listed in the INTRODUCTION.md "Codebase References" table actually exist on disk (use Glob for each path)
2. **Pattern code examples** — Spot-check 2-3 code pattern examples from INTRODUCTION.md: read the referenced file and confirm the code snippet is real and matches
3. **Test fixtures and helpers** — Verify test fixtures/helpers mentioned in INTRODUCTION.md testing patterns actually exist (use Grep to search for fixture/helper names in test files)

Add findings for any broken references. Suggestions should be specific:
- "Update path `src/old/module.py` to `src/new/module.py` in Codebase References table"
- "Remove stale reference to `conftest.py:db_session` — fixture no longer exists"
- "Code example for 'Service Layer' pattern does not match `src/services/base.py:15-30` — update snippet"

---

### Step 4: Check Pattern Compliance (Dynamic)

Read stored pattern docs from the Code patterns path in the `## Arness` config:
- `<code-patterns-dir>/code-patterns.md`
- `<code-patterns-dir>/testing-patterns.md`
- `<code-patterns-dir>/ui-patterns.md` (if it exists)

**Code pattern compliance:**
For each pattern documented in `code-patterns.md`:
- Check that phase plans reference or follow this pattern where relevant
- Flag if a phase plan contradicts a documented pattern (e.g., uses a different framework or approach than what's documented)
- Flag if a phase plan introduces patterns not found in the documentation

**Testing pattern compliance:**
For each testing pattern in `testing-patterns.md`:
- Verify test cases in phase plans use the documented test framework
- Check that test markers/tags match those defined in the testing patterns
- Check that test cases reference fixtures documented in the testing patterns
- Flag if test cases use markers or fixtures not found in the testing patterns

**UI pattern compliance (if `ui-patterns.md` exists):**
For each pattern documented in `ui-patterns.md`:
- Check that frontend tasks reference or follow UI patterns where relevant
- Flag if a phase plan uses a different component library or styling approach than what's documented
- Flag missing accessibility requirements when `ui-patterns.md` documents them

All pattern compliance findings are **WARNING** severity (not ERROR), since pattern compliance is advisory — the patterns may have been intentionally overridden for a specific phase.

Each finding includes a suggestion, e.g.:
- "Phase 2 test cases should use `@pytest.mark.unit` marker per testing patterns"
- "Phase 1 uses Flask-style routing but code-patterns.md documents FastAPI router pattern"
- "Phase 3 uses inline styles but ui-patterns.md documents Tailwind CSS approach"

---

### Step 5: Report

Present a human-readable summary to the user:

```
## Plan Review: <PROJECT_NAME>

### Summary
- Phases: N | Implementation tasks: N | Testing tasks: N
- Issues: N errors, N warnings, N info

### ERRORS (must fix)
1. [S001] INTRODUCTION.md missing — <project-dir>/
   → Fix: Re-run arn-code-save-plan to regenerate INTRODUCTION.md
2. [T013] Task 5 depends on "Task 9" but only 6 tasks exist — TASKS.md:45
   → Fix: Update dependency to correct task number
...

### WARNINGS (should fix)
1. [I012] Pattern "Service Layer" missing "How to apply" — INTRODUCTION.md:45
   → Fix: Add "How to apply" section with concrete instructions
...

### INFO (optional)
1. [Q004] Phase 3 has 9 implementation tasks — consider splitting
...
```

Every ERROR and WARNING includes a `→ Fix:` suggestion line.

If no issues are found, report: "Plan passed all checks — no issues found."

---

### Step 6: Remediate

Present the user with options based on what was found:

**If ERRORS exist:**

Ask the user (using AskUserQuestion):

1. **"Fix all errors automatically"** — attempt to fix every error using the suggested fixes. Edit the relevant plan files (INTRODUCTION.md, TASKS.md, PHASE_N_PLAN.md, PROGRESS_TRACKER.json).
2. **"Let me choose which to fix"** — show each error one at a time. For each, ask the user: fix or skip?
3. **"I'll fix them manually"** — exit with the report. Do not modify any files.

**If only WARNINGS exist (no errors):**

Ask the user (using AskUserQuestion):

1. **"Fix all warnings"** — attempt to fix every warning
2. **"Let me choose which to fix"** — show each warning one at a time, ask fix/skip
3. **"Skip — proceed as is"** — accept the plan with warnings

**If no issues:** skip this step entirely.

**For each fix applied:**
- Edit the relevant plan file in place
- Log the change: which file was modified, what was changed, which check ID it resolves

**After remediation:**
- Re-run only the checks that had findings to verify the fixes resolved them
- If any fixes failed or introduced new issues, report them to the user
- Update the findings with remediation status (`remediated: true` and the action taken)

---

### Step 7: Finalize and Next Steps

Generate a JSON report using the `REVIEW_REPORT_TEMPLATE.json` from the configured template path. Populate all sections:

- **summary** — total checks, error/warning/info counts, phases and tasks reviewed
- **Category sections** (structuralChecks, documentQuality, taskConsistency, patternCompliance, codebaseVerification, contentQuality) — status and category-specific findings
- **findings** — complete list of all findings with check IDs, severity, descriptions, files, locations, suggestions, and remediation status
- **remediation** — whether remediation was performed, counts, and action log
- **recommendation** — `ready` (0 errors), `fix_errors` (errors remain), or `needs_review` (warnings remain)
- **nextStep** — `arn-code-taskify` if ready, or `fix errors first`

Save the report to: `<plans-dir>/<PROJECT_NAME>/reports/REVIEW_REPORT.json`

Present the final status to the user:

- **If clean** (0 errors, 0 warnings or all fixed): "Plan is ready for execution."
- **If warnings remain**: "Plan has N remaining warnings but no blocking errors."
- **If errors remain**: "Plan still has N errors — fix before proceeding."

Offer the next step:
- "Would you like to proceed to `/arn-code-taskify` to create the Claude Code task list?"
- If yes — run `/arn-code-taskify` with the same `PROJECT_NAME`

## Error Handling

- If `## Arness` config is missing, do not proceed — suggest running `/arn-planning` to get started.
- If the project directory does not exist, report the error and suggest running `/arn-code-save-plan` first.
- If pattern documentation files are missing (for Step 4), skip pattern compliance checks and add an INFO finding: "Pattern docs not found — skipping pattern compliance. Run `/arn-planning` to generate pattern docs on first use."
- If the report cannot be written (permissions), print the JSON report to the conversation so the user can save it manually.
