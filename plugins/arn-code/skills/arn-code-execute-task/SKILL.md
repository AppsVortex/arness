---
name: arn-code-execute-task
description: >-
  This skill should be used when the user says "execute task N", "run task N",
  "implement task N", "re-run task N", "retry task N", "run single task",
  or wants to execute a single specific task from the task list with optional
  review. This is for ONE task only — for executing the full plan (all tasks),
  use arn-code-execute-plan instead.
version: 0.4.0
---

# Arness Execute Task

Execute a single task from the task list by spawning a `arn-code-task-executor` agent. Optionally run a `arn-code-task-reviewer` to validate the implementation before marking the task complete.

Pipeline position (this is an alternative entry point, not in the main pipeline):
```
arn-code-taskify -> arn-code-execute-task (single task) -> [optional] arn-code-review-implementation
```

Use cases:
- Re-running a failed task after manual intervention
- Testing a single phase independently
- Implementing one task without the full pipeline
- Retrying a task that was escalated during arn-code-execute-plan

## Prerequisites

If no `## Arness` section exists in the project's CLAUDE.md, inform the user: "Arness is not configured for this project yet. Run `/arn-implementing` to get started — it will set everything up automatically." Do not proceed without it. Task list must exist (run `/arn-code-taskify` first).

## Workflow

### Step 1: Load Configuration

1. Read the project's CLAUDE.md and extract the `## Arness` section to find:
   - **Plans directory** -- base path where project plans are saved
   - **Code patterns** -- path to the directory containing stored pattern documentation
   - **Template path** -- path to the report template set (JSON templates)
   - **Template version** -- plugin version the templates were copied from (if present)
   - **Template updates** -- user preference: `ask`, `auto`, or `manual` (if present)
   - **Specs directory** -- path to the directory containing specification files (if present)

   **Template version check:** If `Template version` and `Template updates` fields are present, run the template version check procedure documented in arn-code-save-plan Step 1 (Template Version Check) before proceeding. If `## Arness` does not contain these fields, treat as legacy and skip.

---

### Step 2: Identify the Task

- If user provided a task ID or number: verify it exists in TaskList
- If user provided a description: search TaskList for a matching task
- If no task specified: show all available tasks (pending, unblocked) and ask user to choose
- Show the selected task: ID, description, status, dependencies
- If task is blocked: warn user that dependencies haven't completed, ask if they want to proceed anyway

---

### Step 3: Choose Review Option

Ask (using `AskUserQuestion`):

**"Run with review gate after execution?"**

Options:
1. **Yes, review after execution** (Recommended) -- Spawn reviewer to validate
2. **No, execute only** -- Skip review, mark complete after executor finishes

If review chosen, also ask:

Ask (using `AskUserQuestion`):

**"How should Arness handle critical review findings?"**

Options:
1. **Resume executor with feedback** (Recommended) -- Resumes the original agent with its full implementation context
2. **Dispatch fresh executor with review report** -- Spawns a new executor with the review report as context

Store the choice for the execution session.

---

### Step 4: Execute the Task

1. Ask the user for `PROJECT_NAME` if not provided in the trigger message
2. Verify the project directory exists:
   ```
   <plans-dir>/<PROJECT_NAME>/
   ├── INTRODUCTION.md
   ├── TASKS.md
   ├── PROGRESS_TRACKER.json
   ├── plans/PHASE_*.md
   └── reports/
   ```
   If `PROGRESS_TRACKER.json` is missing, warn that progress tracking will not be available. Execution can still proceed.
3. Mark task as `in_progress` via TaskUpdate
4. Check if the project has `### Visual Testing` configured in the `## Arness` section of CLAUDE.md. If found, extract: capture script path, compare script path, baseline directory, diff threshold.

   Note: Extract only the top-level fields (implicit Layer 1). Do NOT parse `#### Layer N:` subsections — multi-layer visual validation runs during `/arn-code-review-implementation`, not per-task.

5. Spawn `arn-code-task-executor` via the Task tool with full context:
   - Task ID and full task description
   - Project name: `<PROJECT_NAME>`
   - Project folder path: `<plans-dir>/<PROJECT_NAME>/`
   - Phase plan file path (extracted from the task description)
   - INTRODUCTION.md path: `<project-folder>/INTRODUCTION.md`
   - Code patterns directory path: `<code-patterns-dir>/`
   - Specs directory path: `<specs-dir>/` (if relevant to the task)
   - Report template path: `<template-path>/`
   - Visual testing config (if configured): capture script path, compare script path, baseline directory, diff threshold
6. Record the agent ID returned by the Task tool (needed for resume mode)
7. Wait for executor to complete

---

### Step 5: Review (if requested)

1. Read the executor's output to extract:
   - Report file path(s)
   - List of files created and modified
   - Visual capture directory path (if reported)
