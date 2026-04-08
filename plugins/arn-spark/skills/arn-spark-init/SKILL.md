---
name: arn-spark-init
description: >-
  Optional customization tool for greenfield projects. This skill should be used when the user says
  "greenfield init", "arn spark init", "initialize greenfield", "setup greenfield",
  "greenfield setup", "start greenfield", "configure greenfield",
  "set up greenfield", "init greenfield", "greenfield configuration",
  "review greenfield config", "customize greenfield config", "greenfield settings",
  "Figma setup", "Canva setup", "add Figma", "add Canva", "design tool setup",
  or wants to customize Arness Spark configuration, add design tool integrations
  (Figma, Canva), or review current greenfield settings. Arness Spark auto-configures
  with sensible defaults on first skill invocation — this init is optional.
  Design tool integration (Figma/Canva) remains available only through this skill.
version: 1.0.0
---

# Arness Spark Init

Set up Arness for a greenfield project by configuring output directories for all greenfield artifacts and detecting the project's platform setup. This is optional — Arness Spark auto-configures with sensible defaults on first skill invocation. Use this to customize directories, add design tool integrations (Figma, Canva), or review your current settings.

This skill is lightweight and focused: it configures only what greenfield skills need (artifact directories and platform integration). It does NOT set up code patterns, report templates, plans, or documentation directories — those are handled when the project transitions to the development phase. Design tool integration (Figma/Canva) is only available through this skill — ensure-config does not configure design tools.

The `## Arness` section written by this skill is forward-compatible with Arness Code and Arness Infra. When either plugin's ensure-config or init runs later, it detects the existing configuration and adds the remaining fields without disrupting greenfield settings.

## Workflow

### Step 1: Check Existing Configuration

Read the project's CLAUDE.md and look for a `## Arness` section. If no CLAUDE.md exists, create one at the project root before proceeding.

**If the section does not exist:**
- Proceed to Step 2 (fresh init)

**If the section exists:**
1. Parse all config fields from the existing `## Arness` block
2. Read the current plugin version from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`
3. Show the user their current configuration
4. Ask via `AskUserQuestion`:
   - **Review** — Show current configuration summary, no changes
   - **Update** — Check for missing greenfield fields and fill them in
   - **Reconfigure** — Re-run the full setup flow from scratch
   - **Keep** — No changes
- If **Review** → display a clean summary of all `## Arness` fields relevant to Arness Spark, then exit the skill
- If **Keep** → done, exit the skill
- If **Reconfigure** → continue to Step 2, pre-filling known values as defaults
- If **Update** → check which greenfield fields are missing (Vision directory, Use cases directory, Prototypes directory, Spikes directory, Visual grounding directory, Reports directory, Git, Platform, Issue tracker, Figma, Canva) and only process those. For missing directory fields, ask the user with the existing value as the default. For missing Git/Platform/Issue tracker, re-run Step 3 detection. For missing Figma/Canva, re-run Step 3.4 design tool integration. Then proceed to Step 4 to write the updated config. Preserve all existing fields that are not managed by this skill (such as Plans directory, Specs directory, Report templates, etc.).

---

### Step 2: Configure Output Directories

Ask the user about each output directory. All defaults are under `.arness/` to centralize Arness artifacts in one place.

**2.1. Vision directory:**

"Where should Arness store greenfield vision documents (product concept, architecture vision, style brief, spike results, feature backlog)?"

- Default: `.arness/vision`
- Used by: `/arn-spark-discover`, `/arn-spark-arch-vision`, `/arn-spark-spike`, `/arn-spark-style-explore`, `/arn-spark-feature-extract`, `/arn-spark-dev-setup`

**2.2. Use cases directory:**

"Where should Arness store use case documents?"

- Default: `.arness/use-cases`
- Used by: `/arn-spark-use-cases`, `/arn-spark-use-cases-teams`

**2.3. Prototypes directory:**

"Where should Arness store prototype versions and review reports?"

- Default: `.arness/prototypes`
- Used by: `/arn-spark-static-prototype`, `/arn-spark-clickable-prototype`

**2.4. Spikes directory:**

"Where should Arness store technical spike POC code?"

- Default: `.arness/spikes`
- Used by: `/arn-spark-spike`

**2.5. Visual grounding directory:**

"Where should Arness store visual grounding assets (reference images, design mockups, brand assets)?"

- Default: `.arness/visual-grounding`
- Used by: `/arn-spark-style-explore`, `/arn-spark-static-prototype`, `/arn-spark-clickable-prototype`

Create three subfolders inside the visual grounding directory: `references/`, `designs/`, `brand/`.

**2.6. Reports directory:**

"Where should Arness store stress test reports and other analysis output?"

- Default: `.arness/reports`
- Used by: `/arn-spark-stress-interview`, `/arn-spark-stress-competitive`, `/arn-spark-stress-premortem`, `/arn-spark-stress-prfaq`, `/arn-spark-concept-review`

After creating the Reports directory (`mkdir -p <chosen-path>`), also create the `stress-tests/` subdirectory: `mkdir -p <chosen-path>/stress-tests/`

