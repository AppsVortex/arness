---
name: arn-code-review-implementation
description: >-
  This skill should be used when the user says "review implementation", "review
  the project", "check implementation", "quality review", "validate
  implementation", "implementation review", or wants a post-execution quality gate to verify that the
  implementation follows the project's stored code and testing patterns and
  matches the plan. Reports issues as ERRORS, WARNINGS, INFO with a verdict.
  Do NOT use this for reviewing PRs (use arn-code-review-pr) or validating plans
  (use arn-code-review-plan).
version: 1.0.0
---

# Arness Review Implementation

Post-execution quality gate that verifies an implementation matches the project plan and follows the stored code patterns, testing patterns, and architecture documentation. Reports issues classified as ERRORS, WARNINGS, and INFO, with a final verdict.

Pipeline position:
```
arn-code-init -> arn-code-feature-spec / arn-code-bug-spec -> arn-code-plan -> arn-code-save-plan -> arn-code-review-plan -> arn-code-taskify -> arn-code-execute-plan -> **arn-code-review-implementation**
```

This is a self-contained review -- it does not invoke sub-agents. The review is a structured, checklist-driven process: read code, compare to patterns, classify findings.

**When to Use:**
- After `arn-code-execute-plan` completes
- To verify that implementation matches the plan and follows stored patterns
- Before considering the project done
- **Optional** -- skip for small/straightforward projects; recommended for 3+ phases, multiple modules, or critical features

## Prerequisites

If no `## Arness` section exists in the project's CLAUDE.md, inform the user: "Arness is not configured for this project yet. Run `/arn-implementing` to get started — it will set everything up automatically." Do not proceed without it.

## Workflow

### Step 1: Load the Project

1. Read the project's CLAUDE.md and extract the `## Arness` section to find:
   - Plans directory path
   - Code patterns directory path
2. Ask for `PROJECT_NAME` if not provided in the trigger message
3. Read all project artifacts:
   - `<project-folder>/INTRODUCTION.md` -- codebase patterns that should have been followed
   - All reports in `<project-folder>/reports/` -- what was implemented, tested, bugs fixed
   - All phase plans in `<project-folder>/plans/` -- acceptance criteria, expected files, expected patterns
4. Read stored pattern documentation:
   - `<code-patterns-dir>/code-patterns.md`
   - `<code-patterns-dir>/architecture.md`
   - `<code-patterns-dir>/testing-patterns.md`
   - `<code-patterns-dir>/ui-patterns.md` (if it exists)
   - `<code-patterns-dir>/security-patterns.md` (if it exists)
5. Build a review checklist from these sources: files that should exist, patterns that should have been applied, features that were planned, tests that should pass

---

### Step 2: Plan Compliance Review

Compare the plan artifacts (phase plans, INTRODUCTION.md) with the execution reports (implementation reports, testing reports). Run these checks:

| Check | Severity | What |
|-------|----------|------|
| PC01 | ERROR | Every feature listed in phase plans has a matching entry in implementation reports |
| PC02 | ERROR | Every test case listed in phase plans has a matching entry in testing reports |
| PC03 | WARNING | All acceptance criteria from phase plans are addressed in reports |
| PC04 | WARNING | Files listed in `filesCreated`/`filesModified` in reports actually exist on disk |
| PC05 | INFO | Features implemented that were NOT in the original plan (scope creep detection) |
| PC06 | ERROR | Any `bugsFixed` entries -- read the changed files to verify the fix was correct |
| PC07 | WARNING | Testing pass rate below 100% -- investigate remaining failures |

---

### Step 3: Pattern Compliance Review (Dynamic)

All checks in this step are generated dynamically from stored pattern documentation. This is NOT a hardcoded checklist -- the checks are derived at runtime from whatever patterns are documented for this project.

**Code Pattern Compliance:**

Read `code-patterns.md`. For each documented pattern:
1. Identify implementation files where this pattern should apply (from reports + pattern context)
2. Read the relevant files
3. Check whether the implementation follows the documented pattern
4. Generate findings with these severity levels:
   - `CP-[PatternName]-CONFLICT` (ERROR) -- implementation contradicts the documented pattern
   - `CP-[PatternName]-MISSING` (WARNING) -- pattern should apply but wasn't followed
   - `CP-[PatternName]-APPLY` (WARNING) -- general deviation from the pattern

**Architecture Compliance:**

Read `architecture.md`. Check that:
- Component boundaries are respected (no cross-boundary violations)
- Integration points match the documented architecture
- Architectural decisions from INTRODUCTION.md are reflected in the implementation

**UI Pattern Compliance (if `ui-patterns.md` exists):**

