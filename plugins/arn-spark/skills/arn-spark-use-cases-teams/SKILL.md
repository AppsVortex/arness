---
name: arn-spark-use-cases-teams
description: >-
  This skill should be used when the user says "use cases teams",
  "arn use cases teams", "team use cases", "debate use cases",
  "collaborative use cases", "use cases with debate",
  "team-based use case review", "use case debate", "review use cases as a team",
  or wants to create structured use case documents through expert debate
  where product strategist and UX specialist review and discuss each other's
  findings before revising, producing a use-cases/ directory with individual
  Cockburn fully-dressed use case files and a README index.
version: 1.0.0
---

# Arness Use Cases Teams

Create structured use case documents in Cockburn fully-dressed format through a team debate process. The `arn-spark-use-case-writer` agent drafts, then `arn-spark-product-strategist` and `arn-spark-ux-specialist` (greenfield agents in this plugin) engage in a structured debate -- reviewing each other's findings, agreeing, disagreeing, and surfacing insights neither would find alone. Supports Agent Teams for parallel debate or sequential simulation as fallback. If `arn-spark-ux-specialist` is unavailable, the skill falls back to single-reviewer mode with product strategist only. This is a conversational skill that runs in normal conversation (NOT plan mode).

This is an alternative to `arn-spark-use-cases` (independent sequential review). Use this when the project has enough complexity that expert debate adds value -- multiple actors, many use cases, or business rules that benefit from cross-disciplinary scrutiny. For simpler projects or lower token budgets, use `/arn-spark-use-cases` instead.

The primary artifacts are a **use-cases/ directory** at the project root containing individual use case files (`UC-NNN-title.md`) and a **README.md** index -- the same output format as `/arn-spark-use-cases`. Additionally, mandatory **per-round debate reports** are saved to `use-cases/reviews/`.

## Prerequisites

Same prerequisites as `/arn-spark-use-cases`. Check in order:

Determine the use cases output directory:
1. Read the project's `CLAUDE.md` and check for a `## Arness` section
2. If found, extract the configured Use cases directory path — this is the source of truth
3. If no `## Arness` section exists or Arness Spark fields are missing, inform the user: "Arness Spark is not configured for this project yet. Run `/arn-brainstorming` to get started — it will set everything up automatically." Do not proceed without it.
4. If the directory does not exist, create it

> All references to `use-cases/` in this skill refer to the configured use cases directory determined above.

**Product concept (strongly recommended):**
1. Read the project's `CLAUDE.md` for a `## Arness` section. If found, look for a `Vision Directory` field and check that directory for `product-concept.md`
2. If no `## Arness` section found, check `.arness/vision/product-concept.md` at the project root

**If a product concept is found:** Use it as the primary source for actors, goals, and use case derivation.

**If no product concept is found:** Ask the user: "No product concept found. I recommend running `/arn-spark-discover` first to define your product. Alternatively, describe your application's purpose, users, and main capabilities and I will work from that."

**Architecture vision (optional):**
1. Check the same Vision directory for `architecture-vision.md`
2. If no `## Arness` section found, check `.arness/vision/architecture-vision.md` at the project root

If found: use for understanding system capabilities, constraints, and platform scope.

**Existing prototype screens (optional):**
1. Read the configured Prototypes directory from the `## Arness` section (default: `.arness/prototypes`)
2. Check for `[prototypes-dir]/clickable/` directories
3. Check for `[prototypes-dir]/static/` directories

If found: screen references can enrich use case steps with concrete screen paths.

**Style brief is NOT needed.** Use cases describe behavior, not visual presentation.

## Workflow

### Step 1: Detect Resume or Fresh Start

Check for existing use case output:

1. Look for `use-cases/README.md` at the project root
2. If found, scan for `use-cases/UC-*.md` files

**If existing use cases found:**

Ask (using `AskUserQuestion`):

**"I found an existing use cases directory with [N] use case files. Which would you prefer?"**

