---
name: arn-spark-clickable-prototype-teams
description: >-
  This skill should be used when the user says "clickable prototype teams",
  "arn clickable prototype teams", "team clickable prototype", "debate clickable prototype",
  "collaborative interaction review", "clickable prototype with debate",
  "team-based interaction review", "interaction debate", "review interactions as a team",
  "interactive prototype teams", "team prototype review",
  or wants to create a clickable interactive prototype with linked screens and
  validate it through iterative expert debate cycles where product strategist
  and UX specialist discuss their scores and findings before producing a
  combined review, with Playwright-based interaction testing, per-criterion scoring,
  an independent judge verdict, and versioned output.
  Supports Agent Teams for parallel debate or sequential simulation as fallback.
  For standard lower-of-two-scores interaction review, use /arn-spark-clickable-prototype instead.
version: 1.0.0
---

# Arness Clickable Prototype Teams

Generate a clickable interactive prototype with all main application screens linked together and validate it through iterative build-review cycles with expert debate, aided by the `arn-spark-prototype-builder` agent for screen creation, the `arn-spark-ui-interactor` agent for Playwright-based interaction testing, `arn-spark-product-strategist` and `arn-spark-ux-specialist` (greenfield agents in this plugin) for debate-based expert review, and the `arn-spark-ux-judge` agent for an independent final verdict. This is a conversational skill that runs in normal conversation (NOT plan mode).

This is an alternative to `/arn-spark-clickable-prototype` (independent sequential review with mechanical lower-of-two scoring). Use this when the project has enough interaction complexity that expert debate adds value -- nuanced navigation decisions, multiple user journeys with trade-offs, screens where strategist and UX perspectives genuinely differ on flow quality. For simpler projects or lower token budgets, use `/arn-spark-clickable-prototype` instead.

The primary artifacts are **versioned clickable prototype applications**, **journey screenshots** documenting user flows, **debate review reports** with per-criterion scores and debate findings, and a **final report** documenting the complete validation and debate history. All output is versioned so the user can compare evolution across cycles.

This skill covers interactive behavior validation: do the screens link correctly, do interactions work, can users complete journeys? For visual-only validation of component rendering, use `/arn-spark-static-prototype` or `/arn-spark-static-prototype-teams` first.

## Prerequisites

The following artifacts inform the prototype. Check in order:

Determine the prototypes output directory:
1. Read the project's `CLAUDE.md` and check for a `## Arness` section
2. If found, extract the configured Prototypes directory path -- this is the source of truth
3. If no `## Arness` section exists or Arness Spark fields are missing, inform the user: "Arness Spark is not configured for this project yet. Run `/arn-brainstorming` to get started — it will set everything up automatically." Do not proceed without it.
4. If the directory does not exist, create it

> All references to `prototypes/` in this skill refer to the configured prototypes directory determined above.

**Product concept (strongly recommended):**
1. Read the project's `CLAUDE.md` for a `## Arness` section. If found, check the configured Vision directory for `product-concept.md`
2. If no `## Arness` section found, check `.arness/vision/product-concept.md` at the project root

**Style brief (recommended):**
1. Check the configured Vision directory for `style-brief.md`
2. If no `## Arness` section found, check `.arness/vision/style-brief.md` at the project root

**Architecture vision (for framework context):**
1. Check the configured Vision directory for `architecture-vision.md`
2. If no `## Arness` section found, check `.arness/vision/architecture-vision.md` at the project root

**Static prototype results (optional):**
1. Check for `[prototypes-dir]/static/final-report.md` -- if a static prototype was validated, the visual direction is confirmed

**Visual grounding assets (recommended):**
1. Read the `## Arness` section for the Visual grounding directory path
2. Check for assets in `[visual-grounding]/references/`, `[visual-grounding]/designs/`, `[visual-grounding]/brand/`
3. Also check the style brief's Visual Grounding section for asset paths and categories

If found: visual grounding assets will be provided to expert reviewers and the judge alongside journey screenshots for comparison. The focus is on screen-level layout comparison and overall flow feel, not component-level fidelity (that was validated in the static prototype).

**Fresh design assets (optional):**
1. Read the `## Arness` section for `Figma` and `Canva` fields
2. If either is `yes` AND the visual grounding directory already has assets in `designs/` or `brand/`:
   Ask (using `AskUserQuestion`):

   > **Design assets exist from a previous step. Would you like to pull fresh versions from [Figma/Canva] before starting validation?**
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

