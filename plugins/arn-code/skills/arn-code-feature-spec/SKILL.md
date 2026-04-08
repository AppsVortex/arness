---
name: arn-code-feature-spec
description: >-
  This skill should be used when the user says "feature spec", "arness code feature
  spec", "arn-code-feature-spec", "spec this feature", "help me spec", "design this feature", "feature
  design", "write a spec", "create a specification", "I have an idea for a
  feature", "let's flesh out this feature", "decompose feature",
  "spec XL feature", "resume spec", "continue spec", "finish my spec",
  "break down feature", or wants to iteratively develop a feature idea into a
  well-formed specification through guided conversation with architectural
  analysis. For XL features with decomposition hints, creates multiple
  sub-feature specs with full traceability. Produces specification documents
  capturing WHAT to build and WHY, which then feed into plan creation.
version: 1.3.0
---

# Arness Feature Spec

Develop a feature idea into a well-formed specification through iterative conversation, aided by architectural analysis from the `arn-code-architect` agent and, when the feature involves UI, user experience design from the `arn-code-ux-specialist` agent. This is a conversational skill that runs in normal conversation (NOT plan mode). The primary artifact is a **feature specification** written to the project's specs directory that captures requirements, architectural assessment, and decisions from the exploration conversation. The spec then informs plan creation via the `/arn-code-plan` skill.

## Step 0: Ensure Configuration

Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-ensure-config/references/ensure-config.md` and follow its instructions. This guarantees a user profile exists and `## Arness` is configured with Arness Code fields before proceeding.

## Workflow

### Step 1: Capture the Feature Idea

#### 1a. Detect Backlog Feature (Greenfield Path)

Before asking the user to describe their feature, check if the trigger includes a greenfield feature backlog entry:

1. Check if the trigger message contains an F-NNN pattern (regex: `F-\d{3}`). Accept natural invocations like:
   - `feature spec F-002`
   - `spec F-002: Device Pairing`
   - `feature spec: Device Pairing` (fuzzy match against feature file names in the features directory)

2. Check if conversation context from `arn-code-pick-issue` includes feature file content (look for markers: `## Description`, `## Journey Steps`, `## Acceptance Criteria` that indicate an F-NNN file was passed inline).

3. **If either condition is met:** extract the feature ID and proceed to **Step 1b**.

4. **If neither condition is met:** fall through to the standard flow below (ask the user to describe the feature).

#### 1b. Load Greenfield Feature Context

Only runs when a backlog entry is detected in Step 1a. Loads the feature file, referenced UC documents, and scope boundary context (related features from the Feature Tracker) to provide rich context for the spec exploration. If any greenfield artifact is missing, falls back gracefully.

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-feature-spec/references/greenfield-loading.md` for the full loading sequence and error handling.

- If the style-brief has an "Animation and Motion" section, extract it as animation context. This will be passed to both the architect and UX specialist.

#### 1c. Detect XL Decomposition

Only runs after Step 1b successfully loads a greenfield feature.

1. Check if the loaded feature file has:
   - `**Complexity:** XL`
   - A `## Decomposition Hints` section with at least 2 suggested sub-features

2. **If both conditions are met:** Set a flag: `decomposition_mode = true`. Hold the decomposition hints (suggested sub-features, split rationale, inter-dependencies) for use in Step 5. Inform the user:

   "This is an XL feature with decomposition hints. I will create separate sub-feature specs (F-NNN.1, F-NNN.2, ...) instead of a single spec, each scoped to an implementation slice. Let me analyze the implementation approach."

3. **If the feature is XL but has NO or insufficient decomposition hints** (fewer than 2 sub-features): Warn the user:

   Ask (using `AskUserQuestion`):

   **"Feature F-NNN is estimated as XL but has no decomposition hints (or fewer than 2 sub-features). How would you like to proceed?"**

   Options:
   1. **Provide decomposition hints now** -- Suggest 2-4 sub-features with journey segment mappings
   2. **Proceed with a single spec anyway** -- Not recommended for XL features
   3. **Return to the backlog** -- Run `/arn-spark-feature-extract` to add decomposition hints

   If **Provide decomposition hints now**: the user provides hints inline, capture them in the same structure as the feature entry template's `## Decomposition Hints` section and set `decomposition_mode = true`. If **Proceed with a single spec anyway**: set `decomposition_mode = false` and continue normally.

