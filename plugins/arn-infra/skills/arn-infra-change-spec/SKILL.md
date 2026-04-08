---
name: arn-infra-change-spec
description: >-
  This skill should be used when the user says "infra change spec",
  "infrastructure change", "specify infrastructure change", "change spec",
  "arn infra spec", "describe infra change", "what infrastructure needs to change",
  "infra spec", "spec this infra change", "write infra spec",
  "infrastructure change specification", "create infra change spec",
  "upgrade to pipeline", "convert to pipeline", or wants to iteratively develop
  an infrastructure change idea into a well-formed specification through guided
  conversation, or wants to upgrade existing interactive IaC artifacts into the
  structured change pipeline.
version: 1.0.0
---

# Arness Infra Change Spec

Develop an infrastructure change idea into a well-formed specification through iterative conversation, aided by the `arn-infra-request-analyzer` and `arn-infra-cost-analyst` agents. This is a conversational skill that runs in normal conversation (NOT plan mode). The primary artifact is an **infrastructure change specification** written to the project's infra specs directory that captures affected resources, blast radius, environment scope, rollback requirements, compliance constraints, and cost impact. The spec then informs plan creation via `/arn-infra-change-plan`.

This skill supports two entry paths:
- **Fresh:** Guide the user through an iterative conversation to develop the change from scratch
- **Upgrade from interactive:** Accept existing IaC artifacts or resource manifests produced by interactive skills (define, containerize, deploy) and build a structured spec around them

Pipeline position:
arn-infra-init -> arn-infra-wizard (Full Pipeline) -> [arn-infra-change-spec] -> arn-infra-change-plan -> arn-infra-save-plan -> arn-infra-execute-change -> arn-infra-review-change -> arn-infra-document-change

## Prerequisites

Read `## Arness` from the project's CLAUDE.md. If no `## Arness` section exists or Arness Infra fields are missing, inform the user: "Arness Infra is not configured for this project yet. Run `/arn-infra-wizard` to get started — it will set everything up automatically." Do not proceed without it.

Check the **Deferred** field. If `Deferred: yes`, inform the user: "Infrastructure is in deferred mode. Change specification is not available until infrastructure is fully configured. Run `/arn-infra-assess` to un-defer." Stop.

Extract:
- **Infra specs directory** -- path where INFRA_CHANGE_*.md specs are stored (default: `.arness/infra-specs`)
- **Experience level** -- derived from user profile. Read `~/.arness/user-profile.yaml` (or `.claude/arness-profile.local.md` if it exists — project override takes precedence). Apply the experience derivation mapping from `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-ensure-config/references/experience-derivation.md`. If no profile exists, check for legacy `Experience level` in `## Arness` as fallback.
- **Providers** -- which cloud providers are configured
- **Environments** -- which environments exist and their promotion order
- **Cost threshold** -- budget threshold for cost impact warnings

If `Infra specs directory` is not configured, use the default `.arness/infra-specs`. If the directory does not exist, create it: `mkdir -p <infra-specs-dir>`.

---

## Workflow

### Step 1: Determine Entry Path

Analyze the user's trigger message and project state to determine which entry path to follow.

**Upgrade detection:**
Check for signals that the user wants to upgrade existing interactive work to the pipeline:
- User explicitly says "upgrade to pipeline", "convert to pipeline", or "upgrade from interactive"
- User references existing IaC artifacts: "I already defined infrastructure", "I used arn-infra-define", "upgrade my existing infrastructure"
- Existing IaC files are present and the user references them

**If upgrade signals are detected:** Go to Step 2a (Upgrade Path).

**If no upgrade signals:** Go to Step 2b (Fresh Path).

---

### Step 2a: Upgrade from Interactive Path

This path accepts existing IaC artifacts produced by interactive skills and builds a structured change spec around them.

1. **Locate existing artifacts:**
   - Check for IaC files in the project (`.tf`, `Pulumi.*`, `cdk.json`, `*.bicep`, `fly.toml`, `docker-compose.yml`, Kubernetes manifests, platform configs)
   - Check for resource manifests (`active-resources.json`, `tooling-manifest.json`)
   - Check for existing provider configuration (`.arness/infra/providers.md`)

2. **Present findings to the user:**

   "I found the following existing infrastructure artifacts:

   | Artifact | Type | Provider | Path |
   |----------|------|----------|------|
   | ... | IaC/Config/Manifest | ... | ... |

   I'll build a change specification around these. This captures the change formally so it can go through the structured pipeline (plan, execute, review, document)."

3. **Extract infrastructure context from artifacts:**
   - Read the IaC files to identify resources being created, modified, or configured
   - Read provider configuration for environment and provider details
   - Read any existing specs or briefs in the infra specs directory

4. **Proceed to Step 3** with the extracted context as the initial change description. Skip the iterative idea capture -- the artifacts define what is changing.

---

### Step 2b: Fresh Path

Guide the user through developing the change idea from scratch.

Ask the user to describe their infrastructure change. Accept anything from a single sentence to a detailed description. Do not require a specific format.

If the user already provided the change idea in their trigger message (e.g., "infra change spec: migrate the database to a managed service"), use that directly without asking again.

Acknowledge the idea with a brief restatement to confirm understanding.

**Prompt questions to fill gaps** (adapt to experience level):

**Expert:** Ask targeted questions only for genuinely missing information. Trust the user to provide sufficient detail.

**Intermediate:** Ask 3-5 structured questions covering the key areas:
- "Which resources are affected and what operations (create/modify/destroy)?"
- "Which environments does this change target?"
- "Are there rollback constraints or compliance requirements?"
- "What is the expected cost impact?"

