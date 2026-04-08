# Backlog Selection

Reference procedure for scanning the greenfield Feature Tracker and identifying unblocked features for batch planning.

## Canonical Source

The core backlog scanning algorithm is defined in `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-pick-issue/references/greenfield-backlog-resolution.md`. That file contains the canonical procedure for: reading configuration, locating the feature backlog, parsing the Feature Tracker table, resolving dependencies, and identifying unblocked features.

**Read that file and follow its Detection Chain and Resolution Procedure.** The steps below describe only the batch-planning-specific adaptations applied on top of the canonical algorithm.

## Batch-Planning Adaptations

After running the canonical greenfield-backlog-resolution procedure:

### 1. Filter to Unblocked Only

From the canonical procedure's output, retain only features that are:
- Status = `pending`
- All dependencies have status = `done` (or Deps = `None`)

Exclude features with status `in-progress`, `done`, or `decomposed`. Decomposed parent features are excluded because their sub-feature rows (F-NNN.1, F-NNN.2, etc.) are the individual work items.

### 2. Sort Results

Sort the unblocked features by two criteria, in order:

**Primary sort: Phase order**
1. Foundation
2. Core
3. Enhancement
4. Polish

**Secondary sort: Priority order (within the same phase)**
1. Must-have
2. Should-have
3. Nice-to-have

### 3. Return Results

Return the following data to the calling skill:

| Field | Description |
|-------|-------------|
| `total` | Total non-decomposed features in the tracker |
| `unblocked` | Count of unblocked features (pending with all deps done) |
| `blocked` | Count of blocked features (pending with unmet deps) |
| `in_progress` | Count of features with status `in-progress` |
| `done` | Count of features with status `done` |
| `decomposed` | Count of parent features with status `decomposed` |
| `unblocked_features` | Sorted list of unblocked features, each with: ID, Feature name, Priority, Phase, Deps, Issue |

If `unblocked` = 0, the calling skill should handle this case (e.g., inform the user that no features are ready for planning).

## Error Handling

Errors from the canonical procedure (no Vision directory, no backlog file, unparseable table) are propagated directly — this reference does not add additional error handling beyond what the canonical source provides.
