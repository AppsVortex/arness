---
name: arn-code-assess
description: >-
  This skill should be used when the user says "arness code assess", "arn-code-assess",
  "assess codebase",
  "technical review", "codebase assessment", "find improvements", "what should I improve",
  "tech debt review", "tech debt audit", "pattern compliance check", "codebase health check",
  "assess the project", "improvement plan", "review my codebase", "what needs fixing",
  "code quality check", "audit my code", "run an assessment",
  or wants a comprehensive technical assessment of the codebase against stored patterns
  followed by prioritized improvement execution through the full Arness pipeline.
version: 1.0.0
---

# Arness Assess

Run a comprehensive technical assessment of the codebase against stored patterns, let the user prioritize findings, then orchestrate the full Arness pipeline (spec → plan → execute → test → ship) for multiple improvements in a single session.

This skill is a **sequencer and decision-gate handler**, like arn-planning. It MUST NOT duplicate sub-skill or agent logic. All pipeline work is done by the invoked skills and agents. This skill handles: scope selection, assessment orchestration, finding prioritization, multi-spec pipeline management, and progress display.

## Prerequisites

Check for a `## Arness` section in the project's CLAUDE.md. If missing, inform the user: "Arness is not configured for this project yet. Run `/arn-assessing` to get started — it will set everything up automatically." Do not proceed without it.

Additionally, verify that pattern files exist at the configured code-patterns path. At minimum, these must exist:
- `code-patterns.md`
- `testing-patterns.md`
- `architecture.md`

If any required pattern file is missing, inform the user: "Pattern documentation is incomplete. Run `/arn-assessing` which will generate pattern docs on first use."

## Decision Gates

The skill pauses at exactly 7 gates. Steps marked (auto) flow without stopping.

| Gate | When | Question | Options |
|------|------|----------|---------|
| G1 | Entry | "What would you like to assess?" | Entire codebase / Specific area |
| G2 | After assessment | "Ready to prioritize?" | Prioritize / Investigate further |
| G3 | After prioritization | "How should improvements be organized?" | Bundle all / Separate specs / Arness suggests groupings |
| G4 | After all plans generated | "Plans ready. Proceed?" | Approve all / Revise specific plan / Remove a spec |
| G5 | Before each subsequent spec execution | "Conflict detected" (conditional) | Re-plan / Proceed / Skip |
| G6 | After test results | "Tests [pass/fail]. Proceed?" | Ship / Fix and re-test / Abort |
| G7 | Final | "Ship it?" | Commit, push & PR / Just commit / Not yet |

## Pipeline Overview

```
Arness Assess: scope → assess → prioritize → spec(s) → plan all → save all → [taskify+execute]×N → test → ship
```

## Workflow

### Step 0: Initialize

1. Read the project's CLAUDE.md and extract the `## Arness` section.
2. Extract configuration fields:
   - **Plans directory** — where plans and project folders live
   - **Specs directory** — where specs and assessment reports are stored
   - **Code patterns** — path to pattern documentation directory
   - **Docs directory** — for documentation generation
   - **Git** — whether git is configured
   - **GitHub/Platform** — for shipping
3. Load pattern files from the configured code-patterns path:
   - `code-patterns.md` (required)
   - `testing-patterns.md` (required)
   - `architecture.md` (required)
   - `ui-patterns.md` (optional — sets `has_ui_patterns = true`)
   - `security-patterns.md` (optional — sets `has_security_patterns = true`)

### Step 1: Detect Assessment State (Resumability)

Check for existing assessment artifacts:

| Artifact | Detected State |
|----------|---------------|
| `ASSESSMENT_*.md` in specs-dir + executed plans with reports | Near-complete — resume at test gate |
| `ASSESSMENT_*.md` in specs-dir + project folders with TASKS.md | Mid-execution — resume at taskify+execute |
| `ASSESSMENT_*.md` in specs-dir + PLAN_PREVIEW files | Plans ready — resume at G4 |
| `ASSESSMENT_*.md` in specs-dir + FEATURE specs matching assessment IDs | Specs written — resume at plan all |
| `ASSESSMENT_*.md` in specs-dir only | Assessment done — resume at G2 (prioritize) |
| None | Fresh start — begin at G1 |

If artifacts detected, ask: "It looks like you have an in-progress assessment. Resume from [stage], or start fresh?"

---

### Step 2: Gate G1 — Scope Selection

Show progress:
```
Arness Assess: SCOPE → assess → prioritize → spec(s) → plan → save → execute → test → ship             ^^^^^
```

Even if the user triggered the skill with arguments (e.g., "assess the auth module"), confirm scope with `AskUserQuestion`:

**"What would you like to assess?"**

Options:
1. **Assess entire codebase** — Full review against all stored patterns
2. **Assess specific area** — Review a particular module, directory, or concern

If **specific area**: ask the user to describe the area (module name, directory path, or concern like "authentication" or "API layer").

