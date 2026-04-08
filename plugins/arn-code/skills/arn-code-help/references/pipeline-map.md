# Pipeline Map

Reference for the `arn-code-help` skill. Contains pipeline templates, stage detection rules, and next-step suggestions for the **core development pipeline**. Cross-plugin hints reference Arness Spark and Arness Infra.

---

## Core Pipeline Template

The diagram below is the canonical core development pipeline. When rendering for the user, annotate the active stage with a `YOU ARE HERE` marker placed below the active stage name.

```
Core Development Pipeline
=========================

  init --> [ spec | SWIFT | STANDARD ] --> plan --> save --> review-plan --> taskify --> execute --> simplify --> review-impl --> docs --> ship
                  |        |                                                                       (optional)
                  |        +-- arn-code-standard: spec-lite -> plan -> execute -> review-lite -> ship (medium complexity, collapsed pipeline)
                  +-- arn-code-swift: quick assessment -> plan -> execute -> simplify -> verify -> ship (1-8 files, skips full pipeline)

  Tiers:     swift (low ceremony) | standard (medium ceremony) | thorough (full pipeline)
  Variants:  arn-code-feature-spec-teams, arn-code-bug-spec, arn-code-execute-plan-teams, arn-code-execute-task
  Quick:     arn-code-swift — pattern-aware implementation for small features (1-8 files)
  Standard:  arn-code-standard — collapsed spec-plan-execute for medium complexity
  Standalone: arn-code-report, arn-code-review-pr, arn-code-create-issue, arn-code-pick-issue, arn-code-sketch, arn-code-simplify, arn-code-catch-up
  Entry points: /arn-planning, /arn-implementing, /arn-shipping, /arn-reviewing-pr, /arn-assessing
```

### Core Stage-to-Skill Mapping

| Stage | Primary Skill | Notes |
|-------|--------------|-------|
| `init` | `/arn-planning` | Auto-configured via ensure-config on first entry-point invocation |
| `spec` | `/arn-code-feature-spec` or `/arn-code-bug-spec` | Teams variant: `/arn-code-feature-spec-teams` |
| `standard` | `/arn-code-standard` | Collapsed spec-plan-execute for medium complexity |
| `plan` | `/arn-code-plan` | Invokes `arn-code-feature-planner` agent; iterates with user feedback until approved; writes PLAN_PREVIEW to plans directory |
| `save` | `/arn-code-save-plan` | |
| `review-plan` | `/arn-code-review-plan` | Optional — can skip directly to taskify |
| `taskify` | `/arn-code-taskify` | |
| `execute` | `/arn-code-execute-plan` | Variants: `/arn-code-execute-plan-teams`, `/arn-code-execute-task` |
| `simplify` | `/arn-code-simplify` | Optional — reviews code for reuse, quality, and efficiency improvements |
| `review-impl` | `/arn-code-review-implementation` | Optional — recommended for 3+ phases |
| `docs` | `/arn-code-document-project` | |
| `ship` | `/arn-code-ship` | |
| `catch-up` | `/arn-code-catch-up` | Standalone -- retroactive documentation of out-of-pipeline commits |

### Core Annotation Instructions

1. Identify the user's current stage using the core detection rules below.
2. Place the marker directly below the matching stage label in the diagram.
3. If multiple projects exist (subdirectories under the plans directory), render a separate annotated diagram for each project, prefixed with the project name.
4. If no `## Arness` section exists, skip the diagram and show only the "Not initialized" next step.

**Single-project example:**

```
Core Development Pipeline
=========================

  init --> spec --> plan --> save --> review-plan --> taskify --> execute --> simplify --> review-impl --> docs --> ship
                    ^^^^                                                    (optional)
                 YOU ARE HERE

  Variants:  arn-code-feature-spec-teams, arn-code-bug-spec, arn-code-execute-plan-teams, arn-code-execute-task
  Standalone: arn-code-report, arn-code-review-pr, arn-code-create-issue, arn-code-pick-issue, arn-code-simplify, arn-code-catch-up
```

**Multi-project example:**

