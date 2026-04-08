# Review Report Template -- Static Prototype

Use this template for each version's expert review report during the static prototype validation cycle.

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
- **Reference alignment:** [How well the showcase matches the inspirational direction]
- **Design fidelity:** [How closely components match the design mockups — only if designs exist]
- **Brand compliance:** [Whether brand elements are correctly applied — only if brand assets exist]

[If no visual grounding assets were available: "No visual grounding assets provided. Review based on style brief text only."]

## Failing Criteria

### [Criterion Name] -- Combined [X]/[scale]
- **Product strategist feedback:** [specific observation and suggestion]
- **UX specialist feedback:** [specific observation and suggestion]
- **Priority:** [Critical / Important]

[Repeat for each failing criterion]

## Passing Criteria Highlights
[Brief notes on particularly strong aspects, if any]

## Summary
- **Passing:** [N] of [M] criteria meet threshold
- **Failing:** [N] criteria below threshold
- **Verdict:** PROCEED TO NEXT CYCLE / ALL CRITERIA PASS -- PROCEED TO JUDGE

## Recommended Focus for Next Cycle
[If failing: ordered list of what to fix, most critical first]
```

## Usage Notes

- The combined score uses the LOWER of the two expert scores for each criterion. This ensures both perspectives are satisfied.
- If only one expert is available (e.g., arn-spark-product-strategist only), use that single score as the combined score.
- The skill writes this report to `prototypes/static/vN/review-report.md` after each validation cycle.
