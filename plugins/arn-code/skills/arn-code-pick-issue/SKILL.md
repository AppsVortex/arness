---
name: arn-code-pick-issue
description: >-
  This skill should be used when the user says "pick issue", "work on issue",
  "arness code pick", "arness code pick issue", "arn-code-pick-issue", "grab issue", "pick from backlog", "what should I work on",
  "show issues", "find issue", "browse issues", "next issue", "select issue",
  "choose issue",
  "what's unblocked", "work on next feature", "pick from feature tracker",
  or wants to browse issues filtered by Arness labels, select one, and route
  it to the appropriate Arness pipeline skill for implementation. Supports
  local-first dependency resolution from a greenfield feature backlog when
  available. Requires an issue tracker (GitHub or Jira) to be configured
  for remote issue browsing. Do NOT use this for creating new issues — use
  /arn-code-create-issue for that.
version: 1.3.0
---

# Arness Pick Issue

Browse issues filtered by Arness labels, select one for assessment, and route it to the appropriate Arness pipeline skill for implementation. When a greenfield feature backlog with a Feature Tracker exists, offers local-first dependency resolution to surface unblocked features without network calls.

---

## Step 1: Check Prerequisites

If no `## Arness` section exists in the project's CLAUDE.md, inform the user: "Arness is not configured for this project yet. Run `/arn-planning` to get started — it will set everything up automatically." Do not proceed without it.

Read the **Issue tracker** field from `## Arness` config in the project's `CLAUDE.md` (values: `github`, `jira`, or `none`). If the `Issue tracker` field is not present, fall back to legacy detection: check for `GitHub: yes` and treat as `github`; otherwise treat as `none`.

### If Issue tracker is github

1. `git rev-parse --is-inside-work-tree` — confirm the working directory is inside a git repository.
2. `git remote -v` — confirm a GitHub remote exists (the origin URL must contain `github.com`).
3. `gh auth status` — confirm the GitHub CLI is authenticated.

If any check fails, inform the user what is missing and suggest running `/arn-planning` to get started. Do not proceed until all prerequisites are satisfied.

### If Issue tracker is jira

1. Read **Jira project** and **Jira site** from `## Arness` config
2. Verify the Atlassian MCP server is available (attempt a lightweight MCP call, e.g., list projects)
3. If the MCP server is not available: "The Atlassian MCP server is not available. Run `/mcp` to check status, or run `/arn-planning` to reconfigure."

### If Issue tracker is none

Check for a greenfield feature backlog before stopping:

1. Read `## Arness` config — check if a **Vision directory** field exists (only set by `arn-spark-init`, never by core `arn-code-init`)
2. If Vision directory exists, check if `<vision-dir>/features/feature-backlog.md` exists
3. If the file exists, check if it contains a `## Feature Tracker` table

**If all three pass:** Proceed to Step 1b (Local Backlog Check). The greenfield feature backlog provides a local-only alternative to remote issue browsing. Inform the user: "No remote issue tracker is configured, but a local greenfield feature backlog was found. Showing local features."

**If any condition fails:** Inform the user: "Issue management is not configured for this project. Run `/arn-planning` to get started, or configure the issue tracker manually." STOP — do not proceed.

---

## Step 1b: Local Backlog Check (Greenfield Integration)

