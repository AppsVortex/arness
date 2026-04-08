# Persona Casting Spec

Defines the 3 casting overlays used by the `arn-spark-stress-interview` skill to create adversarial interview perspectives. Each overlay is applied on top of a base persona profile to focus the interview through a specific critical lens.

## Overview

Casting overlays do not replace the persona's identity -- they focus the persona's natural concerns toward specific categories of product weakness. A Pragmatist version of "Sarah, the senior product manager" evaluates differently from a Skeptic version of the same person, even though both share the same background, goals, and pain points.

The 3 overlays are designed to cover complementary failure surfaces:
- **Pragmatist:** Practical adoption and workflow integration failures
- **Skeptic:** Trust, privacy, and systemic risk failures
- **Power User:** Depth, scalability, and customization failures

Together, they approximate the range of real user reactions that a product concept would face in the market.

---

## Overlay 1: Pragmatist

### Adversarial Lens

The Pragmatist evaluates everything through the lens of practical adoption. Their time is valuable, their current workflow is functional (if imperfect), and they need concrete evidence that switching is worth the disruption. They are not hostile to new tools -- they are hostile to wasted time.

### How It Modifies Base Persona Responses

- Amplifies the persona's existing concerns about workflow disruption and migration cost
- Foregrounds time-to-value calculations: "How long until this actually helps me?"
- Emphasizes comparison with current workarounds: "My spreadsheet is ugly but it works"
- Reduces patience for abstract benefits: "Show me the before/after for my specific Tuesday morning"
- Increases sensitivity to onboarding friction and learning curves

### Weakness Categories Surfaced

- Migration and onboarding friction that the product concept underestimates
- Workflow integration gaps (the product works in isolation but not in the user's existing toolchain)
- Time-to-value disconnect (the product requires significant setup before delivering value)
- Reliability concerns (the product needs to work consistently, not just in demos)
- Hidden costs of switching (not just price -- cognitive load, team retraining, data migration)

### Casting Instructions for Persona Architect

When generating a persona with the Pragmatist overlay for instantiation mode:
1. Take the base persona mould and generate a concrete instance
2. Emphasize the persona's current tool stack and daily workflow in the profile
3. Include specific details about how the persona currently solves the problem (even poorly)
4. Note the persona's switching history: what tools they have adopted and abandoned, and why
5. Set the frustration threshold around workflow disruption rather than abstract concerns

---

## Overlay 2: Skeptic

### Adversarial Lens

The Skeptic evaluates everything through the lens of trust, privacy, and systemic risk. They have been burned before by products that over-promised and under-delivered, or that handled their data carelessly. They are not paranoid -- they are experienced. Marketing language makes them more suspicious, not less.

### How It Modifies Base Persona Responses

- Amplifies the persona's existing concerns about data handling, privacy, and security
- Foregrounds trust establishment: "Who built this? What is their track record?"
- Emphasizes vendor lock-in and exit strategies: "What happens if this company shuts down?"
- Reduces trust in marketing claims: "Show me the architecture, not the landing page"
- Increases sensitivity to vague privacy policies and unclear data ownership

### Weakness Categories Surfaced

- Trust and credibility gaps in the product concept's positioning
- Privacy and data handling assumptions that are stated but not substantiated
- Vendor lock-in risks that the product concept minimizes or ignores
- Failure precedents: "Why would this succeed where [competitor] failed?"
- Security architecture decisions that are deferred or hand-waved

### Casting Instructions for Persona Architect

When generating a persona with the Skeptic overlay for instantiation mode:
1. Take the base persona mould and generate a concrete instance
2. Emphasize the persona's past experiences with tool adoption failures
3. Include specific details about data sensitivity in the persona's domain
4. Note the persona's trust signals: what makes them trust a new tool, what triggers distrust
5. Set the frustration threshold around trust violations rather than usability issues

---

## Overlay 3: Power User

### Adversarial Lens

The Power User evaluates everything through the lens of depth, customization, and scalability. They push every tool to its limits and need to know what happens at the edges. They are not looking for the simplest tool -- they are looking for the most capable one that respects their expertise.

### How It Modifies Base Persona Responses

- Amplifies the persona's existing need for control, customization, and advanced features
- Foregrounds API access, automation, and integration capabilities
- Emphasizes performance ceilings and scalability limits: "What happens at 10x?"
- Reduces tolerance for opinionated defaults without escape hatches
- Increases sensitivity to edge cases, error handling, and recovery mechanisms

### Weakness Categories Surfaced

- Customization and configuration limitations that constrain advanced workflows
- API and integration gaps that prevent embedding the product in existing pipelines
- Performance ceilings and scalability limits that the product concept does not address
- Edge case handling: what happens when the happy path breaks?
- Advanced workflow support: can the product grow with the user or does it plateau?

### Casting Instructions for Persona Architect

When generating a persona with the Power User overlay for instantiation mode:
1. Take the base persona mould and generate a concrete instance
2. Emphasize the persona's technical depth and existing integrations
3. Include specific details about the persona's advanced use cases and automation needs
4. Note the persona's history with outgrowing tools: what tools they have abandoned because of limits
5. Set the frustration threshold around capability ceilings rather than initial usability

---

## Instantiation Workflow

The interview skill uses the following process to generate cast personas:

1. **Read persona moulds** from the product concept's Target Personas section
2. **Select 3 moulds** (or use all if 3 or fewer exist). If more than 3 moulds exist, select the 3 that are most diverse in their adoption posture and technical sophistication.
3. **For each mould, invoke `arn-spark-persona-architect` in instantiation mode** with:
   - The mould definition (abstracted profile)
   - The casting overlay specification (from this document)
   - The product concept summary (for domain grounding)
4. **Receive back** a fully detailed concrete persona with the casting overlay baked into the profile
5. **Pass the cast persona** to `arn-spark-persona-impersonator` for interview phases

### Mould-to-Overlay Assignment

Each mould gets exactly one overlay. Assignment follows this priority:

1. If the mould's boundary conditions or variation axes suggest a natural fit (e.g., a mould with "risk-averse" in its personality spectrum maps well to Skeptic), use that alignment.
2. If no natural fit exists, assign overlays to maximize coverage: the mould whose persona is most likely to challenge practical adoption gets Pragmatist, the mould most sensitive to trust gets Skeptic, and the mould with the deepest technical range gets Power User.
3. If all moulds are similar, assign overlays round-robin to ensure all 3 lenses are represented.

The goal is not to assign the "matching" overlay but to ensure all 3 adversarial perspectives are represented across the interview set.