**Use cases (recommended):**
1. Read the configured Use cases directory from the `## Arness` section (default: `.arness/use-cases`)
2. Check for `[use-cases-dir]/README.md`
3. If found, scan for `[use-cases-dir]/UC-*.md` files

**If use cases are found:** Read the README index and all use case files. Use them alongside the product concept for richer screen and journey derivation (see Step 2b).

**If no use cases are found:** Derive screens and journeys from the product concept alone. Note: "No use cases found. Screen derivation will use the product concept directly. Run `/arn-spark-use-cases` first for richer screen derivation from structured behavioral specs."

**If a product concept is found:** Use it to derive the screen list and user journeys.

**If no product concept is found:** Ask the user to describe the screens and journeys: "No product concept found. Describe the main screens of your application and the key user flows, and I will create the prototype from your description."

**If a style brief is found:** Apply the visual style to all screens.

**If no style brief is found:** Use sensible defaults for the installed component library. Note: "No style brief found. The prototype will use default styling. Run `/arn-spark-style-explore` first for a custom visual direction."

**Project scaffold:** The project must be scaffolded with the UI framework and component library installed. If not, inform the user: "The project needs to be scaffolded before building a prototype. Run `/arn-spark-scaffold` first."

**Agent Teams (strongly recommended):** This skill works best with Agent Teams enabled for parallel expert debate. Agent Teams availability is verified in Step 1 before any work begins. If not enabled, the skill falls back to sequential debate mode (or suggests `/arn-spark-clickable-prototype` for the non-debate alternative).

## Workflow

### Step 1: Check Agent Teams Availability

This is the FIRST step -- before any prototype work begins.

Run via Bash: `echo $CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`

**Display the result clearly to the user.** This is critical because Agent Teams sometimes does not activate even when the user expects it.

**If the variable is "1":**

"**Agent Teams: ENABLED** (environment variable `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` = `1`)

This skill will use Agent Teams for parallel expert debate. Both experts will score in parallel (Phase 1) and cross-review each other's findings in parallel (Phase 2).

Ask (using `AskUserQuestion`):

> **Proceed with Agent Teams debate, or use standard review instead?**
> 1. **Proceed** — Use Agent Teams for parallel expert debate
> 2. **Skip** — Use `/arn-spark-clickable-prototype` instead (non-debate review, lower token cost)

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
2. **Use /arn-spark-clickable-prototype instead** — Non-debate review (mechanical lower-of-two scoring, lower token cost)
3. **Enable Agent Teams and restart** — Set the env var, restart Claude Code, then re-run this skill"

Wait for user response.

Record the execution mode: `"agent_teams"` if the value is `"1"`, otherwise `"sequential"`.

---

### Step 2: Detect Resume or Fresh Start

Check for existing versioned output:

1. Look for `prototypes/clickable/v*/` directories at the project root
2. If versions exist, find the highest version number

**If existing versions found:**

Ask (using `AskUserQuestion`):

**"I found existing clickable prototype versions up to v[N]. Which would you prefer?"**

Options:
1. **Continue from v[N]** — I will read the latest review report and continue with new cycles
2. **Fresh start** — I will begin from v1 (existing versions are preserved)

If continuing: read `prototypes/clickable/v[N]/review-report.md` to understand the current state and what was flagged. Ask the user for the new cycle budget and any focus refinements.

**If no existing versions:** Proceed to Step 2b.

### Step 2b: Derive Screen List and User Journeys

Load the product concept and extract screens and journeys:

**Screens:** Extract from the core experience:
- Each interaction mode suggests one or more screens
- Each user journey implies a sequence of screens
- Administrative functions suggest their own screens
- Check architecture vision for platform-specific screens
- Check style brief sample screens if any exist
- **Derive state-specific screens:** Each distinct state of a major screen should be a separate navigable view (e.g., a connection screen in "searching", "found", "pairing", "connected" states; a main view in "active", "muted", "idle", "offline" states). This makes every meaningful state individually navigable, screenshottable, and testable rather than hiding states behind runtime interactions that may be hard to trigger.