4. **If the feature is not XL:** Set `decomposition_mode = false`. Proceed to Step 2.

#### 1d. Standard Flow (No Backlog Entry)

Ask the user to describe their feature idea. Accept anything from a single sentence to a detailed description. Do not require a specific format.

If the user already provided the feature idea in their trigger message (e.g., "feature spec: add WebSocket support for real-time notifications"), use that directly without asking again.

Acknowledge the idea with a brief restatement to confirm understanding.

---

### Step 2: Load Codebase Context

Read the project's CLAUDE.md and extract the `## Arness` section to find the Code patterns path and Specs directory path.

Read the stored pattern documentation:
- `<code-patterns-dir>/code-patterns.md`
- `<code-patterns-dir>/testing-patterns.md`
- `<code-patterns-dir>/architecture.md`
- `<code-patterns-dir>/ui-patterns.md` (if it exists)
- `<code-patterns-dir>/security-patterns.md` (if it exists)

**If pattern documentation files are missing** (no `code-patterns.md`, `testing-patterns.md`, or `architecture.md` in the Code patterns directory):

Inform the user: "This is the first time pattern documentation is being generated for this project. Analyzing your codebase to understand its patterns, conventions, and architecture. This is a one-time operation — future invocations will use the cached results."

Then invoke the `arn-code-codebase-analyzer` agent to generate fresh analysis. Write the results to the Code patterns directory. Summarize the key findings relevant to the feature idea.

Hold this context for use throughout the conversation. Do not dump all of it on the user — reference specific parts when relevant.

**Sketch detection:** Check if a `arness-sketches/` directory exists at the project root. If it does, scan for a subdirectory whose name matches the feature being specified (by feature name, F-NNN ID, or keyword overlap). If a matching sketch directory is found:
1. Read `arness-sketches/<sketch-name>/sketch-manifest.json`
2. If the manifest file cannot be read or parsed (malformed JSON, empty file, permission error), set `sketch_context_loaded = false` and proceed normally — treat as if no sketch exists.
3. Verify the manifest has `componentMapping` and `composition` fields (Phase 1 enrichment)
4. If both fields are present, set `sketch_context_loaded = true` and hold the manifest data (sketch directory path, manifest path, status, paradigm, componentMapping entries, composition metadata) for use in Step 5
5. If the manifest exists but lacks `componentMapping` or `composition`, set `sketch_context_loaded = false` — the sketch predates the enrichment and cannot be referenced in the spec
6. If no matching sketch directory is found, set `sketch_context_loaded = false` and proceed normally

This check is silent — do not announce sketch detection to the user unless the sketch will affect the spec content.

**If greenfield context was loaded in Step 1b**, hold both the codebase patterns AND the greenfield context (feature file + UC documents) as combined context. The greenfield context provides behavioral requirements (WHAT to build), while the codebase patterns provide implementation conventions (HOW the codebase does things). These two sources complement each other and are both used in subsequent steps.

---

### Step 2b: Check for Existing Draft

After loading codebase context, check `<specs-dir>/` for files matching `DRAFT_FEATURE_*.md`.

**If one or more DRAFT files exist:**

1. If only one DRAFT exists, present it: "I found an in-progress draft: `DRAFT_FEATURE_<name>.md`. Would you like to resume editing this draft, or start fresh?"
2. If multiple DRAFTs exist, list them and ask which to resume (or start fresh).

**If resuming:**
- Read the DRAFT file
- Present the current state: which sections are populated, what decisions are logged, what open items remain
- Derive the spec name from the DRAFT filename (strip `DRAFT_FEATURE_` prefix and `.md` extension)
- Skip Steps 2c and 3 (initial analysis is already captured in the draft) and proceed to Step 4 (exploration) with the draft context loaded
- The DRAFT file becomes the working document for subsequent updates

