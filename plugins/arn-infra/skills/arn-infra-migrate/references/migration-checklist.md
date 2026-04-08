# Migration Checklist

Pre-migration, cutover, and post-cutover checklists for infrastructure migration. Use this checklist at each phase of the migration lifecycle.

---

## Pre-Migration Checklist

Complete these items before beginning migration execution.

### Data and Backups

- [ ] **Full backup of source databases verified.** Backup was created, tested for restore, and stored securely. Record backup timestamp and location.
- [ ] **File storage backup verified.** All object storage (S3, GCS, Blob) contents backed up or snapshots created.
- [ ] **Backup restore procedure tested.** Successfully restored from backup to a test environment. Documented the restore time and any issues.
- [ ] **Data export completed (if applicable).** Database dumps, CSV exports, or replication setup for data migration.

### DNS Preparation

- [ ] **DNS TTL reduced.** TTL set to 300 seconds (5 minutes) or lower at least 24 hours before cutover. This ensures DNS changes propagate quickly during cutover.
  ```bash
  # Verify current TTL
  dig +short myapp.example.com | head -1
  dig myapp.example.com | grep TTL
  ```
- [ ] **DNS records documented.** All current DNS records (A, CNAME, MX, TXT) recorded for rollback reference.
- [ ] **Domain registrar access confirmed.** Can make DNS changes when needed.

### Target Infrastructure

