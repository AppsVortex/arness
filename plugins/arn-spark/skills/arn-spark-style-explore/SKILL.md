---
name: arn-spark-style-explore
description: >-
  This skill should be used when the user says "style explore", "arn style",
  "visual style", "explore styles", "UI style", "look and feel",
  "design direction", "pick a style", "choose colors", "theme the app",
  "visual direction", "style guide", or wants to explore and define the visual
  design direction for their project through guided conversation, producing a
  style brief document with implementable toolkit configuration.
version: 1.0.0
---

# Arness Style Explore

Explore visual style direction for the project through iterative conversation, aided by the `arn-spark-ux-specialist` agent (a greenfield agent in this plugin) for design guidance, optionally the `arn-spark-style-capture` agent for capturing reference website screenshots, and optionally the `arn-spark-prototype-builder` agent for sample screens. This is a conversational skill that runs in normal conversation (NOT plan mode). The primary artifact is a **style brief document** with implementable toolkit configuration.

This skill covers the visual identity of the product: colors, typography, spacing, component customization, and animation approach. It translates these into concrete configuration for the project's CSS framework and component library. It does not create full application screens -- that is `/arn-spark-static-prototype` and `/arn-spark-clickable-prototype`'s job.

## Prerequisites

A product concept document should exist for context on target users and product personality. Check in order:

1. Read the project's `CLAUDE.md` for a `## Arness` section. If found, check the configured Vision directory for `product-concept.md`
2. If no `## Arness` section found, check `.arness/vision/product-concept.md` at the project root

**If a product concept is found:** Read it to inform style recommendations.

**If no product concept is found:** Proceed with the user's description of the product. Style exploration does not hard-require a product concept.

**Visual direction (recommended):**
1. Check the configured Vision directory for `visual-direction.md`
2. If no `## Arness` section found, check `.arness/vision/visual-direction.md` at the project root

**If a visual direction is found:** Read it. The visual direction provides primary visual grounding from `/arn-spark-visual-sketch`: selected direction characteristics (color mood, typography feel, component style, layout density), approximate color palette with hex values, CSS variables used in the sketch, screenshot paths in the visual grounding `designs/` directory, **creative anchors** — tone commitment, differentiation anchor, and Design Thinking answers that capture the creative intent behind the direction, and **animation and motion context** — motion philosophy, key patterns, animation approach used, and whether animation is integral to the direction's identity. Use this as the starting point for style exploration rather than asking the user to describe a direction from scratch. The creative anchors are the direction's DNA — preserve them through token refinement rather than diluting them into generic defaults.

**If no visual direction is found:** Proceed normally with the user's verbal description. Visual direction is optional -- style exploration works without it.

The project should be scaffolded with a UI toolkit already configured (CSS framework and component library installed via `/arn-spark-scaffold`). Check:

1. Read the project's `package.json` to identify installed CSS framework and component library
2. Read the architecture vision for UI framework and toolkit choices

**If the project is scaffolded:** Use the installed toolkit for style configuration.

**If the project is NOT scaffolded:** Inform the user: "The project does not appear to be scaffolded yet. I can explore style direction conceptually, but the toolkit configuration section will be more useful after running `/arn-spark-scaffold`." Proceed with the exploration -- the style brief can be written without toolkit config and updated later.

Determine the output directory:
1. Read the project's `CLAUDE.md` and check for a `## Arness` section
2. If found, extract the configured Vision directory path — this is the source of truth
3. If no `## Arness` section exists or Arness Spark fields are missing, inform the user: "Arness Spark is not configured for this project yet. Run `/arn-brainstorming` to get started — it will set everything up automatically." Do not proceed without it.
4. If the output directory does not exist, create it

Determine the visual grounding directory:
1. Read the project's `CLAUDE.md` `## Arness` section
2. If found, extract the Visual grounding directory path
3. If not found, fall back to `.arness/visual-grounding`
4. Create the directory and subfolders (`references/`, `designs/`, `brand/`) if they do not exist

Check for design tool integration:
1. Read the `## Arness` section for `Figma` and `Canva` fields
2. Only offer Figma/Canva integration in Step 1 if the corresponding field is `yes`
3. If the field is `no` or missing, do not mention or attempt to use that design tool

## Workflow

### Step 1: Gather Context

Load available context:

