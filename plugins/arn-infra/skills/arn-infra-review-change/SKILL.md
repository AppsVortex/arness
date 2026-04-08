---
name: arn-infra-review-change
description: >-
  This skill should be used when the user says "review infra change",
  "infrastructure review", "review infrastructure", "infra quality review",
  "arn infra review", "check infra change", "review infrastructure change",
  "infra change review", "quality check infrastructure", "arn-infra-review-change",
  "post-deployment review", or wants to perform a comprehensive post-execution
  quality review of completed infrastructure changes, producing a structured
  review report with a PASS/WARN/NEEDS_FIXES verdict.
version: 1.0.0
---

# Arness Infra Review Change

Perform a comprehensive post-execution quality review of completed infrastructure changes. This skill reads all phase execution reports, the original spec, and the source plan, then invokes the `arn-infra-change-reviewer` agent to evaluate 7 quality categories and produce a structured review report with an overall verdict.

This is the quality gate between execution and documentation. A PASS or WARN verdict enables documentation generation. A NEEDS_FIXES verdict identifies specific remediation actions and suggests re-executing affected phases.

## Prerequisites

Read `## Arness` from the project's CLAUDE.md. If no `## Arness` section exists or Arness Infra fields are missing, inform the user: "Arness Infra is not configured for this project yet. Run `/arn-infra-wizard` to get started — it will set everything up automatically." Do not proceed without it.

Check the **Deferred** field. If `Deferred: yes`, inform the user: "Infrastructure is in deferred mode. Change review is not available until infrastructure is fully configured. Run `/arn-infra-assess` to un-defer." Stop.

Extract:
- **Infra plans directory** -- where structured plan projects live (default: `.arness/infra-plans`)
- **Infra specs directory** -- where change specs are stored (default: `.arness/infra-specs`)
- **Providers** -- cloud providers configured
- **Environments** -- environment names in promotion order
- **Experience level** -- derived from user profile. Read `~/.arness/user-profile.yaml` (or `.claude/arness-profile.local.md` if it exists — project override takes precedence). Apply the experience derivation mapping from `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-ensure-config/references/experience-derivation.md`. If no profile exists, check for legacy `Experience level` in `## Arness` as fallback.
- **Cost threshold** -- monthly budget limit for cost compliance evaluation (default: `100`)

### Locate the Completed Change Project

Search for completed or in-progress change projects:

```
Glob <infra-plans-dir>/*/PROGRESS_TRACKER.json
```

For each project found, read the PROGRESS_TRACKER.json and filter to projects where at least one phase has `execution.status === "completed"`.

**If one eligible project found:** Auto-select it.
**If multiple eligible projects found:** Present the list with project names, phase completion status, and overall status. Ask the user to select.
**If no eligible project found:** Inform the user: "No completed change projects found. Run `/arn-infra-execute-change` to execute a change plan first."

---

## Workflow

### Step 1: Gather Review Inputs

Read all artifacts from the selected project:

1. **Phase reports:** Read all `INFRA_CHANGE_REPORT_PHASE_N.json` files from the project's `reports/` directory:
   ```
   Glob <project-dir>/reports/INFRA_CHANGE_REPORT_PHASE_*.json
   ```

2. **Change spec:** Locate and read the original change spec:
   - Check PROGRESS_TRACKER.json for the `changeSpec` path
   - If not set, search the Infra specs directory: `Glob <infra-specs-dir>/INFRA_CHANGE_*.md`
   - Match by project name

3. **Source plan:** Read `<project-dir>/SOURCE_PLAN.md`

4. **INTRODUCTION.md:** Read `<project-dir>/INTRODUCTION.md` for cost budget and security requirements

**If any phase reports are missing (some phases not executed):**
Warn: "Phase [N] has not been executed yet. The review will cover completed phases only. Consider running `/arn-infra-execute-change` to complete all phases before reviewing."

Present a review scope summary:
"**Review scope:**
- **Project:** [name]
- **Phases completed:** [N] of [total]
- **Environments covered:** [list]
- **Resources deployed:** [count]

Ask (using `AskUserQuestion`):

**"Proceed with review?"**

Options:
1. **Yes** -- Start the quality review
2. **No** -- Cancel

---

### Step 2: Invoke the Change Reviewer Agent

Invoke the `arn-infra-change-reviewer` agent via the Task tool with structured context:

```text
--- PHASE REPORTS ---
Phase 1 Report:
[full JSON content of INFRA_CHANGE_REPORT_PHASE_1.json]

Phase 2 Report:
[full JSON content of INFRA_CHANGE_REPORT_PHASE_2.json]

...
--- END PHASE REPORTS ---

--- CHANGE SPEC ---
[full content of the INFRA_CHANGE_*.md specification]
--- END CHANGE SPEC ---

--- CHANGE PLAN ---
[full content of SOURCE_PLAN.md]
--- END CHANGE PLAN ---

--- PROVIDER CONFIG ---
Providers: [from ## Arness]
Environments: [from ## Arness]
Cost threshold: [from ## Arness]
--- END PROVIDER CONFIG ---

--- REVIEW INSTRUCTIONS ---
Perform a comprehensive review across all 7 categories:
1. Security posture delta (before vs after -- any regressions?)
2. Cost compliance (estimated vs actual vs threshold)
3. Blast radius compliance (planned vs actual impact)
4. Rollback documentation (complete and actionable?)
5. Environment parity (consistent where expected?)
6. State consistency (clean state, no orphaned resources?)
7. Resource tagging (compliant with policy?)

Produce a structured review report with:
- Per-category evaluation with findings
- Per-finding entries with severity, description, resource, and suggestion
- Overall verdict: pass / warn / needs-fixes
- Recommendation and suggested next step

Focus on cross-phase consistency and cumulative impact since this is a
full post-execution review (not a single-phase gate check).
--- END REVIEW INSTRUCTIONS ---
```

---

### Step 3: Write Review Report

Receive the structured review output from the agent.

> Read the report template: `Read ${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-save-plan/report-templates/default/INFRA_REVIEW_REPORT_TEMPLATE.json`

Write `INFRA_REVIEW_REPORT.json` to the project's `reports/` directory following the loaded template schema.

If a previous review report exists, overwrite it (reviews are meant to be re-run after fixes).

Write to: `<project-dir>/reports/INFRA_REVIEW_REPORT.json`

---

### Step 4: Present Results

Adapt the presentation to the user's experience level.

**Expert:**

"**Review Verdict: [PASS / WARN / NEEDS_FIXES]**

| Category | Status | Findings |
|----------|--------|----------|
| Security posture | [OK/WARN/FAIL] | [count] |
| Cost compliance | [OK/WARN/FAIL] | [count] |
| Blast radius | [OK/WARN/FAIL] | [count] |
| Rollback docs | [OK/WARN/FAIL] | [count] |
| Environment parity | [OK/WARN/FAIL] | [count] |
| State consistency | [OK/WARN/FAIL] | [count] |
| Resource tagging | [OK/WARN/FAIL] | [count] |

**Total:** [N] errors, [N] warnings, [N] info
**Report:** `<project-dir>/reports/INFRA_REVIEW_REPORT.json`"

**Intermediate:**

Present the verdict with categorized findings. For each finding with severity HIGH or above, include the description and suggestion. Group findings by category.

**Beginner:**

Present the verdict with plain-language explanations. For each finding:
- What the issue is (in non-technical terms)
- Why it matters
- How to fix it (step-by-step)
- What happens if it is not fixed

---

### Step 5: Handle Verdict

**If verdict is PASS:**
"All quality checks passed. Your infrastructure change is complete.

**Next steps:**
1. **Document** -- Run `/arn-infra-document-change` to generate runbooks, changelog, and architecture docs
2. **Monitor** -- Run `/arn-infra-monitor` to set up observability"

**If verdict is WARN:**
"Quality review passed with warnings. Review the [N] warnings in the report.

**Next steps:**
1. **Address warnings** -- Review the warnings and decide which to fix
2. **Document** -- Run `/arn-infra-document-change` to generate documentation (warnings will be noted)
3. **Monitor** -- Run `/arn-infra-monitor` to set up observability"

**If verdict is NEEDS_FIXES:**
"Quality review found [N] issues that need to be fixed.

**Remediation actions:**
1. [Action 1 -- specific fix with affected resource]
2. [Action 2 -- specific fix with affected resource]
...

**After fixing:** Re-execute the affected phase(s) with `/arn-infra-execute-change`, then re-run `/arn-infra-review-change` to verify the fixes."

---

## Error Handling

- **`## Arness` config missing:** Suggest running `/arn-infra-wizard` to get started. Stop.
- **Project not found:** Suggest running `/arn-infra-save-plan` to create a structured project. Stop.
- **No phase reports found:** Suggest running `/arn-infra-execute-change` to execute the plan. Stop.
- **Agent invocation fails:** Report the error. Offer to retry the review. If retry also fails, present the raw phase report data and suggest manual review.
- **Incomplete phase reports (some phases not executed):** Warn the user and proceed with available data. Note the incomplete coverage in the review report.
- **Review report write fails:** Print the review findings in the conversation so the user can capture them. Warn about the write failure.
- **Re-running is safe:** Re-running overwrites the previous review report. This is the intended behavior -- reviews are meant to be re-run after fixes are applied.
