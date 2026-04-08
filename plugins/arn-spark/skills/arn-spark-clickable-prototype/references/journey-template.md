# User Journey Template

Use this template to define user journeys for the clickable prototype validation. Each journey describes a sequence of interactions a user would perform to accomplish a goal.

```markdown
## Journey: [Name]

**Goal:** [What the user is trying to accomplish]
**Starting point:** [Where the journey begins, e.g., "Home screen", "/settings"]

### Steps

| # | Action | Target | Expected Outcome |
|---|--------|--------|-----------------|
| 1 | Navigate | [URL or screen name] | [Page loads with expected content] |
| 2 | Click | [Button/link text or description] | [What should happen: navigation, modal opens, state changes] |
| 3 | Fill | [Input field name/label] | [Input accepts text, validation feedback if applicable] |
| 4 | Select | [Dropdown/option description] | [Option is selected, dependent UI updates] |
| 5 | Click | [Submit/confirm button] | [Action completes, success state shown] |

### Expected End State
[What the screen should look like when the journey is complete]
```

## Example Journeys

### Journey: Device Pairing

**Goal:** Connect a new device to the local network
**Starting point:** Home screen

| # | Action | Target | Expected Outcome |
|---|--------|--------|-----------------|
| 1 | Navigate | / | Home screen with device list |
| 2 | Click | "Add Device" button | Pairing modal or screen opens |
| 3 | Wait | Device list | Available devices appear |
| 4 | Click | Device name in list | Device selected, confirmation shown |
| 5 | Click | "Connect" button | Connection established, device appears in main list |

**Expected End State:** Home screen shows the newly paired device in the device list with "Connected" status.

### Journey: Settings Navigation

**Goal:** Navigate through all settings sections
**Starting point:** Home screen

| # | Action | Target | Expected Outcome |
|---|--------|--------|-----------------|
| 1 | Click | Settings icon/button | Settings screen opens |
| 2 | Click | "Audio" settings section | Audio settings displayed |
| 3 | Click | "Video" settings section | Video settings displayed |
| 4 | Click | "Network" settings section | Network settings displayed |
| 5 | Click | Back/close button | Returns to home screen |

**Expected End State:** Home screen displayed, no errors.

## Notes

- Keep journeys focused on one goal each. A journey with 10+ steps should probably be split.
- Journeys should use the same vocabulary as the prototype's UI (button labels, section names).
- The `arn-spark-clickable-prototype` skill derives initial journeys from the product concept and screen list. The user refines them.
- The `arn-spark-ui-interactor` agent translates these journeys into Playwright scripts.