Store the scope for agent invocations. Derive a scope name for the assessment file:
- Entire codebase → `full-codebase`
- Specific area → kebab-case of the area (e.g., `auth-module`, `api-layer`)

---

### Step 3: Assessment

Show progress:
```
Arness Assess: scope → ASSESS → prioritize → spec(s) → plan → save → execute → test → ship                      ^^^^^^
```

Inform: "Running assessment agents against stored patterns..."

Read the assessment protocol:
```
Read ${CLAUDE_PLUGIN_ROOT}/skills/arn-code-assess/references/assessment-protocol.md
```

**Agent invocations — launch all applicable agents in parallel:**

**Always invoke `arn-code-architect`** with:
- The architect assessment prompt template from the protocol
- Codebase context: full content of `code-patterns.md`, `testing-patterns.md`, `architecture.md`
- Scope: the scope from G1

**If `has_ui_patterns` is true**, also invoke `arn-code-ux-specialist` with:
- The UX specialist assessment prompt template from the protocol
- Context: `ui-patterns.md`, `architecture.md`, `code-patterns.md`
- Scope from G1

**If `has_security_patterns` is true**, also invoke `arn-code-security-specialist` with:
- The security specialist assessment prompt template from the protocol
- Context: `security-patterns.md`, `architecture.md`, `code-patterns.md`
- Scope from G1

All applicable agents are invoked in parallel (single message, multiple Agent tool calls).

**After all agents return:**

Follow the merge, deduplication, ID assignment, and report generation procedures defined in the assessment protocol. Write the assessment report to `<specs-dir>/ASSESSMENT_<scope-name>.md`.

Present the findings to the user grouped by category with severity indicators.

**If no findings:** "Assessment found no significant deviations from stored patterns. Your codebase is in good shape!" — exit gracefully.

---

### Step 4: Gate G2 — Prioritize

Show progress:
```
Arness Assess: scope → assess → PRIORITIZE → spec(s) → plan → save → execute → test → ship                                ^^^^^^^^^^
```

Ask: "These are the assessment findings. Ready to prioritize, or would you like to investigate any finding further?"

If the user wants to investigate: discuss the specific finding, read relevant files, provide more context. Return to this gate when done.

Present findings as a numbered list (grouped by severity: high first). Ask:

**"Select which improvements to implement (comma-separated numbers, 'all', or 'all high'):"**

After selection, proceed to G3.

---

### Step 5: Gate G3 — Spec Strategy

Ask with `AskUserQuestion`:

**"How should these improvements be organized into specifications?"**

Options:
1. **Bundle all into one spec** — Single feature spec covering all selected improvements
2. **Create separate specs** — One spec per improvement
3. **Let Arness suggest groupings** — Group by affected module or theme

**If "Let Arness suggest groupings":**
- Group findings that share affected files or are in the same architectural area
- Present the suggested groups: "Group 1: [finding IDs] — [theme]. Group 2: [finding IDs] — [theme]."
- Ask the user to confirm or adjust the groupings

Store the final bundles as `spec_bundles` — a list where each entry has a name and a list of finding IDs.

---

### Step 6: Create Specs

Show progress:
```
Arness Assess: scope → assess → prioritize → SPEC(s) → plan → save → execute → test → ship                                            ^^^^^^^
```

For each bundle in `spec_bundles`:

Compose a feature description from the bundled findings:
- Title: "Improve [primary category]: [brief summary of findings]"
- Body: List each finding's description and suggested approach
- Context: Reference the assessment report for full details

Invoke `Skill: arn-code:arn-code-feature-spec` with the composed description as context.

After each spec is created, track the spec filename in `spec_list`.

If `arn-code-feature-spec` fails for a bundle, offer to split into individual findings and retry.

---

### Step 7: Plan All

Show progress:
```
Arness Assess: scope → assess → prioritize → spec(s) → PLAN → save → execute → test → ship                                                       ^^^^
```

Inform: "Generating plans for all specs..."

For each spec in `spec_list`:
- Invoke `Skill: arn-code:arn-code-plan <spec-name>`
- Track the plan preview path

---

### Step 8: Gate G4 — Review Plans

Present all generated plans with a brief summary of each (phase count, task count, estimated scope).

Ask with `AskUserQuestion`:

**"Plans are ready. How would you like to proceed?"**

Options:
1. **Approve all plans** — Proceed to save and execute
2. **Revise a plan** — Re-invoke arn-code-plan with feedback for a specific spec
3. **Remove a spec** — Drop a spec from the pipeline

If **Revise**: ask which plan and what feedback, re-invoke `arn-code:arn-code-plan`, return to this gate.
If **Remove**: mark the spec as `skipped` in state tracking, return to this gate with remaining plans.
Continue until the user approves.

---

### Step 9: Save All (auto)

Show progress:
```
Arness Assess: scope → assess → prioritize → spec(s) → plan → SAVE → execute → test → ship                                                               ^^^^
```

Inform: "Converting plans to structured projects..."

For each approved plan:
- Invoke `Skill: arn-code:arn-code-save-plan`

