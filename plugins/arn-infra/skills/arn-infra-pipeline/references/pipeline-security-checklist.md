# Pipeline Security Checklist

SOC 2-aligned security checklist for infrastructure CI/CD pipelines. Review every generated pipeline against these requirements.

---

## Credentials and Secrets

- [ ] **No static credentials in pipeline files.** All cloud provider authentication uses OIDC token exchange (AWS, GCP, Azure) or platform-managed service connections. No `AWS_ACCESS_KEY_ID`, `GOOGLE_CREDENTIALS`, or `ARM_CLIENT_SECRET` stored as CI variables.
- [ ] **No secrets in logs or artifacts.** Pipeline steps mask sensitive values. Commands use `-no-color` flags and avoid echoing environment variables. Log output is reviewed for accidental exposure.
- [ ] **OIDC preferred over static API keys.** If OIDC is available for the provider, it must be used. Static credentials are only acceptable when OIDC is not supported (e.g., some PaaS providers).
- [ ] **Secrets scoped to environments.** Production secrets are not accessible from staging jobs. Each environment uses separate CI/CD variable scopes or separate secret stores.
- [ ] **No secrets in Dockerfile build args.** Build-time secrets use BuildKit secret mounts (`--mount=type=secret`), not `ARG` or `ENV` directives.

---

## IAM and Permissions

- [ ] **Minimal IAM permissions for CI role.** The CI runner's cloud role has only the permissions needed for `plan` and `apply` operations. No wildcard (`*`) actions or resources.
- [ ] **Separate IAM roles per environment.** The staging CI role cannot access production resources and vice versa. Role assumption is scoped by environment name in the trust policy.
- [ ] **No admin or root credentials.** CI pipelines never use organization admin, root account, or owner-level credentials.
- [ ] **Role session names include job context.** For AWS `assume-role-with-web-identity`, the session name includes the CI job ID or commit SHA for audit trail.

---

## Dependency and Action Pinning

- [ ] **Actions/images pinned to SHA or specific version.** GitHub Actions use `@v4` minimum (prefer SHA pinning for critical actions). Docker images specify version tags, not `latest`.
- [ ] **Third-party actions reviewed.** Any third-party GitHub Action or GitLab CI template is from a verified publisher or has been audited. No unverified marketplace actions with write permissions.
- [ ] **IaC tool versions pinned.** Terraform/OpenTofu, Pulumi, CDK, and Bicep CLI versions are explicit in the pipeline (e.g., `terraform_version: 1.7.0`), not `latest`.

---

## Branch Protection

- [ ] **No direct push to main/production branches.** Branch protection rules require PR review before merge. The pipeline only deploys from protected branches.
- [ ] **PR review required before deployment.** At least one approved review is required before infrastructure changes can be merged and deployed.
- [ ] **Status checks required.** The validation job (format, validate, security scan) must pass before merge is allowed.
- [ ] **Force push disabled on protected branches.** No force push to main, staging, or production branches.

---

## Plan and Apply Separation

- [ ] **Plan is generated and reviewed before apply.** The pipeline follows a plan-then-apply pattern: `tofu plan -out=tfplan` in the PR, `tofu apply tfplan` in the deploy job.
- [ ] **Apply uses the exact plan that was reviewed.** The plan file is saved as an artifact and used in the apply step. No re-planning during apply.
- [ ] **Plan output visible for review.** The plan is posted as a PR comment or available as a downloadable artifact. Reviewers can see what will change before approving.

---

## Audit Trail

- [ ] **Plan artifacts retained.** Terraform/OpenTofu plan files and human-readable plan output are stored as pipeline artifacts with retention of at least 90 days for SOC 2 compliance.
- [ ] **Deployment logs retained.** All deployment job logs are preserved per the organization's retention policy (minimum 90 days for SOC 2).
- [ ] **Who approved what is traceable.** Production deployments record the approver's identity. For GitHub: environment protection reviewers are logged. For GitLab: manual job trigger identity is logged.

---

## Network and Runtime

- [ ] **CI runners use ephemeral environments.** Runners are stateless -- no persistent data from previous jobs. Self-hosted runners are hardened and regularly rotated.
- [ ] **No open SSH or debug ports in pipelines.** Pipeline steps do not expose ports for debugging. SSH access to runners is disabled in production pipelines.
- [ ] **Artifact access is restricted.** Pipeline artifacts containing plan files or state information are not publicly accessible.

---

## Scheduled Jobs

- [ ] **Cleanup jobs do not auto-destroy.** Scheduled cleanup checks report expired resources and create issues. They do not automatically destroy resources without human review.
- [ ] **Cron jobs use minimal permissions.** Scheduled pipelines have read-only access unless they need to create issues or send notifications.
- [ ] **Scheduled job failures are visible.** Failed cleanup or monitoring jobs send notifications to the responsible team.

---

## Compliance Summary

| SOC 2 Control | Pipeline Implementation |
|---------------|------------------------|
| Change management | PR review required, plan-as-artifact audit trail |
| Separation of duties | Separate IAM roles per environment, reviewer != deployer |
| Access control | OIDC auth, environment-scoped secrets, minimal IAM |
| Audit logging | Plan artifacts retained 90+ days, deployment logs preserved |
| Monitoring | Scheduled cleanup checks, failed job notifications |
