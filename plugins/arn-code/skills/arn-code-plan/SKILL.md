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
version: 1.0.0
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

### Step 4: Invoke the Planner Agent

Derive the spec name from the spec filename (strip prefix and extension):
- `FEATURE_websocket-notifications.md` → `websocket-notifications`
- `BUGFIX_checkout-500.md` → `checkout-500`
- `FEATURE_F-001.1_user-auth.md` → `F-001.1_user-auth`

The output file path is: `<plans-dir>/PLAN_PREVIEW_<spec-name>.md`

**Check for existing PLAN_PREVIEW:** If a PLAN_PREVIEW file already exists at that path, inform the user: "A plan preview already exists for this spec: `<path>`. Would you like to regenerate it from scratch, or review the existing plan?" If review → skip to Step 5. If regenerate → proceed.

Spawn the `arn-code-feature-planner` agent via the Task tool with this context:

```
You are generating an implementation plan for the following specification.

**Specification:** <spec-name>
**Spec file:** <specs-dir>/<spec-filename>

--- SPECIFICATION CONTENT ---
[full spec file content]
--- END SPECIFICATION ---

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
2. Present a structured summary to the user:
   - **Spec:** the linked specification name
   - **Phases:** list each phase with a 1-line description and key deliverables
   - **Dependencies:** which phases depend on which
   - **Total files:** approximate count of files to create/modify
   - **Testing:** whether testing phases are included
3. Ask: **"Does this plan look right, or would you like to change anything?"**

**If the user approves** (e.g., "looks good", "approved", "yes", "proceed"):
→ Go to Step 6.

**If the user provides feedback** (e.g., "split phase 2 into two phases", "add error handling for X", "remove the caching component"):
→ Go to Step 5b.

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
Fall back to spawning a fresh `arn-code-feature-planner` agent with:

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
