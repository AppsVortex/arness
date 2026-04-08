---
name: arn-brainstorming
description: >-
  This skill should be used when the user says "brainstorming", "arn brainstorming",
  "brainstorm", "let's brainstorm", "start brainstorming", "brainstorming session",
  "greenfield wizard", "arn spark wizard", "greenfield pipeline",
  "walk me through greenfield", "guided greenfield", "full greenfield pipeline",
  "greenfield flow", "explore to feature backlog", "greenfield start to finish",
  "run the greenfield pipeline", "guide me through greenfield", "greenfield guided mode",
  "greenfield setup", "new project wizard", "add a feature", "new feature",
  "I need another feature", "add feature to greenfield", "one more feature",
  or wants to be walked through the entire Arness greenfield exploration pipeline
  in a single continuous session with guided decision gates instead of invoking
  each skill manually. Also triggers when the user wants to add a new feature
  to an existing greenfield project after the clickable prototype is complete.
version: 1.0.0
---

# Arness Brainstorming

Walk the user through the entire Arness greenfield exploration pipeline in a single continuous session. The wizard invokes each pipeline skill in sequence using the Skill tool, only pausing at genuine decision gates where user input is needed. Conversational skills (discover, arch-vision) have internal feedback loops and flow without wizard-level gates.

This skill is a **sequencer and decision-gate handler**. It MUST NOT duplicate sub-skill logic. All pipeline work is done by the invoked skills. The wizard handles: entry routing, transitions between skills, progress display, and resumability.

## Step 0: Ensure Configuration

Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-ensure-config/references/ensure-config.md` and follow its instructions. This guarantees a user profile exists and `## Arness` is configured with Arness Spark fields before proceeding.

After Step 0 completes, extract from `## Arness`:
- Vision directory, Use cases directory, Prototypes directory, Spikes directory, Visual grounding directory, Reports directory

## Decision Gates

The wizard pauses at exactly 9 gates. Everything else flows automatically.

| Gate | When | Question | Options |
|------|------|----------|---------|
| G1 | Entry (artifacts detected) | "It looks like you have an in-progress greenfield pipeline. Resume or start fresh?" | Resume from [detected stage] / Start fresh |
| G-Stress | After discover | "Run stress tests on the product concept?" then "Select which stress tests to run" | Yes/Skip; then multi-select: Interview, Competitive, Pre-Mortem, PR/FAQ |
| G-Name | After stress-test/concept-review | "Explore brand names for your product?" | Yes / Skip |
| G2 | After arch-vision | "Write use cases before scaffolding?" | Write use cases (recommended) / Write use cases with expert debate (teams) / Skip to scaffold |
| G3 | After scaffold | "Validate technical risks before visual design?" | Run spikes (recommended if risks found) / Skip to visual sketch |
| G4 | Pre-prototype | "How should prototypes be validated?" | Standard review cycles / Expert debate (teams) for both / Expert debate (teams) for clickable only |
| G5 | After clickable prototype | "Lock the prototype and extract features?" | Lock prototype then extract features (recommended) / Extract features without locking / Review prototype first |
| G6 | After feature extraction | "Transition to development pipeline?" | Yes, run /arn-planning / Not yet |
| G7 | Entry (add-feature intent + completed prototype) | "Adding a new feature. This will update use cases, iterate the prototype, and add to the feature backlog. Ready?" | Proceed / Choose which steps to include / Cancel |

## Workflow

### Step 0.5: Extract Configuration

1. Read the project's CLAUDE.md `## Arness` section (guaranteed to exist after Step 0).
2. Extract configuration fields needed for artifact detection:
   - **Vision directory** — for detecting product concept, architecture vision, scaffold summary, spike results, style brief, visual direction, feature backlog
   - **Use cases directory** — for detecting use case files
   - **Prototypes directory** — for detecting static and clickable prototype reports
   - **Spikes directory** — for detecting spike POC directories
   - **Visual grounding directory** — for detecting captured design references
   - **Reports directory** — for detecting stress test reports and concept review report

### Step 1: Detect Pipeline State (Resumability)

Check which artifacts exist on disk to determine if the user is resuming a previous pipeline run. Check from most advanced to least advanced — first match wins:

| Artifact | Detected State | Resume Point |
|----------|---------------|--------------|
| User says "add feature" / "new feature" AND `<prototypes-dir>/clickable/final-report.md` exists | Add Feature mode | Start at Add Feature Mode (Step AF) |
| `<vision-dir>/features/feature-backlog.md` | Feature extraction complete | Resume at G6 |
| `<prototypes-dir>/locked/LOCKED.md` exists AND NO `<vision-dir>/features/feature-backlog.md` | Prototype locked, extraction pending | Resume at feature-extract directly (invoke `arn-spark-feature-extract`, skip G5 lock step — already locked) |
| `F-*.md` files in `<vision-dir>/features/` but NO `<vision-dir>/features/feature-backlog.md` | Feature extraction interrupted | Resume at feature-extract (invoke to complete/rebuild the Feature Tracker) |
| `<prototypes-dir>/clickable/final-report.md` | Clickable prototype done | Resume at G5 |
| `<prototypes-dir>/static/final-report.md` | Static prototype done | Resume at clickable prototype (Step 9b) |
| `<vision-dir>/style-brief.md` | Style defined | Resume at static prototype (Step 9a) |
| `<vision-dir>/visual-direction.md` | Visual direction chosen | Resume at style-explore (Step 8) |
| `<vision-dir>/spike-results.md` | Spike complete | Resume at visual-sketch (Step 7) |
| `<vision-dir>/scaffold-summary.md` | Scaffold built | Resume at G3 |
| `UC-*.md` in `<use-cases-dir>/` | Use cases written | Resume at scaffold (Step 5) |
| `<vision-dir>/architecture-vision.md` | Architecture defined | Resume at G2 |
| `<reports-dir>/stress-tests/concept-review-report.md` AND `<vision-dir>/naming-brief.md` with "Final Decision" section populated | Concept review + naming complete | Resume at arch-vision (Step 3) |
| `<reports-dir>/stress-tests/concept-review-report.md` AND `<vision-dir>/naming-brief.md` exists but no "Final Decision" section | Naming in progress | Resume at G-Name (naming skill handles internal resume) |
| `<reports-dir>/stress-tests/concept-review-report.md` AND NO `<vision-dir>/naming-brief.md` | Concept review complete, naming not started | Resume at G-Name |
| Any stress test report (`interview-report.md`, `competitive-report.md`, `premortem-report.md`, `prfaq-report.md`) in `<reports-dir>/stress-tests/` but NO `concept-review-report.md` | Stress tests run, review pending | Resume at concept review offer within G-Stress |
| `<vision-dir>/product-concept.md` | Product discovered | Resume at G-Stress |
| Greenfield fields but no artifacts | Greenfield initialized | Begin at discover (Step 2) |

**If artifacts are detected:**

Show the detected state and ask:

Ask (using `AskUserQuestion`):

> **It looks like you have an in-progress greenfield pipeline at [detected stage]. Would you like to resume or start fresh?**
> 1. **Resume from [detected stage]** — Skip to the detected resume point
> 2. **Start fresh** — Begin at Step 2 (existing artifacts are preserved)

**If ambiguous or conflicting artifacts are detected** (e.g., architecture-vision.md exists but no product-concept.md, or multiple conflicting states): list the detected artifacts and ask the user to clarify which state to resume from.

**If no artifacts detected:** skip G1 and proceed directly to Step 2.

---

### Step 2: Product Discovery (Automated)

Show progress:
```
Spark Pipeline: DISCOVER --> stress-test --> naming --> arch-vision --> use-cases --> scaffold --> spike --> visual-sketch --> style-explore --> prototypes --> feature-extract
                ^^^^^^^^
```

Inform the user: "Let's start by shaping your product idea..."

> `Skill: arn-spark:arn-spark-discover`

The discover skill has its own internal conversation loop with the product strategist agent. When it completes, `product-concept.md` exists in the vision directory.

---

### Step 2.5: Gate G-Stress — Stress Test Decision

Show progress:
```
Spark Pipeline: discover --> STRESS-TEST --> naming --> arch-vision --> use-cases --> scaffold --> spike --> visual-sketch --> style-explore --> prototypes --> feature-extract
                            ^^^^^^^^^^^
```

**Step 1 of gate — Explain and ask:**

Briefly explain stress testing and each available test:

"Before committing to an architecture, you can stress-test the product concept to validate assumptions and identify blind spots. Four tests are available:

1. **Synthetic User Interview** — Generates synthetic personas (Pragmatist, Skeptic, Power User) from your product concept and conducts structured interviews to surface usability concerns and unmet needs.
2. **Competitive Gap Analysis** — Deep feature-by-feature comparison against identified competitors, revealing gaps in your positioning and missed opportunities.
3. **Pre-Mortem** — Assumes the product has already failed and investigates the most likely root causes, using Gary Klein's pre-mortem framework.
4. **PR/FAQ** — Drafts a press release for your product and then adversarially critiques it, exposing weak value propositions and messaging gaps.

Stress testing is optional but recommended — it validates WHAT you are building before committing to HOW."

Ask (using `AskUserQuestion`):

**"Run stress tests on the product concept?"**

Options:
1. **Yes, run stress tests** (Recommended) — Validate the concept before architecture
2. **Skip to architecture vision** — Proceed without stress testing

If **Skip** → proceed to Step 3 (arch-vision).

**Step 2 of gate — Multi-select:**

Ask (using `AskUserQuestion` with `multiSelect: true`):

**"Select which stress tests to run (select all that apply):"**

Options:
1. **Synthetic User Interview** — Persona-driven interviews revealing usability concerns
2. **Competitive Gap Analysis** — Feature comparison against competitors
3. **Pre-Mortem** — Investigate likely causes of product failure
4. **PR/FAQ** — Draft and adversarially critique a press release

Invoke each selected stress test skill in sequence:

- If Interview selected → `Skill: arn-spark:arn-spark-stress-interview`
- If Competitive selected → `Skill: arn-spark:arn-spark-stress-competitive`
- If Pre-Mortem selected → `Skill: arn-spark:arn-spark-stress-premortem`
- If PR/FAQ selected → `Skill: arn-spark:arn-spark-stress-prfaq`

**After all selected tests complete:**

"Stress tests complete. [N] report(s) generated. Run concept review to synthesize findings into product concept updates?"

Ask (using `AskUserQuestion`):

**"Review and update the product concept based on stress test findings?"**

Options:
1. **Yes, review and update concept** (Recommended) — Synthesize findings and propose concept changes
2. **Skip** — Keep concept as-is and proceed to architecture vision

If **Yes** → `Skill: arn-spark:arn-spark-concept-review`. After concept review completes, proceed to Step 2.7 (G-Name).

If **Skip** → proceed to Step 2.7 (G-Name).

---

### Step 2.7: Gate G-Name — Brand Naming Decision

Show progress:
```
Spark Pipeline: discover --> stress-test --> NAMING --> arch-vision --> use-cases --> scaffold --> spike --> visual-sketch --> style-explore --> prototypes --> feature-extract
                                             ^^^^^^
```

Ask (using `AskUserQuestion`):

**"Would you like to explore brand names for your product?"**

Options:
1. **Yes, find a name** (Recommended) — Run the structured 4-step naming process
2. **Skip** — I already have a name or will name it later

If **Yes** → `Skill: arn-spark:arn-spark-naming`. After naming completes, proceed to Step 3 (arch-vision).

If **Skip** → proceed to Step 3 (arch-vision).

---

### Step 3: Architecture Vision (Automated)

Show progress:
```
Spark Pipeline: discover --> stress-test --> naming --> ARCH-VISION --> use-cases --> scaffold --> spike --> visual-sketch --> style-explore --> prototypes --> feature-extract
                                                       ^^^^^^^^^^^
```

Inform the user: "Product concept is ready. Now let's explore the architecture..."

> `Skill: arn-spark:arn-spark-arch-vision`

The arch-vision skill has its own internal conversation loop with the tech evaluator agent. When it completes, `architecture-vision.md` exists in the vision directory.

---

### Step 4: Gate G2 — Use Cases Decision

Show progress:
```
Spark Pipeline: discover --> stress-test --> naming --> arch-vision --> USE-CASES --> scaffold --> spike --> visual-sketch --> style-explore --> prototypes --> feature-extract
                                                                                       ^^^^^^^^^
```

Ask (using `AskUserQuestion`):

**"Architecture vision is complete. Write use cases before scaffolding?"**

Options:
1. **Write use cases** (Recommended) — Structured behavioral requirements in Cockburn format
2. **Write use cases with expert debate** (Teams) — Multi-agent debate format with product strategist and UX specialist
3. **Skip to scaffold** — Proceed without formal use cases

Based on the user's choice:

- **Write use cases** → `Skill: arn-spark:arn-spark-use-cases`
- **Expert debate** → `Skill: arn-spark:arn-spark-use-cases-teams`
- **Skip** → mark use-cases as skipped and proceed to Step 5

