# arn-infra CHANGELOG

Notable changes to the `arn-infra` plugin.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html). The authoritative version for `arn-infra` lives in the plugin's entry in `/.claude-plugin/marketplace.json` at the repository root — `plugin.json` intentionally omits the `version` field per Anthropic's guidance.

Release tags follow Anthropic's official plugin tag convention: `arn-infra--v{version}` (double-hyphen `--v`), produced by `claude plugin tag --push` from inside `plugins/arn-infra/`.

## [2.4.0] — 2026-05-07

Baseline entry for arn-infra at its current marketplace version. The plugin ships 25 infrastructure skills and 10 specialist agents that cover containerization, IaC generation (OpenTofu, Pulumi, AWS CDK), deployment, CI/CD pipelines, environment management, secrets, monitoring, migration, and structured change management.

Notable capabilities at this version:
- Toolchain audit and Dockerfile / IaC generation
- Environment configuration and secrets management
- CI/CD pipeline construction and deployment orchestration
- Structured change management pipeline mirroring the arn-code development pipeline for complex infrastructure changes
- Progressive zero-config init with user profiling and expertise-aware recommendations
- Can operate standalone or alongside the arn-code core plugin

**Experimental.** Always review generated infrastructure configurations and deployment commands before applying them to real environments. Test in non-production environments first.

Prior release history predates this CHANGELOG. See `git log --oneline -- plugins/arn-infra/` for the full commit history.