**Screen organization:** Group screens by functional area (e.g., setup flow, main experience, settings). The builder will create:
- A **hub screen** grouping all areas with screen counts and descriptions as the prototype entry point
- **Sequential prev/next navigation** within each group for guided walkthroughs
- **Persistent navigation** across all screens showing the current group

This structure supports both human reviewers (who can explore freely or follow a guided path) and automated testing tools (which can discover screens from the hub and follow linear navigation).

**If use cases are available, also derive screens from them:**
- Each use case main success scenario implies a screen sequence (each step where the system presents information or the actor interacts with the UI suggests a screen or screen state)
- Each extension/alternate flow may imply additional screens or states not visible in the main scenario (error screens, confirmation dialogs, empty states, timeout states)
- Use case preconditions may imply prerequisite screens (e.g., "Device is paired" implies a pairing completion screen exists)
- If use case files contain screen references, cross-reference them with the derived screen list
- Merge use case screens with product concept screens: product concept provides broad strokes (interaction modes, administrative functions), use cases provide fine-grained states and flows. For each use case, check if its steps map to existing screens. If yes, enrich those screens with state-specific views. If no, add new screens.

**User journeys:** Derive from use cases (preferred) or product concept user flows:
- If use cases exist: each user-goal level use case maps directly to a user journey. The main success scenario steps become the journey steps. Extensions become alternate journey paths or error scenarios to test.
- If no use cases: extract from user flows in the product concept. Each primary user goal becomes a journey.
- Read the journey template for structure:
  > Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-clickable-prototype/references/journey-template.md`

Propose the screen list and journeys:

"Based on your product concept, here are the screens and user journeys:

**Screens** (grouped by area):
| Area | # | Screen | Description | Links To |
|------|---|--------|-------------|----------|
| [area] | 1 | [Name] | [description] | Screens 2, 3 |
| ... | ... | ... | ... | ... |

**Navigation flow:**
```
[Hub] --> [Area 1: Screen 1] --> [Screen 2] --> [Screen 3]
  |
  +--> [Area 2: Screen 4] --> [Screen 5]
```

**User Journeys:**
| # | Journey | Steps | Goal |
|---|---------|-------|------|
| 1 | [Name] | [count] | [what the user accomplishes] |
| ... | ... | ... | ... |

Adjust screens, navigation, or journeys before I proceed."

Wait for user confirmation or adjustments.

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
- `/arn-spark-clickable-prototype` (no debate): 2 expert invocations per cycle
- This skill (divergence mode): 2-4 expert invocations per cycle (2 if no divergence, 4 if divergence detected)
- This skill (standard mode): 3-4 expert invocations per cycle (always full debate)

**Criteria:** Based on your screens and journeys, here are the proposed criteria:

| # | Criterion | Description |
|---|-----------|-------------|
| 1 | [criterion] | [description] |
| ... | ... | ... |

Adjust any parameter, debate mode, or criterion, or confirm to proceed."

To propose criteria:
1. Read the default criteria template:
   > Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-clickable-prototype/references/clickable-prototype-criteria.md`
2. Adapt based on the screen list and journeys (add journey-specific criteria, remove inapplicable ones)
3. Incorporate relevant items from these additional categories if not already covered: screen completeness, navigation, visual style consistency, component library usage, content quality, responsive considerations, and build/run verification
4. Present the adapted list

Check `arn-spark-ux-specialist` availability by attempting to invoke it with a minimal prompt (e.g., "Respond with OK to confirm availability"). If the agent is not found or the invocation fails, record single-reviewer mode and inform the user:

"UX specialist is not available. Review will be strategist-only (no debate). Consider `/arn-spark-clickable-prototype` which handles single-reviewer mode identically with lower overhead."

Present the full configuration summary:

"**Configuration summary:**
- **Debate mode:** [Divergence / Standard]
- **Execution mode:** [Agent Teams / Sequential / Single-reviewer]
- **Reviewers:** arn-spark-product-strategist + arn-spark-ux-specialist [/ arn-spark-product-strategist only]
- **Scale:** [1-N], **Threshold:** [T], **Max cycles:** [M]
- **Criteria:** [count] criteria
- **Journeys:** [count] journeys

Confirm to proceed."

