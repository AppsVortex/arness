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
version: 1.1.0
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

Inform the user about worktree location: "Workers run in pre-created worktrees at `.claude/worktrees/arn-batch-<slug>/` on branches `arn-batch/<slug>`. Worktrees are preserved until the corresponding PR is merged; `arn-code-batch-merge` cleans them up after each successful merge."

### Step 3: Launch Confirmation

Ask (using `AskUserQuestion`):

> **Launch [N] parallel implementations?**
> 1. Launch all
> 2. Select subset
> 3. Cancel

- **Launch all** -- proceed with all pending features.
- **Select subset** -- present a multi-select (using `AskUserQuestion` with `multiSelect: true`) listing all pending features by name. Proceed with selected features only.
- **Cancel** -- exit.

### Step 4: Pre-create Worktrees and Spawn Workers

The Agent tool's built-in `isolation: "worktree"` has known silent-failure modes (see upstream issues anthropics/claude-code#27881 and #39886) where concurrent spawns can skip worktree creation entirely and run agents directly in the main checkout. To eliminate this risk, the orchestrator pre-creates every worktree itself via `git worktree add`, then spawns agents **without** `isolation` and passes the absolute worktree path in the prompt.

Read the worker instructions template from `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-batch-implement/references/worker-instructions.md`.

#### Step 4a: Compute Worktree Slugs

For each selected feature, derive a slug from the feature name: lowercase, replace non-alphanumerics with `-`, collapse runs of `-`, trim leading/trailing `-`. Example: `Auth Service v2` → `auth-service-v2`.

**Empty-slug fallback:** If sanitization produces an empty string (feature name was entirely non-alphanumeric, e.g., emojis or punctuation), substitute `feature-<index>` where `<index>` is the feature's 1-based position in the batch. This keeps provisioning deterministic instead of silently failing downstream.

Capture the repo root once:

```bash
REPO="$(git rev-parse --show-toplevel)"
```

For each slug, resolve three possible collisions before provisioning — a path may already be taken, a branch may already exist from a prior run, and stale worktree metadata may block creation:

1. **Path collision.** Check `git -C "$REPO" worktree list --porcelain` for an existing worktree at `$REPO/.claude/worktrees/arn-batch-<slug>`:
   - None: path is free, proceed to the branch check.
   - Exists on branch `arn-batch/<slug>` with clean status (`git -C "$REPO/.claude/worktrees/arn-batch-<slug>" status --porcelain` is empty): reuse it and mark this slug as "already provisioned" (skip Step 4b).
   - Otherwise (dirty worktree, different branch, unknown state): append `-<n>` starting at `2` and re-check until the path is free.

