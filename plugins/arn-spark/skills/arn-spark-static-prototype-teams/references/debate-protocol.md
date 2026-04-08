# Visual Review Debate Protocol

This document defines the structured debate process for team-based visual review in `arn-spark-static-prototype-teams`. Two expert reviewers -- a product strategist and a UX specialist -- independently score visual criteria against showcase screenshots, then cross-review each other's scores and findings to surface insights, resolve disagreements, and produce richer feedback than mechanical lower-of-two scoring.

The skill acts as the **facilitator**: it orchestrates the debate phases, passes file paths between agents, synthesizes the debate report, detects divergence, manages resolution, and presents results to the user. The facilitator does not participate in the scoring itself.

## Team Roles

| Role | Agent | Perspective |
|------|-------|-------------|
| Builder | `arn-spark-prototype-builder` | Creates showcase (not part of debate) |
| Visual Strategist | `arn-spark-product-strategist` | Brand alignment, design direction, style brief fidelity, overall impression, product context |
| Visual Flow Reviewer | `arn-spark-ux-specialist` | Component usability, state coverage, interaction patterns, accessibility, spacing/hierarchy |
| Facilitator | The skill itself | Orchestrates debate, synthesizes report, manages divergence |
| Judge | `arn-spark-ux-judge` | Independent verdict (not part of debate) |

## Debate Modes

### Divergence Mode (Default)

Cross-review (Phase 2) triggers only when any criterion score differs by >= 2 points between experts. When experts mostly agree (all scores within 1 point), Phase 2 is skipped and combined scores use the lower of each pair (identical to base skill behavior). This mode saves tokens on cycles where the experts align.

### Standard Mode

Full cross-review every cycle, regardless of score agreement. Produces richer debate findings but costs more tokens. Use when the project has complex visual decisions where expert dialogue adds value even on criteria they numerically agree about.

## Execution Modes

**Important:** All execution modes use the same file-based review output. Each expert writes its review to a file -- this works identically in Agent Teams mode and sequential mode. The execution mode selection is based ONLY on whether `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` is set to `1`. File-based output does NOT affect mode selection and does NOT favor sequential over Agent Teams. When Agent Teams is enabled, always use Agent Teams mode -- it is faster because experts run in parallel.

### Agent Teams Mode (Preferred)

**When:** `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` environment variable is set to `1`.

Both experts are spawned as teammates. Phase 1 runs in parallel -- each expert writes to its own file simultaneously with no contention. Phase 2 uses Teams communication to coordinate cross-review -- each expert reads the other's completed file and writes its cross-review to a separate file.

### Sequential Mode (Fallback)

**When:** Agent Teams is NOT enabled.

The skill simulates the debate through sequential expert invocations, manually passing file paths between agents so each can read the other's review. Produces the same logical result as Agent Teams mode but with serialized invocations.

### Single-Reviewer Mode

**When:** `arn-spark-ux-specialist` is unavailable.

No debate occurs. The product strategist reviews independently. Strategist scores become the combined scores directly. The debate report notes "Single-Reviewer Mode" throughout. The skill suggests using `/arn-spark-static-prototype` instead, which handles single-reviewer identically.

## Debate Phases

### Phase 1: Independent Scoring

Both experts independently score ALL criteria against the showcase screenshots. Neither sees the other's scores during this phase.

**Product strategist focus areas:**
- Does the color palette match the style brief's hex values?
- Does the typography match the style brief's specified families, weights, sizes?
- Do shadows, borders, and radii match the style brief?
- Does the overall visual impression match the style brief's described feel?
- Is the showcase coherent with the product concept's intended audience and tone?
- If visual grounding assets exist:
  - References: Does the overall direction align with inspirational references?
  - Designs: How closely do components match design mockups?
  - Brand: Are brand elements correctly applied?

**UX specialist focus areas:**
- Are all component variants rendered (sizes, states)?
- Are interactive states visually distinct (default, hover, active, disabled, error)?
- Does the component library theme configuration appear applied globally (not per-component overrides)?
- Does the visual hierarchy (heading, body, caption) establish clear reading order?
- Are components aligned to a consistent grid or layout system?
- Is content density appropriate for the intended use?
- Does dark mode (if applicable) maintain contrast and readability?
- Are spacing tokens consistent across components?

**Phase 1 file output:** Each expert writes their review to a file using the expert visual review template (`${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-static-prototype-teams/references/expert-visual-review-template.md`). The skill tells each agent the exact file path to write to:
- Product strategist -> `prototypes/static/reviews/round-N-strategist-review.md`
- UX specialist -> `prototypes/static/reviews/round-N-ux-review.md`

The agent returns a brief summary in conversation -- the full review is in the file. Downstream steps read from the file, not from conversation context.

### Divergence Check (Performed by Skill)

