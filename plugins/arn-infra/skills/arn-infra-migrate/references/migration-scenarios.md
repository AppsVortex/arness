# Migration Scenarios

Detailed reference for each infrastructure migration type. Covers typical motivation, step-by-step process, common pitfalls, rollback strategy, and expected duration.

---

## Scenario 1: Graduate (PaaS to IaC)

Move from platform-as-a-service native configurations to infrastructure-as-code.

### Typical Motivation

- Outgrowing PaaS limitations (custom networking, specific instance types, compliance requirements)
- Cost optimization at scale (PaaS premium becomes significant)
- Need for multi-region deployment
- Compliance requirements that PaaS cannot satisfy (SOC 2, HIPAA, PCI-DSS)
- Team has grown and can manage IaC complexity

### Common Source Platforms

| Platform | Config File | Key Features to Migrate |
|----------|-------------|------------------------|
| Heroku | `Procfile`, `app.json` | Dynos, add-ons, config vars, review apps |
| Fly.io | `fly.toml` | Machines, volumes, secrets, internal networking |
| Railway | `railway.json` | Services, databases, environment variables |
| Render | `render.yaml` | Services, databases, static sites, cron jobs |
| Vercel | `vercel.json` | Functions, edge config, environment variables |
| Netlify | `netlify.toml` | Functions, redirects, build settings |

### Step-by-Step Process

1. **Audit current PaaS deployment**
   - Inventory all services, databases, and add-ons
   - Document environment variables and secrets
   - Record DNS configuration and custom domains
   - Note auto-scaling rules, health checks, and deployment settings
   - Export data from PaaS databases (pg_dump, mongodump, etc.)

2. **Design target architecture**
   - Map PaaS services to cloud provider equivalents:
     - Web dyno/machine --> EC2/Cloud Run/App Service + ALB
     - Managed database --> RDS/Cloud SQL/Azure DB
     - Redis add-on --> ElastiCache/Memorystore/Azure Cache
     - Worker process --> ECS Task/Cloud Run Job/Container Instance
   - Design networking (VPC, subnets, security groups)
   - Plan auto-scaling strategy (ASG, Cloud Run scaling, VMSS)

3. **Generate target IaC**
   - Create IaC modules for each service component
   - Generate environment-specific configs (dev, staging, prod)
   - Configure state backend (remote state for team collaboration)

4. **Deploy to staging**
   - Apply IaC to staging environment
   - Migrate data to staging database
   - Configure DNS for staging (staging.example.com)
   - Run full verification suite

5. **Parallel running (optional but recommended)**
   - Keep PaaS deployment running alongside new infrastructure
   - Split traffic or run smoke tests against both
   - Compare performance metrics

6. **Cutover**
   - Reduce DNS TTL (at least 1 hour before)
   - Final data sync (if database changed during parallel period)
   - Update DNS to point to new infrastructure
   - Monitor for errors during propagation

7. **Decommission PaaS**
   - Verify all traffic on new infrastructure (check PaaS access logs)
   - Cancel PaaS services/add-ons
   - Delete PaaS application (after retention period)

### Common Pitfalls

| Pitfall | Mitigation |
|---------|------------|
| Missing environment variables | Export all config vars before migration, verify in staging |
| Database connection string format differences | Test connection from new infra to new database |
| PaaS-specific features with no direct equivalent | Identify early, implement alternatives (e.g., Heroku review apps --> GitHub Actions preview environments) |
| SSL/TLS certificate management | Set up ACM/Let's Encrypt before cutover |
| Build process differences | Dockerfile replaces PaaS buildpacks -- test thoroughly |
| Add-on API keys | Generate new keys for managed service equivalents |

### Rollback Strategy

1. DNS revert: Point DNS back to PaaS deployment
2. PaaS is still running during cutover window -- no data loss on rollback
3. If database was migrated: restore from pre-cutover backup on PaaS

### Expected Duration

| Project Size | Planning | Implementation | Staging | Cutover | Total |
|-------------|----------|---------------|---------|---------|-------|
| Small (1-2 services) | 1 day | 1-2 days | 1 day | 1 hour | 3-5 days |
| Medium (3-5 services) | 2 days | 3-5 days | 2 days | 2-4 hours | 1-2 weeks |
| Large (5+ services) | 3-5 days | 1-2 weeks | 3-5 days | 4-8 hours | 2-4 weeks |

---

## Scenario 2: Provider Migration (Provider to Provider)

Move services from one cloud provider to another.

### Typical Motivation

- Cost reduction (provider pricing changes, better deals on target)
- Technical requirements (specific services only available on target)
- Geographic requirements (regions only available on target)
- Team expertise alignment (team more familiar with target)
- Vendor risk reduction (avoiding single-provider lock-in)

### Step-by-Step Process

1. **Assess provider lock-in**
   - Identify provider-specific services in use (Lambda, Cloud Functions, Azure Functions)
   - Identify portable services (containers, databases with standard APIs)
   - Map source services to target equivalents
   - Identify services with no equivalent (may need architecture changes)

2. **Design target architecture**
   - Create equivalent architecture on target provider
   - Address service gaps (architect alternatives for non-portable services)
   - Design networking to match or improve current topology
   - Plan IAM/RBAC structure on target

