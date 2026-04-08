---
title: "Your First Feature"
description: "End-to-end walkthrough: from feature idea to shipped PR using Arness Code"
sidebar:
  order: 20
---

# Your First Feature

This guide walks through building a feature from scratch using Arness Code. You'll go from a one-sentence idea to a shipped PR.

## Prerequisites

- Arness Code installed (`/plugin install arn-code@arn-marketplace`)

## Step 1: Start Planning

```
/arn-planning
```

Arness asks what you want to build. Describe your feature in plain language:

> "I need to add email notifications when a user's subscription is about to expire."

Arness assesses the scope and routes you to the appropriate ceremony tier — swift for small changes, standard for medium, thorough for complex features.

## Step 2: Develop the Specification

For a medium-to-complex feature, Arness invokes the architect agent to refine your idea into a structured specification. It asks clarifying questions:

- What triggers the notification?
- How far in advance should it fire?
- What channels (email, in-app, both)?
- What existing code handles subscriptions?

The spec is saved as a Markdown file in `.arness/specs/`. You can review and edit it before proceeding.

## Step 3: Generate the Plan

Arness generates an implementation plan — phased, with task dependencies and acceptance criteria. For complex features, the plan is broken into phases:

- Phase 1: Data layer (expiration query, notification preferences)
- Phase 2: Notification service (email templates, delivery)
- Phase 3: Scheduling (cron job, retry logic)

You review the plan and approve, adjust, or request changes.

## Step 4: Execute

```
/arn-implementing
```

Arness converts the plan into a task list with dependencies, then dispatches task-executor agents. Independent tasks run in parallel; dependent tasks wait for their blockers to complete. Each task is reviewed by a task-reviewer agent before moving on.

After execution, a simplification pass looks for optimization opportunities, and a review checks the implementation against your plan and codebase patterns.

## Step 5: Ship

```
/arn-shipping
```

Arness commits, pushes, and creates a PR with a structured description that references the spec and plan. The PR description includes what changed, why, and how to test it.

## Step 6: Handle PR Feedback

If reviewers leave comments:

```
/arn-reviewing-pr
```

Arness fetches the PR comments, validates each finding against the codebase, and categorizes them as fix, defer, or reject. Approved fixes are applied and the PR is updated.

## What You Produced

At the end of this workflow, your `.arness/` directory contains:

- A **specification** documenting what you decided to build and why
- A **plan** with phased implementation strategy
- **Execution reports** showing what each agent did
- A **review report** with quality findings
- A **PR** with structured description

A new team member reading these artifacts can understand the entire feature — no context needed beyond what's in the files.

## Tips

- **Skip any step** — every stage has a skip option. If you already have a plan, jump to `/arn-implementing`.
- **Change ceremony mid-stream** — if a feature turns out more complex than expected, you can escalate from swift to standard or thorough.
- **Use `/arn-code-help`** — if you lose track of where you are in the pipeline, this skill detects your state and suggests the next step.

## Next Steps

- **[Quick Fixes with Swift](quick-fixes-with-swift.md)** — for smaller changes that don't need the full pipeline
- **[Batch Pipeline](batch-pipeline.md)** — for implementing multiple features in parallel
- **[Arness Code](../plugins/arn-code.md)** — full plugin reference
