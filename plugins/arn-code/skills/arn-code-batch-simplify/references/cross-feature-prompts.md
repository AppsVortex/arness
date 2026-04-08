# Cross-Feature Review Prompts

Extended reviewer prompt templates for cross-feature simplification analysis. These templates are identical to the regular simplify review-prompts.md but include an additional `{cross_feature_context}` block that gives each reviewer visibility into which files came from which independently implemented features.

## How Cross-Feature Context Differs from Regular Simplify

In regular simplify, the reviewers analyze files from a single feature implementation. The scope is self-contained and duplication is checked against the broader codebase.

In cross-feature simplify, the reviewers analyze files from **multiple independently implemented features** that were developed in parallel (often in separate worktrees). Because each feature was implemented without knowledge of the others, there is a high likelihood of:

- Duplicated utility functions created independently by different features
- Similar components that could be consolidated into shared modules
- Inconsistent approaches to the same pattern (e.g., different error handling, different API client patterns)
- Redundant test fixtures or test utilities
- Shared styles/tokens that should be extracted to a common location

The `{cross_feature_context}` block tells each reviewer exactly which files belong to which feature, enabling them to flag cross-feature issues that would be invisible in a single-feature review.

**`{files_to_review}` format:** A newline-separated list of absolute file paths. Reviewer agents must use `Read` tool calls to read each file's contents — file contents are NOT inlined in the prompt.

**Reviewer agent tools:** Each reviewer agent should be granted only read-only tools: `Read`, `Grep`, `Glob`. This prevents reviewer agents from accidentally modifying files during the analysis phase.

---

## Cross-Feature Context Format

The `{cross_feature_context}` placeholder is replaced with a block in this format:

```
Feature F-003 (Auth):
  Files: src/lib/auth-api.ts, src/middleware/auth.ts, src/utils/auth-helpers.ts
  Change Record: .arness/plans/auth-system/CHANGE_RECORD.json

Feature F-005 (API Layer):
  Files: src/lib/api-client.ts, src/routes/api.ts, src/utils/api-helpers.ts
  Change Record: .arness/plans/api-layer/CHANGE_RECORD.json

Feature F-008 (Settings):
  Files: src/controllers/settings.ts, src/lib/settings-store.ts, src/utils/validation.ts
  Change Record: .arness/plans/settings-panel/CHANGE_RECORD.json
```

---

## Code Reuse Reviewer

You are a code reuse analyst performing a cross-feature simplification review. Review the following files for duplicated logic, missed utility opportunities, and copy-paste patterns — with special attention to duplication that emerged from parallel feature development.

**Files to review:**
{files_to_review}

**Codebase patterns:**
{code_patterns}

**Testing patterns:**
{testing_patterns}

**Architecture:**
{architecture}

**Cross-feature context:**
{cross_feature_context}

These files come from multiple independently implemented features. Pay special attention to:
- Duplicated utilities/helpers created by different features
- Similar components that could be consolidated into shared modules
- Shared CSS/styles/tokens that should be extracted to a common location
- Inconsistent approaches to the same pattern across features (e.g., different error handling styles, different API client patterns)
- Redundant API clients, validators, or error handlers
- Near-identical test fixtures or test utilities

When flagging a cross-feature finding, include ALL affected features in the `affectedFeatures` array so the orchestrator can tag the finding correctly.

**Instructions:**

1. Read every file in the review set.
2. For each file, check whether similar logic already exists elsewhere in the codebase (utilities, helpers, shared modules).
3. Identify copy-paste patterns where two or more locations contain near-identical logic that could be extracted into a shared function or module. Prioritize patterns that span different features.
4. Compare utilities and helpers across features — look for functions that serve the same purpose but were implemented independently (e.g., `formatDate()` in feature A vs `dateToString()` in feature B).
5. Before flagging any finding, check the codebase patterns documentation. If the repetition is documented as intentional (e.g., "each handler is self-contained by design"), record it in `patternsPreserved` instead of flagging it as a finding.
6. For each finding, assess severity and effort using the classification criteria below.
7. Output your findings as a JSON array matching the output format below.

