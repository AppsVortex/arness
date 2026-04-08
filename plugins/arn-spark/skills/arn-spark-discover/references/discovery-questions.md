# Product Discovery Questions

Structured question bank for guided product discovery in greenfield projects. These are conversation guides, not a rigid questionnaire. Select questions based on what is weakest or most unclear in the user's description. Never ask all questions at once.

## 1. Vision & Problem

- What specific problem does this solve? Who has this problem today?
- What do people currently do without this product? What is painful or inefficient about their current approach?
- In one sentence, what is this product? (Forces clarity)
- What would success look like six months after launch?
- Is this a "vitamin" (nice to have) or a "painkiller" (solves an urgent need)?
- How severe is this problem? Is it a daily frustration or an occasional inconvenience?
- Can you describe a specific recent moment when someone experienced this problem?
- If this problem disappeared tomorrow, what would change in the user's daily workflow?
- Who else is affected when this problem occurs? (teammates, customers, family, downstream systems)

## 2. Target Users & Personas

- Who is the primary user? Describe them specifically -- not "developers" but "solo developers working on side projects who need quick feedback."
- What is the user doing when they reach for this product? What triggered that moment?
- Are there secondary users or stakeholders who benefit but are not the primary user?
- How technically sophisticated is the target user? Does the product need to be zero-configuration or is customization expected?
- What does a typical day look like for your primary user? When does the problem surface in their routine?
- What has your target user already tried to solve this problem? Why did those attempts fail or fall short?
- How does the target user currently discover new tools? (peer recommendation, search, app store, conference talks, social media)
- What would make someone stop using your product after trying it? What is their breaking point?
- Are there users you explicitly do NOT want to serve? Who is this product NOT for?

## 3. Core Experience

- What is the primary interaction? Walk me through the "moment of magic" -- what does the user experience that makes this product valuable?
- What does the user see and feel when they first open this product?
- What is the single most important thing this product does? If it could only do one thing, what would that be?
- How frequently will users interact with this? Multiple times a day, daily, weekly?
- Is this product used actively (user initiates) or passively (runs in background)?

## 4. Trust & Security Model

- How do users discover each other or access the product? Is discovery automatic or manual?
- What trust model applies? (No auth, device pairing, user accounts, invite codes, OAuth, etc.)
- What is the security posture? (Casual/personal, team/workplace, regulated/enterprise)
- What data is sensitive? What would be the impact of unauthorized access?
- Does the product need to work without an internet connection?

## 5. Platform & Constraints

- What platforms must be supported on day one? (Desktop, mobile, web, specific OS versions)
- Are there performance requirements? (Latency, throughput, response time, battery usage)
- What about offline support? Does it need to work without network access?
- Are there size or resource constraints? (Embedded, low-memory, bandwidth-limited)
- How will users install or access this? (App store, installer, browser, CLI)

## 6. Participants & Scale

- How many simultaneous users or devices are expected?
- What is the communication or interaction topology? (1:1, room/group, broadcast, hub-and-spoke)
- How does the experience change with more participants? Is there a natural upper limit?
- Do all participants have equal roles or are there different permission levels?

## 7. Scope Boundaries

- What is explicitly NOT part of v1? What features have you thought about but want to defer?
- What features sound essential but could actually wait?
- What is the absolute minimum version that delivers the core value?
- Are there adjacent products or features that should remain separate?
- What would you cut if you had to ship in half the time?

## 8. Product Pillars

These questions surface the non-negotiable qualities that define the product's soul -- the standards that every feature, design choice, and trade-off should be measured against. Pillars are not features; they are commitments. Ask these throughout the conversation, not as a separate block. Look for moments when the user expresses strong conviction ("it HAS to feel...", "the whole point is...", "I refuse to compromise on...").

- What quality or feeling should this product absolutely nail? If the product does everything else right but gets this wrong, would it still feel like a failure?
- When you imagine a user recommending this product to someone else, what would they say about it? What one word or phrase would they use?
- Are there products you admire not for what they do, but for how they do it? What specifically about their approach resonates?
- If you had to cut a feature to protect the quality of the experience, would you? What would you never compromise even under deadline pressure?
- What would make this product feel cheap or wrong? What is the opposite of what you are trying to build?

## 9. Business Model & Constraints

These questions surface business-model constraints that directly affect architecture and technology choices. Multi-tenancy models, regulatory requirements, budget caps, and vendor preferences can eliminate technology options entirely — a SaaS with 500 tenants cannot use a service with hard per-project connection limits, and HIPAA compliance restricts which cloud providers are viable. Capture concrete numbers, not vague aspirations.

- What is the business model? (B2C, B2B SaaS, marketplace, self-hosted, white-label, enterprise on-prem)
- Is this multi-tenant? If so, how many tenants/clients are expected at launch? At scale? (10, 100, 500, 1000+)
- What tenant isolation level is needed? (shared database, schema-per-tenant, database-per-tenant, infrastructure-per-tenant)
- Are there regulatory or compliance requirements? (GDPR, HIPAA, SOC2, PCI-DSS, FedRAMP, ISO 27001)
- Are there data residency requirements? (data must stay in EU, US, specific country)
- What is the budget constraint for cloud/infrastructure costs? (monthly spend target, per-tenant cost target)
- Is there a preference for or against specific vendors? (must use AWS, avoid Google, open-source only)
- What is the licensing constraint? (open-source only, no AGPL, commercial licenses acceptable)
- What is the team's technical experience? (languages, frameworks, cloud providers they know)
- Is there a hard timeline or market window? (MVP by Q3, launch before competitor X)
- Are there existing systems this must integrate with? (legacy APIs, specific databases, SSO providers)
- Is vendor lock-in acceptable? (fully managed services OK, or must be portable/self-hostable)

## 10. Competitive Landscape

These questions surface the competitive context. Not all products need deep research (internal tools, hobby projects, genuinely novel spaces may have few competitors). The goal is understanding what users do today and what alternatives exist, not building a competitive strategy. When the user cannot name competitors, offer AI-assisted market research via arn-spark-market-researcher.

- What do people use today to solve this problem? (Include manual processes, spreadsheets, and "doing nothing" as valid answers)
- Can you name any direct competitors? What do they do well? What do they get wrong?
- Are there adjacent products that partially solve this problem even though it is not their main purpose?
- Why would someone choose your product over the alternatives? What is your unfair advantage?
- Is the market for this solution growing, stable, or shrinking? What is driving the trend?
- Are there competitors you admire? What specifically about their approach do you want to learn from or avoid?

## 11. Assumptions & Success Criteria

These questions are typically NOT asked directly. The AI synthesizes assumptions from the conversation and presents them for validation. The questions below are fallbacks for when direct probing is needed.

Assumptions:
- What is the biggest bet you are making with this product? What has to be true for it to work?
- What do you believe about your users that you have not yet verified?
- What market or behavioral trend are you counting on?
- If you had to name one thing that could make this product fail, what would it be?

Success Criteria:
- How will you know this product is working? What does success look like in concrete numbers?
- What is the minimum number of users, transactions, or interactions that would make this worth continuing?
- Six months after launch, what metric would make you feel this is succeeding? What would make you feel it is failing?
- Is there a leading indicator you could measure in the first week to predict long-term success?