This step is entirely optional — it activates only when a greenfield feature backlog exists. Projects without greenfield skip this step silently and proceed to Step 2. It resolves dependencies in the local Feature Tracker, presents unblocked features, validates against the remote issue tracker, and updates the tracker status.

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-pick-issue/references/greenfield-backlog-resolution.md` for the full detection chain, resolution workflow, and sub-feature handling.

If the user picks a feature from the local backlog, skip Steps 2-4 and proceed to Step 5 (Assess Issue).

---

## Step 2: Filter Issues

**Deferred Label Check:**

If Platform is `github`: check if Arness labels exist by running `gh label list --search "arness-"`. If fewer than 7 Arness labels are found, create the missing ones using `gh label create --force` for each label per `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-init/references/platform-labels.md`. This is idempotent and safe to run on every invocation.

If Platform is `bitbucket` or Issue tracker is `jira`: no label creation needed (Jira labels are implicit, Bitbucket uses different mechanisms).

Ask the user how they want to filter issues, or infer filters from hints in the trigger message. Use `AskUserQuestion` to gather preferences.

**By type:**
- `arness-feature-issue` — Feature requests only
- `arness-bug-issue` — Bug reports only
- `arness-backlog` — Backlog items only
- All Arness-labeled — any issue with a Arness label

**By priority (optional):**
- `arness-priority-high`
- `arness-priority-medium`
- `arness-priority-low`
- Any priority

**By state:** Open (default), Closed, All

**Free text search (optional):** If the user provides keywords in their trigger message, use them as a search filter.

### If Issue tracker is github

Build the label filter from the user's selections. Multiple labels are combined with AND logic in `gh issue list`.

### If Issue tracker is jira

Build a JQL query from the user's selections. Labels map directly (e.g., `arness-feature-issue`). Priority maps to Jira priority values (High, Medium, Low). State maps to Jira statuses (e.g., Open excludes `Done`).

---

## Step 3: Fetch and Paginate

### If Issue tracker is github

Use the `gh` CLI to fetch issues matching the constructed filter:

```bash
gh issue list --label "<label1>,<label2>" --state open --limit 10 --json number,title,labels,createdAt,author
```

Display results as a numbered list with issue number, title, labels, and age:

```
1. #42 — Add WebSocket support [arness-feature-issue, arness-priority-high] (3 days ago)
2. #38 — Fix checkout 500 error [arness-bug-issue, arness-priority-medium] (1 week ago)
3. #35 — Refactor auth middleware [arness-backlog, arness-priority-low] (2 weeks ago)
...
```

If more than 10 results exist, offer "Show more" to fetch the next page.

If no results match the filters, inform the user and suggest either adjusting the filters or creating a new issue via `/arn-code-create-issue`.

### If Issue tracker is jira

Use the Atlassian MCP server to search Jira issues with JQL:

```
project = <JIRA_PROJECT>
  AND labels in (<selected-arness-labels>)
  AND status != Done
  ORDER BY created DESC
