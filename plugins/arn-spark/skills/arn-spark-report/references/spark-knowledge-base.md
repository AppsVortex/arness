# Spark Knowledge Base

Reference documentation for the `arn-spark-doctor` agent. Describes the Arness Spark plugin's pipeline, configuration requirements, expected file structures, common failure modes, and inter-skill data flow.

## Pipeline Map

### Main Pipeline (Brainstorming Wizard)

```
discover → stress-test → concept-review → naming → arch-vision → use-cases → scaffold → spike → visual-sketch → style-explore → static-prototype → clickable-prototype → prototype-lock → feature-extract
```

The `arn-brainstorming` wizard walks through this pipeline with decision gates, detecting progress and offering to resume at the correct stage.

### Stress Testing Suite

Four stress test skills run after discovery and before concept review:

```
discover → stress-interview ──┐
         → stress-competitive ─┤
         → stress-premortem ───┤ → concept-review
         → stress-prfaq ───────┘
```

Stress tests can run in parallel and produce independent reports. Concept review synthesizes all available stress test findings.

### Teams Variants

- `arn-spark-use-cases-teams` — team debate variant of use case authoring
- `arn-spark-static-prototype-teams` — team debate variant of static prototype validation
- `arn-spark-clickable-prototype-teams` — team debate variant of clickable prototype validation

### Standalone Skills

- `arn-spark-dev-setup` — development environment setup (can run independently after scaffold)
- `arn-spark-visual-strategy` — visual testing strategy with layered validation
- `arn-spark-visual-readiness` — visual readiness checkpoint for deferred layer activation

### Entry Point

- `arn-brainstorming` — guided wizard that walks through the entire greenfield pipeline with decision gates, detects resume point

## Config Requirements

The `## Arness` section in CLAUDE.md includes Spark-specific fields. Each skill reads specific fields:

| Skill | Vision dir | Use cases dir | Prototypes dir | Spikes dir | Visual grounding dir | Reports dir |
|-------|-----------|---------------|---------------|------------|---------------------|-------------|
| arn-spark-ensure-config | creates | creates | creates | creates | creates | creates |
| arn-spark-discover | writes to | - | - | - | - | - |
| arn-spark-stress-interview | reads (vision) | - | - | - | - | writes to |
| arn-spark-stress-competitive | reads (vision) | - | - | - | - | writes to |
| arn-spark-stress-premortem | reads (vision) | - | - | - | - | writes to |
| arn-spark-stress-prfaq | reads (vision) | - | - | - | - | writes to |
| arn-spark-concept-review | reads (vision) | - | - | - | - | writes to |
| arn-spark-naming | reads (vision) | - | - | - | - | writes to |
| arn-spark-arch-vision | reads (vision) | - | - | - | - | - |
| arn-spark-use-cases | reads (vision) | writes to | - | - | - | - |
| arn-spark-use-cases-teams | reads (vision) | writes to | - | - | - | - |
| arn-spark-scaffold | reads (vision) | - | - | - | - | - |
| arn-spark-spike | reads (vision) | - | - | reads/writes | - | - |
| arn-spark-visual-sketch | reads (vision) | - | - | - | writes to | - |
| arn-spark-style-explore | reads (vision) | - | - | - | writes to | - |
| arn-spark-static-prototype | reads (vision) | - | reads/writes | - | writes to | - |
| arn-spark-static-prototype-teams | reads (vision) | - | reads/writes | - | writes to | - |
| arn-spark-clickable-prototype | reads (vision) | - | reads/writes | - | writes to | - |
| arn-spark-clickable-prototype-teams | reads (vision) | - | reads/writes | - | writes to | - |
| arn-spark-prototype-lock | - | - | reads | - | - | - |
| arn-spark-feature-extract | reads (vision) | reads | reads | reads | reads | writes to |
| arn-spark-visual-strategy | - | - | - | - | reads | - |
| arn-spark-visual-readiness | - | - | - | - | reads | - |
| arn-spark-dev-setup | - | - | - | - | - | - |
| arn-brainstorming | all (via ensure-config) | all | all | all | all | all |

## Expected ## Arness Config Format (Spark Fields)

```markdown
## Arness
- **Vision directory:** <path>
- **Use cases directory:** <path>
- **Prototypes directory:** <path>
- **Spikes directory:** <path>
- **Visual grounding directory:** <path>
- **Reports directory:** <path>
```