---

### Step 5: Scaffold (Automated)

Show progress:
```
Spark Pipeline: discover --> stress-test --> naming --> arch-vision --> use-cases --> SCAFFOLD --> spike --> visual-sketch --> style-explore --> prototypes --> feature-extract
                                                                                                 ^^^^^^^^
```

Inform the user: "Setting up the project skeleton with the chosen tech stack..."

> `Skill: arn-spark:arn-spark-scaffold`

The scaffold skill creates the project structure, installs dependencies, and produces a buildable project. When it completes, `scaffold-summary.md` exists in the vision directory.

---

### Step 6: Gate G3 — Spike Decision

Show progress:
```
Spark Pipeline: discover --> stress-test --> naming --> arch-vision --> use-cases --> scaffold --> SPIKE --> visual-sketch --> style-explore --> prototypes --> feature-extract
                                                                                                         ^^^^^
```

Before asking, read `architecture-vision.md` from the vision directory and check for a "Risks" or "Known Risks" section. Count the number of identified risks.

Ask (using `AskUserQuestion`):

**"Scaffold complete. Validate technical risks before moving to visual design?"**

Options (if risks were found in architecture vision):
1. **Run spikes** (Recommended — [N] risks identified in architecture vision) — Validate risky assumptions with proof-of-concept code
2. **Skip to visual sketch** — Proceed to visual design without risk validation

Options (if no risks section found):
1. **Run spikes anyway** — Validate key assumptions even though no explicit risks were documented
2. **Skip to visual sketch** (Recommended) — Proceed to visual design

If **Run spikes:**
> `Skill: arn-spark:arn-spark-spike`

If **Skip:** mark spike as skipped and proceed to Step 7.

---

### Step 7: Visual Sketch (Automated)

Show progress:
```
Spark Pipeline: discover --> stress-test --> naming --> arch-vision --> use-cases --> scaffold --> spike --> VISUAL-SKETCH --> style-explore --> prototypes --> feature-extract
                                                                                                          ^^^^^^^^^^^^^
```

Inform the user: "Generating visual direction proposals..."

> `Skill: arn-spark:arn-spark-visual-sketch`

The visual-sketch skill generates multiple direction proposals as live pages on the dev server. When it completes, `visual-direction.md` exists in the vision directory.

---

### Step 8: Style Explore (Automated)

Show progress:
```
Spark Pipeline: discover --> stress-test --> naming --> arch-vision --> use-cases --> scaffold --> spike --> visual-sketch --> STYLE-EXPLORE --> prototypes --> feature-extract
                                                                                                                            ^^^^^^^^^^^^^
```

Inform the user: "Defining the design system from the chosen visual direction..."

> `Skill: arn-spark:arn-spark-style-explore`

The style-explore skill defines color palettes, typography, component styles, and toolkit configuration. When it completes, `style-brief.md` exists in the vision directory.

---

### Step 9: Gate G4 — Prototype Validation Mode

Show progress:
```
Spark Pipeline: discover --> stress-test --> naming --> arch-vision --> use-cases --> scaffold --> spike --> visual-sketch --> style-explore --> PROTOTYPES --> feature-extract
                                                                                                                                          ^^^^^^^^^^
```

Ask (using `AskUserQuestion`):

**"Style system defined. How should prototypes be validated?"**

Options:
1. **Standard review cycles** — Build-review-iterate with expert scoring and UX judge verdict
2. **Expert debate (teams) for both** — Multi-agent debate for static and clickable prototypes
3. **Expert debate (teams) for clickable only** — Standard for static, debate for clickable

Based on choice, invoke the prototype skills in sequence:

**Standard:**
> `Skill: arn-spark:arn-spark-static-prototype`
> Then: `Skill: arn-spark:arn-spark-clickable-prototype`

**Teams for both:**
> `Skill: arn-spark:arn-spark-static-prototype-teams`
> Then: `Skill: arn-spark:arn-spark-clickable-prototype-teams`

**Teams for clickable only:**
> `Skill: arn-spark:arn-spark-static-prototype`
> Then: `Skill: arn-spark:arn-spark-clickable-prototype-teams`

After each prototype skill completes, show an intermediate progress update before invoking the next.

---

### Step 10: Gate G5 — Post-Prototype Actions

