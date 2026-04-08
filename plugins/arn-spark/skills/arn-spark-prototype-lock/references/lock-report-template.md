# Lock Report Template

This template defines the structure for the `LOCKED.md` manifest file written by the `arn-spark-prototype-lock` skill. The manifest is saved to `[prototypes-dir]/locked/LOCKED.md` and documents the frozen prototype snapshot.

## Template

```markdown
# Prototype Lock Manifest

Locked by `/arn-spark-prototype-lock` on [date].

## Locked Versions

| Type | Version | Judge Verdict | Source | Locked Copy |
|------|---------|--------------|--------|-------------|
| [Clickable / Static] | v[N] | [PASS / FAIL / N/A] | [relative path to original] | [relative path to locked copy] |

## Git Tag

Tag: `[tag-name]` (or "None -- Git not configured")

To return to this exact state: `git checkout [tag-name]`

## Independent Build Validation

| Check | Result |
|-------|--------|
| Dependency install | [PASS / FAIL / SKIPPED] |
| Build | [PASS / FAIL / SKIPPED] |
| Dev server | [PASS / FAIL / SKIPPED] |

[If any checks failed: description of why and whether the snapshot is still usable as a reference]

## Stack

- **UI framework:** [detected framework]
- **Package manager:** [npm / pnpm / yarn / bun]
- **Build tool:** [vite / webpack / turbopack / etc.]

## How to View

```bash
cd [locked-copy-path]
[package-manager] install
[package-manager] run dev
```

Then open [URL, e.g., http://localhost:5173] in your browser.

## What is Locked

The locked directory contains:
- **Prototype source code** -- all components, routes, styles, and configuration
- **Lockfile** -- exact dependency versions for reproducible builds
- **Validation evidence** -- review reports, judge reports, journey screenshots, showcase
- **Criteria document** -- agreed validation criteria

## What is NOT Locked

- `node_modules/` -- excluded from the copy (reinstall via lockfile)
- Framework build output (`.svelte-kit/`, `.next/`, `dist/`) -- excluded (rebuild from source)
- Runtime state, caches, and temporary files

## Protected by

- **CLAUDE.md rules:** `### Prototype Lock > #### Protected Paths` in the project's CLAUDE.md
- **PreToolUse hook:** [yes / no] -- blocks Write/Edit operations targeting locked directories
```
