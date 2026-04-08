---
name: arn-code-batch-planning
description: >-
  This skill should be used when the user says "batch planning", "batch plan",
  "arness batch planning", "arn-code-batch-planning", "plan multiple features",
  "plan all features", "plan unblocked features", "plan the backlog",
  "plan from backlog", "batch spec and plan", "plan next features",
  "sequential planning", "multi-feature plan", "plan the next batch",
  "plan these features", "batch plan GitHub issues", "batch plan from Jira",
  "plan issues in batch",
  or wants to plan multiple features from the greenfield Feature Tracker,
  GitHub issues, or Jira issues in a single session. Pre-analyzes all
  selected features in parallel, then guides sequential spec review with
  pipelined plan generation. This skill is
  typically invoked directly or after arn-brainstorming completes and
  chains to arn-code-batch-implement upon completion. For single-feature
  planning, arn-planning is the correct entry point.
version: 1.0.0
---

# Arness Batch Planning

Plan multiple features in a single session with parallel pre-analysis and pipelined plan generation. Supports features from greenfield Feature Tracker (F-NNN), GitHub issues, Jira issues, or plain descriptions. Pre-analyzes all selected features in parallel using `arn-code-batch-analyzer` agents to generate draft specs, then guides the user through sequential review. Plans are generated in the background while the user reviews the next spec.

This skill is a **sequencer**. It MUST NOT duplicate sub-skill logic. All pipeline work is done by the invoked skills and agents (`arn-code-batch-analyzer`, `arn-code-feature-spec`, `arn-code-feature-planner`, `arn-code-save-plan`). Arness-code-batch-planning handles: source detection, feature selection, parallel pre-analysis orchestration, sequential spec review, pipelined plan generation, plan review, and chaining.

Pipeline position:
```
Sources:
  arn-spark (greenfield) -> feature-backlog.md ─┐
  GitHub issues ─────────────────────────────────┤
  Jira issues ───────────────────────────────────┤
                                                  v
                                  **arn-code-batch-planning**
                                    |
                                    +-- Step 2.5: scope assessment (score each feature → swift/standard/thorough)
                                    +-- Step 2.6: generate SWIFT/STANDARD plans (auto, no review)
                                    +-- Step 2.7: parallel arn-code-batch-analyzer (thorough only → draft specs)
                                    +-- Step 3: per thorough feature: arn-code-feature-spec (resume from draft)
                                    +-- Step 3.5: per thorough feature: plan review → save-plan
                                    |
                                    v
                                  arn-code-batch-implement
```

## Step 0: Ensure Configuration

Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-ensure-config/references/ensure-config.md` and follow its instructions. This guarantees a user profile exists and `## Arness` is configured with Arness Code fields before proceeding.

After configuration is ensured, extract the following from `## Arness`:
- **Plans directory** — base path where project plans and PLAN_PREVIEW files are stored
- **Specs directory** — path to the directory containing specification files
- **Code patterns** — path to the directory containing stored pattern documentation
- **Vision directory** (if exists) — path to greenfield vision artifacts
- **Use cases directory** (if exists) — path to UC documents
- **Issue tracker** — determines remote issue tracker type (`github`, `jira`, or `none`)
- **Template path** — path to report templates

---

## Step 1: Detect Feature Sources

Batch planning supports multiple feature sources. Check them in order — the first match determines the primary source.

### 1a. Check for Greenfield Feature Tracker

Read the backlog-selection reference: `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-batch-planning/references/backlog-selection.md`. Follow its procedure to scan the Feature Tracker and identify unblocked features.

**If greenfield backlog exists with 2+ unblocked features:** Proceed to Step 2 with greenfield features (input_type: `greenfield` for each).

**If greenfield backlog exists with exactly 1 unblocked feature:**

Inform the user: "Only 1 unblocked feature found: **F-XXX [Feature Name]**. Batch planning is designed for 2+ features."

Ask (using `AskUserQuestion`):

**"How would you like to proceed?"**

Options:
1. **Plan this feature** — Switch to arn-planning with F-XXX
2. **Proceed with batch anyway** — Use the batch pipeline for this single feature
3. **Exit**

If **Plan this feature**: invoke `Skill: arn-code:arn-planning` with the F-XXX reference. Exit batch-planning.
If **Proceed with batch anyway**: continue to Step 2 with the single feature pre-selected.
If **Exit**: STOP.

**If greenfield backlog exists with zero unblocked features:**

Inform the user: "No unblocked features found. All pending features have incomplete dependencies." Present the summary counts.

Ask (using `AskUserQuestion`):