- **Product concept:** Target users, core experience, product personality
- **Architecture vision:** UI framework, platform (desktop, web, mobile)
- **Scaffold results:** Installed CSS framework, component library, icon library
- **Visual direction (if found):** Selected direction characteristics, approximate color palette, CSS variables used in the sketch, screenshot paths, creative anchors (tone commitment, differentiation anchor, Design Thinking), animation context (motion philosophy, key patterns, animation approach, role)

Present the context to the user:

**If a visual direction exists:**

"Your project uses **[UI framework]** with **[CSS framework]** and **[component library]**. The product is [brief description from product concept, targeting audience].

A visual direction was established via `/arn-spark-visual-sketch`. The selected direction is: [summary from visual-direction.md — overall feel, color mood, typography, layout approach]. The creative anchors are: **Tone:** [tone commitment], **Differentiation:** [differentiation anchor].

[If screenshots exist:] Screenshots of the sketched screens are available at [paths].

I will use this as the starting point for the style brief."

Ask (using `AskUserQuestion`):

> **How would you like to proceed with this visual direction?**
> 1. **Proceed** — Build a style proposal based on this direction
> 2. **Adjust** — Refine specific aspects before proceeding
> 3. **Different direction** — Take it in a completely different direction

**If no visual direction exists:**

"Your project uses **[UI framework]** with **[CSS framework]** and **[component library]**. The product is [brief description from product concept, targeting audience].

Adapt the context summary based on what was found. If the project is not scaffolded, omit toolkit details and present only what is known (e.g., product description and platform context).

Describe the visual feel you want. You can:
- **Use words:** minimal, dark, playful, professional, etc.
- **Reference other apps:** 'I like how Linear looks' or 'something like Discord'
- **Share URLs:** Paste a URL and I can capture a screenshot to analyze the design
- **Share screenshots:** Paste or reference image files

Some starting points if you are not sure:
- **Minimal and clean** -- lots of whitespace, muted colors, thin borders
- **Dark with neon accents** -- dark backgrounds, vibrant accent colors, tech feel
- **Warm and approachable** -- rounded corners, warm colors, friendly tone
- **Professional and dense** -- compact layout, neutral palette, data-focused

Or describe your own direction."

After the user describes their initial direction, ask about visual assets:

Ask (using `AskUserQuestion`):

**"Do you have any visual assets to guide the style direction?"**

Options:
1. **Reference images** — Screenshots or URLs of apps/sites you admire (inspirational)
2. **Design mockups** — Figma, Canva, or exported screen designs (specification)
3. **Brand assets** — Logos, brand guidelines, color specs (constraints)
4. **None** — We will work from verbal descriptions

**Handle each asset type:**

| User has | Action |
|----------|--------|
| Reference URLs | Invoke `arn-spark-style-capture` → save to `[visual-grounding]/references/` |
| Reference image files | User provides paths → copy to `[visual-grounding]/references/` |
| Figma designs (Figma enabled in config) | Use Figma MCP to read selected designs, export screenshots → save to `[visual-grounding]/designs/` |
| Figma designs (Figma not enabled) | Do not offer Figma integration. If user mentions Figma, suggest re-running `/arn-spark-init` to enable it. User can export as PNG/PDF manually → save to `[visual-grounding]/designs/` |
| Canva designs (Canva enabled in config) | Use Canva MCP to export designs → save to `[visual-grounding]/designs/` |
| Canva designs (Canva not enabled) | Same as Figma — suggest re-running init or manual export → save to `[visual-grounding]/designs/` |
| Hand-drawn wireframes | User provides photos → save to `[visual-grounding]/designs/` |
| Brand assets (logos, guidelines) | User provides files → save to `[visual-grounding]/brand/` |

**If the user provides one or more URLs:** Invoke the `arn-spark-style-capture` agent with the URLs and save screenshots to the visual grounding directory (under `references/`). If the agent reports Playwright is not available, inform the user:

"Playwright is not installed in this environment, so I cannot automatically capture that URL. You can either:
1. Install Playwright (`npm install -D playwright && npx playwright install chromium`) and try again
2. Take a screenshot yourself and share it
3. Describe what you like about the referenced site and I will work from that"

If capture succeeds, use the agent's extracted design characteristics (colors, typography, layout, spacing) as input to the `arn-spark-ux-specialist` alongside the user's verbal description.

### Step 2: Initial Style Proposal

Invoke the `arn-spark-ux-specialist` agent (greenfield agent) with:

