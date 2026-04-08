---
name: arn-spark-concept-review
description: >-
  This skill should be used when the user says "concept review", "review concept",
  "update product concept", "synthesize stress tests", "stress test review",
  "apply stress test findings", "review stress test results", "concept update",
  "merge stress test recommendations", or wants to synthesize findings from
  completed stress tests into a reviewed and updated product concept document.
  Scans for stress test reports, consolidates recommendations, resolves conflicts
  using product pillars, presents the full changeset for user approval, and
  produces an updated product-concept.md alongside a concept-review-report.md.
version: 1.0.0
---

# Arness Spark Concept Review

Synthesize findings from completed stress tests into an updated product concept. This skill scans for stress test reports, extracts their Recommended Concept Updates tables and Unresolved Questions, invokes the product strategist to consolidate and de-duplicate recommendations, resolves conflicts using product pillars, and presents the full proposed changeset to the user for approval before making any changes.

This is the **only skill that modifies product-concept.md**. All stress test skills are read-only with respect to the product concept -- they write recommendations to their reports, and this skill is the single point where those recommendations become actual changes, subject to explicit user approval.

The process:
1. Scan for available stress test reports
2. Extract all recommendations and unresolved questions
3. Consolidate, de-duplicate, and detect conflicts via the product strategist
4. Conditionally involve the UX specialist for UX-relevant changes
5. Present the full changeset to the user for approval (accept all, or review individually)
6. Apply approved changes: rename the original concept, write the updated concept
7. Write the concept review report as an audit trail

## Prerequisites

### Configuration Check

1. Read the project's `CLAUDE.md` and check for a `## Arness` section
2. If found, extract the configured **Vision directory** and **Reports directory** paths
3. If no `## Arness` section exists or Arness Spark fields are missing, inform the user: "Arness Spark is not configured for this project yet. Run `/arn-brainstorming` to get started — it will set everything up automatically." Do not proceed without it.
4. If the Reports directory or `stress-tests/` subdirectory does not exist, inform the user: "No stress-tests directory found. Run a stress test skill first to generate reports." (The stress test skills create this directory when writing their reports.)

### Data Availability

| Artifact | Status | Location | Fallback |
|----------|--------|----------|----------|
| Product concept | REQUIRED | `<vision-dir>/product-concept.md` | Cannot proceed without it -- suggest running `/arn-spark-discover` |
| Product pillars | REQUIRED | Product Pillars section of product concept | Cannot resolve conflicts without pillars -- suggest running `/arn-spark-discover` to define pillars |
| At least 1 stress test report | REQUIRED | `<reports-dir>/stress-tests/` | Cannot proceed without at least one report -- see below |
| Competitive landscape | ENRICHES | Competitive Landscape section of product concept | Review proceeds but competitive context is unavailable for conflict resolution |

**Stress test report detection:**

Scan `<reports-dir>/stress-tests/` for the following report files:
- `interview-report.md` (from `/arn-spark-stress-interview`)
- `competitive-report.md` (from `/arn-spark-stress-competitive`)
- `premortem-report.md` (from `/arn-spark-stress-premortem`)
- `prfaq-report.md` (from `/arn-spark-stress-prfaq`)

Present the scan results to the user:

"Found [N] stress test report(s):
- ✓ / — Interview Report: [found / not found]
- ✓ / — Competitive Report: [found / not found]
- ✓ / — Pre-Mortem Report: [found / not found]
- ✓ / — PR/FAQ Report: [found / not found]"

Use ✓ for found reports and — for missing reports.

**If 0 reports found:**

Inform the user: "No stress test reports found in `<reports-dir>/stress-tests/`. Run at least one stress test skill before reviewing the concept."

List the available stress test skills:
- `/arn-spark-stress-interview` -- Synthetic user interviews with adversarial personas
- `/arn-spark-stress-competitive` -- Competitive gap analysis
- `/arn-spark-stress-premortem` -- Pre-mortem failure investigation
- `/arn-spark-stress-prfaq` -- PR/FAQ marketing stress test

Do not proceed. Exit the skill.

**If 1 or more reports found:** Proceed with the available reports.

## Workflow

### Step 1: Load References

Load the conflict resolution protocol and review report template:
> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-concept-review/references/conflict-resolution-protocol.md`
> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-concept-review/references/review-report-template.md`

