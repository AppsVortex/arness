---
name: arn-spark-ensure-config
description: >-
  This skill should be used when the user says "ensure config", "check arn spark config",
  "arn-spark-ensure-config", "verify arn spark setup", "configure spark", "setup arness spark",
  "spark config", or wants to verify that Arness Spark configuration is present for the
  current project. This skill is primarily consumed as a reference by entry-point skills
  (arn-brainstorming, arn-spark-discover, arn-spark-arch-vision) which read the
  `references/step-0-fast-path.md` reference as Step 0 before proceeding with their workflow.
version: 1.1.0
---

# Arness Spark Ensure Config

Verify and establish Arness Spark configuration for the current project. This skill guarantees that a valid user profile and `## Arness` section exist before any Arness Spark workflow proceeds. It runs automatically as Step 0 of all entry-point skills via a hash-based fast-path cache.

**Entry points should NOT read this SKILL.md directly.** They should read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-ensure-config/references/step-0-fast-path.md`, which runs the cache-check shell script and only falls through to the full validation when needed. This indirection is what saves ~95% of ensure-config token cost.

When invoked DIRECTLY (rare — typically via `/arn-spark-ensure-config`), this skill bypasses the cache and runs the full validation flow.

## Workflow

Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-ensure-config/references/ensure-config.md` and follow its instructions (Layers 1–2, then Layer 3 cache write).
