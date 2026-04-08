# Product Concept Template

This template defines the structure for product concept documents written by the `arn-spark-discover` skill. The document is saved to the project's vision directory as `product-concept.md`.

A product concept captures the WHAT and WHY of the product at a high level: the vision, core experience, target users, trust model, platform scope, and explicit boundaries. It does not address HOW to build it -- that is the architecture vision's job.

## Instructions for arn-spark-discover

When populating this template:

- Every section below MUST appear in the output, even if the content is brief
- Replace all bracketed placeholders with concrete content from the discovery conversation
- If information is missing for a section, write what you know and add the gap to a note at the end
- Adapt subsection names to match the product (e.g., "The Widget" for a desktop app, "The Feed" for a social app)
- Core Experience subsections should reflect the product's actual interaction modes, not generic categories
- Product Pillars must come from the user's own convictions, not generic best practices. If the user said "polish is everything," that is a pillar. Do not invent pillars the user did not express. If fewer than 3 emerged from the conversation, ask the user to confirm whether any are missing before writing.
- Future Considerations should list items that were explicitly discussed and deferred, not speculative features
- Write in present tense, as if the product exists ("Talkie lives as a small widget" not "Talkie will live as a small widget")
- For AI-assisted sections (Problem Statement, Target Personas, Competitive Landscape, Key Assumptions, Success Criteria): use the user-approved content. If a section was offered but declined, write "Not explored during discovery." If not applicable, write "Not applicable -- [reason]." Never leave these sections blank without explanation.
- Target Personas must include BOTH layers: (1) abstracted persona profiles ("moulds") that define the archetype's ranges, patterns, and variation axes, and (2) concrete example personas that were validated during conversation. The moulds are the primary reusable artifact — future skills use them to generate fresh concrete instances. Do not flatten either layer into a single paragraph.
- Competitive Landscape must include source URLs if market research was conducted. Mark unverified claims accordingly.
- Key Assumptions are hypotheses, not facts. Frame them as testable statements with confidence levels.

---

## Template

