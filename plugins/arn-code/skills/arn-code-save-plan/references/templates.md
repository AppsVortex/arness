# Plan Templates

Structures for transforming SOURCE_PLAN.md into the full project. All plans use the combined format: one file per phase with both implementation and testing sections.

Report templates are at the configured template path (see CLAUDE.md `## Arness` section) -- reference them, do not duplicate.

---

## INTRODUCTION.md

```markdown
# [Project Title]

## Project Overview

**Project Name:** [name]
**Description:** [1-2 sentences]
**Rationale:** [Why this project exists]

**Goals:**
1. [Goal 1]
2. [Goal 2]

---

## Architectural Definition

### High-Level Architecture

[ASCII diagram showing integration with existing system]

### Key Architectural Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| [Decision] | [Choice] | [Why] |

---

## Codebase Patterns

> Populated by arn-code-codebase-analyzer. Every pattern MUST have real file paths and code from the existing codebase.

### Pattern 1: [Name]

**Description:** [What and when to use]
**Reference Files:**
- `[source-root]/[module]/[file]:[lines]`

**Code Example (from codebase):**
\`\`\`python
# Actual snippet from reference file
class ExampleService:
    ...
\`\`\`

**How to apply:** [Concrete instructions for this project]

### Testing Pattern 1: [Name]

**Description:** [Test pattern and when to use]
**Reference Files:**
- `[source-root]/[module]/tests/[file].py`
- `[source-root]/docs/testing/[relevant].md`

**Code Example (from tests):**
\`\`\`python
[appropriate test markers]
class TestExampleService:
    def test_something(self, [test fixtures from INTRODUCTION.md]):
        ...
\`\`\`

**Test infrastructure available:** [From test infrastructure files — fixtures, factories, helpers, etc.]

> **Note:** If the source plan does not include testing, this section may be omitted or reduced to a brief note stating that the project relies on manual verification.

---

## Codebase References

| Area | File Path | Purpose |
|------|-----------|---------|
| [Area] | `[source-root]/[module]/[file]` | [Why] |
| Testing | `[source-root]/tests/` | Test infrastructure |
| Testing docs | `[source-root]/docs/testing/[type].md` | Patterns |

### Sketch Artifacts (if sketch exists)

> Include this subsection only when a arn-code-sketch session has produced validated components for this project. Omit entirely when no sketch exists.

**Sketch directory:** `[path to arness-sketches/<sketch-name>/]`
**Manifest:** `[path to arness-sketches/<sketch-name>/sketch-manifest.json]`
**Blueprint:** `[path to blueprint file]`

| Sketch File | Target Location | Mode | Status |
|-------------|----------------|------|--------|
| `[sketch component path]` | `[target file path]` | direct / refine | validated — promote as starting point |

---

## Scope & Boundaries

**In Scope:** [items]
**Out of Scope:** [items]

---

## Dependencies

**External:** [Libraries, services]
**Internal:** [Other modules/packages]

---

## Phase Overview

| Phase | Title | Dependencies |
|-------|-------|--------------|
| 1 | [Title] | None |
| 2 | [Title] | None |
| 3 | [Title] | Phase 1 |

If phase plans include Testing sections, add a "Test Deps (sequential chain)" column showing the dependency chain.

---

## Metadata

- **Created:** [Date]
- **Source plan:** SOURCE_PLAN.md
- **Specification:** [path to spec file, if found] or "None"
```

---

## PHASE_N_PLAN.md

```markdown
# Phase [N]: [Title]

**Project:** [PROJECT_NAME]
**Phase:** [N] of [Total]
**Prerequisites:** [Prior phases, or "None"]

---

## Implementation

### Directives

- DO NOT write full test suites — only simple validation tests
- Generate JSON report: Use the report template from the configured template path (see CLAUDE.md `## Arness` section)
- Save to: `<project-dir>/reports/IMPLEMENTATION_REPORT_PHASE_[N].json`
- If report exists, create new with timestamp suffix
- Follow codebase patterns from INTRODUCTION.md strictly

### Objectives

1. [Objective]

### Deliverables

| Deliverable | Path | Action |
|-------------|------|--------|
| [File] | `[source-root]/[module]/[file]` | Create/Modify |

### Tasks

#### IMPL-P[N]-001: [Title]

**What:** [What to implement]

**Follow pattern from** `[source-root]/[module]/[reference file]`:
- [Concrete instruction from codebase pattern]
- [Concrete instruction from codebase pattern]

