---
name: arn-code-report
description: >-
  This skill should be used when the user says "report issue", "arness code report",
  "code report", "something went wrong", "report a bug", "file arness code issue",
  "arness code broke", "report arness code problem", "diagnose issue", "arness doctor",
  "run doctor", "diagnose arness code", "arn-code-report", or wants to report a
  problem with an Arness Code workflow skill. Invokes the arn-code-doctor agent to
  diagnose the issue, then files a GitHub issue on the Arness plugin repository.
  Do NOT use this for filing issues on the user's own project — use
  /arn-code-create-issue for that. For Spark issues use /arn-spark-report. For
  Infra issues use /arn-infra-report.
version: 1.1.0
---

# Arness Code Report

Report an Arness Code workflow issue by running a diagnostic and filing a GitHub issue on the Arness plugin repository. The arn-code-doctor agent analyzes Arness Code configuration and behavior — it never reads project source code or business logic. Supports cross-plugin smart routing — detects if the issue belongs to Spark or Infra and suggests the right report skill.

## Workflow

### Step 0: Smart Routing

Before gathering details, check if the issue might belong to another plugin:

1. Read `## Arness` from the project's CLAUDE.md.
2. If the user has already described the issue (e.g., in their initial message), scan for keyword signals:
   - **Spark keywords**: "discover", "prototype", "greenfield", "stress test", "naming", "brainstorming", "feature extract", "visual sketch", "use cases", "scaffold", "spike"
   - **Infra keywords**: "deploy", "Dockerfile", "container", "IaC", "terraform", "pipeline", "CI/CD", "environment", "secrets", "monitor", "infrastructure", "verify", "cleanup"
3. If Spark signals detected and Spark fields exist in `## Arness`: suggest "This sounds like an Arness Spark issue. Run `/arn-spark-report` instead, or confirm this is a Code issue."
4. If Infra signals detected and Infra fields exist in `## Arness`: suggest "This sounds like an Arness Infra issue. Run `/arn-infra-report` instead, or confirm this is a Code issue."
5. If no signals or user confirms it's a Code issue: proceed to Step 1.

---

### Step 1: Explain the Process

Inform the user:

"I'll help you report a Arness workflow issue. Here's how this works:
1. You describe what happened — which skill you used and what went wrong
2. I'll run a diagnostic that checks Arness's configuration and expected behavior (I won't read your project code)
3. You'll review the issue report before it's submitted
4. The issue gets filed on the Arness plugin repository for the maintainers

Your project code and business logic are never included in the report."

---

### Step 2: Gather User Description

Ask the user using `AskUserQuestion`:
- "What happened? Which Arness skill were you using and what went wrong?"

Let the user type a free-form description. This becomes the `user_description` for the diagnostic.

---

### Step 3: Check Prerequisites

1. Detect the plugin's GitHub repository:
   - Read `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json` and extract the `repository` field.
   - Parse `owner/repo` from the URL (strip `https://github.com/` prefix and any trailing `.git`).
   - **Fallback** (for local dev testing with `--plugin-dir`): if no `repository` field exists, try `git -C ${CLAUDE_PLUGIN_ROOT} remote get-url origin`.

2. Check `gh auth status` — user must be authenticated to file issues.

3. Read plugin version from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`.

4. Read `## Arness` config from the project's CLAUDE.md (if it exists).

If GitHub access is not available, offer an alternative: generate the diagnostic report as a local file (`arness-code-report-<YYYY-MM-DD>.md` in the project root) the user can manually submit.

---

### Step 4: Invoke arn-code-doctor

Spawn the `arn-code-doctor` agent via the Task tool with:
- The user's description of the issue
- Project root path
- `## Arness` config content (or "not configured")
- Plugin version
- Instruction to read the knowledge base at `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-report/references/arness-knowledge-base.md`

Wait for the agent to complete and collect the diagnostic report.

---

### Step 5: Compose and Review Issue

Assemble the GitHub issue using the template from `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-report/references/issue-template.md`:
- Include the user's original description in the "User Report" section
- Include the doctor's diagnostic findings (ISSUE items only, not OK items)
- Include the doctor's assessment
- Include plugin version and relevant config state
- Include environment info (OS, Git, GitHub, gh CLI status)
- Exclude any project code or business logic

Present the complete draft to the user, then request explicit consent.

Ask (using `AskUserQuestion`):

> **This report will be filed as a public GitHub issue on the Arness repository.** It contains only Arness configuration state and diagnostic findings — no project source code or business logic. Please review the report above carefully.
>
> 1. Submit — I've reviewed it and consent to filing this publicly
> 2. Save locally — save as a file instead of submitting
> 3. Edit first — let me modify the report before deciding

- If **Submit**: proceed to Step 6.
- If **Save locally**: save as `arness-code-report-<YYYY-MM-DD>.md` in the project root. Inform the user. Do not submit.
- If **Edit first**: let the user modify the draft, then ask again.

---

### Step 6: Submit Issue

The `arn-code-report` label must already exist on the plugin repository (maintained by the plugin maintainers, not created by this skill).

1. Create the issue with the `arn-code-report` label:
   ```bash
   gh issue create --repo <owner/repo> --title "<title>" --body "<body>" --label "arn-code-report"
   ```

2. If the command fails because the label does not exist, retry without `--label` and inform the user that the issue was filed without a label.

3. Report the issue URL to the user.

If submission fails for other reasons (permissions, network), save the report as `arness-code-report-<YYYY-MM-DD>.md` in the project root and inform the user with instructions to submit manually.

## Error Handling

- **Plugin repository not detected** — no `repository` field in plugin.json and no git remote found. Generate report as `arness-code-report-<YYYY-MM-DD>.md` in the project root instead.
- **`gh` not authenticated** — suggest `gh auth login`, offer local file fallback (`arness-code-report-<YYYY-MM-DD>.md`).
- **User lacks permission to file issues on plugin repo** — save report as `arness-code-report-<YYYY-MM-DD>.md` in the project root, suggest opening manually.
- **arn-code-doctor agent fails** — report the failure, offer to file a minimal issue with just the user's description.
- **`## Arness` config missing** — proceed anyway, note "not configured" in the report.
- **`arn-code-report` label missing from plugin repo** — retry without `--label`, note this in the output.

## Constraints

- **NEVER** include project source code, business logic, or sensitive data in the report
- **NEVER** file issues on the user's own project repository — this skill only files on the Arness plugin repository
- **ALWAYS** present the full report draft and obtain explicit user consent before submitting
- **ALWAYS** offer a local-file alternative — the user must never be forced to submit publicly
