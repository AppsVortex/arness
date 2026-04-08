# Pattern Documentation Schema

This file defines the canonical schema for Arness pattern documentation files. It is the single source of truth for the format that both the `arn-code-codebase-analyzer` and `arn-code-pattern-architect` agents must produce.

The output conforming to this schema gets split into **up to five separate files** stored at the user-chosen pattern docs directory (default `.arness/`):

1. `code-patterns.md` — naming conventions, project structure, API patterns, data layer, error handling, configuration
2. `testing-patterns.md` — test framework setup, test organization, fixtures, markers, setup/teardown
3. `architecture.md` — technology stack, architectural decisions, dependencies, project layout, codebase references
4. `ui-patterns.md` *(optional — projects with a user-facing interface)* — interface patterns: component/widget/output patterns, layout/styling, state management, accessibility, navigation
5. `security-patterns.md` *(optional — generated when security-relevant patterns are detected)* — authentication, authorization, input validation, data protection, API security, dependency security

**Existing codebases vs. greenfield projects:** For existing codebases, `Reference` fields must contain real file paths with line numbers (e.g., `src/app/main.py:15-30`). For greenfield projects where no code exists yet, `Reference` should say `"Recommended"` or `"Best practice"`.

---

## File 1: `code-patterns.md`

### Structure

```markdown
# Code Patterns

## Project Stack
- **Language:** [language and version if known]
- **Framework:** [framework and version]
- **Package manager:** [npm/uv/pip/cargo/etc.]
- **Project layout:** [src layout/flat/monorepo/etc.]

## Naming Conventions

### Pattern: [Name]
**Description:** [What this pattern is and when to use it]
**Reference:** `path/to/file.ext:lines` | "Recommended" (for greenfield)
**Example:**
\`\`\`[language]
actual code snippet or recommended code
\`\`\`
**How to apply:** [Concrete instructions]

## Project Structure
[same per-pattern format]

## API / Routing Patterns
[same per-pattern format]

## Data Layer
[same per-pattern format]

## Error Handling
[same per-pattern format]

## Configuration
[same per-pattern format]
```

### Rules

- **Project Stack** section is always required.
- Pattern sections (Naming Conventions, Project Structure, API / Routing Patterns, Data Layer, Error Handling, Configuration) are optional — skip any category that does not apply to the project.
- For existing codebases: `Reference` must be a real file path with line numbers.
- For greenfield projects: `Reference` should say `"Recommended"` or `"Best practice"`.
- Each pattern section should have 1-3 patterns. Prioritize quality over quantity.
- Code examples must be concrete and copy-pasteable.

---

## File 2: `testing-patterns.md`

### Structure

```markdown
# Testing Patterns

## Test Framework
- **Runner:** [pytest/jest/vitest/go test/cargo test/etc.]
- **Configuration:** [config file location and key settings]

## Test Organization

### Pattern: [Name]
**Description:** [What this pattern is and when to use it]
**Reference:** `path/to/test_file.ext` | "Recommended"
**Example:**
\`\`\`[language]
actual test code snippet or recommended test code
\`\`\`
**Fixtures/Helpers:** [Available fixtures, factories, helpers relevant to this pattern]

## Fixtures & Factories
[same per-pattern format]

## Markers / Tags
[same per-pattern format]

## Setup & Teardown
[same per-pattern format]
```

### Rules

- **Test Framework** section is always required.
- Pattern sections (Test Organization, Fixtures & Factories, Markers / Tags, Setup & Teardown) are optional — skip any category that does not apply to the project.
- Same `Reference` rules as `code-patterns.md`: real file paths for existing codebases, `"Recommended"` for greenfield.
- The `Fixtures/Helpers` field lists what is available for that pattern (e.g., shared fixtures, factory functions, test helpers).

---

## File 3: `architecture.md`

### Structure