```markdown
# [Product Name] - Product Concept

## Vision

[2-4 sentences. What is this product, who is it for, and what makes it different from existing solutions. Core value proposition. Tone: aspirational but concrete. Avoid buzzwords.]

## Problem Statement

**The problem:** [1-2 sentences — what specific problem exists, stated clearly and concretely]

**Who experiences it:** [Specific roles, situations, or contexts — not generic categories]

**Current workarounds:** [How people cope today — tools, manual processes, or "nothing"]

**Why existing solutions fall short:** [What is painful, slow, expensive, or missing about current approaches]

**Severity:** [Painkiller (urgent, frequent pain) / Vitamin (nice-to-have, gradual improvement) / Infrastructure (invisible but essential) — with justification]

## Target Personas

[2-4 persona archetypes identified during discovery. Each includes an abstracted profile (the "mould" — a generative template for producing concrete instances) and one concrete example persona that was validated during conversation. The moulds can be used by future skills to generate additional concrete personas for stress-testing, simulation panels, and validation.]

### Archetype: The [Archetype Label]

#### Abstracted Profile (Mould)

**Demographic range:** [Age range, profession spectrum, sophistication range — expressed as ranges, not single points]

**Personality spectrum:** [Range of personality traits for this archetype — e.g., "pragmatic ↔ idealistic", "risk-tolerant ↔ risk-averse", "vocal ↔ reserved". Concrete instances pick specific positions along these spectrums.]

**Core motivation pattern:** [The underlying drive shared by all instances of this archetype]

**Pain pattern:** [The category of frustrations — what kind of problems they face, not specific instances]

**Adoption pattern:** [What type of trigger drives them to seek solutions, what type of threshold makes them leave]

**Variation axes:**
- [Dimension 1 that varies between instances, e.g., "technical depth: self-taught → CS degree"]
- [Dimension 2, e.g., "urgency: casual exploration → deadline-driven"]
- [Dimension 3 if applicable]

**Boundary conditions:** [What would NOT be this archetype — helps distinguish from other moulds]

#### Concrete Example: [Persona Name]

**Demographics:** [Age, profession, technical sophistication, context (solo/team/enterprise)]

**Personality Traits:** [3-5 traits that define how this person thinks, decides, and communicates — e.g., pragmatic, risk-averse, vocal in meetings, data-driven, impatient with slow tools]

**Goals:** [What they are trying to achieve — primary and secondary]

**Pain Points:**
- [Specific frustration #1 with current state]
- [Specific frustration #2]
- [Specific frustration #3]

**Current Workarounds:** [Tools or processes they use today, and why they fall short]

**Decision Factors:** [What drives adoption for this person — price, ease of use, peer validation, trust, feature completeness]

**Day-in-the-Life:** [2-3 sentences showing a specific moment when the problem surfaces — time, place, what goes wrong, how they feel]

**Adoption Trigger:** [The specific event or moment that makes them actively seek a solution]

**Frustration Threshold:** [What would make them stop using the product after trying it]

[Repeat "### Archetype: The [Label]" block for each persona archetype (2-4 total)]

### Differentiation Summary

| Dimension | [Persona 1 Name] | [Persona 2 Name] | [Persona 3 Name] |
|-----------|-------------------|-------------------|-------------------|
| Primary motivation | [key driver] | [key driver] | [key driver] |
| Technical sophistication | [level] | [level] | [level] |
| Adoption posture | [eager/cautious/skeptical] | [posture] | [posture] |
| Pain severity | [high/medium/low] | [severity] | [severity] |
| Decision style | [style] | [style] | [style] |

## Product Pillars

[3-5 non-negotiable qualities that define this product's soul. These are not features — they are the standards every feature, design choice, and architectural trade-off must be tested against. If a decision compromises a pillar, it should be reconsidered or rejected. Pillars flow through the entire pipeline: architecture must serve them, use cases must respect them, prototypes must demonstrate them, and features must embody them.]

### [Pillar Name]

[What this quality means for the product — not an abstract value, but a concrete commitment. Why it is non-negotiable: what happens to the product if this is compromised. Litmus test: a practical question to test any decision against this pillar. Example: "If a feature can't meet this standard within the timeline, defer it rather than ship it rough."]

### [Pillar Name]

[Same structure. Each pillar should be distinct — if two pillars overlap significantly, merge them.]

### [Pillar Name]

[Same structure. 3 pillars is the minimum. 5 is the maximum — more than 5 means nothing is truly prioritized.]

## Competitive Landscape

[Identified alternatives in this problem space, curated by the user. This is a landscape map — who exists and what they do — not a deep analysis. Detailed feature comparison and gap analysis can be performed separately via dedicated skills. The full research is preserved in tiers so future skills can draw from any level.]

### Primary Competitors (Focus)
[The user-validated top 5 — these are the most relevant alternatives to track and compare against]

1. **[Name]** ([URL]) — [one-line description of approach and target user]
   **Why primary:** [1 sentence rationale — relevance to problem space, user overlap, market presence]
   **Confidence:** [Verified / Inferred / Unverified]

2. **[Name]** ([URL]) — [one-line]
   **Why primary:** [rationale]
   **Confidence:** [tag]

[... up to 5]

### Extended Landscape
[Additional validated alternatives kept for reference — may become relevant as the product evolves]

- **[Name]** ([URL]) — [one-line] [Confidence: tag]
[... up to ~10]

### Indirect Alternatives
- **Manual / "Do Nothing"** — [How people cope without a dedicated tool]
- **[Generic tool]** — [How people repurpose general tools for this]

**Initial positioning:** [1-2 sentences — where the proposed product sits relative to these alternatives and what gap it fills]

### Research Metadata
- **Research date:** [ISO 8601 date]
- **Search coverage:** [N] queries across [M] search angles
- **Raw candidates found:** [X]
- **Validated alternatives:** [Y]
- **Research mode:** Identification (landscape mapping only — deep analysis available via dedicated skills)

## Core Experience

### [Primary Interaction Mode]

[Describe the main way users interact with the product. What do they see, what do they do, what happens? This is the "moment of magic" -- the experience that makes the product valuable. Be specific about the UX, not the technology.]

### [Secondary Interaction Mode(s)]

[Additional interaction patterns essential to v1. Each gets its own subsection with a descriptive name. Only include modes that are core to the product -- defer nice-to-haves to Future Considerations.]

### [Discovery / Onboarding]

[How do users get started? What is the first-run experience? How do they discover other users, content, or features? Keep it simple -- the best onboarding is minimal.]

## Trust & Security Model

### First-Time Setup

[What happens when the user first installs or opens the product? What information do they provide? What identity is established?]

### [Trust Establishment Mechanism]

[How do users establish trust with each other or with the system? Device pairing, user accounts, invite codes, OAuth, etc. Describe the flow from the user's perspective.]

### Per-[Entity] Settings

[What can be configured per relationship, per device, per user, or per workspace? List the key settings that affect how the product behaves between entities.]

## [Resource / Platform] Management

[Platform-specific considerations relevant to the user experience. Device selection (camera, microphone, etc.), system permissions, hot-plug handling, system tray behavior, notification preferences, or other OS integration points. Name the section to match the product domain.]

## Target Platforms

[Supported platforms with version requirements. Be specific: "Windows 10/11" not just "Windows." Note any platform-specific considerations that affect the user experience.]

## Participants

[How many users or devices participate simultaneously? What is the topology (1:1, room, mesh, broadcast)? Is there an upper limit? Note any scaling considerations that affect the v1 design.]

## Business Constraints

**Business model:** [B2C / B2B SaaS / marketplace / self-hosted / white-label / enterprise. How revenue is generated.]

**Tenancy:** [Single-tenant / multi-tenant. Expected tenant count at launch and at scale. Required isolation level (shared DB, schema-per-tenant, DB-per-tenant, infra-per-tenant). "Not applicable" for consumer products.]

**Compliance:** [Regulatory requirements: GDPR, HIPAA, SOC2, PCI-DSS, FedRAMP, or none. Data residency constraints (EU-only, US-only, etc.). "None" if no regulatory requirements.]

**Cost constraints:** [Monthly cloud/infrastructure budget target. Per-tenant cost target if multi-tenant. Licensing constraints (open-source only, commercial OK). "No hard limit" if unconstrained.]

**Vendor & technology constraints:** [Required or excluded vendors/clouds. Required integrations with existing systems. Team technical experience that constrains technology choices. "No constraints" if flexible.]

**Timeline:** [Hard deadlines, market windows, or competitive pressures that affect build-vs-buy decisions. "No hard deadline" if flexible.]

## Key Assumptions

[Assumptions underlying the product concept — things stated or implied during discovery that have not been empirically validated. Each is a testable hypothesis.]

| Assumption | Confidence | What Would Disprove It |
|-----------|-----------|----------------------|
| [Market/user/tech/business assumption] | High / Medium / Low | [Observable evidence that would invalidate this] |

## Success Criteria

[Measurable outcomes that define whether the product is succeeding.]

| Metric | Target | Timeframe | Why It Matters |
|--------|--------|-----------|----------------|
| [What to measure] | [Specific target value] | [By when] | [Connection to product vision] |

## Future Considerations (Not in v1)

[Explicitly scoped-out items. Each should have a brief note explaining why it was deferred and, if relevant, how v1's design accommodates it later. These are items that were actively discussed and decided against for v1, not a wishlist.]
```

