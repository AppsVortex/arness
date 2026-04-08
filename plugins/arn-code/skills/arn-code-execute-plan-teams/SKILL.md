---
name: arn-code-execute-plan-teams
description: >-
  This skill should be used when the user says "execute plan with teams",
  "run plan teams", "execute with agent teams", "team execution",
  "execute plan with agent teams instead of subagents", "teams mode",
  "agent teams mode", "execute with teams",
  or wants to execute a structured project plan using Claude Code's
  experimental Agent Teams feature. Creates a team of executor, reviewer,
  and architect teammates that collaborate on task implementation with
  built-in quality gates. Requires the experimental Agent Teams feature
  to be enabled. For standard subagent-based execution, use
  arn-code-execute-plan instead.
version: 0.3.0
---

# Arness Execute Plan Teams

Execute a structured project plan using Claude Code's experimental Agent Teams feature. Creates a coordinated team of executor, reviewer, and architect teammates that work together on task implementation. Each task goes through an implement->review->gate cycle within the team.

Pipeline position:
```
arn-code-taskify -> **arn-code-execute-plan-teams** (team: execute -> review -> architect consult -> gate) -> arn-code-review-implementation
```

This is an alternative to `arn-code-execute-plan` (subagent-based). Use this when:
- You want tighter executor<->reviewer collaboration (direct messaging between teammates)
- You want an on-call architect for architectural questions during implementation
- You're working on a complex multi-phase project where quality gates matter most
- You accept 3-7x higher token usage for better coordination

## Prerequisites

If no `## Arness` section exists in the project's CLAUDE.md, inform the user: "Arness is not configured for this project yet. Run `/arn-implementing` to get started — it will set everything up automatically." Do not proceed without it. Task list must exist (run `/arn-code-taskify` first).

## Workflow

### Step 1: Check Agent Teams Availability

Run via Bash: `echo $CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`

**If the variable is not set, is empty, or is set to "0" or "false":**
Inform the user: "This skill requires Claude Code's experimental Agent Teams feature."

Provide setup instructions:
- Add to `~/.claude/settings.json` under `"env"`:
  ```json
  "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  ```
- Or set the environment variable before running Claude Code:
  ```bash
  CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 claude
  ```

Suggest the alternative: "You can use `arn-code-execute-plan` instead, which uses subagents and doesn't require Agent Teams."

**If enabled:** proceed to Step 2.

### Step 2: Load Configuration and Verify Project

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
5. If PROGRESS_TRACKER.json is missing, warn that progress tracking will not be available. Execution can still proceed.

6. Call `TaskList` to check for existing tasks
   - If **no tasks exist**, tell the user to run `/arn-code-taskify` first
   - If **tasks already exist with progress**, show state and:

     Ask (using `AskUserQuestion`):

     **"Tasks already exist with progress. How would you like to proceed?"**

     Options:
     1. **Resume** -- Continue execution from where it left off, picking up the next pending unblocked task
     2. **Restart** -- Reset task statuses to pending (existing reports will be preserved; confirm before proceeding)

### Step 3: Create the Team

> **Note:** Teammates should not claim tasks until Step 4 completes. The lead notifies the team when the task list is structured.

Create ONE team for the entire execution. Determine team size based on the number of unblocked parallel tasks:
- **1-3 unblocked tasks:** 1 executor teammate
- **4+ unblocked tasks:** 2 executor teammates (more executors add coordination overhead without proportional speedup)

Team composition:

**Executor teammate(s)** (1-2 instances based on task count):
- Role: Claims pending unblocked IMPL tasks, implements them, writes tests, runs targeted tests
- Spawn prompt includes:
  - Project name: `<PROJECT_NAME>`
  - Project folder path: `<plans-dir>/<PROJECT_NAME>/`
  - INTRODUCTION.md path (with instruction to read it first)
  - Code patterns directory path (with instruction to read code-patterns.md, testing-patterns.md, architecture.md, and ui-patterns.md if present)
  - Phase plan directory path
  - Report template path
  - Testing instructions: write tests if planned, run ONLY targeted tests (precise test file/function targeting: `pytest tests/test_specific.py::TestClass`, `jest --testPathPattern=specific.test.ts`), optionally broader module scope, NEVER full test suite
  - Task workflow: claim pending unblocked IMPL tasks from the shared task list via TaskUpdate, implement, test, generate implementation report to `<project-folder>/reports/`, mark IMPL task as completed via TaskUpdate
  - If the project has `### Visual Testing` configured in CLAUDE.md, include Layer 1 visual testing config (top-level fields only: capture script path, compare script path, baseline directory, diff threshold) in the spawn prompt. Instruct the executor to capture screenshots after implementing UI tasks, same as the dispatch loop executor.
- Model: Opus

**Reviewer teammate** (1 instance):
- Role: Claims unblocked REVIEW tasks, validates completed implementations, re-runs tests, classifies findings
- Spawn prompt includes:
  - Same project context as executor
  - TASK_REVIEW_REPORT_TEMPLATE.json path (from template path directory)
  - Review instructions: claim REVIEW tasks when they unblock (after corresponding IMPL completes), read the implementation report, re-run targeted tests, check pattern compliance and acceptance criteria, generate task review report to `<project-folder>/reports/`
  - Verdict logic: pass (mark REVIEW task complete) / pass-with-warnings (append warnings to implementation report, mark complete) / needs-fixes (message the executor directly with specific findings to fix, do NOT mark complete)
  - If the executor reported visual capture paths, include them along with Layer 1 visual testing config (top-level fields only: compare script path, baseline directory, diff threshold). Instruct the reviewer to run visual comparison against baselines and classify regressions, same as the dispatch loop reviewer.
  - Do NOT modify implementation files -- reviewer uses Bash only for running tests
