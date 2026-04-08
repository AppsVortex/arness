---
name: arn-spark-visual-strategy
description: >-
  This skill should be used when the user says "visual strategy",
  "arn visual strategy", "visual testing", "visual regression",
  "screenshot testing", "compare to prototype", "visual validation",
  "how do I test visuals", "set up visual tests", "baseline images",
  "screenshot comparison", "pixel diff", "visual diff",
  "does it match the prototype",
  or wants to set up visual regression testing for development — creating
  capture scripts, comparison scripts, and baseline images so that feature
  implementations are automatically compared against prototype screenshots
  to catch visual regressions during development.
version: 1.0.0
---

# Arness Visual Strategy

Set up automated visual regression testing so that **during feature development**, each implemented screen can be compared pixel-by-pixel against the approved prototype screenshots. The prototype screenshots serve as **baseline images** — the "gold standard" of what the UI should look like. As features are built, capture scripts take screenshots of the development build and comparison scripts diff them against these baselines, catching layout breaks, color mismatches, and misplaced elements before they reach the user.

This is a conversational skill that runs in normal conversation (NOT plan mode). It uses the `arn-spark-visual-test-engineer` agent for proof-of-concept validation and script generation.

The primary artifacts are:
- **Capture script** — takes screenshots of the development build (NOT the prototype)
- **Comparison script** — diffs development screenshots against prototype baselines
- **Baseline images** — copied from prototype screenshots, used as the reference standard
- **CLAUDE.md configuration** — integrates visual testing into the Arness execution pipeline so that `/arn-code-execute-plan` and `/arn-code-execute-task` automatically validate UI changes

**The core problem this solves:** during feature development, visual regressions (button on the wrong side, layout breaks, color mismatches) go undetected until the user manually inspects the application. This skill sets up the tooling so that every UI task automatically compares the development build against the prototype.

## Prerequisites

Read the project's `CLAUDE.md` for a `## Arness` section. If no `## Arness` section exists or Arness Spark fields are missing, inform the user: "Arness Spark is not configured for this project yet. Run `/arn-brainstorming` to get started — it will set everything up automatically." Do not proceed without it.

Extract:
- **Vision directory** (default: `.arness/vision`)
- **Prototypes directory** (default: `.arness/prototypes`)
- **Spikes directory** (default: `.arness/spikes`) -- for mini-spike workspaces
- **Git** / **Platform**

Check for prototype lock (strongly recommended):
1. Check for `### Prototype Lock` in the `## Arness` section
2. If found: read the locked directory path and the `LOCKED.md` manifest
3. If NOT found: warn the user -- "No prototype lock detected. Visual testing compares against the prototype, but the prototype is not currently protected from modification. Consider running `/arn-spark-prototype-lock` first."

Check for prototype validation evidence:
- `[prototypes-dir]/clickable/final-report.md`
- `[prototypes-dir]/static/final-report.md`
- Scan for showcase screenshots: `[prototypes-dir]/clickable/v[N]/showcase/screens/`, journey screenshots, static showcase screenshots

Check for architecture vision (required for stack analysis):
- Read `architecture-vision.md` for framework, application type, platform targets

Check for dev-setup document (for environment constraints):
- Read `dev-setup.md` for development environment type, platforms, and CI configuration

**If no architecture vision:** "No architecture vision found. Describe your technology stack and target platforms so I can design a visual testing strategy."

**If no prototype screenshots:** "No prototype screenshots found. Visual testing needs reference images. Either run the prototype skills first, or provide screenshots manually."

## Workflow

### Step 1: Analyze the Stack and Environment

Load context from architecture vision, dev-setup, and the current environment. Detect the current OS via `uname`. Build a constraints profile:

"Here is what I understand about your stack and environment:

**Application type:** [Browser app / Tauri desktop / Electron desktop / etc.]
**UI framework:** [SvelteKit / React / Vue / etc.]
**Rendering context:** [Browser viewport / Webview in native frame / Native window with transparency / etc.]
**Platform targets:** [Linux, macOS, Windows]
**Development environment:** [Native / WSL2 / Dev container / etc.]
**Current OS:** [detected via uname]

