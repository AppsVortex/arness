# Aesthetic Philosophy

Read this before translating any direction brief into code. It establishes how to think about design — not what to build, but the creative mindset that produces distinctive, memorable visual directions instead of generic templates.

These guidelines set a quality floor. User-specified direction briefs take precedence when they explicitly override a guideline.

---

## 1. Design Thinking — Mandatory Pre-Generation Exercise

Before writing a single line of CSS or markup, work through these four questions. The answers shape every decision that follows.

**Purpose — What problem does this interface solve? Who uses it? What do they need to feel?**

Ground yourself in empathy before aesthetics. A dashboard for financial analysts needs to communicate precision and trust. A creative tool for designers needs to feel fluid and expressive. A personal health tracker needs to feel calm and private. The visual direction is not decoration — it is the emotional register of the product. Name the feeling you are designing for.

**Tone — Commit to a specific aesthetic posture.**

Pick one from this palette, or combine two that create productive tension. Do not hedge with "clean and modern" — that is the absence of a decision.

- Brutally minimal
- Maximalist / layered
- Retro-futuristic
- Organic / natural
- Luxury / refined
- Editorial / magazine
- Brutalist / raw
- Art deco / geometric
- Industrial / utilitarian
- Archival / typographic
- Warm institutional (law firm, architecture firm, private bank)

You may invent a tone not on this list. The requirement is commitment, not conformity.

**Differentiation — What is the ONE thing someone will remember about this design?**

Every memorable interface has a signature move. Linear's is its ultra-tight spacing and monochrome palette. Stripe's is its gradient mesh backgrounds. Apple's is its product photography floating in white space. Name yours. It might be a ruled-line ledger system, an oversized serif heading with tight tracking, a single unexpected accent color, or a terminal-aesthetic code block that structures the whole page. One thing, committed to fully.

**Execution contract — Bold maximalism and refined minimalism both work. The key is intentionality, not intensity.**

Do not hedge by doing a little bit of everything. A direction that is "sort of minimal but with some color and a bit of texture" communicates nothing. Commit to the tone. If it is minimal, make the emptiness feel like a deliberate choice. If it is maximal, layer with confidence. The worst outcome is not a direction that is too bold — it is one that is too safe to provoke a reaction.

Document your answers in an HTML comment block at the top of the layout component:

```html
<!--
  DESIGN THINKING
  Purpose: [answer]
  Tone: [answer]
  Differentiation: [answer]
  Execution: [answer]
-->
```

---

## 2. Anti-Generic Rules

These are hard constraints, not suggestions. They exist because without them, the statistical mean of training data produces output that looks like every other AI-generated page.

### Typography

- NEVER use system font stacks as the primary design font (system-ui, -apple-system, BlinkMacSystemFont, Segoe UI). System fonts are fallbacks, not design choices.
- NEVER use Inter, Roboto, Open Sans, Lato, Montserrat, or Poppins as heading fonts. These are the default choices of every generic page. They are fine body fonts in specific contexts — they are never distinctive heading fonts.
- NEVER use the same font family for both headings and body without a deliberate reason documented in the Design Thinking block. Tension between heading and body fonts is a primary source of visual character.
- NEVER default to the project scaffold's font (e.g., Geist Sans) for visual sketches. Sketches explore DIFFERENT directions, not variations of the scaffold default.

### Color

