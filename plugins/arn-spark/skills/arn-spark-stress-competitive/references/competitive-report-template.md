# Competitive Report Template

Template for the competitive gap analysis stress test report. This document is consumed by the `arn-spark-stress-competitive` skill when assembling the final report from market researcher findings and gap analysis.

## Instructions for arn-spark-stress-competitive

When populating this template:

- Every section below MUST appear in the output
- Replace all bracketed placeholders with concrete content from market researcher output and gap analysis
- The Feature Comparison Matrix must include ALL features identified -- do not omit features where the product is weak
- Gap Analysis must cover all 4 categories even if a category is empty (write "None identified" if so)
- The Recommended Concept Updates table MUST use the standardized schema exactly as shown
- Unresolved Questions should capture gaps in competitive intelligence that could not be resolved with available data
- Source URLs should be included where available from market researcher output

---

## Template

```markdown
# Competitive Gap Analysis Report

**Product:** [product name]
**Date:** [ISO 8601 date]
**Competitors analyzed:** [Competitor 1], [Competitor 2], [Competitor 3], ...

---

## Executive Summary

[3-5 sentences summarizing the competitive position. Where is the product strong? Where is it vulnerable? What is the most significant finding?]

---

## Feature Comparison Matrix

| Feature | Category | [Product] | [Competitor 1] | [Competitor 2] | [Competitor 3] | Notes |
|---------|----------|-----------|-----------------|-----------------|-----------------|-------|
| [feature] | [Core/Diff/Stakes] | [Yes/No/Partial/Planned] | [Yes/No/Partial/Unknown] | ... | ... | [context] |

**Legend:**
- **Yes:** Fully available and functional
- **No:** Not available
- **Partial:** Available with significant limitations
- **Planned:** In product concept scope but not yet built
- **Unknown:** Insufficient data

---

## Per-Competitor Gap Analysis

### [Competitor 1 Name]

**Overview:** [1-2 sentences on what this competitor does and who they serve]

**Their advantages over [product]:**
- [Advantage 1 -- specific feature or capability with context]
- [Advantage 2]

**Our advantages over them:**
- [Advantage 1 -- specific feature or capability with context]
- [Advantage 2]

**Key differentiator:** [The single most important difference between this competitor and the product]

**Switching cost assessment:** [What it would take for their user to switch to the product, and vice versa]

---

### [Competitor 2 Name]

[Same structure as Competitor 1]

---

### [Competitor 3 Name]

[Same structure as Competitor 1]

---

## Positioning Assessment

### Market Position Map

**Crowded areas:** [Feature categories where 3+ competitors are strong -- differentiation is harder here]

**Underserved areas:** [Feature categories with 0-1 competitors -- opportunity for ownership]

**Product alignment:** [Does the product concept position itself in underserved areas or compete head-on in crowded spaces?]

### Defensibility

**Defensible strengths:** [Product advantages that are hard to replicate -- network effects, data moats, technical complexity]

**Vulnerable strengths:** [Product advantages that competitors could replicate quickly -- UI features, integrations, pricing]

**Estimated competitive response time:** [How long before well-resourced competitors could close the gap on key differentiators]

### Switching Costs

**Inbound switching cost:** [Cost for users moving FROM competitors TO this product]

**Outbound switching cost:** [Cost for users moving FROM this product TO competitors]

**Lock-in assessment:** [Does the product concept create healthy retention or problematic lock-in?]

---

## Recommended Concept Updates

| # | Section | Current State | Recommended Change | Type | Rationale |
|---|---------|---------------|--------------------|------|-----------|
| 1 | [product concept section] | [what the concept currently says or assumes] | [specific change recommended] | [Add/Modify/Remove] | [which competitive finding supports this] |
| 2 | ... | ... | ... | ... | ... |

---

## Unresolved Questions

| # | Section | Question | Options | Assessment |
|---|---------|----------|---------|------------|
| 1 | [product concept section] | [question about competitive position that could not be resolved] | [possible approaches to answering this] | [preliminary assessment based on available data] |
| 2 | ... | ... | ... | ... |
```

---

## Section Guidance

| Section | Source | Depth |
|---------|--------|-------|
| Executive Summary | Synthesized by skill from gap analysis findings | 3-5 sentences, strategic overview |
| Feature Comparison Matrix | Market researcher deep-analysis output + gap analysis framework | All identified features, all analyzed competitors, with indicators and notes |
| Per-Competitor Gap Analysis | Market researcher findings structured per competitor | Per competitor: overview, their advantages, our advantages, key differentiator, switching cost |
| Positioning Assessment | Gap analysis framework Steps 4-5 applied to findings | Market position map, defensibility analysis, switching cost assessment |
| Recommended Concept Updates | Derived from Critical and High weight gaps | One row per recommendation, Type must be Add/Modify/Remove, rationale must reference specific competitive findings |
| Unresolved Questions | Gaps in competitive intelligence identified during analysis | One row per question, must specify which product concept section is affected |
