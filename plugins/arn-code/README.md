# Arness Code

Structured, artifact-driven development pipeline for Claude Code. Every feature flows through spec, plan, structure, execute, review, and ship — producing a durable Markdown or JSON artifact at each stage that feeds the next. Three ceremony tiers (swift, standard, thorough) scale process to match scope, from a one-file fix to a cross-cutting refactor. Also includes `arn-code-batch-cve-scan` and `arn-code-batch-cve-fix` for CVE discovery, triage, and batch resolution — safe to run unattended via Claude Code Routines. Ships 37 pipeline skills and 18 specialist agents.

## Install

```
# Add the Arness marketplace (one-time)
/plugin marketplace add AppsVortex/arness

# Install this plugin
/plugin install arn-code@arn-marketplace
```

## Hooks

Since 3.9.0 the plugin ships hooks. They are **off until you turn them on**, and they act only in projects with a `## Arness` section in `CLAUDE.md`. Turn them on for a project with `- **Hooks:** on` in the `## Arness` section (`/arn-code-init` asks), or for yourself with `ARNESS_HOOKS=on` (for example in `.claude/settings.local.json` under `env`).

- **Session start:** one status line about the Arness config; after a compaction, a pointer to the plan in progress.
- **Before `git push`:** blocks `--force`, `-f` and `+refspec` (`--force-with-lease` is allowed).
- **Before `git commit`:** blocks commits that contain private keys, access tokens, key files or `.env`. Add `arness:allow-secret` on a line to mark a false positive.
- **After an edit:** when `Linting: enabled`, runs the project's own file-level lint and format checks from `.arness/tooling.json` and reports issues to Claude. Advisory only. The commands run only after you approve them during setup.

`ARNESS_HOOKS=off` turns all hooks off, whatever the project says. Turn some off with `ARNESS_HOOKS_DISABLE=session,force-push,secrets,lint` (for example in `.claude/settings.local.json` under `env`).

## Documentation

Full guide: [docs/plugins/arn-code.md](../../docs/plugins/arn-code.md) · [arness.appsvortex.com](https://arness.appsvortex.com/)

## License

MIT. See [LICENSE](./LICENSE).

## Privacy

Arness Code runs entirely inside Claude Code on your local machine. The plugin emits no telemetry, collects no usage data, and transmits nothing off-device on its own — all skills and agents operate on files in your working directory. Claude Code (the host harness) handles its own Anthropic API communication; refer to [Anthropic's privacy policy](https://www.anthropic.com/legal/privacy) and [Claude Code's data usage documentation](https://code.claude.com/docs/en/data-usage) for details on how the host processes your prompts and context. Integrations with `git` and the GitHub CLI (`gh`) are invoked locally using your existing credentials — the plugin does not intermediate, store, or forward credentials.
