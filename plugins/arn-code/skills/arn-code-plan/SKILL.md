---
name: arn-code-plan
description: >-
  This skill should be used when the user says "arness code plan", "arn-code-plan",
  "plan this",
  "write a plan", "create plan", "implementation plan", "plan feature",
  "plan the spec", "plan from spec", "generate plan", "arness code plan FEATURE_X",
  "plan the bugfix", "plan bugfix", "make a plan",
  or wants to generate an implementation plan from a Arness specification.
  The skill invokes the arn-code-feature-planner agent to generate the plan,
  presents it for review, and iterates on user feedback until approved.
  Produces a PLAN_PREVIEW file that feeds into /arn-code-save-plan.
version: 1.1.0
---

# Arness Plan

Generate an implementation plan from a Arness specification by invoking the `arn-code-feature-planner` agent. The plan is written to disk as a PLAN_PREVIEW file, presented to the user for review, and iteratively refined based on feedback until approved. The approved plan then feeds into `/arn-code-save-plan` for structuring into phases, tasks, and reports.

Pipeline position:
```
arn-code-init -> arn-code-feature-spec / arn-code-bug-spec -> **arn-code-plan** -> arn-code-save-plan -> arn-code-review-plan -> arn-code-taskify -> arn-code-execute-plan
```

## Prerequisites

If no `## Arness` section exists in the project's CLAUDE.md, inform the user: "Arness is not configured for this project yet. Run `/arn-planning` to get started — it will set everything up automatically." Do not proceed without it.

## Workflow

### Step 1: Load Configuration

Read the project's CLAUDE.md and extract the `## Arness` section to find:
- **Plans directory** — base path where project plans and PLAN_PREVIEW files are stored
- **Specs directory** — path to the directory containing specification files
- **Code patterns** — path to the directory containing stored pattern documentation

If `## Arness` is not found, inform the user: "Arness is not configured for this project yet. Run `/arn-planning` to get started — it will set everything up automatically." Do not proceed.

---

### Step 2: Find the Specification

The user may provide a spec name as an argument (e.g., "arness plan FEATURE_websocket-notifications" or "plan the spec websocket-notifications").

**If an argument was provided:**
- Look for `<specs-dir>/<argument>.md` (exact match)
- If not found, try `<specs-dir>/FEATURE_<argument>.md` and `<specs-dir>/BUGFIX_<argument>.md`
- If not found, try matching files in `<specs-dir>/` that contain the argument text in their filename
- If still not found, list available specs and ask the user to choose

**If no argument was provided:**
- List all `.md` files in `<specs-dir>/`
- If only one exists, use it automatically
- If multiple exist, show the list sorted by modification date (most recent first) and ask the user to choose
- If none exist, inform the user: "No specifications found in `<specs-dir>/`. Run `/arn-code-feature-spec` or `/arn-code-bug-spec` to create one first."

---

### Step 3: Load Context