Read `ui-patterns.md`. For each documented pattern:
1. Identify implementation files where this pattern should apply (frontend components, pages, layouts)
2. Read the relevant files
3. Check whether the implementation follows the documented UI pattern
4. Generate findings:
   - `UP-[PatternName]-CONFLICT` (ERROR) -- implementation contradicts the documented UI pattern (e.g., wrong component library)
   - `UP-[PatternName]-MISSING` (WARNING) -- UI pattern should apply but wasn't followed
   - `UP-[PatternName]-ACCESSIBILITY` (WARNING) -- accessibility requirements documented but not implemented

**Testing Pattern Compliance:**

Read `testing-patterns.md`. For each documented pattern:
1. Identify test files from testing reports
2. Read the test files
3. Check correct usage of the documented test framework, markers, fixtures, and helpers
4. Generate findings:
   - `TP-[PatternName]-FRAMEWORK` (ERROR) -- wrong test framework or runner used
   - `TP-[PatternName]-FIXTURES` (WARNING) -- should use documented fixtures but doesn't
   - `TP-[PatternName]-MARKERS` (WARNING) -- should use documented markers but doesn't

**Security Pattern Compliance (if `security-patterns.md` exists):**

Read `security-patterns.md`. For each documented pattern:
1. Identify implementation files where this pattern should apply (auth endpoints, input handlers, data models, API routes)
2. Read the relevant files
3. Check whether the implementation follows the documented security pattern
4. Generate findings:
   - `SP-[PatternName]-CONFLICT` (ERROR) -- implementation contradicts the documented security pattern (e.g., plaintext passwords when hashing is documented)
   - `SP-[PatternName]-MISSING` (WARNING) -- security pattern should apply but wasn't followed (e.g., no input validation on a new endpoint)
   - `SP-[PatternName]-WEAKNESS` (WARNING) -- implementation partially follows the pattern but has gaps (e.g., auth check present but no rate limiting)

---

### Step 3b: Visual Regression Review

This step is conditional. Check if `### Visual Testing` is configured in the project's CLAUDE.md `## Arness` section.

**If not configured:** Skip this step silently. Do not add any findings.

**If configured:** Parse the full `### Visual Testing` section:

1. **Discover layers:**
   - Extract top-level fields as Layer 1 config (always active): capture script, compare script, baseline directory, diff threshold, requires dev server
   - Scan for `#### Layer N:` subsections. For each, extract: Status, Capture script, Compare script, Baseline directory, Diff threshold, Requires dev server, Environment
   - Build a layer list. Filter to **active layers only** (Status = active or validated). Skip deferred layers.