**Key constraints:**
- [Constraint 1: e.g., 'Tauri with transparency -- native window compositing cannot be captured by browser-based tools']
- [Constraint 2: e.g., 'WSL2 development -- no native Windows display server access from WSL2']
- [Constraint 3: e.g., 'Webview content IS accessible via standard HTTP -- Playwright can connect to the dev server']

Is this accurate? Anything to add or correct?"

Wait for user confirmation.

### Step 2: Propose Layered Testing Strategy

Based on the constraints profile, propose a multi-layer strategy. Read the strategy layers guide:
> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-visual-strategy/references/strategy-layers-guide.md`

Match the project's application type against the Layer Decision Matrix to determine the recommended layers. Present the layered approach:

"Based on your stack, here is a layered visual testing strategy:

**Layer 1: [Name] (Recommended first)**
- **What it captures:** [e.g., 'Webview content rendered in a browser via Playwright against the dev server']
- **Coverage:** [e.g., 'All web UI content -- layouts, components, typography, colors. Does NOT capture native window chrome, transparency, or system-level rendering.']
- **Environment:** [e.g., 'Runs anywhere Playwright runs -- WSL2, CI, macOS, Linux native']
- **Complexity:** [Low / Medium / High]
- **Trade-off:** [e.g., 'Fast and reliable but misses native window integration. A button on the wrong side WILL be caught; transparency blending WILL NOT.']

**Layer 2: [Name] (Optional, fills gaps)**
- **What it captures:** [e.g., 'Full native window screenshot including transparency, title bar, system tray integration']
- **Coverage:** [e.g., 'Everything visible on screen including OS chrome and compositor effects']
- **Environment:** [e.g., 'Requires the target OS natively -- for Tauri Windows apps, needs a Windows machine or CI runner']
- **Complexity:** [Medium / High]
- **Trade-off:** [e.g., 'Comprehensive but requires cross-environment pipeline. Screenshots depend on OS version, display scaling, and compositor.']

[Layer 3 if applicable]

**My recommendation:** Start with Layer 1. It catches 80-90% of visual regressions (layout, component rendering, color, typography) with minimal infrastructure. Add Layer 2 when you need to validate native integration or transparency.

Ask (using `AskUserQuestion`):

**"Which layers do you want to set up?"**

Options (based on the layers presented above, e.g.):
1. **Layer 1 only** (Recommended) — Start with browser-based capture
2. **Layer 1 + Layer 2** — Browser-based capture plus native window capture"

**Journey interaction detection (Layer 2 only):**

If Layer 2 is selected, check whether journey interaction testing is appropriate:
- Does the prototype have multiple routes or navigation flows?
- Does the implementation include interactive sequences (login, form submission, multi-step wizards)?
- Are there state transitions that static screenshots would miss?

If any of these conditions apply, ask the user:

Inform the user: "Layer 2 can capture static screenshots (current behavior) or walk through the app like a user using journey-based interaction testing (via UI automation APIs). Journey mode captures screenshots at each step of a user flow — login, navigation, form submission, etc."

Ask (using `AskUserQuestion`):

**"Do you want to enable journey interaction for Layer 2?"**

Options:
1. **Yes** — Enable journey-based interaction testing
2. **No** — Keep static screenshot capture

Record the user's choice:
- If yes: set `Interaction: journey` for Layer 2
- If no or if none of the conditions apply: set `Interaction: static` for Layer 2
- If the user is unsure: default to `static` and note that they can upgrade later via `arn-spark-visual-readiness`

For each selected layer that cannot be validated in the current environment (e.g., native capture from WSL2, CI-only capture):

"Layer [N] ([Name]) cannot be validated in this environment. When should it be activated?

Examples:
- 'After first successful build on the target platform'
- 'After the first feature is implemented and the app runs natively'
- 'When CI is configured with the required OS matrix runner'

Activation criteria for Layer [N]:"

Wait for user input. Record the activation criteria text for each deferred layer.

### Step 3: Define Baseline Sources

Map prototype screenshots to visual test baselines. Scan for available screenshots:
- Clickable prototype showcase: `[prototypes-dir]/clickable/v[N]/showcase/screens/`
- Journey captures: `[prototypes-dir]/clickable/v[N]/journeys/`
- Static prototype showcase: `[prototypes-dir]/static/v[M]/showcase/`
- Locked prototype (if available): `[prototypes-dir]/locked/clickable-v[N]/`

If using locked prototype, prefer those screenshots as they are guaranteed stable.

Present the baseline sources:

"I found these prototype screenshots that can serve as baselines:

**From clickable prototype showcase (v[N]):**
| Screen | Route | Screenshot | Baseline category |
|--------|-------|------------|-------------------|
| [Name] | [/route] | [path] | Layout reference |
| ... | ... | ... | ... |

**From journey captures (v[N]):**
| Journey | Step | Screenshot | Baseline category |
|---------|------|------------|-------------------|
| [Name] | [step] | [path] | Flow reference |
| ... | ... | ... | ... |

**From static prototype showcase (v[M]):**
| Section | Component | Screenshot | Baseline category |
|---------|-----------|------------|-------------------|
| [Name] | [variants] | [path] | Component reference |
| ... | ... | ... | ... |

Ask (using `AskUserQuestion`):

**"How should I organize the baselines?"**

Options:
1. **Screen-based** — One baseline per screen (matches clickable showcase)
2. **Journey-based** — One set per user journey (matches journey captures)
3. **Both** — Screen-level baselines for layout + journey baselines for flow
4. **Custom** — You specify the mapping"

### Step 4: Validate Strategy with Mini-Spike (Per Layer)

For each selected layer, run a proof-of-concept. This follows the arn-spark-spike pattern: one mini-spike per layer.

**IMPORTANT: Run spikes sequentially, one at a time.** Do NOT launch multiple visual-test-engineer agents in parallel or in the background. The agent needs Bash and Write tool access, which requires user permission approval. Parallel or background agents cannot surface permission prompts to the user, causing all tool calls to be denied.

"I will validate each testing layer with a mini-spike to confirm the capture and comparison tooling works in your environment:

**Spike: Layer 1 -- [Layer Name]**
- Create a proof-of-concept capture script
- Run it against the dev server (or the prototype as a convenient test target) to verify the tooling captures screenshots correctly
- Compare a captured screenshot against a prototype baseline to verify the comparison tooling works
- Report whether the tooling is viable for development-time use

The spike validates the **tooling**, not the prototype. The prototype is just a convenient target because it already has known-good screenshots to compare against.

Ready to proceed?"

For each layer:

1. Read the spike checklist:
   > Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-visual-strategy/references/spike-checklist.md`

