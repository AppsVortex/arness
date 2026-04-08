# Agent Invocation Guide

Reference for agent invocation during the arn-infra-assess workflow.

---

## arn-infra-request-analyzer (Mode B: Full Application Analysis)

Invoke the `arn-infra-request-analyzer` agent in Mode B with the following structured prompt:

--- APPLICATION CONTEXT ---
[codebase patterns content]
[architecture content]
[deferred backlog content, if any]
--- END APPLICATION CONTEXT ---

--- INFRASTRUCTURE CONFIG ---
Project topology: [topology]
Application path: [path]
Providers: [from ## Arness]
Default IaC tool: [from ## Arness]
Experience level: [from ## Arness]
--- END INFRASTRUCTURE CONFIG ---

--- INSTRUCTIONS ---
Perform a comprehensive infrastructure analysis of the entire application.
Analyze: application components, data layer, external integrations, networking,
security surface, and performance indicators.
Incorporate the deferred backlog items as starting context.
Produce infrastructure implications organized by priority category
(foundation, core, enhancement).
--- END INSTRUCTIONS ---

### Expected Return

The agent returns a comprehensive analysis covering:
- Application components (web servers, APIs, workers, scheduled jobs)
- Data layer (databases, caches, object storage, file systems)
- External integrations (third-party APIs, email services, payment gateways)
- Networking (public endpoints, internal service communication, DNS)
- Security (authentication providers, SSL/TLS, secrets)
- Performance (traffic patterns, scaling requirements, latency sensitivity)
