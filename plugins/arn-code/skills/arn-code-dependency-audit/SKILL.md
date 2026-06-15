---
name: arn-code-dependency-audit
description: >-
  This skill should be used when the user says "dependency audit",
  "audit dependencies", "security dependency review", "CVE review",
  "npm audit", "pip audit", "cargo audit", "license audit",
  "supply chain check", "package vulnerability scan", or wants Arness Code
  to review project dependencies for known vulnerabilities, outdated packages,
  license concerns, and low-risk remediation planning.
version: 0.1.0
---

# Arness Dependency Audit

Run a dependency and supply-chain readiness review, then route safe remediation
through the Arness pipeline.

This skill is an **assessment and routing skill**. It does not continuously
monitor dependencies, upload reports, or modify CI by default. It runs local
package-manager checks only after user approval and turns the results into a
prioritized plan.

## Safety Rules

- Do not run audit commands before showing the detected package managers and
  asking for approval.
- Do not send dependency manifests, lockfiles, audit output, credentials, or
  private repository context to external services.
- Do not auto-upgrade packages. Recommend or plan upgrades only after reviewing
  the affected package, dependency path, and likely breaking-change risk.
- Do not add scheduled monitoring, SARIF upload, or CI workflows unless the
  user explicitly asks for that scope.
- Redact tokens, registry credentials, private package URLs, and internal host
  names from any report.

## Step 1: Check Prerequisites

If no `## Arness` section exists in the project's `CLAUDE.md`, inform the user:
"Arness is not configured for this project yet. Run `/arn-planning` to get
started — it will set everything up automatically." Do not proceed without it.

Read the `## Arness` section and identify:

- Plans directory
- Specs directory
- Code patterns directory
- Git configuration
- Issue tracker configuration, if present

## Step 2: Detect Package Managers

Inspect the repository for dependency manifests and lockfiles.

| Ecosystem | Signals | Suggested command |
| --- | --- | --- |
| Node.js | `package.json`, `package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, `bun.lock` | `npm audit --json`, `pnpm audit --json`, `yarn npm audit --json`, or `bun audit --json` |
| Python | `pyproject.toml`, `requirements*.txt`, `poetry.lock`, `uv.lock` | `pip-audit --format json` or `uv pip audit` when available |
| Rust | `Cargo.toml`, `Cargo.lock` | `cargo audit --json` |
| Go | `go.mod`, `go.sum` | `govulncheck ./...` |

If no supported manifest is found, report that dependency audit cannot proceed
and suggest `/arn-code-assess` for a broader codebase assessment.

## Step 3: Gate G1 — Approval To Run Local Commands

Present the detected ecosystems and the exact commands you intend to run.

Ask:

**"Run local dependency audit commands for the detected ecosystems?"**

Options:

1. **Run audits** — Execute read-only audit commands locally
2. **Dry-run report only** — Create a checklist from manifests without running tools
3. **Stop** — Do not continue

If the user chooses dry-run, skip Step 4 and clearly label findings as
manifest-only.

## Step 4: Run Read-Only Audits

Run only the approved commands. Prefer JSON output when available. Capture:

- Command
- Exit code
- Tool version, if easy to obtain
- Raw finding count by severity
- Package name, advisory id/link, current version, fixed version, and dependency path

If a command is unavailable, record it as a setup gap rather than installing
tools automatically.

## Step 5: Triage Findings

Group findings by severity and remediation risk.

| Bucket | Criteria | Recommended route |
| --- | --- | --- |
| Swift patch | Patch/minor update, clear fixed version, low blast radius | `/arn-code-swift` |
| Standard remediation | Several packages, lockfile refresh, moderate test surface | `/arn-code-standard` |
| Thorough remediation | Major upgrades, framework migration, or shared dependency roots | `/arn-planning` |
| Documented exception | Dev-only, unreachable, no fix, or accepted risk with evidence | Record in report |

For each finding, include:

- Package and ecosystem
- Advisory reference
- Direct or transitive dependency path
- Runtime, build-time, or dev-only exposure when inferable
- Fix availability
- Suggested ceremony tier
- Tests or checks to run after remediation

## Step 6: Write Audit Report

Write a report to the configured specs directory:

`<specs-dir>/DEPENDENCY_AUDIT_<scope>.md`

Use this structure:

```markdown
# Dependency Audit: <scope>

## Summary

- Date:
- Ecosystems checked:
- Commands run:
- Highest severity:
- Recommended next route:

## Findings

| Severity | Package | Ecosystem | Direct/Transitive | Fix | Route | Notes |
| --- | --- | --- | --- | --- | --- | --- |

## Setup Gaps

## Suggested Remediation Plan

## Documented Exceptions

## Verification Commands
```

## Step 7: Gate G2 — Choose Remediation

Ask:

**"How should Arness handle these dependency findings?"**

Options:

1. **Fix the highest-priority safe patch** — Route one swift patch first
2. **Plan all actionable findings** — Create a standard or thorough plan
3. **Document only** — Keep the report without implementation

Route according to the user's answer:

- Swift patch → invoke `/arn-code-swift` with the selected finding and report path
- Plan all → invoke `/arn-planning` with the report as source context
- Document only → stop after reporting the file path

## Error Handling

- **Audit command unavailable** — Record setup gap and suggest installation docs, but do
  not install tools automatically.
- **Audit command fails because of registry authentication** — Stop and ask the user to
  resolve credentials locally. Do not request or display tokens.
- **Private package names or registry URLs appear** — Redact them in the report unless
  the user confirms they are safe to document.
- **No fix is available** — Mark as documented exception or suggest compensating
  controls rather than forcing an upgrade.
