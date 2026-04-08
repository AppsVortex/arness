# Secrets Providers Comparison

Comparison of secrets management solutions for infrastructure deployments. Select based on cloud provider, feature requirements, budget, and complexity tolerance.

---

## AWS Secrets Manager

| Aspect | Detail |
|--------|--------|
| Provider compatibility | AWS (native) |
| Pricing | $0.40/secret/month + $0.05 per 10,000 API calls |
| Automatic rotation | Yes (Lambda-based, built-in for RDS, Redshift, DocumentDB) |
| Versioning | Yes (automatic version staging: AWSCURRENT, AWSPREVIOUS) |
| Audit logging | CloudTrail integration (automatic) |
| Cross-region replication | Yes |
| Setup complexity | Low (IAM-based access, native SDK support) |

**IaC integration:**
```hcl
# OpenTofu/Terraform -- create secret
resource "aws_secretsmanager_secret" "db_password" {
  name                    = "${var.environment}/db-password"
  recovery_window_in_days = 7
}

# OpenTofu/Terraform -- reference secret
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id
}

# Use in other resources
resource "aws_rds_cluster" "main" {
  master_password = data.aws_secretsmanager_secret_version.db_password.secret_string
}
```

**Best for:** AWS-only deployments, RDS database credentials with auto-rotation.

---

## AWS SSM Parameter Store

| Aspect | Detail |
|--------|--------|
| Provider compatibility | AWS (native) |
| Pricing | Standard: free (up to 10,000 parameters). Advanced: $0.05/parameter/month |
| Automatic rotation | No (manual or Lambda-based custom) |
| Versioning | Yes |
| Audit logging | CloudTrail integration |
| Encryption | Optional (SecureString type uses KMS) |
| Setup complexity | Very low |

**IaC integration:**
```hcl
resource "aws_ssm_parameter" "api_key" {
  name  = "/${var.environment}/api-key"
  type  = "SecureString"
  value = var.api_key  # Set once, then manage via AWS console
}

data "aws_ssm_parameter" "api_key" {
  name = "/${var.environment}/api-key"
}
```

**Best for:** Simple key-value secrets, cost-sensitive setups, configuration values that do not need rotation.

---

## GCP Secret Manager

| Aspect | Detail |
|--------|--------|
| Provider compatibility | GCP (native) |
| Pricing | 6 secret versions free, then $0.06/active version/month + $0.03 per 10,000 access operations |
| Automatic rotation | Yes (Pub/Sub-based rotation triggers) |
| Versioning | Yes (immutable versions with aliases) |
| Audit logging | Cloud Audit Logs integration |
| Cross-region replication | Automatic (configurable replication policy) |
| Setup complexity | Low |

**IaC integration:**
```hcl
resource "google_secret_manager_secret" "db_password" {
  secret_id = "db-password-${var.environment}"
  replication {
    auto {}
  }
}

data "google_secret_manager_secret_version" "db_password" {
  secret  = google_secret_manager_secret.db_password.id
  version = "latest"
}
```

**Best for:** GCP-only deployments, projects needing granular version control.

---

## Azure Key Vault

| Aspect | Detail |
|--------|--------|
| Provider compatibility | Azure (native) |
| Pricing | Standard: $0.03/10,000 operations. Premium: $1/key/month (HSM-backed) |
| Automatic rotation | Yes (Event Grid-based rotation notifications) |
| Versioning | Yes |
| Audit logging | Azure Monitor and Activity Log |
| Certificate management | Yes (TLS certificate lifecycle management) |
| Setup complexity | Medium (RBAC + access policies) |

**IaC integration:**
```bicep
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'kv-${environment}'
  location: location
  properties: {
    sku: { family: 'A', name: 'standard' }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
  }
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'db-password'
  properties: {
    value: dbPassword
  }
}
```

**Best for:** Azure-only deployments, projects needing certificate management alongside secrets.

---

## HashiCorp Vault

| Aspect | Detail |
|--------|--------|
| Provider compatibility | All (cloud-agnostic) |
| Pricing | Open source: free (self-hosted). HCP Vault: starts at $0.03/hr (~$22/month) |
| Automatic rotation | Yes (dynamic secrets with TTL-based leases) |
| Versioning | Yes (KV v2 engine) |
| Audit logging | Built-in audit device (file, syslog, socket) |
| Dynamic secrets | Yes (generates temporary credentials on demand for AWS, GCP, Azure, databases) |
| Setup complexity | High (server management, unsealing, HA setup) |

