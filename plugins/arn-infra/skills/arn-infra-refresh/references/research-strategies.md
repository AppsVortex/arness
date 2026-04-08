# Research Strategies

Per-category search queries, verification procedures, and update criteria for the `arn-infra-reference-researcher` agent. Each category section describes what to search for, where to look, how to verify findings, what constitutes a valid update, and what to ignore.

---

## Registries

**Files:** `mcp-registry.md`, `cli-registry.md`, `plugin-registry.md`, `secrets-providers.md`

### What to Search For

- Latest versions of official MCP server packages per cloud provider
- Latest CLI versions for provider CLIs and IaC tools
- New official Claude Code plugins from cloud providers
- Latest secrets manager SDK versions and CLI commands

### Search Queries

**MCP servers:**
- `"@modelcontextprotocol" npm official MCP server [provider]`
- `[provider] MCP server latest version npm`
- `"@aws" OR "@google-cloud" OR "@azure" MCP server package`
- `site:npmjs.com @modelcontextprotocol`

**CLI tools:**
- `[provider] CLI latest version release`
- `aws cli latest version changelog`
- `gcloud CLI latest version release notes`
- `azure cli latest version changelog`
- `opentofu latest release version`
- `pulumi latest version changelog`

**Plugins:**
- `[provider] Claude Code plugin official`
- `Claude Code infrastructure plugin [provider]`

**Secrets providers:**
- `[provider] secrets manager SDK latest version`
- `AWS Secrets Manager CLI latest`
- `Google Secret Manager client library latest version`
- `Azure Key Vault SDK latest version`

### Where to Look

- **npm registry:** `https://www.npmjs.com/package/[package-name]` for MCP server packages
- **PyPI:** `https://pypi.org/project/[package-name]` for Python SDK versions
- **GitHub releases:** `https://github.com/[org]/[repo]/releases` for CLI tools and IaC tools
- **Official docs:** Provider release notes pages (AWS, GCP, Azure, DigitalOcean, Fly.io, Vercel, etc.)

### How to Verify

1. Check the npm registry or GitHub releases page for the exact version number
2. Confirm the package name matches (providers sometimes rename packages)
3. Verify the install command works with the latest version
4. Cross-reference with the provider's official documentation

### Valid Updates

- Version number bumped for a package or CLI tool
- New official MCP server package added by a provider
- Install command changed (e.g., new binary name, new package manager support)
- Package renamed or moved to a new scope
- Tool deprecated and replaced by an official successor

### What to Ignore

- Alpha, beta, RC, preview, or canary releases
- Community-maintained forks or wrappers
- Unofficial third-party MCP servers
- Version bumps that are patch-only with no user-visible changes (still report, but note as minor)

---

## IaC Patterns

**Files:** `opentofu-patterns.md`, `pulumi-patterns.md`, `cdk-patterns.md`, `bicep-patterns.md`, `kubernetes-patterns.md`, `paas-config-patterns.md`, `validation-ladder.md`

### What to Search For

- New syntax features, built-in functions, or language changes in IaC tools
- Updated provider version requirements or constraints
- New resource types or module registry patterns
- Deprecated syntax, resources, or API versions
- New or updated validation tool rules and policies

### Search Queries

**OpenTofu:**
- `opentofu changelog latest release`
- `opentofu new built-in functions`
- `opentofu provider requirements changes`
- `site:opentofu.org blog release`

**Pulumi:**
- `pulumi SDK latest version [language]`
- `pulumi new resource types [provider]`
- `pulumi automation API changes`
- `site:pulumi.com blog release`

**AWS CDK:**
- `aws cdk construct library latest version`
- `aws cdk new L2 L3 constructs`
- `aws cdk breaking changes migration`
- `site:docs.aws.amazon.com cdk release notes`

**Bicep:**
- `azure bicep latest version features`
- `bicep new resource API versions`
- `bicep module registry updates`
- `site:learn.microsoft.com bicep release notes`

**Kubernetes:**
- `kubernetes latest stable version API changes`
- `kubernetes deprecated APIs removal`
- `kubernetes new resource kinds stable`
- `site:kubernetes.io blog release`

**PaaS configuration:**
- `[provider] app service configuration changes`
- `cloud run latest configuration options`
- `elastic beanstalk platform updates`

