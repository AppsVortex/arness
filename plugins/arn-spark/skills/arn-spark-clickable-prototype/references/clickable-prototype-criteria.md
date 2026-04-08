# Clickable Prototype Default Criteria

This template provides the default criteria for interaction validation of clickable prototypes. The `arn-spark-clickable-prototype` skill proposes these criteria based on available project artifacts (product concept, style brief, screen list). The user confirms or adjusts before validation begins.

## Default Criteria

### Navigation

| # | Criterion | Description |
|---|-----------|-------------|
| 1 | Screen reachability | Every screen is reachable from the navigation index and via the defined navigation flow |
| 2 | Navigation consistency | Navigation elements (nav bar, sidebar, breadcrumbs) appear consistently and indicate the current location |
| 3 | Back navigation | Users can return to previous screens without using the browser back button |
| 4 | No dead ends | Every screen has at least one navigation path forward or back |

### Interaction

| # | Criterion | Description |
|---|-----------|-------------|
| 5 | Clickable elements respond | All buttons, links, and interactive elements respond to clicks (visual feedback or navigation) |
| 6 | Form elements functional | Input fields accept text, dropdowns open, checkboxes toggle, selects work |
| 7 | State changes visible | Interactive state changes (selected, active, expanded, collapsed) are visually clear |
| 8 | Transition smoothness | Page transitions and component state changes are smooth, not jarring or broken. Animations use appropriate easing and duration for the platform. |
| 9 | Animation implementation | If the style brief has an Animation and Motion section: all specified animations are implemented with the correct approach, triggers, and behavior. Entrance sequences play on the documented triggers. State transitions match specified timing. Animation descriptions in the style brief use platform-agnostic intent language — the prototype translates that intent to the project's specific technology. |

### User Journeys

| # | Criterion | Description |
|---|-----------|-------------|
| 10 | Journey completability | Each defined user journey can be completed from start to finish without errors |
| 11 | Journey clarity | At each step of a journey, the next action is obvious to the user |
| 12 | Error state handling | If the prototype shows error states, they are visually clear and provide guidance |

### Visual Consistency

| # | Criterion | Description |
|---|-----------|-------------|
| 13 | Style brief adherence | Visual style (colors, typography, spacing) matches the style brief across all screens |
| 14 | Component consistency | Same component types look and behave the same across all screens |
| 15 | Responsive behavior | If specified: layout adapts correctly at target viewport sizes |

### Build Quality

| # | Criterion | Description |
|---|-----------|-------------|
| 16 | No JavaScript errors | Prototype runs without console errors during normal interaction |
| 17 | No broken assets | All images, icons, and fonts load correctly |

## Adapting Criteria

- **If no style brief exists:** Remove criteria 13-14. Focus on navigation and interaction.
- **If no user journeys are defined:** Remove criteria 10-12. Add them once journeys are defined.
- **If desktop-only (no responsive):** Remove criterion 15.
- **If specific interaction patterns were discussed:** Add per-pattern criteria (e.g., drag-and-drop, keyboard navigation, accessibility).
- **If reference images exist** (in visual grounding `references/`): Add criterion:
  "Reference alignment — screen layouts and overall flow feel align with the reference direction"
- **If design mockups exist** (in visual grounding `designs/`): Add criterion:
  "Design fidelity — screen layouts match the provided design mockups in structure, component placement, and flow"
- **If brand assets exist** (in visual grounding `brand/`): Add criterion:
  "Brand compliance — brand elements appear correctly across all screens"

- **If no style brief Animation section exists or it says "none":** Remove criterion 9 (Animation implementation). Criterion 8 (Transition smoothness) still applies to basic transitions.
- **If style brief specifies animations:** Both criteria 8 and 9 apply. Pass the style brief's Animation and Motion section to expert reviewers and the judge so they can compare implementation against specification.

The user may add, remove, or modify any criterion before validation begins.
