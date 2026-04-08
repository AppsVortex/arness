---
name: arn-spark-prototype-lock
description: >-
  This skill should be used when the user says "prototype lock", "lock prototype",
  "arn prototype lock", "freeze prototype", "preserve prototype",
  "snapshot prototype", "protect prototype", "archive prototype",
  "save the prototype", "don't overwrite the prototype",
  "lock the design", "freeze the design",
  or wants to create a frozen snapshot of the validated prototype before
  development begins, preventing production code from overwriting the
  validated reference artifact.
version: 1.0.0
---

# Arness Prototype Lock

Create a frozen, independently servable snapshot of the validated prototype before development code begins to modify shared source files. The primary artifacts are a **frozen prototype copy**, **CLAUDE.md guardrail rules** that prevent agents from modifying prototype files, an optional **PreToolUse hook** for enforcement, and a **git tag** marking the prototype completion point.

This skill addresses the problem: once development starts, production code overwrites prototype components because they share the same source files. The locked copy preserves the validated design reference for visual comparison and rollback.

## Prerequisites

Read the project's `CLAUDE.md` for a `## Arness` section. If no `## Arness` section exists or Arness Spark fields are missing, inform the user: "Arness Spark is not configured for this project yet. Run `/arn-brainstorming` to get started — it will set everything up automatically." Do not proceed without it.

Extract:
- **Prototypes directory** (default: `.arness/prototypes`)
- **Vision directory** (default: `.arness/vision`)
- **Git** (yes/no)
- **Platform** (github/bitbucket/none)

Check for prototype validation evidence:
1. Check for `[prototypes-dir]/clickable/final-report.md` -- if found, read it. Extract the latest version number and judge verdict.
2. Check for `[prototypes-dir]/static/final-report.md` -- same.
3. Check for `[prototypes-dir]/criteria.md`

**If no prototype validation evidence found:** Inform the user: "No prototype validation results found. This skill works best after `/arn-spark-clickable-prototype` or `/arn-spark-static-prototype` has validated a prototype. You can still lock any existing prototype files. What prototype source should I preserve?"

**If validation found but judge verdict was FAIL:** Warn the user: "The latest prototype version (v[N]) received a FAIL verdict from the judge. Are you sure you want to lock this version, or would you prefer to run more validation cycles first?"

Check for architecture vision to detect the stack:
1. Read `architecture-vision.md` from the Vision directory
2. Extract: UI framework (Svelte/SvelteKit, React/Next.js, Vue/Nuxt, etc.), application framework (Tauri, Electron, plain web), package manager

## Workflow

### Step 1: Inventory Prototype Artifacts

Scan the prototypes directory structure. Build an inventory:

"I found the following prototype artifacts:

**Clickable prototype:**
- Latest version: v[N] (Judge: [PASS/FAIL])
- App source: [prototypes-dir]/clickable/v[N]/app/ ([X] files, [Y] KB)
- Journey screenshots: [prototypes-dir]/clickable/v[N]/journeys/ ([Z] files)
- Showcase: [prototypes-dir]/clickable/v[N]/showcase/ ([W] files)
- Review/judge reports: [list]

**Static prototype:**
- Latest version: v[M] (Judge: [PASS/FAIL])
- Showcase: [prototypes-dir]/static/v[M]/showcase/ ([A] files)
- Review/judge reports: [list]

**Shared:**
- Criteria: [prototypes-dir]/criteria.md

**Total size:** [calculated total]

Which version should I lock? (Default: latest passing version)"

Wait for user to confirm or specify a different version before proceeding. Do not continue until the user responds.

### Step 2: Detect Stack and Plan Copy Strategy

Read the prototype app directory and detect the framework:
- Check for `package.json` -- read for framework indicators (svelte, react, vue, next, nuxt, sveltekit)
- Check for `Cargo.toml` if Tauri
- Check for build configuration files (vite.config, next.config, svelte.config, etc.)

Determine copy strategy based on stack:

| Framework | Copy Strategy | Validation |
|-----------|--------------|------------|
| SvelteKit | Copy full app directory, exclude node_modules. Include package.json, lockfile, svelte.config, vite.config, tailwind.config, src/, static/ | `cd [dest] && [pm] install && [pm] run build` |
| Next.js | Copy full app directory, exclude node_modules and .next/. Include package.json, lockfile, next.config, tsconfig, src/, public/ | `cd [dest] && [pm] install && [pm] run build` |
| Vue/Nuxt | Copy full app directory, exclude node_modules and .nuxt/. Include package.json, lockfile, nuxt.config, src/ | `cd [dest] && [pm] install && [pm] run build` |
| Plain HTML/CSS/JS | Copy all files directly | Open index.html in browser or serve with `npx serve` |
| Tauri | Copy the webview source (follows its own framework row above). Copy src-tauri/ config only if relevant to the UI snapshot | Framework-specific build (webview only) |

