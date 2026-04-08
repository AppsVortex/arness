---
name: arn-infra-document-change
description: >-
  This skill should be used when the user says "document infra change",
  "infrastructure documentation", "generate runbook", "infra docs",
  "arn infra document", "create infra changelog", "document infrastructure",
  "generate infrastructure docs", "infra documentation", "create runbook",
  "generate changelog", "arn-infra-document-change", or wants to generate
  operational documentation (runbooks, architecture updates, changelogs,
  environment docs) from completed infrastructure changes.
version: 1.0.0
---

# Arness Infra Document Change

Generate comprehensive operational documentation from completed infrastructure changes. This skill reads the change spec, plan, execution reports, and review report, then produces runbooks, architecture updates, operational playbooks, environment documentation, and changelog entries -- all written to the configured Infra docs directory.

This is the final step in the infrastructure change pipeline: change-spec -> change-plan -> save-plan -> execute-change -> review-change -> **document-change**.

## Prerequisites

Read `## Arness` from the project's CLAUDE.md. If no `## Arness` section exists or Arness Infra fields are missing, inform the user: "Arness Infra is not configured for this project yet. Run `/arn-infra-wizard` to get started — it will set everything up automatically." Do not proceed without it.

Check the **Deferred** field. If `Deferred: yes`, inform the user: "Infrastructure is in deferred mode. Documentation generation is not available until infrastructure is fully configured. Run `/arn-infra-assess` to un-defer." Stop.

Extract:
- **Infra docs directory** -- where documentation artifacts are written (default: `.arness/infra-docs`)
- **Infra plans directory** -- where structured plan projects live (default: `.arness/infra-plans`)
- **Infra specs directory** -- where change specs are stored (default: `.arness/infra-specs`)
- **Providers** -- cloud providers configured
- **Environments** -- environment names
- **Experience level** -- derived from user profile. Read `~/.arness/user-profile.yaml` (or `.claude/arness-profile.local.md` if it exists — project override takes precedence). Apply the experience derivation mapping from `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-ensure-config/references/experience-derivation.md`. If no profile exists, check for legacy `Experience level` in `## Arness` as fallback.

Resolve **Infra docs directory** (default: `.arness/infra-docs`). If the directory does not exist on disk, offer to create it: "The infra docs directory `<path>` does not exist yet. I can create it now. Proceed?"

### Locate the Completed Change Project

Search for completed change projects:

```
Glob <infra-plans-dir>/*/PROGRESS_TRACKER.json
```

Filter to projects where `overallStatus === "completed"` or where at least one phase has `execution.status === "completed"`.

**If one eligible project found:** Auto-select it.
**If multiple eligible projects found:** Present the list. Ask the user to select.
**If no eligible project found:** Inform the user: "No completed change projects found. Run `/arn-infra-execute-change` to execute a change plan first."

---

## Workflow

### Step 1: Gather Documentation Inputs

Read all artifacts from the selected project:

1. **Change spec:** The original `INFRA_CHANGE_*.md` specification
2. **Source plan:** `SOURCE_PLAN.md` from the project directory
3. **INTRODUCTION.md:** Project overview with cost budget, security requirements, rollback strategy
4. **Phase reports:** All `INFRA_CHANGE_REPORT_PHASE_N.json` files
5. **Review report:** `INFRA_REVIEW_REPORT.json` (if available -- review is recommended but not required)
6. **PROGRESS_TRACKER.json:** Overall execution status

Present a documentation scope summary:
"**Documentation scope:**
- **Project:** [name]
- **Phases documented:** [N]
- **Environments:** [list]
- **Resources:** [count]
- **Review verdict:** [pass/warn/needs-fixes or 'not reviewed']

I will generate the following documentation:
- Runbook (deployment and rollback procedures)
- Architecture update (resource inventory and diagram)
- Operational playbook (day-2 operations)
- Environment documentation (per-environment details)
- Changelog entry (structured change record)"

Ask (using `AskUserQuestion`):

**"Proceed with generating documentation?"**

Options:
1. **Yes** -- Generate all documentation artifacts
2. **No** -- Cancel documentation generation

---

### Experience-Level Adaptation

Before generating documentation artifacts in Steps 2-6, note the user's experience level (derived from user profile) and apply these principles:

- **Expert:** Concise documentation, command-focused, minimal prose. Assume familiarity with tools and cloud concepts. Focus on reference material: command tables, endpoint lists, configuration values.
- **Intermediate:** Balanced documentation with context and commands. Include brief explanations of trade-offs and alternatives. Highlight areas that may need customization.
- **Beginner:** Detailed documentation with explanations and examples. Include plain-language descriptions of what each resource does and why. Add common pitfalls and how to avoid them. Include screenshots or dashboard navigation instructions where relevant.