```
Project: auth-service

  init --> spec --> plan --> save --> review-plan --> taskify --> execute --> simplify --> review-impl --> docs --> ship
                                                                ^^^^^^^    (optional)
                                                             YOU ARE HERE

Project: billing-api

  init --> spec --> plan --> save --> review-plan --> taskify --> execute --> simplify --> review-impl --> docs --> ship
           ^^^^                                                             (optional)
        YOU ARE HERE
```

---

## Core Stage Detection Rules

Check stages from **most advanced to least advanced**. The first matching rule determines the current stage. For per-project detection, scan each subdirectory under the plans directory independently.

| Stage | Key | Detection Rule | Artifacts Checked |
|-------|-----|----------------|-------------------|
| Shipped | `ship` | Git working tree is clean AND/OR a pull request exists for the current branch | `git status`; If Platform is github: `gh pr list --head <branch>`; If Platform is bitbucket: `bkt pr list --state OPEN --limit 5 --json` and match current branch name |
| Documented | `docs` | At least one file matching the project name exists in the configured docs directory | `<docs-dir>/<project>.md` or `<docs-dir>/<project>/` directory exists |
| Implementation reviewed | `review-impl` | `PROGRESS_TRACKER.json` exists with `overallStatus` = `"completed"` AND the conversation history contains a review-implementation verdict (PASS, PASS WITH WARNINGS, or NEEDS FIXES), OR the docs directory has no project-matching files yet but execution is complete | `<plans-dir>/<project>/PROGRESS_TRACKER.json` with `overallStatus === "completed"` — if `docs` detection fails, fall through to this stage |
| Simplification complete | `simplify-done` | `SIMPLIFICATION_REPORT.json` exists in the project reports directory | `<plans-dir>/<project>/reports/SIMPLIFICATION_REPORT.json` |
| Execution complete | `execute-done` | `PROGRESS_TRACKER.json` exists in the project directory AND its `overallStatus` field = `"completed"` | `<plans-dir>/<project>/PROGRESS_TRACKER.json` — read JSON, check `overallStatus === "completed"` |
| Executing | `execute` | At least one `IMPLEMENTATION_REPORT_*.json` or `TESTING_REPORT_*.json` exists in the project reports directory | `<plans-dir>/<project>/reports/IMPLEMENTATION_REPORT_*.json` or `TESTING_REPORT_*.json` |
| Tasks created | `taskify` | `TASKS.md` exists in the project directory and contains parseable task entries (lines matching `### Task` heading pattern) | `<plans-dir>/<project>/TASKS.md` |
| Plan reviewed | `review-plan` | Contextual — no durable artifact. Treat as equivalent to "Plan saved" unless the user states the plan has been reviewed | Conversational context only |
| Plan saved | `save` | A project subdirectory exists under the plans directory containing `INTRODUCTION.md` | `<plans-dir>/<project>/INTRODUCTION.md` |
| Plan generated | `plan` | At least one file matching `PLAN_PREVIEW_*.md` exists in the plans directory (plan generated but not yet structured via save-plan) | `<plans-dir>/PLAN_PREVIEW_*.md` |
| Swift complete | `swift-complete` | A subdirectory matching `SWIFT_*` exists in the plans directory AND contains `SWIFT_REPORT.json` | `<plans-dir>/SWIFT_*/SWIFT_REPORT.json` |
| Swift in progress | `swift-in-progress` | A subdirectory matching `SWIFT_*` exists in the plans directory containing `SWIFT_*.md` but no `SWIFT_REPORT.json` | `<plans-dir>/SWIFT_*/SWIFT_*.md` (no `SWIFT_REPORT.json`) |
| Standard complete | `standard-complete` | A subdirectory matching `STANDARD_*` exists in the plans directory AND contains `STANDARD_REPORT.json` | `<plans-dir>/STANDARD_*/STANDARD_REPORT.json` |
| Standard in progress | `standard-in-progress` | A subdirectory matching `STANDARD_*` exists in the plans directory containing `STANDARD_*.md` but no `STANDARD_REPORT.json` | `<plans-dir>/STANDARD_*/STANDARD_*.md` (no `STANDARD_REPORT.json`) |
| Spec written | `spec` | At least one file matching `FEATURE_*.md` or `BUGFIX_*.md` exists in the specs directory | `<specs-dir>/FEATURE_*.md` or `<specs-dir>/BUGFIX_*.md` |
| Spec in progress | `spec-draft` | At least one file matching `DRAFT_FEATURE_*.md` exists in the specs directory, but no finalized `FEATURE_*.md` or `BUGFIX_*.md` exists | `<specs-dir>/DRAFT_FEATURE_*.md` (no finalized spec for same feature) |
| Initialized | `init` | `## Arness` section exists in CLAUDE.md with core fields (Plans directory), but specs directory is empty and plans directory is empty | `CLAUDE.md` contains `## Arness` with Plans directory, `<specs-dir>/` empty, `<plans-dir>/` empty |
| Not initialized | `none` | No `## Arness` section found in CLAUDE.md | `CLAUDE.md` missing or lacks `## Arness` |

