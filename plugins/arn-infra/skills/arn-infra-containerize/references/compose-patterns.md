# Docker Compose Patterns

Multi-service topology patterns for docker-compose configurations. Each pattern includes service definitions, dependency ordering, health checks, networking, and volume management.

---

## Web Application + Database

The most common pattern: a web service backed by a persistent database.

### PostgreSQL

```yaml
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
      target: production
    ports:
      - "${APP_PORT:-3000}:3000"
    environment:
      DATABASE_URL: postgresql://${POSTGRES_USER:-app}:${POSTGRES_PASSWORD}@db:5432/${POSTGRES_DB:-appdb}
      NODE_ENV: production
    depends_on:
      db:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:3000/health"]
      interval: 30s
      timeout: 3s
      start_period: 10s
      retries: 3
    restart: unless-stopped

  db:
    image: postgres:17-alpine
    volumes:
      - pgdata:/var/lib/postgresql/data
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-app}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB:-appdb}
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-app} -d ${POSTGRES_DB:-appdb}"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped

volumes:
  pgdata:
```

### MySQL / MariaDB

```yaml
services:
  app:
    build:
      context: .
      target: production
    ports:
      - "${APP_PORT:-8000}:8000"
    environment:
      DATABASE_URL: mysql://${MYSQL_USER:-app}:${MYSQL_PASSWORD}@db:3306/${MYSQL_DATABASE:-appdb}
    depends_on:
      db:
        condition: service_healthy
    restart: unless-stopped

  db:
    image: mysql:8.4
    volumes:
      - mysqldata:/var/lib/mysql
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE:-appdb}
      MYSQL_USER: ${MYSQL_USER:-app}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped

volumes:
  mysqldata:
```

### MongoDB

```yaml
services:
  app:
    build:
      context: .
      target: production
    ports:
      - "${APP_PORT:-3000}:3000"
    environment:
      MONGO_URI: mongodb://${MONGO_USER:-app}:${MONGO_PASSWORD}@db:27017/${MONGO_DB:-appdb}?authSource=admin
    depends_on:
      db:
        condition: service_healthy
    restart: unless-stopped

  db:
    image: mongo:7
    volumes:
      - mongodata:/data/db
    environment:
      MONGO_INITDB_ROOT_USERNAME: ${MONGO_USER:-app}
      MONGO_INITDB_ROOT_PASSWORD: ${MONGO_PASSWORD}
      MONGO_INITDB_DATABASE: ${MONGO_DB:-appdb}
    healthcheck:
      test: ["CMD", "mongosh", "--eval", "db.adminCommand('ping')"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped

volumes:
  mongodata:
```

---

## Web + Database + Cache

Add a Redis (or Valkey) caching layer to the web+db pattern.

```yaml
services:
  app:
    build:
      context: .
      target: production
    ports:
      - "${APP_PORT:-3000}:3000"
    environment:
      DATABASE_URL: postgresql://${POSTGRES_USER:-app}:${POSTGRES_PASSWORD}@db:5432/${POSTGRES_DB:-appdb}
      REDIS_URL: redis://cache:6379
    depends_on:
      db:
        condition: service_healthy
      cache:
        condition: service_healthy
    restart: unless-stopped

  db:
    image: postgres:17-alpine
    volumes:
      - pgdata:/var/lib/postgresql/data
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-app}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB:-appdb}
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-app}"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped

  cache:
    image: redis:7-alpine
    volumes:
      - redisdata:/data
    command: redis-server --appendonly yes --maxmemory 256mb --maxmemory-policy allkeys-lru
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5
    restart: unless-stopped

volumes:
  pgdata:
  redisdata:
```

---

## Microservices

Multiple independently built services communicating over internal networks.