2. Read the capture script template:
   > Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-visual-strategy/references/baseline-capture-script-template.js`

3. Determine the spike workspace: `[spikes-dir]/visual-strategy-spike-layer-[N]/`

4. Invoke the `arn-spark-visual-test-engineer` agent (foreground, not background) with:
   - Stack details (application type, framework, rendering context)
   - Layer specification (what approach to validate)
   - Environment constraints
   - Dev server URL or prototype URL (as a convenient test target for validating the capture tooling)
   - Workspace path
   - Baseline screenshots for comparison (if available)
   - Capture script template as a starting point
   - Spike checklist criteria for this layer

**Additional context for journey interaction spikes:**

If the layer has `Interaction: journey`, provide additional context to the `arn-spark-visual-test-engineer` agent:
- Include the journey schema reference: `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-visual-strategy/references/journey-schema.md`
- Request accessibility tree inspection: agent should verify that the target application exposes automation IDs on key interactive elements
- Request minimal journey execution test: agent should generate at least one journey and execute it in dry-run mode (or full execution if app is running)
- For macOS targets: agent should check Accessibility permissions and prompt the user to grant them if not already granted

The spike must validate journey readiness in addition to the standard Layer 2 spike criteria. See `spike-checklist.md` in this directory for the "Layer 2 -- Journey Interaction" checklist.

5. Wait for agent to complete fully before proceeding.

6. Present results and record layer status:
   - **Validated:** "Layer [N] works. [Evidence: captured screenshots match baselines within threshold.]"
     Record: `status: active`, `validated: [date]`
   - **Partially validated:** "Layer [N] works with caveats. [Evidence + caveats, e.g., anti-aliasing noise above expected threshold.]"
     Record: `status: active`, `validated: [date]`, `caveats: [list]`
   - **Failed:** "Layer [N] does not work in this environment. [Evidence + reason.] Should I try an alternative approach?"
     Record: `status: failed` -- ask user whether to retry, adjust approach, or drop layer
   - **Deferred:** "Layer [N] cannot be tested here. [Required environment + instructions.] The scripts have been created at `[workspace]` for manual validation on the target OS."
     Record: `status: deferred`, `activation_criteria: [from Step 2]`, `deferred_reason: [evidence from spike]`

7. Proceed to the next layer only after presenting results.

### Step 5: Generate Production Scripts

After validating layers, invoke `arn-spark-visual-test-engineer` again (foreground) with:
- Validated layer specifications and spike results
- Full baseline image set (all screens, not just the POC subset)
- Project structure and build configuration
- Request: generate production-ready capture and comparison scripts

The agent produces:
- **Capture script** (e.g., `scripts/visual-test-capture.mjs`) -- Playwright script that navigates to each screen of the **development build** (via the dev server), captures screenshots at specified viewport sizes, saves to `visual-tests/captures/`. This runs against the dev build, NOT the prototype.
- **Comparison script** (e.g., `scripts/visual-test-compare.mjs`) -- loads development captures and prototype baselines, computes pixel diff, generates a diff report with highlighted differences, reports pass/fail per screen
- **Baseline setup script** (e.g., `scripts/visual-test-baseline.mjs`) -- copies prototype screenshots to baseline directory with proper naming (one-time setup)
- **Cross-environment pipeline script (if Layer 2+)** (e.g., `scripts/visual-test-cross-env.sh`) -- WSL2-to-Windows build+capture+copy pipeline, or equivalent

Present the scripts to the user before writing to the project.

### Step 6: Set Up Baseline Images

Invoke `arn-spark-visual-test-engineer` (foreground) with:
- Prototype screenshot locations (from Step 3)
- Baseline directory path (e.g., `visual-tests/baselines/`)
- Naming convention from the capture script

The agent:
1. Creates the baseline directory
2. Copies and renames prototype screenshots following the naming convention from the capture script (e.g., `screen-name--light.png`, `screen-name--dark.png`)
3. Writes a `baseline-manifest.json` mapping screen names to baseline file paths
4. Validates that every screen in the capture script has a corresponding baseline
5. Reports any gaps (screens without baselines)

### Step 7: Update .gitignore

Check if the project uses Git (from `## Arness` config or by checking for `.git/`). If not configured, skip this step silently.

