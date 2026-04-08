---
name: arn-infra-assess
description: >-
  This skill should be used when the user says "assess infrastructure",
  "infra assess", "arn infra assess", "infrastructure assessment",
  "analyze infrastructure needs", "what infrastructure do I need",
  "infrastructure audit", "app infrastructure assessment", "full infra assessment",
  "infrastructure review", "assess my app", "un-defer infrastructure",
  "infra backlog", or wants a comprehensive analysis of their application's
  infrastructure needs, including processing deferred infrastructure backlogs,
  to produce a prioritized infrastructure backlog published as issues.
version: 1.0.0
---

# Arness Infra Assess

Perform a comprehensive infrastructure assessment of the application. Read the deferred backlog (if exists), analyze the complete application codebase, ask structured assessment questions, and produce a prioritized infrastructure backlog published as issues to the issue tracker.

This skill serves two primary use cases:
1. **Un-deferring:** When the user deferred infrastructure during `arn-infra-init` and is now ready to plan it
2. **Fresh assessment:** When the user wants a comprehensive infrastructure review of an existing application

## Step 0: Ensure Configuration

Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-ensure-config/references/ensure-config.md` and follow its instructions. This guarantees a user profile exists and `## Arness` is configured with Arness Infra fields before proceeding.

After Step 0 completes, read `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-ensure-config/references/experience-derivation.md` and derive the user's infrastructure experience level from their profile.

Check for at least one Arness Infra-specific field (`Infra plans directory` or `Infra specs directory`) within `## Arness`. If neither is present, Arness Infra has not been fully configured (the `## Arness` section may exist from ensure-config defaults or another plugin). This is acceptable -- assess can still run with defaults.

Extract:
- **Deferred** -- if `yes`, read the deferred backlog
- **Project topology** -- how to resolve the application project
- **Application path** -- path to the application project root
- **Providers** -- configured providers (may be minimal if deferred)
- **Experience level** -- derived from user profile (see experience-derivation.md). If no profile exists, check for legacy `Experience level` in `## Arness` as fallback.
- **Issue tracker** -- where to publish backlog items
- **Jira site** and **Jira project** -- if Issue tracker is jira

## Workflow

### Step 1: Check Deferred Status and Load Backlog

**If `Deferred: yes`:**
1. Read `.arness/infra/deferred-backlog.md` if it exists
2. Inform the user: "You previously deferred infrastructure planning. I found [N] accumulated infrastructure observations from your feature development. These will seed the assessment."
3. Present the deferred backlog items for context

**If `Deferred: no` (or missing):**
Continue to Step 2 without deferred backlog context.

---

### Step 2: Resolve Application Context

Resolve the application project based on topology:

**Monorepo (`Application path: .`):**
- Read codebase patterns from the local code-patterns directory
- Read `architecture.md` for technology stack and dependencies
- Scan the source tree for infrastructure-relevant patterns

**Separate repo:**
- Navigate to `Application path`
- Read the application's `## Arness` config, code patterns, and architecture
- If the path is unreachable, inform the user and ask them to describe the application stack manually

**Infra-only:**
- No application to analyze
- Ask the user to describe the application or provide a list of services and their requirements
- Proceed with user-provided context

---

### Step 3: Full Application Analysis

Invoke the `arn-infra-request-analyzer` agent in Mode B (full application analysis). Pass the loaded codebase patterns, architecture content, deferred backlog (if any), and infrastructure config fields as structured context.

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-assess/references/agent-invocation-guide.md` for the exact prompt template and expected return format.

The agent returns a comprehensive analysis covering application components, data layer, external integrations, networking, security, and performance indicators.

---

### Step 4: Structured Assessment Questions

Ask the user structured questions to refine the infrastructure requirements. Adapt question depth based on experience level.

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-assess/references/assessment-questionnaire.md` for the full question set with options, beginner versions, and selection logic.

Select questions using the **Question Selection Logic** from the questionnaire reference:
- **Always ask:** Availability (Q1), Traffic (Q2), Budget (Q4)
- **Conditional:** Traffic patterns (Q3), Compliance (Q5), Geography (Q6), Latency (Q7), Data volume (Q8) -- based on application analysis results

For beginner experience level, use the simplified question versions from the reference and cap at 4-5 questions total.

---

### Step 5: Produce Prioritized Infrastructure Backlog

