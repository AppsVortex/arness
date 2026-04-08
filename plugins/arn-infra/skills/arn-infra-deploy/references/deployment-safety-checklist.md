# Deployment Safety Checklist

Pre-deployment gates that must be evaluated before any infrastructure deployment. Each gate has a status (PASS, WARN, FAIL, SKIP) and determines whether deployment can proceed. Critical gates block deployment; warning gates require acknowledgment.

---

## Gate 1: IaC Validation (Critical)

**What it checks:** Has the infrastructure-as-code been validated through the validation ladder?

**How to verify:**
- Check for IaC files in the project (`.tf`, `Pulumi.*`, `cdk.json`, `*.bicep`, `fly.toml`, etc.)
- Check if `arn-infra-define` has been run (look for `INFRA_*.md` in the Infra specs directory)
- Check if the validation ladder passed (Level 0 minimum)

**Status logic:**
- **PASS:** IaC files exist and validation has been run
- **WARN:** IaC files exist but no evidence of validation -- suggest running `/arn-infra-define`
- **FAIL:** No IaC files found -- deployment cannot proceed without infrastructure code
- **SKIP:** PaaS deployment (beginner path) -- platform-native configs do not require IaC validation

**Blocks deployment if:** FAIL

---

## Gate 2: Security Scan (Warning)

**What it checks:** Has a security scan been performed on the IaC code?

**How to verify:**
- Check validation ceiling from `## Arness` config
- If ceiling >= 2: check for security scan results from the define step
- If ceiling < 2: skip this gate (user opted out of security scanning)

**Status logic:**
- **PASS:** Security scan completed with no Critical or High findings
- **WARN:** Security scan completed but High findings remain unresolved
- **FAIL:** Security scan found Critical findings that were not remediated
- **SKIP:** Validation ceiling < 2 (security scanning not configured)

**Blocks deployment if:** FAIL (Critical findings)

---

## Gate 3: Cost Estimation (Warning)

**What it checks:** Does the estimated deployment cost fit within the configured budget threshold?

**How to verify:**
- Read cost threshold from `## Arness` config
- Check for cost estimation results (from define step Level 2 validation or manual estimate)
- Compare estimated monthly cost against the threshold

**Status logic:**
- **PASS:** Cost estimate is below the threshold
- **WARN:** Cost estimate is within 80-100% of the threshold
- **FAIL:** Cost estimate exceeds the threshold
- **SKIP:** Cost threshold is set to "none" (disabled)

**Blocks deployment if:** Never blocks -- but FAIL requires explicit acknowledgment. Present: "The estimated cost ($X/month) exceeds your configured threshold ($Y/month). Do you want to proceed anyway?"

**Cost gate acknowledgment format:**
"I understand that this deployment will cost approximately $X/month, which exceeds my configured threshold of $Y/month. Proceed."

---

## Gate 4: State Lock Check (Critical)

**What it checks:** Is the IaC state locked by another deployment?

**Applicable to:** OpenTofu, Terraform, Pulumi, CDK (tools that maintain deployment state)
**Not applicable to:** PaaS platforms (Fly.io, Railway, Render, Vercel, Netlify), raw kubectl

**How to verify:**
- OpenTofu/Terraform: check for `.terraform.lock.hcl` and state lock in backend (S3 DynamoDB, GCS, Azure Blob)
- Pulumi: check `pulumi stack export` for pending operations
- CDK: check CloudFormation stack status for `UPDATE_IN_PROGRESS` or `CREATE_IN_PROGRESS`

**Status logic:**
- **PASS:** State is not locked, no concurrent operations
- **FAIL:** State is locked by another operation
- **SKIP:** Not applicable for the current IaC tool

**Blocks deployment if:** FAIL

**Recovery options:**
1. **Wait:** Poll every 30 seconds until the lock is released
2. **Force unlock:** `tofu force-unlock <lock-id>` / `terraform force-unlock <lock-id>` -- WARNING: only use if the locking operation has failed and left a stale lock. Force-unlocking an active deployment causes state corruption.

---

## Gate 5: Rollback Plan (Warning)

**What it checks:** Is a rollback strategy available for the target environment?

**How to verify:**
- Check for previous deployment state (state file, previous version, last known good config)
- Verify rollback commands are available for the IaC tool in use
- For first deployments: rollback means full destroy (verify destroy commands)

**Status logic:**
- **PASS:** Previous state available and rollback commands verified
- **WARN:** First deployment to this environment -- rollback means destroy all resources
- **FAIL:** No rollback strategy available (state corrupted or missing)

**Blocks deployment if:** Never blocks -- but FAIL generates a strong warning. Present: "No rollback strategy is available for this deployment. If the deployment fails, manual intervention will be required."

---

## Gate 6: Pending Changes Diff (Informational)

**What it checks:** What will change compared to the current deployed state?

**How to generate:**
- OpenTofu/Terraform: `tofu plan -var-file=environments/<env>.tfvars`
- Pulumi: `pulumi preview --stack <env>`
- CDK: `cdk diff --context env=<env>`
- Bicep: `az deployment group what-if`
- PaaS: diff current config against deployed config (e.g., `fly config show` vs local `fly.toml`)

**Present to user:**
```
Resources to create: N
Resources to modify: N
Resources to destroy: N

Detailed changes:
+ [resource type] [name] (create)
~ [resource type] [name] (modify: [fields changing])
- [resource type] [name] (destroy)
```

**Blocks deployment if:** Never blocks -- but destructive changes (destroy) always require explicit confirmation: "This deployment will DESTROY [N] resources: [list]. This action cannot be undone. Confirm?"

---

## Checklist Summary Format

Present the checklist to the user before deployment proceeds:

```
Pre-deployment checklist for [environment]:

[PASS] IaC validation: Level [N] passed
[WARN] Security scan: 2 High findings (acknowledged)
[PASS] Cost estimate: $45/month (threshold: $100/month)
[PASS] State lock: No active locks
[PASS] Rollback plan: Previous state available
[INFO] Changes: 5 create, 2 modify, 0 destroy

All critical gates passed. Proceed with deployment? [Yes / No]
```

If any critical gate is FAIL, deployment is blocked:

```
Pre-deployment checklist for [environment]:

[FAIL] IaC validation: No infrastructure code found
[SKIP] Security scan: Skipped (no IaC to scan)
[SKIP] Cost estimate: Skipped (no IaC to estimate)
[PASS] State lock: No active locks
[WARN] Rollback plan: First deployment (rollback = destroy)
[SKIP] Changes: Cannot compute (no IaC)

BLOCKED: 1 critical gate failed. Resolve before deploying.
Action: Run /arn-infra-define to generate infrastructure code.
```

---

## Environment-Specific Gate Adjustments

### Development Environment
- Security scan: SKIP (unless explicitly requested)
- Cost gate: relaxed (warn at 150% of threshold instead of 100%)
- Rollback plan: SKIP (dev environments are disposable)

### Staging Environment
- All gates active
- CI/CD recommendation (not enforcement) for first staging deployment
- CI/CD enforcement for subsequent staging deployments if pipelines exist

### Production Environment
- All gates active with stricter thresholds
- CI/CD strongly recommended (warning if deploying locally)
- Cost gate: strict (warn at 80% of threshold)
- Rollback plan: REQUIRED (FAIL if no rollback strategy)
- Pending changes: destructive changes require double confirmation
