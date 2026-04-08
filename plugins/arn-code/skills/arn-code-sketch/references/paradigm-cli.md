# Paradigm: CLI

CLI-specific detection, artifact structure, preview mechanism, and promotion rules for the arn-code-sketch skill. This file is loaded by the sketch-setup paradigm router when the sketch strategy paradigm is `cli`.

## Sketch Strategy Values (CLI)

When `ui-patterns.md` declares paradigm `cli`, the sketch strategy typically includes:

| Field | Typical Values |
|-------|---------------|
| Paradigm | `cli` |
| Artifact structure | `sketch-cli.py` + `expected-output.md` in `arness-sketches/[feature-name]/` |
| Preview mechanism | Run the sketch script: `python arness-sketches/[feature-name]/sketch-cli.py` |
| Promotion rules | Extract output functions and command definitions into the project's CLI module |

---

## CLI Library Detection

Detect the project's CLI framework by reading `pyproject.toml`, `setup.py`, `setup.cfg`, or `requirements.txt`. Check for these libraries:

| Package | Library | Purpose | Detection |
|---------|---------|---------|-----------|
| `click` | Click | Command definition, argument parsing | `[project.dependencies]` or `install_requires` |
| `typer` | Typer | Type-hint-based CLI (built on Click) | `[project.dependencies]` or `install_requires` |
| `rich` | Rich | Terminal formatting, tables, trees, panels | `[project.dependencies]` or `install_requires` |
| `rich-click` | Rich-Click | Rich formatting for Click help pages | `[project.dependencies]` or `install_requires` |
| `colorama` | Colorama | Cross-platform colored output | `[project.dependencies]` or `install_requires` |
| `tabulate` | Tabulate | Simple table formatting | `[project.dependencies]` or `install_requires` |
| `argparse` | argparse (stdlib) | Standard library argument parsing | Check `import argparse` in existing CLI modules |
| `questionary` | Questionary | Interactive prompts | `[project.dependencies]` or `install_requires` |
| `InquirerPy` | InquirerPy | Interactive prompts (Inquirer.js port) | `[project.dependencies]` or `install_requires` |

**Multiple libraries:** Many CLI projects combine a CLI framework (Click/Typer/argparse) with a formatting library (Rich/tabulate/colorama). Detect all that are present -- the sketch should use the same combination.

**Entry point detection:** Check `pyproject.toml` for `[project.scripts]` or `[tool.poetry.scripts]` to find the CLI entry point. This reveals the project's command structure and module organization.

---

## Artifact Structure

```
arness-sketches/
  [feature-name]/
    sketch-cli.py           # Runnable CLI sketch script
    expected-output.md      # Annotated expected terminal output
    sketch-manifest.json    # Metadata about this sketch
```

### sketch-cli.py Conventions

The sketch script must be:

1. **Standalone and runnable:** `python arness-sketches/[feature-name]/sketch-cli.py` must execute without requiring the user to install additional packages or configure environment variables (beyond what the project already has).

2. **Uses the project's CLI library:** If the project uses Click, the sketch uses Click. If Typer, use Typer. Match the exact library and patterns.

3. **Imports from the project where possible:** Import shared utilities, formatters, and data models from the project's existing modules. This keeps the sketch realistic and reduces duplication.

4. **Uses realistic mock data:** Hardcode realistic sample data that demonstrates the feature's output. Data should look plausible (real names, realistic numbers, proper formatting) rather than generic placeholders.

5. **Shows the full command interaction:** Include all subcommands, flags, arguments, and help text that the feature will have. If the feature is a new command group, show the group help and at least one subcommand in action.

6. **Matches the project's output style:** If the project uses Rich tables, the sketch uses Rich tables with the same styling. If the project uses plain text with color codes, the sketch does the same.

**Example structure (Click + Rich):**
```python
#!/usr/bin/env python3
"""Arness sketch: [feature-name] command group.

Run: python arness-sketches/[feature-name]/sketch-cli.py [subcommand]
"""
import click
from rich.console import Console
from rich.table import Table

# Import from the project where possible:
# from myproject.formatters import format_status

console = Console()

# Realistic mock data
MOCK_DATA = [
    {"name": "production", "status": "healthy", "uptime": "14d 6h"},
    {"name": "staging", "status": "degraded", "uptime": "2d 1h"},
    {"name": "development", "status": "healthy", "uptime": "6h 30m"},
]

@click.group()
def cli():
    """Manage deployment environments."""
    pass

@cli.command()
@click.option("--format", type=click.Choice(["table", "json"]), default="table")
def list(format):
    """List all environments and their status."""
    if format == "table":
        table = Table(title="Environments")
        table.add_column("Name", style="cyan")
        table.add_column("Status", style="green")
        table.add_column("Uptime")
        for env in MOCK_DATA:
            table.add_row(env["name"], env["status"], env["uptime"])
        console.print(table)
    else:
        import json
        console.print_json(json.dumps(MOCK_DATA))

if __name__ == "__main__":
    cli()
```

