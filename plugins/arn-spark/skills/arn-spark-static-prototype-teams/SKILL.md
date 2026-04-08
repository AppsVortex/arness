---
name: arn-spark-static-prototype-teams
description: >-
  This skill should be used when the user says "static prototype teams",
  "arn static prototype teams", "team static prototype", "debate static prototype",
  "collaborative visual review", "static prototype with debate",
  "team-based visual review", "visual debate", "review visuals as a team",
  or wants to create a static component showcase and validate it through
  iterative expert debate cycles where product strategist and UX specialist
  discuss their scores and findings before producing a combined review,
  with per-criterion scoring, an independent judge verdict, and versioned output.
  Supports Agent Teams for parallel debate or sequential simulation as fallback.
  For standard lower-of-two-scores visual review, use /arn-spark-static-prototype instead.
version: 1.0.0
---

# Arness Static Prototype Teams

Create a static component showcase and validate it through iterative build-review cycles with expert debate, aided by the `arn-spark-prototype-builder` agent (in showcase mode) for rendering, the `arn-spark-style-capture` agent for screenshots, `arn-spark-product-strategist` and `arn-spark-ux-specialist` (greenfield agents in this plugin) for debate-based expert review, and the `arn-spark-ux-judge` agent for an independent final verdict. This is a conversational skill that runs in normal conversation (NOT plan mode).

This is an alternative to `/arn-spark-static-prototype` (independent sequential review with mechanical lower-of-two scoring). Use this when the project has enough visual complexity that expert debate adds value -- nuanced style decisions, multiple visual grounding assets, components where strategist and UX perspectives genuinely differ. For simpler projects or lower token budgets, use `/arn-spark-static-prototype` instead.

The primary artifacts are **versioned showcase pages** with component renders, **debate review reports** with per-criterion scores and debate findings, and a **final report** documenting the complete validation and debate history. All output is versioned so the user can compare evolution across cycles.

This skill covers visual fidelity validation: do the components look correct according to the style brief? It does not cover interactive behavior -- that is `/arn-spark-clickable-prototype`'s job.

## Prerequisites

The following artifacts inform the validation. Check in order:

Determine the prototypes output directory:
1. Read the project's `CLAUDE.md` and check for a `## Arness` section
2. If found, extract the configured Prototypes directory path -- this is the source of truth
3. If no `## Arness` section exists or Arness Spark fields are missing, inform the user: "Arness Spark is not configured for this project yet. Run `/arn-brainstorming` to get started — it will set everything up automatically." Do not proceed without it.
4. If the directory does not exist, create it

> All references to `prototypes/` in this skill refer to the configured prototypes directory determined above.

**Style brief (strongly recommended):**
1. Read the project's `CLAUDE.md` for a `## Arness` section. If found, check the configured Vision directory for `style-brief.md`
2. If no `## Arness` section found, check `.arness/vision/style-brief.md` at the project root

**Product concept (recommended):**
1. Check the configured Vision directory for `product-concept.md`
2. If no `## Arness` section found, check `.arness/vision/product-concept.md` at the project root

**Architecture vision (for framework context):**
1. Check the configured Vision directory for `architecture-vision.md`
2. If no `## Arness` section found, check `.arness/vision/architecture-vision.md` at the project root

**Visual grounding assets (recommended):**
1. Read the `## Arness` section for the Visual grounding directory path
2. Check for assets in `[visual-grounding]/references/`, `[visual-grounding]/designs/`, `[visual-grounding]/brand/`
3. Also check the style brief's Visual Grounding section for asset paths and categories

If found: visual grounding assets will be provided to expert reviewers and the judge alongside showcase screenshots for comparison.

**Fresh design assets (optional):**
1. Read the `## Arness` section for `Figma` and `Canva` fields
2. If either is `yes` AND the visual grounding directory already has assets in `designs/` or `brand/`:
   Ask (using `AskUserQuestion`):

   > **Design assets exist from style exploration. Would you like to pull fresh versions from [Figma/Canva] before starting validation?**
   > 1. **Yes** — Pull fresh design assets
   > 2. **No** — Use existing assets on disk
   - If yes: ask the user to specify which assets to fetch (Figma file URL, page, or frame names / Canva design URL). Use the corresponding MCP to fetch and save to `[visual-grounding]/designs/` or `[visual-grounding]/brand/`. Show a summary of what was downloaded or replaced.
   - If no: proceed with existing assets on disk.
