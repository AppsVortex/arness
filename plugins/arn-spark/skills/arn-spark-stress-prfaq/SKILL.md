---
name: arn-spark-stress-prfaq
description: >-
  This skill should be used when the user says "prfaq", "pr faq", "pr/faq",
  "press release stress test", "stress prfaq", "amazon pr faq method",
  "test the pitch with a pr/faq", "validate concept through pr/faq",
  "critique press release", "pr faq stress test",
  "will this marketing story hold up", or wants to stress-test a product concept by drafting a
  compelling press release and FAQ, then adversarially critiquing it to find
  where the concept cracks under scrutiny. Produces a PR/FAQ report with the
  full draft, adversarial questions, crack point analysis, and recommended
  concept updates.
version: 1.0.0
---

# Arness Spark Stress PR/FAQ

Stress-test a product concept using Amazon's PR/FAQ method. This technique forces the product concept through two filters:

1. **Draft phase:** A marketing PM agent writes the best possible public story -- a compelling press release, customer FAQ, and internal FAQ. If the press release is unconvincing, the product concept likely has clarity problems.
2. **Critique phase:** The same marketing PM agent (in a separate invocation, with no memory of drafting) adversarially attacks the draft -- finding questions the PR dodges, identifying crack points where claims exceed substance, and recommending concept changes.

The two phases use **separate agent invocations** to prevent rubber-stamping. A critic who remembers being the drafter unconsciously defends what it wrote. Separate invocations force genuine adversarial evaluation.

The product concept is read but never modified -- all recommendations are captured in the PR/FAQ report for later review.

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
| Product pillars | ENRICHES | Product Pillars section of product concept | Draft messaging is less focused; critique has fewer anchors |
| Competitive landscape | ENRICHES | Competitive Landscape section of product concept | Draft positioning is less grounded in market context |
| Target personas | ENRICHES | Target Personas section of product concept | Customer quote in press release is less persona-specific |

**Standard fallback cascade:**

If no product concept exists:

Ask (using `AskUserQuestion`): **"No product concept found. The PR/FAQ stress test needs a product concept to draft and critique messaging for. How would you like to proceed?"**
1. Run `/arn-spark-discover` to create a product concept first
2. Describe the product now (I will conduct the PR/FAQ from your description)
3. Skip the PR/FAQ stress test

If the user chooses option 2, collect a product description and proceed with a reduced-fidelity test (note in the report that the test was based on a verbal description rather than a full product concept).

## Workflow

### Step 1: Load References

Load the PR/FAQ workflow and report template:
> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-stress-prfaq/references/prfaq-workflow.md`
> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-stress-prfaq/references/prfaq-report-template.md`

### Step 2: Read Product Concept and Extract Context

Read the product concept from `<vision-dir>/product-concept.md`. Extract:
- Full product concept (both draft and critique need the complete document)
- Product pillars (anchors messaging in draft, tested for sincerity in critique)
- Competitive landscape (grounds positioning in real market context)
- Target personas (for realistic customer quote in press release)
- Core experience (primary material for the solution paragraph)

### Step 3: Phase 1 -- Draft

Invoke `arn-spark-marketing-pm` in **draft mode** with:

--- PRODUCT CONCEPT ---
[full product concept document]
--- END PRODUCT CONCEPT ---

--- PRODUCT PILLARS ---
[product pillars section]
--- END PRODUCT PILLARS ---

--- OPERATING MODE ---
draft
--- END OPERATING MODE ---

Receive back the complete draft: press release (400-600 words), customer FAQ (5-8 entries), internal FAQ (3-5 entries).

**Quality check before proceeding:**
- Press release must be 400-600 words and compelling (would a reporter find this newsworthy? Does it lead with customer value, not features?)
- Customer FAQ answers must be concrete with specific examples, not evasive hedging
- Internal FAQ questions must address genuine tensions or risky claims in the press release
- Customer quote must use colloquial language and personal emotion, not corporate phrasing

If the draft is too thin or generic, retry with more specific context:

"The draft needs to be more specific. Ground it in these details:
- Target persona for the customer quote: [specific persona from product concept]
- Key competitive differentiator: [from competitive landscape]
- Core interaction to highlight: [from core experience]
- Most important pillar to anchor messaging: [from product pillars]"

### Step 4: Phase 2 -- Critique

Invoke `arn-spark-marketing-pm` in **critique mode** with:

--- PRODUCT CONCEPT ---
[full product concept document -- same as Phase 1]
--- END PRODUCT CONCEPT ---

