# Scope Router Criteria

Six weighted criteria for determining the recommended ceremony tier (swift, standard, or thorough). Each criterion is rated at three levels (low = 0, medium = 1, high = 2), then multiplied by its weight. The weighted scores are summed to produce a total (0-20) that maps to a tier recommendation.

This assessment is internal -- do not present the scoring table to the user. Present only the recommended tier and a one-sentence rationale.

---

## Criterion 1: File Count (weight: 1)

How many files need to be created or modified (excluding test files)?

| Level | Score | Threshold | Examples |
|-------|-------|-----------|---------|
| Low | 0 | 1-3 files | Fix a typo in a config file; update a single utility function; change one component's styling |
| Medium | 1 | 4-10 files | Add a new API endpoint with route, controller, service, and model; refactor a shared component and its consumers; add a feature with frontend and backend changes |
| High | 2 | 11+ files | Add a full CRUD domain entity across all layers; implement a cross-cutting concern like audit logging; redesign a multi-page flow |

---

## Criterion 2: Domain Sensitivity (weight: 3)

How sensitive is the domain area being changed? This is the highest-weight criterion -- a 2-file change in a payment flow scores higher than a 6-file CSS cleanup.

| Level | Score | Threshold | Examples |
|-------|-------|-----------|---------|
| Low | 0 | Cosmetic, config, UI polish | Update button colors; fix typos; adjust padding; change environment variables; update dependencies; rename labels |
| Medium | 1 | Business logic, API behavior | Add form validation rules; modify API response shapes; change sorting/filtering logic; update business rules in a service layer |
| High | 2 | Auth, payments, PII, data migrations | Modify authentication flows; change payment processing; handle personally identifiable information; alter database schemas with data migration; modify encryption or token handling |

### Domain Sensitivity Signals

Use these keyword and file-path signals to assist with domain sensitivity rating:

**High-sensitivity keywords:** auth, login, password, token, session, OAuth, SSO, payment, billing, Stripe, charge, refund, subscription, PII, encrypt, decrypt, hash, salt, migration, schema change, backfill, GDPR, HIPAA, compliance, permission, role, ACL, RBAC

**High-sensitivity file paths:** `**/auth/**`, `**/payments/**`, `**/billing/**`, `**/migrations/**`, `**/security/**`, `**/crypto/**`, `**/permissions/**`, `**/middleware/auth*`

**Medium-sensitivity keywords:** API, endpoint, route, handler, controller, service, validate, business rule, workflow, state machine, queue, webhook, notification

**Medium-sensitivity file paths:** `**/api/**`, `**/services/**`, `**/controllers/**`, `**/handlers/**`, `**/webhooks/**`, `**/middleware/**`

**Low-sensitivity keywords:** style, color, padding, margin, font, label, tooltip, readme, docs, config, lint, format, rename, typo, comment

**Low-sensitivity file paths:** `**/styles/**`, `**/css/**`, `**/assets/**`, `**/docs/**`, `**/*.config.*`, `**/README*`

---

## Criterion 3: Architectural Change (weight: 2)

Does the change introduce new patterns, abstractions, or structural decisions?

| Level | Score | Threshold | Examples |
|-------|-------|-----------|---------|
| Low | 0 | None -- follows existing patterns | Add a method to an existing class; use an established utility; add a new file following an existing template |
| Medium | 1 | Extends existing patterns | Add a new implementation of an existing interface; introduce a new enum that fits existing type hierarchies; extend an existing hook or middleware chain |
| High | 2 | Genuinely novel patterns or abstractions | Introduce a pattern not yet in the codebase AND not a well-understood industry standard being applied for the first time (e.g., a custom event bus, novel state machine); create a new abstraction layer; fundamentally change an interface contract. Note: applying a well-known pattern (caching, repository, middleware) to a new area is "medium" (extending), not "high" — "high" means the pattern itself is novel to the codebase and requires new architectural thinking |

---

## Criterion 4: Cross-Module Impact (weight: 1)

How many distinct modules, layers, or bounded contexts does the change touch?

| Level | Score | Threshold | Examples |
|-------|-------|-----------|---------|
| Low | 0 | Single module | Change stays within one package/directory; modify a single component and its tests; update one service |
| Medium | 1 | 2-3 modules | Change spans frontend and backend; modify a service and its API layer; update a shared library and two consumers |
| High | 2 | 4+ modules | Change touches API, service, data, and UI layers; modify core infrastructure used across all modules; update a contract affecting multiple services |

