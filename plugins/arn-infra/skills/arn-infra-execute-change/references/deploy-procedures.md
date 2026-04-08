# Deploy Procedures

Shared deployment procedures for infrastructure apply/deploy operations. This reference is used by both `arn-infra-deploy` (interactive deployment) and `arn-infra-execute-change` (structured pipeline deployment) to avoid duplication of deployment logic.

---

## IaC Apply Commands

### OpenTofu / Terraform

```bash
# 1. Initialize (if not already done)
tofu init
# or: terraform init

# 2. Plan with environment-specific variables and save the plan
tofu plan -var-file=environments/<env>.tfvars -out=deploy-phase-N.tfplan
# or: terraform plan -var-file=environments/<env>.tfvars -out=deploy-phase-N.tfplan

# 3. Apply the saved plan (no additional approval needed -- plan file is exact)
tofu apply deploy-phase-N.tfplan
# or: terraform apply deploy-phase-N.tfplan
```

**Important:** Always apply from a saved plan file. This guarantees the user approved exactly what gets deployed, eliminating plan-apply drift. Never use `-auto-approve` without a saved plan.

**Success indicators:** `Apply complete! Resources: N added, N changed, N destroyed.`
**State location:** Configured in backend block (S3, GCS, Azure Blob, local)

### Pulumi

```bash
# 1. Select the target stack
pulumi stack select <env>

# 2. Preview changes
pulumi preview --stack <env>

# 3. Apply (--yes skips interactive confirmation -- user already confirmed)
pulumi up --stack <env> --yes
```

**Note:** Pulumi does not support saved plan files. The `--yes` flag is used because the user has already confirmed after reviewing the preview output.

**Success indicators:** `update complete` with resource summary
**State location:** Pulumi Cloud, S3 backend, or local file

### CDK (AWS)

```bash
# 1. Synthesize the CloudFormation template
cdk synth

# 2. Diff against currently deployed stack
cdk diff --context env=<env>

# 3. Deploy (--require-approval never -- user already confirmed)
cdk deploy --context env=<env> --require-approval never
```

**Note:** CDK does not support saved plan files. The `--require-approval never` flag is used because the user has already confirmed after reviewing the diff output.

**Success indicators:** Stack ARN output with deployment status
**State location:** CloudFormation stack in AWS

### Bicep (Azure)

```bash
# 1. Preview changes (what-if)
az deployment group what-if \
  --resource-group <rg> \
  --template-file main.bicep \
  --parameters @environments/<env>.parameters.json

# 2. Deploy
az deployment group create \
  --resource-group <rg> \
  --template-file main.bicep \
  --parameters @environments/<env>.parameters.json
```

**Success indicators:** `provisioningState: Succeeded`
**State location:** Azure Resource Manager (ARM) deployment history

### kubectl

```bash
# 1. Diff against current state
kubectl diff -f manifests/<env>/ 2>/dev/null || true
# or: kubectl diff -k environments/<env>/

# 2. Apply manifests
kubectl apply -f manifests/<env>/
# or: kubectl apply -k environments/<env>/

# 3. Wait for rollout
kubectl rollout status deployment/<name> -n <namespace> --timeout=300s
```

**Success indicators:** `deployment.apps/<name> successfully rolled out`
**State location:** Kubernetes API server (etcd)

### Helm

```bash
# 1. Diff against current release
helm diff upgrade <release> <chart> \
  -f values-<env>.yaml \
  --namespace <namespace>

# 2. Install or upgrade
helm upgrade --install <release> <chart> \
  -f values-<env>.yaml \
  --namespace <namespace> \
  --wait --timeout 300s
```

**Success indicators:** `Release "<release>" has been upgraded. Happy Helming!`
**State location:** Kubernetes secrets (Helm release history)

---

## Platform CLI Deploy Commands

### Fly.io

```bash
# Deploy
fly deploy --app <app-name>

# Check status
fly status --app <app-name>

# For specific environment (using Fly apps as environments)
fly deploy --app <app-name>-<env>
```

**Success indicators:** `deployed successfully` or monitoring deployment with health check pass
**Rollback:** `fly releases rollback --app <app-name> --version <N>`

### Railway

