# Use Case Review Protocol

This document defines the team review process for use case documents. The `arn-spark-use-cases` skill follows this protocol to coordinate expert reviews and writer revisions efficiently while keeping token costs manageable.

## Team Roles

| Role | Agent | Perspective |
|------|-------|-------------|
| Writer | `arn-spark-use-case-writer` | Drafts and revises use case documents in Cockburn format |
| Business Reviewer | `arn-spark-product-strategist` | Business relevance, scope alignment, actor/goal accuracy, priority |
| Flow Reviewer | `arn-spark-ux-specialist` | Flow quality, user-friendliness, interaction completeness, accessibility |

The skill acts as the **facilitator**: it does not participate in the review but orchestrates the agents, combines feedback, checks convergence, and presents results to the user.

## Review Process

### Round 1: Draft + Full Review

**Step 1: Writer drafts all use cases** (1 invocation)
- Reads product concept, templates, and any existing screen references
- Writes all UC files and the README index
- Reports gaps and assumptions made during drafting

**Step 2: Business reviewer reviews all use cases** (1 invocation)

Focus areas:
- Are all business-relevant actors identified?
- Does each use case goal align with the product concept's stated capabilities?
- Are priorities consistent with product scope boundaries (v1 vs. future)?
- Are there missing use cases for capabilities described in the product concept?
- Do extensions cover business-relevant exceptions (payment failures, policy violations, resource limits)?
- Are business rules complete, correct, and specific to each use case?
- Is scope appropriate -- no use cases that exceed the product concept's boundaries?
- Do the use case levels make sense (are subfunctions actually reused, are user goals actually what a user sits down to do)?

**File output:** The business reviewer writes its review to `[use-cases-dir]/reviews/round-N-business-review.md` using the expert review template (`${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-use-cases/references/expert-review-template.md`). The skill tells the agent the exact file path and template path. The agent returns a brief summary in conversation — the full review is in the file.

**Step 3: Flow reviewer reviews all use cases** (1 invocation)

Focus areas:
- Is the main success scenario natural from the actor's perspective?
- Are actor-system steps at the right granularity (not too detailed, not too vague)?
- Are common interaction patterns covered? Specifically:
  - Cancel/abort at reasonable points
  - Undo or back-navigation where applicable
  - Timeout or inactivity handling
  - Retry after failure
  - Empty states (no items found, no devices available)
- Are error recovery flows present for likely failures?
- Is accessibility considered (alternative interaction paths, non-visual feedback)?
- Do preconditions and postconditions make sense as observable, verifiable states?
- Are related use cases properly connected (bidirectional references)?
- Is step granularity consistent across use cases (one UC has 4 steps while a similar one has 12)?

**File output:** The flow reviewer writes its review to `[use-cases-dir]/reviews/round-N-flow-review.md` using the same expert review template. The skill tells the agent the exact file path and template path.

**Step 4: Writer revises all use cases** (1 invocation)
- The skill reads the review files written by the experts (not from conversation context)
- Combines feedback from both review files into a consolidated per-use-case list
- Sends combined feedback to the writer
- Writer applies changes to all use case files
- Updates README index if relationships or actors changed
- Reports: changes made per UC, any feedback that could not be fully addressed, any conflicting feedback between reviewers

### Round 2: Convergence Check (Conditional)

The skill evaluates the writer's revision report to decide whether a second round is needed.

**Proceed without Round 2 (convergence reached) when:**
- No missing actors were flagged by either reviewer
- No missing use cases were flagged
- No use case goals were challenged as fundamentally wrong or out of scope
- All feedback was refinement-level: wording improvements, additional extensions, granularity adjustments, minor precondition/postcondition fixes
- No conflicting business rules between use cases remain unresolved

**Trigger Round 2 when ANY of these exist after revision:**
- A reviewer flagged a missing actor that was not added
- A reviewer flagged a missing use case that was not created
- A use case goal was challenged as wrong or out of scope and was not resolved
- Business rules conflict between use cases (e.g., UC-001 says max 4 participants, UC-002 says max 8)
- The writer reported feedback items that could not be addressed

**Round 2 steps** (if triggered):

**Step 5: Business reviewer re-reviews** (1 invocation)
- Focuses only on previously flagged critical issues
- Verifies that major concerns from Round 1 were addressed
- May flag NEW issues discovered in the revisions
- Writes review to `[use-cases-dir]/reviews/round-N-business-review.md` (N=2 for Round 2)

**Step 6: Flow reviewer re-reviews** (1 invocation)
- Focuses only on previously flagged critical issues
- Verifies that flow concerns were addressed
- May flag new issues in revised flows
- Writes review to `[use-cases-dir]/reviews/round-N-flow-review.md` (N=2 for Round 2)

**Step 7: Writer applies final revisions** (1 invocation)
- The skill reads the Round 2 review files written by the experts
- Addresses Round 2 feedback
- Updates all affected files

### Maximum Invocations

| Scenario | Writer | Strategist | UX Specialist | Total |
|----------|--------|-----------|---------------|-------|
| Single review round (no structural issues) | 2 | 1 | 1 | 4 |
| Two review rounds (structural issues found) | 2 | 2 | 2 | 6-7* |

*The writer's final revision in Round 2 is the 7th invocation. If only one reviewer triggered Round 2, the other reviewer may be skipped in Round 2, reducing to 6.

The process never exceeds 7 agent invocations.

## Feedback Format

Expert reviewers should structure their feedback as follows:

### Per-Use-Case Feedback

```markdown
**UC-NNN: [Title]**
- **[Critical]:** [Specific observation] --> [Specific suggestion]
- **[Minor]:** [Specific observation] --> [Specific suggestion]
```

**Critical** feedback indicates issues that affect the use case's correctness, completeness, or alignment with the product concept. These MUST be addressed.

**Minor** feedback indicates improvements to clarity, granularity, or style. These SHOULD be addressed but are not blockers.

### Cross-Cutting Feedback

```markdown
**Missing use case:** [Description of what behavior is not captured by any existing use case]
**Missing actor:** [Who is not represented in the actor catalog and what they do]
**Scope concern:** [What appears to be out of scope or missing from scope relative to the product concept]
**Consistency issue:** [What is inconsistent across use cases -- step granularity, terminology, business rules, actor naming]
```

Cross-cutting feedback is addressed by the writer across all affected use cases, not in a single UC.

## Skill's Facilitation Responsibilities

The `arn-spark-use-cases` skill (not the agents) is responsible for:

1. **Telling each expert where to write:** Provide the exact file path and template path when invoking each expert. Create the `[use-cases-dir]/reviews/` directory if it does not exist.
2. **Reading review files:** After each expert completes, read the review file (not the conversation summary) to extract feedback.
3. **Combining feedback:** Merge per-UC feedback from both review files into a single combined list per UC before sending to the writer.
4. **Flagging conflicts:** If both reviewers give contradictory feedback on the same UC, note the conflict and present it to the user for resolution before sending to the writer.
5. **Convergence decision:** Evaluate the writer's revision report against the convergence criteria above.
6. **User communication:** Present review summaries and revision results to the user between rounds.
7. **Budget management:** Never exceed 2 review rounds (7 invocations).
