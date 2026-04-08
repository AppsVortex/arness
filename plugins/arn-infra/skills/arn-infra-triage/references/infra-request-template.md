# Infrastructure Request Template

Template for infrastructure request issues created by Arness Core (or manually). This is the expected format for issues labeled `arn-infra-request`. The `arn-infra-triage` skill parses this structure automatically.

---

## Template

```markdown
## Infrastructure Request: [Feature Name]

### Feature
**Name:** [Feature display name]
**Issue/PR:** [Link to the originating Core issue or PR]
**Status:** [Completed | In Progress | Planned]

### Spec
**Path:** [Relative path to the feature spec in the Core project]
Example: `.arness/specs/FEATURE_user-authentication.md`

### Plan
**Path:** [Relative path to the implementation plan, if exists]
Example: `.arness/plans/user-authentication/plans/PHASE_1_PLAN.md`
*Omit this section if no plan exists yet.*

### Infrastructure Implications
[Summary of what the feature needs from infrastructure. Written by Arness Core or the developer.]

**New resources needed:**
- [Resource type]: [purpose] (e.g., "PostgreSQL database: user account storage")
- [Resource type]: [purpose]

**Changes to existing infrastructure:**
- [Change description] (e.g., "New environment variable DATABASE_URL for the API service")

**New environment variables:**
- `[VAR_NAME]`: [description] (e.g., "`REDIS_URL`: Connection string for the session cache")

**Networking changes:**
- [Change description] (e.g., "Expose port 8080 for the new API endpoint")

### Key Implementation Files
[Paths to source files in the Core project that affect infrastructure]
- `src/services/auth.ts` -- New authentication service with database dependency
- `src/config/database.ts` -- Database connection configuration
- `migrations/001_create_users.sql` -- Database migration

### Originating Issue
[Link to the Core project issue or PR that triggered this request]
Example: `https://github.com/org/my-app/issues/15`

### Priority
[One of: Blocking | Planned | Enhancement]

- **Blocking:** Feature cannot ship without this infrastructure. Deployment is blocked.
- **Planned:** Infrastructure is needed but the feature can ship to development first.
- **Enhancement:** Nice-to-have infrastructure improvement. Not blocking any feature.
```

---

## Parsing Rules

The `arn-infra-triage` skill parses this template by heading:

| Heading | Required | Parsing Method |
|---------|----------|----------------|
| `### Feature` | Yes | Extract name, issue/PR link, status |
| `### Spec` | Yes | Extract path to feature spec |
| `### Plan` | No | Extract path to plan (if present) |
| `### Infrastructure Implications` | Yes | Extract sub-sections: new resources, changes, env vars, networking |
| `### Key Implementation Files` | No | Extract file paths as a list |
| `### Originating Issue` | No | Extract URL |
| `### Priority` | Yes | Extract one of: Blocking, Planned, Enhancement |

---

## Example: Complete Issue

```markdown
## Infrastructure Request: User Authentication

### Feature
**Name:** User Authentication with OAuth
**Issue/PR:** https://github.com/acme/my-app/pull/23
**Status:** Completed

### Spec
**Path:** .arness/specs/FEATURE_user-authentication.md

### Plan
**Path:** .arness/plans/user-authentication/plans/PHASE_1_PLAN.md

### Infrastructure Implications

**New resources needed:**
- PostgreSQL database: User account storage (users, sessions, OAuth tokens)
- Redis cache: Session management and rate limiting
- S3-compatible storage: User avatar uploads

**Changes to existing infrastructure:**
- New environment variables for database and cache connections
- API service needs outbound HTTPS access for OAuth provider callbacks

**New environment variables:**
- `DATABASE_URL`: PostgreSQL connection string
- `REDIS_URL`: Redis connection string
- `S3_BUCKET`: Avatar storage bucket name
- `S3_ACCESS_KEY`: S3 access credentials
- `OAUTH_CLIENT_ID`: OAuth provider client ID
- `OAUTH_CLIENT_SECRET`: OAuth provider client secret

**Networking changes:**
- Allow outbound HTTPS (443) to OAuth providers (Google, GitHub)
- Expose `/auth/callback` endpoint publicly for OAuth redirects

### Key Implementation Files
- `src/services/auth-service.ts` -- OAuth flow implementation
- `src/models/user.ts` -- User model with database schema
- `src/config/database.ts` -- Database connection pool
- `src/middleware/session.ts` -- Session middleware using Redis
- `migrations/001_create_users_table.sql` -- User table migration

### Originating Issue
https://github.com/acme/my-app/pull/23

### Priority
Blocking
```

---

## Notes

- This template is designed to be machine-parseable (consistent markdown headings) while remaining human-readable
- Arness Core creates issues in this format automatically when the `Infrastructure` field is set in `## Arness`
- Manual issues do not need to follow this format exactly -- `arn-infra-triage` will extract what it can and ask for gaps
- The paths reference the Core project, not the infra project -- the request-analyzer agent navigates to these paths via `Application path`
