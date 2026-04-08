# Feature Entry Template

This template defines the structure for individual feature files written by the `arn-spark-feature-extract` skill. Each feature is saved as a separate file (`F-NNN-kebab-name.md`) in the `features/` directory under the project's Vision directory.

A feature entry captures lean context -- description, journey summary, UI behavior unique to the feature, validated components, use case references, debate insights, technical notes, and acceptance criteria -- with references to upstream UC documents. `arn-code-feature-spec` expands these references at spec time by reading the referenced UC documents directly, so feature files avoid duplicating UC content.

## Instructions for arn-spark-feature-extract

When populating this template for each feature:

- Extract the feature from ALL available artifacts: product concept, architecture vision, style brief, spike results, static prototype results (including showcase), clickable prototype results (including showcase and screen manifest), use cases (including postconditions and business rules), user journey definitions, debate reports (from teams variants), and visual grounding assets
- Each feature should be a user-facing capability, not a technical task (e.g., "Voice communication between paired devices" not "Implement WebRTC peer connection")
- **Journey summary, UI behavior, and components are mandatory fields** -- journey summary captures the user flow briefly with UC references; UI behavior describes only interactions unique to this feature (not already described in the UC); components list the validated building blocks
- Priority must be justified -- not every feature is must-have
- Complexity estimates are relative within the project (S/M/L/XL) and based on the architecture vision's stack
- The "Source" field tracks where the feature was identified, for traceability
- Features marked "Ready for spec: Yes" must have description, journey summary (with UC references), UI behavior, and components filled in with enough detail for `arn-code-feature-spec` to start (it will read the referenced UC documents for full behavioral detail)
- XL features should be flagged for decomposition -- either split into separate backlog features, or if the UX specialist determines it is one coherent user-facing capability, kept whole with a `## Decomposition Hints` section providing suggested sub-feature boundaries for `arn-code-feature-spec` to decompose at spec time
- When use cases exist, reference them with step ranges and BR identifiers -- do not inline postconditions or business rules verbatim (arn-code-feature-spec reads the UC documents directly at spec time)

---

## Template

