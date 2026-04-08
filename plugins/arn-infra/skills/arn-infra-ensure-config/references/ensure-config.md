# Arness Infra Ensure Config — Step 0 Reference

This reference is read by entry-point skills (arn-infra-wizard, arn-infra-assess) as Step 0 before their workflow begins.

Follow the layers below in order. Each layer has a fast path (skip when already satisfied) and a setup path (run once).

---

## Layer 0: Migration Check (Nova to Arness)

This layer runs before everything else. It silently migrates legacy Nova artifacts to the Arness naming convention. All steps are idempotent — safe to run multiple times. No user prompts; log-only.

### 0a. Project Directory

Check via Bash:
```bash
test -d .nova && echo "OLD_EXISTS" || echo "OLD_MISSING"
test -d .arness && echo "NEW_EXISTS" || echo "NEW_MISSING"
```

- If `.nova/` exists AND `.arness/` does NOT exist: run `mv .nova .arness`. Log: "Migrated project directory: .nova/ -> .arness/"
- If both exist: skip (safety). Log: "Both .nova/ and .arness/ exist — skipping directory migration"
- Otherwise: no action needed.

### 0b. CLAUDE.md Config Section

Read CLAUDE.md (if it exists) and check for `## Nova` and `## Arness` headers.

- If `## Nova` exists AND `## Arness` does NOT exist: replace `## Nova` with `## Arness` in CLAUDE.md. Log: "Migrated config section: ## Nova -> ## Arness"
- If both exist: skip (safety). Log: "Both ## Nova and ## Arness sections exist — skipping section migration"
- Otherwise: no action needed.

### 0c. User Home Directory

Check via Bash:
```bash
test -d ~/.nova && echo "OLD_EXISTS" || echo "OLD_MISSING"
test -d ~/.arness && echo "NEW_EXISTS" || echo "NEW_MISSING"
```

- If `~/.nova/` exists AND `~/.arness/` does NOT exist: run `mv ~/.nova ~/.arness`. Log: "Migrated user directory: ~/.nova/ -> ~/.arness/"
- If both exist: skip (safety). Log: "Both ~/.nova/ and ~/.arness/ exist — skipping user directory migration"
- Otherwise: no action needed.

### 0d. Gitignore

Read `.gitignore` (if it exists) and check for `.nova/*.local.yaml`.

- If `.gitignore` contains `.nova/*.local.yaml` but NOT `.arness/*.local.yaml`: replace `.nova/*.local.yaml` with `.arness/*.local.yaml`. Log: "Updated .gitignore: .nova/*.local.yaml -> .arness/*.local.yaml"
- If both patterns exist: skip (safety).
- Otherwise: no action needed.

### 0e. Profile Reference

Check via Bash:
```bash
test -f .claude/nova-profile.local.md && echo "OLD_EXISTS" || echo "OLD_MISSING"
test -f .claude/arness-profile.local.md && echo "NEW_EXISTS" || echo "NEW_MISSING"
```

- If `.claude/nova-profile.local.md` exists AND `.claude/arness-profile.local.md` does NOT exist: run `mv .claude/nova-profile.local.md .claude/arness-profile.local.md`. Log: "Migrated profile: nova-profile.local.md -> arness-profile.local.md"
- If both exist: skip (safety).
- Otherwise: no action needed.

After all migration steps complete (or are skipped), proceed to Layer 1.

---

## Layer 1: Profile Check (Welcome & Profile)

### 1a. Check for Existing Profile

Check whether a user profile already exists:

1. Run via Bash: `test -f ~/.arness/user-profile.yaml && echo "EXISTS" || echo "MISSING"`
2. Check whether `.claude/arness-profile.local.md` exists in the current project (Read `.claude/arness-profile.local.md` — if readable, it exists)

**Decision tree:**

- **Both user-level and project-level exist:** Read the project-level override (`.claude/arness-profile.local.md` frontmatter). Use its values. Proceed to Experience Derivation (Section 1d), then Layer 2.
- **User-level exists, no project-level:** Read `~/.arness/user-profile.yaml`. Ask (using `AskUserQuestion`):

  > **Use your existing Arness profile for this project?**
  > 1. Yes, use my existing profile
  > 2. No, let me adjust for this project

  - If **Yes:** Use the user-level profile. Proceed to Experience Derivation (Section 1d), then Layer 2.
  - If **No:** Show the current profile values and let the user modify any fields. Write the adjusted profile to `.claude/arness-profile.local.md` as YAML frontmatter. Proceed to Experience Derivation (Section 1d), then Layer 2.

- **Neither exists:** Run the Welcome Flow (Section 1b).

### 1b. Welcome Flow (First-Time Only)

Display a brief welcome message:

> **Welcome to Arness!** Let me set up your profile so Arness can tailor recommendations to your experience. This takes about 30 seconds and only happens once.

Then ask 4 questions:

**Q1 — Primary role:**

Ask (using `AskUserQuestion`):
> **What best describes your primary role?**
> 1. Developer (frontend, backend, or full-stack)
> 2. DevOps / Infrastructure Engineer
> 3. Product Manager / Designer
> 4. Tech Lead / Engineering Manager