```

Request fields: `key`, `summary`, `labels`, `created`, `assignee`, `status`, `priority`.

Display results as a numbered list:

```
1. PROJ-42 — Add WebSocket support [Story, High] (3 days ago)
2. PROJ-38 — Fix checkout error [Bug, Medium] (1 week ago)
3. PROJ-35 — Refactor auth middleware [Task, Low] (2 weeks ago)
...
```

Paginate: show 10 results at a time, offer "Show more" option.

If no results match the filters, inform the user and suggest either adjusting the filters or creating a new issue via `/arn-code-create-issue`.

---

## Step 4: Select Issue

Wait for the user to select an issue by number from the displayed list.

### If Issue tracker is github

Fetch the full issue details:

```bash
gh issue view <number> --json number,title,body,labels,comments,assignees,createdAt,author
```

Display the full issue to the user: title, body, labels, comments, assignees, and author.

### If Issue tracker is jira

Use the Atlassian MCP server to get full issue details by key (e.g., PROJ-42).

Display the full issue to the user: summary, description, issue type, labels, priority, status, assignee, and comments.

---

## Step 5: Assess Issue

Invoke the most appropriate agent for a brief assessment based on the issue's labels:

- **`arness-feature-issue`** (GitHub) or **Story** (Jira) — invoke the `arn-code-architect` agent to assess feasibility, scope, and architectural impact.
- **`arness-bug-issue`** (GitHub) or **Bug** (Jira) — invoke the `arn-code-investigator` agent to do a quick diagnostic assessment (likely cause, affected components, reproduction steps if available).
- **`arness-backlog`** (GitHub) or **Task** (Jira) — choose the agent based on issue content:
  - If the content describes a feature or enhancement, invoke `arn-code-architect`.
  - If the content describes a defect or error, invoke `arn-code-investigator`.
  - If unclear, default to `arn-code-architect`.

The agent receives the issue title, body (or backlog entry content if coming from the local Feature Tracker path), and relevant codebase context. It provides a brief assessment covering:

- Is the issue valid and actionable?
- Estimated complexity (small / medium / large)
- Suggested approach
- Any immediate concerns or blockers

Present the assessment to the user alongside the issue details.

---

## Step 6: User Decision

After the user has reviewed the issue details and agent assessment, offer options using `AskUserQuestion`:

1. **Route to spec** — start the Arness pipeline for this issue:
   - `arness-feature-issue` / Story — suggest `/arn-code-feature-spec`
   - `arness-bug-issue` / Bug — suggest `/arn-code-bug-spec`
   - `arness-backlog` / Task — suggest based on the assessment (feature or bug spec)
   - Let the user override the suggestion if they prefer a different skill.

2. **Reject issue** — mark as rejected:

   ### If Issue tracker is github
   - Apply the `arness-rejected` label: `gh issue edit <number> --add-label arness-rejected`
   - Optionally add a comment explaining the reason: `gh issue comment <number> --body "<reason>"`
   - Ask if the user wants to close the issue.

   ### If Issue tracker is jira
   - Use the Atlassian MCP server to update the issue:
     - Add label: `arness-rejected`
     - Transition status to "Won't Do" or equivalent closed status (check available transitions via MCP)
     - Optionally add a comment with the rejection reason

3. **Defer** — leave the issue open for later:
   - Optionally change the priority label.

4. **Do nothing** — return to browsing or exit.

---

## Step 6.5: Spec Freshness Gate

**Skip this step entirely** unless BOTH of the following are true:

1. The user chose option 1 (**Route to spec**) in Step 6, AND
2. An existing artifact will be carried into the hand-off — specifically:
   - The local Feature Tracker path (Step 1b) located an existing `features/F-NNN-kebab-name.md`, OR
   - A sub-feature spec already exists at `<specs-dir>/FEATURE_F-NNN.M_<name>.md` (the case noted in Step 7 where `arn-code-feature-spec` will load and refine an existing spec rather than create a new one).

For brand-new issues with no prior feature file or spec, there is nothing to drift against — skip directly to Step 7.

When the gate applies, spawn the `arn-code-drift-detector` agent via the Task tool with the existing feature file (or sub-feature spec) as the input spec:

```
Verify whether the following feature file / spec still aligns with the current codebase.

**Spec file:** <features/F-NNN-kebab-name.md or <specs-dir>/FEATURE_F-NNN.M_<name>.md>
**Source root:** <repo root>

