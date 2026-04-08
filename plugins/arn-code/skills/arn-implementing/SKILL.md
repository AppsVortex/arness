---
name: arn-implementing
description: >-
  This skill should be used when the user says "implementing", "arness implementing",
  "start implementing", "execute the plan", "build it", "implement this",
  "run the tasks", "execute", "start building", "implement the feature",
  "implement the fix", "quick change", "swift", "swift mode", "quick implementation",
  "standard", "standard mode", "standard implementation",
  "start execution", "build the feature", "arn-implementing",
  or wants to execute an implementation plan, run a quick implementation,
  a standard-tier implementation, or manage the build-simplify-review cycle.
  Chains to arn-shipping at completion.
version: 1.1.0
---

# Arness Implementing

Execute an implementation plan, run a quick implementation (swift), run a standard-tier implementation, or manage the build-simplify-review cycle. This is a first-citizen entry point that orchestrates `arn-code-execute-plan`, `arn-code-swift`, `arn-code-standard`, `arn-code-simplify`, `arn-code-review-implementation`, and related execution skills. Chains from `arn-planning` and chains to `arn-shipping` or `arn-assessing` at completion.

This skill is a **sequencer and decision-gate handler**. It MUST NOT duplicate sub-skill logic. All implementation work is done by the invoked skills. Arness-implementing handles: input routing, state detection, execution mode selection, the simplify/review cycle, and chaining.

## Step 0: Ensure Configuration

Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-ensure-config/references/ensure-config.md` and follow its instructions. This guarantees a user profile exists and `## Arness` is configured with Arness Code fields before proceeding.

After Step 0 completes, extract the following from `## Arness`:
- **Plans directory** — for detecting structured plans and project folders
- **Code patterns** — path to stored pattern documentation
- **Template path** — path to report templates

## Workflow

### Step 0: Input Routing

Check the trigger message for swift or standard intent:

- **"swift: [description]"**, **"quick: [description]"**, **"quick change: [description]"**, or **"quick implementation: [description]"** detected:
  → Route directly to the Swift Path (Step S1). Skip all state detection.

- **"standard: [description]"** or **"standard mode: [description]"** detected:
  → Route directly to the Standard Path (Step ST1). Skip all state detection.

- **No swift or standard intent** detected:
  → Proceed to Step 1 (State Detection).

---

### Step 1: State Detection

Check which artifacts exist on disk to determine the entry point. Check from most advanced to least advanced — first match wins:

| Artifact | Detected State | Resume Point |
|----------|---------------|--------------|
| `SIMPLIFICATION_REPORT.json` in `<plans-dir>/<project>/reports/` | Simplification done | G4 (Review implementation) |
| Any `IMPLEMENTATION_REPORT_*.json` or `TESTING_REPORT_*.json` in `<plans-dir>/<project>/reports/` (no SIMPLIFICATION_REPORT) | Execution complete | G3 (Simplify?) |
| `TASKS.md` in `<plans-dir>/<project>/` with parseable task entries | Tasks exist | G2 (Execution mode) |
| `INTRODUCTION.md` in `<plans-dir>/<project>/` but no `TASKS.md` | Plan saved, not taskified | Auto-taskify, then G2 |
| `SWIFT_REPORT.json` in `<plans-dir>/SWIFT_<name>/` | Swift complete | G5 (Completion handoff) |
| `<plans-dir>/SWIFT_<name>/SWIFT_<name>.md` but no report | Swift plan exists, not executed | Resume swift execution |
| `STANDARD_REPORT.json` in `<plans-dir>/STANDARD_<name>/` | Standard complete | G5 (Completion handoff) |
| `<plans-dir>/STANDARD_<name>/STANDARD_<name>.md` but no report | Standard in progress | Resume standard execution |
| None of the above | No plan found | G0 (No plan fallback) |

**If multiple projects detected** (more than one subdirectory in plans-dir with artifacts): list them with their states and ask the user which to implement.

**If artifacts detected for a single project:** ask: "Resume [project-name] at [detected stage], or start fresh?"
- **Resume** → skip to the detected gate
- **Start fresh** → begin at G0/G2 (do not delete existing artifacts)

---

### Step 2: Gate G0 — No Plan Fallback

Only reached when no structured plan or swift artifacts are found.

