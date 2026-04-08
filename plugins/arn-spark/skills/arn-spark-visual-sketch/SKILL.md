---
name: arn-spark-visual-sketch
description: >-
  This skill should be used when the user says "visual sketch", "arn visual sketch",
  "sketch directions", "explore visuals", "visual proposals", "try different looks",
  "design directions", "sketch the UI", "visual exploration", "compare styles",
  "show me options", "what could this look like", or wants to generate multiple
  visual direction proposals as real HTML/CSS running on the scaffolded project's
  dev server, iteratively selecting and refining until a final visual direction
  is chosen.
version: 1.0.0
---

# Arness Spark Visual Sketch

Generate visual direction proposals as real HTML/CSS in the scaffolded project, compare them side by side in the browser, and iteratively refine until a direction is selected. This is a conversational skill that runs in normal conversation (NOT plan mode). The primary artifacts are a **visual-direction.md** document in the Vision directory and **screenshot captures** of the selected direction in the visual grounding directory.

This skill sits between `/arn-spark-scaffold` and `/arn-spark-style-explore` in the greenfield pipeline. It produces a visual-direction.md that style-explore uses as primary input for detailed design token specification. The user sees what the product could look like before committing to a full design system.

The iterative process works in rounds:
1. **Round 1:** N proposals with distinct visual directions (default 3)
2. **Round 2+:** N expansions of the selected proposal with user-guided refinements
3. **Final:** The selected direction is captured and documented

Each proposal runs on the scaffold's actual dev server using the project's real CSS framework and component library.

## Prerequisites

The following artifacts inform the sketch generation. Check in order:

Determine the output directories:
1. Read the project's `CLAUDE.md` and check for a `## Arness` section
2. If found, extract the configured Vision directory path and Visual grounding directory path
3. If no `## Arness` section exists or Arness Spark fields are missing, inform the user: "Arness Spark is not configured for this project yet. Run `/arn-brainstorming` to get started — it will set everything up automatically." Do not proceed without it.
4. Create directories if they do not exist

> All references to "Vision directory" and "visual grounding directory" in this skill refer to the configured directories determined above.

**Scaffold (required):**
1. Check the Vision directory for `scaffold-summary.md`
2. If no `## Arness` section found, check `.arness/vision/scaffold-summary.md` at the project root
3. Also check for `package.json` at the project root

**If a scaffold-summary is found:** Read it to extract the full technology stack — UI framework, CSS framework, component library, icon library, dev server command, build command.

**If no scaffold-summary is found:** Inform the user: "The project must be scaffolded before visual sketching. The sketch needs a real CSS framework and component library to generate proposals. Run `/arn-spark-scaffold` first." Do not proceed.

**Architecture vision (required for fallback context):**
1. Check the Vision directory for `architecture-vision.md`
2. If no `## Arness` section found, check `.arness/vision/architecture-vision.md`

**If found:** Read it for UI framework and platform context. The scaffold-summary is the primary source, but the architecture vision provides additional context (platform type, product category).

**If not found:** Proceed if scaffold-summary exists — the scaffold-summary contains enough technical context.

**Product concept (recommended):**
1. Check the Vision directory for `product-concept.md`
2. If no `## Arness` section found, check `.arness/vision/product-concept.md`

**If found:** Read it to identify screens, understand target users, and derive realistic content for sketches.

**If not found:** Ask the user to describe the product briefly. Screen identification and content will be based on the user's description. Note the limitation.

**Dev server verification:**
1. Extract the dev server command from scaffold-summary.md (the "How to Run" section)
2. Verify the project builds without errors by running the build command

If the build fails, do not proceed with sketch generation. Report the error and suggest the user fix the scaffold first.

## Workflow

### Step 1: Load Context

Read available documents and present a summary:

