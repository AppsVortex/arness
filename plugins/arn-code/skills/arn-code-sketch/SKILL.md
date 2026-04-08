---
name: arn-code-sketch
description: >-
  This skill should be used when the user says "sketch", "arness code sketch",
  "preview this", "show me what this looks like", "UI preview",
  "sketch the feature", "visual preview", "sketch this page",
  "what will this look like", "mock this up", "prototype this UI",
  "preview the design", "sketch the UI",
  "preview this command", "show me what the output looks like",
  "sketch the TUI", "what will the CLI look like",
  "mock up the terminal output",
  or wants to see a working interface preview of a feature in the context of
  their existing application before committing to full implementation.
  Creates real, runnable artifacts using the project's actual framework
  and conventions, rendered in a dedicated sketch namespace.
version: 1.0.0
---

# Arness Sketch

Create a working interface preview of a feature using the project's actual framework, conventions, and styling system. The sketch renders the new feature in context -- showing it within the real application where it will live, not in isolation. This lets the user see and interact with a preview before committing to the full implementation pipeline.

Sketches are real code: runnable artifacts written with the project's conventions, served from a dedicated `arness-sketches/` namespace. They can be iterated on via feedback, promoted into the real codebase, or cleaned up when no longer needed.

This is a conversational skill. It runs in normal conversation (NOT plan mode).

## Prerequisites

1. **Arness must be configured.** Read the project's CLAUDE.md and check for a `## Arness` section. If missing, inform the user: "Arness is not configured for this project yet. Run `/arn-implementing` to get started — it will set everything up automatically." Do not proceed without it.

2. **Sketch strategy must exist.** Read `ui-patterns.md` from the project's code patterns directory (the path under **Code patterns:** in the `## Arness` config). Look for a `## Sketch Strategy` section. If absent, halt with:

   "No sketch strategy found. Run `/arn-implementing` to get started — pattern documentation will be generated on first use, including the sketch strategy if your project has a UI framework."

   Do not proceed without a sketch strategy.

## Pipeline Position

```
Entry points:
  - Direct: user says "sketch this" / "preview this"
  - From feature-spec: proactively offered after initial proposal when UI is involved
  - From feature-spec-teams: proactively offered after debate converges when UI is involved
  - From swift: after swift assessment, offered for interface changes above threshold

                    arn-code-sketch (this skill)
                    =========================
                    For interface preview before implementation

  Input:  Feature description (from spec, swift, or direct)
            |
            v
  Load:    Sketch strategy + paradigm reference from pattern docs
            |
            v
  Assess:  Should this be sketched? (threshold rules)
            |
            +--- Below threshold --> "This change is small enough to implement
            |                         directly. Proceed with /arn-code-swift or
            |                         /arn-code-feature-spec instead."
            |
            +--- Above threshold --> Continue
            |
            v
  Create:  arness-sketches/[feature-name]/ artifact namespace
            |
            v
  Build:   Spawn arn-code-sketch-builder agent
            |
            v
  Present: Show preview instructions, iterate on feedback
            |
            v
  Finish:  Promote to real codebase OR clean up
```

## Workflow

### Step 1: Load Sketch Strategy and Paradigm Reference

Load the sketch setup and paradigm routing rules:

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-sketch/references/sketch-setup.md`

Follow the setup sequence:

1. **Read `ui-patterns.md`** from the project's code patterns directory (already read in Prerequisites). Parse the `## Sketch Strategy` section to extract:
   - **Paradigm** -- the interface type (e.g., `web`, `cli`, `tui`, `desktop`, `mobile`)
   - **Artifact structure** -- what sketch files to create and where
   - **Preview mechanism** -- how the user previews the sketch (browser URL, terminal command, etc.)
   - **Promotion rules** -- how sketch artifacts move into the real codebase

2. **Read `architecture.md`** from the code patterns directory for Technology Stack confirmation (framework, language, key libraries).

3. **Load paradigm reference** -- based on the paradigm extracted from the sketch strategy:

   > Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-sketch/references/paradigm-<paradigm>.md`

   If the paradigm-specific reference file does not exist, fall back to:

   > Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-sketch/references/paradigm-stub.md`

4. Hold the sketch strategy context (paradigm, artifact structure, preview mechanism) and paradigm reference for use by the builder agent.

### Step 2: Read Feature Context

Determine what to sketch from one of these sources (check in order):

1. **From conversation context** -- if invoked after `/arn-code-feature-spec` or `/arn-code-swift`, the feature description and architectural decisions are already in the conversation. Extract the interface-relevant portions.

2. **From a spec file** -- if the user references a spec (e.g., "sketch F-001" or "sketch the auth feature"), read the spec file from the project's specs directory.

3. **From direct description** -- if the user describes what they want directly (e.g., "sketch a settings page with a profile form and notification preferences"), use that description.

If the feature description is vague, ask one clarifying question focused on what the user wants to SEE:

"What should I show in the preview? For example: 'a settings page with profile form and notification toggles', 'the new dashboard widget showing recent activity', 'the deploy command with its subcommands and flags', or 'the status screen with live metrics'."

### Step 3: Assess Sketch Threshold

Not every interface change warrants a sketch. Apply these threshold rules based on the paradigm:

**Skip sketching (below threshold):**
- Web: single component additions (e.g., "add a loading spinner"), style-only changes, text content changes, icon swaps, single field additions to existing forms
- CLI: add a single flag, change help text, rename a subcommand, adjust a default value
- TUI: change a label, adjust a column width, reorder a single field

For below-threshold changes, suggest the direct path:

"This change is straightforward enough to implement directly. Would you like to proceed with `/arn-code-swift` instead?"

**Offer sketching (above threshold):**
- Web: new pages or routes, new forms with 3+ fields, new sections or panels, layout changes (sidebar, navigation, dashboard grids), multi-component features, features where the visual result is ambiguous
- CLI: new command group with 3+ subcommands, interactive wizard or multi-step prompts, new output format (table, tree, structured report), complex argument combinations
- TUI: new screen or view, new widget panel, multi-widget layout, dashboard or status display

If the user explicitly asked for a sketch (e.g., "sketch this", "preview this"), always proceed regardless of threshold.

### Step 4: Create Sketch Artifacts

Create the artifact structure as specified by the loaded paradigm reference file. The paradigm reference (loaded in Step 1) defines the exact files, directory layout, and naming conventions for the current paradigm.

The artifact namespace is `arness-sketches/[feature-name]/`. For web paradigms, the paradigm reference file may specify a framework-specific location within the routing directory (e.g., `app/arness-sketches/` for Next.js App Router, `src/routes/arness-sketches/` for SvelteKit). The project root `arness-sketches/` is the default for non-web paradigms. Every sketch includes a `sketch-manifest.json`:

```json
{
  "featureName": "",
  "description": "",
  "sourceSpec": "",
  "paradigm": "",
  "framework": "",
  "createdAt": "",
  "targetPage": "",
  "previewCommand": "",
  "components": [],
  "componentMapping": [],
  "composition": {
    "blueprint": "",
    "layout": [],
    "dataFlow": [],
    "interactionSequence": [],
    "animation": []
  },
  "status": "draft"
}
```

Where `targetPage` is the real location where this feature will eventually live (a route for web, a command module for CLI, a screen for TUI). The `paradigm` field records the interface type. The `previewCommand` field records how to run or view the sketch (e.g., a URL for web, a shell command for CLI/TUI).

The `composition.animation` array documents animations implemented in the sketch. Each entry records: the component name, animation type (entrance/exit/state-change/feedback/scroll-triggered), trigger condition, a platform-agnostic description of the effect, and the animation approach used. This metadata enables the feature planner to generate animation-aware promotion tasks.

See the arn-code-sketch-builder agent Step 6 for the full schema including `componentMapping` and `composition` fields. These are populated by the builder during creation and by this skill during Step 8.

### Step 5: Spawn the Builder Agent

Spawn the `arn-code-sketch-builder` agent with:

--- SKETCH CONTEXT ---
**Feature:** [feature name and description]
**Target page:** [the real location where this feature will live -- a route for web, a command module for CLI, a screen for TUI]
**Paradigm:** [paradigm from sketch strategy -- e.g., web, cli, tui]
**Paradigm reference:** [path to the loaded paradigm reference file]
**Framework:** [detected framework and version from architecture.md / ui-patterns.md]
**Component library:** [detected component library, if applicable]
**Styling approach:** [detected styling approach, if applicable]
**Artifact namespace:** arness-sketches/[feature-name]/
--- END SKETCH CONTEXT ---

--- CODEBASE CONTEXT ---
[Contents of ui-patterns.md]
[Contents of architecture.md Technology Stack section if it exists]
--- END CODEBASE CONTEXT ---

--- TARGET CONTEXT ---
[Contents of the target location -- the page, command module, or screen where this feature will live]
[Key imports and patterns used by that target]
--- END TARGET CONTEXT ---

**Output directory:** arness-sketches/[feature-name]/
**Manifest file:** arness-sketches/[feature-name]/sketch-manifest.json

The agent will read the project's existing code and create the sketch using real, runnable artifacts matching the project's conventions.

### Step 6: Present Preview

After the builder agent completes:

1. Verify the sketch files were created by checking the output directory.
2. Present the preview to the user based on the paradigm's preview mechanism (from the `## Sketch Strategy` in `ui-patterns.md`):
   - **Web:** "Start your dev server and visit the sketch URL"
   - **CLI:** "Run the sketch script in your terminal"
   - **TUI:** "Run the sketch app in your terminal"
   - **Other:** Use the `previewCommand` from the sketch manifest

   For detailed framework-specific instructions, the paradigm reference file (loaded in Step 1) provides the exact commands and URLs.

3. Include a brief description of what was built and prompt: "What would you like to change?"

### Step 7: Iterate on Feedback

