---
name: arn-infra-init
description: >-
  Optional customization tool for infrastructure projects. This skill should be used when the user says
  "infra init", "arn infra init", "initialize infra", "setup infrastructure", "arn-infra-init",
  "configure infra", "init infra", "infrastructure setup", "set up infrastructure", "infra setup",
  "start infra", "configure arn infra", "add infrastructure to this project",
  "review infra config", "customize infra config", "infra settings",
  or wants to configure providers, environments, IaC tools, CI/CD platform, or review
  current infrastructure settings. Arness Infra auto-configures with sensible defaults on first
  skill invocation — this init is optional for basic usage but required for provider/environment
  configuration.
version: 1.0.0
---

# Arness Infra Init

Configure the Arness Infra plugin for a project by selecting cloud providers and IaC tools, establishing environment strategy, and persisting configuration to CLAUDE.md. This is optional — Arness Infra auto-configures with sensible defaults on first skill invocation. Use this to configure providers, environments, IaC tools, CI/CD platform, or review your current settings.

This skill does NOT require Arness Core. It writes infra configuration fields into the shared `## Arness` section in CLAUDE.md, preserving any existing fields from arn-code or arn-spark. If no `## Arness` section exists, it creates one.

The infra configuration written by this skill contains up to 25 fields that govern the behavior of all downstream infrastructure skills and agents. The configuration is expertise-adaptive: experience level is derived from your user profile (set during first Arness skill invocation) and governs conversational tone and recommendations. Beginner users get opinionated PaaS recommendations, while expert users have full control over provider and IaC tool selection.

> **Note:** Experience level is now derived from your user profile and is no longer stored in `## Arness` config. The derivation mapping is at `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-ensure-config/references/experience-derivation.md`. If no profile exists when init runs, the welcome flow in ensure-config runs first to create one.

## Workflow

### Step 0: Existing Infrastructure Detection

Before any user interaction, scan the project for existing infrastructure artifacts.

> Read the local override or plugin default for `existing-infra-detection.md`.

Scan for:
- **IaC files:** `*.tf`, `*.hcl`, `Pulumi.*`, `cdk.json`, `*.bicep`
- **Container configs:** `Dockerfile`, `docker-compose.*`, `.dockerignore`
- **CI/CD pipelines:** `.github/workflows/`, `.gitlab-ci.yml`, `bitbucket-pipelines.yml`
- **Platform configs:** `fly.toml`, `railway.json`, `vercel.json`, `render.yaml`, `netlify.toml`
- **Kubernetes:** `kubernetes/`, `k8s/`, `helm/`, `Chart.yaml`
- **Cloud-specific:** `.aws/`, `gcloud/`, `azure/`

**If existing infrastructure is detected:**
Present findings: "I found existing infrastructure in this project: [list detected artifacts]. I can adopt and manage these within Arness Infra."
Infer provider and IaC tool from detected artifacts (e.g., `.tf` files imply OpenTofu/Terraform, `fly.toml` implies Fly.io) and pre-populate the config suggestions in subsequent steps.

**If no infrastructure is detected:**
Continue to Step 1 normally.

---

### Step 1: Check Prerequisites and Existing Configuration

Read the project's CLAUDE.md.

**Check for `## Arness` section:**
- If `## Arness` section exists: read it and extract all fields. Note which fields are from other plugins (Plans directory, Specs directory, etc. from arn-code; Vision directory, etc. from arn-spark) -- these will be preserved when writing infra fields.
- If `## Arness` section does NOT exist: this is a standalone infra project. A new `## Arness` section will be created in Step 8.

**Check for existing infra configuration within `## Arness`:**

Check for any infra-specific field within `## Arness` (such as `Deferred`, `Project topology`, `Providers`, or `Infra plans directory`) -- these fields are only written by infra-init or infra-ensure-config and their presence indicates infra has been initialized. Note: the `Experience level` field is no longer used as the indicator since it has been removed from `## Arness` config.

**If infra fields do not exist (fresh init):**
- Proceed to Step 1b

**If infra fields exist:**
1. Parse all infra config fields from the `## Arness` section
2. Show the user their current configuration
3. Ask (using `AskUserQuestion`):

   **"What would you like to do with your existing configuration?"**

   Options:
   1. **Review** -- Show current configuration summary, no changes
   2. **Update** -- Check for missing fields and fill them in
   3. **Reconfigure** -- Re-run the full setup flow from scratch
   4. **Keep** -- No changes
