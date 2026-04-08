---
name: arn-spark-visual-readiness
description: >-
  This skill should be used when the user says "visual readiness",
  "check visual layers", "activate visual layer", "visual checkpoint",
  "promote visual testing", "enable layer 2", "visual test health",
  "check deferred layers", "activate deferred layers", "layer promotion",
  or wants to validate and activate deferred visual testing layers
  after project milestones.
version: 1.0.0
---

# Arness Visual Readiness

Validate and activate deferred visual testing layers after project milestones. When `arn-spark-visual-strategy` sets up a multi-layer testing strategy, Layer 1 (typically browser-based capture) is validated and activated immediately. Additional layers (e.g., native window capture) are marked as **deferred** because the project may not yet have the build pipeline, platform access, or tooling required to validate them. This skill is the checkpoint that evaluates whether deferred layers are now ready, validates them with a spike, and promotes them to active.

This is a conversational skill that runs in normal conversation (NOT plan mode). It uses the `arn-spark-visual-test-engineer` agent for layer validation spikes.

The primary artifacts are:
- **Updated CLAUDE.md** -- deferred layers promoted to active with validation evidence
- **Updated strategy document** -- validation results appended per layer
- **Readiness report** -- layer status table with evidence and recommendations

**The core problem this solves:** deferred visual testing layers sit dormant after `arn-spark-visual-strategy` because nothing re-evaluates whether the project has reached the point where those layers can be activated. This skill closes that gap by checking activation criteria, running validation spikes, and promoting layers that pass.

## Prerequisites

Read the project's `CLAUDE.md` for a `## Arness` section. If no `## Arness` section exists or Arness Spark fields are missing, inform the user: "Arness Spark is not configured for this project yet. Run `/arn-brainstorming` to get started — it will set everything up automatically." Do not proceed without it.

Extract:
- **Plans directory**
- **Vision directory** (default: `.arness/vision`)
- **Spikes directory** (default: `.arness/spikes`) -- for validation spike workspaces
- **Git** / **Platform**

Check for `### Visual Testing` subsection:
1. If found: parse all fields (see Step 1 for details)
2. If NOT found: "No visual testing configuration found in CLAUDE.md. Run `/arn-spark-visual-strategy` first to set up your visual testing strategy." Exit.

## Workflow

### Step 1: Load Visual Testing Config

Read CLAUDE.md `### Visual Testing` section.

**Parse top-level fields as Layer 1 config (always active):**
- **Strategy doc:** path to the visual strategy document
- **Baseline directory:** path to baseline images
- **Capture script:** path to the capture script
- **Compare script:** path to the comparison script
- **Layers:** comma-separated list of layer names
- **Diff threshold:** pixel difference tolerance percentage
- **Integration:** manual / npm-script / ci / arness-pipeline

**Scan for `#### Layer N:` subsections.** For each subsection, extract per-layer fields:
- **Status:** active / deferred
- **Capture script:** path to the layer's capture script
- **Compare script:** path to the layer's comparison script
- **Baseline directory:** path to the layer's baselines
- **Diff threshold:** layer-specific threshold (or inherit top-level)
- **Requires dev server:** yes / no
- **Activation criteria:** free-text description of what must be true to activate
- **Environment:** target platform/OS for this layer
- **Spike result:** previous spike outcome (Validated / Partially validated / Failed / Deferred)

Build a layer list with all extracted data. Layer 1 is always the top-level config (implicit, always active). Additional layers come from `#### Layer N:` subsections.

**If no `### Visual Testing` found:** suggest `/arn-spark-visual-strategy` and exit.

**If no deferred layers:** "All visual testing layers are active. No deferred layers to promote." Present a summary table of active layers and suggest `/arn-code-review-implementation` for a full multi-layer quality check. Exit.

### Step 2: Validate Active Layers

For each active layer, verify the existing pipeline still works:

1. Run the layer's capture script against the development build (or prototype if dev build unavailable)
2. Run the layer's compare script against the baselines
3. Check baseline counts against the screen manifest (if `baseline-manifest.json` exists)
4. Report newly capturable screens that lack baselines (screens added since last baseline update)

Present results per active layer:

"**Layer [N] ([Name]) -- Active:**
- Capture: [PASS / FAIL] -- [N] screens captured
- Compare: [PASS / FAIL] -- [N] screens compared, [M] within threshold
- Baselines: [N] baselines / [M] screens in manifest ([coverage]%)
- New screens without baselines: [list or 'none']"

If an active layer's pipeline fails: report it as a **WARNING** but continue. Do not block deferred layer evaluation because an active layer has a transient issue.

### Step 3: Check Activation Criteria