**Validation tools:**
- `checkov latest version new rules`
- `tflint latest version changelog`
- `trivy latest version infrastructure scanning`

### Where to Look

- **OpenTofu:** `https://github.com/opentofu/opentofu/releases`, `https://opentofu.org/blog`
- **Pulumi:** `https://github.com/pulumi/pulumi/releases`, `https://www.pulumi.com/blog`
- **CDK:** `https://github.com/aws/aws-cdk/releases`, AWS docs
- **Bicep:** `https://github.com/Azure/bicep/releases`, Microsoft Learn
- **Kubernetes:** `https://kubernetes.io/blog`, `https://github.com/kubernetes/kubernetes/releases`
- **Validation:** `https://github.com/bridgecrewio/checkov/releases`, `https://github.com/aquasecurity/trivy/releases`

### How to Verify

1. Check changelogs for syntax-level changes that affect patterns (not just bug fixes)
2. Verify deprecated APIs have confirmed removal timelines
3. Confirm new resource types are in stable/GA, not beta
4. Cross-reference Kubernetes API deprecation with the deprecation guide at `https://kubernetes.io/docs/reference/using-api/deprecation-guide/`

### Valid Updates

- New syntax features that improve patterns in the reference file
- Provider version requirement changes that affect `required_providers` blocks
- New stable resource types relevant to infrastructure patterns
- Deprecated APIs or syntax with confirmed removal dates
- Validation tool version bumps with new rule sets

### What to Ignore

- Bug fix releases that do not change syntax or patterns
- Beta or experimental features not yet in stable channel
- Changes to provider-specific resources outside the scope of the reference file
- Kubernetes alpha API versions

---

## Container Patterns

**Files:** `dockerfile-patterns.md`, `compose-patterns.md`

### What to Search For

- Latest official base image tags (Node.js Alpine, Python slim, distroless, etc.)
- New multi-stage build best practices or Dockerfile syntax additions
- Docker Compose specification changes and new service options
- Security updates to base images (CVEs in common base images)

### Search Queries

**Dockerfile patterns:**
- `node alpine latest LTS docker image tag`
- `python slim latest docker image tag`
- `distroless latest image tag`
- `golang alpine latest docker image tag`
- `Dockerfile best practices [year]`
- `docker build new syntax features BuildKit`
- `site:hub.docker.com _/node`
- `site:hub.docker.com _/python`

**Compose patterns:**
- `docker compose specification latest version`
- `docker compose new features [year]`
- `compose file specification changes`
- `site:docs.docker.com compose compose-file`

### Where to Look

- **Docker Hub:** `https://hub.docker.com/_/node`, `https://hub.docker.com/_/python`, etc.
- **Distroless:** `https://github.com/GoogleContainerTools/distroless`
- **Docker docs:** `https://docs.docker.com/reference/dockerfile/`
- **Compose spec:** `https://docs.docker.com/compose/compose-file/`, `https://github.com/compose-spec/compose-spec`

### How to Verify

1. Check Docker Hub for the exact tag (e.g., `node:20-alpine` vs `node:22-alpine`)
2. Confirm the tag is for a current LTS version (not end-of-life)
3. Verify Compose syntax changes against the official specification
4. Check that base image updates do not introduce breaking changes for common use cases

### Valid Updates

- New LTS version of a runtime base image (e.g., Node 20 to Node 22 LTS)
- New distroless image variants
- New Dockerfile syntax instructions (e.g., heredocs, `COPY --link`)
- Compose specification version changes with new service options
- Security-critical base image updates

### What to Ignore

- Non-LTS runtime versions (odd-numbered Node.js releases, Python alpha/beta)
- Community-maintained base images (only official images)
- Minor patch updates to base images that do not affect tag references
- Docker Desktop-specific features not available in Docker Engine

---

## CI/CD Patterns

**Files:** `github-actions-patterns.md`, `gitlab-ci-patterns.md`, `pipeline-security-checklist.md`

### What to Search For

- Latest GitHub Actions runner images and their OS versions
- Official action version bumps (actions/checkout, actions/setup-node, etc.)
- New workflow features (reusable workflows, environment protection rules, etc.)
- GitLab CI runner image updates and new CI/CD keywords
- Pipeline security tool updates (OIDC providers, supply chain security)

### Search Queries

