# Dispatch Loop Algorithm

This is the core orchestration loop for arn-code-execute-plan. It runs entirely in the main session. All agent spawning uses the `Task` tool.

```
  -- 0. Initialize progress tracking ------------------------------------

  Read PROGRESS_TRACKER.json from <project-folder>/PROGRESS_TRACKER.json.
  If the file exists:
    - Set overallStatus to "in_progress" and update lastUpdated.
    - Write the updated PROGRESS_TRACKER.json back to disk.
  If the file is missing:
    - Log a warning: "PROGRESS_TRACKER.json not found — progress tracking disabled."
    - Continue without progress tracking.

WHILE there are pending tasks:

  -- 1. Identify the next batch ------------------------------------------

  Call TaskList. Find all tasks that are:
    - status = pending
    - blockedBy list is empty (or all blockers are completed)

  If NO unblocked pending tasks found AND some tasks are in_progress:
    -> Wait and re-check TaskList (executors or reviewers are still running)

  If NO unblocked pending tasks found AND NO tasks are in_progress:
    -> All remaining tasks are blocked with no way to unblock
    -> ERROR: escalate to user, show the blocked tasks and their dependencies

  -- 2. Dispatch executors (PARALLEL) ------------------------------------

  Limit each parallel batch to at most 5 concurrent executor agents.

  For each unblocked pending task in this batch:
    a. Mark the task as in_progress via TaskUpdate
    b. Spawn a arn-code-task-executor agent via the Task tool with this prompt:
       - Task ID and full task description (from TaskGet)
       - Project name: <PROJECT_NAME>
       - Project folder path: <plans-dir>/<PROJECT_NAME>/
       - Phase plan file path (extracted from the task description, e.g., plans/PHASE_1_PLAN.md)
       - INTRODUCTION.md path: <project-folder>/INTRODUCTION.md
       - Code patterns directory path: <code-patterns-dir>/
       - Specs directory path: <specs-dir>/ (if relevant to the task)
       - Report template path: <template-path>/
       - If the project has `### Visual Testing` configured in CLAUDE.md, include the Layer 1
         visual testing config in the spawn prompt (top-level fields only: capture script path,
         compare script path, baseline directory, diff threshold). Do NOT include `#### Layer N:`
         subsection configs — multi-layer validation runs during `/arn-code-review-implementation`.
       - If a sketch manifest was detected in Step 1, include the following in the spawn prompt:
         --- SKETCH CONTEXT ---
         **Sketch manifest path:** <absolute path to sketch-manifest.json>
         **Sketch directory:** <absolute path to the sketch directory>
         **Instruction:** Before creating any file, check the sketch manifest's componentMapping
         for a matching target path. If found, promote from the sketch source rather than writing
         from scratch. See "Sketch-aware file creation" in your execution instructions.
         --- END SKETCH CONTEXT ---
         If no sketch manifest was detected, omit this block entirely.
       - Instructions:
         - Read INTRODUCTION.md and pattern docs (including ui-patterns.md if present) before starting implementation
         - Implement the task according to the phase plan
         - Write tests if the phase plan includes them for this task
         - Run ONLY targeted tests (precise: pytest tests/test_specific.py::TestClass,
           jest --testPathPattern=specific.test.ts). Never run the full test suite.
         - All targeted tests must pass before reporting completion
         - If visual testing is configured and the task involves UI components, capture
           screenshots after implementation/testing (see executor's Visual Capture section)
         - Generate an implementation report (IMPLEMENTATION_REPORT_TEMPLATE.json) and/or
           testing report (TESTING_REPORT_TEMPLATE.json) as appropriate
         - Return: report file path(s), list of files created/modified, and visual capture
           directory path (if captures were taken)
    c. Record the agent ID returned by the Task tool (needed for resume mode)

  ALL executors in this batch are dispatched in a SINGLE message (multiple Task
  tool calls in one response) so they run in PARALLEL.

  -- 3. Wait for executors -----------------------------------------------

  Wait for all executor agents in the batch to complete and return their results.

  -- 4. Dispatch reviewers (PARALLEL) ------------------------------------

  For each completed executor in this batch:
    a. Read the executor's output to extract:
       - Report file path(s) (implementation report and/or testing report)
       - List of files created and modified
    b. Spawn a arn-code-task-reviewer agent via the Task tool with this prompt:
       - Task ID and full task description
       - Project name: <PROJECT_NAME>
       - Project folder path: <plans-dir>/<PROJECT_NAME>/
       - INTRODUCTION.md path: <project-folder>/INTRODUCTION.md
       - Code patterns directory path: <code-patterns-dir>/
       - Report template path: <template-path>/ (for TASK_REVIEW_REPORT_TEMPLATE.json)
       - Implementation/testing report path(s) from the executor
       - List of files created/modified by the executor
       - If the executor reported visual capture paths, include them in the reviewer spawn
         prompt along with the Layer 1 visual testing config (top-level fields only: compare
         script path, baseline directory, diff threshold).
       - Instructions:
         - Read INTRODUCTION.md and pattern docs (including ui-patterns.md if present)
         - Validate the implementation against pattern documentation and phase plan
           acceptance criteria
         - Re-run the targeted tests the executor wrote (precise targeting, never full suite)
         - If visual captures are available, run visual comparison against baselines and
           classify any visual regressions (see reviewer's Visual Regression Check)
         - Classify each finding as error (critical, blocks progress) or warning (minor,
           non-blocking)
         - Generate a review report (TASK_REVIEW_REPORT_TEMPLATE.json)
         - Return: review report path and verdict (pass / pass-with-warnings / needs-fixes)

  ALL reviewers for this batch are dispatched in a SINGLE message (multiple Task
  tool calls in one response) so they run in PARALLEL.

  -- 5. Wait for reviewers -----------------------------------------------

  Wait for all reviewer agents in the batch to complete and return their results.

  -- 6. Process review verdicts ------------------------------------------

  For each review result in this batch:

    IF verdict = "pass":
      - Mark the task as completed via TaskUpdate
      - Log: task passed on first review
      - Update PROGRESS_TRACKER.json (see Step 6a below)

    IF verdict = "pass-with-warnings":
      - Read the executor's implementation report JSON
      - Append the reviewer's warning findings to the reviewFindings array in the
        implementation report (so warnings are preserved in one place)
      - Write the updated implementation report back to disk
      - Mark the task as completed via TaskUpdate
      - Log: task passed with warnings
      - Update PROGRESS_TRACKER.json (see Step 6a below)

    IF verdict = "needs-fixes":
      - Increment the retry counter for this task
      - IF retry count > 2 (max review cycles exceeded):
        - Escalate to user with the review findings
        - Present options:
          1. Retry with additional user-provided context
          2. Skip this task and continue with others
          3. Abort execution entirely
        - Wait for user decision and act accordingly
      - IF retry count <= 2:
        - IF review feedback mode = "resume":
          - Resume the original executor agent (using the resume parameter of the
            Task tool, passing the agent ID recorded in step 2c) with a new prompt
            containing:
            - The reviewer's specific error findings (errors that must be fixed)
            - The review report path for full context
            - Instruction: fix the identified issues, re-run targeted tests, update
              the implementation report, return
          - After the executor returns, go back to step 4 for this task only
            (re-run the reviewer)
        - IF review feedback mode = "fresh":
          - Spawn a NEW arn-code-task-executor agent via the Task tool with:
            - All original task context (same as step 2b)
            - PLUS: the review report path
            - PLUS: specific findings to fix from the reviewer
            - Instruction: fix the identified issues based on the review report,
              re-run targeted tests, update the implementation report, return
          - After the executor returns, go back to step 4 for this task only
            (re-run the reviewer)

  -- 6a. Update PROGRESS_TRACKER.json ------------------------------------

  After marking a task as completed (pass or pass-with-warnings):
    - Read <project-folder>/PROGRESS_TRACKER.json
    - Find the phase entry whose implementation.taskId or testing.taskId matches
      the completed task
    - Set the matching status (implementation or testing) to "completed"
    - Set completedAt to the current ISO 8601 timestamp
    - Set review.verdict to the reviewer's verdict ("pass" or "pass-with-warnings")
    - Set review.reviewCycles to the total number of review cycles for this task
      (1 for first-pass success, retry count + 1 for tasks that needed fix cycles)
    - Update lastUpdated
    - Write PROGRESS_TRACKER.json back to disk

  If PROGRESS_TRACKER.json was not found during Step 0, skip this step silently.

  -- 7. Loop -------------------------------------------------------------

  Go back to step 1 to find the next batch of newly unblocked pending tasks.
  Tasks that were blocked by tasks completed in this batch are now eligible.

  -- 8. Finalize progress tracking ---------------------------------------

  After the WHILE loop exits (all tasks completed or no more unblocked tasks):
    - Read PROGRESS_TRACKER.json
    - If all phases have implementation.status = "completed" (and testing.status
      is "completed" or "none" for each phase): set overallStatus to "completed"
    - Update lastUpdated
    - Write PROGRESS_TRACKER.json to disk

  If PROGRESS_TRACKER.json was not found during Step 0, skip this step silently.

  -- 8.5. Pattern refresh (auto) ------------------------------------------

  Invoke the pattern refresh procedure defined in pattern-refresh.md.
  This is automatic and non-blocking -- if the refresh fails, log a warning
  and continue. The refresh compares the codebase's current state against
  stored pattern docs and writes updates if differences are found.
```
