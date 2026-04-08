---
name: arn-spark-static-prototype
description: >-
  This skill should be used when the user says "static prototype", "arn static
  prototype", "visual validation", "pixel perfect", "component showcase",
  "static screens", "build a static prototype", "create a component showcase",
  "visual review", "validate the visuals", "check the design",
  "validate components", "review the design visuals", or wants to create a static component showcase and
  validate it through iterative expert review cycles with per-criterion scoring,
  an independent judge verdict, and versioned output.
version: 1.0.0
---

# Arness Static Prototype

Create a static component showcase and validate it through iterative build-review cycles, aided by the `arn-spark-prototype-builder` agent (in showcase mode) for rendering, the `arn-spark-style-capture` agent for screenshots, `arn-spark-product-strategist` and `arn-spark-ux-specialist` (greenfield agents in this plugin) for expert review, and the `arn-spark-ux-judge` agent for an independent final verdict. This is a conversational skill that runs in normal conversation (NOT plan mode).

The primary artifacts are **versioned showcase pages** with component renders, **review reports** with per-criterion scores, and a **final report** documenting the complete validation history. All output is versioned so the user can compare evolution across cycles.

This skill covers visual fidelity validation: do the components look correct according to the style brief? It does not cover interactive behavior -- that is `/arn-spark-clickable-prototype`'s job.

## Prerequisites

The following artifacts inform the validation. Check in order:

Determine the prototypes output directory:
1. Read the project's `CLAUDE.md` and check for a `## Arness` section
2. If found, extract the configured Prototypes directory path — this is the source of truth
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

   - If **Yes**: ask the user to specify which assets to fetch (Figma file URL, page, or frame names / Canva design URL). Use the corresponding MCP to fetch and save to `[visual-grounding]/designs/` or `[visual-grounding]/brand/`. Show a summary of what was downloaded or replaced.
   - If no: proceed with existing assets on disk.
3. If either is `yes` but NO existing design assets found in `designs/` or `brand/`:
   Ask (using `AskUserQuestion`):

   > **No design mockups found yet. Would you like to pull design assets from [Figma/Canva]?**
   > 1. **Yes** — Pull design assets now
   > 2. **No** — Proceed without design mockups

   - If **Yes**: same flow as above.
   - If **No**: proceed without design mockups.
4. If neither flag is `yes` or flags are missing: skip silently.

**If a style brief is found:** Use it for visual validation criteria.

**If no style brief is found:** Inform the user: "No style brief found. I can create a component showcase with default styling, but visual validation is more meaningful with a style brief. Consider running `/arn-spark-style-explore` first." Proceed if the user wants to continue -- criteria will focus on component quality and layout rather than style fidelity.

**Project scaffold:** The project must be scaffolded with the UI framework and component library installed. Check the project's dependency configuration. If not scaffolded, inform the user: "The project needs to be scaffolded before building a component showcase. Run `/arn-spark-scaffold` first."

## Workflow

### Step 1: Detect Resume or Fresh Start

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

**If no existing versions:** Proceed to Step 2.

### Step 2: Configure Validation Parameters

Present defaults and ask the user to confirm or adjust:

"Let me set up the validation parameters:

**Scoring:**
- **Scale:** 1-5 (1 = unmet, 5 = exemplary)
- **Minimum threshold:** 4 (every criterion must score at least 4)
- **Max cycles:** 3 (build-review iterations before judge review)

**Criteria:** Based on your style brief and product concept, here are the proposed criteria:

| # | Criterion | Description |
|---|-----------|-------------|
| 1 | [criterion] | [description] |
| ... | ... | ... |

Adjust any parameter or criterion, or confirm to proceed."

To propose criteria:
1. Read the default criteria template:
   > Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-static-prototype/references/static-prototype-criteria.md`
2. Adapt based on available artifacts (remove dark mode criterion if not applicable, add reference image criterion if images exist, etc.)
3. Present the adapted list

When the user confirms, write the agreed criteria to `prototypes/criteria.md` (create `prototypes/` directory if needed).

### Step 3: Create Task List

Create the task structure for the validation run. For max_cycles=N:

- Task pairs: Build v[X] + Validate v[X] for each cycle (2 tasks per cycle)
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
- **Showcase mode:** true
- **Style brief:** toolkit configuration section
- **Component list:** components from the criteria + style brief
- **UI framework and component library:** from architecture vision or the project's dependency configuration
- **Project root path**
- **Output path:** `prototypes/static/v[N]/`
- **Reference images (if available):** captured screenshots or user-provided images
- **Previous review feedback (if not first cycle):** failing criteria details and improvement suggestions from the previous cycle's review report
- **Showcase expectations:** The builder should produce numbered sections showing each component with all variants, all states, contextual usage (components in realistic surroundings, not just isolation), working interactive elements (toggles that toggle, inputs that accept text), and a simulated environment background appropriate to the application type. If the style brief includes dark mode, the showcase should have an inline dark/light toggle.

Mark the Build task as in_progress before invoking, completed after.

#### 4b: Capture Screenshots

Invoke the `arn-spark-style-capture` agent with:
- **URL:** the URL serving the showcase (from the running prototype)
- **Output path:** `prototypes/static/v[N]/screenshots/`

If Playwright is unavailable, ask the user to provide screenshots of the showcase manually, or attempt to serve the showcase and capture screenshots through an alternative method. Note the limitation in the review report.

#### 4c: Expert Review

Invoke `arn-spark-product-strategist` and `arn-spark-ux-specialist` in parallel. Both agents receive the same inputs:

- Screenshots, criteria list, scoring scale, threshold, style brief, product concept
- If visual grounding assets are available, include them with category context:
  - **References:** "These are inspirational references. Assess whether the overall direction aligns."
  - **Designs:** "These are design mockups (specification). Assess fidelity — how closely does the showcase match these designs?"
  - **Brand:** "These are brand constraints. Verify brand elements (logos, colors, typefaces) are correctly applied."
- Request per-criterion scores and feedback from each agent.

After both agents complete:

For each criterion, use the LOWER of the two expert scores as the combined score. If only one expert is available (e.g., `arn-spark-ux-specialist` is not accessible), use that single expert's scores as the combined scores and note the limitation in the review report.

#### 4d: Evaluate and Record

1. Check all combined scores against the minimum threshold
2. Read the review report template:
   > Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-static-prototype/references/review-report-template.md`