Default values (created by arn-spark-ensure-config): Vision directory = `.arness/vision`, Use cases directory = `.arness/use-cases`, Prototypes directory = `.arness/prototypes`, Spikes directory = `.arness/spikes`, Visual grounding directory = `.arness/visual-grounding`, Reports directory = `.arness/reports`.

## Expected Directory/File Structure

### After arn-spark-discover

```
<vision-dir>/
└── product-concept.md
```

### After stress tests (one or more)

```
<reports-dir>/
├── stress-interview-report.md     (from arn-spark-stress-interview)
├── stress-competitive-report.md   (from arn-spark-stress-competitive)
├── stress-premortem-report.md     (from arn-spark-stress-premortem)
└── stress-prfaq-report.md         (from arn-spark-stress-prfaq)
```

### After arn-spark-concept-review

```
<vision-dir>/
├── product-concept.md              (updated with approved changes)
└── product-concept-pre-review.md   (backup of pre-review version)
<reports-dir>/
└── concept-review-report.md
```

### After arn-spark-naming

```
<vision-dir>/
└── naming-brief.md                 (includes Final Decision section)
<reports-dir>/
└── naming-report.md
```

### After arn-spark-arch-vision

```
<vision-dir>/
└── architecture-vision.md
```

### After arn-spark-scaffold

```
<project-root>/
├── package.json (or equivalent)
├── node_modules/ (or equivalent)
├── src/ (or framework-specific structure)
└── ... (framework scaffolded files)
```

### After arn-spark-prototype-lock

```
<prototypes-dir>/
├── locked/                         (frozen prototype copy)
│   └── ... (snapshot of prototype files)
└── LOCKED.md                       (lock manifest with timestamp and git tag)
```

### After arn-spark-feature-extract

```
<reports-dir>/
└── feature-backlog.md              (prioritized feature list with Feature Tracker)
```

## Common Failure Modes

| Symptom | Likely Cause | Diagnostic Check |
|---------|-------------|------------------|
| product-concept.md not found after discovery | arn-spark-discover did not complete, or Vision directory misconfigured | Check `<vision-dir>/product-concept.md` exists |
| Stress test reports not in expected directory | Reports directory misconfigured, or stress test did not complete | Check `<reports-dir>/` for `stress-*-report.md` files |
| naming-brief.md incomplete (no Final Decision section) | Naming skill did not reach Step 4 (due diligence), or user exited early | Check `<vision-dir>/naming-brief.md` for "Final Decision" heading |
| Scaffold fails (npm/yarn install errors, framework init fails) | Missing Node.js, wrong version, network issues, or framework CLI not available | Run `node --version`, `npm --version`, check network |
| Playwright not available for prototyping | Playwright not installed or not in PATH | Run `npx playwright --version` |
| Visual sketch server won't start | Scaffold not completed, dev server config broken, or port conflict | Check scaffold output exists, dev server is runnable |
| Style brief not generated from visual direction | visual-direction.md missing in Vision directory, or style-explore did not complete | Check `<vision-dir>/visual-direction.md` exists |
| Static/clickable prototype build fails | Missing dependencies, scaffold incomplete, or style tokens not applied | Check `node_modules/` exists, scaffold files present |
| Feature extraction finds no upstream artifacts | No product concept, no use cases, no prototype validation reports | Check Vision, Use cases, Prototypes directories for expected files |
| Visual testing layer activation fails | Visual grounding directory missing or empty, visual strategy not run | Check `<visual-grounding-dir>/` exists and contains assets |
| Figma/Canva MCP not available | MCP server not configured for design tool integration | Check `.mcp.json` for design tool entries |
| Use case files not in expected format | Use cases written manually instead of via arn-spark-use-cases skill | Check `<use-cases-dir>/` for `UC-*.md` pattern |
| Prototype lock LOCKED.md missing | arn-spark-prototype-lock did not complete or Prototypes directory misconfigured | Check `<prototypes-dir>/LOCKED.md` exists |
| Brainstorming wizard can't detect resume point | Artifacts in unexpected locations, config directories changed after initial run | Check all configured directories match where artifacts were actually written |
| ensure-config fails to create Spark fields | CLAUDE.md not writable, or `## Arness` section has unexpected format | Check CLAUDE.md exists and is writable, check `## Arness` section format |

## Inter-Skill Data Flow

