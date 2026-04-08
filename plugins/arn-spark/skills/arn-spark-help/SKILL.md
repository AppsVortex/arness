---
name: arn-spark-help
description: >-
  This skill should be used when the user says "spark help", "arn spark help",
  "greenfield status", "greenfield help", "where am I in spark", "what's next for spark",
  "spark pipeline", "spark status", "arn-spark-help", "show spark pipeline",
  "what step am I on for spark", "spark workflow", "exploration status",
  "show exploration pipeline", "how does spark work", "explain spark pipeline",
  or wants to see their current position in the
  Arness Spark exploration pipeline and get guidance on the next step.
version: 1.0.0
---

# Arness Spark Help

Detect the user's current position in the Arness Spark exploration pipeline, render a diagram with the active stage marked, and suggest the next command to run. Supports cross-plugin awareness — detects activity in Arness Code and Arness Infra and provides hints at the bottom of the output. This skill is strictly read-only — it never modifies files or project state.

**Allowed tools:** Read, Glob, Grep only. This skill MUST NOT use Write, Edit, Bash, or Task tools. This skill MUST NOT invoke any agents.

## Workflow

### Step 0: Multi-Plugin Awareness

1. Read the project's `CLAUDE.md` file.
2. Extract the `## Arness` section.
3. Detect other plugin field groups:
   - **code_fields_present**: true if `Plans directory` OR `Specs directory` present in `## Arness`
   - **infra_fields_present**: true if `Infra plans directory` OR `Infra specs directory` present in `## Arness`
4. For each detected plugin, do a quick existence check (max 2 files):
   - **Code**: Check if `<Specs directory>` contains any `FEATURE_*.md` or `BUGFIX_*.md`, OR `<Plans directory>` has any subdirectories
   - **Infra**: Check if `<Infra plans directory>` has any subdirectories, OR if `Dockerfile` or `docker-compose.yml` exists in the project root
5. Record `{ plugin_name, has_activity: bool }` for each detected plugin.
6. Proceed to Step 1. The cross-plugin hints are appended AFTER own status is rendered in Step 3.

---

### Step 1: Load Configuration

1. From the `## Arness` section, extract **Spark fields**:
   - **Vision directory** (e.g., `.arness/vision/`)
   - **Use cases directory** (e.g., `.arness/use-cases/`)
   - **Prototypes directory** (e.g., `.arness/prototypes/`)
   - **Spikes directory** (e.g., `.arness/spikes/`)
   - **Visual grounding directory** (e.g., `.arness/visual-grounding/`)
   - **Reports directory** (e.g., `.arness/reports/`)

**If `## Arness` is missing or no Spark fields present:** Show the Spark pipeline diagram with all stages unmarked. Suggest `/arn-brainstorming` to start a new greenfield project. Do not attempt detection.

---

### Step 2: Detect Pipeline Position

Read the pipeline reference file at `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-help/references/pipeline-map.md` to load detection rules, rendering templates, and next-step tables.

Check from most advanced to least advanced — first match wins:

1. **Feature backlog ready** (`gf-feature-extract`): `<vision-dir>/features/feature-backlog.md` exists
2. **Prototype locked** (`gf-prototype-lock`): `<prototypes-dir>/locked/LOCKED.md` exists
3. **Clickable prototype done** (`gf-clickable-proto`): `<prototypes-dir>/clickable/final-report.md` exists
4. **Static prototype done** (`gf-static-proto`): `<prototypes-dir>/static/final-report.md` exists
5. **Style defined** (`gf-style-explore`): `<vision-dir>/style-brief.md` exists
6. **Visual direction chosen** (`gf-visual-sketch`): `<vision-dir>/visual-direction.md` exists
7. **Spike complete** (`gf-spike`): `<vision-dir>/spike-results.md` exists
8. **Scaffold built** (`gf-scaffold`): `<vision-dir>/scaffold-summary.md` exists
9. **Use cases written** (`gf-use-cases`): At least one `UC-*.md` file exists in `<use-cases-dir>/`
10. **Architecture defined** (`gf-arch-vision`): `<vision-dir>/architecture-vision.md` exists
11. **Naming complete** (`gf-naming`): `<vision-dir>/naming-brief.md` exists OR `<reports-dir>/naming-report.md` exists
12. **Concept reviewed** (`gf-concept-review`): `<reports-dir>/stress-tests/concept-review-report.md` exists
13. **Stress tests run** (`gf-stress-test`): Any of `interview-report.md`, `competitive-report.md`, `premortem-report.md`, `prfaq-report.md` exists in `<reports-dir>/stress-tests/`
14. **Product discovered** (`gf-discover`): `<vision-dir>/product-concept.md` exists
15. **Spark initialized** (`gf-init`): Spark fields exist in `## Arness` but none of the above artifacts found

