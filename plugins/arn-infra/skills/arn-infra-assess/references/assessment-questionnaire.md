# Assessment Questionnaire

Structured questions for infrastructure assessment, organized by category. Each question includes the question text, why it matters, how the answer influences decisions, and a default assumption if the user does not know.

---

## Availability

### Q1: Uptime Requirement
**Question:** "What uptime do you need for your application?"
**Options:**
- 99% (~87.6 hours downtime/year) -- Acceptable for internal tools and dev environments
- 99.9% (~8.7 hours downtime/year) -- Standard for most web applications
- 99.99% (~52 minutes downtime/year) -- Critical for revenue-generating or user-facing services
- 99.999% (~5.2 minutes downtime/year) -- Mission-critical services (banking, healthcare)

**Why it matters:** Higher availability requires redundancy (multi-AZ, load balancers, health checks, auto-restart), which increases cost and complexity.

**How it influences decisions:**
- 99%: Single instance, basic health checks
- 99.9%: Multi-AZ deployment, load balancer, automated restarts
- 99.99%: Multi-region, automated failover, blue-green deployments
- 99.999%: Active-active multi-region, zero-downtime deployments

**Default assumption:** 99.9% (standard for most web applications)

**Beginner version:** "How important is it that your app is always available?"
- Very important (99.9% -- redundant servers, load balancer)
- Somewhat important (99% -- single server with restarts)
- Not critical (basic -- single server, manual restarts acceptable)

---

## Traffic and Scale

### Q2: Expected Traffic
**Question:** "What is your expected traffic volume?"
**Options (offer the most relevant):**
- Concurrent users: [number] (how many users at the same time)
- Requests per second: [number] (if known from load testing or estimates)
- Monthly active users: [number] (total unique users per month)
- Page views per month: [number] (for content sites)

**Why it matters:** Traffic volume determines compute sizing, database tier, caching strategy, and CDN needs.

**How it influences decisions:**
- < 100 concurrent: Smallest compute instance, minimal database
- 100-1000 concurrent: Medium compute, managed database, consider caching
- 1000-10000 concurrent: Multiple instances, load balancer, caching required, CDN recommended
- 10000+: Auto-scaling, CDN required, database read replicas, consider microservices

**Default assumption:** < 100 concurrent users (early-stage application)

**Beginner version:** "How many users do you expect?"
- A few (< 10 at a time)
- Dozens (10-100 at a time)
- Hundreds (100-1000 at a time)
- Thousands or more

### Q3: Traffic Patterns
**Question:** "Do you expect traffic spikes?"
**Options:**
- Steady: Consistent traffic throughout the day
- Daily peaks: Higher during business hours, lower at night
- Seasonal: Peaks during specific times of year (holidays, events)
- Unpredictable: Viral potential, event-driven spikes

**Why it matters:** Spiky traffic requires auto-scaling and may benefit from serverless or pay-per-use pricing.

**How it influences decisions:**
- Steady: Fixed-size compute, reserved instances for cost savings
- Daily peaks: Time-based scaling, or slightly over-provisioned steady state
- Seasonal: Auto-scaling with min/max limits
- Unpredictable: Serverless or aggressive auto-scaling with spend limits

**Default assumption:** Steady (for early-stage applications)

---

## Budget

### Q4: Monthly Budget
**Question:** "What is your monthly infrastructure budget?"
**Options:**
- Specific amount in USD
- "No hard limit" (but cost-consciousness is appreciated)
- "As cheap as possible" (prioritize free tiers and minimal resources)

**Why it matters:** Budget constrains provider choice, instance sizes, and optional features (CDN, monitoring, backups).

**How it influences decisions:**
- < $25/month: Free tiers, smallest instances, PaaS providers (Fly.io, Railway)
- $25-100/month: Small dedicated instances, managed databases, basic monitoring
- $100-500/month: Medium instances, caching, CDN, automated backups
- $500+/month: Production-grade infrastructure, multi-AZ, monitoring, alerting

**Default assumption:** $50/month (reasonable for a small production application)

