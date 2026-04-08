---
name: arn-code-swift
description: >-
  This skill should be used when the user says "swift", "arness code swift",
  "quick change", "small change", "just do this", "quick feature",
  "quick implementation", "swift fix", "implement this quickly",
  "add this quickly", "simple change", "just implement this",
  "arn-code-swift", "swift mode", "quick task",
  or wants a lightweight, pattern-aware implementation for a small feature
  or enhancement (1-8 files) without going through the full Arness pipeline.
  Bridges the gap between raw Claude Code and the full feature-spec/plan
  pipeline. Includes architectural assessment, targeted testing, and
  pattern compliance review.
version: 1.1.0
---

# Arness Swift

Implement small features and enhancements through a lightweight, pattern-aware workflow: quick architectural assessment, inline plan, direct execution, verification, and review -- all in a single session. Every swift implementation produces a plan (`SWIFT_<name>.md`) and a report (`SWIFT_REPORT.json`), giving the same auditability as the full pipeline without the overhead.

This skill follows the `arn-code-bug-spec` dual-path architecture: assess complexity, route simple tasks to direct execution, escalate moderate tasks to task-tracked execution, and redirect complex tasks to the full pipeline.

This is an execution skill. It runs in normal conversation (NOT plan mode).

## Step 0: Ensure Configuration

Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-ensure-config/references/ensure-config.md` and follow its instructions. This guarantees a user profile exists and `## Arness` is configured with Arness Code fields before proceeding.

## Pipeline Position

```
              arn-code-swift (this skill)
              ========================
              For changes touching 1-8 files
              with no new architectural patterns

Entry:  User describes a small change
          |
          v
Full:   init --> [ feature-spec | bug-spec | SWIFT ] --> plan --> ...
                                              |
                          +-------------------+-------------------+
                          |                   |                   |
                       SIMPLE              MODERATE            COMPLEX
                      (1-3 files)         (4-8 files)         (9+ files)
                          |                   |                   |
                       Plan -->            Plan -->           Redirect to
                       Execute             TaskCreate -->     /arn-code-feature-spec
                       in session          Execute
                          |                   |
                       Review              Review
                          |                   |
                       Ship                Ship
```

## Workflow

### Step 1: Capture and Load Context

1. Accept the user's description. This can be anything from a sentence ("add rate limiting to /api/users") to detailed requirements. If the user already provided the description in their trigger message, use that directly without asking again.

2. Confirm understanding with a brief restatement (1-2 sentences).

3. Read the project's CLAUDE.md and extract the `## Arness` section to find:
   - Code patterns path
   - Plans directory
   - Specs directory
   - Template path
   - Template version and Template updates preference (if present)

4. Load pattern documentation from the code patterns directory:
   - `code-patterns.md` (required)
   - `testing-patterns.md` (required)
   - `architecture.md` (required)
   - `ui-patterns.md` (if it exists)
   - `security-patterns.md` (if it exists)

5. **If pattern documentation files are missing** (no `code-patterns.md`, `testing-patterns.md`, or `architecture.md` in the Code patterns directory):

   Inform the user: "This is the first time pattern documentation is being generated for this project. Analyzing your codebase to understand its patterns, conventions, and architecture. This is a one-time operation — future invocations will use the cached results."

   Then invoke the `arn-code-codebase-analyzer` agent (existing codebase) or `arn-code-pattern-architect` (greenfield) to generate fresh analysis. Write the results to the Code patterns directory.

Hold this context for use throughout the workflow.

---

### Step 2: Quick Architectural Assessment

#### 2a. Pre-check specialist relevance

Before invoking any agents, read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-ensure-config/references/specialist-pre-check.md` and apply the pre-check logic using the pattern documentation loaded in Step 1 and the user's feature description. This produces two boolean flags:

- `ui_involved`: true if ANY of: (1) `ui-patterns.md` exists AND contains a `## Sketch Strategy` section, (2) the feature description contains UI terms (component, page, form, button, layout, dashboard, UI, UX, screen, view, modal, dialog, command, terminal, output, widget, window, panel, console, display, prompt, menu, toolbar, status bar, progress, table, tree -- case-insensitive), (3) `architecture.md` contains a frontend, CLI, TUI, desktop, or mobile framework in its Technology Stack section
- `security_relevant`: true if BOTH: (1) `security-patterns.md` exists, AND (2) the feature description contains security terms (auth, login, password, token, payment, upload, API key, PII, encrypt, permission, session, cookie, CORS, CSRF, rate limit, secret, credential -- case-insensitive)

