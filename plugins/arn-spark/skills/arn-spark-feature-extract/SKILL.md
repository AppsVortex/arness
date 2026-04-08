---
name: arn-spark-feature-extract
description: >-
  This skill should be used when the user says "feature extract",
  "arn feature extract", "extract features", "feature backlog",
  "create backlog", "list features", "what features do we need",
  "prioritize features", "feature list", "build the backlog",
  "what should we build", "upload features", "feature tracker",
  or wants to extract a structured, prioritized feature list with
  journey steps, validated components, use case context, and UI
  behavior details from all project artifacts, producing a feature
  backlog document with a Feature Tracker that bridges into
  arn-code-feature-spec and optionally uploads features to the issue tracker.
version: 3.0.0
---

# Arness Feature Extract

Extract a structured, prioritized feature backlog from all available project artifacts through guided conversation, aided by the `arn-spark-product-strategist` and `arn-spark-ux-specialist` agents (greenfield agents in this plugin) for feature analysis, prioritization, and UX flow analysis. This is a conversational skill that runs in normal conversation (NOT plan mode). The primary artifact is a **feature backlog document** that feeds into `arn-code-feature-spec`.

This skill bridges the greenfield pipeline into Arness's existing development pipeline. It takes all upstream artifacts -- product concept, architecture vision, spike results, style brief, static prototype validation (including showcase and debate reports), clickable prototype validation (including showcase, screen manifest, and debate reports), use cases (including postconditions, business rules, and debate reports), and visual grounding assets -- and distills them into a prioritized list of features with a local Feature Tracker for dependency management.

Each feature carries lean context (description, journey summary, UI behavior unique to the feature, validated components, use case references, debate insights, technical notes, acceptance criteria) with references to upstream UC documents. `arn-code-feature-spec` expands these references at spec time by reading the referenced UC documents directly.

Optionally, features can be uploaded as issues to the configured issue tracker (GitHub or Jira) for team visibility and tracking.

## Prerequisites

At minimum, a product concept document should exist. Check in order:

1. Read the project's `CLAUDE.md` for a `## Arness` section. If found, check the configured Vision directory for `product-concept.md`
2. If no `## Arness` section found, check `.arness/vision/product-concept.md` at the project root

**If a product concept is found:** Read it as the primary source for feature extraction.

**If no product concept is found:** Ask the user: "No product concept found. I can extract features from your description of the product. What are the main things users should be able to do?"

Read the configured directories from the `## Arness` section (use defaults if no config found):
- **Use cases directory** (default: `.arness/use-cases`)
- **Prototypes directory** (default: `.arness/prototypes`)
- **Vision directory** for the output (default: `.arness/vision`)
- **Visual grounding directory** (default: `.arness/visual-grounding`)

If no `## Arness` section exists or Arness Spark fields are missing, inform the user: "Arness Spark is not configured for this project yet. Run `/arn-brainstorming` to get started — it will set everything up automatically." Do not proceed without it.

> All references to `use-cases/`, `prototypes/`, and `visual-grounding/` in this skill refer to the configured directories determined above.

