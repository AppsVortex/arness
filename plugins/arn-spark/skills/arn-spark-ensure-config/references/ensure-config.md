# Arness Spark Ensure Config — Step 0 Reference

This reference is read by entry-point skills (arn-brainstorming, arn-spark-discover, arn-spark-arch-vision) as Step 0 before their workflow begins.

Follow the layers below in order. Each layer has a fast path (skip when already satisfied) and a setup path (run once).

**Special note for `arn-spark-discover`:** Ensure-config should run but must not hard-block if something fails. Discover may be invoked before any project exists — it is exploratory by nature. If CLAUDE.md cannot be written (no project directory), skip Layer 2 and proceed with the original skill.

---

## Layer 0: Migration Check (Nova to Arness)

This layer runs before everything else. It silently migrates legacy Nova artifacts to the Arness naming convention. All steps are idempotent — safe to run multiple times. No user prompts; log-only. If any migration step fails, log the error and continue (do not hard-block — consistent with Spark's resilience pattern).

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

- **Both user-level and project-level exist:** Read the project-level override (`.claude/arness-profile.local.md` frontmatter). Use its values. Proceed to Layer 2.
- **User-level exists, no project-level:** Read `~/.arness/user-profile.yaml`. Ask (using `AskUserQuestion`):

  > **Use your existing Arness profile for this project?**
  > 1. Yes, use my existing profile
  > 2. No, let me adjust for this project

  - If **Yes:** Use the user-level profile. Proceed to Layer 2.
  - If **No:** Show the current profile values and let the user modify any fields. Write the adjusted profile to `.claude/arness-profile.local.md` as YAML frontmatter. Proceed to Layer 2.

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

Skip this question if the user selected "Non-technical" in Q2, or if Q2 was skipped (PM/Designer role in Q1) and the user's role suggests non-technical background.

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

3. Verify `.claude/*.local.md`, `.claude/settings.local.json`, and `.arness/*.local.yaml` are in the project's `.gitignore`:
   - Read `.gitignore` in the project root
   - If `.gitignore` does not exist, create it with `.claude/settings.local.json`, `.claude/*.local.md`, and `.arness/*.local.yaml` as entries
   - If `.gitignore` exists but does not contain `.claude/*.local.md`, append `.claude/*.local.md` on a new line
   - If `.gitignore` exists but does not contain `.claude/settings.local.json`, append `.claude/settings.local.json` on a new line
   - If `.gitignore` exists but does not contain `.arness/*.local.yaml`, append `.arness/*.local.yaml` on a new line
   - **Important:** Do NOT gitignore the entire `.claude/` directory — `.claude/settings.json` and other project-level Claude Code settings should remain committable for team sharing.
   - **Important:** Do NOT gitignore the entire `.arness/` directory — `.arness/preferences.yaml` (team technology preferences) and other Arness project files must remain committable.
4. Optionally create `.claude/arness-profile.local.md` if the user wants project-specific adjustments

Display a closing message:

> **Profile saved.** Your profile is stored at `~/.arness/user-profile.yaml` and works across all your projects. You can edit it anytime or override it per-project.

Proceed to Layer 2.

---

## Layer 2: Config Check (Ensure-Config)

### 2a. Read CLAUDE.md

Read the project's CLAUDE.md and look for a `## Arness` section.

If CLAUDE.md does not exist and no project directory is established (e.g., `arn-spark-discover` invoked in a temporary context), skip Layer 2 entirely and proceed with the original skill.

### 2b. If No `## Arness` Section Exists

Perform auto-detection and create the section with sensible defaults.

**Auto-detect:**

1. Git: `git rev-parse --is-inside-work-tree 2>/dev/null && echo "yes" || echo "no"`
2. Remote: `git remote -v 2>/dev/null`
3. Platform: Check for GitHub (`gh auth status 2>/dev/null`) or Bitbucket (`bkt --version 2>/dev/null`). If neither is detected, set Platform to `none`.
4. Issue tracker: If Platform is `github`, set Issue tracker to `github`. If Jira MCP is available, set to `jira`. Otherwise `none`.

**Present defaults:**

Show the user the detected and default values:

| Field | Value |
|-------|-------|
| Vision directory | .arness/vision |
| Use cases directory | .arness/use-cases |
| Prototypes directory | .arness/prototypes |
| Spikes directory | .arness/spikes |
| Visual grounding directory | .arness/visual-grounding |
| Reports directory | .arness/reports |
| Git | (detected) |
| Platform | (detected) |
| Issue tracker | (detected) |

Ask (using `AskUserQuestion`):
> **Use these defaults or customize folder locations?**
> 1. Use defaults
> 2. Let me customize

- If **Use defaults:** Set `Folder preference: defaults`. Use all values as shown.
- If **Let me customize:** Ask about each directory individually. Set `Folder preference: custom`.

**Write `## Arness` section to CLAUDE.md:**

Construct the `## Arness` section with all fields. If CLAUDE.md does not exist, create it with the `## Arness` section. If CLAUDE.md exists, append the section at the end.

Fields to write:
```
## Arness

- **Vision directory:** .arness/vision
- **Use cases directory:** .arness/use-cases
- **Prototypes directory:** .arness/prototypes
- **Spikes directory:** .arness/spikes
- **Visual grounding directory:** .arness/visual-grounding
- **Reports directory:** .arness/reports
- **Git:** yes
- **Platform:** github
- **Issue tracker:** github
- **Folder preference:** defaults
```

**Create directories:**

Run via Bash: `mkdir -p` for each configured directory (vision, use-cases, prototypes, spikes, visual-grounding, reports).

### 2c. If `## Arness` Exists But Arness Spark Fields Are Missing

Check for the presence of Arness Spark fields: `Vision directory`, `Use cases directory`, `Prototypes directory`, `Spikes directory`, `Visual grounding directory`, `Reports directory`.

If any are missing:

1. Check the `Folder preference` field in the existing `## Arness` section.
2. If `Folder preference: defaults` — silently add missing Spark fields with default values. Create directories via `mkdir -p`.
3. If `Folder preference: custom` — ask the user about each missing Spark directory. Add fields with the user's chosen values. Create directories.
4. If no `Folder preference` field exists — add it with value `defaults` and silently add missing fields.
5. **Preserve all existing fields** from other plugins (Code fields, Infra fields) per the CLAUDE.md Config Section pattern.

### 2d. If `## Arness` Exists and All Spark Fields Are Present

**Fast path.** No action needed. Proceed with the original skill's workflow.

---

## Important Rules

1. **Never hard-block.** If auto-detection fails for a non-critical field (Platform, Issue tracker), default gracefully (`none`). Only the profile welcome flow is mandatory on first invocation. For `arn-spark-discover`, if Layer 2 cannot complete (no project directory), skip it entirely.
2. **Preserve ALL existing `## Arness` fields** not managed by Arness Spark. When writing or updating the section, read all existing fields first and include them unchanged. Arness Code fields (Plans directory, Specs directory, Template path, Code patterns, Docs directory, etc.) and Arness Infra fields (Infra plans directory, Infra specs directory, Infra docs directory, etc.) must be preserved.
3. **Use `${CLAUDE_PLUGIN_ROOT}`** for all plugin-internal path references. Never hardcode absolute paths.
4. **No template setup.** Arness Spark does not have report templates. Template setup is handled exclusively by Arness Code's ensure-config.
5. **Profile YAML uses structured `technology_preferences`** with separate `languages`, `frameworks`, `databases`, `infrastructure` arrays. Do not store technologies as a flat string.
6. **Profile data is non-sensitive** (role, technology preferences — no credentials or secrets). The `.claude/*.local.md` gitignore pattern protects against accidental commits of the project-level override while keeping `.claude/settings.json` committable for team sharing.
7. **Folder preference coordination:** When setting `Folder preference`, this value is shared across all three plugins. If another plugin already set it, respect that value.
8. **Discover resilience:** `arn-spark-discover` has "Prerequisites: None" in its design. If ensure-config encounters any error during Layer 2 (e.g., no writable directory, no CLAUDE.md), log the issue silently and let the original skill proceed. The profile (Layer 1) should still be captured if possible since it lives at `~/.arness/` which is always writable.