Show progress:
```
Spark Pipeline: discover --> stress-test --> naming --> arch-vision --> use-cases --> scaffold --> spike --> visual-sketch --> style-explore --> prototypes --> FEATURE-EXTRACT
                                                                                                                                                            ^^^^^^^^^^^^^^^
```

Before asking, check if `<prototypes-dir>/locked/LOCKED.md` exists.

**If prototype is already locked:**

"Prototype is already locked (see `prototypes/locked/LOCKED.md`). Proceeding directly to feature extraction."

> `Skill: arn-spark:arn-spark-feature-extract`

Skip the G5 question — locking is already done. After feature-extract completes, proceed to G6.

**If prototype is NOT locked:**

Ask (using `AskUserQuestion`):

**"Prototype validation complete. What next?"**

Options:
1. **Lock prototype and extract features** (Recommended) — Protect the validated prototype, then build the feature backlog
2. **Extract features without locking** — Build the backlog without prototype protection
3. **Review prototype first** — Look at the validation results before deciding

If **Lock and extract:**
> `Skill: arn-spark:arn-spark-prototype-lock`
> Then: `Skill: arn-spark:arn-spark-feature-extract`

If **Extract without locking:**
> `Skill: arn-spark:arn-spark-feature-extract`

If **Review first:**
- Read the final reports from both static and clickable prototype directories
- Present a summary of the validation results (verdicts, scores, key findings)
- Then re-ask: "Lock and extract, or extract only?"

---

### Step 11: Gate G6 — Transition to Development

Show progress:
```
Spark Pipeline: discover --> stress-test --> naming --> arch-vision --> use-cases --> scaffold --> spike --> visual-sketch --> style-explore --> prototypes --> feature-extract
                       ✓            ✓              ✓              ✓             ✓           ✓           ✓                ✓               ✓               ✓
```

Before asking about transition, check if features have been uploaded to the issue tracker:

1. Read `## Arness` config for **Issue tracker** field (`github`, `jira`, or `none`). If not present, treat as `none`.
2. If Issue tracker is `none`: skip this check.
3. If Issue tracker is `github` or `jira`:
   a. Read `<vision-dir>/features/feature-backlog.md` and check the Feature Tracker table's Issue column.
   b. If ALL features have `--` in the Issue column (none uploaded):

      Ask (using `AskUserQuestion`):

      > **Your feature backlog has [N] features but none have been uploaded to [GitHub/Jira] yet. Would you like to upload them now?** This creates issues for team visibility and enables `/arn-code-pick-issue` for feature selection.
      > 1. **Upload now** — Create issues for all features
      > 2. **Skip** — Continue without uploading

      If **Upload now** → `Skill: arn-spark:arn-spark-feature-extract` (the skill detects existing features and runs Step 7 upload)
      If **Skip** → Continue to transition question

   c. If SOME features have issue numbers (partial upload):

      Ask (using `AskUserQuestion`):

      > **[M] of [N] features have been uploaded to [GitHub/Jira]. Would you like to upload the remaining [K]?**
      > 1. **Upload remaining** — Create issues for the remaining features
      > 2. **Skip** — Continue without uploading

      If **Upload remaining** → `Skill: arn-spark:arn-spark-feature-extract`
      If **Skip** → Continue to transition question

   d. If ALL features have issue numbers: skip this check silently.

Then proceed:

Ask (using `AskUserQuestion`):

**"Greenfield exploration is complete. Feature backlog is ready. Transition to the development pipeline?"**

Options:
1. **Yes, start developing** — Run `/arn-planning` to begin planning features from the backlog. Arness auto-configures code patterns, plans, specs, and report templates on first use.
2. **Not yet** — Stay in greenfield mode; transition later

If **Yes:**
> `Skill: arn-code:arn-planning`

If **Not yet:**
- Show what was completed
- Inform: "Run `/arn-planning` when ready to transition. Arness auto-configures on first use. Your greenfield artifacts are preserved."

---

### Step 12: Complete

Show final progress:
```
Spark Pipeline: discover --> stress-test --> naming --> arch-vision --> use-cases --> scaffold --> spike --> visual-sketch --> style-explore --> prototypes --> feature-extract
                       ✓            ✓              ✓              ✓             ✓           ✓           ✓                ✓               ✓               ✓
```