---

### Step 10: Sequential Taskify + Execute

Show progress:
```
Arness Assess: scope → assess → prioritize → spec(s) → plan → save → EXECUTE → test → ship                                                                     ^^^^^^^
```

Read the orchestration flow:
```
Read ${CLAUDE_PLUGIN_ROOT}/skills/arn-code-assess/references/orchestration-flow.md
```

**Determine execution order** using the ordering heuristic from the orchestration flow. Present the suggested order and allow the user to override.

**For each spec in execution order:**

1. **Conflict check** (skip for the first spec):
   - Compare files modified by previously executed specs against files referenced in this spec's phase plans
   - Follow the conflict detection algorithm from the orchestration flow
   - If conflicts detected → **Gate G5**: Present conflicts using the format from the orchestration flow. Ask with `AskUserQuestion`:
     - **Re-plan** — Re-invoke `arn-code:arn-code-plan` and `arn-code:arn-code-save-plan` for this spec
     - **Proceed anyway** — Execute the existing plan
     - **Skip this spec** — Mark as skipped, move to next

2. **Taskify**: Invoke `Skill: arn-code:arn-code-taskify`

3. **Execute**: Invoke `Skill: arn-code:arn-code-execute-plan`

4. **Track results**: Collect execution reports, extract list of files modified, update spec state

If execution fails mid-spec:
- Present the failure
- Ask: Retry / Skip remaining tasks in this spec / Abort pipeline

---

### Step 11: Test

Show progress:
```
Arness Assess: scope → assess → prioritize → spec(s) → plan → save → execute → TEST → ship                                                                                ^^^^
```

Invoke the `arn-code-test-specialist` agent via the Agent tool with:
- **Scope:** "full suite"
- **Code patterns directory:** the configured code-patterns path

**Gate G6 — based on verdict:**

**If ALL PASSING:** "All tests pass. Ready to ship."

**If FAILURES DETECTED or ERRORS DETECTED:**
- Present the failures from the test report
- Ask with `AskUserQuestion`:

  **"Tests have failures. How would you like to proceed?"**

  Options:
  1. **Fix and re-test** — User fixes the issues, then re-invoke `arn-code-test-specialist`
  2. **Proceed despite failures** — Continue to ship (warn: not recommended)
  3. **Abort** — Stop the pipeline, show what was completed

Loop on option 1 until tests pass or user chooses another option.

---

### Step 12: Gate G7 — Ship

Show progress:
```
Arness Assess: scope → assess → prioritize → spec(s) → plan → save → execute → test → SHIP                                                                                      ^^^^
```

Ask with `AskUserQuestion`:

**"Ready to ship?"**

Options:
1. **Commit, push & create PR** — Full ship workflow
2. **Just commit** — Commit locally without pushing
3. **Not yet** — Exit without shipping (can run `/arn-code-ship` later)

If **Commit, push & create PR** or **Just commit:**
→ `Skill: arn-code:arn-code-ship`

If **Not yet:** show what was completed and inform the user they can ship later.

---

### Step 13: Complete

Show final progress:
```
Arness Assess: scope → assess → prioritize → spec(s) → plan → save → execute → test → ship
               ✓       ✓          ✓           ✓         ✓      ✓       ✓        ✓      ✓
```

Present completion summary:

- **Assessment:** N findings across N categories (H high, M medium, L low)
- **Selected:** N improvements (of N total findings)
- **Specs created:** [list of spec names]
- **Specs executed:** [count] executed, [count] skipped
- **Tests:** [verdict]
- **Ship:** [PR URL / commit hash / deferred]

"Assessment pipeline complete. Run `/arn-code-assess` again anytime to review your codebase."

---

## Error Handling

- **Sub-skill fails:** Present the error. Ask: retry / skip / abort. If retry, re-invoke. If skip, continue to next gate. If abort, show what was completed and exit.
- **Agent returns empty findings:** Report that the agent found no issues in its domain. Continue with findings from other agents.
- **No findings at all:** Exit gracefully with positive message (see Step 3).
- **User says "stop" or "pause":** Show what has been completed. Inform user they can resume by running `/arn-code-assess` again (artifact detection will pick up).
- **Conflict detection finds massive overlap (5+ files across 3+ specs):** Warn and suggest re-bundling remaining specs into a single combined spec.
- **Arness not configured:** Block and suggest running `/arn-assessing` to get started.
- **Multiple assessment files detected during resume:** List them and ask which to resume.

## Constraints

- This skill MUST NOT duplicate sub-skill or agent logic. It only handles sequencing, decision gates, and multi-spec orchestration.
- All pipeline work is done by invoked skills (via Skill tool) and agents (via Agent tool).
- Progress display uses the compact format shown above — one line with the current stage highlighted.
- The skill runs in normal conversation (not plan mode).
- Assessment agents are invoked in parallel (single message, multiple Agent tool calls).
- Spec execution is always sequential with conflict detection between specs.