```yaml
services:
  gateway:
    build:
      context: ./services/gateway
      target: production
    ports:
      - "${GATEWAY_PORT:-8080}:8080"
    environment:
      AUTH_SERVICE_URL: http://auth:3001
      API_SERVICE_URL: http://api:3002
    depends_on:
      auth:
        condition: service_healthy
      api:
        condition: service_healthy
    networks:
      - frontend
      - backend
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:8080/health"]
      interval: 15s
      timeout: 3s
      retries: 3
    restart: unless-stopped

  auth:
    build:
      context: ./services/auth
      target: production
    environment:
      DATABASE_URL: postgresql://${POSTGRES_USER:-app}:${POSTGRES_PASSWORD}@db:5432/${AUTH_DB:-authdb}
      JWT_SECRET: ${JWT_SECRET}
    depends_on:
      db:
        condition: service_healthy
    networks:
      - backend
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:3001/health"]
      interval: 15s
      timeout: 3s
      retries: 3
    restart: unless-stopped

  api:
    build:
      context: ./services/api
      target: production
    environment:
      DATABASE_URL: postgresql://${POSTGRES_USER:-app}:${POSTGRES_PASSWORD}@db:5432/${API_DB:-apidb}
      CACHE_URL: redis://cache:6379
    depends_on:
      db:
        condition: service_healthy
      cache:
        condition: service_healthy
    networks:
      - backend
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:3002/health"]
      interval: 15s
      timeout: 3s
      retries: 3
    restart: unless-stopped

  db:
    image: postgres:17-alpine
    volumes:
      - pgdata:/var/lib/postgresql/data
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-app}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    networks:
      - backend
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-app}"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped

  cache:
    image: redis:7-alpine
    volumes:
      - redisdata:/data
    command: redis-server --appendonly yes
    networks:
      - backend
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5
    restart: unless-stopped

networks:
  frontend:
  backend:

volumes:
  pgdata:
  redisdata:
```

### Key Points for Microservices
- Use named networks to isolate traffic (frontend services cannot talk directly to the database)
- Each service gets its own Dockerfile and build context
- Service-to-service communication uses internal DNS (service name)
- Only the gateway exposes external ports
- Health checks at each service level for proper dependency ordering

---

## Worker Queue Pattern

Background job processing with a message broker.

### With Redis (Bull / BullMQ)

```yaml
services:
  web:
    build:
      context: .
      target: production
    ports:
      - "${APP_PORT:-3000}:3000"
    environment:
      REDIS_URL: redis://queue:6379
      DATABASE_URL: postgresql://${POSTGRES_USER:-app}:${POSTGRES_PASSWORD}@db:5432/${POSTGRES_DB:-appdb}
    depends_on:
      db:
        condition: service_healthy
      queue:
        condition: service_healthy
    restart: unless-stopped

  worker:
    build:
      context: .
      target: production
    command: ["node", "dist/worker.js"]
    environment:
      REDIS_URL: redis://queue:6379
      DATABASE_URL: postgresql://${POSTGRES_USER:-app}:${POSTGRES_PASSWORD}@db:5432/${POSTGRES_DB:-appdb}
    depends_on:
      db:
        condition: service_healthy
      queue:
        condition: service_healthy
    restart: unless-stopped

  queue:
    image: redis:7-alpine
    volumes:
      - queuedata:/data
    command: redis-server --appendonly yes
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5
    restart: unless-stopped

  db:
    image: postgres:17-alpine
    volumes:
      - pgdata:/var/lib/postgresql/data
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-app}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB:-appdb}
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-app}"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped

volumes:
  pgdata:
  queuedata:
```

### With RabbitMQ (Celery / AMQP)

```yaml
services:
  web:
    build:
      context: .
      target: production
    ports:
      - "${APP_PORT:-8000}:8000"
    environment:
      BROKER_URL: amqp://${RABBITMQ_USER:-guest}:${RABBITMQ_PASSWORD:-guest}@broker:5672
      DATABASE_URL: postgresql://${POSTGRES_USER:-app}:${POSTGRES_PASSWORD}@db:5432/${POSTGRES_DB:-appdb}
    depends_on:
      db:
        condition: service_healthy
      broker:
        condition: service_healthy
    restart: unless-stopped

  worker:
    build:
      context: .
      target: production
    command: ["celery", "-A", "app.celery", "worker", "--loglevel=info"]
    environment:
      BROKER_URL: amqp://${RABBITMQ_USER:-guest}:${RABBITMQ_PASSWORD:-guest}@broker:5672
      DATABASE_URL: postgresql://${POSTGRES_USER:-app}:${POSTGRES_PASSWORD}@db:5432/${POSTGRES_DB:-appdb}
    depends_on:
      db:
        condition: service_healthy
      broker:
        condition: service_healthy
    restart: unless-stopped

  broker:
    image: rabbitmq:3.13-management-alpine
    volumes:
      - rabbitdata:/var/lib/rabbitmq
    environment:
      RABBITMQ_DEFAULT_USER: ${RABBITMQ_USER:-guest}
      RABBITMQ_DEFAULT_PASS: ${RABBITMQ_PASSWORD:-guest}
    healthcheck:
      test: ["CMD", "rabbitmq-diagnostics", "check_port_connectivity"]
      interval: 15s
      timeout: 5s
      retries: 5
    restart: unless-stopped

  db:
    image: postgres:17-alpine
    volumes:
      - pgdata:/var/lib/postgresql/data
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-app}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB:-appdb}
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-app}"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped

volumes:
  pgdata:
  rabbitdata:
```

