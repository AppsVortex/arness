# Runbook Template

Operational runbook template for documenting deployed infrastructure changes. This template produces a self-contained operations document that enables any team member to understand, operate, troubleshoot, and rollback the deployed infrastructure.

---

## Template Structure

### 1. Change Summary

```markdown
## Change Summary

| Field | Value |
|-------|-------|
| **Change ID** | [INFRA_CHANGE_<name> -- from spec filename] |
| **Date** | [ISO 8601 date of deployment completion] |
| **Deployed by** | [user or CI/CD pipeline identifier] |
| **Description** | [One-line summary of the change] |
| **Blast radius** | [none / contained / broad / critical] |
| **Environments** | [List of environments deployed to, in order] |
| **Review verdict** | [pass / warn / needs-fixes] |
```

---

### 2. Prerequisites

```markdown
## Prerequisites

### Required Tools
| Tool | Version | Install Command |
|------|---------|----------------|
| [tool name] | [version] | [install command] |
| ... | ... | ... |

### Access Requirements
- [Cloud provider credentials -- how to obtain, not the values]
- [VPN or network requirements]
- [Required IAM roles or permissions]
- [Kubernetes cluster access -- kubeconfig path]

### Environment Variables
| Variable | Purpose | Source |
|----------|---------|--------|
| [VAR_NAME] | [what it is used for] | [where to get the value -- secret manager path, not the value] |
| ... | ... | ... |
```

---

### 3. Deployment Steps

```markdown
## Deployment Steps

**Total estimated duration:** [sum of per-step estimates]

### Step 1: [Step title]
**Duration:** [estimate]
**Environment:** [target environment]

Commands:
\```bash
[exact commands used during deployment]
\```

Expected output:
\```
[what the successful output looks like]
\```

**Verification:** [how to confirm this step succeeded]

---

### Step 2: [Step title]
...
```

**Populate from:** Phase reports -- extract the exact deployment commands and their output. List steps in the order they were executed, including environment promotion steps.

---

### 4. Verification Steps

```markdown
## Verification Steps

### Health Checks
| Endpoint | Expected Status | Check Command |
|----------|----------------|---------------|
| [URL] | 200 OK | `curl -sf [URL]` |
| ... | ... | ... |

### Smoke Tests
1. [Test description]: [command or procedure]
2. [Test description]: [command or procedure]

### Resource State Validation
\```bash
# Verify all resources are in expected state
[tool-specific state check command]
\```

### Monitoring Dashboard
- [Dashboard URL or navigation path]
- Key metrics to verify: [list]
```

**Populate from:** Verification data in phase reports -- endpoints checked, health check results, resource state comparisons.

---

### 5. Rollback Procedure

```markdown
## Rollback Procedure

**Estimated rollback duration:** [estimate]

### Pre-Rollback Checklist
- [ ] Notify stakeholders of planned rollback
- [ ] Verify rollback checkpoint exists: [checkpoint path]
- [ ] Backup current state before rollback: [backup command]
- [ ] Identify point-of-no-return steps (if any): [list or "none"]

### Phase [N] Rollback (execute in reverse phase order)
**Environment:** [environment]

Step 1: [Rollback step]
\```bash
[rollback command]
\```

Step 2: [Rollback step]
\```bash
[rollback command]
\```

### Post-Rollback Verification
\```bash
[verification command after rollback]
\```

### Point-of-No-Return Warning
[If applicable: describe which steps cannot be rolled back and why
-- e.g., data migration, schema change, DNS propagation]
```

**Populate from:** INTRODUCTION.md rollback strategy, phase plan rollback checkpoints, rollback-patterns.md procedures for the specific IaC tool.

---

### 6. Monitoring

```markdown
## Monitoring

### Dashboards
| Dashboard | URL | Purpose |
|-----------|-----|---------|
| [name] | [URL] | [what it monitors] |
| ... | ... | ... |

### Alerts
| Alert | Condition | Severity | Notification |
|-------|-----------|----------|-------------|
| [name] | [threshold or condition] | [critical/warning/info] | [where notifications go] |
| ... | ... | ... | ... |

### Key Metrics
| Metric | Normal Range | Warning Threshold | Critical Threshold |
|--------|-------------|-------------------|-------------------|
| [name] | [range] | [threshold] | [threshold] |
| ... | ... | ... | ... |

### SLO Impact Assessment
- [Which SLOs are affected by this change]
- [Expected impact on error rates, latency, availability]
```

**Populate from:** Monitor configuration if available, otherwise provide placeholders for the team to fill in.

---

### 7. Escalation

```markdown
## Escalation

### Contacts
| Role | Name | Contact | Hours |
|------|------|---------|-------|
| Primary on-call | [TODO: fill in] | [TODO: fill in] | [TODO: fill in] |
| Secondary on-call | [TODO: fill in] | [TODO: fill in] | [TODO: fill in] |
| Infrastructure lead | [TODO: fill in] | [TODO: fill in] | [TODO: fill in] |

### SLA Commitments
- **Response time:** [TODO: fill in]
- **Resolution time:** [TODO: fill in]

### Incident Response
1. Assess the impact (which environments, which services)
2. Check monitoring dashboards for root cause indicators
3. If rollback is needed, follow the Rollback Procedure above
4. Notify stakeholders using the communication template below
5. File a post-incident report

### Communication Template
Subject: [INCIDENT] [Service] - [Brief description]
Body:
- **Impact:** [what is affected]
- **Status:** [investigating / mitigating / resolved]
- **ETA:** [estimated resolution time]
- **Actions:** [what is being done]
```

**Note:** Escalation contacts are always placeholder -- the team must fill these in with their specific contacts and procedures.

---

### 8. Known Issues and Workarounds

```markdown
## Known Issues and Workarounds

### Expected Transient Errors
| Issue | Duration | Resolution |
|-------|----------|------------|
| [DNS propagation delay] | [up to 48h] | [Wait or flush local DNS cache] |
| [SSL certificate provisioning] | [up to 24h] | [Wait for ACME validation] |
| ... | ... | ... |

### Acknowledged Warnings
| Warning | Category | Risk | Accepted Because |
|---------|----------|------|-----------------|
| [from review report] | [security/cost/...] | [description] | [reason for acceptance] |
| ... | ... | ... | ... |

### Known Limitations
- [Limitation 1: description and impact]
- [Limitation 2: description and impact]

### Troubleshooting Tips
1. **[Symptom]:** [Likely cause] -- [Resolution]
2. **[Symptom]:** [Likely cause] -- [Resolution]
```

**Populate from:** Review report warnings, acknowledged gate findings, and common failure modes from the deployment tool's patterns.