3. If either is `yes` but NO existing design assets found in `designs/` or `brand/`:
   Ask (using `AskUserQuestion`):

   > **No design mockups found yet. Would you like to pull design assets from [Figma/Canva]?**
   > 1. **Yes** — Pull design assets now
   > 2. **No** — Proceed without design mockups
   - If yes: same flow as above.
   - If no: proceed without design mockups.
4. If neither flag is `yes` or flags are missing: skip silently.

**If a style brief is found:** Use it for visual validation criteria.

**If no style brief is found:** Inform the user: "No style brief found. I can create a component showcase with default styling, but visual validation is more meaningful with a style brief. Consider running `/arn-spark-style-explore` first." Proceed if the user wants to continue -- criteria will focus on component quality and layout rather than style fidelity.

**Project scaffold:** The project must be scaffolded with the UI framework and component library installed. Check the project's dependency configuration. If not scaffolded, inform the user: "The project needs to be scaffolded before building a component showcase. Run `/arn-spark-scaffold` first."

**Agent Teams (strongly recommended):** This skill works best with Agent Teams enabled for parallel expert debate. Agent Teams availability is verified in Step 1 before any work begins. If not enabled, the skill falls back to sequential debate mode (or suggests `/arn-spark-static-prototype` for the non-debate alternative).

## Workflow

### Step 1: Check Agent Teams Availability

This is the FIRST step -- before any prototype work begins.

Run via Bash: `echo $CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`

**Display the result clearly to the user.** This is critical because Agent Teams sometimes does not activate even when the user expects it.

**If the variable is "1":**

"**Agent Teams: ENABLED** (environment variable `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` = `1`)

This skill will use Agent Teams for parallel expert debate. Both experts will score in parallel (Phase 1) and cross-review each other's findings in parallel (Phase 2).

Confirm to proceed, or type 'skip' to use `/arn-spark-static-prototype` instead (non-debate review, lower token cost)."

Wait for user confirmation before proceeding.

**If the variable is NOT "1" (empty, unset, or any other value):**

"**Agent Teams: NOT ENABLED** (environment variable `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` = `[actual value or 'unset']`)

This skill works without Agent Teams using sequential debate (I will pass feedback between experts manually), but parallel debate is faster and produces identical results.

**To enable Agent Teams:**
- Add to `~/.claude/settings.json` under `"env"`:
  ```json
  "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  ```
- Or set the environment variable before running Claude Code:
  ```bash
  CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 claude
  ```
- Then **restart this Claude Code session** (the variable must be set before the session starts).

Ask (using `AskUserQuestion`):

**"What would you like to do?"**

Options:
1. **Continue with sequential debate** — Same debate quality, slower execution (3 sequential expert invocations per debate round instead of 2 parallel)
2. **Use /arn-spark-static-prototype instead** — Non-debate review (mechanical lower-of-two scoring, lower token cost)
3. **Enable Agent Teams and restart** — Set the env var, restart Claude Code, then re-run this skill"

Wait for user response.

Record the execution mode: `"agent_teams"` if the value is `"1"`, otherwise `"sequential"`.

---

### Step 2: Detect Resume or Fresh Start

Check for existing versioned output:

1. Look for `prototypes/static/v*/` directories at the project root
2. If versions exist, find the highest version number

**If existing versions found:**

Ask (using `AskUserQuestion`):

**"I found existing static prototype versions up to v[N]. Which would you prefer?"**

Options:
1. **Continue from v[N]** — I will read the latest review report and continue with new cycles
2. **Fresh start** — I will begin from v1 (existing versions are preserved)

If continuing: read `prototypes/static/v[N]/review-report.md` to understand the current state and what was flagged. Ask the user for the new cycle budget and any focus refinements.

**If no existing versions:** Proceed to Step 3.

### Step 3: Configure Validation Parameters

Present defaults and ask the user to confirm or adjust:

"Let me set up the validation parameters:

**Scoring:**
- **Scale:** 1-5 (1 = unmet, 5 = exemplary)
- **Minimum threshold:** 4 (every criterion must score at least 4)
- **Max cycles:** 3 (build-review iterations before judge review)

**Debate configuration:**
- **Debate mode:** [Choose one]
  - **Divergence mode (Recommended):** Cross-review triggers only when any criterion score diverges by >= 2 points between experts. Saves tokens when experts mostly agree.
  - **Standard mode:** Full cross-review every cycle, regardless of score agreement. Richer debate, higher token cost.
- **Execution mode:** [Agent Teams / Sequential] (detected in Step 1)

**Token cost comparison:**
- `/arn-spark-static-prototype` (no debate): 2 expert invocations per cycle
- This skill (divergence mode): 2-4 expert invocations per cycle (2 if no divergence, 4 if divergence detected)
- This skill (standard mode): 3-4 expert invocations per cycle (always full debate)

**Criteria:** Based on your style brief and product concept, here are the proposed criteria:

| # | Criterion | Description |
|---|-----------|-------------|
| 1 | [criterion] | [description] |
| ... | ... | ... |

Adjust any parameter, debate mode, or criterion, or confirm to proceed."

To propose criteria:
1. Read the default criteria template:
   > Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-static-prototype/references/static-prototype-criteria.md`
2. Adapt based on available artifacts (remove dark mode criterion if not applicable, add visual grounding criteria if assets exist, etc.)
3. Present the adapted list

Check `arn-spark-ux-specialist` availability by attempting to invoke it with a minimal prompt (e.g., "Respond with OK to confirm availability"). If the agent is not found or the invocation fails, record single-reviewer mode and inform the user:

"UX specialist is not available. Review will be strategist-only (no debate). Consider `/arn-spark-static-prototype` which handles single-reviewer mode identically with lower overhead."

Present the full configuration summary:

"**Configuration summary:**
- **Debate mode:** [Divergence / Standard]
- **Execution mode:** [Agent Teams / Sequential / Single-reviewer]
- **Reviewers:** arn-spark-product-strategist + arn-spark-ux-specialist [/ arn-spark-product-strategist only]
- **Scale:** [1-N], **Threshold:** [T], **Max cycles:** [M]
- **Criteria:** [count] criteria

Confirm to proceed."

When the user confirms, write the agreed criteria to `prototypes/criteria.md` (create `prototypes/` directory if needed).

### Step 4: Create Task List

Create the task structure for the validation run. For max_cycles=N:

- Task pairs: Build v[X] + Debate review v[X] for each cycle (2 tasks per cycle)
- Judge review task
- User review task

Example for max_cycles=3 (starting from v1):
```
Task 1:  Build v1
Task 2:  Debate review v1
Task 3:  Build v2
Task 4:  Debate review v2
Task 5:  Build v3
Task 6:  Debate review v3
Task 7:  Judge review
Task 8:  User review
```

If resuming from v[N], number versions sequentially from v[N+1].

Present the task list to the user and proceed.

### Step 5: Build-Review Cycle (Iterative)

For each cycle:

#### 5a: Build

Invoke the `arn-spark-prototype-builder` agent with:
- **Showcase mode:** true
- **Style brief:** toolkit configuration section
- **Component list:** components from the criteria + style brief
- **UI framework and component library:** from architecture vision or the project's dependency configuration
- **Project root path**
- **Output path:** `prototypes/static/v[N]/`
- **Reference images (if available):** visual grounding assets
- **Previous review feedback (if not first cycle):** failing criteria details, debate insights, and improvement suggestions from the previous cycle's debate review report
- **Showcase expectations:** The builder should produce numbered sections showing each component with all variants, all states, contextual usage (components in realistic surroundings, not just isolation), working interactive elements (toggles that toggle, inputs that accept text), and a simulated environment background appropriate to the application type. If the style brief includes dark mode, the showcase should have an inline dark/light toggle.

Mark the Build task as in_progress before invoking, completed after.

#### 5b: Capture Screenshots

Invoke the `arn-spark-style-capture` agent with:
- **URL:** the URL serving the showcase (from the running prototype)
- **Output path:** `prototypes/static/v[N]/screenshots/`

If Playwright is unavailable, ask the user to provide screenshots of the showcase manually, or attempt to serve the showcase and capture screenshots through an alternative method. Note the limitation in the review report.

#### 5c: Expert Debate Review

This step replaces the mechanical lower-of-two scoring in `/arn-spark-static-prototype` with a structured expert debate.

1. Read the debate protocol:
   > Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-static-prototype-teams/references/debate-protocol.md`

