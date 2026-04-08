# Gate Policies

Security and cost gate policies for the `arn-infra-execute-change` skill. These policies govern how findings from security audits and cost estimates are evaluated, when execution is blocked, and how escalation works.

---

## Security Gate Policies

### Severity-Based Rules

#### CRITICAL Findings

**Action:** Block execution immediately.

**Presentation:**
"**SECURITY GATE BLOCKED -- CRITICAL FINDING**

[Finding description]
- **Resource:** [affected resource]
- **Risk:** [what could happen if deployed]
- **Remediation:** [specific fix]

This finding must be resolved before execution can proceed. CRITICAL findings cannot be acknowledged or bypassed."

**Options:**
1. Fix the issue in the IaC code and retry the security gate
2. Abort execution and rollback

**Examples of CRITICAL findings:**
- Publicly accessible database without authentication
- IAM policy granting `*:*` (full admin) to a service role
- Hardcoded secrets or credentials in IaC code
- S3 bucket with public read/write access
- Security group allowing 0.0.0.0/0 on SSH (port 22) for production

---

#### HIGH Findings

**Action:** Present findings with risk assessment. Require explicit acknowledgment.

**Presentation:**
"**SECURITY GATE WARNING -- HIGH FINDING**

[Finding description]
- **Resource:** [affected resource]
- **Risk:** [what could happen if deployed]
- **Remediation:** [specific fix]

This finding represents significant risk. You can acknowledge it to proceed, but the accepted risk will be logged in the phase report."

**Options:**
1. Acknowledge risk and proceed (logged in audit trail)
2. Fix the issue and retry the security gate
3. Abort execution

**Examples of HIGH findings:**
- Overly permissive security group (broad CIDR range, not 0.0.0.0/0)
- Missing encryption at rest for non-production database
- IAM policy broader than principle of least privilege
- Missing VPC for cloud resources (using default VPC)
- Unencrypted data transfer between services

---

#### MEDIUM Findings

**Action:** Log as warnings in the phase report. Proceed with execution.

**Presentation:** Include in the gate summary: "[N] medium findings logged as warnings."

**Examples:**
- Missing resource tagging
- Non-optimal instance sizing
- Missing CloudTrail or audit logging
- Default security group rules unchanged

---

#### LOW Findings

**Action:** Log as informational in the phase report. Proceed with execution.

**Presentation:** Include in the gate summary: "[N] informational findings noted."

**Examples:**
- Naming convention deviations
- Missing description fields on resources
- Using older but still supported API versions
- Non-critical best practice recommendations

---

### Environment-Specific Security Adjustments

| Environment | CRITICAL | HIGH | MEDIUM | LOW |
|-------------|----------|------|--------|-----|
| Development | Block | Warn (no ack required) | Log | Log |
| Staging | Block | Block until acknowledged | Log | Log |
| Production | Block | Block until acknowledged | Warn (presented to user) | Log |

---

## Cost Gate Policies

### Threshold Enforcement

#### Below Threshold

**Action:** Log the cost estimate in the phase report. Proceed.

**Presentation:**
"**Cost gate: PASSED**
- Estimated monthly cost: $X/month
- Threshold: $Y/month
- Budget utilization: Z%"

---

#### Approaching Threshold (80-100%)

**Action:** Warn the user. Proceed with the warning logged.

**Presentation:**
"**Cost gate: WARNING -- Approaching budget limit**
- Estimated monthly cost: $X/month
- Threshold: $Y/month
- Budget utilization: Z%

Execution will proceed, but you are approaching your budget limit."

---

#### Exceeds Threshold

**Action:** Present detailed cost breakdown. Require explicit acknowledgment.

**Presentation:**
"**COST GATE -- THRESHOLD EXCEEDED**

**Cost Breakdown:**
| Resource | Type | Monthly Cost |
|----------|------|-------------|
| [name]   | [type] | $X/month |
| ...      | ...    | ...      |

**Phase total:** $X/month
**Cumulative (all phases):** $Y/month
**Threshold:** $Z/month
**Over budget by:** $W/month

**Cost Reduction Suggestions:**
1. [Suggestion 1 -- e.g., use a smaller instance type: t3.medium -> t3.small saves $X/month]
2. [Suggestion 2 -- e.g., use reserved instances for 1-year commitment saves $X/month]
3. [Suggestion 3 -- e.g., use spot instances for non-critical workloads saves $X/month]
4. [Suggestion 4 -- e.g., consolidate resources to reduce count]"

**Options:**
1. Acknowledge the cost and proceed (logged in audit trail)
2. Modify the configuration to reduce costs and retry the cost gate
3. Abort execution

---

#### No Threshold Configured

**Action:** Log the cost estimate. Proceed without gate enforcement.

**Presentation:**
"**Cost estimate:** $X/month (no threshold configured -- consider setting one in `/arn-infra-init`)"

---

### Cumulative Cost Tracking

Track total cost across phases:

```
Phase 1: +$50/month  -> Cumulative: $50/month (threshold: $200/month, 25%)
Phase 2: +$80/month  -> Cumulative: $130/month (threshold: $200/month, 65%)
Phase 3: +$90/month  -> Cumulative: $220/month (threshold: $200/month, 110%) -- EXCEEDED
```

Present cumulative cost at each phase to help users track budget consumption.

---

## Escalation Procedures

### When Any Gate Blocks

Present exactly 3 options:

1. **Acknowledge risk and proceed** -- Available for HIGH security findings and cost threshold exceedance. Not available for CRITICAL security findings. The acknowledgment is logged in the phase report with timestamp and finding details.

2. **Fix the issue and retry the gate** -- The user modifies the IaC code or configuration. The gate is re-evaluated from scratch. All findings are re-checked (not just the blocking one).

3. **Abort execution and rollback** -- Stop execution for the current phase. Restore the rollback checkpoint created in Step 1. Set phase status to `rolled_back` in PROGRESS_TRACKER.json.

### Audit Trail

All gate decisions are recorded in the INFRA_CHANGE_REPORT for the phase:

```json
{
  "gateDecisions": [
    {
      "gate": "security",
      "step": "2.3",
      "status": "passed",
      "findings": 0,
      "timestamp": "2026-03-14T10:30:00Z"
    },
    {
      "gate": "cost",
      "step": "2.4",
      "status": "acknowledged",
      "findings": 1,
      "detail": "Estimated $220/month exceeds threshold of $200/month",
      "acknowledgedBy": "user",
      "timestamp": "2026-03-14T10:35:00Z"
    }
  ]
}
```

This audit trail is reviewed by the `arn-infra-change-reviewer` agent during the review gate (Step 2.7) and during the full review via `arn-infra-review-change`.