**If starting fresh** (or no DRAFTs found):
- Continue to Step 2c and Step 3 as normal
- If a DRAFT with the same name already exists (detected after spec name derivation in Step 2c), ask: overwrite or choose a different name

**Greenfield path (Step 1b loaded):**
- Match DRAFT files by F-NNN prefix when applicable (e.g., `DRAFT_FEATURE_F-001_device-setup.md`)

---

### Step 2c: Derive Spec Name

Derive a spec name for the feature to use for both the DRAFT and final spec files.

**If greenfield context loaded (Step 1b):**
- Use the F-NNN ID and feature name: `F-NNN_<kebab-name>` (e.g., `F-001_device-setup`)
- No user confirmation needed — the name comes from the feature backlog entry

**If standard flow (Step 1d):**
- Derive from the feature description (e.g., "WebSocket support for real-time notifications" → `websocket-notifications`)
- Suggest to the user: "I'll call this feature spec `<name>`. Good?"
- If the user suggests a different name, use that instead

Hold the spec name for use in Steps 3-5. The draft file will be `<specs-dir>/DRAFT_FEATURE_<name>.md`. The final file will be `<specs-dir>/FEATURE_<name>.md`.

---

### Step 3: Initial Analysis

#### 3a. Detect UI involvement

Before invoking agents, determine whether the feature involves UI:

- Check if `ui-patterns.md` exists in the code patterns directory (with a `## Sketch Strategy` section), or if the Technology Stack table in `architecture.md` contains a frontend framework entry (React, Vue, Svelte, Angular, Next.js, Nuxt, SvelteKit, etc.) or a CLI/TUI/desktop/mobile framework entry (Click, Typer, Rich, Textual, BubbleTea, Ratatui, Qt, Electron, SwiftUI, Jetpack Compose, or similar)
- Analyze the feature description for interface-related terms: component, page, form, button, layout, dashboard, UI, UX, screen, view, modal, dialog, command, terminal, output, widget, window, panel, console, display, prompt, menu, toolbar, status bar, progress, table (output), tree (output)
- If ambiguous, ask the user: "Does this feature involve any user-facing interface work (web UI, CLI output, TUI screen, desktop window, or mobile screen)?"

**Result:** **"involves UI"** or **"no interface work"**

#### 3b. Pre-check security relevance and invoke agents

Before invoking any agents, read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-ensure-config/references/specialist-pre-check.md` and apply the security relevance pre-check using the pattern documentation loaded in Step 2 and the feature description:

- `security_relevant`: true if BOTH: (1) `security-patterns.md` exists in the code patterns directory, AND (2) the feature description contains security terms (auth, login, password, token, payment, upload, API key, PII, encrypt, permission, session, cookie, CORS, CSRF, rate limit, secret, credential -- case-insensitive)

**Parallel agent dispatch based on pre-check:**

**If `security_relevant` is true:** Dispatch the following agents in parallel:
- `arn-code-architect` (always)
- `arn-code-ux-specialist` (if the feature involves UI, from Step 3a)
- `arn-code-security-specialist`

**If `security_relevant` is false:** Dispatch the following agents in parallel:
- `arn-code-architect` (always)
- `arn-code-ux-specialist` (if the feature involves UI, from Step 3a)

All dispatched agents run in parallel (independent analyses, no cross-agent dependencies).

**For `arn-code-architect`, provide:**

**User expertise context:**

```
--- BEGIN USER EXPERTISE ---
[Read from ~/.arness/user-profile.yaml or .claude/arness-profile.local.md (project override takes precedence)]
Role: [role]
Experience: [development_experience]
Technology preferences: [technology_preferences]
Expertise-aware: [expertise_aware]
--- END USER EXPERTISE ---

