---
name: arn-code-execute-plan
description: >-
  This skill should be used when the user says "execute plan", "run the plan",
  "start execution", "execute project", "execute all tasks", "run all tasks",
  "run plan in parallel", "execute with review gates", or wants to execute
  a full structured project plan after tasks have been created via arn-code-taskify.
  This skill runs ALL tasks from the task list — for executing a single specific
  task, use arn-code-execute-task instead. For Agent Teams mode, use
  arn-code-execute-plan-teams. Do NOT use this skill when executing a single task —
  use `/arn-code-execute-task` instead.
version: 0.4.0
---

# Arness Execute Plan

Execute a structured project plan by dispatching parallel batches of `arn-code-task-executor` agents and validating each completed task through a `arn-code-task-reviewer` agent before marking it done. Independent tasks run concurrently; dependent tasks wait for their blockers to clear. Each task goes through an execute-review-gate cycle: the executor implements and tests, the reviewer validates against patterns and acceptance criteria, and the orchestrator (this skill) decides whether to pass, retry, or escalate.

**Key architectural constraint:** Subagents cannot spawn other subagents. The dispatch loop MUST stay in the main session (this skill).

Pipeline position:
```
arn-code-init -> arn-code-feature-spec / arn-code-bug-spec -> arn-code-plan -> arn-code-save-plan -> arn-code-review-plan -> arn-code-taskify -> **arn-code-execute-plan** (dispatch -> execute -> review -> gate) -> arn-code-review-implementation -> arn-code-document-project -> arn-code-ship
```

## Prerequisites

If no `## Arness` section exists in the project's CLAUDE.md, inform the user: "Arness is not configured for this project yet. Run `/arn-implementing` to get started — it will set everything up automatically." Do not proceed without it.

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

2. Ask the user for `PROJECT_NAME` if not provided in the trigger message

3. Verify the project directory exists and contains the required structure:
   ```
   <plans-dir>/<PROJECT_NAME>/
   ├── INTRODUCTION.md
   ├── TASKS.md
   ├── PROGRESS_TRACKER.json
   ├── plans/PHASE_*.md
   └── reports/
   ```

4. If the project directory is missing, suggest running `/arn-code-save-plan` first
5. If INTRODUCTION.md or phase plans are missing, suggest running `/arn-code-save-plan` first
6. If `PROGRESS_TRACKER.json` is missing, warn that progress tracking will not be available. Execution can still proceed.
7. If `### Visual Testing` is configured in CLAUDE.md, note the presence of visual testing. Per-task execution uses Layer 1 config only (top-level fields). Multi-layer visual validation is handled by `/arn-code-review-implementation` after plan execution completes.
8. **Detect sketch artifacts** -- Read `<project-folder>/INTRODUCTION.md` and check for a `### Sketch Artifacts` section. If found, extract the sketch manifest path listed there (typically a relative path to `sketch-manifest.json`). Resolve it to an absolute path relative to the project directory. Also resolve the sketch directory path (the parent directory of the manifest). If no Sketch Artifacts section is found, check for manifests by scanning `arness-sketches/` in the project's source directory for any `sketch-manifest.json` matching `PROJECT_NAME`. Store the resolved manifest path and sketch directory path for use in the dispatch loop (Step 4). If no manifest is found from either source, proceed normally -- the dispatch loop will not pass sketch context to executors.

---

### Step 2: Verify Task List and Build Dependency Graph

**Deferred Task List Setup:**

Check for **Task list ID** in `## Arness` config. If absent:

Ask (using `AskUserQuestion`):

**"Persistent task lists are not configured. Would you like to enable them? (Recommended — tasks survive across sessions)"**

1. **Yes** (Recommended) — Auto-generate ID from project directory name
2. **Yes, with custom ID** — Specify the task list ID
3. **No** — Keep tasks session-scoped

If Yes: derive ID (slugify project directory name or use custom ID), write to `.claude/settings.json` (create if needed, preserve existing env vars), add `Task list ID` to `## Arness` config. Inform: "Persistent task list configured."

If No: proceed without persistence. Inform (once): "Tasks will be session-scoped. Enable persistence anytime with `/arn-code-taskify`."

1. Call `TaskList` to check for existing tasks
2. If **no tasks exist**:
   - If `Task list ID` is configured in `## Arness`: tasks should have persisted — suggest: "No tasks found despite persistent task lists being configured. The task list may have been cleared. Run `/arn-code-taskify` to recreate tasks."
   - If `Task list ID` is NOT configured: "No tasks found. Tasks may have been lost when the previous session ended (session-scoped storage). Run `/arn-code-taskify` to recreate them. To enable persistent task lists for future sessions, run `/arn-code-taskify` which will offer to configure persistence."
3. If **tasks already exist with progress** (some in_progress or completed):
   - Show the current state (how many pending, in_progress, completed)
   - Ask (using `AskUserQuestion`):

     **"Tasks already exist with progress. How would you like to proceed?"**

     Options:
     1. **Resume** -- Continue execution from where it left off, picking up the next pending unblocked task
     2. **Restart** -- Warn that existing reports will be preserved but task statuses will be reset to pending; confirm before proceeding
4. Present the dependency graph:
   - Total number of tasks
   - How many tasks can run in the **first parallel batch** (unblocked, pending)
   - Dependency chain overview -- which tasks block which, showing the critical path
5. Confirm with the user before starting execution

---

### Step 3: Choose Review Feedback Mode

Ask (using `AskUserQuestion`):

**"How should Arness handle critical review findings?"**

