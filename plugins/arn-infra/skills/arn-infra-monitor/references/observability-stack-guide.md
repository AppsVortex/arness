# Observability Stack Guide

Provider-specific and third-party observability options for infrastructure monitoring. Covers logging, metrics, and alerting capabilities with pricing and setup complexity.

---

## Native Cloud Monitoring

### AWS: Amazon CloudWatch

| Component | Service | Purpose |
|-----------|---------|---------|
| Logging | CloudWatch Logs | Centralized log ingestion and search |
| Metrics | CloudWatch Metrics | Infrastructure and custom metric collection |
| Alerting | CloudWatch Alarms + SNS | Threshold-based alerts with notification routing |
| Tracing | AWS X-Ray | Distributed request tracing |
| Dashboards | CloudWatch Dashboards | Metric visualization (out of scope for initial setup) |

**Pricing:**
- Logs: $0.50/GB ingested, $0.03/GB stored (after 5GB free)
- Metrics: First 10 custom metrics free, then $0.30/metric/month
- Alarms: $0.10/alarm/month (first 10 free)
- Dashboard: $3/dashboard/month

**IaC example (OpenTofu):**
```hcl
resource "aws_cloudwatch_log_group" "app" {
  name              = "/${var.environment}/${var.app_name}"
  retention_in_days = var.environment == "production" ? 90 : 30
  tags = {
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.environment}-${var.app_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 90
  alarm_description   = "CPU utilization exceeds 90% for 10 minutes"
  alarm_actions       = [aws_sns_topic.alerts.arn]
}

resource "aws_sns_topic" "alerts" {
  name = "${var.environment}-infra-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}
```

**Setup complexity:** Low -- tightly integrated with all AWS services, automatic metric collection for most resources.

---

### GCP: Cloud Monitoring (formerly Stackdriver)

| Component | Service | Purpose |
|-----------|---------|---------|
| Logging | Cloud Logging | Centralized log management with log-based metrics |
| Metrics | Cloud Monitoring | Infrastructure metrics with uptime checks |
| Alerting | Cloud Alerting | Policy-based alerts with notification channels |
| Tracing | Cloud Trace | Distributed tracing |

**Pricing:**
- Logging: First 50 GB/month free, then $0.50/GB
- Metrics: Custom metrics $0.258/1000 time series/month (first 150 MB free)
- Alerting: Free (included with Cloud Monitoring)
- Uptime checks: Free (up to 100)

**IaC example (OpenTofu):**
```hcl
resource "google_monitoring_uptime_check_config" "health" {
  display_name = "${var.environment}-${var.app_name}-health"
  timeout      = "10s"
  period       = "60s"

  http_check {
    path         = "/health"
    port         = 443
    use_ssl      = true
    validate_ssl = true
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      host       = var.service_url
      project_id = var.project_id
    }
  }
}

resource "google_monitoring_alert_policy" "uptime" {
  display_name = "${var.environment}-${var.app_name}-uptime"
  combiner     = "OR"

  conditions {
    display_name = "Uptime check failing"
    condition_threshold {
      filter          = "resource.type = \"uptime_url\" AND metric.type = \"monitoring.googleapis.com/uptime_check/check_passed\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 1

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_NEXT_OLDER"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]
}
```

**Setup complexity:** Low -- automatic metric collection for GCP resources, generous free tier.

---

### Azure: Azure Monitor

| Component | Service | Purpose |
|-----------|---------|---------|
| Logging | Log Analytics workspace | Centralized log queries (KQL) |
| Metrics | Azure Monitor Metrics | Platform and custom metrics |
| Alerting | Azure Alerts | Metric, log, and activity log alerts |
| Tracing | Application Insights | APM and distributed tracing |

**Pricing:**
- Log Analytics: First 5 GB/month free (per workspace), then ~$2.76/GB
- Metrics: Platform metrics free, custom metrics $0.258/1000 time series
- Alerts: Metric alerts ~$0.10/signal/month, log alerts $1.50/rule/month

**IaC example (Bicep):**
```bicep
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'log-${environment}-${appName}'
  location: location
  properties: {
    sku: { name: 'PerGB2018' }
    retentionInDays: environment == 'production' ? 90 : 30
  }
}

resource metricAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-${environment}-high-cpu'
  location: 'global'
  properties: {
    severity: 2
    enabled: true
    evaluationFrequency: 'PT5M'
    windowSize: 'PT10M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [{
        name: 'HighCPU'
        metricName: 'Percentage CPU'
        operator: 'GreaterThan'
        threshold: 90
        timeAggregation: 'Average'
      }]
    }
    actions: [{
      actionGroupId: actionGroup.id
    }]
  }
}
```

**Setup complexity:** Medium -- Log Analytics workspace setup required, KQL query language for log analysis.

