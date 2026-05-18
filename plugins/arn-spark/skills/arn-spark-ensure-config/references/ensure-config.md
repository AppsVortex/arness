# Arness Spark Ensure Config — Step 0 Reference

This reference is read by entry-point skills (arn-brainstorming, arn-spark-discover, arn-spark-arch-vision) as Step 0 before their workflow begins.

Follow the layers below in order. Each layer has a fast path (skip when already satisfied) and a setup path (run once).

**Special note for `arn-spark-discover`:** Ensure-config should run but must not hard-block if something fails. Discover may be invoked before any project exists — it is exploratory by nature. If CLAUDE.md cannot be written (no project directory), skip Layer 2 and proceed with the original skill.

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

3. Verify `.claude/*.local.md`, `.claude/settings.local.json`, and `.arness/*.local.*` are in the project's `.gitignore`:
   - Read `.gitignore` in the project root
   - If `.gitignore` does not exist, create it with `.claude/settings.local.json`, `.claude/*.local.md`, and `.arness/*.local.*` as entries
   - If `.gitignore` exists but does not contain `.claude/*.local.md`, append `.claude/*.local.md` on a new line
   - If `.gitignore` exists but does not contain `.claude/settings.local.json`, append `.claude/settings.local.json` on a new line
   - If `.gitignore` exists but does not contain `.arness/*.local.*`, append `.arness/*.local.*` on a new line
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

For the `Spark agent model profile:` field: do NOT default it here. Leave the field absent so Layer 2c routes to the **Profile selection** procedure (see "Model profile field" section below) on the next ensure-config invocation. This guarantees the user is asked rather than silently set to `all-opus`. The corresponding `.arness/agent-models/spark.md` file is created by the Profile selection procedure, not by this fast path.

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

Check for the presence of Arness Spark fields: `Vision directory`, `Use cases directory`, `Prototypes directory`, `Spikes directory`, `Visual grounding directory`, `Reports directory`, `Spark agent model profile`.

If any directory-style fields are missing (`Vision directory`, `Use cases directory`, `Prototypes directory`, `Spikes directory`, `Visual grounding directory`, `Reports directory`):

1. Check the `Folder preference` field in the existing `## Arness` section.
2. If `Folder preference: defaults` — silently add missing Spark fields with default values. Create directories via `mkdir -p`.
3. If `Folder preference: custom` — ask the user about each missing Spark directory. Add fields with the user's chosen values. Create directories.
4. If no `Folder preference` field exists — add it with value `defaults` and silently add missing fields.
5. **Preserve all existing fields** from other plugins (Code fields, Infra fields) per the CLAUDE.md Config Section pattern.

If the `Spark agent model profile:` field is missing (separate logic — this field requires a real choice and downstream artifact copy):

1. Run the **Profile selection** procedure documented in the "Model profile field" section below. The procedure handles the AskUserQuestion prompt, writes the field to the `## Arness` block, copies the chosen preset to `.arness/agent-models/spark.md`, and records the SHA-256 checksum.

If the `Spark agent model profile:` field is **present** (consistency check — runs whether or not directory fields are also missing):

1. **If value is `all-opus` or `balanced`:**
   a. Compute the SHA-256 checksum of `.arness/agent-models/spark.md` and compare it to the recorded checksum in `.arness/agent-models/.checksums.json`.
   b. If checksums **differ** (user edited the file): flip the field value in `## Arness` from its current value to `custom` and inform the user with a one-line message: `"Detected your edits to .arness/agent-models/spark.md — set profile to 'custom' so future updates won't overwrite your changes."` Do NOT overwrite the user's edits; do NOT recompute the checksum (the `custom` profile means "user-managed").
   c. If checksums match: read the `# Version:` header from `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-init/references/agent-models-presets/<value>.md` (the upstream preset) and compare to the `# Version:` header recorded in `.arness/agent-models/spark.md`. If they differ, apply the project's `Template updates:` policy (reuse the procedure in `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-save-plan/references/template-versioning.md` — Spark reuses Arness Code's template-versioning machinery):
      - `auto`: copy the new preset, regenerate the checksum, inform the user "Refreshed `.arness/agent-models/spark.md` from preset `<value>` v<old>→v<new>."
      - `ask`: prompt the user; on accept, copy + regenerate; on decline, leave file alone and skip until the user re-runs.
      - `manual`: do nothing this run.

