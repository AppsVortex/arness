---
name: arn-infra-containerize
description: >-
  This skill should be used when the user says "containerize", "dockerize",
  "create dockerfile", "docker setup", "container setup", "arn infra containerize",
  "infra containerize", "generate docker", "docker compose", "compose setup",
  "containerize my app", "docker configuration", "create docker-compose",
  "multi-stage docker", "container config", "dockerize my application",
  "infra docker", "set up containers", or wants to generate Dockerfiles,
  docker-compose configurations, and .dockerignore files for their application
  with security auditing and multi-stage build best practices.
version: 1.0.0
---

# Arness Infra Containerize

Generate production-ready Dockerfiles, docker-compose configurations, and .dockerignore files for the application. This skill produces security-audited, multi-stage container configurations adapted to the application's technology stack and topology.

This skill reads the application context (codebase patterns, architecture, technology stack) based on the project topology, invokes the `arn-infra-specialist` agent for container configuration generation, and the `arn-infra-security-auditor` agent for security review. All generated files are presented for user approval before being written.

## Prerequisites

Read `## Arness` from the project's CLAUDE.md. If no `## Arness` section exists or Arness Infra fields are missing, inform the user: "Arness Infra is not configured for this project yet. Run `/arn-infra-wizard` to get started — it will set everything up automatically." Do not proceed without it.

Check the **Deferred** field. If `Deferred: yes`, inform the user: "Infrastructure is in deferred mode. Containerization is not available until infrastructure is fully configured. Run `/arn-infra-assess` to un-defer." Stop.

Extract:
- **Project topology** -- how to resolve the application project (monorepo, separate-repo, infra-only)
- **Application path** -- path to the application project root
- **Experience level** -- derived from user profile. Read `~/.arness/user-profile.yaml` (or `.claude/arness-profile.local.md` if it exists — project override takes precedence). Apply the experience derivation mapping from `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-ensure-config/references/experience-derivation.md`. If no profile exists, check for legacy `Experience level` in `## Arness` as fallback.
- **Providers** -- informs container registry selection and platform-specific optimizations
- **Tooling manifest** -- path to check for Docker/container tools availability

## Workflow

### Step 1: Resolve Application Context

Resolve the application project based on topology to understand the technology stack, services, and dependencies.

**Monorepo (`Application path: .`):**
- Read codebase patterns from the local code-patterns directory (path from `## Arness` config)
- Read `architecture.md` for technology stack, services, and dependencies
- Scan the source tree for: `package.json`, `requirements.txt`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `pom.xml`, `*.csproj`, `Gemfile`
- Identify application entry points, build commands, and runtime requirements

**Separate repo:**
- Navigate to `Application path`
- Read the application's `## Arness` config, code patterns, and architecture
- Scan for the same dependency/entry point files
- If the path is unreachable, inform the user and ask them to describe the application stack manually

**Infra-only:**
- No application to analyze directly
- Ask the user to describe: language/framework, services (web, API, workers), databases, build commands, runtime requirements
- Proceed with user-provided context

---

### Step 2: Check Existing Container Configurations

Scan for existing container files:
- `Dockerfile`, `Dockerfile.*`, `*.Dockerfile`
- `docker-compose.yml`, `docker-compose.yaml`, `compose.yml`, `compose.yaml`, `docker-compose.*.yml`
- `.dockerignore`

**If existing files found:**
Present findings: "I found existing container configurations: [list files]."

Ask (using `AskUserQuestion`):

**"What would you like to do with existing container configurations?"**

Options:
1. **Replace** -- Generate new configurations (existing files will be overwritten after your approval)
2. **Augment** -- Keep existing files and add missing configurations
3. **Review only** -- Run a security audit on the existing files without generating new ones

**If the user chooses Review only:** Skip to Step 5 (security audit) with existing files.

**If no existing files found:** Continue to Step 3.

---

### Step 3: Determine Container Strategy

Based on the application analysis from Step 1, determine what container files are needed.

**Single-service applications:**
- Generate: `Dockerfile`, `.dockerignore`
- Optionally generate `docker-compose.yml` if the app depends on external services (database, cache, queue)

**Multi-service applications:**
- Generate: one `Dockerfile` per service (or `Dockerfile.<service>`)
- Generate: `docker-compose.yml` with all services
- Generate: `.dockerignore`

Ask the user to confirm the container strategy:

"Based on your application, I plan to generate:
- [list of files to generate]
- Multi-stage builds for [production optimization / smaller images]
- [Development docker-compose with hot reload / Production-only compose]

Does this look right, or would you like to adjust?"

---

### Step 4: Invoke Specialist Agent for Generation

Load the appropriate reference files based on the detected technology stack:

> Read the local override or plugin default for `dockerfile-patterns.md`.

If multi-service or compose is needed:

> Read the local override or plugin default for `compose-patterns.md`.

Invoke the `arn-infra-specialist` agent via the Task tool with:

--- APPLICATION CONTEXT ---
Technology stack: [language, framework, runtime version]
Services: [list of services with roles]
Build commands: [build steps for each service]
Entry points: [start commands for each service]
Dependencies: [external services -- databases, caches, queues]
Environment variables: [required env vars, without values]
Ports: [exposed ports per service]
--- END APPLICATION CONTEXT ---

