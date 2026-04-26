# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Purpose

Arness is a plugin marketplace for Claude Code containing three independently installable plugins for development, greenfield exploration, and infrastructure. The repository is itself a valid Claude Code marketplace, so plugins can be tested locally.

## Architecture

```
arness/                                 # Marketplace repository
├── .claude-plugin/
│   └── marketplace.json                # Marketplace catalog (lists all 3 plugins)
├── plugins/
│   ├── arn-code/                        # Core development plugin
│   │   ├── .claude-plugin/plugin.json
│   │   ├── skills/                     # 25 pipeline skills
│   │   └── agents/                     # 14 specialist agents
│   ├── arn-spark/                       # Greenfield exploration plugin
│   │   ├── .claude-plugin/plugin.json
│   │   ├── skills/                     # 19 exploration skills
│   │   └── agents/                     # 13 specialist agents
│   └── arn-infra/                      # Infrastructure plugin
│       ├── .claude-plugin/plugin.json
│       ├── skills/                     # 23 infrastructure skills
│       └── agents/                     # 9 specialist agents
└── assets/                             # Shared assets (banner, etc.)
```

**Key rule:** All plugin component directories (skills/, agents/) must be at the plugin root, NOT inside `.claude-plugin/`.

## Template Management

When updating default report templates in `plugins/arn-code/skills/arn-code-save-plan/report-templates/default/`:

1. Make changes to the template JSON files
2. Bump `version` in the relevant plugin's `.claude-plugin/plugin.json`
3. Test by running `arn-code-init` in a test project -- templates will be copied and fresh checksums generated
4. Projects using the previous version will be prompted to update on next Arness skill invocation (behavior depends on their `Template updates` preference)

Checksums are generated at init-time by Claude (via `sha256sum` or `shasum -a 256`), not pre-computed in the repository.

## Plugin Component Conventions

### Skills (preferred for new functionality)
- Each skill lives in `plugins/<plugin>/skills/<skill-name>/SKILL.md`
- Frontmatter: `name`, `description` (trigger conditions — use "This skill should be used when..."), `version`
- Supporting files (references, scripts, examples) go in the same subdirectory

### Agents
- Files: `plugins/<plugin>/agents/<agent-name>.md`
- Frontmatter: `name`, `description` (with `<example>` blocks for triggers), `tools`, `model`, `color`

### User Interaction Convention
- All discrete user choices (numbered options, yes/no decisions, multi-select menus) MUST use `Ask (using \`AskUserQuestion\`):` followed by the bold question text and numbered options
- Conversational exploration loops (open-ended back-and-forth) remain as plain text
- Free-form text input prompts ("describe what you want") remain as plain text
- Informational "next steps" lists (sequential workflow guidance) remain as plain text
- Multi-select choices use `multiSelect: true` with clear multi-select instruction text
- Menus with more than 4 options MUST be restructured into layered questions (2-4 options per layer)
- AskUserQuestion is only available in the main conversation — agents/subagents cannot use it

### Path References
**No user-specific paths in committed files.** Never embed usernames, home directories, or machine-specific absolute paths (e.g., `/home/username/...`) in any file that gets committed — including skills, agents, specs, plans, and documentation. Use `${CLAUDE_PLUGIN_ROOT}`, relative paths, or generic placeholders like `/path/to/arness` instead.

## Versioning

When creating a PR, always suggest bumping the `version` in the affected plugin's `.claude-plugin/plugin.json`. Follow semver:

- **Patch** (0.1.0 → 0.1.1): Bug fixes, typo corrections, minor wording changes
- **Minor** (0.1.0 → 0.2.0): New features, new skills/commands/agents, significant behavior changes to existing components
- **Major** (0.2.0 → 1.0.0): Breaking changes that require users to re-run `arn-code-init` or manually update their `## Arness` config

Include the version bump in the PR commit, not as a separate commit.

## Linting Configuration

Each project's `## Arness` block carries a `Linting:` field with one of three values:

- **`enabled`** — run lint as a hard gate. The codebase analyzer detects per-service linters and writes them to `<code-patterns-dir>/linting.md`. The `arn-code-task-executor` runs lint on touched files at task completion (silent — findings flow into the implementation report). The `arn-code-ship` skill runs lint against the staged diff before commit and surfaces a 3-option menu (Fix now / File a backlog issue / Proceed with documented reason) when issues are found, with the suggested default adapting to issue count.
- **`none`** — project has no linters configured. Lint gates are skipped silently in both executor and ship.
- **`skip`** — user explicitly disabled the gate. Same behavior as `none`; provided so the user can opt back in later.

When the field is missing, `arn-code-ensure-config` (Layer 2c) prompts the user with the same 3-option menu and, if `enabled` is chosen, invokes the codebase analyzer to generate `linting.md`. The `Discovered run command` in `linting.md` is a hint — downstream consumers adapt to the actual environment (e.g., pnpm vs npm).

## Testing Locally as a Plugin

```bash
# Test a single plugin (from the repo root)
claude --plugin-dir plugins/arn-code
claude --plugin-dir plugins/arn-spark
claude --plugin-dir plugins/arn-infra

# Or install from the local marketplace:
# /plugin marketplace add /absolute/path/to/arness
# /plugin install arn-code@arn-marketplace
```

## Arness

- **Plans directory:** .arness/plans
- **Specs directory:** .arness/specs
- **Report templates:** default
- **Template path:** .arness/templates
- **Template version:** 2.3.0
- **Template updates:** ask
- **Code patterns:** .arness
- **Docs directory:** .arness/docs
- **Vision directory:** .arness/vision
- **Use cases directory:** .arness/use-cases
- **Prototypes directory:** .arness/prototypes
- **Spikes directory:** .arness/spikes
- **Visual grounding directory:** .arness/visual-grounding
- **Reports directory:** .arness/reports
- **Linting:** skip
- **Git:** yes
- **Platform:** github
- **Issue tracker:** github
- **Task list ID:** arness
