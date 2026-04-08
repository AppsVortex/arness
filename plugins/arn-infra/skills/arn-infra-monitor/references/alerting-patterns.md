# Alerting Patterns

Alert categories, threshold guidance, notification channel options, and escalation policies for infrastructure monitoring.

---

## Availability Alerts

Alerts that detect service outages or degradation.

### Health Check Failure

| Aspect | Detail |
|--------|--------|
| Metric | HTTP health check response (2xx vs. non-2xx or timeout) |
| Threshold | 3 consecutive failures within 5 minutes |
| Severity | Critical |
| Evaluation period | 60 seconds between checks |
| Notification | Immediate (PagerDuty, SMS, Slack) |

**IaC implementation (OpenTofu - AWS):**
```hcl
resource "aws_route53_health_check" "app" {
  fqdn              = var.service_domain
  port               = 443
  type               = "HTTPS"
  resource_path      = "/health"
  failure_threshold  = 3
  request_interval   = 30
}

resource "aws_cloudwatch_metric_alarm" "health_check" {
  alarm_name          = "${var.environment}-health-check-failed"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = 60
  statistic           = "Minimum"
  threshold           = 1
  alarm_description   = "Service health check is failing"
  alarm_actions       = [var.critical_sns_topic_arn]

  dimensions = {
    HealthCheckId = aws_route53_health_check.app.id
  }
}
```

### Uptime Monitoring

| Aspect | Detail |
|--------|--------|
| Metric | External uptime check from multiple regions |
| Threshold | 2+ regions report failure for 3 consecutive checks |
| Severity | Critical |
| Best practice | Monitor from at least 3 geographic regions |

---

## Performance Alerts

Alerts that detect performance degradation before users are affected.

### High Latency

| Aspect | Detail |
|--------|--------|
| Metric | HTTP response time (p99) |
| Warning threshold | > 1 second for 5 minutes |
| Critical threshold | > 3 seconds for 5 minutes |
| Evaluation window | 5-minute sliding window |
| Notification | Warning: Slack/email. Critical: PagerDuty |

**Threshold guidance by application type:**
| Application | Good (p99) | Warning (p99) | Critical (p99) |
|-------------|-----------|----------------|-----------------|
| API service | < 200ms | > 500ms | > 2s |
| Web application | < 500ms | > 1s | > 3s |
| Background worker | < 5s | > 30s | > 60s |
| Database query | < 100ms | > 500ms | > 2s |

### High Error Rate

| Aspect | Detail |
|--------|--------|
| Metric | HTTP 5xx responses / total responses |
| Warning threshold | > 1% of requests for 5 minutes |
| Critical threshold | > 5% of requests for 5 minutes |
| Evaluation window | 5-minute sliding window |
| Minimum sample | Alert only when > 100 requests in window (avoid false positives on low traffic) |

**IaC implementation (OpenTofu - AWS ALB):**
```hcl
resource "aws_cloudwatch_metric_alarm" "high_error_rate" {
  alarm_name          = "${var.environment}-high-5xx-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 5

  metric_query {
    id          = "error_rate"
    expression  = "(errors / requests) * 100"
    label       = "Error Rate %"
    return_data = true
  }

  metric_query {
    id = "errors"
    metric {
      metric_name = "HTTPCode_Target_5XX_Count"
      namespace   = "AWS/ApplicationELB"
      period      = 300
      stat        = "Sum"
      dimensions = {
        LoadBalancer = var.alb_arn_suffix
      }
    }
  }

  metric_query {
    id = "requests"
    metric {
      metric_name = "RequestCount"
      namespace   = "AWS/ApplicationELB"
      period      = 300
      stat        = "Sum"
      dimensions = {
        LoadBalancer = var.alb_arn_suffix
      }
    }
  }

  alarm_actions = [var.critical_sns_topic_arn]
}
```

---

## Resource Alerts

Alerts that detect resource exhaustion before failures occur.

### CPU Utilization

| Aspect | Detail |
|--------|--------|
| Metric | CPU utilization percentage |
| Warning threshold | > 80% average for 10 minutes |
| Critical threshold | > 95% average for 5 minutes |
| Evaluation window | 5-10 minutes (avoid burst false positives) |

**Threshold adjustments:**
- Auto-scaling enabled: set higher thresholds (scaling handles spikes)
- Fixed capacity: set lower thresholds (no automatic relief)
- Burstable instances (t3, e2): monitor burst credit balance separately

### Memory Utilization

| Aspect | Detail |
|--------|--------|
| Metric | Memory utilization percentage |
| Warning threshold | > 85% for 10 minutes |
| Critical threshold | > 95% for 5 minutes |
| Note | AWS EC2 does not emit memory metrics by default -- requires CloudWatch Agent |

