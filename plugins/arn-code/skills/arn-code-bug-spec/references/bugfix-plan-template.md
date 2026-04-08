# Bugfix Plan Template

This template defines the structure for bugfix plans written by the `arn-code-planner` agent during the `arn-code-bug-spec` workflow. The bugfix plan is written to the project folder as `FIX_PLAN.md` during the `arn-code-bug-spec` workflow's simple fix path (Step 6A).

## Instructions for arn-code-planner

When populating this template:
- Every section below MUST appear in the output, even if the content is brief
- Replace all bracketed placeholders with concrete content from the provided context
- If information is missing for a section, write what you know and add the gap to Open Items
- Tables should have real data, not example rows -- remove example rows if no data is available
- Phases should reflect the actual scope of the fix, not a generic breakdown

---

## Template

```markdown
# [Bug Fix Title]

## Bug Description
- **Symptom:** [what the user observes]
- **Severity:** [Low / Medium / High / Critical]
- **Affected area:** [module/component/endpoint]
- **Reproduction:** [steps or conditions to reproduce]

---

## Root Cause Analysis
- **Root cause:** [what is actually wrong, 2-4 sentences]
- **Evidence:** [file paths and line numbers supporting the diagnosis]
- **How it was introduced:** [if known -- recent change, original design flaw, dependency update, etc.]

---

## Impact Assessment

### Affected Files
| File | What's Wrong | Action Needed |
|------|-------------|---------------|
| `path/to/file` | [description] | [fix/modify/review] |

### Broader Impact
- **Affected functionality:** [what else is broken or degraded]
- **Data impact:** [any data corruption, integrity, or migration concerns]
- **User impact:** [who is affected and how]

---

## Fix Approach

### High-Level Strategy
[2-4 sentences: what the fix does and why this approach was chosen]

### Key Decisions
| Decision | Choice | Rationale |
|----------|--------|-----------|
| [Decision area] | [What was chosen] | [Why] |

### Components to Change
| Component | Action | File(s) | What Changes |
|-----------|--------|---------|-------------|
| [Component name] | Create / Modify | `path/to/file` | [Description] |

### Integration Points
- [Where the fix connects to existing code, with file paths]

---

## Regression Prevention
- **Test gaps:** [what tests were missing that allowed this bug]
- **Tests to fix:**

| Test File | Current Assertion | Correct Assertion |
|-----------|-------------------|-------------------|
| `path/to/test` | [what it asserts now] | [what it should assert] |

- **New tests needed:**

| Test | What It Covers | Why It Was Missing |
|------|---------------|-------------------|
| [test name] | [scenario] | [reason] |

- **Existing tests to verify:** [tests that should still pass after the fix -- confirms no regression]
- **Monitoring:** [any alerts, logging, or observability to add]

---

## Scope & Boundaries

**In Scope:**
- [What this fix includes]

**Out of Scope:**
- [What this fix explicitly does NOT include -- related improvements deferred]

---

## Dependencies

**External:**
- [Libraries, services, or APIs this fix depends on]

**Internal:**
- [Existing modules or components this fix builds on]

**Prerequisites:**
- [What must exist or be completed before this fix can be applied]

---

## Phases

### Phase 1: [Title]

**Deliverables:**
- [Concrete deliverable 1]
- [Concrete deliverable 2]

**Depends on:** None

[Add more phases as needed. Simple fixes may have only one phase.]

---

## Open Items
- [Unresolved question or decision needed]
- [Risk that needs monitoring or mitigation]
- [Area that needs more investigation]

---

## Notes
[Any additional context, links, related issues, or conversation highlights. Remove this section if empty.]
```

---

## Section Guidance

| Section | Source | Depth |
|---------|--------|-------|
| Bug Description | User's bug report + investigator findings | 4 fields, keep factual |
| Root Cause Analysis | arn-code-investigator output | 2-4 sentences + evidence |
| Impact Assessment | arn-code-investigator scope assessment | Tables + bullets |
| Fix Approach | arn-code-architect proposals + conversation decisions | Tables + 2-4 sentences strategy |
| Regression Prevention | arn-code-investigator Test Coverage Assessment | Tables for tests to fix/add |
| Scope & Boundaries | Conversation decisions | 2-5 bullets per subsection |
| Dependencies | arn-code-architect proposals + pattern docs | Brief -- list format |
| Phases | Conversation + arn-code-architect proposals | 2-5 deliverables per phase |
| Open Items | Accumulated from conversation | All unresolved items |
| Notes | Conversation highlights | Optional, keep brief |

---

## Save-Plan Compatibility Mapping

**Note:** This template is used for the simple fix path's optional small plan (arn-code-bug-spec Step 6A). For complex bugs, a specification document is written instead, and the plan is generated via `/arn-code-plan`.

This mapping is provided for reference in case the user later decides to feed the FIX_PLAN.md into `arn-code-save-plan` for a more structured execution. In the typical simple path, the plan is executed directly. The following mapping shows how sections correspond:

| Bugfix Template Section | Maps To (INTRODUCTION.md) | Notes |
|------------------------|---------------------------|-------|
| Bug Description | Project Overview | Symptom becomes Description, Severity appended to Rationale |
| Root Cause Analysis | Architectural Definition (partial) | Root cause + evidence becomes the architectural context |
| Impact Assessment | Architectural Definition (partial) | Affected files/functionality informs the scope |
| Fix Approach | Architectural Definition | High-Level Strategy maps to High-Level Architecture, Key Decisions maps to Key Architectural Decisions table |
| Regression Prevention | Testing Patterns (supplement) | Test gaps and new tests feed into phase plan testing sections |
| Scope & Boundaries | Scope & Boundaries | Direct mapping |
| Dependencies | Dependencies | Direct mapping |
| Phases | Phase Overview | Direct mapping |
| Open Items | (preserved as-is) | Carried into phase plans |

This mapping ensures arn-code-save-plan can consume the bugfix plan as SOURCE_PLAN.md without modification to save-plan itself.
