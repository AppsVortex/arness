# Review Report Template

Template for the concept review report produced by the `arn-spark-concept-review` skill. This report is the audit trail documenting which stress test findings were considered, how conflicts were resolved, and what the user decided for each proposed change.

## Instructions for arn-spark-concept-review

When populating this template:

- Every section below MUST appear in the output, even if no changes were accepted
- Replace all bracketed placeholders with concrete content from the review process
- The Consolidated Changeset must include ALL recommendations from all reports, with source attribution
- Conflict Resolutions must include BOTH sides and the strategist's assessment for every conflict
- User Decisions must document every recommendation's fate: accepted, rejected (with reason), or modified (with user's modification)
- If the user rejected all changes, the report still documents the full changeset and rejection -- this is the audit trail
- Aggregated Unresolved Questions must be de-duplicated across reports with source attribution
- The Change Summary must accurately count accepted changes by type

---

## Template

```markdown
# Concept Review Report

**Product:** [product name]
**Date:** [ISO 8601 date]
**Stress tests included:** [list of report names included in this review, e.g., "Interview Report, Competitive Report, Pre-Mortem Report"]

---

## Input Reports Summary

| Report | File | Date | Recommendations | Unresolved Questions |
|--------|------|------|-----------------|---------------------|
| [Report name] | [filename] | [date from report] | [count] | [count] |
| [Report name] | [filename] | [date from report] | [count] | [count] |
| **Total** | | | **[total]** | **[total]** |

---

## Consolidated Changeset

All recommendations from all stress test reports, consolidated and de-duplicated. Grouped by product concept section.

### [Product Concept Section 1]

**Change 1** (from [Source Report(s)])
- **Type:** [Add/Modify/Remove]
- **Current state:** [what the concept currently says or assumes]
- **Proposed change:** [specific recommended change]
- **Rationale:** [why this change is recommended, with source report attribution]
- **User decision:** [Accepted / Rejected / Modified]
- **User notes:** [reason for rejection, or description of modification, or empty if accepted as-is]

**Change 2** (from [Source Report(s)])
- **Type:** [Add/Modify/Remove]
- **Current state:** [current state]
- **Proposed change:** [recommended change]
- **Rationale:** [rationale]
- **User decision:** [Accepted / Rejected / Modified]
- **User notes:** [notes]

[Repeat for all changes in this section]

### [Product Concept Section 2]

[Same structure as above]

[Repeat for all affected sections]

---

## Conflict Resolutions

[If no conflicts were detected, write: "No conflicts detected across stress test reports."]

### Conflict 1: [Product Concept Section] -- [Brief Description]

**Recommendation A** (from [Source Report A])
- **Type:** [Add/Modify/Remove]
- **Proposed change:** [change A]
- **Rationale:** [rationale A]

**Recommendation B** (from [Source Report B])
- **Type:** [Add/Modify/Remove]
- **Proposed change:** [change B]
- **Rationale:** [rationale B]

**Strategist's Assessment:**
- **Pillar alignment:** [which pillars each recommendation serves or conflicts with]
- **Recommendation:** [which side the strategist recommended and why]
- **Trade-off:** [what is gained and lost with each option]

**User's Decision:** [Which recommendation was chosen, or a custom resolution, with the user's reasoning]

[Repeat for all conflicts]

---

## User Decisions Summary

### Accepted Changes

| # | Section | Type | Change Summary | Source |
|---|---------|------|----------------|--------|
| 1 | [section] | [Add/Modify/Remove] | [brief description of accepted change] | [source report(s)] |
| 2 | ... | ... | ... | ... |

### Rejected Changes

| # | Section | Type | Change Summary | Source | Reason for Rejection |
|---|---------|------|----------------|--------|---------------------|
| 1 | [section] | [Add/Modify/Remove] | [brief description of rejected change] | [source report(s)] | [user's reason] |
| 2 | ... | ... | ... | ... | ... |

### Modified Changes

| # | Section | Type | Original Recommendation | User's Modification | Source |
|---|---------|------|------------------------|---------------------|--------|
| 1 | [section] | [Add/Modify/Remove] | [original recommended change] | [what the user changed it to] | [source report(s)] |
| 2 | ... | ... | ... | ... | ... |

[If a table is empty (e.g., no rejections), write "None." below the table header]

---

## Aggregated Unresolved Questions

Questions from stress test reports that cannot be answered without real user data, domain expertise, or further research. De-duplicated across reports.

| # | Section | Question | Source Report(s) | Options | Assessment |
|---|---------|----------|------------------|---------|------------|
| 1 | [product concept section] | [unresolved question] | [report(s) that raised this] | [possible approaches] | [preliminary assessment] |
| 2 | ... | ... | ... | ... | ... |

---

## UX Specialist Review

[If UX specialist was not involved, write: "UX specialist was not invoked -- no UX participation signals detected in the product concept."]

[If UX specialist was involved:]

**Trigger:** [Which signals in the product concept indicated UX specialist participation]

**Sections reviewed:** [List of product concept sections the UX specialist reviewed]

**UX Specialist Feedback:**
- [Section]: [feedback on proposed changes -- alignment with visual direction, interaction pattern implications, additional UX considerations]
- [Section]: [feedback]

**Impact on changeset:** [How the UX specialist's feedback modified or supplemented the changeset]

---

## Change Summary

| Metric | Count |
|--------|-------|
| Total recommendations across all reports | [N] |
| After de-duplication | [N] |
| Conflicts detected | [N] |
| Changes accepted | [N] |
| Changes rejected | [N] |
| Changes modified | [N] |
| Adds accepted | [N] |
| Modifies accepted | [N] |
| Removes accepted | [N] |
| Unresolved questions | [N] |
| Concept updated | [Yes / No -- "No" if user rejected all changes] |
```

---

## Section Guidance

| Section | Source | Depth |
|---------|--------|-------|
| Input Reports Summary | Extracted from report headers | One row per report with recommendation and question counts |
| Consolidated Changeset | All recommendations from all reports, consolidated per conflict resolution protocol | Every recommendation with full context, source attribution, and user decision |
| Conflict Resolutions | Detected during consolidation, assessed by product strategist | Both sides, pillar analysis, strategist recommendation, user's final decision |
| User Decisions Summary | Aggregated from per-change user decisions | Three tables: accepted, rejected (with reason), modified (with modification) |
| Aggregated Unresolved Questions | Collected from all reports, de-duplicated | One row per unique question with all source reports listed |
| UX Specialist Review | Conditional -- only if UX specialist was involved | Trigger signals, sections reviewed, feedback, changeset impact |
| Change Summary | Computed from user decisions | Counts by category and type |
