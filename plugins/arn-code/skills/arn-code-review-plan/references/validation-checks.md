# Validation Checks

Comprehensive checklist for reviewing a structured project plan. Run every check and collect issues.

---

## 1. Structural Completeness

### Files Present

| Check | Severity | What |
|-------|----------|------|
| S001 | ERROR | `INTRODUCTION.md` exists in `<project-dir>/` |
| S002 | ERROR | `TASKS.md` exists in `<project-dir>/` |
| S003 | ERROR | `SOURCE_PLAN.md` exists in `<project-dir>/` |
| S004 | WARNING | `PROGRESS_TRACKER.json` exists in `<project-dir>/` |
| S005 | ERROR | `plans/` directory exists and contains at least one `PHASE_*.md` file |
| S006 | ERROR | `reports/` directory exists in `<project-dir>/` |

### Phase File Consistency

| Check | Severity | What |
|-------|----------|------|
| S010 | ERROR | Phase Overview table in INTRODUCTION.md lists N phases — verify exactly N `PHASE_N_PLAN.md` files exist |
| S011 | ERROR | Phase numbering is sequential (no gaps: 1, 2, 3 — not 1, 3, 4) |
| S012 | WARNING | Every phase mentioned in TASKS.md has a corresponding `PHASE_N_PLAN.md` |

---

## 2. INTRODUCTION.md Quality

### Required Sections

| Check | Severity | What |
|-------|----------|------|
| I001 | ERROR | Has "Project Overview" section with name, description, rationale |
| I002 | ERROR | Has "Architectural Definition" section |
| I003 | ERROR | Has "Codebase Patterns" section with at least one pattern |
| I004 | ERROR | Has "Codebase References" section with file paths |
| I005 | WARNING | Has "Scope & Boundaries" section |
| I006 | WARNING | Has "Dependencies" section |
| I007 | ERROR | Has "Phase Overview" section |

### Pattern Quality

| Check | Severity | What |
|-------|----------|------|
| I010 | ERROR | Each codebase pattern has a real file path (not placeholder like `[app]` or `[file]`) |
| I011 | ERROR | Each codebase pattern has a code example (not TODO or empty) |
| I012 | WARNING | Each codebase pattern has "How to apply" instructions |
| I013 | WARNING | At least one testing pattern exists with fixtures or helpers listed |
| I014 | WARNING | Testing pattern references are consistent with stored testing-patterns.md |

### Codebase Reference Verification

| Check | Severity | What |
|-------|----------|------|
| I020 | ERROR | File paths in "Codebase References" table actually exist on disk |
| I021 | WARNING | Code examples in patterns match what's actually in the referenced files (spot-check 2-3) |
| I022 | WARNING | Referenced test fixtures actually exist (grep fixture names in test files) |
| I023 | WARNING | Referenced test factories or helpers actually exist |

---

## 3. Phase Plan Quality (check each PHASE_N_PLAN.md)

### Implementation Section

| Check | Severity | What |
|-------|----------|------|
| P001 | ERROR | Has "Implementation" section |
| P002 | ERROR | Has "Directives" subsection with report template reference |
| P003 | ERROR | Has at least one implementation task (IMPL-PN-XXX) |
| P004 | ERROR | Each task has file paths (Create/Modify lines) — not placeholders |
| P005 | WARNING | Each task references a codebase pattern from INTRODUCTION.md |
| P006 | WARNING | Has "Acceptance Criteria" with checkboxes |
| P007 | ERROR | Report save path matches convention: `reports/IMPLEMENTATION_REPORT_PHASE_N.json` |

### Testing Section

> These checks apply only to phase plans that include a Testing section. Phases without testing are valid — skip these checks for those phases.

| Check | Severity | What |
|-------|----------|------|
| P010 | ERROR | Has "Testing" section (if the phase plan includes testing) |
| P011 | ERROR | Has "Directives" subsection including self-healing directive (fix bugs, document, re-run) |
| P012 | ERROR | Has "Read Before Writing Tests" list that references test infrastructure from INTRODUCTION.md |
| P013 | ERROR | Has at least one test case (TEST-PN-XXX) |
| P014 | ERROR | Each test case has a Type (unit/integration) |
| P015 | WARNING | Each test case has appropriate markers/tags from testing patterns |
| P016 | WARNING | Each test case has a code structure example showing class/method pattern |
| P017 | WARNING | Test cases reference specific fixtures from the test infrastructure |
| P018 | ERROR | Report save path matches convention: `reports/TESTING_REPORT_PHASE_N.json` |

