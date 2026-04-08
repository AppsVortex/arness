# Prototype Guardrail Rules Template

This template defines the `### Prototype Lock` subsection written to the target project's `CLAUDE.md` by the `arn-spark-prototype-lock` skill. The skill substitutes project-specific paths into the placeholders before writing.

## Placeholders

- `__LOCK_DATE__` -- date the lock was created
- `__LOCK_TAG__` -- git tag name (or "none")
- `__LOCKED_DIR__` -- path to the locked directory (e.g., `.arness/prototypes/locked/`)
- `__CLICKABLE_VERSION__` -- e.g., `clickable/v3/`
- `__STATIC_VERSION__` -- e.g., `static/v4/`
- `__PROTOTYPES_DIR__` -- base prototypes directory (e.g., `.arness/prototypes`)

## Template

```markdown
### Prototype Lock
- **Locked:** yes
- **Lock date:** __LOCK_DATE__
- **Lock tag:** __LOCK_TAG__
- **Locked directory:** __LOCKED_DIR__

#### Protected Paths
DO NOT modify, delete, or overwrite any files under these paths. They contain the validated prototype reference artifact:
- `__LOCKED_DIR__` -- frozen prototype snapshots (independently buildable)
- `__PROTOTYPES_DIR__/__CLICKABLE_VERSION__` -- original validated clickable prototype
- `__PROTOTYPES_DIR__/__STATIC_VERSION__` -- original validated static prototype
- `__PROTOTYPES_DIR__/criteria.md` -- agreed validation criteria
- `__PROTOTYPES_DIR__/*/final-report.md` -- complete validation history
- `__PROTOTYPES_DIR__/*/v*/review-report.md` -- version review reports
- `__PROTOTYPES_DIR__/*/v*/judge-report.md` -- judge verdicts
- `__PROTOTYPES_DIR__/*/v*/showcase/` -- visual showcase assets
- `__PROTOTYPES_DIR__/*/v*/journeys/` -- journey test screenshots

Any agent or skill that attempts to modify these files is operating incorrectly. The prototype is a reference artifact, not a working codebase. When implementing features, build in the project's source directories -- never in the prototype directories.

To view the locked prototype: see `__LOCKED_DIR__/LOCKED.md` for build and serve instructions.
```
