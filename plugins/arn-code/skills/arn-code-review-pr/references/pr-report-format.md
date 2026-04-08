# PR Review Report Format

Standard report format for `/arn-code-review-pr` findings.

## Format

```markdown
## PR Review Analysis: #<number> — <title>

### Summary
- Total comments analyzed: N
- Valid issues: N (N critical, N moderate, N minor)
- False positives: N
- Already fixed: N
- Discussion points: N

### Valid Issues (should fix)

1. **[VALID — Critical]** `<file_path>:<line>` — @<reviewer>: "<comment summary>"
   - **Assessment**: <Why this is valid and what impact it has>
   - **Suggested fix**: <Specific fix>

2. **[VALID (MINOR)]** `<file_path>:<line>` — @<reviewer>: "<comment summary>"
   - **Assessment**: <Why this is valid>
   - **Suggested fix**: <Specific fix>

### False Positives (no action needed)

1. **[FALSE POSITIVE]** `<file_path>:<line>` — @<reviewer>: "<comment summary>"
   - **Assessment**: <Why this is not an issue>

### Already Fixed

1. **[ALREADY FIXED]** `<file_path>:<line>` — @<reviewer>: "<comment summary>"
   - **Assessment**: Fixed in commit <sha>.

### Discussion Points

1. **[DISCUSSION]** @<reviewer>: "<comment summary>"
   - **Context**: <What's being discussed, not an actionable issue>
```

## Notes

- Group related comments about the same concern into a single finding
- Order findings by severity within each section (critical first)
- Include the reviewer's username for traceability
- Omit empty sections (e.g., if no false positives, skip that section)
