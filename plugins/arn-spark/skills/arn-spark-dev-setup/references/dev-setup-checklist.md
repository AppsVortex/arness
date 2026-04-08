# Dev Setup Checklist

This checklist defines what a properly configured development environment should have. The `arn-spark-dev-setup` skill uses it to verify completeness after the `arn-spark-dev-env-builder` agent finishes (Define mode) or after a developer completes onboarding (Onboard mode). Items are environment-type-agnostic -- skip categories that do not apply.

## Verification Categories

### 1. Environment Configuration

- [ ] Environment type is defined (native, dev-container, docker, docker-compose, hybrid)
- [ ] Target platforms are documented (linux, macos, windows)
- [ ] CLAUDE.md has a `### Dev Environment` subsection in the `## Arness` section
- [ ] `dev-setup.md` document exists with complete setup instructions

### 2. Prerequisites Documentation

- [ ] Prerequisites are listed per platform with specific package names and versions
- [ ] Prerequisites distinguish between system packages and toolchain tools
- [ ] Installation commands are provided (not just package names)

### 3. Setup Scripts

- [ ] Setup script exists for the current platform (`scripts/setup.sh` or `scripts/setup.ps1`)
- [ ] Setup script is executable (has appropriate permissions)
- [ ] Setup script runs without errors on the current platform
- [ ] Setup script is idempotent (running it twice does not cause errors)
- [ ] Setup script reports what it installed and any manual steps needed

### 4. Build Verification

- [ ] Project builds successfully after environment setup
- [ ] Development server starts without errors (if applicable)
- [ ] Test suite runs (even if no tests exist yet)
- [ ] Linter runs without errors

### 5. Toolchain Pins (if applicable)

- [ ] Rust version pinned in `rust-toolchain.toml` (if using Rust)
- [ ] Node.js version pinned in `.nvmrc` or `.tool-versions` (if using Node)
- [ ] Pinned versions match what the setup script installs
- [ ] `package.json` engines field set (if using Node)

### 6. Container Configuration (if applicable)

- [ ] Dev container configuration exists (`.devcontainer/devcontainer.json`) if environment type is dev-container
- [ ] Dockerfile exists and builds without errors if environment type includes docker
- [ ] Docker Compose configuration is valid (`docker compose config` passes) if environment type is docker-compose
- [ ] Container includes all required system dependencies for the stack
- [ ] Container port forwarding is configured for dev server access

### 7. CI/CD Configuration (if applicable)

- [ ] CI workflow file exists (`.github/workflows/ci.yml` or `.gitlab-ci.yml`)
- [ ] CI workflow YAML is valid
- [ ] Platform matrix matches the target platforms
- [ ] CI installs the same system dependencies as the setup scripts
- [ ] CI runs build, lint, and test steps

### 8. Onboarding Documentation

- [ ] CONTRIBUTING.md exists with development setup section
- [ ] Setup instructions are copy-pasteable (commands, not prose)
- [ ] Quick start path exists (clone to running in 3-5 commands)
- [ ] Troubleshooting section addresses observed issues

## How to Use This Checklist

### In Define Mode

After the `arn-spark-dev-env-builder` agent reports completion:

1. Walk through each applicable category based on the environment type chosen
2. Skip categories that do not apply (e.g., skip "Container Configuration" for a native-only setup)
3. For each failed check, note it as an issue in the results summary
4. Critical failures (setup script errors, build broken) should be addressed before proceeding
5. Non-critical gaps (missing troubleshooting entry, no IDE config) can be noted for the user to address later

### In Onboard Mode

After the developer completes the setup steps:

1. Focus on categories 3 (Setup Scripts) and 4 (Build Verification)
2. Verify the project builds and runs in the developer's actual environment
3. Note any issues encountered for potential addition to the troubleshooting section
4. If the developer deviated from the standard, ensure their setup still passes Build Verification