---

## Third-Party Monitoring

### Datadog

| Aspect | Detail |
|--------|--------|
| Coverage | Logging, metrics, APM, security, synthetics, RUM |
| Pricing | Infrastructure: $15/host/month. Logs: $0.10/GB ingested. APM: $31/host/month |
| Multi-cloud | Yes (unified view across AWS, GCP, Azure) |
| Setup complexity | Medium (agent deployment, API key management) |
| IaC support | Terraform provider available (`datadog/datadog`) |

**Best for:** Organizations wanting a single pane of glass across multiple cloud providers, teams that need APM and infrastructure monitoring in one tool.

**Cost warning:** Datadog costs can escalate rapidly with high log volume or many hosts. Start with infrastructure metrics only and add logging/APM selectively.

### Grafana Cloud

| Aspect | Detail |
|--------|--------|
| Coverage | Metrics (Prometheus), logs (Loki), traces (Tempo), dashboards |
| Pricing | Free tier (up to 10K metrics, 50GB logs). Pro: $8/user/month |
| Multi-cloud | Yes (Prometheus-compatible, pull-based) |
| Setup complexity | Medium (Prometheus/Grafana Agent deployment) |
| IaC support | Terraform provider available (`grafana/grafana`) |

**Best for:** Teams familiar with Prometheus/Grafana, projects wanting open-source-compatible monitoring, cost-conscious multi-cloud setups.

### New Relic

| Aspect | Detail |
|--------|--------|
| Coverage | APM, infrastructure, logs, synthetics, browser monitoring |
| Pricing | Free tier (100 GB/month data). Standard: $0.30/GB ingested |
| Multi-cloud | Yes |
| Setup complexity | Low-medium (agent-based, language-specific APM agents) |
| IaC support | Terraform provider available (`newrelic/newrelic`) |

**Best for:** Teams wanting generous free tier with full-stack observability.

### Sentry

| Aspect | Detail |
|--------|--------|
| Coverage | Error tracking, performance monitoring, session replay |
| Pricing | Free (5K errors/month). Team: $26/month (50K errors) |
| Multi-cloud | Yes (cloud-agnostic SaaS) |
| Setup complexity | Low (SDK integration per language) |
| Focus | Application errors and performance, NOT infrastructure metrics |

**Best for:** Application-level error tracking. Use alongside a provider-native solution for infrastructure metrics.

### PagerDuty

| Aspect | Detail |
|--------|--------|
| Coverage | Incident management, on-call scheduling, alert routing |
| Pricing | Free (up to 5 users). Professional: $21/user/month |
| Multi-cloud | Yes (integrates with all monitoring tools) |
| Setup complexity | Low (webhook/API integration) |
| Focus | Alert routing and incident response, NOT metric collection |

**Best for:** On-call rotation and escalation. Use as a notification channel with any monitoring tool.

---

## Stack Recommendation Matrix

| Provider | Beginner | Intermediate | Expert |
|----------|----------|--------------|--------|
| AWS | CloudWatch (built-in) | CloudWatch + SNS | CloudWatch or Datadog/Grafana Cloud |
| GCP | Cloud Monitoring (built-in) | Cloud Monitoring + email | Cloud Monitoring or Grafana Cloud |
| Azure | Azure Monitor (built-in) | Azure Monitor + Action Groups | Azure Monitor or Datadog |
| K8s | Provider-native | Prometheus + Grafana | Prometheus + Grafana + Loki |
| PaaS | Platform built-in + Sentry | Platform + Sentry + PagerDuty | Grafana Cloud + Sentry + PagerDuty |
| Multi-cloud | Native per provider | Grafana Cloud | Datadog or Grafana Cloud |

---

## Logging Best Practices

### Structured Logging Format

```json
{
  "timestamp": "2026-03-11T14:30:00.000Z",
  "level": "ERROR",
  "service": "api",
  "environment": "production",
  "correlationId": "req-abc123",
  "message": "Database connection failed",
  "error": {
    "type": "ConnectionError",
    "message": "Connection refused on port 5432"
  },
  "metadata": {
    "host": "api-prod-1",
    "version": "1.2.3"
  }
}
```

### Log Level Guidelines

| Level | When to Use | Retention |
|-------|-------------|-----------|
| ERROR | Failures requiring attention | Always retained |
| WARN | Degraded conditions, recoverable errors | Retained for alerting window |
| INFO | Normal operations, request/response summaries | Retained per policy |
| DEBUG | Detailed diagnostic information | Dev/staging only, short retention |

### What NOT to Log

- Passwords, API keys, tokens, or secrets
- Personally identifiable information (PII) without consent
- Full request/response bodies with sensitive data
- Credit card numbers, SSNs, or financial data
