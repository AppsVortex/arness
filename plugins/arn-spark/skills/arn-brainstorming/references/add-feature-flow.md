# Add Feature Flow

Reference procedure for the greenfield wizard's Add Feature mode. Triggered when the user wants to add a new feature after the clickable prototype is complete.

## Why This Sequence

Each step produces artifacts the next step needs:
1. **Use cases** provide the behavioral specification (main success scenario, extensions, business rules)
2. **Clickable prototype** adds screens that validate the new feature's UI interactions
3. **Feature extract** creates the F-NNN backlog entry with references to the new UC and prototype screens
4. **Re-lock** (if previously locked) updates the frozen snapshot to include the new screens

Skipping a step is allowed but has consequences:
- Skip use cases → the feature has no behavioral grounding; prototype screens lack UC-driven flows
- Skip prototype → the feature has no validated screens; feature file has no Component/Reference entries
- Skip extract → the new behavior exists in UCs and prototype but is not in the feature backlog

## Workflow

### Step AF1: Gate G7 — Confirm Intent and Detect Lock State

1. Check if a prototype lock exists by reading CLAUDE.md for a `### Prototype Lock` section.

2. Present what will happen:

   **If prototype is NOT locked:**

   "Adding a new feature to your greenfield project. This will:
   1. Add a new use case (or update existing ones) to describe the behavior
   2. Iterate the clickable prototype to add screens for the new feature
   3. Add the feature to your backlog via feature extraction

   Ready to proceed, or would you like to customize which steps to include?"

   **If prototype IS locked:**

   "Adding a new feature to your greenfield project. The prototype is currently locked (v[N], locked on [date]).

   This will:
   1. Add a new use case (or update existing ones) to describe the behavior
   2. Iterate the clickable prototype to a NEW version v[N+1] — the locked v[N] snapshot is preserved
   3. Add the feature to your backlog via feature extraction
   4. Re-lock the prototype with the new v[N+1] as the reference

   The original locked snapshot (v[N]) will be preserved alongside the new lock. Ready to proceed?"

3. Ask (using `AskUserQuestion`):

   > **How would you like to proceed with adding this feature?**
   > 1. **Proceed with all steps** (Recommended) — Use cases, prototype, extract, and re-lock if applicable
   > 2. **Choose which steps** — Pick which steps to include
   > 3. **Cancel** — Return to normal wizard flow

### Step AF2: Capture the Feature Idea

Ask the user to describe the new feature. Accept anything from a sentence to a detailed description.

Acknowledge with a brief restatement: "Got it — you want to add [summary]. Let me walk you through the updates."

### Step AF3: Update Use Cases (if included)

Show progress:
```
Add Feature: USE-CASES --> prototype --> extract [→ re-lock]
             ^^^^^^^^^
```

Invoke the use-cases skill in resume mode. The skill detects the existing `use-cases/` directory and offers to add new use cases.

> `Skill: arn-spark:arn-spark-use-cases`

Pass context: "The user wants to add a new feature: [user's description from AF2]. Resume the existing use case catalog and add use case(s) for this new behavior."

When the skill completes, note which new UC-NNN files were created.

### Step AF4: Iterate Clickable Prototype (if included)

Show progress:
```
Add Feature: use-cases --> PROTOTYPE --> extract [→ re-lock]
                           ^^^^^^^^^
```

Invoke the clickable-prototype skill. It detects existing versions and offers to iterate. The lock does NOT prevent this — the locked snapshot is in `prototypes/locked/clickable-v[N]/`, while the skill creates a new version in `prototypes/clickable/v[N+1]/`.

> `Skill: arn-spark:arn-spark-clickable-prototype`

Pass context: "Iterate on the current clickable prototype to add screens for the new feature: [user's description]. New use case(s) added: [UC-NNN list from AF3]."

When the skill completes, note the new version number and new screens added.

### Step AF5: Add to Feature Backlog (if included)

