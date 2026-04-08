---
name: arn-code-feature-spec-teams
description: >-
  This skill should be used when the user says "feature spec teams",
  "arness code feature spec teams", "team feature spec", "debate this feature",
  "collaborative feature spec", "spec with agent teams",
  "multi-agent feature spec", "feature spec debate", or wants to
  develop a feature idea through
  structured debate between multiple specialist agents (architects, UX
  experts, and security specialists) before writing the specification. Uses Claude Code's experimental
  Agent Teams feature. Requires Agent Teams to be enabled. For standard
  single-agent feature spec, use arn-code-feature-spec instead.
version: 0.1.0
---

# Arness Feature Spec Teams

Develop a feature idea through structured debate between specialist teammates — architects and UX experts — before synthesizing a specification. Uses Claude Code's experimental Agent Teams feature for direct inter-agent communication. Each teammate proposes, critiques, and revises independently, producing a richer spec than a single-agent approach.

Pipeline position:
```
arn-code-feature-spec-teams (team: propose -> critique -> revise -> resolve) -> /arn-code-plan
```

This is an alternative to `arn-code-feature-spec` (single-agent). Use this when:
- The feature is complex enough to benefit from multiple perspectives
- There is a significant UI/UX component that needs specialist advocacy
- Multiple architectural approaches are viable and warrant debate
- You want trade-offs and disagreements surfaced explicitly

## Prerequisites

If no `## Arness` section exists in the project's CLAUDE.md, inform the user: "Arness is not configured for this project yet. Run `/arn-planning` to get started — it will set everything up automatically." Do not proceed without it. For standard single-agent feature spec, use `arn-code-feature-spec` instead.

**Limitations compared to `arn-code-feature-spec`:**
- XL feature decomposition is not supported. Use `arn-code-feature-spec` for features that need to be broken into sub-features.
- Draft file management is not supported. If the session crashes, re-run the skill from the beginning.

## Workflow

### Step 1: Check Agent Teams Availability

Run via Bash: `echo $CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`

**If the variable is NOT set to "1":**
Inform the user: "This skill requires Claude Code's experimental Agent Teams feature."

Provide setup instructions:
- Add to `~/.claude/settings.json` under `"env"`:
  ```json
  "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  ```
- Or set the environment variable before running Claude Code:
  ```bash
  CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 claude
  ```

Suggest the alternative: "You can use `/arn-code-feature-spec` instead, which uses a single architect agent and doesn't require Agent Teams."

**If enabled:** proceed to Step 1b.

---

### Step 1b: Detect Greenfield Context (Optional)

This step activates only when greenfield artifacts exist. Projects without greenfield skip this step silently.

1. Check the trigger message for an F-NNN pattern (regex: `F-\d{3}`). Accept natural invocations like "feature spec teams F-002" or "team spec: Device Pairing".

2. If detected, or if conversation context includes feature file content (look for markers: `## Description`, `## Journey Steps`, `## Acceptance Criteria`):

   > Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-feature-spec/references/greenfield-loading.md` for the full loading sequence.

   Execute the loading sequence to load:
   - Feature file (F-NNN) with description, journey steps, UI behavior, components, acceptance criteria
   - Referenced UC documents (main success scenarios, extensions, business rules)
   - Scope boundary context (related features from Feature Tracker for cross-feature awareness)
   - Style-brief (if available at `[vision-dir]/style-brief.md` — toolkit configuration, color tokens, typography)

   If the style-brief has an "Animation and Motion" section, extract it as animation context. This will be passed to both the architect and UX specialist teammates.

3. Hold all loaded context for use in Step 4 (teammate spawn prompts).

4. If no F-NNN pattern detected and no feature file markers found: proceed to Step 2 as normal (standard flow).

---

### Step 2: Capture Feature Idea and Load Context

1. If the user provided the feature idea in the trigger message, use it directly. Otherwise, ask.

2. Read the project's CLAUDE.md and extract the `## Arness` section to find:
   - **Code patterns** -- path to the directory containing stored pattern documentation
   - **Specs directory** -- path to the directory containing specification files

