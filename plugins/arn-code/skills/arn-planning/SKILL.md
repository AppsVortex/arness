---
name: arn-planning
description: >-
  This skill should be used when the user says "planning", "arness planning",
  "plan a feature", "start planning", "I want to build", "new feature",
  "plan something", "what should I build", "pick an issue", "plan a bug fix",
  "I have an idea", "spec and plan", "plan from scratch", "plan this",
  "feature planning", "bug planning", "plan this issue", "arn-planning",
  or wants to go from an idea, issue, or bug report through to a complete
  implementation plan ready for execution. Handles severity-aware scope
  routing across three ceremony tiers (swift, standard, thorough),
  routing between feature specs, bug specs, and quick implementations,
  and produces a reviewed plan ready for execution. Chains to
  arn-implementing at completion.
version: 1.1.0
---

# Arness Planning

Go from an idea, issue, or bug report through to a complete implementation plan ready for execution. This is the primary first-citizen entry point for the Arness development pipeline. It orchestrates scope assessment, spec authoring, plan generation, plan structuring, plan review, and task creation — then chains to `arn-implementing`.

This skill is a **sequencer and decision-gate handler**. It MUST NOT duplicate sub-skill logic. All pipeline work is done by the invoked skills. Arness-planning handles: input routing, scope assessment, transitions between skills, progress display, resumability, and chaining.

## Prerequisites: Ensure Configuration

Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-ensure-config/references/ensure-config.md` and follow its instructions. This guarantees a user profile exists and `## Arness` is configured with Arness Code fields before proceeding.

After configuration is ensured, extract the following from `## Arness`:
- **Plans directory** — for detecting plan previews and project folders
- **Specs directory** — for detecting specification files
- **Code patterns** — path to stored pattern documentation
- **Issue tracker** — determines if "Pick from backlog" option is available (`github`, `jira`, or `none`)

## Workflow

### Step 0: Input Routing

Check the trigger message to determine the entry path:

| Input Pattern | Action |
|--------------|--------|
| No args | Proceed to Step 1 (State Detection), then G1 if no resume |
| Text description (e.g., "planning: add rate limiting") | Extract description, proceed to Step 3 (Scope Assessment) |
| Issue reference (`#42`, `PROJ-123`) | Invoke `Skill: arn-code:arn-code-pick-issue` with the reference, then proceed to Step 3 with the loaded issue context |
| Feature backlog reference (`F-003`) | Invoke `Skill: arn-code:arn-code-pick-issue` with the reference, then proceed to Step 3 |
| "pick" keyword | Invoke `Skill: arn-code:arn-code-pick-issue` (browse mode), then proceed to Step 3 |
| "resume" | Proceed to Step 1 (State Detection) |

---

### Step 1: State Detection

Check which artifacts exist on disk to determine the entry point. Check from most advanced to least advanced — first match wins:

| Artifact | Detected State | Resume Point |
|----------|---------------|--------------|
| `INTRODUCTION.md` in `<plans-dir>/<project>/` | Plan saved and structured | G5 (Completion — offer implementing) |
| `STANDARD_*.md` in `<plans-dir>/` or project root | Standard tier in progress/complete | Chain to `arn-implementing` with standard intent |
| `PLAN_PREVIEW_*.md` in `<plans-dir>/` | Plan generated, not saved | Auto-run save-plan, then G5 |
| `FEATURE_*.md` or `BUGFIX_*.md` in `<specs-dir>/` (finalized) | Spec written, no plan | G3 (Spec review) |
| `DRAFT_FEATURE_*.md` in `<specs-dir>/` (no finalized spec) | Spec in progress | Resume spec (invoke feature-spec, which detects the draft) |
| None of the above | Fresh start | G1 |

**If multiple specs or plans detected:** List them and ask the user which to resume.

**If artifacts detected:**

Show the detected state and ask: "It looks like you have an in-progress plan. Resume from [detected stage], or start fresh?"

- **Resume** → skip to the detected resume point
- **Start fresh** → begin at G1 (do not delete existing artifacts)

