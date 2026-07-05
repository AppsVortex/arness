# arn-spark CHANGELOG

Notable changes to the `arn-spark` plugin.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html). The authoritative version for `arn-spark` lives in the plugin's entry in `/.claude-plugin/marketplace.json` at the repository root — `plugin.json` intentionally omits the `version` field per Anthropic's guidance.

Release tags follow Anthropic's official plugin tag convention: `arn-spark--v{version}` (double-hyphen `--v`), produced by `claude plugin tag --push` from inside `plugins/arn-spark/`.

## [2.4.0] — 2026-05-07

Baseline entry for arn-spark at its current marketplace version. The plugin ships 28 exploration skills and 20 specialist agents that take a raw product idea through product discovery, persona generation, competitive research, brand naming, architecture vision, use case authoring, project scaffolding, visual sketch exploration, and interactive prototype validation — producing a validated concept, a prioritized feature backlog, and a scaffolded codebase ready for development.

Notable capabilities at this version:
- Product discovery with AI-assisted persona generation and competitive landscape research
- Brand naming through a structured 4-step methodology with domain and trademark screening
- Architecture vision and use case authoring
- Project scaffolding with visual style exploration
- Static and interactive prototype validation
- Prototype preservation and feature extraction
- Visual testing strategy, stress testing suite, concept review
- Issue tracker integration
- Progressive zero-config init with user profiling and expertise-aware recommendations
- Can operate standalone or alongside the arn-code core plugin

Prior release history predates this CHANGELOG. See `git log --oneline -- plugins/arn-spark/` for the full commit history.