2. **If value is `custom`:**
   a. Read the canonical agent list from `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-init/references/agent-models-presets/all-opus.md` (every entry of the form `<agent-name>: <model>`).
   b. Read the user's `.arness/agent-models/spark.md` and collect the agent names present.
   c. For any agent in the canonical list that is NOT present in the user's file, surface as an info-level diagnostic: `"Note: .arness/agent-models/spark.md is missing entries for: <comma-separated agent list>. Add them or run with 'all-opus'/'balanced' profile to refresh."` This is informational only — do not block the workflow.

3. **If value is anything else** (legacy/typo): treat as missing — run the Profile selection procedure to repair.

### 2d. If `## Arness` Exists and All Spark Fields Are Present

**Fast path.** Verify against the canonical Spark fields list at the top of section 2c — every field on that list (including `Spark agent model profile`) must be present. If `Spark agent model profile` is present, also run the checksum/version/custom-diagnostic checks documented in section 2c (they are cheap and idempotent). If all checks pass, no action needed; proceed with the original skill's workflow.

---

## Layer 3: Cache Write

After Layers 1–2 complete successfully, write the validation cache so future ensure-config invocations can fast-path via `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-ensure-config/scripts/cache-check.sh`. This is the final step of the validation flow.

### Why a cache?

Entry-point skills invoke ensure-config as Step 0 on every workflow trigger (~30 trigger points across the plugin). Re-running the full Layers 1–2 flow on every invocation costs ~2k tokens even when nothing has changed. The cache lets the cache-check shell script (zero model tokens) verify validity in milliseconds; on hit, the entry-point skips reading this references file entirely (per the procedure in `references/step-0-fast-path.md`).

### Cache file location

`.arness/arn-spark-ensure-config.local.json` (project-local, gitignored via the `.arness/*.local.*` pattern from Layer 1c).

### Cache schema

```json
{
  "schemaVersion": 1,
  "validatedAt": "2026-05-10T12:34:56Z",
  "pluginVersion": "2.4.0",
  "fingerprints": {
    "claudeMdArnessSection": "<sha256 of the ## Arness block content>",
    "agentModelsCodeMd": "<sha256 of .arness/agent-models/spark.md, or 'MISSING'>",
    "agentModelsChecksums": "<sha256 of .arness/agent-models/.checksums.json, or 'MISSING'>",
    "templatesChecksums": "<sha256 of .arness/templates/.checksums.json, or 'MISSING'>",
    "userProfile": "<sha256 of ~/.arness/user-profile.yaml, or 'MISSING'>",
    "profileOverride": "<sha256 of .claude/arness-profile.local.md, or 'MISSING'>",
    "gitignoreContent": "<sha256 of .gitignore, or 'MISSING'>"
  },
  "validationStatus": "pass"
}
```

(Note: the fingerprint key remains `agentModelsCodeMd` for cross-plugin schema consistency, but its value hashes the spark-specific file `.arness/agent-models/spark.md`.)

### Write procedure

1. **Compute the 7 fingerprints** using `sha256sum` (Linux + Git Bash) || `shasum -a 256` (Mac BSD). For the `claudeMdArnessSection` hash, extract the `## Arness` block via `awk '/^## Arness$/{flag=1;next} /^## /{flag=0} flag' CLAUDE.md` then pipe to the hasher. For each file fingerprint: if the file does not exist, use the literal string `MISSING` instead of computing a hash.

