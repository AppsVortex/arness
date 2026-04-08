# Agent Invocation Guide

When to invoke each agent vs. answer directly during the arn-code-bug-spec workflow:

| Situation | Action |
|-----------|--------|
| Initial bug investigation | Invoke `arn-code-investigator` |
| Investigator proposes fix direction | Invoke `arn-code-architect` to validate against architecture |
| Fix direction changes during diagnosis | Re-invoke `arn-code-architect` to re-validate |
| "What does the code do at X?" | Invoke `arn-code-investigator` with specific hypothesis |
| "Could the bug be in Y?" | Invoke `arn-code-investigator` with specific hypothesis |
| User provides new symptoms | Invoke `arn-code-investigator` with updated context |
| "Would this fix break the architecture?" | Invoke `arn-code-architect` |
| Architect flags fix as hack/misaligned | Route to complex path (Step 6B) |
| Simple fix -- "write small plan first" | Invoke `arn-code-planner` with bugfix template + inline proposal -> `<project-folder>/FIX_PLAN.md` |
| Simple fix -- execute or assign | Invoke `arn-code-bug-fixer` (if user assigns) or execute directly |
| Complex fix -- design approach | Invoke `arn-code-architect` |
| Complex fix -- write bug spec | Write directly using the template -- no agent needed |
| "Is this a common issue?" | Answer directly |
| Scope question | Answer directly |
| User confirms / agrees | Move forward, don't invoke |