```markdown
# Architecture

## Technology Stack

| Layer | Choice | Rationale |
|-------|--------|-----------|
| [Language] | [e.g., Python 3.12] | [Why] |
| [Framework] | [e.g., FastAPI] | [Why] |
| [Database] | [e.g., PostgreSQL] | [Why] |
| [Testing] | [e.g., pytest] | [Why] |

## Key Architectural Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| [e.g., Project layout] | [e.g., src layout] | [Why] |
| [e.g., API style] | [e.g., REST] | [Why] |

## Dependencies

### External
- [library/service] — [purpose]

### Internal
- [module/package] — [purpose]

## Project Layout

[ASCII tree or description of directory structure]

## Codebase References

| Area | File Path | Purpose |
|------|-----------|---------|
| [e.g., Entry point] | `path/to/main.py` | [What it does] |
| [e.g., Config] | `path/to/settings.py` | [What it does] |

## Architectural Constraints (optional — populated from greenfield architecture-vision)

> Include this section when the project transitioned from greenfield exploration and has an
> architecture-vision.md with pillar alignment and business constraints. Preserves the
> constraint context that influenced technology choices so feature-level decisions stay aligned.

**Product Pillars:**

| Pillar | Constraint | Impact on Implementation |
|--------|-----------|------------------------|
| [Pillar name] | [What it constrains] | [How implementations must comply] |

**Business Constraints:**

| Constraint | Requirement | Technology Implication |
|-----------|------------|----------------------|
| [e.g., Multi-tenant, 500 clients] | [Schema-per-tenant isolation] | [No services with per-project hard limits] |

## Known Risks & Mitigations (optional — populated from greenfield architecture-vision)

| Risk | Impact | Mitigation | Status |
|------|--------|-----------|--------|
| [From architecture-vision.md] | [What happens if unmitigated] | [Planned mitigation] | [Open / Validated via spike / Accepted] |
```

### Rules

- **Technology Stack** and **Project Layout** sections are always required.
- **Key Architectural Decisions** should capture important choices with rationale.
- For existing codebases: the **Codebase References** table must contain real file paths.
- For greenfield projects: **Codebase References** can be omitted or show planned structure.
- **Dependencies** section lists both external (libraries/services) and internal (modules/packages).
- **Architectural Constraints** and **Known Risks & Mitigations** are optional — populated automatically when transitioning from a greenfield project that has an architecture-vision.md. They are preserved across upgrades and should not be removed.

---

## File 4: `ui-patterns.md` (optional — projects with a user-facing interface)

This file is generated when the project has a user-facing interface — web frontend, CLI with formatted output, TUI, desktop GUI, or mobile app. It is triggered when the project type is "frontend", "fullstack", "cli", "tui", "desktop", or "mobile", or when the codebase analyzer detects an interface framework or output library. Do not create it for projects with no user-facing output (pure libraries, background services, data pipelines).

### Structure

