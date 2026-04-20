---
title: "Arness Code"
description: "Core development pipeline — spec, plan, build, review, and ship features with AI-assisted workflows"
sidebar:
  order: 11
---

![Arness Code](../../assets/code.png)

[![Docs](https://img.shields.io/badge/docs-arness.appsvortex.com-7e3ff2?logo=astro&logoColor=white)](https://arness.appsvortex.com/)

Arness Code is the development pipeline that treats AI-assisted coding like engineering, not guesswork. Every feature flows through spec, plan, structure, execute, review, and ship — producing a durable artifact at each step that feeds the next. The pipeline operates at three ceremony tiers — swift, standard, and thorough — that scale process to match scope. A one-file fix gets a lightweight pass. A cross-cutting refactor gets phases, task dependencies, parallel execution, and quality gates.

## Start Here — Five Entry Points

Most developers never need to think about individual skills. These five entry points detect what you need and chain the right steps together.

| Entry Point | What it does |
|---|---|
| `/arn-planning` | Start a new feature or bug fix. Scope router that detects complexity and routes through the appropriate ceremony tier (swift, standard, or thorough). Chains through spec, plan, save, review, and taskify. |
| `/arn-implementing` | Resume or execute an existing plan. Manages the build-simplify-review cycle. Routes to execute-plan, swift, or standard depending on context. |
| `/arn-shipping` | Commit, push, and create a PR with structured messaging. Invokes ship and chains to reviewing-pr. |
| `/arn-reviewing-pr` | Validate PR review comments, categorize findings (fix, defer, reject), and apply fixes. Chains back to implementing if substantial fixes are needed. |
| `/arn-assessing` | Comprehensive codebase review against stored patterns. Identifies improvements and chains to implementing. |

Two more commands round out the basics:

- **`/arn-code-init`** *(optional)* — Explicitly set up Arness for your project with full control. Analyzes your codebase, learns patterns, and generates pattern documentation. Not required — Arness auto-configures on first skill use.
- **`/arn-code-help`** — See where you are in the development pipeline. Cross-plugin aware — hints about Spark and Infra activity at the bottom.

## Pipeline at a Glance

```mermaid
flowchart LR
    A[Spec] --> B[Plan] --> C[Structure] --> D[Review Plan]
    D --> E[Taskify] --> F[Execute] --> G[Simplify]
    G --> H[Review] --> I[Docs] --> J[Ship]

    style A fill:#001a2c,stroke:#00B4D8,color:#00B4D8
    style B fill:#001a2c,stroke:#00B4D8,color:#00B4D8
    style C fill:#001a2c,stroke:#00B4D8,color:#00B4D8
    style D fill:#001a2c,stroke:#00B4D8,color:#00B4D8
    style E fill:#001a2c,stroke:#00B4D8,color:#00B4D8
    style F fill:#001a2c,stroke:#00B4D8,color:#00B4D8
    style G fill:#001a2c,stroke:#00B4D8,color:#00B4D8
    style H fill:#001a2c,stroke:#00B4D8,color:#00B4D8
    style I fill:#001a2c,stroke:#00B4D8,color:#00B4D8
    style J fill:#001a2c,stroke:#00B4D8,color:#00B4D8
```

Every step is optional. Use all of them for a thorough multi-phase feature, or just the ones that fit your situation. The entry points handle routing automatically.

## Workflows

### Full Feature Development (Thorough Tier)

The complete pipeline for complex features — multi-phase work that touches many files, introduces new patterns, or carries architectural risk.

1. **Specify** — `/arn-code-feature-spec` opens an iterative conversation with the architect agent to develop a specification. For contentious design decisions, `/arn-code-feature-spec-teams` runs a multi-agent debate to stress-test the approach. For bugs, `/arn-code-bug-spec` investigates with hypothesis-driven analysis and offers a dual path: simple fix or structured spec.

2. **Plan** — `/arn-code-plan` generates an implementation plan from the spec using the feature-planner agent. The plan includes phases, file-level changes, risk flags, and dependency ordering.

3. **Structure** — `/arn-code-save-plan` converts the plan into a structured project directory with `INTRODUCTION.md`, `PHASE_N_PLAN.md` files, and `TASKS.md`.

4. **Validate** — `/arn-code-review-plan` checks the plan for completeness, pattern compliance, and feasibility before any code is written.

5. **Taskify** — `/arn-code-taskify` converts `TASKS.md` into a Claude Code task list with dependencies, so execution respects the correct ordering.

6. **Execute** — `/arn-code-execute-plan` dispatches task-executor agents in parallel batches with reviewer validation gates between them. `/arn-code-execute-plan-teams` uses multi-agent collaboration for particularly complex tasks.

7. **Simplify** — `/arn-code-simplify` runs a post-execution optimization pass: dead code removal, duplication consolidation, naming improvements. Inspired by the Claude Code `/simplify` skill, extended with pattern compliance checks and artifact-aware analysis.

8. **Review** — `/arn-code-review-implementation` is the quality gate that validates the implementation against the plan and stored patterns.

9. **Document** — `/arn-code-document-project` generates developer documentation from the completed work.

10. **Ship** — `/arn-code-ship` commits, pushes, and creates a PR with structured messaging.

### Quick Changes (Swift and Standard Tiers)

Not everything needs a ten-step pipeline. Arness detects complexity and suggests the right tier automatically.

- **`/arn-code-swift`** — Lightweight implementation for 1-8 file changes. Pattern-aware: runs an architectural assessment, generates an inline plan, executes, and verifies. Produces a SWIFT report as an artifact. Best for small bug fixes, config changes, and minor feature additions.

- **`/arn-code-standard`** — Mid-ceremony path for medium scope. Bridges swift and thorough with a spec-lite phase and task-tracked execution. Good for features that touch a moderate number of files but do not warrant full phased planning.

- **`/arn-code-sketch`** — UI component preview using the project's actual framework. Generates a runnable preview for web, CLI, or TUI components so you can validate appearance and interaction before committing to full implementation. Inspired by the Claude Code `/frontend-design` skill, adapted to work within Arness's pipeline and support multiple paradigms.

When you use `/arn-planning`, the scope router analyzes your request and suggests the appropriate tier. You can always override the suggestion.

### Batch Pipeline (Multi-Feature Parallel)

Plan, build, and merge multiple features simultaneously using isolated worktrees and parallel agents. Inspired by the recently announced Claude Code batch capabilities, extended with batch-merge for automated PR conflict resolution and batch-simplify for cross-feature deduplication.

- **`/arn-code-batch-planning`** — Plan multiple features in parallel using batch-analyzer agents. Takes a feature backlog and produces individual plans for each feature.

- **`/arn-code-batch-implement`** — Parallel worktree-isolated background agents implement features simultaneously. Each feature gets its own branch and worktree, so there are no conflicts during development.

- **`/arn-code-batch-merge`** — Discovers open batch PRs, analyzes conflicts, determines optimal merge order, and executes merges sequentially.

- **`/arn-code-batch-simplify`** — Post-merge cross-feature deduplication and consolidation. Catches redundant abstractions and inconsistent patterns introduced when multiple features are developed in isolation.

### Codebase Health and Maintenance

- **`/arn-code-assess`** — Comprehensive technical assessment with 7 internal gates: scope definition, analysis, prioritization, spec generation, plan generation, execution, and shipping. Produces an actionable improvement plan.

- **`/arn-code-catch-up`** — Retroactively documents commits made outside the Arness pipeline. Backfills artifacts (specs, plans, change records) for those 2am hotfixes so the project history stays complete.

- **`/arn-code-report`** — Diagnoses and reports Arness Code workflow issues. Cross-plugin aware — detects if the issue belongs to Spark or Infra and suggests the right report skill. For Spark issues use `/arn-spark-report`, for Infra use `/arn-infra-report`.

## Utility Skills

- **`/arn-code-pick-issue`** — Browse GitHub issues filtered by Arness labels, then route the selected issue directly into the appropriate workflow.
- **`/arn-code-create-issue`** — Create GitHub or Jira issues with Arness labels pre-applied so they are ready for pipeline pickup.

## All Skills Summary

| Command | What it does |
|---|---|
| **Entry Points** | |
| `/arn-planning` | Scope router — detects complexity, chains spec through taskify |
| `/arn-implementing` | Resume or execute an existing plan |
| `/arn-shipping` | Commit, push, and create a PR |
| `/arn-reviewing-pr` | Validate PR comments, categorize, and apply fixes |
| `/arn-assessing` | Codebase review against stored patterns |
| **Initialization & Help** | |
| `/arn-code-init` | Set up Arness for a project (patterns, config, templates) |
| `/arn-code-help` | Show pipeline state and available next steps |
| **Specification** | |
| `/arn-code-feature-spec` | Iterative spec development with architect agent |
| `/arn-code-feature-spec-teams` | Multi-agent debate for contested design decisions |
| `/arn-code-bug-spec` | Hypothesis-driven bug investigation and spec |
| **Planning** | |
| `/arn-code-plan` | Generate implementation plan from spec |
| `/arn-code-save-plan` | Structure plan into project directory |
| `/arn-code-review-plan` | Validate plan for completeness and compliance |
| **Execution** | |
| `/arn-code-taskify` | Convert TASKS.md into task list with dependencies |
| `/arn-code-execute-plan` | Dispatch task-executor agents in parallel batches |
| `/arn-code-execute-plan-teams` | Multi-agent collaborative execution |
| `/arn-code-execute-task` | Execute a single task from the task list |
| **Lightweight Paths** | |
| `/arn-code-swift` | 1-8 file changes with inline plan and SWIFT report |
| `/arn-code-standard` | Mid-ceremony spec-lite and task-tracked execution |
| `/arn-code-sketch` | UI component preview using project framework |
| **Quality** | |
| `/arn-code-simplify` | Post-execution optimization pass |
| `/arn-code-review-implementation` | Quality gate against plan and patterns |
| `/arn-code-review-pr` | PR review comment triage and fix application |
| **Batch** | |
| `/arn-code-batch-planning` | Plan multiple features in parallel |
| `/arn-code-batch-implement` | Parallel worktree-isolated implementation |
| `/arn-code-batch-merge` | Analyze conflicts and merge batch PRs |
| `/arn-code-batch-simplify` | Cross-feature deduplication after merge |
| **Shipping & Docs** | |
| `/arn-code-ship` | Commit, push, and create PR with structured messaging |
| `/arn-code-document-project` | Generate developer documentation |
| **Utility** | |
| `/arn-code-assess` | Comprehensive technical assessment (7 gates) |
| `/arn-code-pick-issue` | Browse issues by Arness labels, route to workflow |
| `/arn-code-create-issue` | Create issues with Arness labels |
| `/arn-code-catch-up` | Backfill artifacts for out-of-pipeline commits |
| **Diagnostics** | |
| `/arn-code-report` | Diagnose and report Arness Code workflow issues (cross-plugin routing) |
| **Configuration** | |
| `/arn-code-ensure-config` | Validate and repair Arness project configuration |

For full skill details including parameters and examples, see [Arness Code Skills Reference](../reference/arn-code-skills.md).

## Agents at Work

Arness Code includes 16 specialist agents that handle different aspects of the pipeline. The **architect** develops specifications through iterative conversation. The **feature-planner** and **planner** translate specs into actionable plans. **Task-executor** agents run in parallel batches to implement tasks, with **task-reviewer** agents validating each batch before the next begins. The **codebase-analyzer** and **pattern-architect** ground every decision in your project's actual code and conventions. The **investigator** and **bug-fixer** handle diagnosis and repair. **Security-specialist**, **ux-specialist**, and **test-specialist** provide domain-specific review. The **batch-analyzer** and **batch-pr-analyzer** power the multi-feature parallel pipeline. The **sketch-builder** generates UI previews, and the **doctor** diagnoses pipeline issues.

For full agent details, see [Arness Code Agents Reference](../reference/arn-code-agents.md).

## Cross-Plugin Integration

Arness Code does not operate in isolation. It connects to the other Arness plugins at key handoff points:

- **From Spark** — Arness Spark's discovery and brainstorming workflows produce feature backlogs. Run `/arn-spark-help` for Spark exploration status, or `/arn-code-help` which detects Spark activity and provides a cross-plugin hint.
- **To Infra** — Code that Arness Code ships is ready for Arness Infra to deploy. The structured PR artifacts and change records produced by the pipeline feed directly into Infra's deployment workflows.
