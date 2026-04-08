# Changelog Template

Infrastructure changelog entry template for structured change records. Each entry provides a complete audit trail of an infrastructure change, from specification through execution and review.

---

## Template Structure

Each changelog entry follows this format. Entries are prepended to `CHANGELOG.md` in reverse chronological order (newest first).

```markdown
## [Date] -- [Change ID]

### Summary
[One-line description of the infrastructure change]

### Resources Affected
| Provider | Created | Modified | Destroyed | Total |
|----------|---------|----------|-----------|-------|
| [provider] | [N] | [N] | [N] | [N] |
| ... | ... | ... | ... | ... |
| **Total** | **[N]** | **[N]** | **[N]** | **[N]** |

### Environments
| Environment | Phase | Status | Deployed At |
|-------------|-------|--------|-------------|
| [env name] | [N] | [completed/failed/rolled_back] | [ISO 8601] |
| ... | ... | ... | ... |

**Promotion order:** [env1] --> [env2] --> [env3]

### Blast Radius
**Classification:** [none / contained / broad / critical]
**Justification:** [Brief explanation of the classification]

### Cost Impact
| Metric | Value |
|--------|-------|
| Monthly delta | [+$X/month or -$X/month] |
| One-time costs | [$Y] |
| Total estimated monthly cost after change | [$Z/month] |
| Budget threshold | [$W/month] |
| Budget utilization | [N%] |

### Security Impact
| Finding Type | Count | Status |
|-------------|-------|--------|
| CRITICAL resolved | [N] | [all resolved before deployment] |
| HIGH resolved | [N] | [resolved or acknowledged] |
| HIGH acknowledged | [N] | [accepted with documented risk] |
| Warnings | [N] | [logged] |

**Security gate decisions:** [Summary of any acknowledged HIGH findings with rationale]

### Rollback Reference
- **Runbook:** [path to runbook-<project-name>.md]
- **Rollback section:** [Section 5: Rollback Procedure]
- **Checkpoint locations:** [list of checkpoint paths in reports/]
- **Point-of-no-return:** [phases or steps that cannot be reversed, or "none"]

### Related Spec and Plan
- **Change spec:** [path to INFRA_CHANGE_*.md]
- **Structured plan:** [path to project directory]
- **SOURCE_PLAN.md:** [path]
- **INTRODUCTION.md:** [path]

### Review Verdict
**Verdict:** [PASS / WARN / NEEDS_FIXES]
**Review report:** [path to INFRA_REVIEW_REPORT.json]

**Findings summary:**
- Errors: [N]
- Warnings: [N]
- Informational: [N]

[If WARN or NEEDS_FIXES: brief summary of key findings]

---
```

## Field Descriptions

### 1. Date and Change ID
- **Date:** ISO 8601 date of the change completion (last phase deployed)
- **Change ID:** Derived from the spec filename: `INFRA_CHANGE_<name>` becomes the Change ID. This provides a unique, traceable identifier for the change.

### 2. Summary
- One-line description extracted from the change spec's description field or the INTRODUCTION.md Change Overview.
- Should answer: "What changed and why?" in one sentence.

### 3. Resources Affected
- Aggregated counts per provider across all phases.
- Created: new resources provisioned for the first time.
- Modified: existing resources whose configuration changed.
- Destroyed: resources removed during this change.

### 4. Environments
- Lists every environment that received changes, the phase that deployed to it, the deployment status, and timestamp.
- Promotion order shows the sequence environments were deployed in.

### 5. Blast Radius
- The highest blast radius classification across all phases.
- If Phase 1 was "contained" and Phase 3 was "broad", the changelog reports "broad".
- Justification explains why the highest classification was assigned.

### 6. Cost Impact
- Monthly delta is the net change in monthly infrastructure cost (positive for increases, negative for decreases).
- One-time costs include data transfer fees, setup charges, migration costs.
- Total estimated monthly cost is the projected monthly bill after all changes.
- Budget utilization compares the total against the configured cost threshold.

### 7. Security Impact
- Aggregated security gate findings across all phases.
- CRITICAL findings must be resolved -- they should always show as "resolved".
- HIGH findings may be acknowledged (bypassed with documented risk).
- This section provides an audit trail of security decisions.

### 8. Rollback Reference
- Points to the runbook section with rollback procedures.
- Lists checkpoint locations for each phase (state snapshots, resource manifests).
- Identifies any point-of-no-return steps so operators know the limits of rollback.

### 9. Related Spec and Plan
- Links to all source artifacts for full traceability.
- Enables auditors to trace from the changelog entry back to the original request.

### 10. Review Verdict
- The overall verdict from `arn-infra-review-change`.
- If the review has not been run, note: "Not reviewed -- run `/arn-infra-review-change`"
- Key findings are summarized for quick reference.

---

## Changelog File Convention

The changelog file is `CHANGELOG.md` in the **Infra docs directory**. It follows the "newest first" convention:

```markdown
# Infrastructure Changelog

## 2026-03-14 -- INFRA_CHANGE_multi-region-migration
[latest entry]

---

## 2026-03-10 -- INFRA_CHANGE_database-upgrade
[previous entry]

---

## 2026-03-01 -- INFRA_CHANGE_initial-setup
[oldest entry]
```

### Deduplication

Before prepending a new entry, check if an entry with the same Change ID already exists. If it does, replace the existing entry (the change was re-executed or re-reviewed). This prevents duplicate entries from re-running `arn-infra-document-change`.
