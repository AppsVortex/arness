# Blast Radius Classification Guide

Guide for classifying the blast radius of infrastructure changes. Used by `arn-infra-change-spec` to assess risk per environment and by `arn-infra-change-planner` to order phases from lowest to highest blast radius. Also read by `arn-infra-change-plan` (cross-skill reference).

---

## Classification Levels

### None

Configuration-only changes with no impact on running infrastructure or dependent services.

**Examples:**
- Updating resource tags or labels
- Changing alert thresholds or notification channels
- Updating DNS TTL values (without changing records)
- Modifying documentation or annotation metadata
- Updating IaC variable descriptions or comments
- Changing monitoring dashboard layouts

**Risk Profile:**

| Operation | Risk |
|-----------|------|
| Create | No risk -- metadata only |
| Modify | No risk -- no runtime impact |
| Destroy | No risk -- metadata removal only |

**Mitigation Strategies:**
- No special mitigation required
- Standard code review is sufficient
- Can be applied during business hours without concern

**Review Gates:**
- Peer review (optional for tag-only changes)
- No approval workflow required

**Rollback Complexity:** Trivial -- revert the configuration change. No state to restore.

---

### Contained

Single resource changes with no downstream dependencies. The change affects one resource in isolation -- if it fails, only that resource is impacted.

**Examples:**
- Resizing a compute instance (CPU/memory)
- Updating a storage class or volume size
- Modifying a single security group rule
- Changing a container image version
- Updating a single environment variable
- Rotating a non-shared secret or certificate
- Scaling a replica count up or down
- Changing a single database parameter (non-restart parameters)

**Risk Profile:**

| Operation | Risk |
|-----------|------|
| Create | Low -- new resource, no disruption to existing infrastructure |
| Modify | Low to moderate -- brief disruption possible during apply (instance restart, container rollout) |
| Destroy | Moderate -- resource removal is irreversible; verify no hidden dependencies first |

**Mitigation Strategies:**
- **Rolling updates:** For compute/container changes, use rolling deployment to maintain availability
- **Snapshot before modify:** Take a snapshot of the resource before applying changes (especially storage and databases)
- **Maintenance window:** Schedule during low-traffic periods for production changes that may cause brief disruption
- **Health check after apply:** Verify the resource is healthy after the change completes

**Review Gates:**
- Peer review required
- No additional approval required for dev/staging
- Team lead approval recommended for production

**Rollback Complexity:** Low -- revert the single resource change or restore from snapshot. Typically under 15 minutes.

---

### Broad

Multi-resource changes or changes affecting shared infrastructure. Multiple resources are modified, or the changed resource is consumed by other services. Failure may cascade to dependent services.

**Examples:**
- VPC CIDR modification or subnet restructuring
- Database migration (schema changes, engine version upgrades)
- Load balancer reconfiguration (listener rules, target groups)
- IAM role restructuring (policies affecting multiple services)
- Kubernetes namespace changes (affecting all pods in the namespace)
- DNS zone record changes (A/AAAA/CNAME for active services)
- Shared secret rotation (secrets consumed by multiple services)
- Service mesh configuration changes
- Container orchestration platform upgrades (ECS task definitions, EKS node groups)

**Risk Profile:**

| Operation | Risk |
|-----------|------|
| Create | Moderate -- new shared resources may conflict with existing topology |
| Modify | High -- changes propagate to dependent resources; cascading failures possible |
| Destroy | High -- removing shared infrastructure disrupts all consumers |

**Mitigation Strategies:**
- **Blue-green deployment:** Stand up the new configuration alongside the existing one, validate, then cut over
- **Canary deployment:** Route a small percentage of traffic to the new configuration before full cutover
- **Feature flags:** Gate application behavior on the new infrastructure behind feature flags
- **Maintenance window:** Schedule during a planned maintenance window with user notification
- **Pre-change snapshot:** Snapshot all affected resources (databases, volumes, configuration state)
- **Dependency mapping:** Document all services consuming the shared resource before making changes
- **Staged rollout:** Apply to one availability zone or region first, validate, then proceed

**Review Gates:**
- Peer review required
- Team lead approval required for all environments
- Infrastructure lead approval required for production
- Notify dependent service owners before applying

