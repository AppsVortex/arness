# Experience Level Derivation

Maps user profile fields to an infrastructure experience level (`expert`, `intermediate`, or `beginner`). This replaces the former `Experience level` field in the `## Arness` config section.

All Arness Infra skills and agents use the derived experience level to govern conversational tone, tool complexity, and recommendations — the same behavior as the former config field, with a richer source of truth.

---

## Derivation Rules

Apply rules in order. The first matching rule determines the experience level.

### Rule 1: DevOps with Infrastructure Tools

**Condition:** `role == devops` AND `technology_preferences.infrastructure` has at least one entry

**Result:** `expert`

**Rationale:** A DevOps engineer who lists infrastructure tools is operating in their primary domain.

### Rule 2: DevOps without Infrastructure Tools

**Condition:** `role == devops` AND `technology_preferences.infrastructure` is empty

**Result:** `intermediate`

**Rationale:** A DevOps engineer who did not list specific infrastructure tools may be transitioning into the role or focused on CI/CD and scripting rather than cloud provisioning.

### Rule 3: Deep Infrastructure Experience

**Condition:** `technology_preferences.infrastructure` count >= 3 (from tools like AWS, GCP, Azure, OpenTofu, Terraform, Pulumi, Kubernetes, Docker, Ansible, CloudFormation, Bicep, DigitalOcean, Fly.io, Railway, Vercel, Netlify)

**Result:** `expert`

**Rationale:** Three or more infrastructure tools indicates significant hands-on experience across the stack, regardless of primary role.

### Rule 4: Some Infrastructure Experience

**Condition:** `technology_preferences.infrastructure` count >= 1 (but less than 3)

**Result:** `intermediate`

**Rationale:** Some infrastructure experience but not enough to indicate expert-level multi-tool proficiency.

### Rule 5: Non-Technical User

**Condition:** `development_experience == non-technical`

**Result:** `beginner`

**Rationale:** Non-technical users need maximum guidance and opinionated PaaS-first recommendations.

### Rule 6: Learning Developer without Infrastructure

**Condition:** `development_experience == learning` AND `technology_preferences.infrastructure` is empty

**Result:** `beginner`

**Rationale:** A developer who is still learning and has no infrastructure experience needs guided, opinionated recommendations.

### Rule 7: Ambiguous — Follow-Up Question

**Condition:** None of the above rules match (e.g., an experienced developer with no listed infrastructure tools, or a tech lead without infrastructure specifics)

**Action:** Ask one follow-up question:

Ask (using `AskUserQuestion`):
> **For infrastructure specifically, how would you rate your experience?**
> 1. Expert — I design and manage production infrastructure
> 2. Intermediate — I've deployed apps and managed basic cloud resources
> 3. Beginner — I'm new to infrastructure and cloud platforms

**Result:** Use the selected level.

**Caching:** Write the answer as `infrastructure_experience_override` in the project-level profile (`.claude/arness-profile.local.md`). On subsequent invocations for this project, read the cached value instead of re-asking. The override is project-scoped because infrastructure experience relevance varies by project context.

---

## Derivation Summary Table

| # | Condition | Result |
|---|-----------|--------|
| 1 | DevOps + infrastructure tools listed | expert |
| 2 | DevOps + no infrastructure tools | intermediate |
| 3 | infrastructure tools >= 3 | expert |
| 4 | infrastructure tools >= 1 (and < 3) | intermediate |
| 5 | Non-technical user | beginner |
| 6 | Learning + no infrastructure tools | beginner |
| 7 | No rule matches | Ask follow-up, cache answer |

---

## Backward Compatibility

For projects that have a legacy `Experience level` field in the `## Arness` config:

1. **If `Experience level` exists in `## Arness` AND no user profile exists:** Use the `## Arness` value directly. This supports the transition period where existing projects may not yet have user profiles.
2. **If both `Experience level` in `## Arness` AND a user profile exist:** The profile-derived value takes precedence. The `## Arness` field is ignored but not removed (removal happens during init repurposing in Phase 5).
3. **If only a user profile exists (no `Experience level` in `## Arness`):** Use the profile-derived value. This is the steady-state behavior for all new projects.

---

## Usage by Calling Skills

The derived experience level is used identically to the former `Experience level` config field:

- **expert:** Terse guidance, full tool flexibility, trusts user's choices. Recommendation matrix allows "User's choice" across all application types.
- **intermediate:** Guided recommendations with trade-off explanations. Recommendation matrix suggests specific tools with rationale.
- **beginner:** Opinionated decisions, PaaS-first recommendations, heavy hand-holding. Recommendation matrix steers toward managed platforms with minimal IaC.

The calling skill (or agent) receives the derived level as a variable and passes it through its existing experience-level-aware logic without modification.
