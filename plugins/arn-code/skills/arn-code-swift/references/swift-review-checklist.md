# Swift Review Checklist

Lightweight review procedure performed after implementation, before offering to ship. The review produces findings with severity levels and a verdict that is recorded in the `SWIFT_REPORT.json`.

---

## Review Procedure

**Note:** If `/arn-code-simplify` was run before this review, the code may have been modified since the initial implementation. The review should validate the post-simplification state, not the pre-simplification state. Check the SIMPLIFICATION_REPORT.json in the project directory for details on what was changed.

### 1. Pattern Compliance

Spot-check modified files against the patterns listed in the swift plan's "Patterns to Follow" section.

**How to spot-check:**
- For each pattern listed in the plan, read at least one modified file where the pattern applies
- Verify the implementation follows the pattern's conventions (naming, structure, error handling, etc.)
- Compare against the pattern reference in `code-patterns.md` if there is ambiguity
- Check 2-3 files minimum; check all files if 5 or fewer were modified

**Finding severity:**
- **WARNING** -- minor deviation from a pattern that does not affect functionality (e.g., slightly different naming convention, missing optional documentation, non-standard file organization)
- **ERROR** -- significant deviation that could cause issues (e.g., wrong error handling pattern, missing required validation, breaking an established interface contract)

### 2. Test Verification

Verify that all targeted tests pass after implementation.

**Procedure:**
- Run the verification command from the swift plan's "Test Plan" section
- If no specific command was listed, run the project's default test command against the affected test files
- All tests that were updated or added must pass

**Finding severity:**
- **ERROR** -- any test failure. Test failures always block shipping.

**Self-heal before reporting:** If tests fail, attempt to fix (up to 3 attempts per failing test) before recording the finding. Only record an ERROR if the test still fails after self-healing attempts.

### 3. Architect Concern Resolution

If the architect flagged any concerns in Step 2 of the workflow, verify each concern was addressed during implementation.

**Procedure:**
- For each concern the architect raised, check whether the implementation addressed it
- A concern is "resolved" if the code change directly addresses it, or if the concern was determined to be inapplicable after implementation
- A concern is "unresolved" if it was not addressed and no justification was provided

**Finding severity:**
- **WARNING** -- concern acknowledged but not fully addressed (e.g., architect suggested adding input validation, implementation deferred it with a TODO)
- **ERROR** -- concern ignored entirely with no justification (e.g., architect warned about a race condition, implementation did not address it at all)

---

## Severity Definitions

### WARNING

A finding that should be noted but does not block shipping. Warnings are informational -- they flag areas where the implementation could be improved but is not incorrect.

Examples:
- Pattern naming convention slightly differs from code-patterns.md
- A test covers the happy path but not an edge case the architect mentioned
- Documentation comment is missing on a public function
- An architect concern was partially addressed but could be more thorough

### ERROR

A finding that blocks shipping until resolved. Errors indicate the implementation has a problem that should be fixed before merging.

Examples:
- A test fails after implementation
- A required validation pattern is missing (per code-patterns.md)
- An architect-flagged security concern was not addressed
- An existing interface contract was broken without updating consumers
- Error handling does not follow the project's established pattern

---

## Verdict Logic

The verdict is determined by the highest-severity finding across all three review areas.

### PASS

All checks are green:
- All spot-checked files follow their applicable patterns
- All tests pass
- All architect concerns are resolved (or none were raised)

No findings are recorded in the report.

### PASS WITH WARNINGS

One or more WARNING findings exist, but no ERRORs:
- Minor pattern deviations were noted
- Architect concerns were partially addressed
- Tests all pass

Record all WARNING findings in the report. Present them to the user as informational notes.

### NEEDS FIXES

One or more ERROR findings exist:
- A test is failing
- A significant pattern violation was found
- An architect concern was ignored

Record all findings (WARNING and ERROR) in the report. Present the ERRORs to the user with specific guidance on what to fix. Offer to fix the issues before shipping.

After fixes are applied, re-run the review to update the verdict. Repeat until the verdict is PASS or PASS WITH WARNINGS.

---

## Recording Findings in the Report

Each finding is recorded as an entry in the appropriate array in `SWIFT_REPORT.json`:

**Pattern findings** go in `review.patternFindings`:
```json
{
  "checkId": "pattern-<N>",
  "severity": "warning | error",
  "description": "Description of the finding",
  "file": "path/to/affected/file"
}
```

**Test findings** go in `review.testFindings`:
```json
{
  "checkId": "test-<N>",
  "severity": "error",
  "description": "Description of the test failure",
  "test": "path/to/test/file::test_name"
}
```

**Architect concern resolution** goes in `review.architectConcernsResolved`:
```json
{
  "concern": "The original concern text",
  "resolved": true,
  "resolution": "How it was addressed"
}
```

Empty arrays indicate no findings in that category.
