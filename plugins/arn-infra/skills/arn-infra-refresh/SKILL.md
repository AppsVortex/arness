---
name: arn-infra-refresh
description: >-
  This skill should be used when the user says "refresh infra references",
  "update tool versions", "check for new MCPs", "update infra patterns",
  "refresh registries", "arn infra refresh", "infra refresh",
  "update references", "check for updates", "refresh infrastructure tools",
  "update MCP servers", "refresh CLI versions", "update base images",
  "arn-infra-refresh", or wants to update the version-sensitive
  infrastructure reference files (tool versions, MCP packages, CLI commands,
  base image tags, IaC patterns) using online research.
version: 1.0.0
---

# Arness Infra Refresh

Refresh the project-local infrastructure reference files using online research. This skill searches for the latest stable versions of tools, MCP servers, CLI commands, base image tags, and IaC patterns, then updates the externalized reference overrides in `.arness/infra-references/` while preserving checksums for future conflict detection.

The 28 evolving reference files are organized into 6 categories (registries, IaC patterns, container patterns, CI/CD patterns, cloud patterns, infrastructure guides). Users can refresh all categories at once, select specific categories, or target a single file.

## Prerequisites

Read `## Arness` from the project's CLAUDE.md. If no `## Arness` section exists or Arness Infra fields are missing, inform the user: "Arness Infra is not configured for this project yet. Run `/arn-infra-wizard` to get started — it will set everything up automatically." Do not proceed without it.

Extract:
- **Experience level** -- derived from user profile. Read `~/.arness/user-profile.yaml` (or `.claude/arness-profile.local.md` if it exists — project override takes precedence). Apply the experience derivation mapping from `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-ensure-config/references/experience-derivation.md`. If no profile exists, check for legacy `Experience level` in `## Arness` as fallback.
- **Reference overrides** -- path to the project-local reference directory (e.g., `.arness/infra-references`)
- **Reference version** -- current reference version for display

If **Reference overrides** is not configured, stop and instruct the user: "Reference overrides are not configured. Run `/arn-infra-init` (or upgrade your existing configuration) to set up reference externalization before refreshing."

---

## Workflow

### Step 1: Load Current State

Read the checksums tracking file and the reference manifest to understand the current state of all externalized reference files.

1. Read `.reference-checksums.json` from the **Reference overrides** path (e.g., `.arness/infra-references/.reference-checksums.json`)
2. Read the reference manifest: `Read ${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-refresh/references/reference-manifest.md`
3. **Reconcile new files:** If the manifest lists files not present in `.reference-checksums.json`, these are newly added reference files from a plugin update. Copy them from the plugin defaults (`${CLAUDE_PLUGIN_ROOT}/skills/<source-path>`) to the Reference overrides directory, generate their SHA-256 checksums, and add them to `.reference-checksums.json` with `updatedBy: "init"` before proceeding.

Present current state to the user:

"**Reference Overrides Status:**
- **Reference version:** [Reference version from config]
- **Plugin baseline version:** [pluginVersion from checksums]
- **Last refreshed:** [lastRefreshed from checksums, or 'Never' if null]
- **Total files tracked:** [count of files in checksums]
- **Categories:** [list of unique categories with file counts]"

---

### Step 2: Select Refresh Scope

Present scope selection adapted to the user's experience level.

**Expert:**

Ask (using `AskUserQuestion`):

**"Refresh scope?"**

Options:
1. **All (28 files)** -- Refresh every reference file across all categories
2. **Select categories** -- Choose which categories to refresh
3. **Single file** -- Specify a single filename to refresh individually

If **All (28 files)**: proceed to Step 3 with all 28 files selected.

If **Single file**: ask the user to specify the filename. Proceed to Step 3 with that single file.

If **Select categories**:

Ask (using `AskUserQuestion`) with 2 questions:

Q1 (multiSelect: true): **"Tooling categories (select any):"**