**IaC integration:**
```hcl
provider "vault" {
  address = var.vault_address
}

data "vault_kv_secret_v2" "db" {
  mount = "secret"
  name  = "${var.environment}/database"
}

# Dynamic secret: Vault generates temporary AWS credentials
data "vault_aws_access_credentials" "deploy" {
  backend = "aws"
  role    = "deploy-${var.environment}"
}
```

**Best for:** Multi-cloud deployments, organizations needing dynamic secrets, enterprise compliance.

---

## Doppler

| Aspect | Detail |
|--------|--------|
| Provider compatibility | All (cloud-agnostic SaaS) |
| Pricing | Free (up to 5 users), Team: $5/user/month |
| Automatic rotation | Manual (with webhook notifications) |
| Versioning | Yes (full change history with audit trail) |
| Audit logging | Built-in activity log |
| Environment management | Built-in (dev, staging, prod scopes per project) |
| Setup complexity | Very low (CLI + SDK) |

**Integration:**
```bash
# CLI usage
doppler secrets --project myapp --config staging
doppler run -- node server.js  # Injects secrets as env vars

# Docker
doppler run --mount /etc/secrets/config.json -- docker compose up

# CI/CD (GitHub Actions)
- uses: dopplerhq/secrets-fetch-action@v1
  with:
    doppler-token: ${{ secrets.DOPPLER_TOKEN }}
    doppler-project: myapp
    doppler-config: staging
```

**Best for:** Teams wanting simplicity, multi-cloud setups, projects without existing cloud provider preference.

---

## 1Password (via Connect Server)

| Aspect | Detail |
|--------|--------|
| Provider compatibility | All (cloud-agnostic) |
| Pricing | Business: $7.99/user/month (includes Connect Server) |
| Automatic rotation | Manual (with webhook triggers) |
| Versioning | Yes |
| Audit logging | Yes (1Password Events API) |
| Setup complexity | Medium (Connect Server deployment required) |

**Integration:**
```hcl
# OpenTofu/Terraform (1Password provider)
provider "onepassword" {
  url   = var.op_connect_url
  token = var.op_connect_token
}

data "onepassword_item" "db_password" {
  vault = "Infrastructure"
  title = "Database Password - ${var.environment}"
}
```

**Best for:** Teams already using 1Password, organizations wanting unified password and secrets management.

---

## SOPS (Secrets OPerationS)

| Aspect | Detail |
|--------|--------|
| Provider compatibility | All (encrypts files in git using cloud KMS or age keys) |
| Pricing | Free (open source) + KMS costs |
| Automatic rotation | No (file-based, manual updates) |
| Versioning | Git history (encrypted file changes tracked) |
| Audit logging | Git log + KMS audit trail |
| Setup complexity | Low-medium |

**Setup:**
```yaml
# .sops.yaml
creation_rules:
  - path_regex: environments/dev/.*
    kms: arn:aws:kms:us-east-1:123456789:key/dev-key-id
  - path_regex: environments/prod/.*
    kms: arn:aws:kms:us-east-1:123456789:key/prod-key-id
```

```bash
# Encrypt a file
sops -e secrets.yaml > secrets.enc.yaml

# Decrypt in CI/CD
sops -d secrets.enc.yaml > secrets.yaml
```

**Best for:** GitOps workflows, teams wanting secrets versioned alongside IaC, complement to a central secrets manager.

---

## Comparison Summary

| Feature | AWS SM | AWS SSM | GCP SM | Azure KV | Vault | Doppler | 1Password | SOPS |
|---------|--------|---------|--------|----------|-------|---------|-----------|------|
| Multi-cloud | No | No | No | No | Yes | Yes | Yes | Yes |
| Auto-rotation | Yes | No | Yes | Yes | Yes | No | No | No |
| Dynamic secrets | No | No | No | No | Yes | No | No | No |
| Free tier | No | Yes | Yes | No | Yes* | Yes | No | Yes |
| Setup complexity | Low | Very low | Low | Medium | High | Very low | Medium | Low |
| Best for | AWS | AWS simple | GCP | Azure | Enterprise | Teams | 1Pass users | GitOps |

*Vault open source is free but requires self-hosting.
