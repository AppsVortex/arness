# Greenfield Feature Context Loading

Reference procedure for loading greenfield feature context during `arn-code-feature-spec`. This step only runs when a backlog entry is detected in Step 1a.

## Loading Sequence

1. Read `## Arness` config from CLAUDE.md to get:
   - **Vision directory** (for feature files at `[vision-dir]/features/`)
   - **Use cases directory** (for UC documents)

2. Read the F-NNN feature file:
   - Derive path: `[vision-dir]/features/F-NNN-kebab-name.md`
   - If exact filename unknown, scan the features directory for files starting with the `F-NNN` prefix

3. Parse UC references from the feature file's `## Use Case Context > References` field:
   - Extract UC-NNN identifiers (regex: `UC-\d{3}`)
   - For each UC reference, scan `[use-cases-dir]/` for the matching file (prefix `UC-NNN`)

4. Read each referenced UC document. Extract and hold:
   - Primary Actor, Goal, Preconditions, Trigger
   - Main Success Scenario (full numbered steps)
   - Extensions (all alternate/error paths)
   - Postconditions and Business Rules
   - Related Use Cases (includes, preceded-by, followed-by)

5. **Load style-brief (if available):**
   - Check for `[vision-dir]/style-brief.md`
   - If found, read and extract:
     - Toolkit Configuration section (Tailwind config, component library theme)
     - Color palette (all roles: primary, neutral, semantic, dark mode)
     - Typography tokens (heading levels, body, caption)
     - Spacing/sizing tokens
   - Hold as **style context** for use in Step 3 (agent invocations)
   - If not found: proceed without style context (no warning needed — not all greenfield projects have style exploration)

6. **Load scope boundary context** from the Feature Tracker and related feature files:

   a. Read the Feature Tracker from `[vision-dir]/features/feature-backlog.md`. Parse the table to get all feature IDs, names, dependencies, and statuses.

   b. Identify related features:
      - **Dependencies:** features listed in this feature's Deps column (features that must be done before this one)
      - **Dependents:** features whose Deps column includes this feature's ID (features that build on this one)
      - **Siblings:** other features that share a dependency with this feature (they share a common parent in the dependency graph)

   c. Read each related feature file (dependencies + dependents). For each, extract and hold:
      - Description (what the feature covers)
      - Journey Steps summary (what user flows it handles)
      - Acceptance Criteria (what it is responsible for delivering)
      - Components (what UI components it owns)

   d. Hold this as **scope boundary context** — a map of what each neighboring feature covers, used in Step 4 to prevent scope creep and identify genuine gaps.

   If `feature-backlog.md` is not found or cannot be parsed: warn and proceed without scope boundary context. The spec will be written without cross-feature awareness.

7. Present what was loaded:

   ```
   Loaded feature context for F-NNN: [Feature Name]

   **Feature file:** [path] (M acceptance criteria, J components)
   **Use cases loaded:** [N] documents
   - UC-NNN: [Title] (M steps, K extensions)
   **Scope context:** [N] related features loaded (M dependencies, K dependents)
   **Style-brief:** [loaded / not found]
   [If loaded:] Toolkit: [framework], [N] color tokens, [N] typography tokens, [N] spacing tokens

   The feature file, use case documents, and related feature context provide rich context.
   I'll use these to bootstrap the spec. Let me analyze the implementation approach.
   ```

8. Hold all loaded context (feature file + UC documents + style context + scope boundary context) for use throughout the workflow. Proceed to Step 2.

## Error Handling

- Feature file not found: warn and fall back to standard flow (ask user to describe)
- Use cases directory not configured or missing: proceed with feature file only, note the limitation
- Individual UC file not found: warn, proceed with available UCs
- No UC references in feature file: proceed with feature file only (some features have `None` for UC references)
- Feature Tracker (`feature-backlog.md`) not found or unparseable: proceed without scope boundary context; note that cross-feature awareness will be limited
- Related feature file not found: skip that feature in scope context, proceed with available files
- Style-brief not found: proceed without style context (no warning needed — style exploration is optional in the greenfield pipeline)
