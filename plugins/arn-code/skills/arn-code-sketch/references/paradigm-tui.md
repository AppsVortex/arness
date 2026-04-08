# Paradigm: TUI

TUI-specific detection, artifact structure, preview mechanism, and promotion rules for the arn-code-sketch skill. This file is loaded by the sketch-setup paradigm router when the sketch strategy paradigm is `tui`.

## Sketch Strategy Values (TUI)

When `ui-patterns.md` declares paradigm `tui`, the sketch strategy typically includes:

| Field | Typical Values |
|-------|---------------|
| Paradigm | `tui` |
| Artifact structure | `sketch_app.py` + optional `sketch.tcss` in `arness-sketches/[feature-name]/` |
| Preview mechanism | Run the sketch app: `python arness-sketches/[feature-name]/sketch_app.py` |
| Promotion rules | Extract screens and widgets into the project's TUI module structure |

---

## TUI Framework Detection

Detect the project's TUI framework by reading the appropriate dependency manifest.

### Python TUI Frameworks

Check `pyproject.toml`, `setup.py`, `setup.cfg`, or `requirements.txt`:

| Package | Library | Purpose | Notes |
|---------|---------|---------|-------|
| `textual` | Textual | Modern TUI framework (CSS-like styling, reactive widgets) | Primary focus of this paradigm file |
| `textual-dev` | Textual Dev Tools | Development console, CSS hot-reload | Development dependency; confirms Textual usage |
| `urwid` | Urwid | Classic TUI framework (widget-based) | Less common; see notes below |
| `prompt_toolkit` | prompt_toolkit | TUI toolkit (used by ptpython, REPL-style apps) | Often used for interactive prompts, not full TUIs |
| `npyscreen` | npyscreen | ncurses-based forms and widgets | Legacy; less common |
| `curses` | curses (stdlib) | Low-level terminal control | Standard library; detected via `import curses` in source |

### Non-Python TUI Frameworks

These are detected but handled with lighter guidance (see Notes section below):

| Manifest | Package | Library | Language |
|----------|---------|---------|----------|
| `go.mod` | `github.com/charmbracelet/bubbletea` | Bubble Tea | Go |
| `go.mod` | `github.com/charmbracelet/lipgloss` | Lip Gloss (styling for Bubble Tea) | Go |
| `Cargo.toml` | `ratatui` | ratatui | Rust |
| `Cargo.toml` | `crossterm` | crossterm (backend for ratatui) | Rust |

### Textual-Specific Detection

When Textual is detected, also look for:
- **CSS directory:** Does the project store `.tcss` files in a dedicated directory (e.g., `styles/`, `css/`, or alongside components)?
- **Widget structure:** How are custom widgets organized? Check for a `widgets/` or `components/` directory.
- **Screen structure:** How are screens organized? Check for a `screens/` directory.
- **App class:** Find the main `App` subclass to understand the app structure, screen routing, and binding patterns.
- **Theme:** Check for custom theme configuration in the App class or TCSS files.

---

## Artifact Structure

### Textual (Primary)

```
arness-sketches/
  [feature-name]/
    sketch_app.py           # Runnable Textual app
    sketch.tcss             # Textual CSS for the sketch (if the project uses TCSS)
    sketch-manifest.json    # Metadata about this sketch
```

### Other TUI Frameworks

```
arness-sketches/
  [feature-name]/
    sketch_app.py           # Runnable TUI sketch (or sketch_app.go, sketch_app.rs)
    sketch-manifest.json    # Metadata about this sketch
```

### sketch_app.py Conventions (Textual)

The sketch app must be:

1. **Standalone and runnable:** `python arness-sketches/[feature-name]/sketch_app.py` must launch a working Textual app that the user can interact with in their terminal.

2. **A proper Textual App subclass:** Follow the project's App class patterns. Include screen routing, key bindings, and action methods as the project does.

3. **Imports from the project where possible:** Import custom widgets, screens, data models, and utilities from the project's existing modules. This keeps the sketch realistic.

4. **Uses realistic mock data:** Hardcode sample data that demonstrates the feature's display. Data should be plausible and representative.

5. **Includes TCSS if the project uses it:** If the project separates styling into `.tcss` files, create a `sketch.tcss` file following the same patterns. If the project inlines styles in Python, do the same.

6. **Matches the project's widget patterns:** Use the same widget composition, layout containers (Horizontal, Vertical, Grid), and naming conventions.

**Example structure (Textual):**
```python
#!/usr/bin/env python3
"""Arness sketch: [feature-name] screen.

Run: python arness-sketches/[feature-name]/sketch_app.py
"""
from textual.app import App, ComposeResult
from textual.containers import Horizontal, Vertical
from textual.widgets import Header, Footer, DataTable, Static

# Import from the project where possible:
# from myproject.widgets import StatusIndicator

# Realistic mock data
MOCK_ENVIRONMENTS = [
    ("production", "healthy", "14d 6h", "v2.3.1"),
    ("staging", "degraded", "2d 1h", "v2.4.0-rc1"),
    ("development", "healthy", "6h 30m", "v2.4.0-dev"),
]


class EnvironmentDashboard(Static):
    """Dashboard panel showing environment status."""

    def compose(self) -> ComposeResult:
        table = DataTable()
        table.add_columns("Name", "Status", "Uptime", "Version")
        for env in MOCK_ENVIRONMENTS:
            table.add_row(*env)
        yield table


class SketchApp(App):
    """Sketch: Environment dashboard screen."""

    CSS_PATH = "sketch.tcss"  # Only if using external TCSS
    TITLE = "Environment Dashboard (Sketch)"
    BINDINGS = [("q", "quit", "Quit")]

    def compose(self) -> ComposeResult:
        yield Header()
        yield EnvironmentDashboard()
        yield Footer()


if __name__ == "__main__":
    app = SketchApp()
    app.run()
```

