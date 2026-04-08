# GitHub Actions Patterns for Infrastructure CI/CD

Reference patterns for generating GitHub Actions workflows for infrastructure deployment pipelines.

---

## Pattern: Deploy on Push to Branch

Triggers infrastructure deployment when changes are pushed to a specific branch after PR merge.

```yaml
name: Deploy Infrastructure - Staging
on:
  push:
    branches: [main]
    paths:
      - 'infra/**'
      - '*.tf'
      - '*.hcl'
      - 'Pulumi.*'
      - 'cdk.json'

jobs:
  deploy-staging:
    runs-on: ubuntu-latest
    environment: staging
    permissions:
      id-token: write   # Required for OIDC
      contents: read
    steps:
      - uses: actions/checkout@v4
      - name: Configure cloud credentials (OIDC)
        # Provider-specific OIDC step
      - name: Setup IaC tool
        # Tool-specific setup
      - name: Apply infrastructure
        run: |
          # Apply using the plan artifact from PR validation
```

**When to use:** Staging environment with auto-deploy enabled.

---

## Pattern: Environment Protection Rules

Uses GitHub Environments for deployment gating with required reviewers and wait timers.

```yaml
jobs:
  deploy-production:
    runs-on: ubuntu-latest
    environment:
      name: production
      url: ${{ steps.deploy.outputs.url }}
    # GitHub enforces protection rules configured in Settings > Environments:
    # - Required reviewers (1-6 people)
    # - Wait timer (0-43200 minutes)
    # - Deployment branches (restrict to main only)
```

**Setup requirements:**
1. Go to Settings > Environments > New environment
2. Add "production" environment
3. Configure required reviewers
4. Restrict deployment branches to `main`
5. Optionally add wait timer for compliance

---

## Pattern: OIDC Provider Authentication

Eliminates static credentials by using GitHub's OIDC token with cloud provider trust relationships.

### AWS OIDC

```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::${{ secrets.AWS_ACCOUNT_ID }}:role/github-actions-${{ github.event.inputs.environment || 'staging' }}
    aws-region: ${{ vars.AWS_REGION }}
    # No access keys needed -- uses OIDC token exchange
```

**AWS setup:**
1. Create an OIDC identity provider in IAM for `token.actions.githubusercontent.com`
2. Create IAM roles per environment with trust policy scoped to the repo and environment
3. Scope each role to minimum required permissions

### GCP OIDC

```yaml
- name: Authenticate to Google Cloud
  uses: google-github-actions/auth@v2
  with:
    workload_identity_provider: projects/${{ secrets.GCP_PROJECT_NUMBER }}/locations/global/workloadIdentityPools/github-pool/providers/github-provider
    service_account: github-actions-${{ github.event.inputs.environment || 'staging' }}@${{ secrets.GCP_PROJECT_ID }}.iam.gserviceaccount.com
```

**GCP setup:**
1. Create a Workload Identity Pool and Provider
2. Create service accounts per environment
3. Bind the pool to the service accounts with repo/environment conditions

### Azure OIDC

```yaml
- name: Azure Login
  uses: azure/login@v2
  with:
    client-id: ${{ secrets.AZURE_CLIENT_ID }}
    tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
    # Uses federated credentials -- no client secret needed
```

**Azure setup:**
1. Create an App Registration with federated credentials
2. Configure subject filter for repo and environment
3. Assign roles per subscription/resource group

---

## Pattern: IaC Validation Job

Runs on every PR that modifies infrastructure files. Produces a plan for review.

```yaml
name: Validate Infrastructure
on:
  pull_request:
    paths:
      - 'infra/**'
      - '*.tf'
      - '*.hcl'

permissions:
  id-token: write
  contents: read
  pull-requests: write  # For PR comments

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup IaC tool
        # Tool-specific setup (e.g., setup-terraform, setup-opentofu)

      - name: Format check
        run: tofu fmt -check -recursive

      - name: Initialize
        run: tofu init -backend=false

      - name: Validate
        run: tofu validate

      - name: Security scan
        if: ${{ hashFiles('**/checkov') != '' }}
        run: checkov -d . --output github_failed_only

      - name: Plan
        id: plan
        run: tofu plan -no-color -out=tfplan

      - name: Save plan artifact
        uses: actions/upload-artifact@v4
        with:
          name: tfplan-${{ github.sha }}
          path: tfplan
          retention-days: 30  # Audit trail

      - name: Comment plan on PR
        uses: actions/github-script@v7
        with:
          script: |
            const plan = `${{ steps.plan.outputs.stdout }}`;
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `## Infrastructure Plan\n\`\`\`\n${plan}\n\`\`\``
            });
```

---

## Pattern: Cost Estimation Job

Adds Infracost cost estimates to PR comments when available.

```yaml
  cost-estimate:
    runs-on: ubuntu-latest
    if: ${{ vars.INFRACOST_API_KEY != '' }}
    steps:
      - uses: actions/checkout@v4

      - name: Setup Infracost
        uses: infracost/actions/setup@v3
        with:
          api-key: ${{ secrets.INFRACOST_API_KEY }}

      - name: Generate cost breakdown
        run: infracost breakdown --path . --format json --out-file /tmp/infracost.json

      - name: Post cost comment
        uses: infracost/actions/comment@v3
        with:
          path: /tmp/infracost.json
          behavior: update
```

---

## Pattern: Matrix Strategy for Multi-Environment

Deploys to multiple environments using a matrix strategy with environment-specific configs.

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        environment: [staging, production]
      max-parallel: 1  # Sequential deployment
    environment: ${{ matrix.environment }}
    steps:
      - uses: actions/checkout@v4
      - name: Apply with environment-specific vars
        run: |
          tofu init
          tofu apply -auto-approve -var-file="environments/${{ matrix.environment }}.tfvars"
```

**Note:** For production, prefer separate workflows with manual triggers over matrix strategies to enforce proper approval gates.

---

## Pattern: Scheduled Cleanup Job

Daily cron job that checks for expired infrastructure resources and creates cleanup issues.

```yaml
name: Infrastructure Cleanup Check
on:
  schedule:
    - cron: '0 6 * * *'  # Daily at 6 AM UTC
  workflow_dispatch: {}   # Allow manual trigger

jobs:
  check-ttl:
    runs-on: ubuntu-latest
    permissions:
      issues: write
      contents: read
    steps:
      - uses: actions/checkout@v4
      - name: Check for expired resources
        id: check
        run: |
          # Parse active-resources.json for expired TTLs
          # Output list of expired resources
      - name: Create cleanup issues
        if: steps.check.outputs.expired_count > 0
        uses: actions/github-script@v7
        with:
          script: |
            // Create an issue per expired resource group
```

---

## Reusable Workflow Pattern

Extract common steps into reusable workflows for consistency across environments.

```yaml
# .github/workflows/infra-deploy-reusable.yml
name: Reusable Infrastructure Deploy
on:
  workflow_call:
    inputs:
      environment:
        required: true
        type: string
      auto-approve:
        required: false
        type: boolean
        default: false
    secrets:
      AWS_ACCOUNT_ID:
        required: true

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: ${{ inputs.environment }}
    steps:
      # Common deployment steps
```

**Calling workflow:**
```yaml
jobs:
  deploy-staging:
    uses: ./.github/workflows/infra-deploy-reusable.yml
    with:
      environment: staging
      auto-approve: true
    secrets: inherit
```
