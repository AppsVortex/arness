# Use Case Index Template

This template defines the structure for the `use-cases/README.md` file written by the `arn-spark-use-case-writer` agent. This file serves as the entry point for the use case directory, providing an overview of the application's behavior, a complete actor catalog, a use case index with links, and a relationship diagram.

## Instructions for arn-spark-use-case-writer

When populating this template:

- The introduction should summarize what the application does in 2-3 paragraphs, derived from the product concept but focused on system behavior (what it does), not identity (what it is)
- The actor catalog must include every actor referenced in any use case file
- The use case index must link to every UC file in the directory using relative paths
- The use case diagram should show all actors and use cases with their relationships as a Mermaid `graph TB` diagram, with `click` directives linking to UC files. Keep the text relationship summary below for accessibility.
- Coverage notes should honestly assess completeness -- note known gaps
- Update this file whenever use cases are added, removed, or restructured

---

## Template

```markdown
# [Product Name] -- Use Cases

## Introduction

[2-3 paragraphs summarizing the application's behavioral scope. Describe what the system does from the actors' perspectives. Readers should understand the full range of behaviors the application supports from this introduction alone.

Focus on behavior, not identity. Instead of "Talkie is a walkie-talkie app", write "The system enables real-time voice communication between devices on a local network. Users discover nearby devices, pair with them, and initiate voice calls with a single action. Optional video and text capabilities extend the core voice experience."]

## Actor Catalog

| Actor | Type | Description |
|-------|------|-------------|
| [Name] | Primary | [What this actor is, what they want from the system, and how they interact with it] |
| [Name] | Secondary | [What this actor is and how it participates in interactions initiated by primary actors] |
| [Name] | Supporting | [What this external system or service provides to the system] |

**Actor types:**
- **Primary:** Initiates interactions with the system to achieve a goal
- **Secondary:** Participates in interactions initiated by primary actors (e.g., a paired device, another user)
- **Supporting:** External systems or services that the system depends on (e.g., operating system, network)

## Use Case Index

| UC-ID | Title | Primary Actor | Level | Priority | File |
|-------|-------|---------------|-------|----------|------|
| UC-001 | [Title] | [Actor] | User Goal | Must-have | [UC-001-title.md](./UC-001-title.md) |
| UC-002 | [Title] | [Actor] | User Goal | Must-have | [UC-002-title.md](./UC-002-title.md) |
| UC-003 | [Title] | [Actor] | Subfunction | Should-have | [UC-003-title.md](./UC-003-title.md) |
| ... | ... | ... | ... | ... | ... |

## Use Case Diagram

\`\`\`mermaid
graph TB
    %% Actors
    Actor1((Actor Name))
    Actor2((Actor Name))

    %% Use Cases
    UC001[UC-001: Title]
    UC002[UC-002: Title]
    UC003[UC-003: Title]
    UC004[UC-004: Title]

    %% Actor-UseCase connections
    Actor1 --> UC001
    Actor1 --> UC002
    Actor2 -.participates.-> UC002

    %% Relationships
    UC001 -.includes.-> UC003
    UC004 -.extends.-> UC001
    UC001 -- follows --> UC002

    %% Click links (relative paths to UC files)
    click UC001 "./UC-001-title.md" "Open use case"
    click UC002 "./UC-002-title.md" "Open use case"
    click UC003 "./UC-003-title.md" "Open use case"
    click UC004 "./UC-004-title.md" "Open use case"
\`\`\`

[Show ALL actors and ALL use cases with their relationships. Use `graph TB` (top-to-bottom) for the system-level overview. Include:
- All actors as `((Actor Name))` circle nodes
- All use cases as `[UC-NNN: Title]` rectangle nodes
- Solid arrows `-->` for actor-to-use-case connections (primary actors)
- Dotted arrows `-.participates.->` for secondary actor connections
- Dotted arrows `-.includes.->` for includes relationships
- Dotted arrows `-.extends.->` for extends relationships
- Solid arrows `-- follows -->` for temporal ordering
- `click` directives with relative file paths for every use case node
- Remove any example nodes/lines that do not apply — only show actual actors, use cases, and relationships from the catalog]

## Use Case Relationships

[Text summary of relationships for accessibility and searchability. One line per use case with relationships:]

- **UC-001 [Title]:** includes UC-003, extended by UC-004, follows → UC-002
- **UC-002 [Title]:** includes UC-005, extended by UC-006
- **UC-003 [Title]** (subfunction): included by UC-001, UC-002

## Coverage Notes

**Actors fully covered:** [List actors whose goals are all captured in use cases above]

**Actors partially covered:** [List actors with known goals not yet captured, and what is missing]

**Known gaps:** [Behaviors mentioned in the product concept or discussed with the user that are not yet written as use cases. Note why -- deferred, out of scope, or pending clarification.]
```
