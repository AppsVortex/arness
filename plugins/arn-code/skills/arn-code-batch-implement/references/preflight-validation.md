# Pre-flight Validation Procedure

This reference defines the pre-flight validation steps for arn-code-batch-implement. Follow each section in order and collect results into a structured summary.

---

## 1. Scan for Pending Plans

List all subdirectories in the Plans directory (from `## Arness` config). For each subdirectory:

1. **Check for plan artifacts** to determine if a plan exists:
   - `INTRODUCTION.md` -- thorough tier indicator
   - `STANDARD_*.md` -- standard tier indicator
   - `SWIFT_*.md` -- swift tier indicator
   - If none of these exist, skip this subdirectory (not a plan)

2. **Check for completion indicators** -- if ANY of the following are present, the plan is already implemented or shipped; skip it:
   - `IMPLEMENTATION_REPORT_*.json` exists
   - `TESTING_REPORT_*.json` exists
   - `STANDARD_REPORT.json` exists
   - `SWIFT_REPORT.json` exists
   - `CHANGE_RECORD.json` exists AND contains a non-empty `commitHash` field

3. **Classification**: if plan artifacts exist but no completion indicators are found, classify the plan as **pending**.

Collect all pending plans into a list with their directory name (feature name) and directory path (absolute).

---

## 2. Auto-detect Tier

For each pending plan, determine its ceremony tier based on which artifacts are present:

- **Thorough**: `INTRODUCTION.md` exists AND a `plans/` subdirectory contains at least one `PHASE_*.md` file. If `INTRODUCTION.md` is present but no phase files exist, classify the plan as **incomplete** and exclude it from the pending list with a warning: "Plan [name] has INTRODUCTION.md but no phase files — incomplete plan, skipping."
- **Standard**: a file matching `STANDARD_*.md` exists at the plan root
- **Swift**: a file matching `SWIFT_*.md` exists at the plan root

If multiple indicators are present (unusual), prefer the highest ceremony: thorough > standard > swift.

---

## 3. Check Sketch Readiness

For each pending plan:

1. Check if `arness-sketches/<feature-name>/sketch-manifest.json` exists (relative to the project root, not the plans directory).
2. If found, read the manifest:
   - If `status` is `"kept"` and `componentMapping` is non-empty -- classify as **"ready"**
   - Otherwise -- classify as **"n/a"** (sketch exists but was not kept)
3. If no manifest found, check the plan's main artifact (`INTRODUCTION.md`, `STANDARD_*.md`, or `SWIFT_*.md`) for references to UI components, pages, screens, or views:
   - If UI references are found -- classify as **"recommended"** (sketch recommended but missing; this is a warning, not blocking)
   - If no UI references -- classify as **"n/a"**

---

## 4. Detect File Overlap

For each pending plan, extract the list of files it intends to modify or create:

- **Thorough**: read `INTRODUCTION.md` and phase plans (`plans/PHASE_*.md`) for file references in implementation tables, task descriptions, or file lists
- **Standard**: read `STANDARD_*.md` and look for "Files to Modify" or "Files to Create" tables/sections
- **Swift**: read `SWIFT_*.md` for any file references

**Path normalization:** Before comparing, normalize all file paths to project-relative form — strip any leading `./`, resolve to project root. This prevents mismatches between `src/config.ts` and `./src/config.ts`.

Compare file lists across all pairs of pending plans. Report any file that appears in 2 or more plans, noting which features share it.

---

## 5. Verify Prerequisites

Run the following checks:

1. **Git available**: check that `Git` field in `## Arness` is `yes`. If `no`, flag: "BLOCKING: git is required for worktree-based parallel execution."
2. **Platform CLI auth**: check based on `Platform` field:
   - If `github`: run `gh auth status` via Bash. If fails, flag: "gh auth not available -- PRs cannot be created."
   - If `bitbucket`: run `bkt auth status` via Bash. If fails, flag: "bkt auth not available -- PRs cannot be created."
   - If `none`: flag: "No platform configured -- workers will commit but cannot create PRs."
3. **Clean working tree**: run `git status --porcelain` via Bash. If output is non-empty, flag: "Uncommitted changes detected."
4. **On main branch**: run `git branch --show-current` via Bash. If not `main` or `master`, flag: "Not on main branch -- plans should be on main (merged via plans PR from batch-planning)."

---

## 6. Estimate File Count

For each pending plan, count the total number of unique files referenced (both modify and create). This provides the "Est. Files" column in the pre-flight summary.

---

## Return Value

Return a structured summary containing:

- **pendingFeatures**: list of objects, each with:
  - `name`: feature/directory name
  - `path`: absolute path to the plan directory
  - `tier`: "thorough" | "standard" | "swift"
  - `sketchStatus`: "ready" | "recommended" | "n/a"
  - `sketchManifestPath`: absolute path or null
  - `estimatedFiles`: integer
  - `overlapWith`: list of other feature names sharing files (empty if none)
- **prerequisites**:
  - `ghAuth`: true | false
  - `cleanTree`: true | false
  - `warnings`: list of warning strings