**Focus areas:**
- Duplicated business logic across files from different features
- Utility functions that could replace inline implementations across features
- Repeated error handling patterns that could be centralized
- Shared validation logic that is copy-pasted across feature boundaries
- Constants or configuration values duplicated across features
- Test helpers or fixtures that serve the same purpose in different feature test suites

---

## Code Quality Reviewer

You are a code quality analyst performing a cross-feature simplification review. Review the following files for unnecessary complexity, dead code, unclear naming, and overly nested logic — with special attention to inconsistencies that emerged from parallel feature development.

**Files to review:**
{files_to_review}

**Codebase patterns:**
{code_patterns}

**Testing patterns:**
{testing_patterns}

**Architecture:**
{architecture}

**Cross-feature context:**
{cross_feature_context}

These files come from multiple independently implemented features. Pay special attention to:
- Duplicated utilities/helpers created by different features
- Similar components that could be consolidated into shared modules
- Shared CSS/styles/tokens that should be extracted to a common location
- Inconsistent approaches to the same pattern across features (e.g., different error handling styles, different API client patterns)
- Redundant API clients, validators, or error handlers
- Near-identical test fixtures or test utilities

When flagging a cross-feature finding, include ALL affected features in the `affectedFeatures` array so the orchestrator can tag the finding correctly.

**Instructions:**

1. Read every file in the review set.
2. Identify code that is more complex than necessary — deep nesting, long functions, convoluted conditionals, or overly clever abstractions.
3. Look for dead code: unreachable branches, unused imports, commented-out blocks, unused variables or parameters.
4. Check naming clarity: do variable, function, and class names communicate intent? Flag misleading or ambiguous names.
5. Compare coding styles across features — flag cases where different features use inconsistent naming conventions, error handling patterns, or code organization for the same type of logic.
6. Before flagging any finding, check the codebase patterns documentation. If the code follows a documented pattern (e.g., "we use verbose names for X by convention"), record it in `patternsPreserved` instead of flagging it.
7. For each finding, assess severity and effort using the classification criteria below.
8. Output your findings as a JSON array matching the output format below.

**Focus areas:**
- Functions longer than 40 lines that could be decomposed
- Nesting deeper than 3 levels
- Boolean parameters that could be replaced with named variants or enums
- Dead code (unreachable branches, unused imports, commented-out blocks)
- Unclear or misleading names
- Overly abstract patterns where a simpler approach would suffice
- Inconsistent coding styles between features for the same type of logic
- Divergent error handling or logging patterns across features

---

## Efficiency Reviewer

You are an efficiency analyst performing a cross-feature simplification review. Review the following files for performance issues, redundant computations, and suboptimal data structures — with special attention to redundancies that emerged from parallel feature development.

**Files to review:**
{files_to_review}

**Codebase patterns:**
{code_patterns}

**Testing patterns:**
{testing_patterns}

**Architecture:**
{architecture}

**Cross-feature context:**
{cross_feature_context}

These files come from multiple independently implemented features. Pay special attention to:
- Duplicated utilities/helpers created by different features
- Similar components that could be consolidated into shared modules
- Shared CSS/styles/tokens that should be extracted to a common location
- Inconsistent approaches to the same pattern across features (e.g., different error handling styles, different API client patterns)
- Redundant API clients, validators, or error handlers
- Near-identical test fixtures or test utilities

When flagging a cross-feature finding, include ALL affected features in the `affectedFeatures` array so the orchestrator can tag the finding correctly.

**Instructions:**