**Files:**
- Create: `[source-root]/[module]/[new file]`
- Modify: `[source-root]/[module]/[existing file]` — [what to change]

**Details:**
[Class structure, method signatures, integration points.
Reference specific lines from existing code.]

### Acceptance Criteria

- [ ] [Criterion]
- [ ] Codebase patterns followed
- [ ] Implementation report generated

---

> Include the following Testing section only if the source plan specifies testing for this phase. If no testing is needed, end the phase plan after the Implementation Acceptance Criteria.

## Testing

### Directives

- Investigate implementation carefully before writing tests
- Generate JSON report: Use the report template from the configured template path (see CLAUDE.md `## Arness` section)
- Save to: `<project-dir>/reports/TESTING_REPORT_PHASE_[N].json`
- If report exists, create new with timestamp suffix
- DO NOT override existing test files
- If tests reveal implementation bugs: fix, document in report (prefix "FIXED:"), re-run
- Only mark complete when ALL tests pass

### Read Before Writing Tests

- Read the test infrastructure files listed in INTRODUCTION.md under Testing Patterns
- Review any project-specific test configuration and conventions
- Identify available fixtures, factories, and helpers before writing tests

### Test Patterns

**Follow** `[source-root]/[module]/tests/[reference file]`:
- Markers: `[appropriate test markers]`
- Fixtures: [test fixtures from INTRODUCTION.md]
- Async: follow project conventions (check INTRODUCTION.md)

### Test Cases

#### TEST-P[N]-001: [Name]

**Type:** unit | integration
**What:** [What is tested]

**Structure:**
\`\`\`
[appropriate test markers/decorators for the project's language]
[test class or function following project conventions]:
    [test method/function name](fixtures from INTRODUCTION.md):
        // Arrange / Act / Assert
\`\`\`

**Pass criteria:** [Expected outcome]

### Acceptance Criteria

- [ ] All tests passing
- [ ] Patterns followed (markers, fixtures)
- [ ] Testing report generated
- [ ] Bugs fixed and documented (if any)
```

---

## TASKS.md

```markdown
# [PROJECT_NAME] - Task List

## Implementation Tasks

### Task 1: Phase 1 Implementation - [Title]
**Project folder:** `<project-dir>`
**Plan:** `plans/PHASE_1_PLAN.md` (Implementation section)
**Dependencies:** None

Read INTRODUCTION.md. Execute Implementation section of PHASE_1_PLAN.md. Follow codebase patterns. Generate implementation report.

---

### Task 2: Phase 2 Implementation - [Title]
**Project folder:** `<project-dir>`
**Plan:** `plans/PHASE_2_PLAN.md` (Implementation section)
**Dependencies:** None

Read INTRODUCTION.md. Execute Implementation section of PHASE_2_PLAN.md. Follow codebase patterns. Generate implementation report.

---

### Task 3: Phase 3 Implementation - [Title]
**Project folder:** `<project-dir>`
**Plan:** `plans/PHASE_3_PLAN.md` (Implementation section)
**Dependencies:** Phase 1

Read INTRODUCTION.md. Execute Implementation section of PHASE_3_PLAN.md. Follow codebase patterns. Generate implementation report.

---

> Include the following Testing Tasks section only if any phase plans contain Testing sections. If no phases have testing, the task list contains only implementation tasks.

## Testing Tasks (Sequential)

### Task 4: Phase 1 Testing - [Title]
**Project folder:** `<project-dir>`
**Plan:** `plans/PHASE_1_PLAN.md` (Testing section)
**Dependencies:** Task 1

Read INTRODUCTION.md. Execute Testing section of PHASE_1_PLAN.md. Fix bugs if found (document in report). All tests must pass. Generate testing report.

---

### Task 5: Phase 2 Testing - [Title]
**Project folder:** `<project-dir>`
**Plan:** `plans/PHASE_2_PLAN.md` (Testing section)
**Dependencies:** Task 2, Task 4

Read INTRODUCTION.md. Execute Testing section of PHASE_2_PLAN.md. Fix bugs if found (document in report). All tests must pass. Generate testing report.

---

### Task 6: Phase 3 Testing - [Title]
**Project folder:** `<project-dir>`
**Plan:** `plans/PHASE_3_PLAN.md` (Testing section)
**Dependencies:** Task 3, Task 5

Read INTRODUCTION.md. Execute Testing section of PHASE_3_PLAN.md. Fix bugs if found (document in report). All tests must pass. Generate testing report.

[Repeat implementation and testing task pairs for each additional phase, maintaining the sequential dependency chain]
```