3. Write the review report to `prototypes/static/v[N]/review-report.md`
4. Write version notes to `prototypes/static/v[N]/version-notes.md` (what changed from previous version, or "Initial version" for v1)

**If ALL criteria pass:** Mark the Validate task as completed. Skip remaining cycles and proceed to Step 5 (Judge Review).

**If ANY criterion fails:**
- Mark the Validate task as completed
- Present the failing criteria to the user with a brief summary
- Feed the failing criteria details and improvement suggestions to the next cycle's Build step
- Proceed to the next cycle (or Step 5 if this was the last cycle)

### Step 5: Judge Review

Invoke the `arn-spark-ux-judge` agent with:
- **Review mode:** `static` -- the judge reviews screenshots and files (there is nothing interactive to navigate in a static showcase)
- **Prototype artifacts:** paths to the latest version's showcase files and screenshots
- **Criteria list:** from `prototypes/criteria.md`
- **Scoring scale and minimum threshold**
- **Style brief and product concept**
- **Visual grounding assets (if available):** provide all three categories with context so the judge can compare the showcase against reference images, design mockups, and brand assets directly
- **Version number**
- **Previous review reports:** the latest version's review-report.md

Write the judge's report to `prototypes/static/v[N]/judge-report.md`.

**If Judge returns PASS:** Proceed to Step 6.

**If Judge returns FAIL and cycle budget remains:**
- Present the judge's failing criteria to the user
- Calculate remaining budget (original max_cycles minus cycles used)
Ask (using `AskUserQuestion`):

> **The judge flagged [N] criteria below threshold. You have [M] cycles remaining. Run more fix cycles?**
> 1. **Yes** — Run [M] more fix cycles
> 2. **No** — Proceed with current results

- If **Yes**: create new Build+Validate task pairs for the remaining cycles, return to Step 4
- If **No**: proceed to Step 6 with the judge's report

**If Judge returns FAIL and no budget remains:** Proceed to Step 5b with the judge's report.

### Step 5b: Generate Visual Showcase

After the judge review completes (whether PASS or FAIL with no budget), generate structured screenshot images so the user can review the final visual state without running a dev server. This is the user's primary visual deliverable.

