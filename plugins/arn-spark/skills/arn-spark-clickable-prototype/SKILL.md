---
name: arn-spark-clickable-prototype
description: >-
  This skill should be used when the user says "clickable prototype", "arn
  clickable prototype", "interactive prototype", "test interactions", "validate
  UX", "user journeys", "test navigation", "make it clickable", "prototype
  interactions", "test the prototype", "build the screens", "create the UI",
  "screen mockups", or wants to generate a clickable interactive prototype with
  linked screens and validate it through iterative build-review cycles with
  Playwright-based interaction testing, per-criterion scoring, an independent
  judge verdict, and versioned output.
version: 1.0.0
---

# Arness Clickable Prototype

Generate a clickable interactive prototype with all main application screens linked together and validate it through iterative build-review cycles, aided by the `arn-spark-prototype-builder` agent for screen creation, the `arn-spark-ui-interactor` agent for Playwright-based interaction testing, `arn-spark-product-strategist` and `arn-spark-ux-specialist` for expert review, and the `arn-spark-ux-judge` agent for an independent final verdict. This is a conversational skill that runs in normal conversation (NOT plan mode).

The primary artifacts are **versioned clickable prototype applications**, **journey screenshots** documenting user flows, **review reports** with per-criterion scores, and a **final report** documenting the complete validation history. All output is versioned so the user can compare evolution across cycles.

This skill covers interactive behavior validation: do the screens link correctly, do interactions work, can users complete journeys? For visual-only validation of component rendering, use `/arn-spark-static-prototype` first.

## Prerequisites

The following artifacts inform the prototype. Check in order:

Determine the prototypes output directory:
1. Read the project's `CLAUDE.md` and check for a `## Arness` section
2. If found, extract the configured Prototypes directory path — this is the source of truth
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

**If use cases are found:** Read the README index and all use case files. Use them alongside the product concept for richer screen and journey derivation (see Step 1b).

**If no use cases are found:** Derive screens and journeys from the product concept alone. Note: "No use cases found. Screen derivation will use the product concept directly. Run `/arn-spark-use-cases` first for richer screen derivation from structured behavioral specs."

**If a product concept is found:** Use it to derive the screen list and user journeys.

**If no product concept is found:** Ask the user to describe the screens and journeys: "No product concept found. Describe the main screens of your application and the key user flows, and I will create the prototype from your description."

**If a style brief is found:** Apply the visual style to all screens.

**If no style brief is found:** Use sensible defaults for the installed component library. Note: "No style brief found. The prototype will use default styling. Run `/arn-spark-style-explore` first for a custom visual direction."

**Project scaffold:** The project must be scaffolded with the UI framework and component library installed. If not, inform the user: "The project needs to be scaffolded before building a prototype. Run `/arn-spark-scaffold` first."

## Workflow

### Step 1: Detect Resume or Fresh Start

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

**If no existing versions:** Proceed to Step 1b.

### Step 1b: Derive Screen List and User Journeys

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

### Step 2: Configure Validation Parameters

Present defaults and ask the user to confirm or adjust:

"Let me set up the validation parameters:

**Scoring:**
- **Scale:** 1-5 (1 = unmet, 5 = exemplary)
- **Minimum threshold:** 4 (every criterion must score at least 4)
- **Max cycles:** 3 (build-review iterations before judge review)

**Criteria:** Based on your screens and journeys, here are the proposed criteria:

| # | Criterion | Description |
|---|-----------|-------------|
| 1 | [criterion] | [description] |
| ... | ... | ... |

Adjust any parameter or criterion, or confirm to proceed."

