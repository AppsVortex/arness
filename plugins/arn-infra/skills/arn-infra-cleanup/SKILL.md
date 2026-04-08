---
name: arn-infra-cleanup
description: >-
  This skill should be used when the user says "cleanup", "infra cleanup",
  "arn infra cleanup", "clean up resources", "destroy expired resources",
  "check ttl", "check expired", "ttl cleanup", "remove old deployments",
  "destroy dev environment", "tear down", "teardown infra", "destroy resources",
  "cleanup ephemeral", "check for expired resources", "clean up infra",
  "resource cleanup", "destroy old resources", "prune resources",
  "delete expired deployments", "decommission", or wants to check for and
  destroy expired ephemeral infrastructure resources. This skill also supports periodic
  monitoring via `/loop 6h /arn-infra-cleanup` for
  session-duration TTL enforcement.
version: 1.0.0
---

# Arness Infra Cleanup

Check for expired ephemeral infrastructure resources across three TTL sources (issue tracker, TTL registry, resource manifest) and destroy them with user confirmation. Supports periodic monitoring via `/loop` for session-duration TTL enforcement.

This skill never auto-destroys resources. Every destruction requires explicit user confirmation with a summary of what will be destroyed and its associated cost.

## Prerequisites

Read `## Arness` from the project's CLAUDE.md. If no `## Arness` section exists or Arness Infra fields are missing, inform the user: "Arness Infra is not configured for this project yet. Run `/arn-infra-wizard` to get started — it will set everything up automatically." Do not proceed without it.

Check the **Deferred** field. If `Deferred: yes`, inform the user: "Infrastructure is in deferred mode. Cleanup is not available until infrastructure is fully configured. Run `/arn-infra-assess` to un-defer." Stop.

Extract:
- **Experience level** -- derived from user profile. Read `~/.arness/user-profile.yaml` (or `.claude/arness-profile.local.md` if it exists — project override takes precedence). Apply the experience derivation mapping from `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-ensure-config/references/experience-derivation.md`. If no profile exists, check for legacy `Experience level` in `## Arness` as fallback.
- **Providers** -- which cloud providers are configured
- **Providers config** -- path to `providers.md`
- **Default IaC tool** -- for determining destroy commands
- **Environments** -- environment names in promotion order
- **Environments config** -- path to `environments.md` for per-environment deployment state
- **Resource manifest** -- path to `active-resources.json` for resource inventory
- **Reference overrides** -- path to local reference override directory (for evolving reference reads)
- **Platform** -- for issue tracker access
- **Issue tracker** -- for reading cleanup issues and updating labels
- **Tooling manifest** -- path to `tooling-manifest.json` for available CLIs

---

## Workflow

### Step 1: Scan TTL Sources

Check all three TTL sources in priority order. Collect a unified list of resources with expired or near-expiry TTLs.

**Source 1: Issue Tracker (highest priority)**

If issue tracking is configured (Platform is github or Issue tracker is jira):

For GitHub:
```bash
gh issue list --label "arn-infra-cleanup" --state open --json number,title,body,createdAt
```

For Jira:
Query issues with label `arn-infra-cleanup` in the configured Jira project.

Parse each cleanup issue:
- Extract TTL expiry timestamp from the issue body (set by `arn-infra-deploy` during ephemeral deployments)
- Extract resource identifiers and destroy commands from the issue body
- Determine if the TTL has expired (expiry timestamp < current time)
- Determine if the TTL is approaching (within 1 hour of expiry) for early warning

**Source 2: TTL Registry (secondary)**

Check for the TTL registry file:

```
Read .arness/infra/ttl-registry.md
```

If the file exists, parse resource entries with their TTL timestamps. The TTL registry is a fallback for environments without issue tracking or for resources created outside the normal deployment flow.

Expected format:
```markdown
# TTL Registry

| Resource | Environment | Provider | Created | TTL Expiry | Destroy Command |
|----------|-------------|----------|---------|------------|-----------------|
| [name] | [env] | [provider] | [timestamp] | [expiry] | [command] |
```

**Source 3: Resource Manifest (tertiary)**

Read the resource manifest:

