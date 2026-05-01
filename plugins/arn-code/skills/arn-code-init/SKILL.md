---
name: arn-code-init
description: >-
  Optional customization and upgrade tool. This skill should be used when the user says
  "initialize arness code", "arness code init", "arn-code-init", "init arness code", "setup arness code",
  "arness code setup", "set up arness code", "start arness code", "upgrade arness code", "update arness code",
  "configure arness code for this project", "add arness code to this project", "reconfigure arness code",
  "review arness config", "customize arness config", "arness settings",
  or wants to customize Arness configuration, review current settings, or upgrade after a plugin update.
  Handles both existing codebases (analyzes patterns) and greenfield projects (recommends patterns
  based on technology choices). Also handles upgrades after plugin updates.
version: 1.1.0
---

# Arness Init

Set up Arness for a project by analyzing or defining code patterns, choosing configuration options, and persisting everything to CLAUDE.md. This is optional — Arness auto-configures with sensible defaults on first skill invocation. Use this to customize directories, add integrations, update templates, or review your current settings.

## Workflow

### Step 1: Check Existing Configuration

Read the project's CLAUDE.md and look for a `## Arness` section. If no CLAUDE.md exists, create one at the project root before proceeding.

**If the section does not exist:**
- Proceed to Step 2 (fresh init)

**If the section exists:**
1. Parse all config fields from the existing `## Arness` block
2. Read the current plugin version from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`
3. Show the user their current configuration and version comparison:
   - Config template version vs current plugin version
   - Number of config fields present vs expected
4. Ask via `AskUserQuestion`:
   - **Review** — Show current configuration summary, no changes
   - **Upgrade (recommended)** — Check for gaps and update only what's needed. Best after a plugin update.
   - **Reconfigure** — Re-run the full setup flow from scratch (change directories, regenerate patterns, etc.)
   - **Keep** — No changes
- If **Review** → display a clean summary of all `## Arness` fields, then exit the skill
- If **Keep** → done, exit the skill
- If **Reconfigure** → continue to Step 2, pre-filling known values as defaults
- If **Upgrade** → proceed to the **Upgrade Flow** section

---

### Step 2: Detect Project State

Determine whether this is an existing codebase or a greenfield project.

Look for indicators of an existing codebase:
- Package manifests: `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `pom.xml`, `build.gradle`, `Gemfile`, `composer.json`
- Source directories: `src/`, `app/`, `lib/`, `cmd/`, `pkg/`
- Framework markers: `manage.py`, `next.config.*`, `angular.json`, `vite.config.*`, `main.go`, `main.rs`
- Meaningful source files (not just README, LICENSE, .gitignore)

**If existing codebase detected** → proceed to **Flow A** (Step 3A)

**If empty or minimal project** → proceed to **Flow B** (Step 3B)

Tell the user which flow was detected and why: "I detected an existing [language/framework] project" or "This looks like a new project with no existing code."

---

### Step 3: Detect Git, Platform, and Issue Tracker

> **Note:** Step 3 runs for ALL projects (both Flow A and Flow B). Steps 3A and 3B are flow-specific and run after Step 3.

**Shared field preservation:** If `## Arness` already exists and the shared fields (Git, Platform, Issue tracker, Jira site, Jira project) are already present from a prior init (this plugin or another — e.g., arn-spark-init, arn-infra-init, or ensure-config auto-detection), **skip detection and preserve the existing values** — unless the user chose **Reconfigure** in Step 1. If these fields were set by ensure-config auto-detection, preserve them unless the user chose Reconfigure. This prevents overwriting values set by another plugin or by ensure-config in a monorepo.

Check if the project uses Git, determine the code hosting platform, and identify the issue tracker.

**3.1. Git check:**
1. Run `git rev-parse --is-inside-work-tree` to check for a git repository
2. If Git is not detected, inform the user: "This project is not a git repository. Git-dependent skills (`/arn-code-ship`, `/arn-code-review-pr`, `/arn-code-create-issue`, `/arn-code-pick-issue`) will be unavailable." Record Git: no, Platform: none, Issue tracker: none and proceed to Step 3A/3B.

