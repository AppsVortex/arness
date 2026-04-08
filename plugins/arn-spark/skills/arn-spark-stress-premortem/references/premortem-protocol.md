# Pre-Mortem Protocol

Adapted from Gary Klein's pre-mortem methodology for product concept stress testing. This document is consumed by the `arn-spark-stress-premortem` skill to frame the forensic investigator's investigation.

## Overview

The pre-mortem technique inverts the typical risk assessment. Instead of asking "what could go wrong?" (which invites optimism bias and superficial answers), the pre-mortem declares that the product has already failed and asks "why did it fail?" This psychological reframing unlocks deeper, more specific failure analysis because it removes the social pressure to be optimistic and replaces it with the intellectual challenge of explaining a known outcome.

**The premise:** It is 12 months after launch. The product was shut down today. You are not predicting failure -- you are investigating a failure that has already happened.

---

## Methodology

### Step 1: Establish the Failure Premise

Set the temporal frame:
- The product launched 12 months ago with the features and scope described in the product concept
- Initial reception was [variable -- the investigator determines this based on the concept's strengths and weaknesses]
- Despite the team's best efforts, the product was shut down today
- Your job is to explain why

The failure premise must be stated explicitly at the beginning of the investigation. This is not a hypothetical -- it is a forensic reconstruction.

### Step 2: Work Backward from Failure

The investigator works backward from the shutdown to identify root causes. Each root cause follows a causal chain:

```
Shutdown decision
  <- Trigger event (the specific metric or incident that forced the decision)
    <- Compounding effect (what made recovery impossible)
      <- Execution failure (how the design decision played out in practice)
        <- Design assumption (the original decision or assumption in the product concept)
```

### Step 3: Identify Root Causes Across Failure Dimensions

The standard investigation produces 3 root causes, each targeting a distinct failure dimension:

#### Dimension A: User Adoption Failure / Core Experience Flaw
The product's central interaction model had a fundamental flaw. Users tried it and left. This is not about missing features -- it is about the core experience itself being wrong, insufficient, or misaligned with actual user needs.

Investigation angles:
- Gap between promised experience and actual experience
- Onboarding friction that prevented users from reaching the value
- Core interaction that was interesting in demos but tedious in daily use
- Product pillars that conflicted with each other in practice

#### Dimension B: Trust / Security / Compliance Failure
The product had a trust assumption that proved catastrophically wrong. A data breach, a privacy scandal, a compliance failure, or a trust violation that destroyed user confidence overnight.

Investigation angles:
- Data handling assumptions that were tested by a real incident
- Security architecture decisions that seemed reasonable but failed under load or adversarial conditions
- Compliance requirements that emerged post-launch and could not be met
- Trust signals that were sufficient for early adopters but not for mainstream users

#### Dimension C: Market / Audience Misread
The product was built for the wrong people, or the right people in the wrong context. The personas were plausible but did not match reality. The market existed but the product's entry point was misaligned.

Investigation angles:
- Which persona assumption was most wrong, and how the actual early adopters differed
- Market timing: too early, too late, or right time but wrong entry point
- Competitive response that the product concept underestimated
- Adjacent market or use case that users actually wanted but the product did not pivot toward

### Step 4: Evaluate Each Root Cause

For each root cause, assess:

**Likelihood:** How probable is this failure chain given the product concept's current design?
- **High:** The product concept contains specific elements that directly increase this risk
- **Medium:** The product concept does not directly address this risk but is not uniquely vulnerable
- **Low:** The product concept has elements that mitigate this risk, but it cannot be eliminated

**Severity:** If this failure chain occurs, how bad is the outcome?
- **Critical:** Product shutdown -- unrecoverable
- **High:** Significant user loss or trust damage -- recoverable but costly
- **Medium:** Growth stalled or market position weakened -- manageable with pivots

### Step 5: Construct Risk Priority Matrix

Map root causes on a 3x3 matrix:

|  | Low Likelihood | Medium Likelihood | High Likelihood |
|--|---------------|-------------------|-----------------|
| **Critical Severity** | Monitor | Mitigate | Address immediately |
| **High Severity** | Monitor | Mitigate | Address immediately |
| **Medium Severity** | Accept | Monitor | Mitigate |

Root causes in "Address immediately" cells must appear in the Recommended Concept Updates table.

---

## Psychological Framing Instructions for the Forensic Investigator

These instructions are passed to the `arn-spark-forensic-investigator` agent to establish the correct mindset:

1. **You are not defending this product.** You are not an advocate, a coach, or a well-wisher. You are a forensic investigator called in after the shutdown, piecing together what went wrong and why nobody saw it coming.

2. **The failure has already happened.** Do not hedge with "might" or "could." The product failed. Your job is to explain why, not to predict whether it will.

3. **Be specific, not generic.** "Users did not find it useful" is not a root cause. "Users expected [specific claim from concept] but experienced [specific reality], leading to [specific metric decline] by month [N]" is a root cause.

4. **Use the product concept against itself.** Quote specific claims, features, and design decisions. A pre-mortem that could apply to any product is a failed pre-mortem.

5. **Product pillars are forensic evidence.** Pillars often become failure vectors. A "zero-configuration" pillar might mean the product could not accommodate enterprise deployment requirements. A "privacy-first" pillar might mean the product could not implement the analytics needed to detect churn early enough.

6. **Early warning signals must be observable.** Not "user satisfaction declining" but "NPS scores for the [specific feature] flow dropping below 30 within 60 days" or "support ticket volume for [specific issue] exceeding [threshold] by month 2."

7. **Mitigation strategies must change the product concept.** Not "improve onboarding" but "add a guided first-run experience that demonstrates [specific value] within 90 seconds by [specific mechanism]."
