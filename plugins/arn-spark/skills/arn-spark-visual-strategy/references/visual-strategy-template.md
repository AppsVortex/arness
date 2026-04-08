# Visual Strategy Template

This template defines the structure for the `visual-strategy.md` document written by the `arn-spark-visual-strategy` skill. The document captures the project's visual testing strategy, validated through mini-spikes, with baseline configuration and script inventory.

## Template

```markdown
# Visual Testing Strategy

Defined by `/arn-spark-visual-strategy` on [date].

## Summary

- **Testing layers:** [N] layers configured ([layer names])
- **Baseline images:** [N] screen baselines + [M] journey baselines
- **Baseline source:** Prototype v[X] ([locked / unlocked])
- **Comparison tool:** [pixelmatch / looks-same / custom]
- **Diff threshold:** [N]% pixel difference tolerance

## Stack Analysis

| Property | Value |
|----------|-------|
| Application type | [Browser app / Tauri desktop / Electron / etc.] |
| UI framework | [SvelteKit / React / Vue / etc.] |
| Rendering context | [Browser viewport / Webview in native frame / Native + transparency / etc.] |
| Platform targets | [Linux, macOS, Windows] |
| Development environment | [Native / WSL2 / Dev container / etc.] |
| Current OS | [detected] |

### Key Constraints

[Numbered list of constraints that affect the testing strategy, e.g.:]
1. [Tauri transparency cannot be captured by browser-based tools]
2. [WSL2 has no native Windows display server access]
3. [Webview content IS accessible via standard HTTP dev server]

## Testing Layers

### Layer 1: [Layer Name]

- **What it captures:** [description]
- **Coverage:** [what is and isn't covered]
- **Tool:** [Playwright / OS screenshot API / etc.]
- **Environment:** [where it runs]
- **Complexity:** [Low / Medium / High]
- **Trade-off:** [what you get vs what you miss]

**Spike result:** [Validated / Partially validated / Failed / Deferred]
**Evidence:** [brief description of spike outcome, e.g., "Captured 12 screens at 1280x720, diff tool detected intentional change in button placement"]
**Caveats:** [platform-specific notes, known limitations]
**Status:** [active / deferred]
**Activation criteria:** [condition for promoting from deferred to active, or "N/A" if active]

### Layer 2: [Layer Name]

[Same structure as Layer 1, including Status and Activation criteria]

## Baseline Configuration

### Source

| Source | Path | Image count |
|--------|------|-------------|
| Clickable prototype showcase (v[N]) | [path] | [N] |
| Journey captures (v[N]) | [path] | [N] |
| Static prototype showcase (v[M]) | [path] | [N] |

### Organization

- **Baseline directory:** [path, e.g., visual-tests/baselines/]
- **Naming convention:** [e.g., screen-name--viewport.png]
- **Manifest:** [path to baseline-manifest.json]

### Baseline Image Mapping

| Screen/Component | Baseline File | Source Screenshot | Category |
|-----------------|---------------|-------------------|----------|
| [name] | [baseline path] | [prototype screenshot path] | [Layout / Component / Flow] |

## Scripts Inventory

| Script | Path | Purpose | Usage |
|--------|------|---------|-------|
| Capture | [path] | Navigate screens, capture screenshots | `[command]` |
| Compare | [path] | Diff captures against baselines | `[command]` |
| Baseline setup | [path] | Copy prototype screenshots to baseline dir | `[command]` |
| [Cross-env pipeline] | [path] | [WSL2-to-Windows / etc.] | `[command]` |

## Cross-Environment Pipeline

[Only if Layer 2+ requires cross-environment execution. Omit if not applicable.]

### Pipeline Steps

1. [Step 1: e.g., Copy project source to Windows-accessible path]
2. [Step 2: e.g., Trigger build on Windows]
3. [Step 3: e.g., Capture screenshots using Windows screenshot tool]
4. [Step 4: e.g., Copy screenshots back to WSL2 for comparison]

### Requirements

- [e.g., Windows path accessible from WSL2 at /mnt/c/...]
- [e.g., Node.js installed on Windows]
- [e.g., PowerShell script for Windows-side build and capture]

## CI Integration

[Only if CI was configured. Omit if not applicable.]

- **Workflow file:** [path]
- **Trigger:** [on push / on PR / manual]
- **Platform matrix:** [which OSes run visual tests]
- **Artifact upload:** [whether captured screenshots are uploaded as CI artifacts]

## Threshold Configuration

- **Default threshold:** [N]% pixel difference tolerance
- **Per-screen overrides:** [if any screens need different thresholds]
- **Anti-aliasing handling:** [ignore / threshold adjustment / specific tool option]
- **Viewport:** [width x height, e.g., 1280x720]

## Known Limitations

[Numbered list of what the strategy does NOT cover:]
1. [e.g., Native window chrome and transparency effects (Layer 2 deferred)]
2. [e.g., Sub-pixel rendering differences between Linux and macOS]
3. [e.g., Dark mode variants not yet baselined]
- Deferred layers can be activated with `/arn-spark-visual-readiness` once their activation criteria are met.

## Updating Baselines

When the design intentionally changes (not a regression):

1. Run the capture script to generate new screenshots
2. Visually verify the new screenshots match the intended design
3. Run `[baseline update command]` to replace baselines with new captures
4. Commit the updated baselines

Baselines should only be updated after deliberate design changes, never to suppress a failing test.
```
