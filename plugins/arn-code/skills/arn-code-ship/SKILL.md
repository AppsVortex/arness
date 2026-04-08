---
name: arn-code-ship
description: >-
  This skill should be used when the user says "ship it", "arness code ship",
  "create PR", "open pull request", "push and PR", "commit and push",
  "wrap up", "ship the feature", "ship the fix", "ready to ship",
  "push changes", "finalize", "finish up", or wants
  to commit, push, and optionally open a pull request. Guides through branching,
  staging, committing with meaningful messages, pushing, and PR creation.
  Works standalone or as the final Arness pipeline step. Do NOT use this for
  reviewing PRs — use /arn-code-review-pr for that.
version: 1.2.0
---

# Arness Ship

Guides through branching, staging, committing, pushing, and optionally opening a pull request. Works standalone or as the final step in the Arness pipeline.

Pipeline position:
```
arn-code-review-implementation -> arn-code-document-project -> **arn-code-ship**
```

This skill handles the entire shipping workflow: verifying git state, ensuring the user is on the right branch, staging changes safely, generating meaningful commit messages, pushing, and creating a pull request via the GitHub CLI or Bitbucket CLI.

## Workflow

### Step 1: Check Git State

Check `## Arness` config in CLAUDE.md for `Git: yes`. If not present, run runtime check: `git rev-parse --is-inside-work-tree`.

If Git is not available, inform the user: "This project is not a git repository. `/arn-code-ship` requires Git." and exit.

Read the **Platform** field from `## Arness` config in CLAUDE.md (values: `github`, `bitbucket`, or `none`). Store this value for use in Step 5. If the `Platform` field is not present, fall back to legacy detection: check for `GitHub: yes` and treat as `github`; otherwise treat as `none`.

Gather current state:
- Current branch: `git branch --show-current`
- Uncommitted changes: `git status --short` (never use `-uall`)
- Commits ahead of main: `git log main..HEAD --oneline` (skip if on main)
- Remote tracking: `git rev-parse --abbrev-ref @{upstream}` (may fail if no upstream)

If no uncommitted changes AND no commits ahead of remote, inform the user: "Nothing to ship — working tree is clean and up to date with remote." and exit.

---

### Step 2: Branch Decision

**If on main/master:**
- Warn the user: "You're on the main branch. It's recommended to create a feature branch before shipping."
- Offer to create a new branch:
  - If Arness context is available (current spec or plan), suggest a name derived from it (e.g., `feat/websocket-support`, `fix/checkout-500-error`)
  - Otherwise ask the user for a branch name
  - Create with `git checkout -b <branch-name>`
- Let the user continue on main if they prefer

**If on a feature branch:**
- Confirm: "You're on branch `<branch-name>`. Proceeding."

---

### Step 3: Stage and Commit

1. Show current changes: run `git status --short` and `git diff --stat`
2. Check for sensitive files in the diff — warn if any match common patterns:
   - `.env`, `.env.*`
   - Files containing `credential`, `secret`, `token`, `password`, `key` in their name
   - `id_rsa`, `*.pem`, `*.key`
3. Offer staging options via `AskUserQuestion`:
   - **Stage all changes** — `git add -A`
   - **Choose files to stage** — show the list, let user select
   - **Already staged** — user has manually staged files, proceed with what's staged
4. Scan for CHANGE_RECORD.json:
   - Read `## Arness` config from CLAUDE.md to get the plans directory
   - Scan for `CHANGE_RECORD.json` in plans subdirectories: `SWIFT_*/CHANGE_RECORD.json`, `STANDARD_*/CHANGE_RECORD.json`, `CATCHUP_*/CHANGE_RECORD.json`, and `*/CHANGE_RECORD.json`
   - If multiple found, use the most recently modified file
   - If found, read the `ceremonyTier` field to determine the tier tag
5. Generate a commit message:
   - Detect the project's commit convention from `git log --oneline -10` and follow it. Default to imperative mood (e.g., "Add feature X", not "Added feature X").
   - If a CHANGE_RECORD.json was found, prepend the tier tag to the commit message: `[swift]`, `[standard]`, `[thorough]`, or `[catchup]` (e.g., `[swift] Add rate limiting to /api/users`)
   - If Arness context is available (project name, spec, plan), use it to generate a meaningful commit message summarizing the changes
   - Otherwise, generate from `git diff --staged --stat` and file content
   - Present the generated message to the user
   - Let the user customize or approve