---

## Frontend + Backend (Separate Builds)

Static frontend served by Nginx, with an API backend.

```yaml
services:
  frontend:
    build:
      context: ./frontend
      target: production
    ports:
      - "${FRONTEND_PORT:-80}:80"
    depends_on:
      backend:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:80/"]
      interval: 15s
      timeout: 3s
      retries: 3
    restart: unless-stopped

  backend:
    build:
      context: ./backend
      target: production
    environment:
      DATABASE_URL: postgresql://${POSTGRES_USER:-app}:${POSTGRES_PASSWORD}@db:5432/${POSTGRES_DB:-appdb}
    depends_on:
      db:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:3000/health"]
      interval: 15s
      timeout: 3s
      retries: 3
    restart: unless-stopped

  db:
    image: postgres:17-alpine
    volumes:
      - pgdata:/var/lib/postgresql/data
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-app}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB:-appdb}
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-app}"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped

volumes:
  pgdata:
```

---

## Development Override Pattern

Use a `docker-compose.override.yml` for development-specific settings (hot reload, debug ports, mounted source code).

### Base (`docker-compose.yml`)

The production configuration as shown in the patterns above.

### Override (`docker-compose.override.yml`)

```yaml
# Development overrides -- automatically loaded by `docker compose up`
services:
  app:
    build:
      target: builder  # Use builder stage for dev (includes dev dependencies)
    volumes:
      - .:/app         # Mount source code for hot reload
      - /app/node_modules  # Anonymous volume to prevent host node_modules from overwriting
    environment:
      NODE_ENV: development
      DEBUG: "app:*"
    command: ["npm", "run", "dev"]
    ports:
      - "9229:9229"    # Debug port

  db:
    ports:
      - "5432:5432"    # Expose DB port for local tooling
```

### Key Points
- `docker-compose.override.yml` is auto-loaded by Compose (no `-f` flag needed)
- For explicit production: `docker compose -f docker-compose.yml up` (skips override)
- Mount source code only in development; production copies into the image
- Use anonymous volumes (`/app/node_modules`) to prevent host filesystem from clobbering installed dependencies

---

## General Compose Best Practices

### Environment Variables
- Never hardcode secrets in `docker-compose.yml`
- Use `${VAR:-default}` syntax for non-sensitive defaults
- Reference a `.env` file for local development (Compose loads `.env` automatically)
- Document all required variables in a `.env.example` file

### Health Checks
- Every service MUST have a health check
- Use `depends_on` with `condition: service_healthy` for dependency ordering
- Set `start_period` generously for services with slow startup (databases, JVM apps)

### Volumes
- Use named volumes for persistent data (databases, caches)
- Named volumes survive `docker compose down` (only `docker compose down -v` removes them)
- Use bind mounts only for development (source code hot reload)

### Networking
- Use named networks to control which services can communicate
- Only expose ports that need external access
- Internal services (databases, caches, message brokers) should NOT publish ports in production

### Restart Policy
- Use `unless-stopped` for production services
- Use `no` (the default) for one-shot tasks or migration jobs
- `always` is rarely needed; `unless-stopped` handles most cases

### Resource Limits (Production)
```yaml
services:
  app:
    deploy:
      resources:
        limits:
          cpus: "1.0"
          memory: 512M
        reservations:
          cpus: "0.25"
          memory: 128M
```

### Logging
```yaml
services:
  app:
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
```
