# Use Case Review Debate Protocol

This document defines the structured debate process for team-based use case review in `arn-spark-use-cases-teams`. Two expert reviewers — a business reviewer and a flow reviewer — independently analyze use cases, then cross-review each other's findings to surface insights, resolve disagreements, and produce a richer combined assessment than independent review alone.

The skill acts as the **facilitator**: it orchestrates the debate phases, passes outputs between agents, synthesizes the debate report, detects conflicts, manages convergence, and presents results to the user. The facilitator does not participate in the review itself.

## Team Roles

| Role | Agent | Perspective |
|------|-------|-------------|
| Writer | `arn-spark-use-case-writer` | Drafts and revises use case documents in Cockburn format |
| Business Reviewer | `arn-spark-product-strategist` | Business relevance, scope alignment, actor/goal accuracy, priority, business rules |
| Flow Reviewer | `arn-spark-ux-specialist` | Flow quality, user-friendliness, interaction completeness, accessibility |
| Facilitator | The skill itself | Orchestrates debate, synthesizes report, manages convergence |

## Debate Modes

**Important:** All debate modes use the same file-based review output. Each expert writes its review to a file — this works identically in Agent Teams mode and sequential mode. The mode selection is based ONLY on whether `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` is set to `1`. File-based output does NOT affect mode selection and does NOT favor sequential over Agent Teams. When Agent Teams is enabled, always use Agent Teams mode — it is faster because experts run in parallel.

### Agent Teams Mode (Preferred)

**When:** `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` environment variable is set to `1`.

Both experts are spawned as teammates. Phase 1 runs in parallel (no cross-communication) — each expert writes to its own file simultaneously with no contention. Phase 2 uses Teams communication to coordinate cross-review — each expert reads the other's completed file and writes its cross-review to a separate file. This mode is faster and allows more natural back-and-forth between experts.

### Sequential Mode (Fallback)

**When:** Agent Teams is NOT enabled.

The skill simulates the debate through 3 sequential expert invocations per round, manually passing file paths between agents so each can read the other's review. Produces the same logical result as Agent Teams mode but with serialized invocations.

### Single-Reviewer Mode

**When:** `arn-spark-ux-specialist` is unavailable.

No debate occurs. The business reviewer (product strategist) reviews independently. The debate report contains only strategist findings — no cross-review, no disagreements. The skill notes this limitation in all outputs.

## Debate Phases

### Phase 1: Independent Review

Both experts review all use cases independently from their lens. Neither sees the other's output during this phase.

**Business reviewer focus areas:**
- Is each use case goal business-relevant and aligned with the product concept?
- Is the primary actor correct for each use case?
- Are priority and level appropriate?
- Are there missing alternate flows from a business perspective (policy limits, resource constraints, edge cases)?
- Are business rules complete, correct, and specific to each use case?
- Are there missing actors or missing use cases for capabilities described in the product concept?
- Is scope appropriate — no use cases that exceed the product concept's boundaries?
- Do use case levels make sense (are subfunctions actually reused, are user goals actually completable in one session)?

**Flow reviewer focus areas:**
- Is the main success scenario natural from the actor's perspective?
- Are actor-system steps at the right granularity (not too detailed, not too vague)?
- Are common interaction patterns covered: cancel/abort, undo/back-navigation, timeout/inactivity, retry after failure, empty states?
- Are error recovery flows present for likely failures?
- Is accessibility considered (alternative interaction paths, non-visual feedback)?
- Do preconditions and postconditions make sense as observable, verifiable states?
- Are related use cases properly connected (bidirectional references)?
- Is step granularity consistent across use cases?

**Phase 1 file output:** Each expert writes their independent review to a file using the expert review template (`${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-use-cases/references/expert-review-template.md`). The skill tells each agent the exact file path to write to:
- Business reviewer → `[use-cases-dir]/reviews/round-N-business-review.md`
- Flow reviewer → `[use-cases-dir]/reviews/round-N-flow-review.md`

The agent returns a brief summary in conversation — the full review is in the file. Downstream steps read from the file, not from conversation context.

**Phase 1 output format (within the file):**

```markdown
## Independent Review

### Per-Use-Case Feedback

**UC-NNN: [Title]**
- **[Critical]:** [Specific observation] --> [Specific suggestion]
- **[Minor]:** [Specific observation] --> [Specific suggestion]

### Cross-Cutting Observations

- **Missing use case:** [Description of what behavior is not captured]
- **Missing actor:** [Who is not represented and what they do]
- **Scope concern:** [What appears out of scope or missing from scope]
- **Consistency issue:** [What is inconsistent across use cases]
```

### Phase 2: Cross-Review

Each expert reads the other's Phase 1 output and responds. This is where the debate produces its distinctive value — each expert's findings prompt the other to reconsider, agree, or surface new concerns.

**Instructions for each expert during cross-review:**