--- BEGIN PROJECT PREFERENCES ---
[Read from .arness/preferences.yaml if it exists, otherwise omit this section]
--- END PROJECT PREFERENCES ---
```

When presenting technology recommendations, apply the advisory pattern: present the technically optimal recommendation first, then present any preference-aligned alternative with honest pros/cons. Let the user decide.

**Feature idea:** The user's description from Step 1d, OR (if greenfield context loaded) the feature file's Description section from Step 1b.

**Codebase context:** The full content of the stored pattern documentation files loaded in Step 2 (code-patterns.md, testing-patterns.md, architecture.md, and ui-patterns.md if present). If these were not available and `arn-code-codebase-analyzer` was used instead, pass that output.

**Behavioral context (if greenfield context loaded):** The full UC main success scenarios and extensions from the loaded UC documents, technical notes from the feature file, and business rules as constraints. Add instruction: "The behavioral requirements are well-defined by the use case documents. Focus your analysis on HOW to implement these behaviors within the existing codebase patterns, not on WHAT to implement."

**Style context (if style-brief loaded in Step 1b):** The project has a validated style-brief with toolkit configuration. The following tokens and config have been validated through static prototype showcase and clickable prototype screens: [toolkit configuration section from style-brief]. Note: Reference these tokens in the architectural assessment's component integration points. Implementation should use these exact values rather than generating new ones.

**Animation context (if loaded from style-brief):** Animation approach, motion philosophy, timing characteristics, key patterns. Consider: animation library/framework integration, animation cleanup on route/view changes, and performance implications for the project's platform.

**Specific question:** None for the initial invocation.

**Note:** If architecture.md contains "Architectural Constraints" (from greenfield architecture-vision), the architect will validate the proposed implementation against pillar and business constraints. Constraint conflicts will appear in the architect's output as flagged risks with a "Constraint Compliance" section.

**For `arn-code-ux-specialist` (when dispatched), provide:**

**Feature idea:** The user's description from Step 1d, OR (if greenfield context loaded) the feature file's Description section from Step 1b.

**Codebase context:** Same pattern documentation files as the architect.

**UI context (if greenfield context loaded):** The feature file's UI Behavior section, Components list (library + product-specific with prototype references), journey summary, and debate insights about UI decisions. Add instruction: "The UI components and interaction patterns are already validated in the prototype. Focus on mapping these to the codebase's UI patterns and identifying any implementation gaps between the prototype design and the current frontend architecture."

**Style context (if style-brief loaded in Step 1b):** The style-brief's toolkit configuration has been validated through static prototype showcase and clickable prototype screens. The following design tokens are production-ready: [full color palette, typography, spacing from style-brief] [toolkit configuration code from style-brief]. Map your component hierarchy recommendations to these validated tokens. Reference specific token names (e.g., "primary-500", "heading-1") rather than abstract descriptions.

**Animation context (if loaded from style-brief):** Motion design tokens, timing scale, easing functions. Describe which components in this feature should animate, what triggers the animation, and how it matches the product's tone commitment. Output a "Motion Design" subsection in UI Design using platform-agnostic intent language.

**Operating mode hint:** "existing frontend" if ui-patterns.md exists or architecture.md shows a frontend framework, otherwise "greenfield frontend".

**For `arn-code-security-specialist` (when dispatched in parallel), provide:**

**Feature idea:** The user's description from Step 1d, OR the feature file's Description from Step 1b.

**Codebase context:** The content of `security-patterns.md` plus the feature description and codebase patterns context.

**Prompt:** "List 3-5 security considerations for this feature given the codebase context.
Focus on threats, required mitigations, and any security patterns that should be followed.
Keep it brief -- this is design-time guidance, not a full security review."

This is a lightweight invocation -- the output feeds into the spec's Non-Functional
Requirements (security bullet) and Feasibility & Risks section. It does NOT block or
replace the architect's analysis.

**False-negative follow-up (only when `security_relevant` was false):**

After the parallel batch completes, check the architect's assessment for security signals. If the architect's output mentions security concerns, authentication, authorization, data protection, or vulnerability AND `security_relevant` was false: dispatch `arn-code-security-specialist` sequentially with the architect's assessment as additional context. Provide the same prompt as above, plus the architect's proposal.

**False-negative follow-up for UI (only when no UX specialist was dispatched):**

If the architect's response reveals UI involvement that was not detected in Step 3a (e.g., the user said "no UI" to the clarifying question but the architect identifies UI components, screens, or interface work), and no `arn-code-ux-specialist` was dispatched: dispatch `arn-code-ux-specialist` sequentially as a follow-up with the same context as the initial invocation plus the architect's assessment.

All follow-up dispatches are silent -- no user notification or status message. The user sees the combined output from all agents (parallel + sequential) as a single result.

#### 3c. Present the initial proposal

Present the combined output to the user as the **initial proposal**. Highlight:
1. The proposed approach (1-2 sentence summary from the architect)
2. Key components that would be created or modified
3. UI design proposal (if UX specialist was invoked): component hierarchy, accessibility requirements, and any proposed UI stack (greenfield)
4. Open questions from both agents
5. Security considerations (if security specialist was invoked): key threats and recommended mitigations

**Proactive sketch offer (conditional):** If ALL of these conditions are met:
- The feature involves UI (detected in Step 3a)
- `ui-patterns.md` exists in the code patterns directory with a `## Sketch Strategy` section

