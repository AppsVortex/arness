# Scaffold Checklist

This checklist defines what a properly scaffolded project should have. The `arn-spark-scaffold` skill uses it to verify completeness after the `arn-spark-scaffolder` agent finishes. Items are framework-agnostic -- adapt specifics to the chosen stack.

## Verification Categories

### 1. Project Structure

- [ ] Root directory exists with the project name or at the specified path
- [ ] `src/` directory (or framework equivalent) exists for application source code
- [ ] Entry point file exists (e.g., `src/main.ts`, `src/App.svelte`, `src/index.tsx`)
- [ ] Static assets directory exists if applicable (e.g., `public/`, `static/`)
- [ ] Test directory exists (e.g., `tests/`, `test/`, `__tests__/`)

### 2. Dependency Management

- [ ] Package manifest exists (e.g., `package.json`, `Cargo.toml`)
- [ ] Lock file exists (e.g., `package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, `Cargo.lock`)
- [ ] Core framework dependencies are installed (not just listed)
- [ ] Development dependencies are installed (linter, formatter, test framework)
- [ ] No missing peer dependencies (check install output for warnings)

### 3. Build Configuration

- [ ] Build tool configuration exists (e.g., `vite.config.ts`, `webpack.config.js`, `tauri.conf.json`)
- [ ] TypeScript configuration exists if using TypeScript (`tsconfig.json`)
- [ ] Build command runs without errors
- [ ] Development server starts without errors (if applicable)

### 4. Linting and Formatting

- [ ] Linter configuration exists (e.g., `eslint.config.js`, `.eslintrc`, `biome.json`)
- [ ] Formatter configuration exists (e.g., `.prettierrc`, integrated in biome/eslint)
- [ ] Linter runs on the minimal source code without errors
- [ ] Formatter runs without errors

### 5. Testing Framework

- [ ] Test framework is installed and configured
- [ ] Test command is defined in package scripts or is runnable
- [ ] A sample or smoke test can be executed (even if there are no real tests yet)
- [ ] Test configuration exists if needed (e.g., `vitest.config.ts`, `jest.config.js`)

### 6. UI Toolkit (if applicable)

- [ ] CSS framework is installed and configured (e.g., Tailwind CSS with `tailwind.config.js`)
- [ ] CSS framework directives are included in the global stylesheet (e.g., `@tailwind base;`)
- [ ] PostCSS is configured if required by the CSS framework
- [ ] Component library is installed and initialized (e.g., shadcn-svelte, Skeleton UI)
- [ ] Component library theme or base configuration is in place
- [ ] A component library component renders correctly in the minimal entry point

### 7. Git Configuration

- [ ] `.gitignore` exists with appropriate entries for the stack (node_modules, dist, build artifacts, OS files)
- [ ] No sensitive files or large binaries are unignored

### 8. Minimal Entry Point

- [ ] Application renders something visible (text, a component, a styled element)
- [ ] Entry point uses the UI framework (not just raw HTML)
- [ ] If a component library is installed, at least one component is used to verify integration
- [ ] The entry point is intentionally minimal -- no features beyond proving the stack works

### 9. Run Instructions

- [ ] Development server command is clear (e.g., `npm run dev`, `cargo tauri dev`)
- [ ] Build command is clear (e.g., `npm run build`, `cargo tauri build`)
- [ ] Test command is clear (e.g., `npm test`, `npx vitest`)

## How to Use This Checklist

The `arn-spark-scaffold` skill should:

1. After the `arn-spark-scaffolder` agent reports completion, walk through each applicable category
2. Skip categories that do not apply to the chosen stack (e.g., skip "UI Toolkit" for a CLI project)
3. For each failed check, note it as an issue in the scaffold summary
4. Critical failures (build does not pass, dependencies not installed) should be addressed before proceeding
5. Non-critical gaps (missing .gitignore entry, no sample test) can be noted for the user to address later