Load the iteration guide:

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-sketch/references/iteration-guide.md`

Follow the feedback loop protocol:
- User describes what to change
- Re-spawn the builder agent with the feedback + existing sketch files
- Present the updated preview (same location, files updated in place)
- Repeat until the user is satisfied

### Step 8: Finish -- Promote or Clean Up

When the user is satisfied (or decides to move on), offer three options:

1. **Promote** -- Populate component mapping, then copy sketch artifacts into the real codebase structure using per-component promotion. The builder agent handles import path and reference updates. Mark `sketch-manifest.json` status as `"promoted"`.

2. **Keep** -- Populate component mapping, then leave the sketch in `arness-sketches/` for reference during implementation. Mark status as `"kept"`. The sketch serves as a living reference while building the real feature. The component mapping tells downstream consumers (arn-code-task-executor, arness-swift) exactly how to promote each component later.

3. **Clean up** -- Delete the `arness-sketches/[feature-name]/` directory. Useful when the sketch served its purpose during the conversation. No component mapping needed.

**Populating component mapping (for Promote and Keep):**

Before performing the promote or keep action, present the detected components and let the user confirm target paths and promotion modes (direct vs refine).

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-sketch/references/iteration-guide.md` for the full component mapping population procedure.

Write the confirmed mapping to the manifest before proceeding with the chosen action.

If the user proceeds to `/arn-code-feature-spec` or `/arn-code-plan` after sketching, mention that the sketch exists as a reference:

"The sketch at `arness-sketches/[feature-name]/` shows the approved design with component mapping. Implementation should match this preview -- the manifest's `componentMapping` tells executors exactly which files to promote and how."

## Error Handling

- **No sketch strategy found** -- Halt with: "No sketch strategy found in `ui-patterns.md`. Run `/arn-implementing` to get started — pattern documentation will be generated on first use." If the user believes a sketch strategy should exist, suggest re-running the codebase analyzer.
- **Paradigm reference file not found** -- Load `paradigm-stub.md` as a fallback. Inform the user: "No paradigm-specific reference found for '[paradigm]'. Using generic sketch guidelines. The sketch may need manual adjustments."
- **Build fails after sketch creation** -- Read the error output. Common causes: missing imports, incorrect API usage, missing dependencies. Re-spawn the builder agent with the error context to fix.
- **Preview fails** -- For web: suggest the user check their dev server configuration. For CLI/TUI: check that required dependencies are installed and the sketch script is executable. This is outside Arness's direct control.
- **Artifact conflict** -- If `arness-sketches/[feature-name]/` already exists, ask the user: "A sketch for '[feature-name]' already exists. Overwrite it, choose a different name, or iterate on the existing sketch?"
- **Builder agent fails or returns empty** -- Inform the user: "The sketch builder encountered an issue. Let me try a simpler approach." Fall back to creating a minimal sketch artifact with placeholder content and iterate from there.
- **No target location identified** -- If the feature is brand new with no existing context (new page, new command, new screen), the builder creates a standalone sketch without embedding in an existing location. Note this in the manifest.

## Integration Points

### From arn-code-feature-spec

After the initial proposal is presented (Step 3c), if the feature involves UI and `ui-patterns.md` has a Sketch Strategy section, `arn-code-feature-spec` **proactively offers** a sketch:

"This feature involves interface work. Would you like to see a visual preview before we dive deeper?"

The user can also request a sketch at any time during the exploration conversation. In both cases, `arn-code-feature-spec` invokes `Skill: arn-code:arn-code-sketch` with the current feature context.

### From arn-code-feature-spec-teams

After the debate converges (Step 5b), if the feature involves UI and Sketch Strategy is configured, the teams skill offers a sketch before writing the final spec. The user can also request a sketch during debate rounds.

### From arn-code-swift

After the swift assessment, if the change involves an interface and is above the sketch threshold, swift may offer a sketch before implementation.

### To arn-code-ship

At ship time, the arn-code-ship skill checks for `arness-sketches/` directories and offers cleanup:
- Promoted sketches: already cleaned up (or suggest deleting the source)
- Kept sketches: ask if they should be deleted now that the feature is shipped
- Draft sketches: warn that unfinished sketches exist

## Rules

- Use ONLY libraries and components that exist in the project. Never introduce new dependencies.
- Follow the project's conventions exactly. If the project uses Tailwind, the sketch uses Tailwind. If Click for CLI, use Click. If Textual for TUI, use Textual.
- Create real, runnable files. No throwaway mockups or static placeholders.
- Show the feature in context. The sketch should render within the target location's structure (page layout for web, command group for CLI, app screen for TUI) with the new feature inserted where it belongs.
- Never modify the project's existing source files. Sketches live entirely within `arness-sketches/`.
- Always create a `sketch-manifest.json` for traceability.
- Do not start servers or processes automatically. The user controls their own environment.
- Keep sketch file structure minimal. Prefer composing existing patterns over creating new abstractions.