After Phase 1, the skill reads both review files and extracts per-criterion scores from the "Per-Criterion Scores" table.

**In divergence mode:** Calculate `|strategist_score - ux_score|` for each criterion.
- If max divergence < 2: Skip Phase 2. Combined score per criterion = `min(strategist, ux)`. Present to user: "Experts scored within 1 point on all criteria. No divergence detected -- skipping cross-review."
- If any divergence >= 2: Proceed to Phase 2. Present to user: "Divergence detected on [N] criteria (difference >= 2 points): [list criteria names and score pairs]. Triggering cross-review."

**In standard mode:** Always proceed to Phase 2 regardless of score differences.

### Phase 2: Cross-Review

Each expert reads the other's Phase 1 file and responds per-criterion.

**Instructions for each expert during cross-review:**

For each criterion:
- **Agree** -- the other expert's score is valid. Optionally adjust own score (up or down) with reasoning.
- **Disagree** -- the other expert's score is incorrect. Maintain own score with counter-evidence (reference specific screenshot areas, style brief sections, or component states).
- **New concern prompted** -- the other expert's review reveals something not previously noticed. Add observation.

Focus on DIVERGENT criteria (score difference >= 2). For criteria with small differences (<= 1 point), a brief acknowledgment suffices.

**Phase 2 file output:** Each expert writes their cross-review to a separate file:
- Product strategist -> `prototypes/static/reviews/round-N-strategist-cross-review.md`
- UX specialist -> `prototypes/static/reviews/round-N-ux-cross-review.md`

In sequential mode (where the UX specialist writes Phase 1 + Phase 2 combined), the combined output goes to `round-N-ux-review.md` (a single file with both sections).

### Phase 3: Synthesis (Performed by Skill)

The skill reads all review files written by the experts -- never from conversation context. The files to read are:
- `prototypes/static/reviews/round-N-strategist-review.md` (Phase 1)
- `prototypes/static/reviews/round-N-ux-review.md` (Phase 1, or Phase 1 + Phase 2 combined in sequential mode)
- `prototypes/static/reviews/round-N-strategist-cross-review.md` (Phase 2, if written separately)
- `prototypes/static/reviews/round-N-ux-cross-review.md` (Phase 2, Agent Teams mode only)

For each criterion, categorize:

**Consensus:** Both experts scored the same, or one adjusted their score in cross-review to match the other. Combined score = the agreed score.

**Additions:** One expert scored lower with specific feedback, the other did not dispute the lower score in cross-review (neither agreed nor disagreed). Combined score = the lower score.

**Disagreements:** Both experts maintained different scores after cross-review -- one raised a concern and the other explicitly disagreed. These require user resolution in Phase 4.

**No-debate:** Criteria where Phase 2 was skipped (divergence mode, no divergence detected). Combined score = `min(strategist, ux)`.

Write the debate review report using the debate review report template. Save to `prototypes/static/reviews/round-N-cycle-M-debate-report.md`.

### Phase 4: Resolution (Conditional)

**Trigger:** One or more unresolved disagreements exist after Phase 3.

For each unresolved disagreement, present to the user:

"Expert disagreement on **[Criterion Name]** (criterion #[N]):
- **Product Strategist:** Score [X] -- [reasoning and evidence]
- **UX Specialist:** Score [Y] -- [reasoning and evidence]
- **Trade-off:** [what each score optimizes for]

What score should this criterion receive?"

Record user decisions. Update the debate report with resolutions. The resolved score becomes the final combined score for that criterion.

## Sequential Mode Invocation Detail

When Agent Teams is not enabled, the skill simulates the debate with 3 sequential invocations per round:

**Invocation 1 -- Product Strategist Phase 1:**

Invoke `arn-spark-product-strategist` with:
- Screenshots from capture step
- All criteria with descriptions, scoring scale, and threshold
- Style brief, product concept, visual grounding assets (with category context)
- Expert visual review template path: `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-static-prototype-teams/references/expert-visual-review-template.md`
- File path to write to: `prototypes/static/reviews/round-N-strategist-review.md`
- Instruction: "Score every criterion independently against the screenshots. Write your complete review to the specified file path using the expert visual review template. Return a brief summary in conversation."

**Invocation 2 -- UX Specialist Phase 1 + Phase 2 Combined:**

Invoke `arn-spark-ux-specialist` with:
- Same inputs as Invocation 1
- The strategist's file path to read: `prototypes/static/reviews/round-N-strategist-review.md`
- File path to write to: `prototypes/static/reviews/round-N-ux-review.md`
- Instruction: "First, score every criterion independently from the UX perspective using the Phase 1 format. Then, read the strategist's review at the specified file path and respond to each criterion score using the Phase 2 cross-review format: agree (optionally adjust your score), disagree (with counter-evidence), or note new concerns. Write your complete review (Phase 1 + Phase 2 combined) to the specified file path. Return a brief summary in conversation."

