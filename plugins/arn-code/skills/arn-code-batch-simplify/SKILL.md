---
name: arn-code-batch-simplify
description: >-
  This skill should be used when the user says "batch simplify", "cross-feature simplify",
  "batch simplification", "simplify all features", "cross-feature quality pass",
  "batch code cleanup", "consolidate across features", "deduplicate across features",
  "cleanup after batch merge", "cross-feature deduplication",
  "arness batch simplify", "arn-code-batch-simplify", "simplify merged features",
  "post-merge simplify", "find cross-feature duplication", or wants to run a
  post-merge quality pass that finds duplication and consolidation opportunities
  across independently implemented features. This requires merged features in
  .arness/plans/ — run arn-code-batch-merge first if none are merged.
version: 1.0.0
---

# Arness Batch Simplify

Post-merge cross-feature quality pass that finds duplication and consolidation opportunities across independently implemented features. Uses the same 3-reviewer pattern as regular simplify but with cross-feature context so reviewers can identify duplicated utilities, inconsistent patterns, and shared logic that emerged from parallel development.

This is an execution skill. It runs in normal conversation (NOT plan mode).

Pipeline position:
```
arn-code-batch-merge -> **arn-code-batch-simplify** -> (optional: review-implementation -> document-project -> ship)
```

## Prerequisites

If no `## Arness` section exists in the project's CLAUDE.md, inform the user: "Arness is not configured for this project yet. Run `/arn-implementing` to get started — it will set everything up automatically." Do not proceed without it.

## Workflow

### Step 0: Ensure Configuration

Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-ensure-config/references/ensure-config.md` and follow its instructions. Extract from `## Arness`:

- **Plans directory** (default: `.arness/plans`)
- **Code patterns** path (default: `.arness`)
- **Template path** (default: `.arness/templates`)

Hold these values for the remainder of the workflow.

---

### Step 1: Load Pattern Documentation

Load pattern documentation from the code patterns directory:

1. `code-patterns.md` (required)
2. `testing-patterns.md` (required)
3. `architecture.md` (required)
4. `ui-patterns.md` (if it exists)
5. `security-patterns.md` (if it exists)

If any required pattern doc is missing, invoke the `arn-code-codebase-analyzer` agent to generate fresh analysis. If the analyzer is unavailable, suggest running `/arn-implementing` to get started.

Hold all loaded pattern documentation for use throughout the workflow.

---

### Step 2: Collect Batch Scope

Scan the plans directory for `CHANGE_RECORD.json` files across all feature subdirectories:

1. For each `CHANGE_RECORD.json` found, check:
   - `commitHash` is populated (feature was committed)
   - The feature has been merged — check `gh pr view` if `nextSteps` contains a PR URL, or verify the feature branch was merged into main via `git branch --merged main`

2. For each merged feature's `CHANGE_RECORD.json`, collect:
   - `filesModified` — files that were changed
   - `filesCreated` — files that were added
   - `projectName` — the feature name
   - `ceremonyTier` — the ceremony level used
   - `changePath` — path to the feature's plan directory

3. Build the **unified file list**: union of all `filesModified` + `filesCreated` across all merged features, deduplicated. Exclude files that no longer exist on disk (verify with `test -f`).

4. Build the **overlap map**: for each file that appears in 2+ features, record which features touch it. These are priority review targets.

**Exit conditions:**

- If zero merged features found: inform the user "No recently merged batch features found. Run `/arn-code-batch-merge` first." and exit.
- If the unified file list is empty: inform the user "No files to review — all features were merged but produced no file changes." and exit.

---

### Step 3: Present Scope

Display the batch scope summary:

```
Cross-Feature Simplification Scope:

| Feature | Tier | Files |
|---------|------|-------|
| F-003 Auth | thorough | 12 |
| F-005 API | standard | 5 |
| F-008 Settings | thorough | 8 |

Total unique files: [N] (across [M] features)
Files touched by 2+ features: [K] (priority review)
```

Ask (using `AskUserQuestion`): **"Proceed with cross-feature simplification?"**

1. "Yes" (Recommended)
2. "Skip" — exit

If the user selects "Skip", exit gracefully.

---

