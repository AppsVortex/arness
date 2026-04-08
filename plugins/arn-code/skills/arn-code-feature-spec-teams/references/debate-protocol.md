# Debate Protocol

This document defines the round-by-round structure for team-based feature specification debates in `arn-code-feature-spec-teams`.

> **Note:** When greenfield context is loaded (Step 1b of the skill), additional context blocks (feature file, UC documents, style-brief, scope boundaries) are appended to each teammate's spawn prompt. The examples below show the standard (non-greenfield) prompts. See Step 4 in SKILL.md for the complete prompt structure including greenfield context.

## Round Structure

### Round 1: Proposals

**Goal:** Each teammate independently analyzes the feature and produces a proposal.

**Process:**
1. Lead sends the feature idea and codebase context to all teammates simultaneously
2. Each teammate produces their proposal independently (no cross-communication yet)
3. Lead collects all proposals

**Architect proposal should include:**
- Proposed architecture (components, data flow, API design)
- Integration points with existing codebase
- Technology choices and rationale
- Risk assessment
- Testing strategy outline

**UX specialist proposal should include (when present):**
- User flow mapping (screens, transitions, user journey)
- Component hierarchy and props
- Accessibility requirements (WCAG level, keyboard navigation, screen reader support)
- State management approach (local vs. shared vs. server state)
- Responsive design strategy
- If greenfield: proposed UI stack with rationale

**Lead output to user:** Brief summary of each proposal — what each teammate recommends and where they differ.

---

### Round 2: Critique

**Goal:** Each teammate evaluates the other(s)' proposals, identifying weaknesses and trade-offs.

**Process:**
1. Lead shares each proposal with the other teammate(s)
2. Each teammate critiques the others:
   - What are the weaknesses of this approach?
   - What trade-offs does it introduce?
   - What risks does it not address?
   - Where does it conflict with documented patterns or project conventions?
3. Lead collects critiques

**Lead output to user:** Summary of tensions (where teammates disagree) and alignment (where they agree). Frame disagreements as trade-offs, not right/wrong.

---

### Round 3: Revision

**Goal:** Teammates address critiques by revising their proposals.

**Process:**
1. Lead shares each critique with the original proposer
2. Each teammate revises their proposal:
   - Accept valid criticisms and adjust
   - Defend positions where the critique misses context
   - Identify compromises that address both perspectives
3. Lead collects revised proposals

**Convergence check:** Compare revised proposals. If all open tensions are resolved (teammates have converged on approach), skip Round 4 and proceed to synthesis.

**Lead output to user:** What changed, what remains unresolved. If converged, announce: "The team has converged on an approach."

---

### Round 4: Resolution (if needed)

**Goal:** Resolve remaining disagreements through user decision.

**Trigger:** Only runs if Round 3 did not achieve convergence.

**Process:**
1. Lead presents each unresolved disagreement to the user:
   - Position A (who holds it and why)
   - Position B (who holds it and why)
   - Trade-off summary
2. User decides for each disagreement
3. Lead communicates decisions to teammates

**Lead output to user:** Final resolved approach incorporating user decisions.

---

## Convergence Criteria

Debate is considered **converged** when:
- All teammates agree on the core approach (architecture, components, data flow)
- Remaining differences are minor (naming, implementation details) not structural
- No teammate has raised an unaddressed concern about feasibility, performance, or user experience

## Escalation Rules

- **Same disagreement persists across 2 consecutive rounds:** Escalate to user immediately. Do not continue debating — present both positions and ask for a decision.
- **4 rounds completed without convergence:** Force synthesis from current state. Present remaining disagreements as "Open Items" in the specification.
- **Teammate becomes unresponsive:** Continue with remaining teammates. Note the gap in the debate summary.

## Example Teammate Spawn Prompts

### Architect Debate Prompt
```
You are a senior software architect participating in a team debate about a new feature.

Feature: [feature description]

Codebase context:
[code-patterns.md content]
[testing-patterns.md content]
[architecture.md content]
[ui-patterns.md content, if present]

Your role: Analyze this feature from an architectural perspective. Propose an
implementation approach grounded in the project's documented patterns. Focus on:
system design, data flow, API design, integration with existing architecture,
error handling, testing strategy, and performance considerations.

When critiquing other proposals, be specific about trade-offs and back up
concerns with references to documented patterns or architectural principles.
When revising, explicitly address each critique — accept, reject with
justification, or compromise.
```

### UX Specialist Prompt (Existing Frontend)
```
You are a UI/UX specialist participating in a team debate about a new feature.

Feature: [feature description]

Codebase context:
[ui-patterns.md content]
[architecture.md content]
[code-patterns.md content]

Operating mode: Existing frontend — map proposals to documented UI conventions.
Reference existing components, styling approach, and state management.

Your role: Advocate for the user experience perspective. Propose component
architecture, user flows, accessibility requirements, responsive design, and
state management. When critiquing architectural proposals, focus on usability
impact: will users find this intuitive? Is it accessible? Does it handle loading
and error states well?

When revising, maintain UX advocacy while finding practical compromises with
architectural constraints.
```

### UX Specialist Prompt (Greenfield Frontend)
```
You are a UI/UX specialist participating in a team debate about a new feature.
This project currently has no frontend — you are recommending a UI stack from scratch.

Feature: [feature description]

Codebase context:
[architecture.md content]
[code-patterns.md content]

Operating mode: Greenfield frontend — recommend a complete UI stack. Justify
every choice. Mark all references as "Recommended". Include a "Proposed UI Stack"
section with: component library, styling approach, state management, design system.

Consider compatibility with the existing backend stack when making recommendations.

Your role: Same as existing frontend mode, plus: propose the foundational UI
technology choices that the project will adopt. These choices have long-term
impact — be opinionated but justify every recommendation.
```

### Security Specialist Prompt (Existing Patterns)
```
You are a security specialist participating in a team debate about a new feature.

Feature: [feature description]

Codebase context:
[security-patterns.md content]
[architecture.md content]
[code-patterns.md content]

Operating mode: Existing security patterns — ground analysis in documented security
conventions. Reference existing authentication, authorization, input validation, and
data protection implementations.

Your role: Advocate for secure-by-default design. Identify threats from the OWASP Top
10 that apply to this feature. Propose mitigations grounded in the project's documented
security patterns. Challenge architectural proposals that introduce security risks:
missing input validation, insecure data handling, broken authentication, excessive
permissions.

When critiquing other proposals, be specific about threat scenarios and reference
documented security patterns. When revising, maintain security advocacy while finding
practical compromises with architectural and UX constraints.
```

### Security Specialist Prompt (Greenfield)
```
You are a security specialist participating in a team debate about a new feature.
This project does not yet have documented security patterns — you are recommending
security measures from scratch.

Feature: [feature description]

Codebase context:
[architecture.md content]
[code-patterns.md content]

Operating mode: Greenfield security — recommend security measures based on the
architecture. Cover OWASP Top 10 applicable risks. Mark all references as "Recommended".

Your role: Same as existing patterns mode, plus: propose the foundational security
measures the project should adopt. These choices have long-term impact — be opinionated
but justify every recommendation. Consider the technology stack when recommending
specific libraries and approaches.
```

## Output Expectations Per Round

| Round | Lead collects from each teammate | Lead presents to user |
|-------|---|----|
| 1. Proposals | Full proposal document | Brief summary of each proposal + key differences |
| 2. Critique | Critique of each other proposal | Tensions (disagreements) and alignment (agreements) |
| 3. Revision | Revised proposal addressing critiques | What changed, what remains unresolved, convergence status |
| 4. Resolution | N/A (user decides) | Final approach with all decisions captured |
