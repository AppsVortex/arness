---
name: arn-code-review-pr
description: >-
  This skill should be used when the user says "review PR", "review pull
  request", "check PR comments", "review PR feedback", "review PR 123",
  "analyze PR comments", "validate PR review", "address PR feedback",
  "fix PR issues", "what did the reviewer say", "review Bitbucket PR",
  or wants to validate GitHub or Bitbucket
  PR review comments, categorize findings, and optionally connect back into
  the Arness pipeline for fixes. Do NOT use this for creating PRs (use
  arn-code-ship) or reviewing implementation quality (use arn-code-review-implementation).
version: 1.1.0
---

# Arness Review PR

Reviews PR comments from GitHub or Bitbucket, validates each finding against the actual code, categorizes them by severity, and optionally connects back into the Arness pipeline for fixes or creates tracking issues.

---

## Step 1: Find the PR

Read the **Platform** field from `## Arness` config in CLAUDE.md (values: `github`, `bitbucket`, or `none`). If the `Platform` field is not present, fall back to legacy detection: check for `GitHub: yes` and treat as `github`; otherwise treat as `none`.

If Platform is `none`, inform the user: "No platform configured for PR review. Run `/arn-reviewing-pr` to get started." and exit.

### If Platform is github

Run a runtime check if needed:

```bash
git rev-parse --is-inside-work-tree
# Check for a GitHub remote
git remote -v | grep github.com
# Verify gh CLI is authenticated
gh auth status
```

If GitHub is not available, inform the user and exit. Suggest configuring via `/arn-reviewing-pr`.

Try to detect the PR automatically:

1. If the user provided a PR number (e.g., "review PR 42"), use that directly.
2. Otherwise, run `gh pr view --json number,title,url,state,headRefName` for the current branch.
3. If no PR is found, ask the user for a PR number or URL.

Display the PR title, number, and URL for confirmation.

Warn if the PR is **MERGED** or **CLOSED** — comments may be stale. Ask the user whether to proceed.

### If Platform is bitbucket

Run a runtime check: `bkt auth status`. If `bkt` is not available or not authenticated, inform the user and exit. Suggest checking `bkt auth status`.

Try to detect the PR automatically:

1. If the user provided a PR number or URL, use that directly: `bkt pr view <id> --json`
2. Otherwise, list open PRs: `bkt pr list --state OPEN --limit 5 --json`
   - Match the current branch name to find the PR for this branch.
3. If no PR is found, ask the user for a PR number or URL. Suggest creating one via `/arn-code-ship`.

Display the PR title, number, and URL for confirmation.

Warn if the PR is **MERGED** or **DECLINED** — comments may be stale. Ask the user whether to proceed.

---

## Step 2: Fetch Comments

### If Platform is github

Collect all feedback using the `gh` CLI:

Resolve `{owner}/{repo}` from the current repository: `gh repo view --json nameWithOwner -q .nameWithOwner`.

```bash
# Inline code review comments
gh api repos/{owner}/{repo}/pulls/{number}/comments --paginate

# Top-level reviews (approve/request-changes/comment with body)
gh api repos/{owner}/{repo}/pulls/{number}/reviews --paginate

# General conversation comments
gh pr view {number} --comments --json comments
```

Parse and organize by type:

- **Review comments** — inline, attached to a specific file and line
- **Review verdicts** — approve, request changes, or comment (with body text)
- **General comments** — conversation thread

Filter out bot comments and CI status messages. If no substantive comments remain, inform the user and exit.

### If Platform is bitbucket

Collect all feedback using the `bkt` CLI:

```bash
# Fetch all PR comments (inline and general)
bkt pr comments <id> --json

# Fetch PR activity (approvals, changes-requested, etc.)
bkt pr activity <id> --json
```

Parse and organize by type:

- **Review comments** — inline comments that have file path and line number context
- **General comments** — comments without inline context (top-level conversation)
- **Review verdicts** — approval or changes-requested activity entries

Filter out bot and CI messages. If no substantive comments remain, inform the user and exit.

**Note:** Bitbucket inline comments may have less context than GitHub (e.g., no multi-line range, different diff hunk format). When validating comments in Step 3, use the file path and line number to locate the code, but be aware that the surrounding context may be more limited.

---

## Step 3: Validate Each Comment

For each substantive review comment:

1. **Read the referenced file and line** — understand the actual code in its current state.
2. **Understand the reviewer's concern** — what issue are they raising?
3. **Check for subsequent fixes** — was this already addressed in a later commit?
4. **For architectural concerns**, invoke the `arn-code-architect` agent for assessment.
5. **Categorize the comment**:

| Category | Meaning | Severity |
|----------|---------|----------|
| **VALID** | Reviewer is correct — real issue that should be fixed | Critical or Moderate |
| **VALID (MINOR)** | Correct but low impact — style, naming, or preference | Low |
| **FALSE POSITIVE** | Concern doesn't apply — explain why | None |
| **ALREADY FIXED** | Issue addressed in a subsequent commit | None |
| **DISCUSSION** | Not an issue — question or design discussion point | None |

---

## Step 4: Report

Present findings using the format from `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-review-pr/references/pr-report-format.md`.

Summary counts plus per-comment details with category, severity, assessment, and suggested fix (for VALID items).

---

## Step 4.5: Local Testing Offer (Optional)

