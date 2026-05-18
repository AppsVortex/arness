---
name: arn-code-ensure-config
description: >-
  This skill should be used when the user says "ensure config", "check arness config",
  "arn-code-ensure-config", "verify arness setup", or wants to verify that Arness Code
  configuration is present for the current project. This skill is primarily consumed
  as a reference by entry-point skills (arn-planning, arn-implementing, arn-shipping,
  arn-reviewing-pr, arn-assessing, arn-code-feature-spec, arn-code-bug-spec,
  arn-code-swift, arn-code-standard) which read the `references/step-0-fast-path.md`
  reference as Step 0 before proceeding with their workflow.
version: 1.3.0
---

# Arness Code Ensure Config

Verify and establish Arness Code configuration for the current project. This skill guarantees that a valid user profile and `## Arness` section exist before any Arness Code workflow proceeds. It runs automatically as Step 0 of all entry-point skills via a hash-based fast-path cache.

**Entry points should NOT read this SKILL.md directly.** They should read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-ensure-config/references/step-0-fast-path.md`, which runs the cache-check shell script and only falls through to the full validation when needed. This indirection is what saves ~95% of ensure-config token cost.

When invoked DIRECTLY (rare — typically via `/arn-code-ensure-config`), this skill bypasses the cache and runs the full validation flow.

## Workflow

Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-ensure-config/references/ensure-config.md` and follow its instructions (Layers 1–3, then Layer 4 cache write).