If Git is configured:

1. Inventory all directories and files created or referenced by the visual testing strategy so far (spike workspaces, capture output directories, diff output directories, baseline directories, scripts, manifest files)
2. Classify each path as **ephemeral** (regenerated on every run, machine-specific) or **shared** (reference images, scripts, and config the team needs)
3. Read the project's `.gitignore` and check which paths are already covered
4. Present the classification to the user:

"The visual testing strategy created these paths. Which should be excluded from Git?

| Path | Type | Recommendation |
|------|------|----------------|
| [path] | [ephemeral / shared] | [ignore / track] |
| ... | ... | ... |

Ephemeral paths (captures, diffs, spike workspaces) are regenerated on every run and are typically ignored. Shared paths (baselines, scripts, manifests) are reference artifacts the team needs and are typically tracked.

Want to proceed with these recommendations, or adjust?"

5. Wait for user confirmation or adjustments
6. Add the confirmed paths to `.gitignore` under a `# Visual testing` comment block

### Step 8: Configure Test Runner Integration

Present integration options:

Ask (using `AskUserQuestion`):

**"How should visual tests integrate with your workflow?"**

Options:
1. **Manual** — Run `node scripts/visual-test-capture.mjs && node scripts/visual-test-compare.mjs` when you want to check
2. **npm script** — Add `visual-test` to package.json scripts (Recommended)
3. **CI integration** — Add a visual test step to the CI workflow
4. **Arness pipeline hook** — Run visual tests as part of `/arn-code-execute-task` completion verification

