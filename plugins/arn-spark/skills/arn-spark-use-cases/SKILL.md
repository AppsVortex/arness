---
name: arn-spark-use-cases
description: >-
  This skill should be used when the user says "use cases", "arn use cases",
  "write use cases", "define use cases", "Cockburn use cases", "actor goals",
  "behavioral requirements", "system behavior", "what does the app do",
  "describe the behavior", "use case document", "document the behavior",
  "define system behavior", or wants to create structured use case documents
  that describe the application's behavior from actor perspectives, producing
  a use-cases/ directory with individual Cockburn fully-dressed use case files
  and a README index.
version: 1.0.0
---

# Arness Use Cases

Create structured use case documents in Cockburn fully-dressed format through a team-based conversational process, aided by the `arn-spark-use-case-writer` agent for drafting and revising, `arn-spark-product-strategist` for business relevance review, and `arn-spark-ux-specialist` for flow quality review (both are greenfield agents in this plugin -- if `arn-spark-ux-specialist` is unavailable, the skill proceeds with product strategist review only). This is a conversational skill that runs in normal conversation (NOT plan mode).

The primary artifacts are a **use-cases/ directory** at the project root containing individual use case files (`UC-NNN-title.md`) and a **README.md** index. Use cases are technology-agnostic behavioral descriptions that serve as the source of truth for what the application does from the actors' perspectives.

Use cases bridge the gap between the high-level product concept and the concrete artifacts consumed by downstream skills. They describe the WHAT (system behavior) not the HOW (implementation). Each use case specifies actors, preconditions, main success scenarios, alternate flows, postconditions, and business rules -- structured detail that the product concept alone does not provide.

For a richer review process where experts debate each other's findings (product strategist and UX specialist cross-review and respond to each other), use `/arn-spark-use-cases-teams` instead. The teams variant produces the same output format but through structured expert debate with mandatory per-round reports.

## Prerequisites

The following artifacts inform the use cases. Check in order:

Determine the use cases output directory:
1. Read the project's `CLAUDE.md` and check for a `## Arness` section
2. If found, extract the configured Use cases directory path — this is the source of truth
3. If no `## Arness` section exists or Arness Spark fields are missing, inform the user: "Arness Spark is not configured for this project yet. Run `/arn-brainstorming` to get started — it will set everything up automatically." Do not proceed without it.
4. If the directory does not exist, create it

> All references to `use-cases/` in this skill refer to the configured use cases directory determined above.

**Product concept (strongly recommended):**
1. Read the project's `CLAUDE.md` for a `## Arness` section. If found, look for a `Vision Directory` field and check that directory for `product-concept.md`
2. If no `## Arness` section found, check `.arness/vision/product-concept.md` at the project root

**If a product concept is found:** Use it as the primary source for actors, goals, and use case derivation.

**If no product concept is found:** Ask the user: "No product concept found. I recommend running `/arn-spark-discover` first to define your product. Alternatively, describe your application's purpose, users, and main capabilities and I will work from that."

**Architecture vision (optional):**
1. Check the same Vision directory (from the `## Arness` section) for `architecture-vision.md`
2. If no `## Arness` section found, check `.arness/vision/architecture-vision.md` at the project root

If found: use for understanding system capabilities, constraints, and platform scope.

**Existing prototype screens (optional):**
1. Read the configured Prototypes directory from the `## Arness` section (default: `.arness/prototypes`)
2. Check for `[prototypes-dir]/clickable/` directories
3. Check for `[prototypes-dir]/static/` directories
4. Check for `[prototypes-dir]/clickable/screen-list.md` (if clickable prototype was run)

If found: screen references can enrich use case steps with concrete screen paths.

**Style brief is NOT needed.** Use cases describe behavior, not visual presentation.

## Workflow

### Step 1: Detect Resume or Fresh Start

Check for existing use case output:

1. Look for `use-cases/README.md` at the project root
2. If found, scan for `use-cases/UC-*.md` files

**If existing use cases found:**

Ask (using `AskUserQuestion`):

**"I found an existing use cases directory with [N] use case files. Which would you prefer?"**

Options:
1. **Continue** — I will read the existing use cases and offer to add new ones or revise existing ones
2. **Fresh start** — I will begin from scratch (existing files will be overwritten)

If continuing: read all existing use case files and the README. Present the current catalog to the user. Ask what they want to change, add, or revise. Skip to the appropriate step (Step 3 for new additions, Step 4 for review of existing, Step 7 for direct user edits).