---

## Section Guidance

| Section | Source | Depth |
|---------|--------|-------|
| Vision | User's initial idea + refined through conversation | 2-4 sentences, sharp and specific |
| Problem Statement | AI-drafted from conversation, user-approved | 3-5 sentences structured as problem/who/workarounds/gap/severity |
| Target Personas | AI-generated by persona-architect (discovery mode), user-approved | 2-4 archetypes, each with: abstracted mould (ranges, patterns, variation axes, boundaries) + concrete example (full detailed profile). Both layers user-approved. |
| Product Pillars | Conversation exploration of non-negotiable qualities | 3-5 pillars, each with meaning, rationale, and litmus test |
| Competitive Landscape | AI-identified by market-researcher (identification mode), user-approved | Tiered list: Primary (top 5 with rationale and confidence tags), Extended (~10), Indirect. Includes research metadata and initial positioning. Source URLs required. Identification only — deep analysis deferred to Gap Analysis skill. |
| Core Experience | Conversation exploration of interaction modes | 1-3 subsections, each 1-3 paragraphs. UX-focused, not technical. |
| Trust & Security Model | Conversation exploration of trust/security category | 2-3 subsections covering setup, trust mechanism, and per-entity config |
| Resource / Platform Management | Conversation exploration of platform category | 1-2 paragraphs on platform integration relevant to UX |
| Target Platforms | Conversation exploration of platform category | Bullet list with version specifics |
| Participants | Conversation exploration of participants category | 1 paragraph covering count, topology, and limits |
| Business Constraints | Conversation exploration of business model, tenancy, compliance, cost, vendor preferences | 1-2 sentences per subsection; concrete numbers for tenant count, budget, and compliance requirements. Skip subsections that don't apply (write "Not applicable" or "None"). |
| Key Assumptions | AI-derived from conversation, user-validated | 5-8 testable assumptions with confidence levels |
| Success Criteria | AI-suggested based on product type + business model, user-approved | 3-5 measurable outcomes with targets and timeframes |
| Future Considerations | Accumulated deferred items from conversation | Bullet list, each with brief rationale for deferral |