```markdown
# F-[NNN]: [Feature Name]

**Priority:** [Must-have / Should-have / Nice-to-have]
**Complexity:** [S / M / L / XL]
**Phase:** [Foundation / Core / Enhancement / Polish]
**Dependencies:** [F-NNN, F-NNN / None]
**Status:** pending

## Description

[2-4 sentences describing what the feature does from the user's perspective. What can the user do that they could not do before? What problem does it solve?]

## Journey Steps

[Brief summary of the user journey this feature covers (2-3 sentences), with references to UC documents for full step-by-step detail:]

**Journey: [Journey Name]**
[2-3 sentence summary of what happens in this journey segment. E.g., "User discovers peers via mDNS, selects one, sends a pairing request, and upon acceptance exchanges Ed25519 identities to establish a permanent pairing."]
**UC references:** UC-NNN steps N-M, UC-NNN

[If the feature spans multiple journeys, list each with a brief summary and UC references. If no UC exists for this feature, provide 3-5 inline step descriptions instead.]

## UI Behavior

[Describe only the UI interactions and visual details that are unique to this feature and NOT already described in the referenced UC documents. Focus on:]

- [Prototype-specific details: animations, transitions, visual effects not in the UC]
- [Component-level interactions: how specific UI components behave (hover states, expand/collapse, etc.)]
- [Feedback mechanisms: sounds, haptic, toast notifications, loading states]
- [Edge case UI states: empty states, error states, disabled states]
- [Layout and positioning details from the prototype that the UC does not specify]

[If the UC's Main Success Scenario already describes the core flow, do not rewrite it here. Reference it: "Core flow follows UC-NNN steps N-M. Additional UI details:"]

## Components

[Validated UI components this feature uses, split by tier:]

- **Library:** [Component name] ([variants]) -- [static showcase reference]. E.g., "Button (primary, secondary) -- static showcase v3 section 3"
- **Library:** [Component name] ([variants]) -- [static showcase reference]
- **Product-specific:** [Component name] -- [clickable screen reference]. E.g., "DeviceListItem -- clickable v2 screen 04-main-dashboard"

[If no prototypes exist: "None -- no validated components available"]

## Animation

[Animation behaviors for this feature, described in platform-agnostic intent language. Reference the style brief's Animation and Motion section for the motion design system.]

- [e.g., "Scroll-triggered card stagger entrance, 0.15s delay between cards — validated in clickable v2 screen 03"]
- [e.g., "State transition: status change fades between states over 200ms ease-in-out"]
- [Or "None — this feature has no animation requirements"]

**Core or decorative:** [Is animation core to this feature's UX (removing it degrades the experience) or purely decorative (removing it has no functional impact)?]

[If no style brief Animation section exists: omit this section entirely.]

## Priority Rationale

[Why this priority. Must-haves: core experience collapses without it. Should-haves: significantly improves the experience. Nice-to-haves: polish or convenience.]

## Complexity Notes

[Brief explanation of what drives the complexity. E.g., "M -- straightforward UI but requires mDNS integration" or "L -- multiple screens with real-time state updates across peers"]

## Technical Notes

[Relevant technical context from architecture vision and spike results. E.g., "WebRTC getUserMedia validated in spike-001. Uses mDNS for discovery (validated). Requires Ed25519 keypair for identity." Or "Spike-003 showed WKWebView has limited Notification API -- use Tauri notification plugin instead."]

## Source

[Which artifact(s) this was extracted from: product-concept, architecture-vision, spike-results, prototype screen name, journey name, use-case UC-NNN, user input]

## References

**Prototype:** [Which prototype screens show this feature. E.g., "Clickable prototype v3: screens /pairing, /pairing/confirm. Journey screenshots: prototypes/clickable/v3/journeys/device-pairing/"]
**Showcase:** [Which showcase sections show this feature's screens/components. E.g., "Static showcase v3: sections 3 (Buttons), 5 (Inputs). Clickable showcase v2: screens 01-hub, 04-main-dashboard." Or "None"]
**Visual target:** [Implementation precision for this feature's visual appearance:]
- `Design assets` -- design mockups exist in visual grounding `designs/` matching this feature's screens. Implementation should aim for pixel-level fidelity.
- `Reference alignment` -- reference images exist in visual grounding `references/` setting the direction. Implementation should match the feel, not pixel-perfect.
- `Style brief only` -- no visual grounding assets for this feature. Implementation follows style brief text specifications.

## Debate Insights

[Key expert findings from debate reports (static-prototype-teams, clickable-prototype-teams, use-cases-teams) relevant to this feature. E.g., "UX specialist noted pairing flow needs inline error messages (round-2 cross-review). Business reviewer agreed and added: must show device name in error context." Or "None"]

## Use Case Context

**References:** [UC-IDs this feature implements, with relationship and step ranges. E.g., "Implements UC-001 Device Pairing (steps 1-6). Includes UC-005 Device Discovery." Or "None"]
**Postconditions:** See UC-NNN Postconditions [or "None" if no use cases exist]
**Business rules:** See UC-NNN Business Rules (BR-1 through BR-N) [or "None" if no use cases exist]

[If the feature adds business rules BEYOND what the UC defines, inline only those additional rules here:]
- [BR-N+1: Additional rule not in the UC. E.g., "Portal materialization animation must complete before audio pipeline starts."]

## Acceptance Criteria

[3-5 testable conditions that define when this feature is complete. Derived from journey steps, prototype behavior, and use case postconditions.]

- [ ] [Criterion 1 -- e.g., "User can see available devices within 3 seconds of opening the pairing screen"]
- [ ] [Criterion 2 -- e.g., "Selected device shows confirmation dialog before connecting"]
- [ ] [Criterion 3 -- e.g., "Connected device appears in the main device list with status indicator"]

## Decomposition Hints

[Only for XL features kept whole in the backlog. Omit this section entirely for S/M/L features.]

[When the UX specialist or user decides an XL feature should stay as one coherent user-facing capability (not split into separate backlog features), provide decomposition hints so `arn-code-feature-spec` can split it into implementation sub-features at spec time.]

**Suggested sub-features:**

1. **[Sub-feature name]** -- [1 sentence describing the implementation slice]
   - Journey segment: [which UC steps this covers]
   - Key components: [which components from the Components section apply]

2. **[Sub-feature name]** -- [1 sentence]
   - Journey segment: [steps]
   - Key components: [components]

3. **[Sub-feature name]** -- [1 sentence]
   - Journey segment: [steps]
   - Key components: [components]

**Split rationale:** [Why this decomposition. E.g., "Each sub-feature targets a distinct technical domain (audio, signaling, UI) while the user experience is one coherent capability."]

**Dependencies between sub-features:** [E.g., "Sub-feature 1 (audio pipeline) must complete before sub-feature 3 (UI integration) can start. Sub-feature 2 (signaling) is independent."]

## Spec Readiness

**Ready for spec:** [Yes / No]

[If No, note what is missing.]
```

