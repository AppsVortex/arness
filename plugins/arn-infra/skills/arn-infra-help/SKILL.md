---
name: arn-infra-help
description: >-
  This skill should be used when the user says "infra help", "arn infra help",
  "where am I in the pipeline", "what's next for infra", "infra status",
  "pipeline status", "infra pipeline", "arn-infra-help", "show infra pipeline",
  "what step am I on for infra", "infra workflow", "infrastructure status",
  "show infrastructure pipeline", or wants to see their current position in the
  Arness Infra workflow and get guidance on the next step. This skill detects
  whether the user is in Quick (interactive) mode or Full Pipeline mode and
  renders an ASCII diagram with the active stage marked.
version: 1.1.0
---

# Arness Infra Help

Detect the user's current position in the Arness Infra workflow, determine whether they are using Quick mode (interactive skills) or Full Pipeline mode (structured change management), render an ASCII diagram with the active stage marked, and suggest the next command to run. This skill is strictly read-only -- it never modifies files or project state. Supports cross-plugin awareness — detects activity in Arness Spark and Arness Code and provides hints at the bottom of the output.

**Allowed tools:** Read, Glob, Grep only. This skill MUST NOT use Write, Edit, Bash, or Task tools. This skill MUST NOT invoke any agents.

## Prerequisites

Read `## Arness` from the project's CLAUDE.md. If no `## Arness` section exists or Arness Infra fields are missing, inform the user: "Arness Infra is not configured for this project yet. Run `/arn-infra-wizard` to get started — it will set everything up automatically." Do not proceed without it.

Extract:
- **Experience level** -- derived from user profile. Read `~/.arness/user-profile.yaml` (or `.claude/arness-profile.local.md` if it exists — project override takes precedence). Apply the experience derivation mapping from `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-ensure-config/references/experience-derivation.md`. If no profile exists, check for legacy `Experience level` in `## Arness` as fallback.
- **Infra plans directory** -- path to infrastructure change plans (default: `.arness/infra-plans`)
- **Infra specs directory** -- path to infrastructure change specs (default: `.arness/infra-specs`)
- **Infra docs directory** -- path to infrastructure documentation (default: `.arness/infra-docs`)
- **Providers** -- configured providers list
- **Environments** -- environment promotion pipeline
- **Deferred** -- whether infrastructure is deferred

If any of the infra-specific directory fields are missing, use defaults:
- `Infra plans directory` defaults to `.arness/infra-plans`
- `Infra specs directory` defaults to `.arness/infra-specs`
- `Infra docs directory` defaults to `.arness/infra-docs`

**If `Deferred` is `yes`:** Show: "Infrastructure is in deferred mode. Run `/arn-infra-init` to configure, or `/arn-infra-assess` to produce an infrastructure plan from accumulated observations." Stop.

---

## Workflow

### Step 0: Multi-Plugin Awareness

1. From the `## Arness` section (already read during Prerequisites), detect other plugin field groups:
   - **spark_fields_present**: true if `Vision directory` OR `Use cases directory` OR `Prototypes directory` present
   - **code_fields_present**: true if `Plans directory` OR `Specs directory` present
2. For each detected plugin, do a quick existence check (max 2 files):
   - **Spark**: Check if `<Vision directory>/product-concept.md` exists
   - **Code**: Check if `<Specs directory>` contains any `FEATURE_*.md` or `BUGFIX_*.md`, OR `<Plans directory>` has any subdirectories
3. Record `{ plugin_name, has_activity: bool }` for each detected plugin.
4. Proceed to Step 1. Cross-plugin hints are appended AFTER own status is rendered.

---

### Step 1: Load Pipeline Map

Read the pipeline map reference file for detection rules, ASCII templates, and next-step tables.

Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-help/references/pipeline-map.md`

---

### Step 2: Detect Pipeline Mode and Position

Check for artifacts in both Quick mode and Full Pipeline mode directories. The mode with detected artifacts determines the active pipeline.

#### Full Pipeline Detection

Check the Infra specs directory and Infra plans directory for pipeline artifacts. Apply the **Full Pipeline Stage Detection Rules** from pipeline-map.md, checking from most advanced stage to least advanced -- first match wins. Stages: `documented` > `reviewed` > `executed` > `executing` > `saved` > `planned` > `specced`. If no pipeline artifacts found, fall through to Quick mode.

#### Quick Mode Detection

Check for interactive infrastructure artifacts. Apply the **Quick Mode Stage Detection Rules** from pipeline-map.md, checking from most advanced to least advanced -- first match wins. Stages: `monitored` > `verified` > `deployed` > `defined` > `containerized` > `discovered` > `initialized`.

#### No State Detected

If neither Quick mode nor Full Pipeline artifacts are found beyond initialization:
- If `## Arness` exists: position is `initialized`, suggest `/arn-infra-wizard`
- If `## Arness` does not exist: suggest `/arn-infra-init`

