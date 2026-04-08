# Showcase Capture Guide

This document defines how the `arn-spark-static-prototype` skill generates structured visual showcase images after the judge review passes. The output is a set of per-section screenshots and an index document that the user can glance at without running a dev server.

## When This Runs

After the judge returns PASS (or after the final cycle if the judge fails but the user proceeds). This is the last automated step before presenting results to the user. The showcase images are the user's primary visual deliverable from the static prototype process.

## Prerequisites

- The showcase is built and can be served (dev server starts successfully)
- The `showcase-manifest.json` exists in the version directory (written by `arn-spark-prototype-builder`)
- Playwright is available for screenshot capture

If Playwright is not available, skip automated capture and inform the user: "Playwright is not available. The showcase can be viewed by running the dev server. Automated visual export was skipped." The skill continues to the user review step without showcase images.

## Capture Process

### 1. Read the section manifest

Read `prototypes/static/v[N]/showcase-manifest.json` to get the list of sections with their IDs and titles. If the manifest does not exist (e.g., an older prototype build), fall back to capturing a single full-page screenshot only.

### 2. Start the prototype

Start the dev server using the same procedure as Step 4b of the main skill. Record the URL and process ID.

### 3. Generate a capture script

Generate a Playwright script tailored to the project's stack. The script must:

1. **Navigate** to the showcase URL
2. **Wait** for the page to be fully loaded (network idle, no pending animations)
3. **Set dark mode to OFF** (if a dark/light toggle exists) for the primary captures
4. **Capture full page:** Take a full-page scrolling screenshot → `showcase-full.png`
5. **Capture each section:** For each entry in the manifest:
   - Scroll the element with `id="showcase-section-NN"` into view
   - Wait for any lazy-loaded content or animations to settle
   - Capture the element's bounding box → `NN-title.png` (e.g., `01-typography.png`, `04-buttons.png`)
6. **Dark mode captures (if applicable):** If the showcase has dark mode:
   - Toggle dark mode ON
   - Capture full page → `showcase-full-dark.png`
   - Capture each section → `NN-title-dark.png`

**Script generation approach by stack:**

| Stack | Capture method |
|-------|---------------|
| Web app (any framework) | Playwright script targeting `localhost` URL |
| Desktop app with web view (Tauri, Electron) | Playwright script targeting the web view URL (Tauri: `localhost` dev server; Electron: dev server or `chrome-devtools://` if needed) |
| Native mobile app | Start simulator/emulator, use platform screenshot tools (`xcrun simctl io` for iOS, `adb exec-out screencap` for Android). Per-section capture requires scrolling automation via the platform's UI testing framework. If not feasible, capture full-page only and note the limitation. |
| Terminal/CLI app | Not applicable for visual showcase. Skip this step and note: "Terminal applications do not produce visual showcases." |

For the vast majority of greenfield projects (web, Tauri, Electron), the Playwright approach works directly because the prototype builder creates web-based showcases served via a dev server.

**Script location:** Write the generated script to `prototypes/static/v[N]/showcase/capture-script.js` (or `.ts`, `.py` — match the project's ecosystem). This allows the user to re-run the capture manually if needed.

### 4. Run the capture script

Execute the script via Bash. If a section capture fails (element not found, timeout), skip that section and note it in the showcase index. Do not fail the entire capture for one missing section.

### 5. Stop the prototype

Kill the dev server process.

## Output Structure

```
prototypes/static/v[N]/showcase/
├── capture-script.js          ← Generated Playwright script (re-runnable)
├── showcase-full.png          ← Full-page scrolling capture (light mode)
├── showcase-full-dark.png     ← Full-page scrolling capture (dark mode, if applicable)
├── 01-typography.png          ← Per-section captures (light mode)
├── 02-colors.png
├── 03-containers.png
├── 04-buttons.png
├── 05-forms.png
├── ...
├── 01-typography-dark.png     ← Per-section captures (dark mode, if applicable)
├── 02-colors-dark.png
├── ...
└── showcase-index.md          ← Visual summary document
```

### File naming convention

- Section files: `NN-title.png` where `NN` is the zero-padded section number and `title` is the section title in kebab-case (e.g., `04-buttons-and-controls.png`)
- Dark mode variants: append `-dark` before the extension (e.g., `04-buttons-and-controls-dark.png`)
- Full page: `showcase-full.png` / `showcase-full-dark.png`

## Showcase Index Template

The `showcase-index.md` is a self-contained markdown document that the user can open to see all showcase images with context. It embeds the images using relative markdown image links.

```markdown
# Component Showcase — v[N]

**Version:** [N]
**Judge verdict:** [PASS / FAIL]
**Date:** [YYYY-MM-DD]
**Style brief:** [product-name] style brief

## Scores Summary

| # | Criterion | Score | Status |
|---|-----------|-------|--------|
| 1 | [name] | [combined] | PASS/FAIL |
| ... | ... | ... | ... |

---

## Component Sections

### 1. Typography
![Typography](./01-typography.png)

### 2. Colors
![Colors](./02-colors.png)

### 3. Containers
![Containers](./03-containers.png)

[... one section per captured image ...]

## Full Page View
![Full showcase](./showcase-full.png)

[If dark mode exists:]

---

## Dark Mode

### 1. Typography (Dark)
![Typography Dark](./01-typography-dark.png)

[... repeat for all sections ...]

### Full Page View (Dark)
![Full showcase dark](./showcase-full-dark.png)

---

*Generated by Arness Static Prototype v[N] — [date]*
```

## Error Handling

- **Playwright unavailable:** Skip the entire capture. Inform the user the showcase can be viewed by running the dev server.
- **Manifest missing:** Capture full-page only. Note: "Section manifest not found. Only full-page capture produced. Re-build the showcase to generate per-section captures."
- **Section element not found:** Skip that section's capture. List skipped sections in the showcase index.
- **Dev server fails to start:** Skip the capture. Print the showcase index template (without images) so the user knows what sections exist.
- **Dark mode toggle not found:** Capture light mode only. Note in the index: "Dark mode toggle not detected. Only light mode captured."
- **Native mobile (no Playwright):** Attempt platform-specific capture. If not feasible, note the limitation and suggest the user capture screenshots manually from the simulator.