For each directory:
- Accept any relative path the user provides (relative to the project root)
- If updating an existing config (from Step 1), show the current path as the default
- Create the directory if it does not exist: `mkdir -p <chosen-path>`

---

### Step 3: Detect Git, Platform, and Issue Tracker

**Shared field preservation:** If `## Arness` already exists and the shared fields (Git, Platform, Issue tracker, Jira site, Jira project) are already present from a prior init (this plugin or another — e.g., arn-code-init or arn-infra-init), **skip detection and preserve the existing values** — unless the user chose **Reconfigure** in Step 1. This prevents overwriting values set by another plugin in a monorepo.

Check if the project uses Git, determine the code hosting platform, and identify the issue tracker.

**3.1. Git check:**
1. Run `git rev-parse --is-inside-work-tree` to check for a git repository
2. If Git is not detected, inform the user: "This project is not a git repository. Git-dependent skills (Arness Code: `/arn-code-ship`, `/arn-code-review-pr`, `/arn-code-create-issue`, `/arn-code-pick-issue`) will be unavailable." Record Git: no, Platform: none, Issue tracker: none and proceed to Step 4.

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

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-init/references/platform-labels.md` for label details and which skills use each label.

**3.3b. If candidate is bitbucket:**
1. Run `bkt --version` to check if the Bitbucket CLI is installed
   - If NOT available → read and show the setup instructions from `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-init/references/bkt-setup.md`, then **STOP init**
2. Run `bkt auth status` to check authentication
   - If NOT authenticated → read and show the auth instructions from `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-init/references/bkt-setup.md`, then **STOP init**
3. Platform: **bitbucket** (confirmed)
4. Ask (using `AskUserQuestion`):

   > **Do you use Jira for issue tracking on this project?**
   > 1. **Yes** — Verify Atlassian MCP server and select a Jira project
   > 2. **No** — Skip issue tracker integration

   - **Yes** → verify the Atlassian MCP server:
     - Attempt to list Jira projects via the MCP tool
     - If MCP NOT available → read and show the setup instructions from `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-init/references/jira-mcp-setup.md`, then **STOP init**
     - If MCP available → list projects, present to user, user picks one
     - Store: Issue tracker: **jira**, Jira site: (from MCP context or ask user), Jira project: (user's pick)
     - No label creation needed (Jira labels are implicit — see `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-init/references/platform-labels.md`)
   - **No** → Issue tracker: **none**
     - Inform the user: "Issue management skills (Arness Code: `/arn-code-create-issue`, `/arn-code-pick-issue`) will be unavailable. PR and code workflow skills still work via bkt."

**3.4. Design tool integration:**

Detect design tool MCP availability, then ask the user's project-level decision.

**3.4a. Detection (automatic):**

1. Check if a Figma MCP server is configured:
   - Look for `figma` in the project's `.mcp.json` or attempt to invoke a Figma MCP tool
   - Record: Figma MCP available: yes | no

2. Check if a Canva MCP server is configured:
   - Look for `canva` in the project's `.mcp.json` or attempt to invoke a Canva MCP tool
   - Record: Canva MCP available: yes | no

**3.4b. User decision (ask):**

Present the detection results, then ask the user what they want to use for THIS project.

Show the detection context first:

- [If Figma MCP detected:] "Figma MCP is available on this machine."
- [If Figma MCP not detected:] "Figma MCP is not configured. ([Setup instructions](https://www.figma.com/blog/introducing-figma-mcp-server/))"
- [If Canva MCP detected:] "Canva MCP is available on this machine."
- [If Canva MCP not detected:] "Canva MCP is not configured. ([Setup instructions](https://www.canva.dev/docs/connect/mcp-server/))"

Then ask (using `AskUserQuestion`, multiSelect: true):

> **Which design tools do you want to use for this project?** (Even if an MCP is available, you may not need it for every project.)
> 1. **Figma** — Pull design data and export screens during style exploration and prototype validation [only show if MCP available]
> 2. **Canva** — Pull design assets during style exploration [only show if MCP available]
> 3. **None** — No design tool integration for this project

If the user selects a tool whose MCP is not available, inform them it requires MCP setup and suggest the setup link above.

Record the user's choices:
- **Figma:** yes | no (project-level decision, not just availability)
- **Canva:** yes | no (project-level decision, not just availability)

Downstream skills check these flags — not MCP availability — to decide whether to offer Figma/Canva integration. If the flag is `no`, the skill does not mention or attempt to use that MCP, even if it's technically available.

**3.5. Record results:**
- **Git:** yes | no
- **Platform:** github | bitbucket | none
- **Issue tracker:** github | jira | none
- **Jira site:** (only if Issue tracker is jira)
- **Jira project:** (only if Issue tracker is jira)
- **Figma:** yes | no
- **Canva:** yes | no

---

### Step 4: Persist Configuration to CLAUDE.md

Write (or update) the `## Arness` section in the project's CLAUDE.md:

```markdown
## Arness

- **Vision directory:** [chosen-path]
- **Use cases directory:** [chosen-path]
- **Prototypes directory:** [chosen-path]
- **Spikes directory:** [chosen-path]
- **Visual grounding directory:** [chosen-path]
- **Reports directory:** [chosen-path]
- **Git:** yes | no
- **Platform:** github | bitbucket | none
- **Issue tracker:** github | jira | none
- **Jira site:** <site>.atlassian.net
- **Jira project:** <KEY>
- **Figma:** yes | no
- **Canva:** yes | no
```

**Rules:**
- All directory paths MUST be relative to the project root, never absolute. This ensures portability across machines.
- The Jira site and Jira project fields are only written when Issue tracker is jira. Omit them entirely for other issue trackers.
- The Figma and Canva fields are only written when the user explicitly chooses to use them for this project. Omit fields set to `no`.
- Git, Platform, and Issue tracker fields are auto-detected in Step 3 and are not user-configurable. Figma and Canva are user-decided in Step 3.4.
- If updating an existing config that has additional fields from other plugins, **preserve all fields not managed by this skill**. This includes dev fields (Plans directory, Specs directory, Report templates, Template path, Template version, Template updates, Code patterns, Docs directory, Task list ID) and infra fields (Deferred, Experience level, Project topology, Application path, Providers, Providers config, Default IaC tool, Environments, Environments config, Tooling manifest, Resource manifest, Cost threshold, Validation ceiling, Infra plans directory, Infra specs directory, Infra docs directory, Infra report templates, Infra template path, Infra template version, CI/CD platform, Reference overrides, Reference version, Reference updates). For shared fields (Git, Platform, Issue tracker, Jira site, Jira project): if already present, preserve them — do not re-detect unless the user chose Reconfigure in Step 1. Replace only the greenfield fields listed above.
- Replace the existing `## Arness` section in place. Do not duplicate it.

---

### Step 5: Verify and Summarize

Confirm with the user:

- [ ] Vision directory configured and created: `[path]`
- [ ] Use cases directory configured and created: `[path]`
- [ ] Prototypes directory configured and created: `[path]`
- [ ] Spikes directory configured and created: `[path]`
- [ ] Visual grounding directory configured and created: `[path]`
- [ ] Visual grounding subfolders created: `references/`, `designs/`, `brand/`
- [ ] Reports directory configured and created: `[path]`
- [ ] Reports subdirectory created: `stress-tests/`
- [ ] Git detected: yes | no
- [ ] Platform detected: github | bitbucket | none
- [ ] Issue tracker detected: github | jira | none
- [ ] GitHub labels created (if Platform is github)
- [ ] Jira project selected (if Issue tracker is jira)
- [ ] Figma integration: yes | no (user's choice for this project)
- [ ] Canva integration: yes | no (user's choice for this project)
- [ ] `## Arness` section written to CLAUDE.md

List all created/modified files with their paths.

**Next steps:**

"Arness Spark is ready. Here is the recommended exploration pipeline:

1. **Define the product:** Run `/arn-spark-discover` to shape your product idea into a structured concept
2. **Stress-test the concept (optional):** Run `/arn-spark-stress-interview`, `/arn-spark-stress-competitive`, `/arn-spark-stress-premortem`, `/arn-spark-stress-prfaq` to validate the concept, then `/arn-spark-concept-review` to apply findings
3. **Define the architecture:** Run `/arn-spark-arch-vision` to choose technologies and design the system
4. **Write use cases:** Run `/arn-spark-use-cases` (or `/arn-spark-use-cases-teams` for expert debate) to specify system behavior
5. **Scaffold the project:** Run `/arn-spark-scaffold` to create the project skeleton
6. **Validate risks:** Run `/arn-spark-spike` to test critical technical assumptions
7. **Explore visual direction:** Run `/arn-spark-visual-sketch` to generate visual direction proposals and select a direction
8. **Define the style:** Run `/arn-spark-style-explore` to translate the visual direction into a complete design system
9. **Prototype:** Run `/arn-spark-static-prototype` and `/arn-spark-clickable-prototype` to validate the UI
10. **Extract features:** Run `/arn-spark-feature-extract` to build the backlog

When you are ready to transition from exploration to development: if you have the Arness Code plugin installed, run `/arn-planning` to start the development pipeline. Arness auto-configures code patterns, report templates, plans, and documentation directories on first use."

---

## Error Handling

- **User cancels at any step:** Confirm cancellation and exit gracefully. Do not leave partially written configuration. If some directories were already created, inform the user they can be removed manually.
- **Writing to CLAUDE.md fails:** Print the full `## Arness` config block in the conversation so the user can insert it manually. Suggest checking file permissions.
- **`gh auth login` or `bkt auth login` not resolved:** Explain the issue and stop init. The user must resolve authentication before proceeding. They can re-run `/arn-spark-init` after fixing auth.
- **Re-running is safe:** Step 1 detects the existing config and offers Update / Reconfigure / Keep. No data is lost on re-run.
- **Arness Init run after Spark Init:** Fully supported. Arness Init's upgrade flow detects the existing greenfield fields and adds the missing development fields (Plans, Specs, Templates, Code patterns, Docs). Greenfield fields are preserved.