2. Create the `prototypes/static/reviews/` directory if it does not exist.

**Phase 1: Independent Scoring**

Both experts independently score all criteria and write structured feedback to files.

**If execution_mode is "agent_teams":**

Spawn both experts simultaneously as teammates. Each receives:
- Screenshots from Step 5b
- Criteria list from `prototypes/criteria.md`
- Scoring scale and minimum threshold
- Style brief (full document)
- Product concept (full document)
- Visual grounding assets (with category context: references=inspirational, designs=specification, brand=constraints)
- Expert visual review template path: `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-static-prototype-teams/references/expert-visual-review-template.md`
- File path to write to:
  - Product strategist -> `prototypes/static/reviews/round-N-strategist-review.md`
  - UX specialist -> `prototypes/static/reviews/round-N-ux-review.md`
- Instruction: "Score every criterion independently against the screenshots. Write your complete review to the specified file path using the expert visual review template. Do not communicate with other teammates during this phase. Return a brief summary in conversation."

**Verify Agent Teams actually worked:** After Phase 1 completes, check that BOTH review files exist and contain per-criterion scores. If only one expert wrote its file (potential Agent Teams failure), note the issue, invoke the missing expert sequentially, and log in the debate report: "Agent Teams Phase 1 partial failure: [agent] did not produce its review file. Invoked sequentially as fallback."

**If execution_mode is "sequential":**

Invocation 1: Invoke `arn-spark-product-strategist` with all inputs and file path `prototypes/static/reviews/round-N-strategist-review.md`.

Invocation 2: Invoke `arn-spark-ux-specialist` with all inputs and file path `prototypes/static/reviews/round-N-ux-review.md`.

**If single-reviewer mode:**

Invoke `arn-spark-product-strategist` only. No debate. Strategist scores become the combined scores directly (same behavior as `/arn-spark-static-prototype` single-reviewer). Skip Phases 2-4.

**Divergence Check:**

The skill reads both Phase 1 review files and compares per-criterion scores.

If `debate_mode` is "divergence":
- Calculate the absolute score difference for each criterion
- If ALL criteria have score difference < 2: skip Phase 2. Present to user: "Experts scored within 1 point on all criteria. No divergence detected -- skipping cross-review. Combined scores use the lower of each pair."
- If ANY criterion has score difference >= 2: trigger Phase 2. Present to user: "Divergence detected on [N] criteria (difference >= 2 points): [list criteria names with score pairs]. Triggering cross-review."

If `debate_mode` is "standard": always proceed to Phase 2.

**Phase 2: Cross-Review**

Each expert reads the other's Phase 1 file and responds per-criterion, focusing on divergent criteria.

**If execution_mode is "agent_teams":**

Through Teams communication, instruct each expert:
- Product strategist: Read `prototypes/static/reviews/round-N-ux-review.md`, write cross-review to `prototypes/static/reviews/round-N-strategist-cross-review.md`
- UX specialist: Read `prototypes/static/reviews/round-N-strategist-review.md`, write cross-review to `prototypes/static/reviews/round-N-ux-cross-review.md`

Each responds per-criterion using the Phase 2 format from the expert visual review template: Agree (optionally adjust score), Disagree (counter-evidence), or New concern.

**If execution_mode is "sequential":**

This follows the 3-invocation sequential pattern. Since Phase 1 already completed with 2 invocations, Phase 2 requires 1 additional invocation for the UX specialist's cross-review (already combined in Invocation 2 of the sequential pattern) and 1 invocation for the strategist's cross-review.

Actually, the full sequential pattern runs as 3 total invocations across Phase 1 and Phase 2:

Invocation 1: Strategist Phase 1 (writes `round-N-strategist-review.md`)

