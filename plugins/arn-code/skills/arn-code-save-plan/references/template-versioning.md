# Template Version Check Procedure

This procedure checks whether a project's report templates are up to date with the plugin version and handles updates based on user preference. It is invoked from any skill that reads the `## Arness` configuration and finds `Template version` and `Template updates` fields.

## Preconditions

- The `## Arness` section in the project's CLAUDE.md contains `Template version` and `Template updates` fields.
- If either field is missing, treat as legacy and skip this procedure entirely.

## Procedure

1. Read `Template updates` preference.

2. Read `Template version` from `## Arness` (e.g., `0.1.0`).

3. Read `version` from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`.

4. If versions match -- templates are up to date. Skip to main workflow.

5. If versions differ -- always check for new plugin templates first, then handle existing file updates based on preference:
   a. Compute current checksums of user's templates via Bash:
      ```
      sha256sum <template-path>/*.json 2>/dev/null || shasum -a 256 <template-path>/*.json
      ```
   b. Read `<template-path>/.checksums.json` for original checksums.
   c. List plugin templates via Bash:
      ```
      ls ${CLAUDE_PLUGIN_ROOT}/skills/arn-code-save-plan/report-templates/default/*.json
      ```
   d. Compare and classify each file into 4 categories:
      - **Unmodified**: exists in both user project and plugin, user hash matches `.checksums.json`
      - **Modified**: exists in both user project and plugin, user hash differs from `.checksums.json`
      - **Missing**: in `.checksums.json` but not on user disk (user deleted it)
      - **New in plugin**: exists in plugin directory but NOT in user's `<template-path>/` — this detects templates added in newer plugin versions
   e. **New-template rule:** Files classified as "new in plugin" are ALWAYS copied to the user's template directory, **regardless of the Template updates preference**. These are additions, not modifications — the user never had them, so there is nothing to override. After copying, generate their checksums and add them to `.checksums.json`. Log: "Added new template(s): [list of filenames]". This rule applies even when Template updates is `manual` — the user opted out of updates to existing templates, not additions of new ones.
   f. If Template updates is `manual`: stop here. New templates were already added in 5e. Do not update existing templates. Update `Template version` in `## Arness` to the current plugin version (so the new-file check doesn't re-trigger on every invocation). Proceed with template path as-is.
   g. Based on preference (for existing files only — new files already handled in 5e):

      **`auto` + all files unmodified:**
      - Copy new templates from `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-save-plan/report-templates/default/`
      - Regenerate `.checksums.json`
      - Update `Template version` in `## Arness`
      - Inform user: "Templates updated from [old] to [new]."

      **`auto` + some files modified:**
      - Warn: "Templates updated (v[old] -> v[new]), but you customized: [list]. Overwrite or keep?"
      - If overwrite: copy all, regenerate checksums, update version
      - If keep: copy only unmodified, regenerate checksums, update version

      **`ask`:**
      - Inform: "Arness templates updated (v[old] -> v[new])."
      - If modified files exist, list them.
      - Present 4 options:
        1. **"Yes, update now"** -- copy + update. Keep preference `ask`.
        2. **"No, skip this time"** -- skip. Keep preference `ask`.
        3. **"Always auto-update"** -- copy + update. Change preference to `auto`.
        4. **"Never ask, I'll manage them"** -- skip. Change preference to `manual`.
