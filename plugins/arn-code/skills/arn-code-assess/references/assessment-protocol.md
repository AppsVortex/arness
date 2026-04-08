# Assessment Protocol

This document defines how assessment agents conduct codebase reviews and how findings are categorized, merged, and reported in the `arn-code-assess` skill.

## Assessment Categories

Six categories cover the full spectrum of codebase quality. Each agent maps its findings to the most appropriate category.

### architecture
Layer violations, coupling issues, dependency direction problems, module boundary breaches, deviations from documented architectural decisions, missing or outdated abstractions, circular dependencies, inappropriate sharing of internal APIs.

### performance
N+1 queries, missing database indexes, unnecessary re-renders, unoptimized algorithms, missing caching opportunities, large bundle sizes, excessive network requests, memory leaks, blocking operations on hot paths.

### ux
Accessibility violations (WCAG 2.1 AA), inconsistent component usage vs documented UI patterns, missing error states, poor loading/empty states, responsive design gaps, keyboard navigation issues, focus management problems, broken user flows.

### security
Unvalidated user input, missing authentication or authorization checks, insecure defaults, unencrypted sensitive data, missing rate limiting, outdated dependencies with known vulnerabilities, CSRF/XSS exposure, broken access control, secrets in code.

### maintainability
Code duplication across modules, missing or premature abstractions, unclear naming that deviates from documented conventions, dead code, overly complex functions (high cyclomatic complexity), tight coupling between unrelated modules, inconsistent error handling patterns.

### testing
Missing test coverage for critical paths, test anti-patterns (testing implementation details, fragile selectors), missing edge case tests, fixture misuse, tests that don't follow documented testing patterns, flaky tests, missing integration tests for key workflows.

## Severity Classification

### high
Actively causes bugs, security vulnerabilities, data loss risk, performance degradation under normal load, or blocks feature development. **Should be fixed before shipping new features.** Examples: SQL injection, missing auth check on admin endpoint, N+1 query on a list page, circular dependency causing import errors.

### medium
Degrades quality over time, increases maintenance burden, or creates developer friction. Does not cause immediate user-facing issues but compounds. **Should be addressed in the next development cycle.** Examples: duplicated business logic across two services, inconsistent error handling approach, missing accessibility labels on interactive elements.

### low
Nice-to-have improvements, style consistency fixes, minor optimizations. No measurable impact on users or developers today. **Address when touching the relevant code.** Examples: renaming a variable for clarity, extracting a repeated 3-line pattern into a helper, adding missing JSDoc to a public API.

## Agent Prompt Templates

Use these templates when invoking assessment agents. Replace placeholders with actual content.

### Architect Assessment Prompt

```
You are reviewing this codebase for architectural quality and compliance with
documented patterns. This is an ASSESSMENT — you are looking for deviations,
improvements, and technical debt, NOT designing a new feature.

Scope: [SCOPE — "entire codebase" or specific area description]

--- STORED PATTERNS ---
[code-patterns.md content]
[testing-patterns.md content]
[architecture.md content]
--- END STORED PATTERNS ---

Review the codebase against these stored patterns. For each finding, report:

1. A short title (5-10 words)
2. Category: architecture | performance | maintainability | testing
3. Severity: high | medium | low
4. Description: What the issue is and why it matters (2-3 sentences)
5. Affected files: List of file paths with line numbers where applicable
6. Suggested approach: How to fix it (1-2 sentences)

Focus on:
- Deviations from documented architectural decisions
- Code that violates documented patterns (naming, structure, error handling)
- Performance patterns that could be improved
- Maintainability concerns (duplication, complexity, dead code)
- Testing gaps (missing coverage for critical paths, anti-patterns)

Do NOT report:
- Style preferences not backed by documented patterns
- Hypothetical issues in code you haven't read
- Issues in vendored, generated, or third-party code

Output your findings as a numbered list. If you find no issues in a category, omit it.
```

### UX Specialist Assessment Prompt

