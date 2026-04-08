# Paradigm: Web

Web-specific detection, artifact structure, preview mechanism, and promotion rules for the arn-code-sketch skill. This file is loaded by the sketch-setup paradigm router when the sketch strategy paradigm is `web`.

## Sketch Strategy Values (Web)

When `ui-patterns.md` declares paradigm `web`, the sketch strategy typically includes:

| Field | Typical Values |
|-------|---------------|
| Paradigm | `web` |
| Artifact structure | Framework-specific route files in `arness-sketches/[feature-name]/` |
| Preview mechanism | Browser URL: `http://localhost:[port]/arness-sketches/[feature-name]` |
| Promotion rules | Copy sketch files to real route location, update imports |

---

## Framework Detection Sequence

Detect the web framework by reading the project's `package.json` and checking for known framework indicators. Check in this order (first match wins):

### 1. Next.js

**Detection:** `package.json` contains `"next"` in `dependencies` or `devDependencies`.

**App Router vs Pages Router:**
- **App Router:** An `app/` directory exists at the project root (or within `src/`) containing `layout.tsx` or `page.tsx` files. This is the default for Next.js 13+.
- **Pages Router:** A `pages/` directory exists at the project root (or within `src/`) containing page files. No `app/` directory is present with layout/page files.
- **Both present:** If both `app/` and `pages/` directories exist with content, prefer App Router as the primary routing mechanism (Next.js recommendation). Note the hybrid setup in the manifest.

**App Router conventions:**
- Route segments are directories under `app/`
- Entry point: `page.tsx` (or `.jsx`, `.js`)
- Layouts: `layout.tsx` wraps child pages
- Route groups: `(group-name)/` directories for organization
- Sketch namespace: `app/arness-sketches/[feature-name]/page.tsx`

**Pages Router conventions:**
- Route segments are files under `pages/`
- Entry point: `index.tsx` (or named file matching the route)
- Layouts: `_app.tsx` and custom layout components
- Sketch namespace: `pages/arness-sketches/[feature-name]/index.tsx`

### 2. SvelteKit

**Detection:** `package.json` contains `"@sveltejs/kit"` in `dependencies` or `devDependencies`.

**Conventions:**
- Route segments are directories under `src/routes/`
- Entry point: `+page.svelte`
- Layouts: `+layout.svelte` wraps child pages
- Load functions: `+page.ts` or `+page.server.ts`
- Sketch namespace: `src/routes/arness-sketches/[feature-name]/+page.svelte`

### 3. Nuxt

**Detection:** `package.json` contains `"nuxt"` in `dependencies` or `devDependencies`.

**Nuxt version detection:**
- **Nuxt 3:** `package.json` has `"nuxt": "^3.x.x"` or `nuxt.config.ts` exists (TypeScript config)
- **Nuxt 2:** `package.json` has `"nuxt": "^2.x.x"` or `nuxt.config.js` exists (no `.ts` variant)

**Nuxt 3 conventions:**
- Route segments are files/directories under `pages/`
- Entry point: `[feature-name].vue` or `pages/[feature-name]/index.vue`
- Layouts: `layouts/default.vue`
- Auto-imports for composables and components
- Sketch namespace: `pages/arness-sketches/[feature-name].vue` or `pages/arness-sketches/[feature-name]/index.vue`

**Nuxt 2 conventions:**
- Same directory structure as Nuxt 3 but uses Options API by default
- Layouts: `layouts/default.vue`
- Requires explicit imports (no auto-imports)
- Sketch namespace: same as Nuxt 3

### 4. React Router (standalone React)

**Detection:** `package.json` contains `"react-router-dom"` or `"react-router"` in `dependencies`. No `"next"` detected.

**Conventions:**
- Config-based routing: routes defined in a router config file (commonly `src/router.tsx`, `src/routes.tsx`, `src/App.tsx`, or similar)
- Entry point: named component file (e.g., `SketchFeatureName.tsx`)
- No filesystem-based routing -- sketch files go in `src/arness-sketches/[feature-name]/`
- A route entry must be added to the router config pointing to the sketch component

**Route config entry (temporary):**
```tsx
// Add to the router config during sketch creation:
{ path: "/arness-sketches/[feature-name]", element: <SketchFeatureName /> }
```

Remove this entry during promotion or cleanup.

### 5. Vue Router (standalone Vue)