Read these files (skip any that don't exist):
1. The selected specification file
2. `<code-patterns-dir>/code-patterns.md`
3. `<code-patterns-dir>/testing-patterns.md`
4. `<code-patterns-dir>/architecture.md`
5. `<code-patterns-dir>/ui-patterns.md` (if it exists)
6. `<code-patterns-dir>/security-patterns.md` (if it exists)

**If pattern documentation files are missing** (no `code-patterns.md`, `testing-patterns.md`, or `architecture.md` in the Code patterns directory):

Inform the user: "This is the first time pattern documentation is being generated for this project. Analyzing your codebase to understand its patterns, conventions, and architecture. This is a one-time operation — future invocations will use the cached results."

Then invoke `arn-code-codebase-analyzer` (existing codebase) or `arn-code-pattern-architect` (greenfield) to generate fresh analysis. Write the results to the Code patterns directory.

---

### Step 3.5: Verify Spec Alignment with Current Codebase

Specs may have been written days or weeks before being planned. The codebase moves in the meantime — files get renamed, modules refactored, frameworks swapped. Before invoking the planner, verify the spec's concrete references still hold against HEAD.

Spawn the `arn-code-drift-detector` agent via the Task tool, passing the model from `.arness/agent-models/code.md` as the `model` parameter (see `plugins/arn-code/skills/arn-code-ensure-config/references/ensure-config.md` "Dispatch convention" for fallback). Context:

```
Verify whether the following specification still aligns with the current codebase.

**Spec file:** <specs-dir>/<spec-filename>
**Source root:** <repo root>

Return a structured drift report with severity classified as none, minor, moderate, or major.
```

Capture the agent's drift report and branch on severity:

- **`none`** — proceed silently to Step 4.
- **`minor`** — display the report's `Summary` line to the user (one sentence). Carry the full drift report forward as an annotation to the planner agent's context (see Step 4 input block below). Proceed to Step 4.
- **`moderate` or `major`** — display the full drift report. Then ask the user how to proceed using `AskUserQuestion`:

  **The spec has drifted from the current codebase. How would you like to proceed?**
  1. **Refresh the spec** — route to `/arn-code-feature-spec` (or `/arn-code-bug-spec` for a bug spec) with the drift report as input so the spec can be updated against current reality.
  2. **Proceed with annotations** — pass the drift report to the planner so it accounts for the divergence while building the plan.
  3. **Abort** — exit the skill; no plan generated.

  Honor the user's choice. On (1), exit this skill and route to the spec skill. On (3), exit cleanly. On (2), continue to Step 4 with the drift report attached.

If the drift detector itself fails (e.g., spec file unreadable, git unavailable), inform the user and ask whether to proceed without a drift check. Do not block on a tool failure.

---

### Step 4: Invoke the Planner Agent

Derive the spec name from the spec filename (strip prefix and extension):
- `FEATURE_websocket-notifications.md` → `websocket-notifications`
- `BUGFIX_checkout-500.md` → `checkout-500`
- `FEATURE_F-001.1_user-auth.md` → `F-001.1_user-auth`

The output file path is: `<plans-dir>/PLAN_PREVIEW_<spec-name>.md`

**Check for existing PLAN_PREVIEW:** If a PLAN_PREVIEW file already exists at that path, inform the user: "A plan preview already exists for this spec: `<path>`. Would you like to regenerate it from scratch, or review the existing plan?" If review → skip to Step 5. If regenerate → proceed.

Spawn the `arn-code-feature-planner` agent via the Task tool, passing the model from `.arness/agent-models/code.md` as the `model` parameter (see `plugins/arn-code/skills/arn-code-ensure-config/references/ensure-config.md` "Dispatch convention" for fallback). Context:

```
You are generating an implementation plan for the following specification.

**Specification:** <spec-name>
**Spec file:** <specs-dir>/<spec-filename>

--- SPECIFICATION CONTENT ---
[full spec file content]
--- END SPECIFICATION ---

--- DRIFT REPORT ---
[full drift report from Step 3.5, if severity was minor/moderate/major and the user chose to proceed; omit this section entirely if severity was none]
--- END DRIFT REPORT ---

--- CODEBASE PATTERNS ---
[code-patterns.md content]
[testing-patterns.md content]
[architecture.md content]
[ui-patterns.md content, if it exists]
[security-patterns.md content, if it exists]
--- END CODEBASE PATTERNS ---

**Output file:** <plans-dir>/PLAN_PREVIEW_<spec-name>.md

Generate a structured implementation plan and write it to the output file.
Include `Spec: <specs-dir>/<spec-filename>` near the top for arn-code-save-plan linkage.
```

Record the agent ID returned by the Task tool (needed for resume in Step 5b).

---

### Step 5: Present Plan and Feedback Loop

After the planner agent completes:

1. Read the generated plan from `<plans-dir>/PLAN_PREVIEW_<spec-name>.md`
2. Parse each phase's `**Complexity:**` and `**Complexity rationale:**` fields (added by the planner per `${CLAUDE_PLUGIN_ROOT}/agents/arn-code-feature-planner.md`'s Complexity Assessment section). If a phase is missing these fields (older plans), treat its complexity as `unknown` and skip the upgrade gate for it.
3. Present a structured summary to the user:
   - **Spec:** the linked specification name
   - **Phases:** list each phase with a 1-line description, key deliverables, **and complexity rating** (e.g., `Phase 3: Dispatch Site Edits — 7 deliverables — complexity: complex`). Always show the rating, regardless of whether an upgrade gate fires.
   - **Dependencies:** which phases depend on which
   - **Total files:** approximate count of files to create/modify
   - **Testing:** whether testing phases are included
4. Ask: **"Does this plan look right, or would you like to change anything?"**

**If the user approves** (e.g., "looks good", "approved", "yes", "proceed"):
→ Go to **Step 5a (Complex Phase Upgrade Gate)** before Step 6.

**If the user provides feedback** (e.g., "split phase 2 into two phases", "add error handling for X", "remove the caching component"):
→ Go to Step 5b.

#### Step 5a: Complex Phase Upgrade Gate

Before marking the plan approved, check whether the user should be offered an executor model upgrade for any complex phases.

**Filter:** Build the list of phases with `**Complexity:** complex`. If empty, skip this step entirely and go to Step 6.

**Profile detection:** Read the project's CLAUDE.md `## Arness` block for `Code agent model profile:`. Branch:
- If the field is `all-opus`: skip this step silently (every agent is already on Opus, nothing to upgrade). Display brief status line: `Preference: complex phase upgrade silenced — profile is all-opus (no upgrade needed)`. Go to Step 6.
- If the field is `balanced` or `custom`: continue.
- If the field is missing or `.arness/agent-models/code.md` doesn't exist: treat as unknown and continue (run the gate — the user gets the choice).

**Two-tier preference lookup** for `pipeline.complex-phase-upgrade` per `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-ensure-config/references/preferences-schema.md`:

1. Read `.arness/workflow.local.yaml` — if file exists and key present, use that value (note source).
2. Else read `~/.arness/workflow-preferences.yaml` — if file exists and key present, use that value (note source).
3. Else treat as `null` (first encounter).

Branch on the resolved value:

- **`always`:** auto-mark every phase with complexity `complex` for `modelOverride: "opus"` in the in-memory plan structure (carried into save-plan). Display status line: `Preference: upgrading N complex phases to Opus executor (stored in <source>)`. Go to Step 6.
- **`never`:** skip the gate silently. Go to Step 6.
- **`ask`:** show the gate below. Do NOT show the remember-this follow-up afterward.
- **`null` (first encounter):** show the gate below. After the user answers, show the remember-this follow-up.

**Gate (shown when value is `ask`, `null`, or invalid):**

Build a phase list for the prompt:
```
N phases are rated complex:
  - Phase 2: <title> — <complexityRationale>
  - Phase 3: <title> — <complexityRationale>
  - Phase 5: <title> — <complexityRationale>
```

Ask (using `AskUserQuestion`):

**"N phases are rated complex. Upgrade ALL of them to Opus for execution? (Reviewer dispatches stay on configured tier.)"**

Options:
1. **Yes, upgrade all complex phases** (Recommended for known-complex work) — mark every complex phase for `modelOverride: "opus"`
2. **No, keep configured tier** — no override applied; phases run on the agent-models lookup result

If **Yes**: mark every complex phase in the in-memory plan structure for `modelOverride: "opus"`. The override is persisted by `arn-code-save-plan` Step 5 into PROGRESS_TRACKER.json.
If **No**: no override applied.

**Follow-up (only when preference was null):** After the user answers the gate, ask:

Ask (using `AskUserQuestion`):

**"Should Arness remember this choice for future sessions?"**

Options:
1. **Yes, always upgrade complex phases** (saves `always` to preferences)
2. **Yes, never upgrade complex phases** (saves `never` to preferences)
3. **No, ask me each time**

If **Yes (always)**: write `always` to `~/.arness/workflow-preferences.yaml` under `pipeline.complex-phase-upgrade`. Create `~/.arness/` directory and file if they do not exist. If file exists, read first, add or update the key under `pipeline:`, write back preserving all existing keys.
If **Yes (never)**: write `never` to `~/.arness/workflow-preferences.yaml` under `pipeline.complex-phase-upgrade` (same write logic).
If **No**: write `ask` to `~/.arness/workflow-preferences.yaml` under `pipeline.complex-phase-upgrade` (same write logic).

After Step 5a completes (gate applied or skipped), go to Step 6.

#### Step 5b: Iterate with Feedback

Try to resume the planner agent using the Task tool's `resume` parameter with the stored agent ID:

```
The user has reviewed the current plan and has the following feedback:

[user's feedback verbatim]

The current plan is at: <plans-dir>/PLAN_PREVIEW_<spec-name>.md

Read the current plan, apply the user's feedback, and write the updated plan
to the same file. Summarize what you changed.
```

**If resume fails** (API error, agent ID no longer valid):
Fall back to spawning a fresh `arn-code-feature-planner` agent via the Task tool, passing the model from `.arness/agent-models/code.md` as the `model` parameter (see `plugins/arn-code/skills/arn-code-ensure-config/references/ensure-config.md` "Dispatch convention" for fallback). Context:

```
You are revising an existing implementation plan based on user feedback.

**Current plan file:** <plans-dir>/PLAN_PREVIEW_<spec-name>.md
**Spec file:** <specs-dir>/<spec-filename>

**User feedback:**
[user's feedback verbatim]

Read the current plan from the plan file, apply the user's feedback, and write
the updated plan to the same file. Summarize what you changed.
```

After the agent completes, return to Step 5 (read updated plan, present summary, ask for approval).

---

### Step 6: Plan Approved

Confirm with the user:

"Plan approved and saved to `<plans-dir>/PLAN_PREVIEW_<spec-name>.md`.

Next step: Run `/arn-code-save-plan` to convert this plan into a structured project with phased implementation and testing plans."

---

## Error Handling

- **`## Arness` config missing in CLAUDE.md** — suggest running `/arn-planning` to get started.
- **No specs found** — suggest running `/arn-code-feature-spec` or `/arn-code-bug-spec` first.
- **Planner agent fails or crashes** — read the agent's output to identify what went wrong. If partial plan was written, present it and ask the user if they want to retry or edit manually.
- **Resume fails during feedback loop** — fall back to fresh agent invocation (Step 5b fallback). Inform the user: "Could not resume the planner session. Spawning a fresh planner with the current plan and your feedback."
- **PLAN_PREVIEW file not written by agent** — check the agent output for errors. If the agent produced plan content but did not write it, write the content to the PLAN_PREVIEW file directly and continue.
- **User cancels** — confirm cancellation. If a PLAN_PREVIEW file was partially written, inform the user of its location so they can delete or edit it manually.
