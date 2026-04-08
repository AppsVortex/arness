---
name: arn-spark-discover
description: >-
  This skill should be used when the user says "discover", "product discovery",
  "arn discover", "help me define this product", "what should I build",
  "product concept", "define the product", "let's figure out what to build",
  "vision for this project", "shape this idea", "new project idea",
  "brainstorm this product", "starting from scratch", or wants to explore
  and structure a greenfield product idea through guided conversation. Produces a
  product-concept.md document capturing the product vision, core experience,
  target users, trust model, platforms, and scope boundaries.
version: 1.1.0
---

# Arness Discover

Guide a greenfield product idea from raw concept to structured product vision through iterative conversation, aided by product thinking from the `arn-spark-product-strategist` agent, competitive landscape research from `arn-spark-market-researcher`, and persona generation from `arn-spark-persona-architect` (greenfield agents in this plugin). This is a conversational skill that runs in normal conversation (NOT plan mode). The primary artifact is a **product concept document** written to the project's vision directory.

This skill covers the WHAT and WHY of the product, including the **product pillars** -- non-negotiable qualities that define the product's soul and guide all downstream decisions. Technology choices and system design are handled separately by `/arn-spark-arch-vision`.

## Step 0: Ensure Configuration (Non-Blocking)

Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-ensure-config/references/ensure-config.md` and follow its instructions. This captures the user profile and configures `## Arness` with Arness Spark fields.

**Important:** This skill is designed for exploratory use before a project may fully exist. If ensure-config encounters errors (e.g., no git repository, CLAUDE.md cannot be created), proceed anyway using fallback defaults: Vision directory = `.arness/vision`, Reports directory = `.arness/reports`. Do not hard-block.

After Step 0 completes (or falls back), determine the output directory:
1. Read the project's `CLAUDE.md` and check for a `## Arness` section
2. If found, extract the configured Vision directory path — this is the source of truth
3. If NOT found (ensure-config fell back), use `.arness/vision` at the project root.
4. If the output directory does not exist, create it

## Workflow

### Step 1: Capture the Raw Idea

Accept the user's product idea in any form -- a single sentence, a paragraph, or a detailed description. If the idea was included in the trigger message, use it directly. If not, ask:

"What product or tool do you want to build? Describe it in whatever detail you have -- even a rough idea is a good starting point."

After receiving the idea, acknowledge with a brief restatement (2-3 sentences) to confirm understanding. Do not add interpretation or assumptions beyond what the user stated.

### Step 2: Initial Analysis with Product Strategist

Invoke the `arn-spark-product-strategist` agent with:
- The user's raw idea description
- Any context from the conversation so far

The agent returns:
- A vision sketch (initial attempt at a vision statement)
- An assessment of what is clear and what is missing
- 3-5 probing questions organized by priority category
- Scope observations (what looks essential, what could be deferred)

Present the agent's findings to the user as a conversation starter. Frame it as: "Here is my initial read on your idea, with some questions to explore." Do NOT present it as a finished analysis.

### Step 3: Guided Discovery Conversation (Iterative)

Enter a conversation loop. The goal is to cover eleven discovery categories, but do so through natural conversation -- not as a sequential questionnaire.

