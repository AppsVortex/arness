# PR/FAQ Report Template

Template for the PR/FAQ stress test report. This document is consumed by the `arn-spark-stress-prfaq` skill when assembling the final report from the marketing PM's draft and critique outputs.

## Instructions for arn-spark-stress-prfaq

When populating this template:

- Every section below MUST appear in the output
- Replace all bracketed placeholders with concrete content from the marketing PM's draft and critique outputs
- The Press Release should be the FULL text from draft mode, not a summary
- Customer FAQ and Internal FAQ should include ALL entries from draft mode
- Adversarial Questions and Crack Points should include ALL entries from critique mode
- The Recommended Concept Updates table MUST use the standardized schema exactly as shown
- Unresolved Questions should capture questions that emerged from the critique but cannot be answered without real user data or market research
- If either draft or critique mode failed, note what was captured and explain the gap

---

## Template

```markdown
# PR/FAQ Stress Test Report

**Product:** [product name]
**Date:** [ISO 8601 date]

---

## Executive Summary

[3-5 sentences summarizing the PR/FAQ stress test findings. Was the product story compelling? Where did it crack? What was the most significant finding from the critique?]

---

## Press Release

### [Headline]

**[Subheading]**

[Problem paragraph]

[Solution paragraph]

> "[Customer quote]"
> -- [Persona name], [role/context]

[Product details paragraph]

**[Call to action]**

---

## Customer FAQ

### Q: [Question 1]
[Answer]

### Q: [Question 2]
[Answer]

[... 5-8 entries total]

---

## Internal FAQ

### Q: [Question 1]
[Answer]

### Q: [Question 2]
[Answer]

[... 3-5 entries total]

---

## Adversarial Questions

### 1. [Question]
**Why the PR dodges this:** [explanation of what claim is made and what evidence is missing]
**Damage potential:** [High/Medium/Low] -- [brief justification]

### 2. [Question]
**Why the PR dodges this:** [explanation]
**Damage potential:** [High/Medium/Low] -- [justification]

[... 5-8 entries total]

---

## Crack Point Analysis

### 1. [Crack Point Title]
- **What the concept claims:** [specific claim from the PR/FAQ]
- **What the question reveals:** [the gap, assumption, or contradiction exposed]
- **What needs strengthening:** [actionable recommendation for the product concept]

### 2. [Crack Point Title]
- **What the concept claims:** [specific claim]
- **What the question reveals:** [gap exposed]
- **What needs strengthening:** [recommendation]

[... 3-5 entries total]

---

## Recommended Concept Updates

| # | Section | Current State | Recommended Change | Type | Rationale |
|---|---------|---------------|--------------------|------|-----------|
| 1 | [product concept section] | [what the concept currently says or assumes] | [specific change recommended] | [Add/Modify/Remove] | [which crack point this addresses -- reference crack point number] |
| 2 | ... | ... | ... | ... | ... |

---

## Unresolved Questions

| # | Section | Question | Options | Assessment |
|---|---------|----------|---------|------------|
| 1 | [product concept section] | [question that the PR/FAQ critique raised but cannot be answered without real data] | [possible approaches to answering this] | [preliminary assessment based on critique findings] |
| 2 | ... | ... | ... | ... |
```

---

## Section Guidance

| Section | Source | Depth |
|---------|--------|-------|
| Executive Summary | Synthesized by skill from draft quality assessment and critique findings | 3-5 sentences, overall messaging integrity assessment |
| Press Release | Marketing PM draft mode output | Full text, 400-600 words, Amazon PR/FAQ format |
| Customer FAQ | Marketing PM draft mode output | 5-8 entries with concrete, specific answers |
| Internal FAQ | Marketing PM draft mode output | 3-5 entries with honest, hard-question answers |
| Adversarial Questions | Marketing PM critique mode output | 5-8 questions with dodge explanations and damage potential ratings |
| Crack Point Analysis | Marketing PM critique mode output | 3-5 crack points with: claim, revelation, and strengthening recommendation |
| Recommended Concept Updates | Marketing PM critique mode output, reviewed by skill | One row per recommendation, Type must be Add/Modify/Remove, rationale must reference specific crack point |
| Unresolved Questions | Identified during critique as questions requiring real data | One row per question, must specify which product concept section is affected |
