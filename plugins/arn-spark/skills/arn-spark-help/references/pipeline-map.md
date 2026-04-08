# Spark Pipeline Map

Reference for the `arn-spark-help` skill. Contains pipeline templates, stage detection rules, and next-step suggestions for the Spark exploration pipeline.

---

## Spark Pipeline Template

The diagram below is the canonical Spark exploration pipeline. When rendering for the user, annotate the active stage with a `YOU ARE HERE` marker placed below the active stage name.

```
Spark Exploration Pipeline
==========================

  gf-init --> discover --> stress-test --> concept-review --> naming --> arch-vision --> use-cases --> scaffold --> spike --> visual-sketch --> style-explore --> prototypes --> lock --> feature-extract
                          (optional)      (optional)        (optional)                                                     (optional)

  Prototypes: arn-spark-static-prototype then arn-spark-clickable-prototype (in sequence)
  Stress tests: arn-spark-stress-interview, arn-spark-stress-competitive, arn-spark-stress-premortem, arn-spark-stress-prfaq (multi-select)
  Variants: arn-spark-use-cases-teams, arn-spark-static-prototype-teams, arn-spark-clickable-prototype-teams
  Standalone: arn-spark-dev-setup, arn-spark-visual-readiness, arn-spark-visual-strategy
  Guided: /arn-brainstorming -- walks through the entire pipeline with decision gates
```

---

## Stage-to-Skill Mapping

| Stage | Primary Skill | Notes |
|-------|--------------|-------|
| `gf-init` | `/arn-brainstorming` or `/arn-spark-discover` | Brainstorming is the guided wizard; discover is the direct entry |
| `discover` | `/arn-spark-discover` | Produces product-concept.md with vision, personas, competitive landscape, pillars |
| `stress-test` | `/arn-spark-stress-interview`, `/arn-spark-stress-competitive`, `/arn-spark-stress-premortem`, `/arn-spark-stress-prfaq` | Multi-select: user picks which tests to run. All are read-only on product-concept.md |
| `concept-review` | `/arn-spark-concept-review` | Consolidates stress test findings. ONLY skill that modifies product-concept.md |
| `naming` | `/arn-spark-naming` | 4-step methodology: Brand DNA, creative generation, Six Senses scoring, WHOIS/trademark due diligence |
| `arch-vision` | `/arn-spark-arch-vision` | Technology choices, system design, packaging strategy |
| `use-cases` | `/arn-spark-use-cases` | Cockburn fully-dressed format. Teams variant: `/arn-spark-use-cases-teams` |
| `scaffold` | `/arn-spark-scaffold` | Creates project skeleton with chosen framework and dependencies |
| `spike` | `/arn-spark-spike` | Optional — validate risky technical assumptions with POC code |
| `visual-sketch` | `/arn-spark-visual-sketch` | Multiple visual direction proposals as live HTML/CSS |
| `style-explore` | `/arn-spark-style-explore` | Define complete design system from the visual direction |
| `prototypes` | `/arn-spark-static-prototype` then `/arn-spark-clickable-prototype` | Teams variants available for both. Includes UX judge validation |
| `lock` | `/arn-spark-prototype-lock` | Freezes validated prototype as development reference |
| `feature-extract` | `/arn-spark-feature-extract` | Extracts prioritized feature backlog. Optional issue tracker upload |

---

## Annotation Instructions

1. Identify the user's current stage using the detection rules below.
2. Place the `YOU ARE HERE` marker directly below the matching stage label.
3. Spark is a single-track pipeline (no per-project subdirectories).

**Example:**

```
Spark Exploration Pipeline
==========================

  gf-init --> discover --> stress-test --> concept-review --> naming --> arch-vision --> use-cases --> scaffold --> spike --> visual-sketch --> style-explore --> prototypes --> lock --> feature-extract
                                                                                                                                            ^^^^^^^^^^^^^
                                                                                                                                          YOU ARE HERE

  Prototypes: arn-spark-static-prototype then arn-spark-clickable-prototype
  Stress tests: arn-spark-stress-interview, arn-spark-stress-competitive, arn-spark-stress-premortem, arn-spark-stress-prfaq
  Variants: arn-spark-use-cases-teams, arn-spark-static-prototype-teams, arn-spark-clickable-prototype-teams
  Standalone: arn-spark-dev-setup, arn-spark-visual-readiness, arn-spark-visual-strategy
  Guided: /arn-brainstorming
```

