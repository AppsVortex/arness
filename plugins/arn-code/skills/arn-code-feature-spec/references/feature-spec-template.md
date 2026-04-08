# Feature Spec Template

This template defines the structure for feature specification documents written by the `arn-code-feature-spec` skill. The spec is saved to the project's specs directory as `FEATURE_<name>.md`, or as `FEATURE_F-NNN.M_<sub-feature-name>.md` for sub-feature specs created by XL decomposition.

A spec captures WHAT to build and WHY — not HOW (that is the plan's job).

## Instructions for arn-code-feature-spec

When populating this template:
- Every section below MUST appear in the output, even if the content is brief
- **Sections marked "(if UI involved)" are only included when the feature involves user interface work.** Omit them entirely for backend-only features.
- **Sections marked "(if backlog entry exists)" are only included when the feature was loaded from a greenfield feature backlog with use case documents (Step 1b of the skill).** Omit them entirely for features described ad-hoc by the user. When included, these sections carry behavioral detail that grounds the spec in validated upstream artifacts.
- **Sections marked "(if sketch exists)" are only included when a arn-code-sketch session has produced validated sketch components for this feature.** Omit them entirely when no sketch exists. When included, these sections carry component mapping and composition metadata that tells the planner which components to promote from sketch rather than create from scratch.
- **Sections marked "(if style-brief exists)" are only included when greenfield context was loaded AND a style-brief was found during loading.** Omit them entirely when no style-brief exists. These sections carry validated design tokens from prototype showcases.
- **Sections marked "(if animation context exists)"** are only included when the style brief has an Animation and Motion section. Omit them entirely when no animation context exists.
- **Sub-feature specs (F-NNN.M):** When writing a spec for a sub-feature created by XL decomposition, the Feature Backlog Entry section includes `Parent feature`, `Parent issue`, and `Sibling sub-features` fields. The Behavioral Specification sections (Main Success Scenarios, Key Extensions, Business Rules) are scoped to this sub-feature's journey segment only. The Scope & Boundaries section explicitly states which sibling sub-features handle adjacent concerns.
- When a backlog entry is loaded, Functional Requirements should be derived from the feature file's Acceptance Criteria and UC main success scenarios. Do not invent requirements that contradict the loaded behavioral specification.
- Replace all bracketed placeholders with concrete content from the exploration conversation
- If information is missing for a section, write what you know and add the gap to Open Items
- Tables should have real data, not example rows — remove example rows if no data is available
- Do NOT include implementation phases, task ordering, testing approach, or any HOW detail — that belongs in the plan
- Key Decisions (in Architectural Assessment) captures architectural and technical choices validated by arn-code-architect. Decisions Log captures all scope, preference, and design decisions from the exploration conversation chronologically. They may overlap for architectural decisions -- that is expected.

---

## Template

```markdown
# [Feature Name] — Specification

## Problem Statement

**What:** [1-2 sentences describing what the user wants to build or change]

**Why:** [1-2 sentences describing the problem this solves or the value it provides]

**Target project:** [Project name and root path]

---

## Requirements

### Functional Requirements

1. [Concrete, testable requirement]
2. [Concrete, testable requirement]
3. [Additional requirements as needed]

### Non-Functional Requirements

- [Performance: e.g., response time, throughput, resource limits]
- [Security: e.g., auth, input validation, data protection]
- [Reliability: e.g., error handling, graceful degradation]
- [Maintainability: e.g., code style, documentation, modularity]
- [Accessibility (if UI involved): e.g., WCAG level, keyboard navigation, screen reader support]
- [Remove any categories that do not apply]

---

## Architectural Assessment

### Proposed Approach

[2-4 sentences from arn-code-architect describing the overall approach. What are we building, how does it fit into the existing architecture, and what patterns does it follow?]

### Key Decisions

| Decision | Choice | Rationale | Status |
|----------|--------|-----------|--------|
| [Decision area] | [What was chosen] | [Why this choice was made] | Decided / Open |

### Components

| Component | Action | File(s) | Pattern Reference |
|-----------|--------|---------|-------------------|
| [Component name] | Create / Modify / Extend | `path/to/file` | [Pattern from codebase] |

### Integration Points

- [Where new code connects to existing code, with file paths]
- [API boundaries, shared state, event hooks, etc.]

---

## Proposed UI Stack (if UI involved — greenfield only)

> Include this section only when the feature introduces a frontend to a project that does not yet have one. Omit for projects with an existing frontend or for backend-only features.

- **Component library:** [Recommendation with rationale]
- **Styling approach:** [Recommendation with rationale]
- **State management:** [Recommendation with rationale]
- **Design system:** [Recommendation or "Custom" with rationale]

---

## UI Design (if UI involved)

> Include this section when the feature involves user interface work. Content comes from `arn-code-ux-specialist` analysis.

### User Experience Goals

- [Primary user goals this UI serves]
- [Key usability principles guiding the design]

### Component Hierarchy

| Component | Action | File(s) | Props / Inputs | Behavior |
|-----------|--------|---------|----------------|----------|
| [Component name] | Create / Modify / Reuse | `path/to/component` | [Key props] | [What it does, user interactions] |

### User Flows

- [Key user journey through the feature: entry point → steps → outcome]
- [Error / edge-case flows]

### State Management

- [How state flows between components]
- [Which state is local vs. shared vs. server-side]

### Accessibility Requirements

- **WCAG compliance level:** [2.1 AA / AAA / project-specific]
- **Keyboard navigation:** [Plan for keyboard interaction]
- **Screen reader:** [ARIA labels, live regions, focus management]
- **Visual:** [Color contrast, motion preferences, text sizing]

### Responsive Design

- [Breakpoint strategy]
- [Mobile-first vs. desktop-first]
- [Layout adaptations per breakpoint]

### Motion Design (if animation context exists)

| Element | Animation Type | Trigger | Duration / Easing | Reduced Motion Fallback |
|---------|---------------|---------|-------------------|------------------------|
| [component/element] | [entrance / exit / state-change / feedback / scroll-triggered] | [page-load / scroll-position / user-action / state-change] | [e.g., 0.6s ease-out] | [e.g., instant display, no animation] |

**Motion design system reference:** [style-brief Animation section tokens — timing scale, easing functions, stagger values]

**Animation approach:** [from style-brief — the technique/library/framework API used for this project]

*All animation descriptions use platform-agnostic intent language. The implementation translates intent to the project's specific technology.*

### Design Tokens (if style-brief exists)

> Include this section only when greenfield context was loaded and a style-brief exists. Omit entirely if no style-brief was found.

**Style brief:** `[path to style-brief.md]`
**Toolkit:** [CSS framework + component library]

| Token Category | Key Values | Source |
|---------------|-----------|--------|
| Primary colors | [from style-brief] | Validated in static showcase v[N] |
| Typography | [heading/body tokens] | Validated in static showcase v[N] |
| Spacing | [spacing scale] | Validated in static showcase v[N] |
| Motion Design | [animation timing tokens, easing curves, stagger values] | Validated in prototype v[N] |

[Reference the style-brief for the full toolkit configuration. Implementation should use these exact tokens rather than defining new ones.]

---

## Scope & Boundaries

**In Scope:**
- [What this feature includes]

**Out of Scope:**
- [What this feature explicitly does NOT include]

---

## Sketch Reference (if sketch exists)

> Include this section when a arn-code-sketch session has produced validated sketch components for this feature. Omit entirely when no sketch exists.

**Sketch directory:** `[path to arness-sketches/<sketch-name>/]`
**Manifest:** `[path to arness-sketches/<sketch-name>/sketch-manifest.json]`
**Status:** [active / completed]
**Paradigm:** [web / cli / tui / desktop-web / desktop-python / desktop-dotnet / mobile-rn / mobile-flutter]

### Component Mapping

| Sketch Component | Target Location | Mode | Description |
|-----------------|----------------|------|-------------|
| `[sketch file path]` | `[target file path in real codebase]` | direct / refine | [What this component does and why this promotion mode] |

### Composition Summary

**Blueprint:** `[path to blueprint file that shows how components are assembled]`
**Layout:** [Brief description of spatial arrangement — e.g., "sidebar + main content area with header"]
**Data flow:** [Brief description of data dependencies — e.g., "DeviceList fetches from API, passes selected device to DeviceDetail"]
**Interaction flow:** [Brief description of user interaction sequence — e.g., "User selects device → detail panel loads → edit button opens modal"]

---

## Behavioral Specification (if backlog entry exists)

> Include this section when the feature comes from a greenfield feature backlog
> with use case documents. Omit for features described ad-hoc by the user.

### Feature Backlog Entry

**Feature:** F-NNN: [Feature Name]
**Issue:** [SCRUM-NN / #NN / --]
**Priority:** [Must-have / Should-have / Nice-to-have]
**Phase:** [Foundation / Core / Enhancement / Polish]
**Dependencies:** [F-NNN list or None]
**Feature file:** `[path to F-NNN file]`

[If this is a sub-feature spec (F-NNN.M), include the parent reference:]
**Parent feature:** F-NNN: [Parent Feature Name]
**Parent issue:** [#NN / PROJ-NN / --]
**Sibling sub-features:** [F-NNN.1: Name, F-NNN.2: Name, ...] (excluding this one)

### Use Case References

| UC | Title | File | Steps | Extensions |
|----|-------|------|-------|------------|
| UC-NNN | [Title] | `[path]` | [N] | [K] |

### Main Success Scenarios

[For each referenced UC, the key steps from the main success scenario.
Not the full verbatim copy -- a focused summary preserving step numbers
for traceability. Include screen references from the UC.]

### Key Extensions (Error & Alternate Paths)

[Extension paths from the UC documents that define error handling,
edge cases, and alternate flows the implementation must cover.
Group by UC, preserve extension identifiers (e.g., 5a, 5b).]

### Business Rules & Constraints

[Merged business rules from the UC documents.
Include BR identifiers for traceability.]

### Acceptance Criteria

[Carried forward from the feature file. These become the
verification checklist for the implementation.]

---

## Feasibility & Risks

- [Risk or dependency with mitigation if known]
- [Uncertainty that needs investigation]
- [External dependency or constraint]

---

## Decisions Log

1. [Decision made during the exploration conversation, with brief rationale]
2. [Another decision]

---

## Open Items

- [Unresolved question or decision needed from the user]
- [Risk that needs monitoring or mitigation]
- [Area that needs more investigation before implementation]

---

## Recommendation

[Brief statement: ready for planning / needs more investigation on X]

To create a plan: Run `/arn-code-plan FEATURE_<name>`
```

---

## Section Guidance

| Section | Source | Depth |
|---------|--------|-------|
| Problem Statement | User's feature description + conversation | 2-4 sentences total across What/Why |
| Requirements | Conversation decisions + user clarifications | 3-8 functional, 2-5 non-functional |
| Architectural Assessment | arn-code-architect proposals | Tables + 2-4 sentences approach |
| Proposed UI Stack | arn-code-ux-specialist (greenfield only) | 4 items with rationale; omit if existing frontend or backend-only |
| UI Design | arn-code-ux-specialist analysis | UX goals, component table, user flows, state, a11y, responsive; omit if backend-only |
| Design Tokens | style-brief.md (validated through prototype showcases); only when greenfield + style-brief loaded | Token table with 3 categories (colors, typography, spacing) + toolkit reference. Do NOT invent token values — use validated tokens as-is. |
| Motion Design | arn-code-ux-specialist + style-brief Animation tokens | Per-element animation specs with triggers, timing, and reduced-motion fallbacks; only when animation context loaded |
| Scope & Boundaries | Conversation decisions | 2-5 bullets per subsection |
| Sketch Reference | sketch-manifest.json (componentMapping + composition); only when sketch exists for this feature | Component mapping table + composition summary (blueprint, layout, data flow, interaction flow). Omit entirely if no sketch exists. |
| Behavioral Specification | Feature file (F-NNN) + UC documents | UC steps summarized, extensions listed, BRs and ACs carried forward verbatim; omit if no backlog entry. For sub-feature specs (F-NNN.M): scoped to the sub-feature's journey segment; includes parent reference and sibling listing |
| Feasibility & Risks | arn-code-architect + arn-code-ux-specialist analysis + conversation | 2-6 bullets with mitigations |
| Decisions Log | Accumulated from exploration conversation | All decisions, numbered |
| Open Items | Accumulated from conversation | All unresolved items |
| Recommendation | Skill's overall assessment | 1-2 sentences + next-step instruction |
