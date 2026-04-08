---
name: arn-infra-ensure-config
description: >-
  This skill should be used when the user says "ensure config", "check arn infra config",
  "arn-infra-ensure-config", "verify arn infra setup", or wants to verify that Arness Infra
  configuration is present for the current project. This skill is primarily consumed
  as a reference by entry-point skills (arn-infra-wizard, arn-infra-assess) which
  read the ensure-config reference as Step 0 before proceeding with their workflow.
version: 1.0.0
---

# Arness Infra Ensure Config

Verify and establish Arness Infra configuration for the current project. This skill guarantees that a valid user profile and `## Arness` section exist before any Arness Infra workflow proceeds. It runs automatically as Step 0 of all entry-point skills.

When invoked directly, it performs the same checks and setup as when called by an entry-point skill.

## Workflow

Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-ensure-config/references/ensure-config.md` and follow its instructions.
