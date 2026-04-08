# PR/FAQ Workflow

Two-phase workflow for the Amazon PR/FAQ stress test method. This document is consumed by the `arn-spark-stress-prfaq` skill to orchestrate the marketing PM agent across draft and critique modes.

## Overview

The PR/FAQ method forces a product concept to pass two tests:

1. **Can you tell a compelling story about this product?** If the press release is unconvincing, the product concept has messaging problems that likely trace to concept clarity problems.
2. **Does the story hold up under scrutiny?** If adversarial questions expose crack points, the product concept has structural weaknesses that need addressing before architecture commitment.

The two phases use **separate agent invocations** by design. Same-context self-critique tends toward rubber-stamping -- the critic unconsciously defends what the drafter wrote. Separate invocations force genuine adversarial evaluation.

---

## Phase 1: Draft Mode

### Goal

Produce a genuinely compelling press release and FAQ that represents the best possible public story of the product. The draft must be good enough that a real reader would want to try the product -- not a placeholder exercise with bracketed terms.

### Agent Invocation

Invoke `arn-spark-marketing-pm` in **draft mode** with:
- Full product concept
- Product pillars (to anchor messaging)
- Operating mode: `draft`

### Expected Output

1. **Press Release (400-600 words)** following Amazon PR/FAQ format:
   - Headline -- news-worthy, not a tagline
   - Subheading -- who this is for and what it changes
   - Problem paragraph -- specific, grounded in real scenarios
   - Solution paragraph -- user experience focused, not technology focused
   - Customer quote -- realistic, from a target persona, referencing a specific workflow scenario
   - Product details paragraph -- features organized by value, not architecture
   - Call to action -- specific next step

2. **Customer FAQ (5-8 entries)** -- questions a potential customer would ask:
   - Practical usage (how it works in their workflow)
   - Pricing and access
   - Migration and onboarding
   - Data handling and privacy
   - Integration with existing tools
   - Scope boundaries framed as focus, not limitation

3. **Internal FAQ (3-5 entries)** -- harder questions the team asks themselves:
   - Why this will succeed where competitors failed
   - Biggest technical risk
   - Go-to-market strategy for first 1000 users
   - Key assumption risk
   - Success metrics for first 90 days

### Quality Check

Before proceeding to Phase 2, verify the draft is substantive:
- Press release should be 400-600 words, not a skeleton
- Customer FAQ answers should be concrete, not "it depends"
- Internal FAQ questions should be genuinely hard, not softballs
- Customer quote should sound like a real person, not a marketing team

If the draft is too thin or generic, retry with more specific context from the product concept -- highlight specific features, personas, and competitive positioning to ground the draft.

---

## Phase 2: Critique Mode

### Goal

Adversarially evaluate the draft to find every place where the messaging makes a claim the product concept cannot fully support. The critique is not about copywriting quality -- it is about concept integrity.

### Agent Invocation

Invoke `arn-spark-marketing-pm` in **critique mode** with:
- Full product concept (same as Phase 1)
- Product pillars (same as Phase 1)
- Operating mode: `critique`
- Draft output from Phase 1 (complete press release + both FAQs)

**Critical:** This MUST be a separate invocation from Phase 1. Do not pass Phase 1 context or conversation history. The critic has no memory of being the drafter.

### Expected Output

1. **Adversarial Questions (5-8)** -- questions the PR dodges:
   - Each with: the question, why the PR dodges it, damage potential (High/Medium/Low)
   - Focus on questions that expose concept weaknesses, not messaging weaknesses

2. **Crack Points (3-5)** -- gaps between messaging claims and concept substance:
   - What the concept claims (from the PR/FAQ)
   - What the question reveals (the gap or contradiction)
   - What needs strengthening (actionable recommendation for the concept, not the copy)

3. **Recommended Concept Updates** -- standardized table derived from crack points

4. **Unresolved Questions** -- questions the critique raised that need real data to answer

### Quality Check

Verify the critique is genuinely adversarial:
- Adversarial questions should target concept substance, not word choice
- Crack points should identify real gaps, not cosmetic issues
- Damage potential ratings should be justified, not all "Medium"
- Recommendations should change the product concept, not the press release

If the critique is too soft, retry with explicit instruction: "The critique should make the product team uncomfortable. If no crack point makes someone say 'we need to address that before we build this,' the critique is too gentle."

---

## Rationale for Separate Invocations

The two-mode architecture exists because of a well-documented cognitive bias: **consistency bias in self-evaluation.** When the same agent drafts and critiques in a single context:

1. The critic has access to the drafter's reasoning and intent, making it harder to challenge assumptions that "obviously" made sense during drafting
2. The critic unconsciously defends claims it just wrote, finding reasons they work rather than reasons they fail
3. Questions tend to be answerable (because the critic already knows the answers) rather than genuinely probing

Separate invocations break this pattern by forcing the critic to evaluate the draft as an outsider -- the same way a real journalist, competitor, or skeptical customer would encounter the messaging.