1. Read `product-concept.md` → extract target users, core experience, product pillars
2. Read `architecture-vision.md` → extract UI framework, platform type
3. Read `scaffold-summary.md` → extract CSS framework, component library, icon library, dev commands
4. Detect framework routing conventions by examining the project source directory:
   - Look for `src/routes/` (SvelteKit)
   - Look for `app/` with `layout.tsx`/`page.tsx` (Next.js app router)
   - Look for `pages/` with `index.tsx` (Next.js pages router) or `index.vue` (Nuxt)
   - Fall back to generic approach if none match

Present the context:

"Your project uses **[UI framework]** with **[CSS framework]** and **[component library]** on **[platform]**. The product targets [target users] and focuses on [core experience].

I will create visual direction proposals as real pages in your project, running on your dev server. Each proposal applies a distinct visual approach to the same set of product screens.

Let's start by identifying which screens to sketch."

### Step 2: Identify Screens to Sketch

From the product concept (or user description), propose 2-4 key screens that represent the core experience:

"Based on your product concept, I suggest sketching these screens:

1. **[Screen Name]** — [What it shows, e.g., 'Main dashboard with device status grid and connection indicators']
2. **[Screen Name]** — [What it shows, e.g., 'List view with filterable items and status badges']
3. **[Screen Name]** — [What it shows, e.g., 'Settings panel with grouped configuration options']

These screens cover the main user interactions and will show how each visual direction handles different content types (data grids, lists, forms).

Adjust the screen list, add screens, or confirm to proceed."

**Screen selection criteria:**
- Choose screens that represent distinct content types (dashboard, list, detail, form)
- Prefer screens the user will see most frequently
- Include at least one data-heavy screen and one navigation-heavy screen
- Keep the total to 2-4 screens — enough to show the direction, not so many that generation takes too long

Wait for user confirmation before proceeding.

### Step 3: Define Exploration Dimensions

Propose which design aspects should vary between proposals:

"Which aspects of the design should differ between proposals? I suggest exploring:

1. **Layout structure** — sidebar vs. top navigation, card grids vs. lists, split-panel vs. full-width
2. **Color mood** — dark vs. light, warm vs. cool, neutral vs. vibrant
3. **Typography feel** — serif vs. sans-serif headings, compact vs. airy line-height, heavy vs. light weight
4. **Density** — spacious with generous padding vs. compact with dense information
5. **Component style** — rounded with shadows vs. sharp with borders vs. pill-shaped minimal
6. **Animation approach** — static vs. subtle transitions vs. expressive motion vs. scroll-driven narrative

All of these, or focus on specific ones?"

The user's choices guide how the direction briefs (Step 4) differ from each other. If the user wants all dimensions to vary, each proposal will be maximally distinct. If they focus on 1-2 dimensions, proposals share a base but diverge on those aspects.

### Step 4: Compose Direction Briefs