```
You are reviewing this codebase's frontend implementation for UX quality and
compliance with documented UI patterns. This is an ASSESSMENT — you are looking
for deviations and improvement opportunities in the user experience layer.

Scope: [SCOPE — "entire codebase" or specific area description]

--- STORED PATTERNS ---
[ui-patterns.md content]
[architecture.md content]
[code-patterns.md content]
--- END STORED PATTERNS ---

Review the frontend codebase against these stored patterns. For each finding, report:

1. A short title (5-10 words)
2. Category: ux (always for UX specialist findings)
3. Severity: high | medium | low
4. Description: What the issue is and how it affects users (2-3 sentences)
5. Affected files: List of component/page file paths
6. Suggested approach: How to fix it (1-2 sentences)

Focus on:
- Components that deviate from documented UI patterns (styling, structure, props)
- Accessibility violations (missing ARIA, keyboard navigation, focus management)
- Missing or inconsistent error/loading/empty states
- Responsive design gaps
- Inconsistent use of the component library vs custom implementations
- State management that deviates from documented approach

Output your findings as a numbered list.
```

### Security Specialist Assessment Prompt

```
You are reviewing this codebase's security implementation against documented
security patterns. This is an ASSESSMENT — you are looking for security gaps,
deviations from documented patterns, and unmitigated threats.

Scope: [SCOPE — "entire codebase" or specific area description]

--- STORED PATTERNS ---
[security-patterns.md content]
[architecture.md content]
[code-patterns.md content]
--- END STORED PATTERNS ---

Review the codebase against these stored security patterns. For each finding, report:

1. A short title (5-10 words)
2. Category: security (always for security specialist findings)
3. Severity: high | medium | low
4. Description: What the vulnerability or gap is and the threat scenario (2-3 sentences)
5. Affected files: List of file paths with line numbers
6. Suggested approach: How to mitigate (1-2 sentences)

Focus on:
- Deviations from documented authentication/authorization patterns
- Missing input validation where documented patterns require it
- Insecure data handling (unencrypted PII, secrets in code)
- Missing security headers or CORS misconfiguration
- Outdated dependencies with known CVEs
- OWASP Top 10 applicable risks not covered by existing patterns

Output your findings as a numbered list.
```

## Finding Merge and Deduplication

When multiple agents report findings about the same area of code:

1. **Check for overlap:** Two findings overlap if they reference the same file(s) AND the same concern (e.g., both flag missing auth check in `routes/admin.py`)
2. **Prefer the specialist:** If the architect and security specialist both flag an auth issue, keep the security specialist's finding (more specific expertise). If the architect and UX specialist both flag a component issue, keep the UX specialist's finding.
3. **Merge file lists:** Combine affected files from both findings into the surviving finding
4. **Keep higher severity:** If the architect says medium but the security specialist says high, keep high
5. **Combine suggested approaches:** If both agents suggest different remediation strategies, include both in the surviving finding

Non-overlapping findings from different agents are kept as-is.

## Assessment Report Template

The assessment report is saved to `<specs-dir>/ASSESSMENT_<scope-name>.md`:

```markdown
# Assessment: <scope>

**Date:** <timestamp>
**Agents:** <list of agents invoked>
**Scope:** <scope description>

## Summary

- **Categories assessed:** [list]
- **Total findings:** N (H high, M medium, L low)

## Findings

### Architecture

#### ASSESS-ARCH-001 [high]
- **Description:** [what and why]
- **Affected files:** `path/to/file.py:15`, `path/to/other.py:42`
- **Suggested approach:** [how to fix]

#### ASSESS-ARCH-002 [medium]
...

### Performance

#### ASSESS-PERF-001 [medium]
...

### UX

(Only present if arn-code-ux-specialist was invoked)

#### ASSESS-UX-001 [high]
...

### Security

(Only present if arn-code-security-specialist was invoked)

#### ASSESS-SEC-001 [high]
...

### Maintainability

#### ASSESS-MAINT-001 [medium]
...

### Testing

#### ASSESS-TEST-001 [low]
...
```

Categories with no findings are omitted from the report.

Finding IDs use the format `ASSESS-<CATEGORY_PREFIX>-<NNN>`:
- ARCH for architecture
- PERF for performance
- UX for ux
- SEC for security
- MAINT for maintainability
- TEST for testing