**`review-impl` detection note:** `arn-code-review-implementation` does not write a file to a known location — its report is presented in conversation. Since artifact-based detection cannot distinguish `execute-done` from `review-impl`, both resolve to `execute-done` from artifacts alone. The practical effect: after execution completes, the suggestion is always `/arn-code-review-implementation` (which is correct even if the user has already run it — they can skip to `/arn-code-document-project`). The `docs` stage IS artifact-detectable via the docs directory.

### Per-Project Detection

When the plans directory contains multiple project subdirectories, detect the stage for each project independently:

1. Read `## Arness` from CLAUDE.md to get `Plans directory`, `Specs directory`, and `Docs directory`.
2. List subdirectories under the plans directory. Each subdirectory is a project.
3. For each project subdirectory, apply the detection rules starting from `ship` down to `save`.
4. For global stages (`none`, `init`, `spec`), these apply to the workspace as a whole, not to individual projects.

### Detection Precedence

- Per-project stages (`save` through `ship`) override global stages.
- If at least one project exists, show per-project diagrams.
- If no projects exist, show a single diagram with the global stage (`none`, `init`, or `spec`).

---

## Core Next Step Suggestions

After detecting the current core stage, suggest the next command using fully qualified names.

| Current Stage | Next Command | Description |
|---------------|-------------|-------------|
| Not initialized (`none`) | `/arn-planning` | Get started — sets up Arness automatically on first use |
| Initialized (`init`) | `/arn-code-feature-spec` or `/arn-code-bug-spec` | Create a feature or bug specification. For quick changes (1-8 files), run `/arn-code-swift`. For medium complexity, run `/arn-code-standard` |
| Swift in progress (`swift-in-progress`) | `/arn-code-swift` | Resume the swift implementation in progress |
| Swift complete (`swift-complete`) | `/arn-code-ship` | Ship the completed swift implementation |
| Standard in progress (`standard-in-progress`) | `/arn-code-standard` | Resume standard implementation |
| Standard complete (`standard-complete`) | `/arn-code-ship` | Ship completed standard implementation |
| Spec written (`spec`) | `/arn-code-plan` | Generate an implementation plan from the spec (invokes `arn-code-feature-planner` agent with feedback loop) |
| Spec in progress (`spec-draft`) | `/arn-code-feature-spec` | Resume the feature exploration to finalize the draft spec |
| Plan generated (`plan`) | `/arn-code-save-plan` | Convert the approved plan into a structured project with phases, tasks, and reports |
| Plan saved (`save`) | `/arn-code-review-plan` or `/arn-code-taskify` | Review the plan for completeness, or skip review and convert to tasks |
| Plan reviewed (`review-plan`) | `/arn-code-taskify` | Convert the reviewed plan into executable tasks |
| Tasks created (`taskify`) | `/arn-code-execute-plan` or `/arn-code-execute-task` | Execute all tasks or a single task |
| Executing (`execute`) | Continue execution or wait for completion | Tasks are being executed; check progress |
| Execution complete (`execute-done`) | `/arn-code-simplify` or `/arn-code-review-implementation` | Simplify the implementation (optional — reviews for reuse, quality, and efficiency), or review it directly against plan and patterns |
| Simplification complete (`simplify-done`) | `/arn-code-review-implementation` | Review the post-simplification implementation against plan and patterns (optional — skip to docs for simple projects) |
| Implementation reviewed (`review-impl`) | `/arn-code-document-project` | Generate developer documentation from plan artifacts and execution reports |
| Documented (`docs`) | `/arn-code-ship` | Commit, push, and create a pull request |
| Shipped (`ship`) | Pipeline complete | All stages finished for this project |

