# Arness Infra Labels

14 labels for infrastructure issue lifecycle tracking. Created during `arn-infra-init` Step 8 via `gh label create --force` (GitHub) or implicitly (Jira).

---

## Label Definitions

| Label | Color | Description | Set by | Lifecycle Stage |
|-------|-------|-------------|--------|-----------------|
| `arn-infra-request` | `1d76db` | New infrastructure request from application development | Arness Core (cross-plugin issue creation) | Entry point |
| `arn-infra-in-progress` | `fbca04` | Infrastructure work underway -- triaged and being implemented | `arn-infra-triage` | Active work |
| `arn-infra-staging` | `0e8a16` | Deployed to staging environment | `arn-infra-deploy` | Staged |
| `arn-infra-production` | `5319e7` | Deployed to production environment | `arn-infra-deploy` (promotion) | Live |
| `arn-infra-verified` | `0e8a16` | Post-deployment verification passed | `arn-infra-verify` | Verified |
| `arn-infra-failed` | `d93f0b` | Deployment or verification failed | `arn-infra-deploy` / `arn-infra-verify` | Failed |
| `arn-infra-cleanup` | `e4e669` | TTL expired, resources need cleanup | `arn-infra-deploy` (TTL set) | Cleanup |
| `arn-infra-deferred` | `bfdadc` | Deferred infrastructure note accumulated during development | Arness Core (deferred mode) | Deferred |
| `arn-infra-migration` | `c5def5` | Migration parent issue (epic) | `arn-infra-migrate` | Migration |
| `arn-infra-migration-task` | `d4c5f9` | Individual migration step | `arn-infra-migrate` | Migration |
| `arn-infra-migration-ready` | `0e8a16` | Migration step verified, ready for cutover | `arn-infra-verify` | Migration |
| `arn-infra-migration-cutover` | `fbca04` | Cutover in progress | `arn-infra-migrate` | Migration |
| `arn-infra-migration-rollback` | `d93f0b` | Migration step rolled back | `arn-infra-migrate` | Migration |
| `arn-infra-backlog` | `c2e0c6` | Infrastructure backlog item from assessment | `arn-infra-assess` | Backlog |

---

## Standard Issue Lifecycle

```
[arn-infra-request] --> triage --> [arn-infra-in-progress]
  --> deploy (staging) --> [arn-infra-staging]
  --> verify --> [arn-infra-verified] or [arn-infra-failed]
  --> deploy (promote to prod) --> [arn-infra-production]
  --> verify --> [arn-infra-verified] --> close issue
```

### Label Transitions

1. **New request:** Issue created with `arn-infra-request` label (by Arness Core or manually)
2. **Triage:** `arn-infra-triage` removes `arn-infra-request`, adds `arn-infra-in-progress`
3. **Staging deploy:** `arn-infra-deploy` removes `arn-infra-in-progress`, adds `arn-infra-staging`
4. **Staging verify:** `arn-infra-verify` adds `arn-infra-verified` (or `arn-infra-failed` on failure)
5. **Production promote:** `arn-infra-deploy` removes `arn-infra-staging`, adds `arn-infra-production`
6. **Production verify:** `arn-infra-verify` confirms `arn-infra-verified`, issue is closed
7. **Failure at any stage:** `arn-infra-failed` is added; previous stage label may remain for context

---

## Migration Issue Lifecycle

```
[arn-infra-migration] parent issue created
  --> [arn-infra-migration-task] individual steps created
  --> steps: in-progress --> staging --> verified --> [arn-infra-migration-ready]
  --> all steps ready --> [arn-infra-migration-cutover] (DNS swap, traffic shift)
  --> cutover verified --> [arn-infra-production] --> close parent issue
  --> old resources --> [arn-infra-cleanup] issues created automatically
```

### Migration Label Transitions

1. **Migration initiated:** Parent issue with `arn-infra-migration` label
2. **Steps created:** Child issues with `arn-infra-migration-task` label
3. **Step verified:** `arn-infra-migration-ready` replaces `arn-infra-migration-task`
4. **All ready:** Parent gets `arn-infra-migration-cutover` for the cutover phase
5. **Cutover complete:** Parent gets `arn-infra-production`, old resources get `arn-infra-cleanup`
6. **Rollback:** If cutover fails, affected steps get `arn-infra-migration-rollback`

---

## Deferred and Backlog Labels

- **`arn-infra-deferred`:** Used when Arness Core detects `Deferred: yes` in `## Arness` config. Instead of creating full infra request issues, Core creates lightweight deferred notes with this label. These are collected by `arn-infra-assess` when un-deferring.

- **`arn-infra-backlog`:** Used by `arn-infra-assess` when publishing the prioritized infrastructure backlog. Each backlog item becomes an issue with this label and structured content from `backlog-item-template.md`.

---

## GitHub Label Creation Commands

```bash
gh label create "arn-infra-request" --color "1d76db" --description "New infrastructure request" --force
gh label create "arn-infra-in-progress" --color "fbca04" --description "Infrastructure work underway" --force
gh label create "arn-infra-staging" --color "0e8a16" --description "Deployed to staging" --force
gh label create "arn-infra-production" --color "5319e7" --description "Deployed to production" --force
gh label create "arn-infra-verified" --color "0e8a16" --description "Post-deploy verification passed" --force
gh label create "arn-infra-failed" --color "d93f0b" --description "Deployment or verification failed" --force
gh label create "arn-infra-cleanup" --color "e4e669" --description "TTL expired, resources need cleanup" --force
gh label create "arn-infra-deferred" --color "bfdadc" --description "Deferred infrastructure note" --force
gh label create "arn-infra-migration" --color "c5def5" --description "Migration parent issue" --force
gh label create "arn-infra-migration-task" --color "d4c5f9" --description "Individual migration step" --force
gh label create "arn-infra-migration-ready" --color "0e8a16" --description "Migration step ready for cutover" --force
gh label create "arn-infra-migration-cutover" --color "fbca04" --description "Cutover in progress" --force
gh label create "arn-infra-migration-rollback" --color "d93f0b" --description "Migration step rolled back" --force
gh label create "arn-infra-backlog" --color "c2e0c6" --description "Infrastructure backlog item" --force
```

All commands use `--force` to make them idempotent -- existing labels are updated rather than duplicated.
