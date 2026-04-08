---
name: arn-infra-monitor
description: >-
  This skill should be used when the user says "set up monitoring", "arn infra monitor",
  "infra monitor", "configure monitoring", "set up observability", "add logging",
  "configure alerting", "set up alerts", "infrastructure monitoring", "add metrics",
  "set up cloudwatch", "configure grafana", "observability setup", "logging setup",
  "alerting setup", "health checks", "monitor infrastructure", "arn-infra-monitor",
  "set up cloud monitoring", "configure notifications", "prometheus", "datadog",
  "new relic", "sentry", or wants to set up logging, metrics collection, and
  alerting for their deployed infrastructure.
version: 1.0.0
---

# Arness Infra Monitor

Set up observability for deployed infrastructure: structured logging, metrics collection, and alerting. This skill recommends an observability stack based on the configured cloud provider, generates IaC for monitoring resources, and configures basic health-check-based alerts.

This skill focuses on initial monitoring setup and critical alerts. It does NOT create full monitoring dashboards (out of scope per spec). For ongoing monitoring and alerting customization, refer users to their provider's monitoring console.

## Prerequisites

Read `## Arness` from the project's CLAUDE.md. If no `## Arness` section exists or Arness Infra fields are missing, inform the user: "Arness Infra is not configured for this project yet. Run `/arn-infra-wizard` to get started — it will set everything up automatically." Do not proceed without it.

Check the **Deferred** field. If `Deferred: yes`, inform the user: "Infrastructure is in deferred mode. Monitoring setup is not available until infrastructure is fully configured. Run `/arn-infra-assess` to un-defer." Stop.

Extract:
- **Experience level** -- derived from user profile. Read `~/.arness/user-profile.yaml` (or `.claude/arness-profile.local.md` if it exists — project override takes precedence). Apply the experience derivation mapping from `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-ensure-config/references/experience-derivation.md`. If no profile exists, check for legacy `Experience level` in `## Arness` as fallback.
- **Providers** -- cloud providers in use
- **Providers config** -- path to `providers.md` for per-provider details
- **Default IaC tool** -- for generating monitoring IaC
- **Environments** -- environment list for per-environment monitoring config
- **Environments config** -- path to `environments.md`
- **Tooling manifest** -- path to `tooling-manifest.json`
- **Resource manifest** -- path to `active-resources.json` for checking deployed resource state (if available from prior deployments)
- **Cost threshold** -- for monitoring cost considerations

---

## Workflow

### Step 1: Assess Current Monitoring State

Scan for existing monitoring configurations:

```
Glob **/cloudwatch*.tf
Glob **/monitoring*.tf
Glob **/alerting*.tf
Glob **/datadog*.tf
Glob **/grafana*.tf
Glob **/prometheus*.yml
Glob **/alertmanager*.yml
Glob docker-compose*.yml
```

Check deployed resources (if available):
```
Read <resource-manifest-path>
```

**If existing monitoring is detected:**
Present: "I found existing monitoring configuration: [list]. I can extend this with additional alerts and logging."

**If no monitoring is detected:**
Continue to Step 2 for fresh monitoring setup.

---

### Step 2: Recommend Observability Stack

> Read the local override or plugin default for `observability-stack-guide.md`.

Based on the configured provider(s) and experience level, recommend a monitoring approach:

**Expert:**
Present all options:
"Here are the observability options for your [provider] setup:

**Native monitoring:**
- [Provider-native option] -- tightest integration, included in cloud costs

**Third-party options:**
- [Datadog / Grafana Cloud / New Relic] -- richer features, cross-cloud visibility, additional cost

Which approach do you prefer?"

**Intermediate:**
Present the recommended stack:
"For [provider], I recommend:
- **Logging:** [provider-native logging service] -- captures application and infrastructure logs
- **Metrics:** [provider-native metrics] -- tracks resource utilization and application performance
- **Alerting:** [provider-native alerting] -- notifies you when things go wrong

This uses your cloud provider's built-in tools, so there are no additional services to manage. Would you like to proceed, or would you prefer a third-party solution?"

**Beginner:**
Make the recommendation directly:
"I'll set up monitoring using [provider's native tools]. This gives you logging, metrics, and alerts without any extra services or costs beyond your cloud provider."