### Disk Usage

| Aspect | Detail |
|--------|--------|
| Metric | Disk utilization percentage |
| Warning threshold | > 80% |
| Critical threshold | > 90% |
| Evaluation window | 15 minutes (disk fills slowly) |
| Note | Also monitor disk I/O wait for performance issues |

### Database Connections

| Aspect | Detail |
|--------|--------|
| Metric | Active connections / max connections |
| Warning threshold | > 80% of max connections |
| Critical threshold | > 95% of max connections |
| Evaluation window | 5 minutes |

---

## Cost Alerts

Alerts that detect unexpected cost increases.

### Daily Spend

| Aspect | Detail |
|--------|--------|
| Metric | Daily cloud spend (from billing API or cost explorer) |
| Warning threshold | > 150% of daily average (trailing 7 days) |
| Critical threshold | > 200% of daily average |
| Evaluation window | Daily |
| Notification | Email (cost alerts rarely need immediate response) |

### Budget Threshold

| Aspect | Detail |
|--------|--------|
| Metric | Monthly spend vs. configured budget |
| Warning threshold | > 80% of monthly budget with > 10 days remaining |
| Critical threshold | > 100% of monthly budget |
| Note | Link to `## Arness` cost threshold setting |

**IaC implementation (OpenTofu - AWS):**
```hcl
resource "aws_budgets_budget" "monthly" {
  name         = "${var.environment}-monthly-budget"
  budget_type  = "COST"
  limit_amount = var.cost_threshold
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }

  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 100
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }
}
```

---

## Notification Channels

### Email

| Aspect | Detail |
|--------|--------|
| Best for | Non-urgent alerts, cost notifications, daily summaries |
| Setup | Add email address to alert notification channel |
| Latency | Minutes (email delivery can be delayed) |
| Cost | Free |

### Slack / Microsoft Teams

| Aspect | Detail |
|--------|--------|
| Best for | Team visibility, warning-level alerts, deployment notifications |
| Setup | Create incoming webhook, add to alert channel |
| Latency | Seconds |
| Cost | Free (part of Slack/Teams subscription) |

**Slack webhook example:**
```hcl
resource "aws_sns_topic_subscription" "slack" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "https"
  endpoint  = var.slack_webhook_url
}
```

### PagerDuty / OpsGenie

| Aspect | Detail |
|--------|--------|
| Best for | Critical alerts requiring immediate response, on-call rotation |
| Setup | Create service integration, connect to monitoring |
| Latency | Seconds (with escalation policies) |
| Cost | PagerDuty: $21+/user/month. OpsGenie: $9+/user/month |

**Features:**
- On-call rotation scheduling
- Escalation policies (if not acknowledged in N minutes, escalate)
- Alert deduplication and grouping
- Post-incident reporting

### SMS

| Aspect | Detail |
|--------|--------|
| Best for | Critical alerts only (backup for PagerDuty/OpsGenie) |
| Setup | Provider-specific (AWS SNS, Twilio) |
| Latency | Seconds |
| Cost | $0.01-0.05 per message |
| Limitation | No rich formatting, easy to ignore in volume |

---

## Escalation Policies

### Basic Escalation (Recommended for Most Teams)

```
Alert triggered
  └── Level 1: Slack notification + on-call engineer (immediate)
        └── Not acknowledged in 15 min
              └── Level 2: Phone call to on-call (via PagerDuty)
                    └── Not acknowledged in 30 min
                          └── Level 3: Notify team lead + secondary on-call
```

### Simple Escalation (Small Teams / Beginners)

```
Alert triggered
  └── Email + Slack notification to team channel (immediate)
        └── Critical alerts: also send SMS to team lead
```

---

## Alert Hygiene

### Avoiding Alert Fatigue

- **Tune thresholds after deployment.** Start with the defaults above, then adjust based on actual baselines after 1-2 weeks of data.
- **Group related alerts.** Do not send separate alerts for CPU, memory, and disk on the same host simultaneously -- group them as "resource exhaustion on host X."
- **Use warning vs. critical distinction.** Warning = investigate soon. Critical = investigate now. If all alerts are critical, nothing is critical.
- **Set minimum sample sizes.** Do not alert on error rate if there are only 5 requests -- statistical noise will cause false positives.
- **Schedule maintenance windows.** Suppress alerts during planned maintenance to avoid false pages.

### Alert Response Runbook Template

For each critical alert, document:
1. **What does this alert mean?** (plain language)
2. **What is the impact?** (users affected, services degraded)
3. **How to investigate?** (logs to check, metrics to review)
4. **How to mitigate?** (immediate actions: restart, scale up, failover)
5. **How to resolve?** (root cause fix)
6. **Who to escalate to?** (if beyond on-call's ability)
