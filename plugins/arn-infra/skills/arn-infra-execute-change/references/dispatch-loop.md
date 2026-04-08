# Dispatch Loop

Per-phase execution sequence for the `arn-infra-execute-change` skill. This reference documents the 7-step dispatch loop, gate evaluation logic, checkpoint management, parallel execution, progress tracking, and resume logic.

---

## Agent Invocation Sequence

Each phase executes 7 steps in order. Each step invokes a specific agent or procedure with structured context blocks.

### Step 1: Rollback Checkpoint

Before any changes, create a rollback checkpoint.

**IaC state backup (by tool):**

| Tool | Backup Command | Restore Command |
|------|---------------|-----------------|
| OpenTofu/Terraform | `tofu state pull > checkpoint-phase-N.tfstate` | `tofu state push checkpoint-phase-N.tfstate` |
| Pulumi | `pulumi stack export --stack <env> > checkpoint-phase-N.json` | `pulumi stack import --stack <env> --file checkpoint-phase-N.json` |
| CDK | Record CloudFormation stack state via `aws cloudformation describe-stacks` | Revert code and `cdk deploy` |
| Bicep | Record deployment via `az deployment group show` | Revert code and redeploy |
| kubectl/Helm | `kubectl get all -o yaml > checkpoint-phase-N.yaml` | `kubectl apply -f checkpoint-phase-N.yaml` |

**Resource manifest backup:**
- Copy `active-resources.json` to `checkpoint-phase-N-resources.json`

**Checkpoint storage:**
- Store checkpoints in the project's `reports/` directory: `reports/checkpoint-phase-N/`

### Step 2: IaC Generation (arn-infra-specialist)

Invoke the `arn-infra-specialist` agent with:

```text
--- PHASE PLAN ---
[full PHASE_N_PLAN.md content including Resources table, Target Environment,
 Security Requirements, and Cost Estimate sections]
--- END PHASE PLAN ---

--- PROVIDER CONFIG ---
[provider configuration from providers.md: provider names, regions, IaC tool
 overrides, authentication state]
--- END PROVIDER CONFIG ---

--- INFRASTRUCTURE CONTEXT ---
Project: [project name]
Phase: [N] of [total]
Environment: [target environment]
IaC Tool: [default tool or per-provider override]
Blast Radius: [classification]
Existing resources: [summary from active-resources.json if available]
--- END INFRASTRUCTURE CONTEXT ---

--- GENERATION INSTRUCTIONS ---
Generate IaC configurations for all resources listed in the phase plan.
Follow resource specifications exactly. Use the configured IaC tool.
Generate environment-specific variable files. Include resource tagging
with: environment, project, managed-by=arn-infra, phase=N.
--- END GENERATION INSTRUCTIONS ---
```

### Step 3: Security Gate (arn-infra-security-auditor)

Invoke the `arn-infra-security-auditor` agent with:

```text
--- IaC ARTIFACTS ---
[list of generated files from Step 2 with full content]
--- END IaC ARTIFACTS ---

--- SECURITY CONTEXT ---
Environment: [target environment]
Blast radius: [classification]
Security requirements from phase plan: [extracted security section]
Compliance frameworks: [from INTRODUCTION.md if specified]
--- END SECURITY CONTEXT ---

--- SCAN INSTRUCTIONS ---
Scan all generated IaC for security issues. Report by severity:
CRITICAL, HIGH, MEDIUM, LOW. Check for:
- Publicly exposed ports or endpoints without authentication
- Missing encryption at rest or in transit
- Overly permissive IAM policies or security groups
- Hardcoded secrets, credentials, or API keys
- Missing VPC or network isolation
- Default passwords or weak configurations
--- END SCAN INSTRUCTIONS ---
```

### Step 4: Cost Gate (arn-infra-cost-analyst)

Invoke the `arn-infra-cost-analyst` agent with:

```text
--- IaC ARTIFACTS ---
[generated IaC content from Step 2]
--- END IaC ARTIFACTS ---

--- COST CONTEXT ---
Cost threshold: [from ## Arness config]
Budget from plan: [from INTRODUCTION.md Cost Budget section]
Cumulative cost from previous phases: [sum from completed phase reports]
Budget remaining: [total budget - cumulative]
--- END COST CONTEXT ---

--- ESTIMATION INSTRUCTIONS ---
Estimate monthly cost for each resource in this phase. Provide:
- Per-resource monthly cost breakdown
- Phase total monthly delta
- One-time costs (data transfer, setup fees)
- Cumulative monthly cost including previous phases
- Comparison against threshold
- Cost optimization suggestions if threshold is exceeded
--- END ESTIMATION INSTRUCTIONS ---
```

### Step 5: Deployment

Execute deployment using procedures from `deploy-procedures.md`:
1. Run plan/preview command for the target environment
2. Present change summary to user for confirmation
3. Execute apply/deploy command
4. Monitor output for success/failure indicators
5. Update resource manifest on success

### Step 6: Verification (arn-infra-verifier)

Invoke the `arn-infra-verifier` agent with:

```text
--- DEPLOYED RESOURCES ---
[resources deployed in this phase: IDs, types, endpoints]
--- END DEPLOYED RESOURCES ---

--- VERIFICATION CONTEXT ---
Environment: [target environment]
Provider(s): [providers involved]
Expected endpoints: [from phase plan or deployment output]
Expected resource state: [from IaC apply output]
Tooling manifest: [available CLIs for state queries]
--- END VERIFICATION CONTEXT ---

--- VERIFICATION INSTRUCTIONS ---
Run health checks on all endpoints. Verify DNS resolution.
Validate SSL certificates. Compare resource state against expected.
Report PASS/WARN/FAIL verdict.
--- END VERIFICATION INSTRUCTIONS ---
```