When the user confirms, write the agreed criteria to `prototypes/criteria.md` (create `prototypes/` directory if needed). If the file already exists from a static prototype run, ask whether to reuse, merge, or replace.

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
- **Screen list:** with descriptions and navigation flow
- **Style brief:** toolkit configuration section
- **UI framework and component library:** from architecture vision or the project's dependency configuration
- **Project root path**
- **Output path:** `prototypes/clickable/v[N]/app/`
- **Reference images (if available):** visual grounding assets
- **Previous review feedback (if not first cycle):** failing criteria details, journey failure evidence, debate insights, and improvement suggestions from the previous cycle's debate review report

Mark the Build task as in_progress before invoking, completed after.

#### 5b: Interaction Testing

Start the prototype so it can be interacted with:
1. Determine how to run the prototype from the project configuration (e.g., a dev server command, an application launcher, a build-and-open step -- whatever the framework requires)
2. Start the prototype in the background via Bash
3. Wait for it to be ready (e.g., poll a URL for web-based prototypes, wait for the process to report ready)
4. Note the process ID for cleanup

Then invoke the `arn-spark-ui-interactor` agent with:
- **Prototype URL or access point:** how to reach the running prototype (e.g., a URL for web-based, or launch instructions for native)
- **User journey definitions:** the journeys agreed in Step 2b/Step 3
- **Output path:** `prototypes/clickable/v[N]/journeys/`

If Playwright is unavailable, inform the user and ask them to manually walk through the journeys and provide screenshots. Note the limitation in the review report.

After the interactor completes, stop the prototype (kill the background process).

#### 5c: Expert Debate Review

This step replaces the mechanical lower-of-two scoring in `/arn-spark-clickable-prototype` with a structured expert debate.

