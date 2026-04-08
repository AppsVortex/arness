---
title: "Arness Code Agents"
description: "Complete catalog of all Arness Code agents"
sidebar:
  order: 33
---

Complete reference for all 16 Arness Code agents. Agents are specialist AI workers invoked by skills -- you don't call them directly. For workflow context, see the [Arness Code plugin guide](../plugins/arn-code.md).

## Architecture & Planning

| Agent | Purpose | Tools | Model |
|-------|---------|-------|-------|
| `arn-code-architect` | Designs how features should be implemented within an existing codebase. Synthesizes feature ideas with codebase patterns to produce concrete implementation proposals. | Read, Glob, Grep, LSP, WebSearch | opus |
| `arn-code-feature-planner` | Generates or revises implementation plans from Arness specifications and codebase patterns. Produces PLAN_PREVIEW files for review and iterative refinement. | Read, Glob, Grep, Write, Edit, Bash, LSP | opus |
| `arn-code-pattern-architect` | Recommends code patterns, testing strategies, and architectural best practices for greenfield projects. Creates patterns rather than discovering existing ones. | Read, Glob, WebSearch | opus |
| `arn-code-planner` | Compiles brief, structured fix plans for the bug-spec simple-fix path. Takes a small set of fix instructions and produces a structured plan document. | Read | opus |

## Execution

| Agent | Purpose | Tools | Model |
|-------|---------|-------|-------|
| `arn-code-task-executor` | Executes a single plan task (implementation or testing). Reads pattern docs, follows phase plan directives, generates reports, and self-heals during testing. | Read, Glob, Grep, Edit, Write, Bash, LSP | opus |
| `arn-code-task-reviewer` | Validates a completed task's implementation against stored patterns, acceptance criteria, and test results. Returns a verdict: pass, pass-with-warnings, or needs-fixes. | Read, Glob, Grep, Write, Bash | opus |
| `arn-code-batch-analyzer` | Pre-generates draft feature specifications for multiple features in parallel during batch planning. Takes a single feature from any source and produces a DRAFT_FEATURE file. | Read, Glob, Grep, Write, Bash | opus |
| `arn-code-batch-pr-analyzer` | Analyzes multiple open batch PRs for cross-cutting issues. Fetches CI/review/mergeable status, builds a conflict map, checks for duplicated code and inconsistent approaches across PRs. | Read, Glob, Grep, Bash | opus |

## Analysis & Investigation

| Agent | Purpose | Tools | Model |
|-------|---------|-------|-------|
| `arn-code-codebase-analyzer` | Gathers codebase intelligence by analyzing project structure, conventions, and patterns. Invoked by save-plan to inform plan structuring with codebase context. | Glob, Grep, Read | opus |
| `arn-code-investigator` | Traces bugs to their root cause through hypothesis-driven investigation. Synthesizes bug reports with codebase context to determine what went wrong, where, and why. | Read, Glob, Grep, LSP | opus |
| `arn-code-test-specialist` | Runs the project's test suite and interprets results. Used as a quality gate during assessment before shipping implementation changes. | Read, Glob, Grep, Bash | opus |

## Specialist Expertise

| Agent | Purpose | Tools | Model |
|-------|---------|-------|-------|
| `arn-code-ux-specialist` | Provides UI/UX design guidance including component architecture, user experience flows, accessibility, and frontend patterns. Participates in feature-spec-teams debates. | Read, Glob, Grep, LSP, WebSearch | opus |
| `arn-code-security-specialist` | Performs security analysis including threat modeling, OWASP Top 10 analysis, and security pattern evaluation. Joins feature-spec-teams debates for security-sensitive features. | Read, Glob, Grep, LSP, WebSearch | opus |
| `arn-code-bug-fixer` | Implements approved fix plans with code changes, test verification, and structured bug fix reports. Takes a fix plan and produces a complete report of changes and test results. | Read, Glob, Grep, Edit, Write, Bash, LSP | opus |
| `arn-code-sketch-builder` | Creates or updates interface previews using the project's actual framework and styling. Adapts output based on paradigm (web, CLI, TUI) to produce runnable artifacts. | Read, Write, Glob, Grep, Bash, Edit | opus |

## Diagnostics

| Agent | Purpose | Tools | Model |
|-------|---------|-------|-------|
| `arn-code-doctor` | Diagnoses Arness workflow issues by analyzing configuration, directory structure, and skill behavior against expected patterns. Never reads project source code or business logic. | Read, Glob, Grep, Bash | opus |
