# Review Report Template -- Use Case Team Review

This template defines the structure for per-round debate review reports produced by the `arn-spark-use-cases-teams` skill. The skill populates this template after synthesizing the expert debate outputs (Phase 1 independent reviews + Phase 2 cross-review responses) into categorized findings.

## Instructions for the Skill

When populating this template:

- Every section MUST appear, even if empty (write "None" for empty sections)
- Consensus findings are items both experts raised or one raised and the other agreed in cross-review
- Addition findings are items one expert raised and the other did not dispute (no agreement or disagreement in cross-review)
- Disagreement findings are items where experts explicitly disagreed in cross-review and the disagreement was not resolved between them
- The "Recommended Changes for Writer" section is the primary output — this is extracted and sent to `arn-spark-use-case-writer` for revision
- In single-reviewer mode (no UX specialist), there are no cross-review phases. All findings come from the strategist. Omit the Disagreements subsections and note "Single-Reviewer Mode" throughout.
- Save each report to `[use-cases-dir]/reviews/round-N-review-report.md`

---

## Template

```markdown
# Use Case Review Report: Round [N]

## Debate Participants

| Role | Agent | Status |
|------|-------|--------|
| Business Reviewer | arn-spark-product-strategist | Participated |
| Flow Reviewer | arn-spark-ux-specialist | Participated / Unavailable |

## Debate Mode

[Agent Teams / Sequential / Single-Reviewer]

## Per-Use-Case Findings

### UC-NNN: [Title]

#### Consensus (both experts agree)

- **[Critical]:** [observation] --> [suggestion]
- **[Minor]:** [observation] --> [suggestion]

#### Additions (raised by one, undisputed by the other)

- **[Critical] (raised by [Business/Flow Reviewer]):** [observation] --> [suggestion]
- **[Minor] (raised by [Business/Flow Reviewer]):** [observation] --> [suggestion]

#### Disagreements

- **Topic:** [what the experts disagree about]
  - **Business Reviewer:** [position + reasoning]
  - **Flow Reviewer:** [position + reasoning]
  - **Resolution:** [User decided: [decision + reasoning] / Consensus reached in Phase 2: [outcome] / Deferred to next round]

[Repeat for each use case that has findings. Use cases with no findings from either expert may be omitted.]

## Cross-Cutting Findings

### Consensus

- [Cross-cutting items both experts flagged or one flagged and the other agreed]

### Additions

- [Cross-cutting items raised by one expert, undisputed by the other]
- (raised by [Business/Flow Reviewer]): [description]

### Disagreements

- **Topic:** [cross-cutting disagreement]
  - **Business Reviewer:** [position]
  - **Flow Reviewer:** [position]
  - **Resolution:** [outcome]

## Missing Elements

- **Missing actors:** [list of actors flagged as missing, or "None"]
- **Missing use cases:** [list of behaviors not captured by any UC, or "None"]
- **Scope concerns:** [anything flagged as out of scope or inappropriately scoped, or "None"]

## Convergence Status

- **Structural issues found:** [Yes / No]
- **Missing actors flagged:** [list or None]
- **Missing use cases flagged:** [list or None]
- **Unresolved conflicts after user resolution:** [count]
- **Round recommendation:** [Converged -- proceed to user review / Another round needed -- [reason]]

## Recommended Changes for Writer

[Ordered list of changes, most critical first. This section is extracted and sent to arn-spark-use-case-writer as revision input. Each item should be actionable and specific.]

1. **UC-NNN [Title]:** [specific change description] **(Critical)**
2. **UC-NNN [Title]:** [specific change description] **(Critical)**
3. **UC-NNN [Title]:** [specific change description] **(Minor)**
4. **Cross-cutting:** [change that applies across multiple UCs] **(Critical/Minor)**
5. **New UC-NNN [Title]:** [create new use case for: description] **(Critical)**
6. **Actor catalog:** [add/modify actor: description] **(Critical/Minor)**
```

---

## Usage Notes

- The skill writes this report to `[use-cases-dir]/reviews/round-N-review-report.md` after each debate round
- Create the `[use-cases-dir]/reviews/` directory if it does not exist
- The "Recommended Changes for Writer" section is the primary interface between the debate and the writer agent. It must contain every actionable finding — consensus, additions, and resolved disagreements — in a form the writer can directly apply.
- Disagreements marked "Deferred to next round" do NOT appear in the Recommended Changes — they are re-evaluated in the next round's debate
- Disagreements resolved by user decision include the user's reasoning so the writer understands the intent
- In single-reviewer mode, all findings are from the strategist alone. The Disagreements subsections should read "N/A -- single-reviewer mode." The Additions subsection captures all strategist findings.
- When writing the final report (`[use-cases-dir]/reviews/final-report.md`), aggregate all per-round reports with a summary of the overall review arc: how findings evolved across rounds, what converged, and what the user decided.
