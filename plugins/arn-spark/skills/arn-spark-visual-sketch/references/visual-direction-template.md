# Visual Direction Template

This template defines the structure for visual direction documents written by the `arn-spark-visual-sketch` skill. The document is saved to the project's Vision directory as `visual-direction.md`.

A visual direction captures the selected visual approach from iterative sketch exploration. It provides enough detail for downstream skills (especially `arn-spark-style-explore`) to translate the direction into precise design tokens, CSS variables, and toolkit configuration. It is intentionally lighter than a style brief — approximate values and directional characteristics rather than exact token tables.

## Instructions for arn-spark-visual-sketch

When populating this template:

- Replace all bracketed placeholders with concrete values from the exploration
- Color values should be approximate hex values — exact tokens come from `arn-spark-style-explore`
- Include the full iteration history so downstream skills understand how the direction evolved
- Screenshot paths must reference files in the visual grounding `designs/` directory
- The CSS variables section should list what the selected sketch's layout component actually defined
- The direction brief should be the full text of the winning brief, not a summary
- The Tone & Creative Anchors section should extract the tone commitment and differentiation anchor from the winning direction brief, and the Design Thinking answers from the selected sketch's layout component HTML comment block
- The Animation & Motion section should describe motion intent from the selected sketch in platform-agnostic terms. If the sketch had working animations, read the proposal source and manifest to identify patterns, approach, and role. If the sketch was static, note it explicitly — do not leave animation unaddressed
- If screenshots were not captured (Playwright unavailable), note it in the Screenshots section

---

## Template

