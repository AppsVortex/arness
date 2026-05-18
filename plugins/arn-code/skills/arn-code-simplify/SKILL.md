---
name: arn-code-simplify
description: >-
  This skill should be used when the user says "simplify", "arness code simplify",
  "simplify code", "code simplification", "clean up code", "reduce complexity",
  "remove duplication", "check for reuse", "find duplicates", "optimize code",
  "efficiency review", "simplify implementation", "arn-code-simplify",
  or wants to review recently implemented code for reuse opportunities, quality
  issues, and efficiency problems after execution completes. Do NOT use this
  for full implementation correctness review (use arn-code-review-implementation)
  or PR review (use arn-code-review-pr).
version: 1.0.0
---

# Arness Simplify

Analyze recently implemented code for reuse opportunities, quality issues, and efficiency problems. Dispatches three parallel reviewers (code reuse, code quality, efficiency), merges findings, applies user-approved fixes with test verification, and generates a structured simplification report.

This is a post-execution quality improvement skill. It runs after implementation is complete (after execute-plan, swift, or bug-spec) and before review-implementation.

This is an execution skill. It runs in normal conversation (NOT plan mode).

## Prerequisites

If no `## Arness` section exists in the project's CLAUDE.md, inform the user: "Arness is not configured for this project yet. Run `/arn-implementing` to get started — it will set everything up automatically." Do not proceed without it.

## Pipeline Position

```
execute --> **arn-code-simplify** --> review-implementation --> document-project --> ship
```

Arness-simplify is an optional step between execution and review. It can be triggered:
- By arn-implementing as Gate G3 (opt-in)
- By the user directly after any execution completes
- As a next-step offer from arn-code-execute-plan, arn-code-execute-task, or arn-code-swift

## Workflow

### Step 1: Load Configuration

1. Read the project's CLAUDE.md and extract the `## Arness` section to find:
   - Plans directory
   - Code patterns path
   - Template path
   - Template version and Template updates preference (if present)

2. If the `## Arness` section is missing, inform the user: "Arness is not configured for this project yet. Run `/arn-implementing` to get started — it will set everything up automatically." Do not proceed.

3. Load pattern documentation from the code patterns directory:
   - `code-patterns.md` (required)
   - `testing-patterns.md` (required)
   - `architecture.md` (required)
   - `ui-patterns.md` (if it exists)
   - `security-patterns.md` (if it exists)

4. If pattern documentation is missing, invoke the `arn-code-codebase-analyzer` agent to generate fresh analysis. If the analyzer is unavailable, suggest running `/arn-implementing` to get started.

Hold this context for use throughout the workflow.

---

### Step 2: Resolve Scope

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-simplify/references/scope-detection.md` for the full scope detection algorithm.

1. **If invoked with an explicit scope** (e.g., from arn-code-execute-task passing a report path): use the provided scope directly.

2. **If invoked without explicit scope** (standalone or wizard gate): auto-detect scope using the priority order defined in scope-detection.md (pipeline > swift > bugfix).

3. Build the file list from the scope's artifacts. Apply the 30-file cap. If more than 30 files, split into batches as described in scope-detection.md.

4. Confirm scope and file list with the user before proceeding.

---

### Step 3: Dispatch Parallel Reviewers

> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-simplify/references/review-prompts.md` for the three reviewer prompt templates and output format.

Dispatch three Agent tool calls **in a single message** so they run in parallel. Each call passes the model from `.arness/agent-models/code.md` (look up `arn-code-simplify-reviewer`) as the `model` parameter (see `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-ensure-config/references/step-0-fast-path.md` "Dispatch convention" for fallback behavior). The three reviewers share the same synthetic name — apply the multi-agent rule by passing the looked-up value to each call independently.

1. **Code Reuse Reviewer** -- fill the review-prompts.md template with the file list and pattern documentation. Instruct the agent to focus on duplicated logic, missed utilities, and copy-paste patterns.

2. **Code Quality Reviewer** -- fill the template. Instruct the agent to focus on unnecessary complexity, dead code, unclear naming, and overly nested logic.

3. **Efficiency Reviewer** -- fill the template. Instruct the agent to focus on N+1 patterns, redundant computations, suboptimal data structures, and unnecessary allocations.

Each agent receives:
- `{files_to_review}`: the file list for the current batch
- `{code_patterns}`: content of code-patterns.md
- `{testing_patterns}`: content of testing-patterns.md
- `{architecture}`: content of architecture.md

**Partial failure handling:** If one reviewer fails, merge findings from the other two. Record the failure in `reviewerStatus` with status `"failed"`. Add a warning: "The [axis] reviewer failed. Findings may be incomplete for that axis."

