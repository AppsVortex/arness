# Issue Report Template

Template for GitHub issues created by `/arn-code-report`. The skill assembles this template with data from the user's description and the arn-code-doctor agent's diagnostic findings.

## Template Format

The issue body follows this structure:

```markdown
## Arness Code Report

**Plugin version:** <version from plugin.json>
**Skill(s) involved:** <skill names identified by the arn-code-doctor diagnostic>

### User Report

> <user's original description of the issue, quoted verbatim>

### Diagnostic Findings

<arn-code-doctor's findings — only ISSUE items, not OK items>

### Assessment

<arn-code-doctor's root cause assessment — 1-3 sentences>

### Config State

\```
<relevant ## Arness fields from the project's CLAUDE.md, or "Arness not configured">
\```

### Environment

- **OS:** <detected via uname or "unknown">
- **Git:** <yes/no>
- **GitHub:** <yes/no>
- **gh CLI:** <authenticated/not authenticated/not installed>

---
*Filed via `/arn-code-report` — Arness v<version>*
```

## Issue Title Format

Use a concise title derived from the doctor's assessment:

`[arn-code-report] <skill name>: <brief issue summary>`

Examples:
- `[arn-code-report] arn-code-save-plan: templates directory empty after init`
- `[arn-code-report] arn-code-execute-plan: tasks skipped despite no blockers`
- `[arn-code-report] arn-code-init: GitHub labels not created`

## Privacy Guidelines

The issue MUST NOT include:
- Project source code or file contents
- Business logic or domain-specific data
- File paths outside of Arness configuration directories
- User credentials, tokens, or authentication details
- Any information that could identify the user's project

The issue SHOULD include:
- Arness configuration state (## Arness fields)
- Directory existence checks (exists/missing, not contents)
- Skill names and pipeline stage where the issue occurred
- Error messages related to Arness workflow behavior
- Plugin version and environment information

## Labels

The `arn-code-report` label is applied automatically. This label must be pre-created on the plugin repository by maintainers — the skill does not create it.

## Notes

- The user ALWAYS reviews and approves the issue before submission
- If the user edits the draft, use their edited version
- If submission fails, save the report as a local markdown file
