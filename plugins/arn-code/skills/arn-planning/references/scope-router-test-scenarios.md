# Scope Router Test Scenarios

Reference scenarios for validating the severity-aware scope router. Each scenario includes a description, per-criterion scores, weighted total, expected tier, and key rationale.

Use these scenarios during skill-creator evals and manual testing to verify that the scope router produces correct tier recommendations.

---

## Scenario Format

Each scenario follows this structure:

| Field | Description |
|-------|-------------|
| Description | The user's change description (trigger input) |
| File Count (1x) | low=0, medium=1, high=2 |
| Domain Sensitivity (3x) | low=0, medium=1, high=2 |
| Architectural Change (2x) | low=0, medium=1, high=2 |
| Cross-Module Impact (1x) | low=0, medium=1, high=2 |
| Reversibility Risk (2x) | low=0, medium=1, high=2 |
| Test Infrastructure (1x) | low=0, medium=1, high=2 |
| Weighted Total | Sum of (score x weight) |
| Expected Tier | swift / standard / thorough |
| Overrides | Any override rules triggered |

---

## Swift Tier Scenarios

### Scenario 1: Typo fix in documentation

**Description:** "fix typo in README.md"

| Criterion | Weight | Level | Score | Weighted |
|-----------|--------|-------|-------|----------|
| File count | 1 | low (1 file) | 0 | 0 |
| Domain sensitivity | 3 | low (docs) | 0 | 0 |
| Architectural change | 2 | low (none) | 0 | 0 |
| Cross-module impact | 1 | low (single file) | 0 | 0 |
| Reversibility risk | 2 | low (additive) | 0 | 0 |
| Test infrastructure | 1 | low (no tests) | 0 | 0 |

**Weighted Total:** 0 | **Expected Tier:** swift | **Overrides:** None
**Rationale:** Pure documentation change with zero risk across all dimensions.

---

### Scenario 2: UI color change

**Description:** "update button color on settings page"

| Criterion | Weight | Level | Score | Weighted |
|-----------|--------|-------|-------|----------|
| File count | 1 | low (1-2 files) | 0 | 0 |
| Domain sensitivity | 3 | low (cosmetic) | 0 | 0 |
| Architectural change | 2 | low (none) | 0 | 0 |
| Cross-module impact | 1 | low (single component) | 0 | 0 |
| Reversibility risk | 2 | low (visual-only) | 0 | 0 |
| Test infrastructure | 1 | low (existing tests) | 0 | 0 |

**Weighted Total:** 0 | **Expected Tier:** swift | **Overrides:** None
**Rationale:** Cosmetic change affecting a single component with no behavioral impact.

---

### Scenario 3: High file count, low severity (edge case)

**Description:** "update CSS class names across all 15 component files to match new design system naming convention"

| Criterion | Weight | Level | Score | Weighted |
|-----------|--------|-------|-------|----------|
| File count | 1 | high (15 files) | 2 | 2 |
| Domain sensitivity | 3 | low (cosmetic/CSS) | 0 | 0 |
| Architectural change | 2 | low (renaming only) | 0 | 0 |
| Cross-module impact | 1 | low (CSS scope) | 0 | 0 |
| Reversibility risk | 2 | low (additive rename) | 0 | 0 |
| Test infrastructure | 1 | low (snapshot updates) | 0 | 0 |

**Weighted Total:** 2 | **Expected Tier:** swift | **Overrides:** None
**Rationale:** Despite 15 files, all other criteria are low. File count alone (weight 1) cannot push past swift. Demonstrates severity over file count.

---

### Scenario 4: Add a simple utility function

**Description:** "add a formatCurrency helper to the utils module"

| Criterion | Weight | Level | Score | Weighted |
|-----------|--------|-------|-------|----------|
| File count | 1 | low (1-2 files) | 0 | 0 |
| Domain sensitivity | 3 | low (utility) | 0 | 0 |
| Architectural change | 2 | low (follows existing pattern) | 0 | 0 |
| Cross-module impact | 1 | low (single module) | 0 | 0 |
| Reversibility risk | 2 | low (additive) | 0 | 0 |
| Test infrastructure | 1 | medium (new test cases) | 1 | 1 |

**Weighted Total:** 1 | **Expected Tier:** swift | **Overrides:** None
**Rationale:** New additive function in an existing module. Minor test work is the only non-zero criterion.

---

## Standard Tier Scenarios

### Scenario 5: Form validation

**Description:** "add validation to user registration form"

| Criterion | Weight | Level | Score | Weighted |
|-----------|--------|-------|-------|----------|
| File count | 1 | low (2-3 files) | 0 | 0 |
| Domain sensitivity | 3 | medium (business logic) | 1 | 3 |
| Architectural change | 2 | low (uses existing validation pattern) | 0 | 0 |
| Cross-module impact | 1 | low (single form) | 0 | 0 |
| Reversibility risk | 2 | medium (behavioral change) | 1 | 2 |
| Test infrastructure | 1 | medium (new validation tests) | 1 | 1 |