If all files fit in a single batch, dispatch once. If batched, dispatch the three reviewers for each batch sequentially (batch 1 complete, then batch 2, etc.).

---

### Step 4: Merge and Present Findings

1. Collect findings from all three reviewers.

2. Deduplicate: if two reviewers flagged the same code location for overlapping reasons, merge into a single finding. Prefer the higher severity and note both axes.

3. Assign sequential IDs: `SIM-001`, `SIM-002`, etc.

4. Automatically defer findings with effort `"large"`: set status to `"deferred"` and add a note suggesting a refactoring spec for strategic improvements.

5. Collect all `patternsPreserved` entries from all reviewers.

6. Present findings to the user grouped by axis:

   **Code Reuse Findings:**
   - SIM-001 [medium/small]: Title -- description
   - SIM-002 [high/trivial]: Title -- description

   **Code Quality Findings:**
   - SIM-003 [low/small]: Title -- description

   **Efficiency Findings:**
   - SIM-004 [medium/medium]: Title -- description

   **Deferred (large effort):**
   - SIM-005 [high/large]: Title -- consider a refactoring spec

   **Patterns Preserved:** N decisions respected documented patterns.

---

### Step 5: User Approval

**Auto-all mode check:** Before prompting, check the resolved value of `pipeline.simplification` from the two-tier preference lookup. If the value is `auto-all`:

- Auto-approve all non-deferred findings (mark as `"approved"`)
- Skip the user prompt entirely
- Log: "Auto-all mode: approving [N] findings ([M] deferred)."
- Proceed directly to Step 6

This mode is used by batch-implement workers that cannot prompt the user. It follows the same logic as the user selecting `"all"` but without requiring AskUserQuestion.

**Interactive mode (all other preference values):**

Ask the user which findings to apply:

"Which findings should I apply? Enter finding IDs (e.g., SIM-001, SIM-003), 'all' to apply everything except deferred, or 'none' to skip."

Process the user's selection:
- Specific IDs: mark those as `"approved"`, rest as `"rejected"`
- `"all"`: mark all non-deferred findings as `"approved"`
- `"none"`: mark all as `"rejected"`, skip to Step 7

The user may also change individual finding statuses (e.g., "approve SIM-001 but defer SIM-003").

---

### Step 6: Apply Approved Simplifications