3. **Generate target IaC**
   - Use the target provider's IaC tool (may differ from source)
   - Create modules that mirror source functionality
   - Generate environment configs for all environments

4. **Data migration planning**
   - Database: export/import, replication, or migration service (AWS DMS, GCP Database Migration)
   - Object storage: sync tools (rclone, provider-specific sync)
   - Stateful services: snapshot and restore

5. **Staged migration**
   - Deploy target infrastructure to staging
   - Migrate data to staging target
   - Verify feature parity
   - Deploy to production (parallel running)
   - Cutover (DNS, traffic shift)

6. **Decommission source**
   - Verify all traffic on target
   - Remove source resources
   - Cancel source provider billing

### Common Pitfalls

| Pitfall | Mitigation |
|---------|------------|
| Provider-specific API differences | Use abstraction layers or IaC that targets both |
| Data transfer costs (egress) | Budget for egress fees, use provider migration credits |
| Service naming/configuration differences | Map all configs before migration |
| IAM model differences | Design target IAM from scratch (do not 1:1 translate) |
| Network latency changes | Performance test in staging before cutover |
| Regional availability gaps | Verify target region has all required services |

### Rollback Strategy

1. Source infrastructure remains active until cutover is verified
2. DNS revert within TTL window
3. Data: source database remains read-only during cutover, restore to read-write on rollback

### Expected Duration

| Complexity | Total |
|-----------|-------|
| Simple (containers only, no managed services) | 1-2 weeks |
| Moderate (containers + managed database + storage) | 2-4 weeks |
| Complex (many managed services, provider-specific features) | 1-3 months |

---

## Scenario 3: Consolidation (Many Providers to Fewer)

Reduce the number of cloud providers to simplify operations and reduce costs.

### Typical Motivation

- Operational complexity (too many providers to manage)
- Cost optimization (volume discounts, fewer management overheads)
- Security simplification (fewer IAM systems to manage)
- Compliance simplification (fewer providers to audit)

### Step-by-Step Process

1. **Inventory all providers and services**
   - Read `providers.md` for current provider list with scopes
   - Map each service to its current provider
   - Identify which provider(s) to keep and which to consolidate

2. **Plan consolidation order**
   - Migrate the least critical services first
   - Keep the provider with the most services as the primary target
   - Address dependencies: if Service A on Provider X depends on Service B on Provider Y, migrate B first if Y is being removed

3. **Execute as multiple provider-to-provider migrations**
   - Each provider removal is a separate migration project
   - Track all migrations under a single parent issue
   - Respect dependencies between migrations

4. **Update configuration**
   - Remove consolidated providers from `providers.md`
   - Update the remaining provider's scope
   - Simplify IAM and networking

### Common Pitfalls

| Pitfall | Mitigation |
|---------|------------|
| Hidden dependencies between providers | Map all inter-service communication before starting |
| Multi-provider features (e.g., CDN on Cloudflare, compute on AWS) | Some services may be best left on their current provider |
| Team knowledge gaps on consolidation target | Training before migration |
| Compliance implications of moving data between providers/regions | Legal review for data residency requirements |

### Rollback Strategy

Each sub-migration has its own rollback (source remains active). The consolidation can be partially completed (some providers removed, others kept).

### Expected Duration

Multiply the provider-to-provider timeline by the number of providers being removed. Add 50% for coordination overhead.

---

## Scenario 4: Partial Migration

Move specific services while keeping others in place.

### Typical Motivation

- Cost optimization for specific services (e.g., database is cheaper on Provider B)
- Compliance for specific data (e.g., PII must be in a specific region/provider)
- Performance optimization (e.g., CDN or edge functions closer to users)
- Technology upgrade (e.g., move from self-managed database to managed service)

### Step-by-Step Process

1. **Identify migration scope**
   - Which specific service(s) to migrate
   - Source and target for each service
   - Dependencies with non-migrating services

2. **Design cross-provider connectivity**
   - If migrating a database but keeping compute on the original provider:
     - VPN or VPC peering between providers
     - Public endpoint with firewall rules
     - Connection through a proxy or API gateway
   - Latency implications of cross-provider communication

3. **Execute per-service migration**
   - Each service is a separate migration task
   - Deploy target, verify, migrate data, cutover traffic
   - Update connection strings in non-migrating services

4. **Update provider configuration**
   - Update scope in `providers.md` for both source and target
   - Add the target provider entry if new
   - Do not remove the source provider (it still hosts other services)

### Common Pitfalls

| Pitfall | Mitigation |
|---------|------------|
| Cross-provider latency | Measure latency impact before committing |
| Cross-provider networking complexity | Use standard protocols (HTTPS), avoid provider-specific networking |
| Data transfer costs between providers | Factor into cost comparison |
| Split-brain scenarios during database migration | Use replication with clear primary designation |

### Rollback Strategy

Per-service rollback: revert the specific service to its source provider. Non-migrated services are unaffected.

### Expected Duration

| Service Type | Typical Duration |
|-------------|-----------------|
| Stateless service (API, worker) | 1-3 days |
| Database (with data migration) | 3-7 days |
| Storage (S3, GCS, Blob) | 1-5 days (depends on data volume) |
| Full-stack service (app + DB + cache) | 1-2 weeks |
