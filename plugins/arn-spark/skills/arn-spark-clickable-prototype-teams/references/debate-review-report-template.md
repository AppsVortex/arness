# Debate Review Report Template -- Clickable Prototype Teams

Use this template for each cycle's debate review report produced by the `arn-spark-clickable-prototype-teams` skill. The skill populates this template after synthesizing the expert debate outputs (Phase 1 scores + Phase 2 cross-review responses) into categorized findings with final combined scores.

## Instructions for the Skill

When populating this template:

- Every section MUST appear, even if empty (write "None" for empty sections)
- **Consensus:** both experts agree on the score, or one adjusted to match in cross-review
- **Additions:** one expert scored lower with feedback, the other did not dispute
- **Disagreements:** experts explicitly disagreed in cross-review and disagreement persists
- **No-debate:** Phase 2 was skipped (divergence mode, no divergence detected) -- combined = min(strategist, ux)
- In single-reviewer mode (no UX specialist): all scores are from the strategist alone. Omit Disagreements and note "Single-Reviewer Mode" throughout.
- Save each report to `prototypes/clickable/reviews/round-N-cycle-M-debate-report.md`
- Also copy to `prototypes/clickable/v[M]/review-report.md` for version-local access

---

## Template

```markdown
# Debate Review Report: Cycle [M], Round [N]

## Debate Participants

| Role | Agent | Status |
|------|-------|--------|
| Interaction Strategist | arn-spark-product-strategist | Participated |
| Interaction Flow Reviewer | arn-spark-ux-specialist | Participated / Unavailable |

## Configuration

- **Debate mode:** [Divergence / Standard]
- **Execution mode:** [Agent Teams / Sequential / Single-Reviewer]
- **Phase 2 triggered:** [Yes -- [N] criteria diverged by >= 2 / No -- all within 1 point / Yes -- standard mode (always)]
- **Divergent criteria:** [list names, or "None"]
- **Scoring scale:** [1-N]
- **Minimum threshold:** [T]

## Criterion Scores

| # | Criterion | Strategist | UX Specialist | Combined | Status | Category |
|---|-----------|-----------|---------------|----------|--------|----------|
| 1 | [name] | [score] | [score] | [combined] | PASS/FAIL | [Consensus/Addition/Disagreement/No-debate] |
| 2 | [name] | [score] | [score] | [combined] | PASS/FAIL | [category] |
| ... | ... | ... | ... | ... | ... | ... |

## Visual Grounding Comparison

**Assets provided to reviewers:**
| Category | Count | Source |
|----------|-------|--------|
| References | [N] | [URL captures, user screenshots] |
| Designs | [N] | [Figma exports, Canva exports, manual mockups] |
| Brand | [N] | [logos, guidelines] |

**Comparison notes:**
- **Reference alignment:** [How well screen layouts and flow feel match the inspirational direction]
- **Design fidelity:** [How closely screen layouts match the design mockups -- only if designs exist]
- **Brand compliance:** [Whether brand elements appear correctly across screens -- only if brand assets exist]

[If no visual grounding assets: "No visual grounding assets provided. Review based on style brief text only."]

## Journey Results Summary

| # | Journey | Strategist Assessment | UX Assessment | Agreed | Issues |
|---|---------|----------------------|---------------|--------|--------|
| 1 | [name] | [Complete/Partial/Failed] | [Complete/Partial/Failed] | [Yes/No] | [brief summary] |
| 2 | [name] | [Complete/Partial/Failed] | [Complete/Partial/Failed] | [Yes/No] | [brief summary] |
| ... | ... | ... | ... | ... | ... |

[If single-reviewer: only one assessment column, "Agreed" column reads "N/A"]

## Debate Findings

### Consensus Criteria

[Criteria where both experts agreed or one adjusted to match]

**Criterion [N]: [Name]** -- Combined [X]/[scale]
- **Strategist:** [brief reasoning with journey/screenshot reference]
- **UX Specialist:** [brief reasoning with journey/screenshot reference]
- **Outcome:** Both agree. [Any shared feedback for builder.]

[Repeat for each consensus criterion, or "None"]

### Addition Criteria

[Criteria where one expert raised feedback the other did not dispute]

**Criterion [N]: [Name]** -- Combined [X]/[scale] (raised by [Strategist / UX Specialist])
- **Lower scorer:** [agent] scored [X] -- [reasoning with journey evidence]
- **Higher scorer:** [agent] scored [Y] -- did not dispute
- **Outcome:** Lower score used. Builder feedback: [specific suggestion with journey step reference]

[Repeat for each addition criterion, or "None"]

### Disagreement Criteria

[Criteria where experts explicitly disagreed after cross-review]

**Criterion [N]: [Name]**
- **Strategist:** Score [X] -- [position + reasoning + journey/screenshot evidence]
- **UX Specialist:** Score [Y] -- [position + reasoning + journey/screenshot evidence]
- **Trade-off:** [what each score optimizes for]
- **Resolution:** [User decided: score [Z] because [reasoning] / Pending user input]

[Repeat for each disagreement criterion, or "None"]

### No-Debate Criteria

[Criteria where Phase 2 was skipped -- divergence mode only]

[If Phase 2 was skipped:] All criteria scored within 1 point. Combined = min(strategist, ux). No cross-review was performed.

[If Phase 2 ran:] N/A -- all criteria were included in the debate.

## Failing Criteria

### [Criterion Name] -- Combined [X]/[scale]
- **Strategist feedback:** [specific observation and suggestion with journey/screen reference]
- **UX specialist feedback:** [specific observation and suggestion with journey/screen reference]
- **Journey evidence:** [which journey step exposed the issue, with screenshot reference]
- **Debate insight:** [anything surfaced during cross-review that adds context beyond individual feedback]
- **Priority:** [Critical / Important]

[Repeat for each failing criterion]

## Passing Criteria Highlights
[Brief notes on particularly strong aspects]

## Summary

- **Passing:** [N] of [M] criteria meet threshold
- **Failing:** [N] criteria below threshold
- **Journeys:** [X] of [Y] completed successfully (agreed by both experts)
- **Phase 2 triggered:** [Yes / No]
- **Consensus criteria:** [N]
- **Addition criteria:** [N]
- **Disagreement criteria:** [N] ([N] resolved by user)
- **No-debate criteria:** [N]
- **Verdict:** PROCEED TO NEXT CYCLE / ALL CRITERIA PASS -- PROCEED TO JUDGE

## Recommended Focus for Next Cycle

[If failing: ordered list of what to fix, most critical first, incorporating debate insights and journey evidence. Each item includes the debate context so the builder understands WHY, not just what to fix.]

1. **[Criterion Name]:** [specific fix] -- Journey [N], Step [M]: [what went wrong]. [debate context: both experts agreed / strategist flagged X while UX specialist noted Y / user resolved in favor of Z]
2. ...
```

## Usage Notes

- The skill writes this report to `prototypes/clickable/reviews/round-N-cycle-M-debate-report.md` after each debate cycle
- Also copy to `prototypes/clickable/v[M]/review-report.md` for version-local access
- The "Recommended Focus for Next Cycle" section is the primary output fed to the builder for the next cycle -- it must be actionable and specific, enriched by debate context and journey evidence
- In single-reviewer mode, the Category column is always "Single-reviewer", the Disagreements section reads "N/A -- single-reviewer mode", and the UX Specialist column shows "N/A"
- When Phase 2 is skipped in divergence mode, all criteria are categorized as "No-debate" and the Debate Findings section reflects this
- The Journey Results Summary table captures expert agreement on journey outcomes -- if experts disagree on whether a journey completed, this is noted and may trigger additional debate or user resolution
- When writing the final report (`prototypes/clickable/final-report.md`), aggregate all per-cycle debate reports with a summary of the debate arc: how scores evolved, what diverged, what converged, what the user decided
