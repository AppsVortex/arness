# Gap Analysis Framework

Structured framework for conducting deep competitive gap analysis. This document is consumed by the `arn-spark-stress-competitive` skill to guide feature comparison, gap identification, and positioning assessment.

## Overview

Competitive gap analysis goes beyond surface-level feature comparison. The goal is to understand where the product concept is uniquely strong, where competitors have advantages, and where the market has gaps that no one is filling. This analysis uses the product's own pillars as a weighting mechanism -- gaps that threaten core pillars are more critical than gaps in peripheral features.

---

## Step 1: Feature Category Identification

Classify features into three categories based on their strategic role:

### Core Features
Features that directly deliver the product's primary value proposition. Without these, the product has no reason to exist. They correspond to the product concept's Core Experience section.

### Differentiating Features
Features that set the product apart from competitors. These may align with product pillars and represent the product's unique market position. Losing parity on these features undermines the product's reason to exist as a separate offering.

### Table-Stakes Features
Features that users expect as baseline functionality in this product category. Missing a table-stakes feature is not a competitive advantage for others -- it is a disqualification for the product. Examples: authentication, data export, mobile support (if the category demands it).

---

## Step 2: Comparison Matrix Construction

Build a feature comparison matrix with the following structure:

| Feature | Category | [Product] | [Competitor 1] | [Competitor 2] | ... | Notes |
|---------|----------|-----------|-----------------|-----------------|-----|-------|
| [feature name] | Core / Diff / Stakes | Yes/No/Partial/Planned | Yes/No/Partial/Unknown | ... | ... | [context] |

**Indicators:**
- **Yes:** Feature is fully available and functional
- **No:** Feature is not available
- **Partial:** Feature exists but with significant limitations
- **Planned:** Feature is in the product concept's scope but not yet built (for the product being analyzed)
- **Unknown:** Insufficient data to determine (mark for follow-up research)

**Matrix population approach:**
1. Start with the product concept's features (from Core Experience, scope boundaries)
2. Add features found in competitor research that the product concept does not mention
3. Add table-stakes features for the product category even if no competitor lists them explicitly
4. For each competitor, populate based on market researcher findings, public documentation, and feature pages

---

## Step 3: Gap Classification

From the comparison matrix, classify gaps into four categories:

### Our Unique Strengths
Features or capabilities where the product has a clear advantage that competitors lack. These are the product's defensible differentiators. Evaluate:
- How durable is this advantage? (Easy to copy vs. hard to replicate)
- How much do users care about this advantage? (Pillar-aligned vs. nice-to-have)
- Is this advantage acknowledged in the product concept's positioning?

### Competitor Advantages
Features or capabilities where one or more competitors have a clear lead. These represent potential adoption barriers. Evaluate:
- How critical is this feature to the target personas?
- Is the gap addressable within the product concept's scope, or does it require a scope change?
- Is the competitor's advantage based on features, execution quality, or market position?

### Uncovered Market Gaps
Opportunities that neither the product nor competitors address. These are potential differentiators if the product concept expands to fill them. Evaluate:
- Is there evidence of user demand for this capability?
- Does filling this gap align with the product's pillars?
- What would it cost (in scope and complexity) to address?

### Parity Features
Features where the product and key competitors are roughly equivalent. These are not strategic concerns but should be monitored for drift.

---

## Step 4: Gap Weighting by Product Pillars

Weight each gap by its relevance to the product's declared pillars:

| Gap | Pillar Alignment | Weight | Rationale |
|-----|-----------------|--------|-----------|
| [gap description] | [which pillar(s)] | Critical / High / Medium / Low | [why this gap matters to the pillar] |

**Weighting rules:**
- **Critical:** Gap directly contradicts or undermines a product pillar
- **High:** Gap significantly weakens a pillar's delivery
- **Medium:** Gap is relevant to a pillar but does not directly threaten it
- **Low:** Gap is real but not pillar-aligned

Gaps weighted Critical or High should appear in the Recommended Concept Updates table.

---

## Step 5: Positioning Assessment

Evaluate the product's market position based on the gap analysis:

### Crowded vs. Underserved Areas
- Which feature categories have 3+ competitors with strong offerings? (crowded -- differentiation is harder)
- Which feature categories have 0-1 competitors? (underserved -- opportunity for ownership)
- Does the product concept's positioning align with underserved areas or compete head-on in crowded spaces?

### Defensibility Analysis
- Which of the product's unique strengths are defensible? (network effects, data moats, technical complexity, brand trust)
- Which are easily replicated? (UI features, integrations, pricing models)
- What is the estimated time for a well-resourced competitor to close the gap on each unique strength?

### Switching Cost Assessment
- What is the switching cost for a user moving FROM a competitor TO this product? (data migration, learning curve, workflow disruption)
- What is the switching cost for a user moving FROM this product TO a competitor? (lock-in, data portability)
- Does the product concept address switching costs explicitly?
