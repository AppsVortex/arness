---
name: arn-code-batch-merge
description: >-
  This skill should be used when the user says "batch merge", "merge batch",
  "arness batch merge", "arn-code-batch-merge", "merge all PRs",
  "merge batch PRs", "merge the batch", "merge implemented features",
  "batch merge PRs", "merge open PRs", "merge all feature PRs",
  "combine batch PRs", "land the batch", "land all PRs",
  or wants to discover open batch implementation PRs, analyze them for
  conflicts, determine an optimal merge order, and execute merges with
  user-guided conflict resolution. This skill is typically invoked after
  arn-code-batch-implement completes and chains to arn-code-batch-simplify
  upon completion.
version: 1.0.0
---

# Arness Batch Merge

Smart PR management dashboard with guided per-PR review. Discover open batch PRs, delegate cross-PR analysis, then drive an interactive review/merge/refresh cycle.

This skill is a **sequencer**. It MUST NOT duplicate sub-skill logic. Arness-code-batch-merge handles: PR discovery, cross-PR analysis delegation, interactive review loop, merge execution, Feature Tracker updates, and chaining. Review logic lives in `arn-code-review-pr`; analysis logic lives in the `arn-code-batch-pr-analyzer` agent.

Pipeline position:
```
arn-code-batch-implement -> **arn-code-batch-merge** -> arn-code-batch-simplify
                               |
                               +-- per PR: review-pr -> approve/merge -> refresh
```

## Step 0: Ensure Configuration

Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-ensure-config/references/ensure-config.md` and follow its instructions. This guarantees a user profile exists and `## Arness` is configured with Arness Code fields before proceeding.

After configuration is ensured, extract the following from `## Arness`:
- **Plans directory** -- base path where project plans and CHANGE_RECORD.json files are stored
- **Platform** -- `github`, `bitbucket`, or `none`
- **Vision directory** (if exists) -- path containing the feature backlog
- **Code patterns** (if exists) -- path to code patterns directory

---

## Step 1: Discover Batch PRs (Lightweight)

### Platform Gate

If Platform is `none`: "Batch merge requires a platform (GitHub or Bitbucket) for PR management. Merge branches manually." STOP.

If Platform is `github`: verify `gh` CLI is available. If not: "The GitHub CLI (`gh`) is required for batch merge. Install it from https://cli.github.com/ and authenticate with `gh auth login`." STOP.

If Platform is `bitbucket`: verify `bkt` CLI is available. If not: "The Bitbucket CLI (`bkt`) is required for batch merge." STOP.

### Scan for Batch PRs

Scan the Plans directory for CHANGE_RECORD.json files. Check all plan subdirectories: `*/CHANGE_RECORD.json`, `STANDARD_*/CHANGE_RECORD.json`, `SWIFT_*/CHANGE_RECORD.json`.

For each CHANGE_RECORD.json found, check:
1. `commitHash` is populated (non-empty string) -- the feature was committed
2. `nextSteps` array contains at least one entry matching a PR URL pattern (contains `github.com` or `pull` or `bitbucket` or matches a PR reference like `#123`)

For each qualifying CHANGE_RECORD, extract:
- **Feature name** -- from `projectName`
- **PR URL** -- from the `nextSteps` entry containing the PR reference
- **CHANGE_RECORD path** -- full path to the CHANGE_RECORD.json file

### Verify PR State

For each discovered PR, verify it is still open:

- Platform `github`: `gh pr view <url> --json state`
- Platform `bitbucket`: `bkt pr view <id>`

- If the PR is `OPEN`: include it in the batch
- If the PR is `CLOSED` or `MERGED`: skip it silently

**If zero open batch PRs found:** "No open batch PRs found. Run `/arn-code-batch-implement` first to create implementation PRs." STOP.

Collect the final list: PR number, URL, feature name, CHANGE_RECORD path, platform. This is a small data set -- it stays in context.

---

## Step 2: Cross-PR Analysis (Delegated)

Spawn the `arn-code-batch-pr-analyzer` agent in **foreground** (the results are needed before proceeding).

Pass to the agent:
- PR list (number, URL, feature name, CHANGE_RECORD path)
- Code patterns path (from `## Arness`)
- Platform (`github` or `bitbucket`)
- Conflict-classification reference path: `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-batch-merge/references/conflict-classification.md`

The agent returns a concise summary containing:
- **Status table** -- each PR with CI status, review status, merge readiness
- **Cross-PR findings** -- shared files, overlapping concerns, integration risks
- **Conflict map** -- pairwise conflict classifications (clean / auto-mergeable / manual-resolution)
- **Recommended merge order** -- optimal sequence based on conflicts, dependencies, and readiness

Present the agent's summary to the user.

**If the agent fails:** Present the raw PR list without analysis. Offer to retry: "Cross-PR analysis failed. You can still review PRs individually, or I can retry the analysis."

---

## Step 3: Guided Per-PR Review Loop

Ask (using `AskUserQuestion`):

**"Ready to start reviewing PRs?"**

Options:
1. **Start with recommended PR** -- begin reviewing the first in suggested order
2. **Choose a PR to review** -- pick a specific PR
3. **Run batch-simplify first** -- cross-feature quality pass before reviewing
4. **Done for now** -- exit

If **Run batch-simplify first**: Invoke `Skill: arn-code:arn-code-batch-simplify`. After it completes, return to this menu.

If **Done for now**: "Run `/arn-code-batch-merge` when ready to resume." STOP.

### Selecting a PR

If **Start with recommended PR**: select the first PR from the recommended merge order.

