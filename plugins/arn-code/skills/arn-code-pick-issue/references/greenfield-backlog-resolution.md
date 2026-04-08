# Greenfield Backlog Resolution

Reference procedure for resolving issues from a greenfield feature backlog during `arn-code-pick-issue`. This step is entirely optional — it activates only when a greenfield feature backlog exists. Projects without greenfield skip this step silently and proceed to Step 2.

## Detection Chain

All three must pass, otherwise skip to Step 2:

1. `## Arness` config has a **Vision directory** field (only set by `arn-spark-init`, never by core `arn-code-init`)
2. `features/feature-backlog.md` exists at the Vision directory path (i.e., `[vision-dir]/features/feature-backlog.md`)
3. The file contains a `## Feature Tracker` table

## Resolution Workflow

**If all three pass:**

1. Parse the Feature Tracker table into a list of features with: ID, name, priority, deps, phase, issue, status.

2. Resolve dependencies: find features where:
   - status = `pending`
   - ALL dependencies have status = `done` (or deps = `None`)

   **Skip rows with status = `decomposed`** -- these are XL parent features that have been split into sub-features by `arn-code-feature-spec`. Their sub-feature rows (F-NNN.1, F-NNN.2, etc.) are the pickable work items.

   **Sub-feature dependency resolution:** Sub-features may depend on sibling sub-features (e.g., F-005.3 depends on F-005.1). Resolve these the same way as cross-feature dependencies: the dependency must have status = `done` for the sub-feature to be unblocked.

3. Sort unblocked features by: phase order (Foundation first, then Core, Enhancement, Polish), then priority (must-have first).

4. Present unblocked features to the user:

"I found a local Feature Tracker with [N] features. [M] are unblocked and ready to work on:

| # | ID | Feature | Priority | Phase | Issue | Blocked By |
|---|-----|---------|----------|-------|-------|------------|
| 1 | F-003 | [Name] | Must-have | Foundation | #44 | None |
| 2 | F-005 | [Name] | Should-have | Core | #46 | None |
| 3 | F-008 | [Name] | Nice-to-have | Enhancement | #49 | None |

[K] features are blocked by incomplete dependencies.
[J] features are in-progress.
[L] features are done.

Pick a feature by number, or type 'remote' to browse all issues from [GitHub/Jira] instead."

If any features have status `decomposed`, include a note after the table: "[D] feature(s) are decomposed into sub-features (shown as F-NNN.N rows above)."

5. If the user types 'remote': skip to Step 2 (standard remote-only flow).

6. If the user picks a candidate from the local list:

   a. **If the Issue column has a value (not `--`):** Fetch that ONE issue from the remote tracker to validate its current state:
      - **If GitHub:** `gh issue view <number> --json number,title,state,labels,assignees`
      - **If Jira:** Fetch via Atlassian MCP by key

      Handle validation results:
      - **If closed/done:** Update the local Feature Tracker: set this feature's status to `done`. Recalculate unblocked features and re-present the list. Inform: "Feature [F-NNN] was already completed (remote status: closed). Updated local tracker. Here are the updated unblocked features:"
      - **If assigned to someone else:** Warn: "This issue is currently assigned to [assignee]. Do you want to proceed anyway?" Let the user decide.
      - **If labels changed remotely (priority differs):** Note the discrepancy to the user but do not block: "Note: Remote priority for [F-NNN] is [remote priority], local tracker has [local priority]."
      - **If open and unassigned (or user proceeds despite assignment):** Continue to Step 5 (Assess Issue) with the remote issue data as the issue context.

   b. **If the Issue column is `--` (no issue uploaded):** Read the individual feature file at `[vision-dir]/features/F-NNN-kebab-name.md` (derive the filename from the Feature Index table in the backlog, or by scanning the `features/` directory for a file starting with the feature ID). Proceed directly to Step 5 (Assess Issue) using the feature file content as the context instead of a remote issue body. Note: "This feature does not have a remote issue. Assessment will use the local feature file."

      **If the selected item is a sub-feature (F-NNN.M):** Sub-features do not have individual feature files in the `features/` directory. Instead:
      1. Check if a sub-feature spec already exists at `<specs-dir>/FEATURE_F-NNN.M_<name>.md` -- if it does, use the spec as context (it has richer content than the decomposition hints).
      2. If no spec exists, read the PARENT feature file (`F-NNN-kebab-name.md`) and extract the relevant decomposition hint entry for this sub-feature.
      3. Proceed to Step 5 with whichever context was found.

7. Update the local Feature Tracker: set the selected feature's status to `in-progress`. Re-write `features/feature-backlog.md` with the updated tracker. Individual feature files are not modified.

8. Proceed to Step 5 (Assess Issue) — skip Steps 2-4 (remote filtering/fetching/selection).
