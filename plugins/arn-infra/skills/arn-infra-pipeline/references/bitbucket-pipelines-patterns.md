# Bitbucket Pipelines Patterns for Infrastructure

High-level patterns for generating infrastructure CI/CD pipelines using Bitbucket Pipelines. These patterns focus on structural conventions and avoid pinning specific tool versions to reduce maintenance churn.

---

## Pipeline Structure

Bitbucket Pipelines uses `bitbucket-pipelines.yml` at the repository root. Key structural differences from GitHub Actions and GitLab CI:

- **No separate workflow files** -- all pipelines live in a single YAML file
- **`pipelines:` is the top-level key** (not `jobs:` or `stages:`)
- **Branch-based triggers** use `branches:` under `pipelines:`
- **Manual triggers** use `trigger: manual` on a step
- **Pipes** are Bitbucket's reusable action mechanism (equivalent to GitHub Actions)
- **Deployment environments** are first-class via `deployment:` key on steps

---

## Basic Infrastructure Pipeline

```yaml
image: hashicorp/terraform:light  # Or appropriate IaC tool image

definitions:
  caches:
    tofu: ~/.terraform.d/plugin-cache
  steps:
    - step: &validate
        name: Validate
        caches:
          - tofu
        script:
          - tofu init -backend=false
          - tofu validate
          - tofu fmt -check

    - step: &plan
        name: Plan
        caches:
          - tofu
        script:
          - tofu init
          - tofu plan -out=tfplan
        artifacts:
          - tfplan

    - step: &apply
        name: Apply
        trigger: manual
        deployment: staging
        script:
          - tofu init
          - tofu apply -auto-approve tfplan

pipelines:
  branches:
    main:
      - step: *validate
      - step: *plan
      - step: *apply
```

---

## OIDC Authentication

Bitbucket Pipelines supports OIDC for cloud provider authentication without storing long-lived credentials.

### AWS OIDC

```yaml
definitions:
  steps:
    - step: &aws-oidc-deploy
        name: Deploy to AWS
        oidc: true
        script:
          - export AWS_WEB_IDENTITY_TOKEN_FILE=$(pwd)/web-identity-token
          - echo $BITBUCKET_STEP_OIDC_TOKEN > $AWS_WEB_IDENTITY_TOKEN_FILE
          - export AWS_ROLE_ARN=$AWS_OIDC_ROLE_ARN
          - aws sts get-caller-identity  # Verify authentication
          - tofu init
          - tofu apply -auto-approve
```

### GCP OIDC

```yaml
definitions:
  steps:
    - step: &gcp-oidc-deploy
        name: Deploy to GCP
        oidc: true
        script:
          - echo $BITBUCKET_STEP_OIDC_TOKEN > /tmp/oidc-token
          - gcloud auth login --cred-file=/tmp/oidc-token
          - tofu init
          - tofu apply -auto-approve
```

---

## Environment Promotion Pattern

```yaml
pipelines:
  branches:
    main:
      - step: *validate
      - step: *plan-staging
      - step:
          <<: *apply
          name: Deploy to Staging
          deployment: staging
      - step:
          name: Integration Tests
          script:
            - # Run post-deploy verification
      - step:
          <<: *plan-production
          trigger: manual
      - step:
          <<: *apply
          name: Deploy to Production
          deployment: production
          trigger: manual
```

**Key conventions:**
- Use `deployment:` to link steps to Bitbucket deployment environments
- Use `trigger: manual` for production gates
- Staging deploys automatically after validation; production requires manual approval
- Artifacts (plan files) pass between steps in the same pipeline

---

## Security Scanning Step

```yaml
definitions:
  steps:
    - step: &security-scan
        name: Security Scan
        script:
          - pip install checkov || true
          - checkov -d . --output cli --soft-fail || true
          - # Or use trivy
          - # trivy config . --severity HIGH,CRITICAL || true
```

---

## Cost Estimation Step

```yaml
definitions:
  steps:
    - step: &cost-estimate
        name: Cost Estimate
        script:
          - infracost breakdown --path . --format table || true
          - infracost diff --path . --compare-to infracost-base.json || true
```

---

## Multi-Environment with Variable Overrides

```yaml
definitions:
  steps:
    - step: &deploy-env
        name: Deploy to $ENVIRONMENT
        script:
          - tofu init -backend-config="key=$ENVIRONMENT/terraform.tfstate"
          - tofu plan -var-file="environments/$ENVIRONMENT.tfvars" -out=tfplan
          - tofu apply -auto-approve tfplan

pipelines:
  branches:
    main:
      - step: *validate
      - step:
          <<: *deploy-env
          deployment: staging
      - step:
          <<: *deploy-env
          deployment: production
          trigger: manual
```

---

## Parallel Steps

Bitbucket supports parallel execution within a pipeline:

```yaml
pipelines:
  branches:
    main:
      - parallel:
          - step: *validate
          - step: *security-scan
          - step: *cost-estimate
      - step: *plan
      - step: *apply
```

---

## Key Differences from Other Platforms

| Concept | GitHub Actions | GitLab CI | Bitbucket Pipelines |
|---------|---------------|-----------|-------------------|
| Config file | `.github/workflows/*.yml` | `.gitlab-ci.yml` | `bitbucket-pipelines.yml` |
| Reusable units | Actions (uses:) | Templates (include:) | Pipes (pipe:) / YAML anchors |
| Manual gates | `environment: production` | `when: manual` | `trigger: manual` |
| Environments | `environment:` on job | `environment:` on job | `deployment:` on step |
| Parallel | Multiple jobs | `parallel:` keyword | `parallel:` keyword |
| OIDC | `permissions: id-token: write` | `id_tokens:` | `oidc: true` |
| Caching | `actions/cache` | `cache:` keyword | `caches:` in definitions |
| Artifacts | `actions/upload-artifact` | `artifacts:` keyword | `artifacts:` keyword |

---

## Best Practices

1. **Use YAML anchors (`&` and `*`)** for step reuse instead of duplicating step definitions
2. **Use `deployment:` environments** for deployment tracking and manual approval gates
3. **Enable OIDC** for cloud authentication -- avoid storing access keys as repository variables
4. **Use `trigger: manual`** for production deployments as an approval gate
5. **Cache IaC plugin directories** to speed up `init` steps
6. **Pass plan files as artifacts** between plan and apply steps to prevent drift
7. **Use parallel steps** for independent validation tasks (lint, security scan, cost estimate)
8. **Set appropriate `max-time`** on steps to prevent runaway deployments