Show progress:
```
Implementing: [no plan detected]
```

Ask (using `AskUserQuestion`):

**"No implementation plan found. What would you like to do?"**

Options:
1. **Quick implementation** — Describe a small change for swift mode
2. **Go to planning first** — Run `/arn-planning` to create a spec and plan

If **Quick implementation**: Ask for a description, then route to Swift Path (Step S1).
If **Go to planning first**: `Skill: arn-code:arn-planning`. After planning completes and chains back, re-run state detection (Step 1). If the scope router assigned `standard` tier, route to Standard Path (Step ST1) instead of full execution.

---

### Step 3: Auto — Taskify (conditional)

If state detection found `INTRODUCTION.md` but no `TASKS.md`, run taskify automatically:

Inform: "Creating task list from plan..."

> `Skill: arn-code:arn-code-taskify`

After taskify completes, proceed to G2.

---

### Step 4: Gate G2 — Execution Mode

Show progress:
```
Implementing: EXECUTE -> simplify -> review-impl -> [ship]
              ^^^^^^^
```

Ask (using `AskUserQuestion`):

**"How should the tasks be executed?"**

Options:
1. **Sequential with review gates** (Recommended) — Each task is executed and reviewed before the next
2. **Parallel with Agent Teams** — Tasks run in parallel using Agent Teams (higher token cost)
3. **One task at a time** — Execute tasks manually, one at a time

Based on choice:
- **Sequential** → `Skill: arn-code:arn-code-execute-plan`
- **Agent Teams** → `Skill: arn-code:arn-code-execute-plan-teams`
  - If Agent Teams is not available (environment variable not set), inform the user and suggest sequential instead.
- **One at a time** → `Skill: arn-code:arn-code-execute-task`
  - After each task, the user controls which task to run next. When the user is done or all tasks are complete, proceed to G3.

---

### Step 5: Gate G3 — Simplify?

Show progress:
```
Implementing: execute -> SIMPLIFY -> review-impl -> [ship]
                         ^^^^^^^^
```

**Preference check:** Read `pipeline.simplification` using the two-tier lookup chain (see `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-ensure-config/references/preferences-schema.md`):

1. Read `.arness/workflow.local.yaml` — if the file exists and `pipeline.simplification` is present, use that value and note source.
2. If not found, read `~/.arness/workflow-preferences.yaml` — if the file exists and `pipeline.simplification` is present, use that value and note source.
3. If neither found or key is absent, treat as null (first encounter).

Branch on the resolved value:

- If `always`: Show status line: "Preference: running simplification pass ([source])". Auto-proceed to `Skill: arn-code:arn-code-simplify`. After simplification completes, proceed to G4.

- If `skip`: Show status line: "Preference: skipping simplification ([source])". Auto-proceed to G4.

- If `ask`: Present the gate below. Do NOT show the "remember this?" follow-up afterward.

- If null (or invalid value): Present the gate below. After the user answers, show the "remember this?" follow-up (see below).

**Gate (shown when value is `ask`, null, or invalid):**

Ask (using `AskUserQuestion`):

**"Execution complete. Simplify the implementation before review?"**

Options:
1. **Yes** (Recommended for 3+ phases) — Review for reuse opportunities, quality issues, and efficiency improvements
2. **Skip** — Proceed without simplification

If **Yes**: `Skill: arn-code:arn-code-simplify`
If **Skip**: Proceed to G4.

**Follow-up (only when preference was null):** After the user answers the gate, ask:

Ask (using `AskUserQuestion`):

**"Should Arness remember this choice for future sessions?"**

Options:
1. **Yes, always [chosen action]** (saves to preferences)
2. **No, ask me each time**

If **Yes**: Write the chosen value (`always` or `skip`) to `~/.arness/workflow-preferences.yaml` under `pipeline.simplification`. Create `~/.arness/` directory and file if they do not exist. If the file already exists, read it first, add or update the key under `pipeline:`, and write back preserving all existing keys.
If **No**: Write `ask` to `~/.arness/workflow-preferences.yaml` under `pipeline.simplification` (same write logic).

---

### Step 6: Gate G4 — Review Implementation?

Show progress:
```
Implementing: execute -> simplify -> REVIEW-IMPL -> [ship]
                                     ^^^^^^^^^^^
```