**GitHub Actions:**
- `github actions runner images latest version`
- `actions/checkout latest version`
- `actions/setup-node latest version`
- `actions/setup-python latest version`
- `github actions new workflow features [year]`
- `github actions OIDC provider updates`
- `site:github.blog actions`

**GitLab CI:**
- `gitlab ci latest runner image version`
- `gitlab ci new keywords features`
- `.gitlab-ci.yml syntax changes`
- `site:docs.gitlab.com ci`

**Pipeline security:**
- `pipeline security scanning tools latest`
- `github actions supply chain security best practices`
- `sigstore cosign latest version`
- `SLSA framework updates`

### Where to Look

- **GitHub Actions:** `https://github.com/actions/checkout/releases`, `https://github.com/actions/runner-images`, `https://github.blog`
- **GitLab CI:** `https://docs.gitlab.com/ci/`, `https://about.gitlab.com/releases/`
- **Security tools:** `https://github.com/sigstore/cosign/releases`, `https://github.com/aquasecurity/trivy-action`

### How to Verify

1. Check the GitHub Actions Marketplace for the latest major version of official actions
2. Confirm runner image updates match the supported OS versions
3. Verify GitLab CI keyword changes against the CI/CD reference documentation
4. Cross-reference security tool recommendations with official security advisories

### Valid Updates

- Major version bump of an official GitHub action (e.g., actions/checkout@v3 to v4)
- New runner image OS version (e.g., ubuntu-22.04 to ubuntu-24.04)
- New CI/CD keywords or syntax features in stable release
- New security scanning action or tool version
- OIDC provider configuration changes

### What to Ignore

- Pre-release or beta action versions
- Runner image updates that only affect pre-installed software
- GitLab CI features behind feature flags or in experimental state
- Security tools not backed by a recognized organization (CNCF, OpenSSF, etc.)

---

## Cloud Patterns

**Files:** `environment-patterns.md`, `promotion-patterns.md`, `alerting-patterns.md`, `observability-stack-guide.md`

### What to Search For

- New environment management features per provider (AWS Organizations, GCP Projects, Azure Management Groups)
- Latest promotion and deployment pipeline patterns (GitOps tool versions)
- Updated alerting integrations and metric types per provider
- Latest observability tool versions (Prometheus, Grafana, OpenTelemetry)
- New managed observability services or pricing changes

### Search Queries

**Environment patterns:**
- `aws organizations latest features`
- `gcp project organization latest changes`
- `azure management groups updates`
- `environment isolation best practices cloud [year]`

**Promotion patterns:**
- `argocd latest version release`
- `flux cd latest version release`
- `gitops deployment patterns [year]`
- `blue-green canary deployment latest practices`

**Alerting patterns:**
- `cloudwatch alarms latest features`
- `gcp cloud monitoring alerting updates`
- `azure monitor alerts new features`
- `pagerduty integration latest version`
- `opsgenie alerting integration updates`

**Observability stack:**
- `prometheus latest stable version`
- `grafana latest stable version`
- `opentelemetry collector latest stable version`
- `opentelemetry SDK latest version [language]`
- `datadog agent latest version`
- `site:prometheus.io blog`
- `site:grafana.com blog releases`

### Where to Look

- **ArgoCD:** `https://github.com/argoproj/argo-cd/releases`
- **Flux:** `https://github.com/fluxcd/flux2/releases`
- **Prometheus:** `https://github.com/prometheus/prometheus/releases`, `https://prometheus.io/blog`
- **Grafana:** `https://github.com/grafana/grafana/releases`, `https://grafana.com/blog`
- **OpenTelemetry:** `https://github.com/open-telemetry/opentelemetry-collector/releases`
- **Provider docs:** AWS CloudWatch, GCP Cloud Monitoring, Azure Monitor release notes

### How to Verify

1. Check GitHub releases for the exact stable version number
2. Confirm observability tools are in stable release, not RC
3. Verify provider alerting feature availability matches the referenced regions/services
4. Cross-reference GitOps tool changes with upgrade guides for breaking changes

### Valid Updates

- Version bump for observability tools (Prometheus, Grafana, OpenTelemetry)
- New provider alerting features or metric types
- GitOps tool version bumps with new deployment strategies
- New managed observability services from cloud providers
- Updated integration patterns for notification channels

### What to Ignore