If the user's role does not fit these options, accept a free-text description and record it under `role: other` with the description in `role_description`.

**Q2 — Development experience:**

Skip this question if the user selected "Product Manager / Designer" in Q1.

Ask (using `AskUserQuestion`):
> **How would you describe your development experience?**
> 1. Expert — I architect systems and mentor others
> 2. Experienced — I build features independently
> 3. Learning — I'm growing my skills with guidance
> 4. Non-technical — I work with developers but don't code

**Q3 — Technologies:**

Skip this question if the user selected "Non-technical" in Q2.

Ask as free text (not AskUserQuestion — this is open-ended):

> **What technologies do you work with?** List your primary languages, frameworks, databases, and infrastructure tools (e.g., "TypeScript, React, Next.js, PostgreSQL, AWS, Docker").

Parse the response into structured categories:
- `languages`: Programming languages (TypeScript, Python, Go, Java, Rust, etc.)
- `frameworks`: Frameworks and libraries (React, Next.js, Django, Spring, etc.)
- `databases`: Databases and data stores (PostgreSQL, MongoDB, Redis, etc.)
- `infrastructure`: Infrastructure tools and platforms (AWS, GCP, Docker, Kubernetes, Terraform, etc.)

**Q4 — Expertise-aware recommendations:**

Ask (using `AskUserQuestion`):
> **Should Arness tailor recommendations to your experience level?** When enabled, guidance adapts to your expertise — experts get terse, direct advice while learners get more context and explanation.
> 1. Yes, tailor to my experience
> 2. No, give me the standard experience

### 1c. Write Profile

1. Create the user-level directory: `mkdir -p ~/.arness`
2. Write `~/.arness/user-profile.yaml` with the following schema:

```yaml
# Arness User Profile
# Portable across projects — edit freely
role: developer | devops | product | lead | other
role_description: "" # Free-text if role is "other" or for additional context
development_experience: expert | experienced | learning | non-technical
technology_preferences:
  languages: []
  frameworks: []
  databases: []
  infrastructure: []
expertise_aware: true | false
```

3. Verify `.claude/*.local.md` and `.claude/settings.local.json` are in the project's `.gitignore`:
   - Read `.gitignore` in the project root
   - If `.gitignore` does not exist, create it with `.claude/settings.local.json` and `.claude/*.local.md` as entries
   - If `.gitignore` exists but does not contain `.claude/*.local.md`, append `.claude/settings.local.json` and `.claude/*.local.md` on new lines
   - **Important:** Do NOT gitignore the entire `.claude/` directory — `.claude/settings.json` and other project-level Claude Code settings should remain committable for team sharing.
4. Optionally create `.claude/arness-profile.local.md` if the user wants project-specific adjustments

Display a closing message:

> **Profile saved.** Your profile is stored at `~/.arness/user-profile.yaml` and works across all your projects. You can edit it anytime or override it per-project.

Proceed to Experience Derivation (Section 1d), then Layer 2.

### 1d. Experience Level Derivation

Read the experience derivation reference for the mapping logic:

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-ensure-config/references/experience-derivation.md`

Apply the derivation rules to determine the user's infrastructure experience level (`expert`, `intermediate`, or `beginner`). Store the derived value as a variable for the calling skill to use — do NOT write `Experience level` to the `## Arness` section.

The derived experience level replaces the former `Experience level` field in `## Arness`. All Arness Infra skills and agents use this derived value.

---

## Layer 2: Config Check (Ensure-Config)

### 2a. Read CLAUDE.md

Read the project's CLAUDE.md and look for a `## Arness` section.

### 2b. If No `## Arness` Section Exists

Perform auto-detection and create the section with sensible defaults.

**Auto-detect:**

1. Git: `git rev-parse --is-inside-work-tree 2>/dev/null && echo "yes" || echo "no"`
2. Remote: `git remote -v 2>/dev/null`
3. Platform: Check for GitHub (`gh auth status 2>/dev/null`) or Bitbucket (`bkt --version 2>/dev/null`). If neither is detected, set Platform to `none`.
4. Issue tracker: If Platform is `github`, set Issue tracker to `github`. If Jira MCP is available, set to `jira`. Otherwise `none`.

**Present defaults:**

Show the user the detected and default Infra values:

| Field | Value |
|-------|-------|
| Infra plans directory | .arness/infra-plans |
| Infra specs directory | .arness/infra-specs |
| Infra docs directory | .arness/infra-docs |
| Infra report templates | default |
| Infra template path | .arness/infra-templates |
| Infra template version | (current plugin version) |
| Git | (detected) |
| Platform | (detected) |
| Issue tracker | (detected) |

Read the plugin version from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json` for the `Infra template version` field.

Ask (using `AskUserQuestion`):
> **Use these defaults or customize folder locations?**
> 1. Use defaults
> 2. Let me customize

- If **Use defaults:** Set `Folder preference: defaults`. Use all values as shown.
- If **Let me customize:** Ask about each Infra directory individually. Set `Folder preference: custom`.

**Write `## Arness` section to CLAUDE.md:**