1. Read the debate protocol:
   > Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-clickable-prototype-teams/references/debate-protocol.md`

2. Create the `prototypes/clickable/reviews/` directory if it does not exist.

**Phase 1: Independent Scoring**

Both experts independently score all criteria and write structured feedback to files.

**If execution_mode is "agent_teams":**

Spawn both experts simultaneously as teammates. Each receives:
- Journey screenshots from Step 5b
- Interaction report from `arn-spark-ui-interactor`
- Criteria list from `prototypes/criteria.md`
- Scoring scale and minimum threshold
- Style brief (full document)
- Product concept (full document)
- Visual grounding assets (with category context: references=inspirational direction, designs=specification targets, brand=constraints)
- Expert interaction review template path: `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-clickable-prototype-teams/references/expert-interaction-review-template.md`
- File path to write to:
  - Product strategist -> `prototypes/clickable/reviews/round-N-strategist-review.md`
  - UX specialist -> `prototypes/clickable/reviews/round-N-ux-review.md`
- Instruction: "Score every criterion independently against the journey screenshots and interaction report. Assess every journey for completability. Write your complete review to the specified file path using the expert interaction review template. Do not communicate with other teammates during this phase. Return a brief summary in conversation."

**Verify Agent Teams actually worked:** After Phase 1 completes, check that BOTH review files exist and contain per-criterion scores. If only one expert wrote its file (potential Agent Teams failure), note the issue, invoke the missing expert sequentially, and log in the debate report: "Agent Teams Phase 1 partial failure: [agent] did not produce its review file. Invoked sequentially as fallback."

**If execution_mode is "sequential":**

Invocation 1: Invoke `arn-spark-product-strategist` with all inputs and file path `prototypes/clickable/reviews/round-N-strategist-review.md`.

Invocation 2: Invoke `arn-spark-ux-specialist` with all inputs and file path `prototypes/clickable/reviews/round-N-ux-review.md`.

**If single-reviewer mode:**

Invoke `arn-spark-product-strategist` only. No debate. Strategist scores become the combined scores directly (same behavior as `/arn-spark-clickable-prototype` single-reviewer). Skip Phases 2-4.

**Divergence Check:**

The skill reads both Phase 1 review files and compares per-criterion scores.

If `debate_mode` is "divergence":
- Calculate the absolute score difference for each criterion
- If ALL criteria have score difference < 2: skip Phase 2. Present to user: "Experts scored within 1 point on all criteria. No divergence detected -- skipping cross-review. Combined scores use the lower of each pair."
- If ANY criterion has score difference >= 2: trigger Phase 2. Present to user: "Divergence detected on [N] criteria (difference >= 2 points): [list criteria names with score pairs]. Triggering cross-review."

If `debate_mode` is "standard": always proceed to Phase 2.

**Phase 2: Cross-Review**

Each expert reads the other's Phase 1 file and responds per-criterion, focusing on divergent criteria. Experts also compare per-journey assessments.

**If execution_mode is "agent_teams":**

Through Teams communication, instruct each expert:
- Product strategist: Read `prototypes/clickable/reviews/round-N-ux-review.md`, write cross-review to `prototypes/clickable/reviews/round-N-strategist-cross-review.md`
- UX specialist: Read `prototypes/clickable/reviews/round-N-strategist-review.md`, write cross-review to `prototypes/clickable/reviews/round-N-ux-cross-review.md`

Each responds per-criterion and per-journey using the Phase 2 format from the expert interaction review template: Agree (optionally adjust score), Disagree (counter-evidence), or New concern.

**If execution_mode is "sequential":**

This follows the 3-invocation sequential pattern. Since Phase 1 already completed with 2 invocations, Phase 2 requires 1 additional invocation for the UX specialist's cross-review (already combined in Invocation 2 of the sequential pattern) and 1 invocation for the strategist's cross-review.

The full sequential pattern runs as 3 total invocations across Phase 1 and Phase 2:

Invocation 1: Strategist Phase 1 (writes `round-N-strategist-review.md`)

Invocation 2: UX specialist Phase 1 + Phase 2 combined (reads strategist file, writes `round-N-ux-review.md` with both sections)

Invocation 3: Strategist Phase 2 (reads UX specialist file, writes `round-N-strategist-cross-review.md`)

If Phase 2 was skipped (divergence mode, no divergence): only Invocations 1 and 2 (Phase 1 only) run. Invocation 2 does NOT include Phase 2 instructions in this case. Total: 2 invocations.

**Phase 3: Synthesis**

The skill reads all review files written by the experts (never from conversation context):
- `prototypes/clickable/reviews/round-N-strategist-review.md` (Phase 1)
- `prototypes/clickable/reviews/round-N-ux-review.md` (Phase 1, or Phase 1 + Phase 2 combined in sequential mode)
- `prototypes/clickable/reviews/round-N-strategist-cross-review.md` (Phase 2, if written)
- `prototypes/clickable/reviews/round-N-ux-cross-review.md` (Phase 2, Agent Teams mode only, if written)

For each criterion, categorize:

- **Consensus:** Both experts scored the same, or one adjusted their score in cross-review to match. Combined score = the agreed score.
- **Additions:** One expert scored lower with specific feedback, the other did not dispute. Combined score = the lower score.
- **Disagreements:** Both experts maintained different scores after cross-review. Combined score = deferred to Phase 4 for user resolution.
- **No-debate:** Phase 2 was skipped. Combined score = min(strategist, ux).

Also synthesize journey assessments: if experts disagree on whether a journey completed, note the disagreement in the debate report and include it in the resolution step if the journey outcome affects a criterion score.

Read the debate review report template:
> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-clickable-prototype-teams/references/debate-review-report-template.md`

Write the debate report to `prototypes/clickable/reviews/round-N-cycle-M-debate-report.md`.

**Phase 4: Resolution (if disagreements exist)**

For each unresolved disagreement, present to the user:

"Expert disagreement on **[Criterion Name]** (criterion #[N]):
- **Product Strategist:** Score [X] -- [reasoning and journey evidence]
- **UX Specialist:** Score [Y] -- [reasoning and journey evidence]
- **Trade-off:** [what each score optimizes for]

What score should this criterion receive? (Or provide your reasoning and I will set the score.)"

Record user decisions. Update the debate report with resolutions. The resolved score becomes the combined score for that criterion.

Mark the Debate review task as in_progress before Phase 1, completed after all phases finish.

#### 5d: Evaluate and Record

1. Check all combined scores (from debate synthesis) against the minimum threshold
2. Copy the debate report to `prototypes/clickable/v[N]/review-report.md` for version-local access
3. Write version notes to `prototypes/clickable/v[N]/version-notes.md` (what changed from previous version, or "Initial version" for v1)

**If ALL criteria pass:** Mark the Validate task as completed. Skip remaining cycles and proceed to Step 6 (Judge Review).

