# Dockerfile Patterns

Per-language best practices for production-ready, multi-stage Dockerfiles. Each pattern follows security-first principles: pinned base images, non-root users, minimal production images, and optimized layer caching.

---

## Node.js

### Multi-Stage Build

```dockerfile
# Stage 1: Dependencies
FROM node:22-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --production=false

# Stage 2: Build
FROM node:22-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

# Stage 3: Production
FROM node:22-alpine AS production
RUN addgroup -g 1001 -S appgroup && adduser -S appuser -u 1001 -G appgroup
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=deps /app/node_modules ./node_modules
COPY package.json ./
USER appuser
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1
CMD ["node", "dist/index.js"]
```

### Key Points
- Use `npm ci` (not `npm install`) for reproducible builds
- Copy `package.json` and lockfile first for layer caching
- For TypeScript: build in builder stage, copy only compiled JS to production
- For Next.js: use the `standalone` output mode and copy `.next/standalone` and `.next/static`
- For monorepos with workspaces: copy root lockfile and relevant workspace `package.json` files first

### Base Image Selection
| Use Case | Image | Size |
|----------|-------|------|
| Default | `node:22-alpine` | ~180MB |
| Minimal | `gcr.io/distroless/nodejs22-debian12` | ~130MB |
| Native deps | `node:22-slim` | ~250MB |

---

## Python

### Multi-Stage Build

```dockerfile
# Stage 1: Build
FROM python:3.12-slim AS builder
WORKDIR /app
RUN pip install --no-cache-dir --upgrade pip
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# Stage 2: Production
FROM python:3.12-slim AS production
RUN groupadd -r appgroup && useradd -r -g appgroup -d /app -s /sbin/nologin appuser
WORKDIR /app
COPY --from=builder /install /usr/local
COPY . .
RUN chown -R appuser:appgroup /app
USER appuser
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "4", "app:create_app()"]
```

### UV-Based Build (for UV projects)

```dockerfile
# Stage 1: Build
FROM python:3.12-slim AS builder
WORKDIR /app
COPY --from=ghcr.io/astral-sh/uv:0.6 /uv /usr/local/bin/uv
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev --no-editable
COPY . .

# Stage 2: Production
FROM python:3.12-slim AS production
RUN groupadd -r appgroup && useradd -r -g appgroup -d /app -s /sbin/nologin appuser
WORKDIR /app
COPY --from=builder /app/.venv /app/.venv
COPY --from=builder /app .
ENV PATH="/app/.venv/bin:$PATH"
USER appuser
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "4", "app:create_app()"]
```

### Key Points
- Use `--no-cache-dir` with pip to reduce image size
- Copy `requirements.txt` first for layer caching
- For Django: run `collectstatic` in the builder stage
- For FastAPI/Uvicorn: use `uvicorn` as the CMD with `--host 0.0.0.0`
- For UV projects: copy `pyproject.toml` and `uv.lock` first, use `uv sync --frozen`

### Base Image Selection
| Use Case | Image | Size |
|----------|-------|------|
| Default | `python:3.12-slim` | ~150MB |
| Minimal | `gcr.io/distroless/python3-debian12` | ~50MB |
| Sci/ML deps | `python:3.12` | ~900MB |

---

## Go

### Multi-Stage Build

```dockerfile
# Stage 1: Build
FROM golang:1.23-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o /app/server ./cmd/server

# Stage 2: Production
FROM gcr.io/distroless/static-debian12 AS production
COPY --from=builder /app/server /server
USER nonroot:nonroot
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD ["/server", "--healthcheck"]
ENTRYPOINT ["/server"]
```

### Key Points
- Go compiles to a static binary -- use `distroless/static` or `scratch` for the production stage
- Set `CGO_ENABLED=0` for fully static binaries (no libc dependency)
- Use `-ldflags="-w -s"` to strip debug info and reduce binary size
- Copy `go.mod` and `go.sum` first for layer caching
- For multiple binaries: use separate `RUN go build` commands or a build argument

### Base Image Selection
| Use Case | Image | Size |
|----------|-------|------|
| Default | `gcr.io/distroless/static-debian12` | ~2MB |
| Minimal | `scratch` | 0MB (binary only) |
| With libc | `gcr.io/distroless/base-debian12` | ~20MB |
| Build stage | `golang:1.23-alpine` | ~300MB |

---

## Rust

### Multi-Stage Build

```dockerfile
# Stage 1: Build dependencies (cache layer)
FROM rust:1.82-slim AS deps
WORKDIR /app
RUN cargo init --name placeholder
COPY Cargo.toml Cargo.lock ./
RUN cargo build --release && rm -rf src target/release/placeholder*

# Stage 2: Build application
FROM rust:1.82-slim AS builder
WORKDIR /app
COPY --from=deps /app/target ./target
COPY --from=deps /usr/local/cargo /usr/local/cargo
COPY . .
RUN cargo build --release

# Stage 3: Production
FROM gcr.io/distroless/cc-debian12 AS production
COPY --from=builder /app/target/release/myapp /myapp
USER nonroot:nonroot
EXPOSE 8080
ENTRYPOINT ["/myapp"]
```

