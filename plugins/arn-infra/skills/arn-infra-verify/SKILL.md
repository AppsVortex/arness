---
name: arn-infra-verify
description: >-
  This skill should be used when the user says "verify deployment", "verify infra",
  "check deployment", "arn infra verify", "infra verify", "health check",
  "check health", "verify staging", "verify production", "is my deployment healthy",
  "check if deployment worked", "run health checks", "deployment verification",
  "check infrastructure", "validate deployment", "verify environment",
  "post-deployment check", "infra health", "check dns", "check ssl",
  "verify endpoints", "smoke test", "integration test",
  or wants to validate that a deployed environment is healthy
  and its resources match the expected state. This skill runs health checks,
  DNS verification, SSL validation, resource state comparison, and updates
  issue labels and environments.md with verification results.
version: 1.0.0
---

# Arness Infra Verify

Run post-deployment verification against a target environment to confirm that infrastructure is healthy, endpoints are reachable, DNS resolves correctly, SSL certificates are valid, and resource state matches the expected topology. Updates issue labels and environments.md with verification results.

This skill invokes the `arn-infra-verifier` agent to perform the actual health checks and produces a structured verification report.

## Prerequisites

Read `## Arness` from the project's CLAUDE.md. If no `## Arness` section exists or Arness Infra fields are missing, inform the user: "Arness Infra is not configured for this project yet. Run `/arn-infra-wizard` to get started — it will set everything up automatically." Do not proceed without it.

Check the **Deferred** field. If `Deferred: yes`, inform the user: "Infrastructure is in deferred mode. Verification is not available until infrastructure is fully configured. Run `/arn-infra-assess` to un-defer." Stop.

Extract:
- **Experience level** -- derived from user profile. Read `~/.arness/user-profile.yaml` (or `.claude/arness-profile.local.md` if it exists — project override takes precedence). Apply the experience derivation mapping from `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-ensure-config/references/experience-derivation.md`. If no profile exists, check for legacy `Experience level` in `## Arness` as fallback.
- **Environments** -- environment names for target selection
- **Environments config** -- path to `environments.md` for deployment state
- **Resource manifest** -- path to `active-resources.json` for expected resource state
- **Tooling manifest** -- path to `tooling-manifest.json` for available CLIs
- **Providers** -- which cloud providers are configured
- **Providers config** -- path to `providers.md`
- **Platform** -- for issue label management
- **Issue tracker** -- for label updates and issue lifecycle
- **Infra specs directory** -- from `## Arness` config, for locating handoff files (default: `.arness/infra-specs`)
- **Reference overrides** -- path to local reference override directory (for evolving reference reads)

---

## Workflow

### Step 1: Determine Target Environment

Ask the user which environment to verify (if not specified in the invocation):

"Which environment would you like to verify? [list environments from config]"

Read the environment's deployment state from `environments.md`:
- **Last deployed:** timestamp of the most recent deployment
- If `Last deployed` is `--` (never deployed): inform the user: "The [environment] environment has not been deployed yet. Run `/arn-infra-deploy` first." Stop.

---

### Step 2: Gather Expected State

Collect the expected state from multiple sources:

**2a. Resource manifest:**

Read the resource manifest (`active-resources.json`):

```
Read <resource-manifest-path>
```

Filter resources for the target environment. Extract:
- Resource IDs and types
- Expected endpoints (URLs, DNS names)
- Health check paths
- Provider and region information

**2b. Handoff file:**

Look for the handoff file for the target environment:

```
Glob <specs-dir>/INFRA_HANDOFF_<environment>*
```

If found, read it and extract:
- Endpoint URLs and health check paths
- Expected connection string references (for connectivity verification)
- Monitoring endpoints

**2c. INFRA spec:**

Look for the infrastructure architecture spec:

```
Glob <specs-dir>/INFRA_*
```

If found, read it for the expected resource topology (resource types, counts, configurations).