**Preference check:** Read `pipeline.implementation-review` using the two-tier lookup chain (see `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-ensure-config/references/preferences-schema.md`):

1. Read `.arness/workflow.local.yaml` — if the file exists and `pipeline.implementation-review` is present, use that value and note source.
2. If not found, read `~/.arness/workflow-preferences.yaml` — if the file exists and `pipeline.implementation-review` is present, use that value and note source.
3. If neither found or key is absent, treat as null (first encounter).

Branch on the resolved value:

- If `review`: Show status line: "Preference: reviewing implementation ([source])". Auto-proceed to `Skill: arn-code:arn-code-review-implementation`. If the review verdict is **NEEDS FIXES**: the review skill handles fixes internally. After fixes, re-present this gate (the user may want to review again or proceed). After review completes successfully, proceed to G5.

- If `skip`: **Complexity override check** — count the number of phases from the plan structure (phase plan files in `<plans-dir>/<project>/plans/`) and count files modified/created across all implementation and testing reports in `<plans-dir>/<project>/reports/`. If implementation reports cannot be parsed or are missing, default to showing the review recommendation (err on the side of review). If **3 or more phases** OR **15 or more files** touched: override the skip preference and present a recommendation:

  "This implementation touches [N phases / N files]. A review is recommended even though your preference is to skip."

  Then present the gate below as a one-time question (the stored `skip` preference is NOT modified — this override is situational).

  If under both thresholds: Show status line: "Preference: skipping implementation review ([source])". Auto-proceed to G5.

- If `ask`: Present the gate below. Do NOT show the "remember this?" follow-up afterward.

- If null (or invalid value): Present the gate below. After the user answers, show the "remember this?" follow-up (see below).

**Gate (shown when value is `ask`, null, invalid, or `skip` with complexity override):**

Ask (using `AskUserQuestion`):

**"Review the implementation against plan and patterns?"**

Options:
1. **Yes** (Recommended for 3+ phases) — Full implementation review
2. **Skip** — Proceed without review

If **Yes**: `Skill: arn-code:arn-code-review-implementation`

If the review verdict is **NEEDS FIXES**: the review skill handles fixes internally. After fixes, re-present this gate (the user may want to review again or proceed).

If **Skip**: Proceed to G5.

**Follow-up (only when preference was null — not shown for complexity override):** After the user answers the gate, ask:

Ask (using `AskUserQuestion`):

**"Should Arness remember this choice for future sessions?"**

Options:
1. **Yes, always [chosen action]** (saves to preferences)
2. **No, ask me each time**

If **Yes**: Write the chosen value (`review` or `skip`) to `~/.arness/workflow-preferences.yaml` under `pipeline.implementation-review`. Create `~/.arness/` directory and file if they do not exist. If the file already exists, read it first, add or update the key under `pipeline:`, and write back preserving all existing keys.
If **No**: Write `ask` to `~/.arness/workflow-preferences.yaml` under `pipeline.implementation-review` (same write logic).

---

### Step 7: Gate G5 — Completion Handoff

**Generate CHANGE_RECORD.json for thorough tier (conditional):**

Before presenting the completion handoff, check if this is a thorough-tier project that needs a CHANGE_RECORD.json. A project is thorough-tier when it has a full project structure (`INTRODUCTION.md`, phase plans, reports) and its artifact directory does NOT use the `SWIFT_` or `STANDARD_` prefix.

