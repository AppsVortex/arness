# Arness Infra

Infrastructure and deployment plugin for Claude Code. Audits your toolchain, generates Dockerfiles and IaC (OpenTofu, Pulumi, AWS CDK), configures environments and secrets, builds CI/CD pipelines, and walks you through deployment and verification. For complex changes, a structured change management pipeline mirrors the rigor of the development pipeline. Ships 23 infrastructure skills and 9 specialist agents.

> **Experimental — use with care.** Always review generated infrastructure configurations and deployment commands before applying them to real environments. Test in non-production environments first.

## Install

```
/plugin install arn-infra@arn-marketplace
```

## Documentation

Full guide: [docs/plugins/arn-infra.md](../../docs/plugins/arn-infra.md) · [arness.appsvortex.com](https://arness.appsvortex.com/)

## License

MIT. See [LICENSE](./LICENSE).

## Privacy

Arness Infra runs entirely inside Claude Code on your local machine. The plugin emits no telemetry, collects no usage data, and transmits nothing off-device on its own — all skills and agents operate on files in your working directory. Claude Code (the host harness) handles its own Anthropic API communication; refer to [Anthropic's privacy policy](https://www.anthropic.com/legal/privacy) and [Claude Code's data usage documentation](https://code.claude.com/docs/en/data-usage) for details on how the host processes your prompts and context. Cloud CLIs (`aws`, `gcloud`, `az`, `kubectl`, `tofu`, `pulumi`, `cdk`, `docker`, and similar) and optional MCP integrations are invoked locally using your existing credential configuration — the plugin does not intermediate, store, or forward credentials, and any API calls those tools make go directly from your machine to the respective cloud or service provider.
