# Issue Report Template

Template for GitHub issues created by `/arn-infra-report`. The skill assembles this template with data from the user's description and the arn-infra-doctor agent's diagnostic findings.

## Template Format

The issue body follows this structure:

```markdown
## Arness Infra Report

**Plugin version:** <version from plugin.json>
**Skill(s) involved:** <skill names identified by the arn-infra-doctor diagnostic>

### User Report

> <user's original description of the issue, quoted verbatim>

### Diagnostic Findings

<arn-infra-doctor's findings — only ISSUE items, not OK items>

### Assessment

<arn-infra-doctor's root cause assessment — 1-3 sentences>

### Config State

\```
<relevant ## Arness Infra fields from the project's CLAUDE.md, or "Arness Infra not configured">
\```

### Environment

- **OS:** <detected via uname or "unknown">
- **Git:** <yes/no>
- **GitHub:** <yes/no>
- **gh CLI:** <authenticated/not authenticated/not installed>
- **Docker:** <version or not installed>
- **IaC tool:** <terraform/tofu/pulumi/cdk/bicep version or not installed>
- **Cloud CLI:** <aws/gcloud/az version or not installed>

---
*Filed via `/arn-infra-report` — Arness Infra v<version>*
```

## Issue Title Format

Use a concise title derived from the doctor's assessment:

`[arn-infra-report] <skill name>: <brief issue summary>`

Examples:
- `[arn-infra-report] arn-infra-deploy: deployment fails with cost threshold exceeded`
- `[arn-infra-report] arn-infra-containerize: Dockerfile generation ignores multi-stage`
- `[arn-infra-report] arn-infra-execute-change: rollback checkpoint not created`
- `[arn-infra-report] arn-infra-define: validation ladder fails on Checkov step`
- `[arn-infra-report] arn-infra-pipeline: GitHub Actions workflow generation error`

## Privacy Guidelines

The issue MUST NOT include:
- Project source code or file contents
- Business logic or domain-specific data
- File paths outside of Arness configuration directories
- User credentials, tokens, authentication details, or cloud account IDs
- Any information that could identify the user's project or infrastructure
- Cloud resource ARNs, IPs, domains, or account identifiers

The issue SHOULD include:
- Arness configuration state (## Arness Infra fields)
- Directory existence checks (exists/missing, not contents)
- Skill names and pipeline stage where the issue occurred
- Error messages related to Arness workflow behavior
- Plugin version and environment information
- Tool availability (Docker, IaC tool, cloud CLI — version only, not auth details)

## Labels

The `arn-infra-report` label is applied automatically. This label must be pre-created on the plugin repository by maintainers — the skill does not create it.

## Notes

- The user ALWAYS reviews and approves the issue before submission
- If the user edits the draft, use their edited version
- If submission fails, save the report as a local markdown file
