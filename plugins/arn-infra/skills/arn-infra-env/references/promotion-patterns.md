# Promotion Patterns

Deployment promotion strategies for moving infrastructure changes through environments (dev --> staging --> production) with IaC implementation, risk assessment, and rollback procedures.

---

## Rolling Update

Changes are applied incrementally, replacing old resources with new ones one at a time.

### How It Works

1. Infrastructure change is applied to the first resource (e.g., first instance in an auto-scaling group)
2. Health checks verify the updated resource is healthy
3. Process continues to the next resource until all are updated
4. If a health check fails, the rollout pauses

### IaC Implementation

**OpenTofu/Terraform:**
```hcl
resource "aws_autoscaling_group" "app" {
  max_size         = var.max_size
  min_size         = var.min_size
  desired_capacity = var.desired_capacity

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 90
      instance_warmup        = 300
    }
  }
}
```

**Kubernetes:**
```yaml
apiVersion: apps/v1
kind: Deployment
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
```

| Aspect | Detail |
|--------|--------|
| Risk level | Low -- gradual replacement with health checks |
| Downtime | Zero (when configured correctly) |
| Rollback | Moderate -- apply the previous configuration |
| Resource cost | Minimal overhead during rollout (1 extra instance) |
| Best for | Most workloads, stateless services |

---

## Blue-Green Deployment

Two identical environments ("blue" and "green") are maintained. Traffic switches between them.

### How It Works

1. Current version runs on "blue" environment
2. New version is deployed to "green" environment
3. Health checks and tests run against "green"
4. Traffic is switched from "blue" to "green" (DNS, load balancer, or router change)
5. "Blue" is kept as fallback until next deployment

### IaC Implementation

**OpenTofu/Terraform (AWS ALB):**
```hcl
resource "aws_lb_target_group" "blue" {
  name     = "${var.app}-blue"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/health"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
  }
}

resource "aws_lb_target_group" "green" {
  name     = "${var.app}-green"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/health"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
  }
}

resource "aws_lb_listener_rule" "app" {
  listener_arn = var.listener_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = var.active_color == "blue" ? aws_lb_target_group.blue.arn : aws_lb_target_group.green.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}
```

**Kubernetes:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: myapp
spec:
  selector:
    app: myapp
    version: green  # Switch by changing this label
  ports:
    - port: 80
```

| Aspect | Detail |
|--------|--------|
| Risk level | Low -- full environment tested before traffic switch |
| Downtime | Zero |
| Rollback | Instant -- switch traffic back to the previous color |
| Resource cost | High -- double the resources during transition |
| Best for | Critical production workloads, databases with schema changes |

---

## Canary Deployment

A small percentage of traffic is sent to the new version first, then gradually increased.

### How It Works

1. Deploy the new version alongside the current version
2. Route a small percentage (e.g., 5%) of traffic to the new version
3. Monitor error rates, latency, and resource usage
4. If metrics are healthy, gradually increase traffic (10%, 25%, 50%, 100%)
5. If metrics degrade, roll back and route all traffic to the current version

### IaC Implementation

**OpenTofu/Terraform (AWS ALB weighted routing):**
```hcl
resource "aws_lb_listener_rule" "canary" {
  listener_arn = var.listener_arn
  priority     = 100

  action {
    type = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.stable.arn
        weight = var.stable_weight  # e.g., 95
      }
      target_group {
        arn    = aws_lb_target_group.canary.arn
        weight = var.canary_weight  # e.g., 5
      }
    }
  }
}
```

**Kubernetes (Istio):**
```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
spec:
  hosts: [myapp]
  http:
    - route:
        - destination:
            host: myapp
            subset: stable
          weight: 95
        - destination:
            host: myapp
            subset: canary
          weight: 5