```bash
# Deploy
railway up --environment <environment>

# Check status
railway status
```

**Success indicators:** Deployment status showing `active`
**Rollback:** Redeploy previous commit: `git checkout <prev-commit> && railway up`

### Render

```bash
# Deploy (if Render CLI available)
render deploy --service <service-id>

# Or trigger via dashboard -- Render auto-deploys from git push
git push origin main
```

**Success indicators:** Deploy status `Live` in Render dashboard
**Rollback:** Use Render dashboard to rollback to previous deploy

### Vercel

```bash
# Production deploy
vercel --prod

# Preview deploy (non-production)
vercel

# Inspect deployment
vercel inspect <deployment-url>
```

**Success indicators:** Deployment URL with `Ready` status
**Rollback:** `vercel promote <previous-deployment-url>`

### Netlify

```bash
# Production deploy
netlify deploy --prod

# Draft deploy (preview)
netlify deploy

# Check status
netlify status
```

**Success indicators:** `Deploy is live!` with URL
**Rollback:** Netlify dashboard supports instant rollbacks

---

## State Management

### Locking

Before any apply operation, verify the state is not locked:

| Tool | Check Lock | Acquire Lock | Release Lock |
|------|-----------|-------------|-------------|
| OpenTofu/Terraform | Automatic during `tofu plan/apply` | Automatic | Automatic (or `tofu force-unlock <id>`) |
| Pulumi | `pulumi stack export` -- check pending ops | Automatic | `pulumi cancel` for stuck operations |
| CDK | `aws cloudformation describe-stacks` -- check status | Automatic via CloudFormation | Wait for stack to stabilize |

**If locked:** Present lock details and offer to wait (poll every 30s) or force-unlock (with explicit warning about state corruption risk).

### Remote State

Before operations, verify backend connectivity:

```bash
# OpenTofu/Terraform
tofu init -backend=true  # Validates backend config and connectivity

# Pulumi
pulumi whoami  # Verifies Pulumi Cloud connectivity
pulumi stack ls  # Verifies stack access

# CDK
aws sts get-caller-identity  # Verifies AWS credentials
```

If backend is unreachable, stop and report the connectivity issue before attempting any apply.

### Plan-Apply Consistency

For tools that support saved plans (OpenTofu, Terraform):
- **Always** generate a plan file with `-out=<filename>`
- **Always** apply from the saved plan file
- **Never** apply directly without a saved plan (this causes plan-apply drift)

For tools without saved plan support (Pulumi, CDK, platform CLIs):
- Run preview/diff first and present to user
- Apply only after user confirms the preview output
- The `--yes` / `--require-approval never` flags are acceptable because user has already confirmed

---

## Resource Manifest Updates

After successful deployment, update `active-resources.json`:

### New Resources (create action)

Add a new entry per created resource:
```json
{
  "id": "<provider-specific-id>",
  "name": "<resource-name>",
  "type": "<compute|database|storage|...>",
  "provider": "<provider>",
  "environment": "<env>",
  "region": "<region>",
  "createdAt": "<ISO-8601>",
  "lastDeployedAt": "<ISO-8601>",
  "lastVerified": null,
  "ttl": null,
  "costEstimate": { "monthly": <amount>, "currency": "USD" },
  "iacTool": "<tool>",
  "stateLocation": "<state-path>",
  "tags": { "environment": "<env>", "project": "<project>", "managed-by": "arn-infra" },
  "status": "active",
  "endpoints": []
}
```

### Modified Resources (modify action)

Update the existing entry:
- Set `lastDeployedAt` to current timestamp
- Update any changed fields (endpoints, cost estimate, tags)

### Destroyed Resources (destroy action)

Update the existing entry:
- Set `status` to `"destroyed"`
- Destroyed resources remain in the manifest for audit trail

### Summary Recalculation

After all resource updates, recalculate the `summary` object:
- `totalResources`: count of resources with `status === "active"`
- `byEnvironment`: count active resources per environment
- `byProvider`: count active resources per provider
- `totalMonthlyCost`: sum of `costEstimate.monthly` for active resources
- `ephemeralCount`: count of resources with `ttl !== null` and `status === "active"`
- `nextExpiry`: earliest `ttl` among active ephemeral resources
