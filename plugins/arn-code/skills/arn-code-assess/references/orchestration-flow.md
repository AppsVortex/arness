# Orchestration Flow

This document defines the multi-spec pipeline algorithm used by `arn-code-assess` to manage multiple improvement specs through the Arness pipeline in a single session.

## Multi-Spec Lifecycle

Each improvement bundle goes through a lifecycle tracked by the orchestrator:

```
pending → specced → planned → saved → taskified → executing → executed → skipped
```

State transitions:
- `pending` → `specced`: After `arn-code-feature-spec` writes the spec file
- `specced` → `planned`: After `arn-code-plan` writes the plan preview
- `planned` → `saved`: After `arn-code-save-plan` creates the project folder
- `saved` → `taskified`: After `arn-code-taskify` creates the Claude task list
- `taskified` → `executing`: When `arn-code-execute-plan` begins
- `executing` → `executed`: After execution completes
- Any state → `skipped`: If the user chooses to skip during conflict resolution

## Spec State Tracking

The orchestrator maintains state for each spec throughout the session:

```
spec_states = {
  "<spec-name>": {
    status: "<lifecycle state>",
    spec_file: "<specs-dir>/FEATURE_<name>.md",
    plan_preview: "<plans-dir>/PLAN_PREVIEW_<name>.md",
    project_folder: "<plans-dir>/<name>/",
    execution_reports: ["<plans-dir>/<name>/reports/*.json"],
    files_modified: ["list of files changed during execution"]
  }
}
```

This state enables resumability, conflict detection, and the final summary.

## Batch Planning Phase

After all specs are created (G4), plan them:

```
for each spec in spec_list:
    invoke arn-code:arn-code-plan <spec-name>
    store plan_preview path in spec_states
```

Plans can be generated sequentially. Present all plans to the user for review together. The user can:
- Approve all plans
- Request revision on specific plans (re-invoke arn-code-plan with feedback)
- Remove a spec from the pipeline (set status to `skipped`)

After user approves, save all plans:

```
for each spec where status == "planned":
    invoke arn-code:arn-code-save-plan
    store project_folder path in spec_states
```

## Execution Order

Before starting sequential execution, determine the order. Present the suggested order to the user and allow overrides.

### Ordering Heuristic

1. **Independent specs first** — Specs whose plan files reference NO overlapping source files with any other spec. These are safest to execute first because they cannot create conflicts.

2. **Foundational specs second** — Specs that modify shared/base code (utilities, base classes, configuration, database schemas). Other specs may depend on these changes.

3. **Feature-specific specs third** — Specs that modify code within a single feature boundary.

4. **Most-overlapping specs last** — Specs that share the most file references with already-executed specs. These are most likely to need re-planning after earlier executions.

### Determining File Overlap

Extract file paths from each spec's phase plan files (`PHASE_N_PLAN.md`):
- Look for "Files to create" and "Files to modify" sections
- Look for file paths in task descriptions (patterns: backtick-wrapped paths, "in `path/to/file`")
- Build a set of referenced files per spec

Compare sets pairwise to identify overlap.

## Sequential Execution with Conflict Detection

```
for each spec in ordered_spec_list:
    if spec.status == "skipped":
        continue

    # Conflict check (skip for first spec)
    if spec is not the first:
        conflicts = detect_conflicts(previously_executed_specs, spec)
        if conflicts:
            present_conflicts_to_user(conflicts)
            user_choice = ask("Re-plan / Proceed anyway / Skip this spec")
            if user_choice == "re-plan":
                re_invoke_arness_plan(spec)
                re_invoke_arness_save_plan(spec)
            elif user_choice == "skip":
                spec.status = "skipped"
                continue

    # Taskify and execute
    invoke arn-code:arn-code-taskify  (for this spec's project folder)
    spec.status = "taskified"

    invoke arn-code:arn-code-execute-plan
    spec.status = "executing"

    # After execution completes
    collect execution reports
    extract files_modified from reports
    spec.status = "executed"
```

