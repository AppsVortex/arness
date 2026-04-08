# Provider Overview

All supported cloud and PaaS providers organized by tier. Tiers reflect tooling maturity and integration depth with Arness Infra.

---

## Tier 1: Full MCP + CLI Support

Providers with mature official MCP servers and CLI tools. Full Arness Infra integration -- direct resource management, state querying, and deployment without leaving the conversation.

### AWS (Amazon Web Services)
- **MCP:** Official AWS MCP server available
- **CLI:** `aws` (AWS CLI v2)
- **Typical use cases:** Full-stack applications, microservices, data-intensive apps, enterprise workloads
- **Arness Infra capabilities:** Full IaC generation (OpenTofu/CDK), container deployment (ECS/EKS/Lambda), RDS/DynamoDB provisioning, S3/CloudFront CDN, VPC networking, IAM management
- **Complexity:** High
- **Beginner-friendliness:** Expert-only (use Fly.io or Railway instead for simple apps)

### GCP (Google Cloud Platform)
- **MCP:** Official GCP MCP server available
- **CLI:** `gcloud` (Google Cloud SDK)
- **Typical use cases:** Data/ML workloads, Kubernetes (GKE), serverless (Cloud Run/Functions), Firebase integrations
- **Arness Infra capabilities:** Full IaC generation, Cloud Run deployment, GKE management, Cloud SQL/Firestore, Cloud Storage/CDN
- **Complexity:** High
- **Beginner-friendliness:** Expert-only (Cloud Run is intermediate-friendly)

### Azure (Microsoft Azure)
- **MCP:** Official Azure MCP server available
- **CLI:** `az` (Azure CLI)
- **Typical use cases:** Enterprise .NET workloads, hybrid cloud, Active Directory integration, Azure DevOps
- **Arness Infra capabilities:** Full IaC generation (OpenTofu/Bicep), App Service deployment, AKS management, Azure SQL/Cosmos DB, Blob Storage/CDN
- **Complexity:** High
- **Beginner-friendliness:** Expert-only (App Service is intermediate-friendly)

### Cloudflare
- **MCP:** Official Cloudflare MCP server available
- **CLI:** `wrangler` (Cloudflare Workers CLI)
- **Typical use cases:** Edge computing (Workers), DNS management, CDN, DDoS protection, R2 storage
- **Arness Infra capabilities:** Workers deployment, DNS configuration, R2 storage setup, Pages deployment
- **Complexity:** Medium
- **Beginner-friendliness:** Suitable with guidance (Pages and Workers are developer-friendly)

---

## Tier 2: MCP or CLI with Good Coverage

Providers with either an MCP server or a well-documented CLI. Good Arness Infra integration for their target use cases.

### DigitalOcean
- **MCP:** Community MCP available
- **CLI:** `doctl` (DigitalOcean CLI)
- **Typical use cases:** Simple web apps, Kubernetes (DOKS), managed databases, object storage
- **Arness Infra capabilities:** Droplet/App Platform deployment, DOKS management, managed DB provisioning, Spaces storage
- **Complexity:** Medium
- **Beginner-friendliness:** Suitable with guidance

### Fly.io
- **MCP:** Community MCP available
- **CLI:** `fly` (flyctl)
- **Typical use cases:** Full-stack web apps, API services, databases (Fly Postgres), global edge deployment
- **Arness Infra capabilities:** Platform-native deployment (`fly.toml`), Fly Postgres provisioning, multi-region configuration, auto-scaling
- **Complexity:** Low
- **Beginner-friendliness:** Recommended for beginners (simple CLI, straightforward pricing, good docs)

### Vercel
- **MCP:** Official Vercel MCP server available
- **CLI:** `vercel` (Vercel CLI)
- **Typical use cases:** Next.js apps, static sites, serverless functions, edge middleware
- **Arness Infra capabilities:** Platform-native deployment (`vercel.json`), environment variable management, domain configuration
- **Complexity:** Low
- **Beginner-friendliness:** Recommended for beginners (zero-config for supported frameworks)

### Netlify
- **MCP:** Community MCP available
- **CLI:** `netlify` (Netlify CLI)
- **Typical use cases:** Static sites, JAMstack apps, serverless functions, form handling
- **Arness Infra capabilities:** Platform-native deployment (`netlify.toml`), build configuration, serverless functions, edge functions
- **Complexity:** Low
- **Beginner-friendliness:** Recommended for beginners (simple deploy flow)

---

## Tier 3: Limited or Experimental Support

Providers with CLI support but limited or no MCP integration. Arness Infra generates configs and provides guidance but has less direct integration.

### Scaleway
- **MCP:** None
- **CLI:** `scw` (Scaleway CLI)
- **Typical use cases:** European cloud hosting, Kubernetes (Kapsule), managed databases, object storage
- **Arness Infra capabilities:** IaC generation via OpenTofu (Scaleway provider), CLI-based deployment
- **Complexity:** Medium
- **Beginner-friendliness:** Expert-only

### Railway
- **MCP:** None
- **CLI:** `railway` (Railway CLI)
- **Typical use cases:** Full-stack web apps, API services, databases, background workers, monorepo deploys
- **Arness Infra capabilities:** Platform-native deployment (`railway.json`), environment variable management, service linking
- **Complexity:** Low
- **Beginner-friendliness:** Recommended for beginners (GitHub-connected deploy, simple pricing per-usage)

### Render
- **MCP:** None
- **CLI:** Limited (`render` CLI is basic)
- **Typical use cases:** Web services, static sites, background workers, managed PostgreSQL, Redis
- **Arness Infra capabilities:** Platform-native deployment (`render.yaml`), blueprint-based infrastructure definition
- **Complexity:** Low
- **Beginner-friendliness:** Recommended for beginners (straightforward dashboard and config)

---

## Provider Selection Guide

| Need | Beginner | Intermediate | Expert |
|------|----------|--------------|--------|
| Static site / SPA | Vercel, Netlify | Vercel, Netlify | Any |
| Full-stack web app | Fly.io, Railway | Fly.io, DigitalOcean | AWS, GCP, Azure |
| API service | Fly.io, Railway | Fly.io, DigitalOcean | AWS, GCP, Azure |
| Microservices | Railway | DigitalOcean (DOKS) | AWS (EKS), GCP (GKE) |
| Data/ML workloads | -- (not recommended) | GCP | GCP, AWS |
| Enterprise / compliance | -- (not recommended) | Azure | AWS, Azure, GCP |
| Edge / CDN | Vercel, Netlify | Cloudflare | Cloudflare |
| Budget-conscious | Railway, Render | Fly.io, DigitalOcean | Any (right-sizing) |
