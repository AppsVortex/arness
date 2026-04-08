---
name: arn-spark-stress-premortem
description: >-
  This skill should be used when the user says "pre-mortem", "premortem",
  "risk analysis", "stress premortem", "failure analysis", "what could go wrong",
  "pre mortem", "investigate failure", "failure modes", or wants to stress-test a
  product concept by applying Gary Klein's pre-mortem methodology to identify
  hypothetical failure root causes, early warning signals, and mitigation
  strategies. Produces a pre-mortem report with 3 root causes across distinct
  failure dimensions and recommended concept updates.
version: 1.0.0
---

# Arness Spark Stress Pre-Mortem

Stress-test a product concept using Gary Klein's pre-mortem methodology. Instead of asking "what could go wrong?" (which invites optimism bias), the pre-mortem declares that the product has already launched and failed, then investigates why.

The process works like this:
1. **Accept the premise:** It is 12 months after launch. The product was shut down today.
2. **Investigate:** A forensic investigator agent works backward from the failure to identify 3 distinct root causes -- a core experience flaw (A), a trust/security blind spot (B), and a target audience assumption error (C).
3. **Assess:** Each root cause gets a causal chain, early warning signals, mitigation strategies, and a likelihood/severity rating.
4. **Prioritize:** Root causes are mapped on a risk priority matrix to identify what needs immediate attention.

This technique surfaces failure modes that optimism obscures. The product concept is read but never modified -- all recommendations are captured in the pre-mortem report for later review.

## Prerequisites

### Configuration Check

1. Read the project's `CLAUDE.md` and check for a `## Arness` section
2. If found, extract the configured **Vision directory** and **Reports directory** paths
3. If no `## Arness` section exists or Arness Spark fields are missing, inform the user: "Arness Spark is not configured for this project yet. Run `/arn-brainstorming` to get started — it will set everything up automatically." Do not proceed without it.
4. If the Reports directory does not exist, create it with `mkdir -p <reports-dir>/stress-tests/`

### Data Availability

| Artifact | Status | Location | Fallback |
|----------|--------|----------|----------|
| Product concept | REQUIRED | `<vision-dir>/product-concept.md` | Cannot proceed without it -- suggest running `/arn-spark-discover` |
| Product pillars | ENRICHES | Product Pillars section of product concept | Investigation proceeds but pillar-as-evidence analysis is less targeted |
| Competitive landscape | ENRICHES | Competitive Landscape section of product concept | Root Cause C (market misread) is less grounded in competitive dynamics |
| Target personas | ENRICHES | Target Personas section of product concept | Root Cause A and C are less grounded in persona-specific failure scenarios |

**Product concept fallback:**

If no product concept exists:

Ask (using `AskUserQuestion`): **"No product concept found. The pre-mortem needs a product concept to investigate. How would you like to proceed?"**
1. Run `/arn-spark-discover` to create a product concept first
2. Describe the product now (I will conduct the pre-mortem from your description)
3. Skip the pre-mortem stress test

If the user chooses option 2, collect a product description and proceed with a reduced-fidelity investigation (note in the report that the investigation was based on a verbal description rather than a full product concept).

## Workflow

### Step 1: Load References

Load the pre-mortem protocol and report template:
> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-stress-premortem/references/premortem-protocol.md`
> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-stress-premortem/references/premortem-report-template.md`

### Step 2: Read Product Concept and Extract Context

Read the product concept from `<vision-dir>/product-concept.md`. Extract:
- Full product concept (the investigator needs the complete document)
- Product pillars (used as forensic evidence -- pillars often become failure vectors)
- Competitive landscape (grounds Root Cause C in real competitive dynamics)
- Target personas (grounds Root Causes A and C in specific user scenarios)
- Core experience (primary investigation target for Root Cause A)
- Trust & security model (primary investigation target for Root Cause B)

### Step 3: Invoke Forensic Investigator

Invoke `arn-spark-forensic-investigator` with:

--- PRODUCT CONCEPT ---
[full product concept document]
--- END PRODUCT CONCEPT ---

--- PRODUCT PILLARS ---
[product pillars section -- these are forensic evidence, not goals to protect]
--- END PRODUCT PILLARS ---

--- COMPETITIVE LANDSCAPE ---
[competitive landscape section, or "Not available" if absent]
--- END COMPETITIVE LANDSCAPE ---

--- TARGET PERSONAS ---
[target personas section from the product concept, or "Not available" if absent]
--- END TARGET PERSONAS ---