3. Read the stored pattern documentation:
   - `<code-patterns-dir>/code-patterns.md`
   - `<code-patterns-dir>/testing-patterns.md`
   - `<code-patterns-dir>/architecture.md`
   - `<code-patterns-dir>/ui-patterns.md` (if it exists)
   - `<code-patterns-dir>/security-patterns.md` (if it exists)

   **If pattern documentation files are missing** (no `code-patterns.md`, `testing-patterns.md`, or `architecture.md` in the Code patterns directory):

   Inform the user: "This is the first time pattern documentation is being generated for this project. Analyzing your codebase to understand its patterns, conventions, and architecture. This is a one-time operation — future invocations will use the cached results."

   Then invoke the `arn-code-codebase-analyzer` agentto generate fresh analysis. Write the results to the Code patterns directory.

4. If greenfield context was loaded in Step 1b, also extract from `## Arness`:
   - **Vision directory** (for style-brief and feature files)
   - **Use cases directory** (for UC documents)
   - **Prototypes directory** (for screen references)

---

### Step 3: Classify Feature and Determine Team Composition

Use three-axis detection to determine the right team:

**Axis 1 — Project frontend state:**
- Check if `ui-patterns.md` exists in the code patterns directory
- Check the Technology Stack table in `architecture.md` for frontend framework entries (React, Vue, Svelte, Angular, Next.js, Nuxt, SvelteKit, etc.)
- Result: **"has frontend"** or **"no frontend"**

**Axis 2 — Feature scope:**
- Analyze the feature description for UI-related terms (component, page, form, button, layout, dashboard, UI, UX, screen, view, modal, dialog)
- If ambiguous, ask the user to confirm
- Result: **"involves UI"**, **"backend only"**, or **"complex full-stack"** (feature touches backend, frontend, and cross-cutting concerns)

**Axis 3 — Security sensitivity:**
- Check if `security-patterns.md` exists in the code patterns directory
- Analyze the feature description for security-relevant terms (auth, login, password, token,
  payment, upload, API key, PII, encrypt, permission, session, cookie, CORS, CSRF, rate limit,
  secret, credential)
- If ambiguous, ask the user to confirm
- Result: **"security sensitive"** or **"no security concerns"**

**Team composition matrix:**

| Project state | Feature scope | Security | Team | Notes |
|---|---|---|---|---|
| Any | Backend only | No security | 2 architects | Pure architecture debate |
| Any | Backend only | Security sensitive | 2 architects + 1 security specialist | Security joins for auth/data features |
| Has frontend | Involves UI | No security | 1 architect + 1 UX specialist | UX references existing patterns |
| Has frontend | Involves UI | Security sensitive | 1 architect + 1 UX specialist + 1 security specialist | Full-stack with security |
| No frontend | Involves UI | No security | 1 architect + 1 UX specialist | UX in greenfield mode |
| No frontend | Involves UI | Security sensitive | 1 architect + 1 UX specialist + 1 security specialist | Greenfield UI with security |
| Has frontend | Complex full-stack | No security | 2 architects + 1 UX specialist | Three-way debate |
| Has frontend | Complex full-stack | Security sensitive | 2 architects + 1 UX specialist + 1 security specialist | Four-way debate (cost warning) |

Present the proposed team to the user with token estimates:

- 2-person team: estimate 40k-100k tokens (lower end for focused features with quick convergence, upper end for complex features requiring multiple revision rounds)
- 3-person team: estimate 60k-250k tokens (same range factors, plus three-way coordination overhead)
- 4-person team: estimate 80k-300k tokens (include cost warning: "This is a large team. Consider whether security can be addressed during review-implementation instead.")

Ask (using `AskUserQuestion`):