**Weighted Total:** 6 | **Expected Tier:** standard | **Overrides:** None
**Rationale:** Business logic validation with behavioral change pushes into standard despite low file count.

---

### Scenario 6: API rate limiting

**Description:** "add rate limiting to /api/users endpoint"

| Criterion | Weight | Level | Score | Weighted |
|-----------|--------|-------|-------|----------|
| File count | 1 | low (2-4 files) | 0 | 0 |
| Domain sensitivity | 3 | medium (API behavior) | 1 | 3 |
| Architectural change | 2 | medium (extend middleware) | 1 | 2 |
| Cross-module impact | 1 | medium (API + middleware) | 1 | 1 |
| Reversibility risk | 2 | low (additive middleware) | 0 | 0 |
| Test infrastructure | 1 | medium (rate limit tests) | 1 | 1 |

**Weighted Total:** 7 | **Expected Tier:** standard | **Overrides:** None
**Rationale:** Middleware extension with API behavioral change. Moderate complexity across multiple criteria.

---

### Scenario 7: Stripe webhook handler update (low file count, high severity)

**Description:** "update Stripe webhook handler for new event types"

| Criterion | Weight | Level | Score | Weighted |
|-----------|--------|-------|-------|----------|
| File count | 1 | low (2-3 files) | 0 | 0 |
| Domain sensitivity | 3 | high (payments/Stripe) | 2 | 6 |
| Architectural change | 2 | low (extend existing handler) | 0 | 0 |
| Cross-module impact | 1 | low (webhook module) | 0 | 0 |
| Reversibility risk | 2 | medium (billing behavior) | 1 | 2 |
| Test infrastructure | 1 | medium (webhook test cases) | 1 | 1 |

**Weighted Total:** 9 | **Expected Tier:** standard | **Overrides:** Override rule 1 (domain sensitivity high, weight 3 >= 2 forces minimum standard)
**Rationale:** Only 2-3 files, but payment domain sensitivity (3x weight) dominates. Override rule ensures this never routes to swift.

---

### Scenario 8: Database query caching

**Description:** "add caching layer to database queries"

| Criterion | Weight | Level | Score | Weighted |
|-----------|--------|-------|-------|----------|
| File count | 1 | medium (5-7 files) | 1 | 1 |
| Domain sensitivity | 3 | medium (data layer) | 1 | 3 |
| Architectural change | 2 | medium (cache layer extension) | 1 | 2 |
| Cross-module impact | 1 | medium (data + service layers) | 1 | 1 |
| Reversibility risk | 2 | medium (query behavior change) | 1 | 2 |
| Test infrastructure | 1 | medium (cache invalidation tests) | 1 | 1 |

**Weighted Total:** 10 | **Expected Tier:** standard | **Overrides:** None
**Rationale:** Moderate scores across all criteria. Caching is a well-understood pattern extension, not a new abstraction.

---

### Scenario 9: Borderline swift/standard (edge case)

**Description:** "add error toast notification component to the dashboard"

| Criterion | Weight | Level | Score | Weighted |
|-----------|--------|-------|-------|----------|
| File count | 1 | low (2-3 files) | 0 | 0 |
| Domain sensitivity | 3 | low (UI component) | 0 | 0 |
| Architectural change | 2 | medium (new component pattern) | 1 | 2 |
| Cross-module impact | 1 | medium (dashboard + notification) | 1 | 1 |
| Reversibility risk | 2 | low (additive) | 0 | 0 |
| Test infrastructure | 1 | medium (component tests) | 1 | 1 |

**Weighted Total:** 4 | **Expected Tier:** swift (borderline) | **Overrides:** None
**Rationale:** Score of 4 sits at the swift/standard boundary. Per edge case rules, a score of 4 defaults to standard when borderline. However, the architectural change is only "medium" (not "high"), so no override triggers. This is a judgment call -- the router recommends swift but notes the borderline score.

---

### Scenario 10: Borderline standard/thorough (edge case)

**Description:** "add WebSocket support for real-time notifications with pub/sub channels"

| Criterion | Weight | Level | Score | Weighted |
|-----------|--------|-------|-------|----------|
| File count | 1 | medium (6-8 files) | 1 | 1 |
| Domain sensitivity | 3 | medium (real-time messaging) | 1 | 3 |
| Architectural change | 2 | high (new WebSocket pattern) | 2 | 4 |
| Cross-module impact | 1 | medium (server + client + events) | 1 | 1 |
| Reversibility risk | 2 | medium (new protocol) | 1 | 2 |
| Test infrastructure | 1 | high (WebSocket test infra) | 2 | 2 |

**Weighted Total:** 13 | **Expected Tier:** thorough (borderline) | **Overrides:** Override rule 1 (architectural change high, weight 2 >= 2 forces minimum standard -- already met)
**Rationale:** Score of 13 sits at the standard/thorough boundary. Per edge case rules, borderline standard/thorough defaults to thorough. New architectural pattern and new test infrastructure push this over.

---

## Thorough Tier Scenarios

### Scenario 11: OAuth2 authentication redesign

