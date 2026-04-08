# Resource Manifest Schema

JSON schema for `active-resources.json`, the file that tracks all deployed infrastructure resources across providers and environments. This manifest is the source of truth for resource lifecycle management, cost tracking, and TTL cleanup.

---

## File Location

Path is configured in `## Arness` as `Resource manifest`. Default: `.arness/infra/active-resources.json`.

---

## Schema Definition

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "version": {
      "type": "string",
      "description": "Schema version (semver)",
      "const": "1.0.0"
    },
    "lastUpdated": {
      "type": "string",
      "format": "date-time",
      "description": "ISO 8601 timestamp of last manifest update"
    },
    "resources": {
      "type": "array",
      "items": { "$ref": "#/$defs/resource" }
    },
    "summary": { "$ref": "#/$defs/summary" }
  },
  "required": ["version", "lastUpdated", "resources"],
  "$defs": {
    "resource": {
      "type": "object",
      "properties": {
        "id": {
          "type": "string",
          "description": "Provider-specific resource identifier (ARN, resource ID, URL)"
        },
        "name": {
          "type": "string",
          "description": "Human-readable resource name"
        },
        "type": {
          "type": "string",
          "enum": ["compute", "database", "storage", "network", "cache", "cdn", "dns", "ssl", "queue", "function", "container", "registry", "load-balancer", "monitoring", "secret", "other"],
          "description": "Resource category"
        },
        "provider": {
          "type": "string",
          "description": "Cloud provider name (aws, gcp, azure, fly, railway, render, vercel, netlify)"
        },
        "environment": {
          "type": "string",
          "description": "Environment this resource belongs to (dev, staging, production)"
        },
        "region": {
          "type": "string",
          "description": "Provider region (e.g., us-east-1, europe-west1, iad)"
        },
        "createdAt": {
          "type": "string",
          "format": "date-time",
          "description": "ISO 8601 timestamp of resource creation"
        },
        "lastDeployedAt": {
          "type": "string",
          "format": "date-time",
          "description": "ISO 8601 timestamp of last deployment that touched this resource"
        },
        "lastVerified": {
          "type": ["string", "null"],
          "format": "date-time",
          "description": "ISO 8601 timestamp of last verification pass (null if never verified)"
        },
        "ttl": {
          "type": ["string", "null"],
          "format": "date-time",
          "description": "ISO 8601 timestamp when this resource should be destroyed (null for persistent resources)"
        },
        "costEstimate": {
          "type": "object",
          "properties": {
            "monthly": {
              "type": "number",
              "description": "Estimated monthly cost in USD"
            },
            "currency": {
              "type": "string",
              "const": "USD"
            }
          },
          "required": ["monthly", "currency"]
        },
        "iacTool": {
          "type": "string",
          "description": "IaC tool managing this resource (opentofu, terraform, pulumi, cdk, bicep, kubectl, helm, fly-cli, railway-cli, vercel-cli, netlify-cli, none)"
        },
        "stateLocation": {
          "type": ["string", "null"],
          "description": "Where the IaC state for this resource lives (S3 bucket, Pulumi Cloud URL, local path). Null for PaaS-managed resources."
        },
        "tags": {
          "type": "object",
          "additionalProperties": { "type": "string" },
          "description": "Key-value tags applied to the resource for identification and cost tracking"
        },
        "status": {
          "type": "string",
          "enum": ["active", "deploying", "failed", "destroying", "destroyed"],
          "description": "Current lifecycle status"
        },
        "endpoints": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "url": { "type": "string", "description": "Endpoint URL or address" },
              "type": { "type": "string", "enum": ["http", "https", "tcp", "dns", "ssh"], "description": "Endpoint type" },
              "healthCheck": { "type": ["string", "null"], "description": "Health check path (e.g., /health, /ready)" }
            },
            "required": ["url", "type"]
          },
          "description": "Publicly or internally accessible endpoints for this resource"
        }
      },
      "required": ["id", "name", "type", "provider", "environment", "createdAt", "iacTool", "status"]
    },
    "summary": {
      "type": "object",
      "properties": {
        "totalResources": { "type": "integer" },
        "byEnvironment": {
          "type": "object",
          "additionalProperties": { "type": "integer" }
        },
        "byProvider": {
          "type": "object",
          "additionalProperties": { "type": "integer" }
        },
        "totalMonthlyCost": {
          "type": "number",
          "description": "Sum of all resource cost estimates in USD"
        },
        "ephemeralCount": {
          "type": "integer",
          "description": "Number of resources with TTL set"
        },
        "nextExpiry": {
          "type": ["string", "null"],
          "format": "date-time",
          "description": "Earliest TTL expiry across all resources"
        }
      }
    }
  }
}
```

---

## Example Manifest

```json
{
  "version": "1.0.0",
  "lastUpdated": "2026-03-11T14:30:00Z",
  "resources": [
    {
      "id": "arn:aws:ec2:us-east-1:123456789012:instance/i-0abc123def456789",
      "name": "api-server-staging",
      "type": "compute",
      "provider": "aws",
      "environment": "staging",
      "region": "us-east-1",
      "createdAt": "2026-03-10T10:00:00Z",
      "lastDeployedAt": "2026-03-11T14:30:00Z",
      "lastVerified": "2026-03-11T14:45:00Z",
      "ttl": null,
      "costEstimate": { "monthly": 35.00, "currency": "USD" },
      "iacTool": "opentofu",
      "stateLocation": "s3://my-tfstate/staging/terraform.tfstate",
      "tags": {
        "environment": "staging",
        "project": "my-app",
        "managed-by": "arn-infra"
      },
      "status": "active",
      "endpoints": [
        { "url": "https://api-staging.example.com", "type": "https", "healthCheck": "/health" }
      ]
    },
    {
      "id": "fly-app:my-app-preview-abc123",
      "name": "preview-abc123",
      "type": "compute",
      "provider": "fly",
      "environment": "dev",
      "region": "iad",
      "createdAt": "2026-03-11T09:00:00Z",
      "lastDeployedAt": "2026-03-11T09:00:00Z",
      "lastVerified": null,
      "ttl": "2026-03-12T09:00:00Z",
      "costEstimate": { "monthly": 5.00, "currency": "USD" },
      "iacTool": "fly-cli",
      "stateLocation": null,
      "tags": {
        "environment": "dev",
        "ephemeral": "true",
        "ttl": "24h"
      },
      "status": "active",
      "endpoints": [
        { "url": "https://my-app-preview-abc123.fly.dev", "type": "https", "healthCheck": "/health" }
      ]
    }
  ],
  "summary": {
    "totalResources": 2,
    "byEnvironment": { "staging": 1, "dev": 1 },
    "byProvider": { "aws": 1, "fly": 1 },
    "totalMonthlyCost": 40.00,
    "ephemeralCount": 1,
    "nextExpiry": "2026-03-12T09:00:00Z"
  }
}
```

---

## Operations

### Adding Resources

After a successful deployment, add new resource entries for each created resource. Set `createdAt` and `lastDeployedAt` to the current timestamp. Set `status` to `active`. Recalculate the summary.

### Updating Resources

After a deployment that modifies existing resources, update `lastDeployedAt`. If the resource was re-verified, update `lastVerified`. Recalculate the summary.

### Marking Resources for Cleanup

When TTL expires or user requests cleanup, set `status` to `destroying`. After successful destroy, set `status` to `destroyed`. Destroyed resources remain in the manifest for audit trail (they can be pruned periodically).

### Querying Resources

Common queries:
- **All active resources:** filter `status === "active"`
- **Expired TTL resources:** filter `ttl !== null && ttl < now`
- **Resources by environment:** filter by `environment`
- **Resources by provider:** filter by `provider`
- **Unverified resources:** filter `lastVerified === null`

---

## TTL Format

TTL values in the manifest are stored as ISO 8601 timestamps (the absolute expiry time), not relative durations. When the user specifies a relative TTL (e.g., "24h", "7d"), convert it to an absolute timestamp at deployment time.

Conversion examples:
- "2h" at 2026-03-11T14:00:00Z --> `"ttl": "2026-03-11T16:00:00Z"`
- "24h" at 2026-03-11T14:00:00Z --> `"ttl": "2026-03-12T14:00:00Z"`
- "7d" at 2026-03-11T14:00:00Z --> `"ttl": "2026-03-18T14:00:00Z"`