If thorough-tier detected AND no `CHANGE_RECORD.json` exists in `<plans-dir>/<project>/`:
1. Read `CHANGE_RECORD_TEMPLATE.json` from the template path configured in `## Arness`
2. Populate with:
   - `recordType`: `"change-record"`
   - `version`: `1`
   - `ceremonyTier`: `"thorough"`
   - `projectName`: the project name
   - `changePath`: `<plans-dir>/<project>/`
   - `timestamp`: current ISO 8601 timestamp
   - `tierSelection`: `{ "recommended": "thorough", "selected": "thorough", "overrideReason": null }` (or from the scope router's original recommendation if available in INTRODUCTION.md metadata)
   - `specRef`: path to the source spec (from `INTRODUCTION.md` metadata if available)
   - `planRef`: path to `INTRODUCTION.md`
   - `reportRef`: path to the most recent `IMPLEMENTATION_REPORT_*.json` in `<plans-dir>/<project>/reports/`
   - `filesModified` / `filesCreated`: aggregated from all implementation reports in the project
   - `commitHash`: `""` (populated by arn-code-ship after commit)
   - `commitMessage`: `""` (populated by arn-code-ship after commit)
   - `review`: verdict and finding counts from the most recent review report (if available)
   - `sketchRef`: path to sketch manifest if sketch was used, `""` otherwise
   - `nextSteps`: `[]` (populated by arn-code-ship after PR creation)
3. Write to `<plans-dir>/<project>/CHANGE_RECORD.json`

If `CHANGE_RECORD.json` already exists, skip generation.

Show progress:
```
Implementing: execute -> simplify -> review-impl -> [COMPLETE]
                                                     ^^^^^^^^
```

Ask (using `AskUserQuestion`):

**"Implementation complete. What next?"**

Options:
1. **Ship it** — Commit, push, and create a PR
2. **Assess quality first** — Run a codebase assessment before shipping
3. **Not yet** — Exit (run `/arn-shipping` or `/arn-assessing` when ready)

If **Ship it**: `Skill: arn-code:arn-shipping`
If **Assess quality first**: `Skill: arn-code:arn-assessing`
If **Not yet**: Exit.

---

## Swift Path

### Step S1: Invoke Swift

Show progress:
```
Implementing: SWIFT (assess -> plan -> execute -> verify) -> [ship]
              ^^^^^
```

Invoke the swift skill with the user's description:

> `Skill: arn-code:arn-code-swift` [description]

The swift skill handles everything internally: scope assessment, complexity routing (simple/moderate/complex redirect), planning, execution, testing, and review.

**If swift redirects to full pipeline** (complexity too high): the swift skill will inform the user. After swift exits, suggest running `/arn-planning` for the full pipeline.

Wait for swift to complete.

---

### Step S2: Swift Completion Handoff

After swift completes, skip directly to G5 (Completion Handoff). Simplify and review-implementation are not needed — swift has its own lightweight review built in.

---

## Standard Path

### Step ST1: Invoke Standard

Show progress:
```
Implementing: STANDARD (spec-lite -> plan -> execute -> review) -> [ship]
              ^^^^^^^^
```

Invoke the standard skill with the user's description:

> `Skill: arn-code:arn-code-standard` [description]

The standard skill handles everything internally: spec-lite generation, plan creation, execution, testing, and review -- all in a single session.

**If standard redirects to full pipeline** (scope too large): the standard skill will inform the user. After standard exits, suggest running `/arn-planning` for the full pipeline.

Wait for standard to complete.

---

### Step ST2: Standard Completion Handoff

After standard completes, skip directly to G5 (Completion Handoff). Simplify and review-implementation are not needed — standard has its own review built in.

---

## Sketch During Building

If during execution the user asks to preview a UI component ("show me what this looks like", "sketch this", "preview the UI"), and `ui-patterns.md` in the code patterns directory has a `## Sketch Strategy` section:

> `Skill: arn-code:arn-code-sketch`

This is an ad-hoc interrupt, not a decision gate. After the sketch session completes, resume execution where it left off.

If `ui-patterns.md` does not exist or has no Sketch Strategy: inform the user that sketch is not available. Pattern documentation will be generated on first use and will include a Sketch Strategy if your project has a UI framework.

---

## Error Handling

- **`## Arness` config missing:** Handled by Step 0 (ensure-config) — this should not occur if Step 0 completed successfully.
- **No plan found and no swift intent:** Present G0 with options.
- **Agent Teams unavailable at G2:** Inform the user that the environment variable `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` is not set. Suggest sequential execution instead.
- **Swift redirect to full pipeline:** Inform the user. Suggest `/arn-planning`.
- **Standard redirect to full pipeline:** Inform the user. Suggest `/arn-planning`.
- **Multiple projects detected:** List projects with states, ask which to implement.
- **Sub-skill fails:** Present the error. Ask: retry / skip / abort.
- **User says "stop" or "pause":** Show what was completed. Inform: "Run `/arn-implementing` again to resume — artifact detection will pick up where you left off."
