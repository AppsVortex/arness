---
name: arn-spark-naming
description: >-
  This skill should be used when the user says "naming", "brand name",
  "name my product", "find a name", "product naming", "brand naming",
  "what should I call it", "name ideas", "pick a name", "naming session",
  "help me name this", "brainstorm names", "come up with a name",
  "arn spark naming", "arn-spark-naming", or wants to find a brand
  name for their product through strategic analysis, creative generation,
  qualitative scoring, and due diligence including domain availability
  and trademark screening.
version: 1.0.0
---

# Arness Spark Naming

Guide a product from nameless concept to validated brand name through a structured 4-step methodology, driven by the `arn-spark-brand-strategist` agent. Produces a **naming brief** (`naming-brief.md`) in the vision directory and a **naming report** (`naming-report.md`) in the reports directory.

## Prerequisites

1. Read the project's CLAUDE.md for the `## Arness` section.
2. Extract **Vision directory** and **Reports directory** paths. If no `## Arness` section exists or Arness Spark fields are missing, inform the user: "Arness Spark is not configured for this project yet. Run `/arn-brainstorming` to get started — it will set everything up automatically." Do not proceed without it.
3. Create directories if they do not exist.

## Step 0: Context Gathering

### Product context

Check for `<vision-dir>/product-concept.md`:

**If found:** Read and extract: vision statement, value proposition, target audience, product pillars, competitive landscape. Summarize the extracted context to the user: "Found your product concept. I'll use this as the foundation for naming."

**If not found:**

Ask (using `AskUserQuestion`):

**"No product concept found. How should I learn about your product?"**
1. **Describe your product** — Provide a description in the next message
2. **Point me to a file** — Specify a file path containing product information
3. **Explore current project** — I'll read README, package.json, and code to infer what the product does

If option 3: invoke `arn-spark-brand-strategist` in `brand-dna` mode with instructions to explore the project and summarize the product context.

### Target market

Ask (using `AskUserQuestion`):

**"What is the primary target market? This determines trademark databases and languages for linguistic screening."**
1. **United States** — USPTO trademark search, English + Spanish linguistic check
2. **European Union** — EUIPO trademark search, English + French + German + Spanish + Italian
3. **United Kingdom** — IPO trademark search, English linguistic check
4. **Global / Multiple regions** — WIPO + major national databases, all major languages

### Existing naming brief

Check for `<vision-dir>/naming-brief.md`:

**If found:**

Ask (using `AskUserQuestion`):

**"A naming brief already exists. How would you like to proceed?"**
1. **Resume from where I left off** — Continue from the first incomplete section
2. **Start fresh** — Preserve existing as naming-brief-previous.md and begin new

If resume: read the brief, detect which sections contain "-- Pending --" or are missing, and resume from the first incomplete step.

---

## Step 1: Strategic Foundation (Brand DNA)

Invoke `arn-spark-brand-strategist` in `brand-dna` mode with:
- Product context (from product-concept.md or user input)
- Competitive landscape (from product concept, or agent will research via WebSearch)
- Target market

The agent returns: brand personality profile, audience vocabulary, competitor name landscape, 1-2 recommended naming categories with rationale.

Present the Brand DNA analysis to the user.

Ask (using `AskUserQuestion`):

**"Proceed with the recommended naming categories?"**
1. **Yes, proceed with [recommended categories]** (Recommended) — Use the strategist's recommendation (substitute actual category names from the Brand DNA analysis)
2. **Choose different categories** — Select naming categories manually

If option 2:

Ask (using `AskUserQuestion`, `multiSelect: true`):

**"Select naming categories to explore (select all that apply):"**
1. **Descriptive** — Names that describe what the product does (PayPal, Dropbox)
2. **Evocative** — Names that suggest a feeling or metaphor (Slack, Nike)
3. **Invented / Abstract** — Completely new words (Spotify, Google)
4. **Lexical** — Wordplay, puns, alliteration (Pinterest, Netflix)

Then prompt (free-text): "Any existing name ideas, words you love, or words you hate? These will seed the creative sprint. Type 'none' or 'skip' to continue without seeds."

