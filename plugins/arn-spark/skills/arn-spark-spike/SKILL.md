---
name: arn-spark-spike
description: >-
  This skill should be used when the user says "spike", "arn spike",
  "validate risks", "technical validation", "proof of concept",
  "validate architecture", "risk spike", "test this risk", "will this work",
  "technical spike", "validate the stack", or wants to validate critical
  technical risks from the architecture vision by creating minimal
  proof-of-concept code and testing whether the chosen technologies work as
  expected.
version: 1.0.0
---

# Arness Spike

Validate critical technical risks from the architecture vision through minimal proof-of-concept implementations, aided by the `arn-spark-spike-runner` agent for POC creation and execution. This is a conversational skill that runs in normal conversation (NOT plan mode). The primary artifacts are **spike POC code** in isolated directories and a **spike results document**.

This skill addresses the question: "Will the chosen technologies actually work for our use case?" It does not implement features or build the application -- it runs targeted experiments to validate or invalidate specific technical assumptions before committing to them.

## Prerequisites

An architecture vision document should exist. Check in order:

1. Read the project's `CLAUDE.md` for a `## Arness` section. If found, check the configured Vision directory for `architecture-vision.md`
2. If no `## Arness` section found, check `.arness/vision/architecture-vision.md` at the project root

**If an architecture vision is found:** Read it and extract the "Known Risks & Mitigations" section.

**If no architecture vision is found:** Inform the user:

"No architecture vision document found. I can still run spikes if you describe the specific technical risks to validate. For a comprehensive risk assessment, run `/arn-spark-arch-vision` first."

If the user provides risks directly, proceed with those.

The project should ideally be scaffolded (via `/arn-spark-scaffold`) so the spike runner can leverage the existing project setup. If not scaffolded, spikes will need to set up their own dependencies, which the spike runner handles.

Determine the spike workspace:
1. Read the project's `CLAUDE.md` and check for a `## Arness` section
2. If found, extract the configured Spikes directory path — this is the source of truth
3. If no `## Arness` section exists or Arness Spark fields are missing, inform the user: "Arness Spark is not configured for this project yet. Run `/arn-brainstorming` to get started — it will set everything up automatically." Do not proceed without it.
4. If the directory does not exist, create it

## Workflow

### Step 1: Identify Risks

Load the architecture vision and extract all risks from the "Known Risks & Mitigations" section. Parse each risk to identify:

- **Risk title:** Brief name
- **Description:** What could go wrong
- **Validation priority:** Critical (must validate before any code), Important (validate in first sprint), Monitor (keep an eye on)
- **Suggested mitigation:** What the architecture vision proposes as a fallback

If additional validation points were noted in the tech evaluator's recommendations during the architecture vision phase, include those as well.

Present the risk list to the user:

"I found [N] risks in your architecture vision. Here they are by priority:

**Critical:**
1. [Risk title] -- [brief description]
2. [Risk title] -- [brief description]

**Important:**
3. [Risk title] -- [brief description]

**Monitor:**
4. [Risk title] -- [brief description]

Ask (using `AskUserQuestion`) with `multiSelect: true`:

**"Which risks would you like to spike? (select multiple)"**

Options:
[List each risk as a numbered option with its title and brief description, e.g.:]
1. **[Risk 1 title]** — [brief description]
2. **[Risk 2 title]** — [brief description]
3. **[Risk 3 title]** — [brief description]

If the user adds custom risks not from the architecture vision, include those.

### Step 2: Define Validation Criteria (Per Risk)

For each selected risk, propose a minimal POC approach and clear validation criteria:

"For **[Risk Title]**:

**POC approach:** [What we will build to test this. 1-2 sentences describing the minimal experiment.]

**Validation criteria:**
- [Specific, measurable criterion 1]
- [Specific, measurable criterion 2]

**Spike directory:** `<configured Spikes directory>/spike-[NNN]-[descriptive-name]/`

Does this approach look right, or would you test it differently?"

Wait for user approval or adjustments before running each spike. The user may want to modify the approach, change criteria, or skip the risk.

### Step 3: Execute Spikes

**IMPORTANT: Run spikes sequentially, one at a time.** Do NOT launch multiple spike-runner agents in parallel or in the background. The spike-runner agent needs Bash and Write tool access, which requires user permission approval. Parallel or background agents cannot surface permission prompts to the user, causing all tool calls to be denied. Wait for each spike to fully complete before starting the next one.

For each approved spike, in order:

1. Invoke the `arn-spark-spike-runner` agent (foreground, not background) with:
   - Risk description and context
   - Validation criteria
   - Project context (stack, existing scaffold location)
   - Spike workspace path (e.g., `<Spikes directory>/spike-001-webrtc-wkwebview/`)

2. Wait for the agent to complete fully before proceeding.

3. Present the spike runner's results to the user:
   - **Validated:** "Risk validated. [Brief evidence summary]. No architecture changes needed."
   - **Partially Validated:** "Risk partially validated. [Caveats]. We should discuss whether these limitations are acceptable."
   - **Failed:** "Risk failed validation. [Evidence]. Here are the alternatives the spike runner identified: [list]. How would you like to proceed?"
   - **Deferred:** "Could not test this in the current environment. [What is needed]. The spike files and manual execution instructions are saved at `[spike directory]` -- you can run this spike manually on the required platform. This should be validated when [condition]."

