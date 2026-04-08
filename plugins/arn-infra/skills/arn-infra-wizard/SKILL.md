---
name: arn-infra-wizard
description: >-
  This skill should be used when the user says "infra wizard", "arn infra wizard",
  "guided infra", "walk me through infrastructure", "infrastructure pipeline",
  "full infra pipeline", "infra flow", "run the infra pipeline",
  "guide me through infrastructure", "infra guided mode", "infrastructure wizard",
  "end to end infrastructure", "deploy everything", "set up my infrastructure",
  "infra start to finish", "arn infra guided", "run infra wizard",
  "set up everything", "complete infra setup",
  or wants to be walked through the entire Arness infrastructure pipeline in a
  single continuous session with guided decision gates instead of invoking each
  skill manually.
version: 1.0.0
---

# Arness Infra Wizard

Walk the user through the entire Arness infrastructure pipeline in a single continuous session. The wizard invokes each pipeline skill in sequence using the Skill tool, only pausing at genuine decision gates where user input is needed.

This skill is a **sequencer and decision-gate handler**. It MUST NOT duplicate sub-skill logic. All pipeline work is done by the invoked skills. The wizard handles: entry mode detection, transitions between skills, progress display, expertise-adaptive step selection, and artifact-based resumability.

## Step 0: Ensure Configuration

Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-ensure-config/references/ensure-config.md` and follow its instructions. This guarantees a user profile exists and `## Arness` is configured with Arness Infra fields before proceeding.

After Step 0 completes, read `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-ensure-config/references/experience-derivation.md` and derive the user's infrastructure experience level from their profile.

Arness Core is optional but enhances cross-plugin workflows when present. If a `## Arness` section exists with Arness Core fields (plans directory, specs directory, etc.), note the configuration for cross-plugin context. This information may be useful for linking infrastructure changes to application features, but is NOT required.

Extract all `## Arness` config fields for use throughout the wizard:
- **Experience level** -- derived from user profile (see experience-derivation.md). If no profile exists, check for legacy `Experience level` in `## Arness` as fallback.
- **Deferred** -- triggers assessment-driven entry mode
- **Providers config** -- path to `providers.md`
- **Environments config** -- path to `environments.md`
- **Tooling manifest** -- path to `tooling-manifest.json`
- **Resource manifest** -- path to `active-resources.json`
- **Default IaC tool** -- for artifact detection
- **Project topology** -- for context
- **CI/CD platform** -- for CI/CD context (github-actions, gitlab-ci, bitbucket-pipelines, none)
- **Issue tracker** -- for triage entry mode detection

## Mode Selection

After prerequisites, present the user with a mode choice. This determines which pipeline flow the wizard uses for the entire session.

Ask (using `AskUserQuestion`):

**"What type of infrastructure change are you making?"**

Options:
1. **Quick mode** -- Simple, low-risk changes to a single environment. Uses the interactive flow: discover, define, deploy, verify. No planning overhead.
2. **Full pipeline mode** -- Complex, multi-environment, or compliance-sensitive changes. Uses the structured flow: change-spec, change-plan, save-plan, execute-change, review-change, document-change. Includes review gates, cost tracking, and audit trails.

**Mode recommendation logic:**

Analyze the user's change description (if provided) or project context to recommend a mode:
- Single environment + single resource type + low blast radius --> recommend **Quick mode**
- Multi-environment + multiple resources + compliance requirements --> recommend **Full Pipeline mode**
- Existing pipeline artifacts in `.arness/infra-specs/` or `.arness/infra-plans/` --> recommend **Full Pipeline mode** (resume)
- No change description provided --> present both options without recommendation

If the user does not specify, default to Quick mode for beginner experience level and present both options for intermediate/expert.

---

## Entry Mode Detection

After mode selection, detect the appropriate entry mode within the selected mode. Each mode has a set of entry modes checked from most specific to least specific -- first match wins.