If **Choose a PR**: present open PRs as numbered options. If more than 4 PRs, use layered navigation (first ask which group, then which PR within the group -- max 4 options per layer).

### Review

Invoke `Skill: arn-code:arn-code-review-pr` with the selected PR number. The review-pr skill handles the full flow: fetch comments, validate, categorize, fix, local testing.

### Post-Review Action

After review-pr completes:

Ask (using `AskUserQuestion`):

**"PR #N reviewed. What next?"**

Options:
1. **Approve and merge** -- merge this PR, update local, refresh analysis
2. **Next PR** -- move to next in recommended order
3. **Re-check big picture** -- re-run analyzer to refresh status
4. **Done for now** -- exit

#### Approve and Merge

Execute the merge:

- Platform `github`: `gh pr merge <url> --merge`
- Platform `bitbucket`: `bkt pr merge <id>`

Then update the local branch:

```bash
git checkout main && git pull
```

**Clean up the feature's worktree (batch-implement worktrees only)**

After the merge succeeds and `main` is up to date, remove the worktree and local branch created by `arn-code-batch-implement`. Only apply this cleanup when the merged PR's head branch starts with `arn-batch/` — other branches (manual work, hotfixes) are left alone.

```bash
HEAD_BRANCH="$(gh pr view <url> --json headRefName -q .headRefName)"   # or equivalent for bkt
case "$HEAD_BRANCH" in
  arn-batch/*)
    SLUG="${HEAD_BRANCH#arn-batch/}"
    REPO="$(git rev-parse --show-toplevel)"
    WORKTREE_PATH="$REPO/.claude/worktrees/arn-batch-$SLUG"
    git -C "$REPO" worktree remove --force "$WORKTREE_PATH" 2>/dev/null || true
    git -C "$REPO" branch -D "$HEAD_BRANCH" 2>/dev/null || true
    ;;
esac
```

The `--force` flag is safe here: the branch's commits are already on `main`, so nothing is lost. Errors from both commands are ignored (the worktree or branch may have been cleaned up manually). Log the cleanup outcome alongside the PR URL in the merge summary: e.g. `✓ Merged #42 · worktree cleaned`.

**If the merge fails** (CI checks, branch protection, conflicts): report the error: "Merge failed for [feature] (#PR): [error message]." Offer to skip and continue with another PR. Do NOT clean up the worktree — it still holds the only local copy of the work.

If remaining open PRs > 0:
- Re-run the `arn-code-batch-pr-analyzer` agent (foreground) with the updated PR list
- Present the updated summary
- If any remaining PR is now CONFLICTING that was not before: highlight the change
- Return to the post-review action menu for the next PR

#### Next PR

Select the next PR in the recommended merge order (skip any already merged). Invoke review-pr for that PR. After review, return to the post-review action menu.

#### Re-check Big Picture

Re-run the `arn-code-batch-pr-analyzer` agent (foreground) with the current open PR list. Present the updated summary. Return to the main review loop menu ("Ready to start reviewing PRs?").

#### Done for Now

Proceed to Step 4.

---

## Step 4: Completion

Count merged and still-open PRs. Present the final status:

```
Batch Merge Status: [N] merged, [M] still open

| Feature       | PR   | Status  |
|---------------|------|---------|
| Auth service  | #42  | Merged  |
| API endpoints | #43  | Merged  |
| Settings page | #44  | Open    |
```

**Unmerged worktree note:** Worktrees for unmerged features remain at `.claude/worktrees/arn-batch-<slug>/` on branches `arn-batch/<slug>`. They are preserved so the work is not lost. Once you decide what to do with each (rework, merge later, abandon), clean up manually with `git worktree remove <path>` and `git branch -D arn-batch/<slug>`, or re-run `arn-code-batch-merge` after resolving the blocker.

### Feature Tracker Update

**If Vision directory does not exist in `## Arness`, or `feature-backlog.md` does not exist:** Skip this section.

Otherwise, read `feature-backlog.md` and locate the Feature Tracker table.

For each successfully merged feature:
1. Find the feature row by matching the feature name or ID from the CHANGE_RECORD's `projectName`
2. Update its status to `done`

**Parent Rollup Check:** After updating individual features, check for parent rollup. If all sub-features of a parent feature are now `done`, mark the parent as `done`. Recurse upward.

**Newly Unblocked Features:** Scan for features whose status is `pending` and whose dependencies are all `done`. Report them:

```
Newly unblocked features:
- F-010: User Dashboard (was blocked by F-003, F-005)
```

Write the updated `feature-backlog.md` back to disk.

### Handoff

If all PRs are merged:

Ask (using `AskUserQuestion`):

**"All batch PRs merged. Run cross-feature simplification?"**

Options:
1. **Yes** -- Invoke `Skill: arn-code:arn-code-batch-simplify`
2. **Not yet** -- Exit

If **Yes**: Invoke `Skill: arn-code:arn-code-batch-simplify`.

If **Not yet**: "Run `/arn-code-batch-simplify` when ready to clean up cross-feature duplication." Exit.

If some PRs are still open: list remaining PRs with their current status. "Run `/arn-code-batch-merge` to resume." Exit.

---

## Error Handling

- **gh/bkt CLI not available:** STOP with installation instructions (see Step 1).
- **PR merge fails (CI, branch protection, conflicts):** Report the error, skip the PR, continue with others. Do not abort the entire batch.
- **Analyzer agent fails:** Present the raw PR list without analysis. Offer to retry or proceed with individual reviews.
- **review-pr fails:** Report the error. Offer to retry the review or skip the PR and continue.
- **Network/API errors:** Report the specific error. Offer to retry the failed operation.
