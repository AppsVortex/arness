---
name: arn-spark-stress-interview
description: >-
  This skill should be used when the user says "stress interview",
  "synthetic interview", "user interview stress test", "interview my personas",
  "test with synthetic users", "persona interview", "simulate user interviews",
  "run user interviews", or wants to stress-test a product concept by conducting
  structured interviews with synthetic personas through three adversarial lenses
  (Pragmatist, Skeptic, Power User). Produces an interview report with
  per-persona findings, synthesized themes, and recommended concept updates.
version: 1.0.0
---

# Arness Spark Stress Interview

Stress-test a product concept by conducting structured synthetic user interviews. This skill generates 3 synthetic personas from the product concept's persona moulds, applies adversarial casting overlays (Pragmatist, Skeptic, Power User), and runs each through a 3-phase "Two-Part Reveal" interview protocol:

1. **Phase 1 -- Blind Problem Check:** The persona hears about the problem without knowing the product exists. Do they even care?
2. **Phase 2 -- Elevator Pitch Reveal:** The full product concept is revealed. What resonates? What falls flat? What is missing?
3. **Phase 3 -- Dealbreaker Probe:** The weakest aspects are presented head-on. Would they still use this?

The process produces brutally honest feedback from 3 distinct adversarial perspectives, synthesized into actionable concept update recommendations. The product concept is read but never modified -- all recommendations are captured in the interview report for later review.

## Prerequisites

### Configuration Check

1. Read the project's `CLAUDE.md` and check for a `## Arness` section
2. If found, extract the configured **Vision directory** and **Reports directory** paths
3. If no `## Arness` section exists or Arness Spark fields are missing, inform the user: "Arness Spark is not configured for this project yet. Run `/arn-brainstorming` to get started — it will set everything up automatically." Do not proceed without it.
4. Create the reports directory structure if it does not exist: `mkdir -p <reports-dir>/stress-tests/`

### Data Availability

| Artifact | Status | Location | Fallback |
|----------|--------|----------|----------|
| Product concept | REQUIRED | `<vision-dir>/product-concept.md` | Cannot proceed without it -- suggest running `/arn-spark-discover` |
| Persona moulds | REQUIRED | Target Personas section of product concept | Fallback cascade below |
| Product pillars | ENRICHES | Product Pillars section of product concept | Interview proceeds but questions are less targeted |
| Competitive landscape | ENRICHES | Competitive Landscape section of product concept | Phase 3 competitive comparison questions are skipped |

**Persona moulds fallback cascade:**

If the product concept exists but the Target Personas section is missing or contains "Not explored" sentinel:

Ask (using `AskUserQuestion`): **"The product concept does not include persona moulds, which are needed to generate synthetic interview subjects. How would you like to proceed?"**
1. Run `/arn-spark-discover` to generate personas through product discovery
2. Describe 3 target user types now (I will generate personas from your descriptions)
3. Skip the interview stress test

If the user chooses option 2, collect brief descriptions and invoke `arn-spark-persona-architect` in **instantiation mode** to generate persona instances with casting overlays before proceeding.

## Workflow

### Step 1: Load References

