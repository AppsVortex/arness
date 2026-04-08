# Feature Tracker Update (Greenfield Integration)

Reference procedure for updating the greenfield Feature Tracker during `arn-code-ship`. This step is entirely optional — it activates only when a greenfield feature backlog exists. Projects without greenfield skip this step silently and proceed to the completion summary.

## Detection Chain

All three must pass, otherwise skip silently:

1. `## Arness` config in CLAUDE.md has a **Vision directory** field (only set by `arn-spark-init`, never by core `arn-code-init`)
2. `features/feature-backlog.md` exists at the Vision directory path (i.e., `[vision-dir]/features/feature-backlog.md`)
3. The file contains a `## Feature Tracker` table

## Update Workflow

**If all three pass:**

1. Identify the feature being shipped — check in order, stop at first match:

   a. **Branch name:** Check current branch for an `F-NNN` or `F-NNN.N` pattern (e.g., `feat/F-003-voice-communication`, `feat/F-005.1-audio-pipeline`, `fix/F-012-auth-error`). Use regex: `F-\d{3}(\.\d+)?`
   b. **Spec file:** Look in the specs directory for a spec file referencing a feature ID (e.g., `F-003` or `F-005.1` in the spec body or filename). Sub-feature specs use filenames like `FEATURE_F-005.1_audio-pipeline.md`.
   c. **Commit messages:** Scan recent commits for an `F-NNN` or `F-NNN.N` pattern: `git log main..HEAD --oneline`. Use regex: `F-\d{3}(\.\d+)?`
   d. **Ask the user:** If none of the above yields a match: "Does this work correspond to a feature from the backlog? Enter the feature ID (e.g., F-003 or F-005.1) or 'no'."

2. If a match is found, show it and ask for confirmation: "This appears to be feature **F-NNN: [Feature Name]**. Mark it as done in the Feature Tracker?"

3. If the user confirms:

   a. Parse the Feature Tracker table from `features/feature-backlog.md`

   b. Update the matched feature's status from `in-progress` (or `pending`) to `done`

   c. **If the shipped item is a sub-feature (F-NNN.M) — Parent Rollup:**
      - After marking the sub-feature as `done`, check all sibling sub-features (all rows with IDs matching `F-NNN.*` where NNN is the parent)
      - If ALL sibling sub-features have status = `done`, also mark the parent feature (F-NNN) as `done` (changing it from `decomposed` to `done`)
      - Report: "All sub-features of F-NNN: [Parent Name] are now done. Parent feature marked as done."
      - If some siblings are still pending or in-progress, report: "F-NNN.M done. [K] of [N] sub-features of F-NNN: [Parent Name] are now complete. Remaining: F-NNN.X ([status]), F-NNN.Y ([status])."

   d. Scan for newly unblocked features — features (and sub-features) where:
      - Status = `pending`
      - ALL dependencies have status = `done` (or deps = `None`)
      - Skip rows with status = `decomposed`

   e. Re-write `features/feature-backlog.md` with the updated Feature Tracker. Individual feature files are not modified.

   f. Report the update:

   "Feature Tracker updated:
   - **F-NNN[.M]: [Feature Name]** is now done.
   [If parent rollup occurred:] - **F-NNN: [Parent Name]** -- all sub-features complete, parent marked as done.
   - Newly unblocked: **F-005: [Name]**, **F-007: [Name]** (ready to work on).
   - Run `/arn-code-pick-issue` to pick the next feature."

   If no features are newly unblocked: "No new features were unblocked by this change."

4. If no match is found or the user declines: skip silently.
