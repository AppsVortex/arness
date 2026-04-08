---
name: arn-code-standard
description: >-
  This skill should be used when the user says "standard", "standard mode",
  "standard implementation", "arn-code-standard", "standard change",
  "medium change", "standard feature", "standard fix",
  or wants a mid-ceremony implementation for a change that needs lightweight
  architectural context (spec-lite) and task-tracked execution but not the full
  feature-spec/plan pipeline. Bridges the gap between arn-code-swift and the
  full thorough pipeline. Includes spec-lite generation, structured plan,
  in-session execution, review-lite, and a unified change record.
version: 1.0.0
---

# Arness Standard

Implement medium-complexity features and enhancements through a mid-ceremony, pattern-aware workflow: spec-lite generation, structured plan, task-tracked execution, verification, review-lite, and unified change record -- all in a single session. Every standard implementation produces three artifacts in `<plans-dir>/STANDARD_<name>/`: a plan (`STANDARD_<name>.md`), a report (`STANDARD_REPORT.json`), and a change record (`CHANGE_RECORD.json`), giving robust auditability with less overhead than the full thorough pipeline.

This skill follows the same execution model as arn-code-swift's moderate path but adds a Spec-Lite front-end (lightweight architectural specification) and a unified CHANGE_RECORD.json envelope for downstream consumption.

This is an execution skill. It runs in normal conversation (NOT plan mode).

## Step 0: Ensure Configuration

Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-ensure-config/references/ensure-config.md` and follow its instructions. This guarantees a user profile exists and `## Arness` is configured with Arness Code fields before proceeding.

## Pipeline Position

```
              arn-code-standard (this skill)
              ============================
              For medium-complexity changes
              routed here by the scope router

Entry:  arn-planning (scope router) --> standard tier
          |
          v
        arn-implementing --> arn-code-standard
          |
          v
        Spec-Lite --> Plan --> Execute --> Report --> Review-Lite --> Change Record --> Ship
          |
          v
        <plans-dir>/STANDARD_<name>/
        +-- STANDARD_<name>.md      (plan with spec-lite)
        +-- STANDARD_REPORT.json    (execution report)
        +-- CHANGE_RECORD.json      (unified envelope)
```

## Workflow

### Step 1: Capture and Load Context

1. Accept the user's description. This can be anything from a sentence ("add rate limiting to /api/users") to detailed requirements. If the user already provided the description in their trigger message, use that directly without asking again.

2. Confirm understanding with a brief restatement (1-2 sentences).

3. Read the project's CLAUDE.md and extract the `## Arness` section to find:
   - Code patterns path
   - Plans directory
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

### Step 2: Spec-Lite Generation

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

**Specific question:** "Standard-tier assessment for this change: (1) Problem statement -- what problem does this solve in 1-2 sentences? (2) Key requirements -- what are the 3-7 concrete, verifiable requirements? (3) Which files need modification and why? (4) Which codebase patterns apply? (5) Architectural notes -- how does this change fit the existing architecture? What modules, integration points, and constraints are involved? (6) Are there architectural risks or concerns? (7) Does this change need UI work? (8) Are there security implications?"

**For `arn-code-ux-specialist` (when dispatched), provide:** The same feature description and ui-patterns.md. Specific question: "Quick UI assessment: which components are affected? Any accessibility considerations?"

**For `arn-code-security-specialist` (when dispatched), provide:** A brief security assessment request with the feature description and security-patterns.md.

#### 2c. False-negative follow-up

After all parallel agents complete, check the architect's assessment for signals that a missed specialist should have been included:

- If `ui_involved` was false AND the architect's output mentions UI concerns, component design, user interaction, or interface layout: dispatch `arn-code-ux-specialist` sequentially with the architect's assessment as additional context.
- If `security_relevant` was false AND the architect's output mentions security concerns, authentication, authorization, data protection, or vulnerability: dispatch `arn-code-security-specialist` sequentially with the architect's assessment as additional context.

