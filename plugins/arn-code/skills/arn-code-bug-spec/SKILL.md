---
name: arn-code-bug-spec
description: >-
  This skill should be used when the user says "bug spec", "arness code bug spec",
  "investigate this bug", "help me debug", "trace this bug", "diagnose this
  issue", "I found a bug", "something is broken", "why is X not working",
  "fix this bug", "debug this", "why is this not working",
  or wants to iteratively investigate a bug through guided conversation
  with diagnostic analysis. Bridges the gap between a bug report and either
  a direct fix or a structured bug specification for the Arness pipeline.
version: 1.0.0
---

# Arness Bug Spec

Investigate a bug through iterative conversation, aided by diagnostic analysis from the `arn-code-investigator` agent, architectural validation from the `arn-code-architect` agent, and optional automated fix execution from the `arn-code-bug-fixer` agent. Every bug investigation gets its own project folder (`BUGFIX_<name>/`) in the plans directory. For simple bugs, the artifact is a fix plus a bug fix report. For complex bugs, the artifact is a **bug specification** written to `.arness/specs/` that informs plan creation via the `/arn-code-plan` skill.

This is a conversational skill. It runs in normal conversation (NOT plan mode). A `BUGFIX_<name>/` project folder is created at the start of every investigation. For simple bugs, the folder holds the fix report. For complex bugs, a specification document is written to `<specs-dir>/BUGFIX_<name>.md`, and the project folder is used later by `arn-code-save-plan` after the plan is generated via `/arn-code-plan`.

## Step 0: Ensure Configuration

Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-ensure-config/references/ensure-config.md` and follow its instructions. This guarantees a user profile exists and `## Arness` is configured with Arness Code fields before proceeding.

## Workflow

### Step 1: Capture the Bug Report

Accept the user's bug description. This can be anything from "X is broken" to a detailed report with stack traces, error messages, and reproduction steps. Do not require a specific format.

If the user already provided the bug description in their trigger message (e.g., "bug spec: users are getting 500 errors on checkout"), use that directly without asking again.

Acknowledge the report with a brief restatement to confirm understanding. Ask targeted follow-up questions ONLY if critical information is missing:
- What is expected vs actual behavior?
- Any error messages or stack traces?
- When did it start? (recent change, always broken, intermittent)

Do NOT require answers to all of these. Work with what is available and proceed.

#### Establish Project Folder

Once the bug is understood, create a project folder for the investigation:

1. Auto-generate a project name from the bug description (e.g., `BUGFIX_checkout-500-errors`, `BUGFIX_stale-cache-after-update`).
2. Suggest it to the user: "I'll create a bug investigation project called `BUGFIX_<name>`. Good?"
3. Once confirmed, read the `## Arness` section from CLAUDE.md to get the plans directory path, then create the project folder:

```bash
mkdir -p <plans-dir>/BUGFIX_<name>/reports
```

This folder is the home for all artifacts produced during this investigation. Hold the project path (`<project-folder>`) for use throughout the workflow.

---

### Step 2: Load Codebase Context

Read the project's CLAUDE.md and extract the `## Arness` section to find:
- Code patterns path
- Specs directory
- Template path
- Template version (if present)
- Template updates preference (if present)

**Template version check:** If `Template version` and `Template updates` fields are present, run the template version check procedure documented in `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-save-plan/references/template-versioning.md` before proceeding. If `## Arness` does not contain these fields, treat as legacy and skip.

Read the stored pattern documentation:
- `<code-patterns-dir>/code-patterns.md`
- `<code-patterns-dir>/testing-patterns.md`
- `<code-patterns-dir>/architecture.md`
- `<code-patterns-dir>/ui-patterns.md` (if it exists)

**If pattern documentation files are missing** (no `code-patterns.md`, `testing-patterns.md`, or `architecture.md` in the Code patterns directory):

Inform the user: "This is the first time pattern documentation is being generated for this project. Analyzing your codebase to understand its patterns, conventions, and architecture. This is a one-time operation — future invocations will use the cached results."

Then invoke the `arn-code-codebase-analyzer` agent (existing codebase) or `arn-code-pattern-architect` (greenfield) to generate fresh analysis. Write the results to the Code patterns directory. Summarize the key findings relevant to the bug.

Hold this context for use throughout the conversation. Do not dump all of it on the user -- reference specific parts when relevant.

---

### Step 3: Initial Investigation + Architectural Validation

Invoke the `arn-code-investigator` agent with:

**Bug description:** The user's report from Step 1.

**Codebase context:** The full content of the stored pattern documentation files loaded in Step 2 (code-patterns.md, testing-patterns.md, architecture.md, and ui-patterns.md if present). If these were not available and `arn-code-codebase-analyzer` was used instead, pass that output.

**Specific hypothesis:** None for the initial invocation.

Once the investigator returns with a root cause and proposed fix direction, invoke the `arn-code-architect` agent with:

**Feature idea:** The investigator's findings -- root cause, scope assessment, and proposed fix direction.

**Codebase context:** The stored architecture documentation (architecture.md, code-patterns.md, and ui-patterns.md if present).

**Specific question:** "Does this proposed fix direction align with the system architecture? Is it a proper fix or a workaround/hack? Are there architectural concerns or better approaches?"

Present the combined results to the user, highlighting:
1. Root cause (or top hypothesis) -- from the investigator
2. Evidence (file paths and line numbers) -- from the investigator
3. Scope assessment -- from the investigator
4. Test coverage gaps -- from the investigator
5. Architectural assessment -- from the architect: does the fix align with system design, any concerns, recommended approach
6. Open questions -- from both the investigator and the architect