The orchestrator pre-sorts the approved findings by dependency order (if finding B depends on finding A's changes, A comes first), then dispatches a single anonymous Agent call to perform the apply work. The model is configurable via the agent-models config.

**Dispatch the applier as an anonymous Agent tool call**, passing the model from `.arness/agent-models/code.md` (look up `arn-code-simplify-applier`) as the `model` parameter (see `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-ensure-config/references/step-0-fast-path.md` "Dispatch convention" for fallback behavior). Do NOT add any tool restriction — the applier inherits `Edit`, `Write`, `Bash`, `Read`, `Grep`, `Glob` from the orchestrator's toolbelt by default, and needs all of them.

**Applier prompt contents:**

- The pre-sorted list of approved findings (each with `id`, `title`, `description`, `suggestedFix`, `filesAffected`, and `axis`)
- The targeted-test command (from the scope's context or testing-patterns.md)
- Paths to relevant pattern docs (code-patterns.md, testing-patterns.md) so the applier can reference them when self-healing
- The exact instructions below:

```
For each finding in the provided list, IN ORDER:

1. Capture pre-state: `git diff --no-color HEAD > /tmp/pre-{findingId}.diff`
2. Apply the suggested fix (Edit/Write the affected files).
3. Run the targeted test command. Capture stdout+stderr.
4. If tests pass: emit `[FINDING-{findingId}: applied]` to stdout. Record status `"applied"`. Continue to next finding.
5. If tests fail: attempt self-healing.
   - Re-read the test output to identify the failure cause.
   - Make a fix attempt (Edit the file).
   - Re-run the targeted test command.
   - Up to 3 self-heal attempts per finding.
6. If tests still fail after 3 attempts: revert this finding's changes via `git apply -R /tmp/pre-{findingId}.diff` (or, if the diff is empty because no prior changes existed, run `git checkout -- {filesAffected}`). Emit `[FINDING-{findingId}: reverted - <reason>]` to stdout. Record status `"reverted"` with the failure reason and last test output. Continue to next finding.
7. Always emit a per-finding status line so the user sees progress in the transcript.

After processing all findings, run ONE final targeted test pass to verify the cumulative state is consistent. Capture the result.

RETURN — strictly as the final message — a JSON object with this exact schema (no other text):

{
  "applicationResults": [
    {
      "findingId": "SIM-001",
      "status": "applied" | "reverted",
      "attempts": <integer 1-4>,
      "testOutput": "<last test command output, truncated to 2000 chars>",
      "revertReason": "<reason if reverted, omitted if applied>"
    }
  ],
  "finalTestResult": {
    "passed": <boolean>,
    "output": "<final test pass output, truncated to 2000 chars>"
  }
}

If you crash or have to abort partway through, return the JSON with results for the findings you DID process — do not omit the JSON entirely. Mark unprocessed findings as `status: "pending"` so the orchestrator can surface the partial state.
```

**After the applier returns:**

1. Parse the returned JSON. If parsing fails or the schema is incomplete, treat any missing finding as `status: "pending"` and add a warning to the report's `warnings` array: `"Applier returned malformed or partial results. <N> findings have unknown status."`
2. Populate the report's `applicationResults` array directly from the applier's return.
3. Populate `testVerification.revertedFindings` from any entries with `status: "reverted"`.
4. Populate `testVerification.finalTestPassed` from `finalTestResult.passed`.
5. Format a brief user-facing summary from the per-finding statuses for display (mirror the previous Step 7 summary shape).

**Auto-all mode interaction:** Both interactive approval (Step 5) and `auto-all` mode reach this same Step 6 dispatch — the applier dispatch is identical in both paths. The only difference is whether Step 5 prompted the user or skipped the prompt.

---

### Step 7: Generate Report

1. Read the `SIMPLIFICATION_REPORT_TEMPLATE.json` from the template path configured in `## Arness`.

2. Populate all fields:
   - `reportType`: `"simplification"`
   - `projectName`: from the scope context
   - `scopeContext`: `"pipeline"`, `"swift"`, `"bugfix"`, or `"task"`
   - `reportDate`: current ISO 8601 timestamp
   - `reportVersion`: `1`
   - `configuration`: files reviewed count, batch count, review axes used, pattern docs loaded
   - `findings`: all findings with their final statuses
   - `patternsPreserved`: all pattern-preservation records from all reviewers
   - `applicationResults`: results for each applied finding
   - `testVerification`: test run summary
   - `summary`: counts of total, approved, rejected, applied, reverted, deferred
   - `reviewerStatus`: status and finding count per reviewer axis
   - `warnings`: any warnings accumulated during the process
   - `nextSteps`: context-dependent suggestions

3. Write the report to the output path determined by scope detection.

---

### Step 8: Offer Next Steps

Based on the scope context, offer the appropriate next step:

| Scope Context | Next Step Offer |
|---------------|----------------|
| Pipeline | "Run `/arn-code-review-implementation` to review the full implementation." |
| Swift | "Run `/arn-code-ship` to commit and create a PR." |
| Bugfix | "Run `/arn-code-ship` to commit and create a PR." |
| Task | "Simplification complete for this task. Returning to execution." |

---

## Error Handling

- **`## Arness` config missing** -- inform the user: "Arness is not configured for this project yet. Run `/arn-implementing` to get started."
- **Pattern docs missing** -- invoke `arn-code-codebase-analyzer` to generate fresh analysis. If unavailable, suggest running `/arn-implementing` to get started.
- **Reviewer agent fails** -- merge findings from the other two reviewers and note the missing perspective in the report. Add a warning about incomplete coverage for that axis.
- **All three reviewers fail** -- inform the user that simplification analysis could not be completed. Suggest retrying or proceeding to the next pipeline step.
- **SIMPLIFICATION_REPORT_TEMPLATE.json missing** -- if the template file does not exist at the configured template path, generate the report with a minimal structure (`reportType`, `projectName`, `scopeContext`, `findings`, `summary`, `warnings`, `nextSteps`) and warn the user: "Report template not found. Generated report with minimal structure. Run `/arn-implementing` to get started."
- **Test self-heal exhaustion** -- after 3 failed attempts for a finding, revert that finding's changes and continue with the next finding. Record the failure details in the report.
- **No findings** -- if all three reviewers return zero findings, generate a clean report with `summary.totalFindings: 0` and inform the user: "No simplification opportunities found. The implementation looks clean."
- **Scope detection fails** -- if no artifacts are found during auto-detection, ask the user to provide an explicit scope (project name, artifact path, or file list).

## Constraints

- Maximum 30 files per review pass (batch if more).
- Findings with effort `"large"` are always deferred, never applied during simplification.
- Each self-heal cycle gets at most 3 attempts before revert.
- Per-simplification revert: a failed finding does not affect other successfully applied findings.
- Never modify files outside the scope's file list without explicit user approval.
- Reviewer and applier dispatches use synthetic agent names for model-config lookup; no agent files are required.