Based on user choice, configure the integration:
- **npm script:** Add `"visual-test:capture"`, `"visual-test:compare"`, and `"visual-test"` (runs both) to package.json scripts
- **CI:** Add a visual test job to the CI workflow file (if one exists from arn-spark-dev-setup). If no CI exists, create the workflow file or suggest running `/arn-spark-dev-setup` first.
- **Arness pipeline:** Add configuration to CLAUDE.md (see Step 9)

### Step 9: Write Strategy Document

Read the template:
> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-visual-strategy/references/visual-strategy-template.md`

Populate the template with all collected information:
- Stack and environment analysis (from Step 1)
- Layer-by-layer strategy with trade-offs (from Step 2)
- Spike results per layer (from Step 4)
- Baseline image mapping (from Step 3 and Step 6)
- Script inventory with paths and usage (from Step 5)
- Cross-environment pipeline documentation (if applicable)
- CI integration details (if configured in Step 8)
- Known limitations
- Threshold configuration (pixel diff tolerance, per-screen overrides)
- How to update baselines when designs intentionally change

Write to `[vision-dir]/visual-strategy.md`.

### Step 10: Write CLAUDE.md Configuration

Add or update a `### Visual Testing` subsection in the `## Arness` section of the project's `CLAUDE.md`:

```
### Visual Testing
- **Strategy doc:** [vision-dir]/visual-strategy.md
- **Baseline directory:** visual-tests/baselines/
- **Screen manifest:** visual-tests/screen-manifest.json
- **Capture script:** scripts/visual-test-capture.mjs
- **Compare script:** scripts/visual-test-compare.mjs
- **Layers:** [Layer 1 name, Layer 2 name, ...]
- **Diff threshold:** [N]% (pixel difference tolerance)
- **Integration:** [manual / npm-script / ci / arness-pipeline]

During feature development, the capture script runs against the development build (dev server) and the comparison script diffs those captures against the prototype baselines. This catches visual regressions as features are implemented. To update baselines after intentional design changes, run `[baseline update command]`.

[For each additional layer with status other than Layer 1:]

#### Layer [N]: [Name]
- **Status:** [active / deferred]
- **Capture script:** [path]
- **Compare script:** [path]
- **Baseline directory:** [path]
- **Diff threshold:** [N]%
- **Requires dev server:** [yes / no]
- **Activation criteria:** [free-text condition, or "N/A" if active]
- **Environment:** [required OS/platform]
- **Spike result:** [Validated: evidence / Deferred: reason]
- **Interaction:** static | journey
- **Journey manifest:** [path to journey-manifest.json] (only if Interaction: journey)
- **Journey runner:** [path to platform-specific runner script] (only if Interaction: journey)
```

> **Note:** The `**Interaction:**` field distinguishes between static screenshot capture (default) and journey-based interaction testing. When set to `journey`, the `**Journey manifest:**` and `**Journey runner:**` fields specify the paths to the auto-generated journey definitions and platform runner script. These are generated by `arn-spark-visual-test-engineer` during the spike or readiness activation. If the `**Interaction:**` field is absent, `static` is assumed (backward compatible).

Top-level fields (no `####` subsection) are implicitly Layer 1 and are always active. Skills that are not layer-aware continue reading top-level fields unchanged.

### Step 11: Present Summary and Next Steps

"Visual testing strategy configured.

**Strategy:** [layers summary]
**Baselines:** [N] screen baselines + [M] journey baselines from prototype v[X]
**Scripts:** [list with paths]
**Spike results:** Layer 1: [result]. Layer 2: [result].

