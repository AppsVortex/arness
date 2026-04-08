# Specialist Pre-Check

This reference defines the deterministic pre-check logic for UI involvement and security relevance. Skills that parallelize agent dispatches (swift, standard, feature-spec) read this file to decide which specialists to include in the parallel batch.

The checks are deterministic -- they use file existence and text matching, not agent judgment. This allows the skill to make dispatch decisions before any agent runs.

---

## UI Involvement Check

A feature is considered **UI-involved** if ANY of the following conditions is true:

### Condition 1: UI Patterns with Sketch Strategy

The project's `ui-patterns.md` file (at the code patterns path from `## Arness`) exists AND contains a `## Sketch Strategy` section.

### Condition 2: UI Terms in Feature Description

The feature description (from the spec or user input) contains any of these terms (case-insensitive):

`component`, `page`, `form`, `button`, `layout`, `dashboard`, `UI`, `UX`, `screen`, `view`, `modal`, `dialog`, `command`, `terminal`, `output`, `widget`, `window`, `panel`, `console`, `display`, `prompt`, `menu`, `toolbar`, `status bar`, `progress`, `table`, `tree`, `sidebar`, `navigation`, `nav`, `dropdown`, `select`, `card`, `input`, `toast`, `notification`

### Condition 3: Frontend Framework in Architecture

The project's `architecture.md` file (at the code patterns path from `## Arness`) contains a Technology Stack section that references a frontend, CLI, TUI, desktop, or mobile framework. Look for framework names such as: React, Next.js, Vue, Nuxt, Angular, Svelte, SvelteKit, Astro, Remix, Gatsby, Electron, Tauri, Flutter, React Native, Expo, Swift UI, Jetpack Compose, Qt, GTK, Textual, Rich, Ink, Blessed, Bubbletea, Charm, Click, Typer, Commander, Inquirer, Oclif, Vorpal.

---

## Security Relevance Check

A feature is considered **security-relevant** if BOTH of the following conditions are true:

### Condition 1: Security Patterns Exist

The project's `security-patterns.md` file (at the code patterns path from `## Arness`) exists.

### Condition 2: Security Terms in Feature Description

The feature description (from the spec or user input) contains any of these terms (case-insensitive):

`auth`, `login`, `password`, `token`, `payment`, `upload`, `API key`, `PII`, `encrypt`, `permission`, `session`, `cookie`, `CORS`, `CSRF`, `rate limit`, `secret`, `credential`, `OAuth`, `SSO`, `JWT`, `MFA`, `2FA`, `SAML`

---

## Result Format

The pre-check produces two boolean flags:

```
ui_involved: true | false
security_relevant: true | false
```

These flags determine which agents to include in the parallel dispatch:

| ui_involved | security_relevant | Agents Dispatched in Parallel |
|-------------|-------------------|-------------------------------|
| false | false | architect only |
| true | false | architect + UX specialist |
| false | true | architect + security specialist |
| true | true | architect + UX specialist + security specialist |

---

## Silent Sequential Follow-Up

The pre-check is deterministic but not infallible. A false negative can occur when:

- The feature description does not contain obvious UI/security terms, but the architect discovers UI or security implications during assessment.
- The project lacks `ui-patterns.md` or `security-patterns.md`, but the feature still has UI or security concerns.

### Follow-Up Rule

After the parallel agent batch completes, check the architect's assessment for signals that a missed specialist should have been included:

- If the architect's output mentions UI concerns, component design, user interaction, or interface layout AND `ui_involved` was `false`: dispatch the UX specialist sequentially with the architect's assessment as additional context.
- If the architect's output mentions security concerns, authentication, authorization, data protection, or vulnerability AND `security_relevant` was `false`: dispatch the security specialist sequentially with the architect's assessment as additional context.

The follow-up dispatch is **silent** -- no user notification or status message. The user sees the combined assessment from all agents (parallel + sequential) as a single result. The goal is correctness, not speed -- a missed specialist is worse than a slight delay.