2. **For each active layer:**
   a. If the layer requires a dev server and the dev server is not already running: start it (read the start command from INTRODUCTION.md or the project's package.json)
   b. Run the layer's capture script:
      ```
      [layer capture command]
      ```
   c. Run the layer's comparison script against its baselines:
      ```
      [layer compare command]
      ```
   d. Parse the comparison output and generate layer-prefixed findings:

   | Check | Severity | What |
   |-------|----------|------|
   | VR-L[N]-[ScreenName]-REGRESSION | ERROR | Screen has visual regression above threshold ([X]% pixel difference, threshold: [T]%) |
   | VR-L[N]-[ScreenName]-MISSING | WARNING | No baseline image exists for this screen |
   | VR-L[N]-[ScreenName]-MATCH | INFO | Screen matches baseline within threshold |

   e. If the layer's capture or comparison script fails to run: add a single WARNING finding `VR-L[N]-UNAVAILABLE: Layer [N] ([Name]) capture/compare failed: [error]. Visual regression not checked for this layer.` Do NOT block the review. Continue with remaining layers.

3. **Stop dev server** after all layers that require it have been checked.

4. **Deferred layers:** If any layers have Status = deferred, add a single INFO finding: `VR-DEFERRED: Deferred visual testing layers: [layer names]. Run /arn-spark-visual-readiness to check if they can be activated.`

---

### Step 3c: Cross-Layer Comparison

> **Conditional:** Only execute this step if 2 or more active layers produced captures in Step 3b. If only one layer (or no layers) have captures, skip this step silently.

1. Read the cross-layer comparison guide:
   > Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-review-implementation/references/cross-layer-comparison-guide.md`

2. **Determine threshold:**
   - Check the project's CLAUDE.md `### Visual Testing` section for `**Cross-layer threshold:**` -- use that value if present
   - Check for `**Cross-layer overrides:**` for per-screen threshold overrides
   - Default: 7% pixel difference

3. **Match screenshots across layers:**
   - Build a screen-name index for each active layer from Step 3b results
   - Layer 1 and Layer 2 static mode: use screen names from `screen-manifest.json`
   - Layer 2 journey mode: use the `name` field from capture steps in `journey-manifest.json`
   - Match screens across layers by name (case-insensitive)

4. **For each matched pair:**
   - Load both screenshots
   - Resize to common dimensions if they differ (use the larger as reference)
   - Compute pixel diff percentage using the project's compare script (pixelmatch or looks-same)
   - Look up per-screen threshold override if defined, otherwise use global threshold
   - Classify the result:
     - Diff > threshold: `VR-CROSS-[ScreenName]-DIVERGENCE` (WARNING)
     - Diff <= threshold: `VR-CROSS-[ScreenName]-MATCH` (INFO)

5. **Unmatched screens:** For screens present in one layer but not the other, classify as `VR-CROSS-UNMAPPED` (INFO)

6. **Skip silently** if no matched pairs exist across layers (e.g., Layer 1 and Layer 2 capture entirely different screens)

7. Collect all cross-layer findings for the report summary in Step 5

---

### Step 3d: Sketch Promotion Verification

> **Conditional:** Only execute this step if INTRODUCTION.md contains a `### Sketch Artifacts` section. If no sketch artifacts exist, skip this step silently.

If sketch artifacts are present:

1. Read the sketch manifest file referenced in the Sketch Artifacts section
2. Load the `componentMapping` and `composition` fields
3. Run these checks:

| Check | Severity | What |
|-------|----------|------|
| SK01 | WARNING | Every `componentMapping` entry's target file exists on disk |
| SK02 | WARNING | Promoted code in each target file is structurally derived from the sketch source (read both files, check for shared component names, function signatures, or JSX structure -- exact match is not required, but the target should clearly originate from the sketch) |
| SK03 | WARNING | If `composition.layout` exists, components are positioned per the layout specification in the target page (check import statements and render placement in the parent page/screen) |
| SK04 | WARNING | If all `componentMapping` target files exist on disk, the manifest `status` should be `"consumed"` -- flag if still `"validated"` or another non-consumed status |
| SK05 | INFO | If manifest status is `"consumed"`, log: "Sketch manifest fully consumed -- all components promoted successfully" |

---

### Step 4: Cross-Phase Integration

If the project has multiple phases, check integration points between phases:

| Check | Severity | What |
|-------|----------|------|
| XI01 | WARNING | Modules from different phases can import each other without circular dependencies |
| XI02 | WARNING | Data models from different phases have correct relationships (foreign keys, references) |
| XI03 | INFO | Dependency injection / service registration updated if new services were added across phases |

Skip this step for single-phase projects.

---

### Step 5: Report

Present findings in this format:

```
## Implementation Review: <PROJECT_NAME>

### Summary
- Phases reviewed: N
- Files inspected: N
- Pattern docs checked: code-patterns.md (N patterns), testing-patterns.md (N patterns), architecture.md, ui-patterns.md (N patterns, if present), security-patterns.md (N patterns, if present)
- Visual regression: [per-layer summary / "not configured"]
- Cross-layer comparison: [N] screen pairs compared, [M] divergences (WARNING), [K] matches (INFO), [U] unmapped screens (INFO) / Skipped (fewer than 2 active layers with captures)
- Sketch promotion: [N of M components promoted, manifest status: consumed/validated/N/A] / "no sketch artifacts"
- Issues found: N errors, N warnings, N info

### ERRORS (must fix)
1. [CheckID] Description -- file:line

### WARNINGS (should fix)
1. [CheckID] Description -- file:line

### INFO
1. [CheckID] Description

### Verdict
[ PASS | PASS WITH WARNINGS | NEEDS FIXES ]
```

**Verdict logic:**
- **PASS**: Zero errors, warnings are minor or cosmetic
- **PASS WITH WARNINGS**: Zero errors, but warnings should be addressed before the project is considered complete
- **NEEDS FIXES**: One or more errors -- these must be fixed before the project is considered complete

If the verdict is **NEEDS FIXES** -> ask the user if they want help fixing the errors.
If the verdict is **PASS** or **PASS WITH WARNINGS** -> confirm the project implementation is ready and suggest next steps:
- "Run `/arn-code-document-project` to generate developer documentation for this feature."
- "Run `/arn-code-ship` to commit your changes and create a pull request."

---

## Error Handling

- **`## Arness` config missing in CLAUDE.md** -> suggest running `/arn-implementing` to get started.
- **Project directory missing** -> suggest running `/arn-code-save-plan` and `/arn-code-execute-plan` first.
- **Reports missing from reports/ directory** -> suggest running `/arn-code-execute-plan` to generate reports.
- **Stored pattern docs missing** -> skip Pattern Compliance Review (Step 3) entirely, add an INFO finding noting that pattern compliance could not be checked, proceed with Plan Compliance (Step 2) and Cross-Phase Integration (Step 4) only.
- **Implementation file from report doesn't exist on disk** -> record as PC04 WARNING and continue the review.