**Stack selection per provider:**
- AWS --> CloudWatch (Logs, Metrics, Alarms) + SNS (notifications)
- GCP --> Cloud Logging + Cloud Monitoring + Cloud Alerting
- Azure --> Azure Monitor (Log Analytics + Metrics + Alerts)
- Kubernetes --> Prometheus + Grafana (or provider-native)
- PaaS (Fly.io, Railway, etc.) --> Platform-native logging + external alerting (PagerDuty, OpsGenie, or email)
- Multi-cloud --> Grafana Cloud or Datadog (unified view)

---

### Step 3: Configure Logging

Guide the setup of structured logging for the deployment:

**Application logging:**
- Structured log format (JSON) for machine parsing
- Log levels: ERROR, WARN, INFO, DEBUG
- Correlation IDs for request tracing
- Sensitive data redaction (no PII, no secrets in logs)

**Infrastructure logging:**
- CloudTrail / Cloud Audit Logs / Azure Activity Log (API call auditing)
- VPC Flow Logs (AWS) / VPC Flow Logs (GCP) / NSG Flow Logs (Azure) (network monitoring)
- Access logs for load balancers, CDNs, API gateways

**Log retention per environment:**
| Environment | Retention | Rationale |
|-------------|-----------|-----------|
| Dev | 7 days | Cost optimization |
| Staging | 30 days | Debugging window |
| Production | 90 days | Compliance (SOC 2 minimum) |

---

### Step 4: Configure Metrics Collection

Set up metrics collection for key infrastructure components:

**Core metrics to collect:**
- **Compute:** CPU utilization, memory usage, disk I/O
- **Network:** Request count, response time, error rate, bandwidth
- **Database:** Connection count, query latency, replication lag
- **Queue/Cache:** Queue depth, cache hit rate, eviction rate
- **Application:** Health check status, request latency (p50, p95, p99), error rate

**Custom metrics (optional for expert users):**
- Business metrics (orders processed, users active)
- Infrastructure drift metrics (planned vs. actual state)
- Cost metrics (daily spend by resource tag)

---

### Step 5: Configure Alerting

> Read the local override or plugin default for `alerting-patterns.md`.

Set up alerts for critical conditions:

**Essential alerts (configured for all experience levels):**

| Alert | Metric | Threshold | Severity |
|-------|--------|-----------|----------|
| Service down | Health check | 3 consecutive failures | Critical |
| High error rate | HTTP 5xx rate | > 5% of requests for 5 min | Critical |
| High CPU | CPU utilization | > 80% for 10 min | Warning |
| High memory | Memory utilization | > 85% for 10 min | Warning |
| Disk space | Disk usage | > 80% for 15 min | Warning |
| High latency | Response time p99 | > 1s for 5 min | Warning |
| Critical latency | Response time p99 | > 3s for 5 min | Critical |

**Notification channels:**

Ask (using `AskUserQuestion`):

**"Where should alerts be sent?"**

Options:
1. **Email** -- Simple, always available
2. **Slack/Teams webhook** -- Team visibility
3. **PagerDuty/OpsGenie** -- On-call rotation and escalation
4. **SMS** -- Critical alerts only

**Expert:** Allow full customization of thresholds, metrics, and notification channels per alert.

**Intermediate:** Present defaults and allow adjustments: "Here are the recommended alert thresholds. Would you like to adjust any?"

**Beginner:** Apply defaults: "I'll set up alerts for the most critical conditions. You'll receive notifications at [chosen channel] when your services need attention."

---

### Step 6: Generate Monitoring IaC

Invoke the `arn-infra-specialist` agent via the Task tool with:

--- MONITORING CONTEXT ---
Observability stack: [chosen stack]
Provider: [provider]
Environments: [list]
Deployed resources: [from resource manifest, or "not yet deployed"]
--- END MONITORING CONTEXT ---

--- LOGGING CONFIGURATION ---
Log format: structured (JSON)
Log destinations: [provider-native service]
Retention: [per-environment retention settings]
Infrastructure logs: [CloudTrail/Audit Logs enabled]
--- END LOGGING CONFIGURATION ---

--- METRICS CONFIGURATION ---
Core metrics: CPU, memory, disk, network, request count, error rate, latency
Custom metrics: [any user-specified custom metrics]
--- END METRICS CONFIGURATION ---