Also check for and load (if available):
- `[use-cases-dir]/README.md` and `[use-cases-dir]/UC-*.md` -- for structured behavioral specs with actor goals, main success scenarios, alternate flows, business rules, and postconditions that map directly to features
- `[use-cases-dir]/reviews/` -- for debate reports from `arn-spark-use-cases-teams` (consensus findings, business rule discovery, scope concerns, missing elements)
- `architecture-vision.md` (in Vision directory) -- for technical capabilities and platform features
- `spike-results.md` (in Vision directory) -- for validated/failed risks that affect feature scope, validated capabilities, and known limitations
- `style-brief.md` (in Vision directory) -- for UI patterns, visual tokens, and component style that imply features
- `dev-setup.md` (in Vision directory) -- for environment constraints that may affect feature scope
- `[prototypes-dir]/static/final-report.md` -- for validated visual components and their review scores
- `[prototypes-dir]/static/v[N]/showcase/showcase-index.md` -- for per-component visual captures with scores (scan for the latest version directory)
- `[prototypes-dir]/static/v[N]/showcase-manifest.json` -- for the component section list (maps library components to showcase sections)
- `[prototypes-dir]/static/reviews/` -- for debate reports from `arn-spark-static-prototype-teams` (expert scoring, consensus, divergence on visual fidelity)
- `[prototypes-dir]/clickable/final-report.md` -- for validated user journeys, interaction test results, and journey screenshots
- `[prototypes-dir]/clickable/v[N]/showcase/showcase-index.md` -- for per-screen visual captures with journey mapping (scan for the latest version directory)
- `[prototypes-dir]/clickable/v[N]/screen-manifest.json` -- for the canonical screen list with routes and functional areas
- `[prototypes-dir]/clickable/reviews/` -- for debate reports from `arn-spark-clickable-prototype-teams` (expert scoring, journey agreement, interaction quality debate)
- `[prototypes-dir]/criteria.md` -- for agreed validation criteria
- Prototype screens: scan `[prototypes-dir]/clickable/` for versioned prototype app directories. Also check the project's screen/view directories (the location depends on the framework -- look at the project structure) -- each screen suggests features
- User journey definitions from the clickable prototype (journey templates and interaction reports in `[prototypes-dir]/clickable/`)
- `[visual-grounding-dir]/references/` -- reference images (inspirational, inform visual target classification)
- `[visual-grounding-dir]/designs/` -- design mockups (specification targets, inform visual target classification)
- `[visual-grounding-dir]/brand/` -- brand assets (fixed constraints)

The output directory is the Vision directory determined above. If it does not exist, create it.

## Workflow

### Step 1: Load All Artifacts

Read all available project artifacts:

- **Product concept:** Core experience, interaction modes, trust model, platform requirements, scope boundaries, future considerations
- **Architecture vision:** Technology stack, system components, protocols, platform integration points
- **Spike results:** Validated and failed risks (failed risks may eliminate or alter features), validated capabilities and their limitations
- **Style brief:** UI patterns, visual tokens, and component customization that suggest features (settings panel implies settings feature, dark mode toggle implies theme feature, etc.). Also read the Component Style section for the library component inventory.
- **Style brief Animation section (if present):** Motion philosophy, animation approach, key patterns, timing characteristics — used to identify which features have animation requirements
- **Static prototype results:** Validated visual components, review scores, and the component showcase -- which UI elements are themed, validated, and ready to use
- **Static prototype showcase:** Per-component section captures from `showcase-index.md` and `showcase-manifest.json` -- the canonical list of validated library components with their showcase section numbers
- **Clickable prototype results:** Validated user journeys with step-by-step interaction evidence, journey screenshots showing how screens link together, and which interactions work
- **Clickable prototype showcase:** Per-screen captures from `showcase-index.md` and `screen-manifest.json` -- the canonical screen list with routes and functional areas, showing product-specific component compositions
- **Debate reports (static prototype):** Expert consensus, additions, and disagreements on visual fidelity from `arn-spark-static-prototype-teams` review files
- **Debate reports (clickable prototype):** Expert consensus, additions, and disagreements on interaction quality from `arn-spark-clickable-prototype-teams` review files, including journey assessment agreement
- **Debate reports (use cases):** Expert consensus, additions, and disagreements on behavioral specs from `arn-spark-use-cases-teams` review files, including missing use cases, missing actors, and business rule validation
- **Use cases:** Actor catalog, individual use case documents with main success scenarios, extensions, postconditions, and business rules. Each user-goal use case maps to one or more features. Extensions reveal edge-case features. Postconditions provide acceptance criteria. Business rules become feature constraints. When available, use cases are the richest source for feature extraction because they provide structured behavioral detail that the product concept alone does not.
- **User journey definitions:** Journey name, steps (action + target + expected outcome), navigation flow -- these represent user goals that map to one or more features. If use cases exist, journeys are a complementary source (they show how the behavior maps to specific screens); if use cases do not exist, journeys are the primary behavioral source.
- **Visual grounding assets:** Reference images (inspirational direction), design mockups (specification targets), and brand assets (fixed constraints). These inform the visual target classification per feature.

Note which artifacts were available and which were missing. Present the artifact inventory to the user:

"I found these project artifacts:
- [artifact name] -- [brief note on what it provides]
- ...
- Showcase outputs (static v[N]) -- component captures with review scores
- Showcase outputs (clickable v[N]) -- screen captures with journey mapping
- Debate reports (use cases) -- [N] rounds, business + flow perspectives
- Debate reports (static prototype) -- [N] rounds, visual fidelity debate
- Debate reports (clickable prototype) -- [N] rounds, interaction quality debate
- Visual grounding assets -- [N] references, [N] designs, [N] brand assets
- Screen manifest (clickable v[N]) -- [N] screens with routing
- ...
- [artifact name] -- not found