**"Based on the feature, I'll create a team of [composition]. A typical arn-code-feature-spec session uses 20k-50k tokens; expect [40k-100k / 60k-250k] tokens for this team debate. Proceed?"**

Options:
1. **Yes, proceed with team debate** -- Create the team and start the debate
2. **No, use standard spec instead** -- Fall back to `/arn-code-feature-spec` (lower cost)

If the user declines, suggest `/arn-code-feature-spec` as the lower-cost alternative.

If the feature is backend-only AND simple (no ambiguity, single obvious approach), suggest `/arn-code-feature-spec` instead — team debate adds cost without proportional value for straightforward features.

---

### Step 4: Create Debate Team

Read the debate protocol at `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-feature-spec-teams/references/debate-protocol.md`. The general debate rules (round structure, convergence criteria, escalation) are defined there. Do not duplicate them in individual spawn prompts — only include role-specific instructions.

Create the team based on the composition chosen in Step 3. Spawn prompts for each teammate include:

**For architect teammate(s):**
- Feature idea from Step 2
- Full pattern documentation content (code-patterns.md, testing-patterns.md, architecture.md, ui-patterns.md if present)
- User expertise context:
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
- Advisory pattern instruction: "When presenting technology recommendations, present the technically optimal recommendation first, then present any preference-aligned alternative with honest pros/cons. Let the user decide."
- Role instructions: "You are a senior software architect. Analyze this feature, propose an implementation approach grounded in the project's documented patterns, and defend your choices when challenged. Focus on: system design, data flow, API design, integration with existing architecture, error handling, and testing strategy."
- **If greenfield context was loaded in Step 1b, also include:**
  - Feature file content: the full F-NNN file content (description, journey steps, UI behavior, components, acceptance criteria, technical notes)
  - Behavioral context: UC main success scenarios, extensions, and business rules from loaded UC documents
  - Style context (if style-brief loaded): toolkit configuration section from the style-brief
  - Scope boundaries: related feature descriptions, journeys, and acceptance criteria from the Feature Tracker
  - Additional instruction: "The behavioral requirements are well-defined by the use case documents. Focus on HOW to implement within the existing codebase patterns, not on WHAT to implement. If a style-brief is provided, reference the validated design tokens in your component integration points."
  - Animation context (if loaded from style-brief): Animation approach, motion philosophy, timing characteristics, key patterns. Consider: animation library/framework integration, animation cleanup on route/view changes, and performance implications for the project's platform.

**For UX specialist teammate (when UI is involved):**
- Feature idea from Step 2
- Full pattern documentation content (same as architect)
- Operating mode:
  - If project **has frontend**: "Existing frontend mode — map proposals to documented UI conventions in ui-patterns.md. Reference existing components, styling approach, and state management."
  - If project has **no frontend**: "Greenfield frontend mode — recommend a UI stack from scratch. Justify every choice. Include a Proposed UI Stack section. Mark all references as 'Recommended'."
- Role instructions: "You are a UI/UX specialist. Advocate for the user experience perspective: component architecture, accessibility, responsive design, state management, and user flows. Challenge architectural proposals that compromise usability."
- **If greenfield context was loaded in Step 1b, also include:**
  - Feature file content: the full F-NNN file including UI Behavior section, Components list (library + product-specific with prototype references), and journey summary
  - Style context (if style-brief loaded): full color palette, typography tokens, spacing tokens, and toolkit configuration code from the style-brief
  - Prototype references: static showcase sections and clickable screen IDs referenced in the feature file's Components and References sections
  - Additional instruction: "The UI components and interaction patterns are already validated in the prototype. Focus on mapping these to the codebase's UI patterns and identifying implementation gaps. If a style-brief is provided, map your component hierarchy to the validated design tokens — use exact token names (e.g., 'primary-500', 'heading-1') rather than abstract descriptions."
  - Animation context (if loaded from style-brief): Motion design tokens, timing scale, easing functions. Describe which components in this feature should animate, what triggers the animation, and how it matches the product's tone commitment. Output a "Motion Design" subsection in UI Design using platform-agnostic intent language.