To propose criteria:
1. Read the default criteria template:
   > Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-clickable-prototype/references/clickable-prototype-criteria.md`
2. Adapt based on the screen list and journeys (add journey-specific criteria, remove inapplicable ones)
3. Incorporate relevant items from these additional categories if not already covered: screen completeness, navigation, visual style consistency, component library usage, content quality, responsive considerations, and build/run verification
4. Present the adapted list

When the user confirms, write the agreed criteria to `prototypes/criteria.md` (create `prototypes/` directory if needed). If the file already exists from a static prototype run:

Ask (using `AskUserQuestion`):

> **Criteria file already exists from the static prototype. What would you like to do?**
> 1. **Reuse** — Use existing criteria as-is
> 2. **Merge** — Combine existing with clickable-specific criteria
> 3. **Replace** — Define new criteria from scratch

### Step 3: Create Task List

Create the task structure for the validation run. For max_cycles=N:

- Task pairs: Build v[X] + Validate v[X] for each cycle
- Judge review task
- User review task

Example for max_cycles=3 (starting from v1):
```
Task 1:  Build v1
Task 2:  Validate v1
Task 3:  Build v2
Task 4:  Validate v2
Task 5:  Build v3
Task 6:  Validate v3
Task 7:  Judge review
Task 8:  User review
```

If resuming from v[N], number versions sequentially from v[N+1].

Present the task list to the user and proceed.

### Step 4: Build-Review Cycle (Iterative)

For each cycle:

#### 4a: Build

Invoke the `arn-spark-prototype-builder` agent with:
- **Screen list:** with descriptions and navigation flow
- **Style brief:** toolkit configuration section
- **UI framework and component library:** from architecture vision or the project's dependency configuration
- **Project root path**
- **Output path:** `prototypes/clickable/v[N]/app/`
- **Reference images (if available):** captured screenshots or user-provided images
- **Previous review feedback (if not first cycle):** failing criteria details, journey failure evidence, and improvement suggestions from the previous cycle's review report
- **Animation specs (if style brief has Animation and Motion section):** Pass the full Animation and Motion section from the style brief. Instruct the builder: "Implement all specified animations. The prototype must demonstrate the motion experience, not just the static layout."

Mark the Build task as in_progress before invoking, completed after.

#### 4b: Interaction Testing

Start the prototype so it can be interacted with:
1. Determine how to run the prototype from the project configuration (e.g., a dev server command, an application launcher, a build-and-open step -- whatever the framework requires)
2. Start the prototype in the background via Bash
3. Wait for it to be ready (e.g., poll a URL for web-based prototypes, wait for the process to report ready)
4. Note the process ID for cleanup

Then invoke the `arn-spark-ui-interactor` agent with:
- **Prototype URL or access point:** how to reach the running prototype (e.g., a URL for web-based, or launch instructions for native)
- **User journey definitions:** the journeys agreed in Step 1b/Step 2
- **Output path:** `prototypes/clickable/v[N]/journeys/`

If Playwright is unavailable, inform the user and ask them to manually walk through the journeys and provide screenshots. Note the limitation in the review report.

After the interactor completes, stop the prototype (kill the background process).

#### 4c: Expert Review

Invoke `arn-spark-product-strategist` and `arn-spark-ux-specialist` in parallel. Both agents receive the same inputs:

- Journey screenshots, criteria list, scoring scale, threshold, style brief, product concept, and the interaction report
- If visual grounding assets are available, include them with category context:
  - **References:** "These are inspirational references. Assess whether the screen layouts and overall flow feel align with the reference direction."
  - **Designs:** "These are design mockups (specification). Assess whether screen layouts match the design mockups in structure, component placement, and flow."
  - **Brand:** "These are brand constraints. Verify brand elements appear correctly across all screens."
- **Animation reference (if style brief has Animation and Motion section):** Pass the style brief's Animation and Motion section so reviewers can compare animation implementation against specification.
- Request per-criterion scores and feedback from each agent.

After both agents complete:

For each criterion, use the LOWER of the two expert scores as the combined score. If only one expert is available (e.g., `arn-spark-ux-specialist` is not accessible), use that single expert's scores as the combined scores and note the limitation in the review report.

#### 4d: Evaluate and Record

1. Check all combined scores against the minimum threshold
2. Read the review report template:
   > Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-clickable-prototype/references/review-report-template.md`
3. Write the review report to `prototypes/clickable/v[N]/review-report.md`
4. Write version notes to `prototypes/clickable/v[N]/version-notes.md`

**If ALL criteria pass:** Mark the Validate task as completed. Skip remaining cycles and proceed to Step 5 (Judge Review).

**If ANY criterion fails:**
- Mark the Validate task as completed
- Present the failing criteria with journey evidence to the user
- Feed the failing criteria details, journey failure screenshots, and improvement suggestions to the next cycle's Build step
- Proceed to the next cycle (or Step 5 if this was the last cycle)

### Step 5: Judge Review

Start the prototype for the judge's interactive review using the same procedure as Step 4b:
1. Determine how to run the prototype from the project configuration
2. Start the prototype in the background via Bash
3. Wait for it to be ready
4. Note the process ID for cleanup

If the prototype fails to start, fall back to invoking the judge in `static` mode using the journey screenshots from the latest Step 4b cycle. Note the limitation in the final report.

Once the prototype is running, invoke the `arn-spark-ux-judge` agent with:
- **Review mode:** `interactive` -- the judge navigates the prototype firsthand rather than reviewing static screenshots
- **Prototype URL or access point:** how to reach the running prototype
- **Criteria list:** from `prototypes/criteria.md`
- **Scoring scale and minimum threshold**
- **Style brief and product concept**
- **Visual grounding assets (if available):** provide all three categories with context so the judge can compare screen layouts and flow against reference images, design mockups, and brand assets during interactive navigation
- **Version number**
- **Journey definitions:** from Step 1b/Step 2 (for context, not as a script -- the judge navigates freely)
- **Previous review reports:** the latest version's review-report.md

