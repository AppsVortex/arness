---
name: arn-spark-dev-setup
description: >-
  This skill should be used when the user says "dev setup", "arn spark dev setup",
  "development environment", "configure dev environment", "dev container",
  "configure CI", "set up CI", "onboard developer", "developer setup",
  "set up docker", "configure development", "how do I set up this project",
  "development setup", "onboard me", "get this project running", "set up my
  machine", "new developer setup", "how do I get started", "developer
  onboarding", or wants to define a standardized development environment for
  their project (producing dev environment infrastructure files and a dev-setup
  document) or follow an existing environment standard to get onboarded as a
  new developer.
version: 1.0.0
---

# Arness Dev Setup

Define or follow a standardized development environment through guided conversation, aided by the `arn-spark-dev-env-builder` agent for file generation and optionally the `arn-spark-tech-evaluator` agent for environment comparisons. This is a conversational skill that runs in normal conversation (NOT plan mode). The primary artifacts are **development environment infrastructure files** (setup scripts, container configs, CI workflows, toolchain pins) and a **dev-setup document**.

This skill covers the development environment: how developers get the project running on their machines, how CI builds and tests, and how toolchain versions are pinned for reproducibility. It does not create project source code (that is `/arn-spark-scaffold`) or validate technical risks (that is `/arn-spark-spike`).

This skill operates in two modes:

- **Define mode:** An architect or project lead defines the standard development environment. The skill asks questions, generates infrastructure files, writes a dev-setup document, and stores configuration in CLAUDE.md.
- **Onboard mode:** A developer joining the project follows the existing standard. The skill reads the configuration from CLAUDE.md, presents the setup steps, and guides the developer through the process.

## Prerequisites

The following artifacts inform the development environment. Check in order:

**Architecture vision (recommended):**
1. Read the project's `CLAUDE.md` for a `## Arness` section. If found, check the configured Vision directory for `architecture-vision.md`
2. If no `## Arness` section found, check `.arness/vision/architecture-vision.md` at the project root

**If an architecture vision is found:** Read it for stack decisions (framework, languages, platform targets, system dependencies).

**If no architecture vision is found:** Ask the user to describe their stack: "No architecture vision found. Describe your technology stack and target platforms so I can configure the development environment."

**Scaffolded project (recommended):**
Check for `package.json`, `Cargo.toml`, or similar at the project root to detect what dependencies and tooling are already configured.

**If the project is scaffolded:** Use existing manifests and configs for context.

**If the project is not scaffolded:** Warn the user: "The project does not appear to be scaffolded yet. I can define the development environment conceptually, but setup scripts will be more useful after running `/arn-spark-scaffold`." Proceed with the conversation.

## Workflow

### Step 1: Detect Mode

Read CLAUDE.md and check for a `## Arness` section with a `### Dev Environment` subsection.

**If `### Dev Environment` exists:**

"A development environment is already configured for this project:

**Type:** [type from CLAUDE.md]
**Platforms:** [platforms from CLAUDE.md]

Ask (using `AskUserQuestion`):

**"A development environment is already configured. What would you like to do?"**

Options:
1. **Follow the existing setup** — I will guide you through setting up your development environment
2. **Reconfigure** — I will walk through the environment decisions again and update the configuration"

- If the user chooses to follow → proceed to **Onboard Mode (Step O1)**
- If the user chooses to reconfigure → proceed to **Define Mode (Step 2)**

**If no `### Dev Environment` exists:**

Proceed to Define Mode (Step 2).

---

## Define Mode

### Step 2: Load Context

Read available artifacts:

- **Architecture vision:** Framework, languages, platform targets, known risks, system-level requirements
- **Scaffold results:** package.json (scripts, engines, dependencies), Cargo.toml (edition, targets), build configuration files
- **Existing dev files:** Check for .devcontainer/, Dockerfile, docker-compose.yml, .github/workflows/, scripts/ -- note what already exists

Identify platform-specific requirements from the stack. For example:
- Tauri requires WebKit2GTK on Linux, WebView2 on Windows, and Xcode command-line tools on macOS
- Rust requires the Rust toolchain (rustup + cargo)
- Node.js projects need a specific Node version

### Step 3: Explore Environment Approach

Present the environment options, informed by the project context:

"Your project uses **[stack summary]**, targeting **[platforms]**. Based on your stack, I would suggest **[recommendation with brief rationale]**."

Ask (using `AskUserQuestion`):

**"Which development environment approach fits your project?"**

Options:
1. **Native** — Developers install tools directly on their OS. Best for GUI applications, hardware access, and fast iteration
2. **Dev container** — Reproducible containerized environment via VS Code Dev Containers. Best for web services, team consistency, and easy onboarding
3. **Docker / Docker Compose** — Containerized services. Best for backend services, databases, and microservices
4. **Hybrid** — Native for some parts (GUI, hardware), containerized for others (backend services, databases)

If the user is unsure, ask probing questions:

| Question | Guides Toward |
|----------|--------------|
| "Does the project need native windowing or hardware access?" | Native or hybrid (containers cannot easily access GUI/hardware) |
| "Will developers be on different OS platforms?" | Stronger need for setup scripts and CI matrix |
| "Are there backend services or databases to manage?" | Docker compose or hybrid |
| "How important is onboarding speed vs. environment control?" | Dev container (fast onboard) vs. native (more control) |
| "Is this a team project or solo?" | Team → stronger standardization; solo → lighter setup |

### Step 4: Gather Specifics

Based on the chosen approach, explore the details conversationally:

**For all approaches:**

Ask (using `AskUserQuestion`) with `multiSelect: true`:

**"Which platforms should the setup support? (select multiple)"**

Options:
1. **Linux** — Linux development environment
2. **macOS** — macOS development environment
3. **Windows** — Windows development environment

Default to all platforms from the architecture vision.

Ask (using `AskUserQuestion`):

**"Do you want CI configured?"**

Options:
1. **GitHub Actions** — Set up GitHub Actions CI workflow
2. **GitLab CI** — Set up GitLab CI pipeline
3. **Skip for now** — No CI configuration

Also ask conversationally:
- "Should I pin toolchain versions? (Rust version, Node version, etc.)"
- "Any IDE configuration? VS Code extensions, editor settings?"

**For native environments:**
- "How automated should the setup be? Full automation (scripts install everything) or documented manual steps?"
- "Any specific package manager preferences per platform? (Homebrew on macOS, apt vs. snap on Linux, winget vs. chocolatey on Windows)"

**For dev containers:**
- "Which base image? (Language-specific like mcr.microsoft.com/devcontainers/rust or generic like ubuntu?)"
- "Any additional container features needed? (Docker-in-Docker, GPU access, specific system libs)"
- "Port forwarding for dev server?"
- "Post-create commands to run after the container starts?"

**For Docker / Docker Compose:**
- "Which services need containers? (database, cache, message queue, the app itself?)"
- "Volume mounts for live reload during development?"
- "Network configuration between services?"
- "Separate development and production Dockerfiles?"

**For hybrid:**
- "Which parts run natively? Which are containerized?"
- "How do the native and containerized parts communicate? (localhost ports, shared volumes, environment variables)"

Confirm the full specification before proceeding:

"Here is the development environment I will set up:

**Type:** [type]
**Platforms:** [list]
**CI:** [provider or none]
**Toolchain pins:** [list]
**Generated files:** [list of what will be created]

Ready to generate, or want to adjust anything?"

### Step 5: Invoke Builder

Invoke the `arn-spark-dev-env-builder` agent with:

- Environment type and all specifics gathered in Step 4
- Platform targets
- Stack context (from architecture vision and scaffold)
- Project root path
- CI provider and configuration
- Toolchain versions to pin
- IDE preferences

The agent creates all infrastructure files, setup scripts, CI workflows, toolchain pins, and CONTRIBUTING.md.

### Step 6: Write Dev Setup Document

1. Read the template:
   > Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-dev-setup/references/dev-setup-template.md`

2. Populate the template with all decisions from the conversation and the builder's report:
   - Environment type and rationale
   - Prerequisites per platform with specific packages
   - Setup instructions (referencing the generated scripts)
   - Toolchain versions and pin files
   - CI/CD pipeline summary
   - IDE configuration
   - Troubleshooting (from any issues observed during verification)

3. Determine the output directory:
   - Read the project's `CLAUDE.md` and check for a `## Arness` section
   - If found, extract the configured Vision directory path — this is the source of truth
   - If no `## Arness` section exists or Arness Spark fields are missing, inform the user: "Arness Spark is not configured for this project yet. Run `/arn-brainstorming` to get started — it will set everything up automatically." Do not proceed without it.
   - If the output directory does not exist, create it

4. Write the document as `dev-setup.md`

### Step 7: Write Config to CLAUDE.md

Write or update the `### Dev Environment` subsection in the `## Arness` section of CLAUDE.md:

**If no `## Arness` section exists:**

Create a minimal `## Arness` section with the dev environment configuration:

```markdown
## Arness

### Dev Environment
- **Type:** [native / dev-container / docker / docker-compose / hybrid]
- **Platforms:** [linux, macos, windows]
- **CI provider:** [github-actions / gitlab-ci / none]
- **Setup doc:** [path to dev-setup.md]
- **Setup script:** [path to setup script, if applicable]
```

**If `## Arness` section exists but no `### Dev Environment`:**

Append the `### Dev Environment` subsection to the existing `## Arness` section.

**If `### Dev Environment` already exists:**

Replace it with the updated configuration.

### Step 8: Verify and Present Results