**If ANY criterion fails:**
- Present the failing criteria to the user with debate context (what the experts said, where they agreed/disagreed) and journey evidence
- Feed the failing criteria details, journey failure screenshots, debate insights, and improvement suggestions to the next cycle's Build step
- Proceed to the next cycle (or Step 6 if this was the last cycle)

### Step 6: Judge Review

Start the prototype for the judge's interactive review using the same procedure as Step 5b:
1. Determine how to run the prototype from the project configuration
2. Start the prototype in the background via Bash
3. Wait for it to be ready
4. Note the process ID for cleanup

If the prototype fails to start, fall back to invoking the judge in `static` mode using the journey screenshots from the latest Step 5b cycle. Note the limitation in the final report.

Once the prototype is running, invoke the `arn-spark-ux-judge` agent with:
- **Review mode:** `interactive` -- the judge navigates the prototype firsthand rather than reviewing static screenshots
- **Prototype URL or access point:** how to reach the running prototype
- **Criteria list:** from `prototypes/criteria.md`
- **Scoring scale and minimum threshold**
- **Style brief and product concept**
- **Visual grounding assets (if available):** provide all three categories with context so the judge can compare screen layouts and flow against reference images, design mockups, and brand assets during interactive navigation
- **Version number**
- **Journey definitions:** from Step 2b/Step 3 (for context, not as a script -- the judge navigates freely)
- **Previous review reports:** the latest version's review-report.md (which is the debate report)

The judge operates independently -- it provides its own scores without knowledge of the debate process. This is an independent validation gate. The judge will navigate the prototype via Playwright, experience transitions, test interactions, capture its own screenshots as evidence, and score each criterion based on firsthand experience.

After the judge completes, stop the prototype.

Write the judge's report to `prototypes/clickable/v[N]/judge-report.md`.

**If Judge returns PASS:** Proceed to Step 6b.

**If Judge returns FAIL and cycle budget remains:**
- Present the judge's failing criteria to the user
- Calculate remaining budget (original max_cycles minus cycles used)
Ask (using `AskUserQuestion`):

> **The judge flagged [N] criteria below threshold. You have [M] cycles remaining. Run more fix cycles?**
> 1. **Yes** — Run [M] more fix cycles
> 2. **No** — Proceed with current results

- If **Yes**: create new Build+Debate review task pairs for the remaining cycles, return to Step 5
- If **No**: proceed to Step 6b with the judge's report

**If Judge returns FAIL and no budget remains:** Proceed to Step 6b with the judge's report.

### Step 6b: Generate Visual Showcase

After the judge review completes, generate structured visual assets so the user can review all screens and journey flows at a glance without running the dev server.