- If **Review** --> display a clean summary of all `## Arness` fields relevant to Arness Infra, then exit the skill
- If **Keep** --> done, exit the skill
- If **Reconfigure** --> continue to Step 1b, pre-filling known values as defaults
- If **Update** --> check which fields are missing and only process those. Preserve all existing fields. Run Step U1 (Reference Upgrade) to check for reference version changes. Then proceed to Step 8 to write the updated config.

---

### Step 1b: Timing and Deferral

Before any configuration:

Ask (using `AskUserQuestion`):

**"When do you want to set up infrastructure?"**

Options:
1. **Now** -- Configure providers and start the infrastructure workflow
2. **Later** -- Create a minimal config and defer infrastructure planning. Arness will accumulate infrastructure notes as you build features.

**If deferred:**
- Derive experience level from user profile (Step 2) and ask Step 4 (topology) only
- Write (or append to existing `## Arness`) minimal infra config with: `Deferred: yes`, `Project topology`, `Application path` (if applicable)
- Create `.arness/infra/` directory: `mkdir -p .arness/infra`
- Create `.arness/infra/deferred-backlog.md` with empty structure:
  ```markdown
  # Deferred Infrastructure Backlog

  Infrastructure observations accumulated during feature development.
  Run `/arn-infra-assess` when ready to produce a full infrastructure plan.
  ```
- Present: "Infrastructure is deferred. As you build features with Arness Core, infrastructure observations will accumulate in `.arness/infra/deferred-backlog.md`. When ready, run `/arn-infra-assess` to produce a full infrastructure plan from the accumulated notes."
- Stop init here.

**If now:** Continue to Step 2.

---

### Step 2: Derive Experience Level from User Profile

Experience level governs conversational tone and recommendations throughout the init flow. Instead of asking the user directly, derive the experience level from the user profile.

1. Read the user profile from `~/.arness/user-profile.yaml` or `.claude/arness-profile.local.md` (project override takes precedence)
2. If no user profile exists, run the welcome flow first by reading `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-ensure-config/references/ensure-config.md` -- the welcome flow creates the profile
3. Apply the experience derivation mapping at `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-ensure-config/references/experience-derivation.md` to determine the infrastructure experience level (expert, intermediate, or beginner)
4. If the derivation is ambiguous (the mapping indicates a follow-up is needed), ask one focused question: "For infrastructure specifically, would you say expert, intermediate, or beginner?"
5. Use the derived experience level for all subsequent steps (provider recommendations, cost threshold defaults, etc.)

> **Note:** Experience level is no longer stored in `## Arness` config. It is derived at runtime from the user profile. For backward compatibility, if a legacy `Experience level` field exists in `## Arness` and no user profile exists, use the legacy value.

---

### Step 3: Provider Configuration (Multi-Provider Aware)

> Read the local override or plugin default for `provider-overview.md`.
> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-init/references/recommendation-matrix.md` for expertise-adaptive recommendations. *(Static reference -- not part of the evolving reference set.)*
> Read the local override or plugin default for `iac-tool-guide.md`.

Adapt the conversation based on experience level:

**Expert:**
"What cloud providers do you use? (You can specify multiple with their scope, e.g., 'AWS for backend, Vercel for frontend')"
Then: "What IaC tool do you prefer?" -- present all options, let them choose freely. Set as default IaC tool. Per-provider overrides added to `providers.md`.
If they say Terraform, warn about BSL licensing and recommend OpenTofu as a drop-in replacement.

**Intermediate:**
Analyze the application stack from codebase patterns (if available from `## Arness` config). Present 2-3 recommended provider/IaC combinations with trade-offs:
"Based on your application stack, I'd recommend [provider(s)] with [IaC tool]. Here's why: [rationale]."
For multi-component apps (frontend + API + DB), suggest appropriate provider split.

**Beginner:**
Analyze the application stack and make an opinionated recommendation:
"For your application, I'd recommend deploying to [Fly.io / Railway / Render / Vercel] -- these platforms handle most infrastructure complexity for you."
Set IaC tool to `none` (platform-native configs will be used). Warning: "You are responsible for understanding your provider's pricing model."

For each provider selected:
- Record: provider name, scope (which app components), IaC tool (or default), status (active)

---