```markdown
# UI Patterns

## UI Stack

The fields in this section are paradigm-dependent. Populate only the fields relevant to the detected interface paradigm.

### Web (frontend/fullstack)
- **Component library:** [shadcn/ui, Material UI, Vuetify, custom, etc.]
- **Styling approach:** [Tailwind CSS, CSS Modules, styled-components, Sass, etc.]
- **Design system:** [Custom, Material Design, none, etc.]
- **State management:** [Redux, Zustand, Pinia, Context API, signals, etc.]

### CLI
- **Output library:** [Rich, click.echo, Typer, Colorama, tabulate, etc.]
- **Output format:** [tables, panels, progress bars, JSON, plain text, etc.]
- **Color/styling:** [Rich markup, ANSI codes, Colorama, none, etc.]

### TUI
- **Widget framework:** [Textual, Bubble Tea, ratatui, urwid, etc.]
- **Layout system:** [docking, grid, flex, etc.]
- **Theme system:** [CSS (Textual), lipgloss (Bubble Tea), custom, etc.]

### Desktop
- **Widget toolkit:** [PyQt5/6, PySide6, tkinter, Electron, Tauri, WPF, SwiftUI, etc.]
- **Layout system:** [box layout, grid, constraints, auto layout, etc.]
- **Theming approach:** [Qt stylesheets, system native, custom, etc.]

### Mobile
- **Component framework:** [React Native, Flutter, SwiftUI, Jetpack Compose, etc.]
- **Navigation library:** [React Navigation, go_router, UINavigationController, etc.]
- **State management:** [Redux, Riverpod, Provider, Bloc, Combine, etc.]

## Component Patterns

### Pattern: [Name]
**Description:** [What this pattern is and when to use it]
**Reference:** `path/to/component.ext` | "Recommended"
**Example:**
\`\`\`[language]
actual component code snippet or recommended code
\`\`\`
**How to apply:** [Concrete instructions for creating components following this pattern]

## Layout & Styling

### Pattern: [Name]
**Description:** [What this pattern is and when to use it]
**Reference:** `path/to/styles.ext` | "Recommended"
**Example:**
\`\`\`[language]
actual styling code snippet or recommended code
\`\`\`
**How to apply:** [Concrete instructions]

## State Management (UI)

### Pattern: [Name]
**Description:** [What this pattern is and when to use it]
**Reference:** `path/to/store.ext` | "Recommended"
**Example:**
\`\`\`[language]
actual state management code snippet or recommended code
\`\`\`
**How to apply:** [Concrete instructions]

## Accessibility

### Pattern: [Name]
**Description:** [What this pattern is and when to use it]
**Reference:** `path/to/component.ext` | "Recommended"
**Example:**
\`\`\`[language]
actual accessibility code snippet or recommended code
\`\`\`
**How to apply:** [Concrete instructions]

## Form Handling

### Pattern: [Name]
**Description:** [What this pattern is and when to use it]
**Reference:** `path/to/form.ext` | "Recommended"
**Example:**
\`\`\`[language]
actual form handling code snippet or recommended code
\`\`\`
**How to apply:** [Concrete instructions]

## Navigation & Routing

### Pattern: [Name]
**Description:** [What this pattern is and when to use it]
**Reference:** `path/to/routes.ext` | "Recommended"
**Example:**
\`\`\`[language]
actual routing code snippet or recommended code
\`\`\`
**How to apply:** [Concrete instructions]

## Animation & Transitions

### Pattern: [Name]
**Description:** [What this pattern is and when to use it]
**Reference:** `path/to/animation.ext` | "Recommended"
**Example:**
\`\`\`[language]
actual animation code snippet or recommended code
\`\`\`
**How to apply:** [Concrete instructions]

## Paradigm-Specific Sections

The following sections are alternatives to the web-specific sections above. Use the set that matches the project's interface paradigm. Some sections (Accessibility, State Management (UI), Form Handling) remain applicable across paradigms and should still be included when relevant.

### CLI paradigm sections (use instead of Component Patterns, Layout & Styling, Navigation & Routing, Animation & Transitions)
- **CLI Output Formatting** — Tables, panels, progress bars, spinners, color usage, output templating
- **CLI Command Structure** — Command groups, subcommands, argument parsing, option handling, defaults
- **CLI Help & Documentation** — Help text formatting, man page generation, usage examples, error messages

### TUI paradigm sections (use instead of Component Patterns, Layout & Styling, Navigation & Routing, Animation & Transitions)
- **TUI Widget Patterns** — Widget composition, custom widgets, widget lifecycle, data binding
- **TUI Layout** — Screen regions, docking, grid, responsive terminal sizing, panel management
- **TUI Keybindings & Navigation** — Key maps, focus management, modal dialogs, command palette

### Desktop paradigm sections
- Use the standard web section names (Component Patterns, Layout & Styling, etc.) with paradigm-appropriate content. Desktop UI patterns are structurally similar to web component patterns.

### Mobile paradigm sections
- Use the standard web section names (Component Patterns, Layout & Styling, Navigation & Routing, etc.) with paradigm-appropriate content. Mobile patterns follow the same structure with platform-specific guidance.

## Sketch Strategy

> **Required** when `ui-patterns.md` is generated. Both the `arn-code-codebase-analyzer` and `arn-code-pattern-architect` must populate this section whenever they produce `ui-patterns.md`.

- **Paradigm:** [web | cli | tui | desktop-web | desktop-python | desktop-dotnet | mobile-rn | mobile-flutter]
- **Artifact structure:** [description of what files the sketch produces and where they go — e.g., "standalone HTML+JS in .arness/sketches/" for web, "Python script in .arness/sketches/" for CLI/TUI]
- **Preview mechanism:** [how to preview the sketch — e.g., "open in browser at localhost:PORT", "run `python .arness/sketches/<name>.py` in terminal", "launch desktop app"]
- **Promotion rules:** [how sketch artifacts are promoted into the real codebase — e.g., "copy component into src/components/", "extract output formatting into src/cli/formatters.py"]
```

### Rules