Then ask: "Does this match what you're seeing? Any additional context or leads?"

---

### Step 4: Diagnosis Phase (Iterative)

Iterate with the user in a conversation loop: listen for confirmations, corrections, or new symptoms, then invoke `arn-code-investigator` or `arn-code-architect` as appropriate. Summarize the current state after each exchange and check for convergence (root cause confirmed + architect validated). When converged, proceed to Step 5.

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-bug-spec/references/diagnosis-flow.md` for the full diagnosis and fix procedure.

---

### Step 5: Complexity Assessment (Internal)

Internally assess whether the fix is simple or complex based on the architect's validation and six complexity questions (file count, architectural changes, pattern repetition, dependencies, description length, test work). Route to Step 6A for simple fixes or Step 6B for complex ones.

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-bug-spec/references/diagnosis-flow.md` for the full diagnosis and fix procedure.

---

### Step 6A: Simple Fix Path

Present the fix proposal with specific files and test plan, offer the user a choice between writing a small plan first or fixing directly, create a task list, and execute either in-session or via `arn-code-bug-fixer`. The bug fix report is written to `<project-folder>/reports/BUGFIX_REPORT.json`.

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-bug-spec/references/diagnosis-flow.md` for the full diagnosis and fix procedure.

---

### Step 6B: Complex Fix Path — Write Bug Specification

1. Inform the user: "This fix is complex enough to benefit from a structured plan. Let me capture the investigation results in a specification."

2. Invoke the `arn-code-architect` agent with:
   - The root cause analysis from the investigator
   - The full codebase context from Step 2
   - A fix design question: "Design a fix approach for this bug that aligns with the system architecture."

3. Present the architectural proposal, highlighting: fix strategy, components to change, integration points, and open questions.

4. Iterate with the user (same pattern as Step 4):
   - Codebase investigation questions --> invoke `arn-code-architect`
   - Scope/preference questions --> answer directly
   - Direction changes --> re-invoke `arn-code-architect` with updated context

5. When the user is ready, write the bug specification:

   a. Read the bug spec template at `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-bug-spec/references/bug-spec-template.md`.

   b. Populate the template with:
      - **Bug Report:** The refined bug description
      - **Root Cause Analysis:** The investigator's findings (root cause, evidence, confidence, investigation trail)
      - **Impact Assessment:** Affected files, broader impact
      - **Architectural Assessment:** The architect's validation and fix design
      - **Proposed Fix Direction:** The agreed approach
      - **Test Coverage Audit:** The investigator's test coverage assessment
      - **Scope & Boundaries:** What the fix includes and excludes
      - **Open Items:** Unresolved questions, risks

   c. Write the spec to `<specs-dir>/BUGFIX_<name>.md`. If the specs directory does not exist, create it: `mkdir -p <specs-dir>/`

6. Present a summary and next steps:

   "Bug specification saved to `<specs-dir>/BUGFIX_<name>.md`.
   Project folder is at `<project-folder>/`.

   To create a fix plan, run `/arn-code-plan BUGFIX_<name>`.

   The skill will load this spec and your project's codebase patterns, invoke the planner agent to generate a plan, and let you review and refine it before saving."

---

### Step 7: Execution Handoff

For the **simple path**, execution is handled in Step 6A. The task list is created and executed (either directly in the session or via `arn-code-bug-fixer`). No further handoff is needed.

For the **complex path**, after the spec is written, the user runs `/arn-code-plan` to generate the implementation plan. From there, the standard pipeline applies: arn-code-save-plan -> arn-code-review-plan -> arn-code-taskify -> arn-code-execute-plan.

---

## References

- **`references/agent-invocation-guide.md`** -- lookup table for when to invoke each agent vs. answer directly
- **`references/diagnosis-flow.md`** -- iterative diagnosis loop, complexity assessment, and simple-fix execution flow
- **`references/bugfix-plan-template.md`** -- template for inline fix plans in the simple path (used by `arn-code-planner`)
- **`references/bug-spec-template.md`** -- template for bug specification documents (complex path)

## Error Handling

- **User cancels at any point:** Confirm and exit gracefully. Inform the user of the project folder location (`<project-folder>/`) so they can delete or resume later. If only the folder skeleton was created (no report or plan yet), note that it can be safely deleted.
- **arn-code-investigator returns inconclusive results:** Summarize what was found, explain what is still uncertain, and ask the user for more context (reproduction steps, logs, error messages) to narrow the search.
- **arn-code-investigator finds multiple root causes:** Present all candidates with confidence levels. Let the user help prioritize, or investigate the most likely one first and note the others as open items.
- **arn-code-bug-fixer fails after 3 test attempts:** Report the partial state to the user (what was fixed, what tests still fail, what was attempted). Escalate to the user for a decision: retry with more context, switch to complex path, or investigate the test failures manually.
- **User says "just fix it" during complex path:** Explain the benefit of the structured plan for a complex fix (traceability, test coverage, reduced risk). Offer to attempt a direct fix with the caveat that it may be incomplete or introduce regressions. If the user insists, proceed with the best available fix proposal and create the task list as in Step 6A.
- **If writing the spec file fails (permissions, path issues):** Print the spec content in the conversation so the user can save it manually. Suggest checking permissions on the specs directory.
- **If the specs directory does not exist:** Create it: `mkdir -p <specs-dir>/`
- **arn-code-architect returns vague or contradictory guidance:** Summarize what the architect said, note the uncertainty, and ask the user for their architectural preference. Proceed with the user's decision.
