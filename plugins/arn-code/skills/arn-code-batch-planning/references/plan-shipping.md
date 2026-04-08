# Plan Shipping

Reference procedure for committing and PRing all planning artifacts to main before launching batch-implement. This ensures workers (which branch from origin/HEAD) can find all specs, plans, and sketches.

## Prerequisites

Read the `Platform` and `Git` fields from `## Arness` config.

## Procedure

### If Git is `no`

Skip shipping entirely. Inform the user:

"No version control configured. Plans are saved locally only. Batch-implement requires git for worktree-based parallel execution. You can still implement features one at a time with `/arn-implementing`."

STOP — do not proceed to batch-implement handoff.

### If Git is `yes`

#### 1. Create a Plans Branch

Check current branch: `git branch --show-current`

If on main/master:
- Create branch: `git checkout -b plans/<date>-batch` (e.g., `plans/2026-04-05-batch`)

If already on a non-main branch:
- Use the current branch (no need to create a new one)

#### 2. Stage Planning Artifacts

Stage all files in the Arness working directories that were created or modified during batch-planning:

```bash
git add .arness/specs/ .arness/plans/ arness-sketches/ 2>/dev/null
git add .arness/code-patterns.md .arness/testing-patterns.md .arness/architecture.md 2>/dev/null
```

Only stage files that exist — the `2>/dev/null` suppresses errors for missing paths (e.g., no sketches).

Do NOT stage `.arness/*.local.yaml` or `.claude/*.local.md` (these are gitignored).

#### 3. Commit

```
[batch-planning] Specs and plans for N features

Features:
- F-001: [Name] (tier: thorough)
- F-003: [Name] (tier: standard)
- F-005: [Name] (tier: swift)
```

#### 4. Push

```bash
git push -u origin $(git branch --show-current)
```

If push fails: report the error. Offer to retry or let the user handle it.

#### 5. Create PR (Platform-Dependent)

**If Platform is `github`:**

```bash
gh pr create --title "[batch-planning] N feature specs and plans" --body "$(cat <<'EOF'
## Batch Planning Artifacts

Plans and specifications for N features, ready for batch implementation.

### Features
- F-001: [Name] (tier: thorough, plan: .arness/plans/[path])
- F-003: [Name] (tier: standard, plan: .arness/plans/STANDARD_[name]/)
- F-005: [Name] (tier: swift, plan: .arness/plans/SWIFT_[name]/)

### Next Steps
Merge this PR, then run `/arn-code-batch-implement` to launch parallel implementation.
EOF
)"
```

**If Platform is `bitbucket`:**

```bash
bkt pr create \
  --title "[batch-planning] N feature specs and plans" \
  --description "<same body as above>" \
  --source $(git branch --show-current) \
  --destination main
```

**If Platform is `none`:**

Skip PR creation. Inform: "No platform configured — plans are pushed to branch `plans/<date>-batch`. Merge this branch into main manually before running batch-implement."

#### 6. Wait for Merge

Inform the user:

"Plans PR created: [PR URL]. Merge it before launching batch-implement — workers need plans on main."

Ask (using `AskUserQuestion`):

**"Has the plans PR been merged?"**

Options:
1. **Yes, it's merged** — proceed to batch-implement handoff
2. **Not yet** — exit (run `/arn-code-batch-implement` later)

If **Yes**: checkout main and pull:
```bash
git checkout main && git pull
```
Verify plans exist on disk after pull. Proceed to handoff.

If **Not yet**: exit with "Merge the plans PR, then run `/arn-code-batch-implement` when ready."

## Error Handling

- Push fails: report error, offer retry
- PR creation fails (gh/bkt not authenticated): report error, suggest manual PR creation
- Plans PR merge check: the AskUserQuestion is trust-based (we trust the user). If they say merged but it isn't, batch-implement's pre-flight will catch it (plans won't be on main).
