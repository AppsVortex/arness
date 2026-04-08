---
title: "Arness Spark Agents"
description: "Complete catalog of all Arness Spark agents"
sidebar:
  order: 31
---

Complete reference for all 20 Arness Spark agents. Agents are specialist AI workers invoked by skills -- you don't call them directly. For workflow context, see the [Arness Spark plugin guide](../plugins/arn-spark.md).

## Discovery & Product

| Agent | Purpose | Tools | Model |
|-------|---------|-------|-------|
| arn-spark-product-strategist | Probes product ideas, challenges assumptions, and structures raw concepts into a coherent product vision. Used during discovery to sharpen vague ideas and identify scope boundaries. | Read, Glob, Grep, Write | opus |
| arn-spark-persona-architect | Generates rich, realistic target user personas for a product concept. Expands user-provided seeds or creates new personas with distinct motivations and adoption postures. Can instantiate fresh persona instances from existing moulds. | WebSearch | opus |
| arn-spark-market-researcher | Conducts competitive landscape research to identify alternatives in a product's problem space. Validates competitor capabilities with web-grounded evidence and produces tiered competitor lists. | Read, WebSearch, WebFetch | opus |
| arn-spark-brand-strategist | Analyzes brand DNA, generates name candidates across naming categories, scores them using the Six Senses framework, and conducts linguistic screening for brand names. | Read, Glob, Grep, WebSearch | opus |

## Technology & Architecture

| Agent | Purpose | Tools | Model |
|-------|---------|-------|-------|
| arn-spark-tech-evaluator | Evaluates candidate technologies, produces comparison matrices, and recommends a stack with rationale for greenfield projects. | Read, Glob, Grep, WebSearch | opus |
| arn-spark-scaffolder | Creates a working project skeleton from architecture decisions, installing dependencies, configuring build tools, and producing a minimal running application. | Read, Glob, Grep, Edit, Write, Bash, LSP | opus |
| arn-spark-dev-env-builder | Creates development environment infrastructure files: dev containers, Docker configurations, setup scripts, CI workflows, toolchain pins, and onboarding documentation. | Read, Glob, Grep, Edit, Write, Bash, LSP | opus |
| arn-spark-spike-runner | Validates specific technical risks by creating minimal proof-of-concept code, running it, and reporting whether the risk is validated, partially validated, or failed. | Read, Glob, Grep, Edit, Write, Bash, LSP | opus |

## Design & Prototyping

| Agent | Purpose | Tools | Model |
|-------|---------|-------|-------|
| arn-spark-visual-sketcher | Creates visual direction proposals inside the project's route structure. Builds page components with CSS-variable-isolated layouts using the project's actual CSS framework and component library. | Read, Glob, Grep, Edit, Write, Bash, LSP | opus |
| arn-spark-ux-specialist | Provides UI/UX design guidance for prototype validation, style exploration, and component design. Specializes in visual style direction, prototype review scoring, and user experience flows. | Read, Glob, Grep, LSP, WebSearch, Write | opus |
| arn-spark-prototype-builder | Creates clickable static screen prototypes with navigation, static component showcase pages for visual validation, and sample screens for style evaluation using the project's UI framework. | Read, Glob, Grep, Edit, Write, Bash, LSP | opus |
| arn-spark-style-capture | Captures screenshots of URLs and extracts visual design characteristics (colors, typography, layout, spacing) from websites, web applications, or locally served prototypes. | Read, Glob, Bash, Write | opus |
| arn-spark-ux-judge | Delivers strict, evidence-based scoring of prototype artifacts with PASS/FAIL verdicts. Operates in static mode (evaluates screenshots) or interactive mode (navigates the prototype via Playwright). | Read, Glob, Grep, Write, Bash | opus |

## Behavioral & Analysis

| Agent | Purpose | Tools | Model |
|-------|---------|-------|-------|
| arn-spark-use-case-writer | Drafts, revises, and finalizes structured use case documents in Cockburn fully-dressed format. Transforms product vision and expert review feedback into implementation-ready use cases. | Read, Glob, Grep, Write | opus |
| arn-spark-ui-interactor | Simulates user journeys through interactive prototypes by writing and executing Playwright scripts. Clicks buttons, fills forms, navigates screens, and captures screenshots at every state change. | Read, Glob, Grep, Write, Bash | opus |

## Validation & Stress Testing

| Agent | Purpose | Tools | Model |
|-------|---------|-------|-------|
| arn-spark-persona-impersonator | Role-plays synthetic personas during structured user interviews. Receives a persona profile and an adversarial casting overlay (Pragmatist, Skeptic, or Power User), then responds in-character to interview questions. | Read | opus |
| arn-spark-forensic-investigator | Investigates hypothetical product failure using Gary Klein's pre-mortem methodology. Works backward from the premise that the product already launched and failed to identify root causes, early warning signals, and mitigations. | Read, Glob, Grep, WebSearch | opus |
| arn-spark-marketing-pm | Drafts press releases and FAQs for product concepts (draft mode) or adversarially critiques them to find where the concept cracks under scrutiny (critique mode). Draft and critique are always separate invocations. | Read, WebSearch | opus |

## Infrastructure & Testing

| Agent | Purpose | Tools | Model |
|-------|---------|-------|-------|
| arn-spark-visual-test-engineer | Investigates, designs, and validates visual testing infrastructure. Creates capture scripts, cross-environment pipelines, and test runner configurations, validating approaches by running proof-of-concept captures. | Read, Glob, Grep, Edit, Write, Bash, LSP | opus |

## Diagnostics

| Agent | Purpose | Tools | Model |
|-------|---------|-------|-------|
| arn-spark-doctor | Diagnoses Arness Spark workflow issues. Analyzes greenfield configuration, directory structure, and skill behavior against expected patterns in the Spark knowledge base. Reports only Spark-specific issues — never reads user project code or business logic. | Read, Glob, Grep, Bash | opus |
