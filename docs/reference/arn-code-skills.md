---
title: "Arness Code Skills"
description: "Complete catalog of all Arness Code skills"
sidebar:
  order: 32
---

Complete reference for all 35 Arness Code skills. For workflow-oriented documentation, see the [Arness Code plugin guide](../plugins/arn-code.md).

## Entry Points

The five first-citizen entry points are the primary way to interact with Arness Code. Each one orchestrates multiple internal skills and chains to the next stage.

| Command | Description | Version |
|---------|-------------|---------|
| `/arn-planning` | Go from an idea, issue, or bug report through to a complete implementation plan. Handles severity-aware scope routing across three ceremony tiers (swift, standard, thorough) and chains to arn-implementing. | 1.1.0 |
| `/arn-implementing` | Execute an implementation plan, run a quick implementation (swift), a standard-tier implementation, or manage the build-simplify-review cycle. Chains to arn-shipping. | 1.1.0 |
| `/arn-shipping` | Commit, push, and optionally create a pull request. Wraps arn-code-ship and chains to arn-reviewing-pr. | 1.0.0 |
| `/arn-reviewing-pr` | Validate PR review comments, categorize findings, and fix or defer issues. Chains back to arn-implementing if substantial fixes are needed. | 1.0.0 |
| `/arn-assessing` | Comprehensive technical assessment of the codebase against stored patterns, followed by prioritized improvement execution. Chains to arn-implementing if improvements are identified. | 1.0.0 |

## Initialization & Help

| Command | Description | Version |
|---------|-------------|---------|
| `/arn-code-init` | Set up Arness for a project by analyzing or defining code patterns, choosing configuration options, and persisting everything to CLAUDE.md. Optional -- Arness auto-configures with sensible defaults on first skill invocation. | 1.0.0 |
| `/arn-code-help` | Detect current position in the Arness Code development pipeline, render a diagram with the active stage marked, and suggest the next command. Cross-plugin aware — detects Spark and Infra activity and provides hints. Read-only. | 1.2.0 |

## Specification

| Command | Description | Version |
|---------|-------------|---------|
| `/arn-code-feature-spec` | Develop a feature idea into a well-formed specification through iterative conversation with architectural analysis. For XL features, creates multiple sub-feature specs with traceability. | 1.3.0 |
| `/arn-code-feature-spec-teams` | Develop a feature idea through structured debate between specialist agents (architects, UX experts, security specialists) using the experimental Agent Teams feature. | 0.1.0 |
| `/arn-code-bug-spec` | Investigate a bug through iterative conversation with diagnostic analysis. Bridges the gap between a bug report and either a direct fix or a structured bug specification for the pipeline. | 1.0.0 |

## Planning

| Command | Description | Version |
|---------|-------------|---------|
| `/arn-code-plan` | Generate an implementation plan from a specification by invoking the feature-planner agent. Presents the plan for review and iterates on feedback until approved. | 1.0.0 |
| `/arn-code-save-plan` | Convert a planning conversation into a structured, executable project with phased implementation plans, testing plans, task lists, and progress tracking. | 2.0.0 |
| `/arn-code-review-plan` | Validate a structured project plan for completeness, correctness, and pattern compliance before execution. Offers interactive remediation and can proceed directly to taskify. | 1.0.0 |

## Execution

| Command | Description | Version |
|---------|-------------|---------|
| `/arn-code-taskify` | Convert a project's TASKS.md into a Claude Code task list with dependency management. Creates tasks and wires up the dependency graph. | 1.0.0 |
| `/arn-code-execute-plan` | Execute a structured project plan by dispatching parallel batches of task-executor agents with review gates. Independent tasks run concurrently; dependent tasks wait for blockers. | 0.3.0 |
| `/arn-code-execute-plan-teams` | Execute a structured project plan using the experimental Agent Teams feature. Creates a coordinated team of executor, reviewer, and architect teammates. | 0.3.0 |
| `/arn-code-execute-task` | Execute a single specific task from the task list by spawning a task-executor agent with optional review. For one task only -- use execute-plan for the full plan. | 0.3.0 |

## Lightweight Paths

