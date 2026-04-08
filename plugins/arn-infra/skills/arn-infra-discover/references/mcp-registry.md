# MCP Registry

Curated registry of known provider MCP servers for infrastructure management. This is the starting point for discovery -- `arn-infra-discover` Phase B supplements it with online searches for new official tools.

---

## AWS

### AWS MCP Server
- **Package:** `@aws/mcp-server` (or `awslabs/mcp`)
- **Provider:** AWS
- **Official:** Yes (published by AWS)
- **Capability tier:** Full (resource CRUD, state querying, deployment)
- **Maturity:** Production
- **Install command:** `npm install -g @aws/mcp-server`
- **`.mcp.json` config:**
  ```json
  {
    "aws": {
      "command": "npx",
      "args": ["-y", "@aws/mcp-server"]
    }
  }
  ```
- **What it enables for Arness Infra:** Direct resource creation and state querying without AWS CLI. Enables real-time infrastructure state checks, resource listing, and configuration changes through the conversation.

---

## GCP

### Google Cloud MCP Server
- **Package:** `@google-cloud/mcp-server` (or `googlecloudplatform/mcp-server`)
- **Provider:** GCP
- **Official:** Yes (published by Google Cloud)
- **Capability tier:** Full (resource management, project operations)
- **Maturity:** Production
- **Install command:** `npm install -g @google-cloud/mcp-server`
- **`.mcp.json` config:**
  ```json
  {
    "gcp": {
      "command": "npx",
      "args": ["-y", "@google-cloud/mcp-server"]
    }
  }
  ```
- **What it enables for Arness Infra:** Direct GCP resource management, Cloud Run deployments, GKE operations, and Cloud SQL management through the conversation.

---

## Azure

### Azure MCP Server
- **Package:** `@azure/mcp-server` (or `azure/mcp-server`)
- **Provider:** Azure
- **Official:** Yes (published by Microsoft)
- **Capability tier:** Full (resource management, subscription operations)
- **Maturity:** Production
- **Install command:** `npm install -g @azure/mcp-server`
- **`.mcp.json` config:**
  ```json
  {
    "azure": {
      "command": "npx",
      "args": ["-y", "@azure/mcp-server"]
    }
  }
  ```
- **What it enables for Arness Infra:** Direct Azure resource management, App Service deployments, AKS operations, and Azure SQL management through the conversation.

---

## Cloudflare

### Cloudflare MCP Server
- **Package:** `@cloudflare/mcp-server-cloudflare`
- **Provider:** Cloudflare
- **Official:** Yes (published by Cloudflare)
- **Capability tier:** Full (Workers, R2, DNS, KV management)
- **Maturity:** Production
- **Install command:** `npm install -g @cloudflare/mcp-server-cloudflare`
- **`.mcp.json` config:**
  ```json
  {
    "cloudflare": {
      "command": "npx",
      "args": ["-y", "@cloudflare/mcp-server-cloudflare"]
    }
  }
  ```
- **What it enables for Arness Infra:** Workers deployment, DNS record management, R2 storage operations, KV namespace management, and Pages deployment through the conversation.

---

## Vercel

### Vercel MCP Server
- **Package:** `@vercel/mcp` (or community `vercel-mcp-server`)
- **Provider:** Vercel
- **Official:** Yes (published by Vercel)
- **Capability tier:** Full (deployments, environment variables, domains)
- **Maturity:** Production
- **Install command:** `npm install -g @vercel/mcp`
- **`.mcp.json` config:**
  ```json
  {
    "vercel": {
      "command": "npx",
      "args": ["-y", "@vercel/mcp"]
    }
  }
  ```
- **What it enables for Arness Infra:** Deployment management, environment variable configuration, domain setup, and project settings through the conversation.

---

## Community MCPs (Not Proactively Recommended)

The following are community-maintained MCPs. Arness Infra does not proactively recommend these but recognizes them if found in `.mcp.json`.

### DigitalOcean Community MCP
- **Package:** Various community packages
- **Provider:** DigitalOcean
- **Official:** No (community)
- **Capability tier:** Partial
- **Maturity:** Beta

### Fly.io Community MCP
- **Package:** Various community packages
- **Provider:** Fly.io
- **Official:** No (community)
- **Capability tier:** Partial
- **Maturity:** Beta

### Netlify Community MCP
- **Package:** Various community packages
- **Provider:** Netlify
- **Official:** No (community)
- **Capability tier:** Partial
- **Maturity:** Beta

---

## Registry Notes

- Only **official** MCPs are proactively recommended during discovery
- Community MCPs are recognized if already installed but not suggested for installation
- Package names and installation commands should be verified via Phase B (online check) as they may change
- The `what it enables` field helps users understand the value of installing each MCP
- Configuration snippets are ready to paste into `.mcp.json`
