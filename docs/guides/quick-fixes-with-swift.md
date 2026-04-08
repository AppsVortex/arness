---
title: "Quick Fixes with Swift"
description: "Lightweight pattern-aware implementation for small changes without the full pipeline"
sidebar:
  order: 22
---

# Quick Fixes with Swift

Not every change needs the full spec-plan-execute pipeline. Arness Code offers three ceremony tiers that match process depth to change scope.

## When to Use What

| Tier | Scope | Files | Use when |
|------|-------|-------|----------|
| **Swift** | Small | 1-8 | Bug fixes, config changes, small refactors, hotfixes, renames |
| **Standard** | Medium | 4-15 | Feature additions, moderate refactors, API changes |
| **Thorough** | Complex | 15+ | New features, architectural changes, cross-cutting work |

Arness detects complexity automatically when you run `/arn-planning` and suggests the right tier. You can always override.

## The Swift Workflow

```
/arn-code-swift
```

Or let `/arn-planning` route you there based on scope assessment.

Swift is a lightweight, pattern-aware workflow:

1. **Architectural assessment** — Arness reads your codebase patterns and understands the conventions
2. **Inline plan** — a brief description of what will change and why (no separate plan file)
3. **Execution** — implements the change following your project's patterns
4. **Verification** — runs relevant tests
5. **Review** — quick quality check

The output is a `SWIFT_<name>.md` change record and a `SWIFT_REPORT.json` — lightweight but sufficient for traceability. Every change gets documented, even the small ones.

## The Standard Workflow

```
/arn-code-standard
```

Standard bridges swift and thorough. It includes:

- A **spec-lite** — lighter than a full feature spec but more structured than swift's inline plan
- **Task-tracked execution** — work is broken into tracked tasks
- **Review** — quality check against patterns

The output is a `STANDARD_<name>.md` and `STANDARD_REPORT.json`.

## UI Previews with Sketch

For any change that involves UI components:

```
/arn-code-sketch
```

Sketch creates a preview of the UI change using your project's actual framework and styling system. It works for web, CLI, and TUI applications. Use it during feature spec to validate a design, or during implementation to check your work.

## Retroactive Documentation

Made a change outside the Arness pipeline? A 2am hotfix, an emergency patch, a quick manual edit?

```
/arn-code-catch-up
```

Catch-up examines recent commits and generates lightweight artifact records after the fact. This ensures the artifact trail remains complete even when the pipeline was bypassed.

## Scope Routing in Practice

When you run `/arn-planning` and describe your change, Arness assesses:

- How many files are likely affected
- Whether it crosses module/service boundaries
- Whether it involves new patterns or follows existing ones
- Whether there are test implications

Based on this, it suggests swift, standard, or thorough — and explains why. You always have the final say.

## Next Steps

- **[Your First Feature](your-first-feature.md)** — for the full thorough-tier walkthrough
- **[Batch Pipeline](batch-pipeline.md)** — for implementing multiple changes in parallel
- **[Arness Code](../plugins/arn-code.md)** — full plugin reference
