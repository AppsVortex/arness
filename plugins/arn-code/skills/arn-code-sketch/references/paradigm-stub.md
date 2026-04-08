# Paradigm: Stub (Fallback)

Generic guidelines for paradigms without a full reference file. This file is loaded by the sketch-setup paradigm router when the paradigm-specific reference file does not exist.

## Supported Stub Paradigms

This file provides lightweight guidance for the following paradigms that do not yet have full reference files:

| Paradigm | Typical Frameworks | Status |
|----------|-------------------|--------|
| `desktop-web` | Electron, Tauri | Stub -- full reference planned |
| `desktop-python` | PyQt5, PyQt6, PySide6, Tkinter | Stub -- full reference planned |
| `desktop-dotnet` | WPF, MAUI, WinUI | Stub -- full reference planned |
| `mobile-rn` | React Native, Expo | Stub -- full reference planned |
| `mobile-flutter` | Flutter (Dart) | Stub -- full reference planned |

---

## General Stub Instructions

For any paradigm not covered by a full reference file:

### 1. Read the Sketch Strategy

Read `ui-patterns.md` and extract the `## Sketch Strategy` section. It should contain:
- **Artifact structure** -- what files to create for the sketch
- **Preview mechanism** -- how the user previews the sketch
- **Promotion rules** -- how sketch artifacts move into the real codebase

Use these values directly. The sketch strategy was written by the codebase analyzer specifically for this project.

### 2. Read Project Conventions

Read the project's code patterns documentation (`code-patterns.md` in the code patterns directory) and `architecture.md` from the same directory. These contain:
- Naming conventions (file names, component names, module structure)
- Import patterns
- Project layout and directory structure
- Language-specific conventions

Follow these conventions exactly in all sketch artifacts.

### 3. Rely on Builder Agent Knowledge

The builder agent has general knowledge of all major frameworks. When no paradigm-specific reference is available, the builder should:
- Use its knowledge of the framework's conventions
- Read existing project files to understand the specific project's patterns
- Create sketch artifacts that match the project's style
- Note any assumptions in the sketch manifest

### 4. Artifact Structure

Unless the sketch strategy specifies otherwise, use this default structure:

```
arness-sketches/
  [feature-name]/
    sketch-entry.[ext]        # Main entry point (extension matches the project language)
    sketch-manifest.json      # Metadata about this sketch
```

The entry point file extension should match the project:
- `.tsx`/`.jsx` for React-based projects (Electron, React Native)
- `.py` for Python projects
- `.dart` for Flutter projects
- `.xaml` + `.cs` for .NET projects

---

## Per-Paradigm Hints

### desktop-web (Electron, Tauri)

**Typical artifact structure:**
```
arness-sketches/
  [feature-name]/
    sketch-window.tsx         # Main window/page component
    components/               # (optional) sketch-specific components
    sketch-manifest.json
```

**Preview mechanism:**
- Electron: The sketch component can often be rendered via the existing dev server since Electron loads web content. Point the user to the dev server URL.
- Tauri: Similar to Electron -- the frontend is standard web. Use the project's web framework conventions.

**Promotion:** Move files into the project's renderer/frontend directory. Update imports and window routing.

**Key considerations:**
- Electron/Tauri apps have web frontends but also native integration (IPC, file system access, menus). Sketches should focus on the visual UI and mock any native APIs.
- Check if the project uses a web framework (React, Vue, Svelte) for the renderer -- if so, follow that framework's conventions.

### desktop-python (PyQt, PySide, Tkinter)

**Typical artifact structure:**
```
arness-sketches/
  [feature-name]/
    sketch_window.py          # Main window class
    sketch-manifest.json
```

**Preview mechanism:**
- Run: `python arness-sketches/[feature-name]/sketch_window.py`
- The script should create a QApplication/Tk instance and show the window.

**Promotion:** Move the window/widget class into the project's GUI module. Register it with the application's window management.

**Key considerations:**
- PyQt/PySide: Use the project's Qt version (5 vs 6). Match the signal/slot pattern (old-style vs new-style connections). Use the project's layout approach (Designer .ui files vs programmatic layout).
- Tkinter: Use the project's Tkinter style (procedural vs class-based, ttk vs plain widgets). If the project uses a theme, apply it.

