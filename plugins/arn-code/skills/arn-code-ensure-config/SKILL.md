---
name: arn-code-ensure-config
description: >-
  This skill should be used when the user says "ensure config", "check arness config",
  "arn-code-ensure-config", "verify arness setup", or wants to verify that Arness Code
  configuration is present for the current project. This skill is primarily consumed
  as a reference by entry-point skills (arn-planning, arn-implementing, arn-shipping,
  arn-reviewing-pr, arn-assessing, arn-code-feature-spec, arn-code-bug-spec,
  arn-code-swift, arn-code-standard) which read the ensure-config reference as
  Step 0 before proceeding with their workflow.
version: 1.0.0
---

# Arness Code Ensure Config

Verify and establish Arness Code configuration for the current project. This skill guarantees that a valid user profile and `## Arness` section exist before any Arness Code workflow proceeds. It runs automatically as Step 0 of all entry-point skills.

When invoked directly, it performs the same checks and setup as when called by an entry-point skill.

## Workflow

Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-ensure-config/references/ensure-config.md` and follow its instructions.