#### 2b. Parallel agent dispatch

Dispatch the following agents in parallel based on the pre-check results:

- **Always:** `arn-code-architect`
- **If `ui_involved`:** also `arn-code-ux-specialist` (requires `ui-patterns.md` to exist)
- **If `security_relevant`:** also `arn-code-security-specialist` (requires `security-patterns.md` to exist)

All dispatched agents run in parallel (independent analyses, no cross-agent dependencies).

**For `arn-code-architect`, provide:**

**User expertise context:**

```
--- BEGIN USER EXPERTISE ---
[Read from ~/.arness/user-profile.yaml or .claude/arness-profile.local.md (project override takes precedence)]
Role: [role]
Experience: [development_experience]
Technology preferences: [technology_preferences]
Expertise-aware: [expertise_aware]
--- END USER EXPERTISE ---

--- BEGIN PROJECT PREFERENCES ---
[Read from .arness/preferences.yaml if it exists, otherwise omit this section]
--- END PROJECT PREFERENCES ---
```

When presenting technology recommendations, apply the advisory pattern: present the technically optimal recommendation first, then present any preference-aligned alternative with honest pros/cons. Let the user decide.

**Feature idea:** The user's description from Step 1.

**Codebase context:** The full content of the pattern documentation loaded in Step 1 (code-patterns.md, testing-patterns.md, architecture.md, and ui-patterns.md if present).

**Specific question:** "Quick scope assessment for this change: (1) Which files need modification and why? (2) Which codebase patterns apply? (3) Are there architectural risks or concerns? (4) Estimated scope: simple (1-3 files), moderate (4-8 files), or complex (9+ files)? (5) Does this change need UI work? (6) Are there security implications?"

**For `arn-code-ux-specialist` (when dispatched), provide:** The same feature description and ui-patterns.md. Specific question: "Quick UI assessment: which components are affected? Any accessibility considerations?"

**For `arn-code-security-specialist` (when dispatched), provide:** A brief security assessment request with the feature description and security-patterns.md.

#### 2c. False-negative follow-up

After all parallel agents complete, check the architect's assessment for signals that a missed specialist should have been included:

- If `ui_involved` was false AND the architect's output mentions UI concerns, component design, user interaction, or interface layout: dispatch `arn-code-ux-specialist` sequentially with the architect's assessment as additional context.
- If `security_relevant` was false AND the architect's output mentions security concerns, authentication, authorization, data protection, or vulnerability: dispatch `arn-code-security-specialist` sequentially with the architect's assessment as additional context.

The follow-up dispatch is silent -- no user notification or status message. The user sees the combined assessment from all agents (parallel + sequential) as a single result.

#### 2d. Present combined assessment

Present the combined assessment to the user, highlighting:
1. Scope estimate (files to change, with paths)
2. Applicable patterns from code-patterns.md
3. Risks or concerns (if any)
4. UI and security notes (if applicable)

---

### Step 2b: Arness-Sketch Offer (Conditional)

After the architect assessment, check the sketch-preview preference before deciding whether to present the sketch offer.

**Prerequisite conditions (always enforced regardless of preference):** This step requires (a) significant interface scope is identified (the architect reports multiple UI components, CLI command outputs, TUI screens, or desktop/mobile views to create or modify, or the change touches layouts, pages, navigation, command output formatting, or screen composition), AND (b) `ui-patterns.md` exists with a `## Sketch Strategy` section.

**Interface file detection:** Check for interface-related files beyond web frontend types (`.tsx`, `.svelte`, `.vue`, `.jsx`). Also consider: Python files in CLI command directories or importing click/typer/rich; Python files importing textual; Go files importing bubbletea; Rust files importing ratatui; desktop component files (PyQt `.py` widget files, Electron renderer `.tsx`, Tauri frontend files) and mobile component files (React Native `.tsx` screen files, Flutter `.dart` widget files).

