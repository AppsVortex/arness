# Cross-Reference Algorithm

Reference for the `arn-code-catch-up` skill. Describes the complete algorithm for scanning git history, cross-referencing commits against existing Arness artifacts, and classifying each commit as tracked, likely tracked, untracked, or pre-Arness.

---

## Scan Range Detection

Determine the start date for the git log scan using a three-tier fallback:

1. **Tier-tag commit:** Search git log for the most recent commit message containing `[swift]`, `[standard]`, `[thorough]`, or `[catchup]` tier tags. If found, use that commit's date as the scan start.
   ```
   git log --all --format='%H|%aI|%s' --grep='\[swift\]\|\[standard\]\|\[thorough\]\|\[catchup\]' -1
   ```
2. **PROGRESS_TRACKER fallback:** Read all `PROGRESS_TRACKER.json` files in the plans directory. Use the most recent `lastUpdated` timestamp found.
3. **30-day default:** If neither of the above produces a result, use 30 days before the current date.

The scan end is always `HEAD`.

---

## Commit Collection

Run `git log` to collect all commits in the scan range:

```
git log --format='%H|%aI|%s' --no-merges --after=<scan-start>
```

- Filter out merge commits with `--no-merges`.
- Parse each line into: commit hash, author date (ISO 8601), and subject line.

**Input validation:** Commit hashes used in subsequent git commands (e.g., `git diff-tree`) must be validated as 40-character hex strings matching the pattern `^[0-9a-f]{40}$`. Dates used in `--after` must be validated as ISO 8601 format. This prevents unexpected shell behavior from malformed git log output.

---

## Cross-Reference Against Existing Artifacts

### Primary Match: CHANGE_RECORD commitHash Fields

Scan all `CHANGE_RECORD.json` files in the plans directory using these glob patterns:
- `SWIFT_*/CHANGE_RECORD.json`
- `STANDARD_*/CHANGE_RECORD.json`
- `CATCHUP_*/CHANGE_RECORD.json`
- `*/CHANGE_RECORD.json`

Extract the `commitHash` field from each. Mark any commit whose hash appears in a CHANGE_RECORD as **"tracked"**.

### Secondary Match: Tier Tags in Commit Messages

If a commit message contains `[swift]`, `[standard]`, `[thorough]`, or `[catchup]`, mark it as **"tracked"** even if no CHANGE_RECORD has the exact hash. This handles manual commits made after pipeline runs.

### Secondary Match: File Overlap

For remaining unmatched commits, run:

```
git diff-tree --no-commit-id --name-only -r <hash>
```

to get the list of modified files. Compare against `filesModified` and `filesCreated` arrays in all CHANGE_RECORD.json files. If >80% of the commit's files overlap with any single CHANGE_RECORD, mark the commit as **"likely tracked"** (present to user for confirmation).

### Report File Hash Scanning

Check if any implementation/testing report JSONs (`IMPLEMENTATION_REPORT_*.json`, `TESTING_REPORT_*.json`) reference the commit hash in their content. If found, mark as **"tracked"**.

---

## Idempotency

CATCHUP_ CHANGE_RECORD.json files contain a `catchup.coveredCommits` array listing all commit hashes covered by that catch-up record. Before classifying a commit, check if its hash appears in any existing CATCHUP_ record's `coveredCommits` array. If so, exclude it from the current run.

This ensures running `arn-code-catch-up` multiple times never creates duplicate records for the same commits.

---

## Boundary Detection

If unmatched commits exist whose dates are before the earliest Arness artifact's date (the oldest `timestamp` across all CHANGE_RECORD.json files, or the oldest spec/plan file creation date), classify them as **"pre-Arness"**. These commits predate Arness tracking and receive a boundary marker record rather than individual catch-up records.

To determine the boundary:
1. Find the earliest `timestamp` across all CHANGE_RECORD.json files in the plans directory.
2. If no CHANGE_RECORD files exist, use the creation date of the oldest spec or plan file.
3. If no Arness artifacts exist at all, all commits are classified as pre-Arness.

---

## Tiered Batching

After classification, determine the batching strategy based on the count of untracked commits:

### 1-5 Untracked Commits: Individual Records

Create one CATCHUP_ record per commit. Each record covers a single commit with its own `CHANGE_RECORD.json` and markdown summary.

### 6-20 Untracked Commits: Grouped Records

Group commits by theme using clustering logic:

1. **File path overlap:** Commits touching the same directory or module are grouped together.
2. **Commit message keyword overlap:** Extract significant terms from commit messages (after stopword removal). Commits sharing 2+ significant terms are candidates for the same group.
3. **Temporal proximity:** Commits within 2 hours of each other are candidates for the same group.

A commit is assigned to a group if it matches on at least 2 of the 3 clustering criteria. Ungrouped commits form their own single-commit groups.

Present the proposed groups to the user for confirmation or adjustment:
- **Split:** Break a group into smaller groups
- **Merge:** Combine two groups into one
- **Rename:** Change a group's theme name

### 21+ Untracked Commits: Summary Record

Create a single summary record covering all untracked commits. The record includes:
- A complete list of covered commit hashes
- A high-level summary of what changed (file-level stats, most-affected directories)
- A boundary marker indicating the range covered

### Pre-Arness Commits Only: Boundary Marker

If the only unmatched commits are pre-Arness, generate only a boundary marker record (no individual or grouped records). The boundary marker documents how many commits predate Arness tracking and where the boundary falls.
