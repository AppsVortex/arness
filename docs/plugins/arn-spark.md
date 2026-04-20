---
title: "Arness Spark"
description: "Product discovery and prototyping — from raw idea to validated, feature-ready codebase"
sidebar:
  order: 10
---

![Arness Spark](../../assets/spark.png)

[![Docs](https://img.shields.io/badge/docs-arness.appsvortex.com-7e3ff2?logo=astro&logoColor=white)](https://arness.appsvortex.com/)

Spark is where ideas come alive. It is the ideation plugin that takes you from "I have an idea" to "I have a validated, feature-ready codebase." Most projects fail before the first line of code -- wrong problem, wrong audience, wrong architecture. Spark is the antidote: structured discovery, adversarial validation, and interactive prototyping before you commit to building.

## Start Here

The fastest way to use Spark is the brainstorming wizard:

**`/arn-brainstorming`** -- a guided session that walks through the entire greenfield pipeline with decision gates at every stage. You never have to remember what comes next; the wizard handles sequencing, progress tracking, and resumability. Leave mid-session and pick up where you left off.

To customize the greenfield configuration (e.g., set up Figma or Canva integration), you can optionally run **`/arn-spark-init`** — but it's not required. Arness auto-configures on first use.

Spark uses progressive questioning -- it asks once and remembers your answers across sessions. Configuration choices, user profile details, and project preferences are captured during the first run and reused automatically, so subsequent sessions start faster and stay focused on the work.

## The Pipeline

```mermaid
flowchart LR
    A[Discover] --> B[Stress Test] --> C[Name] --> D[Architecture]
    D --> E[Use Cases] --> F[Scaffold] --> G[Spike]
    G --> H[Visual Sketch] --> I[Style] --> J[Prototype]
    J --> K[Lock] --> L[Feature Extract] --> M[Development]

    style A fill:#3a2800,stroke:#F5C542,color:#F5C542
    style B fill:#3a2800,stroke:#F5C542,color:#F5C542
    style C fill:#3a2800,stroke:#F5C542,color:#F5C542
    style D fill:#3a2800,stroke:#F5C542,color:#F5C542
    style E fill:#3a2800,stroke:#F5C542,color:#F5C542
    style F fill:#3a2800,stroke:#F5C542,color:#F5C542
    style G fill:#3a2800,stroke:#F5C542,color:#F5C542
    style H fill:#3a2800,stroke:#F5C542,color:#F5C542
    style I fill:#3a2800,stroke:#F5C542,color:#F5C542
    style J fill:#3a2800,stroke:#F5C542,color:#F5C542
    style K fill:#3a2800,stroke:#F5C542,color:#F5C542
    style L fill:#3a2800,stroke:#F5C542,color:#F5C542
    style M fill:#0077B6,stroke:#00B4D8,color:#fff
```

Every step is optional. The brainstorming wizard presents decision gates at each transition -- skip what you do not need, deep-dive where it matters. You can also invoke any skill directly by name if you already know where you are in the pipeline.

---

## Workflow 1: Discover and Validate

Start with a raw idea. End with a structured product concept and system architecture.

### Product Discovery

**`/arn-spark-discover`** runs an iterative conversation backed by three specialist agents -- a product strategist, a market researcher, and a persona architect. Through guided exploration, it produces a **product concept document** capturing:

- Product vision and core experience
- Problem statement and target users
- Persona moulds for your audience
- Competitive landscape analysis
- Product pillars -- the non-negotiable qualities that define the product's soul

This is the foundation that every downstream skill builds on.

### Architecture Vision

**`/arn-spark-arch-vision`** picks up where discovery leaves off, exploring technology choices and system design. It produces an architecture vision document covering stack selection, system boundaries, data flow, and deployment topology -- the HOW to discovery's WHAT and WHY.

### Use Cases

**`/arn-spark-use-cases`** generates Cockburn fully-dressed use cases from the product concept: primary actors, preconditions, main success scenarios, extensions, and postconditions. Each use case goes through expert review for completeness and consistency.

**`/arn-spark-use-cases-teams`** takes it further with a structured team debate -- multiple expert perspectives argue over edge cases, business rules, and missing flows before the use cases are finalized.

---

## Workflow 2: Stress Test Your Concept

This is where Spark has no competition. Every AI coding tool helps you build. None of them help you figure out whether you *should* build. Spark's stress testing suite applies four distinct adversarial methodologies to your product concept, surfacing the failure modes that optimism obscures -- before you write a single line of production code.

All four stress tests are **read-only on the product concept**. They analyze, critique, and recommend, but never modify the source of truth. Only `/arn-spark-concept-review` consolidates findings and applies approved changes. One document, one point of modification, zero drift.

### Synthetic User Interviews

**`/arn-spark-stress-interview`** generates three synthetic personas from your product concept's persona moulds, then applies adversarial casting overlays -- the **Pragmatist** (will this actually work in my workflow?), the **Skeptic** (why should I trust this over what I already use?), and the **Power User** (where does this break at scale?). Each persona goes through a structured "Two-Part Reveal" interview protocol:

1. **Blind Problem Check** -- the persona hears about the problem without knowing the product exists. Do they even care?
2. **Elevator Pitch Reveal** -- the full concept is revealed. What resonates? What falls flat? What is missing?
3. **Dealbreaker Probe** -- the weakest aspects are presented head-on. Would they still use this?

The result is brutally honest feedback from three distinct perspectives, synthesized into actionable recommendations.

### Competitive Gap Analysis

**`/arn-spark-stress-competitive`** goes beyond surface-level feature comparison. A market researcher agent conducts deep competitive intelligence, builds feature matrices categorized by core, differentiating, and table-stakes capabilities, and assesses your positioning for defensibility, switching costs, and underserved market gaps. You learn not just where you stand, but where the openings are.

### Pre-Mortem

**`/arn-spark-stress-premortem`** applies Gary Klein's pre-mortem methodology. Instead of asking "what could go wrong?" (which invites optimism bias), it declares that your product launched 12 months ago and was shut down today. A forensic investigator agent works backward from the failure to identify **three distinct root causes**: a core experience flaw, a trust/security blind spot, and a target audience assumption error. Each gets a full causal chain, early warning signals, mitigation strategies, and a likelihood/severity rating mapped on a risk priority matrix.

### PR/FAQ

**`/arn-spark-stress-prfaq`** uses Amazon's PR/FAQ method in two adversarial phases. First, a marketing PM agent writes the best possible public story -- a compelling press release and FAQ as if the product just launched. Then, in a **separate invocation** with no memory of drafting, the same agent adversarially tears the draft apart -- finding questions the press release dodges, identifying crack points where claims exceed substance, and recommending concept changes. The separate invocations prevent rubber-stamping: a critic who remembers being the drafter unconsciously defends what it wrote.

### Concept Review

**`/arn-spark-concept-review`** is the consolidation point. It gathers findings from all completed stress tests, presents the recommended changes, and lets you approve, modify, or reject each one. Only after your approval does the product concept get updated. This is the single point of truth -- stress tests recommend, concept review decides.

---

## Workflow 3: Name Your Product

**`/arn-spark-naming`** runs a four-step brand naming methodology driven by the brand strategist agent:

1. **Strategic Foundation** -- Brand DNA analysis extracts the naming constraints from your product concept: personality traits, audience expectations, competitive positioning, and naming taboos.
2. **Creative Generation** -- 50-80 candidate names per category (descriptive, evocative, abstract, coined, acronym), generated against the strategic brief.
3. **Qualitative Scoring** -- The **Six Senses framework** evaluates each finalist across memorability, pronounceability, visual identity potential, emotional resonance, cultural safety, and domain viability.
4. **Due Diligence** -- Live WHOIS domain availability checks and trademark screening against existing registrations.

The process produces two artifacts: a **naming brief** (`naming-brief.md`) capturing the strategic foundation and constraints, and a **naming report** (`naming-report.md`) with the full candidate list, scoring results, and recommended shortlist.

---

## Workflow 4: Prototype and Ship to Code

From validated concept to interactive prototype to feature backlog -- the full bridge from ideation to development.

### Scaffold

**`/arn-spark-scaffold`** generates a project skeleton with your chosen framework, installs dependencies, and sets up the initial directory structure. This is the foundation that prototypes and spikes build on.

### Technical Spikes

**`/arn-spark-spike`** validates technical risks with proof-of-concept code before you invest in full implementation. Each spike targets a specific unknown -- an API integration, a performance constraint, an algorithm choice -- and produces a pass/fail verdict with findings that feed into architecture decisions.

### Visual Design

**`/arn-spark-visual-sketch`** produces multiple visual direction proposals as live HTML/CSS -- not mockups, not wireframes, but rendered pages you can open in a browser and evaluate. You choose the direction that best represents the product's personality.

**`/arn-spark-style-explore`** translates the chosen visual direction into concrete design tokens: color palettes, typography scales, spacing systems, and component styles captured in a style brief that guides all downstream prototyping.

### Prototyping

**`/arn-spark-static-prototype`** builds a component showcase -- every UI element rendered and validated through a 3-cycle build-review-judge process. **`/arn-spark-static-prototype-teams`** adds multi-expert debate to the review cycles for deeper validation.

**`/arn-spark-clickable-prototype`** links those components into an interactive prototype with connected screens, navigation flows, and Playwright journey testing to verify that user paths work end-to-end. **`/arn-spark-clickable-prototype-teams`** adds the expert debate layer.

**`/arn-spark-prototype-lock`** freezes the validated prototype before development begins -- a clean snapshot that the development team can reference as the source of truth for UI behavior.

### Bridge to Development

**`/arn-spark-feature-extract`** walks through all upstream artifacts -- product concept, architecture vision, use cases, spike results, prototype validation reports -- and distills them into a prioritized feature backlog. Each feature carries lean context: description, journey summary, UI behavior, validated components, use case references, and acceptance criteria. Features can be uploaded directly to GitHub, Jira, or Bitbucket as issues.

**`/arn-spark-dev-setup`** standardizes the development environment configuration for the scaffolded project.

### Visual Testing

**`/arn-spark-visual-strategy`** defines the visual testing approach for the prototype, and **`/arn-spark-visual-readiness`** validates that visual assets meet quality and consistency standards before the prototype is locked.

### Cross-Plugin Handoff

When feature extraction is done, run `/arn-code-init` in the scaffolded project and you are in the development pipeline. Feature files produced by Spark feed directly into `/arn-planning` in Arness Code -- no manual translation, no copy-paste, no context lost.

---

## All Skills

| Command | What it does |
|---------|-------------|
| **Entry Points** | |
| `/arn-brainstorming` | Guided wizard through the full greenfield pipeline with decision gates |
| `/arn-spark-help` | See where you are in the Spark pipeline, with cross-plugin hints for Code and Infra |
| `/arn-spark-init` | *(Optional)* Configure the greenfield environment and user profile |
| `/arn-spark-discover` | Iterative product discovery producing a structured product concept |
| **Concept Validation** | |
| `/arn-spark-stress-interview` | Synthetic user interviews via 3 adversarial personas |
| `/arn-spark-stress-competitive` | Deep competitive gap analysis with feature matrices |
| `/arn-spark-stress-premortem` | Gary Klein's pre-mortem failure investigation |
| `/arn-spark-stress-prfaq` | Amazon PR/FAQ draft-then-destroy stress test |
| `/arn-spark-concept-review` | Consolidate stress test findings and update the product concept |
| **Brand & Architecture** | |
| `/arn-spark-naming` | 4-step brand naming with WHOIS checks and trademark screening |
| `/arn-spark-arch-vision` | Technology exploration and system architecture |
| **Behavioral Definition** | |
| `/arn-spark-use-cases` | Cockburn fully-dressed use cases with expert review |
| `/arn-spark-use-cases-teams` | Use cases with structured team debate |
| `/arn-spark-spike` | Technical risk validation with proof-of-concept code |
| **Visual Design** | |
| `/arn-spark-visual-sketch` | Multiple visual direction proposals as live HTML/CSS |
| `/arn-spark-style-explore` | Translate visual direction into design tokens and style brief |
| **Prototyping** | |
| `/arn-spark-static-prototype` | Component showcase with 3-cycle build-review-judge |
| `/arn-spark-static-prototype-teams` | Static prototype with multi-expert debate |
| `/arn-spark-clickable-prototype` | Interactive prototype with linked screens and Playwright testing |
| `/arn-spark-clickable-prototype-teams` | Clickable prototype with multi-expert debate |
| `/arn-spark-prototype-lock` | Freeze validated prototype before development |
| **Development Bridge** | |
| `/arn-spark-scaffold` | Project skeleton with chosen framework and dependencies |
| `/arn-spark-dev-setup` | Standardized development environment configuration |
| `/arn-spark-feature-extract` | Prioritized feature backlog with issue tracker integration |
| **Visual Testing** | |
| `/arn-spark-visual-strategy` | Define visual testing approach for the prototype |
| `/arn-spark-visual-readiness` | Validate visual asset quality and consistency |
| **Diagnostics** | |
| `/arn-spark-report` | Diagnose and report Arness Spark workflow issues (cross-plugin routing) |
| **Configuration** | |
| `/arn-spark-ensure-config` | Internal config bootstrapping (called by other skills) |

See [Arness Spark Skills Reference](../reference/arn-spark-skills.md) for full details on each skill.

## Agents at Work

Behind these workflows, 20 specialist agents provide deep expertise without requiring you to context-switch or manage prompts. Each agent is scoped to a single domain and invoked automatically by the skills that need it.

Highlights: **product-strategist** drives discovery and feature extraction. **market-researcher** conducts competitive intelligence. **persona-architect** generates synthetic user profiles. **brand-strategist** runs the full naming methodology. **forensic-investigator** powers the pre-mortem failure analysis. **marketing-pm** drafts and then destroys the PR/FAQ. **ux-specialist** and **ux-judge** validate prototypes through structured review cycles. **prototype-builder** constructs the static and clickable prototypes. **visual-sketcher** produces the visual direction proposals. **style-capture** extracts design tokens. **use-case-writer** generates Cockburn-format use cases. **persona-impersonator** conducts the adversarial synthetic interviews.

See [Arness Spark Agents Reference](../reference/arn-spark-agents.md) for the full roster.

## Cross-Plugin Integration

Spark is designed as the upstream half of a two-plugin pipeline. Everything it produces is structured for machine consumption by Arness Code.

**Spark to Code handoff:** Feature extraction produces feature files with lean context -- description, journey steps, validated components, use case references, and acceptance criteria. These feed directly into `/arn-planning` in the Code plugin, which expands the references, generates full feature specs, and enters the development pipeline. No manual translation step, no context lost in handoff.

**Design grounding:** Spark supports Figma and Canva integration for visual grounding. Captured design references are stored in the visual grounding directory and referenced by the visual sketch, style exploration, and prototyping skills to maintain design consistency throughout the pipeline.

**The full arc:** `/arn-brainstorming` to `/arn-spark-feature-extract` to `/arn-code-init` to `/arn-planning` -- raw idea to validated feature backlog to development-ready specs, with adversarial validation at every stage.