### Step 4: Project Topology and Application Linking

Ask (using `AskUserQuestion`):

**"Where does your application code live?"**

Options:
1. **Here** -- application and infrastructure are in this repository (monorepo)
2. **Separate location** -- infrastructure is here, application is in another repo/folder
3. **No application** -- this is a standalone infrastructure project

**Option 1 (monorepo):** Set `Project topology: monorepo`, `Application path: .`

**Option 2 (separate repo):**
Ask for the application path. Validate the path exists. Check for `## Arness` section in the app's CLAUDE.md.
Set `Project topology: separate-repo`, `Application path: <provided-path>`.
Offer to add the reverse pointer:
"I'd like to add an `Infrastructure` field to your application's `## Arness` config at `<app-path>/CLAUDE.md` so Arness Core knows where infrastructure lives. This enables automatic infra issue creation when features need infrastructure changes. OK?"
If approved, add `- **Infrastructure:** <relative-path-to-infra>` to the app's `## Arness` section.

**Option 3 (infra-only):** Set `Project topology: infra-only`. Omit `Application path`.

---

### Step 5: Platform and Issue Tracker Detection

Auto-detect the infra project's own Git, Platform, and Issue tracker. This follows the same detection logic as Arness Core's `arn-code-init` Step 3 but runs independently for the infra project (in separate-repo topology, the infra repo may have different git remotes and issue trackers than the app repo).

**5.1. Git check:**
1. Run `git rev-parse --is-inside-work-tree`
2. If Git is not detected: record Git: no, Platform: none, Issue tracker: none.

**5.2. Remote classification:**
1. Run `git remote -v` and classify:
   - Contains `github.com` --> candidate: **github**
   - Contains `bitbucket.org` --> candidate: **bitbucket**
   - Neither --> Platform: none, Issue tracker: none

**5.3a. If candidate is github:**
1. Run `gh auth status` to check authentication
2. If authenticated --> Platform: **github**, Issue tracker: **github**
3. If NOT authenticated --> warn the user, suggest `gh auth login`, and **STOP init**

**5.3b. If candidate is bitbucket:**
1. Run `bkt --version` to check for the Bitbucket CLI
   - If NOT available --> show setup instructions, **STOP init**
2. Run `bkt auth status` to check authentication
   - If NOT authenticated --> show auth instructions, **STOP init**
3. Platform: **bitbucket**
4. Ask: "Do you use Jira for issue tracking on this project?"
   - **YES** --> verify Jira MCP availability, select project. Record Issue tracker: **jira**, Jira site, Jira project.
   - **NO** --> Issue tracker: **none**

**5.4. CI/CD Platform Detection:**

Scan the project for CI/CD configuration files to determine which CI/CD system is in use. This is independent of the code hosting Platform — a GitHub-hosted project can use GitLab CI.

1. Check for `.github/workflows/` directory with `.yml`/`.yaml` files --> CI/CD platform: **github-actions**
2. Check for `.gitlab-ci.yml` --> CI/CD platform: **gitlab-ci**
3. Check for `bitbucket-pipelines.yml` --> CI/CD platform: **bitbucket-pipelines**
4. If multiple detected, ask the user which is primary
5. If none detected --> CI/CD platform: **none**

Record the result as `CI/CD platform: github-actions | gitlab-ci | bitbucket-pipelines | none`.

---

### Step 6: Environment Strategy

Ask (using `AskUserQuestion`):

**"How do you want to manage environments?"**

Options:
1. **Staging + Production** (recommended) -- Changes deploy to staging first, promote to prod when ready
2. **Dev + Staging + Production** -- Three-stage pipeline with a development environment
3. **Production only** -- Direct to production (not recommended -- no safety net for testing infrastructure changes)
4. **Custom** -- Define your own stages

**Option 3 gets a warning:** "Deploying directly to production means infrastructure mistakes affect live users immediately. There is no staging environment to test changes first. Are you sure?" Requires explicit confirmation.

**Option 4:** Ask the user to list their environment names in promotion order (e.g., "dev, qa, staging, prod").

Create `.arness/infra/environments.md` with the chosen pipeline. Each environment entry includes:
- Auto-deploy flag
- Approval required flag
- Last deployed timestamp (initially `--`)
- Pending changes (initially `none`)

---

### Step 7: Remaining Configuration

Ask:

**7.1. Cost threshold:**
"What is your monthly infrastructure budget limit? Arness will warn before deployments that would exceed this threshold."
- Suggest a default based on experience level: beginner ($25), intermediate ($100), expert ($500)
- Accept any USD amount or "none" to disable

**7.2. Validation ceiling:**
"What is the maximum validation level Arness should perform without asking for explicit approval? (0 = syntax only, 1 = dry run, 2 = security scan, 3 = cost estimate, 4 = full apply)"
- Default: 2 (security scan)
- Expert users may prefer higher; beginners should keep it low

---

### Step 8: Create Infrastructure Files and Write Configuration

1. Create infrastructure directory structure:
   ```bash
   mkdir -p .arness/infra
   mkdir -p .arness/infra-plans
   mkdir -p .arness/infra-specs
   mkdir -p .arness/infra-docs
   mkdir -p .arness/infra-templates
   ```

2. Create `.arness/infra/providers.md` with provider entries from Step 3:
   ```markdown
   # Providers

   ## [provider-name]
   - **Scope:** [components this provider handles]
   - **IaC tool:** [tool or "none"]
   - **Confidence:** -- (set by arn-infra-discover)
   - **Status:** active
   - **Migration:** none
   ```

3. Create `.arness/infra/environments.md` with environment config from Step 6:
   ```markdown
   # Environments

   ## Promotion Pipeline
   [env1] --> [env2] --> [env3]

   ## [environment-name]
   - **Auto-deploy:** [yes | no]
   - **Approval required:** [yes | no]
   - **Last deployed:** --
   - **Pending changes:** none
   ```

4. Create the Arness Infra labels defined in the reference file (if Platform is github or Issue tracker is jira).

   > Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-init/references/infra-labels.md` for the full label list with colors and descriptions.

   For GitHub: use `gh label create --force` for each label (idempotent).
   For Jira: labels are implicit (no creation needed).
   If no issue tracker: skip label creation.

5. Write infra configuration fields to the `## Arness` section in CLAUDE.md.

   > Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-init/references/config-schema.md` for the full field documentation.

   The following infra fields are written to `## Arness`:

   ```markdown
   - **Deferred:** no
   - **Project topology:** [monorepo | separate-repo | infra-only]
   - **Application path:** [path] (omitted for infra-only)
   - **Providers:** [comma-separated list]
   - **Providers config:** .arness/infra/providers.md
   - **Default IaC tool:** [tool or "none"]
   - **Environments:** [comma-separated in promotion order]
   - **Environments config:** .arness/infra/environments.md
   - **Tooling manifest:** .arness/infra/tooling-manifest.json
   - **Resource manifest:** .arness/infra/active-resources.json
   - **Cost threshold:** [USD amount or "none"]
   - **Validation ceiling:** [0-4]
   - **Infra plans directory:** .arness/infra-plans
   - **Infra specs directory:** .arness/infra-specs
   - **Infra docs directory:** .arness/infra-docs
   - **Infra report templates:** default
   - **Infra template path:** .arness/infra-templates
   - **Infra template version:** <version from plugin.json>
   - **Git:** [yes | no]
   - **Platform:** [github | bitbucket | none]
   - **CI/CD platform:** [github-actions | gitlab-ci | bitbucket-pipelines | none]
   - **Issue tracker:** [github | jira | none]
   - **Jira site:** [site] (only if Issue tracker is jira)
   - **Jira project:** [key] (only if Issue tracker is jira)
   - **Reference overrides:** .arness/infra-references
   - **Reference version:** <version from plugin.json>
   - **Reference updates:** ask | auto | manual
   ```

   > **Note:** Experience level is no longer written to `## Arness`. It is derived at runtime from the user profile. If a legacy `Experience level` field exists in `## Arness`, it may be removed during the next upgrade cycle.

   **Rules:**
   - All paths MUST be relative to the project root. Never use absolute paths.
   - Jira site and Jira project fields are only written when Issue tracker is jira.
   - **If `## Arness` already exists** (monorepo with arn-code/green): Append infra fields to the existing section. Skip shared fields (Git, Platform, Issue tracker, Jira site, Jira project) that are already present. Preserve all existing fields not managed by this skill (Plans directory, Specs directory, Report templates, Template path, Template version, Template updates, Code patterns, Docs directory, Vision directory, Use cases directory, Prototypes directory, etc.).
   - **If `## Arness` does not exist** (separate-repo or infra-only): Create a new `## Arness` section with all infra fields including shared fields.
   - If updating an existing config that has infra fields (re-running), replace only the infra fields listed above. Do not duplicate them.