6. Commit using the approved message

---

### Step 4: Push

1. Check if the branch has a remote tracking branch: `git rev-parse --abbrev-ref @{upstream}`
2. If tracking branch exists: `git push`
3. If no tracking branch: `git push -u origin <branch-name>`
4. Handle push rejection:
   - If push is rejected (remote has new commits), suggest `git pull --rebase` first
   - Never force-push without explicit user approval

---

### Step 5: Create Pull Request (optional)

Use the **Platform** value read in Step 1 to determine the PR creation path.

**Deferred Label Check:**

If Platform is `github`: check if Arness labels exist by running `gh label list --search "arness-"`. If fewer than 7 Arness labels are found, create the missing ones using `gh label create --force` for each label per `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-init/references/platform-labels.md`. This is idempotent and safe to run on every invocation.

If Platform is `bitbucket` or Issue tracker is `jira`: no label creation needed (Jira labels are implicit, Bitbucket uses different mechanisms).

Ask: "Would you like to create a pull request?"

If no: confirm the push was successful and exit.

If yes, branch based on Platform:

#### If Platform is github

Run runtime check if needed: `gh auth status`. If GitHub CLI is not available or not authenticated, inform the user and skip this step.

1. Generate PR title — short, under 70 characters, from spec/plan or commit message
2. Generate PR body using Arness context if available:
   - Summary bullets from plan/spec
   - Key changes from git diff
   - Test plan from phase plans or testing reports
   - **CHANGE_RECORD enrichment:** If a CHANGE_RECORD.json was found in Step 3, enrich the PR body with:
     - `Ceremony: [tier]` line (e.g., "Ceremony: swift")
     - Spec link from `specRef` (if non-empty): `Spec: [specRef]`
     - Review verdict from `review.verdict` (if present): `Review: [verdict]`
     - Structured change summary from `filesModified` and `filesCreated` arrays
3. Let the user review and customize title and body
4. Offer the option to create as a draft PR (`gh pr create --draft`) if the user wants feedback before marking it ready for review
5. Create the PR: `gh pr create --title "..." --body "..."` (add `--draft` if chosen)
6. Report the PR URL
7. Suggest next step: "Run `/arn-code-review-pr` after receiving feedback on the pull request."

#### If Platform is bitbucket

Run runtime check: `bkt auth status`. If `bkt` is not available or not authenticated, inform the user and skip this step.

1. Generate PR title — short, under 70 characters, from spec/plan or commit message
2. Generate PR body using Arness context if available (same generation logic as GitHub path):
   - Summary bullets from plan/spec
   - Key changes from git diff
   - Test plan from phase plans or testing reports
   - **CHANGE_RECORD enrichment:** Same as GitHub path -- if a CHANGE_RECORD.json was found, include Ceremony tier, spec link, review verdict, and structured change summary
3. Let the user review and customize title and body
4. Detect the default branch: `git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'`
5. Create the PR: `bkt pr create --title "..." --description "..." --source <branch> --destination <default-branch>`
6. **Note:** Bitbucket Cloud does not support draft PRs. If the user requested a draft, inform them: "Bitbucket does not support draft PRs. Creating a regular PR. Consider prefixing the title with WIP: to signal work-in-progress."
7. Parse PR URL from `bkt` output
8. Report the PR URL
9. Suggest next step: "Run `/arn-code-review-pr` after receiving feedback on the pull request."

#### If Platform is none

Skip PR creation. Inform user: "No platform configured for PR creation. Run `/arn-shipping` to get started."

#### After PR creation: Update CHANGE_RECORD.json

If a CHANGE_RECORD.json was found in Step 3, update it after the commit and push (regardless of whether a PR was created):

1. Set `commitHash` from `git rev-parse HEAD`
2. Set `commitMessage` from the commit message used
3. If a PR was created, add the PR URL to the `nextSteps` array (e.g., "PR: [url]")
4. Write the updated CHANGE_RECORD.json back to disk

If no CHANGE_RECORD.json was found, skip this step silently.

---

### Step 5b: Sketch Cleanup (Conditional)

After pushing (and optionally creating a PR), check for sketch directories in these locations:
- `arness-sketches/` at the project root (all paradigms)
- Legacy web locations for backward compatibility: `app/arness-sketches/`, `pages/arness-sketches/`, `src/routes/arness-sketches/`

Scan for subdirectories whose names match the shipped feature (by branch name, spec name, or feature ID).

