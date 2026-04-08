---
name: arn-infra-execute-change
description: >-
  This skill should be used when the user says "execute infra change",
  "run infra plan", "apply infrastructure change", "execute change",
  "arn infra execute", "deploy infra plan", "execute infrastructure plan",
  "run infrastructure change", "apply infra plan", "infra execute",
  "arn-infra-execute-change", or wants to orchestrate the phased execution
  of a structured infrastructure change plan, invoking agents for IaC
  generation, security gates, cost gates, deployment, verification, and review.
version: 1.0.0
---

# Arness Infra Execute Change

Orchestrate the phased execution of a structured infrastructure change plan. For each phase, this skill runs a 7-step dispatch loop: rollback checkpoint, IaC generation, security gate, cost gate, deployment, verification, and review gate. It tracks progress in PROGRESS_TRACKER.json and produces per-phase INFRA_CHANGE_REPORT_PHASE_N.json reports.

This skill consumes the structured project created by `arn-infra-save-plan` and coordinates all existing infrastructure agents (specialist, security-auditor, cost-analyst, verifier) plus the new change-reviewer agent.

Pipeline position:
```
arn-infra-init -> arn-infra-change-spec -> arn-infra-change-plan -> arn-infra-save-plan -> **arn-infra-execute-change** -> arn-infra-review-change -> arn-infra-document-change
```

## Prerequisites

Read `## Arness` from the project's CLAUDE.md. If no `## Arness` section exists or Arness Infra fields are missing, inform the user: "Arness Infra is not configured for this project yet. Run `/arn-infra-wizard` to get started — it will set everything up automatically." Do not proceed without it.

Check the **Deferred** field. If `Deferred: yes`, inform the user: "Infrastructure is in deferred mode. Change execution is not available until infrastructure is fully configured. Run `/arn-infra-assess` to un-defer." Stop.

Extract:
- **Infra plans directory** -- where structured plan projects live (default: `.arness/infra-plans`)
- **Providers** -- cloud providers configured
- **Providers config** -- path to `providers.md`
- **Environments** -- environment names in promotion order
- **Environments config** -- path to `environments.md`
- **Experience level** -- derived from user profile. Read `~/.arness/user-profile.yaml` (or `.claude/arness-profile.local.md` if it exists — project override takes precedence). Apply the experience derivation mapping from `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-ensure-config/references/experience-derivation.md`. If no profile exists, check for legacy `Experience level` in `## Arness` as fallback.
- **Cost threshold** -- monthly budget limit for cost gate warnings (default: `100`)
- **Default IaC tool** -- default IaC tool
- **Tooling manifest** -- path to `tooling-manifest.json`
- **Resource manifest** -- path to `active-resources.json`

### Locate the Structured Plan Project

Search for structured plan projects in the **Infra plans directory**:

```
Glob <infra-plans-dir>/*/PROGRESS_TRACKER.json
```

**If one project found:** Auto-select it.
**If multiple projects found:** Present the list with project names and overall status from each PROGRESS_TRACKER.json. Ask the user to select.
**If no project found:** Inform the user: "No structured plan project found. Run `/arn-infra-save-plan` to create one from a plan preview."

Read `PROGRESS_TRACKER.json` to determine current phase and execution state. If a phase is `in_progress`, offer to resume from the last completed step.

---

## Workflow

### Step 1: Present Execution Plan

Read the project's INTRODUCTION.md and present an execution summary:

"**Infrastructure Change Execution:**
- **Project:** [project name]
- **Phases:** [total] ([completed] completed, [remaining] remaining)
- **Current phase:** [N] -- [title] (targeting [environment])
- **Blast radius:** [classification for current phase]
- **Cost budget remaining:** $[amount]

Proceed with Phase [N]?"

**Token consumption warning:** If the project has 5+ phases or 20+ resources, warn: "This is a large change with [N] phases and [M] resources. Execution will consume significant context. Consider executing one phase at a time."

---

### Step 2: Per-Phase Dispatch Loop

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-execute-change/references/dispatch-loop.md` for the detailed dispatch loop logic.

For the current phase, execute the 7-step dispatch loop:

#### Step 2.1: Create Rollback Checkpoint

Before making any changes, create a rollback checkpoint:
- Backup IaC state files (state pull/export)
- Record the current resource manifest state
- Note the checkpoint path in the phase report

Update PROGRESS_TRACKER.json: set phase execution status to `in_progress`.

#### Step 2.2: Invoke IaC Generation (arn-infra-specialist)

Read the phase plan (`PHASE_N_PLAN.md`) and invoke the `arn-infra-specialist` agent with structured context:

```text
--- PHASE PLAN ---
[full content of PHASE_N_PLAN.md]
--- END PHASE PLAN ---

