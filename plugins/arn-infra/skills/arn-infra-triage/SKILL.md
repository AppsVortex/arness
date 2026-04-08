---
name: arn-infra-triage
description: >-
  This skill should be used when the user says "triage infra request",
  "infra triage", "arn infra triage", "process infra issue", "handle infra request",
  "infrastructure request", "triage infrastructure", "analyze infra issue",
  "infra request analysis", "process infrastructure request", or wants to process
  an incoming infrastructure request issue created by Arness Core or manually,
  analyze its infrastructure implications, and produce a structured implications
  brief.
version: 1.0.0
---

# Arness Infra Triage

Process incoming infrastructure request issues, invoke the `arn-infra-request-analyzer` agent to extract infrastructure implications from the referenced application artifacts, update issue labels, and produce a structured implications brief. This skill bridges application feature development and infrastructure provisioning.

Infrastructure request issues are typically created by Arness Core when a completed feature has infrastructure implications (new database, new endpoints, new env vars). They can also be created manually by users.

## Prerequisites

Read `## Arness` from the project's CLAUDE.md. If no `## Arness` section exists or Arness Infra fields are missing, inform the user: "Arness Infra is not configured for this project yet. Run `/arn-infra-wizard` to get started — it will set everything up automatically." Do not proceed without it.

Check the **Deferred** field. If `Deferred: yes`, inform the user: "Infrastructure is currently in deferred mode. Triage is not available until infrastructure is un-deferred. Run `/arn-infra-assess` to un-defer and produce a full infrastructure assessment." Stop.

Extract `Infra specs directory` for use in Step 6 save path. If not configured, default to `.arness/infra-specs`.

Extract:
- **Issue tracker** -- where to read/update issues (github, jira, none)
- **Project topology** -- how to resolve the application project (monorepo, separate-repo, infra-only)
- **Application path** -- path to the application project root
- **Experience level** -- derived from user profile. Read `~/.arness/user-profile.yaml` (or `.claude/arness-profile.local.md` if it exists — project override takes precedence). Apply the experience derivation mapping from `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-ensure-config/references/experience-derivation.md`. If no profile exists, check for legacy `Experience level` in `## Arness` as fallback.
- **Jira site** and **Jira project** -- if Issue tracker is jira

## Workflow

### Step 1: Accept Issue Input

The user provides an issue reference. Accept any of:
- **Issue number:** e.g., `#42` or `42`
- **Issue URL:** e.g., `https://github.com/org/repo/issues/42`
- **Issue description pasted:** For manual issues or when the tracker is unavailable

**Read the issue:**
- **GitHub:** `gh issue view <number> --json title,body,labels,url`
- **Jira:** Use the Atlassian MCP to read the issue by key
- **None / pasted:** Parse the content directly from the user's input

---

### Step 2: Parse the Infrastructure Request

Extract structured fields from the issue body. If the issue follows the `infra-request-template.md` format (created by Arness Core), parsing is automatic:

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-triage/references/infra-request-template.md` for the expected format.

**Structured parsing (template format):**
- **Feature:** Name and issue/PR reference
- **Spec:** Path to the feature spec in the Core project
- **Plan:** Path to the implementation plan (if exists)
- **Infrastructure implications:** Summary of what the feature needs
- **Key implementation files:** Paths to source files affecting infrastructure
- **Originating issue:** Link to the Core issue/PR
- **Priority:** Blocking | Planned | Enhancement

**Free-form parsing (manual issues):**
If the issue does not follow the template format:
1. Extract what you can from the issue body
2. Ask the user to fill gaps: "This issue wasn't created using the standard template. I need some additional information:"
   - What feature or application change drives this infrastructure need?
   - Where is the relevant application code? (file paths or description)
   - What is the priority? (Blocking / Planned / Enhancement)

---

### Step 3: Invoke the Request Analyzer Agent

Invoke the `arn-infra-request-analyzer` agent via the Task tool with:

```text
--- ISSUE CONTEXT ---
[parsed issue content from Step 2]
--- END ISSUE CONTEXT ---