Then include in the proposal presentation:

Ask (using `AskUserQuestion`):

**"This feature involves interface work. Would you like to see a visual preview before we dive deeper?"**

Options:
1. **Yes, sketch it** -- Generate a sketch showing what the [components/screens/output] would look like
2. **No, continue with the spec** -- Proceed to exploration

If **Yes, sketch it**: Invoke `Skill: arn-code:arn-code-sketch` with the current feature context (description, architectural assessment, UX specialist output). After the sketch session completes, resume the exploration conversation. The sketch output informs subsequent spec decisions.
If **No, continue with the spec**: Proceed to exploration.

If sketch conditions are NOT met (no UI involvement or no Sketch Strategy), skip this offer entirely — do not mention sketch.

Then ask: "What do you think? Any questions, concerns, or changes?"

#### 3d. Write Initial Draft

After presenting the initial proposal to the user (3c), write the draft spec to disk as an automatic save point.

1. Read the feature spec template at `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-feature-spec/references/feature-spec-template.md`.

2. Populate the template with what is available from the initial analysis:

   | Section | Source | Completeness |
   |---------|--------|-------------|
   | Problem Statement | User's feature description (Step 1) | Full |
   | Functional Requirements | Initial requirements from architect analysis | Partial — mark with "[Draft — may be refined during exploration]" |
   | Non-Functional Requirements | From architect + security specialist (if invoked) | Partial |
   | Architectural Assessment | Full architect output (approach, components, integration points) | Full initial analysis |
   | Key Decisions | From initial agent outputs | Partial — only initial decisions |
   | Proposed UI Stack | From UX specialist (if greenfield UI) | Full if applicable |
   | UI Design | From UX specialist (if UI involved) | Full initial analysis |
   | Scope & Boundaries | From feature description + initial analysis | Partial |
   | Behavioral Specification | From Step 1b greenfield context (if loaded) | Full if applicable |
   | Feasibility & Risks | From architect + security specialist | Partial |
   | Decisions Log | Empty or minimal (exploration has not started yet) | Empty |
   | Open Items | Open questions from agents | Full initial list |
   | Recommendation | "In progress — exploring with user" | Placeholder |

3. Add a draft status marker at the top of the file (before the title):

   ```
   > **Status: DRAFT** — This specification is under active development. Last updated during exploration. Run `/arn-code-feature-spec` to resume or finalize.
   ```

4. Write to `<specs-dir>/DRAFT_FEATURE_<name>.md`.

5. Inform the user (brief, one line — not a decision gate): "Draft spec saved to `<specs-dir>/DRAFT_FEATURE_<name>.md` — I'll keep it updated as we explore."

Do NOT ask the user for approval to write the draft. This is an automatic save point, not a decision gate. The user's attention should remain on the initial proposal and their response to "What do you think?"

If the draft write fails (permissions, path issues), continue without the draft and fall back to the current behavior (write everything at Step 5). Inform the user: "Could not save draft — I'll write the spec at the end instead."

---

### Step 4: Exploration Phase (Iterative)

**When greenfield context is loaded:** The exploration phase should be shorter and more focused. The behavioral requirements (what to build) are already defined by the feature file and use cases. Exploration should focus on: (1) implementation approach within the codebase, (2) gaps between the defined behavior and what the codebase can support, (3) technical decisions not covered by the feature file. Do not re-explore requirements that are already well-defined in the loaded context.