**Quick mode entry modes:** Fresh/Resume (default), Triage-driven, Assessment-driven, Migration.
**Full Pipeline entry modes:** Change Pipeline (resume or explicit), New Pipeline (default).

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-wizard/references/entry-modes.md` for the complete entry mode detection rules, conditions, and pipeline sequences.

The workflow steps below (Step 1a, Step 1b) correspond to Entry Mode 2 (Triage-Driven) and Entry Mode 3 (Assessment-Driven) respectively.

---

## Full Pipeline Mode Flow

> Read ${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-wizard/references/full-pipeline-flow.md

---

## Expertise-Adaptive Pipeline

### Expert / Intermediate

Full 10-step pipeline with 8 decision gates (Q1, Q1.5, Q2 through Q7). All steps are presented. Decision gates allow skipping optional steps.

### Beginner

Simplified 6-step pipeline focusing on the essentials:
1. init (already done)
2. discover
3. containerize
4. define
5. deploy
6. verify

Advanced steps (pipeline, env, secrets, monitor) are offered as optional extras after the core pipeline completes:

"The core infrastructure is deployed and verified. These additional steps are optional but recommended for production readiness:
- **CI/CD Pipeline** -- Automate future deployments
- **Environment Management** -- Set up staging/prod promotion
- **Secrets Management** -- Secure your credentials
- **Monitoring** -- Set up health checks and alerting

Ask (using `AskUserQuestion`):

**"Would you like to set up any of these optional features?"**

Options:
1. **All** -- Set up all optional features
2. **Pick individually** -- Choose which features to set up
3. **Skip** -- Skip all optional features

---

## Interactive-to-Pipeline Upgrade Path

At any point during Quick mode, the user may request an upgrade to Full Pipeline mode. Detect upgrade requests when the user says any of: "I want review gates", "upgrade to pipeline", "add audit trail", "switch to full pipeline", "need more structure", or "this is getting complex".

**Upgrade flow:**

1. Acknowledge the upgrade request: "Upgrading to Full Pipeline mode. I will create a structured change specification from your existing progress."
2. Invoke `Skill: arn-infra:arn-infra-change-spec` with the existing artifacts as input context:
   - Pass any IaC files generated by define
   - Pass any deployment results from deploy
   - Pass any verification results from verify
   - Pass the tooling manifest from discover
3. When change-spec completes, continue in Full Pipeline mode from P2 (change-plan) onward.

**Proactive upgrade detection:**

After any Quick mode step completes, check if the change complexity warrants an upgrade. Offer an upgrade if:
- The user has run `arn-infra-define` interactively and the generated IaC touches multiple environments or providers
- The deployment scope has expanded beyond the initial single-environment expectation
- The user mentions compliance, audit, or review requirements

Proactive offer: "I see you have generated IaC code that spans multiple environments. Would you like to wrap this in the structured pipeline for review gates and documentation? (yes / no)"

If the user accepts: follow the upgrade flow above. If the user declines: continue in Quick mode.

---

## Decision Gates (Quick Mode)

> Read ${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-wizard/references/decision-gates.md

---

## Artifact Detection (Resumability)

> Read ${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-wizard/references/artifact-detection.md

---

## Workflow

### Step 0: Initialize, Select Mode, and Detect Entry Mode

1. Read CLAUDE.md. Check prerequisites (see Prerequisites section).
2. Extract `## Arness` config fields. If `## Arness` section exists, note it for cross-plugin context.
3. Determine expertise level from the profile-derived experience level (see Step 0).
4. Present mode selection (see Mode Selection section). User chooses Quick or Full Pipeline.
5. If **Quick mode**: detect entry mode from Quick mode entry modes (see Entry Mode Detection section).
6. If **Full Pipeline mode**: detect entry mode from Full Pipeline mode entry modes (see Entry Mode Detection section).
7. If Quick mode Fresh/Resume: run artifact detection (see Artifact Detection section).
8. If Full Pipeline mode Change Pipeline: run pipeline artifact detection (see Entry Mode 5).