- The user's style description or preferences
- Product concept context (target users, product personality)
- UI toolkit context (CSS framework, component library)
- Platform context (desktop app, web app, mobile)
- **Visual direction context (if found):** Include the visual direction's characteristics, approximate color palette, CSS variables, screenshot paths, and creative anchors (tone commitment, differentiation anchor, Design Thinking answers). Instruct the specialist: "A visual direction has been established via /arn-spark-visual-sketch. Use it as the primary input for the style proposal. The screenshots show the selected visual approach applied to real product screens. The tone commitment is '[tone]' and the differentiation anchor is '[differentiation]' — these are the creative DNA of the direction. Translate the direction into precise design tokens while preserving its character. Every token decision should support the tone commitment and keep the differentiation anchor intact. Do not flatten distinctive choices into generic defaults during refinement."
- **Visual direction animation context (if found):** If the visual direction includes an Animation & Motion section, pass it to the specialist: "The visual direction includes animation context: [motion philosophy], with key patterns [patterns], using [animation approach]. Animation is [integral/decorative/none] to the direction. Build the style brief's Animation and Motion section grounded in these choices — do not reinvent the motion approach from scratch. Describe animation in platform-agnostic intent language."
- **All available visual grounding assets.** Provide images from all three subfolders with category context so the specialist knows the intent:
  - **References** (`[visual-grounding]/references/`): "These reference images are inspirational direction — they inform the overall feel but are not pixel-level targets."
  - **Designs** (`[visual-grounding]/designs/`): "These design mockups are specification targets — match them for layout, spacing, and proportions where applicable."
  - **Brand** (`[visual-grounding]/brand/`): "These brand assets are fixed constraints — logos, colors, and typefaces must be incorporated as-is."

Visual references provide nuances that text descriptions alone cannot convey — the UX specialist should see the actual images alongside the extracted design characteristics.

Request that the agent provide recommendations covering: color palette (with hex values for all roles), typography (specific font families and sizes), spacing and sizing tokens, border radius values, component style characteristics, and animation approach. These map directly to the style brief template sections.

The agent returns design recommendations:

- Color palette with specific values
- Typography recommendations
- Spacing and sizing tokens
- Component customization approach for the chosen library
- Animation and motion philosophy

Present the proposal to the user. Frame it as a starting point:

"Here is an initial style direction based on your description:

**Colors:** [Brief summary with primary, background, and accent colors]
**Typography:** [Font families and general sizing]
**Components:** [Overall feel -- rounded, sharp, shadows, borders]
**Animation:** [Approach -- minimal, moderate, expressive]

What do you think? We can adjust colors, change the overall feel, or try a completely different direction."

### Step 3: Iterative Refinement

Enter a conversation loop. The user may want to:

| User Request | Action |
|-------------|--------|
| "Make it darker" / "warmer" / "more playful" | Re-invoke `arn-spark-ux-specialist` with adjusted direction |
| "I like the colors but change the typography" | Re-invoke `arn-spark-ux-specialist` with partial update request |
| "Show me what it looks like" | Invoke `arn-spark-prototype-builder` to create 1-2 sample screens |
| "Compare two directions" | Invoke `arn-spark-ux-specialist` for both, present side-by-side |
| "Use [specific color/font]" | Record directly, adjust the proposal |
| "What would [reference app] style look like?" | Invoke `arn-spark-ux-specialist` with the reference for interpretation |
| User provides a URL to reference | Invoke `arn-spark-style-capture` with the URL, save to `[visual-grounding]/references/`. Feed results to `arn-spark-ux-specialist`. |
| User provides multiple URLs to compare | Invoke `arn-spark-style-capture` with all URLs, save to `[visual-grounding]/references/`. Present the comparison and feed results to `arn-spark-ux-specialist`. |
| User provides design mockups (Figma/Canva/manual) | Save to `[visual-grounding]/designs/`. Feed to `arn-spark-ux-specialist` as specification targets. |
| User provides brand assets | Save to `[visual-grounding]/brand/`. Feed to `arn-spark-ux-specialist` as fixed constraints. |
| User is happy with the direction | Proceed to Step 4 |

**Sample screens (optional):** If the user wants to see the style applied, invoke the `arn-spark-prototype-builder` agent to create 1-2 representative screens (e.g., the main screen and a settings screen). These use the actual component library with the proposed style configuration. If visual grounding assets are available, include them so the builder can visually match the intended direction — especially design mockups (specification targets) and brand assets (fixed constraints).