Read the verification checklist:
> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-dev-setup/references/dev-setup-checklist.md`

Walk through the applicable checklist categories. Then present results:

"Development environment configured. Here is what was set up:

**Environment:** [type] for [platforms]

**Files created:**
- [list grouped by category: scripts, CI, containers, toolchain, docs]

**CLAUDE.md updated** with dev environment configuration.

**Verification:**
- Setup script: [pass/fail/skipped]
- Build in environment: [pass/fail]
- CI config: [valid/skipped]

Recommended next steps:
1. **Validate critical risks:** Run `/arn-spark-spike` to test technical risks from your architecture vision
2. **Explore visual style:** Run `/arn-spark-style-explore` to define the look and feel
3. **Share with team:** Commit the generated files so other developers can run `/arn-spark-dev-setup` to onboard"

---

## Onboard Mode

After Step 1 detects existing configuration and the user chooses to follow it:

### Step O1: Read Configuration

1. Read the `### Dev Environment` subsection from CLAUDE.md for the environment type and key paths
2. Read the full `dev-setup.md` document for detailed setup instructions
3. Check which generated files exist (setup scripts, container configs, CI workflows)

### Step O2: Present Standard Environment

"This project uses a **[type]** development environment targeting **[platforms]**.

**What you need:**
[Prerequisites from dev-setup.md, filtered for the current platform]

**Setup steps:**
1. [Step 1 from dev-setup.md]
2. [Step 2]
3. [Step 3]

Ready to proceed with setup?"

### Step O3: Guide Setup

Walk the developer through each setup step from dev-setup.md:

1. Present each step clearly with the exact commands to run
2. If a setup script exists, offer to run it: "A setup script is available at `[path]`. Shall I run it for you?"
3. If the developer runs steps manually, verify each succeeded before moving to the next
4. If a step fails, consult the troubleshooting section of dev-setup.md

**If the developer wants to deviate:**

"That differs from the project's standard development environment (**[type]**). The standard is used by CI and other developers.

You can proceed with your preference, but be aware:
- CI builds use the standard environment, so you may see failures locally that do not appear in CI (or vice versa)
- Other developers expect the standard setup when pairing or reviewing

Continue with your preference, or follow the standard?"

Record the deviation but do not block the developer.

### Step O4: Verify and Complete

Read the verification checklist:
> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-dev-setup/references/dev-setup-checklist.md`

Focus on Build Verification (category 4):
- Project builds successfully
- Development server starts
- Tests run
- Linter passes

"Environment setup complete. Your project builds and runs.

**Verification:**
- Build: [pass/fail]
- Dev server: [pass/fail]
- Tests: [pass/fail]

You are ready to start developing. If you encounter issues, check the troubleshooting section in `[path to dev-setup.md]`."

## Agent Invocation Guide

| Situation | Action |
|-----------|--------|
| Generate environment files (Define Step 5) | Invoke `arn-spark-dev-env-builder` with full specification |
| Run setup script during onboard (Step O3) | Offer to run the setup script directly; invoke `arn-spark-dev-env-builder` only if the script fails and needs diagnosis |
| User asks about container image options | Discuss options, invoke `arn-spark-tech-evaluator` for comparison if needed |
| User asks about CI provider differences | Discuss briefly, invoke `arn-spark-tech-evaluator` for deep comparison if needed |
| User asks about technology choices (framework, languages) | Defer: "Technology choices are in the architecture vision. This skill configures the development environment for the chosen stack." |
| User asks about project structure or dependencies | Defer: "Project structure is set up by `/arn-spark-scaffold`. This skill configures the environment around the existing project." |
| User asks about code patterns or features | Defer: "Code patterns come during feature development. The dev environment just needs to support building and testing." |
| Setup script fails during onboard | Consult troubleshooting, invoke builder to diagnose if needed |

## Error Handling

- **No architecture vision found:** Proceed with the user's description of the stack. Dev environment can be configured from a verbal stack description.
- **Project not scaffolded:** Warn that auto-detection of dependencies will be limited. Proceed with manual specification. Setup scripts can be updated after scaffolding.
- **Dev setup already configured (Define mode):**

  Ask (using `AskUserQuestion`):

  > **A development environment is already configured at `[path]`. How would you like to proceed?**
  > 1. **Replace** — Reconfigure the entire development environment
  > 2. **Update** — Update specific parts (CI, scripts, container config)
- **Setup script fails:** Report the error. Invoke the builder to fix. If it fails after 3 attempts, present the error and the manual steps the developer can follow.
- **Container build fails:** Report the error. Invoke the builder to diagnose. Common issues: missing system dependencies, wrong base image, network problems during build.
- **CI workflow invalid:** Report the YAML error. Invoke the builder to fix the syntax.
- **User cancels mid-setup:** Note what was completed. The user can re-run `/arn-spark-dev-setup` to continue. In Define mode, any files already generated are usable.
- **Writing CLAUDE.md fails:** Print the configuration block in the conversation so the user can add it manually.
- **Platform not available for testing:** Note the platform as untested. The setup script and CI will validate on that platform when it becomes available.
- **dev-setup.md not found (Onboard mode):** Check for CONTRIBUTING.md or README with setup instructions as fallback. If nothing found, inform the developer: "The setup document is missing. Ask the project maintainer to run `/arn-spark-dev-setup` in Define mode, or describe the setup and I will guide you."
