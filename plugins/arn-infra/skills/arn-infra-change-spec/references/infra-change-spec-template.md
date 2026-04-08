# Infrastructure Change Specification Template

Template for `INFRA_CHANGE_*.md` specification files produced by the `arn-infra-change-spec` skill. Each section captures a specific aspect of the infrastructure change to enable structured planning, execution, and review.

---

## Template

```markdown
# Infrastructure Change: [Change Name]

**Created:** [ISO 8601 date]
**Author:** [user or skill]
**Status:** Draft | Approved | In Progress | Completed
**Entry path:** Fresh | Upgrade from interactive

---

## 1. Change Overview

### What is changing
[Clear description of the infrastructure change -- what resources are being created, modified, or destroyed and in which environments.]

### Why
**Business driver:** [Business reason for the change -- e.g., "New authentication feature requires a managed database."]
**Technical motivation:** [Technical reason -- e.g., "Self-managed PostgreSQL on EC2 has unacceptable maintenance overhead."]

---

## 2. Affected Resources

| Resource | Type | Provider | Action | Environment | Notes |
|----------|------|----------|--------|-------------|-------|
| [name] | [e.g., RDS Instance] | [e.g., AWS] | Create | [e.g., dev, staging, prod] | [any notes] |
| [name] | [e.g., Security Group] | [e.g., AWS] | Modify | [e.g., dev, staging, prod] | [what is changing] |
| [name] | [e.g., EC2 Instance] | [e.g., AWS] | Destroy | [e.g., dev, staging, prod] | [replacement info] |

**Total resources:** [N] create, [N] modify, [N] destroy

---

## 3. Blast Radius Assessment

| Environment | Classification | Justification |
|-------------|---------------|---------------|
| [dev] | None / Contained / Broad / Critical | [why this classification] |
| [staging] | None / Contained / Broad / Critical | [why this classification] |
| [production] | None / Contained / Broad / Critical | [why this classification] |

**Affected dependencies:**
- [List services, applications, or infrastructure components that depend on the affected resources]

**Risk analysis:**
- [Specific risks identified for this change]
- [What could go wrong and what the impact would be]

---

## 4. Rollback Requirements

**Rollback strategy:** [e.g., Blue-green cutover, IaC state revert, manual restore from snapshot]

**Data preservation:**
- [What data needs to be preserved during rollback -- e.g., database contents, object storage, configuration state]
- [Whether data migration is involved and its reversibility]

**Point of no return:**
- [Identify the specific step after which rollback becomes significantly more complex or impossible]
- [e.g., "After the database migration runs destructive schema changes in production, rollback requires restoring from the pre-migration snapshot."]

**Estimated rollback time:** [e.g., "15 minutes for IaC revert, 45 minutes if database restore is needed"]

---

## 5. Environment Scope

**Affected environments:** [List of environments this change targets]

**Promotion order:**
1. [First environment -- e.g., dev]
2. [Second environment -- e.g., staging]
3. [Third environment -- e.g., production]

**Gates between environments:**
| Gate | From | To | Type | Criteria |
|------|------|----|------|----------|
| [gate name] | [env] | [env] | Manual approval / Automated check | [what must pass] |

---

## 6. Compliance Constraints

**Regulatory requirements:**
- [e.g., "Data must remain in eu-west-1 region per GDPR data residency requirements"]
- [e.g., "PCI DSS requires encryption at rest for all payment-related databases"]

**Security policies:**
- [e.g., "All new security group rules must be reviewed by the security team"]
- [e.g., "IAM roles must follow least-privilege principle"]

**Tagging requirements:**
- [e.g., "All resources must include: environment, team, cost-center, managed-by tags"]

**Approval workflows:**
- [e.g., "Production changes require sign-off from the infrastructure lead"]
- [e.g., "Changes exceeding $500/month require finance approval"]

---

## 7. Cost Impact

**Estimated monthly cost delta:** [e.g., "+$150/month" or "-$50/month"]
**One-time provisioning costs:** [e.g., "$0" or "$200 for data migration compute"]
**Cost comparison:**

| Item | Current Monthly | Projected Monthly | Delta |
|------|----------------|-------------------|-------|
| [resource/service] | $[amount] | $[amount] | +/-$[amount] |

**Cost threshold status:** [Within threshold / Exceeds threshold ($X configured)]

---

## 8. Dependencies

**Infrastructure dependencies:**
- [Other infrastructure changes that must happen first or in coordination]

**Application dependencies:**
- [Application changes that depend on or are depended upon by this infrastructure change]

**Blocking dependencies:**
- [Changes that MUST be completed before this change can proceed]

**Non-blocking dependencies:**
- [Changes that are related but do not block execution]

---

## 9. Acceptance Criteria

- [ ] [Measurable criterion -- e.g., "Health check endpoint returns 200 on the new database-backed service"]
- [ ] [Performance criterion -- e.g., "Database query latency < 50ms at p99"]
- [ ] [Security criterion -- e.g., "All connections use TLS 1.2+"]
- [ ] [Cost criterion -- e.g., "Monthly cost increase does not exceed $200"]
- [ ] [Operational criterion -- e.g., "Automated backups are configured with 7-day retention"]
```

---

## Section Authoring Notes

| Section | Required | Source |
|---------|----------|--------|
| Change Overview | Yes | User conversation + initial analysis |
| Affected Resources | Yes | IaC artifact analysis or user input |
| Blast Radius Assessment | Yes | blast-radius-guide.md classifications |
| Rollback Requirements | Yes | Determined by resource types and operations |
| Environment Scope | Yes | ## Arness Environments config |
| Compliance Constraints | No | User input -- omit section if none apply |
| Cost Impact | Yes | arn-infra-cost-analyst agent output |
| Dependencies | No | User input -- omit section if no dependencies |
| Acceptance Criteria | Yes | User conversation + standard health/security checks |

- Sections marked "No" for Required can be omitted entirely if not applicable. Do not include empty placeholder sections.
- The Affected Resources table should list every resource individually -- do not group multiple resources into one row.
- Blast Radius Assessment must classify every target environment separately, as the same change may have different blast radius in dev vs production.
- Acceptance Criteria should be concrete and measurable, not vague goals.