### Step 4: Dispatch Parallel Reviewers

Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-batch-simplify/references/cross-feature-prompts.md` for the extended reviewer prompt templates.

Build the `{cross_feature_context}` block from the data collected in Step 2 — listing each feature's name, its files, and its change record path.

Dispatch three Agent tool calls **in a single message** so they run in parallel:

1. **Code Reuse Reviewer** — fill the cross-feature-prompts.md template with the file list, pattern documentation, and cross-feature context. Instruct the agent to focus on duplicated logic, missed utilities, and copy-paste patterns, with special attention to utilities created independently by different features.

2. **Code Quality Reviewer** — fill the template. Instruct the agent to focus on unnecessary complexity, dead code, unclear naming, and overly nested logic, with special attention to inconsistent approaches to the same pattern across features.

3. **Efficiency Reviewer** — fill the template. Instruct the agent to focus on N+1 patterns, redundant computations, suboptimal data structures, and unnecessary allocations, with special attention to redundant API clients, validators, or error handlers across features.

Each agent receives:
- `{files_to_review}`: the unified file list
- `{code_patterns}`: content of code-patterns.md
- `{testing_patterns}`: content of testing-patterns.md
- `{architecture}`: content of architecture.md
- `{cross_feature_context}`: the cross-feature context block

**Reviewer agent tools:** Each reviewer agent should be granted only read-only tools: `Read`, `Grep`, `Glob`.

**30-file cap with batching:** If more than 30 files in the unified list, batch by grouping related files. Prioritize files touched by 2+ features in the first batch. Dispatch the three reviewers for each batch sequentially (batch 1 complete, then batch 2, etc.).

**Partial failure handling:** If one reviewer fails, merge findings from the other two. Record the failure in `reviewerStatus` with status `"failed"`. Add a warning: "The [axis] reviewer failed. Findings may be incomplete for that axis."

If all three reviewers fail, inform the user that cross-feature simplification analysis could not be completed. Suggest retrying.

---

### Step 5: Merge and Present Findings

1. Collect findings from all three reviewers.

2. Deduplicate: if two reviewers flagged the same code location for overlapping reasons, merge into a single finding. Prefer the higher severity and note both axes.

3. Assign sequential IDs: `SIM-001`, `SIM-002`, etc.

4. Automatically defer findings with effort `"large"`: set status to `"deferred"` and add a note suggesting a refactoring spec for strategic improvements.

5. Tag each finding based on its `affectedFeatures` array:
   - **Cross-feature finding**: `affectedFeatures` contains 2+ features
   - **Single-feature finding**: `affectedFeatures` contains exactly 1 feature

6. Collect all `patternsPreserved` entries from all reviewers.

7. Present findings grouped by cross-feature vs single-feature:

   **Cross-Feature Findings** (spanning 2+ features):
   - SIM-001 [reuse/medium]: "validateApiResponse() duplicated in auth and API layers"
     Affected: F-003 (src/lib/auth-api.ts), F-005 (src/lib/api-client.ts)
     Suggested: Extract to shared utility
   - SIM-002 [quality/medium]: "Inconsistent error handling — F-003 uses try/catch, F-005 uses .catch()"
     Affected: F-003 (src/lib/auth-api.ts), F-005 (src/routes/api.ts)
     Suggested: Standardize on try/catch per code-patterns.md

   **Single-Feature Findings:**
   - SIM-003 [quality/low]: "Unused import in settings controller"
     Affected: F-008 (src/controllers/settings.ts)
   - SIM-004 [efficiency/small]: "Redundant database query in auth middleware"
     Affected: F-003 (src/middleware/auth.ts)

   **Deferred (large effort):**
   - SIM-005 [reuse/large]: "Three features each implement their own API client wrapper"
     Consider a refactoring spec to consolidate

   **Patterns Preserved:** N decisions respected documented patterns.

If zero findings from all reviewers: inform the user "No cross-feature simplification opportunities found. The implementation looks clean across all features." and skip to Step 8.

---

### Step 6: User Approval

**Auto-all mode check:** Read `pipeline.simplification` using the two-tier preference lookup (see `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-ensure-config/references/preferences-schema.md`). If the resolved value is `auto-all`:

- Auto-approve all non-deferred findings (mark as `"approved"`)
- Skip the user prompt entirely
- Log: "Auto-all mode: approving [N] findings ([M] deferred)."
- Proceed directly to Step 7

**Interactive mode (all other preference values):**

Ask the user which findings to apply:

"Which findings should I apply? Enter finding IDs (e.g., SIM-001, SIM-003), 'all' to apply everything except deferred, or 'none' to skip."

Process the user's selection:
- **Specific IDs**: mark those as `"approved"`, rest as `"rejected"`
- **`"all"`**: mark all non-deferred findings as `"approved"`
- **`"none"`**: mark all as `"rejected"`, skip to Step 8

The user may also change individual finding statuses (e.g., "approve SIM-001 but defer SIM-003").

---

### Step 7: Apply Approved Simplifications

For each approved finding, in dependency order (if finding B depends on finding A's changes, apply A first):

1. Apply the suggested fix.

2. Run targeted tests relevant to the modified files:
   - Use the test command from testing-patterns.md
   - Only run tests covering the modified files, not the full suite

3. If tests pass: mark the finding as `"applied"`. Record in `applicationResults`.

4. If tests fail: attempt self-healing.
   - Fix the implementation issue that caused the failure.
   - Re-run the targeted tests.
   - Up to 3 self-heal attempts per finding.

5. If tests still fail after 3 attempts: **revert** the changes for this specific finding. Mark as `"reverted"` with the failure reason. Record in `applicationResults` and `testVerification.revertedFindings`.

6. Proceed to the next finding regardless of whether this one was reverted.

After all approved findings are processed, run one final targeted test pass to verify the cumulative changes are consistent.

---

### Step 8: Generate Report

1. Read `{template_path}/BATCH_SIMPLIFICATION_REPORT_TEMPLATE.json` where `{template_path}` is the template path extracted in Step 0. If the template file does not exist at the configured path, fall back to `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-save-plan/report-templates/default/BATCH_SIMPLIFICATION_REPORT_TEMPLATE.json`.

2. Populate all fields:
   - `reportType`: `"batch-simplification"`
   - `reportDate`: current ISO 8601 timestamp
   - `reportVersion`: `1`
   - `batchFeatures`: array of objects, one per merged feature, containing `projectName`, `ceremonyTier`, `fileCount`, `changePath`
   - `crossFeatureFindings`: count of findings that span 2+ features
   - `singleFeatureFindings`: count of findings that span exactly 1 feature
   - `configuration`: files reviewed count, batch count, review axes used, pattern docs loaded
   - `findings`: all findings with their final statuses
   - `patternsPreserved`: all pattern-preservation records from all reviewers
   - `applicationResults`: results for each applied finding
   - `testVerification`: test run summary including `revertedFindings`
   - `summary`: counts of total, approved, rejected, applied, reverted, deferred
   - `reviewerStatus`: status and finding count per reviewer axis
   - `warnings`: any warnings accumulated during the process
   - `nextSteps`: context-dependent suggestions

3. Write the report to `.arness/plans/BATCH_SIMPLIFICATION_REPORT.json` (not inside a feature-specific directory — this spans all features).

If `BATCH_SIMPLIFICATION_REPORT_TEMPLATE.json` is missing from the template path, generate the report with a minimal structure (`reportType`, `batchFeatures`, `crossFeatureFindings`, `findings`, `summary`, `warnings`, `nextSteps`) and warn the user: "Report template not found. Generated report with minimal structure."

---

### Step 9: Test and Ship

If any fixes were applied (at least one finding has status `"applied"`):

#### 9a. Run Tests

Ask (using `AskUserQuestion`):

**"Simplification fixes applied. Run the project's test suite to verify nothing is broken?"**

Options:
1. **Yes, run tests** — Run the full test suite before committing
2. **Skip tests** — Proceed to commit

If **Yes, run tests:**
- Read the test command from testing-patterns.md
- Run the test suite via Bash
- Present results
- If tests fail: show failures, offer to investigate and fix. After fixing, re-run tests.
- If tests pass: "All tests pass. Ready to commit."

#### 9b. Branch and Commit

Create a separate branch for the simplification — do NOT commit directly to main:

```bash
git checkout -b batch-simplify/<date>
```

Stage all modified files and create a commit:

```
[batch-simplify] Cross-feature quality improvements