**For security specialist teammate (when security sensitive):**
- Feature idea from Step 2
- Full pattern documentation content (security-patterns.md if present, plus code-patterns.md, architecture.md)
- Operating mode:
  - If `security-patterns.md` exists: "Existing security patterns mode — ground analysis in documented security patterns. Reference existing auth, validation, and data protection implementations."
  - If no `security-patterns.md`: "Greenfield security mode — recommend security measures based on the architecture. Cover OWASP Top 10 applicable risks. Mark all references as 'Recommended'."
- Role instructions: "You are a security specialist. Advocate for secure-by-default design: authentication, authorization, input validation, data protection, API security. Challenge architectural proposals that introduce security risks. Reference OWASP Top 10 where applicable."
- **If greenfield context was loaded in Step 1b, also include:**
  - Feature file content: Description, Acceptance Criteria, and Technical Notes sections from the F-NNN file
  - UC security context: business rules and postconditions from loaded UC documents that relate to security constraints (data validation, access control, encryption requirements)
  - Additional instruction: "Use case business rules and postconditions define security boundaries. Evaluate whether the proposed implementation satisfies these constraints."

---

### Step 5: Facilitate Debate

Facilitate the structured debate following the round-by-round protocol. Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-feature-spec-teams/references/debate-protocol.md` for the complete debate structure, convergence criteria, and escalation rules.

Present a summary to the user after each round: what was proposed, what was challenged, what was resolved.

**Scope boundary awareness (if greenfield context loaded in Step 1b):** When a teammate proposes including functionality that may overlap with a sibling feature, check the scope boundary context before allowing the debate to expand into that territory. If the proposed functionality is already covered by another feature in the Feature Tracker, note it as out of scope: "That's handled by F-NNN: [Name] — keeping it out of this spec's scope." Only escalate genuine gaps to the user.

---

### Step 5b: Proactive Sketch Offer (Conditional)

After the debate converges, if ALL of these conditions are met:
- The feature involves UI (detected in Step 3, Axis 2)
- `ui-patterns.md` exists in the code patterns directory with a `## Sketch Strategy` section

Then offer a visual preview before synthesizing the final spec:

Ask (using `AskUserQuestion`):

**"The team has converged on a design. Would you like to see a visual preview before I write the final spec?"**

Options:
1. **Yes, sketch it** -- Generate a sketch showing what the [components/screens/output] would look like
2. **No, finalize the spec** -- Proceed to writing the specification

If **Yes, sketch it**: Invoke `Skill: arn-code:arn-code-sketch` with the converged feature context (description, architect proposals, UX specialist output, resolved decisions). After the sketch session completes, capture any sketch context (manifest with `componentMapping` and `composition` fields) for inclusion in the spec's Sketch Reference section. Then proceed to Step 6.
If **No, finalize the spec**: Proceed to Step 6.

If sketch conditions are NOT met (no UI involvement or no Sketch Strategy), skip this step entirely.

**On-demand sketch during debate:** If the user asks to see a preview at any point during the debate rounds ("show me what this looks like", "can I see a preview"), and the conditions above are met, invoke `Skill: arn-code:arn-code-sketch` immediately. After the sketch completes, resume the debate where it left off.

---

### Step 6: Synthesize Specification

When debate converges (or user resolves remaining disagreements):

1. Read the feature spec template at `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-feature-spec/references/feature-spec-template.md`