**Files created/updated:**
- [vision-dir]/visual-strategy.md
- scripts/visual-test-capture.mjs
- scripts/visual-test-compare.mjs
- scripts/visual-test-baseline.mjs
- visual-tests/baselines/ ([N] images)
- visual-tests/baselines/baseline-manifest.json
- [cross-env scripts if applicable]
- .gitignore (added visual-tests/captures/ and visual-tests/diffs/)

**CLAUDE.md updated** with `### Visual Testing` configuration.

Recommended next steps:
1. **Extract features:** Run `/arn-spark-feature-extract` to build the backlog
2. **Start developing:** If you have the Arness Code plugin installed, run `/arn-planning` to begin the development pipeline. Arness auto-configures on first use.
3. **Start building:** Features will be compared against prototype baselines during implementation

[If any layers were deferred:]

**Deferred layers:** [layer names]. These layers were configured but could not be validated in the current environment. After the first feature is implemented and the application builds on the target platform, run `/arn-spark-visual-readiness` to activate them."

## Agent Invocation Guide

| Situation | Action |
|-----------|--------|
| Validate a testing layer (Step 4) | Invoke `arn-spark-visual-test-engineer` sequentially (foreground, not background) with layer spec, stack, workspace, spike checklist, and capture script template. Wait for completion before starting the next spike. |
| Generate production scripts (Step 5) | Invoke `arn-spark-visual-test-engineer` with validated layer specs, full screen list, and project context. |
| Set up baselines (Step 6) | Invoke `arn-spark-visual-test-engineer` with screenshot paths, baseline directory, and naming convention. |
| Agent permission denied | Same as arn-spark-spike: re-run in foreground. If still denied, execute directly in conversation (write POC files and run capture commands yourself). |
| User asks about prototype quality | Reference the prototype lock manifest and judge reports. Do not re-run validation. |
| User asks about specific framework capture methods | Discuss and invoke `arn-spark-tech-evaluator` if deep comparison needed. |
| User asks about CI setup | Discuss briefly. If CI workflow exists, offer to add visual test step. If not, suggest running `/arn-spark-dev-setup` first. |
| User asks about feature implementation | Defer: "Feature implementation is handled by `/arn-code-feature-spec` and the Arness development pipeline." |
| Cross-environment spike deferred | Record the deferral with instructions. Create the scripts anyway. The user can run them manually on the target OS later. |

## Error Handling

- **No prototype screenshots found:** Ask the user to provide reference screenshots or run the prototype skills first. Without baselines, the strategy document can still be written but baselines cannot be set up.
- **Playwright not available:** Layer 1 requires Playwright. Suggest installation (`npm install -D @playwright/test`). If the user declines, note that Layer 1 is unavailable and fall back to Layer 2 options or manual testing only.
- **Cross-environment spike cannot run (e.g., no Windows access from WSL2):** Mark as deferred. Create the pipeline scripts and document how to run them manually on the target OS. The scripts are the artifact even if they cannot be validated here.
- **Diff tool comparison is too noisy (anti-aliasing, sub-pixel rendering):** Expected for some stacks. Recommend a higher threshold or switching from pixelmatch to looks-same. Discuss with the user during Step 4.
- **Dev server fails to start during spike:** Check for port conflicts, build errors, missing dependencies. The spike uses a running server (prototype or dev build) as a test target to validate capture tooling — the server is a means, not the end goal.
- **Layer 2 validation fails:** Report the failure. Layer 1 may still be sufficient for most use cases. Discuss with the user.
- **CI runner does not support display (headless-only):** Layer 1 (Playwright) works headless. Layer 2 (native screenshot) needs a display. Document the limitation.
- **Too many screens (>20 baselines):** Suggest prioritizing key screens for initial baselines. Secondary screens can be added incrementally.
- **Strategy already exists:** "A visual testing strategy already exists at `[path]`. Do you want to replace it, update specific layers, or add a new layer?"
- **No dev-setup document:** Proceed with environment detection from the current runtime. Note that CI integration will be limited without a dev-setup baseline.
