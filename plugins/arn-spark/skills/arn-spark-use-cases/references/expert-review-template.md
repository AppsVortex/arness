# Expert Review Template

This template defines the file format that expert agents (arn-spark-product-strategist, arn-spark-ux-specialist) use when writing their use case review reports to disk. Writing reviews to files ensures they survive context compression and provides a full audit trail.

## File Naming Convention

All review files go in `[use-cases-dir]/reviews/`. Create the directory if it does not exist.

### arn-spark-use-cases (independent reviews, no debate)

```
reviews/
├── round-N-business-review.md       ← Product strategist review
└── round-N-flow-review.md           ← UX specialist review (if available)
```

### arn-spark-use-cases-teams (debate reviews)

```
reviews/
├── round-N-business-review.md       ← Product strategist Phase 1
├── round-N-flow-review.md           ← UX specialist Phase 1 (+Phase 2 in sequential mode)
├── round-N-business-cross-review.md ← Product strategist Phase 2 response
├── round-N-flow-cross-review.md     ← UX specialist Phase 2 response (Agent Teams mode only)
├── round-N-review-report.md         ← Synthesized debate report (written by skill)
└── final-report.md                  ← Aggregated final report (written by skill)
```

## Template

When an expert writes their review, the file must follow this structure:

```markdown
# Expert Review: Round [N] — [Business Reviewer / Flow Reviewer]

**Agent:** [arn-spark-product-strategist / arn-spark-ux-specialist]
**Phase:** [Phase 1: Independent Review / Phase 2: Cross-Review / Phase 1 + Phase 2 Combined]
**Mode:** [Sequential / Agent Teams / Single-Reviewer / Independent]
**Use cases reviewed:** [count]

---

## Per-Use-Case Feedback

**UC-NNN: [Title]**
- **[Critical]:** [Specific observation] --> [Specific suggestion]
- **[Minor]:** [Specific observation] --> [Specific suggestion]

[Repeat for each use case with findings. Use cases with no findings may be omitted.]

## Cross-Cutting Observations

- **Missing use case:** [Description of what behavior is not captured]
- **Missing actor:** [Who is not represented and what they do]
- **Scope concern:** [What appears out of scope or missing from scope]
- **Consistency issue:** [What is inconsistent across use cases]

[For Phase 2 cross-review, add the following section after the above:]

## Cross-Review Response

### Response to [Business/Flow] Reviewer's Findings

**UC-NNN: [Title]**
- **Agree:** [item from other expert] -- [supporting reason or additional evidence]
- **Disagree:** [item from other expert] -- [counterargument with specific reasoning]
- **New concern prompted:** [description of something their finding revealed]

### Response to Cross-Cutting Observations
- **Agree:** [item] -- [reason]
- **Disagree:** [item] -- [counterargument]
- **New concern prompted:** [description]
```

## Instructions for Expert Agents

When instructed to write a review:

1. Read all use case files provided
2. Perform the review according to your focus area
3. Read this template to understand the expected format
4. Write your review to the file path specified by the caller
5. Return a brief summary in conversation (what you reviewed, how many findings, key concerns) — the full detail is in the file

The file contains the COMPLETE review. The conversation summary is just an acknowledgment — downstream steps read from the file, not from the conversation.

## Instructions for the Skill (Facilitator)

When orchestrating expert reviews:

1. Tell each expert agent the exact file path to write to and the path to this template
2. When invoking the next expert (cross-review), tell it to READ the previous expert's file — pass the file path, not the file content
3. When synthesizing the debate report, read ALL review files from the current round
4. Never rely on the expert's conversation summary for synthesis — always read the file
