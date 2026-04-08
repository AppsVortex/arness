# Reference Manifest

Catalog of all 28 evolving reference files in the arn-infra plugin. These files contain version-sensitive content (tool versions, MCP package names, CLI install commands, base image tags, IaC syntax) that goes stale over time and benefits from periodic refresh via online research.

The 18 static reference files (schemas, checklists, workflow definitions) are excluded -- they do not contain version-sensitive content and do not need refresh.

---

## Categories

| Category | File Count | Refresh Cadence | Description |
|----------|-----------|-----------------|-------------|
| registries | 4 | Quarterly | Tool and provider registries with package names, versions, install commands |
| iac-patterns | 7 | Semi-annually | Infrastructure-as-Code patterns with syntax, best practices, module references |
| container-patterns | 2 | Semi-annually | Container build and orchestration patterns with base images, build stages |
| cicd-patterns | 3 | Semi-annually | CI/CD pipeline patterns with action versions, runner images, security tools |
| cloud-patterns | 4 | Semi-annually | Cloud environment and observability patterns with service names, API versions |
| infra-guides | 8 | Annually to semi-annually | Infrastructure guides with provider features, tool capabilities, detection heuristics |

**Total: 28 unique evolving files across 6 categories (30 read directives across 12 skills — `gitlab-ci-patterns.md` is referenced twice in arn-infra-pipeline for both GitLab CI and Bitbucket Pipelines, and `rollback-patterns.md` is referenced in both arn-infra-deploy and arn-infra-cleanup)**

---

## Registries

Tool and provider registries containing package names, version numbers, and installation commands that change with new releases.

| Filename | Source Path | Refresh Strategy | Update Frequency |
|----------|------------|------------------|------------------|
| `mcp-registry.md` | `arn-infra-discover/references/mcp-registry.md` | Search for latest official MCP server packages per provider; verify npm package names and install commands | Quarterly |
| `cli-registry.md` | `arn-infra-discover/references/cli-registry.md` | Search for latest CLI versions per provider; verify binary names, install commands, and structured output flags | Quarterly |
| `plugin-registry.md` | `arn-infra-discover/references/plugin-registry.md` | Search for new official Claude Code plugins from cloud providers; verify package names and capability descriptions | Quarterly |
| `secrets-providers.md` | `arn-infra-secrets/references/secrets-providers.md` | Search for latest secrets manager SDK versions, CLI commands, and provider-specific integration patterns | Quarterly |

---

## IaC Patterns

Infrastructure-as-Code patterns containing syntax examples, module references, and best practices that evolve with tool releases.

| Filename | Source Path | Refresh Strategy | Update Frequency |
|----------|------------|------------------|------------------|
| `opentofu-patterns.md` | `arn-infra-define/references/opentofu-patterns.md` | Search for latest OpenTofu syntax changes, new built-in functions, provider requirements, and module registry patterns | Semi-annually |
| `pulumi-patterns.md` | `arn-infra-define/references/pulumi-patterns.md` | Search for latest Pulumi SDK versions per language, new resource types, and automation API changes | Semi-annually |
| `cdk-patterns.md` | `arn-infra-define/references/cdk-patterns.md` | Search for latest AWS CDK construct library versions, new L2/L3 constructs, and breaking changes | Semi-annually |
| `bicep-patterns.md` | `arn-infra-define/references/bicep-patterns.md` | Search for latest Bicep language features, new resource API versions, and module registry updates | Semi-annually |
| `kubernetes-patterns.md` | `arn-infra-define/references/kubernetes-patterns.md` | Search for latest Kubernetes API versions, deprecated APIs, and new resource kinds in stable channel | Semi-annually |
| `paas-config-patterns.md` | `arn-infra-define/references/paas-config-patterns.md` | Search for latest PaaS configuration options per provider (App Service, Cloud Run, Elastic Beanstalk) | Semi-annually |
| `validation-ladder.md` | `arn-infra-define/references/validation-ladder.md` | Search for latest versions of validation tools (Checkov, tflint, Trivy) and new rule sets or policies | Semi-annually |

---

## Container Patterns

Container build and orchestration patterns containing base image tags, build stage conventions, and compose syntax.

| Filename | Source Path | Refresh Strategy | Update Frequency |
|----------|------------|------------------|------------------|
| `dockerfile-patterns.md` | `arn-infra-containerize/references/dockerfile-patterns.md` | Search for latest official base image tags, multi-stage build best practices, and Dockerfile syntax additions | Semi-annually |
| `compose-patterns.md` | `arn-infra-containerize/references/compose-patterns.md` | Search for latest Docker Compose specification changes, new service options, and compose file version features | Semi-annually |

---

## CI/CD Patterns

CI/CD pipeline patterns containing action versions, runner image references, and security tool integrations.

