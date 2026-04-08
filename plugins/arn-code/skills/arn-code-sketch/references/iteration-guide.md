# Iteration Guide

Feedback loop protocol, promotion workflow, and cleanup rules for all paradigms. Used by the arn-code-sketch skill at Steps 7 and 8.

## Feedback Loop

After the initial sketch is presented, the user reviews the preview and describes changes. The review mechanism varies by paradigm:

- **Web:** User reviews in their browser at the sketch URL
- **CLI:** User runs the sketch script and reviews terminal output
- **TUI:** User runs the sketch app and interacts in the terminal
- **Desktop/Mobile:** User launches the sketch application or reviews a descriptive mockup

Each iteration follows this cycle:

```
User reviews the sketch preview
(paradigm-specific: browser, terminal, app, or mockup)
         |
         v
User describes change
("move the sidebar to the left", "make the form wider",
 "change the table to a tree", "add a status column",
 "dock the panel to the right", "add a --verbose flag")
         |
         v
Parse feedback into actionable changes
         |
         v
Re-spawn arn-code-sketch-builder with:
  - Original sketch context (including paradigm)
  - Current sketch files (read them fresh)
  - User feedback
         |
         v
Builder updates files in place
         |
         v
User re-previews the sketch
(paradigm-specific: refresh browser, re-run script,
 restart app, or review updated mockup)
         |
         v
Present: "Updated. [Brief description of what changed.]
          What else would you like to change?"
```

### Feedback Categories

Classify user feedback to route it correctly. These categories apply across all paradigms:

| Category | Web Examples | CLI Examples | TUI Examples | Action |
|----------|-------------|-------------|--------------|--------|
| **Layout** | "move X to the left", "make it a grid instead of a list" | "show the summary above the table" | "dock the panel to the right", "split the screen" | Re-spawn builder with layout change instructions |
| **Component swap** | "use a dropdown instead of radio buttons", "use the existing DataTable" | "use a tree instead of a table", "use Rich panels instead of plain text" | "use a DataTable instead of a ListView", "use tabs instead of screens" | Re-spawn builder with replacement instructions; builder reads the target component/widget API first |
| **Styling** | "make it wider", "match the existing card styling", "use the brand colors" | "use blue headers", "add box borders", "use a different table style" | "change the panel color", "increase padding", "use the project theme" | Re-spawn builder with styling adjustments |
| **Content** | "add a description field", "show the user's avatar", "include a cancel button" | "add a 'last deployed' column", "show the count" | "add a status indicator", "show timestamps" | Re-spawn builder with content additions |
| **Data** | "use real data from the API", "show sample data that looks realistic" | "show more sample rows", "use realistic file paths" | "simulate live data updates", "add a refresh action" | Re-spawn builder; wire up real data if straightforward, otherwise improve mock data |
| **Remove** | "remove the sidebar", "don't show the footer" | "remove the --format flag", "don't show the header row" | "remove the status bar", "hide the sidebar" | Re-spawn builder with removal instructions |
| **Interaction** | "add a confirmation dialog", "make the table sortable" | "add a confirmation prompt", "make it interactive" | "add keyboard shortcuts", "make the table sortable" | Re-spawn builder with interaction instructions |
| **Satisfied** | "looks good", "that's what I want", "perfect", "done" | Same | Same | Exit feedback loop, proceed to Step 8 (Finish) |

### Iteration Rules

- **Maximum iterations:** There is no hard cap, but if the user has iterated more than 5 times, gently ask: "We have been iterating for a while. Would you like to continue refining, or is this close enough to proceed with implementation?"
- **Incremental updates:** The builder should modify existing files in place, not recreate from scratch each time. This preserves work from previous iterations.
- **Manifest updates:** After each iteration, update the `sketch-manifest.json` to reflect the current state (component list, description changes).
- **No existing code modification:** Even during iteration, never modify the project's real source files. All changes stay within `arness-sketches/`.
- **Paradigm-specific artifacts:** If the paradigm has supplementary files (e.g., `expected-output.md` for CLI, `sketch.tcss` for TUI), update them after each iteration to stay in sync with the primary sketch file.

---

## Component Mapping Population

Before performing a promote or keep action, the arn-code-sketch skill populates `componentMapping` and refines `composition` in the manifest. Follow this procedure:

1. **Present detected components.** Read the manifest's `components` list and `composition.layout` entries. Present them to the user in a table:

   "The sketch has these components:

   | # | Component | Sketch File | Suggested Target | Mode |
   |---|-----------|-------------|------------------|------|
   | 1 | ProfileForm | arness-sketches/settings/components/ProfileForm.tsx | src/components/settings/ProfileForm.tsx | refine |
   | 2 | NotificationToggle | arness-sketches/settings/components/NotificationToggle.tsx | src/components/settings/NotificationToggle.tsx | direct |
   | 3 | SettingsLayout | arness-sketches/settings/page.tsx | app/settings/page.tsx | refine |

   Adjust target paths or promotion modes?"

   - Suggest target paths based on the project's existing component directory structure and the `targetPage` from the manifest.
   - Suggest `mode: "direct"` for display-only components (pure presentational, no data fetching, no state management, no side effects).
   - Suggest `mode: "refine"` for components that use mock data, hardcoded state, placeholder API calls, or simplified error handling.

2. **Confirm with user.** Let the user adjust target paths and modes. Accept the mapping when the user confirms (or proceeds without changes).

3. **Write componentMapping to manifest.** For each confirmed component, write an entry:
   ```json
   {
     "sketchFile": "arness-sketches/feature/components/MyComponent.tsx",
     "targetFile": "src/components/MyComponent.tsx",
     "mode": "direct",
     "description": "Profile avatar display with online indicator"
   }
   ```

4. **Refine composition target paths.** Update `composition.layout` entries to reflect the confirmed target paths. The `position` and `visualRole` fields remain as written by the builder; only component-to-file mapping is refined.

5. **Proceed with the chosen option.** For Promote: invoke the builder agent in Promotion Mode with the populated componentMapping. For Keep: write the manifest with the mapping and inform the user that the sketch is ready for downstream consumption.

---

## Promotion Workflow

> **Note:** The promotion logic here and in the `arn-code-sketch-builder` agent's Promotion Mode section describe the same process from different perspectives (skill orchestration vs agent execution). Changes to promotion rules must be synchronized across both files.

When the user chooses to promote a sketch (Step 8, option 1), follow this process. The workflow uses `componentMapping` for per-component promotion when available, falling back to paradigm-based promotion for legacy sketches without mapping.

### 1. Identify Target Locations

Read `sketch-manifest.json` to get the `componentMapping` array, `composition` object, `targetPage` field, and `paradigm` field.

**When componentMapping is populated (preferred):**

Each component in `componentMapping` has its own `targetFile` -- components may go to different locations in the codebase. Read the mapping to understand the full promotion plan:

```json
{
  "componentMapping": [
    { "sketchFile": "arness-sketches/settings/components/ProfileForm.tsx", "targetFile": "src/components/settings/ProfileForm.tsx", "mode": "refine" },
    { "sketchFile": "arness-sketches/settings/components/NotificationToggle.tsx", "targetFile": "src/components/settings/NotificationToggle.tsx", "mode": "direct" },
    { "sketchFile": "arness-sketches/settings/page.tsx", "targetFile": "app/settings/page.tsx", "mode": "refine" }
  ]
}
```

For each entry, verify the target path is valid. If a `targetFile` points to an existing file, ask: "The target `[targetFile]` already exists. Should I: (a) merge the sketched component into the existing file, or (b) replace it entirely?"

**When componentMapping is empty (fallback):**

Use the `targetPage` field as the single target location. The target varies by paradigm:

- **Web:** A route path (e.g., `app/settings/page.tsx`, `pages/settings/index.tsx`)
- **CLI:** A command module path (e.g., `src/myproject/commands/deploy.py`)
- **TUI:** A screen or widget module path (e.g., `src/myproject/screens/dashboard.py`)
- **Desktop/Mobile:** An app view or screen path (varies by framework)

If `targetPage` is empty or a placeholder: ask the user where the promoted files should go.

### 2. Copy and Transform Files

**When componentMapping is populated (preferred):**

Iterate `componentMapping` entries and apply the specified mode per entry:

**`mode: "direct"` entries:**
1. Copy the sketch file to its `targetFile` location. Create intermediate directories as needed.
2. Rewrite import paths from `arness-sketches/[feature-name]/` to the new canonical paths based on other componentMapping entries' `targetFile` values.
3. Remove sketch markers (e.g., `// arn-code-sketch: ...`, `{/* Arness Sketch */}`, `# arn-code-sketch: ...`).
4. Do not modify component logic, data, or structure.

