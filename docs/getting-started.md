---
title: "Getting Started"
description: "Install Arness and run your first workflow in under 5 minutes"
sidebar:
  order: 1
---

# Getting Started

Arness installs through the Claude Code plugin marketplace. Pick the plugin that matches your starting point — you can always add more later.

## Prerequisites

- [Claude Code](https://claude.ai/code) (CLI, Desktop, or Web)
- Git initialized in your project (or an empty directory for greenfield)
- Optional: GitHub CLI (`gh`) or Bitbucket CLI (`bkt`) for PR and issue workflows
- Optional: [Atlassian MCP](https://mcp.atlassian.com) for Jira integration

## Install the Marketplace

This is a one-time setup:

```
/plugin marketplace add AppsVortex/arness
```

## Pick Your Path

### Starting a brand-new product?

Install Arness Spark and let it guide you from raw idea to validated prototype:

```
/plugin install arn-spark@arn-marketplace
/arn-brainstorming
```

Spark walks you through product discovery, concept validation, architecture decisions, prototyping, and feature extraction — with decision gates at every step. It auto-configures on first run. When you're ready to build, it hands off a prioritized feature backlog to the development pipeline.

[Learn more about Arness Spark](plugins/arn-spark.md)

### Have an existing codebase?

Install Arness Code to get the development pipeline:

```
/plugin install arn-code@arn-marketplace
/arn-planning
```

On first run, Arness analyzes your codebase, learns your patterns and conventions, and auto-configures everything it needs. Then `/arn-planning` takes your feature idea through spec, plan, build, review, and ship.

[Learn more about Arness Code](plugins/arn-code.md)

### Need to deploy?

Install Arness Infra for the infrastructure lifecycle:

```
/plugin install arn-infra@arn-marketplace
/arn-infra-wizard
```

The wizard audits your toolchain, walks you through containerization, IaC generation, environment configuration, and deployment — auto-configuring and adapting to your experience level.

[Learn more about Arness Infra](plugins/arn-infra.md)

### Want the full lifecycle?

Install all three:

```
/plugin install arn-spark@arn-marketplace
/plugin install arn-code@arn-marketplace
/plugin install arn-infra@arn-marketplace
```

Each plugin works independently, but together they connect: Spark's feature backlog feeds Code's planning pipeline, and Code's shipped artifacts feed Infra's deployment workflow.

## What Happens on First Run

The first time you invoke any Arness skill, it automatically:

1. **Creates your profile** — asks about your role, experience, and preferred tech stack (once — reused across all sessions and projects)
2. **Analyzes your project** — detects Git, platform (GitHub/Bitbucket), issue tracker, existing patterns and conventions. On existing codebases, Arness retroactively learns your code patterns, application architecture, and infrastructure tools.
3. **Sets up `.arness/`** — creates the artifact directory where specs, plans, reports, and other artifacts live. Your source tree stays clean.
4. **Writes configuration** — adds an `## Arness` section to your project's `CLAUDE.md` with directory paths and preferences

Everything is plain text. You can read, edit, or delete any of it.

> **Optional init skills:** For more control over setup, you can run `/arn-spark-init`, `/arn-code-init`, or `/arn-infra-init` explicitly — but it's not required. Running init later also updates Arness to the latest version.

**Works on any project.** Arness adapts to both brand-new projects and existing codebases. There's no migration, no setup ceremony — just install and go.

## The Seven Entry Points

Once installed, these are the only commands you need to remember:

| Command | What it does | Plugin |
|---------|-------------|--------|
| `/arn-brainstorming` | New product — discover, validate, prototype, extract features | Spark |
| `/arn-planning` | Plan a feature or fix from scratch | Code |
| `/arn-implementing` | Pick up where you left off | Code |
| `/arn-shipping` | Commit, push, open a PR | Code |
| `/arn-reviewing-pr` | Handle PR feedback | Code |
| `/arn-assessing` | Deep-dive codebase review | Code |
| `/arn-infra-wizard` | Infrastructure end-to-end | Infra |

Each entry point detects your project state and guides you through the relevant workflow steps. You don't need to know the 134 skills and agents behind them — the entry points orchestrate everything.

**Lost? Each plugin has a help skill** — `/arn-spark-help`, `/arn-code-help`, `/arn-infra-help` — that shows your current pipeline position and suggests what to do next. Help skills are cross-plugin aware: they detect activity in the other plugins and provide hints, so any help command can orient you across the full lifecycle.

## Next Steps

- **[Core Concepts](concepts.md)** — understand entry points, skills, agents, and how they connect
- **[Your First Feature](guides/your-first-feature.md)** — end-to-end walkthrough from idea to PR
- **[Greenfield to Production](guides/greenfield-to-production.md)** — the complete Spark → Code → Infra journey