2. **Read plugin version** from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json` if present (legacy), else from the marketplace's `marketplace.json` entry for `arn-spark`. Use the empty string if neither is resolvable.

3. **Construct the JSON object** with the schema above. `validatedAt` is the current ISO 8601 UTC timestamp. `validationStatus` is `"pass"` (only written on successful Layers 1–2).

4. **Write atomically** using a project-local temp file (NOT `/tmp/` — Windows compat):

   ```bash
   <json content> > .arness/arn-spark-ensure-config.local.json.tmp
   mv .arness/arn-spark-ensure-config.local.json.tmp .arness/arn-spark-ensure-config.local.json
   ```

   The `mv` is atomic on POSIX filesystems (Linux ext4, Mac APFS, Windows NTFS via Git Bash).

5. **Verify** by reading the file back and confirming valid JSON. If the verify fails, surface as a warning but do not block — the next invocation will simply cache-miss.

### When the cache invalidates

- `pluginVersion` differs from current (plugin upgrade)
- `schemaVersion` differs from current (cache schema bump — silently invalidates)
- Any of the 7 fingerprints differs from current state

All invalidation paths trigger a cache miss, which causes the entry-point to read the full ensure-config.md and re-run Layers 1–2 — at the end of which this Layer 3 step writes a new cache.

---

## Model profile field

The `Spark agent model profile` field controls which Claude model each Arness Spark agent is dispatched on. It mirrors the structure of the Linting field flow used by Arness Code and reuses the same checksum + version-update machinery as report templates.

### Field summary

| Property | Value |
|----------|-------|
| Field name | `Spark agent model profile` |
| Valid values | `all-opus` \| `balanced` \| `custom` |
| Default on init | `all-opus` (preserves prior behavior) |
| Where the choice lives | The field in `## Arness` records the user's choice; the actual model-per-agent map lives at `.arness/agent-models/spark.md`. |
| Update policy | Reuses the project's `Template updates:` field (`ask` \| `auto` \| `manual`). If `Template updates:` is not present (Spark-only project), default to `ask`. |
| Drift detection | SHA-256 checksum of `.arness/agent-models/spark.md` compared to the recorded checksum. Mismatch flips the field to `custom`. |
| Custom diagnostic | When value is `custom`, missing-agent entries (against the canonical `all-opus.md` agent list) are surfaced as info-level diagnostics. |
| User example | The arness repo's own `## Arness` block uses `Template path: .arness/templates`, `Template version: 2.3.0`, `Template updates: ask`. The model-profile field is appended in the same `- **Field name:** value` style. |

### Profile selection procedure

This procedure is the single source of truth for the prompt + write + copy + checksum flow. It is invoked from two places:
- `arn-spark-init` ("Choose model profile" step), and
- `arn-spark-ensure-config` Layer 2c (when the field is missing).

Both call sites must read this section and follow it verbatim — do NOT duplicate the AskUserQuestion + write + copy + checksum logic at the call sites.

**Steps:**

1. **Cross-plugin default suggestion.** Before asking, read the project's CLAUDE.md `## Arness` block. If a sibling plugin's profile field (`Code agent model profile:` or `Infra agent model profile:`) is set to `all-opus` or `balanced`, suggest that value as the default in the AskUserQuestion options ordering (the recommended/default option goes first, with `(Recommended)` appended). If both siblings are set to different values, prefer the most recently written field; if neither is set, the default is `all-opus`.

2. **Ask the user.** Ask (using `AskUserQuestion`):

   > **Choose model profile for arn-spark agents**
   > 1. **all-opus (Recommended)** — Every agent uses Opus. Maximum quality, maximum cost. (Current behavior.)
   > 2. **balanced** — Opus for heavy reasoning, Sonnet for operational work. Lower cost, similar quality on routine tasks.

   The label `(Recommended)` is appended to the suggested default (which may be `balanced` if a sibling plugin chose `balanced`). The recommended option appears first in the option list.

3. **Write the field.** Append `- **Spark agent model profile:** <choice>` to the `## Arness` block in CLAUDE.md, using the existing field-write idiom (preserve all other fields, replace the single field if it already exists).

4. **Copy the preset.** Create `.arness/agent-models/` if it does not exist (`mkdir -p .arness/agent-models`). Copy `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-init/references/agent-models-presets/<choice>.md` to `.arness/agent-models/spark.md`.