Write initial `<vision-dir>/naming-brief.md` using the creative brief template:
> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-naming/references/creative-brief-template.md`

Populate: Context and Brand DNA sections. Mark remaining sections as "-- Pending --".

---

## Step 2: Creative Sprint (The Big List)

Four generation rounds via `arn-spark-brand-strategist` in `generation` mode.

**Round 1 — Seed harvest:** Invoke agent with user's existing ideas and preferences as seeds. If no seeds, skip to Round 2.

**Round 2 — Category sprints:** Invoke agent once per selected category, requesting 50-80 candidates each. Pass the brand DNA context and dead directions. Present candidates to user after each category sprint for early feedback.

**Round 3 — Mashup round:** Invoke agent with all Round 1-2 candidates. Cross-pollinate fragments across categories. Target: 30-50 mashup candidates.

**Round 4 — User collaboration checkpoint:** Present the complete candidate list organized by category. This is a free-text conversation loop: the user marks favorites (star), flags directions to kill, and may suggest additional directions. Iterate until the user signals satisfaction.

Target: 200+ total candidates across all rounds.

Update `naming-brief.md` with Creative Sprint Results section (generation stats, candidates by category, starred favorites, dead directions).

---

## Step 3: Qualitative Filter (Six Senses)

Load the scoring methodology:
> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-naming/references/naming-methodology.md`

Invoke `arn-spark-brand-strategist` in `scoring` mode with: full candidate list, user-starred favorites, dead directions.

**Pass 1:** Agent filters 200+ candidates to 30-40 by removing obvious duds (unpronounceable, too long, too similar, offensive, dead directions). User-starred names always survive Pass 1.

**Pass 2:** Agent scores each surviving candidate on the Six Senses (1-5 each):
1. Appearance — visual punch, letter count
2. Sound — euphony, Phone Test
3. Meaning — associations, connotations
4. Memorability — stickiness, alliteration
5. Function — verbability, typability, handle-fit
6. Scalability — expansion headroom

Present the scored table sorted by total score (6-30).

Prompt (free-text): "Select 5-8 finalists for due diligence. You can pick from the top of the table, or choose names you like regardless of score."

Update `naming-brief.md` with Qualitative Filter Results section.

---

## Step 4: Cold Shower (Due Diligence)

### 4a — Domain Availability

Load the WHOIS/RDAP server reference:
> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-naming/references/whois-server-map.md`

**How it works:** Both scripts use RDAP (the modern IETF standard) as the primary lookup method, with port-43 WHOIS and system `whois` as built-in fallbacks. The fallback chain per domain is: RDAP → port-43 WHOIS → system whois → manual URL. The scripts handle this automatically — no manual fallback logic needed.

**Environment detection** (priority order):

1. Check Python: run `python3 --version`. If available, use `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-naming/scripts/whois-check.py`.
2. Check Node.js: run `node --version`. If available, use `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-naming/scripts/whois-check.js`.
3. Neither available: skip automated checking. Present manual fallback URLs (`https://www.whois.com/whois/[domain]`) for each domain.

Note: System `whois` is NOT required — both scripts have it as a built-in last-resort fallback (gracefully skipped on Windows where `whois` is not available). Python and Node.js scripts work identically across Linux, macOS, Windows, and WSL2.

**Rate limit discovery:** Before running queries, use WebSearch for `"[RDAP or WHOIS server name]" rate limit` for the primary TLD servers involved. Set `delay_seconds` to the most conservative discovered limit. Floor: 2 seconds. Default if unknown: 3 seconds.

**Domain list construction:** Each finalist name × TLDs. Start with global TLDs: `.com` (essential), `.io`, `.co`, `.dev`, `.app`, `.ai`. Then add country-specific TLDs based on target market (see `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-naming/references/whois-server-map.md` for the market-to-TLD mapping):
- US: add `.us`
- EU: add `.eu`, `.de`, `.fr`, `.it`, `.es`, `.nl`
- UK: add `.co.uk`
- Global: add relevant local TLDs based on user's primary markets

The scripts handle compound ccTLDs (`.com.br`, `.co.uk`, `.com.au`, etc.) and RDAP-only TLDs (`.dev`, `.app`, `.land`) automatically. Ask user if additional TLDs should be checked.

**Execution:**
```bash
echo '{"domains": ["name1.com", "name1.io", ...], "delay_seconds": N}' | python3 ${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-naming/scripts/whois-check.py
```

Parse JSON output. Each result includes a `method` field ("rdap", "whois", "system-whois", or "none") and a `manual_url` for any domain that couldn't be determined. If exit code 1 (RDAP rate limit circuit breaker): read partial results, report what was checked, offer manual URLs for unchecked domains.