**If no existing use cases:** Proceed to Step 2.

### Step 2: Identify Actors and Propose Use Case Catalog

This step uses expert agents to help build a comprehensive catalog before any use cases are drafted. The experts do not write use case details here — they identify actors, goals, and candidate use cases from their specialist perspectives.

#### 2a: Initial Extraction

Load the product concept and perform an initial extraction of actors and use cases.

**Actors:** Identify all entities that interact with the system:

- **Primary actors:** Entities that initiate interactions to achieve a goal (e.g., a human user, another application)
- **Secondary actors:** Entities that participate in interactions initiated by primary actors (e.g., a paired device in a communication app, another user being called)
- **Supporting actors:** External systems or services the system depends on (e.g., the operating system for hardware access, a network for connectivity)

**Use cases:** For each actor, identify their goals. Each distinct goal becomes a candidate use case. Organize by level:

- **Summary level:** High-level business goals that span multiple user goals (rare -- most applications have 0-2 of these)
- **User goal level:** What a user sits down to accomplish in one session. This is the most common level. Each user-goal use case should be completable in a single interaction session.
- **Subfunction level:** Steps that are reused across multiple user-goal use cases. These become separate use cases when the substep is complex enough to document independently and is included by 2+ user-goal use cases.

**Relationships:** Identify how use cases connect:
- **Includes:** UC-A contains UC-B as a substep
- **Extends:** UC-B adds optional behavior to UC-A
- **Follows/Precedes:** Temporal ordering (UC-A typically happens before UC-B)

#### 2b: Expert Use Case Discovery

Invoke `arn-spark-product-strategist` with:
- The product concept document
- The initial actor and use case extraction from Step 2a
- Product pillars (if present in the product concept)
- Instructions: "Review this initial actor and use case catalog from a business perspective. Identify: (1) Missing actors — are there stakeholders, external systems, or participant roles not captured? (2) Missing use cases — are there business processes, capabilities described in the product concept, or product pillar implications that do not have a corresponding use case? (3) Priority concerns — are any use cases mislabeled as must-have or should-have? (4) Scope concerns — are any proposed use cases out of scope for v1? Do not draft use case details — just identify what is missing or needs adjustment. Return a list of suggested additions and corrections."

Then invoke `arn-spark-ux-specialist` with:
- The product concept document
- The initial actor and use case extraction from Step 2a
- Existing prototype screens (if available)
- Instructions: "Review this initial actor and use case catalog from a user experience perspective. Identify: (1) Missing user goals — are there interaction patterns, user journeys, or common user needs not captured? Think about first-run experience, error recovery, settings management, and lifecycle events (install, update, uninstall). (2) Missing actors — are there user roles or external systems that participate in UX flows but are not listed? (3) Granularity concerns — are any proposed use cases too broad (should split) or too narrow (should merge)? (4) Missing interaction patterns — cancel, undo, timeout, retry, empty states, accessibility needs. Do not draft use case details — just identify what is missing or needs adjustment. Return a list of suggested additions and corrections."

If `arn-spark-ux-specialist` is unavailable, proceed with the product strategist's suggestions only. Note the limitation.

#### 2c: Merge and Present Consolidated Catalog

Merge the initial extraction with expert suggestions:
- Add any actors or use cases both experts agree are missing
- Add any actors or use cases one expert raised that do not conflict with the other
- Note any disagreements (one expert suggests adding something the other considers out of scope) — present these to the user for resolution
- Apply priority corrections if both experts agree

Present the consolidated actor catalog and proposed use case catalog:

"Based on your product concept and expert analysis, here are the actors and use cases identified:

[If experts contributed additions:] The product strategist suggested [N] additions (business processes, missing actors) and the UX specialist suggested [M] additions (user flows, interaction patterns). These are marked with their source below.

**Actors:**
| Actor | Type | Description | Source |
|-------|------|-------------|--------|
| [Name] | Primary | [brief description] | Initial |
| [Name] | Secondary | [brief description] | Product strategist |
| [Name] | Supporting | [brief description] | UX specialist |

**Proposed Use Cases:**
| UC-ID | Title | Primary Actor | Level | Priority | Source | Notes |
|-------|-------|---------------|-------|----------|--------|-------|
| UC-001 | [Title] | [Actor] | User Goal | Must-have | Initial | [brief note] |
| UC-002 | [Title] | [Actor] | User Goal | Must-have | Product strategist | [brief note] |
| UC-003 | [Title] | [Actor] | Subfunction | Should-have | UX specialist | [included by UC-001, UC-002] |
| ... | ... | ... | ... | ... | ... | ... |

