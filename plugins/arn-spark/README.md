# Arness Spark

Greenfield exploration plugin for Claude Code. Takes a raw idea through product discovery, persona generation, competitive research, brand naming, architecture vision, use case authoring, project scaffolding, visual sketch exploration, and interactive prototype validation — producing a validated concept, a prioritized feature backlog, and a scaffolded codebase ready for development. Ships 19 exploration skills and 13 specialist agents.

## Install

```
# Add the Arness marketplace (one-time)
/plugin marketplace add AppsVortex/arness

# Install this plugin
/plugin install arn-spark@arn-marketplace
```

## Documentation

Full guide: [docs/plugins/arn-spark.md](../../docs/plugins/arn-spark.md) · [arness.appsvortex.com](https://arness.appsvortex.com/)

## License

MIT. See [LICENSE](./LICENSE).

## Privacy

Arness Spark runs entirely inside Claude Code on your local machine. The plugin emits no telemetry, collects no usage data, and transmits nothing off-device on its own — all skills and agents operate on files in your working directory. Claude Code (the host harness) handles its own Anthropic API communication; refer to [Anthropic's privacy policy](https://www.anthropic.com/legal/privacy) and [Claude Code's data usage documentation](https://code.claude.com/docs/en/data-usage) for details on how the host processes your prompts and context. Some skills suggest external research — any web browsing, domain lookups, or trademark checks are surfaced as user-driven actions, not plugin-initiated network requests.