5. **Record the checksum.** Compute the SHA-256 checksum of the copied file via Bash:
   ```bash
   sha256sum .arness/agent-models/spark.md 2>/dev/null || shasum -a 256 .arness/agent-models/spark.md
   ```
   Read or create `.arness/agent-models/.checksums.json`. Add or update the entry for `spark.md`:
   ```json
   {
     "spark.md": {
       "sha256": "<hex digest>",
       "profile": "<choice>",
       "version": "<version from the preset's # Version: header>"
     }
   }
   ```
   Preserve any sibling entries (`code.md`, `infra.md`) already present in `.checksums.json` — those belong to the other plugins and are managed by their own ensure-config flows.

6. **Inform the user** with a one-line confirmation: `"Set Spark agent model profile to <choice>. Wrote .arness/agent-models/spark.md (sha256: <first-8-chars>...)."`

### Drift detection (Layer 2c integration)

Layer 2c runs the following whenever the field is present:

1. **Checksum check.** Compute the current sha256 of `.arness/agent-models/spark.md` and compare to the recorded checksum in `.arness/agent-models/.checksums.json`. If they differ, flip the field to `custom` (one-line user message; do NOT overwrite the user's file).
2. **Version check** (only when value is `all-opus` or `balanced` and checksums match): compare the `# Version:` header in the user's `.arness/agent-models/spark.md` against the upstream preset at `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-init/references/agent-models-presets/<value>.md`. On mismatch, apply the `Template updates:` policy (reuse `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-save-plan/references/template-versioning.md`).
3. **Custom diagnostic** (only when value is `custom`): read the canonical agent list from `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-init/references/agent-models-presets/all-opus.md` and surface info-level diagnostics for any canonical agent missing from the user's file.

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

---

## Dispatch convention (agent model lookup)

Every skill in this plugin that dispatches a subagent via the Task tool consults a per-plugin model profile to decide which model the agent runs on. The profile lives at `.arness/agent-models/spark.md` (project-relative, NOT plugin-relative — this path is project-rooted while plugin assets use `${CLAUDE_PLUGIN_ROOT}` per Pattern 8 in INTRODUCTION.md). The file is created during init and is one of the presets shipped under `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-init/references/agent-models-presets/`.

### Lookup procedure (apply at every dispatch site)

1. **Read `.arness/agent-models/spark.md`** (project-relative).
2. **If the file is missing or unparseable:** omit the `model:` parameter when invoking the Task tool. The agent's frontmatter default (`opus`) applies. Do not surface an error — fallback is silent.
3. **Look up the agent's name** (e.g., `arn-spark-doctor`, `arn-spark-product-strategist`) in the file's mapping.
4. **If the agent name is found:** pass the mapped value (e.g., `opus`, `sonnet`, `haiku`) as the Task tool's `model` parameter. This overrides the agent's `model:` frontmatter.
5. **If the agent name is NOT found in the file:** omit the `model:` parameter — frontmatter fallback applies. This keeps user-edited `custom` profiles forward-compatible: agents added to the plugin after the user customized their profile still run on their frontmatter default (`opus`) until the user adds them to the file.
6. **Multi-agent parallel dispatches:** apply the lookup to each agent independently. A single instruction that spawns three agents in parallel produces three independent lookups, each potentially passing a different `model:` value.
7. **Resume-mode dispatches** (calls that pass an existing agent ID via the Task tool's `resume` parameter): do NOT consult the profile. Resume calls inherit the model from the original invocation. Dispatch sites that resume an existing agent do not include the model-lookup phrasing.

### Why this design

- **Native Task tool support.** The Task tool's `model:` parameter takes precedence over agent frontmatter (Pattern 2 in INTRODUCTION.md). No wrapper or shim is needed.
- **Self-documenting.** Every dispatch site explicitly references this convention, so the lookup behavior is visible at the point of dispatch rather than buried in a global default. A static grep for `via the Task tool` confirms coverage.
- **Graceful degradation.** Missing file, missing agent entry, and unparseable content all fall back to frontmatter — there is no failure mode where dispatch hangs or errors on a config issue.
- **Single source of truth.** `.arness/agent-models/spark.md` is the only place a user edits to change behavior across all arn-spark dispatches. The file is template-managed (Pattern 6) so version bumps, drift detection, and the `Template updates: ask | auto | manual` policy all apply.