- Model: Opus

**Architect teammate** (1 instance, on-call):
- Role: Consulted for architectural disputes, critical design questions, pattern clarification
- Spawn prompt includes:
  - architecture.md content (read and include in prompt)
  - code-patterns.md content (read and include in prompt)
  - ui-patterns.md content (read and include in prompt, if it exists)
  - INTRODUCTION.md content (read and include in prompt)
  - Instruction: remain idle until messaged by reviewer or executor. When consulted, provide architectural guidance based on documented patterns and decisions. Do not implement code. Do not claim tasks.
- Model: Opus (strategic reasoning)
- Initially idle -- activated only when reviewer or executor messages with an architectural question

### Step 4: Structure the Shared Task List

For each existing task in the Claude Code task list, create a corresponding REVIEW task:

For Task N (already in task list):
1. Rename/annotate as `IMPL-N: [original description]` if needed for clarity
2. Create `REVIEW-N: Review implementation of Task N` via TaskCreate
   - Block REVIEW-N on IMPL-N via TaskUpdate with addBlockedBy
   - Preserve original dependency chain for IMPL tasks

This creates pairs:
```
IMPL-1 (unblocked) -> REVIEW-1 (blocked by IMPL-1)
IMPL-2 (blocked by IMPL-1) -> REVIEW-2 (blocked by IMPL-2)
...
```

Executor teammates claim IMPL tasks via TaskUpdate (set status to in_progress). Reviewer teammate claims REVIEW tasks as they unblock.

### Step 5: Monitor and Coordinate

The lead (main session) monitors:
- **Task list progress** -- call TaskList periodically (every 30-60 seconds) to check for stalled tasks
- **Progress tracker** -- after each task is marked completed by the reviewer, the lead reads `<project-folder>/PROGRESS_TRACKER.json`, updates the matching phase entry status to `"completed"` with a `completedAt` timestamp and the review verdict/cycles, and writes it back to disk. This keeps the tracker current during team execution.
- **Teammate health** -- if a teammate goes idle unexpectedly, investigate
- **Review outcomes** -- if reviewer reports needs-fixes:
  - The reviewer messages the executor directly with findings
  - Executor fixes, reviewer re-reviews
  - If fix cycle exceeds 2 iterations, lead intervenes and escalates to user
- **Architect activation** -- if architect remains idle but should be consulted, the lead can message the reviewer to consult the architect on a specific issue

Intervention triggers:
- Teammate idle for extended period with pending tasks available
- Circular messaging (executor and reviewer stuck in a loop)
- All REVIEW tasks returning needs-fixes repeatedly
- Any teammate crash or error

### Step 6: Completion

When all IMPL and REVIEW tasks are completed:
- Finalize PROGRESS_TRACKER.json:
  - Read `<project-folder>/PROGRESS_TRACKER.json`
  - Verify all phase statuses are up to date (set any remaining phases with completed IMPL/REVIEW tasks to `"completed"`)
  - Set `overallStatus` to `"completed"` and update `lastUpdated`
  - Write PROGRESS_TRACKER.json to disk
- If the project has `### Visual Testing` configured in CLAUDE.md, include a visual testing summary: screenshots captured, baselines updated, visual diffs detected. Note any Layer 1 visual regressions that were flagged during execution.

**Pattern refresh (auto):** After finalizing progress tracking, refresh stored pattern documentation.

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-execute-plan/references/pattern-refresh.md` and follow the pattern refresh procedure.

This is automatic and non-blocking. If the refresh fails, note it in the summary but do not block completion.

- Present summary: total tasks, pass rate on first review, fix cycles needed, reports generated
- Show: "Progress tracker finalized in `<project-folder>/PROGRESS_TRACKER.json`"
- List all reports in `<project-folder>/reports/`
- Note token usage if available
- Offer: "Would you like to run `/arn-code-review-implementation` for a full project review?"

## Error Handling

- **Agent Teams not enabled** -- provide setup instructions, suggest `/arn-code-execute-plan` as alternative
- **`## Arness` config missing in CLAUDE.md** -- suggest running `/arn-implementing` to get started
- **Project directory missing** -- suggest running `/arn-code-save-plan` to create the project structure
- **No tasks in TaskList** -- suggest running `/arn-code-taskify` to convert TASKS.md into tasks
- **Teammate crashes** -- lead reports issue, suggests retrying the failed task or falling back to subagent mode (`/arn-code-execute-plan`)
- **Teammates deadlocked** -- lead intervenes with clarifying message, breaks the cycle
- **Executor and reviewer stuck in fix loop (>2 cycles)** -- lead escalates to user with findings
- **Architect unresponsive** -- lead messages architect directly, or provides architectural guidance itself based on pattern docs
- **Token budget exceeded** -- warn user, suggest completing remaining tasks with `/arn-code-execute-plan` (lower cost)
- **Task list inconsistency** -- if IMPL/REVIEW pairs get out of sync, lead reconciles by checking task statuses and re-aligning

## Cost Considerations

Agent Teams use significantly more tokens than the subagent-based arn-code-execute-plan. Expect:
- ~3-4x tokens for a 3-teammate team working 30 minutes
- ~5-7x tokens when teammates use plan mode extensively
- Each teammate is a full Claude Code session with its own context window

To keep costs manageable:
- All teammates use Opus. The architect's cost is justified by its strategic role — it stays idle until consulted.
- Shut down the team promptly when all tasks complete
- For simpler projects (fewer than 5 tasks, no complex dependencies), prefer `/arn-code-execute-plan` instead