--- INFRASTRUCTURE CONFIG ---
Project topology: [topology]
Application path: [path]
Providers: [from ## Arness]
Default IaC tool: [from ## Arness]
Experience level: [derived from user profile]
--- END INFRASTRUCTURE CONFIG ---

--- INSTRUCTIONS ---
Analyze the referenced application artifacts. Navigate to the application project
at [Application path]. Read the feature spec, plan, and implementation files
referenced in the issue. Extract infrastructure implications and produce an
implications brief following the template format.
--- END INSTRUCTIONS ---
```

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-triage/references/implications-brief-template.md` for the brief format.

Pass the implications brief template to the agent so it produces correctly structured output.

**Topology-aware behavior:**
- **Monorepo:** The Core artifacts are in the same repo. Direct file reads with relative paths.
- **Separate repo:** The agent reads from `Application path`. If the path is unreachable, fall back to the issue content only and inform the user: "Could not access the application project at [path]. Analysis is based on the issue content only. For a more thorough analysis, ensure the application path is accessible."
- **Infra-only:** No application project. Process the issue as a standalone infrastructure request without cross-project analysis.

---

### Step 4: Update Issue Labels

After the analyzer produces its brief, update the issue labels.

First check if the `arn-infra-request` label is present on the issue. If present, remove it. Always add `arn-infra-in-progress` regardless.

**GitHub:**
```bash
gh issue edit <number> --remove-label "arn-infra-request" --add-label "arn-infra-in-progress"
```

**Jira:**
Use the Atlassian MCP to update labels on the issue.

**None:** Skip label updates. Note in the output.

---

### Step 5: Present the Implications Brief

Present the infrastructure implications brief to the user. Adapt detail level based on experience level:

- **Expert:** Concise presentation with technical details. Focus on resource specifications and cost impact.
- **Intermediate:** Balanced presentation with explanations of trade-offs and recommendations.
- **Beginner:** Detailed presentation with plain-language explanations of what each resource does and why it is needed.

---

### Step 6: Offer Next Steps

Ask (using `AskUserQuestion`):

**"Infrastructure implications have been analyzed. What would you like to do?"**

Options:
1. **Act on this now** -- Proceed to implementation
2. **Review and adjust** -- Discuss the implications and make changes before proceeding
3. **Save for later** -- Save this brief for future reference

If **Review and adjust**: enter discussion mode -- present the implications brief for iterative refinement with the user before returning to this decision.

If **Save for later**: write the brief to `<infra-specs-dir>/INFRA_<feature-name>.md` using the feature name from the issue.

If **Act on this now**:

Ask (using `AskUserQuestion`):

**"Which implementation path?"**

Options:
1. **Generate IaC directly** -- Feed this brief into `/arn-infra-define` to generate IaC configurations
2. **Full guided pipeline** -- Feed this brief into `/arn-infra-wizard` for end-to-end infrastructure setup
3. **Structured change pipeline** -- Feed this brief into `/arn-infra-change-spec` for structured change management with review gates, cost tracking, and audit trails. Recommended for complex or multi-environment changes.

---

## Error Handling

- **`## Arness` config missing:** Suggest running `/arn-infra-wizard` to get started. Stop.
- **Issue not found:** If the issue number does not exist or the URL is invalid, inform the user and ask for a valid reference.
- **Issue has no `arn-infra-request` label:** Warn: "This issue does not have the `arn-infra-request` label. It may not be a standard infrastructure request. Proceed anyway?" If yes, continue. If no, stop.
- **Request analyzer agent fails:** Report the error. Fall back to presenting the raw issue content and ask the user to manually identify infrastructure needs.
- **Request analyzer returns empty output:** Inform: "The analyzer could not determine infrastructure implications from the available artifacts. This may mean the referenced files are incomplete or the application path is not accessible." Ask the user to provide additional context.
- **Label update fails:** Warn but continue. The brief is still useful even if labels could not be updated.
- **Application path unreachable (separate-repo):** Fall back to issue-content-only analysis. Note the limitation in the brief.
- **Re-running is safe:** Re-triaging the same issue overwrites the previous analysis. Labels remain at `arn-infra-in-progress`.
