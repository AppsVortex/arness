---
name: arn-spark-arch-vision
description: >-
  This skill should be used when the user says "arch vision", "architecture
  vision", "arn arch vision", "define the architecture", "tech stack",
  "what technology should I use", "design the system", "system architecture",
  "how should I build this", "technology choices", "choose technologies",
  "pick a tech stack", or wants to explore
  technology options and define the high-level architecture for a greenfield
  project. Takes a product concept as input and produces an
  architecture-vision.md document capturing the technology stack, system
  design, protocols, packaging strategy, and known risks.
version: 1.0.0
---

# Arness Arch Vision

Explore technology options and define the system architecture for a greenfield project through iterative conversation, aided by technology research from the `arn-spark-tech-evaluator` agent. This is a conversational skill that runs in normal conversation (NOT plan mode). The primary artifact is an **architecture vision document**.

This skill covers the HOW at a high level: what technologies to use and how the system is structured. It does not cover implementation details like file structure, specific APIs, or code patterns -- that is the plan's job (via `/arn-code-plan`).

## Step 0: Ensure Configuration

Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-ensure-config/references/ensure-config.md` and follow its instructions. This guarantees a user profile exists and `## Arness` is configured with Arness Spark fields before proceeding.

After Step 0 completes, extract from `## Arness`:
- Vision directory, Use cases directory, Prototypes directory, Spikes directory, Visual grounding directory, Reports directory

## Prerequisites

A product concept document should exist. Check in order:

1. Check the configured Vision directory for `product-concept.md`
2. If not found, check `.arness/vision/product-concept.md` at the project root

**If a product concept is found:** Read it and proceed to Step 1.

**If no product concept is found:** Inform the user:

"No product concept document found. I recommend running `/arn-spark-discover` first to define what you are building. Alternatively, you can describe your product briefly and I will work with that."

If the user provides an inline description, proceed with that as the product context. Do not hard-block.

Determine the output directory:
1. Use the Vision directory path from `## Arness` — this is the source of truth
2. If the output directory does not exist, create it

## Workflow

### Step 1: Load Product Concept and Extract Requirements

Read the product concept document (or use the inline description). Extract two things:

**Product Pillars:** If the product concept contains a Product Pillars section, extract all pillars. These are non-negotiable qualities that every technology choice must serve or, at minimum, not compromise. Examples: "design fidelity" means the UI framework must support high polish; "zero configuration" means the packaging and distribution must be frictionless; "privacy-first" means the network layer must support end-to-end encryption natively.

**Technical requirements by category:**

- **Target platforms:** Operating systems, versions, deployment targets
- **Real-time requirements:** Latency needs, streaming, P2P, bidirectional communication
- **Security requirements:** Trust model, encryption, authentication mechanism
- **Scale requirements:** Number of participants, topology, data volume
- **UI requirements:** Complexity, animations, native feel, accessibility
- **Distribution requirements:** Installer type, app store, auto-updates
- **Business & operational constraints:** Business model (B2B/B2C/SaaS), multi-tenancy requirements (tenant count, isolation level), regulatory compliance (GDPR/HIPAA/SOC2), cost/budget limits, vendor constraints, licensing requirements, team experience, timeline pressures

Present both to the user:

"Based on your product concept, here are the **product pillars** that will guide technology decisions:
- **[Pillar]:** [what it means for architecture choices]
- ...

And the key **technical requirements:** [bullet list].

Does this capture everything correctly, or should I adjust anything before we explore technology options?"

If no pillars were found in the product concept (e.g., it was written before the pillars feature, or the user provided an inline description), ask: "I did not find product pillars in your concept. Are there non-negotiable qualities -- like performance, polish, simplicity, privacy -- that should influence technology choices?"

Wait for user confirmation or corrections before proceeding.

### Step 2: Initial Technology Exploration

Read the user profile for expertise context. Check `.claude/arness-profile.local.md` first (project override takes precedence), then `~/.arness/user-profile.yaml`. Also check `.arness/preferences.yaml` for project-level team preferences.