Consolidated [N] findings across [M] features.
[K] cross-feature duplications resolved.
```

#### 9c. Push and PR

Push the branch and create a PR:

```bash
git push -u origin batch-simplify/<date>
```

- Platform `github`: `gh pr create --title "[batch-simplify] Cross-feature quality improvements" --body "<summary of applied findings>"`
- Platform `bitbucket`: `bkt pr create --title "[batch-simplify] Cross-feature quality improvements" --description "<summary>" --source batch-simplify/<date> --destination main`
- Platform `none`: push only, inform user to merge manually

Present the PR URL to the user: "Simplification changes are on a separate branch with a PR to main. Review and merge when ready."

Return to main:

```bash
git checkout main
```

If no fixes were applied (all findings were rejected, deferred, or reverted), skip the commit entirely.

---

## Error Handling

- **`## Arness` config missing** — inform the user: "Arness is not configured for this project yet. Run `/arn-implementing` to get started."
- **Pattern docs missing** — invoke `arn-code-codebase-analyzer` to generate fresh analysis. If unavailable, suggest running `/arn-implementing` to get started.
- **Reviewer agent fails** — merge findings from the other two reviewers and note the missing perspective in the report. Add a warning about incomplete coverage for that axis.
- **All three reviewers fail** — inform the user that cross-feature simplification analysis could not be completed. Suggest retrying or proceeding to the next pipeline step.
- **BATCH_SIMPLIFICATION_REPORT_TEMPLATE.json missing** — generate the report with a minimal structure and warn the user.
- **Test self-heal exhaustion** — after 3 failed attempts for a finding, revert that finding's changes and continue with the next finding. Record the failure details in the report.
- **No findings** — generate a clean report with `summary.totalFindings: 0` and inform the user: "No cross-feature simplification opportunities found. The implementation looks clean across all features."
- **No merged features** — inform the user: "No recently merged batch features found. Run `/arn-code-batch-merge` first."

## Constraints

- Maximum 30 files per review pass (batch if more, prioritizing multi-feature overlap files first).
- Findings with effort `"large"` are always deferred, never applied during simplification.
- Each self-heal cycle gets at most 3 attempts before revert.
- Per-finding revert: a failed finding does not affect other successfully applied findings.
- Never modify files outside the unified scope's file list without explicit user approval.
- Anonymous Agent tool calls only — no named agent files for reviewers.
- Report is written to `.arness/plans/BATCH_SIMPLIFICATION_REPORT.json`, not inside any feature subdirectory.