**`mode: "refine"` entries:**
1. Copy the sketch file to its `targetFile` location. Create intermediate directories as needed.
2. Rewrite import paths to the new canonical paths.
3. Remove sketch markers.
4. Add TODO comments at data integration points, guided by `composition.dataFlow`:
   - For each `dataFlow` entry where this component is the `consumer`, add: `// TODO: Replace mock data with real data from [producer] via [mechanism]`
   - Mark state management placeholders: `// TODO: Wire to [state store / context / props]`
   - Mark error handling gaps: `// TODO: Add error handling for [operation]`
   - Mark API call placeholders: `// TODO: Replace with real API call to [endpoint]`

**When componentMapping is empty (fallback):**

For each file in the sketch directory, the transformation depends on the paradigm:

**Web:**
1. Copy the page/route component to the target route location. If the target page already exists, ask: "The target page already exists. Should I: (a) add the sketched section to the existing page, or (b) replace the page entirely?"
2. Copy sketch-specific components to the project's component directory. Update import paths.
3. Remove sketch markers (e.g., `// arn-code-sketch: ...`, `{/* Arness Sketch */}`).

**CLI:**
1. Move command functions into the target CLI module. Replace mock data with TODOs for real data integration.
2. Move output formatters (table builders, display functions) into the project's utility module.
3. Register new commands with the project's CLI entry point group.

**TUI:**
1. Move screen classes into the project's screen directory. Register with the app's screen routing.
2. Move custom widgets into the project's widget directory.
3. Merge sketch TCSS into the project's stylesheet structure (if applicable).
4. Replace mock data with reactive data sources.

**Desktop/Mobile:**
1. Move view/screen files into the project's views/screens directory.
2. Register with the app's navigation or window management.
3. Follow framework-specific integration steps from the paradigm reference.

### 3. Composition-Aware Assembly

When `composition` metadata is available, use it to guide how promoted components are assembled in their target locations:

**Read the blueprint for assembly context:**

The `composition.blueprint` file is the authoritative reference for how components fit together. Read it to understand the complete assembly recipe -- import order, component nesting, prop passing, and layout structure.

**Insert at positions from `composition.layout`:**

Each `layout` entry describes where a component belongs:
- `position`: where in the target to insert (paradigm-specific -- page layout positions for web, output order for CLI, widget docking for TUI)
- `parent`: what container or parent component holds this component
- `visualRole`: whether the component is `primary` (main content), `supporting` (sidebar, secondary panels), `navigation`, or `decoration`

Use these entries to place promoted components at the correct positions in the target page, module, or screen. For web paradigms, this means inserting JSX/template fragments at the described position within the target layout. For CLI, this means registering commands in the described order. For TUI, this means docking widgets at the described positions.

**Wire data flow from `composition.dataFlow`:**

Each `dataFlow` entry describes a data relationship:
- `producer` -> `consumer` via `mechanism` carrying `data`

For `mode: "direct"` components, data wiring is already correct (display-only). For `mode: "refine"` components, the dataFlow entries tell the implementer (or downstream executor) exactly what real data sources to wire:
- `mechanism: "props"` -- the parent must pass the described data as props
- `mechanism: "context"` -- a context provider must wrap the component tree
- `mechanism: "state"` -- a state store must be connected
- `mechanism: "event"` -- event handlers must be wired between producer and consumer
- `mechanism: "command-args"` -- CLI arguments must be threaded through

**Follow the interaction sequence:**

The `composition.interactionSequence` describes the user flow. Verify that the promoted assembly preserves this flow -- each step's `action` should trigger the described `result` in the target environment.

### 4. Update Import Paths

All import paths that reference `arness-sketches/[feature-name]/` must be rewritten to the new locations. The builder agent handles this transformation:

- Read each promoted file
- Find all import statements referencing sketch paths
- Rewrite to the new canonical paths (using `componentMapping` entries' `targetFile` values when available)
- Verify no broken imports remain

### 5. Clean Up Routing Entries (If Applicable)

For paradigms that required temporary routing entries during sketch creation:

- **Web (config-based routing -- React Router, Vue Router):** Remove the sketch route entry from the router config. Add a route entry for the promoted location if the target page is new.
- **TUI (screen routing):** Remove any temporary screen registration. Add the real screen registration.
- **Other:** Follow framework-specific cleanup from the paradigm reference.

Filesystem-based routing (Next.js, SvelteKit, Nuxt) does not require cleanup -- moving the files is sufficient.

### 6. Update Manifest

Set `sketch-manifest.json` status to `"promoted"` and add per-component promotion tracking:

**When componentMapping is populated:**
```json
{
  "status": "promoted",
  "promotedAt": "ISO-8601 timestamp",
  "promotedTo": ["list of all targetFile paths from componentMapping"],
  "componentMapping": [
    {
      "sketchFile": "arness-sketches/settings/components/ProfileForm.tsx",
      "targetFile": "src/components/settings/ProfileForm.tsx",
      "mode": "refine",
      "description": "Profile editing form with avatar upload",
      "promotedTo": "src/components/settings/ProfileForm.tsx",
      "promotedAt": "ISO-8601 timestamp"
    }
  ]
}
```

**When componentMapping is empty (fallback):**
```json
{
  "status": "promoted",
  "promotedAt": "ISO-8601 timestamp",
  "promotedTo": ["list of destination file paths"]
}
```

### 7. Offer Sketch Directory Cleanup

After promotion:

"Sketch files have been promoted to their final locations. Delete the `arness-sketches/[feature-name]/` directory? (The promoted files are now in [destination paths].)"

If the user agrees, delete the sketch directory. If the paradigm required temporary routing entries, also remove those.

---

## Ship-Time Cleanup Protocol

When `/arn-code-ship` is preparing to commit and ship a feature, it should check for `arness-sketches/` directories and handle them:

### Detection

Check for `arness-sketches/` at the project root:

```
Check: does `arness-sketches/` directory exist at the project root?
```

Also check legacy web-specific locations for backward compatibility:

```
Legacy web locations (check if project root arness-sketches/ was not found):
  app/arness-sketches/              (Next.js App Router)
  pages/arness-sketches/            (Next.js Pages Router, Nuxt)
  src/routes/arness-sketches/       (SvelteKit)
  src/arness-sketches/              (React Router, Vue Router)
```

If no `arness-sketches/` directory is found at any location, skip cleanup entirely.

### Per-Sketch Handling

For each subdirectory in `arness-sketches/`, read its `sketch-manifest.json` and check both the `status` and `paradigm` fields:

| Status | Action |
|--------|--------|
| `"promoted"` | Safe to delete. The sketch was already promoted. Offer: "Sketch '[feature-name]' was promoted. Delete the sketch directory?" |
| `"kept"` | Ask the user. The sketch was kept as a reference. Offer: "Sketch '[feature-name]' was kept as a reference. Now that you are shipping, delete it, or keep it for later?" |
| `"draft"` | Warn the user. The sketch was never finished. Offer: "Sketch '[feature-name]' is still a draft. Delete it, promote it first, or keep it?" |

### Routing Entry Cleanup

Read the `paradigm` field from each manifest:

- **Web (config-based routing):** Check the router config file for any `arness-sketches/` route entries and offer to remove them.
- **Other paradigms:** Check for any temporary registrations noted in the manifest and offer to remove them.

### .gitignore Note

If `arness-sketches/` is in `.gitignore`, no action needed -- the directory will not be committed regardless. If it is NOT in `.gitignore`, warn the user:

"The `arness-sketches/` directory is not in `.gitignore` and would be included in your commit. Should I add it to `.gitignore`, or delete the sketch directories first?"

---

## Integration Hooks

### arn-code-feature-spec Integration

After a feature spec is written (Step 6 of feature-spec workflow), the feature-spec skill checks if the spec has interface components by scanning for terms in the spec body: "page", "form", "dashboard", "screen", "view", "layout", "component", "modal", "dialog", "sidebar", "navigation", "table", "list", "card", "widget", "command", "output", "terminal", "TUI", "CLI", "prompt", "menu".

If interface terms are found AND a sketch strategy exists in `ui-patterns.md`:

"This feature has interface components. Would you like to sketch a preview before planning? Run `/arn-code-sketch` to visualize the design."

The user can accept (which invokes arn-code-sketch with the spec as context) or decline (which proceeds to the plan step).

### arn-code-swift Integration

After the swift assessment determines the change involves an interface (by checking if modified files include interface files -- `.tsx`, `.svelte`, `.vue`, `.jsx` for web; CLI modules for CLI; screen/widget files for TUI), and the change is above the sketch threshold:

"This interface change might benefit from a preview. Would you like to sketch it first? (This adds a minute but lets you see the result before implementing.)"

If the user accepts, arn-code-swift invokes arn-code-sketch with the swift description as context. After sketching, swift resumes implementation using the sketch as a reference.

### arn-code-ship Cleanup

See "Ship-Time Cleanup Protocol" above. The arn-code-ship skill calls into this guide's cleanup logic when preparing to commit.