1. Read the showcase capture guide:
   > Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-clickable-prototype/references/showcase-capture-guide.md`

2. Read the screen manifest from `prototypes/clickable/v[N]/screen-manifest.json` (written by the prototype builder). If the manifest does not exist, note the limitation and capture the hub page only.

3. Start the prototype dev server.

4. Generate a Playwright capture script following the capture guide:
   - Navigate to each screen route from the manifest
   - Capture a full-viewport screenshot per screen, grouped by functional area
   - Capture dark mode variants if the prototype has a dark/light toggle

5. Run the capture script via Bash.

6. Stop the prototype dev server.

7. Organize the journey gallery: read existing journey screenshots from `prototypes/clickable/v[N]/journeys/` (captured during Step 5b).

8. Write `prototypes/clickable/v[N]/showcase/showcase-index.md` with version, judge verdict, final scores, screen gallery, journey gallery, and embedded images.

If Playwright is unavailable, skip screen capture but still organize the journey gallery from existing screenshots. Inform the user the full prototype can be viewed by running the dev server.

### Step 7: User Review

Present the complete validation history:

"**Clickable prototype validation complete (debate mode).**

**Latest version:** v[N]
**Judge verdict:** [PASS / FAIL]
**Debate mode:** [Divergence / Standard]
**Execution mode:** [Agent Teams / Sequential / Single-reviewer]

**Version history:**
| Version | Criteria Passing | Criteria Failing | Journeys OK | Phase 2 Triggered | Notable Changes |
|---------|-----------------|------------------|-------------|-------------------|----------------|
| v1 | [X]/[M] | [Y] | [J1]/[J2] | [Yes/No] | Initial build |
| v2 | [X]/[M] | [Y] | [J1]/[J2] | [Yes/No] | [summary of fixes] |
| ... | ... | ... | ... | ... | ... |

**Final scores (v[N]):**
| # | Criterion | Strategist | UX Specialist | Combined | Category | Judge | Status |
|---|-----------|-----------|---------------|----------|----------|-------|--------|
| 1 | [name] | [score] | [score] | [score] | [Consensus/Addition/Resolved] | [score] | PASS/FAIL |
| ... | ... | ... | ... | ... | ... | ... | ... |

The prototype is at `prototypes/clickable/v[N]/app/`.
Debate reports are at `prototypes/clickable/reviews/`.
[If showcase images were generated:] Visual showcase is at `prototypes/clickable/v[N]/showcase/showcase-index.md` -- open this file to see all screens and journey flows at a glance without running the dev server.

Are you satisfied with this result, or would you like additional cycles?"

If the user wants more cycles, return to Step 3 with new parameters.

### Step 8: Write Final Report

Write `prototypes/clickable/final-report.md` with:
- Complete version history and all scores
- Debate history: per-cycle summaries including which criteria triggered cross-review, how disagreements were resolved, and how scores evolved across cycles
- Judge verdict and report (from `prototypes/clickable/v[N]/judge-report.md`)
- User decision
- Criteria and journey definitions used
- Links to all version directories and debate reports in `prototypes/clickable/reviews/`
- Link to the visual showcase (`prototypes/clickable/v[N]/showcase/showcase-index.md`) if generated

### Step 9: Recommend Next Steps

"Clickable prototype validation complete. Results saved to `prototypes/clickable/`.

Recommended next steps:
1. **Extract features:** Run `/arn-spark-feature-extract` to create a prioritized feature backlog from the product concept and prototype
2. **Start developing:** If you have the Arness Code plugin installed, run `/arn-planning` to begin the development pipeline. Arness auto-configures on first use.
3. **Start feature specs:** Run `/arn-code-feature-spec` to spec your first production feature

The prototype serves as a visual reference during feature development."

## Agent Invocation Guide

| Situation | Action |
|-----------|--------|
| Check Agent Teams (Step 1) | Run `echo $CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` via Bash. Display result. Confirm with user. |
| Build prototype screens (Step 5a) | Invoke `arn-spark-prototype-builder` with screen list, style, framework, output path, and previous debate review feedback |
| Test user journeys (Step 5b) | Start the prototype, invoke `arn-spark-ui-interactor` with access point, journeys, and output path. Stop the prototype after. |
| Expert debate -- Agent Teams Phase 1 (Step 5c) | Spawn both experts simultaneously as teammates. Each writes to own file with journey screenshots + interaction report. Verify both files exist after completion. |
| Expert debate -- Agent Teams Phase 2 (Step 5c) | Through Teams communication, tell each expert to read the other's file and write cross-review to separate file. |
| Expert debate -- Sequential (Step 5c) | (1) Strategist Phase 1, writes file. (2) UX specialist Phase 1 + Phase 2, reads strategist file, writes own file. (3) Strategist Phase 2, reads UX file, writes cross-review. |
| Expert debate -- UX unavailable (Step 5c) | Strategist only. No debate. Same as `/arn-spark-clickable-prototype` single-reviewer. Suggest base skill. |
| Divergence check (Step 5c) | Skill reads both Phase 1 files, compares per-criterion scores. If divergence mode and all diffs < 2: skip Phase 2. |
| Synthesize debate report (Step 5c) | Skill reads all expert files (not from conversation). Categorizes per criterion: consensus, addition, disagreement, no-debate. Compares per-journey assessments. Writes debate report. |
| Resolve disagreements (Step 5c Phase 4) | Present each disagreement to user with both positions, journey evidence, and trade-offs. Wait for decisions. Update report. |
| Agent Teams failure detection (Step 5c) | After Phase 1, if one expert's file is missing, invoke that expert sequentially. Log the issue in the debate report. |
| Judge review (Step 6) | Start the prototype, invoke `arn-spark-ux-judge` in `interactive` mode with prototype URL, criteria, scoring parameters, journey definitions, review reports, and visual grounding assets for comparison. Stop the prototype after. If prototype fails to start, fall back to `static` mode with journey screenshots. |
| Generate visual showcase (Step 6b) | Read shared showcase capture guide from base clickable skill. Start prototype, generate and run Playwright capture script per screen manifest, organize journey screenshots, write showcase-index.md. |
| User wants targeted screen updates | Invoke `arn-spark-prototype-builder` with specific screen changes only |
| User wants to re-test a specific journey | Invoke `arn-spark-ui-interactor` with just that journey |
| User asks about visual-only validation | Suggest `/arn-spark-static-prototype` or `/arn-spark-static-prototype-teams` for component showcase validation |
| User asks about style changes | Defer to `/arn-spark-style-explore` for style brief updates |
| User asks about features | Defer: "Feature work starts after `/arn-spark-feature-extract` and `/arn-code-feature-spec`." |
| Builder fails | Retry up to 3 times. If still failing, present the error for manual investigation. |
| Interactor reports Playwright unavailable | Fall back to manual journey testing. User walks through and provides screenshots. |
| Expert returns vague scores (all maximum, no evidence) | Re-invoke with more specific prompt requiring per-criterion evidence referencing exact journey screenshots. |

## Error Handling

- **Agent Teams not enabled:** Fall back to sequential debate mode. Inform user clearly with setup instructions and offer `/arn-spark-clickable-prototype` as lower-cost alternative.
- **Agent Teams enabled but one expert fails to write its file:** Detect the missing file after Phase 1. Invoke the missing expert sequentially. Note the issue in the debate report: "Agent Teams Phase 1 partial failure."
- **arn-spark-ux-specialist unavailable:** Single-reviewer mode. No debate, strategist reviews alone. Suggest `/arn-spark-clickable-prototype` as equivalent for single-reviewer. Note limitation in all reports.
- **No product concept found:** Proceed with user's verbal screen and journey descriptions.
- **No style brief found:** Use component library defaults. Note that `/arn-spark-style-explore` can be run for custom styling.
- **Project not scaffolded:** Cannot build prototype. Suggest `/arn-spark-scaffold` first.
- **Builder fails (3 times):** Present the error. The user can investigate manually or adjust the approach.
- **Playwright unavailable for interaction testing:** Fall back to manual testing. User walks through journeys and provides screenshots. The skill continues without automated interaction capture. The visual showcase (Step 6b) screen capture is also skipped.
- **Prototype fails to start (Step 5b):** Check for port conflicts, build errors, missing dependencies. Present the error.
- **Prototype fails to start (Step 6 judge review):** Fall back to invoking the judge in `static` mode using journey screenshots from the latest interaction testing cycle. Note the limitation in the final report.
- **Journey interaction fails (3 consecutive):** The interactor abandons the journey. Note it in the review. The expert reviewers assess based on available screenshots.
- **Playwright unavailable for showcase (Step 6b):** Skip screen capture. Journey screenshots from interaction testing are still organized into the showcase index. Inform the user the full prototype can be viewed by running the dev server.
- **Screen manifest missing (Step 6b):** The builder did not write `screen-manifest.json`. Capture the hub page only. Note: "Screen manifest not found. Only hub capture produced. Re-build the prototype to generate per-screen captures."
- **Expert returns unhelpful scores (vague, all maximum, etc.):** Re-invoke with a more specific prompt asking for scores on each criterion individually with evidence.
- **Judge unavailable:** The user becomes the judge. Present all debate review reports and ask the user to make the pass/fail decision.
- **Resume from interrupted cycle:** Detect the latest version directory. If it has a review-report.md, the cycle completed -- continue from the next cycle. If it has app files but no review-report.md, the build completed but review did not -- run review on the existing build.
- **Criteria file already exists:**

  Ask (using `AskUserQuestion`):

  > **Existing criteria found at `prototypes/criteria.md`. What would you like to do?**
  > 1. **Reuse** — Use existing criteria as-is
  > 2. **Merge** — Combine existing with clickable-specific criteria
  > 3. **Define new** — Create fresh criteria from scratch
- **Too many screens (>10-12):** Suggest prioritizing core screens for initial cycles. Secondary screens can be added in follow-up.
- **Writing review files fails:** Print the full content in the conversation so the user can copy it.
- **User cancels mid-process:** Inform user of partial files in `prototypes/clickable/` and debate reports in `prototypes/clickable/reviews/`. These can be cleaned up manually.
