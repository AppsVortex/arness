---
name: arn-code-create-issue
description: >-
  This skill should be used when the user says "create issue", "file issue",
  "arness code issue", "arness code create issue", "arn-code-create-issue", "report bug", "request feature", "add to backlog", "create
  GitHub issue", "create Jira issue", "file a bug", "submit issue",
  "log issue", "open issue", or wants
  to create an issue in the current repository with Arness labels for type and
  priority. Requires an issue tracker (GitHub or Jira) to be configured. Do
  NOT use this for picking/browsing existing issues — use /arn-code-pick-issue
  for that.
version: 1.1.0
---

# Arness Create Issue

Create an issue in the configured issue tracker (GitHub or Jira) with Arness labels for type and priority.

---

## Step 1: Check Prerequisites

If no `## Arness` section exists in the project's CLAUDE.md, inform the user: "Arness is not configured for this project yet. Run `/arn-planning` to get started — it will set everything up automatically." Do not proceed without it.

Read the **Issue tracker** field from `## Arness` config in the project's `CLAUDE.md` (values: `github`, `jira`, or `none`). If the `Issue tracker` field is not present, fall back to legacy detection: check for `GitHub: yes` and treat as `github`; otherwise treat as `none`.

### If Issue tracker is github

1. `git rev-parse --is-inside-work-tree` — must be inside a git repository
2. `git remote -v` — must have a GitHub remote (origin pointing to github.com)
3. `gh auth status` — the GitHub CLI must be authenticated

If **any** check fails, inform the user what is missing and suggest running `/arn-planning` to get started. Do not proceed until all prerequisites are satisfied.

### If Issue tracker is jira

1. Read **Jira project** and **Jira site** from `## Arness` config
2. Verify the Atlassian MCP server is available (attempt a lightweight MCP call, e.g., list projects)
3. If the MCP server is not available: "The Atlassian MCP server is not available. Run `/mcp` to check status, or run `/arn-planning` to reconfigure."

### If Issue tracker is none

Inform the user: "Issue management is not configured for this project. Run `/arn-planning` to get started, or configure the issue tracker manually."

STOP — do not proceed.

---

**Trigger message inference:** If the user's trigger message contains enough context to infer the issue type, priority, and title (e.g., "create issue: high priority bug — checkout page crashes on empty cart"), extract these values and present them for confirmation rather than re-asking each question separately. If the trigger message is ambiguous, proceed with the standard question flow below.

## Step 2: Classify Issue Type

Ask the user to select the issue type using `AskUserQuestion`. Present these options:

| Option | GitHub Label | Jira Issue Type | Jira Label | Description |
|--------|-------------|-----------------|------------|-------------|
| Feature request | `arness-feature-issue` | Story | `arness-feature-issue` | A new feature or enhancement |
| Bug report | `arness-bug-issue` | Bug | `arness-bug-issue` | Something is broken or not working as expected |
| Backlog item | `arness-backlog` | Task | `arness-backlog` | Deferred or low-urgency item for future consideration |

The user-facing question is the same regardless of issue tracker. The internal mapping differs by platform and is applied during submission (Step 5).

---

## Step 3: Set Priority

Ask the user to select the priority using `AskUserQuestion`. Present these options:

| Option | GitHub Label | Jira Priority | Description |
|--------|-------------|---------------|-------------|
| High | `arness-priority-high` | High | Urgent — should be addressed soon |
| Medium | `arness-priority-medium` | Medium | Important but not urgent |
| Low (default) | `arness-priority-low` | Low | Nice to have, address when convenient |

If the user does not express a preference, default to **Low**.

The user-facing question is the same regardless of issue tracker. The internal mapping differs by platform and is applied during submission (Step 5).

---

## Step 4: Compose Issue

1. Ask the user for the **issue title** (short, descriptive).
2. Ask the user for the **issue description**, or offer to compose one on their behalf.
3. If Arness context is available in the current session (spec, plan, or branch name), offer to pre-populate the description with relevant references:
   - Link to the current spec file if one exists
   - Reference the current plan/project if one is active
   - Include the branch name for traceability

### If Issue tracker is github

4. **Deferred Label Check:**

   Check if Arness labels exist by running `gh label list --search "arness-"`. If fewer than 7 Arness labels are found, create the missing ones using `gh label create --force` for each label per `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-init/references/platform-labels.md`. This is idempotent and safe to run on every invocation.

### If Issue tracker is jira

4. No label pre-creation needed — Jira labels are freeform and created implicitly when applied to an issue.

---

## Step 5: Submit

### If Issue tracker is github

Create the issue using the GitHub CLI:

```bash
gh issue create --title "<title>" --body "<body>" --label "<type-label>,<priority-label>"
```

Report to the user:

- The issue number and URL (returned by `gh issue create`)
- The labels that were applied
- Suggest: "Run `/arn-code-pick-issue` later to pick this up for implementation, or continue with your current work."

### If Issue tracker is jira

Use the Atlassian MCP server to create a Jira issue:

- **Project:** `<Jira project from ## Arness config>`
- **Issue type:** Story | Bug | Task (from Step 2 mapping)
- **Summary:** `<title>`
- **Description:** `<body>` (in Jira-compatible markdown)
- **Priority:** High | Medium | Low (from Step 3 mapping)
- **Labels:** `[arness-<type-label>, arness-priority-<level>]`

Report to the user:

- The issue key (e.g., PROJ-42) and URL: `https://<jira-site>/browse/<issue-key>`
- The issue type and priority that were set
- Suggest: "Run `/arn-code-pick-issue` later to pick this up for implementation, or continue with your current work."

---

## Error Handling

- **Issue tracker is `none`** — Inform the user that issue management is not configured. Suggest running `/arn-planning` to get started.
- **GitHub not available** — Inform the user and suggest running `/arn-planning` to get started.
- **`gh` CLI not authenticated** — Suggest running `gh auth login` to authenticate.
- **Atlassian MCP server not available** — Inform the user. Suggest running `/mcp` to check status or `/arn-planning` to reconfigure.
- **Jira project not found** — Verify the Jira project key in `## Arness` config is correct. Suggest running `/arn-planning` to reconfigure.
- **Label creation fails (GitHub)** — Warn the user but proceed with issue creation. Label creation may require repository admin permissions.
- **Issue creation fails** — Show the full error message and offer to retry.
- **No GitHub remote** — Inform the user that GitHub issues require a GitHub-hosted repository.

## Conventions

- Use `${CLAUDE_PLUGIN_ROOT}` for all paths referencing plugin files.
- Reference other Arness skills with the `/arn-code:skill-name` prefix (e.g., `/arn-code-init`, `/arn-code-pick-issue`).