Present a completion summary:
- **Product concept:** `<vision-dir>/product-concept.md`
- **Brand name:** `<vision-dir>/naming-brief.md` — [chosen name] (or "skipped")
- **Architecture:** `<vision-dir>/architecture-vision.md`
- **Use cases:** [count] use cases in `<use-cases-dir>/` (or "skipped")
- **Scaffold:** `<vision-dir>/scaffold-summary.md`
- **Spikes:** `<vision-dir>/spike-results.md` (or "skipped")
- **Visual direction:** `<vision-dir>/visual-direction.md`
- **Style:** `<vision-dir>/style-brief.md`
- **Static prototype:** `<prototypes-dir>/static/final-report.md`
- **Clickable prototype:** `<prototypes-dir>/clickable/final-report.md`
- **Prototype lock:** [yes / no]
- **Feature backlog:** `<vision-dir>/features/feature-backlog.md` — [feature count] features
- **Development transition:** [initialized / deferred]

"Pipeline complete. Run `/arn-brainstorming` again to re-explore, or `/arn-planning` for the development pipeline."

---

### Add Feature Mode

Triggered when the user wants to add a new feature to a completed greenfield project. This mode sequences the incremental update skills in dependency order: use cases provide the behavioral foundation, the prototype validates the UI, and feature extraction adds to the backlog. Handles locked prototypes by iterating to a new version and re-locking.

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-brainstorming/references/add-feature-flow.md` for the full Add Feature mode workflow.

---

## Error Handling

- **Sub-skill fails or errors out:** Present the error to the user. Ask (using `AskUserQuestion`): retry this step / skip this step / abort the wizard. If retry, re-invoke the same skill. If skip, continue to the next gate. If abort, show what was completed and exit.
- **User says "stop" or "pause":** Show what has been completed and what's next. Inform the user they can resume by running `/arn-brainstorming` again (artifact detection will pick up where they left off).
- **Arness greenfield not initialized:** Handled by Step 0 ensure-config, which auto-configures with sensible defaults.
- **Architecture vision has no risks section at G3:** Adjust the spike recommendation — default suggestion becomes "Skip" instead of "Run spikes". Show: "No explicit risks identified in the architecture vision."
- **Scaffold fails to build:** The scaffold skill has its own error handling with retries. If it ultimately fails, ask: retry scaffold / abort wizard. Do not skip scaffold — it is required for all subsequent visual steps.
- **Prototype validation does not reach PASS verdict:** After the sub-skill returns, inform the user: "The prototype did not reach a PASS verdict. Continue to feature extraction anyway, or iterate more on the prototype?" If iterate: re-invoke the prototype skill. If continue: proceed to G5.
- **arn-spark plugin not installed:** If skill invocations fail because the greenfield plugin is missing, inform: "The arn-spark plugin must be installed. Run `/plugin install arn-spark@arn-marketplace`."
- **Teams variant not available at G2 or G4:** If the user selects a teams variant but the environment does not support Agent Teams (CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1), inform them and suggest the standard option instead.
- **Product concept already exists when starting fresh:** The discover skill handles this internally (asks to replace or refine). The wizard does not need separate handling.
- **Add Feature mode invoked without completed prototype:** Redirect to normal wizard flow. Inform: "Add Feature mode requires a completed clickable prototype. Let's start with the full pipeline instead."
- **Locked prototype during Add Feature:** The lock protects the frozen snapshot, not the working directory. Prototype iteration creates a new version alongside the locked one. After iteration, the wizard offers to re-lock with the new version.
- **Feature extraction interrupted (partial feature files exist without Feature Tracker):** Detected by finding `F-*.md` files in the features directory without `feature-backlog.md`. Invoke `arn-spark-feature-extract` which handles resume and rebuilds the Feature Tracker from existing feature files.
- **Features not uploaded to issue tracker:** Detected at G6 by checking the Feature Tracker's Issue column. If all entries show `--`, offer to upload before transitioning to development.

## Constraints

- This skill MUST NOT duplicate sub-skill logic. It only handles sequencing and decision gates.
- All pipeline work is done by the invoked skills via the Skill tool.
- Progress display uses the compact format shown above — one line showing the full pipeline with the current stage highlighted.
- The wizard runs in normal conversation (not plan mode).
- Skill invocations use the Skill tool with fully qualified names: `Skill: arn-spark:arn-spark-<name>` for greenfield skills, `Skill: arn-code:arn-planning` for the development pipeline transition.
- Add Feature mode uses the same sub-skill invocation pattern as the main pipeline.
- Add Feature mode never unlocks or modifies a locked prototype snapshot. It iterates to a new version and optionally re-locks.