```
Read <resource-manifest-path>
```

Filter resources where:
- `ttl` is not null
- `ttl` timestamp is in the past (expired)
- `status` is `active` (not already destroyed)

---

### Step 2: Compile Expired Resource List

Merge results from all three sources, deduplicating by resource ID. For each expired resource, compile:

- Resource name and type
- Provider and region
- Environment
- Created timestamp
- TTL expiry timestamp (how long ago it expired)
- Estimated cost since creation (calculate: `monthly_cost × (hours_since_creation / 730)`)
- Destroy command (IaC-tool-appropriate)
- Source (which TTL source identified this resource)

**If no expired resources are found:**

Present: "No expired resources found. All TTLs are current."

If there are resources with TTLs approaching expiry (within 1 hour), list them as early warnings:
"The following resources will expire soon:
- [resource]: expires in [time remaining]"

Stop here (or if running via `/loop`, wait for the next interval).

**If expired resources are found:**

Continue to Step 3.

---

### Step 3: Present Expired Resources for Confirmation

Present each expired resource group (grouped by environment):

"The following resources have expired TTLs and are candidates for cleanup:

**Environment: [env]**

| Resource | Type | Provider | Expired | Cost Since Creation | Destroy Command |
|----------|------|----------|---------|--------------------| --------------- |
| [name] | [type] | [provider] | [time since expiry] | $[amount] | [command] |

**Total cost of expired resources:** $[total] (estimated charges since TTL expired)

Ask (using `AskUserQuestion`):

**"How would you like to handle the expired resources?"**

Options:
1. **Destroy all** -- Destroy all expired resources listed above
2. **Select** -- Choose which resources to destroy
3. **Extend TTL** -- Extend the TTL for some or all resources
4. **Skip** -- Do not destroy anything right now

**NEVER auto-destroy without confirmation.** Even when running via `/loop`, each cleanup cycle must ask for confirmation before destroying anything.

---

### Step 4: Execute Destruction

For each confirmed resource, execute the appropriate destroy command.

> Read the local override or plugin default for `rollback-patterns.md`.

**Destroy commands by IaC tool:**

| IaC Tool | Destroy Command |
|----------|----------------|
| OpenTofu | `tofu destroy -target=<resource> -var-file=environments/<env>.tfvars` |
| Terraform | `terraform destroy -target=<resource> -var-file=environments/<env>.tfvars` |
| Pulumi | `pulumi destroy --target <urn> --stack <env> --yes` |
| CDK | `cdk destroy --context env=<env>` |
| Bicep | `az resource delete --ids <resource-id>` |
| kubectl | `kubectl delete <resource-type> <name> -n <namespace>` |
| Helm | `helm uninstall <release> -n <namespace>` |
| Fly.io | `fly apps destroy <app-name> --yes` |
| Railway | `railway down` or delete via dashboard |
| Vercel | `vercel remove <project> --yes` |
| Netlify | `netlify sites:delete --id <site-id>` |
| Render | Delete via Render dashboard |

**For targeted IaC destruction (OpenTofu/Terraform):**

When destroying specific resources from a larger state file, use `-target` to avoid destroying the entire environment:
```bash
tofu destroy -target=module.<module>.<resource_type>.<name> -var-file=environments/<env>.tfvars
```

**For full environment teardown:**
If all resources in an environment are expired, offer full environment destruction:
```bash
tofu destroy -var-file=environments/<env>.tfvars
```

**Important:** Always ask for confirmation before executing destroy commands. Show the exact command that will be run.

---

### Step 5: Update Tracking

After successful destruction:

**5a. Update resource manifest:**
- Set `status` to `destroyed` for each destroyed resource
- Update `lastUpdated` timestamp
- Recalculate the summary section

**5b. Close/update cleanup issues:**
If the resource was tracked via an issue:
- For GitHub: close the issue with a comment "Resources destroyed by arn-infra-cleanup at [timestamp]"
  ```bash
  gh issue close <number> --comment "Resources destroyed by arn-infra-cleanup at [timestamp]."
  ```
- For Jira: transition the issue to Done/Closed