--- ALERTING CONFIGURATION ---
[For each alert:]
Alert name: [name]
Metric: [metric source]
Threshold: [value and duration]
Severity: [critical | warning]
Notification channel: [channel type and target]
--- END ALERTING CONFIGURATION ---

--- INSTRUCTIONS ---
Generate IaC for monitoring resources:

1. **Logging resources:** Log group/workspace creation, log subscription filters, log retention policies
2. **Metrics resources:** Custom metric definitions, metric filters, dashboard data sources (but NOT full dashboards)
3. **Alerting resources:** Alarm/alert policy definitions, notification channel configurations, action groups
4. **Health check resources:** HTTP health checks for deployed services

For each environment:
- Generate environment-specific monitoring configurations
- Production should have tighter thresholds and shorter evaluation periods
- Dev can have relaxed thresholds or disabled non-critical alerts

Follow these rules:
- Use the chosen IaC tool for all resources
- Include comments explaining each alert's purpose and threshold rationale
- Configure notification channels per user choice
- Do NOT create full monitoring dashboards -- only data sources and alerts
--- END INSTRUCTIONS ---

---

### Step 7: Present and Write Configuration

Present the generated monitoring configuration for user approval:

"Here is the monitoring setup:

**Observability stack:** [stack]
**Logging:** [log service] with [retention] retention
**Metrics:** [count] core metrics tracked
**Alerts:** [count] alerts configured
**Notification channel:** [channel]

[For each generated file:]
**[filename]:**
```[language]
[generated content]
```

Ask (using `AskUserQuestion`):

**"How would you like to proceed with the monitoring configuration?"**

Options:
1. **Approve and write** -- Write all monitoring files
2. **Adjust thresholds** -- Modify alert thresholds before writing
3. **Add/remove alerts** -- Change which alerts are configured
4. **Regenerate** -- Choose a different observability stack

Upon approval, write the files.

---

### Step 8: Summarize and Next Steps

**Monitoring Setup Summary:**
- **Observability stack:** [stack]
- **Logging:** [service] with [retention] retention per environment
- **Metrics:** [count] metrics tracked ([list key metrics])
- **Alerts:** [count] alerts configured via [notification channel]
- **Files created:** [list with paths]

**Recommended next steps:**

"Monitoring is configured. Here is the recommended path:

1. **Deploy monitoring:** Run `/arn-infra-deploy` to deploy the monitoring configuration alongside your infrastructure
2. **Verify alerts:** After deployment, trigger a test alert to confirm notifications work
3. **Review thresholds:** After running for a few days, review alert thresholds based on actual usage patterns
4. **Set up secrets:** Run `/arn-infra-secrets` if your monitoring requires API keys (e.g., Datadog, PagerDuty)

Or run `/arn-infra-wizard` for the full guided pipeline."

---

## Error Handling

- **`## Arness` config missing:** Suggest running `/arn-infra-wizard` to get started. Stop.
- **No providers configured:** Suggest running `/arn-infra-init` to configure providers. Stop.
- **No deployed resources yet:** Proceed with monitoring IaC generation. The monitoring resources will be deployed alongside the infrastructure. Note: "Health check alerts will activate once services are deployed."
- **Specialist agent fails:** Report the error. Fall back to generating basic monitoring configurations directly using the loaded reference patterns. Present with a note: "Generated using fallback patterns -- review carefully."
- **Specialist agent returns empty output:** Inform the user and retry with additional context. If retry fails, generate minimal monitoring with health check alerts only.
- **Third-party monitoring requires API key:** Guide the user through API key setup. Suggest storing the key in the configured secrets manager. Do not hardcode API keys in IaC.
- **Cost concerns with monitoring:** If monitoring adds significant cost (e.g., Datadog, high-volume logging), warn the user and suggest alternatives (native monitoring, log sampling).
- **PaaS providers with limited monitoring:** Note that PaaS platforms (Fly.io, Railway, Render) have basic built-in monitoring. For deeper observability, recommend an external tool (Grafana Cloud, Sentry).
- **Re-running is safe:** Re-running presents current monitoring state and offers to update. Existing alert configurations are shown before overwriting. Monitoring IaC files are updated, not duplicated.
