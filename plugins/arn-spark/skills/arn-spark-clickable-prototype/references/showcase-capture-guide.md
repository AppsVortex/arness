# Clickable Prototype Showcase Capture Guide

This document defines how the `arn-spark-clickable-prototype` skill generates structured visual showcase assets after the judge review passes. The output is a set of per-screen screenshots, organized journey galleries, and an index document that the user can review without running a dev server.

## When This Runs

After the judge returns PASS (or after the final cycle if the judge fails but the user proceeds). This is the last automated step before presenting results to the user. The showcase assets are the user's primary visual deliverable from the clickable prototype process.

## Prerequisites

- The prototype is built and can be served (dev server starts successfully)
- The `screen-manifest.json` exists in the version directory (written by `arn-spark-prototype-builder`)
- Journey screenshots exist in `prototypes/clickable/v[N]/journeys/` (captured by `arn-spark-ui-interactor` during Step 4b)
- Playwright is available for screen capture

If Playwright is not available, skip automated screen capture and inform the user: "Playwright is not available. The prototype can be viewed by running the dev server. Automated visual export was skipped." The skill continues to the user review step. Journey screenshots (already captured during interaction testing) are still organized into the showcase index.

## Screen Capture Process

### 1. Read the screen manifest

Read `prototypes/clickable/v[N]/screen-manifest.json` to get the list of screens with their routes and functional areas. If the manifest does not exist (e.g., an older prototype build), fall back to capturing only the hub page and skip per-screen captures.

### 2. Start the prototype

Start the dev server using the same procedure as Step 4b of the main skill. Record the URL and process ID.

### 3. Generate a capture script

Generate a Playwright script tailored to the project's stack. The script must:

1. **Launch** a browser with a consistent viewport (e.g., 1440x900 for desktop, or the target viewport from the style brief)
2. **Navigate to each screen route** from the manifest, in order grouped by functional area
3. **Wait** for the page to be fully loaded (network idle, no pending animations)
4. **Capture each screen:** Take a full-viewport screenshot → `screens/NN-area-screen-name.png`
5. **Capture the hub:** The first capture should be the hub/index screen → `screens/01-hub.png`
6. **Dark mode captures (if applicable):** If the prototype has a dark mode toggle:
   - After capturing all screens in light mode, toggle dark mode ON
   - Re-navigate to each screen and capture → `screens/NN-area-screen-name-dark.png`

**Script generation approach by stack:**

| Stack | Capture method |
|-------|---------------|
| Web app (any framework) | Playwright script targeting `localhost` URL, navigating to each route |
| Desktop app with web view (Tauri, Electron) | Playwright script targeting the web view URL |
| Native mobile app | Start simulator/emulator, use platform screenshot tools. Per-screen capture by navigating through the hub. If not feasible, capture hub only and note the limitation. |
| Terminal/CLI app | Not applicable for visual showcase. Skip this step and note: "Terminal applications do not produce visual showcases." |

