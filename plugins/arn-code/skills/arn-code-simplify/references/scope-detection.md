# Scope Detection

Auto-detection algorithm for resolving which files to review and where to write the simplification report. The skill reads this reference on-demand during Step 2.

---

## Scope Contexts

Arness-simplify operates in one of four scope contexts. Each context defines how to discover the files to review and where to write the output report.

### 1. Pipeline Scope

**Detection:** Look for `<plans-dir>/<PROJECT_NAME>/reports/IMPLEMENTATION_REPORT_*.json` files.

**File resolution:**
1. Read each `IMPLEMENTATION_REPORT_*.json` found.
2. Extract file paths from `implementedFeatures[].filesCreated` and `implementedFeatures[].filesModified`.
3. Merge all file paths into a deduplicated list.
4. Exclude files that no longer exist on disk (they may have been renamed or removed in a later phase).

**Output path:** `<plans-dir>/<PROJECT_NAME>/reports/SIMPLIFICATION_REPORT.json`

**Scope context value:** `"pipeline"`

### 2. Swift Scope

**Detection:** Look for `<plans-dir>/SWIFT_<name>/SWIFT_REPORT.json` files.

**File resolution:**
1. Read the `SWIFT_REPORT.json`.
2. Extract file paths from `implementation.filesCreated` and `implementation.filesModified`.
3. Deduplicate.

**Output path:** `<plans-dir>/SWIFT_<name>/SIMPLIFICATION_REPORT.json` (alongside the SWIFT_REPORT.json)

**Scope context value:** `"swift"`

### 3. Bugfix Scope

**Detection:** Look for `<plans-dir>/BUGFIX_<name>/reports/BUGFIX_REPORT.json` files.

**File resolution:**
1. Read the `BUGFIX_REPORT.json`.
2. Extract file paths from `finalFix.filesChanged[].file`.
3. Deduplicate.

**Output path:** `<plans-dir>/BUGFIX_<name>/reports/SIMPLIFICATION_REPORT.json` (alongside the BUGFIX_REPORT.json)

**Scope context value:** `"bugfix"`

### 4. Task Scope

**Detection:** Provided explicitly by the caller (e.g., arn-code-execute-task passes the task's implementation report path).

**File resolution:**
1. Read the caller-provided implementation report.
2. Extract file paths from `implementedFeatures[].filesCreated` and `implementedFeatures[].filesModified`.
3. Deduplicate.

**Output path:** Same directory as the caller-provided report, named `SIMPLIFICATION_REPORT.json`.

**Scope context value:** `"task"`

---

## Auto-Detection Priority Order

When arn-code-simplify is invoked without explicit scope (standalone invocation or wizard gate), detect scope automatically using this priority order:

```
1. Pipeline scope  -- check for IMPLEMENTATION_REPORT_*.json in any project under <plans-dir>
2. Swift scope     -- check for SWIFT_REPORT.json in any SWIFT_* folder under <plans-dir>
3. Bugfix scope    -- check for BUGFIX_REPORT.json in any BUGFIX_* folder under <plans-dir>
```

**Selection rules:**
- Use the most recently modified matching artifact to determine the active scope.
- If multiple artifacts of the same type are found (e.g., two SWIFT_* folders), compare last-modified timestamps and select the most recent one.
- If artifacts of different types are found, apply the priority order above (pipeline takes precedence over swift, swift over bugfix).

---

## Multi-Match Disambiguation

If multiple candidates are found within the same scope type and cannot be resolved by timestamp alone (e.g., two pipeline projects modified at the same second):

1. List all candidates with their paths and modification times.
2. Ask the user to select one:

   "I found multiple recent execution artifacts. Which one should I review?"

   1. `<plans-dir>/my-feature/reports/IMPLEMENTATION_REPORT_PHASE_2.json` (modified 2 minutes ago)
   2. `<plans-dir>/another-feature/reports/IMPLEMENTATION_REPORT_PHASE_1.json` (modified 5 minutes ago)

3. Use the user's selection to set the scope.

---

## File Cap and Batching

**Cap:** Each review pass processes at most **30 files**.

**Batching logic:**

1. After resolving the file list from the scope, count the total files.
2. If total <= 30: proceed with a single review pass (batch count = 1).
3. If total > 30: split into batches of up to 30 files each.
   - Group files by directory or module to keep related files in the same batch.
   - If a single directory contains more than 30 files, split alphabetically within that directory.
4. Run each batch through the three parallel reviewers sequentially (batch 1, then batch 2, etc.).
5. Merge findings across all batches before presenting to the user.

**Batch reporting:**
- Set `configuration.filesReviewed` to the total number of unique files reviewed across all batches.
- Set `configuration.batchCount` to the number of batches processed.

---

## Scope Confirmation

After auto-detection resolves a scope, confirm with the user before proceeding:

"I detected a recent **[pipeline|swift|bugfix]** execution: `[artifact path]`. This covers **[N] files**. Ready to review for simplification opportunities?"

If the user says no or wants a different scope, allow them to specify:
- A different project/artifact path
- A custom file list
- A subset of the detected files