---

### Step 3: Render Pipeline Diagram

Read the appropriate ASCII diagram template from the pipeline-map.md reference and render it with the position marker.

#### Experience Level Adaptation

**Expert:**
Show the compact diagram, detected stage name, and next command. No explanatory text.

**Intermediate:**
Show the diagram with a one-line description of the current stage and what the next step does.

**Beginner:**
Show the diagram with a brief explanation of the current stage, what has been completed, what the next step does, and why it matters. Include the full `/arn-infra-<name>` command for copy-paste.

#### Dual-Mode Display

If artifacts from both Quick mode and Full Pipeline mode are detected:
- Show both pipelines with position markers
- Note which mode is more recent or more advanced
- Suggest the user pick one mode and continue there

---

### Step 4: Suggest Next Step

Based on the detected position, look up the next command in the next-step table from pipeline-map.md.

Present the suggestion using the fully-qualified `/arn-infra-<name>` invocation format.

If the user is at the end of a pipeline:
- **Quick mode complete:** "The interactive infrastructure workflow is complete. Consider running `/arn-infra-help` periodically to check status, or `/arn-infra-verify` to re-validate your deployment."
- **Full Pipeline complete:** "The infrastructure change pipeline is complete. The change has been documented. Consider running `/arn-infra-verify` to re-validate, or start a new change with `/arn-infra-change-spec`."

After rendering the infra pipeline status and next-step suggestion, append cross-plugin hints from Step 0:

- If Code has activity: append "Development pipeline: active — run `/arn-code-help` for details."
- If Spark has activity: append "Spark exploration: active — run `/arn-spark-help` for details."
- When not configured: suggest own options first (`/arn-infra-wizard` to get started), then: "Looking for development workflows? Try `/arn-code-help`. Starting a new product? Try `/arn-spark-help`."
- When own pipeline complete (deployed + monitored): "Infrastructure pipeline complete. Start a new change with `/arn-infra-change-spec`." If Code is configured: "Build more features with `/arn-planning`."

---

### Step 5: Answer Follow-up Questions

After presenting the pipeline status:

1. Remain available for follow-up questions about skills, pipeline stages, or workflow decisions.
2. Reference the pipeline-map.md for answers -- do not re-scan the filesystem unless the user explicitly asks to refresh detection.
3. Keep answers brief and direct.

Common questions the user might ask:
- "What does arn-infra-define do?" -- explain the skill's purpose from the pipeline context
- "Can I skip the containerize step?" -- explain that steps are optional; the wizard walks through all but individual skills can be run in any order
- "What is the difference between Quick mode and Full Pipeline?" -- Quick mode runs interactive skills directly; Full Pipeline uses specs, plans, and review gates for structured change management
- "How do I switch from Quick mode to Full Pipeline?" -- run `/arn-infra-change-spec` to start the structured pipeline
- "How do I start?" -- suggest `/arn-infra-wizard` which detects project state and presents guided options
- "What is the wizard?" -- explain it's a guided orchestrator that chains infrastructure skills in sequence, pausing at decision points
- "Where is the development pipeline?" -- "Run `/arn-code-help` for Arness Code development pipeline status."
- "Where is greenfield/Spark status?" -- "Run `/arn-spark-help` for Spark exploration pipeline status."

---

## Error Handling

- **`## Arness` config missing:** Suggest running `/arn-infra-wizard` to get started. Stop.
- **No artifacts found:** Show the pipeline diagram with the `initialized` stage marked. Suggest running `/arn-infra-wizard` to start the infrastructure workflow.
- **Ambiguous state (artifacts from both modes):** Show both pipelines with positions. Note: "Artifacts from both Quick mode and Full Pipeline mode were detected. The most recently modified artifacts suggest [mode]. Continue with `/arn-infra-<next-command>`."
- **Infra plans/specs/docs directories do not exist:** Treat as `initialized` stage. The directories may not have been created yet (pre-pipeline-feature projects).
- **Pipeline reference file not found:** Inform the user that the pipeline-map.md reference is missing and suggest reinstalling or updating the Arness Infra plugin.
- **Deferred mode active:** Show deferred status and suggest un-deferring via `/arn-infra-init` or producing an assessment via `/arn-infra-assess`.
- **Re-running is safe:** This skill is read-only. Re-running always produces a fresh detection based on current artifacts.

## Constraints

- This skill MUST NOT write or modify any files.
- This skill MUST NOT invoke any agents.
- All tools used must be read-only: Read, Glob, Grep.
- All command suggestions must use fully qualified format (e.g., `/arn-infra-init`, `/arn-infra-wizard`).