---

### Step 8b: Initialize Reference Overrides

Set up locally-owned copies of the 28 evolving reference files so they survive plugin updates and can be refreshed via online research. This step creates the overrides directory, copies files from the plugin, generates SHA-256 checksums, and asks the user for their Reference updates preference.

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-init/references/reference-override-protocol.md` (Step 8b section) for the full initialization procedure (sub-steps 8b.1 through 8b.6).

---

### Step 9: Verify and Summarize

Confirm with the user:

- [ ] Existing infrastructure detected and acknowledged (if any)
- [ ] Experience level derived from user profile: [level]
- [ ] Provider(s) configured: [list]
- [ ] Default IaC tool set: [tool]
- [ ] Project topology established: [topology]
- [ ] Application linking completed (if applicable)
- [ ] Git detected: [yes | no]
- [ ] Platform detected: [platform]
- [ ] Issue tracker configured: [tracker]
- [ ] Environment strategy set: [environments]
- [ ] Cost threshold set: [$amount]
- [ ] Validation ceiling set: [level]
- [ ] Arness Infra labels created (if issue tracker available)
- [ ] `.arness/infra/providers.md` created
- [ ] `.arness/infra/environments.md` created
- [ ] `.arness/infra-plans/` created
- [ ] `.arness/infra-specs/` created
- [ ] `.arness/infra-docs/` created
- [ ] `.arness/infra-templates/` created
- [ ] `.arness/infra-references/` created with 28 evolving reference files
- [ ] `.arness/infra-references/.reference-checksums.json` generated
- [ ] Reference updates preference recorded
- [ ] Infra fields written to `## Arness` section in CLAUDE.md

List all created/modified files with their paths.

**Next steps:**

"Arness Infra is configured. Here is the recommended next step:

1. **Discover tools:** Run `/arn-infra-discover` to audit your installed tools, MCPs, CLIs, and configure provider access.

After discovery, the infrastructure pipeline continues:
2. **Containerize:** Run `/arn-infra-containerize` to generate Docker configurations
3. **Define infrastructure:** Run `/arn-infra-define` to generate IaC in your chosen tool
4. **Deploy:** Run `/arn-infra-deploy` to deploy to your environments
5. **Verify:** Run `/arn-infra-verify` to validate your deployment

Or run `/arn-infra-wizard` for the full guided pipeline."

---

## Update Flow: Reference Upgrade

### Step U1: Reference Upgrade

This step runs during the Update flow (from Step 1) to check whether reference files need upgrading after a plugin update. It compares version numbers, performs checksum-based conflict detection on all 28 files, and applies updates based on the user's `Reference updates` preference (ask, auto, or manual).

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-init/references/reference-override-protocol.md` (Step U1 section) for the full upgrade procedure (sub-steps U1.1 through U1.4).

---

## Error Handling

- **No existing `## Arness` section:** This is expected for standalone or separate-repo usage. A new `## Arness` section will be created with infra fields.
- **User cancels at any step:** Confirm cancellation and exit gracefully. Do not leave partially written configuration.
- **Writing to CLAUDE.md fails:** Print the infra config fields in the conversation so the user can insert them manually. Suggest checking file permissions.
- **`gh auth login` not resolved:** Explain the issue and stop init. The user must resolve authentication before proceeding. They can re-run `/arn-infra-init` after fixing auth.
- **Application path unreachable (separate-repo):** Warn that cross-project features will be limited. Still allow init to proceed with the path recorded -- the user can fix the path later.
- **Reference checksums missing or corrupt:** If `.reference-checksums.json` is missing or unparseable during upgrade, treat all files as unmodified and re-initialize from plugin defaults. Regenerate the checksums file.
- **Reference overrides directory missing:** If the Reference overrides directory does not exist during upgrade, run Step 8b (Initialize Reference Overrides) as a fresh setup.
- **Re-running is safe:** Step 1 detects the existing config and offers Update / Reconfigure / Keep. No data is lost on re-run.
- **Deferred mode re-init:** If the user previously deferred and re-runs init, the existing deferred backlog is preserved. The skill offers to continue in deferred mode or switch to full configuration.
