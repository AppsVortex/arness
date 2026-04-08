# Expert Interaction Review Template

This template defines the file format that expert agents (`arn-spark-product-strategist`, `arn-spark-ux-specialist`) use when writing their interaction review reports to disk during `arn-spark-clickable-prototype-teams` debate cycles. Writing reviews to files ensures they survive context compression and provides a full audit trail.

## File Naming Convention

All review files go in `prototypes/clickable/reviews/`. Create the directory if it does not exist.

```
prototypes/clickable/reviews/
├── round-N-strategist-review.md       ← Product strategist Phase 1
├── round-N-ux-review.md               ← UX specialist Phase 1 (+ Phase 2 in sequential mode)
├── round-N-strategist-cross-review.md ← Product strategist Phase 2 response
├── round-N-ux-cross-review.md         ← UX specialist Phase 2 response (Agent Teams only)
└── round-N-cycle-M-debate-report.md   ← Synthesized debate report (written by skill)
```

Where `N` is the overall round number and `M` is the cycle number within the current validation run.

---

## Phase 1 Template (Independent Scoring)

When an expert writes their Phase 1 review, the file must follow this structure:

```markdown
# Interaction Review: Round [N] -- [Product Strategist / UX Specialist]

**Agent:** [arn-spark-product-strategist / arn-spark-ux-specialist]
**Phase:** Phase 1: Independent Scoring
**Execution mode:** [Agent Teams / Sequential / Single-Reviewer]
**Criteria scored:** [count]
**Journey screenshots reviewed:** [count]
**Journeys assessed:** [count]
**Version:** v[X]

---

## Per-Criterion Scores

| # | Criterion | Score | Evidence |
|---|-----------|-------|----------|
| 1 | [name] | [X]/[scale] | [1-2 sentence observation grounded in specific journey screenshot evidence] |
| 2 | [name] | [X]/[scale] | [evidence] |
| ... | ... | ... | ... |

## Per-Journey Assessment

| # | Journey | Steps | Completed | Issues | Key Screenshots |
|---|---------|-------|-----------|--------|----------------|
| 1 | [name] | [total] | [count] | [brief summary or "None"] | [screenshot filenames] |
| 2 | [name] | [total] | [count] | [brief summary or "None"] | [screenshot filenames] |
| ... | ... | ... | ... | ... | ... |

## Failing Criteria Detail

### [Criterion Name] -- [X]/[scale]

- **Observation:** [What specifically is wrong -- reference journey step, screenshot, screen, or interaction]
- **Expected:** [What the criteria description requires]
- **Journey evidence:** [Which journey step exposed the issue, with screenshot reference]
- **Suggestion:** [Specific actionable improvement for the builder]
- **Priority:** [Critical / Important]

[Repeat for each criterion below threshold]

## Passing Criteria Highlights

[Brief notes on particularly strong aspects, optional]

## Cross-Cutting Observations

- **Navigation coherence:** [Overall observation about screen reachability and navigation flow]
- **Interaction quality:** [Overall observation about interactive element responsiveness and feedback]
- **Journey experience:** [Overall observation about journey flow, clarity, and completability]
- **Visual consistency:** [Overall observation about style consistency across screens]
- **Missing elements:** [Anything expected but not present in the prototype]
```

---

## Phase 2 Template (Cross-Review)

When an expert writes their Phase 2 cross-review, the file must follow this structure. In sequential mode where the UX specialist writes Phase 1 + Phase 2 combined, append this section after the Phase 1 content in the same file.

```markdown
## Cross-Review Response

### Response to [Product Strategist / UX Specialist]'s Scores

| # | Criterion | Their Score | My Score | Response | Adjusted Score |
|---|-----------|-------------|----------|----------|----------------|
| 1 | [name] | [X] | [Y] | [Agree/Disagree/New concern] | [new score or unchanged] |
| 2 | [name] | [X] | [Y] | [Agree/Disagree/New concern] | [new score or unchanged] |
| ... | ... | ... | ... | ... | ... |

### Journey Assessment Comparison

| # | Journey | Their Assessment | My Assessment | Response |
|---|---------|-----------------|---------------|----------|
| 1 | [name] | [Completed/Partial/Failed] | [Completed/Partial/Failed] | [Agree/Disagree with reason] |
| ... | ... | ... | ... | ... |

### Detailed Responses (for divergent criteria)

**Criterion [N]: [Name]**
- **Their score:** [X] -- "[their evidence summary]"
- **My score:** [Y]
- **Response:** [Agree / Disagree / New concern]
- **Reasoning:** [Specific counter-evidence or supporting evidence, referencing journey steps and screenshots]
- **Adjusted score:** [new score, or same if maintaining position]

[Repeat for each criterion with score difference >= 2, or all criteria in standard mode]

### New Concerns Prompted by Other Expert's Review

- [Description of something their review revealed that was not noticed in Phase 1, with journey/screenshot references]
```

---

## Instructions for Expert Agents

When instructed to write an interaction review:

1. Read all journey screenshots provided (visually, via multimodal capabilities)
2. Read the interaction report from `arn-spark-ui-interactor` for journey completion data
3. Read the criteria list and scoring scale
4. Read the style brief and product concept for context
5. Read visual grounding assets if provided (with their category context: references=inspirational direction, designs=specification targets, brand=constraints)
6. Score EVERY criterion -- do not skip or combine criteria
7. Assess EVERY journey -- note completion status, issues, and key screenshots
8. For each score, provide specific evidence grounded in what you observe in the journey screenshots and interaction report
9. Read this template to understand the expected file format
10. Write your review to the exact file path specified by the caller
11. Return a brief summary in conversation (criteria scored, count below threshold, journeys assessed, top concerns) -- the full detail is in the file

The file contains the COMPLETE review with all scores, journey assessments, and evidence. The conversation summary is just an acknowledgment -- downstream steps read from the file, not from conversation context.

## Instructions for the Skill (Facilitator)

When orchestrating expert interaction reviews:

1. Create the `prototypes/clickable/reviews/` directory if it does not exist before invoking any expert
2. Tell each expert agent the exact file path to write to AND the path to this template
3. Tell each expert the criteria list, scoring scale, threshold, and all reference documents (style brief, product concept, visual grounding assets with categories)
4. Provide all journey screenshots from the interaction testing step AND the interaction report
5. When invoking for cross-review (Phase 2), tell the expert to READ the other expert's file by providing the file path -- do not pass the file content through conversation
6. After each expert completes, read the review file (not the conversation summary) to extract scores for divergence calculation and synthesis
7. Extract per-criterion scores from the "Per-Criterion Scores" table in each review file
8. Extract per-journey assessments from the "Per-Journey Assessment" table to compare journey-level agreement
9. When synthesizing the debate report, read ALL review files from the current round -- never rely on conversation context
