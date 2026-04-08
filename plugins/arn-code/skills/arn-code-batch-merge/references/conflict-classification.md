# Conflict Classification Algorithm

Reference for the `arn-code-batch-merge` skill. Defines how to classify file conflicts between two features based on their CHANGE_RECORD.json file lists.

---

## Prerequisites

This algorithm requires that all PR branches are available locally for hunk analysis (Rule C). The calling skill must fetch them before invoking this procedure: `git fetch origin <branch>` for each PR branch.

**Limitation:** This algorithm uses path-based file matching. If one feature renames a file that another feature modifies, the overlap will not be detected. This is a known edge case.

## Input

Two CHANGE_RECORD.json files, each containing:
- `filesModified` — array of file paths modified by the feature
- `filesCreated` — array of file paths created by the feature

Combine each feature's arrays into a single file list:
- **Feature A files** = `filesModified` + `filesCreated`
- **Feature B files** = `filesModified` + `filesCreated`

---

## Algorithm

### 1. Compute File Overlap

Calculate the intersection of the two file lists (exact path match).

**If no overlap:** Classify the pair as **CLEAN**. No conflicts expected. STOP — no further analysis needed for this pair.

### 2. Classify Each Overlapping File

For each file in the overlap, apply the following classification rules in order. Use the FIRST matching rule.

#### Rule A: Both Features Create the Same File

If the file appears in BOTH features' `filesCreated` arrays, classify it as:

- **BOTH-CREATE** -> **MANUAL-RESOLUTION**

This indicates a design collision — two features independently created the same file. Human judgment is required to determine which version to keep or how to merge them.

#### Rule B: Shared Infrastructure File

Check if the file matches any of the shared infrastructure patterns below:

**Package manifests:**
- `package.json`
- `Cargo.toml`
- `pyproject.toml`
- `go.mod`
- `go.sum`
- `Gemfile`
- `requirements.txt`
- `pom.xml`
- `build.gradle`
- `build.gradle.kts`

**Lock files:**
- `package-lock.json`
- `yarn.lock`
- `pnpm-lock.yaml`
- `Cargo.lock`
- `poetry.lock`
- `uv.lock`
- `Gemfile.lock`
- `composer.lock`

**Config files:**
- `tsconfig.json`, `tsconfig.*.json`
- `webpack.config.*`, `vite.config.*`, `rollup.config.*`
- `.env.example`
- `.eslintrc.*`, `.prettierrc.*`
- `tailwind.config.*`, `next.config.*`, `nuxt.config.*`

**Route registries:**
- `**/routes.*`, `**/router.*`
- `**/urls.py`
- `**/app.ts`, `**/app.js` (when registering routes/middleware)

**Index/barrel files:**
- `**/index.ts`, `**/index.js`
- `**/mod.rs`, `**/lib.rs`
- `**/__init__.py`

**Type definition aggregators:**
- `**/types.ts`, `**/types.d.ts`, `**/interfaces.ts`

**Database schema files:**
- `**/schema.prisma`, `**/schema.sql`
- `**/migrations/index.*`

If the file matches any of the above patterns, classify it as:

- **SHARED-INFRASTRUCTURE** -> **AUTO-MERGEABLE**

Rationale: these files typically receive additive, non-conflicting changes from multiple features (adding entries to a dependency list, adding imports to a barrel file, adding route registrations, etc.).

#### Rule C: Non-Infrastructure File — Hunk Analysis

If the file does NOT match any shared infrastructure pattern, perform hunk-level analysis.

For each feature's branch, examine the diff against the merge target (`{base_branch}`, typically `main`):

```bash
git diff {base_branch}...<branch-a> -- <file>
git diff {base_branch}...<branch-b> -- <file>
```

Extract the line ranges modified by each feature from the diff hunk headers (`@@ -start,count +start,count @@`).

**If the modified line ranges do NOT overlap** (no hunk from feature A touches the same lines as any hunk from feature B):

