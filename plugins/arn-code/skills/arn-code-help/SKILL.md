---
name: arn-code-help
description: >-
  This skill should be used when the user says "arness code help", "where am I",
  "what's next", "show pipeline", "pipeline status", "what step am I on",
  "arness code status", "arn-code-help", "show workflow",
  or wants to see their current position in the Arness workflow pipeline
  and get guidance on the next step.
version: 1.2.0
---

# Arness Help

Detect the user's current position in the Arness workflow pipeline, render an ASCII diagram with the active stage marked, and suggest the next command to run. Supports cross-plugin awareness — detects activity in Arness Spark and Arness Infra and provides hints at the bottom of the output. This skill is strictly read-only -- it never modifies files or project state.

**Allowed tools:** Read, Glob, Grep only. This skill MUST NOT use Write, Edit, Bash, or Task tools. This skill MUST NOT invoke any agents.

## Workflow

### Step 0: Multi-Plugin Awareness

1. From the `## Arness` section (loaded in Step 1), detect other plugin field groups:
   - **spark_fields_present**: true if `Vision directory` OR `Use cases directory` OR `Prototypes directory` present
   - **infra_fields_present**: true if `Infra plans directory` OR `Infra specs directory` present
2. For each detected plugin, do a quick existence check (max 2 files):
   - **Spark**: Check if `<Vision directory>/product-concept.md` exists
   - **Infra**: Check if `<Infra plans directory>` has any subdirectories, OR if `Dockerfile` or `docker-compose.yml` exists in the project root
3. Record `{ plugin_name, has_activity: bool }` for each detected plugin.
4. Proceed to Step 1. Cross-plugin hints are appended AFTER own status is rendered in Step 3.

---

### Step 1: Load Configuration

1. Read the project's `CLAUDE.md` file.
2. Extract the `## Arness` section.
3. From the `## Arness` section, extract **core fields**:
   - **Plans directory** (e.g., `.arness/plans/`)
   - **Specs directory** (e.g., `.arness/specs/`)
   - **Docs directory** (e.g., `.arness/docs/`)

**If `## Arness` is missing:** Skip to Step 3 and render the core pipeline diagram with all stages unmarked. Suggest the user run `/arn-planning` to get started for an existing project, or `/arn-brainstorming` for a brand-new project (requires arn-spark). Do not attempt detection.

---

### Step 2: Detect Pipeline Position

Read the pipeline reference file at `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-help/references/pipeline-map.md` to load detection rules, context-aware rendering rules, and next-step tables.

#### Core Detection

##### Per-Project Detection

For each subdirectory in the plans directory, check artifacts to determine the most advanced stage. Check from most advanced to least advanced -- first match wins:

1. **Documented** (`docs`): A file matching the project name exists in the configured docs directory (`<docs-dir>/<project>.md` or `<docs-dir>/<project>/` directory)
2. **Execution complete** (`execute-done`): The subdirectory has `PROGRESS_TRACKER.json` with `overallStatus` = `"completed"`. Note: `arn-code-review-implementation` does not write a durable artifact, so both "execution complete" and "review complete" map to this detection. The next-step suggestion covers both cases.
3. **Executing** (`execute`): The subdirectory has any `reports/IMPLEMENTATION_REPORT_*.json` or `reports/TESTING_REPORT_*.json`
4. **Tasks created** (`taskify`): The subdirectory has `TASKS.md` with parseable task entries
5. **Plan saved** (`save`): The subdirectory has `INTRODUCTION.md`
6. Otherwise: skip this subdirectory (incomplete project setup)

##### Global Core Detection

If no per-project stages were detected:
- Check the plans directory for subdirectories matching `SWIFT_*` containing `SWIFT_REPORT.json` -- if found, stage is **Swift complete** (`swift-complete`)
- Check the plans directory for subdirectories matching `SWIFT_*` containing `SWIFT_*.md` but no `SWIFT_REPORT.json` -- if found, stage is **Swift in progress** (`swift-in-progress`)
- Check the plans directory for subdirectories matching `STANDARD_*` containing `STANDARD_REPORT.json` -- if found, stage is **Standard complete** (`standard-complete`)
- Check the plans directory for subdirectories matching `STANDARD_*` containing `STANDARD_*.md` but no `STANDARD_REPORT.json` -- if found, stage is **Standard in progress** (`standard-in-progress`)
- Check the plans directory for files matching `PLAN_PREVIEW_*.md` -- if found, stage is **Plan generated** (`plan`)
- Check the specs directory for files matching `FEATURE_*.md` or `BUGFIX_*.md` -- if found, stage is **Spec written** (`spec`)
- Check the specs directory for files matching `DRAFT_FEATURE_*.md` -- if found and no finalized `FEATURE_*.md` or `BUGFIX_*.md` exists, stage is **Spec in progress** (`spec-draft`)
- If `## Arness` exists with core fields but specs and plans directories are empty, stage is **Initialized** (`init`). Suggest `/arn-code-feature-spec`, `/arn-code-bug-spec`, for quick changes (1-8 files) `/arn-code-swift`, or for medium complexity `/arn-code-standard`

#### Fallback

