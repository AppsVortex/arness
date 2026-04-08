# PaaS Configuration Patterns

Platform-native configuration patterns for PaaS providers. These configs are generated for beginner-level users who deploy to managed platforms without full IaC tooling. Each pattern shows the complete config file format with security best practices and health check configuration.

---

## Fly.io (fly.toml)

### Web Application

```toml
app = "myapp"
primary_region = "iad"
kill_signal = "SIGINT"
kill_timeout = "5s"

[build]
  dockerfile = "Dockerfile"

[env]
  PORT = "8080"
  NODE_ENV = "production"

[http_service]
  internal_port = 8080
  force_https = true
  auto_stop_machines = "stop"
  auto_start_machines = true
  min_machines_running = 1

  [http_service.concurrency]
    type = "requests"
    hard_limit = 250
    soft_limit = 200

[[vm]]
  size = "shared-cpu-1x"
  memory = "256mb"

[checks]
  [checks.health]
    type = "http"
    port = 8080
    path = "/health"
    interval = "30s"
    timeout = "5s"
    grace_period = "10s"
```

### With PostgreSQL

```toml
# After creating the app, attach a Postgres cluster:
# fly postgres create --name myapp-db
# fly postgres attach myapp-db

# The DATABASE_URL secret is automatically set by Fly
```

### Key Points
- `primary_region` determines the default deployment region
- `auto_stop_machines` saves costs by stopping idle machines
- `min_machines_running` keeps at least N machines always running
- Secrets are set via `fly secrets set KEY=value` (never in `fly.toml`)
- Postgres is managed via `fly postgres` commands

---

## Railway (railway.json)

### Web Application

```json
{
  "$schema": "https://railway.com/railway.schema.json",
  "build": {
    "builder": "DOCKERFILE",
    "dockerfilePath": "Dockerfile"
  },
  "deploy": {
    "startCommand": "node dist/index.js",
    "healthcheckPath": "/health",
    "healthcheckTimeout": 30,
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 3
  }
}
```

### With Nixpacks (Auto-Detect)

```json
{
  "$schema": "https://railway.com/railway.schema.json",
  "build": {
    "builder": "NIXPACKS"
  },
  "deploy": {
    "healthcheckPath": "/health",
    "healthcheckTimeout": 30,
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 3
  }
}
```

### Key Points
- Railway auto-detects the build system with Nixpacks by default
- Use `DOCKERFILE` builder for custom Dockerfiles
- Environment variables are set in the Railway dashboard or via `railway variables set`
- Database services (PostgreSQL, Redis, MySQL) are added via the dashboard
- The `PORT` environment variable is automatically injected by Railway

---

## Render (render.yaml)

### Web Application with Database

```yaml
services:
  - type: web
    name: myapp
    runtime: docker
    dockerfilePath: ./Dockerfile
    dockerContext: .
    envVars:
      - key: NODE_ENV
        value: production
      - key: DATABASE_URL
        fromDatabase:
          name: myapp-db
          property: connectionString
    healthCheckPath: /health
    autoDeploy: true
    plan: starter

databases:
  - name: myapp-db
    plan: starter
    databaseName: appdb
    user: app
    ipAllowList: []
```

### Static Site

```yaml
services:
  - type: web
    name: myapp-frontend
    runtime: static
    buildCommand: npm run build
    staticPublishPath: ./dist
    headers:
      - path: /*
        name: X-Content-Type-Options
        value: nosniff
    routes:
      - type: rewrite
        source: /*
        destination: /index.html
```

### Background Worker

```yaml
services:
  - type: worker
    name: myapp-worker
    runtime: docker
    dockerfilePath: ./Dockerfile
    dockerContext: .
    envVars:
      - key: WORKER_MODE
        value: "true"
      - key: REDIS_URL
        fromService:
          name: myapp-cache
          type: redis
          property: connectionString
```

### Key Points
- `render.yaml` is an Infrastructure-as-Code blueprint for Render
- Environment variables can reference other services and databases using `fromDatabase` / `fromService`
- Secrets are managed via the dashboard or `fromService` references
- Plans determine instance size: `free`, `starter`, `standard`, `pro`
- Auto-deploy triggers on push to the configured branch

---

## Vercel (vercel.json)

### Next.js / React Application

