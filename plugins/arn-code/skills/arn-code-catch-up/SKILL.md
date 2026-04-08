---
name: arn-code-catch-up
description: >-
  This skill should be used when the user says "catch up", "catch-up",
  "arness code catch up", "retroactive docs", "document old commits",
  "backfill artifacts", "what did I miss", "undocumented commits",
  "catch up on commits", "document past work", "backfill records",
  or wants to retroactively document commits that were made outside the Arness pipeline.
version: 1.0.0
---

# Arness Catch-Up

Developers sometimes bypass the pipeline for quick fixes -- the "2am gap." These commits ship without specs, plans, or records, leaving holes in the artifact trail. Catch-up scans git history, identifies commits that have no corresponding Arness artifacts, and generates lightweight CATCHUP_ records in the CHANGE_RECORD.json envelope. The records are honest about what can and cannot be recovered retroactively: they document what changed (files, diffs, commit messages) and explicitly flag what is unknown (intent, test coverage, architectural reasoning).

This is a standalone skill. It operates outside the main pipeline and can be run at any time.

---

## Step 0: Ensure Configuration

Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-ensure-config/references/ensure-config.md` and follow its instructions. This guarantees a user profile exists and `## Arness` is configured with Arness Code fields before proceeding.

---

## Step 1: Load Configuration

Read the `## Arness` section from CLAUDE.md. Extract the following fields:

- **Plans directory** -- where Arness project artifacts live (CHANGE_RECORD.json files, SWIFT_*, STANDARD_*, CATCHUP_* directories)
- **Specs directory** -- where spec files live (for boundary detection)
- **Code patterns** -- path to pattern documentation (for pattern refresh in Step 6)
- **Template path** -- path to report templates (for CATCHUP_REPORT_TEMPLATE.json)
- **Template version** -- plugin version the templates were copied from (if present)
- **Template updates** -- user preference: `ask`, `auto`, or `manual` (if present)

**Template version check:** If `Template version` and `Template updates` fields are present, run the template version check procedure documented in `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-save-plan/references/template-versioning.md` before proceeding. If `## Arness` does not contain these fields, treat as legacy and skip.

Validate that all paths exist. If the plans directory does not exist, inform the user: "Plans directory not found. Run `/arn-planning` to set up Arness." and exit.

---

## Step 2: Determine Scan Range

Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-catch-up/references/cross-reference-algorithm.md` for the scan range detection procedure.

Execute the three-tier fallback:

1. Search git log for the most recent commit with a `[swift]`, `[standard]`, `[thorough]`, or `[catchup]` tier tag.
2. If not found, read `PROGRESS_TRACKER.json` files in the plans directory and use the most recent `lastUpdated` timestamp.
3. If neither found, use 30 days before the current date.

Display:

```
Scanning commits from <date> to HEAD (<N> commits in range).
Scan range determined by: <method> (tier-tag commit | progress tracker | 30-day default)
```

Offer override:

```
Adjust scan range? (Enter a date or commit hash, or press Enter to continue)
```

If the user provides a date or commit hash, adjust the scan start accordingly.

---

## Step 3: Cross-Reference and Identify Untracked Commits

Follow the cross-reference algorithm from `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-catch-up/references/cross-reference-algorithm.md`.

Execute these steps in order:

1. **Collect commits:** Run `git log --format='%H|%aI|%s' --no-merges --after=<scan-start>` to get all commits in range. Validate commit hashes as 40-character hex strings.

2. **Primary match:** Scan all `CHANGE_RECORD.json` files in the plans directory. Extract `commitHash` fields. Mark any commit whose hash appears in a CHANGE_RECORD as "tracked".

3. **Secondary match -- tier tags:** If a commit message contains `[swift]`, `[standard]`, `[thorough]`, or `[catchup]`, mark as "tracked".

4. **Secondary match -- file overlap:** For remaining unmatched commits, run `git diff-tree --no-commit-id --name-only -r <hash>` to get modified files. Compare against `filesModified` and `filesCreated` arrays in CHANGE_RECORD.json files. If >80% file overlap with any CHANGE_RECORD, mark as "likely tracked".

5. **Report file scanning:** Check if any `IMPLEMENTATION_REPORT_*.json` or `TESTING_REPORT_*.json` files reference the commit hash.

6. **Idempotency check:** Scan existing CATCHUP_ CHANGE_RECORD.json files for `catchup.coveredCommits` arrays. Exclude any commit whose hash already appears in a previous catch-up record.

7. **Boundary detection:** Identify commits whose dates precede the earliest Arness artifact. Classify these as "pre-Arness".

Classify each commit as one of:
- **tracked** -- matched to an existing Arness artifact
- **likely tracked** -- high file overlap with an existing artifact (needs user confirmation)
- **untracked** -- no match found
- **pre-Arness** -- predates the earliest Arness artifact

---

## Step 4: Present Overview and Confirm

Display the findings:

```
Scan Results
============
Total commits in scan range:           <N>
Tracked (matched to Arness artifacts):   <N>
Likely tracked (file overlap match):   <N>
Untracked:                             <N>
Pre-Arness (predates earliest artifact): <N>
```

If there are "likely tracked" commits, list them for manual confirmation:

```
The following commits have >80% file overlap with existing artifacts:
  <short-hash> <message> -- overlaps with <CHANGE_RECORD path>
  ...