The follow-up dispatch is silent -- no user notification or status message. The user sees the combined Spec-Lite from all agents (parallel + sequential) as a single result.

#### 2d. Present the Spec-Lite

Present the Spec-Lite to the user, structured as:

1. **Problem Statement** (1-2 sentences)
2. **Key Requirements** (3-7 bullet points)
3. **Architectural Notes** (2-5 sentences on how this fits the codebase)
4. **Files to modify** (with paths and rationale)
5. **Applicable patterns** from code-patterns.md
6. **Risks or concerns** (if any)
7. **UI and security notes** (if applicable)

Ask (using `AskUserQuestion`):

**"Does this spec-lite capture the change correctly?"**

Options:
1. **Yes, proceed** -- Continue to plan generation
2. **Adjust** -- Let me refine the requirements
3. **Too complex -- use full pipeline** -- Redirect to `/arn-code-feature-spec`

If **Yes, proceed**: continue to Step 2b.
If **Adjust**: let the user refine, update the spec-lite, and re-present.
If **Too complex**: inform the user and suggest running `/arn-code-feature-spec` to develop a detailed specification. Offer to seed the feature-spec conversation with the context gathered so far.

---

### Step 2b: Arness-Sketch Offer (Conditional)

After the spec-lite is confirmed, check the sketch-preview preference before deciding whether to present the sketch offer.

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
   - If status is `"kept"` and `componentMapping` is a non-empty array: Load `componentMapping` and `composition` from the manifest. Hold the loaded data for use in Step 4.
   - If status is `"promoted"`: The sketch components were already copied to the real codebase during the sketch session. Skip sketch-aware promotion in Step 4 -- the files already exist. Inform the user: "The sketch was already promoted -- its components are in your codebase. I will implement around them."
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

Hold the loaded sketch context (manifest path, componentMapping, composition) for Step 4. If no sketch was loaded, all downstream sketch-aware logic is skipped silently.

---

### Step 3: Standard Plan Generation

Auto-generate a project name from the description (e.g., `STANDARD_rate-limiting-api-users`). Create the project folder:

```bash
mkdir -p <plans-dir>/STANDARD_<name>
```

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-standard/references/standard-plan-template.md` for the plan template.

Generate the standard plan using the template. The plan includes:
- The Spec-Lite section (problem statement, key requirements, architectural notes from Step 2)
- Files to Modify table (from architect assessment)
- Patterns to Follow table (from code-patterns.md)
- Implementation Tasks (numbered, with clear deliverables -- always present for standard tier)
- Test Plan (tests to update, tests to add, verification command)
- Risks & Mitigations (from architect assessment)
- Review-Lite criteria

**Sketch annotation (conditional):** If `componentMapping` was loaded in Step 2c, add a "Sketch Source" column to the "Files to Modify" table in the plan. For each file in the deliverables, check if it appears as a `targetFile` in `componentMapping`. If it does, show the sketch source file and promotion mode:

| File | Action | Rationale | Sketch Source |
|------|--------|-----------|---------------|
| `src/components/ProfileForm.tsx` | Create | Profile editing form | `arness-sketches/settings/components/ProfileForm.tsx` (refine) |
| `src/components/NotificationToggle.tsx` | Create | Notification preferences | `arness-sketches/settings/components/NotificationToggle.tsx` (direct) |
| `src/utils/validation.ts` | Modify | Add form validators | -- |

Files without a sketch match show `--` in the Sketch Source column. If no `componentMapping` was loaded, omit the Sketch Source column entirely (standard plan format).

Write the plan to `<plans-dir>/STANDARD_<name>/STANDARD_<name>.md`.

Present the plan to the user for approval.

Ask (using `AskUserQuestion`):

**"Does this plan look good?"**

Options:
1. **Approve** -- Start execution
2. **Adjust** -- Let me refine the plan
3. **Cancel** -- Abandon this change

If **Approve**: continue to Step 4.
If **Adjust**: let the user refine, update the plan file, and re-present.
If **Cancel**: inform the user the standard session is cancelled. No artifacts are written beyond the draft plan (which can be deleted).

---

### Step 4: Execution (Task-Tracked, In-Session)

Execute the implementation tasks from the plan sequentially in the current session.

For each task in the plan:

**Sketch-aware promotion (conditional):** If `componentMapping` was loaded in Step 2c, check for sketch matches before implementing each file within the task:

1. **Check componentMapping** for an entry where `targetFile` matches the file about to be created or modified.

2. **If match found -- promote from sketch:**
   - **Direct mode** (`mode: "direct"`): Read the sketch file from `sketchFile` path. Copy its content to the `targetFile` location. Rewrite import paths from the sketch namespace (`arness-sketches/...`) to the real codebase paths. Remove any sketch-specific markers or comments (e.g., `// SKETCH:`, `# arness-sketch`). After import path rewriting and sketch marker removal, the component requires no further implementation changes -- it is display-only and validated as-is.
   - **Refine mode** (`mode: "refine"`): Read the sketch file from `sketchFile` path. Copy its content to the `targetFile` location. Rewrite import paths. Remove sketch markers. Then: replace mock/hardcoded data with real data sources, wire actual state management, add error handling, connect real API endpoints. Use `composition.blueprint` as assembly context -- read the blueprint file to understand how components fit together, their data flow (`composition.dataFlow`), and interaction sequence (`composition.interactionSequence`).

