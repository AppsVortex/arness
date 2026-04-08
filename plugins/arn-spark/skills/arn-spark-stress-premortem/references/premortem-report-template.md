# Pre-Mortem Report Template

Template for the pre-mortem risk mitigation stress test report. This document is consumed by the `arn-spark-stress-premortem` skill when assembling the final report from the forensic investigator's output.

## Instructions for arn-spark-stress-premortem

When populating this template:

- Every section below MUST appear in the output
- Replace all bracketed placeholders with concrete content from the forensic investigator's output
- Each Root Cause must have ALL 6 subsections: Failure Narrative, Causal Chain, Early Warning Signals, Mitigation Strategies, Likelihood, Severity
- The Risk Priority Matrix must accurately reflect the Likelihood/Severity assessments from the root causes
- The Recommended Concept Updates table MUST use the standardized schema exactly as shown
- Unresolved Questions should capture questions that the pre-mortem raised but could not answer
- If the forensic investigator produced fewer than 3 root causes or overlapping root causes, note this in the report and explain what happened

---

## Template

```markdown
# Pre-Mortem Investigation Report

**Product:** [product name]
**Date:** [ISO 8601 date]
**Failure premise:** It is [date + 12 months]. [Product name] launched 12 months ago and was shut down today.

---

## Executive Summary

[3-5 sentences summarizing the investigation findings. What was the most likely failure mode? What was the most severe? What was the most surprising finding? Overall risk posture of the product concept.]

---

## Failure Premise

[2-3 sentences establishing the temporal frame and initial conditions. How did the launch go? What was the initial reception? What happened in the months that followed?]

---

## Root Cause A: Core Experience Flaw -- [Specific Flaw Title]

**Failure Narrative:**
[3-5 sentences describing what happened from the user's perspective. Specific, vivid, grounded in the product concept's own claims. Reference specific features, interactions, and personas.]

**Causal Chain:**
1. [Design assumption in the product concept]
2. [How that assumption played out in practice]
3. [The compounding effect that made recovery impossible]
4. [The specific trigger event that forced shutdown]

**Early Warning Signals:**
- [Signal 1 -- observable in month 1-2, with specific metric or behavior]
- [Signal 2 -- a metric or user behavior pattern]
- [Signal 3 -- a qualitative signal from feedback or support]

**Mitigation Strategies:**
1. [Specific change to the product concept that addresses the root cause]
2. [Monitoring or validation approach to catch early warning signals]
3. [Design alternative that avoids the failure chain entirely]

**Likelihood:** [High / Medium / Low] -- [1-sentence justification referencing specific product concept elements]
**Severity:** [Critical / High / Medium] -- [1-sentence justification]

---

## Root Cause B: Trust & Security Blind Spot -- [Specific Blind Spot Title]

**Failure Narrative:**
[Same structure as Root Cause A]

**Causal Chain:**
1. [Trust/security assumption in the product concept]
2. [How that assumption was tested by real-world conditions]
3. [The compounding effect -- loss of user confidence, regulatory response, competitive messaging]
4. [The trigger event -- specific incident or revelation]

**Early Warning Signals:**
- [Signal 1]
- [Signal 2]
- [Signal 3]

**Mitigation Strategies:**
1. [Strategy 1]
2. [Strategy 2]
3. [Strategy 3]

**Likelihood:** [High / Medium / Low] -- [justification]
**Severity:** [Critical / High / Medium] -- [justification]

---

## Root Cause C: Target Audience Assumption -- [Specific Assumption Title]

**Failure Narrative:**
[Same structure as Root Cause A]

**Causal Chain:**
1. [Audience assumption in the product concept]
2. [How the actual market differed from the assumed market]
3. [The compounding effect -- wrong users, wrong positioning, wrong growth strategy]
4. [The trigger event -- specific metric or market shift]

**Early Warning Signals:**
- [Signal 1]
- [Signal 2]
- [Signal 3]

**Mitigation Strategies:**
1. [Strategy 1]
2. [Strategy 2]
3. [Strategy 3]

**Likelihood:** [High / Medium / Low] -- [justification]
**Severity:** [Critical / High / Medium] -- [justification]

---

## Risk Priority Matrix

|  | Low Likelihood | Medium Likelihood | High Likelihood |
|--|---------------|-------------------|-----------------|
| **Critical Severity** | [Root Cause letter if applicable] | [Root Cause letter if applicable] | [Root Cause letter if applicable] |
| **High Severity** | [Root Cause letter if applicable] | [Root Cause letter if applicable] | [Root Cause letter if applicable] |
| **Medium Severity** | [Root Cause letter if applicable] | [Root Cause letter if applicable] | [Root Cause letter if applicable] |

---

## Recommended Concept Updates

| # | Section | Current State | Recommended Change | Type | Rationale |
|---|---------|---------------|--------------------|------|-----------|
| 1 | [product concept section] | [what the concept currently says or assumes] | [specific change recommended] | [Add/Modify/Remove] | [which root cause this addresses -- reference Root Cause letter and mitigation strategy number] |
| 2 | ... | ... | ... | ... | ... |

---

## Unresolved Questions

| # | Section | Question | Options | Assessment |
|---|---------|----------|---------|------------|
| 1 | [product concept section] | [question that the pre-mortem raised but could not answer] | [possible approaches to answering this] | [preliminary assessment based on investigation findings] |
| 2 | ... | ... | ... | ... |
```

---

## Section Guidance

| Section | Source | Depth |
|---------|--------|-------|
| Executive Summary | Synthesized by skill from forensic investigator output | 3-5 sentences, overall risk posture |
| Failure Premise | Set by skill based on product concept | 2-3 sentences establishing temporal frame |
| Root Cause A/B/C | Forensic investigator output, one per failure dimension | Each root cause: narrative (3-5 sentences), causal chain (4 links), early warning signals (3), mitigation strategies (3), likelihood and severity with justification |
| Risk Priority Matrix | Derived from root cause likelihood/severity assessments | 3x3 matrix with root cause letters placed in cells |
| Recommended Concept Updates | Derived from root causes in "Address immediately" or "Mitigate" cells | One row per recommendation, Type must be Add/Modify/Remove, rationale must reference specific root cause and mitigation strategy |
| Unresolved Questions | Identified during investigation as questions requiring real data | One row per question, must specify which product concept section is affected |