---

## Priority Definitions

| Priority | Definition | Test |
|----------|-----------|------|
| Must-have | The core experience cannot function without this feature | If removed, does the product still deliver its primary value? If not, it is must-have. |
| Should-have | The experience is significantly degraded without this feature | Users would notice and be frustrated by its absence, but the product still works. |
| Nice-to-have | Adds polish, convenience, or secondary value | The product is complete without it; this makes it better. |

## Complexity Definitions

| Size | Scope | Typical characteristics |
|------|-------|----------------------|
| S | Single component or minor change | One file or a few lines in 2-3 files. Clear implementation path. No new dependencies. Consider merging into a parent feature if too thin. |
| M | Feature within a single domain | Multiple files in one area. May require a new dependency or integration point. Maps to 1-2 journey segments. |
| L | Feature spanning multiple domains | Touches multiple parts of the stack (UI + backend, or multiple services). Requires design decisions. Maps to a full journey. |
| XL | Major feature or infrastructure | New subsystem, complex protocol implementation, or architectural change. **Should be decomposed** into smaller features before speccing, OR kept whole with `## Decomposition Hints` if the UX specialist determines it is one coherent user-facing capability -- `arn-code-feature-spec` decomposes at spec time. Maps to multiple journeys. |

## Spec Readiness Criteria

A feature is **ready for spec** when ALL of the following are true:

1. **Description** is 2-4 sentences covering what the user can do
2. **Journey steps** include at least one journey with actual step descriptions
3. **UI behavior** describes the key interactions with transition details and feedback
4. **Components** lists the validated library and product-specific components used
5. **Technical notes** capture any relevant spike results, validated capabilities, or known limitations
6. **Acceptance criteria** list 3-5 testable conditions
7. **Use case references** are listed with step ranges if use cases exist (arn-code-feature-spec reads UC documents at spec time)
8. **Complexity** is not XL, OR if XL, a `## Decomposition Hints` section is present with at least 2 suggested sub-features (`arn-code-feature-spec` decomposes at spec time)
9. **Animation** (if style brief has Animation and Motion section) describes the feature's animation behaviors in platform-agnostic intent language, with core/decorative classification

If any of these are missing, mark "Ready for spec: No" and note what is needed.

## UI Behavior Writing Guide

The UI behavior field should describe only the interactions and visual details that are **unique to this feature** and not already covered by the referenced UC documents. The UC's Main Success Scenario and Extensions describe the core user flow -- do not rewrite them here.

Focus on:

- **Prototype-specific details:** Animations, transitions, visual effects that the UC text does not describe
- **Component interactions:** How specific UI components behave (hover states, expand/collapse, inline editing)
- **Feedback mechanisms:** Sounds, haptic, toast notifications, loading indicators
- **Edge case UI states:** Empty states, disabled states, error display styles
- **Layout and positioning:** Where elements appear on screen, how they stack or overlay

If the UC already describes the core flow well, reference it and add only the unique UI layer:

Example:
> Core flow follows UC-002 steps 1-10. Additional UI details: Scanning indicator animates while mDNS discovery runs. Discovered devices appear in real-time as PairingCard entries. Portal materialization: fade-in with frosted-glass appearance, brief pulse, settles into ambient state.