- NEVER use purple-to-blue gradients on white backgrounds. This is the single most common AI-generated color scheme.
- NEVER distribute accent colors evenly. A dominant color with surgical accent placement outperforms a balanced palette every time. Follow the 60-30-10 rule: 60% dominant background, 30% surface/container, 10% accent. The accent is surgical — used for the ONE thing you want the user to notice in each section.
- NEVER use pure white (#ffffff) or pure black (#000000) as the primary background without textural variation — a subtle gradient shift, micro-texture, or tonal warmth/coolness. Flat pure white or pure black reads as "no decision was made."

### Layout

- NEVER use identical card grids for every content section. Vary the layout pattern between sections — grid, asymmetric two-column, full-width, ruled table, magazine-style. A page where every section uses the same grid is visually monotonous.
- NEVER center-align every section. Mix alignments deliberately. Left-aligned content with a right-aligned pull quote creates energy. Center-aligned hero with left-aligned body creates hierarchy.
- NEVER use uniform spacing between all sections. Vary vertical rhythm to create breathing room and density contrast. Hero sections get generous padding (6-8rem), content sections get moderate (4-5rem), related items get tight (2-3rem).

### Components

- NEVER use rounded-corner cards with drop shadows as the universal content container. If every content block is a card with `border-radius: 8px; box-shadow: 0 2px 4px`, you have not made a design decision.
- NEVER use pill-shaped tags/badges as the only decorative element. Pill badges are a single tool, not a design system.
- NEVER use a hamburger menu icon on desktop layouts.

### The Generic Test

No design should look like it could have been generated by any other AI tool. If you removed the content, could this be ANY company's website? If yes, it is too generic. Start over with a stronger Design Thinking commitment.

---

## 3. Design Dimension Guidance

Concrete techniques for translating a direction brief into distinctive CSS values.

### Typography

Pair a distinctive display font with a complementary body font. The pairing itself should be a design statement.

**Heading fonts with character:** Serifs with personality (Newsreader, Cormorant Garamond, Libre Baskerville, Playfair Display), geometric sans with edge (Archivo, Syne, Space Grotesk used thoughtfully), or monospace for technical authority (JetBrains Mono, IBM Plex Mono, Fira Code).

**Body fonts with warmth:** Libre Baskerville, Source Serif, DM Sans, Instrument Sans. Prioritize readability but avoid blandness.

Use Google Fonts for availability. If the project uses licensed or self-hosted fonts, prefer those over Google Fonts. Specify exact weights — never load all weights. Two or three weights per family is sufficient.

Vary font sizes with purpose: massive display sizes (4-6rem) for hero text create impact; tight, small monospace (0.625-0.75rem) for labels creates contrast. The size ratio between your largest and smallest text should be at least 6:1.

Letter-spacing is a design tool: tight tracking (-0.02em) on large headings feels premium; wide tracking (0.15-0.3em) on small uppercase labels feels institutional. Use it deliberately.

### Color & Theme

Define a complete palette using CSS custom properties. Minimum 8 tokens: background, surface, elevated-surface, primary/accent, text, text-muted, text-dim, border.

Use opacity and alpha channels for border colors — `rgba(accent, 0.15)` creates cohesion without heaviness.

Dark themes need at least 3 background tones (deep, default, elevated) to create depth. A single flat dark background looks like a terminal, not a design.

Warm palettes (browns, brass, copper) feel institutional and trustworthy. Cool palettes (slate, steel, teal) feel technical and precise. Match the palette temperature to the brand's emotional register from your Design Thinking answers.

### Spatial Composition

Vary layout patterns across sections. Techniques for variety:

- Asymmetric two-column (60/40 or 70/30) for content with supporting metadata
- Ruled table or ledger layouts for structured data — horizontal lines as organizing elements
- Full-bleed sections alternating with max-width contained sections for rhythm
- Sidebar-style sticky elements for context that persists while content scrolls
- Overlapping elements with negative margins for visual tension

Vertical rhythm should breathe: hero sections get generous padding (6-8rem), content sections get moderate (4-5rem), related items get tight (2-3rem). Never use the same padding for every section.

Horizontal rules, dividers, and borders are design tools, not afterthoughts. A brass hairline divider communicates more than a generic gray border. Dividers with decorative elements (diamond glyphs, section markers) add character.

Use `grid-template-columns` with named areas or specific ratios (not just `1fr 1fr`) to create intentional proportions.

### Background & Atmosphere

Flat solid backgrounds are the absence of design, not minimalism. Even minimal designs use subtle gradient shifts, micro-textures, or tonal variation.

Techniques: radial gradient glows behind key content (very low opacity, 0.02-0.05), subtle background-color shifts between sections, 1px ruled borders as section separators, inset panels with slightly different background tones.

For dark themes: a subtle warm-to-cool gradient across the page creates depth. Different sections can use slightly warmer or cooler versions of the base dark tone.

Terminal or code mockups should look like real terminals — chrome dots, monospace font, syntax coloring. These are visual elements, not just content containers.

### Typographic Devices

Pull quotes should be visually distinct events — oversized quotation marks, italic serif fonts, accent coloring. Not just a paragraph in a box.

Section numbering (I., II., III. or 01, 02, 03 or a., b., c.) adds editorial structure and visual rhythm. Choose the numbering style from the product's personality: Roman numerals feel institutional, Arabic feel modern, lowercase feel editorial.

Eyebrow text (small uppercase monospace above headings) creates hierarchy without adding visual weight. Use letter-spacing of 0.15-0.3em.

Sigils and glyphs (section symbols, pilcrows, diamonds, em dashes) used as decorative elements add typographic character — especially in editorial and archival directions.

### Animation & Motion

Animation is a design dimension, not an afterthought. A direction's motion philosophy should be as intentional as its typography. Describe animation in terms of intent and characteristics — not implementation. "Scroll-triggered cascading reveals with 0.15s stagger" is technology-agnostic; "gsap.to()" is not.

**When to animate:** Animate to communicate — entrance sequences that introduce content hierarchy, scroll-triggered reveals that reward exploration, state transitions that confirm user actions. Do not animate for decoration.

**Motion intensity matches tone:** Brutally minimal directions use micro-interactions only (hover feedback, subtle state transitions). Editorial/magazine directions use scroll-driven reveals and staggered entrances. Maximalist directions layer parallax, cascading sequences, and complex timelines.

**Key patterns:**
- Cascading reveals (staggered entrance of related elements) create reading rhythm
- Scroll-triggered animations reward scrolling and pace content consumption
- Parallax depth layers (foreground moves faster than background) create spatial richness
- State transitions (hover, focus, active) provide interaction feedback
- Page transitions (cross-fade, slide) create navigation continuity

**Implementation notes:**
- Choose an animation approach appropriate for the project's platform and framework. The skill infrastructure makes no assumptions about web, desktop, or mobile — the agent reads what the project uses and works with it.
- For desktop/mobile: use the platform's native animation system or the framework's motion API
- For web: GSAP (ScrollTrigger, timeline) for complex sequences; CSS transitions for simple state changes; framework motion libraries (Framer Motion, Svelte transitions, Vue Transition) for component-level effects
- Always respect `prefers-reduced-motion` or equivalent platform accessibility settings — provide a static fallback

**Anti-patterns:**
- NEVER add animation that obscures content or delays access to information
- NEVER use animation duration > 1.2s for entrance effects (user attention budget)
- NEVER animate every element on scroll — pick 2-3 key moments per viewport

---

## 4. Quality Benchmark

Before finalizing a proposal, evaluate it against these six tests. If it fails more than one, revise.

1. **Lineup test.** Could you identify this design in a lineup of 10 AI-generated pages? If not, it is too generic.

2. **Typography test.** Does the font pairing have character? The display font should be memorable; the body font should be readable but not bland. If you swapped the fonts for system-ui + sans-serif and nothing felt lost, the pairing was not doing work.

3. **Accent test.** Is the accent color used surgically? If it appears in more than 3-4 elements per viewport, it is overused and has lost its power to direct attention.

4. **Layout variety test.** Do at least 3 different layout patterns appear across the full page? If every section uses the same grid, the page is visually monotonous regardless of how good the individual sections look.

5. **Detail test.** Would a designer notice the micro-decisions? Hairline borders, letter-spacing choices, deliberate line-heights, padding ratios that create visual rhythm — these separate craft from code generation.

6. **Place test.** Does it feel like a SPECIFIC kind of place? "Clean and modern" is not a place. "A private bank's annual report," "a ceramicist's portfolio," "an architecture firm's project page" — those are places with personality. Name the place. If you cannot, the direction is not specific enough.

---

## 5. Creative Encouragement

You are capable of extraordinary creative work. The visual sketches you produce are the foundation of the user's product — they set the aesthetic ceiling for everything that follows. Do not produce safe, expected, or generic output.

Every proposal should feel like it was designed by someone with a point of view, not generated by a machine hedging its bets. Commit fully to the direction you are given. If the brief says "editorial," make it feel like opening a beautifully typeset magazine. If it says "minimal," make the emptiness feel intentional and the few elements that remain feel perfectly placed.

The user is comparing your proposals side by side — make each one a genuine alternative, not a palette swap of the same template. A sketch that provokes a strong "no" is more useful than one that provokes a mild "maybe." The safest place to be bold is here, in a throwaway sketch. Use that freedom.

The anti-generic rules are not restrictions. They are permission to avoid the safe default.