Present the plan:

"**Stack detected:** [framework]

**Copy plan:**
- Source: [prototypes-dir]/clickable/v[N]/app/
- Destination: [prototypes-dir]/locked/clickable-v[N]/
- Strategy: [framework-specific description]
- Excludes: node_modules/, build output dirs (.svelte-kit/, .next/, dist/)
- Includes: lockfile (package-lock.json/pnpm-lock.yaml/yarn.lock/bun.lockb), all config, all source

Also copying:
- Validation evidence (review reports, judge reports, screenshots, showcase)
- Criteria document

Proceed?"

Wait for user confirmation.

### Step 3: Execute Copy

1. Create destination directory: `[prototypes-dir]/locked/clickable-v[N]/`
2. Copy the prototype app source using `cp -r` with exclusion of `node_modules/` and framework build output directories
3. Copy validation evidence:
   - Journey screenshots from the locked version
   - Showcase screenshots
   - Review and judge reports for the locked version
   - The `final-report.md` for each prototype type
4. Copy `criteria.md`
5. Read the lock report template:
   > Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-prototype-lock/references/lock-report-template.md`
6. Write a `LOCKED.md` manifest file at `[prototypes-dir]/locked/LOCKED.md` using the template. Populate all fields with the actual values from the copy operation.

If a static prototype exists and is validated, repeat the copy for the static prototype to `[prototypes-dir]/locked/static-v[M]/`.

### Step 4: Validate the Snapshot

1. `cd` into the locked copy
2. Run dependency install using the detected package manager (npm/pnpm/yarn/bun)
3. Run build using the framework's build command
4. If the project has a dev server command, start it briefly and verify it responds:
   - Start the dev server in the background
   - Poll for readiness (check HTTP response on the expected port)
   - Kill the dev server after confirming it responds
5. Report validation result

**If validation fails:**
- Report the error
- Ask: "The locked copy does not build independently. Common causes: hard-coded paths, missing shared dependencies, monorepo imports. Should I investigate and fix, or skip validation?"
- If fixing: diagnose and fix path issues, missing deps, etc. Re-validate.
- After 3 failures: "Cannot make the locked copy build independently. The files are preserved as a reference but cannot be served standalone. Proceeding with guardrails."

Update the LOCKED.md manifest with the validation results.

### Step 5: Ask User to Confirm Access

"The prototype snapshot is at `[path]`. Can you confirm you can access it?

If this is a web-based prototype, you can verify by running:
```
cd [path]
[install command]
[dev server command]
```

Then open [URL] in your browser.

Is the snapshot accessible and working?"

Wait for user confirmation. If the user reports issues, investigate.

### Step 6: Git Tag

If Git is configured (`Git: yes`):

1. Check for uncommitted changes: `git status --short`
2. If uncommitted changes exist: "There are uncommitted changes. The git tag should mark a clean state. Should I commit current changes first, or tag despite uncommitted changes?"
3. If the tag name already exists, append a sequence number: `prototype-lock-[date]-2`
4. Create the tag: `git tag -a prototype-lock-[date] -m "Prototype locked after validation. Clickable v[N] (Judge: [verdict]). See [prototypes-dir]/locked/LOCKED.md"`
5. Report: "Git tag `prototype-lock-[date]` created. You can return to this exact state with `git checkout prototype-lock-[date]`."

If Git is not configured: skip, note that no tag was created.

### Step 7: Write CLAUDE.md Guardrail Rules

Read the guardrail rules template:
> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-prototype-lock/references/prototype-guardrail-rules.md`

Substitute the placeholders with project-specific paths:
- `__LOCK_DATE__` -- today's date
- `__LOCK_TAG__` -- the git tag name from Step 6, or "none" if git is not configured
- `__LOCKED_DIR__` -- the locked directory path
- `__CLICKABLE_VERSION__` -- e.g., `clickable/v3/`
- `__STATIC_VERSION__` -- e.g., `static/v4/`
- `__PROTOTYPES_DIR__` -- base prototypes directory