If matching sketch directories are found, read each sketch's `sketch-manifest.json` to determine the `paradigm`, `previewCommand`, and `status` fields. Include `previewCommand` in the user-facing message when presenting options: "Preview was available via: `[previewCommand]`".

Present options based on the manifest `status`:

**If status is `"promoted"`:**

"Found sketch directory `arness-sketches/<name>/` for this feature. This sketch was already promoted into your codebase."

1. **Delete** -- remove the sketch directory (components already in codebase)
2. **Keep** -- preserve the sketches for reference

**If status is `"kept"`:**

"Found sketch directory `arness-sketches/<name>/` for this feature. What would you like to do?"

1. **Delete** -- remove the sketch directory (feature is now implemented)
2. **Keep** -- preserve the sketches for reference
3. **Promote** -- copy the sketch output into the main project structure as a starting point (advanced -- manual review required)

**If status is `"draft"`:**

"Found sketch directory `arness-sketches/<name>/` for this feature. This sketch was never finalized (draft status)."

1. **Delete** -- remove the sketch directory
2. **Keep** -- preserve the sketches for reference

**If status is `"consumed"`:**

"Found sketch directory `arness-sketches/<name>/` for this feature. This sketch was fully consumed during implementation -- all components were promoted."

Suggest **Delete** as the default action. Also offer **Keep** if the user wants to preserve for reference.

**Action handling:**

If **Delete**:
- Remove the sketch directory
- **Paradigm-conditional cleanup:** If the manifest `paradigm` is `web`, check the project's framework (from `architecture.md` or the manifest's `framework` field) to determine if router cleanup is needed. File-system-routed frameworks (Next.js, SvelteKit, Nuxt) need route entry removal. Config-routed frameworks (React Router, Vue Router) need router config cleanup. Other web frameworks may only need directory deletion. For CLI, TUI, desktop, and mobile paradigms, simple directory deletion is sufficient -- no router cleanup is needed.
- Inform: "Sketch directory removed."

If **Keep**: skip silently.
If **Promote** (only available for `"kept"` status): inform: "Sketch promotion copies the output files to your project. Review and integrate manually after this step."

If no matching sketch directories are found, skip this step silently.

---

### Step 6: Update Feature Tracker (Greenfield Integration)

This step is entirely optional — it activates only when a greenfield feature backlog exists. Projects without greenfield skip this step silently and proceed to the completion summary. It identifies the shipped feature (by branch name, spec, or commits), marks it as done, handles sub-feature parent rollup, and reports newly unblocked features.

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-ship/references/feature-tracker-update.md` for the full detection chain, update workflow, and sub-feature parent rollup logic.

---

## Error Handling

- **Git not available** — inform user, exit.
- **No changes to ship** — inform user, exit.
- **On main branch** — warn, offer branch creation.
- **Sensitive files detected** — warn prominently, let user decide.
- **Push rejected** — suggest `git pull --rebase`, never force-push automatically.
- **`gh` CLI not authenticated** — inform user, skip PR creation, suggest `gh auth login`.
- **`bkt` CLI not authenticated** — inform user, skip PR creation, suggest `bkt auth login`.
- **Bitbucket PR creation fails** — show the error from `bkt`, offer to retry.
- **No Bitbucket remote detected** — warn and skip PR creation.
- **PR already exists for this branch** — show existing PR URL, offer to update.
- **Platform field missing** — fall back to legacy `GitHub: yes` detection. If neither found, treat as `none`.
- **Feature Tracker write fails** — print the updated Feature Tracker table in the conversation so the user can manually update. Do not fail the ship flow — the PR was already created.
- **Multiple feature IDs in branch/commits** — present all matches, ask the user to pick the correct one.
- **Feature backlog exists but no Feature Tracker table** — skip Step 6 silently.
- **Feature Tracker parse error** — warn the user about the parse issue, skip Step 6. Suggest running `/arn-spark-feature-extract` to regenerate.
- **Sub-feature ID detected but parent not found in tracker** — warn: "Sub-feature F-NNN.M detected but parent F-NNN not found in Feature Tracker. Updating sub-feature status only."
- **Parent rollup ambiguity** — if some sub-feature rows cannot be parsed, warn and skip the rollup. Mark the individual sub-feature as done.
- **Multiple sub-feature IDs in branch/commits** — present all matches, ask the user to pick the correct one (same as existing multiple feature ID handling).
