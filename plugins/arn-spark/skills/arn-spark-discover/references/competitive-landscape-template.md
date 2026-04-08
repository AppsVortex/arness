# Competitive Landscape Template

This template defines the tiered competitive landscape format for the Competitive Landscape section of `product-concept.md`. The landscape captures identification-level data -- who exists in this space and what they do -- not a deep competitive analysis.

The structure preserves the full research output in tiers so the user can focus on the most relevant alternatives while future skills (e.g., Gap Analysis) can draw from any tier for deeper investigation. The `arn-spark-market-researcher` agent can be re-invoked in **deep analysis mode** by future skills for full feature comparison, strengths/weaknesses analysis, and positioning strategy.

## Instructions for arn-spark-discover

When populating this template:

- Populate from the `arn-spark-market-researcher` agent's Phase 3 consolidation output. The agent produces a ranked, tiered list with rationale for each top-5 selection.
- The user curates the top 5 during the AI Assist Checkpoint. They may swap entries between tiers, exclude irrelevant entries, or add competitors they know about that the research missed. Honor all user curation decisions.
- **Commercial products:** Use "Competitors" framing throughout. The top 5 are direct and indirect competitors to track and compare against.
- **Internal tools / enterprise projects:** Use "Existing Tools / Inspiration" framing instead of "Competitors." The top 5 are existing tools, internal systems, or external products that serve as reference points or alternatives the organization already uses. Adapt language accordingly (e.g., "Why focus" instead of "Why primary", "reference tools" instead of "competitors").
- Source URLs are required for all entries that were identified through market research. User-provided entries without URLs should be marked accordingly.
- Tag confidence for each entry: **Verified** (product page confirmed, description matches), **Inferred** (found in reviews or mentions but not directly verified), **Unverified** (user-provided or single-source claim).
- If the user declines competitive research entirely, write: `Not explored during discovery.`
- If the product is in a genuinely novel space with no known alternatives (rare -- the "do nothing" baseline almost always applies), write: `Not applicable -- [reason].`
- Always include the "do nothing" / manual process baseline in Indirect Alternatives, even when other alternatives are scarce.

---

## Template

```markdown
## Competitive Landscape

[Identified alternatives in this problem space, curated by the user. This is a landscape map -- who exists and what they do -- not a deep analysis. Detailed feature comparison and gap analysis can be performed separately via dedicated skills. The full research is preserved in tiers so future skills can draw from any level.]

### Primary Competitors (Focus)
[The user-validated top 5 -- these are the most relevant alternatives to track and compare against]

1. **[Name]** ([URL]) -- [one-line description of approach and target user]
   **Why primary:** [1 sentence rationale -- relevance to problem space, user overlap, market presence]
   **Confidence:** [Verified / Inferred / Unverified]

2. **[Name]** ([URL]) -- [one-line description]
   **Why primary:** [rationale]
   **Confidence:** [tag]

3. **[Name]** ([URL]) -- [one-line description]
   **Why primary:** [rationale]
   **Confidence:** [tag]

4. **[Name]** ([URL]) -- [one-line description]
   **Why primary:** [rationale]
   **Confidence:** [tag]

5. **[Name]** ([URL]) -- [one-line description]
   **Why primary:** [rationale]
   **Confidence:** [tag]

### Extended Landscape
[Additional validated alternatives kept for reference -- may become relevant as the product evolves]

- **[Name]** ([URL]) -- [one-line description] [Confidence: tag]
- **[Name]** ([URL]) -- [one-line description] [Confidence: tag]
[... up to ~10]

### Indirect Alternatives
- **Manual / "Do Nothing"** -- [How people cope without a dedicated tool]
- **[Generic tool, e.g., spreadsheets, email, Slack]** -- [How people repurpose general tools for this]
[... additional indirect alternatives as applicable]

**Initial positioning:** [1-2 sentences -- where the proposed product sits relative to these alternatives and what gap it fills]

### Research Metadata
- **Research date:** [ISO 8601 date]
- **Search coverage:** [N] queries across [M] search angles
- **Raw candidates found:** [X]
- **Validated alternatives:** [Y]
- **Research mode:** Identification (landscape mapping only -- deep analysis available via dedicated skills)
```

---

## Section Guidance

| Section | Source | Depth |
|---------|--------|-------|
| Primary Competitors (Focus) | market-researcher Phase 3 consolidation output, user-curated during AI Assist Checkpoint | Top 5 entries. Each with name, URL, one-line description, rationale for inclusion, and confidence tag. User has final say on which entries make the top 5. |
| Extended Landscape | market-researcher Phase 3 consolidation output (entries ranked 6+) | Up to ~10 additional entries. Same format as primary but without detailed rationale. These are validated alternatives that did not make the user's top 5 but remain available for future reference. |
| Indirect Alternatives | market-researcher output + conversation context | Always includes "do nothing" / manual process baseline. Add generic tool workarounds (spreadsheets, email, etc.) that people repurpose. These do not need URLs. |
| Initial Positioning | Synthesized from the landscape as a whole, user-validated | 1-2 sentences only. Describes the market gap the proposed product addresses. This is a starting hypothesis, not a strategy document. |
| Research Metadata | market-researcher Phase 3 output | Date of research, number of queries executed, search angles covered, raw vs. validated candidate counts. Enables future skills to assess research freshness and coverage. |
| Source URLs | market-researcher output (WebSearch + WebFetch) | Required for all researched entries. Must point to the actual product page, not a review or listing. User-provided entries without URLs are acceptable but should be noted. |
| Confidence Tags | market-researcher validation during Phase 3 | **Verified**: product page confirmed and description matches actual product. **Inferred**: found in reviews, comparisons, or community mentions but product page not directly verified. **Unverified**: user-provided, single-source, or could not be independently confirmed. |