3. **If no match -- implement from scratch:** Follow the standard implementation flow using patterns from code-patterns.md.

4. **After all tasks are executed:** If any components were promoted, update `sketch-manifest.json`:
   - If ALL components in `componentMapping` were promoted, set `status` to `"consumed"`.
   - If only some were promoted, leave `status` unchanged (partial promotion).

If `componentMapping` was not loaded, implement all files from scratch as normal (no behavioral change).

**Standard execution continues for each task:**
- Implement following the patterns from code-patterns.md (with sketch promotion applied per-file as described above)
- Run targeted tests relevant to the changed files after each task to catch immediate regressions
- If tests fail, self-heal: fix and re-run (up to 3 attempts per failing test)
- If a test fails 3 times on the same assertion, escalate to the user

**Write tests from plan:** After all implementation tasks are complete, read the plan's Test Plan section:

1. **Tests to Update:** For each entry in the "Tests to Update" table, read the existing test file and apply the specified update (new assertions, changed expectations, additional test cases).

2. **Tests to Add:** For each entry in the "Tests to Add" table, write the new test following test patterns from testing-patterns.md (framework, fixtures, naming conventions, markers). Each test should cover the scenario described in the table.

3. **Run all tests:** Run the verification command from the plan's Test Plan section. This runs both updated and new tests alongside existing tests.
   - If tests fail, self-heal: investigate the failure, fix the implementation or test, re-run (up to 3 attempts per failing test)
   - If a test fails 3 times on the same assertion, escalate to the user
   - Only proceed to the next step when ALL tests pass

---

### Step 5: Generate STANDARD_REPORT.json

Read the `STANDARD_REPORT_TEMPLATE.json` from the template path configured in `## Arness`. If the template file does not exist at the configured template path, read it from `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-save-plan/report-templates/default/STANDARD_REPORT_TEMPLATE.json`.

Populate with:
- `reportType`: `"standard"`
- `ceremonyTier`: `"standard"`
- `projectName`: the project name
- `changeTitle`: the change title from the plan
- `changePath`: `<plans-dir>/STANDARD_<name>/`
- `reportDate`: current ISO 8601 date
- `summary`: brief summary of what was implemented
- `specLite`: the spec-lite from Step 2 (problem statement, requirements, architectural notes)
- `tierSelection`: the tier recommendation from the scope router (recommended, selected, overrideReason)
- `architectAssessment`: from Step 2 (files identified, patterns applicable, concerns, UI/security flags)
- `implementation`: files created, files modified, patterns followed
- `testing`: tests updated, tests added, test run results
- `review`: populated in Step 6 (leave empty for now)
- `changeRecordRef`: `<plans-dir>/STANDARD_<name>/CHANGE_RECORD.json`
- `warnings`: any warnings accumulated during execution
- `nextSteps`: suggested follow-up actions