### Cross-References

| Check | Severity | What |
|-------|----------|------|
| P020 | WARNING | Phase plan references INTRODUCTION.md for patterns |
| P021 | WARNING | Phase prerequisites match the dependency graph in TASKS.md |

---

## 4. TASKS.md Consistency

### Structure

| Check | Severity | What |
|-------|----------|------|
| T001 | ERROR | Has "Implementation Tasks" section |
| T002 | ERROR | Has "Testing Tasks" section (required only if any phase plan contains a Testing section) |
| T003 | ERROR | Each task has: title, project folder, plan file reference, dependencies line |
| T004 | ERROR | Plan file references in tasks match actual files in `plans/` |

### Dependency Graph

| Check | Severity | What |
|-------|----------|------|
| T010 | ERROR | No circular dependencies (Task A blocks Task B blocks Task A) |
| T011 | ERROR | Every testing task depends on its corresponding implementation task (applies only when testing tasks exist) |
| T012 | ERROR | Testing tasks form a sequential chain (applies only when testing tasks exist) |
| T013 | ERROR | Dependencies reference valid task numbers (no dangling refs like "Task 9" when only 6 tasks exist) |

### Coverage

| Check | Severity | What |
|-------|----------|------|
| T020 | ERROR | Every `PHASE_N_PLAN.md` has at least one implementation task in TASKS.md |
| T021 | ERROR | Every `PHASE_N_PLAN.md` that has a Testing section has at least one testing task in TASKS.md |
| T022 | WARNING | For phases with testing, number of implementation tasks matches number of testing tasks (1:1 per phase) |

---

## 5. Pattern Compliance (Dynamic)

Pattern compliance checks are built dynamically from the stored pattern documentation at runtime. The review skill reads `code-patterns.md`, `testing-patterns.md`, and `ui-patterns.md` (when present) from the project's configured Code patterns path and generates checks based on the patterns found there.

See SKILL.md Step 4 for the dynamic pattern compliance process.

This section intentionally contains no static checks — all pattern checks are framework-specific and derived from the project's own documentation.

---

## 6. Report Template Alignment

| Check | Severity | What |
|-------|----------|------|
| R001 | WARNING | Implementation report path in phase plans matches `IMPLEMENTATION_REPORT_TEMPLATE.json` structure |
| R002 | WARNING | Testing report path in phase plans matches `TESTING_REPORT_TEMPLATE.json` structure |
| R003 | INFO | `PROGRESS_TRACKER.json` has one entry per phase, each with valid `taskId` values matching TASKS.md task numbers |
| R004 | WARNING | Review report path matches `REVIEW_REPORT_TEMPLATE.json` structure |

---

## 7. Content Quality (Heuristics)

| Check | Severity | What |
|-------|----------|------|
| Q001 | ERROR | No TODO, FIXME, or placeholder text (`[TODO]`, `[Name]`, `[app]`) in any plan file |
| Q002 | WARNING | Implementation tasks have enough detail for an agent to execute without guessing (at least 3 lines of description per task) |
| Q003 | WARNING | Test cases have enough detail for an agent to write tests (structure example or clear assertions) |
| Q004 | INFO | Phase plans are reasonably sized (flag phases with more than 10 implementation tasks — consider splitting) |
| Q005 | INFO | Phases are reasonably balanced (flag if one phase has 8 tasks and another has 1) |

---

## 8. Security Validation (Conditional)

> These checks apply only when `security-patterns.md` exists in the project's code patterns directory. If no security pattern documentation exists, skip this entire section.

| Check | Severity | What |
|-------|----------|------|
| SEC01 | WARNING | Plans for features involving authentication or authorization include security-related acceptance criteria (e.g., auth checks, permission validation, session handling) |
| SEC02 | WARNING | Plans for features handling user input reference an input validation approach (schema validation, parameterized queries, sanitization) |
| SEC03 | WARNING | Plans for features handling sensitive data (passwords, tokens, PII, payment info) document a data protection approach (hashing, encryption, secure storage) |