Load the discovery question bank for reference:
> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-discover/references/discovery-questions.md`

Use the product strategist's output from Step 2 to drive the conversation. Start with the categories the agent flagged as weakest. Cover these categories through the conversation (not necessarily in order — the numbering and ordering here differs intentionally from the question bank and template, which are optimized for different purposes):

1. **Vision & Problem** -- what and why
2. **Target Users & Personas** -- who and when (AI-generated personas for validation)
3. **Core Experience** -- the primary interaction
4. **Product Pillars** -- the non-negotiable qualities that define the product's soul
5. **Trust & Security Model** -- how users establish trust
6. **Platform & Constraints** -- where and what limits
7. **Participants & Scale** -- how many, what topology
8. **Scope Boundaries** -- what is NOT v1
9. **Business Model & Constraints** -- revenue model, tenancy, compliance, cost limits
10. **Competitive Landscape** -- alternatives, market positioning (AI-researched)
11. **Assumptions & Success Criteria** -- validated hypotheses, measurable outcomes (AI-derived)

**Product Pillars** deserve special attention. Unlike the other categories which capture facts and decisions, pillars capture convictions. Listen for strong language throughout the conversation -- phrases like "it HAS to feel...", "the whole point is...", "I refuse to compromise on..." are pillar signals. When you hear them, name the pillar back to the user: "It sounds like [quality] is non-negotiable for you -- would you call that a core pillar of this product?" Collect pillars as they emerge naturally rather than asking for them all at once.

#### AI Assist Checkpoints

**Product type signal:** Early in the conversation (during Step 2 initial analysis or first rounds of Step 3), establish whether this is a **commercial product** (targeting a market/customers) or an **internal tool / personal utility** (for a team, personal use, or internal workflow). If ambiguous from the description, ask naturally: "Is this something you're building for customers, or more of an internal tool / personal utility?" Record the answer -- it affects framing of Checkpoints C and D, but NOT the depth of persona work (Checkpoint B is always full depth because personas feed downstream simulation skills regardless of product type).

**Checkpoint A -- Problem Statement Draft** (after vision is clear, rounds 1-3):
- Synthesize a crisp problem statement from the conversation (who/what/why/workarounds/severity)
- Present to user: "Based on what you've described, here's a draft problem statement. Does this capture it?"
- User validates/refines. No extra agent needed -- the skill does this directly from conversation context.

**Checkpoint B -- Persona Generation** (when target users discussed, rounds 2-4):

This is a two-phase process: **concrete examples first** (for user interaction), then **abstracted moulds** (for reuse).

1. Ask user to describe target users in their own words
2. Assess what the user provides:
   - **Vague description** (e.g., "developers who want to ship faster"):

     Ask (using `AskUserQuestion`):

     > **I can generate concrete persona examples based on what you've described -- specific people you can picture and critique. Would you like me to draft those?**
     > 1. **Yes** — Generate persona examples for review
     > 2. **No** — Skip persona generation, continue with what we have

   - **Concrete names/roles** (e.g., "Bob is a PM who cares about velocity, Julie is a dev who hates context switching"):

     Ask (using `AskUserQuestion`):

     > **I can expand those into full profiles with personality traits, pain points, and day-in-the-life scenarios. Want me to research and draft those?**
     > 1. **Yes** — Expand into full persona profiles
     > 2. **No** — Keep as-is and continue
3. If agreed, invoke `arn-spark-persona-architect` in **discovery mode** with: product vision, problem statement, user description (vague or concrete seeds), product pillars so far. The agent handles both cases -- generating from scratch or expanding user-provided specifics.
4. **Phase 1 -- Concrete examples:** Present the generated/expanded concrete personas (including personality traits): "Here are some specific people who would use this product. Do these ring true? Any to add, remove, or change?" The user interacts with these -- critiquing, adjusting, approving. Iterate until the user is satisfied. These are vivid, specific characters with personality.
5. **Phase 2 -- Abstracted moulds:** Once concrete personas are approved, invoke the persona-architect again (or in the same pass) to derive the abstracted profiles (moulds) from the approved examples. Present: "Here are the generalized persona archetypes I've extracted from the examples. These moulds can be used later to generate more personas for testing. Do they capture the pattern?" The moulds define ranges, patterns, personality spectrums, and variation axes rather than single points.
6. Record both: the approved concrete examples AND the abstracted moulds.
7. If declined, record whatever target user info was gathered conversationally and move on.

**Why both layers?** Concrete personas make the conversation tangible -- the user can say "no, that person wouldn't care about X." Abstracted moulds make the output reusable -- future skills (Synthetic User Panel, etc.) can generate fresh concrete instances from the moulds without repeating the discovery conversation.

**Checkpoint C -- Competitive Landscape / Existing Alternatives** (when competitors come up, rounds 3-6):

Framing adapts based on product type:

**Commercial product framing:**
1. Ask what competitors or alternatives the user is aware of
2. Based on response:
   Ask (using `AskUserQuestion`):

   > **Would you like me to research the competitive landscape?**
   [Adapt the question text based on how many competitors the user named:
   - 0 named: "Would you like me to research what else is out there in this space?"
   - 1-2 named: "Want me to research whether there are others and build a fuller picture?"
   - 3+ named: "Good awareness. Want me to verify these and check for anything you might have missed?"]
   > 1. **Yes** — Research alternatives and build a landscape
   > 2. **No** — Skip competitive research

**Internal tool / utility framing:**
1. Ask: "Have you looked for existing tools that already do something like this? Sometimes there's something out there you could use directly or draw inspiration from."
2. Based on response:
   Ask (using `AskUserQuestion`):

   > [Adapt the question text based on the user's response:
   > - User knows of some: "Want me to search for any others that might save you time or give you ideas?"
   > - User hasn't looked: "Want me to do a quick search for similar tools? Could save you building from scratch, or at least give you inspiration for the approach."]
   > 1. **Yes** — Search for existing tools
   > 2. **No** — Skip and build from scratch

   - If **No** or the user says not needed: Record "Not explored -- user prefers to build from scratch" and move on.

**If user agrees to research (either framing) -- Three-phase fan-out/fan-in orchestration:**

This process ensures thorough, validated results rather than a shallow 3-query search:

1. **Phase 1 -- Query Planning:** Invoke `arn-spark-market-researcher` (identification/plan) with: product description, problem space, known competitors. The agent generates 10-15 search queries across diverse angles (problem-focused, solution-focused, comparison, review, community, domain). Present the query plan briefly: "I've identified [N] search angles to explore. Searching now..."

2. **Phase 2 -- Parallel Search:** Split the queries into 2-3 batches. Invoke `arn-spark-market-researcher` (identification/search) **2-3 times in parallel**, each with a batch of 4-6 queries. Each agent searches independently and returns raw findings.

3. **Phase 3 -- Consolidation:** Invoke `arn-spark-market-researcher` (identification/consolidate) with all raw findings from Phase 2. The agent de-duplicates (products found by multiple queries signal higher relevance), validates (confirms URLs and descriptions are accurate), and ranks by relevance.

4. **Present results for user curation:** Present the full tiered list (top 5 + extended landscape). Frame it for review:
   - "I searched across [N] angles and found [Y] validated alternatives. Here are my top 5 with rationale, plus the extended list. Take a look:"
   - Present the top 5 with rationale for each
   - Present the extended landscape (numbered 6+) so the user can see what else was found
   - Ask: "Does this top 5 look right? You can swap any of them with candidates from the extended list, add ones I missed, or exclude any that aren't relevant."

5. **User curates:** The user may:
   - Approve the top 5 as-is
   - Swap candidates (e.g., "move #8 into the top 5, drop #3")
   - Exclude false positives (e.g., "#4 isn't actually a competitor")
   - Add competitors the research missed
   - Adjust rationale or categorization
   Iterate until the user is satisfied with the focused set.

6. **Record the final curated landscape:** Save the full tiered list to the product concept:
   - **Primary competitors (top 5):** The user-validated focused set -- these are the ones to track and compare against
   - **Extended landscape:** Remaining validated candidates, trimmed to ~10 max -- kept for reference because the vision may shift and make them more relevant later
   - **Indirect alternatives:** The "do nothing" baseline and generic tool workarounds
   The full list is preserved as research -- future skills (Gap Analysis) can draw from any tier.

7. If research was declined, record appropriately and move on. Do NOT force research.

**Checkpoint D -- Assumptions & Success Criteria** (before readiness check, rounds 6-8):
1. Derive 5-8 key assumptions from the entire conversation -- things stated/implied as true but unverified. Present: "Based on our conversation, here are the key assumptions underlying this product. Which feel solid and which feel like risks?"
2. Suggest 3-5 success criteria based on product type + business model:
   - **Commercial product:** Market-oriented metrics -- adoption targets, engagement ratios, revenue milestones, NPS (e.g., "1000 MAU within 6 months", "DAU/MAU > 30%", "$5K MRR by month 12")
   - **Internal tool / utility:** Usage and impact metrics -- team adoption, time saved, process replaced, reliability (e.g., "team uses it daily within 2 weeks", "reduces manual process from 2 hours to 10 minutes", "replaces spreadsheet workflow entirely")
   Present: "Here are some success metrics I'd suggest for this type of product. Do these make sense?"
3. User validates/refines both. Record approved versions.

**Within each round of conversation, decide how to respond:**

| Situation | Action |
|-----------|--------|
| User gives a vague or broad answer | Invoke `arn-spark-product-strategist` for follow-up probing |
| User proposes a feature that might be scope creep | Invoke `arn-spark-product-strategist` for scope assessment |
| User asks "is this too much?" or "should I include X?" | Invoke `arn-spark-product-strategist` for evaluation |
| User gives a clear, concrete answer | Acknowledge and record directly, no agent needed |
| User makes a definitive scope decision | Record directly, confirm |
| User asks about technology choices | Defer to `/arn-spark-arch-vision` |
| User seems done or conversation is circling | Proceed to readiness check |
| Vision & problem are clear enough to draft | **Trigger Checkpoint A** -- draft problem statement for validation |
| User describes target users vaguely (no specific names or roles) | **Trigger Checkpoint B** -- offer persona generation |
| User provides concrete persona seeds (specific names, roles, or detailed descriptions) | **Trigger Checkpoint B** with details as persona seeds |
| Competitors/alternatives come up or mid-conversation lull | **Trigger Checkpoint C** -- ask about competitors (commercial) or existing tools (internal), offer research |
| User names < 3 alternatives (after initial competitor question) | **Trigger Checkpoint C** -- offer to fill gaps with research |
| User wants claims about alternatives validated | **Trigger Checkpoint C** with named alternatives for verification |
| User says research is "not needed" | Record appropriately and move on -- do NOT force research |
| Most categories covered, pre-readiness | **Trigger Checkpoint D** -- present derived assumptions + suggested success criteria |

**Tracking coverage:** Mentally track which categories have been sufficiently explored. A category is "covered" when the user has made concrete statements or decisions about it. Brief answers are acceptable if the topic is genuinely simple for this product.

**Readiness check:** After covering the major categories (typically 3-8 rounds of conversation), check:

"I think we have a solid picture of the product. Here is a quick summary of what we have covered: [brief list of key decisions].

**Product Pillars identified so far:** [list the pillars that emerged, e.g., 'Design fidelity', 'Privacy-first', 'Zero-configuration simplicity']. [If fewer than 3:] Are there other non-negotiable qualities I should capture? [If 3-5:] Do these capture the soul of the product?

**AI-assisted sections status:**
- Problem Statement: [drafted and approved / needs drafting]
- Target Personas: [approved / generated but not reviewed / user declined / not enough context yet]
- Competitive Landscape: [approved / researched but not reviewed / user declined / not applicable]
- Key Assumptions: [validated / not yet surfaced]
- Success Criteria: [approved / not yet suggested]

If any AI-assisted sections have not been offered yet and there is enough context, offer them now before writing.

Ready for me to write the product concept document, or is there anything else to explore?"

If the user wants to explore more, continue the conversation. If ready, proceed to Step 4.

### Step 4: Write the Product Concept Document

When the user is ready:

1. Read the templates:
   > Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-discover/references/product-concept-template.md`
   > Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-discover/references/persona-profile-template.md`
   > Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-discover/references/competitive-landscape-template.md`