**Sketch promotion fields (conditional):** If sketch promotion occurred during execution, add these fields to the report:

- `sketchManifest`: path to the sketch manifest file
- `promotedComponents`: array of promoted component records, each with:
  ```json
  {
    "sketchFile": "arness-sketches/feature/components/Component.tsx",
    "targetFile": "src/components/Component.tsx",
    "mode": "refine",
    "result": "promoted | skipped | failed"
  }
  ```
- `sketchStatus`: the final `status` value of the sketch manifest after promotion

If no sketch promotion occurred, omit these three fields entirely.

Save to: `<plans-dir>/STANDARD_<name>/STANDARD_REPORT.json`

---

### Step 5b: Simplification (Optional)

After the report is generated:

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

If **Yes**: invoke `Skill: arn-code:arn-code-simplify` (auto-detects standard scope from STANDARD_REPORT.json). The SIMPLIFICATION_REPORT.json is written to `<plans-dir>/STANDARD_<name>/SIMPLIFICATION_REPORT.json`.
If **Skip**: proceed directly to review.

**Follow-up (only when preference was null):** After the user answers the gate, ask:

Ask (using `AskUserQuestion`):

**"Should Arness remember this choice for future sessions?"**

Options:
1. **Yes, always [chosen action]** (saves to preferences)
2. **No, ask me each time**

If **Yes**: Write the chosen value (`always` or `skip`) to `~/.arness/workflow-preferences.yaml` under `pipeline.simplification`. Create `~/.arness/` directory and file if they do not exist. If the file already exists, read it first, add or update the key under `pipeline:`, and write back preserving all existing keys.
If **No**: Write `ask` to `~/.arness/workflow-preferences.yaml` under `pipeline.simplification` (same write logic).

---

### Step 6: Review-Lite

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-swift/references/swift-review-checklist.md` for the review procedure and verdict logic.

Perform the review following the shared swift-review-checklist procedure. The review covers:

1. **Pattern compliance** -- spot-check modified files against the patterns in the plan
2. **Test verification** -- run the verification command from the plan's test section
3. **Architect concern resolution** -- verify each concern from Step 2 was addressed
4. **Spec-Lite alignment** -- verify the implementation satisfies all key requirements from the Spec-Lite

Record findings in the STANDARD_REPORT.json's `review` section. For Spec-Lite alignment findings, use the `specLiteAlignment` array:

```json
{
  "requirement": "The requirement text",
  "satisfied": true,
  "notes": "How it was satisfied or why not"
}
```

Present the verdict to the user:
- **PASS** -- all checks green. Offer to proceed to change record generation.
- **PASS WITH WARNINGS** -- minor deviations noted. Present warnings, then offer to proceed.
- **NEEDS FIXES** -- errors found. Present errors, offer to fix before proceeding.

If **NEEDS FIXES**: present the errors, offer to fix them. After fixes, re-run the review. Repeat until the verdict is PASS or PASS WITH WARNINGS.

---

### Step 6b: Pattern Refresh (auto)

After the review completes, refresh stored pattern documentation to capture any new patterns introduced by this standard-tier implementation.

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-execute-plan/references/pattern-refresh.md` and follow the pattern refresh procedure.

This is automatic and non-blocking. If the refresh fails, proceed to change record generation without blocking.

---

### Step 7: Generate CHANGE_RECORD.json

Read the `CHANGE_RECORD_TEMPLATE.json` from the template path configured in `## Arness`. If the template file does not exist at the configured template path, read it from `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-save-plan/report-templates/default/CHANGE_RECORD_TEMPLATE.json`.

