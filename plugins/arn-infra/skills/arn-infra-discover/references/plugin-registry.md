# Plugin Registry

Registry of known Claude Code provider plugins. These plugins provide the highest-priority interaction layer -- when a provider plugin is installed, Arness Infra delegates appropriate operations to it rather than generating configs directly.

---

## Official Plugins

### deploy-on-aws
- **Plugin name:** deploy-on-aws
- **Provider:** AWS
- **Official:** Yes (published by AWS)
- **Detection method:** Check installed plugins list or look for plugin manifest
- **Operations handled:** EC2 deployment, ECS service creation, Lambda function deployment, S3 bucket management, CloudFront distribution setup
- **When Arness Infra delegates:** When the user requests a deployment to AWS and this plugin is installed, Arness Infra delegates the actual deployment operation to `deploy-on-aws` rather than generating raw CLI commands. Arness Infra still handles the planning, cost estimation, and verification phases.
- **Installation:** Install via Claude Code plugin management or `claude plugin install deploy-on-aws`

---

## Expected Official Plugins (Not Yet Available)

The following are anticipated based on cloud provider trends. Arness Infra's Phase B (online check) searches for these during discovery.

### GCP Deploy Plugin
- **Expected name:** deploy-on-gcp or google-cloud-plugin
- **Provider:** GCP
- **Status:** Not yet available (check via Phase B)
- **Expected operations:** Cloud Run deployment, GKE workload management, Cloud Functions deployment

### Azure Deploy Plugin
- **Expected name:** deploy-on-azure or azure-plugin
- **Provider:** Azure
- **Status:** Not yet available (check via Phase B)
- **Expected operations:** App Service deployment, AKS workload management, Azure Functions deployment

### Cloudflare Plugin
- **Expected name:** cloudflare-plugin
- **Provider:** Cloudflare
- **Status:** Not yet available (check via Phase B)
- **Expected operations:** Workers deployment, Pages deployment, DNS management

---

## Community Plugins

Community plugins are recognized if found but not proactively recommended.

### Infrastructure Manager Plugins
- Various community plugins may provide infrastructure management capabilities
- Arness Infra recognizes them if installed but does not recommend installation
- Official plugins are always preferred over community alternatives

---

## Plugin Interaction Priority

When multiple interaction methods are available for a provider, Arness Infra follows this priority:

1. **Official Claude Code plugin** (highest priority) -- delegate operations directly
2. **Official MCP server** -- interact with provider API through the conversation
3. **Official CLI with structured output** -- execute commands with parseable output
4. **Generated configs only** (lowest priority) -- generate IaC/platform configs for manual application

This priority chain ensures the smoothest user experience while maintaining safety and auditability.

---

## Detection Process

During `arn-infra-discover` Phase A:

1. Check if any known plugins from this registry are installed
2. For each installed plugin, record its capabilities
3. Note the provider interaction priority level achieved for each provider
4. In Phase B, search for newly released official plugins not yet in this registry
5. In Phase C, recommend official plugins as the highest-priority installation when available

---

## Notes

- Plugin package names and installation methods may change -- verify via Phase B (online check)
- Official plugins always take priority over MCP or CLI approaches
- When a plugin handles an operation, Arness Infra still validates the result via `arn-infra-verifier`
- Plugin delegation is transparent to the user -- they see the same Arness Infra workflow regardless of which interaction layer is used
