# Backlog Item Template

Template for individual infrastructure backlog items published as issues by `arn-infra-assess`. Each item represents a single infrastructure component or change that needs to be implemented.

---

## Template

```markdown
## [Component Name]

**Priority:** Foundation | Core | Enhancement
**Category:** Compute | Database | Storage | Networking | Security | Monitoring | CDN | Scaling

---

### Purpose
[Why the application needs this infrastructure component. 1-3 sentences.]

### Provider Recommendation
**Provider:** [Recommended provider and service]
**Alternative:** [Alternative provider/service if applicable]
**Rationale:** [Why this provider/service was recommended]

### Resource Specification
[Specific resource configuration details]

| Parameter | Value | Notes |
|-----------|-------|-------|
| [e.g., Instance type] | [e.g., t3.micro] | [e.g., Sufficient for < 100 concurrent users] |
| [e.g., Storage] | [e.g., 20GB SSD] | [e.g., With auto-expansion enabled] |
| [e.g., Region] | [e.g., us-east-1] | [e.g., Closest to primary user base] |

### Estimated Monthly Cost
**Low estimate:** $[amount] (minimal usage)
**Expected estimate:** $[amount] (typical usage)
**High estimate:** $[amount] (peak usage)

**Cost notes:** [Any caveats about pricing -- free tier eligibility, usage-based components, etc.]

### Dependencies
[Other backlog items or existing infrastructure that must be in place before this item]
- [e.g., VPC and subnet configuration (Foundation item)]
- [e.g., DNS zone setup (Foundation item)]
- [e.g., None -- can be implemented independently]

### Implementation Notes
[Guidance for the developer or Arness Infra skills on how to implement this]
- [e.g., Use OpenTofu module in `infra/modules/database/`]
- [e.g., Add connection string to environment variables: `DATABASE_URL`]
- [e.g., Run database migrations after provisioning]

### Implications Brief (Embedded)
[If this item was derived from a feature analysis, embed the relevant section of the implications brief here so `arn-infra-triage` can skip re-analysis]

**Related feature:** [Feature name or "General infrastructure"]
**New resources:** [Brief list]
**Estimated cost:** $[amount]/month
```

---

## Example: PostgreSQL Database (Foundation)

```markdown
## PostgreSQL Database

**Priority:** Foundation
**Category:** Database

---

### Purpose
Primary data store for user accounts, application data, and session management. Required by the authentication, user profile, and content management features.

### Provider Recommendation
**Provider:** Fly.io Postgres (Fly Postgres)
**Alternative:** AWS RDS PostgreSQL, Railway PostgreSQL
**Rationale:** Fly Postgres integrates natively with Fly.io compute, includes automated backups, and is simple to provision via `fly postgres create`. Matches the beginner-friendly provider recommendation.

### Resource Specification

| Parameter | Value | Notes |
|-----------|-------|-------|
| Engine | PostgreSQL 16 | Latest stable release |
| Plan | Development (shared CPU, 256MB RAM) | Upgrade to Production for > 100 concurrent connections |
| Storage | 1GB initial (auto-expanding) | Fly Postgres auto-expands storage |
| High availability | No (single node for dev/staging) | Enable HA for production |
| Backups | Daily automated | Included with Fly Postgres |

### Estimated Monthly Cost
**Low estimate:** $0 (within Fly.io free tier for hobby projects)
**Expected estimate:** $7/month (Development plan)
**High estimate:** $29/month (Production plan with HA)

**Cost notes:** Fly.io offers a free tier for small databases. Development plan is sufficient for most early-stage applications. Upgrade to Production plan when approaching production traffic.

### Dependencies
- None -- this is a Foundation item with no infrastructure prerequisites on Fly.io

### Implementation Notes
- Provision via `fly postgres create --name [app]-db --region [region]`
- Attach to the application: `fly postgres attach [app]-db`
- Connection string is automatically injected as `DATABASE_URL`
- Run application database migrations after provisioning
- For OpenTofu users: use the `fly_postgres_cluster` resource

### Implications Brief (Embedded)

**Related feature:** General infrastructure (authentication, user management, content)
**New resources:** PostgreSQL database instance
**Estimated cost:** $0-29/month depending on plan
```

---

## Example: Redis Cache (Core)

```markdown
## Redis Cache

**Priority:** Core
**Category:** Database

---

### Purpose
In-memory cache for session management, rate limiting, and frequently accessed data. Reduces database load and improves response times for authenticated requests.

### Provider Recommendation
**Provider:** Fly.io Redis (Upstash Redis)
**Alternative:** AWS ElastiCache, Railway Redis
**Rationale:** Upstash Redis on Fly.io provides serverless Redis with pay-per-command pricing, making it cost-effective for low-traffic applications. No idle cost.

### Resource Specification

| Parameter | Value | Notes |
|-----------|-------|-------|
| Engine | Redis 7 | Latest stable |
| Type | Serverless (Upstash) | Pay-per-command, no idle cost |
| Max memory | 256MB | Sufficient for session cache |
| Eviction policy | allkeys-lru | Least recently used eviction |
| Persistence | No (cache only) | Sessions can be recreated |

### Estimated Monthly Cost
**Low estimate:** $0 (within free tier for < 10K commands/day)
**Expected estimate:** $3/month (typical session cache usage)
**High estimate:** $10/month (high traffic with frequent cache operations)

**Cost notes:** Upstash Redis charges per command with a generous free tier. Cost scales linearly with usage.

### Dependencies
- Application service must be deployed (Foundation item)
- No other infrastructure dependencies

### Implementation Notes
- Provision via Upstash dashboard or `fly redis create`
- Add `REDIS_URL` environment variable to the application
- Update session middleware to use Redis instead of in-memory storage
- Consider connection pooling for high-traffic scenarios
```

---

## Priority Guidelines

| Priority | Criteria | Examples |
|----------|----------|---------|
| **Foundation** | Application cannot run without it. Must be provisioned first. | Compute, primary database, networking, DNS/SSL |
| **Core** | Application runs without it but has significant limitations. Should be added for production readiness. | Caching, object storage, job queues, monitoring |
| **Enhancement** | Improves performance, reliability, or cost-efficiency. Can be added incrementally. | CDN, auto-scaling, backup/DR, multi-region |

---

## Notes

- Each backlog item becomes a separate issue in the tracker for independent tracking
- Items within the same priority level can be implemented in any order unless they have explicit dependencies
- The embedded implications brief allows `arn-infra-triage` to skip re-analysis when picking up a backlog item
- Cost estimates use the user's configured provider; alternatives are noted for reference
- Specification values are starting recommendations -- the user should adjust based on their specific requirements