**If no expected state is available:**
Warn: "No resource manifest or handoff file found for [environment]. I can still run basic health checks if you provide endpoint URLs. Would you like to provide URLs manually, or run `/arn-infra-deploy` first?"

If the user provides URLs manually, proceed with those as the expected state.

---

### Step 3: Invoke Verifier Agent

> Read the local override or plugin default for `health-check-patterns.md`.

Invoke the `arn-infra-verifier` agent via the Task tool with:

--- EXPECTED STATE ---
Resources: [filtered resource manifest for the target environment]
Endpoints: [list of endpoints with health check paths]
DNS names: [list of DNS names with expected targets]
SSL domains: [list of HTTPS domains requiring certificate validation]
--- END EXPECTED STATE ---

--- PROVIDER CONTEXT ---
Provider(s): [from providers.md]
Available CLIs: [from tooling manifest -- which CLIs can query resource state]
Environment: [target environment name]
--- END PROVIDER CONTEXT ---

--- TOOLING ---
Available tools: [list of installed verification tools from tooling manifest]
curl: [available/unavailable]
dig/nslookup: [available/unavailable]
openssl: [available/unavailable]
Provider CLIs: [list with auth status]
--- END TOOLING ---

--- INSTRUCTIONS ---
Run the following verification checks in order:

1. HTTP health checks on all endpoints
2. DNS resolution for all configured domains
3. SSL/TLS certificate validation for all HTTPS endpoints
4. Resource state comparison against the expected state using available provider CLIs
5. Database connectivity verification (if database endpoints are configured)
6. Environment variable injection verification (check that required env vars are set in the deployed application)

Produce a structured verification report with overall PASS/WARN/FAIL verdict.
--- END INSTRUCTIONS ---

---

### Step 4: Process Verification Results