**Script location:** Write the generated script to `prototypes/clickable/v[N]/showcase/capture-script.js` (or `.ts`, `.py` — match the project's ecosystem). This allows the user to re-run the capture manually if needed.

### 4. Run the capture script

Execute the script via Bash. If a screen capture fails (route not found, timeout), skip that screen and note it in the showcase index. Do not fail the entire capture for one missing screen.

### 5. Stop the prototype

Kill the dev server process.

## Journey Gallery Process

Journey screenshots already exist from the interaction testing step (Step 4b). The showcase organizes them into a readable gallery without re-capturing.

### 1. Discover journey directories

Scan `prototypes/clickable/v[N]/journeys/` for subdirectories. Each subdirectory contains one journey's screenshots.

### 2. Read journey definitions

Use the journey definitions from Step 1b/Step 2 to provide step labels and journey goals. If the journey definitions are not available, use the screenshot filenames to infer step descriptions (they follow the `NN-action-description.png` naming convention).

### 3. Organize into the showcase index

For each journey, list the screenshots in order with:
- Step number and action description
- Screenshot embed (relative path to the existing file in `journeys/`)
- Step outcome (OK or FAIL, inferred from filename — failures are prefixed with `FAIL-`)

Journey screenshots are referenced from their existing location, not copied to the showcase directory.

## Output Structure

```
prototypes/clickable/v[N]/showcase/
├── capture-script.js              ← Generated Playwright script (re-runnable)
├── screens/
│   ├── 01-hub.png                 ← Hub/index screen
│   ├── 02-setup-device-search.png ← Per-screen captures (light mode)
│   ├── 03-setup-device-found.png
│   ├── 04-main-dashboard.png
│   ├── ...
│   ├── 02-setup-device-search-dark.png  ← Dark mode variants (if applicable)
│   ├── 03-setup-device-found-dark.png
│   └── ...
└── showcase-index.md              ← Visual summary document
```

Journey screenshots remain in their original location:
```
prototypes/clickable/v[N]/journeys/
├── device-pairing/
│   ├── 00-initial-state.png
│   ├── 01-click-add-device.png
│   ├── 02-device-list-appears.png
│   └── ...
└── settings-navigation/
    ├── 00-initial-state.png
    └── ...
```

### File naming convention

- Screen files: `NN-area-screen-name.png` where `NN` is the zero-padded number, `area` is the functional area in kebab-case, and `screen-name` is the screen name in kebab-case (e.g., `02-setup-device-search.png`, `05-main-dashboard.png`)
- Dark mode variants: append `-dark` before the extension (e.g., `02-setup-device-search-dark.png`)
- Hub screen: always `01-hub.png` / `01-hub-dark.png`

## Showcase Index Template

The `showcase-index.md` is a self-contained markdown document that the user can open to see all screens and journey flows with context. It embeds screen images using relative links and journey images using relative paths to the `journeys/` directory.

```markdown
# Clickable Prototype Showcase — v[N]

**Version:** [N]
**Judge verdict:** [PASS / FAIL]
**Date:** [YYYY-MM-DD]
**Screens:** [total count]
**Journeys:** [total count] ([completed]/[total] completed)

## Scores Summary

| # | Criterion | Score | Status |
|---|-----------|-------|--------|
| 1 | [name] | [combined] | PASS/FAIL |
| ... | ... | ... | ... |

---

## Screen Gallery

### Hub

![Hub](./screens/01-hub.png)

### [Area 1: Setup]

#### Device Search
![Device Search](./screens/02-setup-device-search.png)

#### Device Found
![Device Found](./screens/03-setup-device-found.png)

[... one entry per screen in the area ...]

### [Area 2: Main Experience]

#### Dashboard
![Dashboard](./screens/04-main-dashboard.png)

[... one entry per screen in the area ...]

[... repeat for all functional areas ...]

---

## Journey Gallery

### Journey 1: [Name]

**Goal:** [what the user accomplishes]
**Result:** COMPLETE / PARTIAL ([N] of [M] steps)

| Step | Action | Screenshot | Result |
|------|--------|------------|--------|
| 0 | Initial state | ![Start](../journeys/[journey-name]/00-initial-state.png) | OK |
| 1 | [action] | ![Step 1](../journeys/[journey-name]/01-[name].png) | OK |
| 2 | [action] | ![Step 2](../journeys/[journey-name]/02-[name].png) | OK / FAIL |
| ... | ... | ... | ... |

### Journey 2: [Name]

[... repeat for all journeys ...]

[If dark mode exists:]

---

## Dark Mode

### Hub (Dark)
![Hub Dark](./screens/01-hub-dark.png)

### [Area 1: Setup] (Dark)

#### Device Search (Dark)
![Device Search Dark](./screens/02-setup-device-search-dark.png)

[... repeat for all screens ...]

---

*Generated by Arness Clickable Prototype v[N] — [date]*
```

## Error Handling

- **Playwright unavailable:** Skip screen capture entirely. Journey screenshots are still organized into the showcase index (they were captured during interaction testing, which has its own Playwright fallback). If no journey screenshots exist either, write the showcase index as text-only (scores, journey outcomes, no images).
- **Screen manifest missing:** Capture the hub page only. Note: "Screen manifest not found. Only hub capture produced. Re-build the prototype to generate per-screen captures."
- **Route not found:** Skip that screen's capture. List skipped screens in the showcase index.
- **Dev server fails to start:** Skip screen capture. Organize journey screenshots into the showcase index without screen gallery.
- **Dark mode toggle not found:** Capture light mode only. Note in the index: "Dark mode toggle not detected. Only light mode captured."
- **No journey screenshots:** Write the showcase index with screen gallery only. Note: "No journey screenshots found. Run interaction testing (Step 4b) to generate journey captures."
- **Native mobile (no Playwright):** Attempt platform-specific capture. If not feasible, note the limitation and suggest the user capture screenshots manually from the simulator.