--- PROVIDER CONFIG ---
[provider configuration from providers.md]
--- END PROVIDER CONFIG ---

--- INFRASTRUCTURE CONTEXT ---
Project: [project name]
Phase: [N] of [total]
Environment: [target environment]
IaC Tool: [tool]
Blast Radius: [classification]
--- END INFRASTRUCTURE CONTEXT ---

--- GENERATION INSTRUCTIONS ---
Generate the IaC configurations for all resources listed in the phase plan.
Follow the resource specifications exactly. Use the configured IaC tool.
Generate environment-specific variable files. Include resource tagging.
--- END GENERATION INSTRUCTIONS ---
```

#### Step 2.3: Security Gate (arn-infra-security-auditor)

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-execute-change/references/gate-policies.md` for security gate enforcement rules.

Invoke the `arn-infra-security-auditor` agent to scan the generated IaC:

```text
--- IaC ARTIFACTS ---
[list of generated files with content]
--- END IaC ARTIFACTS ---

--- SECURITY CONTEXT ---
Environment: [target environment]
Blast radius: [classification]
Security requirements: [from phase plan]
--- END SECURITY CONTEXT ---

--- SCAN INSTRUCTIONS ---
Scan the generated IaC for security issues. Report findings by severity
(CRITICAL, HIGH, MEDIUM, LOW). Check for: exposed ports, public access,
missing encryption, overly permissive IAM, hardcoded secrets.
--- END SCAN INSTRUCTIONS ---
```

**Gate evaluation (per gate-policies.md):**
- CRITICAL findings: block execution, present findings, require fix-and-retry or abort
- HIGH findings: present findings with risk assessment, require explicit acknowledgment
- MEDIUM/LOW findings: log in phase report, proceed

Update PROGRESS_TRACKER.json: set `securityGate.status`.

#### Step 2.4: Cost Gate (arn-infra-cost-analyst)

Invoke the `arn-infra-cost-analyst` agent to estimate costs:

```text
--- IaC ARTIFACTS ---
[generated IaC content]
--- END IaC ARTIFACTS ---

--- COST CONTEXT ---
Cost threshold: [from config]
Cumulative cost so far: [from previous phases]
Budget remaining: [total budget - cumulative]
--- END COST CONTEXT ---

--- ESTIMATION INSTRUCTIONS ---
Estimate the monthly cost for all resources in this phase.
Break down costs per resource. Compare against the threshold.
Suggest cost optimizations if threshold is exceeded.
--- END ESTIMATION INSTRUCTIONS ---
```

**Gate evaluation (per gate-policies.md):**
- Exceeds threshold: present detailed breakdown, require acknowledgment, suggest alternatives
- Within threshold: log estimate, proceed

Update PROGRESS_TRACKER.json: set `costGate.status`.

#### Step 2.5: Execute Deployment

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-execute-change/references/deploy-procedures.md` for per-tool deployment commands.

Execute the deployment using the procedures from `deploy-procedures.md`. Follow the same deployment flow as `arn-infra-deploy`:
- Run plan/preview command
- Present changes to user for confirmation
- Execute apply/deploy command
- Monitor deployment progress
- Update resource manifest on success

**User confirmation is required before every apply/deploy command.**

#### Step 2.6: Verification (arn-infra-verifier)

Invoke the `arn-infra-verifier` agent to validate the deployment:

```text
--- DEPLOYED RESOURCES ---
[list of resources from this phase]
--- END DEPLOYED RESOURCES ---

--- VERIFICATION CONTEXT ---
Environment: [target environment]
Expected endpoints: [from phase plan]
Expected resource state: [from IaC output]
--- END VERIFICATION CONTEXT ---

--- VERIFICATION INSTRUCTIONS ---
Run health checks, DNS verification, SSL validation, and resource state
comparison for all deployed resources. Report PASS/WARN/FAIL verdict.
--- END VERIFICATION INSTRUCTIONS ---
```

Update PROGRESS_TRACKER.json: set `verification.status`.

#### Step 2.7: Review Gate (arn-infra-change-reviewer)

Invoke the `arn-infra-change-reviewer` agent for a phase-level review:

```text
--- PHASE REPORT ---
[INFRA_CHANGE_REPORT content for this phase]
--- END PHASE REPORT ---