| Filename | Source Path | Refresh Strategy | Update Frequency |
|----------|------------|------------------|------------------|
| `github-actions-patterns.md` | `arn-infra-pipeline/references/github-actions-patterns.md` | Search for latest GitHub Actions runner images, official action version bumps (actions/checkout, actions/setup-*), and new workflow features | Semi-annually |
| `gitlab-ci-patterns.md` | `arn-infra-pipeline/references/gitlab-ci-patterns.md` | Search for latest GitLab CI runner images, new CI/CD keywords, and changes to .gitlab-ci.yml syntax | Semi-annually |
| `pipeline-security-checklist.md` | `arn-infra-pipeline/references/pipeline-security-checklist.md` | Search for latest pipeline security scanning tools, OIDC provider changes, and supply chain security best practices | Semi-annually |
| `bitbucket-pipelines-patterns.md` | `arn-infra-pipeline/references/bitbucket-pipelines-patterns.md` | Search for latest Bitbucket Pipelines features, OIDC changes, pipe updates, and deployment environment capabilities | Semi-annually |

---

## Cloud Patterns

Cloud environment and observability patterns containing service names, API versions, and provider-specific configuration.

| Filename | Source Path | Refresh Strategy | Update Frequency |
|----------|------------|------------------|------------------|
| `environment-patterns.md` | `arn-infra-env/references/environment-patterns.md` | Search for latest environment management features per provider (AWS Organizations, GCP Projects, Azure Management Groups) | Semi-annually |
| `promotion-patterns.md` | `arn-infra-env/references/promotion-patterns.md` | Search for latest promotion and deployment pipeline patterns, GitOps tool versions (ArgoCD, Flux), and environment promotion strategies | Semi-annually |
| `alerting-patterns.md` | `arn-infra-monitor/references/alerting-patterns.md` | Search for latest alerting integrations per provider, new metric types, and alert routing best practices | Semi-annually |
| `observability-stack-guide.md` | `arn-infra-monitor/references/observability-stack-guide.md` | Search for latest observability tool versions (Prometheus, Grafana, OpenTelemetry), new exporters, and managed service changes | Semi-annually |

---

## Infrastructure Guides

Comprehensive infrastructure guides with provider feature lists, tool capabilities, and detection heuristics that evolve with platform updates.

| Filename | Source Path | Refresh Strategy | Update Frequency |
|----------|------------|------------------|------------------|
| `provider-overview.md` | `arn-infra-init/references/provider-overview.md` | Search for new cloud provider services, pricing model changes, and region availability updates | Annually |
| `iac-tool-guide.md` | `arn-infra-init/references/iac-tool-guide.md` | Search for new IaC tools, major version releases, license changes (e.g., Terraform BSL), and feature comparisons | Annually |
| `existing-infra-detection.md` | `arn-infra-init/references/existing-infra-detection.md` | Search for new infrastructure detection heuristics, file signatures for emerging IaC tools, and provider CLI detection methods | Annually |
| `secrets-audit-checklist.md` | `arn-infra-secrets/references/secrets-audit-checklist.md` | Search for new secret detection patterns, updated scanning tool rules, and secrets management best practices | Annually |
| `rollback-patterns.md` | `arn-infra-deploy/references/rollback-patterns.md` | Search for latest rollback strategies per deployment tool, new canary/blue-green features, and provider-specific rollback APIs | Semi-annually |
| `health-check-patterns.md` | `arn-infra-verify/references/health-check-patterns.md` | Search for latest health check endpoint conventions, readiness/liveness probe patterns, and provider-specific health APIs | Semi-annually |
| `deployment-safety-checklist.md` | `arn-infra-deploy/references/deployment-safety-checklist.md` | Search for latest deployment safety practices, new pre-deployment validation tools, and change management automation | Semi-annually |
| `migration-scenarios.md` | `arn-infra-migrate/references/migration-scenarios.md` | Search for new migration tooling, provider migration services, and IaC state migration patterns | Annually |

---

## Source Path Convention

All source paths in this manifest are relative to `${CLAUDE_PLUGIN_ROOT}/skills/`. The full plugin path for any file is:

```
${CLAUDE_PLUGIN_ROOT}/skills/<source-path>
```

For example, `arn-infra-discover/references/mcp-registry.md` resolves to:

```
${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-discover/references/mcp-registry.md
```

When externalized to the project-local override directory, the file is copied to:

```
.arness/infra-references/<filename>
```

The flat structure works because all 28 filenames are unique across skills.

---

## Refresh Strategy Notes

- **Quarterly** files contain rapidly-changing content (package versions, install commands) that should be verified against official sources every 3 months
- **Semi-annually** files contain patterns and best practices that evolve with major tool releases, typically 1-2 times per year
- **Annually** files contain foundational guides and overviews that change slowly, typically only when major new tools or providers emerge
- The refresh skill (`arn-infra-refresh`) uses these strategies to construct targeted search queries for the researcher agent