**When decomposition mode is active:** The exploration phase should additionally validate the decomposition hints: are the suggested sub-feature boundaries correct? Do the journey segment mappings make sense? Are the inter-sub-feature dependencies accurate? The user can adjust the decomposition during this phase. Each sub-feature should be independently implementable and testable.

**Scope boundary awareness (when scope boundary context is loaded from Step 1b):** Before raising any question about whether to include adjacent functionality in this feature's spec, FIRST check the loaded scope boundary context (related feature descriptions, journey steps, and acceptance criteria). Apply this rule:

- **If the concern IS covered by another feature:** Do not ask the user whether to include it. Instead, note it as a cross-feature dependency: "That's handled by F-NNN: [Feature Name] — I'll note it as a dependency in this spec's Scope & Boundaries." Continue without expanding scope.
- **If the concern is PARTIALLY covered by another feature:** Note what the other feature covers and identify the specific gap. Only raise the uncovered portion: "F-NNN: [Name] covers [X], but [Y] isn't addressed by any feature. Should we include [Y] in this spec or flag it as a backlog gap?"
- **If the concern is NOT covered by any feature in the backlog:** Flag it as a genuine gap and ask the user: "This isn't covered by any feature in the backlog: [description]. Options: (1) include it in this spec, (2) note it as a gap for a future feature, (3) add it to the backlog via `/arn-spark-feature-extract`."

This prevents scope creep by ensuring the agent knows what sibling features already handle, and only escalates genuine gaps to the user.

This is a conversation loop. Each iteration:

1. **Listen** — the user responds with feedback, questions, concerns, or new requirements.

2. **Decide how to respond** — first apply the scope boundary awareness rule above (check sibling features before raising scope questions), then consult the Agent Invocation Guide table below to determine whether to invoke an agent or answer directly.

3. **Summarize the current state** — after each substantive exchange, briefly state where things stand: what has been decided, what is still open.

4. **Update the draft** — if a draft file exists (written in Step 3d or loaded during resume in Step 2b), apply the Draft Update Protocol below.

5. **Check for readiness** — when the conversation feels like it is converging (open questions are being resolved, the user is agreeing more than questioning), ask:

   **"I think we have enough to finalize the feature specification. Ready for me to finalize it, or do you want to explore anything else first?"**

   Do not ask this after every single exchange. Use judgment — typically after 2-4 rounds of substantive discussion, or when the user signals readiness (e.g., "I think that covers it", "looks good").

#### Arness-Sketch Integration (On-Demand)

**Note:** The proactive sketch offer happens in Step 3c (after the initial proposal). This section handles the case where the user requests a sketch later during exploration — either because they declined the initial offer, or because the conversation evolved and they now want to visualize something specific.

During exploration, if the user asks to see what the feature would look like (e.g., "show me what this looks like", "can I see a preview", "what would the UI look like", "sketch this"), and the feature involves interface work (detected in Step 3a), and `ui-patterns.md` exists with a `## Sketch Strategy` section, invoke `Skill: arn-code:arn-code-sketch` with the current feature context (description, architectural assessment, UX specialist output if available). After the sketch session completes, resume the exploration conversation where it left off. The sketch output can inform subsequent spec decisions (component structure, layout choices, interaction patterns).

If the feature involves interface work but `ui-patterns.md` does not exist or has no `## Sketch Strategy` section, inform the user: "Sketch is not available for this project. Pattern documentation will be generated on first use and will include a Sketch Strategy if your project has a UI framework." Continue the exploration without sketching.

**After a sketch session completes:** If a arn-code-sketch session was invoked during exploration and produced a manifest with `componentMapping` and `composition` fields, capture the sketch context for Step 5. Set `sketch_context_loaded = true` and hold the manifest data (sketch directory path, manifest path, status, paradigm, componentMapping entries, composition metadata). This is the same data that Step 2 would detect from an existing sketch — the difference is that here the sketch was created during this spec session rather than before it.

#### Draft Update Protocol

