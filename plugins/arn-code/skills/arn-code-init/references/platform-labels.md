# Arness Platform Labels

Arness uses labels for issue management and tracking across supported platforms. The label strategy varies by platform: GitHub uses repository labels with explicit creation, while Jira uses freeform labels with implicit creation plus native issue types and priorities.

---

## GitHub

Labels created during `/arn-code-init` when GitHub integration is detected. These labels are used by Arness skills for issue management and tracking.

### Labels

| Label | Color | Purpose | Used By |
|-------|-------|---------|---------|
| `arness-backlog` | `#d4c5f9` (lavender) | Deferred items from PRs or postponed features | `/arn-code-review-pr`, `/arn-code-create-issue`, `/arn-code-pick-issue` |
| `arness-feature-issue` | `#0e8a16` (green) | Feature requests tracked via Arness | `/arn-code-create-issue`, `/arn-code-pick-issue` |
| `arness-bug-issue` | `#d93f0b` (red) | Bug reports tracked via Arness | `/arn-code-create-issue`, `/arn-code-pick-issue` |
| `arness-priority-high` | `#b60205` (dark red) | High priority | `/arn-code-create-issue`, `/arn-code-pick-issue`, `/arn-code-review-pr` |
| `arness-priority-medium` | `#fbca04` (yellow) | Medium priority | `/arn-code-create-issue`, `/arn-code-pick-issue`, `/arn-code-review-pr` |
| `arness-priority-low` | `#c5def5` (light blue) | Low priority | `/arn-code-create-issue`, `/arn-code-pick-issue`, `/arn-code-review-pr` |
| `arness-rejected` | `#e4e669` (olive) | Issue reviewed and rejected as invalid or out of scope | `/arn-code-pick-issue` |

### Plugin Repository Label

The following label lives on the **Arness plugin repository** (not on user projects). It is pre-created by plugin maintainers and used by `/arn-code-report` to tag diagnostic issues.

| Label | Color | Purpose | Used By |
|-------|-------|---------|---------|
| `arn-code-report` | `#1d76db` (blue) | Issue reported via /arn-code-report diagnostic | `/arn-code-report` (plugin repo only) |

### Creation Command

Labels are created using `gh label create` which is idempotent -- existing labels are skipped:

```bash
gh label create "arness-backlog" --color "d4c5f9" --description "Deferred items from PRs or postponed features" --force
gh label create "arness-feature-issue" --color "0e8a16" --description "Feature requests tracked via Arness" --force
gh label create "arness-bug-issue" --color "d93f0b" --description "Bug reports tracked via Arness" --force
gh label create "arness-priority-high" --color "b60205" --description "High priority" --force
gh label create "arness-priority-medium" --color "fbca04" --description "Medium priority" --force
gh label create "arness-priority-low" --color "c5def5" --description "Low priority" --force
gh label create "arness-rejected" --color "e4e669" --description "Issue reviewed and rejected as invalid or out of scope" --force
```

### Notes

- Labels are only created when GitHub integration is detected during `/arn-code-init`
- The `--force` flag updates existing labels if the color or description has changed
- Projects without GitHub integration skip label creation entirely
- Skills that use labels check for their existence and create missing ones on demand

---

## Jira

Jira labels are freeform -- they are created implicitly on first use and do not need to be pre-created during `/arn-code-init`. Arness combines Jira labels with native issue types and priority fields for a richer mapping.

### Labels

Arness uses the following label names when creating and filtering Jira issues:

| Label | Purpose | Used By |
|-------|---------|---------|
| `arness-feature-issue` | Feature requests tracked via Arness | `/arn-code-create-issue`, `/arn-code-pick-issue` |
| `arness-bug-issue` | Bug reports tracked via Arness | `/arn-code-create-issue`, `/arn-code-pick-issue` |
| `arness-backlog` | Deferred items from PRs or postponed features | `/arn-code-review-pr`, `/arn-code-create-issue`, `/arn-code-pick-issue` |
| `arness-rejected` | Issue reviewed and rejected as invalid or out of scope | `/arn-code-pick-issue` |
| `arness-priority-high` | High priority | `/arn-code-create-issue`, `/arn-code-pick-issue`, `/arn-code-review-pr` |
| `arness-priority-medium` | Medium priority | `/arn-code-create-issue`, `/arn-code-pick-issue`, `/arn-code-review-pr` |
| `arness-priority-low` | Low priority | `/arn-code-create-issue`, `/arn-code-pick-issue`, `/arn-code-review-pr` |

### Issue Type Mapping

Arness maps its label categories to native Jira issue types:

| Arness Label | Jira Issue Type |
|------------|-----------------|
| `arness-feature-issue` | Story |
| `arness-bug-issue` | Bug |
| `arness-backlog` | Task |

### Priority Mapping

Arness maps its priority labels to native Jira priority levels:

| Arness Label | Jira Priority |
|------------|---------------|
| `arness-priority-high` | High |
| `arness-priority-medium` | Medium |
| `arness-priority-low` | Low |

### Notes

- Jira labels are applied in addition to native issue type and priority fields
- Labels are created implicitly by Jira on first use -- no `create` command is needed
- Arness uses both the label and the native Jira field so issues are filterable via JQL or the label sidebar
- Bitbucket's built-in issue tracker is not supported by Arness