---

## Stage Detection Rules

Check stages from **most advanced to least advanced**. The first matching rule determines the current stage. Spark detection uses artifact existence in the configured Spark directories.

**Prerequisites:** `## Arness` must contain at least one Spark field (Vision directory, Use cases directory, Prototypes directory). If none are present, Spark detection is skipped entirely.

| Stage | Key | Detection Rule | Artifact |
|-------|-----|----------------|----------|
| Feature backlog ready | `gf-feature-extract` | Feature backlog index exists | `<vision-dir>/features/feature-backlog.md` |
| Prototype locked | `gf-prototype-lock` | Locked prototype manifest exists | `<prototypes-dir>/locked/LOCKED.md` |
| Clickable prototype done | `gf-clickable-proto` | Clickable prototype final report exists | `<prototypes-dir>/clickable/final-report.md` |
| Static prototype done | `gf-static-proto` | Static prototype final report exists | `<prototypes-dir>/static/final-report.md` |
| Style defined | `gf-style-explore` | Style brief exists | `<vision-dir>/style-brief.md` |
| Visual direction chosen | `gf-visual-sketch` | Visual direction document exists | `<vision-dir>/visual-direction.md` |
| Spike complete | `gf-spike` | Spike results exist | `<vision-dir>/spike-results.md` |
| Scaffold built | `gf-scaffold` | Scaffold summary exists | `<vision-dir>/scaffold-summary.md` |
| Use cases written | `gf-use-cases` | Use case files exist | `<use-cases-dir>/UC-*.md` (at least one) |
| Architecture defined | `gf-arch-vision` | Architecture vision exists | `<vision-dir>/architecture-vision.md` |
| Naming complete | `gf-naming` | Naming brief or report exists | `<vision-dir>/naming-brief.md` OR `<reports-dir>/naming-report.md` |
| Concept reviewed | `gf-concept-review` | Concept review report exists | `<reports-dir>/stress-tests/concept-review-report.md` |
| Stress tests run | `gf-stress-test` | Any stress test report exists | `<reports-dir>/stress-tests/interview-report.md` OR `competitive-report.md` OR `premortem-report.md` OR `prfaq-report.md` |
| Product discovered | `gf-discover` | Product concept exists | `<vision-dir>/product-concept.md` |
| Spark initialized | `gf-init` | Spark fields exist in `## Arness` but no artifacts found | `## Arness` has Spark fields but directories are empty |

### Spark Complete Detection

Spark exploration is considered **complete** when `<vision-dir>/features/feature-backlog.md` exists (the `gf-feature-extract` stage is reached). This signals the project is ready to transition from exploration to development.

### Detection Notes

**Stress test stage:** Four independent reports can exist in any combination. The presence of ANY stress-test report triggers the `gf-stress-test` stage. If `concept-review-report.md` also exists, it takes precedence (concept-review > stress-test in detection order).

**Naming stage:** `naming-brief.md` gets written incrementally during the naming process. Any existence of naming-brief.md or naming-report.md is treated as naming complete. If naming is in-progress and the user runs `/arn-spark-naming`, it handles its own resume.

**Spike stage:** Optional. If a project skips spike and goes directly from scaffold to visual-sketch, the detection works correctly — `gf-visual-sketch` is detected based on `visual-direction.md` existence.

**Prototype-lock stage:** Optional. If a project skips lock and goes directly from clickable-prototype to feature-extract, the detection works correctly.

---

## Next Step Suggestions

After detecting the current Spark stage, suggest the next command.