Construct the `## Arness` section with Infra fields. If CLAUDE.md does not exist, create it with the `## Arness` section. If CLAUDE.md exists, append the section at the end.

Fields to write:
```
## Arness

- **Infra plans directory:** .arness/infra-plans
- **Infra specs directory:** .arness/infra-specs
- **Infra docs directory:** .arness/infra-docs
- **Infra report templates:** default
- **Infra template path:** .arness/infra-templates
- **Infra template version:** (plugin version)
- **Git:** yes
- **Platform:** github
- **Issue tracker:** github
- **Folder preference:** defaults
```

**Do NOT default domain-specific fields.** The following fields require explicit `/arn-infra-init` invocation and must not be auto-configured by ensure-config:
- Providers, Providers config
- Environments, Environments config
- Default IaC tool
- Project topology, Application path
- Tooling manifest, Resource manifest
- Cost threshold, Validation ceiling
- CI/CD platform
- Reference overrides, Reference version, Reference updates

**Create directories:**

Run via Bash: `mkdir -p` for each configured directory (infra-plans, infra-specs, infra-docs, infra-templates).

### 2c. If `## Arness` Exists But Arness Infra Fields Are Missing

Check for the presence of Arness Infra fields: `Infra plans directory`, `Infra specs directory`, `Infra docs directory`, `Infra report templates`, `Infra template path`.

If any are missing:

1. Check the `Folder preference` field in the existing `## Arness` section.
2. If `Folder preference: defaults` — silently add missing Infra fields with default values. Create directories via `mkdir -p`.
3. If `Folder preference: custom` — ask the user about each missing Infra directory. Add fields with the user's chosen values. Create directories.
4. If no `Folder preference` field exists — add it with value `defaults` and silently add missing fields.
5. **Preserve all existing fields** from other plugins (Code fields, Spark fields) per the CLAUDE.md Config Section pattern.

### 2d. If `## Arness` Exists and All Infra Fields Are Present

**Fast path.** No action needed. Proceed to Layer 3.

---

## Layer 3: Infrastructure Labels

Ensure that Arness Infra labels exist on the platform. This layer runs after Layer 2 so that the `Platform` field is available. Labels are required by infrastructure lifecycle skills (`/arn-infra-triage`, `/arn-infra-deploy`, `/arn-infra-verify`, `/arn-infra-assess`, `/arn-infra-migrate`).

### 3a. Check Platform

Read the `Platform` field from `## Arness`. If Platform is `none` or absent, skip this layer entirely and proceed with the original skill's workflow.

### 3b. GitHub Label Setup

If Platform is `github`:

1. **Fast-path check:** Run via Bash: `gh label list --json name --jq '.[].name' | grep -c '^arn-infra-'`
2. If count is **14** (all labels exist): skip. No action needed.
3. If count is **less than 14**: Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-init/references/infra-labels.md` for the full label definitions (names, colors, descriptions). Run `gh label create <name> --color <color> --description "<desc>" --force` for each of the 14 labels. The `--force` flag makes this idempotent — it updates existing labels and creates missing ones.
4. This is a **silent operation** — no user prompt. Log only if labels were created: "Created N missing infrastructure labels."

### 3c. Jira / Bitbucket

No label creation needed. Jira labels are implicit (created on first use by Jira itself). Bitbucket issue tracking is not supported by Arness.

---

## Important Rules

1. **Never hard-block.** If auto-detection fails for a non-critical field (Platform, Issue tracker), default gracefully (`none`). Only the profile welcome flow is mandatory on first invocation.
2. **Preserve ALL existing `## Arness` fields** not managed by Arness Infra. When writing or updating the section, read all existing fields first and include them unchanged. Arness Code fields (Plans directory, Specs directory, Template path, Code patterns, Docs directory, etc.) and Arness Spark fields (Vision directory, Use cases directory, Prototypes directory, Spikes directory, Visual grounding directory, Reports directory) must be preserved.
3. **Use `${CLAUDE_PLUGIN_ROOT}`** for all plugin-internal path references. Never hardcode absolute paths.
4. **Do NOT write `Experience level` to `## Arness`.** Experience level is derived from the user profile at runtime via the experience-derivation.md reference. It is never persisted to the config section.
5. **Do NOT auto-configure domain-specific Infra fields.** Provider selection, environment strategy, IaC tooling, project topology, and all other domain-specific fields require explicit `/arn-infra-init` invocation. Ensure-config only handles directory structure and shared fields.
6. **Profile YAML uses structured `technology_preferences`** with separate `languages`, `frameworks`, `databases`, `infrastructure` arrays. Do not store technologies as a flat string.
7. **Profile data is non-sensitive** (role, technology preferences — no credentials or secrets). The `.claude/*.local.md` gitignore pattern protects against accidental commits of the project-level override while keeping `.claude/settings.json` committable for team sharing.
8. **Folder preference coordination:** When setting `Folder preference`, this value is shared across all three plugins. If another plugin already set it, respect that value.
9. **Backward compatibility:** If `Experience level` exists in `## Arness` and no user profile exists, the experience-derivation.md reference documents how to use the legacy value. Once a profile is created, the profile takes precedence.
