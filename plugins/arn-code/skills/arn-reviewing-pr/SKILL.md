---
name: arn-reviewing-pr
description: >-
  This skill should be used when the user says "reviewing pr", "arness reviewing pr",
  "review PR", "review pull request", "check PR comments", "PR feedback",
  "address PR feedback", "fix PR issues", "what did the reviewer say",
  "handle review comments", "review PR 123", "arn-reviewing-pr",
  "PR review", "check review", or wants to validate PR review comments,
  categorize findings, and fix or defer issues. Chains back to
  arn-implementing if substantial fixes are needed.
version: 1.0.0
---

# Arness Reviewing PR

Validate PR review comments, categorize findings, and fix or defer issues. This is a first-citizen entry point that wraps `arn-code-review-pr` and provides chaining context back to `arn-implementing` if fixes are needed.

This skill is a **thin orchestration wrapper**. It MUST NOT duplicate `arn-code-review-pr` logic. All review work is done by the invoked skill. Arness-reviewing-pr handles: prerequisite checks, input routing, invoking the review skill, and offering the chain exit.

## Step 0: Ensure Configuration

Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-ensure-config/references/ensure-config.md` and follow its instructions. This guarantees a user profile exists and `## Arness` is configured with Arness Code fields before proceeding.

After Step 0 completes, extract the following from `## Arness`:
- **Platform** — determines if PR operations are available (`github`, `bitbucket`, or `none`)

If Platform is `none`: inform the user that no platform is configured and suggest running `/arn-reviewing-pr` again after configuring a platform. Do not proceed.

## Workflow

### Step 1: Input Handling

- **PR number provided** (e.g., "reviewing pr 42", "arness reviewing pr #123"): Extract the PR number and pass it to the review skill.
- **No args**: Auto-detect PR for current branch (the review skill handles this internally).
- **No PR found**: The review skill will detect this and inform the user. Suggest running `/arn-shipping` to create a PR first.

---

### Step 2: Invoke Review PR

Show progress:
```
Reviewing PR: REVIEW-PR -> [fix / defer / plan]
              ^^^^^^^^^
```

Invoke the review skill:

> `Skill: arn-code:arn-code-review-pr` [optional PR number]

The review skill handles all internal decisions: fetching comments, validating findings, categorizing, and optionally fixing. It has its own user interactions. Wait for it to complete.

---

### Step 3: Completion Handoff

After `arn-code-review-pr` completes, assess what happened and offer the appropriate chain exit.

**If fixes were applied:**

Ask (using `AskUserQuestion`):

**"Review complete. What next?"**

Options:
1. **Push updates** — Push the fixes to the PR
2. **More substantial fixes needed** — Start implementing for more complex changes
3. **Done** — Exit

If **Push updates**: Run `git push` to update the PR.
If **More substantial fixes needed**: `Skill: arn-code:arn-implementing`
If **Done**: Exit.

**If no fixes were needed (all deferred or no actionable findings):**

Exit with: "Review complete. No fixes needed."

---

## Error Handling

- **`## Arness` config missing:** Handled by Step 0 (ensure-config) — this should not occur if Step 0 completed successfully.
- **Platform not configured:** Inform the user. Suggest running `/arn-reviewing-pr` again after platform configuration.
- **No PR for current branch:** Suggest running `/arn-shipping` to create one.
- **`arn-code-review-pr` fails:** Present the error. Ask: retry or abort.
- **Auth failure (GitHub/Bitbucket):** The review skill handles auth errors internally. No action needed at this level.
