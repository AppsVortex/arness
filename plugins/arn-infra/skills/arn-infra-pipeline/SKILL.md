---
name: arn-infra-pipeline
description: >-
  This skill should be used when the user says "infra pipeline", "arn infra pipeline",
  "create CI/CD pipeline", "set up deployment pipeline", "generate pipeline",
  "infra CI/CD", "deployment pipeline", "setup cicd", "generate github actions",
  "generate gitlab ci", "generate bitbucket pipeline", "infrastructure pipeline", "pipeline setup",
  "create deployment workflow", "cicd for infrastructure", "infra deployment pipeline",
  "set up infrastructure CI/CD", "arn-infra-pipeline", or wants to generate
  infrastructure-specific CI/CD pipelines with SOC 2 alignment, OIDC authentication,
  and environment-aware deployment stages.
version: 1.0.0
---

# Arness Infra Pipeline

Generate infrastructure-specific CI/CD pipelines (separate from application CI/CD) with SOC 2 alignment. This skill produces four pipeline jobs: PR validation, staging deployment, production promotion, and scheduled cleanup. It detects existing CI configurations from arn-spark and extends rather than replaces them.

The generated pipelines implement security best practices: OIDC authentication for cloud providers (no static credentials), separate IAM roles per environment, plan-as-artifact audit trails, and branch protection enforcement.

## Prerequisites

Read `## Arness` from the project's CLAUDE.md. If no `## Arness` section exists or Arness Infra fields are missing, inform the user: "Arness Infra is not configured for this project yet. Run `/arn-infra-wizard` to get started — it will set everything up automatically." Do not proceed without it.

Check the **Deferred** field. If `Deferred: yes`, inform the user: "Infrastructure is in deferred mode. CI/CD pipeline setup is not available until infrastructure is fully configured. Run `/arn-infra-assess` to un-defer." Stop.

Extract:
- **Experience level** -- derived from user profile. Read `~/.arness/user-profile.yaml` (or `.claude/arness-profile.local.md` if it exists — project override takes precedence). Apply the experience derivation mapping from `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-ensure-config/references/experience-derivation.md`. If no profile exists, check for legacy `Experience level` in `## Arness` as fallback.
- **Platform** -- code hosting platform (github, bitbucket, none)
- **Providers** -- cloud providers in use
- **Providers config** -- path to `providers.md` for per-provider IaC tool details
- **Default IaC tool** -- the default IaC tool
- **Environments** -- environment names in promotion order
- **Environments config** -- path to `environments.md` for promotion rules
- **Tooling manifest** -- path to `tooling-manifest.json` for available tools
- **Validation ceiling** -- maximum validation level
- **Issue tracker** -- for scheduled cleanup job notifications

Extract the **CI/CD platform** field from `## Arness` config. If not present, auto-detect by scanning for `.github/workflows/`, `.gitlab-ci.yml`, or `bitbucket-pipelines.yml`.

---

## Workflow

### Step 1: Read Provider, Environment, and Tooling Configuration

Read the provider configuration:

```
Read <providers-config-path>
```

For each provider, extract:
- Provider name, scope, IaC tool
- Status (skip providers with `Status: inactive`)

Read the environment configuration:

```
Read <environments-config-path>
```

Extract:
- Promotion pipeline order (e.g., dev --> staging --> prod)
- Auto-deploy flags per environment
- Approval requirements per environment

Read the tooling manifest:

```
Read <tooling-manifest-path>
```

Check for available CI/CD-relevant tools:
- IaC CLIs (tofu, terraform, pulumi, cdk, bicep)
- Security scanners (checkov, trivy)
- Cost estimation (infracost)

---

### Step 2: Detect Existing CI/CD

Scan for existing pipeline configurations:

```
Glob .github/workflows/*.yml
Glob .github/workflows/*.yaml
Glob .gitlab-ci.yml
Glob bitbucket-pipelines.yml
```

**If existing CI/CD is found:**
Read and understand the existing pipeline structure. Present findings: "I found existing CI/CD pipelines: [list files]. Infrastructure pipelines will be generated as separate workflow files to extend, not replace, your existing setup."

**If no existing CI/CD is found:**
Note: "No existing CI/CD detected. Generating infrastructure pipelines from scratch."

---

### Step 3: Determine Pipeline Platform and Load Patterns

Based on the `CI/CD platform` from `## Arness` config (auto-detected from CI config files, independent of the code hosting Platform):