**Spark complete:** If the detected stage is `gf-feature-extract`, Spark exploration is considered complete.

---

### Step 3: Render Pipeline Diagram

Read the pipeline templates from `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-help/references/pipeline-map.md`.

1. Place the `YOU ARE HERE` marker below the detected stage.
2. Display the next-step suggestion from the next-step table.
3. Spark is a single-track pipeline (no per-project subdirectories).

**Own-plugin suggestions always come first.** After the pipeline diagram and next-step suggestion, append cross-plugin hints from Step 0:

- If own plugin has activity: show own status first. If other plugins have activity, append 1-2 lines at the bottom:
  ```
  Other pipelines: Development (active) — `/arn-code-help` | Infrastructure (not started)
  ```

- If own plugin is idle (`gf-init`) but other plugins have activity: show own-plugin "ready to start" suggestions FIRST:
  ```
  Ready to start: run `/arn-spark-discover` to shape your product idea, or `/arn-brainstorming` for the guided wizard.
  ```
  Then mention others:
  ```
  You also have active work in Code — run `/arn-code-help` for details.
  ```

- When Spark pipeline is complete (`gf-feature-extract`): suggest transition:
  ```
  Spark exploration is complete. Next steps:
  - Start developing features: `/arn-planning`
  - Deploy infrastructure: `/arn-infra-wizard`
  ```

Keep output concise — the user wants a quick status check, not a wall of text.

---

### Step 4: Answer Follow-up Questions

After presenting the pipeline status:

1. Remain available for follow-up questions about the Spark pipeline, skill purposes, or workflow decisions.
2. Reference `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-help/references/pipeline-map.md` for answers — do not re-scan the filesystem unless the user explicitly asks to refresh the detection.
3. Keep answers brief and direct.

Common questions the user might ask:
- "What is Spark?" — Spark is the exploration phase for new projects. It takes a raw idea through structured discovery, validation, prototyping, and feature extraction before development begins.
- "How do I run the full Spark pipeline?" — Run `/arn-brainstorming`, which walks through the entire exploration pipeline with guided decision gates.
- "What are stress tests?" — Four adversarial lenses that test your product concept: synthetic user interviews, competitive gap analysis, pre-mortem failure analysis, and PR/FAQ stress testing.
- "What is naming?" — A structured 4-step brand naming methodology: strategic foundation, creative generation, qualitative scoring, and due diligence with WHOIS domain checking.
- "Can I skip stress tests?" — Yes, all stages are optional. The brainstorming wizard presents skip options at each gate.
- "How do I transition to development?" — After feature extraction, run `/arn-planning` in the project. Arness Code sets up automatically on first use.
- "Where is the development pipeline status?" — Run `/arn-code-help` for the Arness Code development pipeline.
- "Where is infrastructure status?" — Run `/arn-infra-help` for the Arness Infra infrastructure pipeline.
- "What are the entry points?" — `/arn-brainstorming` is the main Spark entry point. For development: `/arn-planning`. For infrastructure: `/arn-infra-wizard`.
- "What is dev-setup?" — `/arn-spark-dev-setup` is a standalone skill for defining or onboarding to a development environment (dev containers, Docker, CI workflows). It can be run at any time after greenfield config exists.
- "What is visual-strategy?" — `/arn-spark-visual-strategy` sets up layered visual regression testing infrastructure (capture scripts, baselines, comparison pipelines). Requires scaffold and at least style-explore to be complete.
- "What is visual-readiness?" — `/arn-spark-visual-readiness` validates and activates deferred visual testing layers after project milestones. Requires a visual strategy to be defined first.

---

## Error Handling

- **`## Arness` section not found in CLAUDE.md** — Show the Spark pipeline diagram with no stage marked. Suggest running `/arn-brainstorming` to start a new greenfield project.
- **CLAUDE.md does not exist** — Same as `## Arness` not found.
- **Spark fields present but directories don't exist** — Treat as `gf-init` stage. The directories may not have been created yet.
- **Pipeline reference file not found** — Inform the user that the pipeline-map.md reference is missing and suggest reinstalling or updating the Arness Spark plugin.
- **Reports directory not configured** — Skip stress-test, concept-review, and naming detection (these stages require the Reports directory). Proceed with detection from `gf-arch-vision` downward.

## Constraints

- This skill MUST NOT write or modify any files.
- This skill MUST NOT invoke any agents.
- All tools used must be read-only: Read, Glob, Grep.
- All command suggestions must use bare skill names (e.g., `/arn-spark-discover`, `/arn-code-help`). Do not use the fully qualified `plugin:skill` format in user-facing text.
