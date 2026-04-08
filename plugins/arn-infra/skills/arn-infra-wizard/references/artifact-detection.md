# Artifact Detection (Resumability)

Check which artifacts exist on disk to determine if the user is resuming a previous pipeline run. Check from most advanced to least advanced -- first match wins:

## Quick Mode Artifact Detection

| Artifact | Detected State | Resume Point |
|----------|---------------|--------------|
| `.arness/infra/monitoring/` exists with config files | Post-monitor | Resume at Q7 (completion) |
| `.arness/infra/environments.md` has per-env IaC sections | Post-env | Resume at Q6 |
| `.github/workflows/deploy*.yml` or `.gitlab-ci.yml` with deploy stages | Post-pipeline | Resume at Q5 |
| `active-resources.json` (from Resource manifest path) has entries | Post-deploy | Resume at Q4 |
| IaC config files exist (`.tf`, `Pulumi.*`, `cdk.json`, `*.bicep`, PaaS configs) | Post-define | Resume at Q3 |
| `Dockerfile` or `docker-compose.*` exists | Post-containerize | Resume at Q2 |
| `tooling-manifest.json` (from Tooling manifest path) exists | Post-discover | Resume at Q1.5 |
| `## Arness` exists but no infra artifacts | Initialized only | Begin at discover |

**Note:** This artifact detection table applies to Quick mode Fresh/Resume only. Triage-driven and assessment-driven entry modes do not support mid-step resumability -- if interrupted, they restart from their respective entry points (triage or assess). Full Pipeline mode has its own artifact detection (see Entry Mode 5: Change Pipeline).

## Full Pipeline Artifact Detection

Scan for existing pipeline artifacts to determine current pipeline position:

| Artifact | Detected State | Resume Point |
|----------|---------------|--------------|
| `.arness/infra-docs/` contains runbooks or changelogs for this change | Post-document | Pipeline complete (P6 done) |
| Review report exists in `.arness/infra-plans/` for this change | Post-review | Resume at P6 (document) |
| `PROGRESS_TRACKER.json` shows execution progress | Mid-execute | Resume at P4 (execute) |
| Structured plan directory exists in `.arness/infra-plans/` | Post-save | Resume at P4 (execute) |
| `PLAN_PREVIEW_INFRA_*.md` exists in `.arness/infra-plans/` | Post-plan | Resume at P3 (save-plan) |
| `INFRA_CHANGE_*.md` exists in `.arness/infra-specs/` | Post-spec | Resume at P2 (change-plan) |
| No pipeline artifacts | Fresh pipeline | Start at P1 (change-spec) |

If artifacts are detected, inform the user: "I found an in-progress change pipeline at [detected stage]. Resuming from [next stage]."

If no artifacts detected, start at P1 (change-spec).