Show progress:
```
Add Feature: use-cases --> prototype --> EXTRACT [→ re-lock]
                                        ^^^^^^^
```

Invoke the feature-extract skill. It detects the existing feature backlog and offers to add features.

> `Skill: arn-spark:arn-spark-feature-extract`

Pass context: "Add a new feature to the backlog for: [user's description]. New use case(s): [UC-NNN list]. New prototype screens: [screen list from AF4]."

When the skill completes, note the new F-NNN feature file created.

### Step AF6: Re-lock Prototype (if prototype was locked AND prototype step was included)

Show progress:
```
Add Feature: use-cases --> prototype --> extract --> RE-LOCK
                                                    ^^^^^^^
```

The prototype was previously locked at v[N]. A new version v[N+1] has been created and validated. Re-lock to update the reference artifact.

> `Skill: arn-spark:arn-spark-prototype-lock`

The lock skill detects the existing lock and offers to replace it. It will:
- Create a new frozen snapshot at `prototypes/locked/clickable-v[N+1]/`
- Update CLAUDE.md `### Prototype Lock` section with new version and date
- Create a new git tag
- The original locked snapshot (`prototypes/locked/clickable-v[N]/`) is preserved unless the user chooses to remove it

**If prototype was NOT locked or prototype step was skipped:** Skip this step silently.

### Step AF7: Summary

Show completion:
```
Add Feature: use-cases --> prototype --> extract [→ re-lock]
                ✓              ✓           ✓         ✓
```

Present what was done:
- **New use case(s):** UC-NNN: [Title] (or "skipped")
- **Prototype:** Iterated to v[N+1] with [M] new screens (or "skipped")
- **Feature backlog:** Added F-NNN: [Feature Name] (or "skipped")
- **Prototype lock:** Updated to v[N+1] (or "not locked" / "skipped")

Offer next steps:
- "Run `/arn-code-pick-issue` to pick this feature for implementation"
- "Run `/arn-code-feature-spec F-NNN` to start specifying this feature"
- "Run `/arn-brainstorming` again to add another feature"

## Error Handling

- **Use-cases skill fails:** Ask (using `AskUserQuestion`): **"Use-cases skill failed. How would you like to proceed?"** 1. Retry / 2. Skip use cases and continue to prototype / 3. Abort. If skip: note that prototype and extract will proceed without UC grounding.
- **Clickable-prototype skill fails:** Ask (using `AskUserQuestion`): **"Clickable-prototype skill failed. How would you like to proceed?"** 1. Retry / 2. Skip prototype and continue to extract / 3. Abort. If skip: note that extract will proceed without new screens, and re-lock will be skipped.
- **Feature-extract skill fails:** Ask (using `AskUserQuestion`): **"Feature-extract skill failed. How would you like to proceed?"** 1. Retry / 2. Create the feature file manually / 3. Abort.
- **Prototype-lock skill fails during re-lock:** Ask (using `AskUserQuestion`): **"Re-lock failed. How would you like to proceed?"** 1. Retry / 2. Skip re-lock / 3. Abort. If skip: Inform "The new prototype v[N+1] was created successfully but is not locked. Run `/arn-spark-prototype-lock` manually when ready."
- **User cancels mid-flow:** Show what was completed so far. Inform: "Partial updates are preserved. Run the wizard again to continue."
- **No clickable prototype exists:** This mode requires a completed clickable prototype. If not found, inform: "Add Feature mode requires a completed clickable prototype. Run the full greenfield wizard first." Redirect to normal wizard flow.
- **Lock exists but PreToolUse hook blocks prototype iteration:** This should not happen because the lock protects the snapshot directory, not the working prototype directory. If it does occur, the hook guard script may have overly broad path matching. Inform: "The prototype lock hook is blocking iteration. Run `/arn-spark-prototype-lock` with a narrower scope, or temporarily remove the hook from `.claude/settings.json`."
