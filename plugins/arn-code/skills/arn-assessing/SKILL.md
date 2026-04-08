---
name: arn-assessing
description: >-
  This skill should be used when the user says "assessing", "arness assessing",
  "assess", "assess codebase", "technical review", "codebase assessment",
  "find improvements", "what should I improve", "tech debt review",
  "pattern compliance check", "codebase health check", "improvement plan",
  "review my codebase", "what needs fixing", "code quality check",
  "audit my code", "run an assessment", "arn-assessing",
  or wants a comprehensive technical assessment of the codebase against
  stored patterns followed by prioritized improvement execution.
  Chains to arn-implementing if improvements are identified.
version: 1.0.0
---

# Arness Assessing

Comprehensive technical assessment of the codebase against stored patterns, followed by prioritized improvement identification. This is a first-citizen entry point that wraps `arn-code-assess` with a pre-flight check and provides chaining context to `arn-implementing`.

This skill is a **medium orchestration wrapper**. It MUST NOT duplicate `arn-code-assess` logic. All assessment work is done by the invoked skill (which has its own 7 internal gates). Arness-assessing handles: prerequisite checks, pre-flight validation, invoking the assess skill, and offering the chain exit.

## Step 0: Ensure Configuration

Read `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-ensure-config/references/ensure-config.md` and follow its instructions. This guarantees a user profile exists and `## Arness` is configured with Arness Code fields before proceeding.

After Step 0 completes, extract the following from `## Arness`:
- **Code patterns** — path to the directory containing stored pattern documentation

## Workflow

### Step 1: Pre-flight Check

Verify that pattern documentation exists at the configured Code patterns path:
- `<code-patterns-dir>/code-patterns.md`
- `<code-patterns-dir>/testing-patterns.md`
- `<code-patterns-dir>/architecture.md`

**If any are missing:** inform the user: "Pattern documentation is incomplete. The assessment needs stored patterns to compare against. Run `/arn-planning` first — it will generate pattern docs on first use." Do not proceed.

**If all exist:** inform the user briefly: "Pattern documentation found. Starting assessment..."

---

### Step 2: Invoke Assess

Show progress:
```
Assessing: PRE-FLIGHT -> ASSESSMENT (scope -> analyze -> prioritize -> spec -> plan -> execute -> ship -> update-patterns)
                         ^^^^^^^^^^
```

Invoke the assess skill:

> `Skill: arn-code:arn-code-assess`

The assess skill has its own 7 internal decision gates (scope selection, improvement selection, spec review, execution mode, etc.) and manages its own complete pipeline internally. Wait for it to complete.

---

### Step 3: Completion Handoff

After `arn-code-assess` completes, offer the chain exit:

Ask (using `AskUserQuestion`):

**"Assessment complete. What next?"**

Options:
1. **Implement improvements** — Start implementing the identified fixes and improvements
2. **Done** — Exit

If **Implement improvements**: `Skill: arn-code:arn-implementing`
If **Done**: Exit.

---

## Error Handling

- **`## Arness` config missing:** Handled by Step 0 (ensure-config) — this should not occur if Step 0 completed successfully.
- **Pattern docs missing:** Block with pre-flight message. Suggest running `/arn-planning` which will generate pattern docs on first use.
- **`arn-code-assess` fails:** Present the error. Ask: retry or abort.
- **Assessment finds no improvements:** Exit with "Codebase is healthy — no improvements needed." Do not offer implementing chain.