Populate with:
- `recordType`: `"change-record"`
- `version`: `1`
- `ceremonyTier`: `"standard"`
- `projectName`: the project name
- `changePath`: `<plans-dir>/STANDARD_<name>/`
- `timestamp`: current ISO 8601 timestamp
- `tierSelection`: the tier selection from the scope router (recommended, selected, overrideReason)
- `specRef`: `<plans-dir>/STANDARD_<name>/STANDARD_<name>.md` (the plan contains the spec-lite)
- `planRef`: `<plans-dir>/STANDARD_<name>/STANDARD_<name>.md`
- `reportRef`: `<plans-dir>/STANDARD_<name>/STANDARD_REPORT.json`
- `filesModified`: list of all modified files
- `filesCreated`: list of all created files
- `commitHash`: empty (populated by arn-code-ship after commit)
- `commitMessage`: empty (populated by arn-code-ship after commit)
- `review`: verdict and finding counts from Step 6
- `sketchRef`: path to sketch manifest if sketch was used, empty string otherwise
- `nextSteps`: suggested follow-up actions

Save to: `<plans-dir>/STANDARD_<name>/CHANGE_RECORD.json`

---

### Step 8: Ship Offer

Present the completion summary:

"Standard implementation complete. Three artifacts generated:
- Plan: `<plans-dir>/STANDARD_<name>/STANDARD_<name>.md`
- Report: `<plans-dir>/STANDARD_<name>/STANDARD_REPORT.json`
- Change Record: `<plans-dir>/STANDARD_<name>/CHANGE_RECORD.json`

Run `/arn-code-ship` to commit and create a PR."

---

## Artifacts

Every standard implementation produces exactly three artifacts in `<plans-dir>/STANDARD_<name>/`:

| Artifact | File | Purpose |
|----------|------|---------|
| Standard plan | `STANDARD_<name>.md` | Implementation plan with spec-lite, files, patterns, tasks, tests, risks, review criteria |
| Standard report | `STANDARD_REPORT.json` | Execution report with spec-lite, tier selection, review findings, and verdict |
| Change record | `CHANGE_RECORD.json` | Unified envelope for downstream tools (arn-code-ship, artifact index) |

The plan's Spec-Lite section serves as the lightweight specification -- no separate spec file is generated.

The report's `changePath` field should contain the artifact directory path: `<plans-dir>/STANDARD_<name>/`.

---

## Error Handling

- **`## Arness` config missing** -- Handled by Step 0 (ensure-config) — this should not occur if Step 0 completed successfully.
- **Pattern docs missing** -- Handled by the first-run messaging in Step 1 (one-time pattern generation).
- **Architect assessment inconclusive** -- present what is known, ask the user to clarify scope. Proceed with available information.
- **User says "just do it" during spec-lite** -- generate a minimal spec-lite from the description alone and note in the report that the architect assessment was skipped. Add a warning: "Spec-lite generated without full architect review."
- **Spec-lite rejected as too complex** -- redirect to `/arn-code-feature-spec` with context seeding.
- **Tests fail after implementation** -- self-heal (fix and re-run, up to 3 attempts per failing test). If the same test fails 3 times, escalate to the user with details.
- **User changes mind mid-execution** -- show what has been done so far, offer to revert uncommitted changes or continue with adjustments.
- **Review-Lite finds NEEDS FIXES** -- present the errors with specific guidance. Offer to fix, then re-run the review.
- **STANDARD_REPORT_TEMPLATE.json missing** -- if the template file does not exist at the configured template path, generate the report with a minimal structure (reportType, projectName, status, filesModified) and warn the user.
- **CHANGE_RECORD_TEMPLATE.json missing** -- if the template file does not exist, generate the change record with the core fields (recordType, ceremonyTier, projectName, changePath, timestamp) and warn the user.
- **Plan or report write fails** -- print the content in the conversation so the user can save manually. Suggest checking permissions on the plans directory.
