# Container Security Checklist

Security requirements for production container configurations. Each item is categorized by severity (Critical, High, Medium, Low) and applies to Dockerfiles, docker-compose files, and .dockerignore files.

---

## Critical

### C1: No Secrets in Image Layers

**Requirement:** Credentials, API keys, tokens, passwords, and private keys must NEVER appear in Dockerfiles or be embedded in image layers.

**What to check:**
- No `ENV` directives with real secret values
- No `COPY` of `.env`, `*.pem`, `*.key`, `*.p12`, `credentials.json`, or similar files
- No `ARG` used to pass secrets during build (they persist in image history)
- No `RUN curl` or `RUN wget` with embedded tokens or auth headers
- No inline passwords in `RUN` commands (e.g., database connection strings)

**Remediation:**
- Use runtime environment variables (set at container start, not build time)
- Use Docker BuildKit secrets: `RUN --mount=type=secret,id=mysecret`
- Use multi-stage builds to ensure secret-bearing stages are not in the final image

### C2: Non-Root User

**Requirement:** The production container must run as a non-root user.

**What to check:**
- A `USER` directive exists after all `COPY` and `RUN` commands in the production stage
- The user is not `root` (UID 0)
- A dedicated application user is created with `adduser` / `useradd`
- File ownership is set correctly with `chown` before the `USER` directive

**Remediation:**
```dockerfile
RUN addgroup -g 1001 -S appgroup && adduser -S appuser -u 1001 -G appgroup
# ... copy application files ...
RUN chown -R appuser:appgroup /app
USER appuser
```

### C3: No Privileged Mode

**Requirement:** Containers must NOT run in privileged mode in docker-compose.

**What to check:**
- No `privileged: true` in any service definition
- No `cap_add: ALL` or equivalent blanket capability grants
- If capabilities are needed, only the minimum required are added (e.g., `NET_BIND_SERVICE`)

**Remediation:**
- Remove `privileged: true`
- Use specific capabilities: `cap_add: [NET_BIND_SERVICE]` with `cap_drop: [ALL]`

---

## High

### H1: Pinned Base Image Versions

**Requirement:** All base images must use pinned version tags. Never use `:latest` or untagged images.

**What to check:**
- Every `FROM` line specifies a version tag (e.g., `node:22-alpine`, not `node:latest` or `node`)
- Tags include the minor version at minimum (e.g., `python:3.12-slim`, not `python:3`)
- For maximum reproducibility, use digest pinning: `FROM node:22-alpine@sha256:abc123...`

**Remediation:**
```dockerfile
# Bad
FROM node
FROM python:latest

# Good
FROM node:22-alpine
FROM python:3.12-slim
```

### H2: Minimal Base Images

**Requirement:** Use the smallest appropriate base image for the production stage.

**What to check:**
- Production stage uses Alpine, slim, or distroless variants
- Build tools, compilers, and dev dependencies are NOT in the production image
- Package managers (apt, apk) are not used in the production stage (only in builder)

**Base image hierarchy (smallest to largest):**
1. `scratch` -- empty (Go, Rust static binaries)
2. `distroless` -- no shell, no package manager
3. Alpine variants -- small Linux with musl libc (~5MB base)
4. Slim variants -- Debian with minimal packages (~80MB base)
5. Full variants -- complete OS (avoid for production)

### H3: No Unnecessary Packages

**Requirement:** Production images should only contain what is needed to run the application.

**What to check:**
- No `apt-get install` or `apk add` in the production stage (only in builder)
- If system packages are needed in production, install only the specific ones required
- Use `--no-install-recommends` with `apt-get`
- Clean up package caches in the same layer: `&& rm -rf /var/lib/apt/lists/*`
- No `curl`, `wget`, `vim`, `ssh`, or debug tools in production (unless needed for health checks)

### H4: Docker-Compose Secrets Handling

**Requirement:** docker-compose files must not contain inline secrets.

**What to check:**
- Environment values use `${VARIABLE}` references, not literal values
- No hardcoded passwords, tokens, or connection strings
- A `.env.example` documents required variables without real values
- The `.env` file is in `.gitignore` and `.dockerignore`

**Remediation:**
```yaml
# Bad
environment:
  DB_PASSWORD: my_secret_password

# Good
environment:
  DB_PASSWORD: ${DB_PASSWORD}
```

---

## Medium

### M1: Health Check Defined

**Requirement:** Every service should define a health check for proper orchestration and monitoring.