| CI/CD Platform | Reference |
|----------------|-----------|
| `github-actions` | Read the local override or plugin default for `github-actions-patterns.md`. |
| `gitlab-ci` | Read the local override or plugin default for `gitlab-ci-patterns.md`. |
| `bitbucket-pipelines` | Read the local override or plugin default for `bitbucket-pipelines-patterns.md`. |
| `none` | Ask the user which CI/CD platform to target. If no preference, recommend GitHub Actions for GitHub-hosted repos, Bitbucket Pipelines for Bitbucket-hosted repos, or GitLab CI for self-hosted/GitLab-hosted repos. |

Load the security checklist:

> Read the local override or plugin default for `pipeline-security-checklist.md`.

---

### Step 4: Invoke Pipeline Builder Agent

Invoke the `arn-infra-pipeline-builder` agent via the Task tool with:

--- PLATFORM CONTEXT ---
CI/CD platform: [github-actions | gitlab-ci | bitbucket-pipelines]
Existing CI/CD files: [list of detected files, or "none"]
--- END PLATFORM CONTEXT ---

--- PROVIDER CONFIGURATION ---
[For each active provider:]
Provider: [name]
Scope: [components]
IaC tool: [tool]
--- END PROVIDER CONFIGURATION ---

--- ENVIRONMENT CONFIGURATION ---
Environments: [list in promotion order]
Promotion pipeline: [env1 --> env2 --> env3]
[For each environment:]
Environment: [name]
Auto-deploy: [yes | no]
Approval required: [yes | no]
--- END ENVIRONMENT CONFIGURATION ---

--- TOOLING CONTEXT ---
Available security scanners: [checkov, trivy, or "none"]
Available cost tools: [infracost, or "none"]
Validation ceiling: [0-4]
--- END TOOLING CONTEXT ---

--- INSTRUCTIONS ---
Generate infrastructure CI/CD pipeline jobs. The number of jobs depends on the user's experience level:

**Beginner (2-job pipeline):**
1. **PR Validation Job:** Triggers on every PR that modifies IaC files (*.tf, *.hcl, Pulumi.*, cdk.json, *.bicep, kubernetes/). Runs Level 0-1 checks (format, lint, validate). Plan output saved as PR comment.
2. **Deploy Job:** Triggers on merge to main. Applies the validated plan to the target environment.

**Intermediate (3-job pipeline):**
1. **PR Validation Job:** Triggers on every PR that modifies IaC files. Runs Level 0-2 checks (format, lint, validate, security scan if available). Plan output saved as PR comment and artifact.
2. **Staging Deployment Job:** Triggers on merge to main. Applies the exact plan reviewed in the PR. Respects auto-deploy flag from environment config.
3. **Production Promotion Job:** Manual trigger only. Requires approval gate (environment protection rules). Applies from the staging-verified state.

**Expert (4-job pipeline):**
1. **PR Validation Job:** Triggers on every PR that modifies IaC files (*.tf, *.hcl, Pulumi.*, cdk.json, *.bicep, kubernetes/). Runs:
   - Level 0: Static analysis (format check, linting)
   - Level 1: IaC validation (tofu validate, pulumi preview, cdk synth)
   - Level 2: Security scan (Checkov/Trivy if available)
   - Plan output saved as PR comment and artifact for audit trail

2. **Staging Deployment Job:** Triggers on merge to main (or configured branch). Applies the exact plan reviewed in the PR. Respects auto-deploy flag from environment config.

3. **Production Promotion Job:** Manual trigger only. Requires approval gate (environment protection rules). Applies from the staging-verified state.

4. **Scheduled Cleanup Job:** Daily cron that checks for expired TTLs from active-resources.json. Creates issues or sends notifications (does not auto-destroy).

Security requirements (SOC 2 alignment):
- OIDC authentication for cloud providers (AWS, GCP, Azure) -- no static credentials
- Separate IAM roles per environment (staging role cannot access prod)
- Plan output stored as artifacts for audit trail
- Apply only runs the exact plan that was reviewed
- Branch protection rules enforced
- All infra changes require PR review
- Deployment logs retained

If extending existing CI/CD, add infrastructure jobs as new workflow files or new stages. Do not modify existing application CI/CD steps.
--- END INSTRUCTIONS ---

Verify that the pipeline builder agent returned at least one pipeline configuration file. If no files were produced, follow the "Pipeline builder returns empty output" error handling procedure before proceeding.

---

### Step 5: Invoke Security Auditor for Pipeline Review

Invoke the `arn-infra-security-auditor` agent via the Task tool with:

--- FILES TO AUDIT ---
[Generated pipeline configuration files from Step 4]
--- END FILES TO AUDIT ---

--- AUDIT CONTEXT ---
Audit type: CI/CD pipeline security review
Provider(s): [list]
Compliance: SOC 2 alignment
--- END AUDIT CONTEXT ---