If Platform is `none`, skip this step entirely (no remote PR to checkout).

After the report is presented, before offering actions:

Ask (using `AskUserQuestion`):

**"Would you like to test this PR locally before deciding on actions?"**

1. **Yes, checkout and test** — Checkout the PR branch and run tests
2. **No, proceed to actions** — Skip local testing

If **No, proceed to actions**: skip to Step 5.

If **Yes, checkout and test**:

1. **Checkout the PR locally:**
   - If Platform is `github`: `gh pr checkout <number>`
   - If Platform is `bitbucket`: `git fetch origin <branch> && git checkout <branch>` (use the branch name from the PR metadata fetched in Step 1)

2. **Run the project's test command:**
   - Read `testing-patterns.md` from the code patterns directory (the **Code patterns** path in `## Arness` config) for the test command.
   - If a test command is found: run it via Bash.
   - If no test command is found: inform the user and suggest they run tests manually.

3. **Present results:**
   - If all tests pass: "All tests pass locally."
   - If tests fail: show the failures, offer to investigate.

4. **Open-ended exploration:** "Take your time testing locally. Say 'done testing' when ready to continue."
   - This is plain text (not AskUserQuestion — it is conversational).
   - The user can ask questions, run commands, and explore the code.
   - When they say "done testing" or similar, proceed to Step 5.

5. **Cleanup after all actions are complete:** At the very end of the skill (after Step 6 finishes), return to the original branch:
   ```bash
   git checkout main 2>/dev/null || git checkout master 2>/dev/null || git checkout -
   ```

---

## Step 5: Offer Actions

Use `AskUserQuestion` with `multiSelect: true` so the user can combine actions. If no options are selected, treat as "do nothing" (take the report as information only).

1. **Fix valid issues now** — apply suggested fixes for VALID issues directly in the code.
2. **Create tracking issues for deferred items** — for items that don't need to be fixed in this PR but should be tracked. Tag with `arness-backlog` label. Ask for priority level (`arness-priority-high`, `arness-priority-medium`, `arness-priority-low` — default low). Use the deferred issue template from `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-review-pr/references/deferred-issue-template.md`.
3. **Plan and fix via Arness pipeline** — for Critical/Moderate VALID items, route through the Arness pipeline (run `/arn-code-plan` to generate an implementation plan). Only available if `## Arness` config exists in CLAUDE.md.

---

## Step 6: Execute Chosen Actions

### Fix Inline

For each VALID finding the user approved for fixing:

1. **Explain the fix before applying:** Present what will be changed:
   ```
   Fixing SIM-001 [Critical] in src/auth/login.ts:42
   Current: [brief description of current code]
   Change: [brief description of what will be changed and why]
   ```

2. **Apply the fix:** Make the code change.

3. **Verify:** Run targeted tests relevant to the changed file to confirm the fix doesn't break anything. If tests fail, attempt to fix (up to 3 attempts). If still failing, revert and inform the user.

4. **After all fixes are applied**, show a summary of all changes:
   ```
   Fixes applied: [N]
   Files modified: [list]
   Tests run: [pass/fail status]
   ```

5. **Ask before committing and pushing:**

   Ask (using `AskUserQuestion`):

   **"Fixes applied and tested. Commit and push these changes?"**

   Options:
   1. **Yes, commit and push** — commit all fixes with a descriptive message and push to the PR branch
   2. **Yes, and don't ask again this session** — commit, push, and auto-commit for remaining PRs in this session
   3. **No, I'll handle it** — leave changes uncommitted for the user to review manually

   If **Yes, commit and push** or **Yes, don't ask again:**
   - Stage the fixed files: `git add <files>`
   - Commit: `git commit -m "Address PR review: [N] fixes applied"`
   - Push: `git push`
   - If "don't ask again": set a session flag so subsequent fix rounds skip this confirmation

   If **No**: inform the user that changes are applied locally but not committed. They can review with `git diff` and commit manually.

### Create Issues

For each deferred item, create a tracking issue. On GitHub, use `gh issue create` with the deferred issue template. On Bitbucket with Jira, use the Atlassian MCP server. See `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-review-pr/references/deferred-issue-template.md` for platform-specific commands and templates. Ensure labels exist (create if missing). Report created issue numbers and URLs.

### Pipeline Route

Run `/arn-code-plan` with the VALID findings as context for the plan.

---

## Error Handling

- **GitHub not available** — inform user, suggest configuring via `/arn-reviewing-pr`.
- **Bitbucket `bkt` CLI not available or not authenticated** — inform user, suggest checking `bkt auth status` and `bkt auth login`.
- **No PR found for current branch (GitHub)** — ask user for a PR number.
- **No PR found for current branch (Bitbucket)** — ask user for a PR number or URL. Suggest creating one via `/arn-code-ship`.
- **PR is MERGED/CLOSED (GitHub)** — warn that comments may be stale, proceed if user confirms.
- **PR is MERGED/DECLINED (Bitbucket)** — warn that comments may be stale, proceed if user confirms.
- **No substantive comments** — inform user and exit.
- **`gh api` rate limited** — inform user, suggest trying again later.
- **`bkt` command fails** — show the error, suggest checking `bkt auth status`.
- **`arn-code-architect` agent fails** — skip architectural assessment, note in report.
- **Platform field missing** — fall back to legacy `GitHub: yes` detection. If neither found, treat as `none`.
