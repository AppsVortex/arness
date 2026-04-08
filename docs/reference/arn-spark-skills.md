---
title: "Arness Spark Skills"
description: "Complete catalog of all Arness Spark skills"
sidebar:
  order: 30
---

Complete reference for all 28 Arness Spark skills. For workflow-oriented documentation, see the [Arness Spark plugin guide](../plugins/arn-spark.md).

## Entry Points

| Command | Description | Version |
|---------|-------------|---------|
| `/arn-brainstorming` | Guided wizard that walks through the entire Arness greenfield exploration pipeline in a single continuous session with decision gates. Also triggers when adding a new feature to an existing greenfield project. | 1.0.0 |
| `/arn-spark-help` | Detect current position in the Spark exploration pipeline, render a diagram with the active stage marked, and suggest the next command. Cross-plugin aware — detects Code and Infra activity and provides hints. Read-only. | 1.0.0 |
| `/arn-spark-init` | Optional customization tool for greenfield projects. Configures Arness Spark settings and design tool integrations (Figma, Canva). Arness Spark auto-configures with sensible defaults on first skill invocation. | 1.0.0 |
| `/arn-spark-discover` | Explores and structures a greenfield product idea through guided conversation. Produces a product-concept.md capturing the product vision, core experience, target users, trust model, platforms, and scope boundaries. | 1.1.0 |

## Concept Validation

| Command | Description | Version |
|---------|-------------|---------|
| `/arn-spark-stress-interview` | Stress-tests a product concept by conducting structured interviews with synthetic personas through three adversarial lenses (Pragmatist, Skeptic, Power User). Produces an interview report with per-persona findings and synthesized themes. | 1.0.0 |
| `/arn-spark-stress-competitive` | Stress-tests a product concept through deep competitive gap analysis with feature comparison, gap identification, and positioning assessment. Produces a competitive report with a feature matrix and per-competitor analysis. | 1.0.0 |
| `/arn-spark-stress-premortem` | Applies Gary Klein's pre-mortem methodology to identify hypothetical failure root causes, early warning signals, and mitigation strategies. Produces a pre-mortem report with 3 root causes across distinct failure dimensions. | 1.0.0 |
| `/arn-spark-stress-prfaq` | Stress-tests a product concept by drafting a compelling press release and FAQ, then adversarially critiquing it to find where the concept cracks under scrutiny. Produces a PR/FAQ report with crack point analysis. | 1.0.0 |
| `/arn-spark-concept-review` | Synthesizes findings from completed stress tests into a reviewed and updated product concept. Scans for stress test reports, consolidates recommendations, resolves conflicts using product pillars, and produces an updated product-concept.md. | 1.0.0 |

## Brand & Architecture

| Command | Description | Version |
|---------|-------------|---------|
| `/arn-spark-naming` | Finds a brand name through strategic analysis, creative generation, qualitative scoring using the Six Senses framework, and due diligence including domain availability and trademark screening. | 1.0.0 |
| `/arn-spark-arch-vision` | Explores technology options and defines the high-level architecture for a greenfield project. Takes a product concept as input and produces an architecture-vision.md capturing the technology stack, system design, and known risks. | 1.0.0 |

## Behavioral Definition

| Command | Description | Version |
|---------|-------------|---------|
| `/arn-spark-use-cases` | Creates structured use case documents describing application behavior from actor perspectives. Produces a use-cases/ directory with individual Cockburn fully-dressed use case files and a README index. | 1.0.0 |
| `/arn-spark-use-cases-teams` | Creates structured use case documents through expert debate where product strategist and UX specialist review and discuss each other's findings before revising. Produces Cockburn fully-dressed use case files. | 1.0.0 |
| `/arn-spark-spike` | Validates critical technical risks from the architecture vision by creating minimal proof-of-concept code and testing whether the chosen technologies work as expected. | 1.0.0 |
| `/arn-spark-dev-setup` | Defines a standardized development environment for the project, producing dev environment infrastructure files and a dev-setup document. Also supports onboarding new developers to an existing environment standard. | 1.0.0 |

## Visual Design

| Command | Description | Version |
|---------|-------------|---------|
| `/arn-spark-visual-sketch` | Generates multiple visual direction proposals as real HTML/CSS running on the scaffolded project's dev server, iteratively selecting and refining until a final visual direction is chosen. | 1.0.0 |
| `/arn-spark-style-explore` | Explores and defines the visual design direction through guided conversation. Produces a style brief document with implementable toolkit configuration. | 1.0.0 |

## Prototyping

| Command | Description | Version |
|---------|-------------|---------|
| `/arn-spark-static-prototype` | Creates a static component showcase and validates it through iterative expert review cycles with per-criterion scoring, an independent judge verdict, and versioned output. | 1.0.0 |
| `/arn-spark-static-prototype-teams` | Creates a static component showcase validated through expert debate cycles where product strategist and UX specialist discuss their scores before producing a combined review. Supports Agent Teams for parallel debate. | 1.0.0 |
| `/arn-spark-clickable-prototype` | Generates a clickable interactive prototype with linked screens and validates it through iterative build-review cycles with Playwright-based interaction testing, per-criterion scoring, and an independent judge verdict. | 1.0.0 |
| `/arn-spark-clickable-prototype-teams` | Creates a clickable interactive prototype validated through expert debate cycles with Playwright-based interaction testing. Supports Agent Teams for parallel debate or sequential simulation as fallback. | 1.0.0 |
| `/arn-spark-prototype-lock` | Creates a frozen snapshot of the validated prototype before development begins, preventing production code from overwriting the validated reference artifact. | 1.0.0 |

## Development Bridge

| Command | Description | Version |
|---------|-------------|---------|
| `/arn-spark-scaffold` | Creates a working project skeleton from architecture decisions with installed dependencies, configured build tools, and a UI toolkit ready for development. | 1.0.0 |
| `/arn-spark-feature-extract` | Extracts a structured, prioritized feature list with journey steps, validated components, use case context, and UI behavior details from all project artifacts. Produces a feature backlog with a Feature Tracker that bridges into arn-code-feature-spec. | 3.0.0 |

## Visual Testing

| Command | Description | Version |
|---------|-------------|---------|
| `/arn-spark-visual-strategy` | Sets up visual regression testing for development -- creating capture scripts, comparison scripts, and baseline images so feature implementations are automatically compared against prototype screenshots. | 1.0.0 |
| `/arn-spark-visual-readiness` | Validates and activates deferred visual testing layers after project milestones. Evaluates whether deferred layers are ready, validates them with a spike, and promotes them to active. | 1.0.0 |

## Diagnostics

| Command | Description | Version |
|---------|-------------|---------|
| `/arn-spark-report` | Diagnose and report Arness Spark workflow issues. Invokes arn-spark-doctor agent for diagnostics, then files a GitHub issue on the Arness repository. Cross-plugin aware — detects if the issue belongs to Code or Infra. | 1.0.0 |

## Configuration

| Command | Description | Version |
|---------|-------------|---------|
| `/arn-spark-ensure-config` | Verifies that Arness Spark configuration is present for the current project. Primarily consumed as a reference by entry-point skills which read ensure-config as Step 0 before proceeding with their workflow. | 1.0.0 |
