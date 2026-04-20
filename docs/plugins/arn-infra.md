---
title: "Arness Infra"
description: "Infrastructure and deployment — containerize, define IaC, deploy, and monitor your applications"
sidebar:
  order: 12
---

![Arness Infra](../../assets/infra.png)

[![Docs](https://img.shields.io/badge/docs-arness.appsvortex.com-7e3ff2?logo=astro&logoColor=white)](https://arness.appsvortex.com/)

Arness Infra aims to help with containerization, IaC generation, deployment, and monitoring. It audits your existing toolchain, generates infrastructure tailored to your stack, and provides a structured change management pipeline for complex infrastructure work.

> **Experimental — use with care.** Infrastructure is high-stakes by nature. Arness Infra is functional and actively evolving, but it is the newest and least battle-tested of the three plugins. Always review generated configurations, IaC, and deployment commands before applying them to real environments. We strongly recommend testing in non-production environments first. Feedback is very welcome — [open an issue](https://github.com/AppsVortex/arness/issues) or contribute directly.

## Start Here

| Command | What it does |
|---------|-------------|
| `/arn-infra-wizard` | Guided walk-through of the full infrastructure pipeline |
| `/arn-infra-init` | *(Optional)* Configure providers, environments, and IaC tools |
| `/arn-infra-help` | See where you are in the pipeline (cross-plugin aware — hints about Code and Spark) |

## Pipeline Overview

```mermaid
flowchart LR
    A[Discover] --> B[Containerize] --> C[Define] --> D[Env]
    D --> E[Secrets] --> F[Pipeline] --> G[Deploy]
    G --> H[Verify] --> I[Monitor] --> J[Document]

    style A fill:#1a0a2e,stroke:#00CED1,color:#00CED1
    style B fill:#1a0a2e,stroke:#00CED1,color:#00CED1
    style C fill:#1a0a2e,stroke:#00CED1,color:#00CED1
    style D fill:#1a0a2e,stroke:#00CED1,color:#00CED1
    style E fill:#1a0a2e,stroke:#00CED1,color:#00CED1
    style F fill:#1a0a2e,stroke:#00CED1,color:#00CED1
    style G fill:#1a0a2e,stroke:#00CED1,color:#00CED1
    style H fill:#1a0a2e,stroke:#00CED1,color:#00CED1
    style I fill:#1a0a2e,stroke:#00CED1,color:#00CED1
    style J fill:#1a0a2e,stroke:#00CED1,color:#00CED1
```

This is the core infrastructure pipeline. Each stage can be run independently or as part of the wizard's guided flow.

Infra also has a separate **structured change management pipeline** for complex changes that require phased execution, rollback checkpoints, security gates, and cost gates. See [Workflow 3](#structured-change-management) below.

## Guided Setup (The Wizard)

`/arn-infra-wizard` walks through the entire pipeline in a single session. It presents decision gates at each stage, letting you skip what you don't need and dive deep where you do.

Before the wizard generates anything, `/arn-infra-discover` audits your installed tools -- MCPs, CLIs, plugins -- checks authentication state, and recommends any missing tool installations. It produces a tooling manifest that the rest of the pipeline uses to tailor its output.

Infra attempts to be **expertise-adaptive**. If you're new to infrastructure, it leans toward platform-native configurations with more explanation. If you're experienced, it offers full IaC with advanced patterns. The wizard infers your level from your answers and adjusts accordingly — though you should always validate the output matches your expectations.

## Containerize and Deploy

These interactive skills can be used independently or within the wizard. Each one handles a specific stage of the infrastructure pipeline.

**`/arn-infra-containerize`** generates Dockerfiles, docker-compose configurations, and .dockerignore files. Builds use multi-stage patterns by default. Review generated configurations before use in production.

**`/arn-infra-define`** generates Infrastructure as Code in your chosen tool -- OpenTofu, Terraform, Pulumi, CDK, Bicep, or kubectl/Helm. Output is expertise-adaptive: beginners get well-commented, straightforward configurations; experts get modular, reusable patterns.

**`/arn-infra-env`** configures dev, staging, and production environments with isolation strategies, resource sizing, and promotion rules between environments.

**`/arn-infra-secrets`** sets up, audits, or rotates secrets management for your stack. It scans for accidental exposure in code, environment variables, and configuration files.

**`/arn-infra-pipeline`** generates CI/CD pipelines for GitHub Actions, GitLab CI, or Bitbucket Pipelines. Pipelines include environment promotion and testing gates. Audit trail patterns are included but should be reviewed against your organization's actual compliance requirements.

**`/arn-infra-deploy`** executes deployment with environment promotion enforcement, cost gates, and safety layers. It is designed to enforce staging and approval rules you've configured, though you should verify these guardrails work as expected in your environment before relying on them.

**`/arn-infra-verify`** runs post-deployment health checks: endpoint reachability, DNS resolution, SSL certificate validity, and cloud resource state verification.

## Structured Change Management

For complex infrastructure changes -- multi-service migrations, provider switches, major architecture shifts -- Infra provides a full change management pipeline that mirrors the rigor of Code's development pipeline.

**`/arn-infra-change-spec`** develops an infrastructure change specification through guided conversation. You describe what needs to change, and it produces a structured spec covering scope, affected resources, risk assessment, and success criteria.

**`/arn-infra-change-plan`** takes the spec and generates a phased execution plan structured by provisioning order, blast radius, and rollback checkpoints. Each phase is scoped to minimize risk.

**`/arn-infra-save-plan`** structures the plan into an executable project with tracked phases, dependencies, and gate criteria.

**`/arn-infra-execute-change`** runs phased execution with a 7-step dispatch per phase:

1. Rollback checkpoint
2. IaC generation
3. Security gate
4. Cost gate
5. Deployment
6. Verification
7. Review gate

Each phase is designed to pass all gates before the next one begins. Security gates use the **security-auditor agent** with Checkov, Trivy, and TruffleHog integration. Cost gates use the **cost-analyst agent** with Infracost integration. Both gates can flag issues and recommend blocking execution when thresholds are exceeded — but as with all generated infrastructure, human review of gate results is essential.

**`/arn-infra-review-change`** performs post-execution quality review across 7 categories: security posture, cost impact, blast radius containment, rollback readiness, environment parity, state consistency, and resource tagging compliance.

**`/arn-infra-document-change`** generates runbooks, architecture diagram updates, operational playbooks, and changelog entries for the completed change.

## Day-2 Operations

Infrastructure doesn't end at deployment. These skills handle ongoing operations.

**`/arn-infra-monitor`** sets up logging, metrics, and alerting. It recommends an observability stack based on your provider and existing tooling.

**`/arn-infra-cleanup`** checks for expired ephemeral resources and destroys them with confirmation. Supports periodic monitoring via `/loop` for ongoing hygiene.

**`/arn-infra-migrate`** handles infrastructure migrations: PaaS-to-IaC graduation, provider-to-provider moves, provider consolidation, and partial migrations where only some services move.

**`/arn-infra-refresh`** updates 28 evolving reference files that Infra uses internally -- tool versions, MCP packages, CLI commands, base image tags, and IaC patterns. Run periodically to keep recommendations current.

**`/arn-infra-triage`** processes incoming infrastructure request issues, bridging application features to infrastructure changes.

**`/arn-infra-assess`** runs a comprehensive infrastructure needs analysis and produces a prioritized backlog of recommended improvements.

## All Skills

### Entry Points

| Command | What it does |
|---------|-------------|
| `/arn-infra-wizard` | Guided walk-through of the full infrastructure pipeline |
| `/arn-infra-init` | *(Optional)* Configure providers, environments, and IaC tools |
| `/arn-infra-help` | See where you are in the pipeline (cross-plugin aware — hints about Code and Spark) |

### Interactive Skills

| Command | What it does |
|---------|-------------|
| `/arn-infra-discover` | Audit installed tools, check auth, produce tooling manifest |
| `/arn-infra-containerize` | Generate production-ready Dockerfiles and docker-compose |
| `/arn-infra-define` | Generate IaC in your chosen tool and language |
| `/arn-infra-env` | Configure dev/staging/production environments |
| `/arn-infra-secrets` | Set up, audit, or rotate secrets management |
| `/arn-infra-pipeline` | Generate CI/CD pipelines with audit trail patterns |
| `/arn-infra-deploy` | Execute deployment with promotion enforcement and safety layers |
| `/arn-infra-verify` | Post-deployment health checks: endpoints, DNS, SSL, resources |

### Change Management

| Command | What it does |
|---------|-------------|
| `/arn-infra-change-spec` | Develop an infrastructure change specification |
| `/arn-infra-change-plan` | Generate a phased plan with rollback checkpoints |
| `/arn-infra-save-plan` | Structure the plan into an executable project |
| `/arn-infra-execute-change` | Phased execution with 7-step dispatch per phase |
| `/arn-infra-review-change` | Post-execution quality review across 7 categories |
| `/arn-infra-document-change` | Generate runbooks, playbooks, and changelog entries |

### Day-2 Operations

| Command | What it does |
|---------|-------------|
| `/arn-infra-monitor` | Set up logging, metrics, and alerting |
| `/arn-infra-cleanup` | Find and destroy expired ephemeral resources |
| `/arn-infra-migrate` | PaaS-to-IaC, provider-to-provider, and consolidation migrations |
| `/arn-infra-refresh` | Update 28 evolving reference files |
| `/arn-infra-triage` | Process infrastructure request issues |
| `/arn-infra-assess` | Comprehensive infrastructure needs analysis |

### Diagnostics

| Command | What it does |
|---------|-------------|
| `/arn-infra-report` | Diagnose and report Arness Infra workflow issues (cross-plugin routing) |

### Configuration

| Command | What it does |
|---------|-------------|
| `/arn-infra-ensure-config` | Verify and repair Arness Infra configuration |

For detailed skill documentation, see the [Arness Infra skills reference](../reference/arn-infra-skills.md).

## Agents at Work

Arness Infra includes 10 specialist agents that handle focused tasks within the pipeline. The **infrastructure specialist** is the primary workhorse, generating all IaC code, Dockerfiles, and configuration. The **security auditor** integrates with Checkov, Trivy, and TruffleHog to gate deployments on security compliance. The **cost analyst** uses Infracost to enforce cost thresholds before infrastructure is provisioned.

The remaining agents handle specific pipeline stages: the **change planner** structures phased execution plans, the **change reviewer** evaluates completed changes across quality categories, the **verifier** runs post-deployment health checks, the **pipeline builder** generates CI/CD configurations, the **request analyzer** triages incoming infrastructure issues, and the **reference researcher** keeps evolving reference files current.

For detailed agent documentation, see the [Arness Infra agents reference](../reference/arn-infra-agents.md).

## Key Characteristics

- **Provider-agnostic**: targets AWS, GCP, Azure, Fly.io, Railway, Vercel, Netlify, DigitalOcean, and others — coverage varies by provider
- **IaC tool-agnostic**: supports OpenTofu, Terraform, Pulumi, CDK, Bicep, Kubernetes/Helm — depth varies by tool
- **Expertise-adaptive**: attempts to adjust tone and recommendations to your experience level
- **28 evolving reference files** kept current via `/arn-infra-refresh`

## Cross-Plugin Integration

Arness Infra works alongside Arness Code for feature-to-infrastructure workflows. When a Code feature requires infrastructure changes -- a new service, a database, a queue -- `/arn-infra-triage` bridges the application feature into an infrastructure change specification that feeds into the change management pipeline.

Infra can also operate fully standalone for teams that only need infrastructure tooling, without installing Arness Code or Arness Spark.
