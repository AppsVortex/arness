# Arness Code

Structured, artifact-driven development pipeline for Claude Code. Every feature flows through spec, plan, structure, execute, review, and ship — producing a durable Markdown or JSON artifact at each stage that feeds the next. Three ceremony tiers (swift, standard, thorough) scale process to match scope, from a one-file fix to a cross-cutting refactor. Ships 25 pipeline skills and 14 specialist agents.

## Install

```
# Add the Arness marketplace (one-time)
/plugin marketplace add AppsVortex/arness

# Install this plugin
/plugin install arn-code@arn-marketplace
```

## Documentation

Full guide: [docs/plugins/arn-code.md](../../docs/plugins/arn-code.md) · [arness.appsvortex.com](https://arness.appsvortex.com/)

## License

MIT. See [LICENSE](./LICENSE).

## Privacy

Arness Code runs entirely inside Claude Code on your local machine. The plugin emits no telemetry, collects no usage data, and transmits nothing off-device on its own — all skills and agents operate on files in your working directory. Claude Code (the host harness) handles its own Anthropic API communication; refer to [Anthropic's privacy policy](https://www.anthropic.com/legal/privacy) and [Claude Code's data usage documentation](https://code.claude.com/docs/en/data-usage) for details on how the host processes your prompts and context. Integrations with `git` and the GitHub CLI (`gh`) are invoked locally using your existing credentials — the plugin does not intermediate, store, or forward credentials.