Invoke the `arn-spark-tech-evaluator` agent with:
- The product concept (or extracted requirements)
- The full set of technical requirements from Step 1
- The product pillars from Step 1
- Any technology preferences or constraints the user has mentioned
- User expertise context (structured blocks below)

Include in the agent invocation context:

```
--- BEGIN USER EXPERTISE ---
[Read from ~/.arness/user-profile.yaml or .claude/arness-profile.local.md (project override takes precedence)]
Role: [role]
Experience: [development_experience]
Technology preferences: [technology_preferences]
Expertise-aware: [expertise_aware]
--- END USER EXPERTISE ---

--- BEGIN PROJECT PREFERENCES ---
[Read from .arness/preferences.yaml if it exists, otherwise omit this section]
--- END PROJECT PREFERENCES ---
```

If `expertise_aware: true` and the user lists relevant technologies, add "Team has strong [X] experience" as an IMPORTANT (not CRITICAL) criterion in the comparison matrix. If `development_experience: learning`, add explanatory notes for complex technologies and flag steep learning curves. If `development_experience: non-technical`, favor the most mainstream, well-documented options. Apply the advisory pattern: present the technically optimal recommendation first, then a preference-aligned alternative with pros/cons if they differ.

The agent returns:
- A requirements summary table (with pillar-derived criteria marked)
- Candidate technologies per architectural layer with comparison matrices
- Pillar alignment assessment per recommendation
- Validation points and risk assessment
- An initial stack recommendation with rationale

Present the findings to the user as a conversation starter. Highlight:
- The recommended stack and why
- How the stack serves (or challenges) each product pillar
- Key trade-offs and alternatives considered
- Critical validation points that need early testing

Frame it as: "Here is my initial technology assessment. Let's discuss each layer and make sure we are aligned."

### Step 3: Architecture Exploration (Iterative)

