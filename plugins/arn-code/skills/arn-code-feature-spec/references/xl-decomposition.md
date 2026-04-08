# XL Feature Decomposition

Reference procedure for decomposing XL features into sub-feature specs. This flow activates when `decomposition_mode` is true (set in Step 1c when the user opts for XL Decomposition).

## Decomposition Workflow

1. Derive sub-feature IDs and spec names from the decomposition hints:
   - Sub-feature IDs: `F-NNN.1`, `F-NNN.2`, `F-NNN.3`, etc. (dot notation from parent ID)
   - Spec names: `FEATURE_F-NNN.1_<sub-feature-kebab-name>.md`, `FEATURE_F-NNN.2_<sub-feature-kebab-name>.md`, etc.
   - Present the proposed names to the user for confirmation

2. Read the feature spec template at `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-feature-spec/references/feature-spec-template.md`.

3. For each sub-feature, populate a spec using the template:
   - **Problem Statement:** Scoped to the sub-feature's slice. "What" from the sub-feature description in the decomposition hints. "Why" from the parent feature's Priority Rationale, contextualized to this slice.
   - **Requirements:** Functional requirements derived from the sub-feature's journey segment (the UC steps mapped to this sub-feature). Non-functional requirements from the parent feature's Technical Notes, scoped to this sub-feature.
   - **Architectural Assessment:** Invoke `arn-code-architect` once with ALL sub-features described together, requesting per-sub-feature architectural analysis. The architect sees the full picture and can identify shared components, integration points between sub-features, and the correct implementation sequence. Distribute the architect's per-sub-feature analysis into each sub-feature spec's Architectural Assessment section. Shared components and cross-sub-feature integration points go into the Integration Points section of every affected sub-feature spec. If the feature involves UI, also invoke `arn-code-ux-specialist` with the sub-feature boundaries and the parent feature's UI Behavior and Components.
   - **Behavioral Specification:** Populated from the UC documents, scoped to the journey segment mapped to this sub-feature. The Feature Backlog Entry section includes:
     - `**Feature:** F-NNN.M: [Sub-feature Name] (part of F-NNN: [Parent Feature Name])`
     - `**Parent feature:** F-NNN: [Parent Feature Name]`
     - `**Parent issue:** [#NN / PROJ-NN / --]`
     - `**Sibling sub-features:** [F-NNN.1: Name, F-NNN.2: Name, ...]` (excluding this one)
     - The UC References table includes only the UCs relevant to this sub-feature's journey segment
   - **Scope & Boundaries:** Explicitly state what THIS sub-feature covers, what is handled by sibling sub-features, and what is handled by other features in the backlog (from scope boundary context). Include cross-references: "F-NNN.1 handles [X]; F-003 handles [Y]".
   - All other sections populated as normal from the exploration conversation, scoped to the sub-feature.

4. Write all sub-feature specs to `<specs-dir>/`:
   - Write specs in parallel (they are independent files)
   - Each spec file: `FEATURE_F-NNN.M_<sub-feature-kebab-name>.md`

## Feature Tracker Update

5. Update the Feature Tracker in `[vision-dir]/features/feature-backlog.md`:
   a. Parse the existing Feature Tracker table
   b. Set the parent feature's (F-NNN) status to `decomposed`
   c. Add sub-feature rows immediately after the parent row:
      - ID: `F-NNN.1`, `F-NNN.2`, etc.
      - Feature: sub-feature name
      - Priority: inherited from parent (or adjusted if the user specified during exploration)
      - Deps: from the decomposition hints' inter-sub-feature dependencies, plus the parent's external dependencies where relevant
      - Phase: same as parent
      - Issue: `--` (filled in step 6 if issues are created)
      - Status: `pending`
   d. Write the updated `features/feature-backlog.md`

## Child Issue Creation

6. Create child issues (if issue tracker is configured):

   a. Read **Issue tracker** from `## Arness` config. If `none`, skip to step 7.

   b. Retrieve the parent feature's issue reference from the Feature Tracker (the Issue column for F-NNN).

   c. For each sub-feature, create an issue:
      - **If GitHub:**
        ```bash
        gh issue create --title "F-NNN.M: Sub-feature Name" --body "<body>" --label "arness-feature-issue,arness-priority-<level>"
        ```
        The body includes: sub-feature description, journey segment, acceptance criteria scoped to this sub-feature, components, and a traceability line: "Part of #\<parent-issue\> (F-NNN: Parent Feature Name)"
      - **If Jira:**
        Use the Atlassian MCP server to create a sub-task under the parent issue, or a Story linked to the parent with "is part of" relation. Summary: "F-NNN.M: Sub-feature Name". Labels: `[arness-feature-issue, arness-priority-<level>]`.

   d. Update the Feature Tracker: fill in the Issue column for each sub-feature row with the created issue number/key.

   e. Write the updated `features/feature-backlog.md` again.

## Completion Summary

7. Present the decomposition summary:

   "XL feature F-NNN: [Parent Feature Name] decomposed into [N] sub-features.

   **Specs written:**
   - `FEATURE_F-NNN.1_<name>.md` -- [brief description]
   - `FEATURE_F-NNN.2_<name>.md` -- [brief description]
   - `FEATURE_F-NNN.3_<name>.md` -- [brief description]

   **Feature Tracker updated:**
   - F-NNN status: decomposed
   - Sub-features added: F-NNN.1 (#43), F-NNN.2 (#44), F-NNN.3 (#45)

   **Implementation order:** [based on inter-sub-feature dependencies]
   1. F-NNN.1: [Name] -- no sub-feature dependencies
   2. F-NNN.2: [Name] -- no sub-feature dependencies
   3. F-NNN.3: [Name] -- depends on F-NNN.1, F-NNN.2

   To plan a sub-feature: Run `/arn-code-plan FEATURE_F-NNN.M_<name>`
   To pick the next sub-feature: Run `/arn-code-pick-issue`"

   The decomposition flow is now complete. Do not proceed to the standard single-spec flow.

   After writing all sub-feature specs, delete the DRAFT file (`<specs-dir>/DRAFT_FEATURE_<name>.md`) — it is superseded by the decomposed sub-feature specs.

## Error Handling

- Decomposition hints have fewer than 2 sub-features: warn user, ask to provide more or proceed with single spec.
- Sub-feature journey segments don't cover all parent feature journey steps: warn about coverage gap, ask user to adjust.
- Architect returns shared-component warnings between sub-features: note in each affected spec's Integration Points, do not block.
- Child issue creation fails: save specs and Feature Tracker rows without issue references. Print the sub-feature table so user can create issues manually. Do not fail the overall decomposition.
- Feature Tracker update fails: print the updated table in the conversation. Specs are already written and usable.
- Sub-feature spec already exists (re-running decomposition): ask user whether to overwrite or skip existing specs.
