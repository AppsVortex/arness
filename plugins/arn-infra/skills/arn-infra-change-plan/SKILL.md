---
name: arn-infra-change-plan
description: >-
  This skill should be used when the user says "plan infra change",
  "arn-infra-change-plan", "infra change plan", "plan this infrastructure change",
  "create infra plan", "arn infra plan", "plan the infra spec",
  "infrastructure implementation plan", "infra plan from spec",
  "generate infra plan", "plan infrastructure", or wants to generate a
  phased implementation plan from an infrastructure change specification,
  structured by provisioning order, blast radius, rollback checkpoints,
  and environment promotion gates.
version: 1.0.0
---

# Arness Infra Change Plan

Generate a phased implementation plan from an infrastructure change specification by invoking the `arn-infra-change-planner` agent. The plan is written to disk as a PLAN_PREVIEW file, presented to the user for review, and iteratively refined based on feedback until approved. The approved plan then feeds into `/arn-infra-save-plan` for structuring into phases, tasks, and reports.

This skill plans in infrastructure terms -- phases are ordered by provisioning dependency, blast radius classification, rollback checkpoint placement, and environment promotion gates -- not by application development concepts.

Pipeline position:
arn-infra-init -> arn-infra-change-spec -> [arn-infra-change-plan] -> arn-infra-save-plan -> arn-infra-execute-change -> arn-infra-review-change -> arn-infra-document-change

## Prerequisites

Read `## Arness` from the project's CLAUDE.md. If no `## Arness` section exists or Arness Infra fields are missing, inform the user: "Arness Infra is not configured for this project yet. Run `/arn-infra-wizard` to get started — it will set everything up automatically." Do not proceed without it.

Check the **Deferred** field. If `Deferred: yes`, inform the user: "Infrastructure is in deferred mode. Change planning is not available until infrastructure is fully configured. Run `/arn-infra-assess` to un-defer." Stop.

Extract:
- **Infra specs directory** -- path where INFRA_CHANGE_*.md specs are stored (default: `.arness/infra-specs`)
- **Infra plans directory** -- path where plans are stored (default: `.arness/infra-plans`)
- **Experience level** -- derived from user profile. Read `~/.arness/user-profile.yaml` (or `.claude/arness-profile.local.md` if it exists — project override takes precedence). Apply the experience derivation mapping from `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-ensure-config/references/experience-derivation.md`. If no profile exists, check for legacy `Experience level` in `## Arness` as fallback.
- **Providers** -- which cloud providers are configured
- **Environments** -- which environments exist and their promotion order

If `Infra plans directory` is not configured, use the default `.arness/infra-plans`. If the directory does not exist, create it: `mkdir -p <infra-plans-dir>`.

---

## Workflow

### Step 1: Find the Change Specification

The user may provide a spec name as an argument (e.g., "plan infra change migrate-database-managed" or "arn infra plan INFRA_CHANGE_vpc-restructure").

**If an argument was provided:**
- Look for `<infra-specs-dir>/<argument>.md` (exact match)
- If not found, try `<infra-specs-dir>/INFRA_CHANGE_<argument>.md`
- If not found, try matching files in `<infra-specs-dir>/` that contain the argument text in their filename
- If still not found, list available specs and ask the user to choose

**If no argument was provided:**
- List all `INFRA_CHANGE_*.md` files in `<infra-specs-dir>/`
- If only one exists, use it automatically
- If multiple exist, show the list sorted by modification date (most recent first) and ask the user to choose
- If none exist, inform the user: "No infrastructure change specifications found in `<infra-specs-dir>/`. Run `/arn-infra-change-spec` to create one first."

---

### Step 2: Load Context

Read these files:
1. The selected specification file (INFRA_CHANGE_*.md)
2. The blast radius guide for classification reference:
   > Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-change-spec/references/blast-radius-guide.md`

If the spec file cannot be read, inform the user and stop.

---

### Step 3: Invoke the Change Planner Agent

Derive the spec name from the spec filename (strip prefix and extension):
- `INFRA_CHANGE_migrate-database-managed.md` -> `migrate-database-managed`
- `INFRA_CHANGE_vpc-restructure.md` -> `vpc-restructure`

The output file path is: `<infra-plans-dir>/PLAN_PREVIEW_INFRA_<spec-name>.md`

**Check for existing PLAN_PREVIEW:** If a PLAN_PREVIEW file already exists at that path, inform the user: "A plan preview already exists for this spec: `<path>`."

Ask (using `AskUserQuestion`):

**"A plan preview already exists. What would you like to do?"**

Options:
1. **Regenerate** -- Generate a new plan from scratch
2. **Review** -- Review the existing plan

If **Review**, skip to Step 4. If **Regenerate**, proceed.

Invoke the `arn-infra-change-planner` agent via the Task tool with:

```text
You are generating a phased infrastructure implementation plan for the following change specification.

**Specification:** <spec-name>
**Spec file:** <infra-specs-dir>/<spec-filename>

