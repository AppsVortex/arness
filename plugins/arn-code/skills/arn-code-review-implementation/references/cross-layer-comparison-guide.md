<!-- Duplicated from arn-spark/skills/arn-spark-visual-strategy/references/cross-layer-comparison-guide.md. Keep in sync. -->

# Cross-Layer Comparison Guide

This guide defines how cross-layer comparison works during `arn-code-review-implementation`, matching screenshots across rendering contexts (Layer 1 browser vs Layer 2 native) to detect visual divergences.

## Purpose

Cross-layer comparison detects visual divergences between rendering contexts. Layer 1 captures screenshots via browser automation (Playwright), while Layer 2 captures screenshots via native application UI automation (UIA on Windows, NSAccessibility on macOS). Cross-layer comparison identifies when the two contexts produce significantly different visual output for the same logical screen.

This is distinct from intra-layer regression testing (which compares the same layer's current capture against its own baseline). Cross-layer comparison answers a different question: "Does the native app look like the browser version?"

## When to Run

Cross-layer comparison runs **only during `arn-code-review-implementation` Step 3c**.

**Prerequisites:**
- Two or more active layers have produced captures during Step 3b (per-layer regression)
- Both Layer 1 and Layer 2 must have at least one screenshot each

**Skip conditions:**
- If only one layer has captures, skip cross-layer comparison silently
- If Layer 2 status is `deferred`, skip cross-layer comparison
- If no screen names match between layers, report all as `VR-CROSS-UNMAPPED` and conclude

## Screen Matching

Screenshots are matched across layers by **screen name** using a case-insensitive comparison.

### Source of Screen Names per Layer

| Layer | Interaction Mode | Screen Name Source |
|-------|-----------------|-------------------|
| Layer 1 (Browser) | -- | `screen-manifest.json` screen names |
| Layer 2 (Native) | `static` | `screen-manifest.json` screen names |
| Layer 2 (Native) | `journey` | The `name` field from `capture` steps in `journey-manifest.json` |

### Matching Rules

1. Normalize all screen names to lowercase for comparison
2. Match Layer 1 screen names against Layer 2 screen names
3. A screen present in Layer 1 but not Layer 2 is classified as `VR-CROSS-UNMAPPED`
4. A screen present in Layer 2 but not Layer 1 is classified as `VR-CROSS-UNMAPPED`
5. A screen present in both layers forms a **comparison pair**

## Threshold Guidelines

| Parameter | Value | Notes |
|-----------|-------|-------|
| Default cross-layer threshold | 7% pixel difference | Accounts for rendering engine differences |
| Acceptable range | 5-10% | Configurable per project |
| Intra-layer threshold (for contrast) | 0.1-2% | Much tighter because same rendering engine |

The cross-layer threshold is intentionally higher than intra-layer thresholds because browser rendering (Chromium/Blink) and native OS compositing (DWM on Windows, Quartz on macOS) produce inherently different pixel output even for identical logical content. Font hinting, anti-aliasing, sub-pixel rendering, and compositing algorithms all contribute to expected baseline differences.

**Configuration:** Set the project's cross-layer threshold via the `**Cross-layer threshold:**` field in the CLAUDE.md `### Visual Testing` section:

```markdown
### Visual Testing
- **Cross-layer threshold:** 7%
```

## Finding Classification

| Finding ID Pattern | Severity | Condition | Description |
|-------------------|----------|-----------|-------------|
| `VR-CROSS-[ScreenName]-DIVERGENCE` | WARNING | Pixel diff exceeds threshold | The two layers produce visually different output for this screen beyond the acceptable tolerance. Review the diff image to determine if this is an actual defect or an expected platform difference. |
| `VR-CROSS-[ScreenName]-MATCH` | INFO | Pixel diff within threshold | The two layers produce acceptably similar output for this screen. No action required. |
| `VR-CROSS-UNMAPPED` | INFO | Screen present in one layer but not the other | A screen was captured in one layer but has no corresponding capture in the other layer. This is expected when layers test different screen sets. |

**Notes:**
- Cross-layer findings use `WARNING` severity, not `ERROR`. Divergence is informational and should not block the review.
- The `[ScreenName]` in the finding ID uses the original (non-normalized) screen name from the layer that was used as the reference for the comparison pair.

## Expected Differences

The following are known sources of cross-layer visual differences that are **not defects**. Reviewers should consider these when evaluating `VR-CROSS-DIVERGENCE` findings:

| Source | Description | Typical Impact |
|--------|-------------|---------------|
| Font rendering | ClearType (Windows) vs Core Text (macOS) vs FreeType (Linux) vs Skia (Chromium) produce different glyph shapes and hinting | 1-3% pixel diff on text-heavy screens |
| Anti-aliasing algorithms | Browser and native compositor use different anti-aliasing strategies for curves and edges | 0.5-2% pixel diff |
| Transparency compositing | DWM (Windows) and Quartz (macOS) composite transparency differently than Chromium's Skia | 2-5% pixel diff on transparency-heavy screens |
| Native window chrome | Title bar, borders, close/minimize/maximize buttons are OS-rendered in Layer 2 but absent or browser-rendered in Layer 1 | 3-8% pixel diff depending on chrome size |
| Scroll bar rendering | Overlay scrollbars (macOS default) vs classic scrollbars (Windows default) vs Chromium scrollbars | 1-3% pixel diff on scrollable content |
| Focus ring styles | Native focus indicators differ from browser `:focus-visible` styles | 0.5-1% pixel diff on focused elements |
| System theme influence | Dark mode rendering, accent colors, and high contrast mode are applied differently by native compositor vs browser | 2-5% pixel diff under non-default themes |

## Per-Screen Threshold Overrides

For screens with known legitimate divergence that exceeds the global threshold, configure per-screen overrides in the CLAUDE.md `### Visual Testing` section:

```markdown
**Cross-layer overrides:**
- LoginScreen: 12% (heavy transparency gradient on background)
- DashboardCharts: 15% (chart rendering engine differs between browser Canvas and native DirectX/Metal)
- AnimationPreview: 20% (frozen-frame timing differences between browser requestAnimationFrame and native display link)
```

### When to Use Overrides

- **Transparency-heavy screens** -- Screens with frosted glass, acrylic, or blur effects that composite differently across rendering engines
- **Gradient-heavy screens** -- Screens with complex gradients where color interpolation differs between Skia (browser) and native GPU rendering
- **Animation frozen-frames** -- Screens captured mid-animation where the exact frame timing differs between Layer 1 and Layer 2 capture mechanisms
- **Custom-rendered content** -- Canvas, WebGL, or DirectX/Metal-rendered content (charts, maps, 3D views) where the rendering pipeline is fundamentally different

## Comparison Procedure

The following step-by-step algorithm is executed during `arn-code-review-implementation` Step 3c:

1. **Load captures** -- Collect all layer captures produced during Step 3b (per-layer regression). Each capture has a layer identifier, screen name, and file path.

2. **Build screen-name index** -- For each layer, create a map of `lowercase(screenName) -> { originalName, filePath }`.

3. **Match screens across layers** -- Iterate through Layer 1 screen names. For each, look up the lowercase name in Layer 2's index. Record matched pairs and unmatched screens from both layers.

4. **Compare each matched pair:**
   - a. Load both images
   - b. If dimensions differ, resize the smaller image to match the larger (the larger image is the reference). Use nearest-neighbor interpolation to avoid introducing artificial anti-aliasing.
   - c. Run pixel diff using the project's configured comparison tool (pixelmatch or looks-same)
   - d. Compute the difference percentage: `(diffPixelCount / totalPixelCount) * 100`

5. **Load threshold:**
   - a. Check CLAUDE.md for `**Cross-layer threshold:**` field -- use that value if present
   - b. Check for per-screen overrides (`**Cross-layer overrides:**`) -- use the screen-specific value if present
   - c. Default to 7% if neither is configured

6. **Classify each result** -- Apply the finding classification table:
   - Diff percentage > threshold: `VR-CROSS-[ScreenName]-DIVERGENCE` (WARNING)
   - Diff percentage <= threshold: `VR-CROSS-[ScreenName]-MATCH` (INFO)

7. **Collect unmatched screens** -- All screens present in one layer but not the other become `VR-CROSS-UNMAPPED` (INFO) findings.

8. **Aggregate results:**
   - Total comparison pairs
   - Matches (within threshold)
   - Divergences (exceed threshold)
   - Unmapped screens (count and list by layer)
   - Summary recommendation: if any divergences exist, suggest reviewing the diff images
