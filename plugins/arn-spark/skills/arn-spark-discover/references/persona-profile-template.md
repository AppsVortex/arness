# Persona Profile Template

This template defines the dual-layer persona format for the Target Personas section of `product-concept.md`. Each persona archetype includes two layers: an **abstracted profile (mould)** and a **concrete example persona**.

The abstracted profile is a generative template -- it defines ranges, patterns, and variation axes rather than single data points. Future skills (e.g., Synthetic User Panel) use moulds to generate fresh concrete persona instances for stress-testing and simulation. The concrete example is a specific, vivid character that was validated during the discovery conversation. Both layers are required for every archetype.

## Instructions for arn-spark-discover

When populating this template:

- Populate from the `arn-spark-persona-architect` agent's output. The agent produces concrete examples first (for user interaction and critique), then derives abstracted moulds after user approval. Write both layers per archetype.
- When the user provides concrete personas directly (names, roles, specific details), those become seeds. The persona-architect expands them into full profiles and derives moulds. Do not discard user-provided personas -- they represent domain expertise.
- Every archetype MUST include both layers. Do not flatten the mould into a summary paragraph or merge it with the concrete example. The dual-layer structure is required for downstream reuse.
- The moulds are the primary reusable artifact. Concrete examples are illustrative; moulds are generative.
- Include 2-4 archetypes. 2-3 is ideal. At least one should represent a skeptic or reluctant adopter.
- End with a Differentiation Summary table that maps all personas across key distinguishing dimensions.
- If the user declines persona generation entirely, write: `Not explored during discovery.`
- If personas are genuinely not applicable (e.g., fully automated system with no user-facing interaction -- rare), write: `Not applicable -- [reason].`

---

## Template

```markdown
## Target Personas

[2-4 persona archetypes identified during discovery. Each includes an abstracted profile (the "mould" -- a generative template for producing concrete instances) and one concrete example persona that was validated during conversation. The moulds can be used by future skills to generate additional concrete personas for stress-testing, simulation panels, and validation.]

### Archetype: The [Archetype Label]

#### Abstracted Profile (Mould)

**Demographic range:** [Age range, profession spectrum, sophistication range -- expressed as ranges, not single points]

**Personality spectrum:** [Range of personality traits for this archetype -- e.g., "pragmatic <-> idealistic", "risk-tolerant <-> risk-averse", "vocal <-> reserved". Concrete instances pick specific positions along these spectrums.]

**Core motivation pattern:** [The underlying drive shared by all instances of this archetype]

**Pain pattern:** [The category of frustrations -- what kind of problems they face, not specific instances]

**Adoption pattern:** [What type of trigger drives them to seek solutions, what type of threshold makes them leave]

**Variation axes:**
- [Dimension 1 that varies between instances, e.g., "technical depth: self-taught -> CS degree"]
- [Dimension 2, e.g., "urgency: casual exploration -> deadline-driven"]
- [Dimension 3 if applicable]

**Boundary conditions:** [What would NOT be this archetype -- helps distinguish from other moulds]

#### Concrete Example: [Persona Name]

**Demographics:** [Age, profession, technical sophistication, context (solo/team/enterprise)]

**Personality Traits:** [3-5 traits that define how this person thinks, decides, and communicates -- e.g., pragmatic, risk-averse, vocal in meetings, data-driven, impatient with slow tools]

**Goals:** [What they are trying to achieve -- primary and secondary]

**Pain Points:**
- [Specific frustration #1 with current state]
- [Specific frustration #2]
- [Specific frustration #3]

**Current Workarounds:** [Tools or processes they use today, and why they fall short]

**Decision Factors:** [What drives adoption for this person -- price, ease of use, peer validation, trust, feature completeness]

**Day-in-the-Life:** [2-3 sentences showing a specific moment when the problem surfaces -- time, place, what goes wrong, how they feel]

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
```

---

## Section Guidance

| Section | Source | Depth |
|---------|--------|-------|
| Archetype Label | arn-spark-persona-architect output, user-validated | Short, memorable label (e.g., "The Solo Indie Dev", "The Reluctant Enterprise Admin") |
| Abstracted Profile (Mould) | Derived by persona-architect after user approves concrete examples | All 7 fields required: demographic range, personality spectrum, core motivation pattern, pain pattern, adoption pattern, variation axes (2-3), boundary conditions. Express everything as ranges or patterns, never single data points. |
| Concrete Example | Generated by persona-architect (discovery mode), or expanded from user-provided seeds, then user-validated | All 10 fields required: name, demographics, personality traits (3-5), goals, pain points (3), current workarounds, decision factors, day-in-the-life, adoption trigger, frustration threshold. Must be vivid and specific. |
| Differentiation Summary | Synthesized from approved personas | Table with one row per distinguishing dimension, one column per persona. Highlights what makes each archetype distinct. |
| User-provided personas | User provides names, roles, and partial details during conversation | Accept as seeds. Persona-architect expands into full profiles (filling demographics, personality, pain points, workarounds, day-in-the-life, etc. grounded in domain research). Present expanded profiles for approval. Derive moulds from approved expanded profiles. Never discard user-provided input. |
| Vague user descriptions | User says "developers" or "small business owners" without specifics | Persona-architect researches the domain and generates 2-4 distinct concrete examples from the vague description. Each must be differentiated on at least 2 axes (motivation, sophistication, urgency, adoption posture). Present for user critique and refinement. |