Combine the agent's analysis with the user's answers to produce a prioritized backlog.

Categorize each item into one of three priority levels: **Foundation** (must-do-first, e.g., compute, primary database, networking), **Core** (important for production readiness, e.g., caching, object storage, monitoring), or **Enhancement** (incremental improvements, e.g., CDN, auto-scaling, DR).

For each backlog item, produce structured content following the backlog item template.

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-infra-assess/references/backlog-item-template.md` for the item format and priority guidelines.

---

### Step 6: Publish Backlog to Issue Tracker

**GitHub:**
For each backlog item, create an issue:
```bash
gh issue create --title "[arn-infra] [Component]: [brief description]" --body "[backlog item content]" --label "arn-infra-backlog"
```

**Jira:**
For each backlog item, create a Jira issue via the Atlassian MCP in the configured project with the `arn-infra-backlog` label.

**No tracker:**
Write all backlog items to `.arness/infra/backlog.md` as a fallback:
```markdown
# Infrastructure Backlog

Generated by arn-infra-assess on [date].

## Foundation
### [Item 1]
[content]

## Core
### [Item 2]
[content]

## Enhancement
### [Item 3]
[content]
```

---

### Step 7: Update Deferred Status

If the assessment was triggered from deferred mode:

1. Update `## Arness` in CLAUDE.md: set `Deferred: no`
2. If provider configuration is still minimal (from deferred init), offer to run the full provider setup:

   Ask (using `AskUserQuestion`):

   **"Your provider configuration was minimal from the deferred init. Would you like to configure providers now?"**

   Options:
   1. **Yes** -- Guide through the provider selection flow (same as `arn-infra-init` Step 3)
   2. **No** -- Continue with the current minimal config

---

### Step 8: Present Summary

Present the assessment results:

**Assessment Summary:**
- **Application components analyzed:** [count]
- **Deferred backlog items processed:** [count] (or "N/A")
- **Infrastructure backlog items created:** [count]
  - Foundation: [count] items
  - Core: [count] items
  - Enhancement: [count] items
- **Estimated total monthly cost:** $[min] - $[max]
- **Published to:** [GitHub Issues / Jira / .arness/infra/backlog.md]

**Recommended next steps:**

"Infrastructure backlog is ready. Here is the recommended path:

1. **Discover tools:** Run `/arn-infra-discover` to ensure you have the right tools installed (if not done already)
2. **Work through the backlog:** Start with Foundation items:
   - Pick a backlog issue and run `/arn-infra-triage` to analyze it in detail
   - Then run `/arn-infra-define` to generate infrastructure code
   - Or run `/arn-infra-wizard` for the full guided pipeline

Each backlog issue can be individually triaged -- the implications brief is embedded in the issue content.

Alternatively, for complex changes that need review gates and audit trails:
- Run `/arn-infra-change-spec` to create a structured change specification from a backlog item
- Then follow the full change pipeline: change-plan, save-plan, execute-change, review-change, document-change
- Or run `/arn-infra-wizard` and select Full Pipeline mode"

---

## Error Handling

- **`## Arness` config missing:** Step 0 (ensure-config) handles this automatically. If ensure-config itself fails, suggest running `/arn-infra-assess` again.
- **Application path unreachable:** Ask the user to describe the application stack manually. Continue with user-provided context.
- **Request analyzer agent fails:** Fall back to a manual assessment flow: present the assessment questions, gather answers, and produce a simplified backlog based on user input alone (without automated codebase analysis).
- **Request analyzer returns empty output:** Inform: "The analyzer could not determine infrastructure needs from the codebase. This may indicate a very simple application or incomplete codebase patterns." Proceed with the questionnaire-based approach.
- **Issue creation fails:** If publishing to the issue tracker fails, fall back to writing `.arness/infra/backlog.md`. Inform the user of the fallback.
- **Deferred backlog file missing:** If `Deferred: yes` but `.arness/infra/deferred-backlog.md` does not exist, create it as empty and proceed without deferred context. No backlog items is a valid state.
- **No providers configured (deferred mode):** If the assessment runs from deferred mode with minimal config, the assessment still works -- it produces provider-agnostic backlog items. Provider-specific recommendations are added when providers are configured.
- **Re-running is safe:** Re-assessment creates new backlog issues. Existing issues are not duplicated (check for existing issues with the same title before creating).
