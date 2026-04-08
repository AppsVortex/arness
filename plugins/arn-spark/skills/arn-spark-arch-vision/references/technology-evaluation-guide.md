# Technology Evaluation Guide

Framework for evaluating technology choices in greenfield projects. Used by the `arn-spark-arch-vision` skill and `arn-spark-tech-evaluator` agent to ensure consistent, requirements-driven evaluation.

## Evaluation Criteria Categories

When evaluating technologies, draw criteria from these categories. Not all categories apply to every evaluation -- select those relevant to the project's requirements.

### Core Criteria (almost always relevant)

- **Platform support:** Does it run on all target platforms? Native support or workarounds needed?
- **Maturity:** How long has it been production-ready? Stable API? Predictable release cadence?
- **Maintenance:** Active development? Responsive to issues? Backed by a company or strong community?
- **Documentation:** Quality of official docs? Tutorials, examples, migration guides available?
- **Community:** Size and activity of the community? Stack Overflow presence? Discord/forum activity?

### Project-Specific Criteria (select based on requirements)

- **Real-time capability:** Latency characteristics, streaming support, P2P capability
- **Performance:** Startup time, memory usage, CPU overhead, bundle/install size
- **Security:** Built-in security features, encryption support, vulnerability track record
- **Cross-platform consistency:** Same behavior across platforms? Platform-specific quirks?
- **Integration:** How well does it work with other chosen technologies? Known compatibility issues?
- **Learning curve:** Complexity for the team? Familiarity with the paradigm?
- **Licensing:** Open source? Permissive or copyleft? Commercial use restrictions?
- **Extensibility:** Plugin ecosystem? Easy to customize or extend?

## Comparison Matrix Format

For each decision point, build a comparison table:

```
| Criteria | [Tech A] | [Tech B] | [Tech C] |
|----------|----------|----------|----------|
| [Requirement 1] * | Strong | Adequate | Weak |
| [Requirement 2] | Adequate | Strong | Strong |
| [Requirement 3] * | Strong | Strong | Weak |

* = Critical requirement (Weak rating here is a deal-breaker)
```

### Rating Definitions

- **Strong:** Fully meets the requirement with minimal effort. Well-documented, battle-tested for this use case.
- **Adequate:** Meets the requirement but with caveats. May need extra configuration, workarounds, or has minor limitations.
- **Weak:** Does not meet the requirement, or meeting it requires significant effort, workarounds, or unproven approaches.
- **N/A:** Criteria does not apply to this technology.

### Guidelines

- Derive criteria rows from the project's actual requirements, not generic benchmarks
- Mark critical requirements with an asterisk -- a "Weak" on a critical requirement is a deal-breaker
- Include evidence for each rating (1-2 sentences). Avoid bare ratings without explanation.
- If a rating is uncertain, note it: "Adequate (needs validation)" or "Strong (based on docs, not verified)"

## Validation Point Categories

After recommending technologies, categorize what must be validated:

### Critical (validate before writing any production code)

Items where failure would require changing the technology choice entirely. Examples:
- "WebRTC getUserMedia works in Tauri's macOS WKWebView"
- "mDNS multicast is not blocked by default Windows Firewall"

### Important (validate in the first sprint)

Items where failure would require workarounds but not a technology change. Examples:
- "Svelte transitions perform smoothly on older hardware"
- "WebSocket reconnection handles network flapping gracefully"

### Monitor (keep an eye on during development)

Items that are low-risk but worth tracking. Examples:
- "Bundle size stays under target as dependencies are added"
- "Build times remain reasonable as codebase grows"

## Stack Cohesion Assessment

When recommending a full stack, assess how well the technologies work together:

- **Integration patterns:** Are there established patterns for combining these technologies? (e.g., "Tauri + Svelte has official template support")
- **Community examples:** Are there real projects using this combination? Can we reference them?
- **Build tooling:** Do the build tools play well together? Any conflicting requirements?
- **Dependency overlap:** Do the technologies share dependencies that could cause version conflicts?
- **Knowledge transfer:** If a developer knows one part of the stack, does that help with other parts?
