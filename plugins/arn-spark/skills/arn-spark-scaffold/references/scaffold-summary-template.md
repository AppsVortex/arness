# Scaffold Summary Template

This template defines the structure for the scaffold summary document written by the `arn-spark-scaffold` skill after a successful scaffolding. The document is saved to the project's Vision directory as `scaffold-summary.md`.

A scaffold summary records the full technology stack including UI toolkit decisions made during scaffolding. The architecture vision captures high-level technology choices, but CSS framework, component library, and icon library are decided during scaffolding. Downstream skills (style-explore, static-prototype, clickable-prototype, feature-extract) need this information to make informed decisions.

## Instructions for arn-spark-scaffold

When populating this template:

- Fill in all sections from the scaffold results and UI toolkit decisions
- Version numbers should reflect what was actually installed, not what was planned
- Commands should be copy-pasteable — no placeholders
- If a layer was not applicable (e.g., no icon library), omit it from the table
- The Pillar Alignment section should only appear if product pillars exist

---

## Template

```markdown
# [Product Name] - Scaffold Summary

## Technology Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| Application framework | [value] | [version] |
| UI framework | [value] | [version] |
| Language | [value] | [version] |
| CSS framework | [value] | [version] |
| Component library | [value] | [version] |
| Icon library | [value or "none"] | [version] |
| Build tool | [value] | [version] |
| Package manager | [value] | [version] |
| Test framework | [value] | [version] |
| Linter/formatter | [value] | [version] |

## Pillar Alignment

[Only include if product pillars exist. Assess how the UI toolkit decisions (CSS framework, component library) serve each pillar.]

| Pillar | Status | How the Toolkit Serves It |
|--------|--------|--------------------------|
| [Pillar name] | Supported / At Risk | [Specific explanation referencing the CSS framework, component library, or icon library choice.] |

## Key Files

[List the important configuration and entry point files created during scaffolding, grouped by category.]

**Configuration:**
- [file path] — [brief purpose]

**Entry points:**
- [file path] — [brief purpose]

**UI toolkit:**
- [file path] — [brief purpose, e.g., "Tailwind config with content paths"]

## Commands

| Action | Command |
|--------|---------|
| Dev server | `[command]` |
| Build | `[command]` |
| Test | `[command]` |
| Lint | `[command]` |

## Build Verification

- **Build result:** [pass/fail]
- **Warnings:** [any warnings, or "none"]
- **Issues resolved during scaffolding:** [any problems encountered and how they were fixed, or "none"]
```