| Command | Description | Version |
|---------|-------------|---------|
| `/arn-code-swift` | Implement small features (1-8 files) through a lightweight, pattern-aware workflow: quick architectural assessment, inline plan, direct execution, verification, and review in a single session. | 1.1.0 |
| `/arn-code-standard` | Implement medium-complexity features through a mid-ceremony workflow: spec-lite generation, structured plan, task-tracked execution, verification, review-lite, and unified change record. | 1.0.0 |
| `/arn-code-sketch` | Create a working interface preview of a feature using the project's actual framework and conventions before committing to full implementation. Supports web, CLI, and TUI paradigms. | 1.0.0 |

## Quality & Review

| Command | Description | Version |
|---------|-------------|---------|
| `/arn-code-simplify` | Analyze recently implemented code for reuse opportunities, quality issues, and efficiency problems. Dispatches three parallel reviewers and applies user-approved fixes. | 1.0.0 |
| `/arn-code-review-implementation` | Post-execution quality gate that verifies an implementation matches the plan and follows stored code patterns. Reports issues as ERRORS, WARNINGS, INFO with a verdict. | 1.0.0 |
| `/arn-code-review-pr` | Review PR comments from GitHub or Bitbucket, validate each finding against actual code, categorize by severity, and optionally connect back into the pipeline for fixes. | 1.1.0 |

## Batch Pipeline

| Command | Description | Version |
|---------|-------------|---------|
| `/arn-code-batch-planning` | Plan multiple features from the greenfield Feature Tracker, GitHub issues, or Jira issues in a single session. Pre-analyzes all selected features in parallel, then guides sequential spec review with pipelined plan generation. | 1.0.0 |
| `/arn-code-batch-implement` | Spawn parallel worktree-isolated background agents to implement multiple features simultaneously. Each worker is a full independent session operating in its own git worktree. | 1.0.0 |
| `/arn-code-batch-merge` | Discover open batch PRs, analyze them for conflicts, determine an optimal merge order, and execute merges with user-guided conflict resolution. | 1.0.0 |
| `/arn-code-batch-simplify` | Post-merge cross-feature quality pass that finds duplication and consolidation opportunities across independently implemented features. Uses the 3-reviewer pattern with cross-feature context. | 1.0.0 |

## Shipping & Documentation

| Command | Description | Version |
|---------|-------------|---------|
| `/arn-code-ship` | Guide through branching, staging, committing, pushing, and optionally opening a pull request. Works standalone or as the final pipeline step. | 1.2.0 |
| `/arn-code-document-project` | Generate developer documentation for a completed feature or bug fix by reading plan artifacts, spec files, execution reports, and git diff. | 1.0.0 |

## Utility

| Command | Description | Version |
|---------|-------------|---------|
| `/arn-code-assess` | Run a comprehensive technical assessment of the codebase against stored patterns, let the user prioritize findings, then orchestrate the full pipeline for multiple improvements. | 1.0.0 |
| `/arn-code-pick-issue` | Browse issues filtered by Arness labels, select one, and route it to the appropriate pipeline skill. Supports local-first dependency resolution from a greenfield feature backlog. | 1.2.0 |
| `/arn-code-create-issue` | Create an issue in the configured issue tracker (GitHub or Jira) with Arness labels for type and priority. | 1.1.0 |
| `/arn-code-catch-up` | Retroactively document commits made outside the Arness pipeline. Scans git history, identifies undocumented commits, and generates lightweight CATCHUP records. | 1.0.0 |

## Diagnostics

| Command | Description | Version |
|---------|-------------|---------|
| `/arn-code-report` | Report an Arness Code workflow issue by running a diagnostic via the arn-code-doctor agent, then file a GitHub issue on the Arness repository. Cross-plugin aware — detects if the issue belongs to Spark or Infra and suggests the right report skill. | 1.1.0 |

## Configuration

| Command | Description | Version |
|---------|-------------|---------|
| `/arn-code-ensure-config` | Verify and establish Arness Code configuration for the current project. Runs automatically as Step 0 of all entry-point skills to guarantee a valid user profile and config section exist. | 1.0.0 |