Read the readiness checklist:
> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-visual-readiness/references/readiness-checklist.md`

For each deferred layer:

1. Read the layer's `**Activation criteria:**` field from CLAUDE.md
2. Match the criteria text against the common patterns in the readiness checklist (Build Success, Platform Access, Tool Availability, CI Configuration)
3. Execute the concrete checks for each matching pattern:
   - Run commands to verify tool availability (`which [tool]`, `[tool] --version`)
   - Check for build artifacts at expected paths
   - Test file transfer mechanisms for cross-environment layers
   - Verify CI workflow configuration if relevant
4. Collect evidence for each check
5. **Journey upgrade check** — If the layer has `**Interaction:** static` or no `**Interaction:**` field:
   - Run the UIA Availability readiness pattern (Pattern 6 from readiness-checklist.md)
   - Run the Journey Runner readiness pattern (Pattern 7 from readiness-checklist.md) — skip if no runner exists yet
   - On macOS: run the Accessibility Permissions pattern (Pattern 8 from readiness-checklist.md)
   - If UIA Availability passes (automation framework available, accessibility tree inspectable):

     Inform the user: "This Layer 2 is currently configured for static screenshot capture. The platform's UI automation framework is available, which means journey-based interaction testing is possible. Journey mode walks through the app like a user — clicking buttons, filling forms, navigating screens — and captures screenshots at each step."

     Ask (using `AskUserQuestion`):

     **"Would you like to upgrade to journey interaction mode?"**

     Options:
     1. **Yes** — Upgrade to journey-based interaction testing
     2. **No** — Keep static screenshot capture

   - Record the user's choice. If yes, mark the layer for journey upgrade in Step 5.
   - If UIA Availability fails, do not suggest the upgrade — static mode remains appropriate.

Present status per layer:

"**Layer [N] ([Name]):** Criteria '[activation criteria text]'
- [Check 1]: [PASS / FAIL] -- [evidence]
- [Check 2]: [PASS / FAIL] -- [evidence]
- **Overall: [MET / NOT MET]**"

If ambiguous (e.g., a tool is installed but version is uncertain, or platform access is partial): ask the user for explicit confirmation rather than assuming.

### Step 4: Validate Deferred Layers

For each deferred layer whose activation criteria are met:

**IMPORTANT: Run validation spikes sequentially, one at a time.** Do NOT launch multiple `arn-spark-visual-test-engineer` agents in parallel or in the background. The agent needs Bash and Write tool access, which requires user permission approval. Parallel or background agents cannot surface permission prompts to the user, causing all tool calls to be denied.

For each qualifying layer:

1. Read the spike checklist:
   > Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-visual-strategy/references/spike-checklist.md`

2. Determine the spike workspace: `[spikes-dir]/visual-readiness-spike-layer-[N]/`

3. Invoke the `arn-spark-visual-test-engineer` agent (foreground, not background) with:
   - Layer specification (name, capture approach, environment, scripts)
   - Stack details from the strategy document
   - Environment constraints
   - Dev server URL or build path
   - Spike workspace path
   - Baseline screenshots for comparison (if available)
   - Spike checklist criteria for the specific layer
   - Existing scripts from the deferred layer config (if any were pre-created during `arn-spark-visual-strategy`)

4. Wait for the agent to complete fully before proceeding to the next layer.

5. Present results using the same classification as `arn-spark-visual-strategy`:
   - **Validated:** "Layer [N] works. [Evidence: captured screenshots match baselines within threshold.]"
   - **Partially validated:** "Layer [N] works with caveats. [Evidence + caveats, e.g., anti-aliasing noise above expected threshold.]"
   - **Failed:** "Layer [N] does not work in this environment. [Evidence + reason.] Should I investigate an alternative approach?"
   - **Deferred:** "Layer [N] still cannot be tested here. [Required environment + instructions.] Leaving as deferred."

6. Proceed to the next layer only after presenting results.

### Step 5: Promote Layers

For each deferred layer that was partially validated, ask before promoting:

Ask (using `AskUserQuestion`):

> **Layer [N] ([Name]) validated with caveats: [caveats]. Promote to active?**
> 1. **Yes** — Promote to active with caveats noted
> 2. **No** — Leave as deferred

For each deferred layer that was validated (Validated or user-approved Partially validated):

1. Update CLAUDE.md `#### Layer N:` subsection:
   - Change `**Status:** deferred` to `**Status:** active`
   - Add `**Validated:** [YYYY-MM-DD]` with today's date
   - Update `**Spike result:**` with the validation evidence summary

2. For layers that failed validation: leave as `**Status:** deferred`, report the reason.

3. **Journey upgrade** — If the user accepted the journey upgrade suggestion in Step 3:
   a. Update the layer's `**Interaction:**` field from `static` to `journey` in CLAUDE.md
   b. Add `**Journey manifest:**` field with path `<baselines-dir>/layer-2/journey-manifest.json`
   c. Add `**Journey runner:**` field with path `scripts/journey-runner.<ext>` (`.ps1` for Windows, `.swift` or `.applescript` for macOS)
   d. Invoke `arn-spark-visual-test-engineer` agent with:
      - Journey schema reference: `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-visual-strategy/references/journey-schema.md`
      - Journey manifest output path: the path from step (b)
      - Target platform: detected from the layer's `**Environment:**` field
      - Accessibility tree hints: any automation IDs discovered during the UIA Availability check
   e. Wait for the agent to generate the journey manifest and runner script
   f. Run the Journey Runner readiness pattern to validate the generated artifacts
   g. Update `**Spike result:**` to include journey validation evidence

