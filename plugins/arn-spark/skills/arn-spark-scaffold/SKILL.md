---
name: arn-spark-scaffold
description: >-
  This skill should be used when the user says "scaffold", "arn scaffold",
  "set up the project", "create project", "initialize project",
  "bootstrap project", "create the skeleton",
  "install dependencies", "configure the project", or wants to create a working
  project skeleton from architecture decisions with installed dependencies,
  configured build tools, and a UI toolkit ready for development.
version: 1.0.0
---

# Arness Scaffold

Set up a working project skeleton from architecture vision decisions through guided conversation, aided by the `arn-spark-scaffolder` agent for project creation and optionally the `arn-spark-tech-evaluator` agent for UI toolkit comparisons. This is a conversational skill that runs in normal conversation (NOT plan mode). The primary artifact is a **buildable project** with all dependencies installed and configured.

This skill covers the initial project setup: framework scaffolding, dependency installation, build configuration, linting, and UI toolkit setup. It does not implement features, create screens, or write application logic -- those are handled by subsequent skills (`/arn-spark-spike`, `/arn-spark-style-explore`, `/arn-spark-static-prototype`, `/arn-spark-clickable-prototype`).

## Prerequisites

An architecture vision document must exist. Check in order:

1. Read the project's `CLAUDE.md` for a `## Arness` section. If found, check the configured Vision directory for `architecture-vision.md`
2. If no `## Arness` section exists or Arness Spark fields are missing, inform the user: "Arness Spark is not configured for this project yet. Run `/arn-brainstorming` to get started — it will set everything up automatically." Do not proceed without it.
3. If `## Arness` exists but no architecture vision found, check `.arness/vision/architecture-vision.md` at the project root

**If an architecture vision is found:** Read it and proceed to Step 1.

**If no architecture vision is found:** Inform the user:

"No architecture vision document found. I recommend running `/arn-spark-arch-vision` first to define your technology stack. The scaffold needs to know which frameworks, build tools, and libraries to set up."

Do not proceed without an architecture vision or explicit technology stack from the user.

Determine the project root:
1. The project root is the working directory unless the user specifies otherwise
2. If the project root already contains a `package.json`, `Cargo.toml`, or similar, warn the user: "This directory already has a project manifest. Do you want to extend the existing project or start fresh in a subdirectory?"

## Workflow

### Step 1: Load Architecture Vision, Product Pillars, and Extract Stack Decisions

Read the architecture vision document. Extract technology decisions for each layer:

- **Application framework:** e.g., Tauri, Electron, plain web
- **UI framework:** e.g., Svelte, React, Vue
- **Language:** e.g., TypeScript, JavaScript
- **Build tool:** e.g., Vite, webpack
- **Package manager:** e.g., npm, pnpm, yarn, bun
- **Test framework:** e.g., Vitest, Jest, Playwright
- **Linter/formatter:** e.g., ESLint + Prettier, Biome

Also load the product concept document (same Vision directory) and extract the **Product Pillars** section if it exists. Pillars guide UI toolkit decisions in Step 2 — for example, a "design fidelity" pillar means the component library must allow full visual customization, while a "simplicity" pillar favors pre-styled components with minimal configuration.

Present the extracted stack and relevant pillars to the user:

"Based on your architecture vision, here is the stack I will scaffold:

| Layer | Technology |
|-------|-----------|
| Framework | [value] |
| UI | [value] |
| Build | [value] |
| ... | ... |

[If pillars found:] Your product pillars that will guide UI toolkit choices:
- **[Pillar]:** [what it implies for CSS/component library decisions]
- ...

Ask (using `AskUserQuestion`):

**"Does this stack look right?"**

Options:
1. **Yes, proceed** — Set up the project with this stack
2. **Adjust** — I want to change something before proceeding"

### Step 2: UI Toolkit Decisions

The architecture vision defines the high-level UI framework (e.g., Svelte) but typically does not specify the CSS approach and component library. These decisions happen now because they affect the scaffold setup and all subsequent work (style exploration, prototyping, production code).