--- CHANGE SPEC ---
[original spec content]
--- END CHANGE SPEC ---

--- REVIEW INSTRUCTIONS ---
Review this single phase for security posture, cost compliance, blast radius
adherence, and rollback documentation. Provide a phase-level verdict.
--- END REVIEW INSTRUCTIONS ---
```

Update PROGRESS_TRACKER.json: set `review.verdict`.

---

### Step 3: Write Phase Report

After the dispatch loop completes:

> Read the report template: `Read ${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-save-plan/report-templates/default/INFRA_CHANGE_REPORT_TEMPLATE.json`

Write `INFRA_CHANGE_REPORT_PHASE_N.json` to the project's `reports/` directory using the loaded template schema.

Update PROGRESS_TRACKER.json:
- Set phase execution status to `completed` (or `failed` / `rolled_back`)
- Update `lastUpdated` timestamp
- If all phases complete, set `overallStatus` to `completed`

---

### Step 4: Environment Promotion Gate

If the next phase targets a different environment:

"**Environment Promotion:**
Phase [N] ([current-env]) is complete. Phase [N+1] targets [next-env].

**Phase [N] Summary:**
- Resources: [N] created, [N] modified, [N] destroyed
- Security gate: [status]
- Cost gate: [status]
- Verification: [status]
- Review verdict: [verdict]

Ask (using `AskUserQuestion`):

**"Promote to [next-env]? This requires explicit approval."**

Options:
1. **Yes** -- Promote to [next-env] and continue execution
2. **No** -- Stop execution here

**User approval is required for every environment promotion.** Never auto-promote.

---

### Step 5: Continue or Complete

**If more phases remain:** Return to Step 2 for the next phase.

**If all phases complete:** Present the final summary:

"**Infrastructure Change Complete:**
- **Project:** [name]
- **Phases executed:** [N]
- **Resources provisioned:** [total]
- **Total estimated cost:** $[amount]/month
- **Overall review verdict:** [pass/warn/needs-fixes]

**Next steps:**
1. **Full review** -- Run `/arn-infra-review-change` for a comprehensive cross-phase review
2. **Documentation** -- Run `/arn-infra-document-change` to generate runbooks and changelog
3. **Monitor** -- Run `/arn-infra-monitor` to set up observability"

---

### Parallel Batch Execution

For parallel execution of independent resources within the same environment, see the dispatch loop reference.

---

## Error Handling

- **`## Arness` config missing:** Suggest running `/arn-infra-wizard` to get started. Stop.
- **Plan project not found:** Suggest running `/arn-infra-save-plan` to create a structured project. Stop.
- **PROGRESS_TRACKER.json missing or corrupt:** Offer to regenerate from the phase plans. If the user agrees, scan the `plans/` directory and rebuild the tracker.
- **Agent invocation fails:** Report the error. Offer to retry the agent, skip the step (with warning), or abort execution. If aborting, trigger rollback for the current phase.
- **Security gate blocks:** Present the CRITICAL findings. Options: (1) Fix the IaC and retry, (2) Abort and rollback, (3) Do not offer "acknowledge and proceed" for CRITICAL findings.
- **Cost gate exceeds threshold:** Present the cost breakdown. Options: (1) Acknowledge and proceed, (2) Fix the configuration to reduce costs and retry, (3) Abort execution.
- **Deployment fails:** Capture error output. Offer: (1) Retry deployment, (2) Rollback using checkpoint, (3) Abort and leave current state. Update PROGRESS_TRACKER.json with failure status.
- **Verification fails:** Present the verification report. Offer: (1) Investigate and fix, (2) Rollback the phase, (3) Acknowledge and proceed (with warning logged).
- **Environment promotion denied:** Stop execution. The project remains in its current state. The user can resume later.
- **Resume from interruption:** Detect the last completed step from PROGRESS_TRACKER.json. Present: "Execution was interrupted at Phase [N], Step [step]. Resume from [next step]?" If yes, continue from the interrupted point. If no, offer to restart the phase.
- **Re-running is safe:** Re-running re-reads PROGRESS_TRACKER.json and resumes from the first incomplete phase. Completed phases are not re-executed unless the user explicitly requests it.