For each of the other expert's per-UC findings:
- **Agree** — the finding is valid. Optionally add supporting evidence from own perspective.
- **Disagree** — the finding is incorrect or inappropriate. Provide specific counterargument with reasoning.
- **New concern prompted** — the other expert's finding reveals something not previously noticed. Describe the new concern.

For cross-cutting findings: apply the same response structure.

**Focus question for each expert:** "Did the other expert's findings reveal something in the use cases that you missed in your independent review?"

**Phase 2 file output:** Each expert writes their cross-review to a separate file:
- Business reviewer → `[use-cases-dir]/reviews/round-N-business-cross-review.md`
- Flow reviewer → `[use-cases-dir]/reviews/round-N-flow-cross-review.md`

In sequential mode (where the flow reviewer writes Phase 1 + Phase 2 combined), the combined output goes to `round-N-flow-review.md` (a single file with both sections).

**Phase 2 output format (within the file):**

```markdown
## Cross-Review Response

### Response to [Business/Flow] Reviewer's findings

**UC-NNN: [Title]**
- **Agree:** [item from other expert] -- [supporting reason or additional evidence]
- **Disagree:** [item from other expert] -- [counterargument with specific reasoning]
- **New concern prompted:** [description of something their finding revealed]

### Response to Cross-Cutting Observations
- **Agree:** [item] -- [reason]
- **Disagree:** [item] -- [counterargument]
- **New concern prompted:** [description]
```

### Phase 3: Synthesis (Performed by Skill)

The skill reads all review files written by the experts — never from conversation context. The files to read are:
- `[use-cases-dir]/reviews/round-N-business-review.md` (Phase 1)
- `[use-cases-dir]/reviews/round-N-flow-review.md` (Phase 1, or Phase 1 + Phase 2 combined in sequential mode)
- `[use-cases-dir]/reviews/round-N-business-cross-review.md` (Phase 2, if written separately)
- `[use-cases-dir]/reviews/round-N-flow-cross-review.md` (Phase 2, Agent Teams mode only)

The skill categorizes findings:

**Consensus findings:** Items where both experts raised the same concern, or one raised it and the other explicitly agreed in cross-review. These are strong signals for revision.

**Addition findings:** Items raised by one expert that the other did not dispute in cross-review (neither agreed nor disagreed). Treat as valid — the other expert did not object.

**Disagreement findings:** Items where one expert raised a concern and the other explicitly disagreed in cross-review, and the disagreement was not resolved through their exchange. These require user resolution.

Produce the debate report per the review report template. Extract the "Recommended Changes for Writer" section.

### Phase 4: Resolution (Conditional)

**Trigger:** One or more disagreements exist after Phase 2.

For each unresolved disagreement, present to the user:

"Expert disagreement on **UC-NNN [Title]**:
- **Business Reviewer:** [position + reasoning]
- **Flow Reviewer:** [position + reasoning]
- **Trade-off:** [what each position optimizes for]

Which direction should the use case take?"

Record user decisions. Update the debate report with resolutions. Include the resolved changes in the "Recommended Changes for Writer" section.

## Sequential Mode Invocation Detail

When Agent Teams is not enabled, the skill simulates the debate with 3 sequential invocations:

**Invocation 1 — Business Reviewer Phase 1:**

Invoke `arn-spark-product-strategist` with:
- All use case content (read each file and provide the content)
- Product concept for context
- Actor catalog
- Business review focus instructions (Phase 1 focus areas listed above)
- Expert review template path: `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-use-cases/references/expert-review-template.md`
- File path to write to: `[use-cases-dir]/reviews/round-N-business-review.md`
- Instruction: "Write your complete review to the specified file path using the expert review template. Return a brief summary in conversation."

The strategist writes its Phase 1 review to the file.

**Invocation 2 — Flow Reviewer Phase 1 + Phase 2 Combined:**

Invoke `arn-spark-ux-specialist` with:
- All use case content
- Product concept for context
- Existing prototype screens (if available)
- Flow review focus instructions (Phase 1 focus areas listed above)
- The business reviewer's file path to read: `[use-cases-dir]/reviews/round-N-business-review.md`
- Expert review template path: `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-use-cases/references/expert-review-template.md`
- File path to write to: `[use-cases-dir]/reviews/round-N-flow-review.md`
- Instruction: "First, review these use cases independently from the flow/UX perspective using the Phase 1 format. Then, read the business reviewer's review at the specified file path and respond to each finding using the Phase 2 cross-review format: agree, disagree (with reasoning), or note new concerns their findings prompted. Write your complete review (Phase 1 + Phase 2 combined) to the specified file path using the expert review template. Return a brief summary in conversation."

The UX specialist reads the business review file and writes its combined review to its own file.

**Invocation 3 — Business Reviewer Phase 2:**