When product pillars are available, annotate each option with how it serves or challenges the pillars. This helps the user make an informed choice aligned with their product's non-negotiable qualities.

**Profile-aware recommendations:** Read user profile. Check `.claude/arness-profile.local.md` first (project override takes precedence), then `~/.arness/user-profile.yaml`. Also check `.arness/preferences.yaml` for project-level team preferences. If the user lists specific frameworks (e.g., "React"), suggest compatible component libraries the user likely knows. If `development_experience: learning`, favor pre-styled libraries (DaisyUI, Chakra) over headless ones (shadcn, Radix) -- pre-styled libraries have less configuration overhead and visible results faster. If `development_experience: non-technical`, favor the most mainstream option with the largest community and most tutorials. Apply the advisory pattern for all toolkit recommendations: present the technically optimal recommendation first, then a preference-aligned alternative with pros/cons if they differ.

Ask the user about each:

**CSS approach:**

Ask (using `AskUserQuestion`):

**"Which CSS framework should we use?"**

Offer common options for the chosen UI framework, noting pillar alignment where relevant. For example, for Svelte with a "design fidelity" pillar:

Options:
1. **Tailwind CSS** (most popular, utility-first) — Supports design fidelity: fine-grained control over every visual detail
2. **UnoCSS** (similar to Tailwind, faster build) — Same control as Tailwind, lighter toolchain
3. **CSS Modules** (scoped styles, no utility framework) — Maximum control but more manual effort
4. **Vanilla CSS** (no framework, component-scoped styles) — Full freedom but no utility shortcuts

**Component library:**

Ask (using `AskUserQuestion`):

**"Which component library should we use?"**

Offer common options for the chosen UI framework + CSS approach, noting pillar alignment. For example, for Svelte + Tailwind with a "design fidelity" pillar:

Options:
1. **shadcn-svelte** (headless components, fully customizable) — Strong pillar fit: unstyled primitives give complete visual control
2. **Skeleton UI** (Svelte-native, Tailwind-based) — Moderate: customizable but has opinionated defaults
3. **DaisyUI** (Tailwind plugin, pre-styled) — Pillar risk: pre-styled components may conflict with custom design direction
4. **None** (build custom components) — Maximum control, highest effort

Note: Limit to 4 options. If more options exist, group or prioritize based on the chosen framework.

**Icon library (optional):**

Ask (using `AskUserQuestion`):

**"Do you want an icon library?"**

Options:
1. **Lucide** — Clean, consistent, popular
2. **Heroicons** — From the Tailwind team
3. **None** — Add later if needed

If the user is unsure about CSS or component library choices, invoke the `arn-spark-tech-evaluator` agent with a head-to-head comparison request for the specific options — include the product pillars so the evaluator can assess pillar alignment. Present the comparison and let the user decide.

Record all UI toolkit decisions for the scaffolder.

### Step 3: Invoke Scaffolder

Invoke the `arn-spark-scaffolder` agent with:

- All stack decisions from Step 1 (framework, UI, build, package manager, test, linter)
- All UI toolkit decisions from Step 2 (CSS framework, component library, icon library)
- Project root path
- Any configuration preferences the user mentioned

The agent creates the project structure, installs dependencies, configures build tools, sets up the UI toolkit, creates a minimal entry point, and runs the build to verify.

**Staging behavior:** When using official project creation tools (npm create, etc.), the scaffolder uses a `_scaffold-staging/` subdirectory to avoid overwriting existing project content (`.arness/`, `CLAUDE.md`, `.git/`, and any other files already present). Generated files are merged into the project root after creation, skipping any that already exist. The staging directory is removed after a successful merge. On failure, the staging directory is left in place so the user can inspect it.

### Step 4: Verify the Scaffold