**3.2. Remote classification:**
1. Run `git remote -v` and classify the remote URL:
   - Contains `github.com` → candidate: **github**
   - Contains `bitbucket.org` → candidate: **bitbucket**
   - Neither → Platform: none, Issue tracker: none. Inform the user: "No supported platform detected. PR and issue management skills will be unavailable."

**3.3a. If candidate is github:**
1. Run `gh auth status` to check for GitHub CLI authentication
2. If authenticated → Platform: **github**, Issue tracker: **github**
3. If NOT authenticated → warn the user, suggest `gh auth login`, and **STOP init** (do not continue until resolved)
4. Create 7 Arness labels for issue management. Use `gh label create` for each label (the command is idempotent — it will skip labels that already exist):

| Label | Color | Description |
|-------|-------|-------------|
| `arness-backlog` | `d4c5f9` | Deferred items from PRs or postponed features |
| `arness-feature-issue` | `0e8a16` | Feature requests tracked via Arness |
| `arness-bug-issue` | `d93f0b` | Bug reports tracked via Arness |
| `arness-priority-high` | `b60205` | High priority |
| `arness-priority-medium` | `fbca04` | Medium priority |
| `arness-priority-low` | `c5def5` | Low priority |
| `arness-rejected` | `e4e669` | Issue reviewed and rejected as invalid or out of scope |

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-init/references/platform-labels.md` for label details and which skills use each label.

**3.3b. If candidate is bitbucket:**
1. Run `bkt --version` to check if the Bitbucket CLI is installed
   - If NOT available → read and show the setup instructions from `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-init/references/bkt-setup.md`, then **STOP init**
2. Run `bkt auth status` to check authentication
   - If NOT authenticated → read and show the auth instructions from `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-init/references/bkt-setup.md`, then **STOP init**
3. Platform: **bitbucket** (confirmed)
4. Ask the user: "Do you use Jira for issue tracking on this project?"
   - **YES** → verify the Atlassian MCP server:
     - Attempt to list Jira projects via the MCP tool
     - If MCP NOT available → read and show the setup instructions from `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-init/references/jira-mcp-setup.md`, then **STOP init**
     - If MCP available → list projects, present to user, user picks one
     - Store: Issue tracker: **jira**, Jira site: (from MCP context or ask user), Jira project: (user's pick)
     - No label creation needed (Jira labels are implicit — see `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-init/references/platform-labels.md`)
   - **NO** → Issue tracker: **none**
     - Inform the user: "Issue management skills (`/arn-code-create-issue`, `/arn-code-pick-issue`) will be unavailable. PR and code workflow skills still work via bkt."

**3.4. Record results:**
- **Git:** yes | no
- **Platform:** github | bitbucket | none
- **Issue tracker:** github | jira | none
- **Jira site:** (only if Issue tracker is jira)
- **Jira project:** (only if Issue tracker is jira)

---

## Flow A: Existing Codebase

### Step 3A: Analyze Codebase Patterns

Invoke the `arn-code-codebase-analyzer` agent with:
- The detected project type (backend/frontend/fullstack — infer from the codebase)
- The source root path (infer from project structure)
- Any framework hint (infer from manifests/markers)

The agent returns structured pattern documentation covering code patterns, testing patterns, and architecture — with real file paths and code snippets.

Review the output. If it seems incomplete (e.g., missed a major area of the codebase), re-invoke with more specific guidance.

Proceed to **Step 4**.

---

## Flow B: Greenfield Project

### Step 3B: Gather Technology Choices

Walk the user through the questions defined in `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-init/references/greenfield-questions.md`.

**Required questions** (always ask):
1. Project type — backend, frontend, or fullstack?
2. Language — what programming language?
3. Framework — suggest popular options based on language and project type
4. Testing approach — suggest default based on language

**Contextual questions** (ask based on earlier answers):
5. Database — if backend or fullstack
6. API style — if backend or fullstack
7. Package manager — suggest default, confirm
8. Project layout — src layout, flat, monorepo
9. Authentication — if backend or fullstack
10. Additional tooling — linting, formatting, CI
11. UI component library — if frontend or fullstack
12. Styling approach — if frontend or fullstack
13. Accessibility requirements — if frontend or fullstack

Be conversational, not rigid. Skip questions where the answer is obvious from prior answers. Summarize the choices before proceeding.

### Step 3B-2: Generate Recommended Patterns

Invoke the `arn-code-pattern-architect` agent with all the technology choices gathered above.

The agent returns recommended code patterns, testing patterns, and architecture — with concrete best-practice examples marked as "Recommended" rather than real file references.

Present the recommendations to the user for review:
- Show a summary of what was recommended
- Ask: "Does this look good? Would you like to adjust anything?"
- If adjustments needed → discuss and re-invoke the agent, or manually adjust the output
- If approved → proceed to **Step 4**

---

## Common Steps (both flows converge here)

### Step 4: Set Up Pattern Docs Directory

Ask the user: "Where should Arness store the code pattern documentation for this project?"

- Suggest `.arness/code-patterns` at the project root as the default
- Accept any path the user provides (relative to project root or absolute)
- If updating an existing config (from Step 1), show the current path as the default

Create the directory if it does not exist.

### Step 5: Choose Specs Directory

Ask the user: "Where should Arness store feature and bug specifications?"

- Suggest `.arness/specs` as the default
- Accept any path the user provides (relative to project root or absolute)

Create the directory if it does not exist: `mkdir -p <chosen-path>`

These specifications are created by `arn-code-feature-spec` and `arn-code-bug-spec` and drive the planning workflow via `/arn-code-plan`.

### Step 6: Write Pattern Documentation

Read the pattern documentation schema at `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-init/references/pattern-schema.md`. This defines the exact structure each file must follow.

**Greenfield Architecture Bridge:**

Before generating pattern documentation, check if an `architecture-vision.md` exists. Read `## Arness` config for greenfield fields (Vision directory — set by the arn-spark plugin during greenfield exploration). If Vision directory is configured, check `<vision-dir>/architecture-vision.md`.