Invoke `arn-spark-product-strategist` with:
- The flow reviewer's file path to read: `[use-cases-dir]/reviews/round-N-flow-review.md`
- Expert review template path: `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-use-cases/references/expert-review-template.md`
- File path to write to: `[use-cases-dir]/reviews/round-N-business-cross-review.md`
- Instruction: "Read the flow reviewer's review at the specified file path. The flow reviewer has reviewed the use cases and also responded to your review. Review their findings and respond using the Phase 2 cross-review format: agree, disagree (with reasoning), or note new concerns their review prompted. Write your cross-review to the specified file path using the expert review template. Return a brief summary in conversation."

The strategist reads the flow review file and writes its cross-review to a separate file.

The skill synthesizes by reading all three review files (not from conversation context).

**Note on sequential asymmetry:** In sequential mode, the UX specialist sees the strategist's review before writing their own Phase 1 review. Instruct the UX specialist to "review independently first" to minimize anchoring bias. The synthesis step normalizes the output regardless of invocation order.

## Agent Teams Mode Invocation Detail

**Phase 1:** Spawn both experts simultaneously as teammates. Each receives:
- All use case content
- Product concept
- Their respective focus instructions
- Expert review template path: `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-use-cases/references/expert-review-template.md`
- File path to write to: business reviewer → `[use-cases-dir]/reviews/round-N-business-review.md`, flow reviewer → `[use-cases-dir]/reviews/round-N-flow-review.md`
- Instruction: "Produce your independent review. Write the complete review to the specified file path using the expert review template. Do not communicate with other teammates during this phase."

Both produce Phase 1 reviews independently and write them to their respective files.

**Phase 2:** Share file paths through Teams communication:
- Tell the UX specialist to read the strategist's file: `[use-cases-dir]/reviews/round-N-business-review.md`
- Tell the strategist to read the UX specialist's file: `[use-cases-dir]/reviews/round-N-flow-review.md`
- Each reads the other's file and writes their cross-review to a separate file:
  - Business reviewer → `[use-cases-dir]/reviews/round-N-business-cross-review.md`
  - Flow reviewer → `[use-cases-dir]/reviews/round-N-flow-cross-review.md`
- Each responds using the Phase 2 cross-review format

The skill synthesizes by reading all four review files (not from conversation context).

## Convergence Criteria

After the writer revises use cases based on the debate report, evaluate convergence from the report:

**Converged (skip remaining rounds) when ALL of:**
- No missing actors were flagged by either reviewer
- No missing use cases were flagged
- No use case goals were challenged as fundamentally wrong or out of scope
- All feedback was refinement-level: wording improvements, additional extensions, granularity adjustments, minor precondition/postcondition fixes
- No conflicting business rules between use cases remain unresolved
- All Phase 4 disagreements were resolved by user decision

**Another round needed when ANY of:**
- A reviewer flagged a missing actor that was not added in revision
- A reviewer flagged a missing use case that was not created
- A use case goal was challenged as wrong or out of scope and was not resolved
- Business rules conflict between use cases
- The writer reported feedback items that could not be addressed
- The revision introduced changes significant enough to warrant re-review (new use cases added, major flow restructuring)

## Invocation Counts per Round

| Mode | Expert Invocations | Writer Invocations | Total per Round |
|------|-------------------|-------------------|----------------|
| Agent Teams + UX specialist | 4 (2 Phase 1 + 2 Phase 2) | 1 | 5 |
| Sequential + UX specialist | 3 (strategist P1, UX P1+P2, strategist P2) | 1 | 4 |
| Single-reviewer (no UX) | 1 | 1 | 2 |

For `max_rounds=2` with sequential mode: up to 8 expert invocations + 2 writer invocations + 1 initial draft = 11 total. Early convergence reduces actual counts.

## Skill's Facilitation Responsibilities

The `arn-spark-use-cases-teams` skill (not the agents) is responsible for:

1. **Mode detection:** Check `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` environment variable and `arn-spark-ux-specialist` availability
2. **Directory setup:** Create `[use-cases-dir]/reviews/` if it does not exist before invoking experts
3. **File path assignment:** Tell each expert agent the exact file path to write to and the expert review template path
4. **Phase orchestration:** Run Phase 1, then Phase 2, telling each expert to read the other's review file (by file path, not by passing content through conversation)
5. **Synthesis:** Read all expert review files and categorize into consensus, additions, disagreements. Never rely on the expert's conversation summary — always read the file.
6. **Conflict detection:** Identify disagreements and present to user for resolution
7. **Report writing:** Produce the debate report per template and save to file
8. **Convergence evaluation:** Evaluate the debate report against convergence criteria after each revision
9. **Task management:** Create and manage the task list for draft-debate-revise rounds
10. **Budget management:** Never exceed the user's configured max_rounds
11. **User communication:** Present debate summaries, revision results, and convergence status between rounds
