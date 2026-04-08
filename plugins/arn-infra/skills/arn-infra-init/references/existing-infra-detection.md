# Existing Infrastructure Detection

Reference doc for Step 0 of `arn-infra-init`. Lists all infrastructure artifact patterns to scan for, organized by category. For each artifact type: glob patterns to match, what provider/tool it implies, and how to infer config defaults.

---

## IaC Files

| Glob Pattern | Implies Provider | Implies IaC Tool | Notes |
|-------------|-----------------|-----------------|-------|
| `**/*.tf` | Varies (read provider blocks) | OpenTofu or Terraform | Check for `terraform {}` block to determine. Recommend OpenTofu migration. |
| `**/*.tfvars` | Varies | OpenTofu or Terraform | Variable files, often contain environment-specific values. |
| `**/*.hcl` | Varies | OpenTofu, Terraform, or Terragrunt | Check filename: `terragrunt.hcl` implies Terragrunt. |
| `**/terragrunt.hcl` | Varies | Terragrunt | Wrapper around OpenTofu/Terraform. |
| `**/Pulumi.yaml` | Varies (read config) | Pulumi | Read `runtime` field for language. |
| `**/Pulumi.*.yaml` | Varies | Pulumi | Stack configuration files. |
| `**/cdk.json` | AWS | AWS CDK | Read `app` field for language. |
| `**/*.bicep` | Azure | Bicep | Azure-specific IaC. |
| `**/*.bicepparam` | Azure | Bicep | Parameter files for Bicep. |

### Provider Inference from .tf Files

Scan `*.tf` files for `provider` blocks or `required_providers`:
- `provider "aws"` or `hashicorp/aws` --> AWS
- `provider "google"` or `hashicorp/google` --> GCP
- `provider "azurerm"` or `hashicorp/azurerm` --> Azure
- `provider "digitalocean"` --> DigitalOcean
- `provider "cloudflare"` --> Cloudflare
- `provider "scaleway"` --> Scaleway
- `provider "fly"` or `fly-apps/fly` --> Fly.io

---

## Container Configurations

| Glob Pattern | Implies | Notes |
|-------------|---------|-------|
| `**/Dockerfile` | Container-based deployment | Read FROM line for base image. |
| `**/Dockerfile.*` | Multi-stage or variant builds | e.g., `Dockerfile.prod`, `Dockerfile.dev` |
| `**/docker-compose.yml` | Multi-service architecture | Read service definitions for architecture understanding. |
| `**/docker-compose.yaml` | Multi-service architecture | Same as above. |
| `**/docker-compose.*.yml` | Environment-specific compose | e.g., `docker-compose.prod.yml` |
| `**/.dockerignore` | Container-based deployment | Confirms Docker usage. |

---

## CI/CD Pipelines

| Glob Pattern | Implies Platform | Notes |
|-------------|-----------------|-------|
| `.github/workflows/*.yml` | GitHub Actions | Read for existing deploy steps. |
| `.github/workflows/*.yaml` | GitHub Actions | Same as above. |
| `.gitlab-ci.yml` | GitLab CI | Read for existing deploy stages. |
| `bitbucket-pipelines.yml` | Bitbucket Pipelines | Read for existing deploy steps. |
| `.circleci/config.yml` | CircleCI | Third-party CI. |
| `Jenkinsfile` | Jenkins | Self-hosted CI. |

### Existing Deploy Step Detection

In CI/CD files, scan for deploy-related keywords:
- `deploy`, `staging`, `production`, `infra`, `terraform`, `tofu`, `pulumi`, `cdk`
- AWS: `aws`, `ecr`, `ecs`, `eks`, `s3`, `cloudfront`
- GCP: `gcloud`, `gcr`, `cloud-run`, `gke`
- Azure: `az`, `acr`, `aks`
- PaaS: `fly deploy`, `railway`, `vercel`, `netlify`, `render`

If deploy steps exist, note them -- `arn-infra-pipeline` should extend rather than replace.

---

## Platform Configurations (PaaS)

| File | Implies Provider | IaC Tool |
|------|-----------------|----------|
| `fly.toml` | Fly.io | None (platform-native) |
| `railway.json` | Railway | None (platform-native) |
| `railway.toml` | Railway | None (platform-native) |
| `vercel.json` | Vercel | None (platform-native) |
| `netlify.toml` | Netlify | None (platform-native) |
| `render.yaml` | Render | None (platform-native) |
| `app.yaml` (with `runtime:` field) | GCP App Engine | None (platform-native) |
| `Procfile` | Heroku / Dokku | None (platform-native) |

---

## Kubernetes

| Glob Pattern | Implies | Notes |
|-------------|---------|-------|
| `**/kubernetes/**/*.yaml` | Kubernetes deployment | Read for namespace, service, deployment definitions. |
| `**/k8s/**/*.yaml` | Kubernetes deployment | Common alternative directory name. |
| `**/helm/**` | Helm charts | Check for `Chart.yaml`. |
| `**/Chart.yaml` | Helm chart | Read `name` and `version` fields. |
| `**/values.yaml` | Helm values | Environment-specific values. |
| `**/kustomization.yaml` | Kustomize | Kubernetes config management. |

---

## Cloud-Specific Directories and Files

| Pattern | Implies Provider | Notes |
|---------|-----------------|-------|
| `.aws/` | AWS | May contain credentials (do not read). |
| `samconfig.toml` | AWS (SAM) | Serverless Application Model config. |
| `template.yaml` (with `AWSTemplateFormatVersion`) | AWS (CloudFormation/SAM) | Read for resource definitions. |
| `serverless.yml` | Multi-cloud (Serverless Framework) | Read `provider.name` for cloud. |
| `firebase.json` | GCP (Firebase) | Firebase project config. |
| `.firebaserc` | GCP (Firebase) | Firebase project alias. |

---

## Detection Flow

1. Run all glob patterns listed above against the project root
2. Collect findings into categories: IaC, Containers, CI/CD, Platform, Kubernetes, Cloud-specific
3. For each finding, infer the provider and IaC tool
4. Present consolidated results to the user

**If artifacts are found:**
- List detected artifacts grouped by category
- Show inferred provider(s) and IaC tool(s)
- Pre-populate provider selection (Step 3) with detected providers
- Pre-populate IaC tool selection with detected tool
- Ask: "I found existing infrastructure. Would you like Arness Infra to adopt and manage these, or start fresh?"
  - **Adopt:** Use detected settings as defaults, proceed with confirmation
  - **Start fresh:** Ignore detected artifacts, proceed with normal selection flow

**If no artifacts are found:**
- Proceed directly to Step 1b (timing and deferral)

---

## Security Note

When scanning for infrastructure artifacts:
- NEVER read files in `.aws/`, `.azure/`, or similar credential directories
- NEVER display or log credential values found in config files
- Flag any hardcoded secrets found in IaC files as a security concern
- Skip `.git/`, `node_modules/`, `vendor/`, and other dependency directories