--- INVESTIGATION TASK ---
Standard investigation: Generate 3 root causes across distinct failure dimensions:
- Root Cause A: Core Experience Flaw leading to user churn
- Root Cause B: Trust & Security Blind Spot leading to breach or exodus
- Root Cause C: Target Audience Assumption that was wrong

For each root cause: failure narrative, causal chain (4 links), early warning signals (3), mitigation strategies (3), likelihood assessment, severity assessment.

Include a Recommended Concept Updates table and Unresolved Questions section.
--- END INVESTIGATION TASK ---

### Step 4: Validate Investigation Quality

Review the forensic investigator's output for quality:

1. **3 distinct root causes:** Each root cause must have a distinct causal chain. If two root causes share the same underlying mechanism, they are one root cause, not two.
2. **Specificity:** Root causes must reference specific elements of the product concept (features, claims, personas, pillars). Generic failures that could apply to any product are rejected.
3. **Adversarial depth:** Root causes must be genuinely adversarial -- not soft, hedged, or diplomatic. Each should make someone wince and say "that could actually happen."

**If quality is insufficient:** Retry with an explicit adversarial instruction:

"The investigation was too soft. Requirements:
- Each root cause must quote or reference a specific claim from the product concept
- Each causal chain must have 4 distinct links, not 2 restated
- Each early warning signal must include a specific metric threshold or observable behavior
- Failure narratives must describe what users actually experienced, not abstract disappointment"

If the retry also fails quality checks, proceed with the best available output and note the quality gap in the report.

### Step 5: Draft Recommended Concept Updates

Review the investigator's Recommended Concept Updates table. Ensure:
- Each recommendation uses the 6-column schema: `# | Section | Current State | Recommended Change | Type | Rationale`
- Each recommendation traces to a specific root cause
- Type column uses Add/Modify/Remove
- Recommendations from "Address immediately" and "Mitigate" cells in the risk priority matrix are all represented

If the investigator's recommendations are incomplete, supplement from the mitigation strategies.

### Step 6: Assemble and Write Report

Using the pre-mortem report template:
1. Populate all sections with investigator output
2. Construct the Risk Priority Matrix from likelihood/severity assessments
3. Write the report to `<reports-dir>/stress-tests/premortem-report.md`

Present a summary to the user:

"Pre-mortem investigation complete. Report saved to `[path]`.

**Failure premise:** [Product name] launched and was shut down 12 months later.

**Root causes identified:**
- **A -- [Title]:** [1-sentence summary] (Likelihood: [L], Severity: [S])
- **B -- [Title]:** [1-sentence summary] (Likelihood: [L], Severity: [S])
- **C -- [Title]:** [1-sentence summary] (Likelihood: [L], Severity: [S])

**Risk priority:** [N] root causes require immediate attention, [N] require mitigation
**Recommended concept updates:** [N] recommendations ([X] Add, [Y] Modify, [Z] Remove)
**Unresolved questions:** [N]

This report will be used by `/arn-spark-concept-review` to propose changes to the product concept."

## Agent Invocation Guide

| Situation | Agent | Mode/Context |
|-----------|-------|--------------|
| Standard pre-mortem investigation | `arn-spark-forensic-investigator` | Full product concept with pillars and competitive landscape |
| Targeted deep-dive (future) | `arn-spark-forensic-investigator` | Specific failure scenario for extended analysis |

## Error Handling

- **Forensic investigator produces soft/hedged failures:** Retry with explicit adversarial instruction emphasizing that failures must be specific, vivid, and grounded in product concept details. Include: "Generic failures like 'users did not find it useful' are worthless -- explain exactly why and how."

- **Forensic investigator produces fewer than 3 root causes:** Retry specifying which failure dimension is missing and providing additional context for that dimension. If retry still produces fewer than 3, proceed with available output and note the gap.

- **Forensic investigator produces overlapping root causes:** Retry specifying that each root cause must have a distinct causal mechanism. If two root causes share the same first link in the causal chain, they are one root cause.

- **Agent invocation fails entirely:** Retry once with a simplified prompt. If retry fails:
  Ask (using `AskUserQuestion`): **"Agent invocation failed. How would you like to proceed?"**
  1. Retry
  2. Skip this step
  3. Abort

## Constraints

- **Read-only with respect to product-concept.md.** The pre-mortem skill reads the product concept but NEVER modifies it. All recommendations are captured in the pre-mortem report.
- **3 root causes across distinct dimensions.** The standard investigation always targets 3 failure dimensions (core experience, trust/security, audience). This ensures coverage across the most common failure modes.
- **Report overwrites on re-run.** If `premortem-report.md` already exists, it is overwritten. Git provides history.
