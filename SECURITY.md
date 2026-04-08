# Security Policy

## Reporting Security Issues

If you discover a security vulnerability in Arness, please report it responsibly:

1. **GitHub Private Security Advisories** (preferred): Use the [Security tab](https://github.com/AppsVortex/arness/security/advisories/new) on this repository
2. **Email fallback**: Contact the maintainers directly via the repository's security contact

**Response timeline:**
- Acknowledgement within 48 hours
- Triage and severity assessment within 7 days
- Fix or mitigation plan communicated within 14 days for confirmed vulnerabilities

Please include steps to reproduce, affected versions, and potential impact in your report.

## Scope

This policy covers:
- All three Arness plugins: `arn-code`, `arn-spark`, `arn-infra`
- The marketplace manifest (`.claude-plugin/marketplace.json`)
- Skill files (`skills/*/SKILL.md`), agent definitions (`agents/*.md`), reference files, and templates
- Shell scripts in `skills/*/scripts/`

Out of scope:
- Claude Code itself (report to [Anthropic's HackerOne program](https://hackerone.com/anthropic))
- MCP servers configured by users (report to the respective MCP server maintainers)
- External tools Arness integrates with (`gh`, `bkt`, cloud provider CLIs)

## Supported Versions

| Plugin | Current Version | Supported |
|--------|----------------|-----------|
| arn-code | 3.0.0 | Yes |
| arn-spark | 2.0.0 | Yes |
| arn-infra | 2.0.0 | Yes |

Only the latest published version of each plugin receives security updates. We recommend always running the latest version.

## Security Model

### Plugin Architecture

Arness plugins are **instruction-only artifacts** — they consist of markdown files (skills, agents, references) and JSON templates. They contain:

- No compiled code or binaries
- No npm/pip dependencies
- No MCP server processes
- No background services or daemons

Skills and agents are natural-language instructions that Claude Code reads and follows. They operate within Claude Code's existing permission model — every file write, bash command, and tool invocation goes through Claude Code's standard approval flow. Arness does not bypass or modify Claude Code's permission system.

### Trust Boundaries

```
User
  └── Claude Code (permission model, sandboxed bash, file access controls)
        └── Arness plugins (instruction files — no additional privileges)
              └── External tools (gh, bkt, cloud CLIs — own credential management)
```

Arness plugins run with the same privileges as any instruction in Claude Code. They cannot:
- Access files outside Claude Code's project scope
- Execute commands without Claude Code's permission checks
- Bypass the user's approval for file modifications or tool invocations
- Access credentials stored by external tools

### Credential Delegation

**Arness does not store credentials, tokens, API keys, or secrets in any of its files.** All authentication is delegated to the external tools and services that handle it natively:

| Service | Authentication Handled By | What Arness Stores |
|---------|--------------------------|-----------------|
| GitHub | `gh` CLI (`~/.config/gh/`) | Nothing — checks `gh auth status` |
| Bitbucket | `bkt` CLI | Nothing — checks `bkt auth status` |
| Jira | Atlassian MCP server (OAuth 2.1) | Platform URL and project key only |
| AWS / GCP / Azure | Provider CLIs | Nothing — checks CLI auth state |
| Claude API | Claude Code credential management | Nothing |

Arness skills verify that external tools are authenticated before proceeding. They never prompt for, store, or transmit credentials.

### Configuration Security

Arness uses a layered configuration model with clear separation between shared and local data:

| Location | Purpose | Committed to Git? |
|----------|---------|-------------------|
| `CLAUDE.md` `## Arness` section | Structural config (directory paths, tool choices, preferences) | Yes — team-shared |
| `~/.arness/user-profile.yaml` | Personal profile (role, experience, technology preferences) | No — user home directory |
| `.claude/arness-profile.local.md` | Project-level profile override | No — gitignored |
| `.claude/settings.json` | Claude Code project settings (task list ID) | Yes — team-shared |
| `.claude/settings.local.json` | Machine-specific Claude Code overrides | No — gitignored |

**What is committed** contains only structural configuration: directory paths, feature flags, platform identifiers (e.g., `github`, `bitbucket`), and tool preferences. None of these fields contain credentials or sensitive data.

**What is gitignored** includes machine-specific overrides and personal preferences. The `.gitignore` entries are:
```
.claude/settings.local.json
.claude/*.local.md
```

Note: `.claude/settings.json` is intentionally **not** gitignored — it contains team-shared settings per Claude Code's official design.

### Data Handling

Arness reads and generates project artifacts (specifications, plans, reports, pattern documentation) stored in the project's `.arness/` directory. These artifacts contain:

- Feature specifications and implementation plans
- Code pattern documentation extracted from the codebase
- Implementation and testing reports
- Progress tracking data

Arness does not transmit project data to any external service. All data flows through Claude Code's standard API interaction with Anthropic's models, subject to Anthropic's data handling policies.

## Supply Chain Security

### Current Posture

- **Source provenance**: Arness is distributed as a public GitHub repository. Plugin installations can be pinned to specific git commits using the `sha` field in marketplace entries.
- **Content auditability**: All plugin files are human-readable markdown and JSON — no minified code, no binaries, no obfuscated content.
- **No transitive dependencies**: Arness plugins have no package dependencies (no `node_modules`, no `requirements.txt`, no lock files). The attack surface is limited to the files in this repository.
- **Shell scripts**: A small number of shell scripts exist in `skills/*/scripts/`. These are short, auditable, and execute through Claude Code's permission system.

### Marketplace Integrity

The marketplace manifest (`.claude-plugin/marketplace.json`) references plugins by relative path within this repository. Claude Code's `strictKnownMarketplaces` managed setting allows enterprise administrators to restrict which marketplaces users can install from.

### Future Direction

Claude Code's plugin ecosystem is evolving. When the platform adds native plugin signing and integrity verification (tracked in [anthropics/claude-code#29729](https://github.com/anthropics/claude-code/issues/29729)), Arness will adopt the official mechanism. Until then, the combination of git commit pinning and content auditability provides the primary integrity guarantee.

## For Enterprise Administrators

Claude Code provides several managed settings relevant to Arness plugin security:

- **`strictKnownMarketplaces`**: Restrict plugin installation to approved marketplace sources
- **`pluginTrustMessage`**: Display custom security warnings when users install plugins
- **Permission policies**: Control what file operations, bash commands, and MCP tools are allowed
- **`deny` rules in `.claude/settings.json`**: Block reads of sensitive directories (`.env`, `secrets/`)

These settings are configured at the organizational level via MDM, registry policies, or `/etc/claude-code/managed-settings.json`. See [Claude Code Settings documentation](https://code.claude.com/docs/en/settings) for details.

## Security-Adjacent Skills

Arness includes skills that help users improve their project's security posture:

- **`arn-code-feature-spec`**: Invokes a security specialist agent for features involving authentication, payments, uploads, or other security-sensitive areas
- **`arn-infra-secrets`**: Scans for exposed secrets in infrastructure code and recommends remediation
- **`arn-infra-define`**: Runs security audits on generated infrastructure-as-code via the `arn-infra-security-auditor` agent

These skills provide guidance — they do not enforce security policies or modify security configurations automatically.