**"No features are available for batch planning. What would you like to do?"**

Options:
1. **Switch to single-feature planning** — Run arn-planning to describe a feature or report a bug
2. **Exit** — I'll wait for dependencies to complete

If **Switch**: invoke `Skill: arn-code:arn-planning`. Exit batch-planning.
If **Exit**: STOP.

### 1b. Check for Remote Issues (Non-Greenfield Fallback)

**If no greenfield Feature Tracker exists** (no Vision directory field, or no `feature-backlog.md`) BUT Issue tracker is `github` or `jira`:

Ask (using `AskUserQuestion`):

**"No greenfield feature backlog found, but [GitHub/Jira] issues are available. How would you like to select features?"**

Options:
1. **Browse [GitHub/Jira] issues** — Select multiple issues to plan in batch
2. **Switch to arn-planning** — Plan a single feature instead
3. **Exit**

If **Browse issues:**
- For GitHub: `gh issue list --state open --limit 20 --json number,title,labels`
- For Jira: fetch open issues via MCP
- Present in a table with number, title, and labels
- Let user multi-select which issues to plan (same layered selection as Step 2)
- For each selected issue, set input_type: `github_issue` or `jira_issue`
- Proceed to Step 2 with the selected issues

If **Switch**: invoke `Skill: arn-code:arn-planning`. Exit.
If **Exit**: STOP.

### 1c. No Feature Source Available

**If no greenfield backlog AND no Issue tracker configured:**

Inform the user: "Batch planning requires either a greenfield feature backlog or an issue tracker (GitHub/Jira). Run `arn-brainstorming` to set up the greenfield pipeline, or configure an issue tracker in `## Arness`." Offer: "Or run `arn-planning` to plan a single feature by description." STOP.

---

## Step 2: Feature Selection

Present the unblocked features in a table sorted by phase then priority:

```
Unblocked features ready for planning:

| # | ID | Feature | Priority | Phase | Deps |
|---|------|---------|----------|-------|------|
| 1 | F-001 | [Name] | Must-have | Foundation | None |
| 2 | F-003 | [Name] | Should-have | Core | F-001 |
| ... | ... | ... | ... | ... | ... |
```

Also show summary: "[total] features in tracker, [unblocked] unblocked, [in-progress] in progress, [done] done."

### Selection flow

**If 4 or fewer unblocked features:**

Ask (using `AskUserQuestion`, multiSelect: true):

**"Which features would you like to plan for batch implementation? Select all that apply."**

Options: list each unblocked feature as `F-XXX: [Feature Name]`

**If more than 4 unblocked features:**

Use layered selection to stay within the 4-option AskUserQuestion limit.

First, ask (using `AskUserQuestion`):

**"There are [N] unblocked features. How would you like to select?"**

Options:
1. **All unblocked features** — Plan all [N] features sequentially
2. **Let me choose** — Pick specific features from the list

If **All unblocked features**: select all, proceed to Step 2.5.

If **Let me choose**: present features in groups of 4 using sequential `AskUserQuestion` calls (multiSelect: true). After each group, ask if the user wants to select from the next group or proceed with current selections. Continue until all groups are offered or the user says proceed.

After feature selection is confirmed, inform the user about the batch workflow:

"**Batch planning workflow:** After all features are planned, the specs and plans will be committed to a new branch, pushed, and a PR will be opened to merge them into main. This is required before batch implementation — workers need the plans on main to find them. You'll be asked to confirm the PR merge before any implementation begins."

If Git is `no`: instead inform: "Plans will be saved locally. Note: batch implementation requires git — you can implement features one at a time with `/arn-implementing`."

---

## Step 2.5: Scope Assessment

Score each selected feature to determine its ceremony tier. This is a lightweight assessment using only the feature description and pattern documentation — no codebase reading required. The same scope router used by `arn-planning` (Step 3C) is applied here per feature.

### 2.5a. Load Scope Router Context

Read (if not already loaded):
- `<code-patterns-dir>/architecture.md`
- `<code-patterns-dir>/code-patterns.md`
- `${CLAUDE_PLUGIN_ROOT}/skills/arn-planning/references/scope-router-criteria.md`

### 2.5b. Score Each Feature

For each selected feature, apply the scope router criteria from the reference:

1. Rate each of the 6 criteria (file count, domain sensitivity, architectural change, cross-module impact, reversibility risk, test infrastructure) based on the feature's description and the loaded pattern documentation.
2. Multiply each rating (0/1/2) by the criterion's weight.
3. Sum the weighted scores (0-20).
4. Apply override rules (high-weight high-score → minimum standard; multi-high → minimum thorough).
5. Map to tier: 0-4 → swift, 5-12 → standard, 13-20 → thorough.
6. Apply edge case rules (borderline 4-5 defaults to standard, borderline 12-13 defaults to thorough).

