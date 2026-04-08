# OpenTofu / Terraform Patterns

Module structure, state backend configuration, variable conventions, and idiomatic patterns for OpenTofu (and Terraform) infrastructure-as-code. OpenTofu is the recommended engine; Terraform users should be warned about BSL licensing.

> **License note:** Terraform adopted the Business Source License (BSL 1.1) in August 2023. OpenTofu is the CNCF Sandbox fork under MPL 2.0. The two are syntax-compatible. All examples below use `tofu` commands; replace with `terraform` if using Terraform, and consider migrating to OpenTofu.

---

## Project Structure

### Single-Environment (Simple)

```
infra/
├── main.tf           # Resource definitions
├── variables.tf      # Input variable declarations
├── outputs.tf        # Output value declarations
├── providers.tf      # Provider configuration and version constraints
├── terraform.tfvars  # Default variable values (gitignored if contains secrets)
├── backend.tf        # State backend configuration
└── .terraform.lock.hcl  # Provider version lock (committed)
```

### Multi-Environment (Recommended)

```
infra/
├── modules/
│   ├── networking/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── compute/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── database/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── environments/
│   ├── dev/
│   │   ├── main.tf        # Module calls with dev-specific values
│   │   ├── backend.tf     # Dev state backend
│   │   └── terraform.tfvars
│   ├── staging/
│   │   ├── main.tf
│   │   ├── backend.tf
│   │   └── terraform.tfvars
│   └── prod/
│       ├── main.tf
│       ├── backend.tf
│       └── terraform.tfvars
└── .terraform.lock.hcl
```

### Module Structure Convention

Each module follows the same internal structure:
```
modules/<module-name>/
├── main.tf         # Resource definitions
├── variables.tf    # Input declarations with descriptions, types, validation
├── outputs.tf      # Outputs consumed by other modules or root
├── locals.tf       # Local values and computed expressions (optional)
├── data.tf         # Data source lookups (optional)
└── versions.tf     # Required provider versions (optional, if module needs specific versions)
```

---

## State Backend Configuration

### AWS S3

```hcl
terraform {
  backend "s3" {
    bucket         = "myproject-tfstate"
    key            = "env/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "myproject-tfstate-lock"
    encrypt        = true
  }
}
```

### GCP Cloud Storage

```hcl
terraform {
  backend "gcs" {
    bucket = "myproject-tfstate"
    prefix = "env/dev"
  }
}
```

### Azure Blob Storage

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "myproject-tfstate-rg"
    storage_account_name = "myprojecttfstate"
    container_name       = "tfstate"
    key                  = "env/dev/terraform.tfstate"
  }
}
```

### Key Points
- Always use remote state for team collaboration
- Enable encryption at rest
- Use state locking (DynamoDB for AWS, built-in for GCS/Azure)
- Separate state files per environment (different `key` or `prefix`)
- The state backend bucket/container must be created before running `tofu init` (bootstrap manually or with a separate config)

---

## Variable Conventions

### Declaration Pattern

```hcl
variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "instance_type" {
  description = "EC2 instance type for the application server"
  type        = string
  default     = "t3.micro"
}

variable "enable_monitoring" {
  description = "Enable CloudWatch detailed monitoring"
  type        = bool
  default     = false
}

variable "allowed_cidrs" {
  description = "CIDR blocks allowed to access the application"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
```

### Naming Convention
- Use `snake_case` for all variable, resource, and output names
- Prefix sensitive variables: `db_password`, `api_key` (and mark `sensitive = true`)
- Group related variables: `vpc_cidr`, `vpc_name`, `vpc_enable_dns`

### Sensitive Variables

```hcl
variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}
```

---

## Resource Patterns

### Tagging Convention

```hcl
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "opentofu"
    CostCenter  = var.cost_center
  }
}

resource "aws_instance" "app" {
  # ...
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-app"
  })
}
```

### Naming Convention for Resources

```hcl
# Pattern: <project>-<environment>-<role>
resource "aws_instance" "app" {
  tags = {
    Name = "${var.project_name}-${var.environment}-app"
  }
}
```

### Data Source Lookups

```hcl
# Look up existing resources rather than hardcoding IDs
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-24.04-amd64-server-*"]
  }
}
```

---

## Provider Configuration

```hcl
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}
```

---

## Common Resource Patterns

### VPC + Networking (AWS)

```hcl
module "vpc" {
  source = "./modules/networking"

  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
  azs          = var.availability_zones
}
```

### Database (AWS RDS)

```hcl
resource "aws_db_instance" "main" {
  identifier     = "${var.project_name}-${var.environment}-db"
  engine         = "postgres"
  engine_version = "16"
  instance_class = var.db_instance_class

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  allocated_storage     = var.db_storage_gb
  max_allocated_storage = var.db_max_storage_gb

  vpc_security_group_ids = [aws_security_group.db.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  backup_retention_period = var.environment == "prod" ? 30 : 7
  skip_final_snapshot     = var.environment != "prod"
  deletion_protection     = var.environment == "prod"

  tags = local.common_tags
}
```

### Container Service (AWS ECS)

```hcl
resource "aws_ecs_service" "app" {
  name            = "${var.project_name}-${var.environment}-app"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.app_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.vpc.private_subnet_ids
    security_groups  = [aws_security_group.app.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "app"
    container_port   = var.app_port
  }
}
```

---

## Validation Commands

```bash
# Initialize providers and modules
tofu init

# Validate syntax and configuration
tofu validate

# Format check
tofu fmt -check -recursive

# Plan (preview changes)
tofu plan -out=tfplan

# Apply from saved plan
tofu apply tfplan

# Destroy (with confirmation)
tofu destroy
```

---

## Best Practices Summary

1. **State isolation:** One state file per environment. Never share state across environments.
2. **Module everything:** Extract reusable patterns into modules. Root configurations should be thin wrappers.
3. **Pin versions:** Pin provider versions (`~> 5.0`) and lock with `.terraform.lock.hcl` (commit it).
4. **Sensitive values:** Mark secrets as `sensitive = true`. Never commit `.tfvars` files with real secrets.
5. **Remote state:** Always use a remote backend with locking for team collaboration.
6. **Tagging:** Tag every resource for cost tracking, environment identification, and ownership.
7. **Validation:** Add `validation` blocks to variables for early error detection.
8. **Data sources:** Look up existing resources by name/tag rather than hardcoding IDs.
