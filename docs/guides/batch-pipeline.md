---
title: "Batch Pipeline"
description: "Plan, implement, and merge multiple features in parallel using worktree-isolated agents"
sidebar:
  order: 23
---

# Batch Pipeline

When you have a backlog of features ready to build, the batch pipeline plans and implements them in parallel — each feature in its own isolated Git worktree, each with its own PR. Inspired by the recently announced Claude Code batch capabilities, Arness extends the concept with batch-merge for automated PR conflict resolution and batch-simplify for cross-feature deduplication after merge.

## When to Use Batch

- You have multiple features specced and planned (or ready to be planned)
- Features are independent enough to implement in parallel
- You want to maximize throughput without manual coordination

## The Four Stages

### 1. Batch Planning

```
/arn-code-batch-planning
```

Batch planning takes multiple features and specs them in parallel:

- Selects unblocked features from your backlog (Spark feature files, GitHub issues, Jira issues, or plain descriptions)
- Spawns a batch-analyzer agent per feature to generate draft specifications
- Reviews and refines specs through the standard feature-spec flow
- Generates implementation plans for approved specs

Features with dependencies are sequenced automatically — independent features proceed in parallel.

### 2. Batch Implementation

```
/arn-code-batch-implement
```

Each planned feature gets its own background agent running in a separate Git worktree:

- **Worktree isolation** — each agent works on an independent copy of the repository, preventing conflicts during development
- **Full pipeline per feature** — each agent runs the standard execute-plan workflow (task execution, review, simplification)
- **Background execution** — agents run concurrently while you continue working
- **PR per feature** — each agent creates its own pull request when done

### 3. Batch Merge

```
/arn-code-batch-merge
```

When implementation PRs are ready:

- Discovers all open batch PRs
- Analyzes for cross-feature conflicts using a batch-PR-analyzer agent
- Determines the optimal merge order based on dependencies and conflict risk
- Executes merges sequentially, resolving conflicts as needed

### 4. Batch Simplify

```
/arn-code-batch-simplify
```

After merging multiple features:

- Scans for duplication introduced across features (two features may have created similar utilities)
- Identifies consolidation opportunities
- Proposes cross-feature refactoring to reduce redundancy

## Example Workflow

Starting with a Spark feature backlog containing 5 features:

```
/arn-code-batch-planning          # Specs and plans all 5 features
                                   # 3 are independent, 2 have dependencies

/arn-code-batch-implement          # 3 independent features build in parallel
                                   # 2 dependent features queue behind their blockers

/arn-code-batch-merge              # Merges all 5 PRs in dependency order

/arn-code-batch-simplify           # Finds and consolidates cross-feature duplication
```

## Tips

- **Feature independence matters** — the more independent your features are, the more parallelism you get. Spark's feature extraction produces dependency-tracked features by design.
- **Review PRs before batch merge** — each feature PR can be reviewed individually before merging the batch.
- **Works with any feature source** — Spark feature files, GitHub issues, Jira issues, or plain descriptions all work as batch inputs.

## Next Steps

- **[Your First Feature](your-first-feature.md)** — for single-feature implementation
- **[Greenfield to Production](greenfield-to-production.md)** — for the complete Spark → Code → Infra journey
- **[Arness Code](../plugins/arn-code.md)** — full plugin reference
