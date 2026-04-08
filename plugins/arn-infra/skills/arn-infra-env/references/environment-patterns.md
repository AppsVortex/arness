# Environment Isolation Patterns

Provider-specific strategies for isolating infrastructure environments (dev, staging, production) with trade-offs and cost implications.

---

## AWS Isolation Strategies

### Separate Accounts (Strongest)

Use AWS Organizations with separate accounts per environment.

**Structure:**
```
Organization
├── Management Account (billing, IAM Identity Center)
├── Dev Account (123456789011)
├── Staging Account (123456789012)
└── Production Account (123456789013)
```

**IaC implementation (OpenTofu):**
```hcl
provider "aws" {
  alias  = "staging"
  region = var.region
  assume_role {
    role_arn = "arn:aws:iam::${var.staging_account_id}:role/TerraformRole"
  }
}
```

| Aspect | Detail |
|--------|--------|
| Isolation level | Complete -- separate IAM, networking, billing |
| Cost impact | Minimal overhead (consolidated billing), but each account has its own free tier |
| Complexity | High -- requires AWS Organizations, cross-account roles, SSO |
| Best for | Expert users, SOC 2 compliance, production-grade setups |
| Trade-off | Operational overhead of managing multiple accounts |

### Separate VPCs (Good)

Use separate VPCs within the same account per environment.

**Structure:**
```
Account
├── VPC: dev (10.0.0.0/16)
├── VPC: staging (10.1.0.0/16)
└── VPC: production (10.2.0.0/16)
```

**IaC implementation:**
```hcl
resource "aws_vpc" "env" {
  for_each   = toset(var.environments)
  cidr_block = var.vpc_cidrs[each.key]
  tags = {
    Environment = each.key
  }
}
```

| Aspect | Detail |
|--------|--------|
| Isolation level | Network-level -- separate subnets, security groups, route tables |
| Cost impact | Low -- VPCs are free, NAT Gateways per VPC add cost |
| Complexity | Medium -- single account IAM, VPC peering if cross-env access needed |
| Best for | Intermediate users, most production workloads |
| Trade-off | Shared IAM namespace -- requires careful policy management |

### Resource Naming (Lightweight)

Use resource name prefixes/tags within a single VPC.

**IaC implementation:**
```hcl
resource "aws_instance" "app" {
  ami           = var.ami
  instance_type = var.instance_types[var.environment]
  tags = {
    Name        = "${var.environment}-app"
    Environment = var.environment
  }
}
```

| Aspect | Detail |
|--------|--------|
| Isolation level | Minimal -- resources share networking and IAM |
| Cost impact | Lowest -- no duplicated infrastructure |
| Complexity | Low -- simple naming conventions |
| Best for | Beginner users, development-only setups, cost-constrained projects |
| Trade-off | Weak isolation -- a misconfiguration in dev could affect staging/prod |

---

## GCP Isolation Strategies

### Separate Projects (Strongest)

Use Google Cloud projects per environment within an organization.

**Structure:**
```
Organization
├── Folder: environments
│   ├── Project: myapp-dev
│   ├── Project: myapp-staging
│   └── Project: myapp-production
```

**IaC implementation:**
```hcl
provider "google" {
  project = var.project_ids[var.environment]
  region  = var.region
}
```

| Aspect | Detail |
|--------|--------|
| Isolation level | Complete -- separate IAM, networking, billing, quotas |
| Cost impact | Each project has its own free tier and billing |
| Complexity | Medium -- Google Cloud organizations, folder hierarchy |
| Best for | Expert/intermediate users, all production workloads |
| Trade-off | Requires organization setup (not available for personal accounts) |

### Separate VPC Networks (Good)

Use separate VPC networks within the same project.

| Aspect | Detail |
|--------|--------|
| Isolation level | Network-level -- separate firewall rules and subnets |
| Cost impact | Low -- VPC networks are free |
| Complexity | Low-medium -- shared project IAM |
| Best for | Intermediate users, simpler setups |

### Namespace Separation (Lightweight)

Use labels and naming conventions within shared resources.

| Aspect | Detail |
|--------|--------|
| Isolation level | Minimal -- tag-based resource identification |
| Cost impact | Lowest |
| Complexity | Low |
| Best for | Beginner users, development setups |

---

## Azure Isolation Strategies

### Separate Subscriptions (Strongest)

Use separate Azure subscriptions per environment under a management group.

**Structure:**
```
Management Group: environments
├── Subscription: myapp-dev
├── Subscription: myapp-staging
└── Subscription: myapp-production
```

**IaC implementation (Bicep):**
```bicep
targetScope = 'subscription'

param environment string
param subscriptionId string = subscription().subscriptionId
```

| Aspect | Detail |
|--------|--------|
| Isolation level | Complete -- separate RBAC, networking, billing |
| Cost impact | Each subscription has its own spending limits |
| Complexity | High -- requires Azure Management Groups, cross-subscription access |
| Best for | Expert users, enterprise environments |

### Separate Resource Groups (Good)

Use separate resource groups within the same subscription.

**IaC implementation:**
```bicep
resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: '${projectName}-${environment}'
  location: location
  tags: {
    environment: environment
  }
}
```

| Aspect | Detail |
|--------|--------|
| Isolation level | Resource-level -- separate RBAC per resource group, shared subscription |
| Cost impact | Low -- resource groups are free |
| Complexity | Low-medium -- familiar Azure pattern |
| Best for | Intermediate users, most workloads |

### Resource Tags (Lightweight)

| Aspect | Detail |
|--------|--------|
| Isolation level | Minimal -- tag-based identification |
| Cost impact | Lowest |
| Complexity | Low |
| Best for | Beginner users |

---

## Kubernetes Isolation Strategies

### Separate Clusters (Strongest)

Run dedicated clusters per environment.

| Aspect | Detail |
|--------|--------|
| Isolation level | Complete -- separate control planes, nodes, networking |
| Cost impact | High -- cluster management fees per environment |
| Complexity | High -- multiple clusters to manage |
| Best for | Expert users, strict compliance requirements |

### Separate Namespaces (Good)

Use Kubernetes namespaces within a shared cluster.

**IaC implementation:**
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: myapp-staging
  labels:
    environment: staging
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-cross-namespace
  namespace: myapp-staging
spec:
  podSelector: {}
  policyTypes: [Ingress]
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              environment: staging
```

| Aspect | Detail |
|--------|--------|
| Isolation level | Namespace-level -- RBAC per namespace, network policies |
| Cost impact | Low -- shared cluster resources |
| Complexity | Medium -- requires network policies and RBAC setup |
| Best for | Intermediate users, cost-effective multi-env |

---

## PaaS Provider Patterns

### Fly.io

Environments as separate apps:
```toml
# fly.staging.toml
app = "myapp-staging"
[env]
  ENVIRONMENT = "staging"
[build]
  image = "myapp:staging"
```

### Railway / Render

Use platform-native environment features:
- Railway: Environments within a project (built-in)
- Render: Separate services per environment with naming conventions

### Vercel / Netlify

Use platform preview and production environments:
- Vercel: Preview deployments (automatic per PR), production (main branch)
- Netlify: Deploy previews, branch deploys, production

---

## Recommendation Matrix

| Experience | AWS | GCP | Azure | K8s |
|-----------|-----|-----|-------|-----|
| Expert | Separate accounts | Separate projects | Separate subscriptions | Separate clusters |
| Intermediate | Separate VPCs | Separate projects | Separate resource groups | Separate namespaces |
| Beginner | Resource naming | Namespace labels | Resource tags | Single namespace |
