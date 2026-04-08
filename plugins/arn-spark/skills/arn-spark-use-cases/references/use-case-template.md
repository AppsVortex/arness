# Use Case Template

This template defines the structure for individual use case documents written by the `arn-spark-use-case-writer` agent. Each use case is saved as a separate file in the `use-cases/` directory as `UC-NNN-kebab-case-title.md`.

A use case describes a single, coherent interaction between an actor and the system to achieve a specific goal. It uses Cockburn's fully-dressed format for completeness while remaining technology-agnostic.

## Instructions for arn-spark-use-case-writer

When populating this template:

- Every field below MUST appear in the output, even if the value is brief or "None"
- Use cases are technology-agnostic: describe behavior ("The system displays"), not implementation ("The mDNS service queries")
- Main success scenario steps follow actor-system alternation where natural: odd steps are actor actions, even steps are system responses (guideline, not rigid)
- Extensions branch from a specific main scenario step and either rejoin the main flow or terminate
- Preconditions must be verifiable states, not assumptions
- Postconditions describe system state, not actor satisfaction
- Business rules are constraints that govern the behavior within this use case
- Screen references are optional -- include only when prototype screens exist and clearly correspond to a step
- Priority and complexity should match the use case catalog agreed with the user
- Related use cases should use the UC-ID format and note the relationship type (includes, extended by, follows, precedes, included by)

---

## Template

```markdown
# UC-[NNN]: [Title]

**Primary Actor:** [The entity that initiates or primarily benefits from this use case]
**Goal:** [What the primary actor wants to accomplish -- one sentence, verb-noun form]
**Scope:** [The system boundary -- what system is being described]
**Level:** [User Goal / Subfunction / Summary]

## Use Case Diagram

\`\`\`mermaid
graph LR
    Actor1((Primary Actor)) --> ThisUC[UC-NNN: Title]
    Actor2((Secondary Actor)) -.participates.-> ThisUC
    ThisUC -.includes.-> IncludedUC[UC-NNN: Included Title]
    ExtendingUC[UC-NNN: Extending Title] -.extends.-> ThisUC
    ThisUC -- follows --> NextUC[UC-NNN: Next Title]
    click IncludedUC "./UC-NNN-included-title.md" "Open use case"
    click ExtendingUC "./UC-NNN-extending-title.md" "Open use case"
    click NextUC "./UC-NNN-next-title.md" "Open use case"
\`\`\`

[Show the primary actor, this use case, any secondary/supporting actors that participate, and all related use cases (includes, extended by, follows, precedes) as connected nodes. Include `click` directives with relative file paths for each related use case node. Remove any relationship lines that do not apply — only show relationships that exist in the Related Use Cases section. If this use case has no relationships, show only the primary actor connected to the use case node.]

## Preconditions

- [Verifiable state that must be true before this use case can begin]
- [Each precondition on its own line]

## Trigger

[What event or actor action starts this use case]

## Main Success Scenario

1. [Actor action or system response]
2. [Next step]
3. [Continue with actor-system alternation where natural]
4. [...]
N. [Final step that achieves the goal]

## Extensions

**[Step]a. [Condition]:**
1. [What happens when the condition is true]
2. [Additional steps if needed]
3. [Rejoin step N of main scenario / Use case ends in failure / Use case ends with partial success]

**[Step]b. [Another condition at the same step]:**
1. [What happens]
2. [Rejoin step N / Use case ends]

[Repeat for each extension point. Extensions are numbered from the main scenario step they branch from.]

## Postconditions

**Success guarantee:** [System state when the main success scenario completes successfully]
**Minimal guarantee:** [System state preserved regardless of outcome -- what is always true after the use case ends, even on failure. Resources released, partial state cleaned up, etc.]

## Business Rules

- [BR-1: Constraint that governs behavior within this use case]
- [BR-2: Another constraint]
- [If none apply, write "None"]

## Related Use Cases

- **Includes:** [UC-NNN Title] -- [why this is included as a substep]
- **Extended by:** [UC-NNN Title] -- [what optional behavior it adds]
- **Follows:** [UC-NNN Title] -- [what typically happens after this use case]
- **Precedes:** [UC-NNN Title] -- [what typically happens before this use case]
- **Included by:** [UC-NNN Title] -- [which use case contains this one as a substep]
- [If no relationships, write "None"]

## Metadata

- **Priority:** [Must-have / Should-have / Nice-to-have]
- **Complexity:** [S / M / L / XL]
- **Screen References:** [Summary list of prototype screen paths referenced in this use case, e.g., "setup/welcome, setup/pairing". Individual steps may also have inline screen annotations (e.g., "Screen: setup/welcome") where the system presents information. This field summarizes all referenced screens. "None" if no prototype screens exist.]
```

---

## Section Guidance

| Section | Guidance | Common Mistakes |
|---------|----------|-----------------|
| Use Case Diagram | Mermaid `graph LR` showing this UC's actor(s) and related UCs as linked nodes. Include `click` directives with relative `.md` file paths. Only show relationships that exist. | Including UCs that are not in the Related Use Cases section. Forgetting `click` directives. Using `graph TB`/`graph TD` for per-UC diagrams (use `graph LR` for horizontal layout; `TB` is reserved for the system-level index diagram). |
| Primary Actor | The entity initiating the interaction. Always external to the system boundary. | Naming the system as actor. The system responds, it does not initiate use cases. |
| Goal | One sentence, verb-noun form ("Pair with a new device", "Initiate a voice call") | Too vague ("Use the app") or too implementation-specific ("Send mDNS query") |
| Scope | The system being described. Usually the application name. | Listing subsystems instead of the whole system boundary |
| Level | User Goal = what a user sits down to do; Subfunction = a step reused by multiple user goals; Summary = spans multiple user goals | Defaulting everything to User Goal. If a use case is always invoked within another, it is likely a Subfunction. |
| Preconditions | States that must be true BEFORE the trigger. Must be verifiable. | Including things that happen AS PART of the use case. "App is running" is a precondition. "User has opened settings" is a precondition only if the use case does not start by opening settings. |
| Trigger | The specific event that starts the flow. One sentence. | Confusing the trigger with the first step of the main scenario. The trigger is what initiates; step 1 is the first action. |
| Main Success Scenario | Happy path only, typically 4-12 steps. Actor-system alternation. | Including error handling (belongs in extensions). Steps that are too granular ("User moves cursor to button") or too vague ("System handles the request"). |
| Extensions | Branch from a specific step number. Specify rejoin or termination. | Vague branching ("at any point") -- be specific about which step. Forgetting to specify where the extension rejoins or terminates. |
| Postconditions | Observable system state after the use case ends. | Describing actor emotions ("User is satisfied") or vague outcomes ("Everything works"). State what is TRUE about the system. |
| Business Rules | Constraints governing THIS use case specifically. | Generic rules not specific to this use case ("The system must be secure"). Business rules are concrete: "Maximum 8 participants per call", "Pairing requires physical proximity". |
| Related Use Cases | Explicit relationship type with UC-ID. Bidirectional. | Listing related use cases without the relationship type. If UC-001 includes UC-005, then UC-005 must list "Included by UC-001". |
| Screen References | Optional. Only when prototype screens exist. Relative paths. | Inventing screen references when no prototype exists. Screen references are enrichment, not required. |