- Observability tool release candidates or nightly builds
- Provider features in preview or limited availability
- Pricing changes that do not affect configuration patterns
- Dashboard template updates (out of scope for arn-infra)

---

## Infrastructure Guides

**Files:** `provider-overview.md`, `iac-tool-guide.md`, `existing-infra-detection.md`, `secrets-audit-checklist.md`, `rollback-patterns.md`, `health-check-patterns.md`, `deployment-safety-checklist.md`, `migration-scenarios.md`

### What to Search For

- New cloud providers or major service additions
- New IaC tools or major version releases with license changes
- New infrastructure detection heuristics and file signatures
- Updated secret detection patterns and scanning tool rules
- Latest rollback strategies and deployment safety practices
- New health check conventions and provider-specific health APIs
- New migration tooling and state migration patterns

### Search Queries

**Provider overview:**
- `new cloud providers infrastructure [year]`
- `[provider] new services infrastructure [year]`
- `cloud provider pricing model changes [year]`
- `[provider] new regions availability zones`

**IaC tool guide:**
- `new infrastructure as code tools [year]`
- `terraform license change BSL update`
- `opentofu vs terraform comparison [year]`
- `infrastructure as code tool comparison [year]`
- `cdktf latest version features`

**Detection heuristics:**
- `[iac-tool] file signatures detection patterns`
- `infrastructure code detection heuristics`
- `new cloud provider CLI detection methods`

**Secrets audit:**
- `secret detection tools latest version`
- `trufflehog latest version new detectors`
- `gitleaks latest version new rules`
- `secrets management best practices [year]`

**Rollback patterns:**
- `deployment rollback strategies [year]`
- `[provider] rollback API latest features`
- `canary deployment rollback automation`
- `blue-green deployment latest patterns`

**Health checks:**
- `health check endpoint best practices [year]`
- `kubernetes readiness liveness probe patterns`
- `[provider] health check API updates`

**Deployment safety:**
- `deployment safety checklist [year]`
- `pre-deployment validation tools latest`
- `change management automation infrastructure`

**Migration:**
- `infrastructure migration tools [year]`
- `terraform state migration opentofu`
- `[provider] migration service updates`
- `cloud migration best practices [year]`

### Where to Look

- **Provider docs:** AWS, GCP, Azure, DigitalOcean, Fly.io, Vercel, Railway, Render official documentation
- **IaC tools:** OpenTofu, Pulumi, CDK, Bicep official documentation and blogs
- **Security tools:** `https://github.com/trufflesecurity/trufflehog/releases`, `https://github.com/gitleaks/gitleaks/releases`
- **Kubernetes:** `https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/`
- **Migration tools:** Provider-specific migration service documentation

### How to Verify

1. Confirm new cloud provider services are in GA, not preview
2. Verify IaC tool license information against official announcements
3. Check that detection heuristics match actual file patterns (test against known project structures)
4. Confirm security tool updates include relevant rule changes (not just performance fixes)
5. Verify rollback and deployment patterns against official provider documentation

### Valid Updates

- New cloud provider entering GA with infrastructure support
- Major IaC tool release or license change
- New detection patterns for emerging IaC tools
- New secret detection rules for common secret formats
- Updated rollback APIs or deployment safety features from providers
- New health check conventions or probe configuration options
- New migration tools or provider migration service updates

### What to Ignore

- Cloud provider services in preview or beta
- IaC tools without stable releases or community adoption
- Detection patterns for abandoned or deprecated tools
- Security tool updates that only fix false positives
- Provider-specific features limited to a single region

---

## General Research Guidelines

These apply across all categories:

1. **Prefer official sources.** Always start with the official documentation, release pages, or package registries. Use blog posts and articles only as secondary confirmation.
2. **Verify package existence.** Before reporting a new package or tool, verify it exists on the relevant registry (npm, PyPI, Docker Hub, GitHub).
3. **Check release dates.** Note when the latest version was released. If a tool has not had a release in over 12 months, note this as it may indicate the project is unmaintained.
4. **Note breaking changes.** Any update that changes syntax, renames packages, or removes features must be flagged prominently in the update report.
5. **Cross-reference multiple sources.** When possible, confirm findings from at least two independent sources before reporting an update.
6. **Report confidence.** If a finding is uncertain (e.g., a tool's website is ambiguous about the latest version), note the uncertainty rather than presenting it as fact.
