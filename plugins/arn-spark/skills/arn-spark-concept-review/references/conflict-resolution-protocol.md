# Conflict Resolution Protocol

This protocol defines how the `arn-spark-concept-review` skill and the `arn-spark-product-strategist` agent consolidate, de-duplicate, and resolve conflicting recommendations from multiple stress test reports into a single proposed changeset for the product concept.

## Overview

Stress test reports each produce a **Recommended Concept Updates** table and an **Unresolved Questions** section. When multiple reports exist, their recommendations may overlap, reinforce, or contradict each other. This protocol ensures that every recommendation is accounted for, conflicts are surfaced transparently, and the user makes the final decision on every change.

---

## Process

### Step 1: Extract Recommendations from All Reports

For each stress test report found in `<reports-dir>/stress-tests/`:

1. Locate the **Recommended Concept Updates** table (standardized schema: `| # | Section | Current State | Recommended Change | Type | Rationale |`)
2. Parse every row, preserving the source report name (e.g., "Interview Report", "Competitive Report", "Pre-Mortem Report", "PR/FAQ Report")
3. Locate the **Unresolved Questions** section (standardized schema: `| # | Section | Question | Options | Assessment |`)
4. Parse every row, preserving the source report name

If a report exists but does not contain one or both tables (e.g., malformed output), note the gap and proceed with what is available.

### Step 2: De-duplicate Recommendations

Merge recommendations that target the **same product concept section** with **semantically equivalent changes**:

- **Same section + same Type + same intent:** Merge into a single recommendation. Cite all source reports in the rationale. Preserve the most specific wording.
- **Same section + same Type + different specificity:** Keep the more specific recommendation. Note the less specific one as supporting evidence in the rationale.
- **Different sections or different Types:** Keep as separate recommendations -- these are distinct changes.

De-duplication is a consolidation step, not a filtering step. No recommendations are discarded. Merged recommendations list all contributing source reports.

### Step 3: Detect Conflicts

Two recommendations **conflict** when they:

- Target the **same product concept section** AND
- Propose **contradictory changes** (e.g., one says "Add X" while another says "Remove X", or one says "Modify to emphasize A" while another says "Modify to emphasize B where B contradicts A")

Indicators of conflict:
- Opposing Type values for the same section (Add vs. Remove)
- Modify recommendations with incompatible directions (e.g., "simplify the trust model" vs. "add more trust verification layers")
- Recommendations whose rationales cite mutually exclusive user needs or market positions

Indicators that are NOT conflicts:
- Two "Add" recommendations for the same section that address different aspects (these are complementary, not conflicting)
- A "Modify" and an "Add" for the same section that are compatible (the modification and the addition can coexist)
- Recommendations from different reports that reinforce the same direction (these are corroborating, not conflicting)

### Step 4: Resolve Conflicts Using Product Pillars

For each detected conflict, the product strategist assesses which recommendation better serves the product's **Product Pillars** (the non-negotiable qualities defined in the product concept).

The strategist produces a **conflict resolution assessment** for each conflict:

1. **State both sides:** Quote each conflicting recommendation with its source report and rationale
2. **Pillar alignment analysis:** For each recommendation, assess alignment with each product pillar:
   - Which pillars does Recommendation A serve?
   - Which pillars does Recommendation B serve?
   - Does either recommendation conflict with any pillar?
3. **Strategist's assessment:** Based on pillar alignment, the strategist recommends one side and explains why. If both serve different pillars equally well, the strategist notes the tension and defers to the user with a clear framing of the trade-off
4. **Trade-off statement:** A plain-language summary of what is gained and what is lost with each option

**Critical rule:** The strategist's assessment is a recommendation, not a decision. ALL conflicts are surfaced to the user with both sides and the strategist's analysis. The user always makes the final call.

### Step 5: Surface Everything to the User

The complete changeset presented to the user includes:

**For each non-conflicting recommendation (grouped by product concept section):**
- Source report(s)
- Type (Add / Modify / Remove)
- Current state of the section
- Proposed change
- Rationale (with source report attribution)

**For each conflict (grouped by product concept section):**
- Recommendation A: source report, type, proposed change, rationale
- Recommendation B: source report, type, proposed change, rationale
- Strategist's conflict resolution assessment (pillar analysis, recommendation, trade-off statement)
- Clear indication that the user must choose

**Aggregated Unresolved Questions (grouped by product concept section):**
- All questions from all reports, de-duplicated
- Source report attribution for each question
- Options and preliminary assessments preserved

---

## Changeset Presentation Format

The changeset is organized by product concept section for readability. Within each section:

```
### [Product Concept Section Name]

**Change 1** (from [Source Report(s)])
- Type: [Add/Modify/Remove]
- Current state: [what the concept currently says]
- Proposed change: [specific recommended change]
- Rationale: [why, with source attribution]

**Change 2** (from [Source Report(s)])
- Type: [Add/Modify/Remove]
- Current state: [what the concept currently says]
- Proposed change: [specific recommended change]
- Rationale: [why, with source attribution]

**CONFLICT** -- [Source Report A] vs. [Source Report B]
- Recommendation A: [proposed change] (Type: [type]) -- [rationale]
- Recommendation B: [proposed change] (Type: [type]) -- [rationale]
- Strategist's assessment: [pillar analysis and recommendation]
- Trade-off: [what is gained/lost with each option]
```

---

## UX Specialist Conditional Involvement

Before presenting the changeset to the user, check whether UX specialist review is warranted:

**Detection signals** -- scan the product concept for any of these indicators that the UX specialist contributed to the original concept:
- Mentions of "UX specialist", "arn-spark-ux-specialist", or "UX review"
- Presence of detailed visual direction (color palettes, typography specifications, component styles)
- References to style briefs, prototype reviews, or visual grounding assets
- Sections that describe interaction patterns, transitions, or animation behavior in design-specific detail

**If UX signals are detected:**
1. Identify which recommendations in the changeset affect UX-relevant sections (Core Experience, visual direction, interaction patterns, onboarding flows, accessibility)
2. Invoke `arn-spark-ux-specialist` with the UX-relevant recommendations and the current product concept
3. The UX specialist reviews the proposed changes and provides feedback: does the change align with the visual direction and interaction patterns? Are there UX implications the stress tests missed?
4. Incorporate the UX specialist's feedback into the changeset -- add it as a supplementary note alongside each relevant recommendation

**If no UX signals are detected:** Skip UX specialist involvement entirely. Do not invoke the agent.

---

## Edge Cases

- **Single report:** No de-duplication or conflict detection needed. Present recommendations directly from the one report.
- **All reports agree:** No conflicts. Present the unified changeset with multi-source attribution.
- **Reports contradict on fundamental direction:** If recommendations collectively suggest the product concept needs fundamental rethinking (e.g., different target audience, different core experience), surface this as a meta-observation alongside the individual recommendations. The user may choose to re-run discover rather than patch the concept.
- **No recommendations in a report:** Some reports may have zero rows in the Recommended Concept Updates table (the stress test found no issues). This is valid -- note it in the review report as a positive signal.
- **User rejects all changes:** Write the review report documenting the full changeset and the user's rejection. Do NOT modify the product concept. The review report serves as a record that stress tests were run and findings were considered.