```json
{
  "$schema": "https://openapi.vercel.sh/vercel.json",
  "framework": "nextjs",
  "buildCommand": "npm run build",
  "outputDirectory": ".next",
  "regions": ["iad1"],
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        { "key": "X-Content-Type-Options", "value": "nosniff" },
        { "key": "X-Frame-Options", "value": "DENY" },
        { "key": "Referrer-Policy", "value": "strict-origin-when-cross-origin" }
      ]
    }
  ],
  "rewrites": [
    {
      "source": "/api/:path*",
      "destination": "/api/:path*"
    }
  ],
  "crons": [
    {
      "path": "/api/cron/cleanup",
      "schedule": "0 0 * * *"
    }
  ]
}
```

### Static Export

```json
{
  "$schema": "https://openapi.vercel.sh/vercel.json",
  "buildCommand": "npm run build",
  "outputDirectory": "dist",
  "cleanUrls": true,
  "trailingSlash": false,
  "headers": [
    {
      "source": "/assets/(.*)",
      "headers": [
        { "key": "Cache-Control", "value": "public, max-age=31536000, immutable" }
      ]
    }
  ]
}
```

### Key Points
- Vercel auto-detects many frameworks (Next.js, Remix, SvelteKit, Nuxt, etc.)
- `vercel.json` is optional for standard setups -- only needed for custom behavior
- Environment variables are set via the Vercel dashboard or `vercel env add`
- Serverless functions live in `api/` directory by default
- Edge functions use the `edge` runtime in the function file
- Regions control where serverless functions execute

---

## Netlify (netlify.toml)

### Static Site with Build

```toml
[build]
  command = "npm run build"
  publish = "dist"

[build.environment]
  NODE_VERSION = "22"

# Production context
[context.production]
  command = "npm run build"

# Staging context (deploy previews)
[context.deploy-preview]
  command = "npm run build"

[context.deploy-preview.environment]
  NEXT_PUBLIC_API_URL = "https://staging-api.myapp.com"

# Security headers
[[headers]]
  for = "/*"
  [headers.values]
    X-Content-Type-Options = "nosniff"
    X-Frame-Options = "DENY"
    Referrer-Policy = "strict-origin-when-cross-origin"
    Content-Security-Policy = "default-src 'self'"

# Cache static assets
[[headers]]
  for = "/assets/*"
  [headers.values]
    Cache-Control = "public, max-age=31536000, immutable"

# SPA routing
[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200

# Serverless functions
[functions]
  directory = "netlify/functions"
  node_bundler = "esbuild"
```

### Key Points
- Netlify auto-detects build commands for common frameworks
- Context-specific settings override defaults for different deploy scenarios
- Redirects and rewrites handle SPA routing
- Functions live in `netlify/functions/` by default
- Environment variables are set via the Netlify dashboard or `netlify env:set`
- Build plugins extend functionality (caching, notifications, etc.)

---

## Choosing a Platform (Decision Guide)

| Criteria | Fly.io | Railway | Render | Vercel | Netlify |
|----------|--------|---------|--------|--------|---------|
| Best for | Docker containers, full-stack | Full-stack, rapid prototyping | Full-stack, managed DBs | Frontend, serverless | Static sites, JAMstack |
| Databases | Managed Postgres | Postgres, Redis, MySQL | Managed Postgres, Redis | External only | External only |
| Docker support | Native | Native | Native | No | No |
| Serverless functions | Machines | Yes | Yes | Yes | Yes |
| Global edge | Yes | Limited | Limited | Yes | Yes |
| Free tier | Yes (limited) | Yes (limited) | Yes (limited) | Yes (limited) | Yes (limited) |
| Custom domains | Yes | Yes | Yes | Yes | Yes |
| Auto-scaling | Machine-based | Yes | Yes | Automatic | Automatic |

---

## General PaaS Best Practices

1. **Never commit secrets:** Use the platform's secret/environment variable management.
2. **Health checks:** Always configure a health check endpoint for zero-downtime deploys.
3. **Build from Dockerfile:** When available, prefer Dockerfile builds for reproducibility.
4. **Pin runtime versions:** Specify Node.js, Python, etc. versions explicitly.
5. **Security headers:** Configure security headers (CSP, X-Frame-Options, etc.) at the platform level.
6. **Domain and TLS:** All platforms provide automatic TLS. Configure custom domains through the platform dashboard.
7. **Monitoring:** Use the platform's built-in monitoring. Add external monitoring (Sentry, Datadog) for production.