```

| Aspect | Detail |
|--------|--------|
| Risk level | Very low -- limited blast radius for issues |
| Downtime | Zero |
| Rollback | Fast -- remove canary traffic routing |
| Resource cost | Low -- only a small canary instance/pod needed |
| Best for | High-traffic services, risk-averse deployments |
| Prerequisite | Weighted routing support (ALB, Istio, Nginx, Envoy) |

---

## Feature Flags

Infrastructure changes are deployed but gated behind feature flags that control activation.

### How It Works

1. Deploy infrastructure change to all environments
2. Change is inactive by default (behind a feature flag)
3. Enable the flag in dev/staging for testing
4. Enable the flag in production when verified
5. If issues arise, disable the flag (no redeployment needed)

### IaC Implementation

**OpenTofu/Terraform:**
```hcl
variable "enable_new_cache" {
  description = "Feature flag: enable Redis cache cluster"
  type        = bool
  default     = false
}

resource "aws_elasticache_cluster" "cache" {
  count                = var.enable_new_cache ? 1 : 0
  cluster_id           = "${var.environment}-cache"
  engine               = "redis"
  node_type            = var.cache_node_type
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
}
```

**Environment-specific flags:**
```hcl
# environments/dev.tfvars
enable_new_cache = true

# environments/staging.tfvars
enable_new_cache = true

# environments/production.tfvars
enable_new_cache = false  # Enable when ready
```

| Aspect | Detail |
|--------|--------|
| Risk level | Very low -- changes are deployed but inactive |
| Downtime | Zero |
| Rollback | Instant -- toggle the flag off |
| Resource cost | None until activated |
| Best for | Gradual infrastructure rollouts, A/B testing infrastructure |
| Trade-off | Adds conditional complexity to IaC code |

---

## Promotion Pipeline Configurations

### Standard Three-Stage Pipeline

```
Dev (auto-deploy) --> Staging (manual trigger) --> Production (approval required)
```

| Transition | Trigger | Strategy | Approval |
|-----------|---------|----------|----------|
| Code merge --> Dev | Automatic | Rolling | None |
| Dev --> Staging | Manual trigger | Rolling | None |
| Staging --> Prod | Manual trigger | Rolling or Blue-Green | 1+ reviewer |

### Fast Two-Stage Pipeline

```
Staging (auto-deploy on merge) --> Production (approval required)
```

| Transition | Trigger | Strategy | Approval |
|-----------|---------|----------|----------|
| Merge to main --> Staging | Automatic | Rolling | None |
| Staging --> Prod | Manual trigger | Rolling | 1+ reviewer |

### Conservative Pipeline

```
Dev (auto) --> QA (manual) --> Staging (manual) --> Prod (approval + canary)
```

| Transition | Trigger | Strategy | Approval |
|-----------|---------|----------|----------|
| Code merge --> Dev | Automatic | Rolling | None |
| Dev --> QA | Manual trigger | Rolling | None |
| QA --> Staging | Manual trigger | Rolling | 1 reviewer |
| Staging --> Prod | Manual trigger | Canary (5% --> 25% --> 100%) | 2+ reviewers |

---

## Rollback Procedures

### IaC Rollback (OpenTofu/Terraform)

```bash
# Option 1: Apply previous state
git revert <commit-sha>  # Revert the IaC change
tofu plan                 # Verify the revert plan
tofu apply                # Apply the reverted configuration

# Option 2: Use state snapshot (if available)
tofu state pull > current-state.json  # Backup current
# Restore from previous state backup
```

### Kubernetes Rollback

```bash
kubectl rollout undo deployment/myapp -n myapp-staging
kubectl rollout status deployment/myapp -n myapp-staging
```

### PaaS Rollback

```bash
# Fly.io
fly releases -a myapp-staging
fly deploy --image <previous-image> -a myapp-staging

# Railway / Render / Vercel
# Use platform UI to redeploy previous version
```

### Automated Rollback Rules

Configure auto-rollback based on health checks:
- HTTP health check fails for N consecutive checks
- Error rate exceeds threshold (e.g., > 5% of requests)
- Latency exceeds threshold (e.g., p99 > 2s)
- Resource usage exceeds limits (CPU > 95%, memory > 95%)