Invocation 2: UX specialist Phase 1 + Phase 2 combined (reads strategist file, writes `round-N-ux-review.md` with both sections)

Invocation 3: Strategist Phase 2 (reads UX specialist file, writes `round-N-strategist-cross-review.md`)

If Phase 2 was skipped (divergence mode, no divergence): only Invocations 1 and 2 (Phase 1 only) run. Invocation 2 does NOT include Phase 2 instructions in this case. Total: 2 invocations.

**Phase 3: Synthesis**

The skill reads all review files written by the experts (never from conversation context):
- `prototypes/static/reviews/round-N-strategist-review.md` (Phase 1)
- `prototypes/static/reviews/round-N-ux-review.md` (Phase 1, or Phase 1 + Phase 2 combined in sequential mode)
- `prototypes/static/reviews/round-N-strategist-cross-review.md` (Phase 2, if written)
- `prototypes/static/reviews/round-N-ux-cross-review.md` (Phase 2, Agent Teams mode only, if written)

For each criterion, categorize:

- **Consensus:** Both experts scored the same, or one adjusted their score in cross-review to match. Combined score = the agreed score.
- **Additions:** One expert scored lower with specific feedback, the other did not dispute. Combined score = the lower score.
- **Disagreements:** Both experts maintained different scores after cross-review. Combined score = deferred to Phase 4 for user resolution.
- **No-debate:** Phase 2 was skipped. Combined score = min(strategist, ux).

Read the debate review report template:
> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-static-prototype-teams/references/debate-review-report-template.md`

Write the debate report to `prototypes/static/reviews/round-N-cycle-M-debate-report.md`.

**Phase 4: Resolution (if disagreements exist)**

For each unresolved disagreement, present to the user:

"Expert disagreement on **[Criterion Name]** (criterion #[N]):
- **Product Strategist:** Score [X] -- [reasoning and evidence]
- **UX Specialist:** Score [Y] -- [reasoning and evidence]
- **Trade-off:** [what each score optimizes for]

What score should this criterion receive? (Or provide your reasoning and I will set the score.)"

Record user decisions. Update the debate report with resolutions. The resolved score becomes the combined score for that criterion.

Mark the Debate review task as in_progress before Phase 1, completed after all phases finish.

#### 5d: Evaluate and Record

1. Check all combined scores (from debate synthesis) against the minimum threshold
2. Copy the debate report to `prototypes/static/v[N]/review-report.md` for version-local access
3. Write version notes to `prototypes/static/v[N]/version-notes.md` (what changed from previous version, or "Initial version" for v1)

**If ALL criteria pass:** Mark the Validate task as completed. Skip remaining cycles and proceed to Step 6 (Judge Review).

**If ANY criterion fails:**
- Present the failing criteria to the user with debate context (what the experts said, where they agreed/disagreed)
- Feed the failing criteria details, debate insights, and improvement suggestions to the next cycle's Build step
- Proceed to the next cycle (or Step 6 if this was the last cycle)

### Step 6: Judge Review

Invoke the `arn-spark-ux-judge` agent with:
- **Review mode:** `static` -- the judge reviews screenshots and files (there is nothing interactive to navigate in a static showcase)
- **Prototype artifacts:** paths to the latest version's showcase files and screenshots
- **Criteria list:** from `prototypes/criteria.md`
- **Scoring scale and minimum threshold**
- **Style brief and product concept**
- **Visual grounding assets (if available):** provide all three categories with context so the judge can compare the showcase against reference images, design mockups, and brand assets directly
- **Version number**
- **Previous review reports:** the latest version's review-report.md (which is the debate report)

The judge operates independently -- it provides its own scores without knowledge of the debate process. This is an independent validation gate.

Write the judge's report to `prototypes/static/v[N]/judge-report.md`.

**If Judge returns PASS:** Proceed to Step 6b.

**If Judge returns FAIL and cycle budget remains:**
- Present the judge's failing criteria to the user
- Calculate remaining budget (original max_cycles minus cycles used)
- "The judge flagged [N] criteria below threshold. You have [M] cycles remaining in the budget. Should I run [M] more fix cycles?"
- If the user agrees: create new Build+Debate review task pairs for the remaining cycles, return to Step 5
- If the user declines: proceed to Step 6b with the judge's report

**If Judge returns FAIL and no budget remains:** Proceed to Step 6b with the judge's report.

### Step 6b: Generate Visual Showcase

After the judge review completes, generate structured screenshot images so the user can review the final visual state without running a dev server.

1. Read the showcase capture guide:
   > Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-static-prototype/references/showcase-capture-guide.md`