### Key Points
- Rust builds are slow -- cache dependencies separately from source code
- Use `distroless/cc` (not `static`) because Rust binaries may link to libc
- For fully static builds with musl: use `rust:1.82-alpine` and `target x86_64-unknown-linux-musl`
- The `cargo init` trick in the deps stage allows caching the dependency build

### Base Image Selection
| Use Case | Image | Size |
|----------|-------|------|
| Default | `gcr.io/distroless/cc-debian12` | ~20MB |
| Static musl | `scratch` | 0MB |
| Build stage | `rust:1.82-slim` | ~800MB |

---

## Java (Spring Boot / Gradle / Maven)

### Multi-Stage Build (Maven)

```dockerfile
# Stage 1: Build
FROM eclipse-temurin:21-jdk-alpine AS builder
WORKDIR /app
COPY pom.xml .
COPY .mvn .mvn
COPY mvnw .
RUN chmod +x mvnw && ./mvnw dependency:go-offline -B
COPY src ./src
RUN ./mvnw package -DskipTests -B

# Stage 2: Production
FROM eclipse-temurin:21-jre-alpine AS production
RUN addgroup -g 1001 -S appgroup && adduser -S appuser -u 1001 -G appgroup
WORKDIR /app
COPY --from=builder /app/target/*.jar app.jar
USER appuser
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/actuator/health || exit 1
ENTRYPOINT ["java", "-jar", "app.jar"]
```

### Key Points
- Use JRE (not JDK) in the production stage
- Copy `pom.xml` / `build.gradle` first and resolve dependencies for layer caching
- For Spring Boot: use `spring-boot:build-image` for buildpack-based images as an alternative
- Set JVM memory limits via `JAVA_OPTS` environment variable
- Use `-XX:+UseContainerSupport` (enabled by default in modern JVMs) for container-aware memory management
- For Gradle: use `./gradlew build -x test` in the builder stage

### Base Image Selection
| Use Case | Image | Size |
|----------|-------|------|
| Default | `eclipse-temurin:21-jre-alpine` | ~180MB |
| Minimal | `gcr.io/distroless/java21-debian12` | ~230MB |
| Build stage | `eclipse-temurin:21-jdk-alpine` | ~350MB |

---

## .NET

### Multi-Stage Build

```dockerfile
# Stage 1: Build
FROM mcr.microsoft.com/dotnet/sdk:9.0-alpine AS builder
WORKDIR /app
COPY *.csproj .
RUN dotnet restore
COPY . .
RUN dotnet publish -c Release -o /publish --no-restore

# Stage 2: Production
FROM mcr.microsoft.com/dotnet/aspnet:9.0-alpine AS production
RUN addgroup -g 1001 -S appgroup && adduser -S appuser -u 1001 -G appgroup
WORKDIR /app
COPY --from=builder /publish .
USER appuser
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1
ENTRYPOINT ["dotnet", "MyApp.dll"]
```

### Key Points
- Use the ASP.NET runtime image (not the SDK) in production
- Copy `.csproj` first and run `dotnet restore` for layer caching
- For self-contained deployments: use `dotnet publish -r linux-musl-x64 --self-contained` and switch to `alpine` base
- Use `ASPNETCORE_URLS=http://+:8080` to configure the listening port via environment variable

### Base Image Selection
| Use Case | Image | Size |
|----------|-------|------|
| Default | `mcr.microsoft.com/dotnet/aspnet:9.0-alpine` | ~110MB |
| Self-contained | `mcr.microsoft.com/dotnet/runtime-deps:9.0-alpine` | ~10MB |
| Build stage | `mcr.microsoft.com/dotnet/sdk:9.0-alpine` | ~600MB |

---

## General Best Practices

### Layer Ordering for Cache Optimization
1. Base image and system dependencies (rarely changes)
2. Application dependency manifests (`package.json`, `requirements.txt`, `go.mod`)
3. Dependency installation (changes when deps update)
4. Application source code (changes frequently)
5. Build step (depends on source code)

### .dockerignore Essentials
Every project should exclude at minimum:
```
.git
.gitignore
*.md
LICENSE
.env
.env.*
docker-compose*.yml
Dockerfile*
.dockerignore
node_modules
__pycache__
.venv
target
bin/Debug
obj
.idea
.vscode
.DS_Store
*.pem
*.key
*.crt
```

### Health Check Patterns
- HTTP endpoint: `wget --spider` or `curl --fail` against a `/health` route
- TCP check: `nc -z localhost <port>` for non-HTTP services
- Command check: run a lightweight application-specific command
- Always set `--start-period` to give the application time to boot