Add the populated `### Prototype Lock` subsection to the `## Arness` section in the project's `CLAUDE.md`.

### Step 8: Optional PreToolUse Hook

Ask the user:

Ask (using `AskUserQuestion`):

**"The CLAUDE.md rules instruct agents not to modify prototype files. Do you want additional enforcement?"**

Options:
1. **Rules only** (default) — CLAUDE.md instructions are usually sufficient
2. **Rules + hook** — Adds a PreToolUse guard script for stricter enforcement

**If the user chooses hook:**

Read the hook template:
> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-prototype-lock/references/pretooluse-hook-template.json`

The hook is installed in the **target project** (not in the arn-spark plugin):

1. Read or create `.claude/settings.json` in the target project
2. If `.claude/settings.json` already exists and has PreToolUse hooks, append the prototype guard to the existing hook list. Otherwise, create the hooks configuration using the template's `hooks_config`.
3. Adapt the guard script from the template:
   - Replace `__PROTECTED_PATH_1__`, `__PROTECTED_PATH_2__`, etc. with the **relative paths** of the protected directories (relative to the project root, e.g., `.arness/prototypes/locked/`). The guard script resolves them at runtime using the `cwd` field from the hook input, so no user-specific absolute paths are committed.
4. Write the guard script to `.claude/hooks/prototype-lock-guard.sh` in the target project
5. Make the script executable: `chmod +x .claude/hooks/prototype-lock-guard.sh`

**Note:** The hook guards Write and Edit tool calls only. Bash commands that modify the filesystem are not intercepted -- the CLAUDE.md rules (Step 7) are the primary defense for all operations including Bash.

### Step 9: Present Summary

"Prototype locked.

**Snapshot:** [prototypes-dir]/locked/clickable-v[N]/
**Manifest:** [prototypes-dir]/locked/LOCKED.md
**Independent build:** [PASS/FAIL/SKIPPED]
**Git tag:** prototype-lock-[date] [or 'none']
**Guardrails:** CLAUDE.md rules [+ PreToolUse hook]

**Protected paths** (agents will not modify):
- [list from guardrail rules]

**CLAUDE.md updated** with `### Prototype Lock` configuration.

Recommended next steps:
1. **Set up dev environment:** Run `/arn-spark-dev-setup` to configure the development environment
2. **Define visual testing:** Run `/arn-spark-visual-strategy` to set up visual regression testing against the prototype
3. **Extract features:** Run `/arn-spark-feature-extract` to build the backlog
4. **Start developing:** If you have the Arness Code plugin installed, run `/arn-planning` to begin the development pipeline. Arness auto-configures on first use."

## Agent Invocation Guide

| Situation | Action |
|-----------|--------|
| Copy and validate snapshot (Steps 3-4) | Execute directly in conversation via Bash and Write. No agent needed -- operations are deterministic. |
| Build validation fails with path issues | Diagnose directly. If the issue requires framework-specific knowledge, invoke `arn-spark-dev-env-builder` (foreground) for diagnosis assistance. |
| User asks about prototype quality | Reference the judge report and review reports. Do not re-run validation. |
| User wants to re-lock after more cycles | Re-run the skill. It detects the existing lock in Step 1 and offers to replace it. |
| User asks about visual testing | Defer: "Visual regression testing against the prototype is set up by `/arn-spark-visual-strategy`." |
| User asks about features | Defer: "Feature extraction is done by `/arn-spark-feature-extract`." |

## Error Handling

- **No prototype found:** Ask user to point to the prototype source directory. Proceed without validation evidence if necessary.
- **Prototype fails to build independently:** Preserve the files as reference. Note limitation in LOCKED.md. Guardrails still protect the files.
- **Lock already exists:** "A prototype lock already exists from [date]. Replace it, or keep both? (Keeping both creates `locked/clickable-v[N]-[date2]/`)"
- **Git tag already exists:** Append a sequence number: `prototype-lock-[date]-2`
- **CLAUDE.md write fails:** Print the guardrail block for manual insertion.
- **Hook installation fails:** Proceed with CLAUDE.md rules only. Explain that rules are usually sufficient.
- **Large prototype (>100MB):** Warn the user about disk usage. Suggest adding the locked directory to `.gitignore` if it should not be committed.
- **Monorepo prototype (shares dependencies with main project):** The locked copy may need its own dependency install. Note this in the LOCKED.md manifest.
