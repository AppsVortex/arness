# Tooling Manifest Schema

JSON schema for `.arness/infra/tooling-manifest.json` -- the structured output of `arn-infra-discover`. This file is read by downstream skills and agents to understand available tooling, authentication state, and recommended installations.

---

## Schema

```json
{
  "version": "1.0.0",
  "lastUpdated": "ISO 8601 timestamp",
  "providers": {
    "[provider-name]": {
      "mcps": [
        {
          "name": "MCP server name",
          "package": "npm package name",
          "official": true,
          "installed": true,
          "capabilities": ["list", "of", "capabilities"],
          "config": {
            "command": "npx",
            "args": ["-y", "@provider/mcp-server"]
          }
        }
      ],
      "clis": [
        {
          "name": "CLI display name",
          "binary": "binary-name",
          "official": true,
          "installed": true,
          "version": "X.Y.Z",
          "authenticated": true,
          "structuredOutput": "--output json"
        }
      ],
      "plugins": [
        {
          "name": "Plugin name",
          "official": true,
          "installed": true,
          "operations": ["list", "of", "delegated", "operations"]
        }
      ],
      "confidence": "A"
    }
  },
  "iacTools": {
    "[tool-name]": {
      "binary": "binary-name",
      "installed": true,
      "version": "X.Y.Z",
      "notes": "Any relevant notes (e.g., BSL license warning for Terraform)"
    }
  },
  "validationTools": {
    "[tool-name]": {
      "binary": "binary-name",
      "installed": true,
      "version": "X.Y.Z",
      "purpose": "What this tool does"
    }
  },
  "scanningTools": {
    "[tool-name]": {
      "binary": "binary-name",
      "installed": true,
      "version": "X.Y.Z",
      "purpose": "What this tool does"
    }
  },
  "recommended": [
    {
      "name": "Tool display name",
      "type": "mcp | cli | plugin | iac | validation | scanning",
      "official": true,
      "provider": "provider-name or null",
      "installCommand": "full install command",
      "mcpConfig": {
        "command": "npx",
        "args": ["-y", "@provider/mcp-server"]
      },
      "rationale": "Why this tool should be installed",
      "priority": "required | recommended | optional"
    }
  ]
}
```

---

## Field Descriptions

### Top Level

| Field | Type | Description |
|-------|------|-------------|
| `version` | string | Schema version for forward compatibility |
| `lastUpdated` | string | ISO 8601 timestamp of last discovery run |
| `providers` | object | Per-provider tooling inventory |
| `iacTools` | object | IaC CLI tools (provider-agnostic) |
| `validationTools` | object | Validation tools (Checkov, Trivy) |
| `scanningTools` | object | Security scanning tools (TruffleHog, Gitleaks) |
| `recommended` | array | Tools available but not installed |

### Provider Entry

| Field | Type | Description |
|-------|------|-------------|
| `mcps` | array | MCP servers configured for this provider |
| `clis` | array | CLI tools available for this provider |
| `plugins` | array | Claude Code plugins for this provider |
| `confidence` | string | Overall confidence rating (A/B/C/D) |

### Confidence Rating Calculation

| Rating | Criteria |
|--------|----------|
| **A** | Official MCP installed + CLI installed + authenticated |
| **B** | CLI installed + authenticated (no official MCP) |
| **C** | CLI installed but NOT authenticated |
| **D** | No direct tooling available (config generation only) |

If a Claude Code plugin is installed, the confidence is at least B regardless of CLI/MCP status, since the plugin provides direct interaction capabilities.

### MCP Entry

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Display name of the MCP server |
| `package` | string | npm package name for installation |
| `official` | boolean | Whether published by the cloud provider |
| `installed` | boolean | Whether configured in `.mcp.json` |
| `capabilities` | array | What operations this MCP enables |
| `config` | object | `.mcp.json` configuration snippet |

### CLI Entry

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Display name of the CLI |
| `binary` | string | Binary name for detection |
| `official` | boolean | Whether published by the cloud provider |
| `installed` | boolean | Whether the binary was found |
| `version` | string | Detected version (null if not installed) |
| `authenticated` | boolean | Whether auth check passed |
| `structuredOutput` | string | Flag for JSON output (null if none) |

### Plugin Entry

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Plugin name |
| `official` | boolean | Whether published by the cloud provider |
| `installed` | boolean | Whether the plugin is active |
| `operations` | array | Operations delegated to this plugin |

### Recommended Entry

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Tool display name |
| `type` | string | Tool category |
| `official` | boolean | Whether published by the provider |
| `provider` | string | Associated provider (null for provider-agnostic tools) |
| `installCommand` | string | Full installation command |
| `mcpConfig` | object | `.mcp.json` snippet (only for MCP type) |
| `rationale` | string | Why this tool should be installed |
| `priority` | string | How critical the installation is |

### Priority Definitions

| Priority | Meaning | Example |
|----------|---------|---------|
| **required** | Blocks a workflow step without it | `tofu` when IaC tool is `opentofu` |
| **recommended** | Significantly improves the workflow | Official MCP server for the user's provider |
| **optional** | Nice-to-have enhancement | Infracost for cost estimation |

---

## Usage by Downstream Skills

Skills and agents read the tooling manifest to:

1. **Determine available interaction methods** -- which MCPs, CLIs, or plugins to use for a given provider
2. **Check for recommended tools** -- flag when a higher-priority tool is available but not installed
3. **Get provider confidence** -- understand the reliability of infrastructure operations per provider
4. **Read authentication state** -- know whether CLI commands will work without additional auth steps