Enter a conversation loop. Cover these architectural categories (not necessarily in order -- follow the user's interests):

1. **Application Framework** -- Desktop, web, mobile, cross-platform runtime
2. **UI Framework** -- Rendering approach, component library, animation capability
3. **Network & Communication** -- Protocols for discovery, signaling, data transport
4. **Security & Identity** -- Cryptographic identity, trust establishment, encryption
5. **Data Storage & Persistence** -- Config storage, state persistence, caching
6. **Platform Integration** -- OS-specific features, permissions, system tray, device management
7. **Packaging & Distribution** -- Installers, code signing, auto-updates, firewall rules
8. **Known Risks** -- Technical risks with specific mitigations and fallbacks

**Within each round of conversation, decide how to respond:**

| Situation | Action |
|-----------|--------|
| User asks "which is better, X or Y?" | Load `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-arch-vision/references/technology-evaluation-guide.md` if not already loaded, then invoke `arn-spark-tech-evaluator` with head-to-head comparison request |
| User asks "will X work for our use case?" | Invoke `arn-spark-tech-evaluator` with validation question |
| User asks about a technology's current status | Invoke `arn-spark-tech-evaluator` (uses WebSearch to verify) |
| User wants a full recommendation for a layer | Invoke `arn-spark-tech-evaluator` with layer evaluation request |
| User makes a technology decision | Record directly, confirm the decision and note implications |
| User asks about code patterns or project structure | Defer: "Good question -- code patterns will be set up automatically when the project transitions to development. For now, let's focus on which technologies to use." |
| User asks a product/scope question | Defer: "That is a product question. We can revisit the product concept if needed, but let's finish the architecture first." |
| User seems done or conversation is circling | Proceed to readiness check |

**Tracking coverage:** Track which architectural layers have been decided. A layer is "covered" when the user has agreed to a specific technology or explicitly deferred the decision.

**Readiness check:** After covering the major layers (typically 4-8 rounds), check:

"I think we have the architecture mapped out. Here is a summary of the stack: [brief table].

**Pillar alignment:** [For each pillar, a one-line assessment of how the chosen stack serves it. Flag any pillar that is not fully supported — e.g., 'Design fidelity: Strong — Svelte + shadcn-svelte provides full component customization' or 'Zero configuration: At risk — code signing requires manual certificate setup on first build.']

Ready for me to write the architecture vision document, or do you want to explore any area further?"

### Step 4: Write the Architecture Vision Document

When the user is ready:

1. Read the template:
   > Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-arch-vision/references/architecture-vision-template.md`

2. Populate the template with all decisions from the conversation:
   - Replace all bracketed placeholders with concrete content
   - Build the Technology Stack table with every layer discussed
   - Create an ASCII architecture diagram showing major components
   - Adapt section names to match the product domain
   - For Known Risks, include specific mitigations and fallbacks (not vague assurances)
   - Map Future Architecture Considerations to items from the product concept's "Future Considerations"

3. Write the document to the output directory as `architecture-vision.md`

4. Present a summary to the user:
   - List the document path
   - Show the final technology stack table
   - Highlight critical validation points that need early attention
   - Note any decisions that were deferred or need further investigation

### Step 5: Recommend Next Steps

After writing the document, inform the user:

"Architecture vision saved to `[path]/architecture-vision.md`.

You now have both product concept and architecture vision defined. Recommended next steps:

1. **Start developing:** If you have the Arness Code plugin installed, run `/arn-planning` to begin the development pipeline. Arness auto-configures code patterns based on your architecture choices.
2. **Scaffold the project:** Set up the development environment with your chosen stack
3. **Validate critical risks:** [list the top 1-2 validation points from the document]
4. **Start feature specs:** Run `/arn-code-feature-spec` to spec your first feature"

Adapt the next steps based on what makes sense for the project. If critical validation points were identified, emphasize those as the immediate priority.

## Agent Invocation Guide

| Situation | Action |
|-----------|--------|
| Initial technology exploration (Step 2) | Invoke `arn-spark-tech-evaluator` with full requirements |
| "Which is better, X or Y?" | Invoke `arn-spark-tech-evaluator` with comparison request |
| "Will X work for our use case?" | Invoke `arn-spark-tech-evaluator` with validation question |
| "What is the current state of X?" | Invoke `arn-spark-tech-evaluator` (uses WebSearch) |
| Full layer recommendation needed | Invoke `arn-spark-tech-evaluator` with layer evaluation |
| User makes a technology decision | Record directly, no agent needed |
| Architecture pattern question | Answer directly from conversation context |
| Product or scope question | Defer to product concept or `/arn-spark-discover` |

## Error Handling

- **User cancels mid-conversation:** Confirm cancellation. If enough decisions have been made for a partial document, offer to write it. Otherwise, inform the user they can restart with `/arn-spark-arch-vision` at any time.
- **arn-spark-tech-evaluator returns unhelpful response:** Summarize the issue briefly and continue the conversation directly. Try a more specific or narrower question on the next agent invocation.
- **WebSearch unavailable (for arn-spark-tech-evaluator):** The agent will fall back to its training data. Note to the user that technology recommendations have not been verified against current release status and suggest the user manually check version currency for critical choices.
- **Writing the document fails:** Print the full document content in the conversation so the user can copy it. Suggest checking file permissions or the output directory path.
- **Architecture vision already exists:**

  Ask (using `AskUserQuestion`):

  > **An architecture vision already exists at `[path]`. How would you like to proceed?**
  > 1. **Replace** — Start a fresh architecture exploration
  > 2. **Update** — Focus on specific sections that need changes

  If **Update**, read the existing document and focus the conversation on the sections that need changes.
- **No product concept and user declines to describe product:** Cannot proceed meaningfully. Suggest: "Without understanding what we are building, technology choices would be arbitrary. Run `/arn-spark-discover` first to define the product, then come back to architecture."