--- TOOLING CONTEXT ---
Available security scanners: [checkov | trivy | none -- from tooling manifest]
Available secret scanners: [trufflehog | gitleaks | none -- from tooling manifest]
--- END TOOLING CONTEXT ---

--- INSTRUCTIONS ---
Review the generated pipeline configurations for security issues:
- Secrets exposure in logs or artifacts
- Missing OIDC authentication (static credentials used instead)
- Overly permissive IAM roles for CI runners
- Unpinned action versions or container images
- Missing branch protection enforcement
- Insufficient separation of duties between environments
--- END INSTRUCTIONS ---

**If security issues are found:**
Apply fixes to the generated pipeline before presenting to the user. Note what was changed: "The security auditor found [N] issues. I've applied fixes: [list]."

---

### Step 6: Present Generated Pipeline for Approval

Present each generated pipeline file to the user:

"Here are the generated infrastructure CI/CD pipelines:

**Platform:** [GitHub Actions | GitLab CI | Bitbucket Pipelines]
**Security audit:** [Passed | N issues found and fixed]

[For each file:]
**[filename]:**
```yaml
[generated content]
```

**Jobs included:**
1. PR Validation -- Runs on IaC PRs with Level 0-2 checks
2. Staging Deploy -- Triggers on merge to main
3. Production Promotion -- Manual trigger with approval gate
4. Scheduled Cleanup -- Daily TTL check

**Required setup:**
- [List of secrets/variables to configure in CI/CD settings]
- [OIDC provider configuration steps]
- [Branch protection rule recommendations]

Ask (using `AskUserQuestion`):

**"How would you like to proceed with the generated pipelines?"**

Options:
1. **Approve and write** -- Write all pipeline files to the project
2. **Edit** -- Make changes before writing
3. **Regenerate** -- Adjust the configuration and regenerate

---

### Step 7: Write Files and Summarize

Upon user approval, write generated pipeline files to the appropriate locations:
- GitHub Actions: `.github/workflows/infra-*.yml`
- GitLab CI: `.gitlab-ci-infra.yml` or included files
- Bitbucket: extend `bitbucket-pipelines.yml`

Present the summary:

**Infrastructure Pipeline Summary:**
- **Platform:** [platform]
- **Jobs:** PR validation, staging deploy, prod promotion, scheduled cleanup
- **Files created:** [list with paths]
- **Security audit:** [result]
- **OIDC configured for:** [providers]
- **Environments:** [list with promotion rules]

**Required manual setup:**
1. Configure OIDC trust relationships in [provider(s)]
2. Set up environment protection rules for production
3. Configure the following CI/CD secrets/variables: [list]

**Recommended next steps:**

"Infrastructure CI/CD is ready. Here is the recommended path:

1. **Configure OIDC:** Follow the setup instructions above for [provider] OIDC trust
2. **Set up environments:** Run `/arn-infra-env` to configure environment isolation and promotion
3. **Manage secrets:** Run `/arn-infra-secrets` to set up secrets management for your pipelines
4. **Deploy:** Run `/arn-infra-deploy` to deploy to your first environment

Or run `/arn-infra-wizard` for the full guided pipeline."

---

## Error Handling

- **`## Arness` config missing:** Suggest running `/arn-infra-wizard` to get started. Stop.
- **CI/CD platform is `none`:** Inform the user that no CI/CD platform was detected. Suggest running `/arn-infra-init` to re-detect, or specify a target platform manually. Stop.
- **No providers configured:** Suggest running `/arn-infra-init` to configure providers. Stop.
- **Pipeline builder agent fails:** Report the error. Fall back to generating basic pipeline configurations directly using the loaded reference patterns. Present with a note: "Generated using fallback patterns -- review carefully before use."
- **Pipeline builder returns empty output:** Inform the user and retry with additional context. If retry fails, offer to generate a minimal pipeline template manually.
- **Security auditor fails:** Present the generated pipeline without security review. Warn: "Security audit could not be performed. Review the pipeline manually against the security checklist before committing."
- **Existing CI/CD conflicts:** If the generated pipeline would conflict with existing workflows (duplicate triggers, overlapping jobs), present both and ask the user how to resolve.
- **OIDC not supported for provider:** Fall back to documenting manual secret configuration. Warn: "OIDC is not available for [provider]. Static credentials will be used. Ensure proper rotation and least-privilege access."
- **Re-running is safe:** Re-running regenerates pipeline files (after user approval). Existing infrastructure pipelines are shown in a diff before overwriting. Application CI/CD is never modified.