### expected-output.md Conventions

A markdown file showing what the user should see when running the sketch. Uses fenced code blocks with annotations:

```markdown
# Expected Output: [feature-name]

## `sketch-cli.py list`

\```
                    Environments
┏━━━━━━━━━━━━━━┳━━━━━━━━━━━┳━━━━━━━━━━┓
┃ Name         ┃ Status    ┃ Uptime   ┃
┡━━━━━━━━━━━━━━╇━━━━━━━━━━━╇━━━━━━━━━━┩
│ production   │ healthy   │ 14d 6h   │
│ staging      │ degraded  │ 2d 1h    │
│ development  │ healthy   │ 6h 30m   │
└──────────────┴───────────┴──────────┘
\```

> Table uses Rich default styling. The "Status" column
> will use color: green for healthy, yellow for degraded,
> red for unhealthy.

## `sketch-cli.py list --format json`

\```json
[
  {"name": "production", "status": "healthy", "uptime": "14d 6h"},
  ...
]
\```
```

Each output section includes:
- The exact command invoked
- The expected terminal output in a fenced code block
- Annotations explaining styling, colors, or interactive behavior that cannot be captured in static text

---

## Preview Mechanism

The user previews a CLI sketch by running the script:

```
python arness-sketches/[feature-name]/sketch-cli.py
```

Or with specific subcommands/flags:

```
python arness-sketches/[feature-name]/sketch-cli.py list --format table
python arness-sketches/[feature-name]/sketch-cli.py --help
```

Present the preview instructions after the builder completes:

"Sketch ready. Run the sketch:
**`python arness-sketches/[feature-name]/sketch-cli.py`**

Expected output is documented in `arness-sketches/[feature-name]/expected-output.md`.

The sketch demonstrates [brief description] for the [target command].

What would you like to change?"

If the script requires specific Python dependencies that are already in the project's virtual environment, remind the user to activate their environment first.

---

## Promotion Rules

When promoting a CLI sketch into the real codebase:

### 1. Identify Target Module

Read `sketch-manifest.json` for the `targetPage` field (which for CLI projects is the target command module, e.g., `src/myproject/commands/deploy.py`).

- If the target module exists: integrate the sketched commands into it
- If the target module is new: create it following the project's module organization pattern

### 2. Extract and Integrate

For each element in the sketch:

1. **Command functions:** Move `@click.command()` or `@app.command()` decorated functions into the target module. Adapt the mock data to use real data sources (API calls, database queries, config reads).

2. **Output formatters:** Move table builders, formatters, and display functions into the project's utility/formatter module (or create one following the project's conventions).

3. **Mock data replacement:** Replace hardcoded `MOCK_DATA` with actual data fetching logic. Add comments or TODOs marking where real data integration is needed.

4. **Entry point registration:** Register new commands with the project's CLI group (the main `click.group()` or Typer app).

### 3. Update Imports

Rewrite all import statements to reference the project's module structure instead of sketch paths.

### 4. Update Manifest

Set status to `"promoted"` with timestamp and destination paths.

---

## Iteration Specifics

During iteration, the user runs the sketch and describes output changes:

**CLI-specific feedback patterns:**

| Category | Examples | Builder Action |
|----------|----------|----------------|
| **Output format** | "use a tree instead of a table", "show JSON by default" | Replace output renderer, update expected-output.md |
| **Column changes** | "add a 'last deployed' column", "remove the uptime column" | Modify table/output structure |
| **Argument changes** | "add a --verbose flag", "make the name argument optional" | Update Click/Typer decorators and help text |
| **Subcommand changes** | "add a 'status' subcommand", "merge list and show into one command" | Add/modify/merge command functions |
| **Styling** | "use blue headers", "add a progress bar", "make errors red" | Adjust Rich styles, add Rich components |
| **Interaction** | "add a confirmation prompt before delete", "make it interactive" | Add Click.confirm, questionary prompts, or similar |

After each iteration, update both `sketch-cli.py` and `expected-output.md` to reflect the changes.

---

## CLI-Specific Threshold Rules

**Below threshold (implement directly):**
- Adding a single flag to an existing command
- Changing help text or description
- Renaming a subcommand
- Adjusting a default value
- Changing output color or minor formatting

**Above threshold (offer sketch):**
- New command group with 3 or more subcommands
- Interactive wizard or multi-step prompt flow
- New output format (table, tree, structured report, dashboard)
- Complex argument combinations with validation
- Command with multiple output modes (table/JSON/YAML/CSV)
- Features where the user has expressed uncertainty about the CLI interface