### 2.5c. Present Assessment

Show the results table:

```
Scope Assessment: [N] features scored

| # | ID | Feature | Score | Tier | Key Factor |
|---|------|---------|-------|------|-----------|
| 1 | F-001 | [Name] | [N] | swift | [one-sentence rationale] |
| 2 | F-003 | [Name] | [N] | standard | [one-sentence rationale] |
| 3 | F-005 | [Name] | [N] | thorough | [one-sentence rationale] |
```

Do NOT present individual criterion scores (per scope-router-criteria.md: "This assessment is internal — do not present the scoring table to the user"). Present only the recommended tier and a one-sentence rationale.

Show pipeline summary:

```
Pipeline routing:
  [N] swift     — workers plan + execute autonomously (no interactive review)
  [M] standard  — workers plan + execute autonomously (no interactive review)
  [K] thorough  — interactive spec review below, then workers execute
```

### 2.5d. Tier Override Gate

Ask (using `AskUserQuestion`):

**"Tier assignments look right?"**

Options:
1. **Looks good** — Proceed with these tiers
2. **Adjust tiers** — Let me override individual assignments

If **Looks good**: proceed to Step 2.6.

If **Adjust tiers**: for each feature the user wants to change, ask which tier to assign (swift, standard, or thorough). No warning is needed for downgrades — the recommendation is advisory per scope-router-criteria.md rule 4. After adjustments, re-display the final table and proceed.

---

## Step 2.6: Generate Swift/Standard Plans

For features assigned to swift or standard tiers, generate plan artifacts immediately. These features skip the interactive spec review — batch-implement workers will read these plans and handle execution autonomously.

Read the plan templates:
- `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-swift/references/swift-plan-template.md` (for swift features)
- `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-standard/references/standard-plan-template.md` (for standard features)

**For each swift feature:**

1. Derive project name: `SWIFT_<kebab-case-name>` (from feature name)
2. Create directory: `mkdir -p <plans-dir>/SWIFT_<name>/`
3. Generate `SWIFT_<name>.md` following the swift plan template, populated from:
   - Feature description (from source: greenfield feature file, GitHub issue body, Jira description, or plain text)
   - Pattern documentation (architecture.md, code-patterns.md, testing-patterns.md)
   - Scope assessment notes (files likely affected, patterns that apply, identified risks)
4. Write the plan file

**For each standard feature:**

1. Derive project name: `STANDARD_<kebab-case-name>` (from feature name)
2. Create directory: `mkdir -p <plans-dir>/STANDARD_<name>/`
3. Generate `STANDARD_<name>.md` following the standard plan template, populated from:
   - Feature description (same sources as above)
   - Pattern documentation (all loaded pattern docs)
   - Scope assessment notes
   - Spec-Lite section: derive problem statement, key requirements (3-7), and architectural notes from the feature description and architecture.md
   - Implementation Tasks section (always present for standard tier)
4. Write the plan file

**If greenfield source:** Update the Feature Tracker status to `in-progress` for each swift/standard feature.

Show each generated plan to the user with a brief summary:

```
Swift/Standard Plans Generated: [N] features

1. SWIFT_<name>.md — [1-2 sentence summary of scope, files, approach]
2. STANDARD_<name>.md — [1-2 sentence summary of scope, key requirements, files]
...
```

For each plan, show: the tier, problem statement (or scope summary), files to modify, and key patterns that will be followed. This gives the user a quick sanity check without full interactive exploration.

Ask (using `AskUserQuestion`):

**"Review these plans before proceeding?"**

Options:
1. **Looks good** — Proceed with all plans as generated
2. **Review one** — Let me look at a specific plan in detail
3. **Adjust tiers** — Some of these need a different tier (returns to Step 2.5d)

If **Looks good**: proceed to Step 2.7.

If **Review one**: present the plans as options (max 4, layered if more). When user selects a plan, show its full content. Ask:

**"What would you like to do with this plan?"**

Options:
1. **Approve** — Plan is fine as-is
2. **Edit** — Let me adjust the plan content
3. **Upgrade to thorough** — This needs full interactive spec review

If **Approve**: return to the plan selection (for reviewing another) or proceed.
If **Edit**: let the user modify the plan, write updated version. Return to selection.
If **Upgrade to thorough**: move this feature from the swift/standard list to the thorough list. It will go through Step 2.7 pre-analysis and Step 3 interactive review.