Read the verification report from the agent. Parse the overall status: PASS, WARN, or FAIL.

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-verify/references/verification-report-template.md` for the expected report format.

**On PASS:**

1. Present the verification results to the user:
   "Verification PASSED for [environment]. All health checks, DNS, SSL, and resource state checks succeeded."

2. Update issue labels (if issue tracking is configured):
   - Add label `arn-infra-verified`
   - Remove label `arn-infra-failed` (if present from a previous failed attempt)
   - If this is a **production** environment AND the deployment issue exists: close the issue with a comment "Production deployment verified successfully."

3. Update `active-resources.json`:
   - Set `lastVerified` to the current ISO 8601 timestamp for all resources in the target environment

4. Update `environments.md`:
   - Add verification result under the target environment entry:
     ```
     - **Last verified:** [ISO 8601 timestamp]
     - **Verification status:** PASS
     ```

**On WARN:**

1. Present the verification results with warnings:
   "Verification completed with WARNINGS for [environment]. The deployment is functional but the following issues were detected: [list warnings]."

2. Update issue labels:
   - Add label `arn-infra-verified` (functional despite warnings)
   - Add a comment to the issue listing the warnings

3. Update `active-resources.json`:
   - Set `lastVerified` to the current timestamp

4. Update `environments.md`:
   - Add verification result:
     ```
     - **Last verified:** [ISO 8601 timestamp]
     - **Verification status:** WARN ([summary])
     ```

**On FAIL:**

1. Present the verification results with failures:
   "Verification FAILED for [environment]. The following critical checks failed: [list failures]."

2. Categorize failures:
   - **Critical:** service down, endpoints unreachable, SSL expired, DNS not resolving
   - **Warning:** slow response times, certificate expiring soon, minor resource drift
   - **Info:** non-critical differences from expected state

3. Suggest remediation for each failure:
   - Endpoint unreachable: "Check if the service is running. Review deployment logs."
   - DNS not resolving: "Check DNS configuration. Allow up to 48h for propagation."
   - SSL invalid: "Check certificate configuration. Renew if expired."
   - Resource missing: "Resource may have been deleted outside of IaC. Run `/arn-infra-deploy` to reconcile."
   - Resource drift: "Resource configuration differs from expected. Run `/arn-infra-define` and re-deploy."

   Adapt remediation detail to experience level:
   - **Beginner:** Provide step-by-step remediation commands with explanations.
   - **Expert:** Provide summary of failures and expected fix actions only.

4. Update issue labels:
   - Add label `arn-infra-failed`
   - Remove label `arn-infra-verified` (if present)
   - Add a comment with the failure details and remediation steps

5. Update `environments.md`:
   - Add verification result:
     ```
     - **Last verified:** [ISO 8601 timestamp]
     - **Verification status:** FAIL ([failure summary])
     ```

6. Do NOT update `lastVerified` in `active-resources.json` (verification did not pass)

7. Offer remediation options:

   Ask (using `AskUserQuestion`):

   **"How would you like to handle the verification failures?"**

   Options:
   1. **Rollback** -- Roll back to the previous deployment using `/arn-infra-deploy` rollback procedures
   2. **Re-deploy** -- Fix the issues and re-deploy with `/arn-infra-deploy`
   3. **Investigate** -- Examine the failures in more detail
   4. **Ignore** -- Accept the current state (not recommended for staging/production)

---

### Step 5: Summarize and Recommend Next Steps

Present the verification summary:

"**Verification Summary:**
- **Environment:** [name]
- **Overall status:** [PASS / WARN / FAIL]
- **Health checks:** [N passed, N failed]
- **DNS verification:** [N passed, N failed]
- **SSL validation:** [N passed, N failed]
- **Resource state:** [N matched, N drifted, N missing]
- **Timestamp:** [ISO 8601]

**Files updated:**
- [list all files modified]

**Recommended next steps:**

[If PASS:]
1. **Promote:** Run `/arn-infra-deploy` targeting the next environment in the pipeline
2. **Set up monitoring:** Run `/arn-infra-monitor` to configure observability
3. **Set up CI/CD:** Run `/arn-infra-pipeline` to automate future deployments

[If WARN:]
1. **Address warnings:** Review the warnings and fix non-critical issues
2. **Re-verify:** Run `/arn-infra-verify` again after addressing warnings
3. **Promote with caution:** The deployment is functional but has minor issues

[If FAIL:]
1. **Fix failures:** Address the critical failures listed above
2. **Rollback:** Run rollback procedures if the environment is unusable
3. **Re-deploy:** Fix and re-deploy with `/arn-infra-deploy`
4. **Re-verify:** Run `/arn-infra-verify` after fixes

Or run `/arn-infra-wizard` for the full guided pipeline."

---

## Error Handling

- **`## Arness` config missing:** Suggest running `/arn-infra-wizard` to get started. Stop.
- **Environment never deployed:** Inform the user and suggest running `/arn-infra-deploy`. Stop.
- **No resource manifest or handoff file:** Offer manual endpoint entry or suggest deploying first. If the user provides endpoints, run basic HTTP/DNS/SSL checks only (skip resource state comparison).
- **Verifier agent fails:** Fall back to running basic health checks directly (curl for HTTP, dig for DNS, openssl for SSL). Report partial results with a note: "Full verification could not be completed. Running basic checks only."
- **Verifier agent returns empty output:** Inform the user and offer to retry. If retry fails, fall back to basic checks.
- **Provider CLI not available for resource state comparison:** Skip resource state checks. Note in the report: "Resource state comparison skipped -- [CLI] not available. Install via `/arn-infra-discover`."
- **DNS propagation in progress:** If DNS checks fail but the deployment is recent (within the last hour), note: "DNS changes may still be propagating. Re-run verification in 30-60 minutes."
- **SSL certificate not yet issued:** If SSL checks fail for a new deployment, note: "SSL certificate may still be provisioning. For Let's Encrypt, this typically takes 1-5 minutes. Re-run verification shortly."
- **Issue tracker unavailable:** Skip label updates. Log verification results in environments.md only.
- **Re-running is safe:** Re-running overwrites the previous verification results in environments.md and updates `lastVerified` in the resource manifest. Issue labels are updated idempotently.