**What to check:**
- `HEALTHCHECK` directive in Dockerfile or `healthcheck` in docker-compose
- Health check tests a meaningful endpoint (not just process existence)
- `start_period` is set to allow for application startup time
- `interval`, `timeout`, and `retries` are configured

**Recommended defaults:**
```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:PORT/health || exit 1
```

### M2: Layer Cache Optimization

**Requirement:** Dockerfile layers should be ordered for optimal caching.

**What to check:**
- Dependency manifests (`package.json`, `requirements.txt`, `go.mod`) are copied before source code
- Dependency installation runs before source code copy
- Infrequently changing layers come before frequently changing ones
- Multi-stage builds separate the build environment from the runtime

### M3: Exposed Ports Audit

**Requirement:** Only necessary ports should be exposed.

**What to check:**
- `EXPOSE` directives match the application's actual listening ports
- No debug ports (9229, 5005, 5858) exposed in production Dockerfiles
- docker-compose only publishes ports that need external access
- Database and cache ports are NOT published in production compose files

### M4: Read-Only Root Filesystem

**Requirement:** Where possible, mount the container filesystem as read-only.

**What to check:**
- Consider adding `read_only: true` in docker-compose for stateless services
- If the application writes to the filesystem, use specific `tmpfs` mounts for writable paths

```yaml
services:
  app:
    read_only: true
    tmpfs:
      - /tmp
      - /app/logs
```

### M5: Network Isolation

**Requirement:** Services should only be able to communicate with the services they depend on.

**What to check:**
- Named networks separate public-facing and internal services
- Database and cache services are on internal-only networks
- Only gateway/proxy services are on the public network
- No use of `network_mode: host` in production

---

## Low

### L1: Metadata Labels

**Requirement:** Images should include OCI-standard labels for traceability.

**What to check:**
- `LABEL` directives for: `org.opencontainers.image.source`, `org.opencontainers.image.version`, `org.opencontainers.image.description`
- Labels do not contain sensitive information

```dockerfile
LABEL org.opencontainers.image.source="https://github.com/org/repo"
LABEL org.opencontainers.image.version="1.0.0"
LABEL org.opencontainers.image.description="Application description"
```

### L2: .dockerignore Completeness

**Requirement:** The .dockerignore file should exclude all unnecessary files from the build context.

**What to check:**
- Version control: `.git`, `.gitignore`
- IDE/editor files: `.idea`, `.vscode`, `*.swp`
- Secrets: `.env`, `.env.*`, `*.pem`, `*.key`, `*.crt`
- Documentation: `*.md`, `LICENSE`, `docs/`
- Test files: `tests/`, `__tests__/`, `*.test.*`, `*.spec.*`
- Build artifacts: `node_modules/`, `__pycache__/`, `.venv/`, `target/`, `bin/Debug/`, `obj/`
- Docker files themselves: `Dockerfile*`, `docker-compose*`, `.dockerignore`
- OS files: `.DS_Store`, `Thumbs.db`

### L3: Signal Handling

**Requirement:** The application should handle SIGTERM gracefully for clean shutdown.

**What to check:**
- Use `exec` form for CMD/ENTRYPOINT (array syntax, not shell form)
- Application handles SIGTERM for graceful shutdown
- For Node.js: use `tini` or `--init` flag as PID 1 if the app does not handle signals

```dockerfile
# Bad (shell form -- PID 1 is /bin/sh, signals not forwarded)
CMD npm start

# Good (exec form -- application is PID 1, receives signals directly)
CMD ["node", "dist/index.js"]
```

### L4: Logging to stdout/stderr

**Requirement:** Applications should log to stdout/stderr, not to files inside the container.

**What to check:**
- No log file paths configured in the application's container environment
- Application frameworks are configured to write to stdout
- docker-compose logging driver is configured (json-file with rotation, or external driver)

---

## Audit Report Format

When auditing container files, categorize findings by severity and produce a report in this structure:

```
## Security Audit Results

### Critical Findings
- [C1] Secret detected in Dockerfile ENV: DB_PASSWORD on line 12
  Fix: Remove the ENV directive and pass as runtime environment variable

### High Findings
- [H1] Unpinned base image: FROM node (line 1)
  Fix: Pin to specific version, e.g., FROM node:22-alpine

### Medium Findings
- [M1] No health check defined for the api service
  Fix: Add HEALTHCHECK directive or healthcheck in docker-compose

### Low Findings
- [L2] .dockerignore missing: tests/ directory not excluded
  Fix: Add tests/ to .dockerignore

### Summary
- Critical: N | High: N | Medium: N | Low: N
- Overall: PASS / FAIL (FAIL if any Critical or High findings remain unresolved)
```
