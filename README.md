# Arness

![Arness](assets/arness.png)

[![Docs](https://img.shields.io/badge/docs-arness.appsvortex.com-7e3ff2?logo=astro&logoColor=white)](https://arness.appsvortex.com/)

> Arness — H not required.

**Structured AI workflows for Claude Code. From first idea to production deploy.**

Seven entry commands. That's all you need to remember. Behind them, 134 specialist skills and agents handle the details across three independent plugins — ideation, development, and infrastructure.

Most AI coding tools help you write code faster. Arness helps you build software better. It gives your Claude Code session a structured pipeline: specs before code, plans before execution, reviews before shipping. Every stage produces a human-readable artifact that feeds the next. Nothing is hidden, nothing is locked in.

## Three Plugins, One Lifecycle

### Arness Spark — Where ideas come alive

![Arness Spark](assets/spark.png)

Most projects fail before the first commit — wrong problem, wrong audience, wrong architecture. Spark takes a raw idea and puts it through product discovery, stress testing, brand naming, use case writing, architecture evaluation, and interactive prototyping. By the time you write real code, you have a validated concept, a prioritized feature backlog, and a scaffolded codebase ready for development.

**Start here:** `/arn-brainstorming` | [Full guide](docs/plugins/arn-spark.md)

### Arness Code — Where products get built

![Arness Code](assets/code.png)

The development pipeline that treats AI-assisted coding like engineering, not guesswork. Every feature flows through spec, plan, structure, execute, review, and ship — with three ceremony tiers (swift, standard, thorough) that scale process to match scope. A one-file fix gets a lightweight pass. A cross-cutting refactor gets phases, task dependencies, and quality gates.

**Start here:** `/arn-planning` | [Full guide](docs/plugins/arn-code.md)

### Arness Infra — Where products go live

![Arness Infra](assets/infra.png)

A guided approach to containerization, IaC, deployment, and monitoring. Arness Infra audits your toolchain, generates Dockerfiles and IaC, configures environments and secrets, builds CI/CD pipelines, and walks you through deployment and verification. For complex changes, a structured change management pipeline mirrors the rigor of the development pipeline. *Infra is experimental — the newest and least mature of the three plugins. Always review generated infrastructure before applying it. Feedback and suggestions are welcome.*

**Start here:** `/arn-infra-wizard` | [Full guide](docs/plugins/arn-infra.md)

## How It Works

Arness asks you questions once and remembers. Your role, tech stack, preferred frameworks, and development conventions are captured on first run and reused across every session and every project. No repeated configuration.

Every skill produces a Markdown or JSON artifact — specs, plans, task lists, review reports, PR descriptions — stored in `.arness/` at your project root. Each artifact feeds the next stage in the pipeline, creating a traceable chain from initial idea to merged PR. You can read, edit, or version-control any of it.

Three ceremony tiers — swift, standard, and thorough — match process to scope automatically. A bug fix touching two files does not get the same pipeline as a new authentication system. Arness detects complexity and routes accordingly.

## Why Arness

| | |
|---|---|
| **Plain text, open source** | All artifacts are Markdown and JSON. MIT licensed. Read, edit, or delete anything. |
| **Learns your preferences** | Captures your stack, role, and conventions once. Every session uses them. |
| **Artifact-chain traceability** | Spec feeds plan feeds tasks feeds code feeds review feeds PR. Nothing is orphaned. |
| **Graduated ceremony** | Swift (1-8 files), Standard (medium scope), Thorough (complex) — process scales to match the work. |
| **Clean project structure** | Everything lives in `.arness/`. Your source tree stays yours. |
| **No vendor lock-in** | Works with GitHub, Bitbucket, Jira, Figma, and Canva. Remove Arness and your code is untouched. |

## Quick Start

```bash
# Add the Arness marketplace (one-time)
/plugin marketplace add AppsVortex/arness

# Install the plugins you need
/plugin install arn-spark@arn-marketplace    # New product from scratch
/plugin install arn-code@arn-marketplace     # Development pipeline
/plugin install arn-infra@arn-marketplace    # Infrastructure & deployment
```

Then run the entry point that matches what you want to do — Arness auto-configures on first use:

```
/arn-brainstorming    New product — discover, validate, prototype, extract features
/arn-planning         Plan a feature or fix from scratch
/arn-implementing     Pick up where you left off
/arn-shipping         Commit, push, open a PR
/arn-reviewing-pr     Handle PR feedback
/arn-assessing        Deep-dive codebase review
/arn-infra-wizard     Infrastructure end-to-end
```

**Works on any project.** Install Arness on a brand-new project or an existing codebase — it adapts either way. On existing projects, Arness retroactively analyzes your code patterns, application architecture, and infrastructure tools on first run. No migration, no setup ceremony.

> **Tip:** To save context, install only the plugin you need right now. When you're done with Spark's discovery phase, you can uninstall it (`/plugin uninstall arn-spark@arn-marketplace`) and install Code for the next stage. Each plugin works independently.

## Learn More

- **[Documentation site](https://arness.appsvortex.com/)** — Full docs, searchable
- **[Getting Started](docs/getting-started.md)** — Installation, first run, picking your path
- **[Core Concepts](docs/concepts.md)** — Entry points, skills, agents, and how it all connects
- **[Arness Spark](docs/plugins/arn-spark.md)** — Product discovery and prototyping
- **[Arness Code](docs/plugins/arn-code.md)** — The development pipeline
- **[Arness Infra](docs/plugins/arn-infra.md)** — Infrastructure and deployment
- **[Guides](docs/guides/)** — End-to-end walkthroughs
- **[Full Reference](docs/reference/)** — Every skill and agent across all three plugins

## Requirements

- [Claude Code](https://claude.ai/code) (CLI, Desktop, or Web)
- Git
- GitHub CLI (`gh`) or Bitbucket CLI (`bkt`) for platform integration (optional)
- Jira via [Atlassian MCP](https://mcp.atlassian.com) for Jira issue tracking (optional)

## Built with Arness

*Arness was built with Arness.* This repository — all three plugins, 134 components — was specced, planned, implemented, and shipped using its own pipeline.

Created by [Fryderyk Benigni](https://github.com/fredcallagan) at [AppsVortex](https://github.com/AppsVortex).

## Star History

<a href="https://star-history.com/#AppsVortex/arness&Date">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=AppsVortex/arness&type=Date&theme=dark" />
    <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=AppsVortex/arness&type=Date" />
  </picture>
</a>

## License

MIT