If the prerequisite conditions are NOT met, skip this step silently (regardless of preference value).

**Preference check (only when prerequisite conditions are met):** Read `pipeline.sketch-preview` using the two-tier lookup chain (see `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-ensure-config/references/preferences-schema.md`):

1. Read `.arness/workflow.local.yaml` — if the file exists and `pipeline.sketch-preview` is present, use that value and note source.
2. If not found, read `~/.arness/workflow-preferences.yaml` — if the file exists and `pipeline.sketch-preview` is present, use that value and note source.
3. If neither found or key is absent, treat as null (first encounter).

Branch on the resolved value:

- If `always`: Show status line: "Preference: generating sketch preview ([source])". Auto-proceed to invoke `Skill: arn-code:arn-code-sketch` with the feature description and architect assessment. After the sketch session, continue to Step 2c.

- If `never`: Show status line: "Preference: skipping sketch preview ([source])". Skip silently even if interface scope is detected. Continue to Step 2c.

- If `ask`: Present the gate below. Do NOT show the "remember this?" follow-up afterward.

- If null (or invalid value): Present the gate below. After the user answers, show the "remember this?" follow-up (see below).

**Gate (shown when value is `ask`, null, or invalid):**

Ask (using `AskUserQuestion`):

**"This change includes significant interface work. Want to see a preview first?"**

Options:
1. **Yes, sketch first** -- Generate a visual preview before implementing
2. **No, proceed with implementation** -- Continue to implementation

If **Yes, sketch first**: invoke `Skill: arn-code:arn-code-sketch` with the feature description and architect assessment. After the sketch session, continue to Step 2c.
If **No, proceed with implementation**: continue to Step 2c.

**Follow-up (only when preference was null):** After the user answers the gate, ask:

Ask (using `AskUserQuestion`):

**"Should Arness remember this choice for future sessions?"**

Options:
1. **Yes, always offer sketch for interface work** (saves `always` to preferences)
2. **Yes, never offer sketch** (saves `never` to preferences)
3. **No, ask me each time**

If **Yes (always)**: Write `always` to `~/.arness/workflow-preferences.yaml` under `pipeline.sketch-preview`. Create `~/.arness/` directory and file if they do not exist. If the file already exists, read it first, add or update the key under `pipeline:`, and write back preserving all existing keys.
If **Yes (never)**: Write `never` to `~/.arness/workflow-preferences.yaml` under `pipeline.sketch-preview` (same write logic).
If **No**: Write `ask` to `~/.arness/workflow-preferences.yaml` under `pipeline.sketch-preview` (same write logic).

---

### Step 2c: Load Sketch Manifest (Conditional)

After Step 2b completes (or is skipped), check for a sketch manifest to load. This step is silent -- do not present it as a formal step to the user. If no sketch exists, skip entirely with no output.

**Path A -- Sketch session just completed (Step 2b returned):**

If the user chose "Yes, sketch first" in Step 2b and the sketch session completed:

1. Read `arness-sketches/[feature-name]/sketch-manifest.json`.
2. Check the manifest `status` field:
   - If status is `"kept"` and `componentMapping` is a non-empty array: Load `componentMapping` and `composition` from the manifest. Hold the loaded data for use in Steps 4A/4B.
   - If status is `"promoted"`: The sketch components were already copied to the real codebase during the sketch session. Skip sketch-aware promotion in Steps 4A/4B -- the files already exist. Inform the user: "The sketch was already promoted -- its components are in your codebase. I will implement around them."
   - If status is `"consumed"`: All components were already promoted by a previous execution. Skip sketch-aware logic entirely.
   - If status is `"draft"` or `componentMapping` is empty: The sketch was not finalized -- skip sketch-aware promotion and proceed normally.

**Path B -- Step 2b skipped or declined:**

If Step 2b was skipped (no interface work detected) or the user declined the sketch offer, independently scan for a previous-session sketch:

1. Check if a `arness-sketches/` directory exists in the project root.
2. If it exists, scan for subdirectories containing a `sketch-manifest.json`.
3. For each manifest found, read it and check if `featureName` fuzzy-matches the current feature description (case-insensitive substring match on key terms). Then evaluate `status`:

   - If `status` is `"kept"` and `componentMapping` is a non-empty array: This manifest is eligible for promotion. Inform the user briefly:

     "Found an existing sketch for this feature at `arness-sketches/[feature-name]/` with [N] mapped components. I'll use this to promote validated components during implementation."

     Load `componentMapping` and `composition` from the matching manifest.

   - If `status` is `"promoted"`: Inform the user: "Found a previously promoted sketch for this feature at `arness-sketches/[feature-name]/`. The components were already placed in your codebase -- I will implement around them." Do not load `componentMapping` (promotion already happened).

   - If `status` is `"consumed"`: Inform the user: "Found a fully consumed sketch for this feature. All components were already promoted." Do not load `componentMapping`.

   - If `status` is `"draft"` or `componentMapping` is empty: The sketch was not finalized -- skip it silently.

4. If multiple manifests with status `"kept"` match, present the matches and let the user choose which one to use (or none).
5. If no match is found, proceed normally without sketch context.

Hold the loaded sketch context (manifest path, componentMapping, composition) for Steps 4A/4B. If no sketch was loaded, all downstream sketch-aware logic is skipped silently.

---

### Step 3: Complexity Assessment (Internal Decision)

This is an internal assessment. Do NOT present it as a formal step.

Evaluate the change against 6 complexity criteria. Each criterion rates as simple, moderate, or complex.

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-swift/references/complexity-criteria.md` for the full criteria definitions, routing conditions, and edge case handling.

**Core routing rules:**

- **5-6 "simple" ratings AND architect approved** --> Step 4A (Simple path)
- **3-4 "simple" ratings OR architect flagged non-blocking concerns** --> Step 4B (Moderate path)
- **Any single criterion "complex" but rest are simple/moderate (isolated complexity)** --> Step 4B (Moderate path)
- **3+ "complex" ratings OR architect flagged architectural risk** --> Step 4C (Complex redirect)

See the reference for additional edge cases (borderline routing, user overrides).

---

### Step 4A: Simple Path (Direct Execution)

For straightforward changes touching 1-3 files with no cross-cutting concerns.

#### 1. Write the swift plan

Auto-generate a project name from the description (e.g., `SWIFT_rate-limiting-api-users`). Create the project folder:

```bash
mkdir -p <plans-dir>/SWIFT_<name>
```

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-swift/references/swift-plan-template.md` for the plan template.

**Sketch annotation (conditional):** If `componentMapping` was loaded in Step 2c, add a "Sketch Source" column to the "Files to Modify" table in the plan. For each file in the deliverables, check if it appears as a `targetFile` in `componentMapping`. If it does, show the sketch source file and promotion mode:

| File | Action | Rationale | Sketch Source |
|------|--------|-----------|---------------|
| `src/components/ProfileForm.tsx` | Create | Profile editing form | `arness-sketches/settings/components/ProfileForm.tsx` (refine) |
| `src/components/NotificationToggle.tsx` | Create | Notification preferences | `arness-sketches/settings/components/NotificationToggle.tsx` (direct) |
| `src/utils/validation.ts` | Modify | Add form validators | -- |

Files without a sketch match show `--` in the Sketch Source column. If no `componentMapping` was loaded, omit the Sketch Source column entirely (standard plan format).

Write the plan to `<plans-dir>/SWIFT_<name>/SWIFT_<name>.md`. Present it to the user for approval.

#### 2. User approval

Wait for the user to approve, adjust, or reject the plan. If the user adjusts, update the plan file and re-present.

#### 3. Execute in the current session

**Sketch-aware promotion (conditional):** If `componentMapping` was loaded in Step 2c, check for sketch matches before implementing each file. For each file in the plan:

1. **Check componentMapping** for an entry where `targetFile` matches the file about to be created or modified.