2. Spawn `arn-code-task-reviewer` via the Task tool with:
   - Task ID and full task description
   - Project name and folder path
   - INTRODUCTION.md path
   - Code patterns directory path
   - Report template path (for TASK_REVIEW_REPORT_TEMPLATE.json)
   - Implementation/testing report path(s) from executor
   - List of files created/modified by executor
   - Visual testing config (if configured in Step 4): compare script path, baseline directory, diff threshold
   - Note: Only Layer 1 visual config is passed to the reviewer. Multi-layer visual validation runs during `/arn-code-review-implementation`.
   - Visual capture directory (if reported by executor)
3. Handle verdict:
   - **pass** -- mark task as completed via TaskUpdate
   - **pass-with-warnings** -- append warnings to implementation report (`reviewFindings` section), mark task as completed via TaskUpdate
   - **needs-fixes** -- apply chosen feedback mode:
     - **Resume mode:** resume the original executor agent (using its agent ID from Step 4.6, via the `resume` parameter of the Task tool) with review feedback, then re-run reviewer
     - **Fresh dispatch mode:** spawn a new executor with the review report + original context, then re-run reviewer
     - Maximum 2 review cycles, then escalate to user with full findings
4. After marking the task as completed (pass or pass-with-warnings), update `PROGRESS_TRACKER.json`:
   - Read `<plans-dir>/<PROJECT_NAME>/PROGRESS_TRACKER.json`
   - Find the phase entry whose `implementation.taskId` or `testing.taskId` matches this task
   - Set the matching status to `"completed"` and `completedAt` to current ISO 8601 timestamp
   - Set `review.verdict` to the reviewer's verdict and `review.reviewCycles` to the number of review cycles
   - If all phases now have `implementation.status = "completed"` (and `testing.status = "completed"` or `"none"`), set `overallStatus` to `"completed"`; otherwise set `overallStatus` to `"in_progress"` (if not already)
   - Update `lastUpdated` and write to disk
   - If no review was requested: same update but leave `review.verdict` and `review.reviewCycles` at their initial values
   - If `PROGRESS_TRACKER.json` does not exist, skip this step silently

---

### Step 6: Report Result

Show: what was implemented, tests run, review verdict, reports generated.

- If review passed: "Task N is complete. Progress tracker updated: Phase N implementation/testing completed. Overall: X of Y phases complete."
- If no review: "Task N execution complete (no review performed). Progress tracker updated."
- If escalated: present findings and ask user for guidance.

Offer next step: "Would you like to run `/arn-code-review-implementation` to validate the full project, or continue with another task?"

If the review verdict is **pass** or **pass-with-warnings**: also offer "Or run `/arn-code-simplify` to review the implementation for simplification opportunities before full review."

If deferred visual testing layers exist in CLAUDE.md (any `#### Layer N:` subsection with `**Status:** deferred`) and this task is the last task in a phase, suggest: "Deferred visual testing layers detected. Consider running `/arn-spark-visual-readiness` to check if they can be activated now that this phase is complete."

---

## Error Handling

- **`## Arness` config missing in CLAUDE.md** -- suggest running `/arn-implementing` to get started
- **No tasks in TaskList** -- suggest running `/arn-code-taskify` to convert TASKS.md into tasks
- **Task not found** -- show available tasks and ask user to select one
- **Task is blocked by incomplete dependencies** -- warn user, let them decide whether to proceed anyway
- **Project directory missing** -- suggest running `/arn-code-save-plan` to create the project structure
- **Executor fails** -- read agent output, report to user, offer retry
- **Executor reports test failures.** Branch on the executor's classification (from the implementation/testing report's `unrelatedTestFailures` array and any 3-attempt self-heal failures):

  **Branch 1 — only `unrelatedTestFailures` reported (no 3-attempt self-heal failure):** the executor confirmed the failing tests are not related to the task's modified files. Show the full classification reasoning (test names, modified files checked, observed test imports). Then ask (using `AskUserQuestion`):

  > **One or more pre-existing tests are failing but appear unrelated to this task. How would you like to proceed?**
  > 1. **Address now** — pause this task, investigate and fix the failing tests
  > 2. **File a backlog issue and continue** — record the failures as a tracked issue, mark task complete
  > 3. **Continue with documented reason** — proceed without filing a backlog issue, annotate the task report

  Apply the choice. For "File a backlog issue", create the issue on the configured platform (`gh issue create` for github, Jira MCP for jira; if Issue tracker is `none`, warn the user and fall back to "Continue with documented reason"). Use the failing test names + classification reasoning as the issue body.

  **Branch 2 — executor reports a 3-attempt self-heal failure on a `related-or-uncertain` test:** present failure details (test name, error output, files involved). Then ask (using `AskUserQuestion`):

  > **A test failure persists after 3 fix attempts. The failure may be related to this task. How would you like to proceed?**
  > 1. **Retry with more context** — give the executor more guidance and try again
  > 2. **Skip the failing task** — mark this task as incomplete and continue
  > 3. **Abort execution** — stop now

  If `unrelatedTestFailures` are also present in the same report, mention them briefly so the user has the full picture.
- **Reviewer fails** -- report to user, offer to skip review or retry
- **Review cycle exceeds 2 retries** -- escalate to user with full review findings, ask: retry with more context, skip review, or abort
- **Resume fails (API error or agent ID no longer valid)** -- fall back to fresh dispatch mode, inform user
