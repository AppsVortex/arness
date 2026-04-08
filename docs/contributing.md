---
title: "Contributing"
description: "Plugin conventions, development workflow, and how to contribute to Arness"
sidebar:
  order: 50
---

# Contributing

Arness is open source (MIT). Contributions are welcome — whether fixing a bug in a skill, adding a new agent, or improving documentation.

## Before You Start

- **Found a bug?** [Open an issue](https://github.com/AppsVortex/arness/issues) with the bug report template
- **Have a question?** Start a thread in [Discussions](https://github.com/AppsVortex/arness/discussions) — issues are for bugs and feature requests
- **Want a new feature?** [Open an issue](https://github.com/AppsVortex/arness/issues) with the feature request template, or discuss the idea first in Discussions
- **Ready to contribute code?** Fork the repo, follow the conventions below, and submit a PR

Please be respectful and constructive in all interactions. See our [Code of Conduct](../CODE_OF_CONDUCT.md).

## Repository Structure

```
arness/
├── .claude-plugin/
│   └── marketplace.json           # Marketplace catalog (lists all 3 plugins)
├── plugins/
│   ├── arn-code/                   # Core development plugin
│   │   ├── .claude-plugin/plugin.json
│   │   ├── skills/                # 35 pipeline skills
│   │   ├── agents/                # 16 specialist agents
│   │   └── hooks/                 # Event handlers
│   ├── arn-spark/                  # Greenfield exploration plugin
│   │   ├── .claude-plugin/plugin.json
│   │   ├── skills/                # 28 exploration skills
│   │   └── agents/                # 20 specialist agents
│   └── arn-infra/                  # Infrastructure plugin
│       ├── .claude-plugin/plugin.json
│       ├── skills/                # 25 infrastructure skills
│       └── agents/                # 10 specialist agents
├── docs/                          # Documentation (you are here)
└── assets/                        # Banner images
```

**Key rule:** All plugin component directories (skills/, agents/) must be at the plugin root, NOT inside `.claude-plugin/`.

## Skills

Skills are the preferred unit for new functionality. Each skill lives in its own directory:

```
plugins/<plugin>/skills/<skill-name>/SKILL.md
```

### Skill Frontmatter

```yaml
---
name: "skill-name"
description: "This skill should be used when... [trigger conditions]"
---
```

- **name**: The command name (invoked as `/skill-name`)
- **description**: Must start with "This skill should be used when..." — this is how Claude Code matches user intent to skills

Supporting files (references, scripts, examples) go in the same subdirectory as the SKILL.md.

## Agents

Agents are specialist subprocesses that skills invoke for deep expertise:

```
plugins/<plugin>/agents/<agent-name>.md
```

### Agent Frontmatter

```yaml
---
name: "agent-name"
description: "This agent should be used when... [with <example> blocks]"
tools:
  - Read
  - Glob
  - Grep
model: opus
color: blue
---
```

- **description**: Include `<example>` blocks showing trigger scenarios
- **tools**: Only the tools this agent needs (principle of least privilege)
- **model**: Usually `opus` for complex reasoning
- **color**: Terminal color for visual identification

## User Interaction Convention

- All discrete user choices (numbered options, yes/no) MUST use `Ask (using AskUserQuestion):` followed by bold question text
- Conversational exploration loops remain as plain text
- Multi-select choices use `multiSelect: true`
- Menus with more than 4 options MUST be restructured into layered questions (2-4 per layer)
- AskUserQuestion is only available in the main conversation — agents cannot use it

## Path References

Never embed user-specific paths (e.g., `/home/username/...`) in committed files. Use:
- `${CLAUDE_PLUGIN_ROOT}` for paths relative to the plugin root
- Relative paths within the plugin
- Generic placeholders like `/path/to/project`

## Versioning

When creating a PR, bump the `version` in the affected plugin's `.claude-plugin/plugin.json`:

| Change type | Version bump | Example |
|-------------|-------------|---------|
| Bug fixes, typos, minor wording | Patch | 2.0.0 → 2.0.1 |
| New features, new skills/agents, significant behavior changes | Minor | 2.0.0 → 2.1.0 |
| Breaking changes requiring re-init | Major | 2.1.0 → 3.0.0 |

Also update the version in `.claude-plugin/marketplace.json` to match. Include both version bumps in the PR commit, not as separate commits.

## Testing Locally

```bash
# Test a single plugin
claude --plugin-dir plugins/arn-code
claude --plugin-dir plugins/arn-spark
claude --plugin-dir plugins/arn-infra

# Or install from the local marketplace
# /plugin marketplace add /absolute/path/to/arness
# /plugin install arn-code@arn-marketplace
```

## Development Workflow

1. Fork and clone the repository
2. Create a feature branch
3. Make your changes
4. Test locally with `claude --plugin-dir`
5. Bump the version in the affected plugin's `plugin.json`
6. Update `marketplace.json` if you bumped a plugin version
7. Submit a PR with a clear description of what changed and why
