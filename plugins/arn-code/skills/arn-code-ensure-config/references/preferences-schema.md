# Pipeline Preference Schema

This reference defines the canonical YAML schema, two-tier storage model, lookup chain, and read/write protocol for all preference-gated skills. Skills that check preferences read this file for consistent behavior.

---

## YAML Schema

All preferences live under the `pipeline:` namespace. Each key accepts a fixed set of string values.

```yaml
pipeline:
  spec-review: review | proceed | upload | ask
  plan-review: review | skip | ask
  implementation-review: review | skip | ask
  sketch-preview: always | never | ask
  simplification: always | auto-all | skip | ask
  expert-debate: standard | auto | ask
```

### Key Definitions

| Key | Values | Gate Behavior |
|-----|--------|---------------|
| `spec-review` | `review` = full spec review with user; `proceed` = auto-proceed to planning; `upload` = user provides own spec file; `ask` = show gate each time (no follow-up) | arn-planning G3 |
| `plan-review` | `review` = present plan for user review; `skip` = auto-approve plan; `ask` = show gate each time (no follow-up) | arn-planning G4 |
| `implementation-review` | `review` = full implementation review; `skip` = skip review (see complexity override below); `ask` = show gate each time (no follow-up) | arn-implementing G4 |
| `sketch-preview` | `always` = generate sketch preview; `never` = skip sketch preview; `ask` = show gate each time (no follow-up) | arn-code-swift 2b, arn-code-standard 2b |
| `simplification` | `always` = run simplification pass; `auto-all` = run simplification and auto-approve all non-deferred findings without prompting (used by batch-implement workers); `skip` = skip simplification; `ask` = show gate each time (no follow-up) | arn-implementing G3, arn-code-swift 4b/5b, arn-code-standard 5b, arn-code-batch-implement workers |
| `expert-debate` | `standard` = standard spec (no expert debate); `auto` = propose expert debate when scope score is 16+ (see threshold below); `ask` = show gate each time (no follow-up) | arn-planning G2 |

---

## Two-Tier Storage Model

Preferences use two personal files. Neither file is committed to version control.

### Global Personal

- **Path:** `~/.arness/workflow-preferences.yaml`
- **Purpose:** Portable across all projects. First write target.
- **Created by:** Gate skills on first encounter (not by ensure-config).

### Project Personal Override

- **Path:** `.arness/workflow.local.yaml`
- **Purpose:** Project-specific overrides. Gitignored via `.arness/*.local.yaml` pattern.
- **Created by:** User manually, or a future management skill. Never created automatically.

### Schema

Both files use the identical schema:

```yaml
pipeline:
  spec-review: review
  plan-review: skip
  implementation-review: review
  sketch-preview: always
  simplification: skip
  expert-debate: standard
```

Keys may be omitted -- only present keys are read. No checksums -- these are user-owned files.

---

## Lookup Chain

```
project override (.arness/workflow.local.yaml)
  > global (~/.arness/workflow-preferences.yaml)
  > null (first encounter)
```

For a given key:

1. Check `.arness/workflow.local.yaml` -- if the file exists and contains the key under `pipeline:`, use that value.
2. If file is missing or key is absent, check `~/.arness/workflow-preferences.yaml` -- if the file exists and contains the key under `pipeline:`, use that value.
3. If both are missing or neither contains the key, treat the value as **null** (first encounter).

---

## Read Protocol

After resolving a key's value through the lookup chain, the skill branches:

### null (First Encounter)

The user has never been asked about this preference.

1. **Show the gate** -- present the AskUserQuestion with the original options.
2. **Show the follow-up** -- after the user answers, ask the memory question (see Write Protocol below).

### ask (Returning Decliner)

The user was previously asked and chose not to store a preference.

1. **Show the gate** -- present the AskUserQuestion with the original options.
2. **Do NOT show the follow-up** -- the user already declined memory. Respect that decision.

### Valid Value (Stored Preference)

The user has a stored preference that matches one of the valid values for this key.

1. **Auto-proceed** -- apply the stored preference without asking.
2. **Show a status line** -- brief message confirming the auto-proceed action and its source.

---

## Write Protocol

### Follow-Up Question

After a gate question is answered and the preference value is **null** (first encounter), ask:

Ask (using `AskUserQuestion`):
> **Should Arness remember this choice for future sessions?**
> 1. Yes, always [action description] (saves to preferences)
> 2. No, ask me each time

- If **Yes:** Write the chosen value to `~/.arness/workflow-preferences.yaml` under the `pipeline:` namespace. Create the file and `~/.arness/` directory if they do not exist.
- If **No:** Write `ask` to `~/.arness/workflow-preferences.yaml` under the `pipeline:` namespace. This marks the user as a returning decliner -- they will still see the gate but not the follow-up.

### First Write Target

All preference writes go to **`~/.arness/workflow-preferences.yaml`** (global). This ensures the preference is portable across projects. If the user later wants a project-specific override, they create `.arness/workflow.local.yaml` manually or via a future management skill.

### File Creation

When writing to `~/.arness/workflow-preferences.yaml` for the first time:

1. Run: `mkdir -p ~/.arness`
2. Write the file with the `pipeline:` namespace and the single key being stored.

When adding a key to an existing file, read the file first, add or update the key under `pipeline:`, and write the file back. Preserve all existing keys.

---

## Invalid Value Handling

If a key's resolved value does not match any valid value for that key (e.g., a typo, an outdated value, or an unrecognized string):

- Treat the value as **null** (first encounter).
- Show the gate question and follow-up as if no preference existed.
- Do not crash, warn, or delete the invalid value from the file.

---

## Complexity Override

When `implementation-review` resolves to `skip`, the skill still recommends a review if the current implementation meets either threshold:

- **3 or more phases** in the implementation plan, OR
- **15 or more files** touched across all phases

When the override triggers:

1. Show a recommendation message: "This implementation touches [N phases / N files]. A review is recommended even though your preference is to skip."
2. Present the review gate as a one-time question (not stored as a preference change).
3. The stored `skip` preference is **not modified** -- the override is situational.

---

## Expert Debate Threshold

When `expert-debate` resolves to `auto`:

- Propose expert debate only when the scope router score is **16 or higher** (top-quartile complexity).
- Below 16, proceed with standard spec without proposing a debate.
- The threshold of 16+ replaces the previous 13+ threshold to reserve expert debate for genuinely exceptional complexity.

---

## Status Line Format

When auto-proceeding with a stored preference, display a brief status line. The format depends on the source file:

**From global file:**
```
Preference: [action description] (stored in workflow-preferences.yaml)
```

**From project override:**
```
Preference: [action description] (project override in workflow.local.yaml)
```

### Examples

```
Preference: proceeding to plan without spec review (stored in workflow-preferences.yaml)
Preference: skipping implementation review (project override in workflow.local.yaml)
Preference: generating sketch preview (stored in workflow-preferences.yaml)
Preference: running simplification pass (stored in workflow-preferences.yaml)
Preference: standard spec, no expert debate (stored in workflow-preferences.yaml)
Preference: expert debate proposed (scope score 18, auto mode in workflow-preferences.yaml)
```
