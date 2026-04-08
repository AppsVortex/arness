# Static Prototype Default Criteria

This template provides the default criteria for visual validation of static component showcases. The `arn-spark-static-prototype` skill proposes these criteria based on available project artifacts (style brief, product concept). The user confirms or adjusts before validation begins.

## Default Criteria

### Visual Fidelity

| # | Criterion | Description |
|---|-----------|-------------|
| 1 | Color palette accuracy | All color roles (primary, secondary, accent, background, text, border) match the style brief hex values |
| 2 | Typography conformance | Font families, weights, and sizes match the style brief specifications |
| 3 | Spacing consistency | Spacing tokens (padding, margins, gaps) are applied consistently and match the style brief |
| 4 | Border radius conformance | Component corner radii match the style brief specifications |
| 5 | Shadow and elevation | Box shadows and elevation effects match the style brief (or absent if not specified) |

### Component Quality

| # | Criterion | Description |
|---|-----------|-------------|
| 6 | Component variant coverage | All specified component variants (sizes, states) are rendered |
| 7 | State representation | Interactive states (default, hover, active, disabled, error) are visually distinct |
| 8 | Component library usage | Components use the project's actual component library, not custom implementations |
| 9 | Theme integration | Component library theme configuration is applied globally, not per-component overrides |

### Layout and Composition

| # | Criterion | Description |
|---|-----------|-------------|
| 10 | Visual hierarchy | Heading, body, and caption text establish clear hierarchy |
| 11 | Alignment and grid | Components align to a consistent grid or layout system |
| 12 | Content density | Spacing between elements matches the intended density (compact, moderate, spacious) |

### Overall Impression

| # | Criterion | Description |
|---|-----------|-------------|
| 13 | Style brief adherence | Overall visual impression matches the style brief's described feel and direction |
| 14 | Dark mode consistency | If dark mode is specified: all components render correctly in dark mode with appropriate contrast |

## Adapting Criteria

- **If no style brief exists:** Remove criteria 1-5 and 13-14. Focus on component quality and layout.
- **If no dark mode:** Remove criterion 14.
- **If reference images exist** (in visual grounding `references/`): Add criterion:
  "Reference alignment — overall visual direction aligns with provided reference images"
- **If design mockups exist** (in visual grounding `designs/`): Add criterion:
  "Design fidelity — component rendering matches the provided design mockups in layout, spacing, and proportions"
- **If brand assets exist** (in visual grounding `brand/`): Add criterion:
  "Brand compliance — brand elements (logos, colors, typefaces) are correctly incorporated"
- **If specific components were discussed:** Add per-component criteria as needed.
- **If style brief specifies animations:** Add criterion: "Animation readiness — Elements that will be animated have correct initial states (e.g., opacity: 0 for fade-in elements), data attributes for animation targeting, and appropriate class names or identifiers. The animation approach's imports are present. Animations may not be fully wired to triggers in the static prototype."

The user may add, remove, or modify any criterion before validation begins.
