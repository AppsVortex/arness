---
title: "Arness Infra Agents"
description: "Complete catalog of all Arness Infra agents"
sidebar:
  order: 35
---

Complete reference for all 10 Arness Infra agents. Agents are specialist AI workers invoked by skills -- you don't call them directly. For workflow context, see the [Arness Infra plugin guide](../plugins/arn-infra.md).

## Core Infrastructure

| Agent | Purpose | Tools | Model |
|-------|---------|-------|-------|
| arn-infra-specialist | Primary workhorse for generating infrastructure-as-code, Dockerfiles, deployment scripts, and cloud resource definitions. Adapts to the user's IaC tool and cloud providers. | Read, Glob, Grep, Bash, WebSearch | opus |

## Security & Cost

| Agent | Purpose | Tools | Model |
|-------|---------|-------|-------|
| arn-infra-security-auditor | Scans generated IaC, container configurations, and cloud resource definitions for misconfigurations, secrets exposure, OWASP cloud risks, and overly permissive IAM policies. Integrates with Checkov, Trivy, TruffleHog, and Gitleaks. | Read, Glob, Grep, Bash, WebSearch | opus |
| arn-infra-cost-analyst | Estimates cost impact of infrastructure changes before deployment and enforces spend thresholds. Integrates with Infracost when available and provides usage-based pricing estimates. | Read, Glob, Grep, Bash, WebSearch | opus |

## Change Management

| Agent | Purpose | Tools | Model |
|-------|---------|-------|-------|
| arn-infra-change-planner | Generates phased infrastructure implementation plans from change specifications, reasoning about provisioning dependencies, blast radius, rollback checkpoints, and environment promotion strategy. | Read, Glob, Grep, Write, Edit | opus |
| arn-infra-change-reviewer | Evaluates completed infrastructure changes across security posture, cost compliance, blast radius adherence, rollback documentation, environment parity, state consistency, and resource tagging. | Read, Glob, Grep, Bash | opus |

## Deployment & Verification

| Agent | Purpose | Tools | Model |
|-------|---------|-------|-------|
| arn-infra-verifier | Performs post-deployment verification: health checks, endpoint reachability, DNS resolution, SSL validation, and resource state matching. Recommends rollback when checks fail. | Read, Glob, Grep, Bash, WebSearch | opus |
| arn-infra-pipeline-builder | Generates and extends CI/CD pipeline configurations (GitHub Actions, GitLab CI, etc.) for infrastructure deployment. Detects existing CI setups and extends rather than replaces them. | Read, Glob, Grep, Bash, WebSearch | opus |

## Analysis & Research

| Agent | Purpose | Tools | Model |
|-------|---------|-------|-------|
| arn-infra-request-analyzer | Cross-project analyst that reads application artifacts (feature specs, plans, source code) and extracts infrastructure implications. Bridges application features and infrastructure changes. | Read, Glob, Grep, Bash | opus |
| arn-infra-reference-researcher | Researches online for the latest versions of infrastructure tools, MCP servers, CLI tools, base images, and IaC patterns. Compares against current reference files and produces structured update reports. | Read, Glob, Grep, WebSearch, WebFetch | opus |

## Diagnostics

| Agent | Purpose | Tools | Model |
|-------|---------|-------|-------|
| arn-infra-doctor | Diagnoses Arness Infra workflow issues. Analyzes infrastructure configuration, directory structure, and skill behavior against expected patterns in the Infra knowledge base. Reports only Infra-specific issues — never reads user project code or business logic. | Read, Glob, Grep, Bash | opus |