2. Populate the template with all decisions and insights from the conversation:
   - Replace all bracketed placeholders with concrete content
   - Adapt subsection names to match the product (e.g., "The Knock" for a walkie-talkie app)
   - If any section has insufficient information, write what is known and note the gap
   - For AI-assisted sections (Problem Statement, Target Personas, Competitive Landscape, Key Assumptions, Success Criteria): use the user-approved content. If declined, write "Not explored during discovery." If not applicable, write "Not applicable -- [reason]."
   - For Target Personas: follow the structure in persona-profile-template.md -- each archetype needs both the abstracted mould and the concrete example.
   - For Competitive Landscape: follow the structure in competitive-landscape-template.md -- use the tiered format (primary, extended, indirect).
   - Write in present tense, as if the product exists

3. Write the document to the output directory as `product-concept.md`

4. Present a summary to the user:
   - List the document path
   - Highlight 3-5 key decisions captured
   - Note any gaps or areas that could use further exploration

### Step 5: Recommend Next Steps

After writing the document, inform the user:

"Product concept saved to `[path]/product-concept.md`.

Next step: Run `/arn-spark-arch-vision` to explore technology options and define the architecture for this product. That skill will load this product concept as input."

If the project does not yet have Arness initialized, also mention:
"If you have the Arness Code plugin installed, run `/arn-planning` to start the development pipeline. Arness auto-configures code patterns on first use."