Options:
1. **Continue** — I will read the existing use cases and offer to add new ones or revise existing ones
2. **Fresh start** — I will begin from scratch (existing files will be overwritten)

If continuing: read all existing use case files and the README. Present the current catalog to the user. Ask what they want to change, add, or revise. Skip to the appropriate step.

**If no existing use cases:** Proceed to Step 2.

### Step 2: Configure Debate Parameters

1. Check for Agent Teams support via Bash: `echo $CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`
2. Record the debate mode: "agent_teams" if the value is "1", otherwise "sequential". **The mode selection is based ONLY on this environment variable. File-based review output works identically in both modes and does NOT affect mode selection. When Agent Teams is enabled, always use Agent Teams mode.**
3. Check `arn-spark-ux-specialist` availability by attempting to invoke it with a minimal prompt (e.g., "Respond with OK to confirm availability"). If the agent is not found or the invocation fails, record single-reviewer mode.

Present the configuration:

"**Debate configuration:**

- **Debate mode:** [Agent Teams (parallel debate) / Sequential (simulated debate)]
- **Reviewers:** arn-spark-product-strategist + arn-spark-ux-specialist [/ arn-spark-product-strategist only (UX specialist unavailable)]
- **Max review rounds:** 2 (each round: expert debate + writer revision)

Ask (using `AskUserQuestion`):

**"Confirm debate configuration or adjust?"**

Options:
1. **Confirm** — Proceed with these settings
2. **Adjust** — Change max review rounds (1-4) or other settings"

If Agent Teams is not enabled, also note: "Agent Teams is not enabled. The debate will run sequentially (I will pass feedback between experts). For parallel debate, set `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in `~/.claude/settings.json`. Alternatively, use `/arn-spark-use-cases` for independent sequential reviews (lower cost)."

If `arn-spark-ux-specialist` is unavailable: "UX specialist is not available. Review will be strategist-only (no debate). Consider `/arn-spark-use-cases` which handles single-reviewer mode identically."

Wait for user confirmation or adjustments.

### Step 3: Identify Actors and Propose Use Case Catalog

