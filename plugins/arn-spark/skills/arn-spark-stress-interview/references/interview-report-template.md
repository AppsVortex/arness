# Interview Report Template

Template for the synthetic user interview stress test report. This document is consumed by the `arn-spark-stress-interview` skill when assembling the final report from interview transcripts and strategist synthesis.

## Instructions for arn-spark-stress-interview

When populating this template:

- Every section below MUST appear in the output, even if an interview was skipped due to agent failure
- Replace all bracketed placeholders with concrete content from interview transcripts and strategist synthesis
- Per-Persona Findings should quote or closely paraphrase the persona's actual responses -- do not summarize away the specificity
- Synthesized Themes should identify cross-persona patterns, not repeat individual findings
- The Recommended Concept Updates table MUST use the standardized schema exactly as shown
- Unresolved Questions should capture questions that emerged from interviews but cannot be answered without real user data or domain expertise
- Full Transcript includes all 9 persona-impersonator responses organized by persona and phase
- If a persona interview was partially completed (e.g., agent failure after Phase 2), include what was captured and note the gap

---

## Template

```markdown
# Synthetic User Interview Report

**Product:** [product name]
**Date:** [ISO 8601 date]
**Personas interviewed:** [Persona 1 name] (Mould: [archetype], Overlay: [casting]), [Persona 2 name] (Mould: [archetype], Overlay: [casting]), [Persona 3 name] (Mould: [archetype], Overlay: [casting])

---

## Executive Summary

[3-5 sentences summarizing the overall interview findings. What was the dominant sentiment? Where did the product concept hold up? Where did it crack? What was the most surprising finding?]

---

## Per-Persona Findings

### [Persona 1 Name] -- [Archetype Label] / [Casting Overlay]

**Key Reactions:**
- Phase 1 (Blind): [1-2 sentences on whether they recognized and cared about the problem]
- Phase 2 (Reveal): [1-2 sentences on their reaction to the full product concept]
- Phase 3 (Stress): [1-2 sentences on their dealbreaker assessment]

**Adoption Barriers:**
- [Barrier 1 -- specific to this persona's context and casting overlay]
- [Barrier 2]
- [Barrier 3 if applicable]

**Strongest Objections:**
- [Objection 1 -- quoted or closely paraphrased from transcript]
- [Objection 2]

**What Resonated:**
- [Element 1 -- what the persona responded positively to, if anything]
- [Element 2 if applicable]

**Verdict:** [The persona's honest adoption verdict from Phase 3 -- would they use it, pay for it, recommend it? 1-2 sentences.]

---

### [Persona 2 Name] -- [Archetype Label] / [Casting Overlay]

[Same structure as Persona 1]

---

### [Persona 3 Name] -- [Archetype Label] / [Casting Overlay]

[Same structure as Persona 1]

---

## Synthesized Themes

Cross-persona patterns identified by the product strategist from all 9 interview responses.

### Theme 1: [Theme Title]

[Description of the pattern observed across multiple personas. Which personas exhibited this? How does it manifest differently through different casting overlays? What does this mean for the product concept?]

### Theme 2: [Theme Title]

[Same structure]

### Theme 3: [Theme Title]

[Same structure]

[3-5 themes total]

---

## Recommended Concept Updates

| # | Section | Current State | Recommended Change | Type | Rationale |
|---|---------|---------------|--------------------|------|-----------|
| 1 | [product concept section] | [what the concept currently says or assumes] | [specific change recommended] | [Add/Modify/Remove] | [which interview findings support this -- reference persona names and phases] |
| 2 | ... | ... | ... | ... | ... |

---

## Unresolved Questions

| # | Section | Question | Options | Assessment |
|---|---------|----------|---------|------------|
| 1 | [product concept section] | [question that emerged from interviews but cannot be answered without real user data] | [possible approaches to answering this] | [preliminary assessment based on interview data] |
| 2 | ... | ... | ... | ... |

---

## Full Transcript

### [Persona 1 Name] -- [Archetype Label] / [Casting Overlay]

#### Phase 1: Initial Reaction

**Questions asked:**
[questions from product strategist]

**Response:**
[full persona-impersonator response]

#### Phase 2: Deep Probing

**Questions asked:**
[questions from product strategist]

**Response:**
[full persona-impersonator response]

#### Phase 3: Stress Test

**Questions asked:**
[questions from product strategist]

**Response:**
[full persona-impersonator response]

---

### [Persona 2 Name] -- [Archetype Label] / [Casting Overlay]

[Same structure as Persona 1 transcript]

---

### [Persona 3 Name] -- [Archetype Label] / [Casting Overlay]

[Same structure as Persona 1 transcript]
```

---

## Section Guidance

| Section | Source | Depth |
|---------|--------|-------|
| Executive Summary | Synthesized by skill from strategist output and interview transcripts | 3-5 sentences, high-level patterns and surprises |
| Per-Persona Findings | Extracted from persona-impersonator responses across 3 phases | Per persona: key reactions (3 phases), adoption barriers (2-3), strongest objections (1-2), what resonated (1-2), verdict (1-2 sentences) |
| Synthesized Themes | Product strategist synthesis of all 9 interview responses | 3-5 themes, each with cross-persona pattern analysis |
| Recommended Concept Updates | Product strategist output using standardized table schema | One row per recommendation, Type must be Add/Modify/Remove, rationale must reference specific interview findings |
| Unresolved Questions | Identified during strategist synthesis as questions requiring real data | One row per question, must specify which product concept section is affected and possible resolution approaches |
| Full Transcript | Raw persona-impersonator responses, organized by persona and phase | Complete responses -- no summarization or editing |