**Beginner version:** "How much can you spend on infrastructure per month?"
- Free or nearly free (use free tiers as much as possible)
- Up to $25/month
- Up to $100/month
- More than $100/month

---

## Compliance

### Q5: Regulatory Requirements
**Question:** "Are there regulatory or compliance requirements for your application?"
**Options:**
- None
- SOC 2 (service organization controls -- common for SaaS)
- HIPAA (health information -- US healthcare)
- GDPR (data protection -- EU users)
- PCI-DSS (payment card data -- credit card processing)
- Multiple (specify)

**Why it matters:** Compliance requirements mandate specific security controls, data residency, encryption, audit logging, and access management that must be built into the infrastructure from the start.

**How it influences decisions:**
- None: Standard security best practices
- SOC 2: Audit logging, access controls, encryption at rest/in transit, CI/CD-managed deployments
- HIPAA: BAA-eligible services only, encryption everywhere, strict access controls, audit trails
- GDPR: EU data residency, data deletion capabilities, privacy controls
- PCI-DSS: Network segmentation, encrypted cardholder data, penetration testing, audit trails

**Default assumption:** None (no specific compliance requirements)

**Only ask if:** Application handles user personal data, financial transactions, or health information.

---

## Geography

### Q6: Region Requirements
**Question:** "Do you need your application deployed in specific regions?"
**Options:**
- No preference (deploy in the cheapest / closest region)
- Specific region (e.g., US East, EU West, APAC)
- Multi-region (serve users globally with low latency)
- Data residency (data must stay in specific regions for compliance)

**Why it matters:** Region choice affects latency, compliance, cost, and service availability.

**How it influences decisions:**
- No preference: Use the provider's default region (usually US East or EU West)
- Specific region: Deploy all resources in that region
- Multi-region: CDN for static assets, consider multi-region database replication
- Data residency: Must use regions in the required jurisdiction, affects provider choice

**Default assumption:** No preference (single region, provider default)

**Only ask if:** Application serves users in specific markets or has compliance needs (from Q5).

---

## Performance

### Q7: Latency Sensitivity
**Question:** "How latency-sensitive is your application?"
**Options:**
- Not sensitive (content sites, batch processing, internal tools)
- Moderately sensitive (standard web apps, < 500ms response time)
- Highly sensitive (real-time features, trading, gaming, < 100ms response time)

**Why it matters:** Latency requirements influence deployment region, caching strategy, CDN usage, and database proximity.

**How it influences decisions:**
- Not sensitive: Any deployment strategy works
- Moderately sensitive: Same-region database, caching layer, CDN for static assets
- Highly sensitive: Edge deployment, in-memory caching, connection pooling, optimized networking

**Default assumption:** Moderately sensitive (standard web application)

---

## Data

### Q8: Data Volume
**Question:** "How much data will your application store?"
**Options:**
- Minimal (< 1GB -- user profiles, configs, small datasets)
- Moderate (1-100GB -- user content, media, documents)
- Large (100GB-1TB -- logs, analytics, large media libraries)
- Very large (> 1TB -- data pipelines, ML datasets, video)

**Why it matters:** Data volume affects database tier, storage type, backup strategy, and cost.

**How it influences decisions:**
- Minimal: Smallest database tier, basic backup
- Moderate: Standard database tier, automated daily backups
- Large: Larger database tier, consider object storage for media, incremental backups
- Very large: Dedicated storage solutions, lifecycle policies, tiered storage

**Default assumption:** Minimal (early-stage application)

**Only ask if:** Application has data-intensive features (file uploads, analytics, media).

---

## Question Selection Logic

Not all questions are asked every time. The skill selects questions based on:

1. **Always ask:** Q1 (availability), Q2 (traffic), Q4 (budget)
2. **Ask if user-facing app:** Q3 (traffic patterns)
3. **Ask if handles sensitive data:** Q5 (compliance)
4. **Ask if compliance or specific market:** Q6 (geography)
5. **Ask if real-time features detected:** Q7 (latency)
6. **Ask if data-heavy features detected:** Q8 (data volume)

For beginner experience level, use simplified question versions and cap at 4-5 questions total.
