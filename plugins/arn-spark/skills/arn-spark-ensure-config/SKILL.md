---
name: arn-spark-ensure-config
description: >-
  This skill should be used when the user says "ensure config", "check arn spark config",
  "arn-spark-ensure-config", "verify arn spark setup", "configure spark", "setup arness spark",
  "spark config", or wants to verify that Arness Spark
  configuration is present for the current project. This skill is primarily consumed
  as a reference by entry-point skills (arn-brainstorming, arn-spark-discover,
  arn-spark-arch-vision) which read the ensure-config reference as Step 0 before
  proceeding with their workflow.
version: 1.0.0
---

# Arness Spark Ensure Config

Verify and establish Arness Spark configuration for the current project. This skill guarantees that a valid user profile and `## Arness` section exist before any Arness Spark workflow proceeds. It runs automatically as Step 0 of all entry-point skills.

When invoked directly, it performs the same checks and setup as when called by an entry-point skill.

## Workflow

Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-ensure-config/references/ensure-config.md` and follow its instructions.