**Readiness check:** When the style direction seems settled:

"I think we have a solid visual direction. Here is a summary:

**Primary:** [color] | **Background:** [color] | **Accent:** [color]
**Font:** [family] | **Corners:** [radius] | **Animation:** [approach]

Ask (using `AskUserQuestion`):

> **Ready to write the style brief?**
> 1. **Yes, write it** — Generate the style brief document
> 2. **Keep adjusting** — I want to refine more before writing"

### Step 4: Write the Style Brief

When the user is ready:

1. Read the template:
   > Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-style-explore/references/style-brief-template.md`

2. Populate the template with all decisions from the conversation:
   - Specific color values (hex/HSL) for all palette roles
   - Typography with actual font families and sizes
   - Spacing and sizing tokens
   - Component style characteristics
   - Animation approach and specific animations if discussed
   - **Toolkit Configuration section:** Translate all design tokens into the project's CSS framework config (e.g., Tailwind theme extensions) and component library theme (e.g., shadcn CSS custom properties)

3. Write the document to the output directory as `style-brief.md`

4. Present a summary:
   - Document path
   - Color palette overview
   - Font choices
   - Note whether toolkit configuration was included or deferred

### Step 5: Recommend Next Steps

"Style brief saved to `[path]/style-brief.md`.

Recommended next steps:
1. **Build static prototype:** Run `/arn-spark-static-prototype` to validate visual fidelity with component showcases
2. **Apply toolkit config:** The style brief includes [CSS framework] and [component library] configuration that will be applied during prototyping

The prototype will use the style brief to ensure all screens share a consistent visual language."

## Agent Invocation Guide

| Situation | Action |
|-----------|--------|
| User provides reference URL(s) (Step 1 or Step 3) | Invoke `arn-spark-style-capture` with URLs, save to `[visual-grounding]/references/`. If Playwright unavailable, fall back to user-provided screenshots or verbal description. |
| User provides design mockups or brand assets | Save to `[visual-grounding]/designs/` or `[visual-grounding]/brand/` respectively. For Figma/Canva exports, use the MCP only if the corresponding flag is `yes` in `## Arness` config. |
| Initial style proposal (Step 2) | Invoke `arn-spark-ux-specialist` with user's direction + product context + toolkit context + ALL visual grounding assets (with category context: references=inspirational, designs=specification, brand=constraints) |
| User wants style adjustments | Invoke `arn-spark-ux-specialist` with updated direction + all visual grounding assets. Always provide images alongside text when they exist — visual nuances matter. |
| User wants to see sample screens | Invoke `arn-spark-prototype-builder` with: screen list (1-2 screens), navigation flow (minimal), style brief (current direction), UI framework + component library, project root path, and visual grounding assets (especially design mockups and brand assets) |
| User asks which CSS framework to use | Defer: "CSS framework is chosen during `/arn-spark-scaffold`. If you want to change it, re-run scaffold." |
| User asks about specific component APIs | Defer: "Component implementation details come during feature development. The style brief defines how components should look." |
| User asks about features or architecture | Defer to the appropriate skill |

## Error Handling

- **No product concept found:** Proceed with the user's verbal description. The style can be explored without a formal product concept.
- **Project not scaffolded:** Explore style conceptually. Write the style brief without the Toolkit Configuration section, note it for later.
- **UX specialist returns unhelpful response:** Summarize the issue and continue the conversation directly. Try a more specific request on the next invocation.
- **User cannot describe a style direction:** Offer the curated archetypes from Step 1. If still stuck, ask: "What apps do you use and enjoy the look of?" and use those as reference points.
- **Writing the document fails:** Print the full content in the conversation so the user can copy it.
- **Style brief already exists:**

  Ask (using `AskUserQuestion`):

  > **A style brief already exists at `[path]`. How would you like to proceed?**
  > 1. **Replace** — Start fresh with a new style brief
  > 2. **Update** — Update specific sections of the existing brief
- **Sample screen build fails:** Note the issue, continue with the style exploration. The prototype build is optional during style exploration.
- **Playwright not available for URL capture:** Inform the user and offer alternatives: install Playwright, provide manual screenshots, or describe the reference verbally. Do not block the style exploration -- URL capture is optional.
- **URL capture fails (timeout, auth wall):** Report which URL failed. Ask the user to provide a manual screenshot or describe what they like about the site. Continue with the exploration.
