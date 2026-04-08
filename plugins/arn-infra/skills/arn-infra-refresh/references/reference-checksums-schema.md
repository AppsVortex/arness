# Reference Checksums Schema

JSON schema for `.reference-checksums.json` -- the checksum tracking file for externalized reference overrides in `.arness/infra-references/`. This file is managed by `arn-infra-init` (creation and plugin updates) and `arn-infra-refresh` (research-driven updates). It is separate from `.arness/templates/.checksums.json` used by Arness core template versioning.

---

## Schema

```json
{
  "version": "1.0.0",
  "pluginVersion": "1.0.0",
  "lastRefreshed": "2026-03-13T00:00:00Z",
  "files": {
    "mcp-registry.md": {
      "sha256": "a1b2c3d4e5f6...",
      "source": "arn-infra-discover/references/mcp-registry.md",
      "category": "registries",
      "lastUpdated": "2026-03-13T00:00:00Z",
      "updatedBy": "init"
    },
    "opentofu-patterns.md": {
      "sha256": "f6e5d4c3b2a1...",
      "source": "arn-infra-define/references/opentofu-patterns.md",
      "category": "iac-patterns",
      "lastUpdated": "2026-03-13T12:30:00Z",
      "updatedBy": "refresh"
    }
  }
}
```

---

## Field Descriptions

### Top Level

| Field | Type | Description |
|-------|------|-------------|
| `version` | string | Schema version for forward compatibility. Current: `"1.0.0"`. Bumped when the schema structure changes. |
| `pluginVersion` | string | The arn-infra plugin version (`plugin.json` version) that last wrote to this file. Used during plugin upgrades to detect whether new reference files were added or removed. |
| `lastRefreshed` | string | ISO 8601 timestamp of the most recent `arn-infra-refresh` run. Set to `null` if no refresh has been performed yet (init-only state). |
| `files` | object | Map of filename to checksum entry. Keys are bare filenames (e.g., `"mcp-registry.md"`) matching the files in `.arness/infra-references/`. |

### Per-File Entry

| Field | Type | Valid Values | Description |
|-------|------|-------------|-------------|
| `sha256` | string | 64-character hex string | SHA-256 hash of the file content at time of last write. Used to detect user modifications during plugin upgrades and refresh operations. |
| `source` | string | Relative path from `${CLAUDE_PLUGIN_ROOT}/skills/` | The original source path within the plugin. Used to locate the plugin default when computing diffs or falling back. |
| `category` | string | `"registries"` \| `"iac-patterns"` \| `"container-patterns"` \| `"cicd-patterns"` \| `"cloud-patterns"` \| `"infra-guides"` | The refresh category this file belongs to. Used by `arn-infra-refresh` for category-based refresh operations. |
| `lastUpdated` | string | ISO 8601 timestamp | When this specific file was last written (by init, refresh, or plugin update). |
| `updatedBy` | string | `"init"` \| `"refresh"` \| `"plugin-update"` | Which operation last wrote this file. Helps users understand the provenance of each override. |

---

## Lifecycle

### Creation (arn-infra-init -- Fresh Install)

When `arn-infra-init` runs for the first time:

1. Creates `.arness/infra-references/` directory
2. Copies all 28 evolving reference files from plugin defaults
3. Computes SHA-256 for each copied file
4. Writes `.reference-checksums.json` with all entries, `updatedBy: "init"`, and `lastRefreshed: null`

### Plugin Upgrade (arn-infra-init -- Upgrade Flow)

When `arn-infra-init` detects a plugin version change:

1. Reads existing `.reference-checksums.json`
2. For each of the 28 files, computes current SHA-256 of the local override
3. Compares against stored `sha256`:
   - **Match (unmodified):** Overwrites with new plugin default, updates `sha256`, sets `updatedBy: "plugin-update"`
   - **Mismatch (user-modified):** Behavior depends on `Reference updates` config field:
     - `auto`: Updates unmodified files silently; skips user-modified files and warns (user changes preserved)
     - `ask`: Prompts user per-file: keep local, accept plugin default, or merge
     - `manual`: Skips the file, preserves user version
4. Updates `pluginVersion` to new version

### Refresh (arn-infra-refresh)

When `arn-infra-refresh` updates files via online research:

1. Reads existing `.reference-checksums.json`
2. For each refreshed file, writes updated content to `.arness/infra-references/`
3. Computes new SHA-256
4. Updates the entry: new `sha256`, `lastUpdated` to now, `updatedBy: "refresh"`
5. Updates top-level `lastRefreshed` timestamp

---

## File Location

The checksums file is stored at:

```
<project-root>/.arness/infra-references/.reference-checksums.json
```

This keeps it co-located with the reference override files it tracks, inside the `.arness/` project configuration directory.

---

## Category Values

The `category` field maps to the 6 groupings defined in `reference-manifest.md`:

| Category | Description | File Count |
|----------|-------------|-----------|
| `registries` | Tool and provider registries | 4 |
| `iac-patterns` | Infrastructure-as-Code patterns | 7 |
| `container-patterns` | Container build and orchestration patterns | 2 |
| `cicd-patterns` | CI/CD pipeline patterns | 3 |
| `cloud-patterns` | Cloud environment and observability patterns | 4 |
| `infra-guides` | Infrastructure guides and checklists | 8 |

---

## Checksum Computation

Checksums are computed at write-time using SHA-256:

```bash
sha256sum .arness/infra-references/mcp-registry.md | cut -d' ' -f1
```

Or equivalently:

```bash
shasum -a 256 .arness/infra-references/mcp-registry.md | cut -d' ' -f1
```

The checksum covers the exact file content as written. No normalization (line endings, trailing newlines) is applied -- the hash is computed on the raw bytes.

---

## Relationship to Template Checksums

This checksums file is **independent** from Arness core's `.arness/templates/.checksums.json`:

| Aspect | Template Checksums | Reference Checksums |
|--------|-------------------|-------------------|
| File | `.arness/templates/.checksums.json` | `.arness/infra-references/.reference-checksums.json` |
| Managed by | `arn-code-init` | `arn-infra-init`, `arn-infra-refresh` |
| Tracks | Report templates (JSON) | Infrastructure reference files (Markdown) |
| Update trigger | Arness plugin version change | Arness-infra plugin version change or manual refresh |
| Scope | Arness core pipeline | Arness-infra infrastructure workflows |
