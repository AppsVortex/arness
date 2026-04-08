# Complexity Criteria

Six criteria for assessing whether a change is simple, moderate, or complex. Each criterion is rated independently, then the ratings are combined using the routing rules at the bottom.

This assessment is internal -- do not present it as a formal step to the user. Use the architect's assessment from Step 2 as the primary input.

---

## Criterion 1: File Count

How many files need to be created or modified (excluding test files)?

| Level | Threshold | Examples |
|-------|-----------|---------|
| Simple | 1-3 files | Add a utility function to an existing module; update a single API endpoint; change a configuration value and its consumer |
| Moderate | 4-8 files | Add a new API endpoint with route, controller, service, and model changes; refactor a shared component used in several places; add a feature flag with toggles in multiple modules |
| Complex | 9+ files | Add a new domain entity with full CRUD stack; implement a cross-cutting concern like audit logging; redesign a data model with migrations and dependent code |

---

## Criterion 2: Architectural Changes

Does the change introduce new abstractions, patterns, or interfaces?

| Level | Threshold | Examples |
|-------|-----------|---------|
| Simple | None | Use existing patterns exactly as documented; add a method to an existing class following the established pattern; update an existing configuration |
| Moderate | Minor adjustments | Extend an existing interface with a new method; add a new implementation of an existing pattern; introduce a new enum or type that fits existing type hierarchies |
| Complex | New abstractions or patterns | Introduce a new design pattern not yet in the codebase; create a new abstraction layer (e.g., repository pattern where none exists); change a fundamental interface contract |

---

## Criterion 3: Cross-Cutting Concerns

How many distinct modules, layers, or bounded contexts does the change touch?

| Level | Threshold | Examples |
|-------|-----------|---------|
| Simple | Single module | Change stays within one module/package; modify a single service and its direct tests; update a single UI component |
| Moderate | 2-3 modules | Change spans frontend and backend; modify a service and its API layer; update a shared library and two consumers |
| Complex | System-wide (4+ modules) | Change touches API, service, data, and UI layers; modify core infrastructure used by all modules; update a shared contract affecting multiple services |

---

## Criterion 4: Test Work

How much test creation or modification is needed?

| Level | Threshold | Examples |
|-------|-----------|---------|
| Simple | 1-3 test updates or additions | Add a test case to an existing test file; update assertions in 2 existing tests; add one new test file for a new utility |
| Moderate | 4-8 test updates or additions | Add test cases across 3-4 test files; create 2 new test files; update existing integration tests plus add unit tests |
| Complex | New test infrastructure | Need new test fixtures, factories, or helpers; require new test configuration (database seeding, mock servers); need to set up a new testing pattern not yet in the project |

---

## Criterion 5: UI Scope

What is the scope of user interface changes (if any)?

| Level | Threshold | Examples |
|-------|-----------|---------|
| Simple | No UI, or minor tweak | Change a label or color; adjust padding/margin; fix a display bug; add a tooltip |
| Moderate | New component or significant modification | Add a new form with validation; create a new modal or dialog; add a new section to an existing page; implement a new interactive widget |
| Complex | New page or flow | Add a new route/page with navigation; implement a multi-step wizard; create a new dashboard with multiple widgets; redesign an existing page layout |

---

## Criterion 6: Risk Level

How easily can the change be reversed if something goes wrong?

| Level | Threshold | Examples |
|-------|-----------|---------|
| Simple | Low risk, easily reversible | Add-only changes (new functions, new files); changes behind a feature flag; configuration changes with clear rollback |
| Moderate | Medium risk | Modify existing behavior that other code depends on; change API response format with versioning; update database queries that could affect performance |
| Complex | High risk | Data migrations that alter existing data; breaking API changes without versioning; changes to authentication or authorization logic; modifications to payment or billing flows |

---

## Routing Rules

After rating each criterion, apply these rules to determine the path:

### Simple Path (Step 4A)
- **5-6 criteria rated "simple"** AND the architect did not flag concerns
- The change is small, contained, and follows existing patterns

### Moderate Path (Step 4B)
- **3-4 criteria rated "simple"** (remaining are moderate), OR
- The architect flagged non-blocking concerns (e.g., "watch out for X" but no architectural risk), OR
- **Any single criterion rated "complex"** but the rest are simple/moderate (isolated complexity)

### Complex Redirect (Step 4C)
- **3 or more criteria rated "complex"**, OR
- The architect flagged architectural risk (new patterns needed, fundamental design questions), OR
- The change cannot be described in a concise plan (indicates underspecified requirements)

### Edge Cases

- **Borderline simple/moderate:** Default to moderate. The overhead of task tracking is small, and the structure helps catch issues.
- **Borderline moderate/complex:** Present the assessment to the user: "This is on the edge of what swift can handle. I can proceed with the moderate path, but there's a risk of missing architectural considerations. Would you prefer the full pipeline?" If the user chooses swift, proceed with moderate path plus a warning.
- **User override:** If the user explicitly requests a specific path ("just do the simple path"), honor the request but add a warning to the report if the assessment disagrees.