Options:
1. **Resume executor with feedback** (Recommended) -- Resumes the original executor agent with its full implementation context, passing the reviewer's specific findings as new instructions. This preserves all state from the initial implementation pass.
2. **Dispatch fresh executor with review report** -- Spawns a brand-new executor agent with the original task context plus the full review report. Use this if resuming fails or if you prefer a clean slate for fixes.

Store the chosen mode for the duration of this execution session. This choice applies to all tasks; the user is not asked again unless execution is restarted.

---

### Step 4: Dispatch Loop

The dispatch loop identifies batches of unblocked pending tasks, spawns parallel executor agents, then spawns parallel reviewer agents for each completed executor. Review verdicts determine whether a task is marked complete, retried with feedback, or escalated to the user. The loop repeats until all tasks are completed or blocked.

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-execute-plan/references/dispatch-loop.md` for the full dispatch algorithm.

---

### Step 5: Report Completion

When all tasks are completed (or skipped/aborted by user), present a summary:

- **Total tasks completed** (out of total)
- **First-pass tasks** -- tasks that passed review on the first attempt
- **Fix-cycle tasks** -- tasks that needed one or more review-fix cycles (list which ones)
- **Implementation reports generated** (list file names)
- **Testing reports generated** (list file names)
- **Review reports generated** (list file names)
- **Escalations** -- any tasks that were escalated to the user during execution (what happened, what was decided)
- **Skipped tasks** -- any tasks the user chose to skip (if any)
- **Progress tracker** -- updated with final status in `<plans-dir>/<PROJECT_NAME>/PROGRESS_TRACKER.json`

If visual testing is configured, include in the completion summary:
- **Visual testing:** Layer 1 ran on [N] UI tasks. [If deferred layers exist:] Deferred layers: [names]. Run `/arn-spark-visual-readiness` to check activation status, then `/arn-code-review-implementation` for full multi-layer review.

Offer next steps:
- "Run `/arn-code-simplify` to review the implementation for reuse opportunities, quality issues, and efficiency improvements."
- "Run `/arn-code-review-implementation` to validate the full implementation against the plan and stored patterns."
- "Run `/arn-code-document-project` to generate developer documentation."
- "Run `/arn-code-ship` to commit and create a pull request."

---

### Step 5b: Pattern Refresh (auto)

After reporting completion, refresh stored pattern documentation to capture any new patterns introduced during implementation.

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-execute-plan/references/pattern-refresh.md` and follow the pattern refresh procedure.

This step is automatic and non-blocking. If the refresh fails, execution is still considered successful.

---

## Error Handling

- **`## Arness` config missing in CLAUDE.md** -- suggest running `/arn-implementing` to get started
- **Project directory missing** -- suggest running `/arn-code-save-plan` to create the project structure
- **No tasks in TaskList** -- suggest running `/arn-code-taskify` to convert TASKS.md into tasks
- **Executor agent fails or crashes** -- read the agent's output to identify what went wrong, report the failure details to the user, offer to retry the task (respawn executor with the same context)
- **Executor reports test failures.** Branch on the executor's classification (from the implementation/testing report's `unrelatedTestFailures` array and any 3-attempt self-heal failures):

  **Branch 1 — only `unrelatedTestFailures` reported (no 3-attempt self-heal failure):** the executor confirmed the failing tests are not related to the task's modified files. Show the full classification reasoning (test names, modified files checked, observed test imports). Then ask (using `AskUserQuestion`):

  > **One or more pre-existing tests are failing but appear unrelated to this task. How would you like to proceed?**
  > 1. **Address now** — pause this task, investigate and fix the failing tests
  > 2. **File a backlog issue and continue** — record the failures as a tracked issue, mark task complete
  > 3. **Continue with documented reason** — proceed without filing a backlog issue, annotate the task report

  Apply the choice. For "File a backlog issue", create the issue on the configured platform (`gh issue create` for github, Jira MCP for jira; if Issue tracker is `none`, warn the user and fall back to "Continue with documented reason"). Use the failing test names + classification reasoning as the issue body.

  **Branch 2 — executor reports a 3-attempt self-heal failure on a `related-or-uncertain` test (with or without additional `unrelatedTestFailures`):** present the full failure details (test name, error output, files involved). Then ask (using `AskUserQuestion`):

  > **A test failure persists after 3 fix attempts. The failure may be related to this task. How would you like to proceed?**
  > 1. **Retry with more context** — give the executor more guidance and try again
  > 2. **Skip the failing task** — mark this task as incomplete and continue with the rest
  > 3. **Abort execution** — stop the orchestrator now

  If `unrelatedTestFailures` are also present, mention them briefly in the preamble so the user understands the full picture, but the user's choice here governs the orchestrator's next action on the related failure.
- **Reviewer agent fails or crashes** -- report the failure to the user, offer two options: skip the review for this task (mark as completed without review) or retry the reviewer (respawn with the same context)
- **Review cycle exceeds max retries (2)** -- present the accumulated review findings to the user with full context, ask the user to choose: retry with more context (user provides additional guidance), skip the task and continue, or abort execution entirely
- **All remaining tasks blocked (circular dependencies)** -- this should have been caught by `arn-code-review-plan`; show the dependency graph (task IDs, names, and what each is blocked by) and ask the user to manually resolve by removing or reordering dependencies
- **Resume fails (API error or agent ID no longer valid)** -- fall back to fresh dispatch mode for this specific task, inform the user that resume was not possible and a fresh executor was dispatched instead