- **UI Stack** section is always required when `ui-patterns.md` is generated.
- **Sketch Strategy** section is always required when `ui-patterns.md` is generated. Both analyzer agents must produce it.
- Web pattern sections (Component Patterns, Layout & Styling, State Management (UI), Accessibility, Form Handling, Navigation & Routing, Animation & Transitions) are optional — use them for web, desktop, and mobile paradigms. Skip any category that does not apply.
- CLI paradigm sections (CLI Output Formatting, CLI Command Structure, CLI Help & Documentation) are optional — use them for CLI projects. Skip any category that does not apply.
- TUI paradigm sections (TUI Widget Patterns, TUI Layout, TUI Keybindings & Navigation) are optional — use them for TUI projects. Skip any category that does not apply.
- Same `Reference` rules as `code-patterns.md`: real file paths with line numbers for existing codebases, `"Recommended"` for greenfield projects.
- Each pattern section should have 1-3 patterns. Prioritize quality over quantity.
- Code examples must be concrete and copy-pasteable.
- This file is only created for projects with a user-facing interface (web frontend, CLI with formatted output, TUI, desktop GUI, mobile app). Do not create it for projects with no user-facing output (pure libraries, background services, data pipelines).

---

## File 5: `security-patterns.md` (optional — generated when security-relevant patterns are detected)

This file is generated when the project has a security surface: authentication, APIs, user input handling, or sensitive data processing. Unlike `ui-patterns.md` (interface projects only), `security-patterns.md` applies to **any project type** — backend, frontend, fullstack, CLI, TUI, desktop, or mobile. For projects with no security surface (e.g., a pure utility library with no auth, no network, no user data), this file is not created.

### Structure

```markdown
# Security Patterns

## Security Stack
- **Authentication:** [JWT, OAuth2, session-based, API keys, none, etc.]
- **Authorization:** [RBAC, ABAC, ACL, middleware-based, none, etc.]
- **Input validation:** [Zod, Joi, Pydantic, marshmallow, manual, etc.]
- **Secrets management:** [env vars, vault, AWS Secrets Manager, dotenv, etc.]

## Authentication

### Pattern: [Name]
**Description:** [What this pattern is and when to use it]
**Reference:** `path/to/auth.ext:lines` | "Recommended"
**Example:**
\`\`\`[language]
actual authentication code snippet or recommended code
\`\`\`
**How to apply:** [Concrete instructions for implementing authentication following this pattern]

## Authorization

### Pattern: [Name]
**Description:** [What this pattern is and when to use it]
**Reference:** `path/to/authz.ext:lines` | "Recommended"
**Example:**
\`\`\`[language]
actual authorization code snippet or recommended code
\`\`\`
**How to apply:** [Concrete instructions]

## Input Validation

### Pattern: [Name]
**Description:** [What this pattern is and when to use it]
**Reference:** `path/to/validation.ext:lines` | "Recommended"
**Example:**
\`\`\`[language]
actual input validation code snippet or recommended code
\`\`\`
**How to apply:** [Concrete instructions]

## Data Protection

### Pattern: [Name]
**Description:** [What this pattern is and when to use it]
**Reference:** `path/to/encryption.ext:lines` | "Recommended"
**Example:**
\`\`\`[language]
actual data protection code snippet or recommended code
\`\`\`
**How to apply:** [Concrete instructions]

## API Security

### Pattern: [Name]
**Description:** [What this pattern is and when to use it]
**Reference:** `path/to/middleware.ext:lines` | "Recommended"
**Example:**
\`\`\`[language]
actual API security code snippet or recommended code
\`\`\`
**How to apply:** [Concrete instructions]

## Dependency Security

### Pattern: [Name]
**Description:** [What this pattern is and when to use it]
**Reference:** `path/to/config.ext:lines` | "Recommended"
**Example:**
\`\`\`[language]
actual dependency security code snippet or recommended code
\`\`\`
**How to apply:** [Concrete instructions]
```

### Rules

- **Security Stack** section is always required when `security-patterns.md` is generated.
- Pattern sections (Authentication, Authorization, Input Validation, Data Protection, API Security, Dependency Security) are optional — skip any category that does not apply to the project.
- Same `Reference` rules as `code-patterns.md`: real file paths with line numbers for existing codebases, `"Recommended"` for greenfield projects.
- Each pattern section should have 1-3 patterns. Prioritize quality over quantity.
- Code examples must be concrete and copy-pasteable.
- Coverage varies by project type: backend projects emphasize auth middleware, parameterized queries, and secrets management; frontend projects emphasize XSS prevention, secure storage, and CSP headers; fullstack projects cover both.
- This file is only created for projects with a security surface. Do not create it for projects with no authentication, no network exposure, no user data handling, and no sensitive data.