**Detection:** `package.json` contains `"vue-router"` in `dependencies`. No `"nuxt"` detected.

**Conventions:**
- Config-based routing: routes defined in `src/router/index.ts` or similar
- Entry point: named component file (e.g., `SketchFeatureName.vue`)
- Sketch files go in `src/arness-sketches/[feature-name]/`
- A route entry must be added to the router config

**Route config entry (temporary):**
```ts
// Add to the router config during sketch creation:
{ path: '/arness-sketches/[feature-name]', component: () => import('@/arness-sketches/[feature-name]/SketchFeatureName.vue') }
```

Remove this entry during promotion or cleanup.

### 6. Fallback (generic SPA or static site)

If none of the above frameworks are detected but the project has `"react"`, `"vue"`, `"svelte"`, or `"angular"` in its dependencies, it is a generic SPA without standard routing. Create sketch files in `arness-sketches/[feature-name]/` at the project root and instruct the user how to import/render the sketch component manually.

---

## Component Library Detection

After framework detection, identify the project's component library by checking `package.json` dependencies:

| Package Name | Library | Import Pattern |
|-------------|---------|----------------|
| `@mui/material` | Material UI (MUI) | `import { Button } from '@mui/material'` |
| `@chakra-ui/react` | Chakra UI | `import { Button } from '@chakra-ui/react'` |
| `@radix-ui/*` | Radix UI | `import * as Dialog from '@radix-ui/react-dialog'` |
| `@headlessui/react` | Headless UI (React) | `import { Dialog } from '@headlessui/react'` |
| `@headlessui/vue` | Headless UI (Vue) | `import { Dialog } from '@headlessui/vue'` |
| `@mantine/core` | Mantine | `import { Button } from '@mantine/core'` |
| `antd` | Ant Design | `import { Button } from 'antd'` |
| `primereact` | PrimeReact | `import { Button } from 'primereact/button'` |
| `primevue` | PrimeVue | `import Button from 'primevue/button'` |
| `flowbite-react` | Flowbite React | `import { Button } from 'flowbite-react'` |
| `daisyui` | DaisyUI (Tailwind plugin) | CSS classes: `class="btn btn-primary"` |
| `@shadcn/ui` or local `components/ui/` | shadcn/ui | `import { Button } from '@/components/ui/button'` |

**shadcn/ui special case:** shadcn/ui is not installed as a package -- it copies components into the project. Detect by checking for a `components/ui/` directory with files like `button.tsx`, `card.tsx`, `dialog.tsx`. Also check for a `components.json` config file at the project root.

If no known library is detected, check the project's existing components to understand what primitives are used. The sketch should compose from the same primitives.

For projects with multiple component libraries (uncommon but possible), prefer the one used most frequently in existing page components.

---

## Styling Approach Detection

Identify the project's styling approach by checking configuration files and existing component patterns:

| Indicator | Approach | How to Detect |
|-----------|----------|---------------|
| `tailwind.config.*` exists | Tailwind CSS | Config file at project root; class-based styling in components |
| `.module.css` files exist | CSS Modules | Files alongside components; `import styles from './Component.module.css'` |
| `styled-components` in deps | styled-components | `import styled from 'styled-components'` in component files |
| `@emotion/styled` in deps | Emotion | `import styled from '@emotion/styled'` or `css` prop usage |
| `.scss`/`.sass` files exist | Sass/SCSS | Preprocessor files; check for `sass` or `node-sass` in deps |
| `style` objects in JSX | Inline styles | `style={{ color: 'red' }}` pattern in components |
| `vanilla-extract` in deps | Vanilla Extract | `.css.ts` files; `import { style } from '@vanilla-extract/css'` |

**Multiple approaches:** Some projects combine approaches (e.g., Tailwind for utility classes + CSS Modules for custom styles). Read 3-5 existing components to determine the primary approach. The sketch should use the same combination.

**Tailwind configuration:** If Tailwind is detected, read `tailwind.config.*` to extract:
- Custom color tokens (used instead of default Tailwind colors)
- Custom spacing values
- Custom breakpoints
- Plugin configurations (forms, typography, aspect-ratio)
- Content paths (to understand which file patterns are scanned)

---

## Route Namespace Creation

Based on the detected framework, create the sketch route namespace:

### Next.js App Router