---

### Step 1: Artifact Check and Gate Q1

**If artifacts detected (Fresh/Resume mode only):**

Show the detected state and ask Q1:

"It looks like you have an in-progress infrastructure pipeline at [detected stage]. Would you like to resume from there, or start fresh?"

- **Resume** -- skip to the detected resume point
- **Start fresh** -- begin at Step 2 (do not delete existing artifacts)

**If no artifacts detected:** skip Q1 and proceed to Step 2.

---

### Step 1a: Triage (Triage-Driven Entry Only)

This step runs only when Entry Mode 2 (Triage-Driven) was detected in Step 0.

Inform the user: "Processing [N] pending infrastructure request(s)..."

> `Skill: arn-infra:arn-infra-triage`

When triage completes, the implications brief is available. Proceed directly to Step 4 (Define) — skip discover and containerize since the triage brief already contains the analyzed requirements.

---

### Step 1b: Assess (Assessment-Driven Entry Only)

This step runs only when Entry Mode 3 (Assessment-Driven) was detected in Step 0.

Inform the user: "Running full infrastructure assessment on deferred backlog..."

> `Skill: arn-infra:arn-infra-assess`

When assess completes, the user has a prioritized infrastructure backlog. Proceed directly to Step 4 (Define) — skip discover and containerize since the assessment has already produced the infrastructure plan.

---

### Step 2: Discover (Automated)

Show progress (Expert/Intermediate):
```
Infra Pipeline: DISCOVER --> containerize --> define --> deploy --> verify --> pipeline --> env --> secrets --> monitor
                ^^^^^^^^
```

Show progress (Beginner):
```
Infra Pipeline: DISCOVER --> containerize --> define --> deploy --> verify
                ^^^^^^^^
```

Inform the user: "Auditing your installed tools, MCPs, and CLIs..."

> `Skill: arn-infra:arn-infra-discover`

When discover completes, `tooling-manifest.json` exists at the Tooling manifest path.

---

### Step 2.5: Gate Q1.5 -- Tool Installation

After discover, check the tooling manifest for tools with `"status": "recommended"` and `"installed": false`.

If missing recommended tools are found, present Q1.5. Otherwise, skip to Step 3.

---

### Step 3: Gate Q2 -- Containerize Decision

Show progress:
```
Infra Pipeline: discover --> CONTAINERIZE --> define --> deploy --> verify --> pipeline --> env --> secrets --> monitor
                              ^^^^^^^^^^^^
```

Ask Q2 (see Decision Gates section).

If **Yes:**
> `Skill: arn-infra:arn-infra-containerize`

If **Skip:** mark containerize as skipped and proceed to Step 4.

---

### Step 4: Define (Automated)

Show progress:
```
Infra Pipeline: discover --> containerize --> DEFINE --> deploy --> verify --> pipeline --> env --> secrets --> monitor
                                              ^^^^^^
```

Inform the user: "Generating infrastructure-as-code configurations..."

> `Skill: arn-infra:arn-infra-define`

When define completes, IaC configuration files exist in the project.

---

### Step 5: Gate Q3 -- Deploy Level

Show progress:
```
Infra Pipeline: discover --> containerize --> define --> DEPLOY --> verify --> pipeline --> env --> secrets --> monitor
                                                         ^^^^^^
```

Ask Q3 (see Decision Gates section).

Based on user choice:

- **Deploy to staging/production:** `Skill: arn-infra:arn-infra-deploy` (pass the target environment as context)
- **Dry run only:** `Skill: arn-infra:arn-infra-deploy` (pass dry-run mode as context)
- **Skip:** mark deploy as skipped, proceed to Step 6

---

### Step 6: Gate Q4 -- Verify and CI/CD

Show progress:
```
Infra Pipeline: discover --> containerize --> define --> deploy --> VERIFY --> PIPELINE --> env --> secrets --> monitor
                                                                    ^^^^^^    ^^^^^^^^
```