Return a structured drift report with severity classified as none, minor, moderate, or major.
```

Branch on the returned severity:

- **`none`** or **`minor`** — proceed silently to Step 7. If `minor`, attach the drift report alongside the issue context in the Step 7 hand-off so the spec skill can adapt while refining.
- **`moderate`** or **`major`** — display the full drift report, then ask the user how to proceed using `AskUserQuestion`:

  **The existing feature file / spec has drifted from the current codebase. How would you like to proceed?**
  1. **Refresh first** — route to the spec skill with instructions to update the feature file / spec against current reality before any planning.
  2. **Hand off with drift report** — proceed to Step 7 and forward the drift report alongside the issue context so the spec skill can account for it.
  3. **Cancel hand-off** — return to Step 6 (the user can pick a different action).

If the drift detector itself fails (e.g., spec/feature file unreadable, git unavailable), inform the user and ask whether to proceed without a drift check. Do not block on a tool failure.

---

## Step 7: Hand Off

If the user chose to route to a spec skill:

1. Pass the issue context as input to the target skill:
   - Issue title and body become the "feature idea" or "bug report" input.
   - Agent assessment provides initial analysis context.
   - Issue number (GitHub) or issue key (Jira) is included for traceability (the spec can reference it).
   - **If a drift report was produced in Step 6.5** (severity `minor`, or `moderate`/`major` with the user choosing "Hand off with drift report"): include the full drift report so the spec skill can refresh stale references before producing the refined spec.
   - **If coming from the local Feature Tracker path (Step 1b):** Also include:
     - The feature ID (F-NNN or F-NNN.M) for traceability across the pipeline (spec, plan, branch, ship)
     - The full content of the individual feature file (`features/F-NNN-kebab-name.md`): description, journey steps, UI behavior, components, acceptance criteria, technical notes, use case postconditions, use case business rules, visual target, showcase references, debate insights
     - Note: "The feature file carries all context needed for spec writing. Upstream greenfield artifacts do not need to be re-read."
     - **If handing off a sub-feature (F-NNN.M):** Include the sub-feature ID, the parent feature ID (F-NNN), the parent feature name, the parent issue reference, and the sub-feature's decomposition hint (journey segment, key components). If a sub-feature spec already exists, note: "A sub-feature spec already exists at `<specs-dir>/FEATURE_F-NNN.M_<name>.md`. `arn-code-feature-spec` should load and refine it rather than creating a new spec."

2. Inform the user: "Routing issue #<number> (or <ISSUE-KEY>) to `/arn-code-feature-spec` (or `/arn-code-bug-spec`). The issue content will be used as the starting point for the specification."

   If coming from the local Feature Tracker path: "Routing feature **F-NNN: [Name]** to `/arn-code-feature-spec`. The feature file includes inline journey steps, validated components, use case context, and UI behavior -- the spec conversation will start with full context."

---

## Error Handling

- **Issue tracker is `none`** — inform the user that issue management is not configured. Suggest running `/arn-planning` to get started.
- **GitHub not available** — inform the user and suggest running `/arn-planning` to get started.
- **Atlassian MCP server not available** — inform the user. Suggest running `/mcp` to check status or `/arn-planning` to reconfigure.
- **Jira project not found** — verify the Jira project key in `## Arness` config is correct. Suggest running `/arn-planning` to reconfigure.
- **No issues match filters** — suggest adjusting filters or creating a new issue via `/arn-code-create-issue`.
- **`gh` CLI not authenticated** — suggest running `gh auth login`.
- **Agent invocation fails** — skip the assessment, present issue details only, and let the user decide.
- **Issue already assigned** — warn the user and let them decide whether to proceed.
- **Label missing from repository (GitHub)** — create it on demand using `gh label create --force`. Reference `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-init/references/platform-labels.md` for the full label definitions (name, color, description).
- **Jira transition unavailable** — if the "Won't Do" transition is not available, add the `arness-rejected` label and comment only. Inform the user that the status could not be changed.
- **Feature backlog exists but has no Feature Tracker table** — fall back to the remote-only flow (Step 2). Inform: "Feature backlog found but no Feature Tracker table. Using remote issue browsing. Consider re-running `/arn-spark-feature-extract` to generate a Feature Tracker."
- **Feature Tracker parse error** — warn the user about the parse issue and fall back to the remote-only flow (Step 2).
- **All features are blocked** — inform: "All pending features have unmet dependencies. The following features are in-progress: [list]. Complete those first, then re-run `/arn-code-pick-issue`. Or type 'remote' to browse all remote issues."
- **No pending features in Feature Tracker** — inform: "All features in the Feature Tracker are done or in-progress. No pending features to pick. Type 'remote' to browse all remote issues, or run `/arn-spark-feature-extract` to add more features."
- **Feature Tracker write fails** — warn the user but do not block the flow. The feature can still be routed to spec.
- **All sub-features of a parent are blocked** — inform: "All sub-features of F-NNN are blocked by incomplete dependencies. Check sub-feature dependencies."
- **Decomposed feature selected directly** — if user selects a row with status `decomposed`, inform: "F-NNN has been decomposed into sub-features. Pick a sub-feature (F-NNN.1, F-NNN.2, ...) instead." Re-present the list.