**If no artifacts detected:** check for a greenfield feature backlog, then proceed to G1.

**Greenfield backlog check (optional — Arness Spark integration):**

If no Arness Code artifacts were detected, check for a greenfield feature backlog. Arness Spark is an optional plugin — if any condition fails, skip silently and proceed to G1 normally.

1. `## Arness` config has a **Vision directory** field (only set by `arn-spark-init`, never by core `arn-code-init`)
2. If Vision directory exists, `<vision-dir>/features/feature-backlog.md` exists
3. The file contains a `## Feature Tracker` table

If all three pass, parse the Feature Tracker to count features by status (pending, in-progress, done). Skip rows with status `decomposed` — their sub-features are counted individually instead. Calculate unblocked features (pending where all dependencies have status done, or dependencies are None).

Hold the results for G1 — they change how the gate is presented. If any condition fails, proceed to G1 with no backlog context.

---

### Step 2: Gate G1 — Entry Point

Only reached when no input was provided and no artifacts were detected for resume.

Show progress:
```
Planning: ENTRY -> scope-router -> spec -> plan -> save -> review-plan -> taskify -> [ready]
          ^^^^^
```

**If greenfield backlog was detected in Step 1:**

Present the backlog context before asking:

"A greenfield feature backlog exists with **[total]** features ([unblocked] unblocked, [in-progress] in progress, [done] done).

The unblocked features ready for implementation are available via the backlog."

Ask (using `AskUserQuestion`):

**"What would you like to work on?"**

**If `unblocked > 1`** (batch option available — 4 options):

Options:
1. **Pick from backlog** (Recommended) — Browse [unblocked] unblocked features from the greenfield pipeline
2. **Batch plan ([unblocked] features)** — Plan multiple features for parallel implementation
3. **Describe a feature** — Start with a new feature idea
4. **Report a bug** — Investigate a bug and develop it into a fix or spec

**If `unblocked <= 1`** (no batch option — 3 options):

Options:
1. **Pick from backlog** (Recommended if [unblocked] > 0) — Browse [unblocked] unblocked features from the greenfield pipeline *(shown when Issue tracker is not `none` OR greenfield backlog was detected — the greenfield backlog provides local-only browsing even without a remote issue tracker)*
2. **Describe a feature** — Start with a new feature idea
3. **Report a bug** — Investigate a bug and develop it into a fix or spec

**If no greenfield backlog (default):**

Ask (using `AskUserQuestion`):

**"What are you planning?"**

Options:
1. **Pick from backlog** — Browse issues and pick one to work on *(only shown if Issue tracker is not `none`)*
2. **Describe a feature** — Start with a feature idea
3. **Report a bug** — Investigate a bug and develop it into a fix or spec

Based on choice:
- **Pick from backlog** → `Skill: arn-code:arn-code-pick-issue`. When pick-issue completes (issue selected and context loaded), proceed to Step 3 (Scope Assessment) with the issue context.
- **Batch plan** → `Skill: arn-code:arn-code-batch-planning`. Exit arn-planning — batch-planning orchestrates the multi-feature flow including spec, plan, save-plan for each feature, then chains to batch-implement.
- **Describe a feature** → Ask the user to describe the feature. Proceed to Step 3 with the description.
- **Report a bug** → `Skill: arn-code:arn-code-bug-spec`. Bug-spec handles its own investigation flow:
  - If bug-spec resolves via **simple path** (fix applied, no spec): "Bug fixed. No planning needed." Offer: chain to `/arn-shipping` or exit.
  - If bug-spec produces a **spec file**: proceed to G3 (Spec Review).

---

### Step 3: Scope Assessment

Classify the user's input to determine the best routing. This is a lightweight assessment, not a full architect invocation.

Show progress:
```
Planning: entry -> SCOPE-ROUTER -> spec -> plan -> save -> review-plan -> taskify -> [ready]
                   ^^^^^^^^^^^^
```

#### Step 3A: Read Codebase Context