### desktop-dotnet (WPF, MAUI)

**Typical artifact structure:**
```
arness-sketches/
  [feature-name]/
    SketchWindow.xaml         # XAML layout
    SketchWindow.xaml.cs      # Code-behind
    sketch-manifest.json
```

**Preview mechanism:**
- .NET desktop apps cannot be trivially previewed from a sketch directory. The builder should create the XAML and code-behind files, and the user can integrate them into the project to preview.
- Alternative: Create a `sketch-mockup.md` with an annotated description of the layout alongside the XAML.

**Promotion:** Move XAML and code-behind files into the project's Views or Pages directory. Register with navigation and dependency injection.

**Key considerations:**
- WPF uses MVVM pattern -- the sketch should create a corresponding ViewModel if the project follows MVVM.
- MAUI uses a similar XAML approach but targets cross-platform. Follow the project's specific MAUI conventions.

### mobile-rn (React Native, Expo)

**Typical artifact structure:**
```
arness-sketches/
  [feature-name]/
    SketchScreen.tsx          # Screen component
    components/               # (optional) sketch-specific components
    sketch-manifest.json
```

**Preview mechanism:**
- React Native apps require a running Metro bundler. The sketch screen can be temporarily added to the app's navigation to preview.
- Expo: Add a temporary route in the app's navigation config.

**Promotion:** Move the screen component into the project's screens directory. Add navigation route. Move any sketch-specific components to the shared components directory.

**Key considerations:**
- Use React Native components (`View`, `Text`, `ScrollView`), not web HTML elements.
- Follow the project's navigation library (React Navigation, Expo Router).
- Check for and use the project's design system (e.g., NativeBase, React Native Paper, custom components).

### mobile-flutter (Flutter)

**Typical artifact structure:**
```
arness-sketches/
  [feature-name]/
    sketch_screen.dart        # Screen widget
    sketch-manifest.json
```

**Preview mechanism:**
- Flutter requires the project to be running. The sketch widget can be temporarily added to the app's route table.
- Hot reload makes iteration fast once the widget is connected.

**Promotion:** Move the widget into the project's screens/pages directory. Add the route. Move any sketch-specific widgets to the shared widgets directory.

**Key considerations:**
- Use the project's state management approach (Provider, Riverpod, Bloc, GetX).
- Follow the project's widget composition patterns (StatelessWidget vs StatefulWidget).
- Use the project's theme (ThemeData, custom design tokens).

---

## Fallback: Descriptive Mockup

If the builder agent cannot produce a working, runnable sketch for the paradigm (due to build toolchain requirements, missing dependencies, or framework complexity), fall back to a descriptive mockup:

Create `sketch-mockup.md` in the sketch directory:

```markdown
# Sketch Mockup: [feature-name]

## Layout Description

[Detailed description of the visual layout, including:
- Section arrangement (top to bottom, left to right)
- Widget/component types for each section
- Data displayed in each section
- Interactive elements and their behavior]

## Wireframe (ASCII)

\```
+------------------------------------------+
|  Header: [title]                   [btn] |
+------------------------------------------+
|  Sidebar   |  Main Content               |
|  - Item 1  |  +-----+ +-----+ +-----+   |
|  - Item 2  |  | Wid | | Wid | | Wid |   |
|  - Item 3  |  +-----+ +-----+ +-----+   |
|            |                              |
+------------------------------------------+
|  Status bar: [status info]               |
+------------------------------------------+
\```

## Component Inventory

| Component | Type | Data Source | Interactions |
|-----------|------|-------------|--------------|
| Header | AppBar / Toolbar | Static | Menu button |
| Sidebar | NavigationList | Config | Selection |
| Main Grid | GridLayout | API | Refresh |

## Notes

[Any assumptions, open questions, or implementation considerations]
```

The descriptive mockup provides enough detail for the user to evaluate the design and give feedback, even without a runnable preview. It is also useful as a spec supplement for the implementation phase.

Set the manifest `previewCommand` to `""` (empty) and add a `"fallback": "descriptive-mockup"` field.
