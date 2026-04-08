# Interview Protocol

Structured protocol for the "Two-Part Reveal" synthetic user interview process. This document is consumed by the `arn-spark-stress-interview` skill to orchestrate persona impersonator invocations across three interview phases.

## Overview

The Two-Part Reveal is designed to surface genuine reactions by controlling information disclosure. The interview starts blind (the persona does not know what the product is), reveals the full concept in the second phase, and pressure-tests in the third. This mirrors how real users encounter products: first impressions are formed before marketing messaging has time to shape expectations.

The full interview cycle runs 3 personas x 3 phases = 9 persona-impersonator invocations organized as 3 phase-parallel waves, with product-strategist invocations at the start of each wave for question formulation. All personas run the same phase in parallel before the wave advances to the next phase.

---

## Phase 1: Initial Reaction (Blind Problem Check)

**Goal:** Determine whether the persona recognizes and cares about the problem the product solves -- before knowing the product exists.

**Information disclosed to persona:**
- The problem space description (extracted from the product concept's Problem Statement section)
- The persona's own profile and casting overlay
- NO product name, NO solution description, NO features

**Question types:**
- Problem recognition: "Do you experience [problem]? How often? How severely?"
- Current coping: "What do you currently do about this? What tools or workarounds?"
- Pain severity: "On a scale of 'mild annoyance' to 'blocking my work,' where does this fall?"
- Willingness to solve: "If a solution existed, what would you pay / what effort would you invest?"

**What to listen for:**
- Whether the persona even recognizes the problem (if not, the product concept may have a target audience assumption error)
- The language the persona uses to describe the problem (may differ from the product concept's framing)
- How severe the problem is from the persona's perspective versus the product concept's claim
- What the persona's switching threshold looks like (how much pain before they seek a solution)

**Expected duration:** 3-5 sentences from the persona per prompt. 1-2 prompts per phase.

**Product strategist role:** Before Phase 1, the product strategist formulates 2-3 questions that probe problem recognition without revealing the solution. The strategist extracts the problem framing from the product concept and strips solution-specific language.

---

## Phase 2: Deep Probing (Elevator Pitch Reveal)

**Goal:** Reveal the full product concept and probe adoption barriers, feature gaps, and misalignment with the persona's needs.

**Information disclosed to persona:**
- Everything from Phase 1 PLUS the full product concept summary (vision, core experience, product pillars, key features)
- The product's claimed value proposition and differentiation

**Question types:**
- First reaction to solution: "Now that you see the product, what is your gut reaction?"
- Fit assessment: "Does this solve the problem you described in Phase 1? Where does it fall short?"
- Adoption barriers: "What would stop you from trying this? What would you need to see first?"
- Feature evaluation: "Which features matter most to you? Which seem unnecessary?"
- Pillar alignment: "The product commits to [pillar]. Does that match what you need?"

**What to listen for:**
- Whether the persona's Phase 1 problem description matches what the product actually solves
- Specific adoption barriers that the product concept does not address
- Features the persona expected that are missing
- Features the persona considers unnecessary or harmful
- Whether the product pillars resonate or feel irrelevant to the persona's needs

**Expected duration:** 1-3 paragraphs from the persona per prompt. 2-3 prompts per phase.

**Product strategist role:** Between Phase 1 and Phase 2, the product strategist reviews Phase 1 responses and formulates questions that target gaps between the persona's described problem and the product's proposed solution. The strategist identifies which product pillars to probe based on the persona's stated priorities.

---

## Phase 3: Stress Test (Dealbreaker Probe)

**Goal:** Present the weakest aspects of the product concept and pressure-test the persona's willingness to adopt despite known limitations.

**Information disclosed to persona:**
- Everything from Phase 2 PLUS explicitly identified weaknesses, scope boundaries, and deferred features
- Known competitive alternatives and their advantages over this product

**Question types:**
- Dealbreaker identification: "What is the single biggest reason you would NOT use this product?"
- Competitive comparison: "Given that [competitor] already does [feature], why would you switch to this?"
- Scope boundary reaction: "[Feature] is explicitly not in v1. Does that change your assessment?"
- Worst case: "If [known weakness] turns out to be worse than expected, would you still use this?"
- Verdict: "Honest assessment -- would you use this, pay for this, recommend this to a colleague?"

**What to listen for:**
- Dealbreakers that the product concept does not acknowledge or mitigate
- Competitive advantages that the product concept underestimates
- Scope boundary decisions that the persona views as fatal omissions
- The persona's honest adoption verdict and the reasoning behind it
- Whether the casting overlay's specific concerns (pragmatist/skeptic/power user) surface unique failure modes

**Expected duration:** 2-4 paragraphs from the persona per prompt, ending with a clear verdict. 2-3 prompts per phase.

**Product strategist role:** Between Phase 2 and Phase 3, the product strategist reviews Phase 2 responses and identifies the weakest points to probe. The strategist formulates questions that force the persona to confront known limitations rather than politely sidestep them.

---

## Orchestration Guide

### Invocation Sequence (Phase-Parallel Waves)

```
Wave 1 -- Phase 1 (all 3 personas in parallel):
  Persona 1: Product strategist → Persona impersonator (Phase 1)
  Persona 2: Product strategist → Persona impersonator (Phase 1)
  Persona 3: Product strategist → Persona impersonator (Phase 1)
  [Wait for all 3 to complete]

Wave 2 -- Phase 2 (all 3 personas in parallel):
  Persona 1: Product strategist → Persona impersonator (Phase 2)
  Persona 2: Product strategist → Persona impersonator (Phase 2)
  Persona 3: Product strategist → Persona impersonator (Phase 2)
  [Wait for all 3 to complete]

Wave 3 -- Phase 3 (all 3 personas in parallel):
  Persona 1: Product strategist → Persona impersonator (Phase 3)
  Persona 2: Product strategist → Persona impersonator (Phase 3)
  Persona 3: Product strategist → Persona impersonator (Phase 3)
  [Wait for all 3 to complete]
```

Total: 3 waves x 3 personas x 2 agents = 18 invocations (9 impersonator + 9 strategist)
Per wave: 3 parallel persona-pairs, each with a strategist then impersonator (sequential within the pair, parallel across pairs)

### Context Passing Between Waves

Each persona-impersonator invocation receives:
- The persona profile (constant across all 3 phases)
- The casting overlay (constant across all 3 phases)
- The interview phase identifier (reaction/probing/stress)
- The specific questions for this phase (from product strategist)
- Previous phase responses for **this persona only** (accumulated -- Phase 2 receives this persona's Phase 1 responses, Phase 3 receives this persona's Phase 1+2 responses)

Each product-strategist invocation receives:
- The full product concept
- The persona profile and casting overlay
- All previous phase responses **for this persona only**
- The current phase's goal and question types (from this protocol)

### Phase-Parallel Execution

All 3 personas run the same phase in parallel before the wave advances to the next phase. Each persona's interview context is independent -- no cross-persona information is shared between parallel invocations within a wave. Cross-persona comparison happens at the synthesis stage (Step 5 of the SKILL), not during interviews.
