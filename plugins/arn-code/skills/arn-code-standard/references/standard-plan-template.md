# Standard Plan Template

This template defines the structure for `STANDARD_<name>.md` plan files written during the arn-code-standard workflow. Every standard plan includes the Spec-Lite section (architectural context captured from the architect agent) and the Implementation Tasks section (always present, unlike the swift simple path).

## Instructions for the Writer

When populating this template:
- Every section marked **(required)** MUST appear in the output
- Replace all bracketed placeholders with concrete content from the architect assessment and user description
- If information is missing for a section, write what is known and add the gap to Risks & Mitigations
- Tables should have real data, not example rows -- remove example rows if no data is available
- The Spec-Lite section captures the problem context and key requirements -- keep it concise
- Implementation Tasks are always present (standard tier always uses task-tracked execution)
- The Review-Lite section defines the post-execution review criteria

---

## Template

```markdown
# Standard Plan: [Title]

**Tier:** standard
**Scope:** [1-2 sentence summary from architect assessment]
**Architect assessment:** [Reference to key findings -- scope estimate, applicable patterns, concerns if any]

---

## Spec-Lite **(required)**

### Problem Statement

[1-2 sentences describing the problem being solved or the feature being added. Derived from the user's description and the architect's analysis.]

### Key Requirements

- [Requirement 1 -- concrete, verifiable]
- [Requirement 2]
- [Requirement 3]
[3-7 items. Each requirement should be testable.]

### Architectural Notes

[Notes from the architect agent about how this change fits into the existing architecture. Include: affected modules, integration points, patterns that must be followed, and any constraints. 2-5 sentences.]

---

## Files to Modify **(required)**

| File | Action | Rationale |
|------|--------|-----------|
| `path/to/file` | Create / Modify / Delete | [Why this file needs to change] |

---

## Patterns to Follow **(required)**

Patterns identified from `code-patterns.md` that apply to this change:

| Pattern | How It Applies |
|---------|---------------|
| [Pattern name from code-patterns.md] | [Specific guidance for this change] |

---

## Implementation Tasks **(required)**

Numbered tasks with clear deliverables. Each task should be independently executable and verifiable.

1. **[Task title]**
   - Files: `path/to/file1`, `path/to/file2`
   - What: [Concrete description of what to implement]
   - Pattern: [Which pattern to follow]
   - Depends on: [None | Task N]

2. **[Task title]**
   - Files: `path/to/file`
   - What: [Concrete description]
   - Pattern: [Which pattern to follow]
   - Depends on: [None | Task N]

[Continue as needed. Typically 3-8 tasks for standard changes.]

---

## Test Plan **(required)**

### Tests to Update

| Test File | What to Update | Why |
|-----------|---------------|-----|
| `path/to/test` | [Specific assertion or case to change] | [Reason -- new behavior, fixed behavior] |

### Tests to Add

These tests are written after implementation is complete. Each test follows the project's testing patterns (from testing-patterns.md).

| Test File | What to Test | Coverage Gap |
|-----------|-------------|-------------|
| `path/to/test` | [Scenario to cover] | [Why this test is needed] |

### Verification Command

```bash
[The specific test command to run -- e.g., pytest tests/test_specific.py -v]
```

---

## Risks & Mitigations **(required)**

| Risk | Severity | Mitigation |
|------|----------|-----------|
| [Risk from architect assessment or analysis] | Low / Medium / High | [How to mitigate] |

If no risks were identified: "None identified by architect assessment."

---

## Review-Lite **(required)**

Post-execution review criteria. The review uses the shared swift-review-checklist.md procedure.

| Check | What to Verify |
|-------|---------------|
| Pattern compliance | Spot-check modified files against patterns listed above |
| Test verification | All tests in the test plan pass |
| Architect concerns | All concerns from the architect assessment are addressed |
| Spec-Lite alignment | Implementation satisfies all key requirements listed in Spec-Lite |

---

## Notes

[Any additional context, related issues, or constraints. Remove this section if empty.]
```

---

## Section Guidance

| Section | Source | Required |
|---------|--------|----------|
| Title + metadata | User description + architect assessment | Yes |
| Spec-Lite | User description + architect assessment | Yes |
| Files to Modify | Architect assessment (file list) | Yes |
| Patterns to Follow | code-patterns.md + architect assessment | Yes |
| Implementation Tasks | Architect assessment (broken into tasks) | Yes |
| Test Plan | Architect assessment + testing-patterns.md | Yes |
| Risks & Mitigations | Architect assessment (concerns, risks) | Yes |
| Review-Lite | Shared swift-review-checklist.md | Yes |
| Notes | Conversation context | No |

## Sketch Annotation

When a sketch manifest has been loaded (componentMapping is available), add a "Sketch Source" column to the "Files to Modify" table:

| File | Action | Rationale | Sketch Source |
|------|--------|-----------|---------------|
| `src/components/ProfileForm.tsx` | Create | Profile editing form | `arness-sketches/settings/components/ProfileForm.tsx` (refine) |
| `src/components/NotificationToggle.tsx` | Create | Notification preferences | `arness-sketches/settings/components/NotificationToggle.tsx` (direct) |
| `src/utils/validation.ts` | Modify | Add form validators | -- |

Files without a sketch match show `--` in the Sketch Source column. If no `componentMapping` was loaded, omit the Sketch Source column entirely (standard plan format).
