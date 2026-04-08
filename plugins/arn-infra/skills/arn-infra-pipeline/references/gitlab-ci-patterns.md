# GitLab CI Patterns for Infrastructure CI/CD

Reference patterns for generating GitLab CI pipeline configurations for infrastructure deployment.

---

## Pattern: Stage-Based Deployment

GitLab CI uses stages to define the deployment pipeline. Infrastructure stages run after application CI stages.

```yaml
stages:
  - validate
  - plan
  - deploy-staging
  - deploy-production
  - cleanup

# Only run infra jobs when IaC files change
.infra-changes:
  rules:
    - changes:
        - "infra/**/*"
        - "*.tf"
        - "*.hcl"
        - "Pulumi.*"
        - "cdk.json"
        - "*.bicep"

variables:
  TF_STATE_NAME: "default"
  TF_ADDRESS: "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/terraform/state/${TF_STATE_NAME}"
```

**When to use:** Standard GitLab CI infrastructure pipeline with validation, planning, and staged deployment.

---

## Pattern: Environment Scoping

GitLab environments provide deployment tracking, review, and approval gates.

```yaml
deploy-staging:
  stage: deploy-staging
  environment:
    name: staging
    url: https://staging.example.com
    on_stop: stop-staging
  script:
    - tofu init
    - tofu apply -auto-approve -var-file="environments/staging.tfvars"
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
      when: on_success

deploy-production:
  stage: deploy-production
  environment:
    name: production
    url: https://example.com
  script:
    - tofu init
    - tofu apply -auto-approve -var-file="environments/production.tfvars"
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
      when: manual  # Requires manual trigger
  allow_failure: false  # Block pipeline if deploy fails
```

**Setup requirements:**
1. Go to Settings > CI/CD > Variables for environment-scoped variables
2. Go to Settings > CI/CD > Protected Environments for approval gates
3. Configure required approvers for production environment

---

## Pattern: OIDC Authentication

GitLab supports OIDC token exchange with cloud providers via `CI_JOB_JWT_V2`.

### AWS OIDC

```yaml
.aws-oidc:
  id_tokens:
    AWS_OIDC_TOKEN:
      aud: https://gitlab.com
  before_script:
    - >
      export $(printf "AWS_ACCESS_KEY_ID=%s AWS_SECRET_ACCESS_KEY=%s AWS_SESSION_TOKEN=%s"
      $(aws sts assume-role-with-web-identity
      --role-arn arn:aws:iam::${AWS_ACCOUNT_ID}:role/gitlab-ci-${CI_ENVIRONMENT_NAME}
      --role-session-name "gitlab-ci-${CI_JOB_ID}"
      --web-identity-token "${AWS_OIDC_TOKEN}"
      --duration-seconds 3600
      --query "Credentials.[AccessKeyId,SecretAccessKey,SessionToken]"
      --output text))
```

**AWS setup:**
1. Create OIDC identity provider for `gitlab.com`
2. Create IAM roles per environment with trust policy scoped to GitLab project
3. Scope each role to minimum required permissions

### GCP OIDC

```yaml
.gcp-oidc:
  id_tokens:
    GCP_OIDC_TOKEN:
      aud: https://iam.googleapis.com/projects/${GCP_PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_ID}/providers/${PROVIDER_ID}
  before_script:
    - echo "${GCP_OIDC_TOKEN}" > /tmp/oidc_token
    - gcloud iam workload-identity-pools create-cred-config
        "projects/${GCP_PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_ID}/providers/${PROVIDER_ID}"
        --service-account="${GCP_SA_EMAIL}"
        --credential-source-file=/tmp/oidc_token
        --output-file=/tmp/gcp_creds.json
    - export GOOGLE_APPLICATION_CREDENTIALS=/tmp/gcp_creds.json
```

### Azure OIDC

