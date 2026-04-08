# Rollback Patterns

Per-IaC-tool rollback procedures for infrastructure deployments. Each pattern covers the rollback command, state management, data preservation, and common failure modes.

---

## Rollback Strategy Overview

There are three levels of rollback severity:

| Level | Action | When to Use |
|-------|--------|-------------|
| **Revert** | Apply the previous version of the IaC code | Config change broke something, code is the problem |
| **State rollback** | Restore a previous state snapshot | Deployment partially applied, state is inconsistent |
| **Destroy and recreate** | Destroy all resources and re-deploy from scratch | Unrecoverable state corruption, full environment reset |

Always attempt rollback levels in order: Revert first, then state rollback, then destroy-and-recreate as a last resort.

---

## OpenTofu / Terraform

### Revert (Recommended)

```bash
# 1. Check out the previous version of the IaC code
git checkout HEAD~1 -- infra/

# 2. Re-plan with the reverted code
tofu plan -var-file=environments/<env>.tfvars -out=rollback.tfplan

# 3. Review the plan (it should show reverting changes)
# 4. Apply the rollback plan
tofu apply rollback.tfplan
```

### State Rollback

```bash
# 1. List state history (if using S3/GCS backend with versioning)
# S3: aws s3api list-object-versions --bucket <bucket> --prefix <key>
# GCS: gsutil ls -la gs://<bucket>/<key>

# 2. Download the previous state version
# S3: aws s3api get-object --bucket <bucket> --key <key> --version-id <id> previous.tfstate
# GCS: gsutil cp gs://<bucket>/<key>#<generation> previous.tfstate

# 3. Replace current state (DANGEROUS - backup first)
tofu state pull > backup-current.tfstate
tofu state push previous.tfstate

# 4. Plan and apply to reconcile
tofu plan -var-file=environments/<env>.tfvars
tofu apply -var-file=environments/<env>.tfvars
```

### Destroy and Recreate

```bash
# 1. Destroy all resources in the environment
tofu destroy -var-file=environments/<env>.tfvars

# 2. Confirm destruction is complete
tofu show  # Should show empty state

# 3. Re-apply from known good code
git checkout <known-good-commit> -- infra/
tofu apply -var-file=environments/<env>.tfvars
```

### Common Failure Modes

| Failure | Cause | Resolution |
|---------|-------|------------|
| State lock timeout | Previous apply crashed | `tofu force-unlock <lock-id>` (verify no active apply first) |
| Resource already exists | Manual creation outside IaC | `tofu import <resource-type>.<name> <id>` |
| Dependency cycle | Circular resource references | Remove the cycle in code, apply incrementally |
| Provider auth expired | Token/session expired mid-apply | Re-authenticate and retry |

---

## Pulumi

### Revert

```bash
# 1. Check out the previous version of the Pulumi code
git checkout HEAD~1 -- infra/

# 2. Preview the rollback
pulumi preview --stack <env>

# 3. Apply the rollback
pulumi up --stack <env>
```

### State Rollback

```bash
# 1. Export current state as backup
pulumi stack export --stack <env> > backup-state.json

# 2. List deployment history
pulumi stack history --stack <env>

# 3. Pulumi does not natively support state rollback to a previous deployment.
# Instead, use the revert approach (checkout previous code and re-apply).
# If state is corrupted, contact Pulumi support or manually edit the exported state.

# 4. For corrupted resources, refresh state from cloud
pulumi refresh --stack <env>
```

### Destroy and Recreate

```bash
# 1. Destroy all resources
pulumi destroy --stack <env> --yes

# 2. Verify empty state
pulumi stack export --stack <env>  # Should show no resources

# 3. Re-deploy from known good code
git checkout <known-good-commit> -- infra/
pulumi up --stack <env>
```

### Common Failure Modes

| Failure | Cause | Resolution |
|---------|-------|------------|
| Pending operations | Previous up/destroy interrupted | `pulumi cancel --stack <env>` then `pulumi refresh` |
| Import conflict | Resource exists but not in state | `pulumi import <type> <name> <id>` |
| Plugin version mismatch | SDK version differs from state | `pulumi plugin install` and retry |

---

## CDK (AWS)

### Revert

```bash
# 1. Check out the previous version of the CDK code
git checkout HEAD~1 -- infra/

# 2. Synthesize and diff
cdk synth
cdk diff --context env=<env>

# 3. Deploy the rollback
cdk deploy --context env=<env>
```

### State Rollback

CDK uses CloudFormation stacks as state. CloudFormation supports rollback natively:

```bash
# 1. Check stack status
aws cloudformation describe-stacks --stack-name <stack>

# 2. If stack is in UPDATE_ROLLBACK_FAILED:
aws cloudformation continue-update-rollback --stack-name <stack>

# 3. If stack is in a good state but the deployment was wrong:
# Use the revert approach (checkout previous code and cdk deploy)
```

### Destroy and Recreate

```bash
# 1. Destroy the stack
cdk destroy --context env=<env> --force

# 2. Verify stack is deleted
aws cloudformation describe-stacks --stack-name <stack>  # Should return error

# 3. Re-deploy from known good code
git checkout <known-good-commit> -- infra/
cdk deploy --context env=<env>
```

---

## Bicep (Azure)

### Revert

```bash
# 1. Check out the previous version of the Bicep code
git checkout HEAD~1 -- infra/

# 2. Preview changes (what-if)
az deployment group what-if \
  --resource-group <rg> \
  --template-file main.bicep \
  --parameters @<env>.parameters.json

# 3. Deploy the rollback
az deployment group create \
  --resource-group <rg> \
  --template-file main.bicep \
  --parameters @<env>.parameters.json
```

### Destroy and Recreate

```bash
# 1. Delete the resource group (destroys ALL resources in it)
az group delete --name <rg> --yes --no-wait

# 2. Wait for deletion
az group wait --name <rg> --deleted

# 3. Recreate resource group and deploy
az group create --name <rg> --location <region>
az deployment group create \
  --resource-group <rg> \
  --template-file main.bicep \
  --parameters @<env>.parameters.json
```

---

## Kubernetes (kubectl / Helm)

### kubectl Revert

```bash
# 1. Check rollout history
kubectl rollout history deployment/<name> -n <namespace>

# 2. Rollback to previous revision
kubectl rollout undo deployment/<name> -n <namespace>

# 3. Rollback to specific revision
kubectl rollout undo deployment/<name> -n <namespace> --to-revision=<N>

# 4. Monitor rollback
kubectl rollout status deployment/<name> -n <namespace>
```

### Helm Revert

```bash
# 1. List release history
helm history <release> -n <namespace>

# 2. Rollback to previous revision
helm rollback <release> -n <namespace>

# 3. Rollback to specific revision
helm rollback <release> <revision> -n <namespace>

# 4. Verify rollback
helm status <release> -n <namespace>
```

### Destroy and Recreate

```bash
# kubectl
kubectl delete -k environments/<env>/ -n <namespace>
kubectl apply -k environments/<env>/ -n <namespace>

# Helm
helm uninstall <release> -n <namespace>
helm install <release> <chart> -f values-<env>.yaml -n <namespace>
```

---

## PaaS Platforms

### Fly.io

```bash
# 1. List recent releases
fly releases --app <app-name>

# 2. Rollback to previous release
fly deploy --app <app-name> --image <previous-image-ref>

# 3. Alternatively, rollback to a specific release
fly releases rollback --app <app-name> --version <N>
```

### Railway

```bash
# Railway does not have a built-in CLI rollback command.
# Revert by redeploying the previous commit:
git checkout <previous-commit>
railway up

# Or trigger a redeploy from the Railway dashboard.
```

### Vercel

```bash
# 1. List deployments
vercel ls

# 2. Promote a previous deployment to production
vercel promote <deployment-url>
```

### Netlify

```bash
# Netlify supports instant rollbacks from the dashboard.
# Via CLI:
netlify deploy --prod --dir=<previous-build-output>

# Or use the Netlify UI to rollback to a previous deploy.
```

### Render

```bash
# Render supports rollbacks from the dashboard.
# Navigate to the service's Events tab and click "Rollback" on a previous deploy.
# No CLI rollback command is currently available.
```

---

## Data Preservation During Rollback

**CRITICAL:** Before any rollback that touches databases, storage, or stateful resources:

1. **Database snapshots:** Create a snapshot/backup before rollback
   - AWS RDS: `aws rds create-db-snapshot --db-instance-identifier <id> --db-snapshot-identifier rollback-<timestamp>`
   - GCP Cloud SQL: `gcloud sql backups create --instance <id>`
   - Azure SQL: automatic point-in-time restore available

2. **Storage backups:** If S3/GCS/Blob storage is managed by IaC, ensure data is backed up before destroy
   - Use versioning on storage buckets
   - Copy critical data to a backup bucket

3. **State files:** Always backup the current state before state rollback
   - `tofu state pull > backup-<timestamp>.tfstate`
   - `pulumi stack export > backup-<timestamp>.json`

4. **Secrets:** Secrets in secret managers are generally not affected by IaC rollback, but verify that secret references in the rolled-back code still point to valid secrets.
