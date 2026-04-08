# Contributing to Arness

Thanks for your interest in contributing! Arness is open source (MIT) and welcomes contributions of all kinds.

## Quick Links

- **Bug reports and feature requests:** [Open an issue](https://github.com/AppsVortex/arness/issues)
- **Questions and discussions:** [Start a discussion](https://github.com/AppsVortex/arness/discussions)
- **Full contributing guide:** [docs/contributing.md](docs/contributing.md) — covers plugin conventions, skill/agent structure, path rules, versioning, and local testing

## Getting Started

1. Fork and clone the repository
2. Create a feature branch
3. Make your changes following the [plugin conventions](docs/contributing.md)
4. Test locally: `claude --plugin-dir plugins/arn-spark` (or `arn-code`, `arn-infra`)
5. Bump the version in the affected plugin's `plugin.json` and `marketplace.json`
6. Submit a PR with a clear description of what changed and why

## Code of Conduct

Please be respectful and constructive in all interactions. See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
