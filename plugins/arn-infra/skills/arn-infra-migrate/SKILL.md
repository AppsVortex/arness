---
name: arn-infra-migrate
description: >-
  This skill should be used when the user says "migrate infrastructure", "arn infra migrate",
  "infra migrate", "move to AWS", "move to GCP", "move to Azure",
  "switch providers", "change cloud provider", "graduate from PaaS", "move from heroku",
  "move from fly.io", "consolidate providers", "infrastructure migration",
  "provider migration", "partial migration",
  "move database", "move services", "arn-infra-migrate", "infrastructure move",
  "cloud migration", or wants to migrate infrastructure between providers,
  graduate from PaaS to IaC, consolidate providers, or partially move
  specific services.
version: 1.0.0
---

# Arness Infra Migrate

Handle infrastructure migrations as tracked projects with four scenarios: PaaS-to-IaC graduation, provider-to-provider migration, provider consolidation, and partial migration. Creates a parent issue with migration overview and decomposes into individual task issues with dependencies, verification criteria, and rollback procedures.

This skill manages the full migration lifecycle: planning, IaC generation for the target, incremental deployment to staging, verification, cutover, and cleanup. It warns other skills about in-progress migrations to prevent conflicting changes.

## Prerequisites

Read `## Arness` from the project's CLAUDE.md. If no `## Arness` section exists or Arness Infra fields are missing, inform the user: "Arness Infra is not configured for this project yet. Run `/arn-infra-wizard` to get started — it will set everything up automatically." Do not proceed without it.

Check the **Deferred** field. If `Deferred: yes`, inform the user: "Infrastructure is in deferred mode. Migration is not available until infrastructure is fully configured. Run `/arn-infra-assess` to un-defer." Stop.

Extract:
- **Experience level** -- derived from user profile. Read `~/.arness/user-profile.yaml` (or `.claude/arness-profile.local.md` if it exists — project override takes precedence). Apply the experience derivation mapping from `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-ensure-config/references/experience-derivation.md`. If no profile exists, check for legacy `Experience level` in `## Arness` as fallback.
- **Providers** -- current cloud providers
- **Providers config** -- path to `providers.md`
- **Default IaC tool** -- the target IaC tool for graduation migrations
- **Environments** -- environment list for staged migration
- **Environments config** -- path to `environments.md`
- **Issue tracker** -- for creating migration project issues (github, jira, none)
- **Platform** -- for issue management
- **Infra plans directory** -- for migration plan storage (default: `.arness/infra-plans`)
- **Jira site** and **Jira project** -- if Issue tracker is jira

---

## Workflow

### Step 1: Detect Migration Scenario

Ask (using `AskUserQuestion`):

**"What kind of migration are you planning?"**

Options:
1. **Graduate** -- Move from PaaS/platform-native configs to infrastructure-as-code (e.g., `fly.toml` to OpenTofu, Heroku to AWS)
2. **Provider migration** -- Move services from one cloud provider to another (e.g., AWS to GCP, Fly.io to AWS)
3. **Consolidation** -- Reduce the number of providers (e.g., 3 providers to 1-2)
4. **Partial migration** -- Move specific services while keeping others in place (e.g., move just the database to a managed service)

> Read the local override or plugin default for `migration-scenarios.md`.

---

### Step 2: Check for Active Migrations

Read the provider configuration:

```
Read <providers-config-path>
```

Check if any providers have `Migration: <id> (in progress)`:

**If active migration detected:**
Warn: "There is an active migration in progress: [migration-id] affecting [providers/services]. Starting a new migration that overlaps with these services could cause conflicts."

Ask (using `AskUserQuestion`):

**"How would you like to handle the active migration conflict?"**