**If architecture-vision.md is found:**

1. Read the architecture-vision.md
2. Extract and carry forward into the generated architecture.md:
   - **Technology Stack table** — use as the source for architecture.md's Technology Stack section (for Flow B: skip the technology choices gathering in Step 3B since they are already captured)
   - **Pillar Alignment table** → populate the "Architectural Constraints: Product Pillars" section in architecture.md
   - **Business Constraints & Trade-offs table** (if present) → populate the "Architectural Constraints: Business Constraints" section
   - **Known Risks & Mitigations table** → populate the "Known Risks & Mitigations" section
3. Inform: "Found architecture-vision.md from greenfield exploration. Seeding architecture.md with technology choices, pillar constraints, business constraints, and known risks."

**If architecture-vision.md is NOT found:** proceed normally (Flow A: analyze codebase, Flow B: ask for technology choices).

Split the agent output (from Step 3A or Step 3B-2) into three to five files based on the top-level headings: `# Code Patterns`, `# Testing Patterns`, `# Architecture`, and optionally `# UI Patterns` and `# Security Patterns`.

**Before writing each file**, validate the content against the schema:
- Every pattern has all required fields (Description, Reference, Example, How to apply / Fixtures/Helpers)
- Required sections are present (Project Stack in code-patterns.md, Test Framework in testing-patterns.md, Technology Stack and Project Layout in architecture.md, UI Stack in ui-patterns.md)
- References contain real file paths with line numbers (not placeholders)
- Code examples are actual snippets from the codebase (not pseudocode)

If the agent output is missing required fields or uses the wrong structure, reformat it to match the schema before writing.

Write the files to the chosen pattern docs location:

1. **`code-patterns.md`** — Project stack info + code patterns (naming, structure, API/routing, data layer, error handling, configuration)
2. **`testing-patterns.md`** — Test framework info + testing patterns (organization, fixtures, markers, setup/teardown)
3. **`architecture.md`** — Technology stack table, architectural decisions, dependencies, project layout, codebase references
4. **`ui-patterns.md`** *(frontend and fullstack projects only)* — UI stack info + UI patterns (component patterns, layout/styling, state management, accessibility, form handling, navigation, animation). Write this file if the project type is "frontend" or "fullstack" (from question 1 for greenfield, or detected type for existing codebases), OR if the codebase analyzer detected a frontend framework during analysis.
5. **`security-patterns.md`** *(projects with security surface)* — Security stack info +
   security patterns (authentication, authorization, input validation, data protection,
   API security, dependency security). Write this file if the codebase analyzer or pattern
   architect detected security-relevant patterns (auth middleware, API endpoints, user input
   handling, sensitive data). Do not write it for projects with no security surface (pure
   utility libraries, CLI tools with no auth/API/user input).
6. **`linting.md`** — Linter detection per service/package, produced by the codebase analyzer (step 3C of `arn-code-codebase-analyzer`). Always write this file: if no linters were detected, the analyzer returns the single-line "No linters detected." marker, which is what gets written. The lint configuration question in Step 8b uses this file to suggest a default.

### Step 7: Configure Plans and Templates

Ask the user:

**1. Plans directory**

"Where should Arness save structured project plans?"
- Suggest `.arness/plans` as the default
- Accept any path

Create the directory if it does not exist: `mkdir -p <chosen-path>`

**2. Report templates**

"Arness includes default report templates (implementation, testing, progress tracking).
Would you like to use the defaults, or design custom ones?"

For default templates, copy all JSON templates from the plugin to `.arness/templates/`, generate SHA-256 checksums, and write a `.checksums.json` file for version tracking. For custom templates, show the defaults as a starting point and iterate with the user. After setup, ask the user's preference for handling future template updates (ask, auto, or manual).

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-init/references/template-setup.md` for the full template setup procedure.

### Step 8: Choose Documentation Directory

Ask the user: "Where should Arness save project documentation?"

- Suggest `.arness/docs/` at the project root as the default
- Accept any path the user provides

Create the directory if it does not exist: `mkdir -p <chosen-path>`

Documentation generated by `/arn-code-document-project` will be saved here.

### Step 8b: Configure Linting

Read `<code-patterns-dir>/linting.md` (written in Step 6). Use its content to decide the suggested default for the question below:

- If `linting.md` contains the marker `No linters detected.` → suggested default: `None`
- Otherwise (linters were detected) → suggested default: `Enabled`

Ask (using `AskUserQuestion`):

> **How should Arness handle linting for this project? \<suggested default shown above\>**
> 1. **Enabled** — discover and use the project's linters as a gate before commits
> 2. **None** — project has no linters configured
> 3. **Skip** — keep the lint gate disabled (you can change this later)

Record the answer for the config write in Step 9.

If `linting.md` does not exist (e.g., the analyzer failed earlier in Step 6, or this is a partial init), default the question's suggested value to `Skip` so the user is not blocked, and note in the config that linting will be re-checked on the next `arn-code-ensure-config` run.

---

### Step 9: Persist Configuration to CLAUDE.md

Write (or update) the `## Arness` section in the project's CLAUDE.md:

```markdown
## Arness

- **Plans directory:** [chosen-path]
- **Specs directory:** [chosen-specs-path]
- **Report templates:** default | custom
- **Template path:** [relative-path, e.g., .arness/templates]
- **Template version:** [version from plugin.json]
- **Template updates:** ask | auto | manual
- **Code patterns:** [chosen-pattern-docs-path]
- **Docs directory:** [chosen-docs-path]
- **Linting:** enabled | none | skip
- **Git:** yes | no
- **Platform:** github | bitbucket | none
- **Issue tracker:** github | jira | none
- **Jira site:** <site>.atlassian.net
- **Jira project:** <KEY>
- **Task list ID:** <task-list-id>
```

The template path MUST be relative to the project root, never absolute. This ensures portability across machines and plugin updates.

The `Task list ID` field is conditional — only written if the user opts in during Step 9b. Omit it if the user chose not to enable persistent task lists.

