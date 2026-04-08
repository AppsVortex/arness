# Agent Invocation Guide

Reference table for when to invoke each agent vs. answer directly during the feature spec exploration phase.

| Situation | Action |
|-----------|--------|
| Initial feature analysis | Invoke `arn-code-architect` (+ `arn-code-ux-specialist` if UI involved) |
| "How does X work in the codebase?" | Invoke `arn-code-architect` |
| "Would this conflict with Y?" | Invoke `arn-code-architect` |
| "What pattern should we use for Z here?" | Invoke `arn-code-architect` |
| "How should the UI for X look?" | Invoke `arn-code-ux-specialist` |
| "What about accessibility?" | Invoke `arn-code-ux-specialist` |
| "Which component library should we use?" | Invoke `arn-code-ux-specialist` |
| User raises UI concern mid-conversation | Invoke `arn-code-ux-specialist` (even if not used in Step 3) |
| User changes direction significantly | Invoke `arn-code-architect` (+ `arn-code-ux-specialist` if UI affected) |
| Feature has security implications (auth, data, APIs, user input) | Invoke `arn-code-security-specialist` (lightweight) |
| "What about security for this?" | Invoke `arn-code-security-specialist` |
| "What security patterns should we follow?" | Invoke `arn-code-security-specialist` |
| Preference question ("REST vs GraphQL?") | Answer directly |
| Scope question ("include X?") | Check scope boundary context first: if X is covered by another feature, answer "that's F-NNN"; if not covered anywhere, ask user |
| General best practices | Answer directly |
| User approves / says "looks good" | Move forward, don't invoke |
| **When greenfield context is loaded:** | |
| "What about edge case X?" | Reference UC extensions directly; invoke `arn-code-architect` only if the edge case isn't covered |
| "What are the business rules?" | Reference loaded business rules from UC documents |
| "Show me the full user flow" | Present UC main success scenario steps |
| "What about error handling?" | Present UC extensions (alternate/error paths) |
| "What did the experts decide about X?" | Reference feature file's Debate Insights |
| "What components do we need?" | Reference feature file's Components section |
| Agent proposes adding functionality beyond this feature's scope | Check scope boundary context: if covered by another feature, note as dependency; if a gap, raise to user |
| "Should we also handle X?" (adjacent concern) | Check scope boundary context before answering; only expand scope if X is a genuine gap |
| "What do the related features cover?" | Summarize loaded scope boundary context (dependency and dependent feature descriptions) |
