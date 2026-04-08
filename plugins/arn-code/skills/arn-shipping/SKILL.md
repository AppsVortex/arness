---
name: arn-shipping
description: >-
  This skill should be used when the user says "shipping", "arness shipping",
  "ship it", "ship", "create PR", "open pull request", "push and PR",
  "commit and push", "wrap up", "ship the feature", "ship the fix",
  "ready to ship", "push changes", "finalize", "finish up", "done",
  "arn-shipping", or wants to commit, push, and optionally create a
  pull request. Handles branching, staging, committing, pushing, and
  PR creation as a single guided flow. Chains from arn-implementing
  at completion.
version: 1.0.0
---

# Arness Shipping

Commit, push, and optionally create a pull request. This is a first-citizen entry point that wraps `arn-code-ship` and provides chaining context to the next stage (`arn-reviewing-pr`).

This skill is a **thin orchestration wrapper**. It MUST NOT duplicate `arn-code-ship` logic. All shipping work is done by the invoked skill. Arness-shipping handles: prerequisite checks, invoking the ship skill, and informing the user about the next stage.

## Step 0: Ensure Configuration

Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-ensure-config/references/ensure-config.md` and follow its instructions. This guarantees a user profile exists and `## Arness` is configured with Arness Code fields before proceeding.

## Workflow

### Step 1: Invoke Ship

Show progress:
```
Shipping: SHIP (branch -> stage -> commit -> push -> PR)
          ^^^^
```

Invoke the ship skill:

> `Skill: arn-code:arn-code-ship`

The ship skill handles all internal decisions: branching, staging, commit message generation, pushing, and PR creation. It has its own user interactions. Wait for it to complete.

---

### Step 2: Completion Handoff

After `arn-code-ship` completes, present the chain exit:

"When your PR gets review feedback, run `/arn-reviewing-pr` to validate and address comments."

---

## Error Handling

- **`## Arness` config missing:** Handled by Step 0 (ensure-config) — this should not occur if Step 0 completed successfully.
- **`arn-code-ship` fails:** Present the error. Ask: retry or abort.
- **Nothing to ship (clean tree, no commits ahead):** `arn-code-ship` handles this internally — it will inform the user. No action needed at this level.