The Git, Platform, and Issue tracker fields are auto-detected in Step 3 and are not user-configurable.

The Jira site and Jira project fields are only written when Issue tracker is jira. Omit them entirely for other issue trackers.

If updating an existing config, replace the existing `## Arness` section in place. Do not duplicate it. **Preserve all fields not managed by this skill** — this includes greenfield fields (Vision directory, Use cases directory, Prototypes directory, Spikes directory, Visual grounding directory, Figma, Canva) and infra fields (Deferred, Experience level, Project topology, Application path, Providers, Providers config, Default IaC tool, Environments, Environments config, Tooling manifest, Resource manifest, Cost threshold, Validation ceiling, Infra plans directory, Infra specs directory, Infra docs directory, Infra report templates, Infra template path, Infra template version, CI/CD platform, Reference overrides, Reference version, Reference updates). For shared fields (Git, Platform, Issue tracker, Jira site, Jira project): if already present, preserve them — do not re-detect unless the user chose Reconfigure in Step 1.

### Step 9b: Set Up Persistent Task List (Recommended)

Ask the user:

"Would you like to enable persistent task lists? (Recommended)

This sets `CLAUDE_CODE_TASK_LIST_ID` in your project's `.claude/settings.json` so that tasks created by `/arn-code-taskify` survive across sessions. Without this, tasks are lost when a session ends and must be recreated.

Benefits:
- Resume `/arn-code-execute-plan` after a session restart
- Multiple sessions on the same project see the same task state
- Worktree-based parallel execution shares the task list"

Options:
1. **Yes** (Recommended) — Set up with auto-generated ID based on project directory name
2. **Yes, with custom ID** — Let me specify the task list ID
3. **No** — Skip (tasks will be session-scoped)

**If Yes:**
1. Derive the task list ID:
   - **Auto:** slugify the current project directory name (e.g., `/home/user/my-project` → `my-project`)
   - **Custom:** use the user's provided ID