**Rollback Complexity:** Moderate to high -- multiple resources must be reverted in dependency order. Data-involved changes may require snapshot restoration. Estimated 30-60 minutes depending on scope.

---

### Critical

Changes affecting production data, network topology, or IAM/access policies with cross-service impact. These changes have the potential to cause widespread outage, data loss, or security exposure if they fail.

**Examples:**
- Database schema migration with destructive data transformation (column drops, type changes)
- VPC peering changes or transit gateway modifications
- Root IAM policy modification or cross-account role changes
- DNS zone delegation changes
- Encryption key rotation for data-at-rest (KMS, CMEK)
- Network ACL or firewall rule changes affecting multiple subnets
- Certificate authority rotation
- Identity provider (IdP) configuration changes
- State backend migration (Terraform/OpenTofu state file relocation)
- Cross-region replication configuration changes
- Production database engine major version upgrade

**Risk Profile:**

| Operation | Risk |
|-----------|------|
| Create | High -- new critical infrastructure may conflict with security boundaries or data flows |
| Modify | Critical -- incorrect changes can cause outage, data loss, or security breach |
| Destroy | Critical -- irreversible removal of critical infrastructure; potential for data loss |

**Mitigation Strategies:**
- **Maintenance window (mandatory):** Schedule during the lowest-traffic period with advance user notification
- **Pre-change backup (mandatory):** Full backup of all affected data stores and configuration state
- **Dry run / what-if:** Execute `tofu plan`, `pulumi preview`, `cdk diff`, or `az deployment what-if` and review the diff line-by-line before applying
- **Staged environment validation:** Apply to dev first, validate for 24+ hours, then staging, then production -- never skip environments
- **Dual-write / shadow mode:** For data migrations, run old and new schemas in parallel before cutover
- **Explicit go/no-go checkpoint:** Require a human go/no-go decision after the dry run, before applying to production
- **Incident response readiness:** Have the rollback procedure documented and tested, with the team available during the change window
- **Communication plan:** Notify all stakeholders (engineering, support, operations) before and after the change

**Review Gates:**
- Peer review required
- Infrastructure lead approval required
- Security team review required (for IAM/encryption/network changes)
- Management sign-off required for production
- Change advisory board (CAB) review if organizational policy requires it

**Rollback Complexity:** High to very high -- may require data restoration from backup, DNS propagation delays, or certificate re-issuance. Some changes have a point of no return after which rollback means restoring from backup rather than reverting. Estimated 1-4 hours depending on the change type and data volume.

---

## Classification Decision Matrix

Use this matrix to quickly classify a change when the examples above do not directly apply.

| Factor | None | Contained | Broad | Critical |
|--------|------|-----------|-------|----------|
| Resources affected | 0 (metadata only) | 1 | 2+ or shared | Any with data/security impact |
| Downstream dependencies | None | None | Yes | Yes, cross-service |
| Data at risk | No data | No data | Possible | Yes |
| Security boundary change | No | No | Possible | Yes |
| Rollback time | Seconds | < 15 min | 30-60 min | 1-4 hours |
| Requires maintenance window | No | No (usually) | Recommended | Mandatory |

**Tie-breaking rules:**
1. If a change involves production data (even one resource), classify as Critical
2. If a change affects IAM policies or encryption keys, classify as Critical
3. If a change affects shared infrastructure (load balancers, DNS, VPCs), classify as Broad at minimum
4. When in doubt, classify one level higher -- it is safer to over-classify than under-classify
5. The same change may have different classifications in different environments (dev: Contained, prod: Critical)

---

## Environment-Specific Adjustments

### Development
- Blast radius is generally lower because dev environments are isolated and disposable
- A "Broad" change in production may be "Contained" in dev if there are no shared dependencies
- Rollback in dev can include full environment teardown and recreation

### Staging
- Classify at the same level as production for changes that need production-like validation
- Staging failures are learning opportunities -- document what went wrong for the production runbook

### Production
- Always use the strictest applicable classification
- Never downgrade a classification for production -- if anything, upgrade it
- All Critical changes in production require the full mitigation strategy checklist
