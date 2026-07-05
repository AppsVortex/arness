# arn-code CHANGELOG

Notable changes to the `arn-code` plugin.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html). The authoritative version for `arn-code` lives in the plugin's entry in `/.claude-plugin/marketplace.json` at the repository root — `plugin.json` intentionally omits the `version` field per Anthropic's guidance (setting `version` in both places would let a stale manifest silently mask the marketplace value).

Release tags follow Anthropic's official plugin tag convention: `arn-code--v{version}` (double-hyphen `--v`), produced by `claude plugin tag --push` from inside `plugins/arn-code/`.

## [3.8.0] — 2026-07-06

### Added
- `arn-code-batch-cve-scan` skill — three-mode CVE discovery, triage, and ticketing (interactive / proposal / finalize). Proposal mode is safe to schedule unattended via Claude Code Routines: it produces `CVE_SCAN_PROPOSAL.md` + `.json` sidecar under `.arness/plans/CVE_<UTC-timestamp>/`, emits a stable stdout completion line for external schedulers, and never writes to GitHub / Jira / project waiver files. Finalize mode steers a proposal into tickets after human review.
- `arn-code-batch-cve-fix` skill — interactive-only CVE fix skill with worktree-isolated parallel workers (reuses `arn-code-batch-implement` worker-instructions verbatim), per-group PRs targeting the configured `Security branch:`, a 5-condition auto-apply boundary gate (patch bump + fresh CI + 7-day supply-chain quarantine + non-postinstall + reachable), and a post-fix past-plan cleanup sub-step that archives fully-resolved CVE scan proposals to `.arness/plans/CVE_archive/` with a two-axis evidence gate.
- `arn-code-cve-analyst` agent — reasoning-heavy per-CVE triage. Narrowing-only grep-based reachability rule (a "not matched" result never becomes `safe` — only `low-confidence-unreachable`). Explicit grep blind-spot enumeration for dynamic dispatch, reflection, deserialization sinks, template engines, and FFI. Deterministic-parser boundary (never re-derives version-bound fields). Scanner-output checksum echoed back for reproducibility. Runs on `opus` in both agent-models presets (`all-opus.md` and `balanced.md`).
- `Security scanning:` field in `## Arness` (`enabled | none | skip`, default `skip`). Mirrors the `Linting:` field shape with lazy-prompt behavior — first invocation of a scan skill routes to Layer 2c to opt in.
- `Security branch:` field in `## Arness`. Default auto-detected from `git symbolic-ref --short refs/remotes/origin/HEAD` with fallback to `git rev-parse --abbrev-ref HEAD`. Accepts a branch name or `auto` (re-detects every run). Read by both new skills to determine which branch to scan (via `git show <security-branch>:<path>`) and which branch to use as PR target.
- `security-scanning.md` artifact — new sibling of `linting.md` written by `arn-code-codebase-analyzer` (extended with an evidence-based security-scanner detection step). Documents discovered scanners, waiver mechanisms, CI integrations, and advisory-DB freshness hints without enumerating specific tool names.
- `arness-security` platform label (deep purple `#5319e7`). Applied to CVE-triage parent issues, per-group sub-issues, and fix PRs.
- CLAUDE.md sections: `## Security Scanning Configuration` (documenting both new `## Arness` fields) and `### Scheduling CVE Scans` (pointing to Claude Code Routines as the recommended unattended mechanism, plus `claude -p` headless for tool-agnostic scheduling).

### Changed
- Agent-models presets `all-opus.md` and `balanced.md` bumped from `# Version: 1.1.0` → `1.2.0` to include the new `arn-code-cve-analyst: opus` entry at alphabetic position.
- `EXPECTED_LABELS_COUNT` bumped `7 → 8` in `arn-code-ensure-config`'s `cache-check.sh` (and the sibling `arn-spark-ensure-config` and `arn-infra-ensure-config` scripts) to account for the new `arness-security` label.
- `arn-code-codebase-analyzer` agent — added a new evidence-detection step for security scanners (evidence categories: `audit`/`security`-style manifest scripts, scanner config dotfiles, CI workflow steps, lockfile audit metadata, `dependabot.yml` presence, waiver/override blocks in manifests). Writes `<code-patterns-dir>/security-scanning.md`. No tool-name enumeration in the detection prompt.
- ensure-config Layer 2 header, Layer 2b defaults block, Layer 2c handlers, Layer 3b label count check, and Layer 4 cache invalidation trigger — all updated to cover the two new fields and the new label.

### Compatibility
Additive-only. No breaking changes. Users upgrading from `3.7.0` see:
- One silent cache miss on first `ensure-config` invocation post-upgrade (the label-count fingerprint changed from 7 to 8). The cache re-hashes and continues.
- One silent `gh label create --force` for the `arness-security` label on the next entry-point invocation on GitHub-configured projects. Fails silently if the user lacks label-write permission.
- Two new `## Arness` fields written with safe defaults (`Security scanning: skip` and auto-detected `Security branch: <default-branch>`) on the next Layer 2b write. No user-visible prompt unless the user invokes `/arn-code-batch-cve-scan` or `/arn-code-batch-cve-fix`.
- Agent-models preset version bump handled by the existing `Template updates: ask | auto | manual` policy — no user impact for projects with `custom` profile.

## [3.7.0] — 2026-05-10

### Added
- ensure-config cache — hash-based fast-path fingerprint at `.arness/arn-code-ensure-config.local.json` cuts Step 0 token cost by ~95% on cache hits. Cross-platform (bash 3.2 compat, `sha256sum || shasum -a 256` fallback, `$HOME` not `~`).
- Nova → Arness migration Layer 0 removed (no longer needed).
- `.gitattributes` pins `plugins/*/skills/*-ensure-config/scripts/*.sh` to `text eol=lf` for Windows compat.

### Changed
- 23 entry-point skills updated to read `references/step-0-fast-path.md` instead of loading the full `references/ensure-config.md` on cache hits.

## [3.6.0] — 2026-05-09

### Added
- Per-phase model upgrade for complex phases — `arn-code-plan` Step 5a gate offers to upgrade executor model to `opus` for phases rated `complex` in the plan. Preference `pipeline.complex-phase-upgrade: ask | always | never` stored in two-tier preferences (project-local + user-global). `implementation.modelOverride` field in `PROGRESS_TRACKER.json` carries the per-phase decision to executors.

## [3.5.0] — 2026-05-08

### Added
- Configurable reviewer + applier models for `arn-code-simplify` and `arn-code-batch-simplify` — reviewer defaults to `opus`, applier defaults to `sonnet` in the `balanced` preset; both configurable per project.

## [3.4.0] — 2026-05-07

### Added
- Per-plugin agent model profile — three profiles per plugin (`all-opus | balanced | custom`) determine per-agent model assignments. Preset files at `.arness/agent-models/<plugin>.md` with checksum-based drift detection: user edits automatically flip the profile to `custom` so future preset updates skip the file.

## [3.3.0] and earlier

Prior release history predates this CHANGELOG. See `git log --oneline` for a full commit history.