Ask Q4 (see Decision Gates section).

Based on user choice:

- **Verify then CI/CD:**
  > `Skill: arn-infra:arn-infra-verify`
  > Then: `Skill: arn-infra:arn-infra-pipeline`

- **Verify only:**
  > `Skill: arn-infra:arn-infra-verify`

- **CI/CD only:**
  > `Skill: arn-infra:arn-infra-pipeline`

- **Skip both:** proceed to Step 7

---

### Step 7: Gate Q5 -- Environments (Expert/Intermediate Only)

**Beginner:** Skip to Step 8 (beginner optional extras prompt).

Show progress:
```
Infra Pipeline: discover --> containerize --> define --> deploy --> verify --> pipeline --> ENV --> secrets --> monitor
                                                                                           ^^^
```

Ask Q5 (see Decision Gates section).

If **Yes:**
> `Skill: arn-infra:arn-infra-env`

If **Skip:** proceed to Step 8.

---

### Step 8: Gate Q6 -- Secrets and Monitoring (Expert/Intermediate Only)

**Beginner:** Present the optional extras prompt (see Expertise-Adaptive Pipeline section). If the user selects specific extras, invoke the corresponding skills. Otherwise, skip to Step 9.

Show progress:
```
Infra Pipeline: discover --> containerize --> define --> deploy --> verify --> pipeline --> env --> SECRETS --> MONITOR
                                                                                                  ^^^^^^^    ^^^^^^^
```

Ask Q6 (see Decision Gates section).

Based on user choice:

- **Both:**
  > `Skill: arn-infra:arn-infra-secrets`
  > Then: `Skill: arn-infra:arn-infra-monitor`

- **Secrets only:**
  > `Skill: arn-infra:arn-infra-secrets`

- **Monitoring only:**
  > `Skill: arn-infra:arn-infra-monitor`

- **Skip both:** proceed to Step 9

---

### Step 9: Gate Q7 -- Completion Summary

Show final progress (Expert/Intermediate):
```
Infra Pipeline: discover --> containerize --> define --> deploy --> verify --> pipeline --> env --> secrets --> monitor
                    ✓              ✓            ✓          ✓          ✓          ✓         ✓         ✓          ✓
```

Show final progress (Beginner):
```
Infra Pipeline: discover --> containerize --> define --> deploy --> verify
                    ✓              ✓            ✓          ✓          ✓
```

Use `✓` for completed steps, `skipped` for skipped steps, and `·` for steps not reached.

Present a completion summary:

- **Experience level:** [level]
- **Entry mode:** [fresh / triage / assessment / migration]
- **Providers:** [provider list from config]
- **IaC tool:** [default IaC tool]
- **Environments:** [environment list]
- **Tooling audit:** `[tooling-manifest-path]` (completed / skipped)
- **Containerization:** Dockerfile(s) generated (completed / skipped)
- **IaC code:** [IaC tool] configurations generated (completed / skipped)
- **Deployment:** Deployed to [environment] (completed / dry-run / skipped)
- **Verification:** [PASS / WARN / FAIL / skipped]
- **CI/CD pipeline:** [platform] workflows generated (completed / skipped)
- **Environment management:** [environments] configured (completed / skipped)
- **Secrets management:** [provider] configured (completed / skipped)
- **Monitoring:** Observability configured (completed / skipped)

**Next steps:**
- "Run `/arn-infra-wizard` again to revisit any step (artifact detection will resume where appropriate)"
- "Run `/arn-infra-deploy` to deploy to additional environments"
- "Run `/arn-infra-migrate` to migrate between providers"
- If triage-driven and more issues remain: "Run `/arn-infra-triage` to process remaining infrastructure requests"

---

## Error Handling

