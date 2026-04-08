# Diagnosis and Fix Procedure

This document covers the iterative diagnosis loop (Step 4), the complexity assessment (Step 5), and the simple-fix execution flow (Step 6A) from the arn-code-bug-spec skill.

## Diagnosis Phase (Iterative) -- Step 4

This is a conversation loop. Each iteration:

1. **Listen** -- the user responds with confirmation, corrections, additional context, or new symptoms.

2. **Decide how to respond:**

   - **If the user reports new symptoms or provides additional context**: invoke `arn-code-investigator` with the new information plus prior investigation results. If the investigator proposes a different fix direction than previously assessed, re-invoke `arn-code-architect` to validate the new approach against system architecture.

   - **If the user asks about a specific hypothesis** (e.g., "could it be a race condition in the queue handler?"): invoke `arn-code-investigator` with that specific hypothesis to test.

   - **If the user confirms the root cause**: move to the complexity assessment (Step 5).

   - **If the user corrects the diagnosis** (e.g., "no, the bug only happens when X"): invoke `arn-code-investigator` with the correction and accumulated context. If the fix direction changes as a result, re-invoke `arn-code-architect` to validate.

   - **If the user raises an architectural concern** (e.g., "would this fix break the event system?"): invoke `arn-code-architect` directly with the concern and the current fix proposal.

   - **If the user asks a general question** (e.g., "is this a common issue?", scope questions): answer directly from the conversation context and your own knowledge. No need to invoke an agent.

3. **Summarize the current state** -- after each substantive exchange, briefly state: what is confirmed, what is uncertain, and whether the architect has validated the current fix direction.

4. **Check for convergence** -- when the root cause is confirmed AND the architect has validated the fix direction, proceed to Step 5.

   Do not rush this. Use judgment -- typically after 1-3 rounds of substantive discussion, or when the user signals confidence (e.g., "that's definitely it", "makes sense").

**When invoking arn-code-investigator during the diagnosis loop**, pass this context:

```
Bug: [current refined bug description incorporating all observations]

Codebase context: Pattern documentation was loaded in Step 2. Key patterns
relevant to this bug:
- [list 2-4 specific patterns from the docs that matter]

Prior investigation:
- Root cause identified so far: [current root cause or top hypothesis]
- Evidence gathered: [bullet list of file paths and findings]
- Architect's assessment: [summary of architect's validation or concerns]

Current question: [the specific question or hypothesis to investigate]
```

## Complexity Assessment (Internal) -- Step 5

This is an internal assessment. Do NOT present it to the user as a formal step.

The architect's validation from Step 3/4 feeds directly into this assessment.

**Automatic complex routing:** If the architect flagged the proposed fix as a hack, misaligned with architecture, or needing rethinking, automatically route to Step 6B regardless of the other questions. A fix that does not align with system architecture needs a proper design.

Otherwise, answer these six questions internally:

1. How many files need to change? (1-2 = simple, 3+ = complex)
2. Architectural changes needed? (new abstractions, changed interfaces = complex)
3. Same bug pattern repeats elsewhere? (multiple instances = complex)
4. New dependencies or infrastructure needed? (yes = complex)
5. Can the fix be described in one paragraph? (no = complex)
6. Test work needed? (1-2 test updates + 1-2 new tests = simple, significant test infrastructure = complex)

**If the architect approved the approach AND 5-6 answers are "simple"** --> Step 6A (Simple Fix Path).

**If 2+ answers are "complex"** --> Step 6B (Complex Fix Path).

## Simple Fix Path -- Step 6A

1. **Present the fix proposal:**
   - What to change (specific files, lines, code)
   - Why this fixes the root cause
   - Test plan from the investigator's Test Coverage Assessment:
     - Tests to **fix** (existing tests with wrong assertions)
     - Tests to **add** (coverage gaps the investigator identified)
     - Tests to **verify** (existing tests that should still pass as regression check)

2. **Write the fix plan:** Invoke `arn-code-planner` with the bugfix-plan-template at `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-bug-spec/references/bugfix-plan-template.md` and the inline proposal context. Write to `<project-folder>/FIX_PLAN.md`. Present the plan to the user for review before proceeding.

3. **Create a task list** (via TaskCreate/TaskUpdate) with these tasks:
   - **Task 1: Implement fix** -- apply code changes per the plan
   - **Task 2: Update tests** -- fix broken test assertions + add new tests per the investigator's Test Coverage Assessment
   - **Task 3: Verify** -- run the test suite, confirm all tests pass
   - **Task 4: Write report** -- read BUGFIX_REPORT_TEMPLATE.json from the template path configured in `## Arness`, populate with fix details, test results, and outcome

4. Ask (using `AskUserQuestion`):

   **"How would you like to execute the fix?"**

   Options:
   1. **Execute in this session** -- Implement the tasks sequentially in the main conversation
   2. **Assign to arn-code-bug-fixer** -- Delegate to the bug-fixer agent for autonomous execution

   If **Execute in this session**: proceed to implement the tasks sequentially in the main conversation.
   If **Assign to arn-code-bug-fixer**: invoke the `arn-code-bug-fixer` agent with the fix plan, root cause analysis, test instructions from the investigator's Test Coverage Assessment, relevant codebase context, the report template path (from `## Arness` config), and the report output path. The agent executes all tasks and returns the completed report.

   **Report path:** The bug fix report is written to `<project-folder>/reports/BUGFIX_REPORT.json` (the project folder created in Step 1). Pass this path as the "Report output path" when invoking `arn-code-bug-fixer`.

5. **After execution** (either path), present the bug fix report summary:
   - Status (fixed / partially fixed / needs investigation)
   - Files changed
   - Tests added/modified
   - Final test results
   - Any lessons learned

6. **Simplification (optional):**

   Ask (using `AskUserQuestion`):

   **"Would you like to check the fix for simplification opportunities?"**

   Options:
   1. **Yes** -- Check for simplification opportunities before proceeding
   2. **Skip** -- Proceed to next steps

   If **Yes**: invoke `Skill: arn-code:arn-code-simplify` (auto-detects bugfix scope from BUGFIX_REPORT.json). The SIMPLIFICATION_REPORT.json is written to `<project-folder>/reports/SIMPLIFICATION_REPORT.json`.
   If **Skip**: proceed to next steps.