Read (silently, do not present to the user):
- `<code-patterns-dir>/architecture.md` — technology stack, project scale, module structure
- `<code-patterns-dir>/code-patterns.md` — naming conventions, existing patterns

#### Step 3B: Classify Intent

Analyze the description (from user input, issue, or backlog item) for intent signals:

**Bug signals:** "fix", "broken", "error", "not working", "bug", "crash", "failing", "regression", "issue with", "doesn't work", "wrong behavior"
→ **TYPE = bug**

**Feature signals:** "add", "create", "build", "implement", "new", "support for", "enable", "introduce", "enhance", "improve", "extend", "upgrade"
→ **TYPE = feature**

**Ambiguous** (no clear signals or mixed signals):
→ Ask (using `AskUserQuestion`): "Is this a bug fix or a new feature?"

#### Step 3C: Scope Router (features only)

For TYPE = bug, skip scope routing — always route to bug-spec.

For TYPE = feature, apply the severity-aware scope router:

1. **Read criteria:** Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-planning/references/scope-router-criteria.md`

2. **Supplementary signal (optional):** If there is a working tree with changes, run `git diff --stat` silently as a supplementary signal for file count and cross-module impact. This does not override the description-based assessment but can confirm or adjust estimates.

3. **Score each criterion:** Rate each of the 6 criteria (low=0, medium=1, high=2), multiply by its weight, and compute the weighted total (0-20).

4. **Apply override rules:** Check if any override rules from the criteria reference force a minimum tier (e.g., any high-weight criterion scoring "high" forces minimum standard).

5. **Map to recommended tier:**
   - 0-4 → **swift** (small, low-risk, additive change)
   - 5-12 → **standard** (moderate scope or sensitivity)
   - 13-20 → **thorough** (high complexity, risk, or architectural significance)

#### Step 3D: Route

Based on TYPE and recommended tier:

- **TYPE = bug** → `Skill: arn-code:arn-code-bug-spec`
  - If bug-spec simple path → offer arn-shipping, exit planning
  - If bug-spec produces spec → proceed to G3

- **TYPE = feature** → Gate G2 (Tier Selection) with the recommended tier

---

### Step 4: Gate G2 — Tier Selection

Only reached for TYPE = feature. Present the scope router recommendation and let the user confirm or override.

Show progress:
```
Planning [<recommended-tier>]: entry -> SCOPE-ROUTER -> spec -> plan -> save -> review-plan -> taskify -> [ready]
                                        ^^^^^^^^^^^^
