# Style Brief Template

This template defines the structure for visual style documents written by the `arn-spark-style-explore` skill. The document is saved to the project's vision directory as `style-brief.md`.

A style brief captures the visual design direction for the project: colors, typography, spacing, component customization, and toolkit-specific configuration. It serves as the visual contract between design decisions and implementation, ensuring the prototype and production code share the same visual language.

## Instructions for arn-spark-style-explore

When populating this template:

- Replace all bracketed placeholders with concrete values from the style exploration conversation
- Color values must be specific (hex, HSL, or RGB) -- not vague descriptions like "blue"
- Typography must specify actual font families, not categories like "sans-serif"
- The Toolkit Configuration section is critical -- it translates the design into implementable code
- If using a component library (shadcn, Skeleton UI, etc.), include the library-specific theme configuration
- Dark/light mode: specify both palettes if the project supports both, or note that only one mode is in scope for v1
- Visual grounding assets (references, designs, brand) are optional but helpful for communicating intent and enabling downstream fidelity comparison

---

## Template

```markdown
# [Product Name] - Style Brief

## Design Direction

[2-3 sentences describing the overall visual feel. Reference the target audience and product personality from the product concept. E.g., "Warm and approachable, reflecting a tool used between family members and close friends. Clean but not clinical -- soft edges, gentle shadows, and a color palette that feels inviting rather than corporate."]

## Color Palette

### Primary Colors

| Role | Color | Hex | Usage |
|------|-------|-----|-------|
| Primary | [Name] | [#hex] | [Primary actions, key UI elements] |
| Primary Hover | [Name] | [#hex] | [Hover/active state for primary] |
| Primary Foreground | [Name] | [#hex] | [Text on primary background] |

### Neutral Colors

| Role | Color | Hex | Usage |
|------|-------|-----|-------|
| Background | [Name] | [#hex] | [Page background] |
| Surface | [Name] | [#hex] | [Card/panel backgrounds] |
| Border | [Name] | [#hex] | [Borders, dividers] |
| Text Primary | [Name] | [#hex] | [Main body text] |
| Text Secondary | [Name] | [#hex] | [Secondary/muted text] |
| Text Disabled | [Name] | [#hex] | [Disabled state text] |

### Semantic Colors

| Role | Color | Hex | Usage |
|------|-------|-----|-------|
| Success | [Name] | [#hex] | [Connected, active, confirmed] |
| Warning | [Name] | [#hex] | [Attention needed, degraded state] |
| Error | [Name] | [#hex] | [Disconnected, failed, destructive] |
| Info | [Name] | [#hex] | [Informational, neutral status] |

### Dark Mode (if applicable)

[If dark mode is in scope: provide the equivalent palette for dark mode. If not: note "Dark mode deferred to post-v1."]

## Typography

| Role | Font Family | Weight | Size | Line Height |
|------|-------------|--------|------|-------------|
| Heading 1 | [Family] | [Weight] | [Size] | [Line height] |
| Heading 2 | [Family] | [Weight] | [Size] | [Line height] |
| Heading 3 | [Family] | [Weight] | [Size] | [Line height] |
| Body | [Family] | [Weight] | [Size] | [Line height] |
| Body Small | [Family] | [Weight] | [Size] | [Line height] |
| Caption | [Family] | [Weight] | [Size] | [Line height] |
| Monospace | [Family] | [Weight] | [Size] | [Line height] |

**Font loading:** [How fonts are loaded -- Google Fonts, local files, system fonts, etc.]

## Spacing and Sizing

| Token | Value | Usage |
|-------|-------|-------|
| spacing-xs | [value] | [Tight gaps, icon padding] |
| spacing-sm | [value] | [Inner padding, form gaps] |
| spacing-md | [value] | [Section padding, card padding] |
| spacing-lg | [value] | [Section margins, major gaps] |
| spacing-xl | [value] | [Page margins, hero spacing] |

### Border Radius

| Token | Value | Usage |
|-------|-------|-------|
| radius-sm | [value] | [Badges, small elements] |
| radius-md | [value] | [Buttons, inputs, cards] |
| radius-lg | [value] | [Modals, large containers] |
| radius-full | 9999px | [Avatars, circular elements] |

## Component Style

### General Characteristics

- **Edges:** [Rounded / Sharp / Mixed -- describe the approach]
- **Shadows:** [None / Subtle / Prominent -- describe the approach and when shadows are used]
- **Borders:** [Visible / Minimal / None -- describe when borders appear]
- **Density:** [Compact / Comfortable / Spacious -- describe the information density]

### Buttons

- **Primary:** [Description: fill color, text color, hover behavior, border radius]
- **Secondary:** [Description: outline/ghost style, hover behavior]
- **Destructive:** [Description: color treatment for destructive actions]
- **Disabled:** [Description: opacity, cursor, color changes]

### Inputs

- **Default:** [Description: border style, background, focus ring, placeholder color]
- **Focus:** [Description: ring color, border change, animation]
- **Error:** [Description: border color, helper text color]

### Cards / Panels

- **Background:** [Surface color, border, shadow, radius]
- **Hover:** [If interactive: hover effect description]

## Animation and Motion

- **Approach:** [Minimal / Moderate / Expressive -- describe the philosophy]
- **Transitions:** [Duration and easing for standard transitions, e.g., "150ms ease-out for hover, 200ms ease-in-out for layout changes"]
- **Specific animations:** [List any product-specific animations, e.g., "Pulse animation on incoming knock", "Fade-in for new device discovery"]

## Toolkit Configuration

This section translates the design decisions above into implementable configuration for the project's specific CSS framework and component library.

### [CSS Framework] Configuration

[E.g., "Tailwind CSS Configuration" -- provide the actual config values]

```[language]
// [config file name, e.g., tailwind.config.js theme extend section]
[Actual configuration code that implements the color palette, typography, spacing, and border radius defined above]
```

### [Component Library] Theme

[E.g., "shadcn-svelte Theme Variables" -- provide the actual CSS custom properties or theme config]

```css
/* [Description of where these variables live, e.g., app.css :root block] */
[Actual CSS custom properties or theme configuration that customizes the component library]
```

### Global CSS

```css
/* Base styles applied globally */
[Any global CSS needed: font imports, base resets, custom utility classes]
```

## Visual Grounding

### References
[Inspirational images that informed the style direction. These guide the overall feel but are not pixel-level targets.]

| Source | Path | What it informs |
|--------|------|-----------------|
| [URL or description] | [visual-grounding/references/filename.png] | [colors / layout / feel] |

### Designs
[Design mockups that serve as specification targets. These are the ground truth for visual fidelity.]

| Source | Path | Screens covered |
|--------|------|----------------|
| [Figma / Canva / hand-drawn] | [visual-grounding/designs/filename.png] | [which screens or components] |

### Brand
[Fixed brand assets that must be incorporated.]

| Asset | Path | Constraint |
|-------|------|-----------|
| [Logo / color spec / typeface] | [visual-grounding/brand/filename.png] | [how it constrains the design] |

[If no visual grounding assets were provided, note: "No visual grounding assets. Style derived from verbal description only."]
```

---

## Section Guidance

| Section | Source | Depth |
|---------|--------|-------|
| Design Direction | User's description + UX specialist analysis | 2-3 sentences capturing the feel |
| Color Palette | UX specialist recommendation + user refinement | Exact values, all roles covered |
| Typography | UX specialist recommendation + user refinement | Exact values for all text roles |
| Spacing and Sizing | UX specialist recommendation | Token table with concrete values |
| Component Style | UX specialist recommendation + user preferences | Descriptive characteristics per component type |
| Animation and Motion | User preferences + UX specialist guidance | Philosophy + specific animations |
| Toolkit Configuration | Translated from design tokens by skill | Actual code that can be copy-pasted into config files |
| Visual Grounding | User-provided + MCP exports + URL captures | Three categories: references (inspirational), designs (specification), brand (constraints). Paths to files in visual grounding directory. |