2. Read the section manifest from `prototypes/static/v[N]/showcase-manifest.json`.

3. Start the prototype dev server.

4. Generate a Playwright capture script, run it to produce per-section screenshots and a full-page capture, including dark mode variants if applicable.

5. Stop the prototype dev server.

6. Write `prototypes/static/v[N]/showcase/showcase-index.md` with version, judge verdict, final scores, and embedded images.

If Playwright is unavailable, skip this step and inform the user the showcase can be viewed by running the dev server.

### Step 7: User Review

Present the complete validation history:

"**Static prototype validation complete (debate mode).**

**Latest version:** v[N]
**Judge verdict:** [PASS / FAIL]
**Debate mode:** [Divergence / Standard]
**Execution mode:** [Agent Teams / Sequential / Single-reviewer]

**Version history:**
| Version | Criteria Passing | Criteria Failing | Phase 2 Triggered | Notable Changes |
|---------|-----------------|------------------|-------------------|----------------|
| v1 | [X]/[M] | [Y] | [Yes/No] | Initial build |
| v2 | [X]/[M] | [Y] | [Yes/No] | [summary of fixes] |
| ... | ... | ... | ... | ... |

**Final scores (v[N]):**
| # | Criterion | Strategist | UX Specialist | Combined | Category | Judge | Status |
|---|-----------|-----------|---------------|----------|----------|-------|--------|
| 1 | [name] | [score] | [score] | [score] | [Consensus/Addition/Resolved] | [score] | PASS/FAIL |
| ... | ... | ... | ... | ... | ... | ... | ... |

The showcase is at `prototypes/static/v[N]/`.
Debate reports are at `prototypes/static/reviews/`.
[If showcase images were generated:] Visual showcase images are at `prototypes/static/v[N]/showcase/showcase-index.md` -- open this file to see all components at a glance without running the dev server.

Are you satisfied with this result, or would you like additional cycles?"

If the user wants more cycles, return to Step 3 with new parameters.

### Step 8: Write Final Report

Write `prototypes/static/final-report.md` with:
- Complete version history and all scores
- Debate history: per-cycle summaries including which criteria triggered cross-review, how disagreements were resolved, and how scores evolved across cycles
- Judge verdict and report (from `prototypes/static/v[N]/judge-report.md`)
- User decision
- Criteria used
- Links to all version directories and debate reports in `prototypes/static/reviews/`
- Link to the visual showcase (`prototypes/static/v[N]/showcase/showcase-index.md`) if generated

### Step 9: Recommend Next Steps

"Static prototype validation complete. Results saved to `prototypes/static/`.

Recommended next steps:
1. **Build clickable prototype:** Run `/arn-spark-clickable-prototype` to add interaction and validate user journeys
2. **Extract features:** Run `/arn-spark-feature-extract` to create a prioritized feature backlog

The clickable prototype will build on the validated visual direction from this static prototype."

## Agent Invocation Guide