--- PRODUCT PILLARS ---
[product pillars section -- same as Phase 1]
--- END PRODUCT PILLARS ---

--- OPERATING MODE ---
critique
--- END OPERATING MODE ---

--- DRAFT OUTPUT ---
[complete draft from Phase 1 -- press release + customer FAQ + internal FAQ]
--- END DRAFT OUTPUT ---

**Critical:** This MUST be a separate agent invocation from Phase 1. Include ONLY: the full product concept, the product pillars, the complete draft output (press release + FAQs), and the critique task instructions. Do NOT include any conversation context from the draft phase or any conversational recap.

Receive back: adversarial questions (5-8), crack points (3-5), recommended concept updates table, unresolved questions.

**Quality check:**
- Adversarial questions must target concept substance, not word choice
- Crack points must identify real gaps between claims and substance
- At least one crack point should reference a product pillar
- Recommendations must change the product concept, not the press release

If the critique is too soft, retry with explicit adversarial instruction:

"The critique needs to be sharper. Requirements:
- At least 2 adversarial questions rated High damage potential
- Crack points must reference specific claims from the press release and specific gaps in the product concept
- If no crack point makes someone say 'we need to address that before building this,' the critique is too gentle
- Do not find ways the messaging could be improved -- find ways the underlying concept fails"

### Step 5: Draft Recommended Concept Updates

Review the critique's Recommended Concept Updates table. Ensure:
- Each recommendation uses the standardized schema
- Each recommendation traces to a specific crack point
- Type column uses Add/Modify/Remove
- All crack points with High damage potential adversarial questions have corresponding recommendations

If the critique's recommendations are incomplete, supplement from the crack point "What needs strengthening" fields.

### Step 6: Assemble and Write Report

Using the PR/FAQ report template:
1. Populate all sections with draft output and critique output
2. Include the full press release text, all FAQ entries, all adversarial questions, and all crack points
3. Write the report to `<reports-dir>/stress-tests/prfaq-report.md`

Present a summary to the user:

"PR/FAQ stress test complete. Report saved to `[path]`.

**Draft assessment:** [1 sentence on whether the product story was compelling]

**Key critique findings:**
- **Adversarial questions:** [N] questions the PR dodges ([X] High damage, [Y] Medium, [Z] Low)
- **Crack points:** [N] places where the concept cracks under scrutiny

**Top crack point:** [The highest-impact crack point in 1 sentence]

**Recommended concept updates:** [N] recommendations ([X] Add, [Y] Modify, [Z] Remove)
**Unresolved questions:** [N]

This report will be used by `/arn-spark-concept-review` to propose changes to the product concept."

## Agent Invocation Guide

| Situation | Agent | Mode/Context |
|-----------|-------|--------------|
| Write press release and FAQ | `arn-spark-marketing-pm` | Draft mode with product concept and pillars |
| Adversarially critique the draft | `arn-spark-marketing-pm` | Critique mode with product concept, pillars, and draft output (separate invocation) |

## Error Handling

- **Marketing PM produces generic/thin draft:** Retry with more specific context from the product concept -- highlight specific features, personas, and competitive positioning. If retry still produces thin output:
  Ask (using `AskUserQuestion`): **"The PR/FAQ draft is too generic to produce a useful critique. How would you like to proceed?"**
  1. Retry with additional context
  2. Proceed with the current draft (critique may be less effective)
  3. Abort the PR/FAQ stress test

- **Marketing PM produces soft critique:** Retry with explicit adversarial instruction emphasizing that the critique must target concept substance, not copywriting quality. Include: "If no crack point makes someone uncomfortable, the critique has failed."

- **Critique mode receives draft context (accidental context leak):** This should not happen if invocations are properly separated. If detected (the critique references drafting decisions or uses phrases like "when I wrote..."), discard the critique and re-invoke in critique mode with only the draft output and product concept -- no conversational context.

- **Any agent invocation fails entirely:** Retry once with a simplified prompt. If retry fails:
  Ask (using `AskUserQuestion`): **"Agent invocation failed. How would you like to proceed?"**
  1. Retry
  2. Skip this step
  3. Abort

## Constraints

- **Read-only with respect to product-concept.md.** The PR/FAQ skill reads the product concept but NEVER modifies it. All recommendations are captured in the PR/FAQ report.
- **Separate invocations for draft and critique.** This is a hard requirement, not a preference. Same-context self-critique produces rubber-stamp results. The draft and critique MUST be separate agent invocations with no shared conversational context.
- **Report overwrites on re-run.** If `prfaq-report.md` already exists, it is overwritten. Git provides history.
