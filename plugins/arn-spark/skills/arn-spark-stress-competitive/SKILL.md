---
name: arn-spark-stress-competitive
description: >-
  This skill should be used when the user says "competitive analysis",
  "gap analysis", "competitive gap", "stress competitive", "compare competitors",
  "feature comparison", "competitive stress test", "market comparison",
  "competitor analysis", or wants to stress-test a product concept by conducting
  deep competitive gap analysis with feature comparison, gap identification, and
  positioning assessment. Produces a competitive report with a feature matrix,
  per-competitor analysis, and recommended concept updates.
version: 1.0.0
---

# Arness Spark Stress Competitive

Stress-test a product concept through deep competitive gap analysis. This skill goes beyond surface-level feature comparison to identify where the product is uniquely strong, where competitors have real advantages, and where the market has gaps that no one is filling.

The process works in three stages:
1. **Deep research:** The market researcher agent conducts thorough competitive intelligence in deep-analysis mode, going beyond the competitors identified during discovery
2. **Gap analysis:** Features are categorized (core, differentiating, table-stakes), compared across competitors, and gaps are weighted against the product's own pillars
3. **Positioning assessment:** The product's market position is evaluated for defensibility, switching costs, and crowded vs. underserved areas

The product concept is read but never modified -- all recommendations are captured in the competitive report for later review.

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
| Competitive landscape | REQUIRED | Competitive Landscape section of product concept | Fallback cascade below |
| Product pillars | ENRICHES | Product Pillars section of product concept | Gap weighting is less targeted but analysis proceeds |
| Core experience | ENRICHES | Core Experience section of product concept | Feature identification is less complete |

**Competitive landscape fallback cascade:**

If the product concept exists but the Competitive Landscape section is missing, contains "Not explored" sentinel, or lists zero competitors:

Ask (using `AskUserQuestion`): **"The product concept does not include a competitive landscape, which is needed to identify competitors for analysis. How would you like to proceed?"**
1. Run `/arn-spark-discover` to conduct competitive research through product discovery
2. Name 3-5 competitors now (I will research them in depth)
3. Skip the competitive stress test

If the user chooses option 2, collect competitor names and proceed to the workflow using those as the initial competitor list.

## Workflow

### Step 1: Load References

Load the gap analysis framework and report template:
> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-stress-competitive/references/gap-analysis-framework.md`
> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-stress-competitive/references/competitive-report-template.md`

### Step 2: Read Product Concept and Extract Competitor List

Read the product concept from `<vision-dir>/product-concept.md`. Extract:
- Product vision and core experience (for feature identification)
- Product pillars (for gap weighting)
- Competitive landscape section (primary competitors + extended landscape)
- Scope boundaries (to identify planned vs. unplanned features)

Build the initial competitor list from the competitive landscape section of the product concept (look for the primary/focus competitors subsection). Include extended landscape candidates if the primary list has fewer than 3 entries.

### Step 3: Deep Competitive Research

Invoke `arn-spark-market-researcher` in **deep-analysis mode** with:

--- PRODUCT CONCEPT (relevant sections) ---
[Extract and pass: Vision, Core Experience, Product Pillars, Competitive Landscape, Scope Boundaries, Target Platforms. Do not pass the full document — focus on sections relevant to competitive analysis.]
--- END PRODUCT CONCEPT ---

--- COMPETITOR LIST ---
[extracted competitor names and descriptions from product concept]
--- END COMPETITOR LIST ---

--- RESEARCH TASK ---
Deep-analysis mode: For each competitor, research:
1. Full feature inventory (from documentation, feature pages, changelogs, user reviews)
2. Pricing model and tiers
3. Target audience and market positioning
4. Known strengths and weaknesses (from user reviews, comparison articles, community feedback)
5. Recent developments (launches, pivots, acquisitions in the last 12 months)

Also identify any competitors NOT in the provided list that should be analyzed -- look for new entrants, adjacent products expanding into this space, and open-source alternatives.
--- END RESEARCH TASK ---

### Step 4: Build Feature Comparison Matrix

Using the gap analysis framework:

1. **Identify features:** Extract all features from the product concept's Core Experience. Research competitor features. Create a unified feature list by combining both sources and deduplicating any feature present across multiple products. Categorize each unique feature as Core, Differentiating, or Table-Stakes.
2. **Build the matrix:** For each feature, assess availability across the product and all competitors using Yes/No/Partial/Planned/Unknown indicators.
3. **Fill gaps:** Where competitor data is incomplete, note "Unknown" and add to Unresolved Questions.

### Step 5: Classify and Weight Gaps

Using the gap analysis framework:

1. **Classify gaps** into: Our Unique Strengths, Competitor Advantages, Uncovered Market Gaps, Parity Features
2. **Weight gaps** by product pillar alignment: Critical, High, Medium, Low
3. **Assess positioning:** Identify crowded vs. underserved areas, evaluate defensibility, assess switching costs

### Step 6: Draft Recommended Concept Updates

From Critical and High-weight gaps, draft the Recommended Concept Updates table. Each recommendation must:
- Reference a specific product concept section
- Describe the current state and proposed change
- Use the Type column (Add/Modify/Remove)
- Provide rationale linking to specific competitive findings

### Step 7: Assemble and Write Report

Using the competitive report template:
1. Populate all sections with research data, gap analysis, and positioning assessment
2. Write the report to `<reports-dir>/stress-tests/competitive-report.md`

Present a summary to the user:

"Competitive gap analysis complete. Report saved to `[path]`.

**Key findings:**
- **Unique strengths:** [N] features where we lead
- **Competitor advantages:** [N] features where competitors lead
- **Market gaps:** [N] opportunities no one is addressing
- **Critical gaps:** [N] gaps that threaten product pillars

**Recommended concept updates:** [N] recommendations ([X] Add, [Y] Modify, [Z] Remove)
**Unresolved questions:** [N]

This report will be used by `/arn-spark-concept-review` to propose changes to the product concept."

## Agent Invocation Guide

| Situation | Agent | Mode/Context |
|-----------|-------|--------------|
| Deep competitive research | `arn-spark-market-researcher` | Deep-analysis mode with competitor list and product concept |

## Error Handling

- **Market researcher returns sparse data:** Retry with broader search terms, alternative competitor names, and different search angles. If retry still returns insufficient data:
  Ask (using `AskUserQuestion`): **"Competitive research returned limited data for some competitors. How would you like to proceed?"**
  1. Retry with different search terms
  2. Proceed with available data (gaps will be marked as Unknown)
  3. Abort the competitive stress test

- **No competitors found (even with user-provided names):** Record "No competitive data available" and focus the report on feature categorization and market gap identification from the product concept alone. Note the limitation prominently in the report.

- **Market researcher agent fails entirely:** Retry once with a simplified prompt containing only the product description and competitor names. If retry fails:
  Ask (using `AskUserQuestion`): **"Agent invocation failed. How would you like to proceed?"**
  1. Retry
  2. Skip this step
  3. Abort

## Constraints

- **Read-only with respect to product-concept.md.** The competitive skill reads the product concept but NEVER modifies it. All recommendations are captured in the competitive report.
- **Market researcher in deep-analysis mode only.** Do not use identification mode (that is for discovery-time landscape mapping). Deep-analysis mode produces the feature-level detail needed for gap analysis.
- **Report overwrites on re-run.** If `competitive-report.md` already exists, it is overwritten. Git provides history.