After each substantive exchange that changes the spec content, update the DRAFT file using the Edit tool. A "substantive exchange" is one where:

- A decision is made → append to Decisions Log section, update Key Decisions table if the decision is architectural
- A requirement is added, changed, or removed → update the Requirements section
- Scope changes → update Scope & Boundaries section
- The architect or UX specialist provides significant new analysis → update the Architectural Assessment or UI Design sections
- An open item is resolved → remove from Open Items (optionally note resolution in Decisions Log)
- A new risk is identified → append to Feasibility & Risks section

Do NOT update the draft for:
- Simple Q&A that doesn't change the spec content
- User asking for clarification without making a decision
- Minor discussion that doesn't affect any spec section

When updating, use the Edit tool to modify specific sections (surgical edits). Do not rewrite the entire file on each update.

After updating, do NOT announce it to the user. The update is silent — the user's conversational flow should not be interrupted by draft-save notifications. Exception: if the Edit fails, inform the user that the draft could not be updated, and continue the conversation normally. The draft may be partially stale but the conversation holds the latest state — Step 5 finalization will reconcile any gaps.

If the draft file was deleted externally during exploration, detect this at the next update attempt and recreate the draft from conversation context before continuing.

**When invoking agents during exploration**, pass this context:

```
Feature: [current refined feature description incorporating all decisions]

Codebase context: Pattern documentation was loaded in Step 2. Key patterns
relevant to this feature:
- [list 2-4 specific patterns from the docs that matter]

Greenfield context (if loaded): Feature file F-NNN and UC documents loaded
in Step 1b. Relevant behavioral detail:
- [reference specific UC steps, extensions, or business rules that apply]

Conversation context:
- Decisions made so far: [bullet list]
- Current question: [the specific question to investigate]
```

For `arn-code-ux-specialist`, also include the operating mode hint and any prior UX decisions.

---

### Step 5: Write the Feature Specification

When the user says yes to writing the spec:

**If `decomposition_mode` is true (XL Decomposition):**

Create multiple sub-feature specs, update the Feature Tracker, and optionally create child issues. After writing all sub-feature specs, delete the DRAFT file.

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-feature-spec/references/xl-decomposition.md` for the full decomposition procedure, Feature Tracker updates, child issue creation, and error handling.

The decomposition flow is self-contained. Do not proceed to the standard single-spec flow below.

**If `decomposition_mode` is false (standard single-spec flow):**

1. Read the feature spec template at `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-feature-spec/references/feature-spec-template.md`.

2. Read the current draft from `<specs-dir>/DRAFT_FEATURE_<name>.md`. Review each section against the template and the full exploration conversation. Fill in any remaining gaps, refine partial content, and ensure all sections are complete.

   Specific finalization actions:
   - Remove the `> **Status: DRAFT**...` block at the top of the file
   - Ensure the Decisions Log is complete with all decisions from the conversation
   - Ensure Open Items reflects the final state (resolved items removed)
   - Update Recommendation from the placeholder to an actual assessment
   - Replace any "[Draft — may be refined during exploration]" markers with final content
   - If greenfield context was loaded: ensure Behavioral Specification is fully populated from the loaded UC documents and feature file (Feature Backlog Entry metadata, Use Case References table, Main Success Scenarios, Key Extensions, Business Rules, Acceptance Criteria)
   - If scope boundary context was loaded: ensure Scope & Boundaries includes cross-references to sibling features and any gaps identified during exploration
   - If `sketch_context_loaded` is true, populate the Sketch Reference section:
     1. Fill in sketch directory, manifest path, status, and paradigm from held manifest data
     2. Populate the Component Mapping table from `componentMapping` entries (one row per component: sketch file path, target location, promotion mode, description)
     3. Populate the Composition Summary from the `composition` field (blueprint path, layout description, data flow, interaction flow)
   - If `sketch_context_loaded` is false, omit the Sketch Reference section entirely.
   - If animation context was loaded: ensure the Motion Design subsection under UI Design is populated with per-element animation specs, triggers, timing, and reduced-motion fallbacks from the UX specialist's output.

   If no draft file exists (draft write failed in Step 3d, or the skill fell back to in-conversation mode), populate the template from scratch using the conversation content — same as the previous behavior:
   - **Problem Statement:** The refined feature description incorporating all decisions. If greenfield context loaded: seed "What" from the feature file's Description and "Why" from the Priority Rationale.
   - **Requirements:** Functional and non-functional requirements gathered during exploration. If greenfield context loaded: seed Functional Requirements from the feature file's Acceptance Criteria (each criterion -> one requirement), and Non-Functional Requirements from UC Business Rules + feature file Technical Notes.
   - **Architectural Assessment:** The outputs from `arn-code-architect` invocations (initial proposal + subsequent answers), merged with `arn-code-ux-specialist` output (component design, accessibility, UI stack) if the feature involves UI
   - **Scope & Boundaries:** What is in scope and what is not, from the conversation. If greenfield context loaded: seed "In Scope" from the feature file's Description + Journey Summary. If scope boundary context was loaded: populate "Out of Scope" with explicit cross-references to sibling features.
   - **Sketch Reference (if `sketch_context_loaded` is true):** Populate from the held manifest data — sketch directory, manifest path, status, paradigm, Component Mapping table (from `componentMapping`), Composition Summary (from `composition`). Omit this section entirely if `sketch_context_loaded` is false.
   - **Feasibility & Risks:** Risks and concerns identified during exploration.
   - **Decisions Log:** All decisions made during the exploration phase.
   - **Open Items:** Any unresolved questions, risks, or areas needing investigation

3. Write the finalized spec to `<specs-dir>/FEATURE_<name>.md` (where `<specs-dir>` is the Specs directory from the `## Arness` config). If the specs directory does not exist, create it: `mkdir -p <specs-dir>/`

