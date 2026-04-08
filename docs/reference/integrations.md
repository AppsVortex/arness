---
title: "Integrations"
description: "MCP servers, CLIs, and external services that work with Arness"
sidebar:
  order: 36
---

# Integrations

Arness connects to external services through [MCP servers](https://modelcontextprotocol.io/) and CLI tools. All integrations are optional — Arness detects what's available during init and adapts accordingly.

## Platform CLIs

| Service | CLI | Used by | Setup |
|---------|-----|---------|-------|
| **GitHub** | [`gh`](https://cli.github.com/) | Code, Infra — PRs, issues, CI status | `gh auth login` |
| **Bitbucket** | [`bkt`](https://bitbucket.org/atlassian/bitbucket-cli) | Code, Infra — PRs, issues, pipelines | `bkt auth login` |

GitHub and Bitbucket integration uses their native CLIs rather than MCP — no additional setup beyond authenticating the CLI.

## MCP Servers

| Service | MCP Server | Used by | What it enables |
|---------|-----------|---------|-----------------|
| **Jira Cloud** | [Atlassian MCP](https://mcp.atlassian.com) | Code | Issue creation, backlog browsing, PR review tracking |
| **Figma** | [Figma MCP](https://www.figma.com/blog/introducing-figma-mcp-server/) | Spark | Style exploration, design grounding for prototypes |
| **Canva** | [Canva MCP](https://www.canva.dev/docs/connect/mcp-server/) | Spark | Asset export, brand grounding for prototypes |

MCP servers are configured at the project level in `.mcp.json`, not baked into the plugin.

## Cloud Providers (Infra)

Arness Infra supports infrastructure generation for:

| Provider | IaC Tools |
|----------|-----------|
| **AWS** | OpenTofu/Terraform, Pulumi, CDK |
| **GCP** | OpenTofu/Terraform, Pulumi |
| **Azure** | OpenTofu/Terraform, Pulumi, Bicep |
| **Fly.io** | fly CLI, OpenTofu/Terraform |
| **Railway** | railway CLI |
| **Vercel** | vercel CLI |
| **Netlify** | netlify CLI |
| **DigitalOcean** | OpenTofu/Terraform |
| **Render** | render CLI |
| **Cloudflare** | wrangler CLI |
| **Heroku** | heroku CLI |
| **Scaleway** | OpenTofu/Terraform |

Infra also supports Kubernetes/Helm for container orchestration across any provider.

## How Detection Works

During initialization (`/arn-code-init`, `/arn-spark-init`, or `/arn-infra-init`), Arness:

1. **Checks for Git** — detects repository status and remote configuration
2. **Detects platform** — identifies GitHub or Bitbucket from the remote URL
3. **Checks CLI auth** — verifies `gh auth status` or `bkt auth status`
4. **Scans for MCP servers** — reads `.mcp.json` for configured services
5. **Records findings** — stores detected capabilities in the `## Arness` config section

Skills adapt their behavior based on detected capabilities. For example:
- If no issue tracker is detected, issue-related features are skipped gracefully
- If Figma MCP is available, Spark's style exploration can ground designs from Figma files
- If no cloud CLI is installed, Infra suggests installing one during the wizard

## Adding an Integration Later

If you install a CLI or configure an MCP server after init, just run init again:

```
/arn-code-init      # Re-detects platform capabilities
/arn-spark-init     # Re-detects design tool integrations
/arn-infra-init     # Re-detects cloud CLIs and tools
```

Init is non-destructive — it preserves existing configuration and adds newly detected capabilities.