## Conflict Detection Algorithm

```
function detect_conflicts(executed_specs, next_spec):
    # Collect all files modified by previously executed specs
    executed_files = {}  # file_path → spec_name that modified it
    for spec in executed_specs:
        for file in spec.files_modified:
            executed_files[file] = spec.name

    # Collect all files referenced in next spec's plan
    planned_files = set()
    for phase_file in next_spec.project_folder/PHASE_*_PLAN.md:
        extract file paths from "Files to create" sections
        extract file paths from "Files to modify" sections
        extract file paths from task descriptions
        add to planned_files

    # Find overlap
    overlap = {}
    for file in planned_files:
        if file in executed_files:
            overlap[file] = executed_files[file]

    return overlap
```

## Conflict Presentation

When conflicts are detected, present them clearly:

```markdown
### Conflict Detected

The following files were modified by a previous spec and are referenced
in the current spec's plan:

| File | Modified by | Referenced in |
|------|-------------|---------------|
| `src/auth/middleware.py` | ASSESS-ARCH-001 (auth refactor) | ASSESS-SEC-002 (security hardening) |
| `src/utils/validators.py` | ASSESS-ARCH-001 (auth refactor) | ASSESS-SEC-002 (security hardening) |

**Options:**
1. **Re-plan** — Re-generate the plan for this spec (it will read the current code state)
2. **Proceed anyway** — Execute the existing plan (risk: some instructions may be outdated)
3. **Skip this spec** — Move to the next one
```

## Re-plan Decision Flow

Apply these rules to determine the default recommendation:

```
if overlap_count == 0:
    proceed normally (no conflict)

elif all overlapping files are test files:
    recommend "Proceed anyway"
    reason: test files are typically additive (new test functions, new fixtures)
            and rarely conflict

elif overlapping files are source files:
    recommend "Re-plan"
    reason: source file modifications may invalidate the existing plan's
            assumptions about file contents, function signatures, or imports

elif overlap_count > 5:
    recommend "Re-plan" with emphasis
    reason: high overlap suggests these specs are closely related and may
            have been better bundled together
```

## Error Recovery

### Execution Failure Mid-Spec

If `arn-code-execute-plan` fails during execution of spec N:

1. Mark spec N as `executing` (not `executed`) — it is partially complete
2. Present the failure to the user
3. Offer options:
   - **Retry** — Resume execution from the failed task
   - **Skip remaining tasks in this spec** — Mark as `executed` (partial) and move to spec N+1
   - **Abort pipeline** — Stop all execution, proceed to test gate with whatever was completed

### Spec Creation Failure

If `arn-code-feature-spec` fails to create a spec for a bundle:

1. Offer to split the bundle into individual findings and retry each separately
2. If a single finding also fails, skip it and continue with remaining bundles
3. Report skipped findings in the final summary

### Plan Conflict Beyond Recovery

If the user encounters repeated conflicts (same files flagged across 3+ specs):

1. Suggest re-bundling the remaining specs into a single combined spec
2. This consolidation removes the conflict problem since one plan handles all changes
3. Present this as: "These improvements are closely related. Combining them into a single spec would avoid further conflicts."

## Final Summary Data

After all execution completes (or after the user aborts), collect data for the completion summary:

```
summary = {
    assessment: {
        total_findings: N,
        by_severity: { high: H, medium: M, low: L },
        by_category: { architecture: N, performance: N, ... }
    },
    selected: N (of total),
    specs: [
        { name: "...", status: "executed", tasks_completed: N, tasks_total: N },
        { name: "...", status: "skipped", reason: "user chose to skip" },
        ...
    ],
    test_verdict: "ALL PASSING" | "FAILURES DETECTED" | "not run",
    ship: { type: "PR", url: "..." } | { type: "commit", hash: "..." } | "not shipped",
    patterns_updated: { changed: N, added: N, removed: N } | "not updated"
}
```