### sketch.tcss Conventions

If the project uses external Textual CSS:

```css
/* Arness sketch: [feature-name] styles */
/* Follow the project's TCSS patterns */

EnvironmentDashboard {
    height: 1fr;
    padding: 1 2;
}

DataTable {
    height: 100%;
}
```

Match the project's TCSS conventions: selector patterns, spacing units, color tokens, and layout approach.

---

## Preview Mechanism

The user previews a TUI sketch by running the app:

```
python arness-sketches/[feature-name]/sketch_app.py
```

The app launches in the terminal. The user interacts with it (navigate, press keys, resize) and then exits (typically with `q` or `Ctrl+C`).

Present the preview instructions after the builder completes:

"Sketch ready. Run the sketch:
**`python arness-sketches/[feature-name]/sketch_app.py`**

The sketch shows [brief description] for the [target screen].

Interact with it in your terminal, then press `q` to quit. What would you like to change?"

If the app requires specific Python dependencies from the project's virtual environment, remind the user to activate it first.

For Textual apps with CSS hot-reload via `textual-dev`, mention:

"Tip: Run with `textual run --dev arness-sketches/[feature-name]/sketch_app.py` for live CSS reloading."

---

## Promotion Rules

When promoting a TUI sketch into the real codebase:

### 1. Identify Target Location

Read `sketch-manifest.json` for the `targetPage` field (which for TUI projects is the target screen or widget module, e.g., `src/myproject/screens/dashboard.py`).

- If the target module exists: integrate the sketched screen/widgets into it
- If the target module is new: create it following the project's module organization pattern

### 2. Extract and Integrate

For each element in the sketch:

1. **Screen classes:** Move `Screen` subclasses into the project's screen directory or module. Register them with the App class if the project uses screen routing.

2. **Widget classes:** Move custom widgets into the project's widget directory. Update the app or screen to import from the new locations.

3. **TCSS styles:** Merge sketch TCSS into the project's stylesheet structure. If the project uses a single CSS file, append the sketch styles. If it uses per-screen files, create a new file following the naming convention.

4. **Mock data replacement:** Replace hardcoded mock data with actual data sources (reactive attributes, data bindings, worker results, or message handlers).

5. **Key bindings:** Register sketch key bindings with the App or Screen class following the project's binding convention.

### 3. Update Imports

Rewrite all import statements to reference the project's module structure instead of sketch paths.

### 4. Update Manifest

Set status to `"promoted"` with timestamp and destination paths.

---

## Iteration Specifics

During iteration, the user runs the sketch, interacts with it, and describes changes:

**TUI-specific feedback patterns:**

| Category | Examples | Builder Action |
|----------|----------|----------------|
| **Layout** | "move the sidebar to the left", "split the screen vertically", "make the table wider" | Adjust Textual containers (Horizontal, Vertical, Grid), update TCSS |
| **Widget swap** | "use a tree instead of a list", "use a rich log instead of static text" | Replace widget classes, update compose methods |
| **Styling** | "change the header color", "add a border to the panel", "increase padding" | Update TCSS or inline styles |
| **Content** | "add a status bar at the bottom", "show timestamps", "add a filter input" | Add new widgets to compose, wire up bindings |
| **Interaction** | "add keyboard shortcuts", "make the table sortable", "add a modal dialog" | Add Textual bindings, action methods, or Screen.push |
| **Data** | "show more rows", "add a refresh button", "simulate live updates" | Update mock data, add reactive attributes or timers |
| **Panels** | "dock the info panel to the right", "add a collapsible sidebar" | Adjust Textual docking and layout in TCSS |

After each iteration, update both `sketch_app.py` and `sketch.tcss` (if used) to reflect the changes.

---

## TUI-Specific Threshold Rules

**Below threshold (implement directly):**
- Changing a label or column header
- Adjusting a column width
- Reordering a single field
- Changing a color or style
- Adding a single key binding

**Above threshold (offer sketch):**
- New screen or view
- New widget panel or dashboard section
- Multi-widget layout (split panes, tabbed views, docked sidebars)
- Data display with complex interactions (sortable tables, filterable trees)
- Status dashboard with multiple data sources
- Features where the user has expressed uncertainty about the terminal layout

---

## Notes for Non-Python TUI Frameworks

### Bubble Tea (Go)

If the project uses Bubble Tea:
- Sketch file: `sketch_app.go` (must be in a `main` package or a subdirectory with `go.mod`)
- Build and run: `go run arness-sketches/[feature-name]/sketch_app.go`
- Use the project's existing Model/Update/View patterns
- Import from the project's packages where possible
- Use Lip Gloss for styling if the project does

### ratatui (Rust)

If the project uses ratatui:
- Sketch artifacts need a separate Cargo project or must be added as a binary target
- Recommend creating a `arness-sketches/[feature-name]/` directory with a minimal `Cargo.toml` that depends on the project's workspace
- Build and run: `cargo run --bin sketch-[feature-name]`
- Use the project's existing Widget, Frame, and Backend patterns

For both Go and Rust TUI frameworks, the sketch may require more setup than Python Textual sketches. If setup complexity is high, the builder should note this and offer to create a simpler descriptive mockup (a `sketch-mockup.md` describing the layout) as an alternative.