If **Adjust tiers**: return to Step 2.5d (tier override gate) with current assignments.

After all reviews complete, proceed to Step 2.7.

---

## Step 2.7: Pre-Analysis (Parallel) — Thorough Features Only

**If no features were assigned to the thorough tier, skip this step entirely and proceed to Step 3.**

Pre-generate draft specs for thorough features only using `arn-code-batch-analyzer` agents. Swift and standard features already have plan artifacts from Step 2.6 and do not need pre-analysis.

Show progress:
```
Pre-analyzing [K] thorough features in parallel...
(Swift and standard features already have plans — skipping pre-analysis for those.)
```

For each thorough feature, spawn a `arn-code-batch-analyzer` agent with:
- `run_in_background: true`
- The feature's input type and source-specific context:
  - Greenfield: feature ID, feature file path, vision dir, use cases dir
  - GitHub issue: issue reference
  - Jira issue: issue key
- Code patterns path
- Specs directory and derived spec name
- Template reference: `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-feature-spec/references/feature-spec-template.md`
- Greenfield loading reference: `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-feature-spec/references/greenfield-loading.md`

**ALL agents MUST be spawned in a SINGLE message** for true parallelism.

Wait for all agents to complete. As each completes, report:
```
Pre-analysis complete: F-XXX [Name] (draft spec written)
```

**If any agent fails:** Retry that specific feature's batch-analyzer (up to 2 retries). If it still fails after 3 total attempts, pause and inform the user:

"Pre-analysis failed for F-XXX [Name] after 3 attempts: [error details]"

Ask (using `AskUserQuestion`):

**"How would you like to handle this?"**

Options:
1. **Retry again** — Give it one more attempt
2. **Skip this feature** — Remove it from the batch
3. **Abort pre-analysis** — Stop and troubleshoot

**Never silently fall back to a degraded flow.** The user must always know what happened and explicitly choose how to proceed.

After all agents complete, show summary:
```
[K] draft specs ready for thorough features. Starting interactive review.
```

Proceed to Step 3.

---

## Step 3: Sequential Spec Review Loop — Thorough Features Only

**If no features were assigned to the thorough tier, skip this step and proceed to Step 3.5.**

Show the plan:
```
Batch Planning: [N] features selected
Order: F-XXX -> F-YYY -> F-ZZZ -> ...
```

For each selected feature, sequentially:

### 3a. Show Progress

```
Reviewing feature [current/total]: F-XXX [Feature Name]
─────────────────────────────────────────────────────
```

### 3b. Update Feature Tracker

If the source is greenfield: update the Feature Tracker status to `in-progress` for this feature. Re-write `feature-backlog.md` with the updated tracker.

**Revert on failure:** If this feature is later skipped (via error handling) or the batch is aborted, revert the feature's status from `in-progress` back to `pending` before proceeding.

### 3c. Invoke Feature Spec

Invoke `Skill: arn-code:arn-code-feature-spec` with the feature context.

Feature-spec will detect the pre-built `DRAFT_FEATURE_*.md` file (written by the batch-analyzer in Step 2.7) and offer: "Resume or start fresh?" The user picks "Resume" and exploration starts immediately with the pre-built analysis — no agent wait.