---

### Step 2: Generate Runbook

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-document-change/references/runbook-template.md` for the runbook template.

Generate a runbook following the template structure with infrastructure-specific content from the phase reports and plan.

Populate all 8 sections:
1. **Change Summary** -- from spec and INTRODUCTION.md
2. **Prerequisites** -- tools from tooling manifest, credentials from provider config
3. **Deployment Steps** -- from phase reports (exact commands used, in order)
4. **Verification Steps** -- from verification data in phase reports
5. **Rollback Procedure** -- from INTRODUCTION.md rollback strategy and phase checkpoints
6. **Monitoring** -- dashboards and alerts configured (from monitor skill if run)
7. **Escalation** -- contact placeholders for the team to fill in
8. **Known Issues and Workarounds** -- from review report warnings and acknowledged findings

Write to: `<infra-docs-dir>/runbook-<project-name>.md`

---

### Step 3: Generate Architecture Update

Generate an updated architecture document reflecting the current infrastructure state:

1. **Resource inventory table:** All resources across all environments with type, provider, status, and cost
2. **Architecture diagram (text-based):** ASCII or Mermaid diagram showing resource relationships
3. **Dependency map:** Which resources depend on which (from IaC dependencies)
4. **Endpoint registry:** All endpoints with URLs, types, and health check paths

Write to: `<infra-docs-dir>/architecture-<project-name>.md`

---

### Step 4: Generate Operational Playbook

Generate a day-2 operations playbook:

1. **Common operations:** Scaling, restarting, updating configurations
2. **Troubleshooting guide:** Common failure modes and resolution steps (from deployment-safety-checklist patterns)
3. **Maintenance windows:** When to perform updates, recommended schedules
4. **Cost management:** How to monitor costs, optimize spending, clean up unused resources
5. **Security operations:** Credential rotation, access reviews, audit log review

Write to: `<infra-docs-dir>/playbook-<project-name>.md`

---

### Step 5: Generate Environment Documentation

For each environment that was deployed to:

1. **Environment summary:** Name, provider, region, resource count, monthly cost
2. **Resource state:** Per-resource details (ID, type, status, endpoints)
3. **Access instructions:** How to connect, required credentials (by reference, not values)
4. **Configuration:** Environment-specific settings and variable overrides
5. **Promotion status:** Which environments have been promoted from/to

Write to: `<infra-docs-dir>/env-<environment-name>-<project-name>.md` (one per environment)

---

### Step 6: Generate Changelog Entry

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-document-change/references/changelog-template.md` for the changelog template.

Generate a structured changelog entry following the template. If an existing changelog file exists at `<infra-docs-dir>/CHANGELOG.md`, prepend the new entry. If no changelog exists, create it with the entry.

Populate all 10 fields:
1. Date and Change ID
2. Summary
3. Resources Affected
4. Environments
5. Blast Radius
6. Cost Impact
7. Security Impact
8. Rollback Reference
9. Related Spec and Plan
10. Review Verdict

Write to: `<infra-docs-dir>/CHANGELOG.md` (prepend if exists, create if not)

---

### Step 7: Present Summary

"**Documentation generated:**

| Document | Path | Sections |
|----------|------|----------|
| Runbook | `<path>` | [N] sections |
| Architecture | `<path>` | [N] sections |
| Playbook | `<path>` | [N] sections |
| Environment docs | `<paths>` | [N] per env |
| Changelog | `<path>` | 1 entry added |

**Total files:** [N] created/updated in `<infra-docs-dir>/`

**Next steps:**
1. Review the generated documentation and fill in team-specific details (escalation contacts, internal URLs)
2. Share the runbook with the operations team
3. Add the architecture doc to your project wiki
4. Consider running `/arn-infra-monitor` if monitoring is not yet configured"

---

## Error Handling

- **`## Arness` config missing:** Suggest running `/arn-infra-wizard` to get started. Stop.
- **Project not found:** Suggest running `/arn-infra-save-plan` to create a structured project. Stop.
- **Incomplete change data (no reports):** Warn: "No execution reports found. Documentation will be based on the plan only, not actual execution data. Consider running `/arn-infra-execute-change` first."
- **Infra docs directory creation fails:** Report the error. Suggest checking file permissions and creating the directory manually.
- **Template loading fails:** Warn about the missing template. Generate documentation using built-in structure (less detailed but functional).
- **Partial generation (some artifacts fail):** Report which artifacts succeeded and which failed. Continue generating remaining artifacts. Present partial results.
- **Re-running is safe:** Re-running overwrites previously generated documentation. The changelog entry is prepended, not duplicated (checked by Change ID).