```markdown
# [Product Name] - Visual Direction

## Selected Direction

[2-3 sentences describing the chosen visual approach. Reference the product personality and target users. E.g., "A warm, inviting interface with generous whitespace that reflects a tool used between family members. Cream backgrounds and terracotta accents create a friendly atmosphere, while serif headings add a touch of personality without sacrificing readability."]

## Tone & Creative Anchors

| Anchor | Value |
|--------|-------|
| Tone Commitment | [The aesthetic posture from the direction brief, e.g., "archival/typographic", "luxury/refined", "industrial/utilitarian"] |
| Differentiation Anchor | [The one memorable design choice, e.g., "ruled-line ledger system structures all content", "oversized italic serif pull quotes as section dividers"] |
| Anti-Pattern Constraint | [The direction-specific thing to avoid, e.g., "No drop shadows — depth comes only from layered backgrounds"] |

### Design Thinking (from selected sketch proposal)

| Question | Answer |
|----------|--------|
| Purpose | [What problem does this interface solve? Who uses it? What do they need to feel?] |
| Tone | [Aesthetic posture committed to] |
| Differentiation | [The one thing someone will remember] |
| Execution | [How the commitment was applied — bold, restrained, layered, etc.] |

[These anchors were established during visual sketch exploration and should be preserved through style refinement. The tone commitment and differentiation anchor are the creative DNA of this direction — downstream skills should translate them into precise tokens, not dilute them into generic defaults.]

## Direction Characteristics

| Aspect | Value |
|--------|-------|
| Color Mood | [e.g., warm earthy tones, cool minimalist, dark with neon accents] |
| Typography Feel | [e.g., modern sans-serif, mixed serif headings / sans-serif body, playful rounded] |
| Layout Approach | [e.g., top navigation with card grid, sidebar with list content, split-panel] |
| Layout Density | [e.g., spacious, comfortable, compact] |
| Component Style | [e.g., rounded with subtle shadows, sharp with strong borders, pill-shaped minimal] |
| Overall Feel | [2-3 adjectives, e.g., warm, inviting, approachable] |

## Color Palette (Approximate)

| Role | Color | Hex |
|------|-------|-----|
| Background | [description] | [#hex] |
| Surface | [description] | [#hex] |
| Primary | [description] | [#hex] |
| Primary Foreground | [description] | [#hex] |
| Accent | [description] | [#hex] |
| Text Primary | [description] | [#hex] |
| Text Secondary | [description] | [#hex] |
| Border | [description] | [#hex] |

[These are the approximate values used in the sketch. Style-explore will refine them into a complete palette with semantic colors, hover states, and dark mode variants.]

## CSS Variables Used

The selected sketch's layout component defined these CSS custom properties:

```css
--sketch-bg: [value];
--sketch-surface: [value];
--sketch-primary: [value];
--sketch-primary-fg: [value];
--sketch-accent: [value];
--sketch-text: [value];
--sketch-text-muted: [value];
--sketch-border: [value];
--sketch-font-heading: [value];
--sketch-font-body: [value];
--sketch-font-size-base: [value];
--sketch-radius: [value];
--sketch-spacing: [value];
--sketch-shadow: [value];
```

## Animation and Motion

| Aspect | Value |
|--------|-------|
| Motion Philosophy | [minimal / moderate / expressive / scroll-driven narrative — overall approach] |
| Key Animation Patterns | [e.g., "scroll-triggered cascading reveals", "hero entrance sequence", "hover micro-interactions only"] |
| Animation Approach | [e.g., "GSAP with ScrollTrigger", "CSS transitions only", "Svelte transitions", "platform-native", "none"] |
| Animation Role | [integral to direction identity / decorative enhancement / none] |

[If the selected sketch had no animations: "Direction is static — no temporal effects. Motion philosophy to be determined during style exploration."]

[If animations were present: brief description of the motion experience in platform-agnostic terms. Describe intent and characteristics (timing, easing, stagger), not implementation details. E.g., "Content reveals as if being declassified — each section cascades in with a 0.15s stagger triggered by scroll position. The overall effect is archival — slow, deliberate, authoritative."]

## Screens Sketched

| Screen | What It Shows |
|--------|--------------|
| [name] | [description of what this screen displays and its primary purpose] |

## Screenshots

| Screen | Path | Description |
|--------|------|-------------|
| [Screen Name] | [visual-grounding/designs/visual-sketch-screen-name.png] | [Brief description of what the screenshot shows] |

[If no screenshots captured: "Screenshots not captured (Playwright unavailable). Style-explore will work from the direction description, characteristics, and CSS variables above."]

## Iteration History

| Round | Proposals | Selected | User Feedback |
|-------|-----------|----------|---------------|
| 1 | [N] proposals: [brief name for each] | Proposal [X] — [name] | [summary of user's choice rationale and feedback] |
| 2 | [N] expansions of Proposal [X] | Expansion [Y] — [name] | [summary] |

## Direction Brief (Selected)

[Full text of the selected direction brief — the paragraph that the winning arn-spark-visual-sketcher agent received as its creative constraint. Preserved verbatim for downstream reference.]

## Sketch Routes

| Screen | Route |
|--------|-------|
| [name] | [/arness-sketches/round-N/proposal-N/path] |

[If routes were removed during cleanup: "Sketch routes were removed from the project after direction capture. Screenshots above are the visual record."]

## Relationship to Style Brief

This document provides visual direction grounding for `/arn-spark-style-explore`. The style brief will translate these approximate values into:

- Precise design tokens with exact hex/HSL values for all color roles
- Complete typography table with font families, weights, sizes, and line heights
- Spacing and sizing token scale
- Component style specifications per component type
- Toolkit-specific configuration (CSS framework config, component library theme)
- Animation and motion philosophy

The visual direction establishes *what the product should feel like*. The style brief specifies *exactly how to implement that feel*.
```

---

## Section Guidance

| Section | Source | Depth |
|---------|--------|-------|
| Selected Direction | User's final selection + skill's iteration summary | 2-3 sentences capturing the feel |
| Tone & Creative Anchors | Tone commitment and differentiation anchor from the winning direction brief; Design Thinking from the selected sketch's layout component HTML comment block | Structured table with anchors + Design Thinking Q&A |
| Direction Characteristics | Extracted from the selected sketch's direction brief | One-line descriptions per aspect |
| Color Palette | From the selected sketch's CSS variables | Approximate hex values, major roles only |
| CSS Variables | From the selected sketch's layout component | All `--sketch-*` variables verbatim |
| Animation and Motion | From the selected sketch's animation code + proposal-manifest.json animation field | Motion philosophy, key patterns, library/approach, role (integral/decorative/none) |
| Screens Sketched | From the confirmed screen list (Step 2) | Name and description per screen |
| Screenshots | From `arn-spark-style-capture` output (Step 9) | Paths to files in visual grounding designs/ |
| Iteration History | Accumulated during the selection loop | One row per round with selection rationale |
| Direction Brief | The winning direction brief from Step 4 / Step 8 | Full paragraph, verbatim |
| Sketch Routes | From the proposal-manifest.json of the selected sketch | Route paths, or cleanup note |