**Relationships:**
```
UC-001 [Title]
  |-- includes UC-003 [Title]
  +-- follows --> UC-002 [Title]

UC-002 [Title]
  +-- extended by UC-004 [Title]
```

[If disagreements exist:] **Needs your input:**
- [Expert A] suggests [addition/change] because [reason]. [Expert B] considers it [out of scope / too granular / etc.] because [reason]. What do you think?

Adjust actors, use cases, priorities, or relationships before I proceed."

Wait for user confirmation or adjustments. The user may add, remove, rename, re-prioritize, or restructure the catalog. The user has final authority — expert suggestions are recommendations, not mandates.

### Step 3: Draft All Use Cases (Parallel)

Draft use cases in parallel by invoking multiple `arn-spark-use-case-writer` agents simultaneously. Each writer receives the full shared context but is assigned a subset of use cases to write.

**Grouping strategy:**
- Group use cases that have direct includes/extends relationships into clusters (e.g., if UC-001 includes UC-005, they go to the same writer). This keeps closely related use cases together for consistent cross-referencing.
- Independent use cases (no includes/extends relationship to other UCs) can each be assigned to their own writer or batched into small groups of 2-3.
- Aim for 3-5 parallel writer invocations. For small catalogs (5 or fewer use cases), a single writer is fine.

**Each writer receives:**
- **Product concept:** document path
- **Actor catalog:** the confirmed actor table
- **Use case catalog:** the FULL confirmed catalog with all relationships (not just the assigned subset)
- **Assigned use cases:** the specific UC-IDs this writer should draft
- **Use case template:** `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-use-cases/references/use-case-template.md`
- **Output directory:** `use-cases/`
- **Existing prototype screens (if any):** paths to prototype directories
- **Architecture vision (if available):** for system capability context

After all parallel writers complete, invoke one final `arn-spark-use-case-writer` with:
- **Index template:** `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-use-cases/references/use-case-index-template.md`
- **Output directory:** `use-cases/`
- **Product concept:** document path
- **Actor catalog and use case catalog:** for populating the index
- Instruction: "Write only the README index. All use case files already exist."

Present a brief summary: "**[N] use cases drafted.** Files written to `use-cases/`. Starting expert review."

### Step 4: Product Strategist Review (Batch)

