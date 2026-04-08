# Bug Spec Template

A bug spec captures WHAT is wrong and WHY -- not the implementation plan for fixing it. This template defines the structure for bug specification documents written during the `arn-code-bug-spec` workflow's complex path. The spec is saved to the project's specs directory as `BUGFIX_<name>.md` and serves as the diagnostic foundation for a subsequent fix plan.

## Instructions for populating this template

When populating this template:
- Every section below MUST appear in the output, even if the content is brief
- Replace all bracketed placeholders with concrete content from the investigation
- If information is missing for a section, write what you know and add the gap to Open Items
- Tables should have real data, not example rows -- remove example rows if no data is available
- This is a SPECIFICATION, not a plan: NO phases, NO implementation tasks, NO task ordering
- Focus on diagnosis, evidence, and impact -- the "what" and "why", not the "how"

---

## Template

```markdown
# [Bug Title] -- Specification

## Bug Report

- **Symptom:** [what the user observes -- error messages, incorrect behavior, degraded performance]
- **Severity:** [Low / Medium / High / Critical]
- **Affected area:** [module/component/endpoint where the bug manifests]
- **Reproduction:** [steps or conditions to reproduce the bug]
- **When introduced:** [if known -- recent commit, version, date, or "unknown"]

---

## Root Cause Analysis

- **Root cause:** [2-4 sentences explaining what is actually wrong at a technical level]
- **Evidence:** [file paths and line numbers supporting the diagnosis]
- **Confidence:** [High / Medium / Low]

### Investigation Trail

1. **Hypothesis:** [first hypothesis tested]
   **Result:** [Confirmed / Eliminated -- with brief explanation]

2. **Hypothesis:** [second hypothesis tested]
   **Result:** [Confirmed / Eliminated -- with brief explanation]

[Add more hypotheses as needed. Include all significant hypotheses tested during investigation, even those that were eliminated.]

---

## Impact Assessment

### Affected Files

| File | What's Wrong | Action Needed |
|------|-------------|---------------|
| `path/to/file` | [description of the problem in this file] | [fix / modify / review] |

### Broader Impact

- **Affected functionality:** [what else is broken or degraded as a result of this bug]
- **Data impact:** [any data corruption, integrity, or migration concerns]
- **User impact:** [who is affected and how -- scope of the blast radius]

---

## Architectural Assessment

[arn-code-architect's validation of the fix direction. Include:]
- **Alignment:** [does the proposed fix direction align with system architecture?]
- **Concerns:** [architectural risks, coupling issues, or design problems the fix must respect]
- **Recommended approach:** [architect's recommended fix strategy at a high level]

---

## Proposed Fix Direction

[Brief description of what needs to change to resolve the root cause. 2-4 sentences describing the fix direction without full implementation details. This is the "what", not the "how" -- enough to guide a subsequent fix plan.]

---

## Test Coverage Audit

- **Existing tests for affected code:** [list of test files/functions that currently cover the buggy code paths]
- **Tests that should have caught this:** [the gap -- what test coverage was missing that allowed the bug to exist]
- **Tests that will break after fix:** [existing test assertions that match the buggy behavior and will need updating]
- **New tests needed:** [scenarios that must be covered to prevent regression]

---

## Scope & Boundaries

**In Scope:**
- [what the fix for this bug includes]

**Out of Scope:**
- [related improvements, refactors, or tangential issues deferred to separate work]

---

## Open Items

- [unresolved question or decision needed]
- [risk that needs monitoring or mitigation]
- [area that needs more investigation before a fix can be planned]

---

## Recommendation

[Ready for planning / Needs more investigation on X]

To create a fix plan: Run `/arn-code-plan BUGFIX_<name>`
```

---

## Section Guidance

| Section | Source | Depth |
|---------|--------|-------|
| Bug Report | User's bug description + investigator findings | 5 fields, keep factual and concise |
| Root Cause Analysis | arn-code-investigator output | 2-4 sentences root cause + evidence + numbered hypotheses |
| Impact Assessment | arn-code-investigator scope assessment | Table of affected files + 3 impact bullets |
| Architectural Assessment | arn-code-architect validation | Alignment, concerns, recommended approach |
| Proposed Fix Direction | arn-code-investigator + arn-code-architect consensus | 2-4 sentences, high-level direction only |
| Test Coverage Audit | arn-code-investigator Test Coverage Assessment | 4 bullet categories covering existing, missing, breaking, and new tests |
| Scope & Boundaries | Conversation decisions | 2-5 bullets per subsection |
| Open Items | Accumulated from investigation + architect feedback | All unresolved items |
| Recommendation | Overall assessment | 1-2 sentences + handoff instruction |
