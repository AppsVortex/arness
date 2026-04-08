# Sketch Gallery Guide

This guide defines how the gallery index page should be structured. The `arn-spark-visual-sketch` skill creates and maintains this page — the `arn-spark-visual-sketcher` agents do not touch it.

## Purpose

The gallery is the user's entry point for comparing visual direction proposals. It must be immediately useful: a user landing on it should see all proposals at a glance, understand each direction, and navigate to any proposal in one click.

## Gallery Layout

### Structure

```
/arness-sketches/                    ← Gallery index (this page)
/arness-sketches/round-1/proposal-1/ ← First proposal screens
/arness-sketches/round-1/proposal-2/ ← Second proposal screens
/arness-sketches/round-1/proposal-3/ ← Third proposal screens
/arness-sketches/round-2/expansion-1/ ← Expansion of selected proposal
/arness-sketches/round-2/expansion-2/ ← Another expansion
```

### Gallery Index Content

The gallery index page displays:

1. **Title:** "Visual Direction Sketches" or similar
2. **Round sections:** One section per round, most recent first
3. **Proposal cards:** Within each round, one card per proposal

### Proposal Cards

Each card shows:

- **Proposal identifier:** e.g., "Proposal A" or "Expansion 1"
- **Direction brief summary:** The first sentence or a shortened version of the direction brief
- **Key visual indicators:** 3-4 color swatches from the proposal's CSS variables (rendered as small colored circles or rectangles)
- **Link:** Clicking the card navigates to the proposal's first screen

### Multi-Round Display

- All rounds are shown, newest at the top
- The selected proposal from each completed round is visually highlighted (e.g., a border, a "Selected" badge, or a subtle background)
- Rounds that led to expansions show a visual connection: "Round 2 — Expansions of Proposal B from Round 1"

### Navigation

- Each proposal card links to the proposal's first screen
- Within each proposal, the `arn-spark-visual-sketcher` agent creates intra-proposal navigation between screens
- A "Back to Gallery" link should appear on each proposal's pages (the agent's intra-proposal nav handles this within its layout)

## Framework-Specific Patterns

### SvelteKit

```
src/routes/arness-sketches/
  +page.svelte              ← Gallery index
  +layout.svelte            ← Minimal shared layout (no global styling that affects proposals)
  round-1/
    proposal-1/
      +layout.svelte        ← CSS variable isolation for this proposal
      +page.svelte          ← First screen
      list/+page.svelte     ← Second screen
    proposal-2/
      +layout.svelte
      +page.svelte
      ...
```

The top-level `+layout.svelte` at `arness-sketches/` should be minimal — just a wrapper that does NOT define CSS variables. Only proposal-level layouts define `--sketch-*` variables.

### Next.js (App Router)

```
app/arness-sketches/
  page.tsx                  ← Gallery index
  layout.tsx                ← Minimal shared layout
  round-1/
    proposal-1/
      layout.tsx            ← CSS variable isolation
      page.tsx              ← First screen
      list/page.tsx         ← Second screen
    ...
```

### Nuxt

```
pages/arness-sketches/
  index.vue                 ← Gallery index
  round-1/
    proposal-1/
      index.vue             ← First screen (layout via definePageMeta or wrapper)
      list.vue              ← Second screen
    ...
```

### Generic (no file-based routing)

Create a standalone HTML page or a route in the project's router configuration. Use a simple hash-based or conditional rendering approach for the gallery.

## Implementation Notes

- The gallery itself is **sketch-quality** — it does not need to be polished. Simple layout, readable text, clickable links. It is a tool for comparison, not a deliverable.
- Use the project's CSS framework for basic styling (Tailwind utilities, etc.) but do NOT use proposal-specific CSS variables. The gallery should look neutral.
- Read each proposal's `proposal-manifest.json` to get the screen list, routes, direction summary, and CSS variable values for rendering color swatches.
- When updating the gallery for a new round (Step 8 of the skill), preserve existing round sections. Prepend the new round at the top.
- If a proposal failed to generate (agent error), show a placeholder card: "Proposal X — Generation failed. [Error summary]"

## Gallery Visual Standards

The gallery is a comparison tool, not a product deliverable — but it must look consistent across runs so the user can focus on comparing proposals, not deciphering a different layout each time. These standards define the gallery's visual scaffold using a dedicated `--gallery-*` CSS variable namespace that never collides with `--sketch-*` proposal variables.

### CSS Variables

Define these on the gallery wrapper element (never on `:root`):

```css
--gallery-bg: #fafafa;
--gallery-surface: #ffffff;
--gallery-text: #1a1a1a;
--gallery-text-muted: #6b7280;
--gallery-border: #e5e7eb;
--gallery-accent: #2563eb;
--gallery-radius: 8px;
--gallery-font: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
--gallery-shadow: 0 1px 3px rgba(0, 0, 0, 0.08);
```

### Page Structure

- Max-width: `960px`, centered with `margin: 0 auto`
- Horizontal padding: `2rem`
- Background: `var(--gallery-bg)`
- All text uses `var(--gallery-font)` — the gallery never inherits proposal fonts

### Round Section Headers

- Round title (e.g., "Round 1" or "Round 2 — Expansions of Proposal B"): `1.25rem`, font-weight `600`, color `var(--gallery-text-muted)`
- Margin: `2.5rem` top (between rounds), `1rem` bottom (before card grid)
- First round has no top margin

### Proposal Card Grid

- Layout: `display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 1.25rem`
- No media queries — `auto-fill` with `minmax` handles responsive behavior intrinsically (1 column on narrow, 2-3 on wider)

### Card Anatomy

Every proposal card follows this exact internal structure:

```
┌─────────────────────────────┐
│  Proposal A                 │  ← identifier: 1rem, bold
│                             │
│  Dark and focused with      │  ← brief: 0.875rem, muted,
│  deep charcoal backgrounds  │     max 3 lines, overflow
│  and electric blue...       │     hidden with ellipsis
│                             │
│  Confident & calm · Sharp   │  ← direction note: 0.75rem,
│  edges, no shadows          │     italic, muted, 1 line
│                             │
│  ● ● ● ●                   │  ← swatches: 4 circles
│                             │
│  View proposal →            │  ← link: 0.875rem, accent
└─────────────────────────────┘
```

Card styling:
- Background: `var(--gallery-surface)`
- Border: `1px solid var(--gallery-border)`
- Border-radius: `var(--gallery-radius)`
- Box-shadow: `var(--gallery-shadow)`
- Padding: `1.25rem`

**Proposal identifier:** `font-size: 1rem; font-weight: 700; color: var(--gallery-text); margin-bottom: 0.5rem`

**Direction brief:** `font-size: 0.875rem; color: var(--gallery-text-muted); line-height: 1.5; display: -webkit-box; -webkit-line-clamp: 3; -webkit-box-orient: vertical; overflow: hidden; margin-bottom: 0.75rem`

**Direction note:** `font-size: 0.75rem; font-style: italic; color: var(--gallery-text-muted); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; margin-bottom: 0.75rem`
- Shows the tone commitment + differentiation anchor from the direction brief, separated by " · "
- Sourced from `proposal-manifest.json` field `directionNote`
- If `directionNote` is not present in the manifest (backward compatibility with older proposals), omit this line entirely

**Color swatches:** A row of exactly **4 circles** showing the proposal's key colors:
- Values sourced from `proposal-manifest.json`: `--sketch-bg`, `--sketch-primary`, `--sketch-accent`, `--sketch-surface`
- Each circle: `width: 24px; height: 24px; border-radius: 50%; border: 1px solid var(--gallery-border)`
- Row: `display: flex; gap: 8px; margin-bottom: 0.75rem`

**View link:** `font-size: 0.875rem; color: var(--gallery-accent); text-decoration: none; font-weight: 500`

### Selected Proposal Highlight

When a proposal has been selected in a completed round:
- `border-left: 3px solid var(--gallery-accent)` (replaces the standard `1px` left border)
- A "Selected" badge in the header row: `display: inline-block; font-size: 0.6875rem; font-weight: 600; background: var(--gallery-accent); color: #ffffff; padding: 2px 8px; border-radius: 999px; margin-left: 0.5rem; vertical-align: middle`

### Failed Proposal Treatment

When a proposal failed to generate:
- Border style: `1px dashed var(--gallery-border)`
- Background: `var(--gallery-bg)` (matches page, visually recessed)
- Brief text: italic, shows error summary
- No swatch row or view link

### Required HTML Skeleton

All framework implementations must produce this semantic structure:

```html
<div class="gallery-wrapper" style="/* --gallery-* variables defined here */">
  <h1>Visual Direction Sketches</h1>

  <!-- One section per round, newest first -->
  <section class="gallery-round">
    <h2>Round 1</h2>
    <div class="gallery-grid">

      <a href="/arness-sketches/round-1/proposal-1" class="gallery-card">
        <div class="card-header">
          <span class="card-id">Proposal A</span>
          <!-- if selected: <span class="card-badge">Selected</span> -->
        </div>
        <p class="card-brief">Direction brief summary...</p>
        <p class="card-note">Confident & calm · Sharp edges, no shadows</p>
        <div class="card-swatches">
          <span class="swatch" style="background: #1a1a2e"></span>
          <span class="swatch" style="background: #2563eb"></span>
          <span class="swatch" style="background: #7c3aed"></span>
          <span class="swatch" style="background: #1e1e30"></span>
        </div>
        <span class="card-link">View proposal →</span>
      </a>

      <!-- repeat for each proposal -->
    </div>
  </section>
</div>
```

Class names are semantic references — use the project's CSS framework to implement the styles. The structure (nesting, element types, order of children) must be followed.

### Tailwind Utility Example

For projects using Tailwind, the card grid and card anatomy translate to:

```html
<!-- Gallery wrapper -->
<div class="max-w-[960px] mx-auto px-8 bg-[#fafafa] font-[system-ui]">

  <!-- Round section -->
  <section class="mt-10 first:mt-0">
    <h2 class="text-xl font-semibold text-gray-500 mb-4">Round 1</h2>
    <div class="grid grid-cols-[repeat(auto-fill,minmax(280px,1fr))] gap-5">

      <!-- Card -->
      <a href="..." class="block bg-white border border-gray-200 rounded-lg shadow-sm p-5
                           hover:shadow-md transition-shadow no-underline">
        <div class="mb-2">
          <span class="text-base font-bold text-gray-900">Proposal A</span>
        </div>
        <p class="text-sm text-gray-500 leading-relaxed line-clamp-3 mb-3">
          Dark and focused with deep charcoal backgrounds...
        </p>
        <p class="text-xs italic text-gray-400 truncate mb-3">
          Confident & calm · Sharp edges, no shadows
        </p>
        <div class="flex gap-2 mb-3">
          <span class="w-6 h-6 rounded-full border border-gray-200" style="background:#1a1a2e"></span>
          <span class="w-6 h-6 rounded-full border border-gray-200" style="background:#2563eb"></span>
          <span class="w-6 h-6 rounded-full border border-gray-200" style="background:#7c3aed"></span>
          <span class="w-6 h-6 rounded-full border border-gray-200" style="background:#1e1e30"></span>
        </div>
        <span class="text-sm font-medium text-blue-600">View proposal →</span>
      </a>

    </div>
  </section>
</div>
```

Adapt class names for the project's Tailwind version and configuration, but maintain the same visual proportions and structure.