```

Present the recommendation as a one-sentence summary: "Based on [key factors], I recommend **[tier]** for this change."

Ask (using `AskUserQuestion`):

**"Recommended tier: [tier]. How would you like to proceed?"**

Options (dynamically ordered — recommended tier is always option 1):

If recommended tier is **swift**:
1. **Swift** — Lightweight implementation with change record
2. **Standard** — Collapsed spec-plan-execute in one session
3. **Thorough** — Full pipeline with spec, plan, review, and phased execution

If recommended tier is **standard**:
1. **Standard** — Collapsed spec-plan-execute in one session
2. **Swift** — Downgrade to lightweight implementation
3. **Thorough** — Upgrade to full pipeline

If recommended tier is **thorough**:
1. **Thorough** — Full pipeline with spec, plan, review, and phased execution
2. **Standard** — Downgrade to collapsed spec-plan-execute
3. **Swift** — Downgrade to lightweight implementation

Based on the user's selection:

- **Swift**: `Skill: arn-code:arn-implementing` (with swift intent + the description as context). Exit planning — implementing takes over.
- **Standard**: `Skill: arn-code:arn-implementing` (with standard intent + the description as context). Exit planning — implementing takes over.
- **Thorough**: Proceed to feature spec. If the user upgraded to thorough from a lower recommendation, skip the expert debate question and proceed directly to `Skill: arn-code:arn-code-feature-spec`. Otherwise, check the expert-debate preference:

  **Preference check:** Read `pipeline.expert-debate` using the two-tier lookup chain (see `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-ensure-config/references/preferences-schema.md`):

  1. Read `.arness/workflow.local.yaml` — if the file exists and `pipeline.expert-debate` is present, use that value and note source.
  2. If not found, read `~/.arness/workflow-preferences.yaml` — if the file exists and `pipeline.expert-debate` is present, use that value and note source.
  3. If neither found or key is absent, treat as null (first encounter).

  Branch on the resolved value:

  - If `standard`: Show status line: "Preference: standard spec, no expert debate ([source])". Auto-proceed to `Skill: arn-code:arn-code-feature-spec`.

  - If `auto`: Only propose expert debate when the scope router score is **16 or higher** (top-quartile complexity). If score is 16+, present the expert debate gate below. If score is below 16, show status line: "Preference: standard spec (auto mode, score [N] below expert-debate threshold of 16) ([source])". Auto-proceed to `Skill: arn-code:arn-code-feature-spec`.

  - If `ask`: Present the expert debate gate below (when scope router total was 16+). If score is below 16, proceed directly to `Skill: arn-code:arn-code-feature-spec` (expert debate is not applicable at lower scores). Do NOT show the "remember this?" follow-up.

  - If null (or invalid value): Present the expert debate gate below (when scope router total was 16+). If score is below 16, proceed directly to `Skill: arn-code:arn-code-feature-spec`. After the user answers, show the "remember this?" follow-up (see below).

  **Gate (shown when scope router total is 16+ and value is `auto` with score 16+, `ask`, null, or invalid):**

  Ask (using `AskUserQuestion`):

  **"This is a significant feature. How would you like to develop the specification?"**

  Options:
  1. **Standard feature spec** — Single-agent exploration with the architect
  2. **Expert debate** — Multi-agent debate between architect, UX specialist, and security specialist (higher token cost)

  If **Standard feature spec**: `Skill: arn-code:arn-code-feature-spec`
  If **Expert debate**: `Skill: arn-code:arn-code-feature-spec-teams`
    - If feature-spec-teams is unavailable, fall back to standard feature-spec.

  **Follow-up (only when preference was null and the gate was shown):** After the user answers, ask:

  Ask (using `AskUserQuestion`):

  **"Should Arness remember this choice for future sessions?"**

  Options:
  1. **Yes, always use standard spec** (saves `standard` to preferences)
  2. **Yes, auto-propose debate for complex features (score 16+)** (saves `auto` to preferences)
  3. **No, ask me each time**

  If **Yes (standard)**: Write `standard` to `~/.arness/workflow-preferences.yaml` under `pipeline.expert-debate`. Create `~/.arness/` directory and file if they do not exist. If the file already exists, read it first, add or update the key under `pipeline:`, and write back preserving all existing keys.
  If **Yes (auto)**: Write `auto` to `~/.arness/workflow-preferences.yaml` under `pipeline.expert-debate` (same write logic).
  If **No**: Write `ask` to `~/.arness/workflow-preferences.yaml` under `pipeline.expert-debate` (same write logic).

  After spec completes, proceed to G3.

---

### Step 5: Gate G3 — Spec Review

Show progress:
```
Planning [thorough]: entry -> scope-router -> SPEC -> plan -> save -> review-plan -> taskify -> [ready]
                                              ^^^^