Load the interview protocol, persona casting spec, and report template:
> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-stress-interview/references/interview-protocol.md`
> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-stress-interview/references/persona-casting-spec.md`
> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-stress-interview/references/interview-report-template.md`

### Step 2: Read Product Concept and Extract Context

Read the product concept from `<vision-dir>/product-concept.md`. Extract:
- Product vision and problem statement (for Phase 1 blind problem check)
- Full product concept summary (for Phase 2 reveal)
- Product pillars (for targeted probing)
- Competitive landscape (for Phase 3 competitive comparisons)
- Persona moulds from the Target Personas section
- Scope boundaries and deferred features (for Phase 3 dealbreaker probes)

### Step 3: Generate Synthetic Personas (Casting)

Select 3 persona moulds from the product concept. If more than 3 moulds exist, select the 3 most diverse in adoption posture and technical sophistication.

For each mould, invoke `arn-spark-persona-architect` in **instantiation mode** with:

--- PERSONA MOULD ---
[full abstracted profile from product concept]
--- END PERSONA MOULD ---

--- CASTING OVERLAY ---
[overlay specification from persona-casting-spec.md -- one of Pragmatist, Skeptic, Power User]
--- END CASTING OVERLAY ---

--- PRODUCT CONTEXT ---
[product vision and problem statement for domain grounding]
--- END PRODUCT CONTEXT ---

Assign overlays following the priority in the casting spec: natural fit first, then maximize coverage.

Receive back 3 fully detailed concrete personas with casting overlays baked in. Present a brief summary to the user:

"I have generated 3 synthetic interview subjects:
- **[Persona 1 Name]** ([Archetype]) with **Pragmatist** lens -- focused on practical adoption barriers
- **[Persona 2 Name]** ([Archetype]) with **Skeptic** lens -- focused on trust and systemic risk
- **[Persona 3 Name]** ([Archetype]) with **Power User** lens -- focused on depth and scalability

Starting interviews now. Each persona goes through 3 phases: blind problem check, full reveal, and dealbreaker probe."

### Step 4: Conduct Interviews (3 Phases x 3 Personas -- Phase-Parallel)

Run interviews in 3 waves. Each wave runs one phase for all 3 personas in parallel. Each persona's interview context is independent -- no cross-persona information is shared between parallel invocations.

#### Wave 1 -- Phase 1 (Blind Problem Check)

Run all 3 personas' Phase 1 interviews in parallel. For each persona in parallel:

Invoke `arn-spark-product-strategist` with:

--- PRODUCT CONCEPT ---
[full product concept]
--- END PRODUCT CONCEPT ---

--- INTERVIEW PROTOCOL ---
Phase 1 goal: formulate 2-3 questions that probe problem recognition without revealing the solution. Strip solution-specific language from the problem description.
--- END INTERVIEW PROTOCOL ---

--- PERSONA PROFILE ---
[full cast persona profile]
--- END PERSONA PROFILE ---

Then invoke `arn-spark-persona-impersonator` with:

--- PERSONA PROFILE ---
[full cast persona profile]
--- END PERSONA PROFILE ---

--- CASTING OVERLAY ---
[overlay name and specification]
--- END CASTING OVERLAY ---

--- PRODUCT CONCEPT SUMMARY ---
[problem space description ONLY -- no product details]
--- END PRODUCT CONCEPT SUMMARY ---

--- INTERVIEW PHASE ---
reaction
--- END INTERVIEW PHASE ---

--- INTERVIEW PROMPT ---
[questions from product strategist]
--- END INTERVIEW PROMPT ---

Record the full response for each persona.

After all 3 personas' Phase 1 responses are collected, proceed to Wave 2.

#### Wave 2 -- Phase 2 (Deep Probing)

After Wave 1 completes, run all 3 personas' Phase 2 interviews in parallel. Each persona's Phase 2 needs only its own Phase 1 context (available from Wave 1). For each persona in parallel:

Invoke `arn-spark-product-strategist` with that persona's Phase 1 responses and the full product concept, requesting Phase 2 questions that target gaps between the persona's described problem and the product's proposed solution.

Then invoke `arn-spark-persona-impersonator` with the full product concept revealed, interview phase set to `probing`, and questions from the strategist. Include that persona's Phase 1 responses as prior context.

Record the full response for each persona.

After all 3 personas' Phase 2 responses are collected, proceed to Wave 3.

#### Wave 3 -- Phase 3 (Stress Test)

After Wave 2 completes, run all 3 personas' Phase 3 interviews in parallel. Each persona's Phase 3 needs only its own Phase 1+2 context. For each persona in parallel:

Invoke `arn-spark-product-strategist` with that persona's Phase 1+2 responses, requesting Phase 3 questions that force the persona to confront known limitations, scope boundaries, and competitive alternatives.

Then invoke `arn-spark-persona-impersonator` with that persona's Phase 1+2 responses as prior context, interview phase set to `stress`, weakest aspects and scope boundaries explicitly highlighted, and questions from the strategist.

Record the full response for each persona.

### Step 5: Synthesize Findings

After all 9 interviews are complete, invoke `arn-spark-product-strategist` with:

--- PRODUCT CONCEPT ---
[full product concept]
--- END PRODUCT CONCEPT ---

--- PRODUCT PILLARS ---
[product pillars section]
--- END PRODUCT PILLARS ---

--- INTERVIEW TRANSCRIPTS ---
[all 9 persona-impersonator responses organized by persona and phase]
--- END INTERVIEW TRANSCRIPTS ---

--- SYNTHESIS TASK ---
1. Identify 3-5 cross-persona themes (patterns observed across multiple personas and casting overlays)
2. Draft a Recommended Concept Updates table using the standardized schema: | # | Section | Current State | Recommended Change | Type | Rationale |
3. Identify Unresolved Questions that emerged from interviews but cannot be answered without real user data
--- END SYNTHESIS TASK ---

### Step 6: Assemble and Write Report

Using the interview report template:
1. Populate all sections with interview data and strategist synthesis
2. Include the full transcript of all 9 interviews
3. If `<reports-dir>/stress-tests/interview-report.md` already exists, inform the user: "A previous interview report exists. It will be overwritten (git preserves history)."
4. Write the report to `<reports-dir>/stress-tests/interview-report.md`

Present a summary to the user:

"Interview stress test complete. Report saved to `[path]`.

**Key findings:**
- [Finding 1 -- most impactful theme]
- [Finding 2]
- [Finding 3]

**Recommended concept updates:** [N] recommendations ([X] Add, [Y] Modify, [Z] Remove)
**Unresolved questions:** [N]

This report will be used by `/arn-spark-concept-review` to propose changes to the product concept."

## Agent Invocation Guide

| Situation | Agent | Mode/Context |
|-----------|-------|--------------|
| Generate cast personas from moulds | `arn-spark-persona-architect` | Instantiation mode with casting overlay |
| Formulate Phase 1 questions | `arn-spark-product-strategist` | Question formulation from problem statement |
| Conduct Phase 1 interview | `arn-spark-persona-impersonator` | Reaction phase, blind problem check |
| Formulate Phase 2 questions | `arn-spark-product-strategist` | Question formulation targeting revealed concept |
| Conduct Phase 2 interview | `arn-spark-persona-impersonator` | Probing phase, full concept revealed |
| Formulate Phase 3 questions | `arn-spark-product-strategist` | Question formulation targeting weaknesses |
| Conduct Phase 3 interview | `arn-spark-persona-impersonator` | Stress phase, dealbreaker probe |
| Synthesize all interview findings | `arn-spark-product-strategist` | Synthesis with all transcripts |

## Error Handling

- **Persona architect returns generic personas:** Retry with more specific mould details and casting overlay instructions. If retry fails:
  Ask (using `AskUserQuestion`): **"Persona generation produced generic results. How would you like to proceed?"**
  1. Retry with additional context
  2. Skip this persona and continue with remaining
  3. Abort the interview stress test

- **Persona impersonator breaks character:** Retry once with a simplified prompt that re-emphasizes the persona profile and casting overlay. If retry fails, record what was captured and note the gap in the report. Continue with remaining phases/personas.

- **Persona impersonator breaks character (persistent):** After retry failure:
  Ask (using `AskUserQuestion`): **"The persona impersonator is not maintaining character. How would you like to proceed?"**
  1. Retry this phase
  2. Skip this phase and continue
  3. Abort the interview stress test

- **Product strategist returns unhelpful questions:** Use the interview protocol's question types directly as fallback questions. Note in the report that strategist-formulated questions were replaced with protocol defaults.

- **Any agent invocation fails entirely:** Retry once with a simplified prompt. If retry fails:
  Ask (using `AskUserQuestion`): **"Agent invocation failed. How would you like to proceed?"**
  1. Retry
  2. Skip this step
  3. Abort

## Constraints

- **Read-only with respect to product-concept.md.** The interview skill reads the product concept but NEVER modifies it. All recommendations are captured in the interview report.
- **Phase-parallel interviews.** Each phase runs for all 3 personas in parallel before advancing to the next phase. Each persona's interview context is independent -- no cross-persona information is shared between parallel invocations.
- **All 3 casting overlays must be represented.** If fewer than 3 moulds exist, the skill still generates 3 personas (reusing moulds with different overlays if necessary) to ensure Pragmatist, Skeptic, and Power User perspectives are all captured.
- **Report overwrites on re-run.** If `interview-report.md` already exists, it is overwritten. Git provides history.
