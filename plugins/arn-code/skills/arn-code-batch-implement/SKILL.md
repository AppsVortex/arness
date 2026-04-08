---
name: arn-code-batch-implement
description: >-
  This skill should be used when the user says "batch implement", "implement all",
  "batch execution", "implement all features", "parallel implement", "implement in parallel",
  "arness batch implement", "arn-code-batch-implement", "run batch implementation",
  "implement everything", "launch batch workers", or wants to spawn parallel
  worktree-isolated background agents to implement multiple pending features simultaneously.
  Each worker runs as a full independent session with all tools. This skill requires
  pending plans in .arness/plans/ — run arn-code-batch-planning first if none exist.
version: 1.0.0
---

# Arness Batch Implement

Orchestrate parallel worktree-isolated background agents to implement multiple features simultaneously. Each worker is a full independent session with all tools, operating in its own git worktree. The orchestrator (this skill) handles pre-flight validation, worker spawning, progress tracking, and handoff to batch-merge.

**Key architectural constraint:** This skill is a sequencer — it MUST NOT duplicate sub-skill logic. Workers handle all implementation details autonomously.

Pipeline position:
```
arn-code-batch-planning -> **arn-code-batch-implement** (pre-flight -> spawn workers -> track -> handoff) -> arn-code-batch-merge
```

## Workflow

### Step 0: Ensure Configuration

Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-ensure-config/references/ensure-config.md` and follow its instructions. Extract from `## Arness`:

- **Plans directory** -- base path where project plans are saved
- **Code patterns** -- path to the directory containing stored pattern documentation
- **Template path** -- path to the report template set (JSON templates)

### Step 1: Pre-flight Validation

Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-batch-implement/references/preflight-validation.md` and follow its procedure. The preflight reference handles scanning and returns a structured result. Based on that result:

If **zero pending plans found**: inform the user: "No pending plans found. Run `/arn-code-batch-planning` to plan features first." Exit.

If **Git is `no`** in `## Arness`: "Batch implementation requires git for worktree-based parallel execution. Run `/arn-implementing` to implement features one at a time instead." STOP.

If **gh/bkt auth not available** (based on Platform): warn that PRs cannot be created — workers will commit but skip PR creation.

If **uncommitted changes detected**: warn and suggest committing first. Ask (using `AskUserQuestion`):

> **Uncommitted changes detected. Commit or stash before launching batch?**
> 1. Proceed anyway
> 2. Cancel — I'll commit first

If Cancel, exit.

If **not on main/master**: plans should be on main (merged via the plans PR from batch-planning). Ask (using `AskUserQuestion`):

> **You're on branch [name], but plans should be on main. Checkout main?**
> 1. Checkout main — run `git checkout main && git pull`
> 2. Proceed on this branch — I know what I'm doing

If Checkout main: `git checkout main && git pull`. Continue.
If Proceed: continue on current branch.

Run `git pull` to ensure main is up to date with the latest plans.

### Step 2: Pre-flight Summary

Present the validation results as a table:

```
Batch Implementation Pre-flight:

| # | Feature | Tier | Sketch | Est. Files | Overlap Warning |
|---|---------|------|--------|------------|-----------------|
| 1 | ...     | ...  | ...    | ...        | ...             |
```

Column values:
- **Sketch**: "ready" (manifest found with kept status), "recommended" (UI references but no sketch), "n/a" (no UI components)
- **Overlap Warning**: blank if none, or list of overlapping feature names

If file overlap detected between any features, show which features share files and note: "File overlap detected -- batch-merge will handle conflicts after implementation."

Show estimated context: "[N] features will be implemented in parallel, each as an independent session."

### Step 3: Launch Confirmation

Ask (using `AskUserQuestion`):

> **Launch [N] parallel implementations?**
> 1. Launch all
> 2. Select subset
> 3. Cancel

- **Launch all** -- proceed with all pending features.
- **Select subset** -- present a multi-select (using `AskUserQuestion` with `multiSelect: true`) listing all pending features by name. Proceed with selected features only.
- **Cancel** -- exit.

### Step 4: Spawn Workers

Read the worker instructions template from `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-batch-implement/references/worker-instructions.md`.

For each feature to implement, spawn one Agent with:
- `isolation: "worktree"`
- `run_in_background: true`
- A self-contained prompt built from the worker-instructions template, filled with:
  - The feature's plan path (absolute)
  - The detected tier (thorough, standard, or swift)
  - The platform (`github`, `bitbucket`, or `none` — from `## Arness` config)
  - Code patterns directory path (absolute)
  - Template path (absolute)
  - Sketch manifest path (absolute, if sketch exists; otherwise "none")

If a worker **fails to spawn** (Agent tool returns an error), report the failure, continue spawning remaining workers, and include the failed feature in the Step 5 summary with status "failed -- spawn error".

**ALL agents MUST be spawned in a SINGLE message** (multiple Agent tool calls in one response) so they run in parallel. Cap at **5 concurrent workers**.

If more than 5 features are queued, batch into groups of 5. Launch the first group, wait for all workers in that group to complete, then launch the next group.

### Step 5: Track Progress

As workers complete, collect their final messages. Each worker should end with `PR: <url>` or `PR: none -- <reason>`.

Present a status table as workers finish:

```
| Feature | Status | PR | Duration |
|---------|--------|----|----------|
| ...     | ...    | ...| ...      |
```

Status values: "done", "failed -- <reason>"

If a worker fails: report the failure, continue tracking other workers, include the failed feature in the summary.

When all workers in the current batch complete, present the summary: **"[N/M] features implemented successfully."**

If there are additional batches (>5 features), launch the next batch and repeat.

### Step 6: Handoff

Ask (using `AskUserQuestion`):

> **Batch implementation complete. What next?**
> 1. Merge PRs
> 2. Not yet

- **Merge PRs** -- invoke `Skill: arn-code:arn-code-batch-merge`.
- **Not yet** -- inform: "Run `/arn-code-batch-merge` when ready." Exit.
