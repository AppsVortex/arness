---
title: "Greenfield to Production"
description: "Complete journey: from product idea through Spark discovery, Code implementation, to Infra deployment"
sidebar:
  order: 21
---

# Greenfield to Production

This guide walks through the complete Arness lifecycle — from a raw product idea to a deployed application. It uses all three plugins: Spark for discovery, Code for development, and Infra for deployment.

## Phase 1: Spark — From Idea to Validated Concept

### Start the Journey

```
/arn-brainstorming
```

The brainstorming wizard guides you through the entire greenfield pipeline with decision gates at every step. You can also invoke each skill individually.

### Discover Your Product

Spark's product strategist agent shapes your raw idea into a structured vision through conversation. You describe what you want to build; the agent probes for gaps, challenges assumptions, and structures the concept into:

- Vision and problem statement
- Target personas with detailed profiles
- Competitive landscape
- Product pillars (your non-negotiable principles)

### Stress Test the Concept

Before writing code, Spark puts your concept through four adversarial lenses:

- **Pre-mortem** — assumes your product failed, works backward to identify why
- **Competitive gap analysis** — maps your feature matrix against real competitors
- **Synthetic user interviews** — AI personas (Pragmatist, Skeptic, Power User) probe your concept
- **PR/FAQ stress test** — drafts your launch story, then tears it apart

A concept review consolidates all findings and updates your product vision.

### Name and Define

- **Brand naming** — strategic foundation, creative generation, scoring, and WHOIS domain checks
- **Architecture vision** — technology evaluation, stack selection, system design
- **Use cases** — formal Cockburn fully-dressed use cases with expert review

### Prototype and Validate

- **Scaffold** — generate a working project skeleton with your chosen stack
- **Visual sketches** — multiple design direction proposals as live HTML/CSS
- **Clickable prototype** — interactive screens with Playwright journey testing
- **Lock** — freeze the validated prototype as a development reference

### Extract Features

```
/arn-spark-feature-extract
```

Feature extraction pulls a prioritized backlog from all your Spark artifacts — product concept, architecture, use cases, prototypes. Features are written as structured files and optionally uploaded to GitHub Issues, Jira, or Bitbucket.

## Phase 2: Code — From Features to Shipped Code

### Hand Off to the Development Pipeline

```
/arn-planning
```

Run this in your scaffolded project. Arness automatically analyzes the codebase patterns Spark established and sets up the development pipeline on first use. You can optionally run `/arn-code-init` first for more control over the configuration.

### Build Features from the Backlog

Arness detects the Spark feature backlog and lets you pick a feature to implement. From there, the standard development pipeline takes over: spec → plan → execute → review → ship.

For multiple features, the batch pipeline can plan and implement several features in parallel:

```
/arn-code-batch-planning
/arn-code-batch-implement
/arn-code-batch-merge
```

### Ship Each Feature

```
/arn-shipping
```

Each feature gets its own PR with a structured description referencing the spec and plan.

## Phase 3: Infra — From Code to Cloud

### Set Up Infrastructure

```
/arn-infra-wizard
```

The wizard auto-configures and walks through the infrastructure pipeline:

1. **Discover** — audits your tools and auth state
2. **Containerize** — generates Dockerfiles and docker-compose for your application
3. **Define** — produces IaC (Terraform, Pulumi, CDK, etc.) for your cloud provider
4. **Configure** — sets up environments (dev/staging/production) and secrets management
5. **Pipeline** — generates CI/CD workflows
6. **Deploy** — deploys with cost and security gates
7. **Verify** — health checks, DNS, SSL validation
8. **Monitor** — sets up logging, metrics, and alerting

### Structured Changes

For subsequent infrastructure changes, use the change management pipeline:

```
/arn-infra-change-spec
```

This mirrors Code's spec → plan → execute → review flow but with infrastructure-specific gates: blast radius assessment, rollback checkpoints, security scanning, and cost estimation.

## The Complete Artifact Trail

By the end of this journey, your project contains:

| Phase | Artifacts |
|-------|-----------|
| **Spark** | Product concept, stress test reports, naming brief, architecture vision, use cases, prototype screenshots, feature backlog |
| **Code** | Feature specs, implementation plans, execution reports, review findings, PR descriptions |
| **Infra** | Tooling manifest, Dockerfiles, IaC code, environment configs, CI/CD workflows, deployment reports, runbooks |

Every artifact is plain Markdown or JSON — readable without Arness, committed to your repo, and serving as both AI context and human documentation.

## Next Steps

- **[Arness Spark](../plugins/arn-spark.md)** — deep dive into the discovery pipeline
- **[Arness Code](../plugins/arn-code.md)** — deep dive into the development pipeline
- **[Arness Infra](../plugins/arn-infra.md)** — deep dive into the infrastructure pipeline