---

## Variant Commands

These can be used as alternatives at specific stages:

| Variant | Replaces | When to Suggest |
|---------|----------|-----------------|
| `/arn-code-bug-spec` | `/arn-code-feature-spec` | User is investigating a bug rather than building a feature |
| `/arn-code-feature-spec-teams` | `/arn-code-feature-spec` | User prefers team debate format with architect and UX specialist |
| `/arn-code-execute-plan-teams` | `/arn-code-execute-plan` | User wants Agent Teams execution (requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`) |
| `/arn-code-execute-task` | `/arn-code-execute-plan` | User wants to execute a single specific task rather than the full plan |

### Standalone Commands

These operate outside the main pipelines and can be suggested at any time:

| Command | Purpose | Prerequisite |
|---------|---------|--------------|
| `/arn-code-report` | Run a diagnostic report on Arness workflow issues | `## Arness` config exists |
| `/arn-code-review-pr` | Review a pull request and validate PR feedback | Platform (github or bitbucket) configured, PR exists |
| `/arn-code-create-issue` | Create a GitHub or Jira issue with Arness labels | Issue tracker (github or jira) configured |
| `/arn-code-pick-issue` | Browse issues by Arness labels and pick one to work on | Issue tracker (github or jira) configured |
| `/arn-code-ship` | Commit, push, and create a pull request | Platform (github or bitbucket) configured, committed changes |
| `/arn-code-assess` | Comprehensive codebase assessment with prioritized improvement execution through the full pipeline | `## Arness` config exists, pattern files present |
| `/arn-code-sketch` | Generate UI preview sketches for a feature before implementing it | `## Arness` config exists, frontend framework detected |
| `/arn-code-standard` | Collapsed spec-plan-execute for medium complexity changes | `## Arness` config exists |
| `/arn-code-simplify` | Review implemented code for reuse, quality, and efficiency improvements | `## Arness` config exists, recent execution artifacts present |
| `/arn-code-catch-up` | Retroactive documentation of out-of-pipeline commits. Scans git history, identifies untracked commits, generates CATCHUP_ records. | `## Arness` config exists, Git configured |

### Entry Points

Instead of running each skill manually, users can use one of 5 entry points that each drive a complete workflow:

- `/arn-planning` — Start a new feature or bug fix. Drives spec → plan → build → ship.
- `/arn-implementing` — Resume or execute an existing plan through build → review → ship. Routes to swift, standard, or thorough tier based on scope.
- `/arn-shipping` — Commit, push, and create a PR.
- `/arn-reviewing-pr` — Review PR feedback, validate findings, fix or defer.
- `/arn-assessing` — Comprehensive codebase review. Assessment agents review the codebase and suggest improvements. The user prioritizes findings, and the skill then drives them through spec → plan → execute → test → ship for each selected improvement.

When suggesting next steps, mention the entry points as alternatives if the user is at an early stage (`none`, `init`, or `spec`):

```
Tip: Run `/arn-planning` to start a new feature or bug fix, or `/arn-assessing` for a guided codebase review.
```

---

## Cross-Plugin Hints

When Step 0 detects other plugin activity, append these hints at the bottom of the status output:

**Spark active:**
"Spark exploration: active — run `/arn-spark-help` for details."

**Infra active:**
"Infrastructure pipeline: active — run `/arn-infra-help` for details."

**No own-plugin activity (`init`), own-plugin suggestions first:**
"Run `/arn-code-feature-spec` to spec a feature, `/arn-code-bug-spec` for a bug, `/arn-code-swift` for a quick fix, or `/arn-code-assess` for a codebase review."
Then if other plugins active: "You also have active work in Spark — run `/arn-spark-help` for details."

**Own pipeline complete (`ship`):**
"Feature shipped! Start a new feature with `/arn-planning`."
If Infra is configured: "Deploy with `/arn-infra-wizard`."