**Description:** "redesign authentication to support OAuth2"

| Criterion | Weight | Level | Score | Weighted |
|-----------|--------|-------|-------|----------|
| File count | 1 | high (12+ files) | 2 | 2 |
| Domain sensitivity | 3 | high (auth) | 2 | 6 |
| Architectural change | 2 | high (new auth pattern) | 2 | 4 |
| Cross-module impact | 1 | high (all authenticated routes) | 2 | 2 |
| Reversibility risk | 2 | high (breaking auth change) | 2 | 4 |
| Test infrastructure | 1 | high (OAuth mock server) | 2 | 2 |

**Weighted Total:** 20 | **Expected Tier:** thorough | **Overrides:** Override rule 3 (6 criteria high forces thorough)
**Rationale:** Maximum score. Every criterion at highest level. Archetypal thorough-tier change.

---

### Scenario 12: Database migration with data backfill

**Description:** "migrate user table schema with data backfill"

| Criterion | Weight | Level | Score | Weighted |
|-----------|--------|-------|-------|----------|
| File count | 1 | medium (4-6 files) | 1 | 1 |
| Domain sensitivity | 3 | high (data migration/PII) | 2 | 6 |
| Architectural change | 2 | medium (schema change) | 1 | 2 |
| Cross-module impact | 1 | medium (data + service + API) | 1 | 1 |
| Reversibility risk | 2 | high (data mutation) | 2 | 4 |
| Test infrastructure | 1 | medium (migration tests) | 1 | 1 |

**Weighted Total:** 15 | **Expected Tier:** thorough | **Overrides:** Override rule 1 (domain sensitivity high, weight 3 >= 2; reversibility high, weight 2 >= 2)
**Rationale:** Data migration with backfill is inherently high-risk. Domain sensitivity (PII/data) and reversibility (data mutation) both score high with heavy weights.

---

### Scenario 13: RBAC permission system

**Description:** "implement RBAC permission system"

| Criterion | Weight | Level | Score | Weighted |
|-----------|--------|-------|-------|----------|
| File count | 1 | high (10+ files) | 2 | 2 |
| Domain sensitivity | 3 | high (auth/permissions) | 2 | 6 |
| Architectural change | 2 | high (new permission pattern) | 2 | 4 |
| Cross-module impact | 1 | high (all protected resources) | 2 | 2 |
| Reversibility risk | 2 | high (breaking access control) | 2 | 4 |
| Test infrastructure | 1 | high (role/permission fixtures) | 2 | 2 |

**Weighted Total:** 20 | **Expected Tier:** thorough | **Overrides:** Override rule 3 (6 criteria high forces thorough)
**Rationale:** System-wide permission change. Every criterion scores high. Cannot be safely handled without full ceremony.

---

### Scenario 14: Low file count, extreme severity (edge case)

**Description:** "fix the password hashing algorithm — current implementation uses MD5"

| Criterion | Weight | Level | Score | Weighted |
|-----------|--------|-------|-------|----------|
| File count | 1 | low (1-2 files) | 0 | 0 |
| Domain sensitivity | 3 | high (auth/crypto) | 2 | 6 |
| Architectural change | 2 | low (swap algorithm) | 0 | 0 |
| Cross-module impact | 1 | low (single module) | 0 | 0 |
| Reversibility risk | 2 | high (data mutation — rehash) | 2 | 4 |
| Test infrastructure | 1 | medium (hash migration tests) | 1 | 1 |

**Weighted Total:** 11 | **Expected Tier:** standard | **Overrides:** Override rule 1 (domain sensitivity high, weight 3 >= 2; reversibility high, weight 2 >= 2 forces minimum standard)
**Rationale:** Only 1-2 files, but domain sensitivity (crypto) and reversibility (data rehash) push to standard. Despite the score being 11 (standard range), the override rules also independently force standard. If the team prefers thorough for crypto changes, they can upgrade at the tier selection gate.

---

### Scenario 15: Multi-module refactor, low severity (edge case)

**Description:** "rename the 'utils' module to 'shared' across the entire codebase"

| Criterion | Weight | Level | Score | Weighted |
|-----------|--------|-------|-------|----------|
| File count | 1 | high (20+ files) | 2 | 2 |
| Domain sensitivity | 3 | low (naming only) | 0 | 0 |
| Architectural change | 2 | low (rename, no new patterns) | 0 | 0 |
| Cross-module impact | 1 | high (all modules importing utils) | 2 | 2 |
| Reversibility risk | 2 | low (rename is reversible) | 0 | 0 |
| Test infrastructure | 1 | low (update imports) | 0 | 0 |

**Weighted Total:** 4 | **Expected Tier:** swift | **Overrides:** None
**Rationale:** Despite touching 20+ files and all modules, the change is a mechanical rename with zero domain sensitivity, zero architectural change, and zero reversibility risk. The high-weight criteria (domain sensitivity 3x, reversibility 2x, arch change 2x) all score zero. Demonstrates that severity-weighted scoring prevents false thorough routing for high-volume low-risk changes.