| Current Stage | Next Command | Description |
|---------------|-------------|-------------|
| Spark initialized (`gf-init`) | `/arn-spark-discover` | Shape the product idea into a structured concept. Or run `/arn-brainstorming` for the guided wizard. |
| Product discovered (`gf-discover`) | `/arn-spark-stress-interview`, etc. OR `/arn-spark-arch-vision` | Run stress tests to validate the concept (optional), or skip to architecture. |
| Stress tests run (`gf-stress-test`) | `/arn-spark-concept-review` | Consolidate stress test findings and update the product concept. |
| Concept reviewed (`gf-concept-review`) | `/arn-spark-naming` or `/arn-spark-arch-vision` | Name your product (optional), or skip to architecture. |
| Naming complete (`gf-naming`) | `/arn-spark-arch-vision` | Choose technologies and design the system architecture. |
| Architecture defined (`gf-arch-vision`) | `/arn-spark-use-cases` | Write use cases (or `/arn-spark-use-cases-teams` for expert debate). |
| Use cases written (`gf-use-cases`) | `/arn-spark-scaffold` | Create the project skeleton with the chosen tech stack. |
| Scaffold built (`gf-scaffold`) | `/arn-spark-spike` or `/arn-spark-visual-sketch` | Validate risky assumptions (optional), or explore visual directions. |
| Spike complete (`gf-spike`) | `/arn-spark-visual-sketch` | Generate visual direction proposals on the dev server. |
| Visual direction chosen (`gf-visual-sketch`) | `/arn-spark-style-explore` | Define the complete design system from the visual direction. |
| Style defined (`gf-style-explore`) | `/arn-spark-static-prototype` | Build and validate a static HTML/CSS prototype. |
| Static prototype done (`gf-static-proto`) | `/arn-spark-clickable-prototype` | Build and validate an interactive prototype with linked screens. |
| Clickable prototype done (`gf-clickable-proto`) | `/arn-spark-prototype-lock` or `/arn-spark-feature-extract` | Lock the prototype (optional), or extract features directly. |
| Prototype locked (`gf-prototype-lock`) | `/arn-spark-feature-extract` | Extract features into a prioritized backlog for development. |
| Feature backlog ready (`gf-feature-extract`) | `/arn-planning` | Transition to development — start specifying features. Or `/arn-infra-wizard` for infrastructure. |

---

## Variant Commands

These can be used as alternatives at specific stages:

| Variant | Replaces | When to Suggest |
|---------|----------|-----------------|
| `/arn-spark-use-cases-teams` | `/arn-spark-use-cases` | User prefers expert debate format for use cases |
| `/arn-spark-static-prototype-teams` | `/arn-spark-static-prototype` | User prefers expert debate for prototype validation |
| `/arn-spark-clickable-prototype-teams` | `/arn-spark-clickable-prototype` | User prefers expert debate for prototype validation |

### Standalone Commands

These operate outside the main pipeline and can be suggested at any time:

| Command | Purpose | Prerequisite |
|---------|---------|--------------|
| `/arn-spark-dev-setup` | Define or follow development environment setup | Greenfield config exists |
| `/arn-spark-prototype-lock` | Freeze approved prototypes with guardrail hooks | Prototypes directory configured, prototype approved |
| `/arn-spark-visual-readiness` | Check visual layer readiness before activating deferred tests | Visual strategy defined |
| `/arn-spark-visual-strategy` | Define layered visual testing strategy | Scaffold built, at least style-explore complete |

### Entry Points

- `/arn-brainstorming` — Walks through the entire Spark exploration pipeline with guided decision gates. This is the recommended way to use Spark for new projects.
- `/arn-spark-discover` — Direct entry into product discovery without the wizard.
- `/arn-spark-init` — (Optional) Explicitly configure the greenfield environment. Not required — Arness auto-configures on first use.

When suggesting next steps at an early stage (`gf-init` or `gf-discover`):

```
Tip: Run `/arn-brainstorming` for the guided pipeline, or invoke individual skills directly.
```

---

## Cross-Plugin Hint Templates

When Step 0 detects other plugin activity, append these hints at the bottom of the status output.

**Code active:**
```
Development pipeline: active — run `/arn-code-help` for details.
```

**Infra active:**
```
Infrastructure pipeline: active — run `/arn-infra-help` for details.
```

**Code not started but configured:**
```
Development pipeline: configured but not started.
```

**Infra not started but configured:**
```
Infrastructure pipeline: configured but not started.
```

**When Spark pipeline is complete (`gf-feature-extract`):**
```
Spark exploration is complete. Next steps:
- Start developing features: `/arn-planning`
- Deploy infrastructure: `/arn-infra-wizard`
```

**When own plugin idle (`gf-init`) and other plugins have activity:**
Show own suggestions first:
```
Ready to start: run `/arn-spark-discover` to shape your product idea, or `/arn-brainstorming` for the guided wizard.
```
Then mention others:
```
You also have active work in Code — run `/arn-code-help` for details.
```
