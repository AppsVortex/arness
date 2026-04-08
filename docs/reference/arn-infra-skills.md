---
title: "Arness Infra Skills"
description: "Complete catalog of all Arness Infra skills"
sidebar:
  order: 34
---

Complete reference for all 25 Arness Infra skills. For workflow-oriented documentation, see the [Arness Infra plugin guide](../plugins/arn-infra.md).

## Entry Points

| Command | Description | Version |
|---------|-------------|---------|
| `/arn-infra-wizard` | Walks through the entire Arness infrastructure pipeline in a single continuous session with guided decision gates, invoking each pipeline skill in sequence. | 1.0.0 |
| `/arn-infra-init` | Configures providers, environments, IaC tools, and CI/CD platform for a project. Optional for basic usage -- Arness Infra auto-configures with sensible defaults on first skill invocation. | 1.0.0 |
| `/arn-infra-help` | Detects current position in the Arness Infra workflow, renders a pipeline diagram with the active stage marked, and suggests the next command. Cross-plugin aware — detects Code and Spark activity and provides hints. Read-only. | 1.1.0 |

## Interactive Skills

| Command | Description | Version |
|---------|-------------|---------|
| `/arn-infra-discover` | Audits installed infrastructure tools (MCPs, CLIs, plugins), checks authentication state, searches online for new official tools, and produces a tooling manifest. | 1.0.0 |
| `/arn-infra-containerize` | Generates production-ready Dockerfiles, docker-compose configurations, and .dockerignore files with security auditing and multi-stage build best practices. | 1.0.0 |
| `/arn-infra-define` | Generates infrastructure-as-code in the chosen IaC tool for configured cloud providers, validates through a multi-level validation ladder, and produces an architecture spec. | 1.0.0 |
| `/arn-infra-env` | Configures and manages infrastructure environments (dev, staging, production) with provider-specific isolation strategies, variable overrides, and promotion rules. | 1.0.0 |
| `/arn-infra-secrets` | Sets up, configures, and audits secrets management -- scans for exposure, recommends a secrets provider, guides setup, configures injection, and produces an audit report. | 1.0.0 |
| `/arn-infra-pipeline` | Generates infrastructure-specific CI/CD pipelines with SOC 2 alignment, OIDC authentication, and environment-aware deployment stages. Extends existing CI configurations. | 1.0.0 |
| `/arn-infra-deploy` | Executes infrastructure deployment to a target environment with promotion enforcement, cost gates, safety layers, and post-deployment resource tracking. | 1.0.0 |
| `/arn-infra-verify` | Runs post-deployment verification: health checks, DNS resolution, SSL validation, resource state comparison. Updates issue labels and environments.md with results. | 1.0.0 |

## Structured Change Management

| Command | Description | Version |
|---------|-------------|---------|
| `/arn-infra-change-spec` | Develops an infrastructure change idea into a well-formed specification through iterative conversation, capturing affected resources, blast radius, rollback requirements, and cost impact. | 1.0.0 |
| `/arn-infra-change-plan` | Generates a phased implementation plan from a change specification, structured by provisioning order, blast radius, rollback checkpoints, and environment promotion gates. | 1.0.0 |
| `/arn-infra-save-plan` | Converts a PLAN_PREVIEW into a structured project directory with per-phase plan files, tasks, report templates, and a progress tracker for execution. | 1.0.0 |
| `/arn-infra-execute-change` | Orchestrates phased execution of a structured change plan, running a 7-step dispatch loop per phase: rollback checkpoint, IaC generation, security gate, cost gate, deployment, verification, and review. | 1.0.0 |
| `/arn-infra-review-change` | Performs post-execution quality review of completed infrastructure changes across 7 categories, producing a structured review report with a PASS/WARN/NEEDS_FIXES verdict. | 1.0.0 |
| `/arn-infra-document-change` | Generates operational documentation (runbooks, architecture updates, changelogs, environment docs) from completed infrastructure changes. Final step in the change pipeline. | 1.0.0 |

## Day-2 Operations

| Command | Description | Version |
|---------|-------------|---------|
| `/arn-infra-monitor` | Sets up observability for deployed infrastructure: structured logging, metrics collection, and alerting. Recommends an observability stack based on the configured provider. | 1.0.0 |
| `/arn-infra-cleanup` | Checks for expired ephemeral infrastructure resources across TTL sources and destroys them with user confirmation. Supports periodic monitoring via `/loop`. | 1.0.0 |
| `/arn-infra-migrate` | Handles infrastructure migrations as tracked projects: PaaS-to-IaC graduation, provider-to-provider migration, provider consolidation, and partial migration. | 1.0.0 |
| `/arn-infra-refresh` | Refreshes project-local infrastructure reference files (tool versions, MCP packages, CLI commands, base image tags, IaC patterns) using online research. | 1.0.0 |
| `/arn-infra-assess` | Performs a comprehensive infrastructure assessment of the application, producing a prioritized infrastructure backlog published as issues. Also handles un-deferring. | 1.0.0 |

## Triage

| Command | Description | Version |
|---------|-------------|---------|
| `/arn-infra-triage` | Processes incoming infrastructure request issues, analyzes infrastructure implications from referenced application artifacts, and produces a structured implications brief. | 1.0.0 |

## Diagnostics

| Command | Description | Version |
|---------|-------------|---------|
| `/arn-infra-report` | Diagnose and report Arness Infra workflow issues. Invokes arn-infra-doctor agent for diagnostics, then files a GitHub issue on the Arness repository. Cross-plugin aware — detects if the issue belongs to Code or Spark. | 1.0.0 |

## Configuration

| Command | Description | Version |
|---------|-------------|---------|
| `/arn-infra-ensure-config` | Verifies and establishes Arness Infra configuration for the current project. Runs automatically as Step 0 of entry-point skills; can also be invoked directly. | 1.0.0 |