**5c. Update TTL registry:**
If the resource was tracked in `.arness/infra/ttl-registry.md`, remove the entry or mark it as destroyed.

**5d. Update Environments config:**
If all resources in an environment were destroyed (read from the Environments config path extracted in Prerequisites):
- Reset the environment entry: `Last deployed: --`, `Pending changes: none`

---

### Step 6: TTL Extension (if selected in Step 3)

If the user chose to extend TTL for some resources:

Ask: "How long would you like to extend the TTL? (e.g., 2h, 24h, 7d)"

For each selected resource:
1. Calculate new expiry timestamp (current time + extension duration)
2. Update `ttl` field in `active-resources.json`
3. Update the cleanup issue body with the new expiry (if issue-tracked)
4. Update TTL registry entry (if registry-tracked)

Present: "TTL extended for [N] resources. New expiry: [timestamp]. The next cleanup check will re-evaluate these resources."

---

### Step 7: Summarize

Present the cleanup summary:

"**Cleanup Summary:**
- **Resources destroyed:** [N]
- **Resources extended:** [N]
- **Resources skipped:** [N]
- **Estimated savings:** $[amount]/month (freed monthly cost)
- **Issues closed:** [N]

**Files updated:**
- [list all files modified]

**Remaining TTLs:**
- [resource]: expires [timestamp]
- [resource]: expires [timestamp]

**Periodic monitoring:**
To automatically check for expired resources, use:
`/loop 6h /arn-infra-cleanup`

This will check TTLs every 6 hours during the current session and prompt for cleanup when resources expire."

---

## /loop Support

This skill supports periodic execution via the `/loop` command:

```
/loop 6h /arn-infra-cleanup
```

When running in loop mode:
1. Each iteration runs Steps 1-2 (scan and compile)
2. If no expired resources: silently continues to the next interval (no output)
3. If expired resources found: presents the list and asks for confirmation (Step 3)
4. After confirmation (destroy/extend/skip): continues to the next interval
5. **NEVER auto-destroys.** Even in loop mode, destruction requires explicit confirmation.

Recommended loop intervals:
- **Development environments:** 1-2 hours (short-lived ephemeral deployments)
- **Staging environments:** 6 hours (standard monitoring)
- **Mixed environments:** 4-6 hours (balanced check frequency)

---

## Error Handling

- **`## Arness` config missing:** Suggest running `/arn-infra-wizard` to get started. Stop.
- **No TTL sources available:** If there is no issue tracker, no TTL registry, and no resource manifest, inform the user: "No TTL tracking is configured. Deploy ephemeral resources with `/arn-infra-deploy` (which creates cleanup issues) or manually add resources to `.arness/infra/ttl-registry.md`." Stop.
- **Resource manifest missing:** Check other TTL sources (issues, registry). If found, proceed with those. If the manifest should exist, warn: "Resource manifest not found at [path]. Resource tracking may be incomplete."
- **Issue tracker unavailable:** Skip Source 1, proceed with Sources 2 and 3. Note: "Issue tracker was not reachable. Checking TTL registry and resource manifest only."
- **Destroy command fails:** Report the error with the full error output. Offer to retry or skip. Do NOT mark the resource as destroyed if the destroy command failed. Update the issue/registry with the failure.
- **Destroy partially succeeds (multi-resource teardown):** Report which resources were destroyed and which failed. Update tracking for successful destructions only. Present the failures for manual intervention.
- **State lock prevents destruction:** If the IaC state is locked, warn: "Cannot destroy resources -- state is locked by [details]. Wait for the lock to release or force-unlock." Never force-unlock without user confirmation.
- **Resource already destroyed (outside of Arness):** If a resource listed in the manifest no longer exists at the provider, mark it as `destroyed` in the manifest and close any associated cleanup issue. Inform the user: "[resource] was already destroyed (possibly manually or by another process)."
- **TTL registry file does not exist:** Skip Source 2 silently. The TTL registry is optional.
- **Re-running is safe:** Re-running scans all TTL sources again. Already-destroyed resources are skipped (status is `destroyed` in manifest). Closed issues are filtered out by the open-issues query.
