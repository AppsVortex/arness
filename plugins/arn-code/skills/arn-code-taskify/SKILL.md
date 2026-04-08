---
name: arn-code-taskify
description: >-
  This skill should be used when the user says "taskify", "create task list",
  "create tasks", "convert plan to tasks", "generate tasks from plan", "create tasks
  from plan", "turn plan into tasks", "arness code taskify", or wants to convert a structured project
  plan's TASKS.md into an executable Claude Code task list with proper
  dependency management.
version: 1.0.0
---

# Arness Taskify

Convert a project's TASKS.md into a Claude Code task list with dependency management. Reads the structured task definitions created by `arn-code-save-plan`, creates Claude Code tasks via `TaskCreate`, and wires up the dependency graph via `TaskUpdate`.

This skill does NOT execute tasks or assign them to agents — it only creates the task list. Execution happens after the task list is created, either manually or through Claude Code's task system.

## Workflow

### Step 1: Load the Project

Read the project's CLAUDE.md and look for a `## Arness` section. Extract:
- **Plans directory** — base path where project plans are saved

**If `## Arness` is not found:** inform the user: "Arness is not configured for this project yet. Run `/arn-planning` to get started — it will set everything up automatically." Do not proceed.

**Deferred Task List Setup:**

Check for **Task list ID** in `## Arness` config. If present: verify `CLAUDE_CODE_TASK_LIST_ID` environment variable is set and matches. If not set or mismatched, warn: "Task list ID is configured as `<id>` in `## Arness` but `CLAUDE_CODE_TASK_LIST_ID` is not set in the current environment. Tasks may not persist across sessions. Verify `.claude/settings.json` contains the correct env setting."

If absent:

Ask (using `AskUserQuestion`):

**"Persistent task lists are not configured. Would you like to enable them? (Recommended — tasks survive across sessions)"**

1. **Yes** (Recommended) — Auto-generate ID from project directory name
2. **Yes, with custom ID** — Specify the task list ID
3. **No** — Keep tasks session-scoped

If Yes: derive ID (slugify project directory name or use custom ID), write to `.claude/settings.json` (create if needed, preserve existing env vars), add `Task list ID` to `## Arness` config. Inform: "Persistent task list configured."

If No: proceed without persistence. Inform (once): "Tasks will be session-scoped. Enable persistence anytime with `/arn-code-taskify`."

Ask the user for `PROJECT_NAME` if not provided in the conversation.

Read `<plans-dir>/<PROJECT_NAME>/TASKS.md`.

If TASKS.md does not exist:
- Check if `<plans-dir>/<PROJECT_NAME>/` exists at all
- If the directory exists but TASKS.md is missing: "TASKS.md not found. Run `/arn-code-save-plan` to generate it."
- If the directory does not exist: "Project '<PROJECT_NAME>' not found in `<plans-dir>/`. Run `/arn-code-save-plan` to create the project structure."

---

### Step 2: Parse Tasks

Extract from each task entry in TASKS.md:

| Field | Source | Example |
|-------|--------|---------|
| Task number | `### Task N:` heading | `1` |
| Title | Text after task number | `Phase 1 Implementation - Infrastructure` |
| Plan file | `**Plan:**` line | `plans/PHASE_1_PLAN.md (Implementation section)` |
| Dependencies | `**Dependencies:**` line | `Task 1, Task 3` or `None` |
| Description | Body text after metadata lines | Full task instructions |

Build a task map:
```
{ taskNumber → { title, planFile, dependencies[], description } }
```

Validate the parsed data:
- No duplicate task numbers
- All dependency references point to valid task numbers (no "Task 9" when only 6 tasks exist)
- No circular dependencies

If validation fails, report the issues and:

Ask (using `AskUserQuestion`):

**"Validation issues found in TASKS.md. How would you like to proceed?"**

Options:
1. **Proceed** -- Skip invalid entries and create the remaining tasks
2. **Abort** -- Stop and fix TASKS.md before retrying

---

### Step 3: Create Tasks

For each task in sequential order (Task 1 first, Task 2 next, etc.), call `TaskCreate` with:

```
subject: "Task N: <Title>"
description: |
  Project: <PROJECT_NAME>
  Project folder: <plans-dir>/<PROJECT_NAME>
  Plan: <plan file path>

  <Full task description from TASKS.md>
activeForm: "Executing Task N: <Title>"
```

Build an ID map as tasks are created:
```
{ taskNumber → claudeTaskId }
```

Tasks MUST be created in sequential order. Claude Code assigns task IDs sequentially, and the ID map is used in the next step to wire up dependencies.

---

### Step 4: Set Up Dependencies

After ALL tasks are created, iterate through the task map and set up dependency relationships:

- For tasks with `Dependencies: None` — no action needed
- For tasks with dependencies — map TASKS.md task numbers to Claude Code task IDs using the ID map, then call `TaskUpdate`:
  ```
  TaskUpdate(taskId: "<claude_task_id>", addBlockedBy: ["<dep_id_1>", "<dep_id_2>"])
  ```

Example mapping:
```
TASKS.md: "Task 3 depends on Task 1"
ID map:   Task 1 → claude_id "5", Task 3 → claude_id "7"
Result:   TaskUpdate(taskId: "7", addBlockedBy: ["5"])
```

---

### Step 5: Verify

Call `TaskList` and present the results to the user:

- **Total tasks created** — should match the count in TASKS.md
- **Tasks immediately available** (no blockers) — ready to execute now
- **Tasks blocked** — list each with what it's waiting on
- **Dependency graph validation** — confirm the Claude Code task dependencies match what TASKS.md specified

If any discrepancy is found between the created task list and TASKS.md, warn the user and explain what differs.

Example output:
```
## Task List Created: <PROJECT_NAME>

Created N tasks from TASKS.md.

### Ready to execute (no blockers):
- Task 1: Phase 1 Implementation - Infrastructure
- Task 2: Phase 2 Implementation - API

### Blocked:
- Task 3: Phase 1 Testing - Infrastructure (waiting on: Task 1)
- Task 4: Phase 2 Testing - API (waiting on: Task 2, Task 3)

Dependency graph matches TASKS.md.

To start execution:
- `/arn-code-execute-plan` — execute all tasks sequentially with review gates
- `/arn-code-execute-plan-teams` — execute with Agent Teams (parallel, higher cost)
- `/arn-code-execute-task` — execute a single task
```

## Error Handling

- If `## Arness` config is missing, do not proceed — suggest running `/arn-planning` to get started.
- If TASKS.md is empty or has no parseable task entries, report the issue and suggest checking the file format.
- If `TaskCreate` fails for a specific task, report which task failed and continue creating the remaining tasks. The dependency setup in Step 4 will skip any task that was not created.
- If a circular dependency is detected during parsing, report the cycle and ask the user to fix TASKS.md before proceeding.
