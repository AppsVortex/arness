# Issue Report Template

Template for GitHub issues created by `/arn-spark-report`. The skill assembles this template with data from the user's description and the arn-spark-doctor agent's diagnostic findings.

## Template Format

The issue body follows this structure:

```markdown
## Arness Spark Report

**Plugin version:** <version from plugin.json>
**Skill(s) involved:** <skill names identified by the arn-spark-doctor diagnostic>

### User Report

> <user's original description of the issue, quoted verbatim>

### Diagnostic Findings

<arn-spark-doctor's findings — only ISSUE items, not OK items>

### Assessment

<arn-spark-doctor's root cause assessment — 1-3 sentences>

### Config State

\```
<relevant ## Arness Spark fields from the project's CLAUDE.md, or "Arness Spark not configured">
\```

### Environment

- **OS:** <detected via uname or "unknown">
- **Git:** <yes/no>
- **GitHub:** <yes/no>
- **gh CLI:** <authenticated/not authenticated/not installed>
- **Node.js:** <version or not installed>
- **Playwright:** <available/not available>

---
*Filed via `/arn-spark-report` — Arness Spark v<version>*
```

## Issue Title Format

Use a concise title derived from the doctor's assessment:

`[arn-spark-report] <skill name>: <brief issue summary>`

Examples:
- `[arn-spark-report] arn-spark-discover: product concept not saved after discovery`
- `[arn-spark-report] arn-spark-naming: WHOIS check fails with timeout`
- `[arn-spark-report] arn-spark-clickable-prototype: Playwright journey test crashes`

## Privacy Guidelines

The issue MUST NOT include:
- Project source code or file contents
- Business logic or domain-specific data
- File paths outside of Arness configuration directories
- User credentials, tokens, or authentication details
- Any information that could identify the user's project

The issue SHOULD include:
- Arness Spark configuration state (## Arness fields)
- Directory existence checks (exists/missing, not contents)
- Skill names and pipeline stage where the issue occurred
- Error messages related to Arness Spark workflow behavior
- Plugin version and environment information

## Labels

The `arn-spark-report` label is applied automatically. This label must be pre-created on the plugin repository by maintainers — the skill does not create it.

## Notes

- The user ALWAYS reviews and approves the issue before submission
- If the user edits the draft, use their edited version
- If submission fails, save the report as a local markdown file