## Agent Invocation Guide

| Situation | Action |
|-----------|--------|
| Initial idea analysis (Step 2) | Invoke `arn-spark-product-strategist` with raw idea |
| User gives vague/broad answer | Invoke `arn-spark-product-strategist` with answer + context |
| Feature might be scope creep | Invoke `arn-spark-product-strategist` for assessment |
| User asks scope/priority question | Invoke `arn-spark-product-strategist` with question |
| Target user discussion, description is vague | Invoke `arn-spark-persona-architect` (discovery mode) with product context + user hints |
| Target user discussion, some details provided | Invoke `arn-spark-persona-architect` (discovery mode) with details as seeds |
| Concrete personas approved, need moulds | Invoke `arn-spark-persona-architect` to derive abstracted profiles from approved examples |
| User agrees to market research | Phase 1: Invoke `arn-spark-market-researcher` (identification/plan) for query generation |
| Query plan ready | Phase 2: Invoke `arn-spark-market-researcher` (identification/search) 2-3x in parallel with query batches |
| Parallel search complete | Phase 3: Invoke `arn-spark-market-researcher` (identification/consolidate) to de-duplicate and validate |
| User wants claims about alternatives validated | Invoke `arn-spark-market-researcher` with named alternatives for verification |
| Clear, concrete answer | Record directly, no invocation |
| Definitive decision | Record directly, confirm |
| Technology question | Defer to `/arn-spark-arch-vision` |
| Conversation stalls/circles | Summarize progress, suggest next category |
| Most categories covered (pre-readiness) | Synthesize assumptions and success criteria from conversation |