```

**Preference check:** Read `pipeline.spec-review` using the two-tier lookup chain (see `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-ensure-config/references/preferences-schema.md`):

1. Read `.arness/workflow.local.yaml` — if the file exists and `pipeline.spec-review` is present, use that value and note source as "project override in workflow.local.yaml".
2. If not found, read `~/.arness/workflow-preferences.yaml` — if the file exists and `pipeline.spec-review` is present, use that value and note source as "stored in workflow-preferences.yaml".
3. If neither found or key is absent, treat as null (first encounter).

Branch on the resolved value:

- If `review`: Show status line: "Preference: reviewing spec ([source])". Auto-proceed to spec review — read the spec file and present a summary (problem statement, key requirements, architectural approach, open items). Allow edits. When satisfied, continue to Step 6.

- If `proceed`: Show status line: "Preference: proceeding to plan ([source])". Auto-proceed to Step 6 (Plan Generation).

- If `upload`: Check if Issue tracker is `none`. If `none`, fall through to the gate below — show the gate but do NOT show the "remember this?" follow-up (the user already has a stored preference; it is just inapplicable in this project because no issue tracker is configured. Do not modify the stored preference). If Issue tracker is not `none`: show status line "Preference: uploading as issue ([source])". Auto-proceed to `Skill: arn-code:arn-code-create-issue` with the spec content. After issue is created, exit planning.

- If `ask`: Present the gate below. Do NOT show the "remember this?" follow-up afterward.

- If null (or invalid value): Present the gate below. After the user answers, show the "remember this?" follow-up (see below).

**Gate (shown when value is `ask`, null, or invalid):**

Ask (using `AskUserQuestion`):

**"Spec ready. What next?"**

Options:
1. **Review spec** — View a summary and make edits
2. **Proceed to plan** — Move to plan generation
3. **Upload as issue** — Save this spec as an issue to [GitHub/Jira] *(only shown if Issue tracker is not `none`)*

If **Review spec**: Read the spec file and present a summary (problem statement, key requirements, architectural approach, open items). Allow edits. When satisfied, re-present G3.

If **Proceed to plan**: Continue to Step 6 (Plan Generation).

If **Upload as issue**: `Skill: arn-code:arn-code-create-issue` with the spec content. After issue is created, exit planning. "Issue created. Run `/arn-planning` when ready to plan the implementation."

**Follow-up (only when preference was null):** After the user answers the gate, ask:

Ask (using `AskUserQuestion`):

**"Should Arness remember this choice for future sessions?"**

Options:
1. **Yes, always [chosen action]** (saves to preferences)
2. **No, ask me each time**

If **Yes**: Write the chosen value (`review`, `proceed`, or `upload`) to `~/.arness/workflow-preferences.yaml` under `pipeline.spec-review`. Create `~/.arness/` directory and file if they do not exist. If the file already exists, read it first, add or update the key under `pipeline:`, and write back preserving all existing keys.
If **No**: Write `ask` to `~/.arness/workflow-preferences.yaml` under `pipeline.spec-review` (same write logic).

---

### Step 6: Plan Generation

Show progress:
```
Planning [thorough]: entry -> scope-router -> spec -> PLAN -> save -> review-plan -> taskify -> [ready]
                                                       ^^^^
```

Derive the spec name from the spec filename (e.g., `FEATURE_websocket-notifications.md` → `websocket-notifications`) and invoke the plan skill:

> `Skill: arn-code:arn-code-plan <spec-name>`

The plan skill has its own feedback loop — the user iterates with the planner agent until the plan is approved. When it completes, a `PLAN_PREVIEW_<spec-name>.md` file exists in the plans directory.

---

### Step 7: Save Plan (Auto)

Show progress:
```
Planning [thorough]: entry -> scope-router -> spec -> plan -> SAVE -> review-plan -> taskify -> [ready]
                                                               ^^^^
```

Inform: "Plan approved. Converting to structured project..."

> `Skill: arn-code:arn-code-save-plan`

Save-plan auto-detects the PLAN_PREVIEW file and creates the project structure (INTRODUCTION.md, phase plans, TASKS.md, PROGRESS_TRACKER.json).

---

### Step 8: Gate G4 — Review Plan?

Show progress:
```
Planning [thorough]: entry -> scope-router -> spec -> plan -> save -> REVIEW-PLAN -> taskify -> [ready]
                                                                       ^^^^^^^^^^^