Options:
1. **Registries** (4 files) -- MCP servers, CLIs, plugins, secrets providers
2. **IaC Patterns** (7 files) -- OpenTofu, Pulumi, CDK, Bicep, Kubernetes, PaaS, validation
3. **Container Patterns** (2 files) -- Dockerfile base images, Compose syntax

Q2 (multiSelect: true): **"Operations categories (select any):"**

Options:
1. **CI/CD Patterns** (3 files) -- GitHub Actions, GitLab CI, pipeline security
2. **Cloud Patterns** (4 files) -- Environment config, promotion, alerting, observability
3. **Infrastructure Guides** (8 files) -- Provider overviews, IaC tools, detection, deployment

Combine the selected categories from both questions and proceed to Step 3 with the matching files.

**Intermediate:**
Present a recommended scope:

"I recommend refreshing **Registries** and **IaC Patterns** -- these categories change most frequently and have the highest impact on generated infrastructure code.

- **Registries** (4 files) -- tool versions, install commands, MCP packages
- **IaC Patterns** (7 files) -- syntax, module references, best practices"

Ask (using `AskUserQuestion`):

**"How would you like to proceed?"**

Options:
1. **Recommended** -- Refresh Registries and IaC Patterns (11 files)
2. **All** -- Refresh all 28 reference files
3. **Full menu** -- See the full category selection (Expert view)

**Beginner:**
Default to refreshing all categories:

"I'll refresh all 28 reference files across all categories to make sure everything is up to date. This will search online for the latest stable versions of tools, patterns, and configurations."

Ask (using `AskUserQuestion`):

**"Refresh all 28 reference files?"**

Options:
1. **Yes** -- Proceed with refreshing all references
2. **No** -- Cancel

---

### Step 3: Parallel Online Research

For each selected category, spawn the `arn-infra-reference-researcher` agent to research current versions and compare against the local reference content.

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-refresh/references/research-strategies.md` for per-category search queries and verification procedures.

For each file in the selected categories:

1. Read the current content of the local override file from the **Reference overrides** path. If the file is missing, copy it from the plugin default (`${CLAUDE_PLUGIN_ROOT}/skills/<source-path-from-manifest>`) before proceeding, and record the copy in `.reference-checksums.json` with `updatedBy: "init"`.
2. Read the research strategy for the file's category from `research-strategies.md`

Invoke the `arn-infra-reference-researcher` agent via the Task tool with:

```text
--- CURRENT FILE CONTENT ---
Filename: [filename]
Category: [category]
Source path: [source from checksums]

[full content of the local override file]
--- END CURRENT FILE CONTENT ---

--- RESEARCH INSTRUCTIONS ---
[per-category research strategy from research-strategies.md]

Research the latest stable versions, package names, and patterns for the content
in this file. Compare against the current content and report any updates needed.