- [ ] **Target infrastructure deployed in staging.** All IaC applied and resources provisioned in the staging environment.
- [ ] **Target infrastructure tested in staging.** Application deploys, serves traffic, and passes health checks in staging.
- [ ] **Target environment variables configured.** All environment variables and secrets set up on the target.
- [ ] **Target SSL/TLS certificates provisioned.** Certificates issued and verified for the target (ACM, Let's Encrypt, managed certificates).
- [ ] **Target monitoring configured.** Health checks, alerts, and logging active on the target infrastructure.
- [ ] **Target auto-scaling configured (if applicable).** Auto-scaling policies set and tested under load.

### Application Readiness

- [ ] **Application deployed to target staging.** Application runs correctly on the target infrastructure in staging.
- [ ] **Feature parity verified.** All features work identically on source and target. Documented any differences.
- [ ] **Performance baseline established.** Latency, throughput, and error rate measurements on source (for comparison after cutover).
- [ ] **Connection strings updated in application config.** Application can connect to target databases, caches, and services.

### Team and Communication

- [ ] **Team notified of migration window.** All stakeholders know when the cutover will occur.
- [ ] **Rollback plan documented and reviewed.** Written rollback procedure reviewed by at least one team member.
- [ ] **Rollback decision criteria defined.** Clear criteria for when to rollback (e.g., error rate > 10% for 5 minutes, health checks failing for 3 minutes).
- [ ] **Communication channel established.** Slack channel, war room, or incident bridge set up for migration coordination.

### Parallel Running (Recommended)

- [ ] **Both source and target active simultaneously.** Target infrastructure serves staging or shadow traffic alongside source.
- [ ] **Data replication running (if applicable).** Database replication from source to target is active and up to date.
- [ ] **Parallel running duration sufficient.** At least 24-48 hours of parallel running before cutover.

---

## Cutover Checklist

Execute these items during the cutover window. Keep this checklist visible during execution.

### Pre-Cutover (T-30 minutes)

- [ ] **Final data sync initiated.** Last database sync/replication checkpoint. Record the timestamp.
- [ ] **Source set to read-only (if applicable).** Prevent writes to source during cutover to avoid data divergence.
  ```sql
  -- PostgreSQL
  ALTER DATABASE mydb SET default_transaction_read_only = on;
  ```
- [ ] **Team assembled on communication channel.** All participants confirmed ready.
- [ ] **Monitoring dashboards open.** Source and target monitoring visible for real-time comparison.

### DNS and Traffic (T-0)

- [ ] **DNS records updated.** A/CNAME records pointed to target infrastructure.
  ```bash
  # Update DNS (provider-specific)
  # AWS Route53:
  aws route53 change-resource-record-sets --hosted-zone-id $ZONE_ID --change-batch file://dns-change.json

  # Verify DNS propagation
  dig +short myapp.example.com
  # Should return target IP/CNAME
  ```
- [ ] **Traffic shifting verified.** Requests are reaching the target infrastructure. Check target access logs.
- [ ] **Source receiving decreasing traffic.** Monitor source access logs -- traffic should decrease as DNS propagates.

### Health Verification (T+5 minutes)

- [ ] **Health check endpoints passing.** All health check URLs return 200 on the target.
  ```bash
  curl -s -o /dev/null -w "%{http_code}" https://myapp.example.com/health
  # Expected: 200
  ```
- [ ] **Application logs clean.** No error spikes in target application logs.
- [ ] **Error rate within threshold.** Target error rate < 1% (or within defined threshold).
- [ ] **Latency within threshold.** Target p99 latency within acceptable range.

### Data Verification (T+10 minutes)

- [ ] **Database connectivity confirmed.** Application successfully reads and writes to the target database.
- [ ] **Data integrity check passed.** Record counts match between source and target (for migrated data).
  ```sql
  -- Compare record counts
  SELECT COUNT(*) FROM users;     -- Should match source
  SELECT COUNT(*) FROM orders;    -- Should match source
  SELECT MAX(updated_at) FROM users;  -- Should be recent
  ```
- [ ] **Write operations working.** Test a write operation and verify it persists.

### Post-Cutover Monitoring (T+30 minutes to T+24 hours)

- [ ] **No residual traffic to source.** Source access logs show zero or near-zero traffic (accounting for DNS propagation delay).
- [ ] **Alert thresholds normal.** No alerts firing on target infrastructure.
- [ ] **End-to-end transaction test passed.** Complete a full user flow (signup, login, core action) on the target.

---

## Post-Cutover Checklist

Complete these items after the cutover is verified successful.

### Verification (Day 1-3)

- [ ] **24-hour monitoring clean.** No significant errors or performance degradation for 24 continuous hours.
- [ ] **User reports reviewed.** No user-reported issues related to the migration.
- [ ] **Automated test suite passed.** Full integration/E2E test suite passes against the target.
- [ ] **Performance comparison completed.** Compare source and target metrics (latency, throughput, error rate). Document any differences.

### Decommissioning (Day 3-14)

- [ ] **Source infrastructure marked for decommission.** Do NOT immediately destroy -- keep for rollback safety period.
- [ ] **Cleanup issues created.** Individual issues for each source resource to decommission.
- [ ] **Data retention verified.** If source had data retention requirements, ensure they are met on the target or archived.
- [ ] **Source database set for deletion (with delay).** Schedule source database deletion for 7-14 days after cutover (grace period).
  ```bash
  # AWS RDS: Create final snapshot then schedule deletion
  aws rds create-db-snapshot --db-instance-identifier source-db --db-snapshot-identifier final-pre-migration
  ```
- [ ] **Source resources destroyed.** After the safety period, destroy source infrastructure. Record cost savings.

### Configuration Update

- [ ] **providers.md updated.** Source provider removed or scope updated. Target provider scope updated.
- [ ] **CLAUDE.md updated.** Providers field in `## Arness` reflects the current state.
- [ ] **CI/CD pipelines updated.** Deployment pipelines target the new infrastructure.
- [ ] **Documentation updated.** Architecture docs, runbooks, and operational docs reflect the new setup.

### Cost Verification

- [ ] **Cost comparison completed.** Compare actual costs (first full billing cycle) against the pre-migration estimate.
- [ ] **Source billing stopped.** Confirm no ongoing charges for decommissioned source resources.
- [ ] **Migration issue closed.** Parent migration issue closed with final summary.
  ```markdown
  ## Migration Complete

  **Scenario:** [type]
  **Source:** [provider]
  **Target:** [provider]
  **Duration:** [actual duration]
  **Cost change:** $X/month --> $Y/month (saved $Z/month)
  **Issues encountered:** [brief list or "none"]
  ```

---

## Rollback Decision Matrix

| Condition | Action | Timing |
|-----------|--------|--------|
| Error rate > 10% for 5 minutes after cutover | Immediate rollback | Within 15 min |
| Health checks failing for 3 consecutive checks | Immediate rollback | Within 5 min |
| Data integrity check fails | Rollback + investigate | Within 30 min |
| Latency > 3x baseline for 10 minutes | Assess + likely rollback | Within 30 min |
| Single non-critical feature broken | Document + fix forward | No rollback |
| Intermittent errors < 1% | Monitor closely | No rollback unless escalating |

### Rollback Execution Steps

1. **Revert DNS records** to point to source infrastructure
   ```bash
   # Use the documented pre-cutover DNS records
   ```
2. **Restore source database to read-write** (if it was set to read-only)
   ```sql
   ALTER DATABASE mydb SET default_transaction_read_only = off;
   ```
3. **Verify source is serving traffic** -- check source access logs
4. **Update migration task issue** with `arn-infra-migration-rollback` label
5. **Document the failure** -- what happened, root cause hypothesis, fix needed
6. **Plan retry** -- address the root cause, test in staging, attempt cutover again