[X] of [Y] artifacts available. [Note if key artifacts like prototype results, journeys, or use cases are missing.]"

### Step 2: Extract Features with Experts

Invoke the `arn-spark-product-strategist` agent with:

- All loaded artifacts
- Request to extract and categorize features from the artifacts
- Instruction to prioritize based on the product concept's scope boundaries (what is in v1 vs. what was deferred)
- Instruction to derive features from user journeys: each journey or major journey segment should map to a feature or feature group
- Instruction to flag XL features that should be decomposed
- Instruction to classify the visual target per feature based on visual grounding assets: if design mockups exist in `designs/` matching this feature's screens, classify as `Design assets`; if reference images exist in `references/`, classify as `Reference alignment`; otherwise `Style brief only`
- Instruction to extract debate insights from review files: read consensus and disagreement findings from debate reports (static, clickable, and use case) and attach relevant findings to specific features
- Instruction to reference use case documents with step ranges and BR identifiers per feature (do not inline postconditions or business rules -- `arn-code-feature-spec` reads UC documents directly at spec time)
- Instruction to provide a brief journey summary (2-3 sentences) per feature with UC references and step ranges, rather than inlining full step descriptions
- Instruction to identify product-specific component compositions per feature from clickable prototype screens (e.g., "DeviceListItem visible in screen 04-main-dashboard")

The agent returns:

- Categorized feature list grouped by functional area
- For each feature: description, suggested priority, complexity estimate, source artifact, journey references, visual target classification, debate insights, use case references (with step ranges), product-specific components
- Scope observations (features that might be scope creep, features that seem missing)
- Sizing warnings (features that seem too large or too thin)

Then invoke `arn-spark-ux-specialist` with:

- The product strategist's feature list
- User journey definitions and journey screenshots from the clickable prototype
- Style brief and static prototype results (including showcase)
- Showcase screenshots from both static and clickable prototypes
- Visual grounding assets for comparison
- Request to review feature boundaries from a UX perspective: are any features too broad (should split) or too narrow (should merge)? Does each feature make sense as a coherent user-facing capability?
- Request to describe the UI behavior for each feature: what screens are involved, how they transition, what interactions happen, what feedback the user receives
- Request to map library components to features using the static prototype `showcase-manifest.json` sections and the style brief's Component Style section (e.g., "This feature uses Button (primary, secondary) from showcase section 3, and Input (text) from showcase section 5")
- Request to validate the visual target classification proposed by the product strategist
- For each feature, identify animation behaviors from the prototype: entrance animations, state transitions, scroll-triggered effects, loading indicators, hover/focus feedback. Reference the style brief's Animation section for the motion design system. Note whether animation is core to the feature's UX or purely decorative. Describe animation in platform-agnostic intent language.

If `arn-spark-ux-specialist` is not available, proceed with the product strategist's output alone and note the limitation.

The UX specialist returns:

- Feature boundary recommendations (split/merge suggestions)
- Per-feature UI behavior descriptions: screens involved, navigation flows, interaction details, feedback mechanisms
- Per-feature component mapping: library components (from static showcase) + product-specific components (from clickable screens)
- Visual target validation
- UX complexity assessment (some features look simple but have complex interaction patterns)

Merge the two expert outputs into a consolidated feature list. Then enrich each feature with the remaining fields defined in `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-feature-extract/references/feature-entry-template.md` — specifically: technical notes (from architecture vision and spike results), acceptance criteria (from journey steps, prototype behavior, and use case postconditions), use case context (references with step ranges; postconditions and business rules referenced, not inlined), prototype and showcase references (matched to specific screens and sections), component compilation (library + product-specific from both experts), and debate insights (from all debate report sources). The template provides field definitions, examples, and spec readiness criteria.

### Step 2b: Gap Resolution (Collaborative)

After merging both expert outputs, scan for gaps -- areas where the consolidated feature list has incomplete, conflicting, or missing information. Common gap types:

| Gap type | Signal |
|----------|--------|
| **Missing UI behavior** | Product strategist identified a feature but UX specialist could not describe the interaction (no prototype coverage, unclear flow) |
| **Conflicting boundaries** | UX specialist suggested splitting or merging features that the product strategist scoped differently |
| **Journey coverage holes** | User journeys with steps not mapped to any feature |
| **Conflicting assessments** | Experts disagree on priority or complexity for the same feature |
| **Incomplete components** | Feature references screens/components that neither expert could map to showcase or prototype output |
| **Unresolved debate findings** | Debate reports flagged disagreements that affect feature scope but were not resolved in the prototype phase |

**If no gaps are found:** Skip to Step 3.

**If gaps are found:**

1. Compile a gap summary listing each gap with:
   - Which feature(s) it affects
   - What each expert said (or didn't say) about it
   - Why it matters for downstream spec writing

2. Invoke `arn-spark-product-strategist` with:
   - The gap summary
   - The full consolidated feature list for context
   - Instruction: "For each gap, propose a solution or alternative from the product perspective. Consider: should the feature be deferred, split, merged, or redefined? What is the minimal viable scope? If journey coverage is missing, which journeys should the feature map to?"

3. Invoke `arn-spark-ux-specialist` with:
   - The gap summary
   - The product strategist's proposed solutions
   - The full consolidated feature list
   - Instruction: "Review the product strategist's proposed solutions for each gap. For each: agree and refine, or propose an alternative from the UX perspective. For missing UI behavior, describe the interaction. For conflicting boundaries, recommend the split/merge that produces the best user experience. For incomplete components, suggest which existing components could serve or what new compositions are needed."

   If `arn-spark-ux-specialist` is not available: proceed with the product strategist's gap solutions alone.

4. Merge the gap resolutions into the consolidated feature list:
   - Apply agreed solutions directly (update descriptions, boundaries, UI behavior, components)
   - For gaps where experts proposed different solutions: note both perspectives and mark for user attention in Step 3
   - Update journey mappings, component references, and acceptance criteria based on resolved gaps

5. Record the gap resolution summary for transparency -- this will be shown to the user alongside the feature list in Step 3:
   - "[N] gaps identified after expert analysis. [M] resolved collaboratively, [K] require your input."

### Step 3: Present and Refine the Feature List

Present the extracted features to the user, grouped by functional area. For each feature, show the enriched description including journey, behavior, and component context:

"I extracted [N] features from your project artifacts ([X] from use cases/journeys, [Y] from product concept, [Z] from other sources).

[If gap resolution ran:] **Gap resolution:** [N] gaps identified after expert analysis. [M] resolved collaboratively, [K] require your input. [List unresolved gaps below the feature list with both expert perspectives.]

Here they are by area:

**[Functional Area 1]:**

**F-001: [Feature Name]** | Priority: Must-have | Complexity: M | Visual target: Design assets
[Description: 2-4 sentences covering what the user can do]
Journey: [brief summary sentence]. See UC-001 steps 1-6, UC-005.
UI behavior: [unique-beyond-UC behavioral details]
Components: [Button (primary), Input (text) -- static showcase v3 s3, s5. DeviceListItem -- clickable v2 screen 04]
Animation: [e.g., "scroll-triggered card stagger entrance, 0.15s delay — validated in clickable v2 screen 03" or "none"]
Showcase: [Static v3 s3. Clickable v2 screens 01, 04]
Debate: [key insight from debate reports, if any]
UC refs: [UC-001 steps 1-6, UC-005]

**F-002: [Feature Name]** | Priority: Should-have | Complexity: L | Visual target: Reference alignment
...

**Summary:** [X] must-have, [Y] should-have, [Z] nice-to-have

**Sizing notes:**
- [Any features flagged as too large (XL) that should be split]
- [Any features flagged as too thin that could be merged]

Review and adjust:
- Change priorities?
- Add or remove features?
- Split large features or merge thin ones?
- Adjust the interaction descriptions?
- Modify complexity estimates?"

### Step 4: Interactive Refinement

Enter a conversation loop for the user to refine the backlog:

| User Request | Action |
|-------------|--------|
| "Change F-003 to must-have" | Update priority, adjust rationale |
| "Add a feature for [description]" | Add with the user's description, estimate priority and complexity, derive journey and behavior context |
| "Remove F-007" | Remove from the backlog, note if it should go to Deferred Items |
| "Is F-005 really that complex?" | Invoke `arn-spark-product-strategist` for scope assessment if needed |
| "What am I missing?" | Invoke `arn-spark-product-strategist` with the current list and journey definitions to identify gaps |
| "These priorities look wrong" | Invoke `arn-spark-product-strategist` for re-prioritization with the user's feedback |
| "Split F-010 into smaller features" | Decompose with the user's guidance, distribute journey steps across the new features |
| "Keep F-005 as one feature" (UX says don't split) | If XL: add a `## Decomposition Hints` section to the feature with suggested implementation sub-features, journey segment mapping, and component allocation per the feature entry template. Update spec readiness to Yes if all other criteria are met. Explain: "F-005 will stay as one backlog entry. When you run `/arn-code-feature-spec` on it, it will be decomposed into sub-feature specs (F-005.1, F-005.2, ...) with separate tracker rows and issue tracker entries." |
| "Merge F-003 and F-004" | Combine, consolidate journey references and behavior descriptions |
| "The interaction for F-002 is wrong" | Update the UI behavior description based on user's correction |
| "What does F-005 look like in the prototype?" | Reference the clickable prototype journey screenshots and showcase screens for that feature |
| "This feature needs more detail" | Invoke `arn-spark-ux-specialist` with the specific feature for deeper behavior analysis |
| "What did the experts disagree about for F-003?" | Show the debate insights from review reports for that feature |
| "Show me the showcase for F-005" | Reference the showcase-index.md sections for that feature |
| "What visual assets do we have for F-002?" | Check visual grounding directories and showcase for that feature |
| "Change visual target for F-007" | Update the classification |
| "What components does F-004 use?" | Show the library and product-specific components for that feature |
| User is satisfied | Proceed to Step 5 |

Track all changes. The user has final authority over priorities and behavior descriptions -- the experts provide recommendations, not mandates.

### Step 5: Validate Feature Sizing

If sizing concerns were already resolved during Step 4 refinement (user already split/merged features), skip this step. Otherwise, review the feature list for sizing issues:

**Too large (should split):**
- Any feature estimated as XL should be reviewed. XL features typically need decomposition before they can be effectively specced. Suggest splitting along journey boundaries or by UI area.
- Any feature that spans more than 3 user journeys is likely too broad.

**XL features kept whole (decomposition hints path):**
- If the UX specialist or user determines that an XL feature is one coherent user-facing capability that should not be split in the backlog, the feature can remain as a single backlog entry.
- Add a `## Decomposition Hints` section to the feature per the feature entry template. The hints must include at least 2 suggested sub-features with journey segment mappings, component allocations, a split rationale, and inter-sub-feature dependencies.
- Update the spec readiness assessment: the feature is ready for spec if all other criteria are met AND the decomposition hints section is present.
- Inform the user: "F-NNN will remain as one entry in the backlog. When you run `/arn-code-feature-spec` on it, it will be decomposed into [N] sub-feature specs (F-NNN.1, F-NNN.2, ...) with separate issue tracker entries and Feature Tracker rows. Each sub-feature will be a separate pickable and shippable work item."

**Too thin (should merge):**
- Any S-complexity feature that is a minor UI change or single interaction step might not warrant its own spec. Consider merging it into a parent feature.
- Features that only appear in one journey step and have no standalone value are candidates for merging.

**Right-sized features typically:**
- Map to 1-2 user journeys or a coherent segment of a larger journey
- Have 3-8 distinct interactions or behaviors to describe
- Can be specified, implemented, and tested independently
- Deliver a user-facing capability that makes sense on its own

Present sizing concerns to the user and resolve before writing.

### Step 6: Write Feature Files and Index

When the user is ready:

1. Read both templates:
   > Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-feature-extract/references/feature-entry-template.md`
   > Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-feature-extract/references/feature-backlog-template.md`

2. Create the features directory: `[vision-dir]/features/`

3. Write individual feature files — one per feature, using the feature entry template:
   - File naming: `F-NNN-kebab-name.md` (e.g., `F-001-device-discovery.md`, `F-002-voice-communication.md`)
   - Each file includes all fields per the lean feature entry template: description, journey summary (brief + UC refs), UI behavior (unique-beyond-UC), components, priority rationale, complexity notes, technical notes, source, references (prototype, showcase, visual target), debate insights, use case context (references with step ranges, not inlined), acceptance criteria, spec readiness
   - Write features in batches of 4-5 using the Write tool for each file — all features are independent files, so write multiple files in a single turn for efficiency
   - Initial status in each file: `pending`
   - For XL features kept whole: include the `## Decomposition Hints` section. Set `Ready for spec: Yes` if all other spec readiness criteria are met. Sub-feature files are NOT created at this stage -- `arn-code-feature-spec` creates them at spec time.

4. Write the index file: `[vision-dir]/features/feature-backlog.md`
   - Populate using the backlog index template
   - **Feature Tracker table:**
     - One row per feature with ID, name, priority, deps, phase, issue (`--`), status (`pending`)
     - Assign phase per feature from the Implementation Order Suggestion (Foundation / Core / Enhancement / Polish)
     - Deps column derived from each feature's Dependencies field
   - **Feature Index:** grouped by functional area, one row per feature with relative link to the individual file
   - Implementation order suggestion based on priorities and dependencies
   - Deferred items (features discussed and explicitly excluded)
   - Journey-to-feature mapping table

5. Present a summary:

"Feature backlog saved to `[path]/features/`.

**Files written:** [N] individual feature files + 1 index (`feature-backlog.md`)

**Summary:**
- **Must-have:** [N] features
- **Should-have:** [N] features
- **Nice-to-have:** [N] features
- **Total:** [N] features
- **Journey coverage:** [N] of [M] user journeys fully mapped to features
- **Component coverage:** [N] library components, [M] product-specific components mapped

**Feature Tracker:** [N] features tracked with dependency graph. All statuses: pending.

**Suggested implementation order:**
1. Foundation: [list key features]
2. Core experience: [list key features]
3. Enhancement: [list key features]"

### Step 7: Issue Upload (Opt-in)

1. Read the **Issue tracker** field from `## Arness` config in the project's `CLAUDE.md` (values: `github`, `jira`, or `none`). If the field is not present, fall back to legacy detection: check for `GitHub: yes` and treat as `github`; otherwise treat as `none`.

2. If Issue tracker is `none` or not present: skip to Step 8.

3. If Issue tracker is `github` or `jira`:

Ask (using `AskUserQuestion`):

**"Would you like to upload these [N] features as issues to [GitHub/Jira]?"**

Options:
1. **Yes, upload** — Each issue will carry a lean brief (description, journey summary, acceptance criteria, components, technical notes) with repo links to the full feature file and use case documents
2. **Skip** — Do not upload issues now

4. If the user declines: skip to Step 8.

5. If the user accepts:

   a. **Ensure labels exist:**
      - If GitHub: Create labels if missing using `gh label create --force`. Reference `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-init/references/platform-labels.md` for label definitions (name, color, description). Labels needed: `arness-feature-issue` + priority labels (`arness-priority-high`, `arness-priority-medium`, `arness-priority-low`).
      - If Jira: No label creation needed (labels are freeform and created implicitly).

   b. **Priority mapping:**
      - Must-have -> `arness-priority-high`
      - Should-have -> `arness-priority-medium`
      - Nice-to-have -> `arness-priority-low`

   c. **Construct repo browse URL:**
      - Read Platform from `## Arness` config: `github`, `bitbucket`, or `none`
      - For GitHub: derive `https://github.com/<owner>/<repo>/blob/main/` from the git remote URL
      - For Bitbucket: derive `https://bitbucket.org/<workspace>/<repo>/src/main/` from the git remote URL
      - If platform is `none` or URL cannot be determined: repo links will be omitted from issue bodies
      - Hold this base URL for use in all issue bodies

   d. **Create issues in implementation order, in parallel batches of 4-5 using Task agents:**
      - Order features by implementation sequence (Foundation first, then Core, Enhancement, Polish; within each phase, by dependency order)
      - For each batch of 4-5 features:
        - Spawn Task agents in parallel (one per feature in the batch)
        - Each Task agent reads the individual feature file (`[vision-dir]/features/F-NNN-kebab-name.md`) and formats the issue body using the **Issue Body Template** section in `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-feature-extract/references/feature-backlog-template.md`, constructing repo links using the base URL. Then creates the issue:
          - **If GitHub:**
            ```bash
            gh issue create --title "F-NNN: Feature Name" --body "<issue-body>" --label "arness-feature-issue,arness-priority-<level>"
            ```
          - **If Jira:**
            Use the Atlassian MCP server to create a Story with:
            - Summary: "F-NNN: Feature Name"
            - Description: issue body (Jira-compatible markdown)
            - Labels: `[arness-feature-issue, arness-priority-<level>]`
            - Priority: High / Medium / Low (native Jira field, mapped from backlog priority)
        - Collect the issue number (GitHub) or issue key (Jira) from each created issue
      - Wait for each batch to complete before starting the next (dependency references in later batches need issue numbers from earlier batches)

   e. **Update Feature Tracker in index:**
      - For each created issue, update the Issue column in the Feature Tracker (in `features/feature-backlog.md`) from `--` to the issue number (`#42`) or Jira key (`PROJ-42`)

   f. **Add dependency cross-references:**
      - For features with dependencies where the dependency issues have already been created, the issue body already contains the dependency references using the collected issue numbers. E.g., "Depends on #42 (F-001: Device Discovery)".

   g. **Re-write `features/feature-backlog.md`** with the updated Feature Tracker (issue numbers filled in). Individual feature files are not modified.

   h. **Present summary:**

"Created [N] issues on [GitHub/Jira]. Feature Tracker updated with issue references.

| ID | Feature | Issue | Priority |
|----|---------|-------|----------|
| F-001 | [Name] | #42 | Must-have |
| F-002 | [Name] | #43 | Must-have |
| ... | ... | ... | ... |

Dependencies are noted in the issue bodies. Use `/arn-code-pick-issue` to work through these features in dependency order."

### Step 8: Recommend Next Steps

"Your feature backlog is ready. Next steps:

1. **Set up visual testing:** Run `/arn-spark-visual-strategy` to define visual regression testing against the prototype baselines. This ensures that feature implementations match the validated design.
2. **Start developing:** If you have the Arness Code plugin installed, run `/arn-planning` to begin the development pipeline. Arness auto-configures on first use.
3. **Pick features from the backlog:** Run `/arn-code-pick-issue` to browse features in dependency order and route to `/arn-code-feature-spec` for detailed specification. The Feature Tracker shows which features are unblocked.
4. **Or start speccing directly:** Run `/arn-code-feature-spec` with a feature from the backlog to create a detailed specification. Each feature file (`features/F-NNN-name.md`) includes journey summaries with UC references, validated components, and UI behavior details. `/arn-code-feature-spec` will read the referenced UC documents for full behavioral detail.


I recommend starting with the Foundation phase features (those with no dependencies that enable other features). Each feature file references its upstream use case documents -- `/arn-code-feature-spec` will expand these references at spec time, reading the full UC documents for behavioral detail.

The Feature Tracker in `features/feature-backlog.md` is updated by `/arn-code-ship` after each PR — marking shipped features as done and surfacing newly unblocked features."

If the development pipeline is already configured (`## Arness` section exists in CLAUDE.md with Code patterns field), skip the development transition recommendation.

If issues were uploaded (Step 7), emphasize `/arn-code-pick-issue` as the primary path: "Since features are uploaded as issues, `/arn-code-pick-issue` will show you unblocked features with dependency resolution and validate against the remote issue tracker."

## Agent Invocation Guide

| Situation | Action |
|-----------|--------|
| Initial feature extraction (Step 2) | Invoke `arn-spark-product-strategist` with all artifacts (including showcase, debate reports, visual grounding), then `arn-spark-ux-specialist` for behavior and component analysis |
| User asks "what am I missing?" | Invoke `arn-spark-product-strategist` with current list and journey definitions for gap analysis |
| User questions a priority or complexity | Invoke `arn-spark-product-strategist` for assessment |
| User asks to re-prioritize the whole list | Invoke `arn-spark-product-strategist` with user's prioritization criteria |
| User wants more detail on a feature's behavior | Invoke `arn-spark-ux-specialist` with the feature, its journey context, and showcase screenshots |
| User asks about feature boundaries (split/merge) | Invoke `arn-spark-ux-specialist` with the features in question and their journey mapping |
| User asks about debate findings for a feature | Read the relevant debate report files directly; no agent invocation needed |
| User asks about visual grounding for a feature | Check visual grounding directories and showcase-index.md; no agent invocation needed |
| User asks about components for a feature | Reference showcase-manifest.json (library) and screen-manifest.json (product-specific); no agent invocation needed |
| User makes direct changes | Record directly, no agent needed |
| User asks about technology choices | Defer: "Technology choices are in the architecture vision. This skill focuses on what features to build, not how." |
| User asks about implementation details | Defer: "Implementation details come during `/arn-code-feature-spec`. The backlog captures what to build and how it should behave." |
| arn-spark-ux-specialist unavailable | Proceed with `arn-spark-product-strategist` alone. Derive behavior descriptions and component mapping from journey definitions, prototype screenshots, and showcase outputs directly. Note the limitation. |

## Error Handling

- **Only product concept available:** Extract from the product concept alone. Note that features will lack journey context and interaction behavior without prototype input. Behavior descriptions will be speculative. Components, showcase references, debate insights, and use case context will be "None".
- **No prototype results available:** Extract features from product concept and architecture vision. Note that UI behavior, component mapping, and journey mapping will be less detailed. Suggest running `/arn-spark-static-prototype` and `/arn-spark-clickable-prototype` first for richer feature context.
- **No product concept found and user declines to describe:** Cannot extract features from nothing. Suggest: "Run `/arn-spark-discover` first to define what you are building."
- **Product strategist returns unhelpful analysis:** Summarize the issue and continue the conversation directly. Extract features from the artifacts manually and present for user review.
- **arn-spark-ux-specialist unavailable:** Proceed with product strategist output. Derive UI behavior descriptions and component mapping from journey definitions, prototype screenshots, and showcase outputs directly. Gap resolution (Step 2b) will use product strategist only.
- **Gap resolution finds no gaps:** Skip Step 2b entirely — this is normal for simpler projects with good artifact coverage.
- **Experts disagree on gap solutions:** Present both perspectives to the user in Step 3 with the label "Unresolved gap" and let the user decide during refinement (Step 4).
- **Feature list is very large (20+ features):** Suggest the user focus on must-have and should-have for v1. Move nice-to-haves to the Deferred Items section. Check for features that should be merged.
- **Many XL features:** The feature list needs more decomposition. Work with the user to split XL features along journey boundaries before finalizing.
- **Writing a feature file fails:** Print the feature content in the conversation so the user can copy it. Continue with remaining features.
- **Features directory creation fails:** Try the parent directory. If that also fails, fall back to writing a single `feature-backlog.md` at the vision directory root (monolithic fallback).
- **Feature backlog already exists:**

  Ask (using `AskUserQuestion`):

  > **A feature backlog already exists at `[path]/features/`. How would you like to proceed?**
  > 1. **Replace** — Fresh extraction, overwriting existing files
  > 2. **Update** — Update specific features while preserving existing status and issue references

  If **Update**, read the existing Feature Tracker to preserve status and issue references for features being kept.
- **Spike results show failed risks:** Features that depended on failed technologies should be flagged. Either adjust the feature to use the alternative approach from the spike, or defer the feature. Note the spike limitation in the feature's technical notes.
- **Journey definitions missing but prototype exists:** Derive journeys from the prototype screen navigation flow. The journey will be less detailed than one from the clickable prototype validation, but still provides useful structure.
- **User cancels mid-conversation:** If enough features have been discussed, offer to write a partial backlog. Otherwise, inform the user they can restart with `/arn-spark-feature-extract` at any time.
- **Showcase outputs not found:** Note in artifact inventory. Features will not have showcase references. Component mapping will rely on style brief Component Style section only.
- **Debate reports not found:** Note in artifact inventory. Features will not have debate insights.
- **Visual grounding directory not found or empty:** Note in artifact inventory. All features default to `Style brief only` visual target.
- **Screen manifest not found:** Note in artifact inventory. Product-specific component mapping will use screen scanning instead of manifest-based lookup.
- **Issue creation fails (GitHub):** Show the error and offer to retry the failed batch. Successfully created issues are preserved in the Feature Tracker. The user can re-run Step 7 for remaining features.
- **Issue creation fails (Jira):** Show the MCP error and offer to retry. Note which issues were successfully created.
- **Partial issue upload (user cancels mid-batch):** Save the Feature Tracker with whatever issues were created. Inform the user they can re-run the upload for remaining features.
- **Issue tracker not configured:** Skip Step 7 silently and proceed to Step 8.