Rules:
- Only recommend stable/GA releases, never alpha/beta/RC
- Only recommend official first-party tools
- Include source URLs for every finding
- Flag breaking changes or deprecations prominently
- If no updates are found, report "No updates found" rather than guessing
--- END RESEARCH INSTRUCTIONS ---
```

When multiple categories are selected, spawn researcher agents in parallel (one per category or per file, depending on the scope size) to minimize total research time.

---

### Step 4: Present Findings

Aggregate the results from all researcher agents and present a summary.

**If updates were found:**

"**Refresh Findings:**

**[Category 1]:**
| File | Change | Old Value | New Value | Source |
|------|--------|-----------|-----------|--------|
| [filename] | [what changed] | [old] | [new] | [URL] |
| ... | ... | ... | ... | ... |

**[Category 2]:**
| File | Change | Old Value | New Value | Source |
|------|--------|-----------|-----------|--------|
| ... | ... | ... | ... | ... |

**Summary:** [N] updates found across [M] files in [K] categories.
**Breaking changes:** [list any breaking changes, or 'None']"

**If no updates were found:**

"All reference files are up to date. No changes needed."

---

### Step 5: Apply Updates

If updates were found:

Ask (using `AskUserQuestion`):

**"How would you like to proceed with the [N] updates found?"**

Options:
1. **Apply all** -- Update all [N] files with the findings
2. **Review each** -- Step through each update for individual approval
3. **Cancel** -- Keep current references unchanged

**For each approved update:**

1. Read the current content of the local override file
2. Compute the current SHA-256 checksum
3. Compare with the stored checksum in `.reference-checksums.json`:
   - **Match:** Apply the update (no local modifications since last write)
   - **Mismatch:** Alert the user: "This file has been modified since the last refresh/init. Overwrite with the researched update, or skip?" (see Error Handling case 8)
4. Write the updated content to the local override file in the **Reference overrides** path
5. Compute the new SHA-256 checksum
6. Update `.reference-checksums.json`:
   - Set the file's `sha256` to the new checksum
   - Set `lastUpdated` to the current ISO 8601 timestamp
   - Set `updatedBy` to `"refresh"`
7. Update the top-level `lastRefreshed` timestamp in `.reference-checksums.json`

---

### Step 6: Summary

Present a final summary of the refresh operation:

"**Refresh Complete:**
- **Files checked:** [total files in scope]
- **Files updated:** [count of files that were updated]
- **Files skipped:** [count of files with no updates or user-skipped]
- **Categories refreshed:** [list of category names]
- **Timestamp:** [current ISO 8601 timestamp]

**Next steps:**
- Run the relevant skills to see your updated references in action:
  - `/arn-infra-discover` -- re-discover tools with updated registries
  - `/arn-infra-define` -- generate IaC with updated patterns
  - `/arn-infra-containerize` -- build containers with updated base images
  - `/arn-infra-pipeline` -- update CI/CD with latest action versions"

---

## Error Handling

- **`## Arness` config missing:** Suggest running `/arn-infra-wizard` to get started. Stop.
- **No Reference overrides configured:** Suggest running `/arn-infra-init` or upgrading the existing configuration to enable reference externalization. Stop.
- **`.reference-checksums.json` missing:** Regenerate the checksums file by cross-referencing files in the Reference overrides directory against the reference manifest. For each matched file, compute its SHA-256 and populate `source` and `category` from the manifest, set `lastUpdated` to the current timestamp, and `updatedBy` to `"regenerated"`. Files in the overrides directory that do not appear in the manifest are left untracked. Warn: "Checksums file was missing and has been regenerated. Checksum-based conflict detection may be inaccurate until the next full refresh."
- **Override file missing from overrides directory:** Copy the file from the plugin default (`${CLAUDE_PLUGIN_ROOT}/skills/<source-path-from-manifest>`) to the Reference overrides directory. Add it to `.reference-checksums.json` with `updatedBy: "init"`. Then proceed with research as normal.
- **WebSearch unavailable:** Skip online research. Inform the user: "WebSearch is not available. Online research cannot be performed. To refresh references, ensure WebSearch is enabled and try again."
- **Researcher agent fails:** Report the error for the affected category. Continue with remaining categories. Note in the summary: "Research failed for [category]. [N] of [M] categories were refreshed successfully."
- **Researcher agent returns empty output:** Report: "No updates found for [category]." Continue with remaining categories. This is not an error -- it means the references are current.
- **File write fails:** Report the error for the affected file. Continue with remaining files. Note in the summary: "Write failed for [filename]. [N] of [M] files were updated successfully."
- **Checksum mismatch during apply:** The local file has been modified since the last tracked write. Ask the user: "The file `[filename]` has been modified since the last refresh/init. Would you like to overwrite with the researched update, or skip this file?" If overwrite: apply the update and record the new checksum. If skip: leave the file unchanged.
- **Re-running is safe:** Refreshing is idempotent. Re-running will research again and apply any new updates found. Files that are already up to date will be reported as "No updates found."
