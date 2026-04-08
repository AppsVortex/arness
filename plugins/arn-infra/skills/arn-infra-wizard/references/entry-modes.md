# Entry Mode Detection

Complete entry mode detection rules for the arn-infra-wizard. After mode selection (Quick or Full Pipeline), the wizard checks these conditions from most specific to least specific -- first match wins.

---

## Quick Mode Entry Modes

| Condition | Entry Mode | Starting Point |
|-----------|-----------|----------------|
| User explicitly says "migrate" or "migration" | **Migration** | Invoke migrate directly |
| `Deferred: yes` in config, or user says "assess" | **Assessment-driven** | Start with assess, then continue from define |
| Pending `arn-infra-request` issues detected in issue tracker | **Triage-driven** | Start with triage, then continue from define |
| Default (none of the above) | **Fresh/Resume** | Standard pipeline from init through monitor |

### Entry Mode 1: Fresh/Resume (Default)

Standard 10-step pipeline:
1. init (already done -- verify config)
2. discover
3. containerize
4. define
5. deploy
6. verify
7. pipeline
8. env
9. secrets
10. monitor

### Entry Mode 2: Triage-Driven

Detected when pending `arn-infra-request` issues exist in the issue tracker. Query issues:
- GitHub: `gh issue list --label "arn-infra-request" --state open --json number,title`
- Jira: query for issues with the `arn-infra-request` label

If pending issues found, inform the user: "I found [N] pending infrastructure request(s). Starting with triage to process these, then continuing with infrastructure definition."

Pipeline: triage --> define --> deploy --> verify --> pipeline --> env --> secrets --> monitor

> `Skill: arn-infra:arn-infra-triage`

When triage completes, proceed to Step 4 (Define).

### Entry Mode 3: Assessment-Driven

Detected when `Deferred: yes` is in the config, or the user explicitly requests an assessment.

Inform the user: "Infrastructure was deferred. Starting with a full assessment to produce an infrastructure plan from your accumulated backlog."

Pipeline: assess --> (process backlog items) --> define --> deploy --> verify --> pipeline --> env --> secrets --> monitor

> `Skill: arn-infra:arn-infra-assess`

When assess completes and the user has selected backlog items to implement, proceed to Step 4 (Define).

### Entry Mode 4: Migration

Detected when the user explicitly mentions migration.

Inform the user: "Starting infrastructure migration wizard. The migrate skill has its own lifecycle tracking."

> `Skill: arn-infra:arn-infra-migrate`

After migration completes, ask: "Migration complete. Would you like to continue with verification and the rest of the pipeline (verify, pipeline, env, secrets, monitor)?"

If yes: continue from verify step. If no: show completion summary and exit.

---

## Full Pipeline Mode Entry Modes

| Condition | Entry Mode | Starting Point |
|-----------|-----------|----------------|
| User says "change pipeline", "full pipeline", "structured change", or pipeline artifacts exist in `.arness/infra-specs/` or `.arness/infra-plans/` | **Change Pipeline** | Detect progress from pipeline artifacts and resume at the appropriate stage |
| Default (no existing pipeline artifacts) | **New Pipeline** | Start at change-spec (P1) |

### Entry Mode 5: Change Pipeline (Full Pipeline Mode)

Detected when the user selected Full Pipeline mode and either:
- Explicitly says "change pipeline", "full pipeline", or "structured change"
- Pipeline artifacts exist in `.arness/infra-specs/` or `.arness/infra-plans/`

Scan for existing pipeline artifacts to determine current pipeline position.

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-wizard/references/artifact-detection.md` (Full Pipeline Artifact Detection section) for the complete detection table.

If artifacts are detected, inform the user: "I found an in-progress change pipeline at [detected stage]. Resuming from [next stage]."

If no artifacts detected, start at P1 (change-spec).

### Entry Mode 6: New Pipeline (Full Pipeline Mode)

Default for Full Pipeline mode when no existing pipeline artifacts are detected.

Pipeline: change-spec --> change-plan --> save-plan --> execute-change --> review-change --> document-change

Start at P1 (change-spec).