--- CHANGE SPEC ---
[full spec file content]
--- END CHANGE SPEC ---

--- PROVIDER CONFIG ---
Providers: [from ## Arness]
Default IaC tool: [from ## Arness, if configured]
--- END PROVIDER CONFIG ---

--- ENVIRONMENT CONFIG ---
Environments: [from ## Arness]
Promotion order: [from ## Arness or from the spec's Environment Scope section]
--- END ENVIRONMENT CONFIG ---

--- OUTPUT INSTRUCTIONS ---
Output file: <infra-plans-dir>/PLAN_PREVIEW_INFRA_<spec-name>.md

Generate a phased implementation plan structured by:
1. Provisioning dependency order (network before compute, compute before application)
2. Blast radius classification per phase (lowest to highest where possible)
3. Rollback checkpoint placement (before data-involved phases, before network changes, before cross-environment promotions)
4. Environment promotion gates (sequential: dev -> staging -> production, with explicit gates)
5. Cost budgeting per phase (estimated delta, cumulative tracking)
6. Parallel execution opportunities (independent resources within the same environment)

Include `Spec: <infra-specs-dir>/<spec-filename>` near the top for linkage.

Write the plan to the output file.
--- END OUTPUT INSTRUCTIONS ---
```

---

### Step 4: Present Plan and Feedback Loop

After the planner agent completes:

1. Read the generated plan from `<infra-plans-dir>/PLAN_PREVIEW_INFRA_<spec-name>.md`
2. Present a structured summary to the user, adapted by experience level:

**Expert:**
Concise summary with phase table:

| Phase | Environment | Blast Radius | Resources | Cost Delta | Depends On |
|-------|-------------|-------------|-----------|------------|------------|
| [N] | [env] | [classification] | [N] create, [N] modify, [N] destroy | [amount] | [phases] |

**Intermediate:**
Phase list with brief descriptions and key decisions:

"**Phase [N]: [title]**
- Environment: [env]
- Blast radius: [classification]
- Resources: [list]
- Rollback checkpoint: [yes/no -- what is checkpointed]
- Cost: [delta]"

**Beginner:**
Narrative walkthrough explaining each phase in plain language, what it does, and why it is ordered this way.

3. Ask: **"Does this plan look right, or would you like to change anything?"**

**If the user approves** (e.g., "looks good", "approved", "yes", "proceed"):
Go to Step 5.

**If the user provides feedback** (e.g., "combine phases 2 and 3", "add a rollback checkpoint before phase 4", "move the DNS change to a separate phase"):
Go to Step 4b.

#### Step 4b: Iterate with Feedback

Invoke a fresh `arn-infra-change-planner` agent via the Task tool with the current plan and user feedback:

```text
You are revising an existing infrastructure implementation plan based on user feedback.

**Current plan file:** <infra-plans-dir>/PLAN_PREVIEW_INFRA_<spec-name>.md
**Spec file:** <infra-specs-dir>/<spec-filename>

--- USER FEEDBACK ---
[user's feedback verbatim]
--- END USER FEEDBACK ---

Read the current plan from the plan file, apply the user's feedback, and write
the updated plan to the same file. Summarize what you changed.
```

After the agent completes, return to Step 4 (read updated plan, present summary, ask for approval).

---

### Step 5: Plan Approved

Confirm with the user:

"Plan approved and saved to `<infra-plans-dir>/PLAN_PREVIEW_INFRA_<spec-name>.md`.

Next step: Run `/arn-infra-save-plan` to convert this plan into a structured project with phased implementation tasks and infrastructure-specific report templates."

---

## Error Handling

- **`## Arness` config missing:** Suggest running `/arn-infra-wizard` to get started. Stop.
- **No change specs found:** Suggest running `/arn-infra-change-spec` first. Stop.
- **Infra plans directory does not exist:** Create it with `mkdir -p`. Continue.
- **Change planner agent fails or crashes:** Read the agent's output to identify what went wrong. If a partial plan was written, present it and ask the user if they want to retry or edit manually: "The planner encountered an issue. A partial plan was written. Would you like me to retry, or would you prefer to edit the partial plan manually?"
- **Change planner returns empty output:** Inform: "The planner could not generate a plan from the specification. This may mean the spec is incomplete. Review the spec and try again, or provide additional context." Offer to re-run `/arn-infra-change-spec` to refine the spec.
- **Agent invocation fails during feedback loop:** Report the error. Offer to retry or let the user edit the plan file manually.
- **PLAN_PREVIEW file not written by agent:** Check the agent output for errors. If the agent produced plan content but did not write it, write the content to the PLAN_PREVIEW file directly and continue.
- **User cancels:** Confirm cancellation. If a PLAN_PREVIEW file was partially written, inform the user of its location so they can delete or edit it manually.
- **Re-running is safe:** Regenerating a plan overwrites the existing PLAN_PREVIEW file after explicit confirmation. The change spec is not modified.