The judge will navigate the prototype via Playwright, experience transitions, test interactions, capture its own screenshots as evidence, and score each criterion based on firsthand experience. After the judge completes, stop the prototype.

Write the judge's report to `prototypes/clickable/v[N]/judge-report.md`.

**If Judge returns PASS:** Proceed to Step 5b.

**If Judge returns FAIL and cycle budget remains:**
- Present the judge's failing criteria to the user
- Calculate remaining budget
Ask (using `AskUserQuestion`):

> **The judge flagged [N] criteria below threshold. You have [M] cycles remaining. Run more fix cycles?**
> 1. **Yes** — Run [M] more fix cycles
> 2. **No** — Proceed with current results

- If **Yes**: create new Build+Validate task pairs, return to Step 4
- If **No**: proceed to Step 5b with the judge's report

**If Judge returns FAIL and no budget remains:** Proceed to Step 5b with the judge's report.

### Step 5b: Generate Visual Showcase

Generate structured visual assets so the user can review all screens and journey flows at a glance without running the dev server.

1. Read the showcase capture guide:
   > Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-clickable-prototype/references/showcase-capture-guide.md`

2. Read the screen manifest from `prototypes/clickable/v[N]/screen-manifest.json` (written by the prototype builder). If the manifest does not exist, note the limitation and capture the hub page only.

3. Start the prototype dev server using the same procedure as Step 4b.

4. Generate a Playwright capture script following the capture guide:
   - Navigate to each screen route from the manifest
   - Capture a full-viewport screenshot per screen, grouped by functional area
   - Capture dark mode variants if the prototype has a dark/light toggle
   - Save per-screen screenshots to `prototypes/clickable/v[N]/showcase/screens/`

   Write the script to `prototypes/clickable/v[N]/showcase/capture-script.js` so the user can re-run it.

5. Run the capture script via Bash.

6. Stop the prototype dev server.

7. Organize the journey gallery: read existing journey screenshots from `prototypes/clickable/v[N]/journeys/` (captured during Step 4b). These are referenced in the showcase index, not copied.

8. Write `prototypes/clickable/v[N]/showcase/showcase-index.md` — a self-contained markdown document with:
   - Version, judge verdict, date, screen count, journey count
   - Scores summary table
   - **Screen Gallery:** all screens grouped by functional area, each with embedded image
   - **Journey Gallery:** each journey as a visual sequence with step labels, screenshots, and outcomes
   - Dark mode section (if applicable)

If Playwright is unavailable, skip screen capture but still organize the journey gallery from existing screenshots. Inform the user: "Playwright is not available for screen capture. Journey screenshots from interaction testing are included. The full prototype can be viewed by running the dev server."

### Step 6: User Review

Present the complete validation history:

"**Clickable prototype validation complete.**

**Latest version:** v[N]
**Judge verdict:** [PASS / FAIL]

**Version history:**
| Version | Criteria Passing | Criteria Failing | Journeys OK | Notable Changes |
|---------|-----------------|------------------|-------------|----------------|
| v1 | [X]/[M] | [Y] | [J1]/[J2] | Initial build |
| v2 | [X]/[M] | [Y] | [J1]/[J2] | [summary of fixes] |
| ... | ... | ... | ... | ... |

**Final scores (v[N]):**
| # | Criterion | Expert Score | Judge Score | Status |
|---|-----------|-------------|-------------|--------|
| 1 | [name] | [score] | [score] | PASS/FAIL |
| ... | ... | ... | ... | ... |

The prototype is at `prototypes/clickable/v[N]/app/`.
[If showcase images were generated:] Visual showcase is at `prototypes/clickable/v[N]/showcase/showcase-index.md` — open this file to see all screens and journey flows at a glance without running the dev server.

Ask (using `AskUserQuestion`):

> **Are you satisfied with this result?**
> 1. **Yes, finalize** — Write the final report
> 2. **Run additional cycles** — Return to Step 2 with new parameters"

If the user chooses **Run additional cycles**, return to Step 2 with new parameters.

### Step 7: Write Final Report

Write `prototypes/clickable/final-report.md` with:
- Complete version history and all scores
- Judge verdict and report (from `prototypes/clickable/v[N]/judge-report.md`)
- User decision
- Criteria and journey definitions used
- Links to all version directories
- Link to the visual showcase (`prototypes/clickable/v[N]/showcase/showcase-index.md`) if generated

### Step 8: Recommend Next Steps

"Clickable prototype validation complete. Results saved to `prototypes/clickable/`.

Recommended next steps:
1. **Lock the prototype:** Run `/arn-spark-prototype-lock` to freeze a snapshot of the validated prototype before development modifies shared source files
2. **Set up dev environment:** Run `/arn-spark-dev-setup` to configure the development environment
3. **Define visual testing:** Run `/arn-spark-visual-strategy` to set up visual regression testing against the prototype
4. **Extract features:** Run `/arn-spark-feature-extract` to create a prioritized feature backlog from the product concept and prototype

The prototype serves as a visual reference during feature development. Locking it first ensures the reference is preserved even as production code evolves."

## Agent Invocation Guide

| Situation | Action |
|-----------|--------|
| Build prototype screens (Step 4a) | Invoke `arn-spark-prototype-builder` with screen list, style, framework, output path, and previous review feedback |
| Test user journeys (Step 4b) | Start the prototype, invoke `arn-spark-ui-interactor` with access point, journeys, and output path. Stop the prototype after. |
| Expert review (Step 4c) | Invoke `arn-spark-product-strategist` and `arn-spark-ux-specialist` in parallel with journey screenshots, criteria, scoring parameters, and visual grounding assets (with category context). After both complete, take the LOWER score per criterion. |
| Judge review (Step 5) | Start the prototype, invoke `arn-spark-ux-judge` in `interactive` mode with prototype URL, criteria, scoring parameters, journey definitions, review reports, and visual grounding assets for comparison. Stop the prototype after. If prototype fails to start, fall back to `static` mode with journey screenshots. |
| Generate visual showcase (Step 5b) | Read the showcase capture guide, start the prototype, generate and run a Playwright capture script per the screen manifest, organize journey screenshots, write `showcase-index.md`. Skip screen capture if Playwright unavailable. |
| User wants targeted screen updates | Invoke `arn-spark-prototype-builder` with specific screen changes only |
| User wants to re-test a specific journey | Invoke `arn-spark-ui-interactor` with just that journey |
| User asks about visual-only validation | Suggest `/arn-spark-static-prototype` for component showcase validation |
| User asks about style changes | Defer to `/arn-spark-style-explore` for style brief updates |
| User asks about features | Defer: "Feature work starts after `/arn-spark-feature-extract`. If Arness Code is installed, continue with `/arn-code-feature-spec` for detailed specifications." |
| Builder fails | Retry up to 3 times. If still failing, present the error for manual investigation. |
| Interactor reports Playwright unavailable | Fall back to manual journey testing. User walks through and provides screenshots. |
| Expert returns unhelpful scores | Re-invoke with more specific prompt referencing exact criteria and journey screenshots. |

## Error Handling

- **No product concept found:** Proceed with user's verbal screen and journey descriptions.
- **No style brief found:** Use component library defaults. Note that `/arn-spark-style-explore` can be run for custom styling.
- **Project not scaffolded:** Cannot build prototype. Suggest `/arn-spark-scaffold` first.
- **Builder fails (3 times):** Present the error for manual investigation.
- **Playwright unavailable for interaction testing:** Fall back to manual testing. User walks through journeys and provides screenshots. The skill continues without automated interaction capture.
- **Prototype fails to start (Step 4b):** Check for port conflicts, build errors, missing dependencies. Present the error.
- **Prototype fails to start (Step 5 judge review):** Fall back to invoking the judge in `static` mode using journey screenshots from the latest interaction testing cycle. Note the limitation in the final report.
- **Journey interaction fails (3 consecutive):** The interactor abandons the journey. Note it in the review. The expert reviewers assess based on available screenshots.
- **Expert returns unhelpful scores:** Re-invoke with more specific prompt.
- **arn-spark-ux-specialist unavailable:** Proceed with `arn-spark-product-strategist` as the sole expert reviewer. Use its scores directly as the combined scores. Note the limitation in the review report.
- **Judge unavailable:** The user becomes the judge.
- **Playwright unavailable for showcase (Step 5b):** Skip screen capture. Journey screenshots from interaction testing are still organized into the showcase index. Inform the user the full prototype can be viewed by running the dev server.
- **Screen manifest missing (Step 5b):** The builder did not write `screen-manifest.json`. Capture the hub page only. Note: "Screen manifest not found. Only hub capture produced. Re-build the prototype to generate per-screen captures."
- **Resume from interrupted cycle:** Detect the latest version directory. If it has a review-report.md, continue from the next cycle. If it has app files but no review-report.md, run review on the existing build.
- **Criteria file exists from static prototype:** Ask whether to reuse criteria, merge with clickable-specific criteria, or define new ones.
- **Too many screens (>10-12):** Suggest prioritizing core screens for initial cycles. Secondary screens can be added in follow-up.
- **Writing the document fails:** Print the full content in the conversation.