```

**Preference check:** Read `pipeline.plan-review` using the two-tier lookup chain (see `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-ensure-config/references/preferences-schema.md`):

1. Read `.arness/workflow.local.yaml` — if the file exists and `pipeline.plan-review` is present, use that value and note source.
2. If not found, read `~/.arness/workflow-preferences.yaml` — if the file exists and `pipeline.plan-review` is present, use that value and note source.
3. If neither found or key is absent, treat as null (first encounter).

Branch on the resolved value:

- If `review`: Show status line: "Preference: reviewing plan before execution ([source])". Auto-proceed to `Skill: arn-code:arn-code-review-plan`. After review completes, proceed to Step 9.

- If `skip`: Show status line: "Preference: skipping plan review ([source])". Auto-proceed to Step 9 (Taskify).

- If `ask`: Present the gate below. Do NOT show the "remember this?" follow-up afterward.

- If null (or invalid value): Present the gate below. After the user answers, show the "remember this?" follow-up (see below).

**Gate (shown when value is `ask`, null, or invalid):**

Ask (using `AskUserQuestion`):

**"The structured plan has been created. Review it before execution?"**

Options:
1. **Review plan** (Recommended for complex features) — Validate completeness, consistency, and pattern compliance
2. **Skip** — Proceed to task creation

If **Review plan**: `Skill: arn-code:arn-code-review-plan`
If **Skip**: Proceed to Step 9.

**Follow-up (only when preference was null):** After the user answers the gate, ask:

Ask (using `AskUserQuestion`):

**"Should Arness remember this choice for future sessions?"**

Options:
1. **Yes, always [chosen action]** (saves to preferences)
2. **No, ask me each time**

If **Yes**: Write the chosen value (`review` or `skip`) to `~/.arness/workflow-preferences.yaml` under `pipeline.plan-review`. Create `~/.arness/` directory and file if they do not exist. If the file already exists, read it first, add or update the key under `pipeline:`, and write back preserving all existing keys.
If **No**: Write `ask` to `~/.arness/workflow-preferences.yaml` under `pipeline.plan-review` (same write logic).

---

### Step 9: Taskify (Auto)

Show progress:
```
Planning [thorough]: entry -> scope-router -> spec -> plan -> save -> review-plan -> TASKIFY -> [ready]
                                                                                      ^^^^^^^
```

Inform: "Creating task list..."

> `Skill: arn-code:arn-code-taskify`

Taskify converts TASKS.md into Claude Code tasks with dependency management.

---

### Step 10: Gate G5 — Completion Handoff

Show progress:
```
Planning [thorough]: entry -> scope-router -> spec -> plan -> save -> review-plan -> taskify -> [READY]
                                                                                                 ^^^^^
```

Ask (using `AskUserQuestion`):

**"Planning complete. Your plan is structured and tasks are created. Start implementing?"**

Options:
1. **Start implementing** — Begin execution of the plan
2. **Not yet** — Exit (run `/arn-implementing` when ready)

If **Start implementing**: `Skill: arn-code:arn-implementing`
If **Not yet**: Exit with: "Run `/arn-implementing` when ready to start building."

---

## Sketch Integration

Sketch is invoked from within `arn-code-feature-spec` during the spec exploration phase — not at the planning level. When a feature involves UI and `ui-patterns.md` has a `## Sketch Strategy` section, the feature-spec skill proactively offers sketch to the user during the spec conversation.

No action is needed from arn-planning to manage sketch — it is fully delegated to the spec skill.

---

## Error Handling

- **`## Arness` config missing:** Handled by Step 0 (ensure-config) — this should not occur if Step 0 completed successfully.
- **Issue tracker not configured:** Omit "Pick from backlog" at G1 and "Upload as issue" at G3.
- **Bug-spec simple path (no spec):** "Bug fixed. No planning needed." Offer `/arn-shipping` or exit.
- **Swift or standard redirect from scope router:** Chain to `/arn-implementing` with the selected tier intent. Exit planning.
- **Multiple specs or plans during resume:** List them and ask which to resume.
- **feature-spec-teams unavailable:** Fall back to standard `arn-code-feature-spec`.
- **Sub-skill fails:** Present the error. Ask: retry / skip / abort.
- **User says "stop" or "pause":** Show what was completed. Inform: "Run `/arn-planning` again to resume — artifact detection will pick up where you left off."