4. Delete the draft file: remove `<specs-dir>/DRAFT_FEATURE_<name>.md`. If the delete fails or the file does not exist, continue without error.

5. Present a summary to the user:
   - Spec file location
   - Key decisions captured
   - Open items remaining
   - Recommendation (ready for planning vs. needs more investigation)

6. Inform the user of next steps:

   "Feature specification saved to `<specs-dir>/FEATURE_<name>.md`.

   To create an implementation plan, run `/arn-code-plan FEATURE_<name>`.

   The skill will load this spec and your project's codebase patterns, invoke the planner agent to generate a plan, and let you review and refine it before saving."

---

## Agent Invocation Guide

Consult `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-feature-spec/references/agent-invocation-guide.md` to determine when to invoke each agent (arn-code-architect, arn-code-ux-specialist, arn-code-security-specialist) vs. answer directly during exploration.

## Error Handling

- If the user cancels at any point, confirm and exit gracefully. If a draft spec exists, inform the user of its location (`<specs-dir>/DRAFT_FEATURE_<name>.md`) so they can resume later by running `/arn-code-feature-spec` again (the draft will be detected in Step 2b).
- If `arn-code-architect` or `arn-code-ux-specialist` returns an unhelpful or empty response, summarize the issue to the user and offer to try a more specific question or proceed with what is known.
- If writing the spec file fails (permissions, path issues), print the spec content in the conversation so the user can save it manually.
- **Draft pattern errors:**
  - Draft write fails in Step 3d: continue without the draft. Fall back to in-conversation mode (write everything at Step 5). Inform the user: "Could not save draft — I'll write the spec at the end."
  - Draft update fails during Step 4 exploration: log a warning but continue the conversation. The draft may be partially stale but the conversation holds the latest state — Step 5 finalization will reconcile.
  - Draft file deleted externally during exploration: detect at next update attempt, recreate the draft from conversation context, and continue.
  - Resume finds a DRAFT from a different feature: the DRAFT filename includes the feature name, so mismatches are unlikely. If the user starts a new feature and an unrelated DRAFT exists, do not auto-resume — only offer resume for DRAFTs that match the current feature context (matched by filename or F-NNN prefix for greenfield).
- **Greenfield path errors:** See `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-feature-spec/references/greenfield-loading.md` (Error Handling section).
- **XL Decomposition errors:** See `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-feature-spec/references/xl-decomposition.md` (Error Handling section).