## Error Handling

- **User cancels mid-conversation:** Confirm cancellation. If enough content has been gathered for a partial document, offer to write it. Otherwise, inform the user they can restart with `/arn-spark-discover` at any time.
- **arn-spark-product-strategist returns unhelpful response:** Summarize the issue briefly and continue the conversation directly. Try a more specific question on the next agent invocation.
- **Writing the document fails:** Print the full document content in the conversation so the user can copy it. Suggest checking file permissions or the output directory path.
- **Product concept already exists:**

  Ask (using `AskUserQuestion`):

  > **A product concept already exists at `[path]`. What would you like to do?**
  > 1. **Replace** — Start a fresh discovery (existing concept is preserved in git)
  > 2. **Refine** — Use the existing concept as starting context and iterate on it

  If **Refine**, read the existing document and use it as starting context for the conversation.
- **arn-spark-market-researcher returns no results:** "I couldn't find much about competitors in this space. This could mean it's genuinely novel, or the search was too narrow. We can note this as a gap and revisit later." Record what was found (even if sparse). Offer to revisit with different search angles.
- **arn-spark-persona-architect returns generic personas:** Summarize the issue to the user. Ask targeted follow-up questions to get more specific user details. Re-invoke the agent with additional details if user provides them.
- **User declines AI-assisted sections:** Respect the decision. Record "Not explored during discovery." The product concept is valid without these sections -- they are enrichment, not requirements. Do NOT force or re-offer after decline.
- **Mould derivation produces poor results:** Present the moulds to the user. If they are too generic or do not capture the patterns, ask the user what distinguishes the approved personas from each other. Re-invoke the persona-architect with the user's differentiation criteria. If moulds still fail, record the concrete examples as the primary artifact and note that moulds need manual refinement.
