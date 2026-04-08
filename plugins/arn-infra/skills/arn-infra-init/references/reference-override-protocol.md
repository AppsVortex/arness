# Reference Override Protocol

Reference override initialization and upgrade procedures for arn-infra-init. These procedures manage the 28 evolving reference files that are copied to the user's project and can be refreshed via online research.

---

## Step 8b: Initialize Reference Overrides

Set up locally-owned copies of the 28 evolving reference files so they survive plugin updates and can be refreshed via online research.

**8b.1. Create the overrides directory:**

```bash
mkdir -p .arness/infra-references
```

**8b.2. Read the reference manifest:**

Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-refresh/references/reference-manifest.md` to get the full list of 28 evolving reference files with their source paths and categories.

**8b.3. Copy each file from the plugin to the local overrides directory:**

For each file listed in the manifest, copy from the plugin source to the local directory:

```
${CLAUDE_PLUGIN_ROOT}/skills/<source-path>  -->  .arness/infra-references/<filename>
```

For example:
```
${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-discover/references/mcp-registry.md  -->  .arness/infra-references/mcp-registry.md
```

All 28 filenames are unique across skills, so the flat directory structure works without renaming.

**8b.4. Generate SHA-256 checksums:**

Compute a SHA-256 checksum for each copied file:

```bash
sha256sum .arness/infra-references/*.md
```

Or equivalently: `shasum -a 256 .arness/infra-references/*.md`

**8b.5. Write the checksums file:**

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-refresh/references/reference-checksums-schema.md` for the full schema.

Write `.arness/infra-references/.reference-checksums.json` with:

```json
{
  "version": "1.0.0",
  "pluginVersion": "<version from plugin.json>",
  "lastRefreshed": null,
  "files": {
    "<filename>": {
      "sha256": "<computed-hash>",
      "source": "<source-path-from-manifest>",
      "category": "<category-from-manifest>",
      "lastUpdated": "<current-ISO-8601-timestamp>",
      "updatedBy": "init"
    }
  }
}
```

Populate an entry for each of the 28 files using the source paths and categories from the reference manifest.

**8b.6. Ask for Reference updates preference:**

Ask:

"How should Arness Infra handle reference file updates when the plugin is updated?
1. **Ask** (recommended) -- Prompt you during upgrade, showing which files changed
2. **Auto** -- Automatically update files you haven't customized, warn about customized ones
3. **Manual** -- Never auto-update, just inform you that new versions are available"

Record the answer as `Reference updates: ask | auto | manual`.

The `Reference overrides` path (`.arness/infra-references`) and `Reference version` (plugin version) are set automatically -- no user input needed for those.

---

## Step U1: Reference Upgrade

This step runs during the Update flow (from Step 1) to check whether reference files need upgrading after a plugin update.

**U1.1. Read version information:**

1. Read `Reference version` from the existing `## Arness` config
2. Read current plugin version from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`
3. Read `Reference overrides` path from config (default: `.arness/infra-references`)

**U1.2. Version comparison:**

- If `Reference version` is absent (pre-reference config): run Step 8b (Initialize Reference Overrides) as a fresh setup, then continue
- If `Reference version` matches plugin version: references are up to date, skip to next step
- If `Reference version` differs from plugin version: proceed to conflict detection

**U1.3. Checksum-based conflict detection:**

1. Read the existing `.reference-checksums.json` from the Reference overrides directory
2. Read the reference manifest from `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-refresh/references/reference-manifest.md`
3. For each of the 28 files listed in the manifest:
   a. Compute current SHA-256 of the local file in the overrides directory
   b. Compare against the stored `sha256` value in `.reference-checksums.json`
   c. Classify the file:
      - **Unmodified** (checksum matches stored value): safe to overwrite from plugin
      - **Modified** (checksum differs from stored value): user has customized this file
      - **Missing** (file not in overrides directory): new file added in plugin update

**U1.4. Apply updates based on `Reference updates` preference:**

Read `Reference updates` from config (default: `ask`).

**`auto` with all files unmodified:**
- Copy all 28 files from plugin defaults to the overrides directory
- Recompute SHA-256 checksums for all files
- Update `.reference-checksums.json`: new checksums, `updatedBy: "plugin-update"`, `pluginVersion` set to current plugin version
- Update `Reference version` in config to current plugin version
- Report: "Updated all 28 reference files to plugin version X.Y.Z."

**`auto` with some files modified:**
- Copy unmodified files from plugin defaults (overwrite)
- Skip modified files and preserve the user's version
- Warn: "Skipped N customized files: [list filenames]. These retain your local changes."
- Recompute SHA-256 checksums for all files (updated + preserved)
- Update `.reference-checksums.json`: new checksums for updated files, preserved checksums for skipped files, `pluginVersion` set to current plugin version
- Update `Reference version` in config to current plugin version

**`ask`:**
- Present a summary to the user:
  ```
  Reference files update available (current: X.Y.Z → plugin: A.B.C)

  Unmodified files (safe to update): N files
  Customized files (will be preserved): M files
  [list customized filenames if any]
  ```
- Ask:
  1. **Update now** -- Update unmodified files, preserve customized ones
  2. **Skip** -- Keep current reference files, do not update
  3. **Always auto-update** -- Update now and change preference to `auto`
  4. **Never ask** -- Skip and change preference to `manual`
- If **Update now** or **Always auto-update**: copy unmodified files from plugin, skip modified files, regenerate checksums, update `Reference version`
- If **Always auto-update**: also update `Reference updates` in config to `auto`
- If **Never ask**: also update `Reference updates` in config to `manual`
- If **Skip**: leave files unchanged, do not update `Reference version`

**`manual`:**
- Inform the user: "New reference file versions are available in plugin version X.Y.Z. Your local reference files were not changed. Run `/arn-infra-init` and choose Update to apply them later."
- Do not touch files or update `Reference version`