2. **If match found -- promote from sketch:**
   - **Direct mode** (`mode: "direct"`): Read the sketch file from `sketchFile` path. Copy its content to the `targetFile` location. Rewrite import paths from the sketch namespace (`arness-sketches/...`) to the real codebase paths. Remove any sketch-specific markers or comments (e.g., `// SKETCH:`, `# arness-sketch`). After import path rewriting and sketch marker removal, the component requires no further implementation changes — it is display-only and validated as-is.
   - **Refine mode** (`mode: "refine"`): Read the sketch file from `sketchFile` path. Copy its content to the `targetFile` location. Rewrite import paths. Remove sketch markers. Then: replace mock/hardcoded data with real data sources, wire actual state management, add error handling, connect real API endpoints. Use `composition.blueprint` as assembly context -- read the blueprint file to understand how components fit together, their data flow (`composition.dataFlow`), and interaction sequence (`composition.interactionSequence`).

3. **If no match -- implement from scratch:** Follow the standard implementation flow using patterns from code-patterns.md.

4. **After all files are implemented:** If any components were promoted, update `sketch-manifest.json`:
   - If ALL components in `componentMapping` were promoted, set `status` to `"consumed"`.
   - If only some were promoted, leave `status` unchanged (partial promotion). This enables progressive consumption — if a swift run only touches 3 of 8 mapped components, a subsequent swift or execute-plan run can promote the remaining 5.

If `componentMapping` was not loaded, implement all files from scratch as normal (no behavioral change).

**Write smoke tests:** After implementation (with or without promotion), read the plan's Test Plan section:

- **Tests to Update:** For each entry in the "Tests to Update" table, read the existing test file and apply the specified update (new assertions, changed expectations).
- **Tests to Add (Smoke Tests):** For each entry in the "Tests to Add" table, write a minimal smoke test that verifies the new behavior works at a basic level:
  - Test the happy path (expected input → expected output)
  - Test one obvious edge case (empty input, null, boundary value)
  - Follow test patterns from testing-patterns.md (framework, fixtures, naming conventions)
  - Place tests in the locations specified in the table

These are NOT comprehensive test suites — they catch obvious breaks with minimal overhead.

**Run all tests:** Run both the new smoke tests and existing targeted tests relevant to the changed files:
- If tests fail, self-heal: fix and re-run (up to 3 attempts per failing test)
- If a test fails 3 times on the same assertion, escalate to the user

#### 4. Generate SWIFT_REPORT.json

Read the `SWIFT_REPORT_TEMPLATE.json` from the template path configured in `## Arness`. Populate with: change details, patterns followed, test results, and architect assessment.

**Sketch promotion fields (conditional):** If sketch promotion occurred during execution, add these fields to the report:

- `sketchManifest`: path to the sketch manifest file (e.g., `arness-sketches/settings/sketch-manifest.json`)
- `promotedComponents`: array of promoted component records, each with:
  ```json
  {
    "sketchFile": "arness-sketches/settings/components/ProfileForm.tsx",
    "targetFile": "src/components/settings/ProfileForm.tsx",
    "mode": "refine",
    "result": "promoted | skipped | failed"
  }
  ```
  Where `result` is `"promoted"` if the component was successfully promoted, `"skipped"` if the component was not needed for this change, or `"failed"` if promotion was attempted but failed (with details in the report's `warnings` array).
- `sketchStatus`: the final `status` value of the sketch manifest after promotion (e.g., `"consumed"`, `"kept"`)

If no sketch promotion occurred, omit these three fields entirely.

Save to: `<plans-dir>/SWIFT_<name>/SWIFT_REPORT.json`

#### 4a. Generate CHANGE_RECORD.json

Read `CHANGE_RECORD_TEMPLATE.json` from the template path configured in `## Arness`. Populate with:
- `recordType`: `"change-record"`
- `version`: `1`
- `ceremonyTier`: `"swift"`
- `projectName`: the project name derived from the description
- `changePath`: `<plans-dir>/SWIFT_<name>/`
- `timestamp`: current ISO 8601 timestamp
- `tierSelection`: `{ "recommended": "swift", "selected": "swift", "overrideReason": null }` (swift has no scope router — tier is implicit)
- `specRef`: `""` (swift has no spec)
- `planRef`: path to `SWIFT_<name>.md` (e.g., `<plans-dir>/SWIFT_<name>/SWIFT_<name>.md`)
- `reportRef`: path to `SWIFT_REPORT.json` (e.g., `<plans-dir>/SWIFT_<name>/SWIFT_REPORT.json`)
- `filesModified` / `filesCreated`: from the SWIFT_REPORT.json data
- `commitHash`: `""` (populated by arn-code-ship after commit)
- `commitMessage`: `""` (populated by arn-code-ship after commit)
- `review`: verdict and finding counts from the review step (if available at this point, otherwise populated after review)
- `sketchRef`: path to sketch manifest if sketch was used, `""` otherwise
- `nextSteps`: `[]` (populated by arn-code-ship after PR creation)

Write to: `<plans-dir>/SWIFT_<name>/CHANGE_RECORD.json`

If `CHANGE_RECORD_TEMPLATE.json` is not found, generate a minimal CHANGE_RECORD with the core fields (`recordType`, `ceremonyTier`, `projectName`, `changePath`, `timestamp`) and warn the user.

#### 4b. Simplification (optional)

After the report and change record are generated:

**Preference check:** Read `pipeline.simplification` using the two-tier lookup chain (see `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-ensure-config/references/preferences-schema.md`):

1. Read `.arness/workflow.local.yaml` — if the file exists and `pipeline.simplification` is present, use that value and note source.
2. If not found, read `~/.arness/workflow-preferences.yaml` — if the file exists and `pipeline.simplification` is present, use that value and note source.
3. If neither found or key is absent, treat as null (first encounter).

Branch on the resolved value:

- If `always`: Show status line: "Preference: running simplification pass ([source])". Auto-proceed to invoke `Skill: arn-code:arn-code-simplify`. After simplification completes, proceed to review.

- If `skip`: Show status line: "Preference: skipping simplification ([source])". Auto-proceed directly to review.

- If `ask`: Present the gate below. Do NOT show the "remember this?" follow-up afterward.

- If null (or invalid value): Present the gate below. After the user answers, show the "remember this?" follow-up (see below).

**Gate (shown when value is `ask`, null, or invalid):**

Ask (using `AskUserQuestion`):

**"Would you like to check for simplification opportunities before review?"**

Options:
1. **Yes** -- Check for simplification opportunities
2. **Skip** -- Proceed directly to review

If **Yes**: invoke `Skill: arn-code:arn-code-simplify` (auto-detects swift scope from SWIFT_REPORT.json). The SIMPLIFICATION_REPORT.json is written to `<plans-dir>/SWIFT_<name>/SIMPLIFICATION_REPORT.json`.
If **Skip**: proceed directly to review.

**Follow-up (only when preference was null):** After the user answers the gate, ask:

Ask (using `AskUserQuestion`):

**"Should Arness remember this choice for future sessions?"**

Options:
1. **Yes, always [chosen action]** (saves to preferences)
2. **No, ask me each time**

If **Yes**: Write the chosen value (`always` or `skip`) to `~/.arness/workflow-preferences.yaml` under `pipeline.simplification`. Create `~/.arness/` directory and file if they do not exist. If the file already exists, read it first, add or update the key under `pipeline:`, and write back preserving all existing keys.
If **No**: Write `ask` to `~/.arness/workflow-preferences.yaml` under `pipeline.simplification` (same write logic).

#### 5. Lightweight review

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-swift/references/swift-review-checklist.md` for the review procedure and verdict logic.

Perform the review and record findings in the report's `review` section. Present the verdict to the user:
- **PASS** -- all checks green. Offer `/arn-code-ship`.
- **PASS WITH WARNINGS** -- minor deviations noted. Present warnings, then offer `/arn-code-ship`.
- **NEEDS FIXES** -- errors found. Present errors, offer to fix before shipping.

#### 6. Ship

Offer: "Run `/arn-code-ship` to commit and create a PR."

Note: Commit messages for swift-tier changes should include the `[swift]` tier tag. The `/arn-code-ship` skill reads `CHANGE_RECORD.json` to detect the tier and prepend the tag automatically.

---

### Step 4B: Moderate Path (Task-Tracked Execution)

For changes touching 4-8 files or involving 2-3 modules.

#### 1. Write the structured swift plan

Auto-generate a project name. Create the project folder:

```bash
mkdir -p <plans-dir>/SWIFT_<name>
```

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-swift/references/swift-plan-template.md` for the plan template.

The moderate plan includes numbered implementation tasks and test tasks.

**Sketch annotation (conditional):** Same as simple path -- if `componentMapping` was loaded in Step 2c, add a "Sketch Source" column to the "Files to Modify" table showing which files come from sketch and their promotion mode (direct/refine). Files without a sketch match show `--`. If no `componentMapping` was loaded, omit the column.

Write to `<plans-dir>/SWIFT_<name>/SWIFT_<name>.md`. Present it to the user.

#### 2. User approval

Wait for approval. If the user adjusts, update the plan and re-present.

#### 3. Create Claude Code tasks

Create tasks via TaskCreate (one per task in the plan). Wire dependencies so test tasks depend on implementation tasks.

#### 4. Execute tasks

Execute tasks in the current session (sequential execution with self-healing). For each task:

**Sketch-aware promotion (conditional):** Same promotion logic as the simple path (Step 4A, section 3). Before implementing each file within a task, check `componentMapping` for a matching `targetFile`. If found, promote from sketch using the appropriate mode (direct or refine), using `composition.blueprint` as assembly context for refine mode. If no match, implement from scratch.

After all tasks complete: if any components were promoted, update `sketch-manifest.json` status to `"consumed"` (if all components promoted) or leave unchanged (if partial).

If `componentMapping` was not loaded, implement all files from scratch as normal (no behavioral change).

**Standard execution continues for each task:**
- Implement following the patterns from code-patterns.md (with sketch promotion applied per-file as described above)
- Mark task complete when implementation is done

**Write smoke tests:** After all tasks are implemented, read the plan's Test Plan section:
- **Tests to Update:** Apply the specified updates to existing test files.
- **Tests to Add (Smoke Tests):** Write a minimal smoke test for each entry — happy path + one edge case. Follow testing-patterns.md conventions.

**Run all tests:** Run smoke tests + existing targeted tests. Self-heal failures (up to 3 attempts per failing test). Escalate after 3 failures on the same assertion.

#### 5. Generate SWIFT_REPORT.json

Same as Simple path Step 4. Read the template, populate, save to `<plans-dir>/SWIFT_<name>/SWIFT_REPORT.json`.

**Sketch promotion fields (conditional):** Same as simple path -- if sketch promotion occurred, include `sketchManifest`, `promotedComponents`, and `sketchStatus` fields in the report. If no sketch promotion occurred, omit these fields.

#### 5a. Generate CHANGE_RECORD.json

Same as simple path Step 4a. Read `CHANGE_RECORD_TEMPLATE.json` from the template path. Populate all fields identically (same schema, same `ceremonyTier: "swift"`).

Write to: `<plans-dir>/SWIFT_<name>/CHANGE_RECORD.json`

#### 5b. Simplification (optional)

After the report and change record are generated:

**Preference check:** Read `pipeline.simplification` using the two-tier lookup chain (see `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-ensure-config/references/preferences-schema.md`):

1. Read `.arness/workflow.local.yaml` — if the file exists and `pipeline.simplification` is present, use that value and note source.
2. If not found, read `~/.arness/workflow-preferences.yaml` — if the file exists and `pipeline.simplification` is present, use that value and note source.
3. If neither found or key is absent, treat as null (first encounter).

Branch on the resolved value:

- If `always`: Show status line: "Preference: running simplification pass ([source])". Auto-proceed to invoke `Skill: arn-code:arn-code-simplify`. After simplification completes, proceed to review.

- If `skip`: Show status line: "Preference: skipping simplification ([source])". Auto-proceed directly to review.

- If `ask`: Present the gate below. Do NOT show the "remember this?" follow-up afterward.

- If null (or invalid value): Present the gate below. After the user answers, show the "remember this?" follow-up (see below).

**Gate (shown when value is `ask`, null, or invalid):**

Ask (using `AskUserQuestion`):

**"Would you like to check for simplification opportunities before review?"**

Options:
1. **Yes** -- Check for simplification opportunities
2. **Skip** -- Proceed directly to review

If **Yes**: invoke `Skill: arn-code:arn-code-simplify` (auto-detects swift scope from SWIFT_REPORT.json). The SIMPLIFICATION_REPORT.json is written to `<plans-dir>/SWIFT_<name>/SIMPLIFICATION_REPORT.json`.
If **Skip**: proceed directly to review.

**Follow-up (only when preference was null):** After the user answers the gate, ask:

Ask (using `AskUserQuestion`):

**"Should Arness remember this choice for future sessions?"**

Options:
1. **Yes, always [chosen action]** (saves to preferences)
2. **No, ask me each time**

If **Yes**: Write the chosen value (`always` or `skip`) to `~/.arness/workflow-preferences.yaml` under `pipeline.simplification`. Create `~/.arness/` directory and file if they do not exist. If the file already exists, read it first, add or update the key under `pipeline:`, and write back preserving all existing keys.
If **No**: Write `ask` to `~/.arness/workflow-preferences.yaml` under `pipeline.simplification` (same write logic).

#### 6. Lightweight review

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-swift/references/swift-review-checklist.md` for the review procedure and verdict logic.

Same review procedure as the simple path. Record findings in the report's `review` section. Present the verdict.

If **NEEDS FIXES**: present the errors, offer to fix them. After fixes, re-run the review.

#### 6b. Pattern refresh (auto)

After the review completes, refresh stored pattern documentation to capture any new patterns introduced by this moderate-path implementation.

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-execute-plan/references/pattern-refresh.md` and follow the pattern refresh procedure.

This is automatic and non-blocking. If the refresh fails, proceed to ship without blocking.

#### 7. Ship

Offer: "Run `/arn-code-ship` to commit and create a PR."

Note: Commit messages for swift-tier changes should include the `[swift]` tier tag. The `/arn-code-ship` skill reads `CHANGE_RECORD.json` to detect the tier and prepend the tag automatically.

---

### Step 4C: Complex Redirect

The change is too complex for arn-code-swift. Inform the user:

"This change is more complex than a swift implementation -- [reason from architect assessment]. I recommend the full feature pipeline:

Run `/arn-code-feature-spec` to develop a detailed specification, then `/arn-code-plan` to create a phased implementation plan."

Offer to seed the feature-spec conversation with the context gathered so far (the architect's assessment, the user's description, the pattern documentation loaded in Step 1).

**If the user insists on swift despite the complexity warning:** Proceed with the moderate path (Step 4B) but add a warning to the plan: "Architectural risk noted -- consider full pipeline review after completion." Record this override in the report's `warnings` array.

---

## Artifacts

Both paths (simple + moderate) always produce exactly three artifacts in `<plans-dir>/SWIFT_<name>/`:

| Artifact | File | Purpose |
|----------|------|---------|
| Swift plan | `SWIFT_<name>.md` | Implementation plan with files, patterns, tests, risks |
| Swift report | `SWIFT_REPORT.json` | Execution report with review findings and verdict |
| Change record | `CHANGE_RECORD.json` | Unified envelope with tier, refs, and file lists for downstream tools |

No spec, no INTRODUCTION.md, no PROGRESS_TRACKER. The plan, report, and change record are sufficient for audit and traceability.

The report's `changePath` field should contain the artifact directory path: `<plans-dir>/SWIFT_<name>/`.

---

## Error Handling

- **`## Arness` config missing** -- Handled by Step 0 (ensure-config) — this should not occur if Step 0 completed successfully.
- **Pattern docs missing** -- Handled by the first-run messaging in Step 1 (one-time pattern generation).
- **Architect assessment inconclusive** -- present what is known, ask the user to clarify scope. Proceed with available information.
- **User says "just do it" during assessment** -- skip to simple path with warning: "Proceeding without full assessment. Pattern compliance may be incomplete." Record the warning in the report.
- **Tests fail after implementation** -- self-heal (fix and re-run, up to 3 attempts per failing test). If the same test fails 3 times, escalate to the user with details.
- **User changes mind mid-execution** -- show what has been done so far, offer to revert uncommitted changes or continue with adjustments.
- **Complex redirect rejected** -- user insists on swift despite complexity. Proceed with moderate path but add architectural risk warning to the plan and report.
- **SWIFT_REPORT_TEMPLATE.json missing** -- if the template file does not exist at the configured template path, generate the report with a minimal structure (reportType, projectName, status, filesModified) and warn the user.
- **Plan or report write fails** -- print the content in the conversation so the user can save manually. Suggest checking permissions on the plans directory.