4. **If a spike failed:**

   Ask (using `AskUserQuestion`):

   **"Risk [Risk Title] failed validation. How would you like to proceed?"**

   Options:
   1. **Accept the risk** — Proceed anyway with the current approach
   2. **Choose an alternative** — Discuss trade-offs and pick a different approach
   3. **Update architecture vision** — Revise the architecture to address the failure

5. Proceed to the next spike only after presenting results and resolving any failures.

### Step 4: Write Spike Results Document

After all spikes have been run:

1. Read the spike report template:
   > Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-spark-spike/references/spike-report-template.md`

2. Populate the template with all spike results

3. Determine the output directory:
   - Read the project's `CLAUDE.md` and check for a `## Arness` section
   - If found, extract the configured Vision directory path — this is the source of truth
   - If no `## Arness` section exists or Arness Spark fields are missing, inform the user: "Arness Spark is not configured for this project yet. Run `/arn-brainstorming` to get started — it will set everything up automatically." Do not proceed without it.

4. Write the document as `spike-results.md`

5. Present a summary:

"Spike results saved to `[path]/spike-results.md`.

**Summary:**
| Risk | Result |
|------|--------|
| [Risk 1] | Validated |
| [Risk 2] | Failed -- chose Alternative A |
| [Risk 3] | Deferred -- needs macOS |

[N] of [M] risks validated. [Note any architecture changes decided.]"

### Step 5: Update Architecture Vision (If Needed)

If any spikes failed and the user chose an alternative approach:

"Based on the spike results, the following sections of `architecture-vision.md` should be updated:

1. [Section]: [What to change and why]
2. [Section]: [What to change and why]

Ask (using `AskUserQuestion`):

> **Should I update the architecture vision now?**
> 1. **Yes** — Update the affected sections
> 2. **No** — Skip for now, I will update manually later"

If the user chooses **Yes**, make the targeted updates to the architecture vision document. Only change the specific sections affected by failed spikes -- do not rewrite the entire document.

### Step 6: Recommend Next Steps

"All spikes complete. Recommended next steps:

1. **Explore visual style:** Run `/arn-spark-style-explore` to define the look and feel
2. **Build static prototype:** Run `/arn-spark-static-prototype` to validate visual fidelity
3. **Address deferred risks:** [List any deferred risks and when they should be revisited]"

Adapt based on results. If critical risks failed and alternatives were chosen, emphasize the architecture changes. If risks were deferred, note when they should be revisited.

## Agent Invocation Guide

| Situation | Action |
|-----------|--------|
| Run an approved spike (Step 3) | Invoke `arn-spark-spike-runner` sequentially (foreground, not background) with risk details, criteria, and workspace path. Wait for completion before starting the next spike. |
| Spike runner agent denied permissions | The agent likely failed because it ran in the background or in parallel. Re-run it in the foreground sequentially. If permissions are still denied, run the spike directly in the main conversation instead of delegating to the agent. |
| User asks about technology alternatives | Answer from the architecture vision context or invoke `arn-spark-tech-evaluator` if deep comparison needed |
| User wants to add a custom risk | Record it and proceed to Step 2 for that risk |
| User asks about features or screens | Defer: "Feature work comes after risk validation. Next step after spikes is `/arn-spark-style-explore` or `/arn-spark-static-prototype`." |
| Spike runner reports environment limitation | Record as deferred, continue to next spike |

## Error Handling

- **No risks found in architecture vision:** Ask the user if they have specific technical concerns to validate. If none, inform them: "No critical risks identified. You can proceed to `/arn-spark-style-explore` or `/arn-spark-static-prototype`."
- **Spike cannot run in current environment:** The spike runner still creates all POC files and a README with manual execution instructions on disk. Mark as deferred with specific environment requirements. The user can run the spike manually on the required platform later. Continue to the next spike.
- **Spike runner agent denied permissions (Bash/Write):** This happens when agents are launched in parallel or in the background -- permission prompts cannot reach the user. Re-run the spike in the foreground sequentially. If permissions are still denied, fall back to running the spike directly in the main conversation context (write POC files and run build/execute commands yourself rather than delegating to the agent).
- **Spike fails repeatedly (3 times):** The spike runner will halt. Present the failure state to the user and ask how to proceed (skip, try different approach, or investigate manually).
- **User disagrees with spike result:** Re-examine the evidence. If the user provides additional context, consider re-running with adjusted criteria.
- **Writing the results document fails:** Print the full content in the conversation so the user can copy it. Suggest checking file permissions.
- **Architecture vision update conflicts:** If the architecture vision was modified since it was read, re-read it before making changes. Present the diff to the user for confirmation.
- **No project scaffold exists:** Spikes can still run -- the spike runner creates self-contained workspaces. Note that some spikes may need to install their own dependencies.