```yaml
.azure-oidc:
  id_tokens:
    AZURE_OIDC_TOKEN:
      aud: api://AzureADTokenExchange
  before_script:
    - az login --federated-token "${AZURE_OIDC_TOKEN}"
        --service-principal
        --tenant "${AZURE_TENANT_ID}"
        -u "${AZURE_CLIENT_ID}"
```

---

## Pattern: Review Apps for Infrastructure

Preview infrastructure changes in ephemeral environments tied to merge requests.

```yaml
plan-review:
  stage: plan
  extends: .infra-changes
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    on_stop: destroy-review
    auto_stop_in: 1 week
  script:
    - tofu init
    - tofu plan -out=tfplan -var-file="environments/review.tfvars" -var="name_suffix=${CI_COMMIT_REF_SLUG}"
  artifacts:
    paths:
      - tfplan
    expire_in: 1 week
  rules:
    - if: $CI_MERGE_REQUEST_IID

destroy-review:
  stage: cleanup
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    action: stop
  script:
    - tofu init
    - tofu destroy -auto-approve -var-file="environments/review.tfvars" -var="name_suffix=${CI_COMMIT_REF_SLUG}"
  rules:
    - if: $CI_MERGE_REQUEST_IID
      when: manual
```

---

## Pattern: Manual Gates

Production deployments require manual approval with blocking behavior.

```yaml
approve-production:
  stage: deploy-production
  script:
    - echo "Production deployment approved by ${GITLAB_USER_LOGIN}"
  environment:
    name: production
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
      when: manual
  allow_failure: false  # Blocks the pipeline until approved

deploy-production:
  stage: deploy-production
  needs: [approve-production]
  script:
    - tofu init
    - tofu apply -auto-approve -var-file="environments/production.tfvars"
  environment:
    name: production
```

**Protected environments:**
1. Settings > CI/CD > Protected environments
2. Add "production" as protected
3. Set required approval count
4. Restrict to specific roles (Maintainer+)

---

## Pattern: Plan Artifact for Audit Trail

Store Terraform/OpenTofu plans as artifacts for SOC 2 audit compliance.

```yaml
plan:
  stage: plan
  script:
    - tofu init
    - tofu plan -out=tfplan -no-color 2>&1 | tee plan_output.txt
  artifacts:
    paths:
      - tfplan
      - plan_output.txt
    expire_in: 90 days  # SOC 2 audit retention
    reports:
      terraform: plan_output.txt
  rules:
    - if: $CI_MERGE_REQUEST_IID

apply:
  stage: deploy-staging
  needs: [plan]
  script:
    - tofu init
    - tofu apply tfplan  # Applies the exact reviewed plan
  dependencies:
    - plan
```

---

## Pattern: Security Scanning Stage

Run security scans on infrastructure code before deployment.

```yaml
security-scan:
  stage: validate
  extends: .infra-changes
  script:
    - checkov -d . --output cli --compact
    - trivy config . --severity HIGH,CRITICAL
  allow_failure: false  # Block deployment if security issues found
  artifacts:
    reports:
      sast: checkov-report.json

secret-detection:
  stage: validate
  script:
    - gitleaks detect --source . --report-format json --report-path gitleaks-report.json
  artifacts:
    reports:
      secret_detection: gitleaks-report.json
```

---

## Pattern: Scheduled Cleanup

Daily job that checks for expired resources and creates issues.

```yaml
cleanup-check:
  stage: cleanup
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule"
  script:
    - |
      # Parse active-resources.json for expired TTLs
      # Use GitLab API to create issues for expired resources
      curl --request POST "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/issues" \
        --header "PRIVATE-TOKEN: ${CLEANUP_TOKEN}" \
        --data-urlencode "title=Cleanup: Expired infrastructure resources" \
        --data-urlencode "labels=arn-infra-cleanup"
```

**Schedule setup:**
1. Go to CI/CD > Schedules
2. Create schedule: daily at 06:00 UTC
3. Set target branch: main
4. Add variable `CLEANUP_TOKEN` with API access