Load the product concept and extract actors and use cases. Read the base skill for the detailed actor and use case identification process:

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-use-cases/SKILL.md` — follow its Step 2 (Identify Actors and Propose Use Case Catalog) for the actor extraction, use case derivation, level classification, and relationship mapping process.

Present the actor catalog, proposed use case catalog, and relationship diagram as specified in that step. Wait for user confirmation or adjustments.

### Step 4: Draft All Use Cases and Create Task List

Draft use cases in parallel by invoking multiple `arn-spark-use-case-writer` agents simultaneously. Follow the same grouping strategy and invocation pattern as `/arn-spark-use-cases` Step 3:

- Group use cases with direct includes/extends relationships into clusters
- Each writer receives the FULL catalog for cross-reference awareness but only its assigned UC-IDs to draft
- Each writer receives: product concept, actor catalog, full use case catalog, assigned UC-IDs, use case template (`${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-use-cases/references/use-case-template.md`), output directory (`use-cases/`), prototype screens (if any), architecture vision (if available)
- After all parallel writers complete, invoke one final writer to produce the README index using the index template (`${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-use-cases/references/use-case-index-template.md`)

Create the task list based on the configured max_rounds. For max_rounds=2:

```
Task 1: Draft all use cases
Task 2: Expert review debate (Round 1)
Task 3: Revise use cases (Round 1)
Task 4: Expert review debate (Round 2)
Task 5: Revise use cases (Round 2)
Task 6: User review
```

Mark Task 1 as completed. Present the task list to the user in conversation and update it visually after each completed step. Present a brief summary: "**[N] use cases drafted.** Files written to `use-cases/`. Starting expert review debate."

### Step 5: Expert Review Debate (Iterative)

For each review round (up to max_rounds):

Read the debate protocol:
> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-use-cases-teams/references/debate-protocol.md`

#### 5a: Debate

Create the `[use-cases-dir]/reviews/` directory if it does not exist.

**If debate_mode is "agent_teams":**

Follow the Agent Teams Mode Invocation Detail in the debate protocol. Spawn both experts simultaneously as teammates. Each expert receives the expert review template path (`${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-use-cases/references/expert-review-template.md`) and a unique file path to write to (no file contention — each agent writes to a different file). Phase 1: both experts write independent reviews to their respective files in parallel. Phase 2: each expert reads the other's completed file and writes its cross-review to a separate file. File-based output works naturally with Agent Teams — do not fall back to sequential mode because of file output.

**If debate_mode is "sequential":**

Follow the Sequential Mode Invocation Detail in the debate protocol:

1. Invoke `arn-spark-product-strategist` with all UC content, product concept, actor catalog, business review focus instructions, expert review template path, and file path to write to: `[use-cases-dir]/reviews/round-N-business-review.md`. The strategist writes its Phase 1 review to the file.
2. Invoke `arn-spark-ux-specialist` with all UC content, product concept, screens (if any), flow review focus instructions, expert review template path, the business reviewer's file path to read (`[use-cases-dir]/reviews/round-N-business-review.md`), and file path to write to: `[use-cases-dir]/reviews/round-N-flow-review.md`. Instruct: "Review independently first using the Phase 1 format. Then read the business reviewer's review at the specified file path and respond to each finding using the Phase 2 cross-review format. Write your complete review (Phase 1 + Phase 2 combined) to the specified file path."
3. Invoke `arn-spark-product-strategist` with the flow reviewer's file path to read (`[use-cases-dir]/reviews/round-N-flow-review.md`), expert review template path, and file path to write to: `[use-cases-dir]/reviews/round-N-business-cross-review.md`. Instruct: "Read the flow reviewer's review at the specified file path. Respond to their findings and their responses to your review using the Phase 2 cross-review format. Write your cross-review to the specified file path."

**If arn-spark-ux-specialist is unavailable (single-reviewer mode):**

Invoke `arn-spark-product-strategist` only with all UC content, business review focus instructions, expert review template path, and file path to write to: `[use-cases-dir]/reviews/round-N-business-review.md`. No cross-review phase. Note limitation.

#### 5b: Synthesize Debate Report

Read the review report template:
> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-use-cases-teams/references/review-report-template.md`

Read all expert review files written during Step 5a (never from conversation context):
- `[use-cases-dir]/reviews/round-N-business-review.md` (Phase 1)
- `[use-cases-dir]/reviews/round-N-flow-review.md` (Phase 1, or Phase 1 + Phase 2 combined in sequential mode)
- `[use-cases-dir]/reviews/round-N-business-cross-review.md` (Phase 2, if it exists)
- `[use-cases-dir]/reviews/round-N-flow-cross-review.md` (Phase 2, Agent Teams mode only, if it exists)

Synthesize from all expert review files:
- **Consensus:** Items both experts flagged, or one raised and the other agreed in cross-review
- **Additions:** Items one expert raised that the other did not dispute
- **Disagreements:** Items where experts explicitly disagreed and the disagreement persisted

Save the report to `[use-cases-dir]/reviews/round-N-review-report.md`.

#### 5c: Resolve Conflicts

**If disagreements exist:** For each disagreement, present both positions and the trade-off summary, then ask:

Ask (using `AskUserQuestion`):

> **Expert disagreement on UC-[NNN] [Title]: [brief description]. Which direction?**
> 1. **Business Reviewer's position** — [brief summary]
> 2. **Flow Reviewer's position** — [brief summary]
> 3. **Compromise** — I will describe a middle ground

If the user chooses option 3, collect their compromise as free-form text. Update the report with all resolutions.

**If no disagreements:** Skip this sub-step.

#### 5d: Revise Use Cases

Revise use cases in parallel using the same grouping strategy as Step 4. Each `arn-spark-use-case-writer` receives:
- **Existing draft paths:** the current use case files for its assigned UC-IDs
- **Combined debate report:** the "Recommended Changes for Writer" section, filtered to its assigned UCs (plus any cross-cutting changes that apply to all UCs)
- **Use case catalog:** the FULL catalog (for cross-reference awareness)
- **Use case template:** (same shared path)
- **Output directory:** `use-cases/` (overwrites existing files)

After all parallel writers complete, invoke one final writer to update the README index.

#### 5e: Convergence Check

Evaluate the debate report's convergence status using the convergence criteria defined in the debate protocol (`${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-use-cases-teams/references/debate-protocol.md`, Convergence Criteria section). The debate report's "Round recommendation" field provides a preliminary assessment — verify it against the full criteria.

Present the round summary: "**Round [N] complete.** [M] use cases revised. [Summary of major changes]. [Convergence status: converged / another round needed]."

If converged: skip remaining rounds, mark remaining debate+revision tasks as completed, proceed to Step 6.

### Step 6: User Review

Present the final use case catalog:

"**Use case authoring complete.**

**Summary:**
- **Use cases:** [N] total ([X] user-goal, [Y] subfunction, [Z] summary)
- **Actors:** [N] actors ([X] primary, [Y] secondary, [Z] supporting)
- **Debate mode:** [Agent Teams / Sequential / Single-Reviewer]
- **Review rounds:** [N] of [max_rounds]

**Use Case Catalog:**
| UC-ID | Title | Actor | Level | Priority | Status |
|-------|-------|-------|-------|----------|--------|
| UC-001 | [Title] | [Actor] | User Goal | Must-have | Final |
| ... | ... | ... | ... | ... | ... |

All files are in the `use-cases/` directory. Debate reports are in `use-cases/reviews/`.

Ask (using `AskUserQuestion`):

**"What would you like to do?"**

Options:
1. **Adjust a specific use case** — Tell me which one and what to change
2. **Add new use cases** — I will extend the catalog
3. **Proceed** — Use cases are complete"

If the user wants adjustments: invoke `arn-spark-use-case-writer` with the specific use case and the user's change request.
If the user wants new use cases: return to Step 3 with the additions (existing use cases are preserved).
If the user is satisfied: proceed to Step 7.

### Step 7: Write Final Report

Write `use-cases/reviews/final-report.md` with:
- Complete debate history across all rounds
- Aggregated review arc: how findings evolved, what converged, what the user decided
- Links to all per-round reports
- Final convergence status
- Summary statistics (total findings, consensus count, disagreement count, user decisions)

### Step 8: Recommend Next Steps

"Use cases saved to `use-cases/`. Debate reports saved to `use-cases/reviews/`.

These use cases are now available as input for downstream skills:
1. **Scaffold the project:** Run `/arn-spark-scaffold` to set up the development skeleton
2. **Explore visual style:** Run `/arn-spark-style-explore` to establish the visual direction
3. **Prototype the UI:** Run `/arn-spark-clickable-prototype` -- use cases will enrich screen derivation and replace manually defined journeys
4. **Extract features:** Run `/arn-spark-feature-extract` -- use cases provide structured behavioral specs for richer feature extraction

Use cases are living documents. As the project evolves, run `/arn-spark-use-cases-teams` again to add or revise them."

## Agent Invocation Guide

| Situation | Action |
|-----------|--------|
| Draft all use cases (Step 4) | Invoke multiple `arn-spark-use-case-writer` agents in parallel, each with full catalog + assigned UC subset. Then one final writer for the README index. |
| Expert debate -- Agent Teams (Step 5a) | Spawn both experts simultaneously. Each gets expert review template path + file path to write to. Phase 1: write independent reviews to files. Phase 2: read each other's files, write cross-reviews to separate files. Follow debate protocol. |
| Expert debate -- Sequential (Step 5a) | (1) Invoke strategist with UCs + business focus + file path to write to. (2) Invoke UX specialist with UCs + flow focus + strategist's file path to read + own file path to write to. (3) Invoke strategist with UX specialist's file path to read + cross-review file path to write to. Follow debate protocol. |
| Expert debate -- UX unavailable (Step 5a) | Invoke strategist only with file path to write to. No debate phases. Note limitation in report. |
| Synthesize debate report (Step 5b) | Skill reads all expert review files (not from conversation). Synthesizes and saves to `[use-cases-dir]/reviews/round-N-review-report.md`. |
| Resolve conflicts (Step 5c) | Present each disagreement to user with both positions. Wait for decisions. Update report. |
| Revise use cases (Step 5d) | Invoke multiple `arn-spark-use-case-writer` agents in parallel, each with its assigned UC drafts + debate report changes. Then one final writer for the README index. |
| User requests specific UC adjustment (Step 6) | Invoke `arn-spark-use-case-writer` with the specific UC path and the user's change description |
| User wants to add new use cases | Return to Step 3 with additions to the catalog |
| User asks about technology choices | Defer: "Use cases describe behavior, not implementation. Technology choices are in `/arn-spark-arch-vision`." |
| User asks about screen design | Defer: "Screen design is handled by `/arn-spark-style-explore` and `/arn-spark-clickable-prototype`. Use cases focus on what the system does, not how it looks." |
| User asks about features | Defer: "Feature extraction happens in `/arn-spark-feature-extract`, which will consume these use cases as input." |
| User asks about implementation specs | Defer: "Implementation specifications are created by `/arn-code-feature-spec` (requires arn-code plugin). Use cases provide the behavioral foundation that feature specs build on." |
| Strategist returns vague review | Re-invoke with more specific prompt: "Review each use case individually. For each, provide at least one Critical or Minor feedback item with a specific observation and suggestion." |
| UX specialist returns vague review | Re-invoke with more specific prompt focusing on flow analysis: "For each use case, assess the main scenario naturalness, step granularity, and identify at least one missing interaction pattern (cancel, timeout, retry, empty state)." |

## Error Handling

- **Agent Teams not enabled:** Fall back to sequential debate mode automatically. Inform user and offer `/arn-spark-use-cases` as lower-cost alternative.
- **Expert unresponsive in Agent Teams mode:** Fall back to sequential mode for this round. Note the issue in the debate report.
- **arn-spark-ux-specialist unavailable:** Single-reviewer mode. No debate, strategist reviews alone. Suggest `/arn-spark-use-cases` as equivalent for single-reviewer. Note limitation in all reports.
- **No product concept found and user declines to describe:** Cannot proceed meaningfully. Suggest: "Run `/arn-spark-discover` first to define what you are building."
- **Product concept is very brief:** Proceed but warn: "The product concept has limited detail. Use cases may be thin and need more revision."
- **arn-spark-use-case-writer fails to write files:** Print the use case content in conversation so the user can copy it manually.
- **Very large number of use cases (>15):** Warn the user: "This is a large number of use cases, which increases debate time and token cost. I recommend focusing on must-have use cases first."
- **Debate loops without convergence at max_rounds:** Proceed to user review with remaining issues noted in the final report.
- **No actors identified from product concept:** Ask the user directly: "I could not identify clear actors from the product concept. Who uses this application and what do they want to accomplish?"
- **Review reports directory creation fails:** Print report content in conversation so the user can save it manually.
- **User cancels mid-process:** Inform the user that partial use case files exist in `use-cases/` and any completed debate reports exist in `use-cases/reviews/`. They can resume later.
- **User wants to add a use case during review (Step 5):** Accept the addition. Add it to the catalog and include it in the current or next writer invocation.
- **Resume with corrupted or incomplete files:** Offer a fresh start. If the user wants to preserve partial work, read what exists and present it for the user to decide what to keep.