**Beginner:** Walk through each area with explanations:
- "Let's start with what needs to change. Can you describe the resources involved? (For example: a database, a load balancer, a DNS record...)"
- "Which environments will this affect? (For example: just development, or also staging and production?)"
- "If something goes wrong, how would you want to undo this change?"
- "Are there any budget limits or compliance rules to consider?"

---

### Step 3: Load References and Analyze

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-change-spec/references/infra-change-spec-template.md` for the spec template.

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-change-spec/references/blast-radius-guide.md` for blast radius classification.

Using the change description (from Step 2a or 2b), perform initial analysis:

1. **Classify blast radius** per environment using the blast-radius-guide classifications (None/Contained/Broad/Critical)
2. **Identify affected resources** with provider, action (create/modify/destroy), and environment scope
3. **Assess rollback complexity** based on the types of changes involved
4. **Estimate cost impact** direction (increase/decrease/neutral) and rough magnitude

---

### Step 4: Invoke Agents for Deep Analysis

**If application context is available** (the change is driven by an application feature, or cross-project artifacts exist):

Invoke the `arn-infra-request-analyzer` agent via the Task tool with:

```text
--- CHANGE CONTEXT ---
[change description from Step 2a or 2b]
--- END CHANGE CONTEXT ---

--- INFRASTRUCTURE CONFIG ---
Providers: [from ## Arness]
Environments: [from ## Arness]
Experience level: [derived from user profile]
--- END INFRASTRUCTURE CONFIG ---

--- INSTRUCTIONS ---
Analyze the infrastructure implications of this change. Identify all affected
resources, dependencies between resources, and potential impacts on existing
infrastructure. Focus on what needs to change and what could break.
--- END INSTRUCTIONS ---
```

**Always invoke the `arn-infra-cost-analyst` agent** for preliminary cost estimation:

```text
--- CHANGE CONTEXT ---
[change description including identified resources and operations]
--- END CHANGE CONTEXT ---

--- COST CONFIG ---
Providers: [from ## Arness]
Cost threshold: [from ## Arness]
--- END COST CONFIG ---

--- INSTRUCTIONS ---
Provide a preliminary cost estimation for this infrastructure change.
Estimate monthly cost delta, one-time provisioning costs, and compare
with the current state. Flag if the estimated cost exceeds the configured
threshold.
--- END INSTRUCTIONS ---
```

Both agents can be invoked in parallel since they are independent.

---

### Step 5: Exploration Phase (Iterative)

This is a conversation loop. Each iteration:

1. **Present findings** -- Show the initial analysis including blast radius classification, affected resources, cost estimate, and any agent outputs.

2. **Listen** -- The user responds with feedback, corrections, additional requirements, or questions.

3. **Refine** -- Update the change specification based on feedback. Re-invoke agents if the scope changes significantly (e.g., new resources added, different environments targeted).

4. **Summarize** -- After each substantive exchange, briefly state where things stand: what has been decided, what is still open.

5. **Check for readiness** -- When the conversation converges (open questions resolved, user is agreeing), ask:

   "I think we have enough to write the change specification. Ready for me to finalize it, or do you want to explore anything else?"

   Use judgment -- typically after 2-4 rounds of substantive discussion, or when the user signals readiness.

---

### Step 6: Write the Change Specification

When the user approves:

1. Derive a kebab-case name for the change from the description (e.g., "migrate database to managed service" -> `migrate-database-managed`). Suggest to the user: "I'll name this spec `<name>`. Good?"

2. Populate the `infra-change-spec-template.md` with all gathered information:
   - Change Overview from the conversation
   - Affected Resources table from analysis
   - Blast Radius Assessment per environment
   - Rollback Requirements from discussion
   - Environment Scope with promotion order
   - Compliance Constraints if identified
   - Cost Impact from the cost-analyst agent
   - Dependencies identified during exploration
   - Acceptance Criteria from the conversation

3. Write to `<infra-specs-dir>/INFRA_CHANGE_<name>.md`.

4. Present a summary:
   - Spec file location
   - Key decisions captured
   - Blast radius classification per environment
   - Cost impact summary
   - Open items remaining

5. Inform the user of next steps:

   "Infrastructure change specification saved to `<infra-specs-dir>/INFRA_CHANGE_<name>.md`.

   Next step: Run `/arn-infra-change-plan` to generate a phased implementation plan from this spec."

---

## Error Handling

- **`## Arness` config missing:** Suggest running `/arn-infra-wizard` to get started. Stop.
- **Infra specs directory does not exist:** Create it with `mkdir -p`. Continue.
- **Request analyzer agent fails:** Report the error. Continue without cross-project analysis. Note in the spec: "Application context analysis was unavailable. Review affected resources manually."
- **Cost analyst agent fails:** Report the error. Continue without cost estimation. Note in the spec: "Cost estimation was unavailable. Estimate costs before executing the change."
- **Cost analyst returns empty output:** Inform: "The cost analyst could not determine cost impact from the available information. Add cost estimates manually before proceeding."
- **Ambiguous scope:** If the user describes a change that could apply to multiple environments or providers, ask for clarification rather than guessing.
- **Missing provider info:** If the change references a provider not configured in `## Arness`, warn: "Provider [name] is not configured in your Arness Infra setup. Run `/arn-infra-init` to add it, or specify the provider details manually."
- **Existing spec with same name:** If `INFRA_CHANGE_<name>.md` already exists:

  Ask (using `AskUserQuestion`):

  **"A spec with this name already exists. What would you like to do?"**

  Options:
  1. **Overwrite** -- Replace the existing spec
  2. **Rename** -- Choose a different name
- **Re-running is safe:** Creating a new spec does not affect existing specs. The user can create multiple specs for different changes. Overwriting an existing spec requires explicit confirmation.