### 4b — Trademark Screening

Load trademark database reference:
> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-naming/references/trademark-databases.md`

**Tier 1 (automated):** Use WebSearch for `"[name]" trademark [industry]` and `"[name]" registered trademark` for each finalist.

**Tier 2 (guided):** Based on the target market, generate direct search URLs from the trademark database reference. Present URLs as a clickable checklist for the user to verify manually.

**Always include:** "This is a preliminary screening. Consult a trademark attorney before committing to a brand name."

### 4c — Linguistic Screening

Invoke `arn-spark-brand-strategist` in `linguistic-screening` mode with: finalist names, target market, relevant languages (mapped from target market per the agent's language mapping).

The agent checks each name for: negative meanings, phonetic conflicts, cultural associations, and slang issues. Uses WebSearch for verification of uncertain findings.

### 4d — Social Media Handle Check

Use WebSearch for each finalist: `"[name]" @[name] site:twitter.com OR site:x.com OR site:instagram.com OR site:github.com`

Report availability: available, taken, or unknown for each platform.

---

## Final Output

### Update naming brief

Update `<vision-dir>/naming-brief.md` with:
- Due Diligence section (domain matrix, trademark results, linguistic results, social handles)
- Final Decision section (chosen name, rationale, runner-ups)

### Write naming report

Load the report template:
> Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-naming/references/naming-report-template.md`

Write `<reports-dir>/naming-report.md` with all sections populated.

### Update product concept (conditional)

**Only if `<vision-dir>/product-concept.md` exists:**

Present the proposed change: adding the brand name to the product concept's Vision section.

Ask (using `AskUserQuestion`):

**"Update the product concept with the chosen brand name?"**
1. **Yes, update it** — Add brand name to the Vision section of product-concept.md
2. **No, keep as-is** — Product concept remains unchanged

If Yes: read product-concept.md, add `**Brand name:** [chosen name]` to the Vision section, update the document title if it contains a placeholder. Write back.

### Summary

Present to the user:
- Chosen brand name
- Naming brief location: `<vision-dir>/naming-brief.md`
- Naming report location: `<reports-dir>/naming-report.md`
- Product concept updated: yes / no
- Any due diligence gaps to address (unchecked domains, trademark databases to verify manually)
- Runner-up names for reference

---

## Agent Invocation Map

| Step | Agent | Mode | Purpose |
|------|-------|------|---------|
| 1 | `arn-spark-brand-strategist` | brand-dna | Analyze brand personality, audience, competitors, recommend categories |
| 2 (each round) | `arn-spark-brand-strategist` | generation | Generate 50-80 candidates per category per round |
| 3 | `arn-spark-brand-strategist` | scoring | Filter and score candidates on Six Senses framework |
| 4c | `arn-spark-brand-strategist` | linguistic-screening | Check finalists in target languages |
| 4a | Direct (Bash) | scripts | Run WHOIS availability check |
| 4b, 4d | Direct (WebSearch) | — | Trademark and social media screening |

## Error Handling

- **WHOIS script fails:** Read partial JSON results. Report checked vs. unchecked domains. Offer manual fallback: `https://www.whois.com/whois/[domain]`
- **Neither Python nor Node.js available:** Skip automated WHOIS entirely. Present manual check URLs.
- **WebSearch fails during trademark screening:** Note the gap. Present trademark database URLs for manual verification.
- **User cancels mid-process:** Save current progress to naming-brief.md (incomplete sections marked "-- Pending --"). Resumable via Step 0.
- **Product concept update fails:** Print the proposed change in conversation for manual application.
- **Agent returns insufficient candidates:** Retry with adjusted prompt (broader techniques, relaxed constraints). If still insufficient, present what was generated and ask user whether to continue or adjust direction.

## Constraints

- Product-concept.md updates are NET-NEW information (brand name addition), not stress-test-driven modifications. This does not conflict with the concept-review exclusivity rule (from `arn-spark-concept-review`, which restricts stress-test-recommendation consolidation to that skill alone).
- User approval gate is MANDATORY before writing to product-concept.md.
- All reference/script paths use `${CLAUDE_PLUGIN_ROOT}`.
- WHOIS queries use a circuit breaker — any error stops all remaining queries immediately to protect the user's IP.
- The naming brief overwrites on re-run (git provides history). The user is warned and offered resume/start-fresh in Step 0.