**Sketch context for batch workflows (conditional):** If the batch-analyzer reported UI involvement for this feature (check the draft's Architectural Assessment or UI Design sections for non-empty content), prepend this context to the feature description before invoking feature-spec:

> "This feature is being planned for batch implementation. Completing the sketch during planning is strongly recommended — batch workers cannot interact with users to iterate on sketches during implementation. Sketch completion ensures workers can promote validated components autonomously."

If the batch-analyzer did not detect UI involvement, omit this context entirely — it would be confusing for non-UI features. Feature-spec will present the sketch offer with this additional context when it detects UI involvement. The user's decision within feature-spec is final.

### 3d. Background Plan Generation (Pipelined)

After feature-spec completes and the finalized spec file exists (FEATURE_*.md):

1. Read the finalized spec file
2. Derive the spec name from the filename
3. Spawn the `arn-code-feature-planner` agent with:
   - `run_in_background: true`
   - The full spec file content (FEATURE_*.md or BUGFIX_*.md)
   - The spec file path (for the `Spec:` linkage line in the plan)
   - `code-patterns.md` content
   - `testing-patterns.md` content
   - `architecture.md` content
   - `ui-patterns.md` content (if exists)
   - `security-patterns.md` content (if exists)
   - Output path: `<plans-dir>/PLAN_PREVIEW_<spec-name>.md`

Immediately proceed to Step 3a for the NEXT feature. The plan generates in the background while the user reviews the next spec.

### 3e. Progress Report

Print:
```
Feature F-XXX [Name] spec finalized. Plan generating in background. [remaining] remaining.
```

### Error Handling (Spec Phase)

**If feature-spec fails (error or unexpected exit):**

Ask (using `AskUserQuestion`):

**"Feature spec for F-XXX encountered an error. How would you like to proceed?"**

Options:
1. **Retry** — Run feature-spec again for this feature
2. **Skip** — Skip this feature and continue with the next
3. **Abort** — Stop batch planning

**If the user says "stop" mid-loop:**

Show what has been completed so far (completed specs and any plans already generated). Inform the user: "Batch planning paused. [M] of [N] features spec'd. Plans are generating in background for completed specs. Run `/arn-code-batch-implement` when ready — it will pick up completed plans."

---

## Step 3.5: Plan Review Phase — Thorough Features Only

**If no features were assigned to the thorough tier, skip this step and proceed to Step 4.**

After all thorough specs are reviewed, collect and review all generated plans for thorough features. Swift and standard plans were already written in Step 2.6 and do not need user review.

Wait for any still-running background planners to complete. Show progress:
```
Waiting for plan generation to complete: [N] plans ready, [M] still generating...
```

For each feature (in order):

### 3.5a. Check Plan Status

- **If PLAN_PREVIEW exists:** present a summary of the plan (phases, deliverables, key decisions).
- **If planner failed:** retry once in the foreground. If it fails again, inform the user with the error and ask:

  Ask (using `AskUserQuestion`):

  **"Plan generation failed for F-XXX. How would you like to proceed?"**

  Options:
  1. **Retry** — Run the planner again
  2. **Skip this feature** — Remove it from the batch
  3. **Abort** — Stop batch planning

### 3.5b. Plan Approval

Ask (using `AskUserQuestion`):

**"Does this plan for F-XXX look right?"**

Options:
1. **Approve** — Save this plan and continue
2. **Adjust** — Let me refine the plan
3. **Skip this feature** — Remove from the batch

If **Approve**: invoke `Skill: arn-code:arn-code-save-plan`. Proceed to the next feature's plan.

If **Adjust**: let the user provide feedback. Spawn the `arn-code-feature-planner` agent (foreground) with revision instructions and the current plan path. Re-present with the same 3 options. Repeat until approved or skipped.

If **Skip**: remove this feature from the batch. Revert Feature Tracker status to `pending` if applicable. Continue with the next feature's plan.

---

## Step 4: Summary

Present a summary table after all features are processed:

```
Batch Planning Complete: [completed]/[total] features ready

| Feature | Tier | Source | Sketch | Plan Path |
|---------|------|--------|--------|-----------|
| F-001: [Name] | swift | auto-planned | N/A | .arness/plans/SWIFT_[name]/ |
| F-003: [Name] | standard | auto-planned | N/A | .arness/plans/STANDARD_[name]/ |
| F-005: [Name] | thorough | interactive | Done | .arness/plans/[project]/ |
```

**Source column:**
- `auto-planned` — plan generated by batch-planning (Step 2.6), worker handles execution
- `interactive` — spec reviewed interactively, plan saved via save-plan

**Sketch detection (thorough features):** Check if `arness-sketches/<feature>/` exists with a status file indicating `kept` → `Done`. Otherwise → `N/A`. Swift and standard features always show `N/A` for sketch.

If any features were skipped, list them separately: "Skipped: F-XXX (spec error), F-YYY (user skipped)"

---

## Step 5: Ship Plans

Before launching batch-implement, all planning artifacts must be on main so workers can find them.

Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-batch-planning/references/plan-shipping.md` and follow its procedure. This handles:
- Creating a plans branch (if on main)
- Staging and committing all plan artifacts
- Pushing and creating a PR (platform-dependent)
- Waiting for the user to confirm the PR is merged
- Checking out main and pulling

If Git is `no`: skip shipping. Inform the user that plans are local only and batch-implement requires git. Offer to exit or implement features one at a time via `/arn-implementing`.

---

## Step 6: Handoff

After plans are on main (PR merged and pulled):

Ask (using `AskUserQuestion`):

**"Plans are on main. Launch batch implementation?"**

Options:
1. **Launch batch implementation** — Invoke `Skill: arn-code:arn-code-batch-implement`
2. **Not yet** ��� Exit

If **Launch batch implementation**: invoke `Skill: arn-code:arn-code-batch-implement`.

If **Not yet**: "Run `/arn-code-batch-implement` when ready. All plans are saved on main."