2. Read `.claude/settings.json` in the project root (create the file and `.claude/` directory if they don't exist)
3. Add or update the `env` object, preserving any existing env vars (e.g., `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`):
   ```json
   {
     "env": {
       "CLAUDE_CODE_TASK_LIST_ID": "<task-list-id>"
     }
   }
   ```
4. Add `- **Task list ID:** <task-list-id>` to the `## Arness` config block written in Step 9
5. Inform: "Persistent task list configured. Tasks will persist across sessions at `~/.claude/tasks/<task-list-id>/`."

**If No:**
- Do not write to `.claude/settings.json`
- Omit `Task list ID` from the `## Arness` config block
- Inform: "Task lists will be session-scoped. You can enable persistence later by re-running `/arn-code-init`."

### Step 10: Verify and Summarize

Confirm with the user:

- [ ] Project state detected correctly (existing vs greenfield)
- [ ] Code patterns analyzed (Flow A) or recommended (Flow B)
- [ ] Pattern documentation written:
  - `[pattern-dir]/code-patterns.md`
  - `[pattern-dir]/testing-patterns.md`
  - `[pattern-dir]/architecture.md`
  - `[pattern-dir]/ui-patterns.md` (if frontend/fullstack)
  - `[pattern-dir]/security-patterns.md` (if security surface detected)
- [ ] Plans directory configured
- [ ] Report templates configured
- [ ] Specs directory configured and created
- [ ] Template checksums generated (`.arness/templates/.checksums.json`)
- [ ] Git, Platform, and Issue tracker detected and configured
- [ ] GitHub labels created (if Platform is github)
- [ ] Jira project selected (if Issue tracker is jira)
- [ ] Documentation directory configured
- [ ] `## Arness` section written to CLAUDE.md

List all created/modified files with their paths.

**Next steps:**
- To spec a new feature: run `/arn-code-feature-spec` (or `/arn-code-feature-spec-teams` for team debate)
- To spec a bug fix: run `/arn-code-bug-spec`
- To create an issue: run `/arn-code-create-issue` (requires Issue tracker: github or jira)
- To pick an issue from the backlog: run `/arn-code-pick-issue` (requires Issue tracker: github or jira)

## Upgrade Flow

Entered from Step 1 when the user chooses **Upgrade**. Diagnoses gaps using the `arn-code-doctor` agent and surgically fixes only what's missing — preserving all existing user choices.

### Step U1: Run Diagnostic

Invoke the `arn-code-doctor` agent via the Task tool with:
- Description: "Comprehensive health check for arn-code-init upgrade. Check ALL categories: config fields, directories, template files, checksums, Git/Platform/Issue tracker state, platform labels, and pattern doc schema compliance. Use only Read/Glob/Grep and the allowed Bash commands (git status, git remote -v, gh auth status, gh label list, bkt --version, bkt auth status, ls). Do NOT run claude CLI commands."
- Project root path
- The parsed `## Arness` config content
- Plugin version from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`
- Instruction to read the knowledge base at `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-report/references/arness-knowledge-base.md`

The agent should check for:
- Platform field presence and validity (github | bitbucket | none)
- Issue tracker field presence and validity (github | jira | none)
- If Issue tracker is jira: Jira site and Jira project fields populated
- Old `GitHub:` field presence (indicates migration is needed)
- Deferred visual testing layers: look for `#### Layer N:` subsections under `### Visual Testing` in the project's CLAUDE.md where `**Status:** deferred` is present. If found, report the layer names.
- All other standard checks (directories, templates, checksums, pattern docs)

Wait for the agent to complete and collect the diagnostic report.

---

### Step U2: Parse and Present Findings

Categorize each `[ISSUE]` from the doctor's report:

| Category | Examples |
|----------|----------|
| `missing_config_auto` | Git, Platform, Issue tracker fields absent from config |
| `legacy_config` | Old `GitHub: yes\|no` field present (needs migration to Platform + Issue tracker) |
| `missing_config_user` | Docs directory, Plans dir, Specs dir, Code patterns, template prefs absent |
| `missing_config_jira` | Jira site or Jira project absent when Issue tracker is jira |
| `missing_directory` | Directory referenced in config but path doesn't exist |
| `outdated_templates` | Template version in config < current plugin version |
| `missing_labels` | GitHub labels not present in repository (Platform: github only) |
| `pattern_schema` | Pattern docs missing required sections or files absent |
| `visual_deferred_layers` | Deferred visual testing layers detected in `### Visual Testing` config |

If all findings are `[OK]`, inform the user: "Arness is fully up to date. No changes needed." and exit.

Otherwise, present a summary: "Found N items to address:" followed by a brief list of the categories.

---

### Step U3: Auto-Fix (No User Input)

Process these categories silently, then report what was done:

1. **Platform detection** (if Platform/Issue tracker fields absent, or legacy `GitHub:` field present):
   Run the same detection logic as Step 3:
   - `git rev-parse --is-inside-work-tree`
   - `git remote -v` (classify: github.com, bitbucket.org, or other)
   - Platform-specific auth checks (`gh auth status` or `bkt --version` + `bkt auth status`)
   - Record Git, Platform, and Issue tracker values.

   **Migration from legacy config:**
   - If `GitHub: yes` is found → set Platform: github, Issue tracker: github. Remove the `GitHub` field.
   - If `GitHub: no` is found → re-run full detection (the remote may now be Bitbucket). Remove the `GitHub` field.
   - If no `GitHub` field and no `Platform` field → full detection runs as described above.

2. **Missing directories** (for config fields that already have a value but the directory doesn't exist): `mkdir -p <path>` for each.

3. **Missing platform labels** (if Platform is github): Run `gh label create --force` for each missing label per `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-init/references/platform-labels.md`. These commands are idempotent. Skip label creation for Bitbucket and Jira (Jira labels are implicit).

Report to the user what was auto-fixed:
```
Auto-fixed:
- Detected Git: yes, Platform: github, Issue tracker: github
- Migrated legacy GitHub: yes → Platform: github + Issue tracker: github
- Created missing directory: .arness/docs/
- Created 3 missing GitHub labels: arness-backlog, arness-priority-high, arness-priority-low
```

---

### Step U4: User-Input Gaps

For each missing config field that needs a user-provided value, ask **one focused question** using the same prompt and default as the corresponding full-flow step:

| Missing Field | Prompt | Default | Source Step |
|---------------|--------|---------|------------|
| Code patterns | "Where should Arness store the code pattern documentation?" | `.arness/code-patterns` | Step 4 |
| Specs directory | "Where should Arness store feature and bug specifications?" | `.arness/specs` | Step 5 |
| Plans directory | "Where should Arness save structured project plans?" | `.arness/plans` | Step 7 |
| Report templates | "Use default or custom report templates?" | `default` | Step 7 |
| Template updates | "How should Arness handle template updates?" | `ask` | Step 7 |
| Docs directory | "Where should Arness save project documentation?" | `.arness/docs/` | Step 8 |
| Jira site | "What is your Atlassian site URL? (e.g., mycompany.atlassian.net)" | none | Step 3 |
| Jira project | "Which Jira project should Arness use?" | list via MCP and pick | Step 3 |

**Rules:**
- Only ask about fields that are genuinely absent from the config. Never re-ask about fields that already have a value.
- Jira site and Jira project are only asked when Issue tracker is jira and the fields are missing. If the Atlassian MCP server is available, list projects and let the user pick instead of typing manually.
- If a field had a backward-compatibility default (e.g., Docs directory defaults to `.arness/docs/`), still ask so it gets persisted explicitly. Mention the current default: "This field wasn't set in your config. The default is `.arness/docs/`. Would you like to use this, or choose a different path?"
- After each directory answer, create the directory if it does not exist: `mkdir -p <path>`
- If Report templates is missing and the user chooses "default", copy template files and generate checksums per the template setup procedure in `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-init/references/template-setup.md`.

---

### Step U5: Template Upgrades

This step only runs if `Template version` in the config is older than the current plugin version.

1. Read the user's `Template updates` preference from the config
2. Read the existing `.checksums.json` from the user's template directory
3. Compute current SHA-256 checksums of the user's template files to detect customizations

Then follow the preference:

- **`ask`:** Show the user which templates have changed between versions. Ask: "The plugin has updated templates. Would you like to update? Files you've customized will be preserved." If yes → copy new defaults for unmodified templates (checksum matches stored value), skip modified ones and warn. Regenerate `.checksums.json`.
- **`auto`:** For each template: if checksum matches stored value (unmodified), overwrite with new default. If checksum differs (user customized), skip and warn. Regenerate `.checksums.json`.
- **`manual`:** Inform the user: "New template versions are available in the plugin. Your templates were not changed." Do not touch files.

In all cases, update `Template version` in the config to the current plugin version.

---

### Step U6: Pattern Doc Schema Check

This step only runs if the doctor flagged `pattern_schema` issues.

- **Files exist but non-compliant** (missing required sections, wrong structure): Ask the user: "Your pattern documentation files exist but don't fully comply with the current schema. Would you like me to regenerate them? Your existing content will be used as context." If yes → re-invoke `arn-code-codebase-analyzer` (existing project) or `arn-code-pattern-architect` (greenfield), validate output against the schema at `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-init/references/pattern-schema.md`, and write the updated files.
- **Files entirely missing** (directory exists but pattern doc files absent): Ask the user: "No pattern documentation files found. Would you like to generate them now? This will analyze your codebase." If yes → run the full Flow A (Step 3A) or Flow B (Step 3B) detection + Step 6 writing flow.

---

### Step U7: Update Config

Write (or update) the `## Arness` section in CLAUDE.md, merging:
- Existing values (preserved as-is for fields that were already configured)
- Newly detected values (Git, Platform, Issue tracker from Step U3)
- Newly chosen values (from Step U4, including Jira site/project if applicable)
- Updated Template version (from Step U5)

The config includes up to 14 fields (11 core + 3 conditional: 2 Jira fields + 1 Task list ID). The old `GitHub:` field is removed if present (replaced by Platform + Issue tracker). Jira site and Jira project fields are only written when Issue tracker is jira. Task list ID is only written when the user opts in during Step 9b.

Replace the existing `## Arness` section in place. Format matches Step 9 exactly. **Preserve all fields not managed by this skill** (greenfield fields, infra fields) as documented in Step 9.

---

### Step U7b: Deferred Visual Testing Layer Notice

If deferred visual testing layers were detected (`visual_deferred_layers` category):

Present: "Deferred visual testing layers found: [layer names]. Run `/arn-spark-visual-readiness` (requires arn-spark plugin) to check if they can be activated now."

This is informational only — do not auto-fix or block the upgrade flow.

---

### Step U8: Task List Persistence Check

Check if `Task list ID` is present in the existing `## Arness` config.

**If NOT present:**

"Persistent task lists are not configured for this project. Would you like to enable them? (Recommended — ensures tasks survive across sessions)"

Options:
1. **Yes** (Recommended) — Set up with auto-generated ID based on project directory name
2. **Yes, with custom ID** — Let me specify the task list ID
3. **No** — Skip

If Yes: follow the same logic as Step 9b (derive ID, write to `.claude/settings.json`, add to `## Arness` config).

If No: skip silently.

**If already present:**
- Read `.claude/settings.json` and check if `CLAUDE_CODE_TASK_LIST_ID` matches the configured Task list ID
- If `.claude/settings.json` is missing or the env var is absent/mismatched: update it to match. Note: "Updated `.claude/settings.json` to match Task list ID: `<id>`."
- If matching: skip silently

### Step U9: Summarize

Present a change summary:

```
Upgrade Complete (Plugin version: X.Y.Z)

Changes made:
- Migrated legacy config: GitHub: yes → Platform: github + Issue tracker: github
- Added config field: Docs directory → .arness/docs/
- Added config field: Git → yes
- Added config field: Platform → github
- Added config field: Issue tracker → github
- Removed legacy field: GitHub
- Created directory: .arness/docs/
- Updated 4 templates to vX.Y.Z
- Created 7 GitHub labels
- Updated ## Arness config in CLAUDE.md

No changes to:
- Plans directory: plans/ (unchanged)
- Specs directory: specs/ (unchanged)
- Code patterns: .arness/code-patterns (unchanged)
- Pattern documentation (up to date)
```

List all created/modified files with their paths (same style as Step 10).

---

## Error Handling

- If the user cancels at any step, confirm and exit gracefully. Do not leave partially written configuration.
- If an agent invocation (`arn-code-codebase-analyzer` or `arn-code-pattern-architect`) fails or returns empty output, report the issue to the user and suggest providing pattern information manually.
- If writing to CLAUDE.md fails (e.g., permissions), inform the user and print the `## Arness` config block so they can insert it manually.
- **Upgrade mode:** If the `arn-code-doctor` agent fails during upgrade, fall back to offering Reconfigure or Keep.
- **Upgrade mode:** If template upgrade fails (file permission, missing source), warn and skip — do not abort the entire upgrade.
- **Upgrade mode:** If the user cancels mid-upgrade, persist whatever was already resolved and inform the user that the upgrade is partial.

## Re-running Arness Init

This skill is safe to re-run. When re-running:
- Step 1 detects the existing `## Arness` section and offers three options: Upgrade, Reconfigure, or Keep
- **Upgrade** (recommended after plugin updates): Runs arn-code-doctor to diagnose gaps and fills in only what's missing — no re-asking of existing questions
- **Reconfigure**: Re-runs the full setup flow with existing values as defaults — use this to change directories, regenerate patterns, or start fresh
- CLAUDE.md config section is updated in place

**Backward compatibility:** Missing `Docs directory` defaults to `.arness/docs/`. Missing `Git`/`Platform`/`Issue tracker` fields default to runtime detection (checks are run on demand by skills that need them). Legacy `GitHub: yes|no` configs are auto-migrated to `Platform` + `Issue tracker` during upgrade. After a plugin update, the Upgrade flow handles migration of these fields automatically.
