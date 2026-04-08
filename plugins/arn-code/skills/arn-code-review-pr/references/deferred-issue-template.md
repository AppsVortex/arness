# Deferred Issue Template

Template for issues created from deferred PR review findings. Used by `/arn-code-review-pr` when the user chooses to create issues for items that don't need to be fixed in the current PR. Supports both GitHub and Jira issue trackers.

## Template

```markdown
## Source

From PR #<pr_number> review by @<reviewer>

**File**: `<file_path>:<line>`
**Category**: <VALID | VALID (MINOR) | DISCUSSION>
**Severity**: <Critical | Moderate | Low>

## Reviewer Comment

> <Original reviewer comment>

## Assessment

<Arness's assessment of the issue — why it's valid, what impact it has>

## Suggested Fix

<Specific fix suggestion, if applicable>

## Context

- **PR**: #<pr_number> — <pr_title>
- **Branch**: <branch_name>
- **Plan reference**: <plans-dir>/<PROJECT_NAME>/ (if available)

---
*Created from PR review via `/arn-code-review-pr`*
```

## Labels

Issues created from this template should be tagged with:
- `arness-backlog` — always applied
- Priority label — one of `arness-priority-high`, `arness-priority-medium`, `arness-priority-low` (user selects, default: `arness-priority-low`)

## Creation Command

### GitHub

```bash
gh issue create \
  --title "PR #<number> feedback: <short description>" \
  --body "<rendered template>" \
  --label "arness-backlog,arness-priority-<level>"
```

Ensure labels exist before creating the issue (use `gh label create --force` which is idempotent).

### Jira

Use the Atlassian MCP server to create a Jira Task issue:

- **Project:** `<Jira project from ## Arness config>`
- **Summary:** PR #<number> feedback: <short description>
- **Description:** <rendered template above>
- **Labels:** `[arness-backlog, arness-priority-<level>]`
- **Priority:** mapped from level (high -> High, medium -> Medium, low -> Low)

Jira labels are freeform — no pre-creation needed.