### Step 7: Review Gate (arn-infra-change-reviewer)

Invoke the `arn-infra-change-reviewer` agent with:

```text
--- PHASE REPORT ---
[INFRA_CHANGE_REPORT data collected during Steps 1-6]
--- END PHASE REPORT ---

--- CHANGE SPEC ---
[original INFRA_CHANGE_*.md specification content]
--- END CHANGE SPEC ---

--- REVIEW INSTRUCTIONS ---
Review this phase for: security posture delta, cost compliance,
blast radius adherence, rollback documentation completeness.
Provide a phase-level verdict: pass / warn / needs-fixes.
--- END REVIEW INSTRUCTIONS ---
```

---

## Gate Evaluation Logic

### Security Gate Decision Table

| Finding Severity | Action | Blocks Execution? |
|-----------------|--------|-------------------|
| CRITICAL | Present findings. Options: fix-and-retry or abort. | Yes -- no override allowed |
| HIGH | Present findings with risk assessment. Require explicit acknowledgment. | Yes -- until acknowledged |
| MEDIUM | Log as warnings in phase report. | No |
| LOW | Log as informational in phase report. | No |

### Cost Gate Decision Table

| Cost vs Threshold | Action | Blocks Execution? |
|-------------------|--------|-------------------|
| Below threshold | Log estimate, proceed. | No |
| 80-100% of threshold | Warn: "Approaching budget limit." Proceed with warning logged. | No |
| Exceeds threshold | Present breakdown. Require acknowledgment. Suggest alternatives. | Yes -- until acknowledged |
| No threshold configured | Log estimate, proceed. | No |

### All Gate Decisions Logged

Every gate decision (pass, block, acknowledge) is recorded in the phase report for audit trail:
```json
{
  "gate": "security | cost",
  "status": "passed | blocked | acknowledged",
  "findings": [...],
  "acknowledgedBy": "user",
  "timestamp": "<ISO-8601>"
}
```

---

## Checkpoint Management

### When to Create

- **Before each phase** -- mandatory
- **Before destructive operations** -- within a phase if it involves destroy actions

### What to Snapshot

| Artifact | Location | Purpose |
|----------|----------|---------|
| IaC state file | `reports/checkpoint-phase-N/` | State rollback |
| Resource manifest | `reports/checkpoint-phase-N/active-resources.json` | Resource inventory rollback |
| Generated IaC files | `reports/checkpoint-phase-N/iac/` | Code reference for debugging |
| Environment config | `reports/checkpoint-phase-N/environments.md` | Environment state reference |

### How to Restore

1. Stop any in-progress deployment
2. Restore IaC state from checkpoint: use the tool-specific restore command from the table in Step 1
3. Restore resource manifest from checkpoint
4. Run `tofu plan` / `pulumi preview` to verify state matches infrastructure
5. If drift detected: run `tofu apply` / `pulumi up` to reconcile back to checkpoint state

---

## Parallel Batch Execution

### Identifying Independent Resources

Resources are independent when:
- No resource references another resource's output (ID, ARN, endpoint)
- No resource depends on another resource's existence (foreign key, network membership)
- Resources are in different logical groups (separate modules, stacks, or services)

### Execution Strategy

1. Build a dependency graph from the phase plan's Resources table
2. Group independent resources into parallel batches
3. For each batch:
   - Generate IaC in parallel (one specialist invocation per batch if separate modules)
   - Run security and cost gates on the combined output (single pass)
   - Execute deployment commands in parallel (if supported by the IaC tool)
   - Wait for all batch deployments to complete
4. After all batches complete: run verification on all resources together

### Constraints

- **Within same environment:** Parallel execution allowed
- **Across environments:** Always sequential -- environment promotion requires user approval
- **Shared resources:** Resources that depend on each other execute sequentially within the batch order

---

## Progress Tracking Updates

### Per-Step Updates to PROGRESS_TRACKER.json

| Step | Field Updated | Value |
|------|--------------|-------|
| Start phase | `phases[N].execution.status` | `"in_progress"` |
| Security gate | `phases[N].securityGate.status` | `"passed"` / `"blocked"` / `"acknowledged"` |
| Cost gate | `phases[N].costGate.status` | `"passed"` / `"exceeded"` / `"acknowledged"` |
| Verification | `phases[N].verification.status` | `"passed"` / `"failed"` / `"skipped"` |
| Review | `phases[N].review.verdict` | `"pass"` / `"warn"` / `"needs-fixes"` |
| Complete phase | `phases[N].execution.status` | `"completed"` |
| Phase failed | `phases[N].execution.status` | `"failed"` |
| Rollback | `phases[N].execution.status` | `"rolled_back"` |
| All complete | `overallStatus` | `"completed"` |

Always update `lastUpdated` with the current ISO 8601 timestamp on every write.

---

## Resume Logic

### Detection

When `arn-infra-execute-change` starts:
1. Read `PROGRESS_TRACKER.json`
2. Find the first phase where `execution.status` is not `completed`
3. Within that phase, determine the last completed step by checking gate statuses

### Resume Points

| Last Completed Step | Resume At |
|--------------------|-----------|
| None (not_started) | Step 1: Rollback Checkpoint |
| Checkpoint created | Step 2: IaC Generation |
| IaC generated | Step 3: Security Gate |
| Security gate passed | Step 4: Cost Gate |
| Cost gate passed | Step 5: Deployment |
| Deployment complete | Step 6: Verification |
| Verification complete | Step 7: Review Gate |

### Resume Presentation

"**Resuming execution:**
- **Project:** [name]
- **Phase:** [N] -- [title]
- **Last completed step:** [step name]
- **Resuming at:** [next step name]

Continue from [next step]?"

If the user declines, offer: "Would you like to restart Phase [N] from the beginning instead?"