---

## Criterion 5: Reversibility Risk (weight: 2)

How easily can the change be rolled back if something goes wrong?

| Level | Score | Threshold | Examples |
|-------|-------|-----------|---------|
| Low | 0 | Additive or feature-flagged | New functions, new files, add-only changes; changes behind a feature flag; configuration with clear rollback path |
| Medium | 1 | Behavioral change | Modify existing behavior other code depends on; change API response format; update queries that could affect performance; alter validation rules |
| High | 2 | Data mutation or breaking API | Data migrations that alter existing records; breaking API changes without versioning; remove or rename public interfaces; changes to billing or subscription state |

---

## Criterion 6: Test Infrastructure (weight: 1)

How much new test infrastructure is needed (not just test cases)?

| Level | Score | Threshold | Examples |
|-------|-------|-----------|---------|
| Low | 0 | Existing tests sufficient | Change is covered by existing test cases; only need to update a few assertions; no new test files needed |
| Medium | 1 | New test cases needed | Add test cases to existing test files; create 1-2 new test files following existing patterns; add new fixtures to existing conftest |
| High | 2 | New test infrastructure | Need new test fixtures, factories, or helpers; require mock servers or test databases; need to establish a new testing pattern not yet in the project |

---

## Scoring

### Calculation

For each criterion, assign a level (low/medium/high) corresponding to a score (0/1/2). Multiply each score by the criterion's weight. Sum all weighted scores.

| Criterion | Weight | Max Weighted Score |
|-----------|--------|--------------------|
| File count | 1 | 2 |
| Domain sensitivity | 3 | 6 |
| Architectural change | 2 | 4 |
| Cross-module impact | 1 | 2 |
| Reversibility risk | 2 | 4 |
| Test infrastructure | 1 | 2 |
| **Total** | **10** | **20** |

### Tier Thresholds

| Total Score | Recommended Tier | Description |
|-------------|-----------------|-------------|
| 0-4 | Swift | Small, low-risk, additive change. Single session, lightweight record. |
| 5-12 | Standard | Moderate scope or sensitivity. Collapsed spec-plan-execute in one session. |
| 13-20 | Thorough | High complexity, risk, or architectural significance. Full pipeline with spec, plan, review, and phased execution. |

---

## Override Rules

These rules apply after scoring and can force a minimum tier regardless of total score:

1. **High-weight high-score override:** If any criterion with weight >= 2 scores "high" (2), the minimum tier is **standard** (even if the total score falls in the swift range). This prevents a 2-file payment change from routing to swift.

2. **Domain sensitivity ceiling:** If domain sensitivity scores "high" (2), the minimum tier is **standard**. This is a special case of rule 1 since domain sensitivity has weight 3.

3. **Multi-high override:** If 2 or more criteria **with weight >= 2** score "high" (2), the minimum tier is **thorough** regardless of total score. Only domain sensitivity (weight 3), architectural change (weight 2), and reversibility risk (weight 2) are eligible for this rule — file count (weight 1), cross-module impact (weight 1), and test infrastructure (weight 1) do not count toward the multi-high threshold.

4. **User override:** The user can always upgrade or downgrade the recommended tier at the tier selection gate. If the user downgrades from thorough to standard or from standard to swift, no warning is needed -- the recommendation is advisory.

---

## Edge Cases

- **Borderline swift/standard (score 4-5):** Default to standard. The overhead of standard over swift is small, and the additional structure catches issues early.
- **Borderline standard/thorough (score 12-13):** Default to thorough. Underestimating complexity is costlier than overestimating it.
- **High file count, low severity (e.g., 12-file CSS cleanup):** File count alone cannot push past swift if all other criteria are low. A 12-file CSS change scores: file count 2x1=2, domain sensitivity 0x3=0, arch change 0x2=0, cross-module 0x1=0, reversibility 0x2=0, test infra 0x1=0 = total 2 → swift.
- **Low file count, high severity (e.g., 2-file Stripe webhook change):** Domain sensitivity and reversibility dominate. Scores: file count 0x1=0, domain sensitivity 2x3=6, arch change 0x2=0, cross-module 0x1=0, reversibility 1x2=2, test infra 0x1=0 = total 8 → standard. Override rule 1 also applies (domain sensitivity high with weight 3 >= 2).
- **Supplementary signal -- git diff:** If a `git diff --stat` is available, use it as a supplementary signal for file count and cross-module impact. It does not override the description-based assessment but can confirm or adjust the file count estimate.