- **Sub-skill fails or errors out:** Present the error to the user. Ask (using `AskUserQuestion`): "The [skill-name] step encountered an error: [error summary]. What would you like to do?" Options: retry this step / skip this step / abort the wizard. If retry, re-invoke the same skill. If skip, continue to the next gate. If abort, show what was completed and exit.
- **User says "stop" or "pause":** Show what has been completed and what remains. Inform: "Run `/arn-infra-wizard` again to resume (artifact detection will pick up where you left off)."
- **Arness Core not initialized (no Arness Code fields in `## Arness`):** Continue without Arness Core context. Cross-plugin features (linking to application specs/plans) will be unavailable. Optionally inform: "Arness Code is not configured. The wizard will operate in standalone mode. Install and configure the Arness Code plugin for cross-plugin features."
- **Arness Infra not initialized (`## Arness` missing):** Step 0 (ensure-config) handles this automatically. If ensure-config itself fails, inform the user and suggest running `/arn-infra-wizard` again.
- **Issue tracker unavailable for triage mode:** Fall back to Fresh/Resume mode. Inform: "No issue tracker configured -- cannot detect pending infrastructure requests. Starting standard pipeline instead."
- **Migration sub-skill fails:** The migrate skill has its own error handling and lifecycle tracking. If it returns an error, present it and ask: retry migration / abort wizard.
- **Define produces no IaC files:** If define completes but no IaC files are detected, warn the user and ask: retry define / skip to CI/CD setup / abort.
- **Deploy fails:** Present the error. The deploy skill has its own rollback procedures. Ask: retry deploy / skip to verify (to check partial deployment) / abort.
- **Tool installation fails at Q1.5:** Inform: "Some tools could not be installed automatically. You can install them manually later. Continuing with available tools." Proceed to next step.
- **Ambiguous artifacts detected:** List the detected artifacts and ask the user to clarify which state to resume from rather than guessing.
- **arn-infra plugin not installed:** If skill invocations fail because the plugin is missing, inform: "The arn-infra plugin must be installed. Add it to your project's plugin configuration."
- **Full Pipeline skill fails:** Present the error. Ask: "The [pipeline-stage] step encountered an error: [error summary]. What would you like to do?" Options: retry this stage / skip to the next stage / abort the pipeline. If retry, re-invoke the same skill. If skip, proceed to the next P gate (note: skipping execute-change or review-change may leave the pipeline in an incomplete state). If abort, show what was completed and exit.
- **Pipeline upgrade fails:** If the upgrade from Quick to Full Pipeline fails during change-spec creation, inform: "Could not create a change specification from existing artifacts. You can continue in Quick mode or try again." Options: continue Quick mode / retry upgrade / abort.
- **Pipeline artifacts from multiple changes detected:** If `.arness/infra-specs/` contains multiple `INFRA_CHANGE_*.md` files, list them and ask the user which change to resume. Do not guess.

## Constraints

- This skill MUST NOT duplicate sub-skill logic. It only handles sequencing and decision gates.
- All pipeline work is done by the invoked skills via the Skill tool.
- Sub-skill invocations use the Skill tool with fully qualified names: `Skill: arn-infra:arn-infra-<name>`.
- Progress display uses the compact format shown above -- one line showing the full pipeline with the current stage highlighted.
- The wizard runs in normal conversation (not plan mode).
- Beginner mode simplifies the pipeline to 6 core steps with optional advanced extras.
- Expert/Intermediate mode presents the full 10-step pipeline with all 7 decision gates.
- The wizard never deletes existing artifacts when starting fresh -- it builds alongside or replaces via the invoked skills' own logic.
- Full Pipeline mode uses P1-P6 gates. Quick mode uses Q1-Q7 gates. These gate sets are mutually exclusive within a session.
- Interactive-to-pipeline upgrade is a one-way transition. Once upgraded, the session continues in Full Pipeline mode.
- Full Pipeline mode does not apply the Expertise-Adaptive Pipeline simplification (beginner mode). All 6 stages are always presented regardless of experience level.