- If `## Arness` exists but no artifacts are found, stage is `init`.

---

### Step 3: Render Pipeline Diagram

Read the pipeline templates and rendering rules from `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-help/references/pipeline-map.md`.

Show the core pipeline diagram with the position marker. Follow the existing rendering:
- Single-project or multi-project diagrams
- Next-step suggestion from the core next-step table

After rendering the core pipeline status and next-step suggestion, append cross-plugin hints from Step 0:

- If Spark has activity: append "Spark exploration: active — run `/arn-spark-help` for details."
- If Infra has activity: append "Infrastructure pipeline: active — run `/arn-infra-help` for details."
- If own pipeline has NO activity but is initialized (`init`): show own suggestions FIRST (e.g., "Run `/arn-code-feature-spec` to spec a feature, `/arn-code-bug-spec` for a bug, `/arn-code-swift` for a quick fix, or `/arn-code-assess` for a codebase review"), then optionally mention other plugins.
- When own pipeline is complete (shipped): suggest "Start a new feature? `/arn-planning`". If Infra is configured: "Deploy with `/arn-infra-wizard`."

Keep output concise -- the user wants a quick status check, not a wall of text. Show the diagram, the detected stage, the next command, and any cross-plugin hints. That is all.

---

### Step 4: Answer Follow-up Questions

After presenting the pipeline status:

1. Remain available for follow-up questions about either pipeline, skill purposes, or workflow decisions.
2. Reference `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-help/references/pipeline-map.md` for answers -- do not re-scan the filesystem unless the user explicitly asks to refresh the detection.
3. Keep answers brief and direct.

**Arness-sketch detection:** If a `arness-sketches/` directory exists in the project root, note it in the status output: "Active sketches: `arness-sketches/` directory detected with [N] route(s)." This is informational -- it does not affect pipeline position.

Common questions the user might ask:
- "What does arn-code-taskify do?" -- explain the skill's purpose from the pipeline context
- "Can I skip the review step?" -- explain that steps are optional but recommended
- "How do I go back to the previous step?" -- explain that the pipeline is not strictly linear; the user can re-run any earlier skill
- "How do I start?" -- suggest `/arn-planning` which handles scope assessment and routes to the right workflow
- "How do I run the full pipeline?" -- explain the chaining pattern: `/arn-planning` → `/arn-implementing` → `/arn-shipping`. Each entry point offers to chain to the next at completion.
- "What are the entry points?" -- explain the 5 first-citizen entry points: `/arn-planning`, `/arn-implementing`, `/arn-shipping`, `/arn-reviewing-pr`, `/arn-assessing`
- "Where is greenfield status?" -- "Run `/arn-spark-help` for Spark exploration pipeline status."
- "Where is infrastructure status?" -- "Run `/arn-infra-help` for Arness Infra pipeline status."
- "What is arn-code-assess?" -- explain it's a comprehensive assessment tool that reviews the codebase against stored patterns, lets you prioritize findings, then orchestrates the full pipeline to implement improvements
- "Can I review my codebase quality?" -- suggest `/arn-code-assess` for a guided technical review with prioritized improvements
- "What is arn-code-simplify?" -- Reviews implemented code for reuse, quality, and efficiency improvements using three parallel reviewers with pattern awareness. Runs after execution and before review.
- "How do I simplify my code?" -- Run `/arn-code-simplify` after executing your plan or swift implementation. It auto-detects the scope from your most recent execution artifacts.

---

## Error Handling

- **`## Arness` section not found in CLAUDE.md** -- Show the core pipeline diagram with no stage marked. Display "Not configured" as the current position. Suggest running `/arn-planning` for existing projects, or `/arn-brainstorming` for a brand-new project (requires arn-spark).
- **Plans directory does not exist** -- Treat the project as being at the "Initialized" (`init`) stage for core. Suggest running `/arn-code-feature-spec` or `/arn-code-bug-spec` to create a specification (or `/arn-code-feature-spec-teams` for team debate format). For quick changes (1-8 files), suggest `/arn-code-swift`.
- **Specs directory does not exist** -- Treat the project as being at the "Initialized" (`init`) stage for core. Suggest running `/arn-code-feature-spec` or `/arn-code-bug-spec`. For quick changes (1-8 files), suggest `/arn-code-swift`.
- **No projects found in plans directory** -- Show the core pipeline at the global detection level. Check specs directory for spec files. If specs exist, mark the `spec` stage. Otherwise mark `init`.
- **CLAUDE.md does not exist** -- Same as `## Arness` not found. Show core pipeline unmarked and suggest `/arn-planning` or `/arn-brainstorming`.
- **Pipeline reference file not found** -- Inform the user that the pipeline-map.md reference is missing and suggest reinstalling or updating the Arness plugin.

## Constraints

- This skill MUST NOT write or modify any files.
- This skill MUST NOT invoke any agents.
- All tools used must be read-only: Read, Glob, Grep.
- All command suggestions must use bare skill names without the plugin prefix (e.g., `/arn-code-init`, `/arn-code-plan`, `/arn-spark-discover`). Do not use the fully qualified `plugin:skill` format in user-facing text.