```
arn-spark-ensure-config
  outputs: ## Arness config in CLAUDE.md (Spark fields), directories created
  consumed by: all other Spark skills read ## Arness config

arn-spark-discover
  outputs: product-concept.md in <vision-dir>/
  consumed by: stress tests, concept-review, naming, arch-vision, use-cases,
               scaffold (reads product pillars), feature-extract

arn-spark-stress-interview
  outputs: stress-interview-report.md in <reports-dir>/
  consumed by: arn-spark-concept-review

arn-spark-stress-competitive
  outputs: stress-competitive-report.md in <reports-dir>/
  consumed by: arn-spark-concept-review

arn-spark-stress-premortem
  outputs: stress-premortem-report.md in <reports-dir>/
  consumed by: arn-spark-concept-review

arn-spark-stress-prfaq
  outputs: stress-prfaq-report.md in <reports-dir>/
  consumed by: arn-spark-concept-review

arn-spark-concept-review
  outputs: updated product-concept.md, concept-review-report.md in <reports-dir>/
  consumed by: downstream skills that read product-concept.md

arn-spark-naming
  outputs: naming-brief.md in <vision-dir>/, naming-report.md in <reports-dir>/
  consumed by: scaffold (project name), arch-vision (brand context)

arn-spark-arch-vision
  outputs: architecture-vision.md in <vision-dir>/
  consumed by: scaffold, spike, use-cases, feature-extract

arn-spark-use-cases / arn-spark-use-cases-teams
  outputs: UC-*.md files in <use-cases-dir>/
  consumed by: static-prototype, clickable-prototype, feature-extract

arn-spark-scaffold
  outputs: buildable project skeleton at <project-root>/
  consumed by: spike, visual-sketch, style-explore, static-prototype,
               clickable-prototype, dev-setup

arn-spark-spike
  outputs: spike results in <spikes-dir>/
  consumed by: visual-sketch (optional), feature-extract

arn-spark-visual-sketch
  outputs: visual-direction.md in <vision-dir>/, screenshots in <visual-grounding-dir>/
  consumed by: style-explore

arn-spark-style-explore
  outputs: style-brief.md in <vision-dir>/, style tokens in <visual-grounding-dir>/
  consumed by: static-prototype, clickable-prototype

arn-spark-static-prototype / arn-spark-static-prototype-teams
  outputs: prototype files in <prototypes-dir>/, validation reports in <reports-dir>/,
           screenshots in <visual-grounding-dir>/
  consumed by: clickable-prototype, prototype-lock, feature-extract

arn-spark-clickable-prototype / arn-spark-clickable-prototype-teams
  outputs: interactive prototype in <prototypes-dir>/, journey screenshots in
           <visual-grounding-dir>/, validation reports in <reports-dir>/
  consumed by: prototype-lock, feature-extract

arn-spark-prototype-lock
  outputs: locked/ directory in <prototypes-dir>/, LOCKED.md, git tag
  consumed by: development phase (read-only reference)

arn-spark-feature-extract
  outputs: feature-backlog.md in <reports-dir>/, optional issue tracker uploads
  consumed by: arn-code-feature-spec (bridges into Arness Code pipeline)

arn-brainstorming (entry point)
  inputs: detects current pipeline state from artifacts on disk
  outputs: drives discover → ... → feature-extract
  consumed by: user (full greenfield workflow)
```

## Version History

### 1.0.0
- Initial release: 19 skills + 13 agents for the greenfield exploration pipeline
- Includes discover, arch-vision, use-cases, scaffold, spike, visual-sketch, style-explore, static-prototype, clickable-prototype, prototype-lock, feature-extract, dev-setup, visual-strategy, visual-readiness
- Brainstorming wizard for guided pipeline traversal
- Renamed from nova-green-* to arn-spark-* prefix

### 1.1.0
- AI-assisted discovery enrichment: product-concept sections, market-researcher + persona-architect agents
- Stress testing suite: stress-interview, stress-competitive, stress-premortem, stress-prfaq
- Concept review skill for synthesizing stress test findings
- Brand naming skill with 4-step methodology, brand-strategist agent, WHOIS scripts

### 2.0.0
- Nova to Arness rebrand: all skills/agents renamed from nova-green-*/nova-spark-* to arn-spark-*
- Directory convention changed from .nova/ to .arness/
- Config section changed from ## Nova to ## Arness

### 2.1.0
- Progressive zero-config init: arn-spark-ensure-config for automatic setup
- Deferred pattern docs, welcome/profile flow
- Teams variants for use cases, static prototype, and clickable prototype

## Version Information

- Plugin version is in `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json` (field: `version`)
- Skill versions are in each SKILL.md frontmatter (field: `version`)