### Step 2: Read Reports and Extract Data

For each available stress test report:

1. Read the full report from `<reports-dir>/stress-tests/`
2. Extract the **Recommended Concept Updates** table -- parse every row preserving: row number, section, current state, recommended change, type (Add/Modify/Remove), rationale
3. Extract the **Unresolved Questions** section -- parse every row preserving: row number, section, question, options, assessment
4. Record the source report name, file path, and report date for attribution

Also read the current product concept from `<vision-dir>/product-concept.md`. Extract:
- The full document content (for the strategist)
- The Product Pillars section specifically (for conflict resolution)
- All section headings (for validating that recommendations reference real sections)

### Step 3: Invoke Product Strategist for Consolidation

Invoke the `arn-spark-product-strategist` agent with:

--- PRODUCT CONCEPT ---
[full product concept content]
--- END PRODUCT CONCEPT ---

--- PRODUCT PILLARS ---
[product pillars section content]
--- END PRODUCT PILLARS ---

--- STRESS TEST RECOMMENDATIONS ---
Source: [Report 1 name]
[full Recommended Concept Updates table from report 1]

Source: [Report 2 name]
[full Recommended Concept Updates table from report 2]

[... for all available reports]
--- END STRESS TEST RECOMMENDATIONS ---

--- CONSOLIDATION TASK ---
Follow the conflict resolution protocol:
1. De-duplicate recommendations that target the same section with semantically equivalent changes. Merge them with multi-source attribution.
2. Detect conflicts: recommendations targeting the same section with contradictory changes.
3. For each conflict, assess which recommendation better serves the product pillars. Produce a conflict resolution assessment with: both sides stated, pillar alignment analysis for each, your recommendation with reasoning, and a plain-language trade-off statement.
4. Organize the consolidated changeset grouped by product concept section.
5. Do NOT auto-resolve any conflicts. Present your assessment but flag that the user decides.
--- END CONSOLIDATION TASK ---

Receive back the consolidated changeset with de-duplicated recommendations, detected conflicts with resolution assessments, and the organized section grouping.

### Step 4: Conditional UX Specialist Involvement

Check the product concept content for signals that the UX specialist was involved in its creation:

- Explicit mentions of "UX specialist", "arn-spark-ux-specialist", or "UX review" in the document (strong signal)
- Dedicated sections with visual direction details (color names, font families, spacing values, component specs)
- References to prototype files, design artifacts, or Figma links
- Sections with interaction descriptions (click behaviors, transitions, micro-interactions) beyond basic flow

**Trigger condition:** If ANY of these signals are present, invoke the UX specialist.

**If UX signals are detected:**

Identify which recommendations in the consolidated changeset affect UX-relevant sections (Core Experience, visual direction, interaction patterns, onboarding flows, accessibility). If any exist, invoke `arn-spark-ux-specialist` with:

--- PRODUCT CONCEPT ---
[full product concept content]
--- END PRODUCT CONCEPT ---

--- UX-RELEVANT CHANGES ---
[subset of changeset recommendations that affect UX sections]
--- END UX-RELEVANT CHANGES ---

--- UX REVIEW TASK ---
Review the proposed changes to UX-relevant sections. For each change:
1. Does the change align with the visual direction and interaction patterns established in the concept?
2. Are there UX implications the stress tests may have missed?
3. Do you have supplementary recommendations for implementing this change while preserving design coherence?
--- END UX REVIEW TASK ---

Incorporate the UX specialist's feedback into the changeset as supplementary notes alongside each relevant recommendation.

**If no UX signals are detected:** Skip this step entirely.

### Step 5: Present Changeset for User Approval

**This is the mandatory user approval gate. No changes to the product concept are made without explicit user approval.**

Present the full consolidated changeset to the user, organized by product concept section. For each recommendation, show:
- Source report(s)
- Type (Add / Modify / Remove)
- Current state of the affected section
- Proposed change
- Rationale with source attribution
- UX specialist notes (if applicable)

For each conflict, show:
- Both recommendations with source attribution
- The strategist's conflict resolution assessment (pillar analysis, recommendation, trade-off)

After presenting the changeset, also show the aggregated unresolved questions (de-duplicated across reports, with source attribution).

Then ask for the user's decision:

Ask (using `AskUserQuestion`): **"How would you like to handle these [N] proposed changes?"**
1. Accept all changes as proposed
2. Review by section (batch accept/reject per section, then drill into individual changes if needed)
3. Review each change individually

**If the user chooses "Accept all":**
All non-conflicting changes are accepted as-is. For each conflict, accept the strategist's recommended resolution. Proceed to Step 6.

**If the user chooses "Review by section":**
Present changes grouped by product concept section. For each section with changes:

Ask (using `AskUserQuestion`): **"[Section Name] — [N] changes: [brief summary of changes]"**
1. Accept all in this section
2. Reject all in this section
3. Review individually within this section

If **Accept all** or **Reject all**, record the batch decision and move to the next section. If **Review individually**, present each change in the section using the individual review pattern below. After all sections are reviewed, handle conflicts (same as individual review).

**If the user chooses "Review individually":**
Present changes grouped by product concept section. For each change (or batch of related changes within a section):

Ask (using `AskUserQuestion`): **"[Section Name] -- [Change summary]: [Type] -- [brief description]"**
1. Accept
2. Reject
3. Modify

- **Accept:** Record the change as accepted.
- **Reject:** Use plain-text conversational input (not AskUserQuestion) to ask "Why would you like to reject this change?" Record the change as rejected with the user's reason.
- **Modify:** Use plain-text conversational input (not AskUserQuestion) to ask "Describe your modification." Record the change as modified with the user's modification.

For conflicts, present both sides with the strategist's assessment:

Ask (using `AskUserQuestion`): **"CONFLICT in [Section Name]: [Brief description]. The strategist recommends [recommended side]. How would you like to resolve this?"**
1. Accept strategist's recommendation ([brief description of recommended side])
2. Choose the other recommendation ([brief description of other side])
3. Provide a custom resolution

- If the user chooses option 3, collect their custom resolution as free-form text input.

**If the user rejects ALL changes (every individual change rejected):**
Inform the user: "All proposed changes have been rejected. The product concept will not be modified. A review report will still be written documenting the stress test findings and your decisions."
Skip the concept rename and rewrite in Step 6. Proceed directly to Step 7 to write the review report.

### Step 6: Apply Approved Changes

This step is skipped if the user rejected all changes.