Read the aesthetic philosophy reference for tone palette and design vocabulary:
> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-visual-sketch/references/aesthetic-philosophy.md`

Use the tone palette (Section 1), anti-generic rules (Section 2), and design dimension guidance (Section 3) to inform brief composition. Each brief should be informed by these principles but written in the skill's own voice — do not copy-paste from the reference.

Based on the user's exploration preferences, compose N direction briefs. Ask the user how many proposals to generate (default 3).

"How many proposals would you like? (Default: 3)"

After the user specifies a count, compose the briefs:

"I'll generate **[N]** proposals:

**Proposal A — [Short Name]**
[Full paragraph describing the visual direction. Be specific about colors, typography, layout, density, and component style. E.g., "Dark and focused — deep charcoal backgrounds with electric blue accents, monospace headings with sans-serif body text, compact information density, sharp corners with thin borders, no shadows. Conveys a technical, developer-oriented aesthetic."]

**Proposal B — [Short Name]**
[Different direction paragraph]

**Proposal C — [Short Name]**
[Different direction paragraph]

Does this look right? Adjust any brief before I generate."

**Brief composition rules:**
- Each brief should be clearly distinct from the others along the exploration dimensions
- Use specific descriptive language, not vague terms ("warm grays and terracotta" not just "warm colors")
- Include guidance on all visual aspects: color, typography, layout, density, component style
- The brief is the creative constraint for the `arn-spark-visual-sketcher` agent — be explicit enough that the agent can make concrete CSS choices
- Each brief must include a **tone commitment**: a 2-3 word phrase that names the aesthetic posture (e.g., "archival/typographic", "luxury/refined", "industrial/utilitarian"). Draw from the aesthetic philosophy's tone palette or invent a tone that fits the product. This anchors the agent's Design Thinking exercise.
- Each brief must include a **differentiation anchor**: one specific, memorable design choice that prevents the proposal from looking generic (e.g., "ruled-line ledger system structures all content", "oversized italic serif pull quotes as section dividers", "single brass accent color used only on stat numbers and the CTA"). This gives the agent permission to commit fully to at least one distinctive element.
- Each brief must include a **direction-specific anti-pattern reminder**: one thing this particular direction must NOT do, drawn from the aesthetic philosophy's anti-generic rules (e.g., "Do NOT use drop shadows — depth comes only from layered backgrounds and border treatments", "Do NOT use sans-serif headings — this direction requires a display serif with character", "Do NOT use uniform card grids — vary layout between ruled tables, asymmetric columns, and full-width sections").
- Each brief may include an **animation element** describing the motion intent for this direction in platform-agnostic terms (e.g., "scroll-triggered cascading reveals create a declassification narrative", "micro-interactions only — hover feedback and state transitions, no page-level animation", "static — this direction communicates through typography and layout, not motion"). If the user did not express animation preferences in Step 3, default to "animation approach at agent's discretion based on the direction's tone."

Wait for user confirmation before generating.

### Step 5: Prepare Route Structure

Create the `arness-sketches/` route namespace in the project's source tree. The structure is framework-aware:

**SvelteKit:**
```
src/routes/arness-sketches/
  +page.svelte              ← Gallery (created in Step 7)
  +layout.svelte            ← Minimal wrapper (no proposal-specific styling)
  round-1/
    proposal-1/             ← Agent writes here
    proposal-2/
    proposal-3/
```

**Next.js (app router):**
```
app/arness-sketches/
  page.tsx
  layout.tsx
  round-1/
    proposal-1/
    proposal-2/
    proposal-3/
```

**Nuxt:**
```
pages/arness-sketches/
  index.vue
  round-1/
    proposal-1/
    proposal-2/
    proposal-3/
```

Create:
1. The `arness-sketches/` directory at the correct location for the framework
2. A minimal shared layout at the `arness-sketches/` level (no CSS variable definitions — those belong to proposal-level layouts)
3. The `round-1/` directory with empty `proposal-{N}/` subdirectories for each proposal

Read the sketch gallery guide for gallery structure details:
> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-visual-sketch/references/sketch-gallery-guide.md`

### Step 6: Spawn Agents in Parallel

Launch N `arn-spark-visual-sketcher` agents simultaneously using the Task tool. Each agent receives:

- **Product context:** Summary from product-concept.md (target users, core experience, pillars, and content hints for each screen)
- **Screen list:** The confirmed screens from Step 2 with descriptions
- **Direction brief:** This proposal's unique brief from Step 4
- **Tech context:** From scaffold-summary.md — UI framework, CSS framework, component library, icon library
- **Output route path:** The specific proposal directory (e.g., `src/routes/arness-sketches/round-1/proposal-1/`)
- **Aesthetic philosophy path:** `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-visual-sketch/references/aesthetic-philosophy.md`

All agents are launched in a single message with multiple Task tool calls to maximize parallelism.

**Error handling per agent:**
- If an agent fails: note which proposal failed and why
- Continue waiting for remaining agents
- Present successful proposals to the user
- Offer to retry failed proposals

### Step 7: Build Gallery and Present

After all agents complete (or the successful ones complete):

1. Read each proposal's `proposal-manifest.json` to get screen routes, direction summaries, and CSS variable values
2. Create the gallery index page at `arness-sketches/` following the sketch gallery guide:
   - Show a card for each proposal with: direction brief summary, direction note (tone commitment and differentiation anchor from `directionNote` in the manifest), color swatches from CSS variables, link to the proposal's first screen
   - If any proposals failed, show a placeholder card noting the failure