Options:
1. **Continue anyway** -- Start a new migration (I'll flag potential conflicts)
2. **Wait** -- Complete the current migration first
3. **Cancel current** -- Roll back the current migration and start this one

**If no active migrations:**
Continue to Step 3.

---

### Step 3: Assess Source and Target

Based on the chosen scenario:

**Graduate:**
- Read current PaaS configuration (fly.toml, railway.json, render.yaml, vercel.json, etc.)
- Identify deployed services, databases, and networking
- Determine target provider and IaC tool from `## Arness` config
- Map PaaS features to IaC equivalents (auto-scaling, health checks, SSL, custom domains)

**Provider migration:**
- Read source provider's IaC configs and deployed resources
- Ask for target provider: "Which provider do you want to migrate to?"
- Compare source resources with target provider equivalents
- Identify services that may not have direct equivalents

**Consolidation:**
- List all configured providers with their scopes
- Ask which providers to consolidate into: "You currently use [list]. Which provider(s) do you want to consolidate into?"
- Identify the scope of each provider being removed
- Map services to the consolidation target

**Partial migration:**
- Ask which specific services to migrate: "Which services do you want to move?"
- Identify the target provider/service for each
- Check dependencies between migrating and non-migrating services

---

### Step 4: Create Migration Project

#### 4.1: Generate Migration Plan

Invoke the `arn-infra-specialist` agent via the Task tool with:

--- MIGRATION CONTEXT ---
Scenario: [graduate | provider-migration | consolidation | partial]
Source: [source provider(s) and current configuration]
Target: [target provider(s) and IaC tool]
Services affected: [list of services being migrated]
Environments: [environment promotion order]
--- END MIGRATION CONTEXT ---

--- INSTRUCTIONS ---
Generate a migration plan covering:
1. Target infrastructure definition (IaC for the target provider)
2. Data migration steps (database export/import, file transfer)
3. DNS cutover plan (TTL reduction, record updates)
4. Rollback procedure at each step
5. Service dependency order (which services to migrate first)
6. Estimated timeline per step
--- END INSTRUCTIONS ---

#### 4.2: Get Cost Comparison

Invoke the `arn-infra-cost-analyst` agent via the Task tool with:

--- COST CONTEXT ---
Source infrastructure: [current provider resources and costs]
Target infrastructure: [proposed target resources]
Migration type: [scenario]
--- END COST CONTEXT ---

--- INSTRUCTIONS ---
Compare monthly costs before and after migration:
1. Current cost breakdown by service and provider
2. Projected cost after migration
3. Migration execution costs (data transfer, parallel running period)
4. Net cost change and payback period (if applicable)
--- END INSTRUCTIONS ---

#### 4.3: Present Migration Plan for Approval

Present the migration plan to the user:

"Here is the migration plan:

**Scenario:** [type]
**Source:** [provider(s)]
**Target:** [provider(s)]
**Services affected:** [list]

**Cost comparison:**
| | Current | After Migration | Change |
|------|---------|-----------------|--------|
| Monthly cost | $X | $Y | +/-$Z |

**Migration steps:**
[numbered list of steps with dependencies and estimated duration]

**Rollback plan:**
[summary of rollback strategy]

**Risks:**
[identified risks with mitigation]

Ask (using `AskUserQuestion`):

**"How would you like to proceed with the migration plan?"**

Options:
1. **Approve and create project** -- Create migration issues and start execution
2. **Adjust** -- Modify the plan before creating issues
3. **Cancel** -- Abandon this migration

---

### Step 5: Create Migration Issues

Upon approval, create the migration project in the issue tracker.

**If Issue tracker is `none`:** Skip issue creation (Steps 5.1, 5.2). Record the migration plan in a file at `<infra-plans-dir>/MIGRATION_<name>.md` instead. Mark providers as migrating in providers.md (Step 5.3) and proceed to Step 6.

**5.1: Create parent issue:**

**GitHub:**
```bash
gh issue create \
  --title "Migration: [scenario description]" \
  --label "arn-infra-migration" \
  --body "[migration plan overview: source/target providers, affected services, timeline, risk assessment, cost comparison]"
```

**Jira:**
Use the Atlassian MCP to create an Epic with the migration plan.

For all subsequent issue operations in Steps 5.2, 6.4, 7, 8, and 9: use the Atlassian MCP to perform the equivalent Jira operation (create sub-task, update status, transition to Done, add comment, close Epic).

Record the parent issue number as `migration-id`.

**5.2: Create task issues:**

For each migration step, create a task issue:

**GitHub:**
```bash
gh issue create \
  --title "Migration task: [step description]" \
  --label "arn-infra-migration-task" \
  --body "[step details: source, target, dependencies, verification criteria, rollback procedure]"
```

Link each task issue to the parent issue (reference in body: "Part of #[parent-number]").

**5.3: Mark providers as migrating:**

Update `providers.md` for each affected provider:
- Add `Migration: <migration-id> (in progress)` to the affected provider entries
- This flags the provider for other skills to show migration conflict warnings

---

### Step 6: Execute Migration Steps

> Read the local override or plugin default for `migration-checklist.md`.

Execute migration steps incrementally. For each task:

**6.1: Generate target IaC**

Adapt IaC generation instructions to experience level (beginner: simplified configs with comments, expert: production-ready with minimal comments).

Invoke the `arn-infra-specialist` agent to generate IaC for the target provider/service. Follow the same patterns as `arn-infra-define`: invoke the `arn-infra-specialist` agent via the Task tool with the target provider's IaC tool and patterns reference, scoped to the specific migration task.

**6.2: Deploy to staging**

Deploy the target infrastructure to the staging environment:
- Apply the generated IaC to staging
- Configure data replication if applicable (database sync, file sync)
- Set up parallel running (both source and target active in staging)

**6.3: Verify in staging**

Run verification checks:
- Health check endpoints responding
- Data integrity (record counts, checksums)
- Performance comparison (latency, throughput)
- Feature parity (all functionality works on target)

**6.4: Update task status**

**GitHub:**
```bash
gh issue edit <task-number> --remove-label "arn-infra-migration-task" --add-label "arn-infra-migration-ready"
```

Present: "Migration step [N] verified in staging. Task #[number] is marked as ready."

---

### Step 7: Cutover

When all migration tasks are marked `arn-infra-migration-ready`:

**Pre-cutover checklist:**
- [ ] All migration tasks verified in staging
- [ ] DNS TTL reduced (at least 1 hour before cutover)
- [ ] Monitoring configured for target infrastructure
- [ ] Rollback procedure documented and tested
- [ ] Team notified of cutover window

**Execute cutover:**

Update the parent issue:
```bash
gh issue edit <parent-number> --remove-label "arn-infra-migration" --add-label "arn-infra-migration-cutover"
```

For each migration task (in dependency order):
1. Apply target IaC to production
2. Update DNS records (if applicable)
3. Shift traffic from source to target
4. Update connection strings in application configuration
5. Verify health checks passing on target

**Post-cutover verification:**
- All services healthy on target provider
- No errors in application logs
- Latency and throughput within acceptable ranges
- Data consistency verified

---

### Step 8: Post-Migration Cleanup

On successful cutover:

**8.1: Update providers.md:**
- Remove old provider entry (if fully migrated) or update scope (if partially migrated)
- Remove `Migration: <id>` flags
- Update target provider scope to include migrated services

**8.2: Create cleanup issues:**

For each decommissioned resource on the source provider:
```bash
gh issue create \
  --title "Cleanup: Decommission [resource] on [old provider]" \
  --label "arn-infra-cleanup" \
  --body "Resource [name] on [provider] has been replaced by [target]. Verify no residual traffic, then destroy."
```

**8.3: Close parent issue:**
```bash
gh issue close <parent-number> --comment "Migration complete. All services verified on [target provider]. Cleanup issues created for decommissioning source resources."
```

**8.4: Update CLAUDE.md:**
Update the `## Arness` Providers field if the provider list has changed.

---

### Step 9: Handle Rollback

At any point during the migration, if something goes wrong:

**Rollback procedure:**

1. Revert DNS changes (if cutover was in progress)
2. Redirect traffic back to source provider
3. Update the failed task issue:
   ```bash
   gh issue edit <task-number> --add-label "arn-infra-migration-rollback"
   ```
4. Preserve diagnostics: capture logs, error messages, and the state of both source and target
5. Update the parent issue with rollback details
6. Remove migration flags from `providers.md` if the entire migration is abandoned

Present: "Migration step [N] has been rolled back. Source infrastructure is still active and serving traffic. Diagnostics have been preserved in the task issue."

Ask (using `AskUserQuestion`):

**"What would you like to do next?"**

Options:
1. **Investigate and retry** -- Fix the issue and retry this step
2. **Skip this step** -- Continue with other migration steps (if independent)
3. **Abandon migration** -- Roll back all completed steps and cancel

---

### Step 10: Summarize

**Migration Summary:**
- **Scenario:** [type]
- **Source:** [provider(s)]
- **Target:** [provider(s)]
- **Status:** [completed | in-progress | rolled-back]
- **Parent issue:** [link]
- **Task issues:** [count] created, [count] completed, [count] remaining
- **Cost change:** [before] --> [after] ($[change]/month)
- **Cleanup issues:** [count] created

**Recommended next steps:**

"Migration is [status]. Here is the recommended path:

[If completed:]
1. **Complete cleanup:** Address the cleanup issues to decommission source resources
2. **Verify monitoring:** Run `/arn-infra-monitor` to verify monitoring on the new provider
3. **Update CI/CD:** Run `/arn-infra-pipeline` to update pipelines for the new provider

[If in-progress:]
1. **Continue migration:** Execute the remaining [N] migration tasks
2. **Check status:** Review the parent issue #[number] for progress

[If rolled-back:]
1. **Investigate:** Review the diagnostics in the task issues
2. **Retry:** Fix the identified issues and re-run `/arn-infra-migrate`"

---

## Error Handling

- **`## Arness` config missing:** Suggest running `/arn-infra-wizard` to get started. Stop.
- **No issue tracker configured:** Warn: "Migration projects require an issue tracker (GitHub or Jira) for tracking. The migration plan can be generated without one, but tracked execution requires issues." Offer to proceed without issue tracking (plan-only mode) or suggest configuring an issue tracker via `/arn-infra-init`.
- **Specialist agent fails:** Report the error. Fall back to presenting the migration scenario guidance from the reference file and ask the user to provide the target architecture manually.
- **Specialist agent returns empty output:** Inform the user and retry with additional context. If retry fails, generate a migration plan skeleton with placeholder values.
- **Cost analyst agent fails:** Present the migration plan without cost comparison. Warn: "Cost comparison could not be generated. Review provider pricing manually before committing to the migration."
- **Issue creation fails:** Present the migration plan and issue content in the conversation for the user to create manually. Continue with execution if possible.
- **Active migration conflict:** Present the conflict clearly. Do not allow overlapping migrations on the same services without explicit user acknowledgment.
- **Cutover fails (partial):** Some services may have been migrated while others failed. Present the state clearly: "These services are on the new provider: [list]. These services are still on the old provider: [list]. Rollback options: [per-service options]."
- **Data migration data loss risk:** Always warn when data migration is involved: "Data migration carries risk of data loss. Ensure backups are verified before proceeding."
- **DNS propagation delay:** After DNS cutover, warn: "DNS changes may take up to [TTL] to propagate globally. Both source and target should remain active during this period."
- **Re-running is safe:** Re-running detects the active migration project and offers to continue execution from the current state. It does not create duplicate issues or restart completed steps.