- **NON-OVERLAPPING-HUNKS** -> **AUTO-MERGEABLE**

Git's merge machinery can typically handle this automatically since the changes are in different sections of the file.

**If the modified line ranges DO overlap** (at least one hunk from feature A touches lines that are also touched by a hunk from feature B):

- **OVERLAPPING-HUNKS** -> **MANUAL-RESOLUTION**

The changes modify the same code region (function body, class definition, configuration block). A human must decide how to combine them.

---

## 3. Classify the Pair

After classifying each overlapping file individually, determine the overall pair classification based on the **worst** file classification:

| File-Level Results | Pair Classification |
|--------------------|---------------------|
| All files are `SHARED-INFRASTRUCTURE` or `NON-OVERLAPPING-HUNKS` | **AUTO-MERGEABLE** |
| Any file is `OVERLAPPING-HUNKS` or `BOTH-CREATE` | **MANUAL-RESOLUTION** |

---

## Output Format

Produce one classification record per feature pair:

```json
{
  "feature1": "F-003",
  "feature2": "F-005",
  "classification": "clean | auto-mergeable | manual-resolution",
  "overlappingFiles": [
    {
      "file": "path/to/file",
      "classification": "shared-infrastructure | non-overlapping-hunks | overlapping-hunks | both-create",
      "details": "Brief description of the overlap (e.g., 'both add entries to dependencies', 'both modify loadConfig() at lines 42-58')"
    }
  ]
}
```

For `clean` pairs, `overlappingFiles` is an empty array.

---

## Examples

### Example 1: Clean Pair

Feature A modifies: `src/auth/login.ts`, `src/auth/session.ts`
Feature B modifies: `src/api/users.ts`, `src/api/routes.ts`

Overlap: none.
Pair classification: **CLEAN**.

### Example 2: Auto-Mergeable via Shared Infrastructure

Feature A modifies: `package.json`, `src/auth/login.ts`
Feature B modifies: `package.json`, `src/api/users.ts`

Overlap: `package.json`.
`package.json` matches shared infrastructure pattern (package manifest).
File classification: **SHARED-INFRASTRUCTURE**.
Pair classification: **AUTO-MERGEABLE**.

### Example 3: Auto-Mergeable via Non-Overlapping Hunks

Feature A modifies: `src/config.ts` (lines 10-25), `src/auth/login.ts`
Feature B modifies: `src/config.ts` (lines 80-95), `src/api/users.ts`

Overlap: `src/config.ts`.
Not a shared infrastructure file. Hunk analysis: lines 10-25 vs lines 80-95 — no overlap.
File classification: **NON-OVERLAPPING-HUNKS**.
Pair classification: **AUTO-MERGEABLE**.

### Example 4: Manual Resolution — Overlapping Hunks

Feature A modifies: `src/config.ts` (lines 40-55)
Feature B modifies: `src/config.ts` (lines 45-60)

Overlap: `src/config.ts`.
Not a shared infrastructure file. Hunk analysis: lines 40-55 vs lines 45-60 — overlap at lines 45-55.
File classification: **OVERLAPPING-HUNKS**.
Pair classification: **MANUAL-RESOLUTION**.

### Example 5: Manual Resolution — Both Create

Feature A creates: `src/utils/helpers.ts`
Feature B creates: `src/utils/helpers.ts`

Overlap: `src/utils/helpers.ts`.
Both features have this file in `filesCreated`.
File classification: **BOTH-CREATE**.
Pair classification: **MANUAL-RESOLUTION**.

### Example 6: Mixed — Worst Wins

Feature A modifies: `package.json`, `src/config.ts` (lines 40-55)
Feature B modifies: `package.json`, `src/config.ts` (lines 45-60)

Overlap: `package.json`, `src/config.ts`.
`package.json`: **SHARED-INFRASTRUCTURE** (auto-mergeable).
`src/config.ts`: **OVERLAPPING-HUNKS** (manual-resolution).
Pair classification: **MANUAL-RESOLUTION** (worst wins).
