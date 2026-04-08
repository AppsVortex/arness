# Architecture Vision Template

This template defines the structure for architecture vision documents written by the `arn-spark-arch-vision` skill. The document is saved to the project's vision directory as `architecture-vision.md`.

An architecture vision captures the HOW at a high level: technology stack, system design, protocols, platform integration, packaging, and known risks. It does not contain implementation details like code structure, file organization, or specific APIs -- that is the plan's job.

## Instructions for arn-spark-arch-vision

When populating this template:

- Every section below MUST appear in the output, even if the content is brief
- Replace all bracketed placeholders with concrete content from the architecture exploration conversation
- The Technology Stack table should include every architectural layer discussed, with rationale for each choice
- The High-Level Architecture diagram should be ASCII art showing major components and their relationships
- Adapt section names to match the product domain (e.g., "Network Protocols" for a P2P app, "API Design" for a web service)
- Pillar Alignment must reference the product concept's Product Pillars section. If no pillars exist, omit this section. Every pillar must be assessed — do not skip pillars that are hard to evaluate
- Known Risks must include specific mitigations, not just "we'll figure it out"
- Future Architecture Considerations should map to the product concept's "Future Considerations" and explain what would change architecturally

---

## Template

```markdown
# [Product Name] - Architecture Vision

## Technology Stack

| Layer | Technology | Rationale |
|-------|-----------|-----------|
| [layer name] | **[technology]** | [Why this was chosen over alternatives. Reference specific project requirements.] |

## Business Constraints & Trade-offs

[How the technology stack addresses identified business constraints. Cost implications at stated scale, compliance alignment, tenancy support, vendor dependencies, and licensing. Omit this section if no business constraints were captured in the product concept.]

| Constraint | How Stack Addresses It | Risk or Trade-off |
|-----------|----------------------|-------------------|
| [e.g., Multi-tenant, 500 clients] | [e.g., PostgreSQL with schema-per-tenant via pg_schema; PgBouncer for connection pooling] | [e.g., Operational complexity increases with tenant count; schema migrations must be tenant-aware] |
| [e.g., HIPAA compliance] | [e.g., AWS with BAA, RDS encryption at rest, CloudTrail audit logging] | [e.g., Limits provider choices to AWS/GCP/Azure with BAA] |
| [e.g., Budget: $500/mo] | [e.g., Self-hosted on single VPS with tenant density optimization] | [e.g., Scaling beyond 200 tenants requires infrastructure upgrade] |

[Remove example rows. Only include constraints from the product concept's Business Constraints section.]

## Pillar Alignment

[For each product pillar from the product concept, assess how the chosen technology stack serves it. This section ensures that non-negotiable product qualities were not compromised by technology decisions.]

| Pillar | Status | How the Stack Serves It |
|--------|--------|------------------------|
| [Pillar name] | Supported / At Risk / Mitigated | [Specific explanation: which technologies serve this pillar and how. If at risk, explain why and what mitigation exists.] |

[If any pillar is "At Risk," elaborate on the specific concern and what can be done — e.g., a spike to validate, a configuration change, or an alternative technology to evaluate. A technology stack that conflicts with a product pillar should be reconsidered unless the conflict is acknowledged and accepted by the user.]

## High-Level Architecture

[ASCII component diagram showing major components, their groupings, and relationships. Use box drawing characters for clarity. Show the boundary between backend/native and frontend/UI layers if applicable.]

### [Backend / Native Layer Name]

[What runs at the native/system level. List responsibilities as bullets. Describe each major component briefly.]

### [Frontend / UI Layer Name]

[What the user sees and interacts with. List responsibilities as bullets. Describe each major component briefly.]

### Communication Between Layers

[How the backend and frontend communicate. IPC mechanism, event system, API pattern. Brief description of data flow direction.]

## [Protocols / Communication Design]

[For each protocol or communication mechanism used by the product:]

### [Protocol / Mechanism Name]

[Service definition, message types, data format. How devices/users discover each other, how connections are established, what data flows over each channel. Include protocol-specific details like ports, service types, message schemas.]

[Repeat for each protocol]

## [Identity / Security Architecture]

### Identity

[How entities (users, devices) are identified. What cryptographic primitives are used. Where identity information is stored.]

### [Trust Establishment]

[How trust is established between entities. The pairing/authentication flow at a technical level.]

### [Entity] States

[State machine for the primary entity. List states and what each means for the system's behavior.]

## [Platform Integration / Device Management]

### [Capability] Selection & Persistence

[How platform resources (audio devices, cameras, etc.) are enumerated, selected, and remembered across sessions.]

### Hot-Plug Handling

[How the system handles devices being connected/disconnected during operation. Fallback behavior, notification strategy, auto-recovery.]

## Packaging & Distribution

### [Platform 1]

[Installer type, signing requirements, platform-specific setup (firewall rules, permissions), build environment requirements.]

### [Platform 2]

[Same structure for each target platform.]

### Storage Locations

[Where application data is stored on each platform. Config files, cached data, logs.]

## Known Risks & Mitigations

[For each identified risk:]

### [Risk Name]

[Description of the risk. What could go wrong and what impact it would have.]

**Mitigation:** [Specific strategy to address or reduce the risk.]

**Fallback:** [What to do if the mitigation is insufficient. Alternative approach.]

## Future Architecture Considerations

[For each item in the product concept's "Future Considerations," briefly describe what architectural changes would be needed. This ensures v1's architecture does not accidentally block future work.]

- **[Future feature]:** [What would change architecturally. What v1 decisions accommodate or constrain this.]
```

---

## Section Guidance

| Section | Source | Depth |
|---------|--------|-------|
| Technology Stack | arn-spark-tech-evaluator recommendations + user decisions | Table covering every layer, 1-sentence rationale each |
| Business Constraints & Trade-offs | Business Constraints section of product concept | Table mapping each constraint to stack support + risk. Concrete numbers (cost at scale, connection limits, tenant capacity). Omit if no business constraints captured. |
| Pillar Alignment | Product concept pillars + stack decisions | Table with one row per pillar, status + explanation |
| High-Level Architecture | Conversation synthesis | ASCII diagram + 2-3 subsections with bullet lists |
| Protocols / Communication | arn-spark-tech-evaluator analysis + conversation | 1 subsection per protocol, technical but not implementation-level |
| Identity / Security | Conversation exploration of trust model | Identity primitives, trust flow, state machine |
| Platform Integration | Conversation exploration of platform concerns | Device management, hot-plug, OS-specific behavior |
| Packaging & Distribution | arn-spark-tech-evaluator research + conversation | 1 subsection per platform, installer + signing + permissions |
| Known Risks & Mitigations | arn-spark-tech-evaluator validation points + conversation | Each risk: description + mitigation + fallback |
| Future Architecture Considerations | Product concept's "Future Considerations" | Bullet list mapping each future item to architectural impact |