Mark these as tracked? (They will be excluded from catch-up records if confirmed.)
```

Display the proposed batching tier:
- 1-5 untracked: "Batching: **individual** (one record per commit)"
- 6-20 untracked: "Batching: **grouped** (commits clustered by theme)"
- 21+ untracked: "Batching: **summary** (single summary record)"

If grouped (6-20), show the proposed theme groupings with commit lists per group.

Ask (using `AskUserQuestion`):

**"Generate catch-up records for [N] untracked commits?"**

1. **Yes, generate** -- Proceed with proposed batching
2. **Adjust groupings** -- Modify theme groups (split, merge, rename)
3. **Exclude some commits** -- Deselect specific commits from the list
4. **Cancel** -- Exit without generating records

If the user chooses option 2 (Adjust groupings), present the groups and allow modifications, then re-ask the question. If the user chooses option 3 (Exclude some commits), show the commit list and let the user deselect, then re-ask with updated count.

---

## Step 5: Generate CATCHUP_ Records

Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-catch-up/references/catchup-record-format.md` for the record format specification.

Read `CATCHUP_REPORT_TEMPLATE.json` from the template path configured in `## Arness` (field: **Template path**). If the template is not found in the project template directory, fall back to the plugin default at `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-save-plan/report-templates/default/CATCHUP_REPORT_TEMPLATE.json`.

For each record (individual, grouped, or summary):

1. **Create the directory:**
   ```
   mkdir -p <plans-dir>/CATCHUP_<name>/
   ```

2. **Generate `CHANGE_RECORD.json`** using the template with the `catchup` extension object:
   - Set `ceremonyTier` to `"catchup"`
   - Populate `filesModified` and `filesCreated` from `git diff-tree` output
   - Set `commitHash` to the commit hash (individual) or the latest commit hash in the group
   - Set `commitMessage` to the commit message (individual) or a generated group summary
   - Populate `catchup.coveredCommits` with all commit hashes covered by this record
   - Populate `catchup.scanRange` with the scan window and detection method
   - Always set `catchup.confidence` to `"low"`
   - Populate `catchup.gaps` honestly -- list what information is missing
   - Populate `catchup.whatWeKnow` from git data (files changed, commit message, diff stats)
   - Populate `catchup.whatWeDontKnow` with standard unknowns (intent, test coverage, architectural reasoning)

3. **Generate `CATCHUP_<name>.md`** markdown summary using the "What We Know / What We Don't Know" framing as specified in the record format reference.

4. Always set `confidence: "low"`. Populate `gaps[]` honestly. Do not fabricate intent or reasoning -- only document what git data can prove.

If pre-Arness commits were detected, generate a boundary marker record:
- Directory: `<plans-dir>/CATCHUP_pre-arness-boundary/`
- `CHANGE_RECORD.json` with `catchup.boundaryMarker: true`
- `CATCHUP_pre-arness-boundary.md` boundary marker markdown

Display:

```
Generated <N> catch-up record(s) in <plans-dir>/:
  CATCHUP_<name1>/
  CATCHUP_<name2>/
  ...
```

---

## Step 6: Pattern Refresh (Conditional)

Check if any of the untracked commits modified files that are referenced in the pattern documentation (code-patterns.md, testing-patterns.md, architecture.md, ui-patterns.md).

To check: extract the file paths from each untracked commit using `git diff-tree --no-commit-id --name-only -r <hash>`. Compare these paths against the "Reference" fields in the pattern documentation files.

If pattern-relevant files were modified:

Ask (using `AskUserQuestion`):

**"Untracked commits modified files referenced in your pattern documentation. Refresh pattern docs now?"**

Options:
1. **Yes, refresh patterns** -- Run the pattern refresh procedure
2. **No, skip** -- Keep current patterns as-is

If **Yes:**

Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-execute-plan/references/pattern-refresh.md` and follow the pattern refresh procedure.

If **No:** skip silently.

If no pattern-relevant files were modified, skip this step silently (no message needed).

---

## Step 7: Completion Summary

Display the final summary:

```
Catch-Up Complete
=================
Records generated:   <N> individual / <N> groups / 1 summary
Boundary marker:     yes / no
Pattern refresh:     performed / skipped
Commits now tracked: <N> (of <N> total untracked)
```

Offer next steps:

```
Run `/arn-code-ship` to commit the catch-up records.
```

Note:

```
Run `/arn-code-catch-up` again after more out-of-pipeline commits -- it's idempotent and won't create duplicates.
```

---

## Error Handling

- **Git not available** -- inform user: "This project is not a git repository. `/arn-code-catch-up` requires Git." and exit.
- **Plans directory missing** -- inform user: "Plans directory not found. Run `/arn-planning` to set up Arness." and exit.
- **No commits in scan range** -- inform user: "No commits found in the scan range (<start> to HEAD)." and exit.
- **All commits tracked** -- inform user: "All commits in the scan range are already tracked by Arness artifacts. Nothing to catch up on." and exit.
- **Git log command fails** -- display the error, suggest checking git configuration.
- **CHANGE_RECORD.json parse error** -- warn about the malformed file, skip it, continue with remaining files.
- **Template not found** -- fall back to plugin default template. If that also fails, generate records without the template (use the record format reference as the schema).