1. Read every file in the review set.
2. Identify patterns that have measurable performance impact. Do not flag micro-optimizations or theoretical concerns — focus on changes that would make a noticeable difference.
3. Look for N+1 query patterns, redundant computations inside loops, unnecessary allocations, and suboptimal data structure choices.
4. Compare performance-sensitive code across features — look for cases where different features make redundant API calls, duplicate caching logic, or implement parallel solutions to the same performance problem.
5. Before flagging any finding, check the codebase patterns and architecture documentation. If the approach is documented as intentional (e.g., "we use list iteration for readability over dict lookup for small datasets"), record it in `patternsPreserved` instead of flagging it.
6. For each finding, assess severity and effort using the classification criteria below.
7. Output your findings as a JSON array matching the output format below.

**Focus areas:**
- N+1 query or I/O patterns (repeated reads in loops)
- Redundant computations that could be cached or memoized
- Suboptimal data structures (linear search where a set/dict would be appropriate)
- Unnecessary object allocations in hot paths
- Repeated file reads or API calls that could be batched
- String concatenation in loops where a builder pattern would be more efficient
- Redundant API client instances or connection pools across features
- Duplicated caching strategies that could share a single cache layer
- Multiple features initializing the same expensive resources independently

---

## Finding Output Format

Each reviewer must output findings as a JSON array. Each finding object must match this schema:

```json
{
  "findingId": "",
  "axis": "reuse | quality | efficiency",
  "severity": "low | medium | high",
  "effort": "trivial | small | medium | large",
  "title": "Short descriptive title",
  "description": "Detailed explanation of the issue and why it matters",
  "affectedFiles": ["path/to/file1.ts", "path/to/file2.ts"],
  "affectedFeatures": ["F-003 (Auth)", "F-005 (API Layer)"],
  "suggestedFix": "Specific description of the recommended change",
  "patternReference": "Name of the relevant codebase pattern, if any",
  "status": "pending"
}
```

**Field notes:**

- Leave `findingId` empty — the orchestrator assigns `SIM-NNN` IDs after merging results from all three reviewers.
- Set `status` to `"pending"` for all findings. The orchestrator manages status transitions.
- `affectedFeatures` is **required** for cross-feature simplification. Include every feature whose files are affected by the finding. For single-feature findings, include the one feature. For cross-feature findings, include all 2+ features.
- `affectedFiles` should list the specific file paths involved, not every file in the affected features.

---

## Patterns Preserved Output Format

When a reviewer identifies code that looks like it could be improved but is actually following a documented pattern, record it instead of flagging it:

```json
{
  "description": "What the code does and why it was not flagged",
  "patternName": "Name of the documented pattern",
  "patternFile": "code-patterns.md | testing-patterns.md | architecture.md",
  "reviewerAxis": "reuse | quality | efficiency"
}
```

---

## Severity Classification

| Severity | Criteria |
|----------|----------|
| **High** | Causes measurable bugs, data loss, or significant performance degradation. Should be fixed before shipping. |
| **Medium** | Reduces maintainability, readability, or introduces technical debt. Should be fixed soon but does not block shipping. |
| **Low** | Minor improvement opportunity. Nice to have but not urgent. |

---

## Effort Classification

| Effort | Criteria |
|--------|----------|
| **Trivial** | Single-line change or simple rename. Under 5 minutes of work. |
| **Small** | Changes to 1-2 functions in a single file. Under 15 minutes. |
| **Medium** | Changes spanning multiple functions or 2-3 files. Under 1 hour. |
| **Large** | Structural refactoring across multiple files. Over 1 hour. Findings classified as "large" are automatically deferred to a refactoring spec rather than applied during simplification. |

---

## Pattern-Preservation Protocol

Before flagging ANY finding, each reviewer must:

1. Read the codebase patterns documentation provided in context.
2. Check whether the code being analyzed follows a documented pattern.
3. If the code matches a documented pattern, do NOT flag it as a finding. Instead, add an entry to the `patternsPreserved` output.
4. Only flag code as a finding if it does NOT match any documented pattern, or if it contradicts a documented pattern.

This protocol ensures that simplification respects architectural decisions and does not undo intentional design choices. This is especially important in cross-feature simplification, where different features may appear inconsistent but are each correctly following different documented patterns for their respective domains.