```
app/
  arness-sketches/
    [feature-name]/
      page.tsx              # Default export: sketch page component
      components/           # (optional) sketch-specific components
      sketch-manifest.json
```

No additional configuration needed -- Next.js App Router auto-discovers routes from the filesystem.

### Next.js Pages Router

```
pages/
  arness-sketches/
    [feature-name]/
      index.tsx             # Default export: sketch page component
      components/           # (optional) sketch-specific components
      sketch-manifest.json
```

No additional configuration needed -- Next.js Pages Router auto-discovers routes from the filesystem.

### SvelteKit

```
src/routes/
  arness-sketches/
    [feature-name]/
      +page.svelte          # Sketch page component
      components/           # (optional) sketch-specific components
      sketch-manifest.json
```

No additional configuration needed -- SvelteKit auto-discovers routes from the filesystem. If load functions are needed for data, create `+page.ts` alongside the page.

### Nuxt (2 and 3)

```
pages/
  arness-sketches/
    [feature-name].vue      # Sketch page component (single-file)
    OR
    [feature-name]/
      index.vue             # Sketch page component (directory style)
      components/           # (optional) sketch-specific components
      sketch-manifest.json
```

Prefer the single-file approach for simple sketches and the directory approach when sketch-specific components are needed.

### React Router

```
src/
  arness-sketches/
    [feature-name]/
      SketchFeatureName.tsx  # Named component (not page.tsx)
      components/            # (optional) sketch-specific components
      sketch-manifest.json
```

**Additional step required:** Add a temporary route entry to the project's router config file. The builder agent must:
1. Read the router config file (detect its location by searching for `createBrowserRouter`, `<Routes>`, or `<Route>` usage)
2. Add a route entry for `/arness-sketches/[feature-name]` pointing to the sketch component
3. Record the router config file path in the manifest for cleanup

### Vue Router

```
src/
  arness-sketches/
    [feature-name]/
      SketchFeatureName.vue  # Named component
      components/            # (optional) sketch-specific components
      sketch-manifest.json
```

**Additional step required:** Add a temporary route entry to the project's router config file. The builder agent must:
1. Read the router config file (typically `src/router/index.ts` or `src/router.ts`)
2. Add a route entry for `/arness-sketches/[feature-name]` pointing to the sketch component
3. Record the router config file path in the manifest for cleanup

---

## Web-Specific Iteration Notes

During iteration, the user reviews the sketch in their browser and describes visual changes. Web-specific feedback patterns include:

- **Responsive layout:** "Make it work on mobile" -- builder adds responsive breakpoints using the project's responsive pattern
- **Dark mode:** "Support dark mode" -- builder adds dark mode variants if the project has a dark mode theme
- **Animations:** "Add a transition when the panel opens" -- builder uses the project's animation approach (CSS transitions, Framer Motion, Svelte transitions, Vue transitions)
- **Loading states:** "Show a skeleton while loading" -- builder adds loading UI using the project's loading pattern

## Web-Specific Promotion Notes

When promoting a web sketch:

1. **Filesystem-based routing** (Next.js, SvelteKit, Nuxt): Move files from `arness-sketches/[feature-name]/` to the target route directory. The route becomes active automatically.
2. **Config-based routing** (React Router, Vue Router): Move files, add the real route entry, remove the sketch route entry.
3. **Import paths:** All `arness-sketches/` references in import statements must be rewritten to the promoted location. Check both the promoted files and any files that imported from the sketch directory.
4. **Layout integration:** If the target page has a different layout context than the sketch, the promoted code may need layout adjustments. Flag this to the user.

---

## Web-Specific Threshold Rules

These thresholds determine when a web change is complex enough to warrant sketching:

**Below threshold (implement directly):**
- Adding a single component to an existing page (button, badge, tooltip)
- Style-only changes (colors, spacing, font sizes)
- Text content updates
- Icon changes
- Adding a single form field to an existing form
- Swapping one component for a compatible alternative

**Above threshold (offer sketch):**
- New page or route
- New form with 3 or more fields
- New page section or panel (hero, feature grid, pricing table)
- Layout restructuring (adding/removing sidebar, changing navigation)
- Dashboard with multiple data widgets
- Multi-step wizard or flow
- Complex data table with sorting, filtering, pagination
- Modal or dialog with significant content
- Features where the user has expressed uncertainty about the visual design
