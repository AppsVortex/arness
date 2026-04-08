# Review Report Template -- Clickable Prototype

Use this template for each version's expert review report during the clickable prototype validation cycle.

```markdown
# Review Report: Version [N]

## Reviewers
- **Product strategist:** arn-spark-product-strategist
- **UX specialist:** arn-spark-ux-specialist

## Scoring
- **Scale:** [1-N]
- **Minimum threshold:** [T]

## Criterion Scores

| # | Criterion | Product Strategist | UX Specialist | Combined | Status |
|---|-----------|-------------------|---------------|----------|--------|
| 1 | [name] | [score] | [score] | [lower] | PASS/FAIL |
| 2 | [name] | [score] | [score] | [lower] | PASS/FAIL |
| ... | ... | ... | ... | ... | ... |

## Visual Grounding Comparison

**Assets provided to reviewers:**
| Category | Count | Source |
|----------|-------|--------|
| References | [N] | [URL captures, user screenshots] |
| Designs | [N] | [Figma exports, Canva exports, manual mockups] |
| Brand | [N] | [logos, guidelines] |

**Comparison notes:**
- **Reference alignment:** [How well screen layouts and flow feel match the inspirational direction]
- **Design fidelity:** [How closely screen layouts match the design mockups in structure and component placement — only if designs exist]
- **Brand compliance:** [Whether brand elements appear correctly across all screens — only if brand assets exist]

[If no visual grounding assets were available: "No visual grounding assets provided. Review based on style brief text only."]

## Failing Criteria

### [Criterion Name] -- Combined [X]/[scale]
- **Product strategist feedback:** [specific observation and suggestion]
- **UX specialist feedback:** [specific observation and suggestion]
- **Journey evidence:** [which journey step exposed the issue, with screenshot reference]
- **Priority:** [Critical / Important]

[Repeat for each failing criterion]

## Journey Results Summary

| Journey | Steps | Completed | Issues |
|---------|-------|-----------|--------|
| [name] | [total] | [completed] | [brief summary] |
| ... | ... | ... | ... |

## Passing Criteria Highlights
[Brief notes on particularly strong aspects, if any]

## Summary
- **Passing:** [N] of [M] criteria meet threshold
- **Failing:** [N] criteria below threshold
- **Journeys:** [X] of [Y] completed successfully
- **Verdict:** PROCEED TO NEXT CYCLE / ALL CRITERIA PASS -- PROCEED TO JUDGE

## Recommended Focus for Next Cycle
[If failing: ordered list of what to fix, most critical first. Reference specific journey steps and screenshots.]
```

## Usage Notes

- The combined score uses the LOWER of the two expert scores for each criterion.
- If only one expert is available, use that single score as the combined score.
- Journey results from the `arn-spark-ui-interactor` agent should be cross-referenced with criterion scores. If a journey step exposed a criterion failure, note the journey step and screenshot in the failing criteria details.
- The skill writes this report to `prototypes/clickable/vN/review-report.md` after each validation cycle.