2. Populate the template with:
   - **Problem Statement:** Refined feature description incorporating all debate outcomes
   - **Requirements:** Functional and non-functional requirements surfaced during debate
   - **Architectural Assessment:** Merged from architect proposals + UX specialist input
   - **Scope & Boundaries:** What is in scope and what is not
   - **Feasibility & Risks:** Risks identified by each teammate
   - **Decisions Log:** All decisions, including how disagreements were resolved
   - **Open Items:** Remaining questions
   - **Behavioral Specification (if greenfield context loaded):** Populate from loaded UC documents and feature file — same sections as arn-code-feature-spec: Feature Backlog Entry (F-NNN metadata, priority, dependencies), Use Case References table, Main Success Scenarios (summarized from UCs), Key Extensions, Business Rules & Constraints, Acceptance Criteria
   - **Design Tokens (if style-brief loaded):** Populate from style-brief with token category table (Primary colors, Typography, Spacing) and toolkit reference path. Mark as "Validated in static showcase v[N]".
   - **Scope & Boundaries (enhanced if scope boundary context loaded):** Include cross-references to sibling features and any gaps identified during the debate. Format: "Out of scope — handled by F-NNN: [Name]" for known sibling coverage.

   - **Sketch Reference (if sketch was created in Step 5b):** Populate from the held manifest data — sketch directory, manifest path, status, paradigm, Component Mapping table (from `componentMapping`), Composition Summary (from `composition`). Omit this section entirely if no sketch was created.
   - **Motion Design (if animation context loaded):** Populate from debate findings on animation. Include per-element timing, triggers, and reduced-motion fallbacks from the UX specialist's recommendations as validated through the debate.

3. Add an optional **"Debate Summary"** section capturing:
   - Team composition (who participated)
   - Key disagreements and how they were resolved
   - Points where user intervention was needed

4. For features introducing frontend to a backend project, add an optional **"Proposed UI Stack"** section (from the UX specialist's greenfield recommendations)

5. Derive a spec name from the feature (e.g., `FEATURE_analytics-dashboard`, `FEATURE_real-time-notifications`). Suggest it to the user for confirmation.

6. Save to `<specs-dir>/FEATURE_<name>.md`. If the specs directory does not exist, create it: `mkdir -p <specs-dir>/`

7. Present summary: spec location, key decisions, debate outcomes, open items

8. Inform the user of next steps:

   "Feature specification saved to `<specs-dir>/FEATURE_<name>.md`.

   To create an implementation plan, run `/arn-code-plan FEATURE_<name>`.

   The skill will load this spec and your project's codebase patterns, invoke the planner agent to generate a plan, and let you review and refine it before saving."

---

## Error Handling

- **Agent Teams not enabled** -- provide setup instructions, suggest `/arn-code-feature-spec` as alternative
- **`## Arness` config missing in CLAUDE.md** -- suggest running `/arn-planning` to get started
- **Teammate crashes** -- report issue, offer to continue with remaining teammates or fall back to `/arn-code-feature-spec`
- **Debate loops (>4 rounds without convergence)** -- escalate to user with both positions, ask for a decision, then synthesize
- **Same disagreement persists across 2 consecutive rounds** -- escalate to user immediately
- **Token budget concern** -- if the user expresses concern, offer to skip remaining rounds and synthesize from current state
- **No frontend AND no UI scope** -- suggest `/arn-code-feature-spec` instead (team debate adds cost without value for simple backend features)
- **Pattern documentation missing** -- handled by the first-run messaging (one-time pattern generation)
- **Greenfield feature file not found** -- warn and fall back to standard flow (ask user to describe the feature). Teammates receive standard context only.
- **UC documents not found** -- proceed with feature file only, note limitation in debate context sent to teammates
- **Style-brief not found** -- proceed without style context (no warning needed — style exploration is optional in the greenfield pipeline)
- **Feature Tracker not found** -- proceed without scope boundary context; note that cross-feature awareness will be limited
- **User cancels at any point** -- confirm and exit gracefully. If a spec was partially written, inform the user of its location so they can delete or resume later
- **Writing the spec file fails (permissions, path issues)** -- print the spec content in the conversation so the user can save it manually
- **Teammate unresponsive** -- continue with remaining teammates, note the gap in the debate summary
