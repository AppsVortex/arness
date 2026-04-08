# Greenfield Project Questions

Questions to gather context for a new project before generating recommended patterns and architecture.

## Required Questions

These must always be asked:

### 1. Project Type
**Ask:** "Is this a backend, frontend, or fullstack project?"
**Options:** Backend, Frontend, Fullstack
**Why:** Determines which pattern categories apply (API/routing for backend, component patterns for frontend, both for fullstack).

### 2. Language
**Ask:** "What programming language will this project use?"
**Examples:** Python, TypeScript, Go, Rust, Java, Ruby, C#
**Why:** Drives framework suggestions, testing tools, and code style conventions.

### 3. Framework
**Ask:** "What framework would you like to use?" (suggest popular options based on language and project type)
**Suggestions by stack:**
- Python backend: FastAPI, Django, Flask
- Python fullstack: Django
- TypeScript backend: Express, Fastify, NestJS, Hono
- TypeScript frontend: React, Next.js, Vue, Svelte, Angular
- TypeScript fullstack: Next.js, Nuxt, SvelteKit, Remix
- Go backend: Gin, Echo, Chi, standard library
- Rust backend: Actix, Axum, Rocket
- Java backend: Spring Boot, Quarkus, Micronaut
- Ruby backend: Rails, Sinatra
**Why:** Framework choice drives the majority of code patterns, project structure, and conventions.

### 4. Testing Approach
**Ask:** "What testing framework would you like to use?" (suggest default based on language)
**Defaults:**
- Python → pytest
- TypeScript → Jest or Vitest
- Go → go test (built-in)
- Rust → cargo test (built-in)
- Java → JUnit 5
- Ruby → RSpec or Minitest
**Why:** Determines testing patterns, fixtures, markers, and test organization.

## Contextual Questions

Ask these based on the answers above — skip if not applicable:

### 5. Database (if backend or fullstack)
**Ask:** "Will this project use a database? If so, what kind?"
**Options:** PostgreSQL, MySQL, SQLite, MongoDB, Redis, DynamoDB, None
**Why:** Determines data layer patterns, ORM/ODM choice, migration strategy.

### 6. API Style (if backend or fullstack)
**Ask:** "What API style will you use?"
**Options:** REST, GraphQL, gRPC, WebSocket, Not applicable
**Why:** Determines routing patterns, serialization, and request/response conventions.

### 7. Package Manager
**Ask:** "Do you have a preference for package manager?" (suggest default based on language)
**Defaults:**
- Python → uv (or pip/poetry)
- TypeScript → npm (or pnpm/yarn/bun)
- Go → go modules (built-in)
- Rust → cargo (built-in)
- Java → Maven or Gradle
- Ruby → Bundler
**Why:** Affects dependency management patterns and project setup.

### 8. Project Layout
**Ask:** "What project layout do you prefer?"
**Options:**
- src layout (source in `src/` subdirectory)
- Flat layout (source at project root)
- Monorepo (multiple packages in one repo)
**Defaults:** Python → src layout, TypeScript → src layout, Go → flat
**Why:** Determines directory structure and import conventions.

### 9. Authentication (if backend or fullstack)
**Ask:** "Will this project need authentication? If so, what approach?"
**Options:** JWT, Session-based, OAuth2/OIDC, API keys, None yet
**Why:** Affects middleware patterns, user model design, and security configuration.

### 10. Additional Tooling
**Ask:** "Any preferences for linting, formatting, or CI?"
**Common choices:**
- Python: ruff, black, mypy, GitHub Actions
- TypeScript: ESLint, Prettier, GitHub Actions
- Go: golangci-lint, gofmt (built-in)
- Rust: clippy, rustfmt (built-in)
**Why:** Influences configuration patterns and development workflow.

### 11. UI Component Library (if frontend or fullstack)
**Ask:** "What UI component library would you like to use?" (suggest popular options based on framework)
**Suggestions by framework:**
- React: shadcn/ui, Material UI, Ant Design, Chakra UI, Radix
- Next.js: shadcn/ui, Material UI, Mantine
- Vue: Vuetify, PrimeVue, Naive UI, Element Plus
- Svelte: Skeleton, Flowbite Svelte, DaisyUI
- Angular: Angular Material, PrimeNG, Ng-Zorro
- None (custom components from scratch)
**Why:** Determines component patterns, import conventions, and styling integration.

### 12. Styling Approach (if frontend or fullstack)
**Ask:** "What styling approach would you like to use?"
**Options:**
- Tailwind CSS (utility-first)
- CSS Modules (scoped styles)
- styled-components / Emotion (CSS-in-JS)
- Sass/SCSS (preprocessor)
- Vanilla CSS
- Framework default (if component library includes styling)
**Why:** Affects layout patterns, theming strategy, and component styling conventions.

### 13. Accessibility Requirements (if frontend or fullstack)
**Ask:** "What level of accessibility compliance do you need?"
**Options:**
- WCAG 2.1 AA (recommended default — covers most legal and usability requirements)
- WCAG 2.1 AAA (highest standard — complex content, government, healthcare)
- Basic (semantic HTML, keyboard navigation, alt text — no formal compliance target)
- None yet (defer decision)
**Why:** Determines accessibility patterns, testing requirements, and component constraints.