**6a. Read the product concept template:**

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-discover/references/product-concept-template.md`

This is the template that governs the structure of the product concept. The updated concept MUST preserve this template's section structure exactly.

**6b. Rename the original concept:**

Rename `<vision-dir>/product-concept.md` to `<vision-dir>/product-concept-pre-review.md`.

If a file named `product-concept-pre-review.md` already exists (from a previous review cycle), overwrite it. Git provides history.

If the rename fails, inform the user of the error and ask whether to proceed with writing the updated concept anyway (the original would be lost) or abort. Use:

Ask (using `AskUserQuestion`): **"Could not rename the original product concept. How would you like to proceed?"**
1. Write the updated concept anyway (original will be overwritten)
2. Abort -- do not modify the product concept

**6c. Write the updated product concept:**

Starting from the pre-review product concept content, apply all accepted and modified changes while preserving the template structure:

- Every section from the product concept template MUST appear in the output
- Apply "Add" changes by adding content to the specified section
- Apply "Modify" changes by updating the specified content within the section
- Apply "Remove" changes by removing the specified content from the section (but keep the section heading if other content remains)
- For modified changes, use the user's modified version, not the original recommendation
- For resolved conflicts, apply the chosen resolution
- Preserve all sections and content that were NOT targeted by any recommendation
- Write in present tense, consistent with the existing document style

Write the updated concept to `<vision-dir>/product-concept.md`.

### Step 7: Write Concept Review Report

Using the review report template, populate all sections:

1. **Header:** Product name, date, list of stress tests included
2. **Input Reports Summary:** Each report found, its date, recommendation count, and unresolved question count
3. **Consolidated Changeset:** All recommendations grouped by section with full context and user decisions
4. **Conflict Resolutions:** Each conflict with both sides, strategist assessment, and user's decision
5. **User Decisions Summary:** Three tables -- accepted changes, rejected changes (with reasons), modified changes (with modifications)
6. **Aggregated Unresolved Questions:** De-duplicated across reports with source attribution
7. **UX Specialist Review:** If UX specialist was involved, document trigger signals, sections reviewed, feedback, and impact on changeset. If not involved, note why.
8. **Change Summary:** Counts of total recommendations, de-duplicated count, conflicts, accepted/rejected/modified, breakdown by type (Add/Modify/Remove)

Write the report to `<reports-dir>/stress-tests/concept-review-report.md`.

### Step 8: Present Summary

Present a summary to the user:

"Concept review complete.

**Reports reviewed:** [N] stress test report(s) ([list names])
**Total recommendations:** [N] (after de-duplication: [N])
**Conflicts detected:** [N]
**Changes accepted:** [N] ([X] adds, [Y] modifies, [Z] removes)
**Changes rejected:** [N]
**Changes modified:** [N]
**Unresolved questions:** [N]

[If concept was updated:]
Updated product concept saved to `[vision-dir]/product-concept.md`.
Original preserved as `[vision-dir]/product-concept-pre-review.md`.

[If concept was NOT updated:]
Product concept was not modified (all changes rejected).

Review report saved to `[reports-dir]/stress-tests/concept-review-report.md`.

Next step: Run `/arn-spark-arch-vision` to define the architecture based on the [updated / current] product concept."

## Agent Invocation Guide

| Situation | Agent | Context |
|-----------|-------|---------|
| Consolidate recommendations from multiple reports | `arn-spark-product-strategist` | All extracted recommendation tables, full product concept, product pillars, consolidation task instructions |
| Review UX-relevant changes (conditional) | `arn-spark-ux-specialist` | Full product concept, UX-relevant subset of changeset, UX review task instructions |

## Error Handling

- **No stress test reports found:** Inform the user and list available stress test skills. Do not proceed. Exit the skill.

- **Product concept missing:** Inform the user: "No product concept found at `<vision-dir>/product-concept.md`. Run `/arn-spark-discover` to create a product concept before running stress tests and concept review." Do not proceed.

- **Product pillars missing or contain "Not explored" sentinel:** Inform the user: "The product concept does not include product pillars, which are needed for conflict resolution. Run `/arn-spark-discover` to define product pillars." Do not proceed.

- **Report exists but recommendation table is malformed or missing:** Note the gap. Extract what is parseable. If zero recommendations can be extracted from a report, note it as having "0 recommendations (malformed or missing table)" in the review report. Continue with other reports.

- **Product strategist returns poor consolidation:** Retry once with a simplified prompt that emphasizes the consolidation task steps from the conflict resolution protocol. If retry fails:
  Ask (using `AskUserQuestion`): **"The product strategist produced a poor consolidation. How would you like to proceed?"**
  1. Retry
  2. Skip consolidation and present raw recommendations without de-duplication
  3. Abort

- **UX specialist returns unhelpful review:** Note the gap in the review report. Proceed without UX specialist input. Do not block the review.

- **File rename fails:** Present the error and offer the user the choice to write anyway or abort (see Step 6b).

- **User rejects all changes:** Write the review report documenting the full changeset and all rejections. Do NOT modify the product concept. The review report is the audit trail.

- **Writing updated concept fails:** Print the updated concept content in the conversation so the user can copy it. Suggest checking file permissions or the output directory path.

- **Writing review report fails:** Print the report content in the conversation so the user can copy it. Suggest checking file permissions or the reports directory path.

## Constraints

- **ONLY skill that modifies product-concept.md.** No other skill in the pipeline writes to the product concept. This constraint ensures all concept changes are tracked through the review report.
- **User approval gate is MANDATORY.** The full changeset MUST be presented to the user before any writes. No silent concept updates. No auto-applied changes.
- **Preserve template structure.** The updated product concept MUST follow the same template structure as the original (from `product-concept-template.md`). Sections are never dropped, reordered, or renamed.
- **Pre-review rename preserves the original.** The original concept is always renamed to `product-concept-pre-review.md` before the updated concept is written. This ensures recovery if the review produced undesirable results.
- **Read-only except for the final write step.** The skill reads reports and the product concept during Steps 1-5 but writes nothing until Step 6 (concept) and Step 7 (review report).
- **Report overwrites on re-run.** If `concept-review-report.md` already exists, it is overwritten. Git provides history.
- **All reference loading uses `${CLAUDE_PLUGIN_ROOT}` paths.** No absolute paths or user-specific paths in reference loading instructions.