**Invocation 3 -- Product Strategist Phase 2:**

Invoke `arn-spark-product-strategist` with:
- The UX specialist's file path to read: `prototypes/static/reviews/round-N-ux-review.md`
- Expert visual review template path
- File path to write to: `prototypes/static/reviews/round-N-strategist-cross-review.md`
- Instruction: "Read the UX specialist's review at the specified file path. The UX specialist has scored the criteria and also responded to your review. Respond to their scores and cross-review using the Phase 2 format. Write your cross-review to the specified file path. Return a brief summary in conversation."

The skill synthesizes by reading all three review files (not from conversation context).

**Note on sequential asymmetry:** In sequential mode, the UX specialist sees the strategist's review before writing their own Phase 1 review. Instruct the UX specialist to "score independently first" to minimize anchoring bias. The synthesis step normalizes the output regardless of invocation order.

## Agent Teams Mode Invocation Detail

**Phase 1:** Spawn both experts simultaneously as teammates. Each receives:
- Screenshots, criteria, scoring parameters, style brief, product concept, visual grounding assets
- Expert visual review template path
- File path to write to: strategist -> `round-N-strategist-review.md`, UX specialist -> `round-N-ux-review.md`
- Instruction: "Score every criterion independently. Write the complete review to the specified file path using the expert visual review template. Do not communicate with other teammates during this phase."

Both produce Phase 1 reviews independently and write them to their respective files.

**Runtime verification:** After Phase 1, the skill checks that BOTH review files exist and contain per-criterion scores. If one file is missing (Agent Teams silently failed to spawn one expert), invoke the missing expert sequentially and note the issue in the debate report: "Agent Teams Phase 1 partial failure: [agent] did not produce its review file. Invoked sequentially as fallback."

**Phase 2:** Share file paths through Teams communication:
- Tell the UX specialist to read the strategist's file: `round-N-strategist-review.md`
- Tell the strategist to read the UX specialist's file: `round-N-ux-review.md`
- Each reads the other's file and writes their cross-review to a separate file:
  - Product strategist -> `round-N-strategist-cross-review.md`
  - UX specialist -> `round-N-ux-cross-review.md`
- Each responds using the Phase 2 cross-review format from the expert visual review template

The skill synthesizes by reading all four review files (not from conversation context).

## Invocation Counts per Cycle

| Execution Mode | Debate Mode | Divergence Found | Expert Invocations | Notes |
|---------------|-------------|------------------|-------------------|-------|
| Agent Teams | Standard | N/A (always) | 4 (2 P1 + 2 P2) | Parallel within phases |
| Agent Teams | Divergence | Yes | 4 (2 P1 + 2 P2) | Same as standard |
| Agent Teams | Divergence | No | 2 (P1 only) | Phase 2 skipped |
| Sequential | Standard | N/A (always) | 3 (strat P1, UX P1+P2, strat P2) | |
| Sequential | Divergence | Yes | 3 | |
| Sequential | Divergence | No | 2 (strat P1, UX P1) | Phase 2 skipped |
| Single-reviewer | Any | N/A | 1 | No debate |

For max_cycles=3 with Agent Teams + standard mode: up to 12 expert invocations + 3 build cycles + 3 capture cycles + judge + showcase.

## Skill's Facilitation Responsibilities

The `arn-spark-static-prototype-teams` skill (not the agents) is responsible for:

1. **Agent Teams verification:** Check env var in Step 1 AND verify both experts write files after Phase 1. If one expert's file is missing, invoke sequentially as fallback and log the issue.
2. **Mode detection:** Record execution mode (agent_teams / sequential) and debate mode (divergence / standard) from Step 1 and Step 3
3. **Directory setup:** Create `prototypes/static/reviews/` if it does not exist before invoking experts
4. **File path assignment:** Tell each expert agent the exact file path to write to and the expert visual review template path
5. **Phase orchestration:** Run Phase 1, perform divergence check, conditionally run Phase 2, telling each expert to read the other's review file (by file path, not by passing content through conversation)
6. **Synthesis:** Read all expert review files and categorize per criterion into consensus, additions, disagreements. Never rely on the expert's conversation summary -- always read the file.
7. **Score computation:** For each criterion, compute the final combined score based on debate outcome (consensus: agreed score, additions: lower score, disagreements: user-resolved score, no-debate: min of two)
8. **Conflict detection:** Identify disagreements and present to user for resolution with both positions and evidence
9. **Report writing:** Produce the debate review report per template and save to file
10. **Budget management:** Never exceed the user's configured max_cycles
11. **User communication:** Present divergence status, debate summaries, and resolution requests clearly between phases