2. **Branch collision.** Once a path is free, check whether the target branch already exists: `git -C "$REPO" show-ref --verify --quiet "refs/heads/arn-batch/<slug>"`. If it does (common when a worktree was manually deleted but the branch wasn't cleaned up), `git worktree add -b` will fail. Keep incrementing `-<n>` on the slug until both path AND branch are free.

#### Step 4b: Pre-create Worktrees Sequentially

For each slug that needs creation (i.e., wasn't marked "already provisioned" in Step 4a), run:

```bash
git -C "$REPO" worktree add "$REPO/.claude/worktrees/arn-batch-<slug>" -b "arn-batch/<slug>"
```

Capture exit code and stderr per feature. Verify success by confirming the path appears in `git -C "$REPO" worktree list`. Split the feature list into:
- `ready`: features with a valid worktree (newly created or reused).
- `deferred`: features whose `git worktree add` failed. Store the stderr for the retry step.

If **all** features land in `deferred`, report the errors and stop — something is broken globally (disk, permissions, corrupt `.git/worktrees/`). A retry loop cannot fix a systemic failure.

#### Step 4c: Spawn Parallel Workers (ready set)

For each feature in `ready`, spawn one Agent with:
- **No** `isolation` parameter — worktrees already exist.
- `run_in_background: true`.
- A self-contained prompt built from the worker-instructions template, filled with:
  - `{worktree_path}`: the absolute path `$REPO/.claude/worktrees/arn-batch-<slug>`
  - `{feature_name}`, `{plan_path}`, `{tier}`, `{platform}`, `{code_patterns_path}`, `{template_path}`, `{sketch_manifest_path}` as before.

**ALL agents in the ready set MUST be spawned in a SINGLE message** (multiple Agent tool calls in one response) so they run in parallel. Cap at **5 concurrent workers**. If `ready` has more than 5 entries, batch into groups of 5: launch group 1, wait for completion, launch group 2, etc.

If a worker's Agent call returns a spawn error, move that feature from `ready` to `deferred` with reason "spawn error: …". It will be retried sequentially in Step 6.

### Step 5: Track Progress

As workers complete, collect their final messages. Each worker should end with `PR: <url>` or `PR: none -- <reason>`.

Present a status table as workers finish:

```
| Feature | Status | PR | Duration |
|---------|--------|----|----------|
| ...     | ...    | ...| ...      |
```

Status values: "done", "failed -- <reason>", "failed -- worktree provisioning (retry exhausted)" (set in Step 6 for features that couldn't get a worktree even after retry).

If a worker fails: report the failure, continue tracking other workers, include the failed feature in the summary.

When all workers in the current batch complete, present the summary: **"[N/M] features implemented successfully."**

If there are additional batches (>5 features), launch the next batch and repeat.

### Step 6: Retry Deferred Features (sequential)

If the `deferred` set accumulated in Step 4 is empty, skip this step and go straight to handoff.

Retry runs **after** the parallel workers from Step 4c finish, not alongside them — this avoids racing with live workers on `.git/worktrees/` metadata and keeps the orchestrator's output easy to read.

For each feature in `deferred`, sequentially (one at a time, not in parallel):

1. **Prune stale metadata:** `git -C "$REPO" worktree prune`. This clears entries for worktrees whose directories were removed but whose `.git/worktrees/` bookkeeping lingered — the single most common cause of transient `worktree add` failures.
2. **Retry worktree creation:** re-run the Step 4b command. If the path or branch still collides, append `-retry` to the slug as a human-readable marker and try once more.
3. **If creation succeeds:** spawn ONE foreground Agent (no `isolation`, no `run_in_background`) using the same worker-instructions prompt as Step 4c, with `{worktree_path}` set to the newly-created path. Wait for it to complete. Record its outcome in the Step 5 status table.
4. **If creation still fails:** mark the feature as `failed -- worktree provisioning (retry exhausted)` in the status table and include the git error in the final summary.

Do not retry more than once per feature. The goal is to recover from transient collisions and stale state, not to mask systemic failures.

**Worked example.** Say the batch has three features: `auth-service`, `api-endpoints`, `settings-page`. Step 4b succeeds for the first two but `settings-page` fails because `.git/worktrees/arn-batch-settings-page/` holds stale metadata from a manually-deleted worktree. Step 4c spawns parallel workers for `auth-service` and `api-endpoints`; Step 5 tracks them to completion. Step 6 then: prunes the stale metadata, retries `git worktree add` for `settings-page` (now succeeds), spawns ONE foreground worker, waits, records "done" in the Step 5 table. Total outcome: 3/3 succeed — parallel workers were never blocked by the stuck feature.

### Step 6.5: Aggregate Findings

After all workers (parallel + retried) have completed, parse each worker's final message for the report lines emitted in Step 8 of `worker-instructions.md`:

- `LINT_FINDINGS: <errors>/<warnings>/<infos>` (skipped if the worker's `Linting:` was `none`/`skip`)
- `UNRELATED_TESTS: <count>` (skipped if no testing tasks ran)
- `TEST_FAILURES: <count> -- <summary>` (existing — already surfaced today)

If a worker did not include one of these lines (older worker template, isolation failure, parsing failure), assume zeros for that worker and continue. Do not block aggregation on missing lines.

Aggregate across workers. **If all totals are zero across all workers** (lint errors + warnings + infos = 0, unrelated tests = 0, test failures = 0), skip this step silently and proceed to Step 7.

Otherwise present a findings table:

```
| Feature        | Lint (E/W/I) | Unrelated tests | Test failures |
|----------------|--------------|-----------------|---------------|
| auth-service   | 3/0/0        | 0               | 0             |
| api-endpoints  | 0/2/0        | 1               | 0             |
| settings-page  | 0/0/0        | 0               | 0             |
| **Total**      | **3/2/0**    | **1**           | **0**         |
```

Determine the suggested default for the prompt:

- Total lint errors > 0 OR test failures > 0 → suggest **Address now**
- Otherwise (warnings/infos/unrelated only) → suggest **File a backlog issue and proceed**

Then ask (using `AskUserQuestion`):

> **Workers reported \<E\> lint errors, \<W\> warnings, \<I\> infos, \<U\> unrelated test failures, \<F\> hard test failures. Suggested: \<Address now | File a backlog issue and proceed\>. How would you like to proceed?**
> 1. **Address now** — cancel batch-merge for now, fix issues per worktree (each worker's PR is already open), then re-run `/arn-code-batch-merge` when ready
> 2. **File a backlog issue and proceed** — create one aggregated tracker issue with per-feature breakdown, then continue to Step 7
> 3. **Proceed with documented reason** — continue to Step 7; rationale will be appended to PR descriptions when batch-merge runs

Apply the choice:

- **(1) Address now** — print each worker's worktree path (already known from Step 4: `$REPO/.claude/worktrees/arn-batch-<slug>`) so the user can `cd` in and fix issues. Do NOT invoke batch-merge. Exit cleanly.
- **(2) File a backlog issue and proceed** — read `Issue tracker` from `## Arness`. Create the issue:
  - For `github`: `gh issue create --title "Lint/test backlog from batch [N features]" --body "<aggregated table + per-feature breakdown of which reports contain the findings>"`
  - For `jira`: use the Atlassian MCP server with the same title and body
  - For `none`: warn the user that no issue tracker is configured and fall back to choice (3)
  Then proceed to Step 7.
- **(3) Proceed with documented reason** — prompt the user for a one-line rationale (free-form text, NOT `AskUserQuestion` — this is open-ended per CLAUDE.md "User Interaction Convention"). Store the rationale for use in Step 7. Proceed to Step 7.

---

### Step 7: Handoff

Ask (using `AskUserQuestion`):

> **Batch implementation complete. What next?**
> 1. Merge PRs
> 2. Not yet

- **Merge PRs** -- invoke `Skill: arn-code:arn-code-batch-merge`. If a rationale was captured in Step 6.5 (option 3 was chosen), pass it through so batch-merge can append "Lint/test exception: \<rationale\>" to each PR description.
- **Not yet** -- inform: "Run `/arn-code-batch-merge` when ready." Exit. If a rationale was captured in Step 6.5, also note: "Findings rationale captured: \<rationale\>. Re-running `/arn-code-batch-merge` will not preserve this — pass it again at merge time if needed."
