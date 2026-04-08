# Sketch Setup

Paradigm routing, prerequisite validation, and artifact namespace setup. Used by the arn-code-sketch skill at Step 1 and Step 4.

## Sketch Strategy Loading

Read `ui-patterns.md` from the project's code patterns directory. Locate the `## Sketch Strategy` section and extract:

| Field | Description | Example Values |
|-------|-------------|----------------|
| Paradigm | The interface type | `web`, `cli`, `tui`, `desktop`, `mobile` |
| Artifact structure | What sketch files to create | Framework-specific route files (web), sketch scripts (CLI/TUI) |
| Preview mechanism | How the user previews the sketch | Browser URL (web), terminal command (CLI/TUI) |
| Promotion rules | How sketches move into the real codebase | Copy to real routes (web), integrate into command module (CLI) |

If `## Sketch Strategy` is not found, halt with: "No sketch strategy found. Run `/arn-implementing` to get started — pattern documentation will be generated on first use, including the sketch strategy if your project has a UI framework."

---

## Paradigm Reference Routing

Based on the paradigm extracted from the sketch strategy, load the corresponding paradigm reference file:

| Paradigm | Reference File | Contents |
|----------|---------------|----------|
| `web` | `paradigm-web.md` | Framework detection, component library detection, styling detection, route namespace creation |
| `cli` | `paradigm-cli.md` | CLI framework detection, argument structure, output format patterns |
| `tui` | `paradigm-tui.md` | TUI framework detection, screen layout, widget patterns |
| Other | `paradigm-stub.md` | Generic guidelines for unsupported paradigms |

Load the reference file:

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-sketch/references/paradigm-<paradigm>.md`

If the file does not exist, fall back to:

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-sketch/references/paradigm-stub.md`

The paradigm reference file contains all paradigm-specific detection, artifact structure, and creation rules. Follow its instructions for Steps 4-6 of the arn-code-sketch workflow.

---

## Technology Stack Confirmation

Read `architecture.md` from the code patterns directory. Check the Technology Stack table to confirm:
- Language and version
- Framework (should align with the paradigm from the sketch strategy)
- Key libraries relevant to the interface (component libraries, styling tools, CLI frameworks, TUI frameworks)

This information supplements the sketch strategy and is passed to the builder agent.

---

## .gitignore Handling

Check if `arness-sketches/` is already in the project's `.gitignore`. If not, suggest adding it:

"Should I add `arness-sketches/` to your `.gitignore`? Sketches are temporary previews and typically should not be committed. (You can always promote them into the real codebase later.)"

If the user agrees, append `arness-sketches/` to `.gitignore`. If `.gitignore` does not exist, create one with `arness-sketches/` as its content.

If the user declines, proceed without modifying `.gitignore`. Note in the manifest that the sketch is tracked by git.

---

## Prerequisite Validation Checklist

Run these checks before proceeding to sketch creation. Report all failures at once (do not stop at the first one):

| Check | How | Failure Message |
|-------|-----|-----------------|
| `## Arness` config exists | Read CLAUDE.md, look for `## Arness` heading | "Arness is not configured for this project yet. Run `/arn-implementing` to get started — it will set everything up automatically." |
| Sketch strategy found | Read `ui-patterns.md`, look for `## Sketch Strategy` | "No sketch strategy found. Run `/arn-implementing` to get started — pattern documentation will be generated on first use, including the sketch strategy if your project has a UI framework." |
| Paradigm reference loadable | Load `paradigm-<paradigm>.md` or fall back to `paradigm-stub.md` | "No paradigm reference found for '[paradigm]'. Using generic guidelines." (warning, not a halt) |
| Target directory is writable | Verify the `arness-sketches/` parent directory exists and is writable | "Cannot write to [directory]. Check permissions." |

If any prerequisite fails (except the paradigm reference warning), halt with all failure messages combined. Do not partially proceed.