After the scaffolder reports completion, verify using the scaffold checklist:

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-scaffold/references/scaffold-checklist.md`

Walk through all checklist categories:

1. **Project structure:** Key directories exist (src/, tests/, config files)
2. **Dependency management:** Package manifest exists, dependencies installed without errors, lock file present
3. **Build configuration:** Build tool configured, compiles or bundles without errors
4. **Linting and formatting:** Linter and formatter configured, run without errors on the minimal code
5. **Testing framework:** Test runner configured and executes (even with zero tests)
6. **UI toolkit:** CSS framework configured, component library initialized, a component renders
7. **Git configuration:** .gitignore is appropriate for the stack
8. **Minimal entry point:** App starts and renders something visible
9. **Run instructions:** Dev server, build, test, and lint commands documented

For any failed checks:
- Critical failures (build broken, dependencies not installed): Ask the scaffolder to fix
- Non-critical gaps (missing .gitignore entry): Note for the user

### Step 5: Write Scaffold Summary

Write a scaffold summary document so downstream skills have a record of the full technology stack including UI toolkit decisions made during scaffolding.

1. Read the template:
   > Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-scaffold/references/scaffold-summary-template.md`

2. Populate the template with the scaffolding results:
   - Technology stack with actual installed versions (from the scaffolder's report)
   - UI toolkit decisions from Step 2 (CSS framework, component library, icon library)
   - Pillar alignment assessment (if product pillars exist)
   - Key files created
   - Commands
   - Build verification result

3. Determine the output directory:
   - Read the project's `CLAUDE.md` for the configured Vision directory
   - If not found, use `.arness/vision` at the project root
   - Create the directory if it does not exist

4. Write the document to the Vision directory as `scaffold-summary.md`

### Step 6: Present Results and Recommend Next Steps

Present what was created:

"Project scaffolded successfully. Here is what was set up:

**Stack:**
| Layer | Technology | Version |
|-------|-----------|---------|
| ... | ... | ... |

**Key files created:**
- [list of important configuration and entry point files]

**Commands:**
- Dev server: `[command]`
- Build: `[command]`
- Test: `[command]`
- Lint: `[command]`

**Build result:** [pass/fail]

Scaffold summary saved to `[path]/scaffold-summary.md`.

Recommended next steps:
1. **Set up development environment:** Run `/arn-spark-dev-setup` to configure setup scripts, CI, dev containers, and developer onboarding
2. **Validate critical risks:** Run `/arn-spark-spike` to test technical risks from your architecture vision
3. **Explore visual style:** Run `/arn-spark-style-explore` to define the look and feel"

Adapt next steps based on context. If the architecture vision identified critical risks, emphasize spiking first. If the user is eager to see UI, suggest style exploration.

## Agent Invocation Guide

| Situation | Action |
|-----------|--------|
| Initial scaffold (Step 3) | Invoke `arn-spark-scaffolder` with full stack + UI toolkit decisions |
| User unsure about CSS framework | Invoke `arn-spark-tech-evaluator` with comparison request |
| User unsure about component library | Invoke `arn-spark-tech-evaluator` with comparison request |
| User asks about code patterns | Defer: "Code patterns will be established when features are built. The scaffold just sets up the foundation." |
| User asks about features or screens | Defer: "Features come after the scaffold. Next steps are `/arn-spark-spike` or `/arn-spark-style-explore`." |
| Build fails after scaffold | Ask `arn-spark-scaffolder` to diagnose and fix |

## Error Handling

- **Architecture vision not found:** Cannot proceed. Suggest `/arn-spark-arch-vision` first.
- **Project directory already has code:** Warn the user. Offer to extend the existing project or scaffold in a subdirectory.
- **Scaffold build fails:** Report the error. Invoke scaffolder to fix. If it fails after 3 attempts, present the error and suggest the user investigate manually.
- **Dependency installation fails:** Check network connectivity. Report the specific package that failed. Suggest the user try installing it manually.
- **UI toolkit comparison requested but arn-spark-tech-evaluator unavailable:** Provide a brief comparison from general knowledge and note that it was not verified via web search.
- **User cancels mid-scaffold:** Note what was completed. The user can re-run `/arn-spark-scaffold` to continue or start fresh.