4. For layers that remained deferred (criteria not met): leave unchanged, report which criteria were not met.

Present the changes:

"**CLAUDE.md updated:**
- Layer [N] ([Name]): deferred -> **active** (validated [date])
- Layer [M] ([Name]): remains **deferred** (reason: [criteria not met / validation failed])"

### Step 6: Update Strategy Document

Read the strategy document path from the `**Strategy doc:**` field in `### Visual Testing`.

1. Read the strategy document
2. For each layer that was validated in this session:
   - Find the `### Layer N:` section in the strategy document
   - Update the spike result with new validation evidence
   - Add a `#### Readiness Check ([date])` subsection documenting:
     - Activation criteria evaluation results
     - Spike validation results
     - Status change (deferred -> active, or still deferred with reason)
3. Write the updated strategy document

If the strategy document is not found at the configured path: warn and skip this step. Proceed with remaining steps.

### Step 7: Update .gitignore

Check if Git is configured (from `## Arness` config or by checking for `.git/`). If not configured, skip this step silently.

If Git is configured and newly activated layers produce output directories:

1. Inventory directories referenced by the newly activated layers (captures, diffs, spike workspaces)
2. Classify each path as **ephemeral** (regenerated on every run, machine-specific) or **shared** (baselines, scripts, manifests)
3. Read the project's `.gitignore` and check which paths are already covered
4. Present the classification to the user:

"The newly activated layer(s) reference these paths:

| Path | Type | Recommendation | Currently in .gitignore |
|------|------|----------------|------------------------|
| [path] | [ephemeral / shared] | [ignore / track] | [yes / no] |
| ... | ... | ... | ... |

Ask (using `AskUserQuestion`):

> **Proceed with these .gitignore recommendations?**
> 1. **Yes** — Apply the recommendations
> 2. **Adjust** — Let me specify which paths to change"

5. Wait for user confirmation or adjustments. If **Adjust**, collect changes as free-form text.
6. Add confirmed paths to `.gitignore` under a `# Visual testing -- Layer [N]` comment block

### Step 8: Summary

Present the readiness report:

"**Visual Readiness Report**

**Layer Status:**

| Layer | Name | Previous Status | Current Status | Evidence |
|-------|------|----------------|----------------|----------|
| 1 | [Name] | active | active | [capture/compare health] |
| 2 | [Name] | deferred | [active/deferred] | [validation result or criteria status] |
| ... | ... | ... | ... | ... |

**Screen Coverage:**
- Screen manifest: [N] screens
- Layer 1: [N] capturable / [M] baselined
- Layer 2: [N] capturable / [M] baselined (if newly active)

**Recommendations:**
- [Action items based on results, e.g., 'Update Layer 1 baselines for 3 new screens', 'Re-evaluate Layer 2 after Windows CI runner is configured']

Run `/arn-code-review-implementation` to execute a full multi-layer quality check with all active layers."

## Agent Invocation Guide

| Situation | Action |
|-----------|--------|
| Validate a deferred layer (Step 4) | Invoke `arn-spark-visual-test-engineer` sequentially (foreground, not background) with layer spec, environment, workspace, spike checklist. Wait for completion before the next layer. |
| Agent permission denied | Re-run `arn-spark-visual-test-engineer` in foreground. If still denied, execute validation directly in conversation (write POC files and run capture commands yourself). |
| User asks about initial visual setup | Defer: "Initial visual testing setup is handled by `/arn-spark-visual-strategy`." |
| User asks about quality gate | Defer: "The multi-layer quality gate runs during `/arn-code-review-implementation`." |
| User asks about specific layer tooling | Discuss and invoke `arn-spark-tech-evaluator` if a deep comparison is needed. |
| Cross-environment validation deferred | Record the deferral with instructions. Leave layer as deferred with updated evidence. |

## Error Handling

- **No `### Visual Testing` in CLAUDE.md** -- suggest running `/arn-spark-visual-strategy` first to set up visual testing. Exit without further action.
- **No deferred layers** -- report all layers active, present a summary table, suggest `/arn-code-review-implementation` for a full multi-layer quality check. Exit.
- **Spike validation fails** -- leave the layer as deferred, record the failure reason and evidence. Suggest manual investigation or alternative approaches.
- **Agent permission denied** -- re-run `arn-spark-visual-test-engineer` in foreground. If still denied, execute validation directly in conversation (write POC files and run capture commands).
- **Criteria ambiguous** -- ask the user for explicit confirmation rather than assuming. Present the evidence collected and let the user decide.
- **Strategy document not found at configured path** -- warn and skip Step 6. Proceed with remaining steps (CLAUDE.md update, gitignore, summary).
- **Build command fails during validation** -- record the failure evidence (exit code, error output). Leave the layer as deferred. Report the build error and suggest investigating the build pipeline.
