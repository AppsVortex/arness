# Swift Plan Template

This template defines the structure for `SWIFT_<name>.md` plan files written during the arn-code-swift workflow. Both paths (simple and moderate) use this template, with the moderate path including the optional "Implementation Tasks" section.

## Instructions for the Writer

When populating this template:
- Every section marked **(required)** MUST appear in the output
- Replace all bracketed placeholders with concrete content from the architect assessment and user description
- If information is missing for a section, write what is known and add the gap to Risks & Mitigations
- Tables should have real data, not example rows -- remove example rows if no data is available
- For the simple path, omit the "Implementation Tasks" section (inline the work as a single execution block)
- For the moderate path, break the work into numbered tasks with clear deliverables

---

## Template

```markdown
# Swift Plan: [Title]

**Complexity:** [simple | moderate]
**Scope:** [1-2 sentence summary from architect assessment]
**Architect assessment:** [Reference to key findings -- scope estimate, applicable patterns, concerns if any]

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

## Implementation Tasks **(moderate path only)**

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

[Continue as needed. Typically 3-6 tasks for moderate changes.]

---

## Test Plan **(required)**

### Tests to Update

| Test File | What to Update | Why |
|-----------|---------------|-----|
| `path/to/test` | [Specific assertion or case to change] | [Reason -- new behavior, fixed behavior] |

### Tests to Add (Smoke Tests)

Smoke tests verify the new behavior works at a basic level. Keep them minimal — happy path + one edge case per change. These are NOT comprehensive test suites; they catch obvious breaks.

| Test File | What to Test | Type | Coverage Gap |
|-----------|-------------|------|-------------|
| `path/to/test` | [Scenario to cover] | smoke | [Why this test is needed] |

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

## Notes

[Any additional context, related issues, or constraints. Remove this section if empty.]
```

---

## Section Guidance

| Section | Source | Required |
|---------|--------|----------|
| Title + metadata | User description + architect assessment | Yes |
| Files to Modify | Architect assessment (file list) | Yes |
| Patterns to Follow | code-patterns.md + architect assessment | Yes |
| Implementation Tasks | Architect assessment (broken into tasks) | Moderate path only |
| Test Plan | Architect assessment + testing-patterns.md | Yes |
| Risks & Mitigations | Architect assessment (concerns, risks) | Yes |
| Notes | Conversation context | No |