--- CONTAINER PATTERNS ---
[content from dockerfile-patterns.md, filtered to relevant language(s)]
[content from compose-patterns.md, if multi-service]
--- END CONTAINER PATTERNS ---

--- INFRASTRUCTURE CONFIG ---
Experience level: [derived from user profile]
Providers: [from ## Arness -- for registry and platform hints]
--- END INFRASTRUCTURE CONFIG ---

--- INSTRUCTIONS ---
Generate container configurations for the application.
For each Dockerfile:
- Use multi-stage builds (builder stage + production stage)
- Pin base image versions (no :latest tags)
- Run as non-root user in the production stage
- Order layers for optimal cache utilization (dependencies before source code)
- Include health check instructions
- Minimize image size (use alpine/slim/distroless where appropriate)
For docker-compose.yml (if multi-service):
- Define all services with proper dependency ordering
- Use named volumes for persistent data
- Configure networks for service isolation
- Include health checks for dependent services
- Add environment variable placeholders (never hardcode secrets)
For .dockerignore:
- Exclude version control, IDE files, test directories, documentation
- Exclude secrets files (.env, *.pem, *.key)
- Exclude build artifacts and node_modules / venv / target directories
Adapt comment verbosity to the experience level.
--- END INSTRUCTIONS ---

---

### Step 5: Security Audit

Load the security checklist:

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-containerize/references/container-security-checklist.md` for container security requirements.

Invoke the `arn-infra-security-auditor` agent via the Task tool with:

--- FILES TO AUDIT ---
[generated Dockerfile content(s)]
[generated docker-compose.yml content, if any]
[generated .dockerignore content]
--- END FILES TO AUDIT ---

--- SECURITY CHECKLIST ---
[content from container-security-checklist.md]
--- END SECURITY CHECKLIST ---

--- INSTRUCTIONS ---
Review the generated container configurations against the security checklist.
Check for:
- Running as root user
- Unpinned base image versions
- Secrets in build args, environment variables, or layers
- Missing health checks
- Unnecessary packages or tools in production stage
- Exposed ports that should not be public
- Missing .dockerignore entries for sensitive files
Produce a security audit report with categorized findings.
--- END INSTRUCTIONS ---

**If critical or high findings are returned:**
Apply the security auditor's recommendations to the generated files automatically. Present the changes to the user: "The security audit found [N] issues. I have applied the following fixes: [list fixes]. Review the updated files below."

**If only medium or low findings:**
Present the findings as advisory notes alongside the generated files.

---

### Step 6: Present Generated Files for Approval

Present each generated file to the user with syntax highlighting:

"Here are the generated container configurations:

**Dockerfile** (or **Dockerfile.[service]** for each service):
```dockerfile
[generated content]
```

**docker-compose.yml** (if generated):
```yaml
[generated content]
```

**.dockerignore:**
```
[generated content]
```

**Security audit results:** [summary of findings]

Ask (using `AskUserQuestion`):

**"How would you like to proceed with the generated files?"**

Options:
1. **Approve and write** -- Write all files to the project
2. **Edit** -- Make changes before writing
3. **Regenerate** -- Adjust the configuration and regenerate

---

### Step 7: Write Files and Summarize

Upon user approval, write each generated file to the appropriate location:
- For monorepo: write to the project root (or to each service directory for multi-service)
- For separate-repo: write to the `Application path`
- For infra-only: write to the current project root

Present the summary:

**Containerization Summary:**
- **Files created:** [list with paths]
- **Base images used:** [list with pinned versions]
- **Security audit:** [passed / N findings addressed]
- **Multi-stage builds:** [yes / no]
- **Services containerized:** [count]

**Recommended next steps:**

"Container configurations are ready. Here is the recommended path:

1. **Test locally:** Run `docker compose up` (or `docker build .`) to verify the configurations work
2. **Define infrastructure:** Run `/arn-infra-define` to generate IaC for deploying these containers
3. **Set up CI/CD:** Run `/arn-infra-pipeline` to generate a CI/CD pipeline with container builds

Or run `/arn-infra-wizard` for the full guided pipeline."

---

## Error Handling

- **`## Arness` config missing:** Suggest running `/arn-infra-wizard` to get started. Stop.
- **Application path unreachable (separate-repo):** Ask the user to describe the application stack manually. Continue with user-provided context.
- **Specialist agent fails:** Report the error. Fall back to generating basic container configurations directly using the loaded reference patterns, without the agent. Present them with a note: "Generated using fallback patterns -- review carefully before use."
- **Specialist agent returns empty output:** Inform the user and ask for more details about the application stack. Retry with the additional context.
- **Security auditor fails:** Present the generated files without the security audit. Warn: "Security audit could not be performed. Review the generated files manually for: non-root user, pinned base images, no secrets in layers, health checks, and minimal production images before deploying."
- **Security auditor returns critical findings that cannot be auto-fixed:** Present the findings and ask the user to resolve them manually before proceeding. Do not write files with unresolved critical findings.
- **Docker not installed:** Warn: "Docker is not detected. The generated configurations are still valid but cannot be tested locally until Docker is installed." Continue generating.
- **Unsupported language/framework:** If the application uses a language not covered in the patterns reference, generate a generic Dockerfile with comments explaining where to customize. Note the limitation.
- **Re-running is safe:** Re-running overwrites existing generated files (after user approval). Existing custom configurations are not touched unless the user explicitly chooses Replace.