| Situation | Action |
|-----------|--------|
| Check Agent Teams (Step 1) | Run `echo $CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` via Bash. Display result. Confirm with user. |
| Build showcase (Step 5a) | Invoke `arn-spark-prototype-builder` in showcase mode with style brief, components, output path, and previous debate review feedback |
| Capture screenshots (Step 5b) | Invoke `arn-spark-style-capture` with the showcase URL and output path. If unavailable, ask the user for manual screenshots. |
| Expert debate -- Agent Teams Phase 1 (Step 5c) | Spawn both experts simultaneously as teammates. Each writes to own file. Verify both files exist after completion. |
| Expert debate -- Agent Teams Phase 2 (Step 5c) | Through Teams communication, tell each expert to read the other's file and write cross-review to separate file. |
| Expert debate -- Sequential (Step 5c) | (1) Strategist Phase 1, writes file. (2) UX specialist Phase 1 + Phase 2, reads strategist file, writes own file. (3) Strategist Phase 2, reads UX file, writes cross-review. |
| Expert debate -- UX unavailable (Step 5c) | Strategist only. No debate. Same as `/arn-spark-static-prototype` single-reviewer. Suggest base skill. |
| Divergence check (Step 5c) | Skill reads both Phase 1 files, compares per-criterion scores. If divergence mode and all diffs < 2: skip Phase 2. |
| Synthesize debate report (Step 5c) | Skill reads all expert files (not from conversation). Categorizes per criterion: consensus, addition, disagreement, no-debate. Writes debate report. |
| Resolve disagreements (Step 5c Phase 4) | Present each disagreement to user with both positions and evidence. Wait for decisions. Update report. |
| Agent Teams failure detection (Step 5c) | After Phase 1, if one expert's file is missing, invoke that expert sequentially. Log the issue in the debate report. |
| Judge review (Step 6) | Invoke `arn-spark-ux-judge` in `static` mode with latest screenshots, criteria, scoring parameters, review reports, and visual grounding assets for direct comparison |
| Generate visual showcase (Step 6b) | Read shared showcase capture guide from base skill. Start prototype, generate and run Playwright capture script, write showcase-index.md. |
| User asks about interactive behavior | Defer: "Interactive behavior is validated in `/arn-spark-clickable-prototype`. This skill focuses on visual fidelity." |
| User asks to change the style | Defer to `/arn-spark-style-explore` for style brief updates, then re-run static prototype validation |
| User asks about features | Defer: "Feature work starts after `/arn-spark-feature-extract` and `/arn-code-feature-spec`." |
| Builder fails | Retry up to 3 times. If still failing, present the error for manual investigation. |
| Expert returns vague scores (all maximum, no evidence) | Re-invoke with more specific prompt requiring per-criterion evidence referencing exact screenshots. |

## Error Handling

- **Agent Teams not enabled:** Fall back to sequential debate mode. Inform user clearly with setup instructions and offer `/arn-spark-static-prototype` as lower-cost alternative.
- **Agent Teams enabled but one expert fails to write its file:** Detect the missing file after Phase 1. Invoke the missing expert sequentially. Note the issue in the debate report: "Agent Teams Phase 1 partial failure."
- **arn-spark-ux-specialist unavailable:** Single-reviewer mode. No debate, strategist reviews alone. Suggest `/arn-spark-static-prototype` as equivalent for single-reviewer. Note limitation in all reports.
- **No style brief found:** Proceed with component quality and layout criteria only. Note that visual fidelity criteria are deferred until a style brief exists.
- **Project not scaffolded:** Cannot build showcase. Suggest `/arn-spark-scaffold` first.
- **Builder fails (3 times):** Present the error. The user can investigate manually or adjust the approach.
- **Capture fails (Playwright unavailable):** Fall back to asking the user for manual screenshots. Note the limitation. The visual showcase (Step 6b) is also skipped.
- **Showcase manifest missing:** The builder did not write `showcase-manifest.json`. Capture a full-page screenshot only. Note: "Section manifest not found. Re-build the showcase to generate per-section captures."
- **Expert returns unhelpful scores (vague, all maximum, etc.):** Re-invoke with a more specific prompt asking for scores on each criterion individually with evidence.

- **Judge unavailable:** The user becomes the judge. Present all debate review reports and ask the user to make the pass/fail decision.
- **Resume from interrupted cycle:** Detect the latest version directory. If it has a review-report.md, the cycle completed -- continue from the next cycle. If it has showcase files but no review-report.md, the build completed but review did not -- run review on the existing build.
- **Criteria file already exists:**

  Ask (using `AskUserQuestion`):

  > **Existing criteria found at `prototypes/criteria.md`. What would you like to do?**
  > 1. **Use existing** — Keep the current criteria
  > 2. **Define new** — Create fresh criteria for this validation
- **Writing review files fails:** Print the full content in the conversation so the user can copy it.
- **User cancels mid-process:** Inform user of partial files in `prototypes/static/` and debate reports in `prototypes/static/reviews/`. These can be cleaned up manually.