3. Start the dev server if not already running (use the command from scaffold-summary.md)
4. Determine the dev server port (from scaffold-summary or by checking the running process)

Present to the user:

"**Round 1 — [N] proposals generated.**

Open **http://localhost:[port]/arness-sketches** to see the gallery and compare proposals.

| Proposal | Direction | Screens |
|----------|-----------|---------|
| A — [Name] | [1-line summary] | [count] |
| B — [Name] | [1-line summary] | [count] |
| C — [Name] | [1-line summary] | [count] |

Browse each proposal in your browser. When you are ready:
- **Pick a direction** and I will create expansions of it
- **Give feedback** on any proposal and I will adjust
- **Start over** with new direction briefs"

### Step 8: Selection and Expansion Loop

Wait for the user's feedback. The user may:

| User Says | Action |
|-----------|--------|
| "I like Proposal B" / "Go with B" | Proceed to expansion |
| "B is close but too dark" | Note the feedback, refine the brief, proceed to expansion |
| "None of these work" | Return to Step 4 to compose new briefs |
| "This is the direction" / "B is perfect" | Skip expansion, proceed to Step 9 |
| "Can you show me [specific change]?" | Create a targeted single-proposal re-generation |

**When the user selects a proposal for expansion:**

1. Ask: "How many expansions of **Proposal [X]** would you like? (Default: 3)"
2. Ask: "What should change or evolve in the expansions? For example: 'keep the layout but make it cooler in tone', 'try different heading fonts', 'increase the whitespace', etc."
3. Compose expansion briefs:
   - Start with the selected proposal's direction brief as the base
   - Apply the user's guidance as deltas, creating N variations
   - Each expansion brief inherits and may adjust the parent's tone commitment, differentiation anchor, and direction-specific anti-pattern reminder. If the user's expansion guidance changes the tone or focus, update these anchoring elements accordingly.
   - Present the expansion briefs for confirmation (same composition rules as Step 4)
4. Create `round-{N+1}/` structure under `arness-sketches/` with `expansion-{1..M}/` directories
5. Spawn M `arn-spark-visual-sketcher` agents in parallel — each receives the expansion brief + original product context + tech context + new output path + aesthetic philosophy path
6. After agents complete, update the gallery index:
   - Add a new round section at the top
   - Highlight the selected proposal from the previous round
   - Show expansion cards with their briefs
7. Present results (same format as Step 7 but for the new round)

**Repeat** until the user says "this is the direction" or indicates satisfaction.

### Step 9: Capture and Finalize

When the user has selected a final direction:

1. **Capture screenshots:** Invoke the `arn-spark-style-capture` agent with:
   - URLs: the localhost URLs of each screen in the selected proposal (from the proposal's `proposal-manifest.json`)
   - Output path: `[visual-grounding]/designs/`
   - File naming: `visual-sketch-[screen-name].png` (e.g., `visual-sketch-dashboard.png`)

   If `arn-spark-style-capture` reports Playwright is not available, inform the user:
   "Playwright is not installed, so I cannot capture screenshots automatically. You can:
   1. Install Playwright (`npm install -D playwright && npx playwright install chromium`) and re-run the capture
   2. Take screenshots manually from the dev server and save them to `[visual-grounding]/designs/`
   3. Proceed without screenshots — style-explore will work from the direction description"

2. **Read the selected proposal's manifest:** Get CSS variables, screen routes, and direction summary from `proposal-manifest.json`

3. **Write visual-direction.md:** Read the template and populate it:
   > Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-visual-sketch/references/visual-direction-template.md`

   Write the populated document to the Vision directory as `visual-direction.md`.

4. **Offer route cleanup:**

   Ask (using `AskUserQuestion`):

   **What should happen to the sketch routes at `[route path]/arness-sketches/`?**
   1. **Keep** — Leave them for reference (I will suggest adding `arness-sketches/` to `.gitignore`)
   2. **Remove** — Delete the sketch routes from the project

   If **Keep:** Suggest adding the arness-sketches route directory to `.gitignore` so the sketches are not committed.
   If **Remove:** Delete the entire `arness-sketches/` directory from the project's route tree.

5. **Stop the dev server** if it was started by this skill (not if it was already running).

### Step 10: Recommend Next Steps

"**Visual direction selected and documented.**

- Visual direction saved to `[Vision directory]/visual-direction.md`
- [If captured:] Screenshots saved to `[visual-grounding]/designs/`

Recommended next steps:
1. **Define the design system:** Run `/arn-spark-style-explore` to translate this visual direction into precise design tokens and toolkit configuration
2. [If use cases not done:] **Write use cases:** Run `/arn-spark-use-cases` to specify system behavior

The style explorer will use your visual direction as a starting point — you won't need to describe the style from scratch."

## Agent Invocation Guide

| Situation | Action |
|-----------|--------|
| Generate initial proposals (Step 6) | Invoke N `arn-spark-visual-sketcher` agents in parallel via Task tool, each with unique direction brief and output path |
| Generate expansions (Step 8) | Invoke N `arn-spark-visual-sketcher` agents in parallel with expansion briefs derived from selected proposal + user adjustments |
| Capture final screenshots (Step 9) | Invoke `arn-spark-style-capture` with localhost URLs of selected sketch's screens and output to visual grounding `designs/` |
| User asks about detailed design tokens | Defer: "Design tokens are specified in `/arn-spark-style-explore`. This skill establishes the visual direction." |
| User asks about interactive behavior | Defer: "Interactive behavior is validated in `/arn-spark-clickable-prototype`." |
| User asks about component showcases | Defer: "Component showcases are created by `/arn-spark-static-prototype`." |
| User asks about features or architecture | Defer to the appropriate skill (`/arn-code-feature-spec`, `/arn-spark-arch-vision`) |
| Agent build fails (single proposal) | Report which proposal failed. Present successful proposals. Offer to retry. |
| All agents fail | Report all errors. Ask user to verify the scaffold builds correctly. Suggest fixing the scaffold before retrying. |
| Style-capture unavailable | Proceed without screenshots. Visual-direction.md is still written with all other content. Note screenshots are pending. |
| User wants to compare with an external reference | Invoke `arn-spark-style-capture` with the external URL to capture it, then present alongside the proposals for comparison. |

## Error Handling

- **Scaffold not found:** Cannot proceed. Suggest `/arn-spark-scaffold` first.
- **Product concept not found:** Proceed with the user's verbal description. Screen identification will be based on conversation. Note the limitation.
- **Architecture vision not found:** Proceed if scaffold-summary exists — it contains sufficient technical context. Note the limitation.
- **Build fails before sketch generation:** Report the error. Do not attempt to fix the scaffold — that is the user's responsibility or `/arn-spark-scaffold`'s job.
- **One agent fails (others succeed):** Present successful proposals. Show a placeholder card for the failed one. Offer to retry.
- **All agents fail:** Report errors for all proposals. The most likely cause is a scaffold issue (missing dependencies, broken build). Suggest verifying the scaffold.
- **Dev server won't start:** Report the error. The user can start it manually and provide the URL. Proceed with gallery creation.
- **Dev server port conflict:** If the default port is in use, check if a dev server is already running. If so, use that server.
- **Playwright unavailable for captures:** Proceed without screenshots. Write visual-direction.md with all content except screenshot paths. Note the limitation.
- **User wants to restart from scratch:** Clear the `arness-sketches/` directory and return to Step 2.
- **visual-direction.md already exists:**

  Ask (using `AskUserQuestion`):

  > **A visual direction document already exists at `[path]`. What should I do?**
  > 1. **Replace** — Overwrite with the new direction
  > 2. **Keep both** — Rename the existing one and save the new direction alongside it
- **More than 5 rounds of iteration:** Gently suggest: "We have been through [N] rounds. Would you like to finalize the current direction, or would it help to start fresh with new briefs?"
- **Writing the document fails:** Print the full visual-direction.md content in the conversation so the user can save it manually.
