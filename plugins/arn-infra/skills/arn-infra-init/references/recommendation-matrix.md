# Recommendation Matrix

Maps (experience level x application type) to recommended provider + IaC tool. Used by `arn-infra-init` during the adaptive configuration flow (Step 3).

---

## Matrix

| App Type | Beginner | Intermediate | Expert |
|----------|----------|--------------|--------|
| Static site / SPA | Vercel or Netlify (no IaC) | Vercel or Netlify (no IaC) | User's choice |
| Web app (SSR) | Fly.io or Railway (platform config) | Fly.io (platform config) or OpenTofu | User's choice |
| API / web service | Fly.io or Railway (platform config) | OpenTofu (single provider) | User's choice |
| Microservices | Railway (platform config) | OpenTofu + basic K8s | User's choice |
| Workers / queues | Railway (platform config) | OpenTofu | User's choice |
| Full-stack (frontend + API + DB) | Fly.io or Railway (platform config) | OpenTofu | User's choice |
| Data / ML pipeline | Railway (platform config) | GCP with OpenTofu | User's choice |
| Enterprise / compliance | Not recommended -- suggest intermediate | Azure or AWS with OpenTofu | User's choice |

---

## Detailed Rationale

### Static site / SPA
- **Beginner:** Vercel and Netlify offer zero-config deployment for most frameworks (Next.js, React, Vue, Svelte). No IaC needed -- `vercel.json` or `netlify.toml` handles everything. Free tiers are generous.
- **Intermediate:** Same recommendation. These platforms are the best tool for this job regardless of experience.
- **Expert:** Full flexibility. May prefer Cloudflare Pages, S3+CloudFront, or custom CDN setup.

### Web app (SSR)
- **Beginner:** Fly.io offers simple `fly.toml` config with built-in Postgres. Railway provides similar simplicity with GitHub-connected deploys. Both handle SSL, networking, and scaling automatically.
- **Intermediate:** Fly.io with platform config for simpler apps, or OpenTofu for more control. OpenTofu enables managing the full stack (compute, database, networking) as code.
- **Expert:** Full choice. May prefer AWS (ECS/Lambda), GCP (Cloud Run), or Kubernetes.

### API / web service
- **Beginner:** Fly.io or Railway. Both support containerized API services with minimal config. Railway's per-usage pricing is transparent.
- **Intermediate:** OpenTofu for a single cloud provider. Provides full control over compute, networking, and database resources while maintaining reproducibility.
- **Expert:** Full choice. Typically AWS (ECS, Lambda, API Gateway) or GCP (Cloud Run).

### Microservices
- **Beginner:** Railway supports multiple services in a single project with service linking. Simpler than managing separate deployments.
- **Intermediate:** OpenTofu for cloud resources + basic Kubernetes manifests for service orchestration. DigitalOcean Kubernetes (DOKS) is a good intermediate option.
- **Expert:** Full choice. AWS EKS, GCP GKE, or self-managed Kubernetes with Helm.

### Workers / queues
- **Beginner:** Railway supports background workers and cron jobs natively. No queue infrastructure to manage.
- **Intermediate:** OpenTofu for provisioning managed queue services (SQS, Cloud Tasks, Azure Queue) alongside worker compute.
- **Expert:** Full choice. Often combined with the main application's provider.

### Full-stack (frontend + API + DB)
- **Beginner:** Fly.io handles all three (frontend via static assets or SSR, API via container, Postgres built-in). Railway similarly handles full-stack deployments.
- **Intermediate:** OpenTofu manages the complete stack. May split providers (Vercel for frontend, AWS for backend) with OpenTofu managing the backend.
- **Expert:** Full choice. Multi-provider splits are common (Vercel + AWS, Netlify + GCP).

### Data / ML pipeline
- **Beginner:** Railway can run data processing workers, but this category is generally beyond beginner scope. Suggest consulting with an infrastructure-experienced colleague.
- **Intermediate:** GCP offers the strongest ML/data platform (BigQuery, Vertex AI, Dataflow). OpenTofu manages the infrastructure.
- **Expert:** Full choice. GCP, AWS (SageMaker, EMR), or Azure (ML Studio).

### Enterprise / compliance
- **Beginner:** Enterprise infrastructure requires understanding of compliance frameworks, IAM, networking, and audit requirements. Not recommended for beginners -- suggest pairing with an experienced infrastructure engineer.
- **Intermediate:** Azure or AWS with OpenTofu. Both have compliance certifications (SOC 2, HIPAA, PCI DSS) and managed compliance tools.
- **Expert:** Full choice. Provider often dictated by organizational requirements.

---

## Multi-Provider Split Recommendations

For applications with multiple components that benefit from different providers:

| Frontend | Backend / API | Database | Workers | Recommended Split |
|----------|---------------|----------|---------|-------------------|
| Static/SPA | REST API | PostgreSQL | None | Vercel (frontend) + Fly.io (API + DB) |
| SSR (Next.js) | API routes | PostgreSQL | None | Vercel (all-in-one) |
| Static/SPA | REST API | PostgreSQL | Background jobs | Vercel (frontend) + Railway (API + DB + workers) |
| Static/SPA | Microservices | Multiple | Queue workers | Vercel/Netlify (frontend) + AWS/GCP (everything else) |
| SSR | GraphQL | PostgreSQL + Redis | Cron jobs | Fly.io (all-in-one with multi-process) |

---

## IaC Tool Pairing

| Provider Category | Recommended IaC Tool |
|-------------------|---------------------|
| PaaS (Fly.io, Railway, Render, Vercel, Netlify) | None (platform-native config) |
| AWS | OpenTofu or CDK |
| GCP | OpenTofu |
| Azure | OpenTofu or Bicep |
| DigitalOcean | OpenTofu |
| Cloudflare | OpenTofu or Wrangler config |
| Multi-provider | OpenTofu (unified tooling) |
| Kubernetes-heavy | OpenTofu (infrastructure) + Helm (workloads) |