Read the review protocol for the team process:
> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-use-cases/references/review-protocol.md`

Create the `[use-cases-dir]/reviews/` directory if it does not exist.

Invoke `arn-spark-product-strategist` with:
- All drafted use case content (read each file and provide the content)
- Product concept for context
- Actor catalog
- Expert review template path: `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-use-cases/references/expert-review-template.md`
- File path to write to: `[use-cases-dir]/reviews/round-1-business-review.md`
- Review focus instructions: "Review these use cases from a business perspective. For each use case, assess: Is the goal business-relevant and aligned with the product concept? Is the actor correct? Are the priority and level appropriate? Are there missing alternate flows from a business perspective (policy limits, resource constraints, edge cases)? Are business rules complete? Cross-cutting: are there missing actors or missing use cases for capabilities in the product concept? Is scope appropriate? Write your complete review to the specified file path using the expert review template. Return a brief summary in conversation."

After the strategist completes, read the review file at the specified path to extract the full feedback.

### Step 5: UX Specialist Review (Batch)

Invoke `arn-spark-ux-specialist` with:
- All drafted use case content
- Product concept for context
- Existing prototype screens (if available)
- Expert review template path: `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-use-cases/references/expert-review-template.md`
- File path to write to: `[use-cases-dir]/reviews/round-1-flow-review.md`
- Review focus instructions: "Review these use cases from a user experience perspective. For each use case, assess: Is the main success scenario natural from the actor's perspective? Are steps at the right granularity? Are common interaction patterns covered (cancel, undo, timeout, retry, empty states)? Are error recovery flows present for likely failures? Is accessibility considered? Do preconditions and postconditions make sense as observable states? Are related use cases properly connected? Cross-cutting: is step granularity consistent across use cases? Write your complete review to the specified file path using the expert review template. Return a brief summary in conversation."

If `arn-spark-ux-specialist` is unavailable: proceed with product strategist feedback only. Note the limitation: "UX specialist was unavailable. Review is based on product strategist feedback only."

After the UX specialist completes, read the review file at the specified path to extract the full feedback.

### Step 6: Revise All Use Cases (Batch)

Read the review files written by the experts (not from conversation context):
- `[use-cases-dir]/reviews/round-N-business-review.md`
- `[use-cases-dir]/reviews/round-N-flow-review.md`

Combine feedback from both review files into a consolidated per-use-case list. For each use case, merge product strategist and UX specialist feedback items.

**If feedback conflicts exist** (one expert says something contradicts the other), present the conflict to the user for resolution before sending to the writer:

"Expert feedback conflict on **UC-NNN [Title]**:
- **Product strategist:** [position]
- **UX specialist:** [position]

Which direction should the use case take?"

Once conflicts are resolved, revise use cases in parallel using the same grouping strategy as Step 3. Each `arn-spark-use-case-writer` receives:
- **Existing draft paths:** the current use case files for its assigned UC-IDs
- **Combined per-use-case feedback:** only the feedback for its assigned UCs
- **Use case catalog:** the FULL catalog (for cross-reference awareness)
- **Use case template:** (same path)
- **Output directory:** `use-cases/` (overwrites existing files)

After all parallel writers complete, invoke one final writer to update the README index.

#### Step 6b: Convergence Check

Evaluate the writer's revision report against the convergence criteria in the review protocol:

**Proceed to Step 7 (convergence reached) when:**
- No missing actors flagged by either reviewer
- No missing use cases flagged
- No goals challenged as fundamentally wrong
- All feedback was refinement-level (wording, granularity, additional extensions)
- No conflicting business rules remain

**Trigger one more review round (repeat Steps 4-6) when ANY of these exist:**
- A reviewer flagged a missing actor that was not added
- A reviewer flagged a missing use case that was not created
- A use case goal was challenged and not resolved
- Business rules conflict between use cases
- The writer reported feedback that could not be addressed

Maximum 2 review rounds total. This keeps total agent invocations to 4-7.

Present the revision summary: "[N] use cases revised based on expert feedback. [Summary of major changes]. [Review round status: complete / one more round needed]."

### Step 7: User Review

Present the final use case catalog:

"**Use case authoring complete.**

**Summary:**
- **Use cases:** [N] total ([X] user-goal, [Y] subfunction, [Z] summary)
- **Actors:** [N] actors ([X] primary, [Y] secondary, [Z] supporting)
- **Review rounds:** [N]

**Use Case Catalog:**
| UC-ID | Title | Actor | Level | Priority | Status |
|-------|-------|-------|-------|----------|--------|
| UC-001 | [Title] | [Actor] | User Goal | Must-have | Final |
| UC-002 | [Title] | [Actor] | User Goal | Should-have | Final |
| ... | ... | ... | ... | ... | ... |

All files are in the `use-cases/` directory. Read any use case: `use-cases/UC-001-device-pairing.md`.

Ask (using `AskUserQuestion`):

**"What would you like to do?"**

Options:
1. **Adjust a specific use case** — Tell me which one and what to change
2. **Add new use cases** — I will extend the catalog
3. **Proceed** — Use cases are complete"

If the user wants adjustments: invoke `arn-spark-use-case-writer` with the specific use case and the user's change request.
If the user wants new use cases: return to Step 2 with the additions (existing use cases are preserved).
If the user is satisfied: proceed to Step 8.

### Step 8: Recommend Next Steps

"Use cases saved to `use-cases/`.

These use cases are now available as input for downstream skills:
1. **Scaffold the project:** Run `/arn-spark-scaffold` to set up the development skeleton
2. **Explore visual style:** Run `/arn-spark-style-explore` to establish the visual direction
3. **Prototype the UI:** Run `/arn-spark-clickable-prototype` -- use cases will enrich screen derivation and replace manually defined journeys
4. **Extract features:** Run `/arn-spark-feature-extract` -- use cases provide structured behavioral specs for richer feature extraction

Use cases are living documents. As the project evolves, run `/arn-spark-use-cases` again to add or revise them."

## Agent Invocation Guide

| Situation | Action |
|-----------|--------|
| Expert use case discovery (Step 2b) | Invoke `arn-spark-product-strategist` with product concept + initial catalog for missing actors/use cases from business perspective. Then invoke `arn-spark-ux-specialist` with same + screen refs for missing user flows and interaction patterns. |
| Draft all use cases (Step 3) | Invoke multiple `arn-spark-use-case-writer` agents in parallel, each with full catalog + assigned UC subset. Then one final writer for the README index. |
| Product strategist review (Step 4) | Invoke `arn-spark-product-strategist` with all UC content, business review focus instructions, expert review template path, and file path to write to (`reviews/round-N-business-review.md`). Read the file after completion. |
| UX specialist review (Step 5) | Invoke `arn-spark-ux-specialist` with all UC content, screen refs, flow review focus instructions, expert review template path, and file path to write to (`reviews/round-N-flow-review.md`). Read the file after completion. |
| Revise all use cases (Step 6) | Invoke multiple `arn-spark-use-case-writer` agents in parallel, each with its assigned UC drafts + feedback. Then one final writer for the README index. |
| Second review round (Step 6b) | Repeat Steps 4-6 if convergence criteria not met. Max 2 rounds. |
| User requests specific UC adjustment (Step 7) | Invoke `arn-spark-use-case-writer` with the specific UC path and the user's change description |
| User wants to add new use cases | Return to Step 2 with additions to the catalog |
| User asks about technology choices | Defer: "Use cases describe behavior, not implementation. Technology choices are in `/arn-spark-arch-vision`." |
| User asks about screen design | Defer: "Screen design is handled by `/arn-spark-style-explore` and `/arn-spark-clickable-prototype`. Use cases focus on what the system does, not how it looks." |
| User asks about features | Defer: "Feature extraction happens in `/arn-spark-feature-extract`, which will consume these use cases as input." |
| User asks about implementation specs | Defer: "Implementation specifications are created by `/arn-code-feature-spec`. Use cases provide the behavioral foundation that feature specs build on." |
| Product strategist returns vague feedback | Re-invoke with more specific prompt: "Review each use case individually. For each, provide at least one Critical or Minor feedback item with a specific observation and suggestion." |
| UX specialist unavailable | Proceed with product strategist review only. Note the limitation in all subsequent summaries. |

## Error Handling

- **No product concept found and user declines to describe:** Cannot proceed meaningfully. Suggest: "Run `/arn-spark-discover` first to define what you are building."
- **Product concept is very brief:** Proceed but warn: "The product concept has limited detail. Use cases may be thin and need more revision. Consider expanding the product concept with `/arn-spark-discover` first."
- **arn-spark-use-case-writer fails to write files:** Print the use case content in conversation so the user can copy it manually. Suggest checking file permissions or the output directory path.
- **arn-spark-product-strategist returns unhelpful review:** Re-invoke with more specific instructions referencing the review protocol format. If still unhelpful, proceed to UX specialist review and note the limitation.
- **arn-spark-ux-specialist unavailable:** Proceed with product strategist review only. Note the limitation. The review will be less thorough on flow quality and interaction completeness.
- **User cancels mid-process:** Inform the user that partial use case files exist in `use-cases/` and they can resume later by running `/arn-spark-use-cases` again.
- **Very large number of use cases (>15):** Warn the user: "This is a large number of use cases, which increases review time and token cost. I recommend focusing on must-have use cases first and adding should-have and nice-to-have in a follow-up run."
- **Expert feedback conflicts:** Present the specific conflict to the user with both positions. User resolves before the writer revises.
- **Revision introduces new issues:** Caught by the second review round (Step 6b). Maximum 2 rounds prevents infinite loops.
- **No actors identified from product concept:** Ask the user directly: "I could not identify clear actors from the product concept. Who uses this application and what do they want to accomplish?"
- **Product strategist returns no suggestions in Step 2b:** The initial extraction was already comprehensive. Proceed with the initial catalog.
- **UX specialist unavailable in Step 2b:** Proceed with the initial extraction + product strategist suggestions only. Note the limitation — user flow gaps may be caught later during the UX review in Step 5.
- **Use case level ambiguity:** Default to user-goal level. Only create subfunction use cases when a substep is clearly reused by 2+ user-goal use cases and is complex enough to warrant its own document.
- **Prototype screens change after use cases are written:** Use cases remain valid because they describe behavior, not screens. Screen references can be updated by running `/arn-spark-use-cases` again with the "Continue" option.
- **Writing the index/README fails:** Print the index content in conversation so the user can save it manually.
- **User wants to add a use case during review (Steps 4-6):** Accept the addition. Add it to the catalog and include it in the current or next writer invocation.
- **Resume with corrupted or incomplete files:** Offer a fresh start. If the user wants to preserve partial work, read what exists and present it for the user to decide what to keep.
