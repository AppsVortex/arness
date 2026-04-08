# Infrastructure Plan Templates

Templates for generating structured infrastructure change project artifacts. These templates are infrastructure-specific alternatives to Arness Core's application-oriented templates, designed for phased infrastructure provisioning with blast radius management, environment promotion, and compliance gates.

---

## INTRODUCTION.md Template

The INTRODUCTION.md is the root document of a structured infrastructure change project. It provides the complete context for the change, from motivation through execution constraints.

### Template Structure

```markdown
# [Project Name]

## Change Overview

**Project Name:** [project-name]
**Description:** [One-paragraph description of what is changing and why]
**Rationale:** [Business or technical justification for the change]
**Change Spec:** [Path to the INFRA_CHANGE_*.md specification]
**Created:** [ISO 8601 date]

---

## Infrastructure Context

| Field | Value |
|-------|-------|
| Providers | [Comma-separated list of cloud providers] |
| IaC Tool | [Primary IaC tool] |
| Environments | [Comma-separated environment list in promotion order] |
| Current State | [Brief: greenfield / brownfield / migration] |

---

## Current State

[Description of the existing infrastructure state before this change. Include:]
- Existing resources and their environments
- Current deployment method
- Known issues or technical debt being addressed
- Relevant resource IDs or names

---

## Target State

[Description of the desired infrastructure state after all phases complete. Include:]
- New resources to be provisioned
- Modified resources and what changes
- Resources to be decommissioned
- Architecture diagram (text-based)

---

## Blast Radius Summary

| Phase | Environment | Classification | Justification |
|-------|-------------|---------------|---------------|
| 1     | [env]       | none / contained / broad / critical | [brief reason] |
| 2     | [env]       | none / contained / broad / critical | [brief reason] |
| ...   | ...         | ...           | ...           |

**Classifications:**
- **none** -- No impact on existing resources (new resources only)
- **contained** -- Impact limited to a single service or resource group
- **broad** -- Impact spans multiple services within one environment
- **critical** -- Impact crosses environments or affects shared infrastructure

---

## Rollback Strategy

**Checkpoint locations:**
- [Per-phase checkpoint path or description]

**Rollback procedures:**
- [High-level rollback approach per phase]

**Point of no return:**
- [Identify any phases that cannot be rolled back, e.g., data migrations]

---

## Environment Promotion Pipeline

[env1] --> [env2] --> [env3]

**Promotion gates:**
- [env1] to [env2]: [gate conditions -- e.g., all health checks pass, security scan clear]
- [env2] to [env3]: [gate conditions -- e.g., manual approval, 24h soak period]

---

## Cost Budget

| Phase | Environment | Estimated Monthly Delta | One-Time Costs |
|-------|-------------|------------------------|----------------|
| 1     | [env]       | +$X/month              | $Y             |
| 2     | [env]       | +$X/month              | $Y             |
| ...   | ...         | ...                    | ...            |

**Total estimated monthly increase:** $X/month
**Total one-time costs:** $Y
**Budget threshold:** $Z/month (from ## Arness config)

---

## Security Requirements

- **Compliance frameworks:** [SOC 2, HIPAA, PCI-DSS, or N/A]
- **Access controls:** [IAM policies, RBAC, service accounts required]
- **Encryption:** [At-rest and in-transit encryption requirements]
- **Network security:** [VPC, security groups, firewall rules]
- **Secret management:** [Where secrets are stored, rotation policy]

---

## Phase Overview

| Phase | Title | Dependencies |
|-------|-------|--------------|
| 1     | [title] | None |
| 2     | [title] | Phase 1 |
| ...   | ...     | ...    |

---

## Metadata

- **Created:** [ISO 8601 date]
- **Source plan:** SOURCE_PLAN.md
- **Change spec:** [path to INFRA_CHANGE_*.md]
```

---

## PHASE_N_PLAN.md Template

Each phase plan covers a single deployment unit -- typically one environment or one logical group of resources. Phases execute sequentially across environments.

### Template Structure

```markdown
# Phase [N]: [Phase Title]

**Project:** [project-name]
**Phase:** [N] of [total]
**Prerequisites:** [Phase dependencies or "None"]

---

## Phase Overview

[One-paragraph description of what this phase accomplishes]

---

## Target Environment

**Environment:** [environment name]
**Provider(s):** [provider(s) involved]
**Region(s):** [deployment region(s)]

---

## Resources

| Resource | Type | Provider | Action | Details |
|----------|------|----------|--------|---------|
| [name]   | [compute/database/storage/...] | [provider] | create / modify / destroy | [brief description] |
| ...      | ...  | ...      | ...    | ...     |

**Summary:** [N] create, [N] modify, [N] destroy

---

## Blast Radius

**Classification:** none / contained / broad / critical
**Justification:** [Why this classification applies to this phase]
**Affected services:** [List of services impacted]

---

## Rollback Checkpoint

**Before execution, snapshot:**
- [State files to backup]
- [Resource manifests to capture]
- [Configuration snapshots]

**Restore procedure:**
1. [Step-by-step rollback for this phase]
2. [...]

**Estimated rollback duration:** [time estimate]

---

## Security Requirements

- [Phase-specific security requirements]
- [IAM changes needed]
- [Network rule changes]
- [Encryption configuration]

---

## Cost Estimate

**Monthly delta:** +$X/month (or -$X/month for cost reduction)
**One-time costs:** $Y
**Cumulative monthly cost after this phase:** $Z/month

---

## Dependencies

- [Other phases this depends on]
- [External dependencies -- DNS propagation, certificate issuance, etc.]
- [Team dependencies -- approvals, access grants]

---

## Tasks

- [ ] TASK-PN-001: [task description]
- [ ] TASK-PN-002: [task description]
- [ ] ...

---

## Acceptance Criteria

- [ ] [criterion 1]
- [ ] [criterion 2]
- [ ] ...
```

---

## Usage Notes

- The INTRODUCTION.md template is populated once by `arn-infra-save-plan` and updated by `arn-infra-document-change` after execution completes.
- PHASE_N_PLAN.md files are consumed by `arn-infra-execute-change` which reads the Resources, Blast Radius, and Tasks sections to drive execution.
- All monetary values use USD by default. Convert to the user's configured currency if specified in the change spec.
- Blast radius classifications drive gate strictness in `arn-infra-execute-change`: critical phases require explicit user approval at each gate.