1. Read the showcase capture guide:
   > Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-static-prototype/references/showcase-capture-guide.md`

2. Read the section manifest from `prototypes/static/v[N]/showcase-manifest.json` (written by the prototype builder). If the manifest does not exist, note the limitation and capture a single full-page screenshot only.

3. Start the prototype dev server (same procedure as Step 4b).

4. Generate a Playwright capture script appropriate to the project's stack. The script captures:
   - A full-page scrolling screenshot (`showcase-full.png`)
   - A per-section screenshot for each entry in the manifest (e.g., `01-typography.png`, `04-buttons.png`)
   - Dark mode variants of all captures if the showcase has a dark/light toggle

   Write the script to `prototypes/static/v[N]/showcase/capture-script.js` so the user can re-run it.

5. Run the capture script. If individual section captures fail, skip them and note the gaps.

6. Stop the prototype dev server.

7. Write `prototypes/static/v[N]/showcase/showcase-index.md` — a self-contained markdown document embedding all captured images with:
   - Version number, judge verdict, and generation date
   - Final criterion scores summary
   - Each section's screenshot with its title as a heading
   - Full-page overview
   - Dark mode section (if applicable)

If Playwright is unavailable, skip this step entirely and inform the user: "Playwright is not available. The showcase can be viewed by running the dev server. Automated visual export was skipped."

### Step 6: User Review

Present the complete validation history:

"**Static prototype validation complete.**

**Latest version:** v[N]
**Judge verdict:** [PASS / FAIL]

**Version history:**
| Version | Criteria Passing | Criteria Failing | Notable Changes |
|---------|-----------------|------------------|----------------|
| v1 | [X]/[M] | [Y] | Initial build |
| v2 | [X]/[M] | [Y] | [summary of fixes] |
| ... | ... | ... | ... |

**Final scores (v[N]):**
| # | Criterion | Expert Score | Judge Score | Status |
|---|-----------|-------------|-------------|--------|
| 1 | [name] | [score] | [score] | PASS/FAIL |
| ... | ... | ... | ... | ... |

The showcase is at `prototypes/static/v[N]/`.
[If showcase images were generated:] Visual showcase images are at `prototypes/static/v[N]/showcase/showcase-index.md` — open this file to see all components at a glance without running the dev server.

Ask (using `AskUserQuestion`):

> **Are you satisfied with this result?**
> 1. **Yes, finalize** — Write the final report
> 2. **Run additional cycles** — Return to Step 2 with new parameters"

If the user chooses **Run additional cycles**, return to Step 2 with new parameters (the user can adjust criteria, threshold, or cycle count).

### Step 7: Write Final Report

Write `prototypes/static/final-report.md` with:
- Complete version history and all scores
- Judge verdict and report (from `prototypes/static/v[N]/judge-report.md`)
- User decision
- Criteria used
- Links to all version directories
- Link to the visual showcase (`prototypes/static/v[N]/showcase/showcase-index.md`) if generated

### Step 8: Recommend Next Steps

"Static prototype validation complete. Results saved to `prototypes/static/`.

Recommended next steps:
1. **Build clickable prototype:** Run `/arn-spark-clickable-prototype` to add interaction and validate user journeys
2. **Lock the prototype:** After clickable validation, run `/arn-spark-prototype-lock` to freeze a snapshot before development modifies shared source files
3. **Extract features:** Run `/arn-spark-feature-extract` to create a prioritized feature backlog

The clickable prototype will build on the validated visual direction from this static prototype."

## Agent Invocation Guide

| Situation | Action |
|-----------|--------|
| Build showcase (Step 4a) | Invoke `arn-spark-prototype-builder` in showcase mode with style brief, components, output path, and previous review feedback |
| Capture screenshots (Step 4b) | Invoke `arn-spark-style-capture` with the showcase URL and output path. If unavailable, ask the user for manual screenshots. |
| Expert review (Step 4c) | Invoke `arn-spark-product-strategist` and `arn-spark-ux-specialist` in parallel with screenshots, criteria, scoring parameters, and visual grounding assets (with category context). After both complete, take the LOWER score per criterion. |
| Judge review (Step 5) | Invoke `arn-spark-ux-judge` in `static` mode with latest screenshots, criteria, scoring parameters, review reports, and visual grounding assets for direct comparison |
| Generate visual showcase (Step 5b) | Read the showcase capture guide, start the prototype, generate and run a Playwright capture script per the section manifest, write `showcase-index.md`. Skip if Playwright unavailable. |
| User asks about interactive behavior | Defer: "Interactive behavior is validated in `/arn-spark-clickable-prototype`. This skill focuses on visual fidelity." |
| User asks to change the style | Defer to `/arn-spark-style-explore` for style brief updates, then re-run static prototype validation |
| User asks about features | Defer: "Feature work starts after `/arn-spark-feature-extract`. If Arness Code is installed, continue with `/arn-code-feature-spec` for detailed specifications." |
| Builder fails | Retry up to 3 times. If still failing, present the error for manual investigation. |
| Expert returns unhelpful scores | Re-invoke with more specific prompt referencing the exact criteria and screenshots. |

## Error Handling

- **No style brief found:** Proceed with component quality and layout criteria only. Note that visual fidelity criteria are deferred until a style brief exists.
- **Project not scaffolded:** Cannot build showcase. Suggest `/arn-spark-scaffold` first.
- **Builder fails (3 times):** Present the error. The user can investigate manually or adjust the approach.
- **Capture fails (Playwright unavailable):** Fall back to asking the user for manual screenshots. Note the limitation. The visual showcase (Step 5b) is also skipped.
- **Showcase manifest missing:** The builder did not write `showcase-manifest.json`. Capture a full-page screenshot only. Note: "Section manifest not found. Re-build the showcase to generate per-section captures."
- **Expert returns unhelpful scores (vague, all maximum, etc.):** Re-invoke with a more specific prompt asking for scores on each criterion individually with evidence.
- **arn-spark-ux-specialist unavailable:** Proceed with `arn-spark-product-strategist` as the sole expert reviewer. Use its scores directly as the combined scores. Note the limitation in the review report.
- **Judge unavailable:** The user becomes the judge. Present all expert review reports and ask the user to make the pass/fail decision.
- **Resume from interrupted cycle:** Detect the latest version directory. If it has a review-report.md, the cycle completed -- continue from the next cycle. If it has showcase files but no review-report.md, the build completed but review did not -- run review on the existing build.
- **Criteria file already exists:**

  Ask (using `AskUserQuestion`):

  > **Existing criteria found at `prototypes/criteria.md`. What would you like to do?**
  > 1. **Use existing** — Keep the current criteria
  > 2. **Define new** — Create fresh criteria for this validation
- **Writing the document fails:** Print the full content in the conversation so the user can copy it.
