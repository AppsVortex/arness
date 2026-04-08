# Journey Schema Reference

This document defines the platform-agnostic journey definition format used for Layer 2 journey-based interaction testing. It is the canonical reference for all skills and agents that create, validate, or execute journey definitions.

## Journey Definition Schema

A journey is a sequence of steps that model a user interaction flow. Each step has a `type` field that determines the required and optional fields.

### Step Types

| Type | Required Fields | Optional Fields | Description |
|------|----------------|-----------------|-------------|
| `capture` | `name` | `delay` | Takes a screenshot at a checkpoint. The `name` field becomes the screenshot filename and is used for cross-layer matching. |
| `invoke` | `target` | `delay` | Clicks or activates a UI element. The `target` field is a selector object (see Element Selector Format). |
| `setValue` | `target`, `value` | `delay` | Sets a value on an input element. The `target` field is a selector object and `value` is the string to enter. |
| `settle` | _(none)_ | `timeout`, `condition` | Waits for the UI to stabilize before proceeding. Default timeout is 5000ms. The optional `condition` field describes what "settled" means (e.g., "loading spinner disappears"). |

### Field Definitions

- **`name`** (string) -- Unique identifier for the capture step within its journey. Used as the screenshot filename and for cross-layer screen matching.
- **`target`** (object) -- Selector object identifying the UI element to interact with. See Element Selector Format below.
- **`value`** (string) -- The text or value to set on the target element.
- **`delay`** (number) -- Milliseconds to wait before executing the step. Default: 0.
- **`timeout`** (number) -- Maximum milliseconds to wait for the settle condition. Default: 5000.
- **`condition`** (string) -- Human-readable description of what "settled" means. Used by the runner to determine the appropriate wait strategy.

### Example: Login Flow Journey

```json
{
  "name": "login-flow",
  "description": "Navigates to login screen, enters credentials, submits, and captures the resulting dashboard",
  "preconditions": [
    "Application is running and showing the main window",
    "No user is currently logged in"
  ],
  "steps": [
    {
      "type": "capture",
      "name": "login-screen"
    },
    {
      "type": "setValue",
      "target": { "automationId": "usernameInput", "controlType": "textBox" },
      "value": "testuser@example.com"
    },
    {
      "type": "setValue",
      "target": { "automationId": "passwordInput", "controlType": "textBox" },
      "value": "test-password-123"
    },
    {
      "type": "invoke",
      "target": { "automationId": "loginButton", "controlType": "button" },
      "delay": 200
    },
    {
      "type": "settle",
      "timeout": 10000,
      "condition": "Loading spinner disappears and dashboard content is visible"
    },
    {
      "type": "capture",
      "name": "dashboard-after-login"
    }
  ]
}
```

## Element Selector Format

A selector object identifies a UI element in the application's accessibility tree. Selectors are platform-agnostic -- the platform runner translates them into native API calls.

### Selector Properties

| Property | Type | Description |
|----------|------|-------------|
| `automationId` | string | The element's automation ID (highest priority). Maps to `AutomationId` on Windows UIA and `identifier` on macOS NSAccessibility. |
| `controlType` | string | The logical control type (e.g., `button`, `textBox`, `menuItem`). Maps to platform-specific control type enumerations. See the Element Mapping Table below. |
| `name` | string | The element's accessible name (fallback). Maps to `Name` on Windows UIA and `AXTitle` or `AXDescription` on macOS NSAccessibility. |

### Resolution Order

The platform runner resolves selectors in the following priority order:

1. **Custom mappings lookup** -- If the `target` value is a string (logical name), the runner looks it up in the `customMappings` section of the journey manifest. This returns a platform-specific selector with full native properties.
2. **Direct `automationId`** -- If the selector has an `automationId` field, the runner searches the accessibility tree for an element with that automation ID. This is the most reliable cross-platform identifier.
3. **`controlType` + `name` combination** -- If `automationId` is absent or resolution fails, the runner searches for an element matching both the `controlType` (mapped to the platform's native type) and the `name` (accessible name). This is the fallback strategy.

If all resolution strategies fail, the runner reports a `SELECTOR_NOT_FOUND` error for the step.

## Custom Mappings

The `customMappings` section in the journey manifest maps logical component names to platform-specific selectors. This bridges the gap between the journey's platform-agnostic step definitions and the actual accessibility tree of the implementation.

### Structure

```json
{
  "customMappings": {
    "main-navigation": {
      "windows": {
        "automationId": "NavHost",
        "controlType": "Pane",
        "className": "NavigationView"
      },
      "macos": {
        "role": "AXGroup",
        "subrole": "AXNavigationBar",
        "identifier": "MainNavigation"
      }
    },
    "data-table": {
      "windows": {
        "automationId": "MainDataGrid",
        "controlType": "DataGrid",
        "className": "DataGridView"
      },
      "macos": {
        "role": "AXTable",
        "subrole": "",
        "identifier": "MainDataGrid"
      }
    }
  }
}
```

### When to Use Custom Mappings

Custom mappings are needed when standard selectors (automationId, controlType, name) are insufficient:

- **Complex or non-standard components** -- Data grids, chart widgets, custom-drawn controls, and composite components that expose non-obvious accessibility trees.
- **Platform-divergent accessibility trees** -- Components whose accessibility structure differs significantly between Windows UIA and macOS NSAccessibility (e.g., a navigation rail that is a `Pane` on Windows but an `AXGroup` on macOS).
- **Components with unreliable `automationId`** -- Controls generated by frameworks that assign dynamic or unstable automation IDs.
- **Deeply nested elements** -- Components where the target element is several levels deep in the accessibility tree and requires class name or subrole disambiguation.

**Note:** `arn-spark-visual-test-engineer` populates custom mappings automatically by scanning the actual implementation's accessibility tree during the spike phase. Manual editing is only needed for fine-tuning.

### Platform-Specific Properties

**Windows (UIA):**
- `automationId` -- Maps to `AutomationElement.Current.AutomationId`
- `controlType` -- Maps to `ControlType.ControlTypeId` (e.g., `DataGrid`, `Pane`)
- `className` -- Maps to `AutomationElement.Current.ClassName` (disambiguation)

**macOS (NSAccessibility):**
- `role` -- Maps to `AXRole` (e.g., `AXTable`, `AXGroup`, `AXButton`)
- `subrole` -- Maps to `AXSubrole` (e.g., `AXNavigationBar`, `AXSortButton`)
- `identifier` -- Maps to `AXIdentifier` (accessibility identifier set by the developer)

## UIA / NSAccessibility Element Mapping Table

This table maps logical control types used in journey step selectors to their platform-native equivalents.

| Logical Type | Windows UIA ControlType | Windows UIA Class | macOS NSAccessibility Role | macOS NSAccessibility Subrole |
|-------------|------------------------|-------------------|---------------------------|------------------------------|
| `button` | `Button` | `Button` | `AXButton` | -- |
| `textBox` | `Edit` | `TextBox`, `TextEdit` | `AXTextField` | -- |
| `checkBox` | `CheckBox` | `CheckBox` | `AXCheckBox` | -- |
| `radioButton` | `RadioButton` | `RadioButton` | `AXRadioButton` | -- |
| `comboBox` | `ComboBox` | `ComboBox` | `AXPopUpButton` | -- |
| `listItem` | `ListItem` | `ListBoxItem` | `AXCell` | `AXOutlineRow` |
| `menuItem` | `MenuItem` | `MenuItem` | `AXMenuItem` | -- |
| `tab` | `TabItem` | `TabItem` | `AXRadioButton` | `AXTabButton` |
| `treeItem` | `TreeItem` | `TreeViewItem` | `AXRow` | `AXOutlineRow` |
| `slider` | `Slider` | `Slider` | `AXSlider` | -- |
| `progressBar` | `ProgressBar` | `ProgressBar` | `AXProgressIndicator` | -- |
| `dataGrid` | `DataGrid` | `DataGridView` | `AXTable` | -- |
| `link` | `Hyperlink` | `Hyperlink` | `AXLink` | -- |
| `image` | `Image` | `Image` | `AXImage` | -- |
| `window` | `Window` | `Window` | `AXWindow` | `AXStandardWindow` |
| `scrollBar` | `ScrollBar` | `ScrollBar` | `AXScrollBar` | -- |
| `toolBar` | `ToolBar` | `ToolBar` | `AXToolbar` | -- |
| `statusBar` | `StatusBar` | `StatusBar` | `AXGroup` | `AXStatusBar` |
| `dialog` | `Window` | `Dialog` | `AXSheet` | `AXDialog` |
| `label` | `Text` | `TextBlock` | `AXStaticText` | -- |

## Platform Runner Contract

Every platform runner must implement the following interface. Runners are platform-specific executables or scripts that consume the platform-agnostic journey manifest and interact with the native accessibility APIs.

### Required Interface

| Method | Arguments | Returns | Description |
|--------|-----------|---------|-------------|
| `Load(manifestPath)` | Path to `journey-manifest.json` | Parsed manifest object | Reads and validates the journey manifest. Fails if the schema version is unsupported or the JSON is malformed. |
| `Resolve(selector, platform)` | Selector object, platform identifier (`windows` or `macos`) | Native element reference | Finds the UI element using the selector resolution order: custom mappings first, then `automationId`, then `controlType` + `name`. Returns `null` if not found. |
| `Execute(step, resolvedElement)` | Step object, resolved native element | Step result (pass/fail) | Performs the step action on the resolved element. For `invoke`: activates/clicks. For `setValue`: sets the text/value. For `settle`: waits until timeout or condition met. For `capture`: delegates to `Capture()`. |
| `Capture(name, outputDir)` | Screenshot name, output directory path | File path of saved screenshot | Takes a screenshot of the application window and saves it as `{outputDir}/{name}.png`. |
| `Report(results)` | Array of step results | Execution summary | Outputs the full execution results: pass/fail per step, screenshots captured with paths, errors with messages and selectors, total duration. |

### Platform-Specific Notes

**Windows: PowerShell + System.Windows.Automation**

```powershell
# Load the UIA assembly
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

# Element resolution using PropertyCondition
$condition = New-Object System.Windows.Automation.PropertyCondition(
    [System.Windows.Automation.AutomationElement]::AutomationIdProperty,
    "loginButton"
)
$element = $rootElement.FindFirst(
    [System.Windows.Automation.TreeScope]::Descendants,
    $condition
)

# Invoke action using InvokePattern
$invokePattern = $element.GetCurrentPattern(
    [System.Windows.Automation.InvokePattern]::Pattern
)
$invokePattern.Invoke()

# SetValue action using ValuePattern
$valuePattern = $element.GetCurrentPattern(
    [System.Windows.Automation.ValuePattern]::Pattern
)
$valuePattern.SetValue("testuser@example.com")
```

**macOS: AppleScript/Swift + NSAccessibility**

```applescript
-- Element resolution using accessibility identifier
tell application "System Events"
    tell process "MyApp"
        set targetElement to first text field whose value of attribute "AXIdentifier" is "usernameInput"
    end tell
end tell

-- Invoke action (AXPress)
tell application "System Events"
    tell process "MyApp"
        click button "Login" of window 1
    end tell
end tell

-- SetValue action (AXValue)
tell application "System Events"
    tell process "MyApp"
        set value of text field "usernameInput" of window 1 to "testuser@example.com"
    end tell
end tell
```

For programmatic access, use `osascript -e '...'` to execute AppleScript from shell scripts, or use Swift with the `AXUIElement` API for more complex resolution logic.

### Dry-Run Mode

Every platform runner must support a `--dry-run` flag that validates the journey without executing actions:

1. **Load** -- Parse the manifest (same as normal mode)
2. **Resolve** -- Attempt to find every element referenced in all journey steps. Report which selectors resolved and which failed.
3. **Skip Execute** -- Do not perform any invoke, setValue, or settle actions
4. **Skip Capture** -- Do not take screenshots
5. **Report** -- Output a validation summary: total selectors, resolved count, failed count, failed selector details

Dry-run mode is used during the spike phase to validate that the journey manifest's selectors match the actual application's accessibility tree before committing to a full execution run.

## Journey Manifest Schema

The `journey-manifest.json` file is the top-level manifest that contains all journey definitions, custom mappings, and capture configuration for a project.

### Complete Schema

```json
{
  "$schema": "journey-manifest-v1",
  "generatedBy": "arn-spark-visual-test-engineer",
  "generatedAt": "2026-02-28T14:30:00Z",
  "journeys": [
    {
      "name": "login-flow",
      "description": "Tests the login sequence from initial screen through dashboard load",
      "preconditions": [
        "Application is running and showing the main window",
        "No user is currently logged in"
      ],
      "steps": [
        { "type": "capture", "name": "login-screen" },
        {
          "type": "setValue",
          "target": { "automationId": "usernameInput", "controlType": "textBox" },
          "value": "testuser@example.com"
        },
        {
          "type": "setValue",
          "target": { "automationId": "passwordInput", "controlType": "textBox" },
          "value": "test-password-123"
        },
        {
          "type": "invoke",
          "target": { "automationId": "loginButton", "controlType": "button" },
          "delay": 200
        },
        {
          "type": "settle",
          "timeout": 10000,
          "condition": "Loading spinner disappears and dashboard content is visible"
        },
        { "type": "capture", "name": "dashboard-after-login" }
      ]
    },
    {
      "name": "settings-navigation",
      "description": "Opens settings from the dashboard and captures each settings panel",
      "preconditions": [
        "User is logged in and on the dashboard"
      ],
      "steps": [
        {
          "type": "invoke",
          "target": { "automationId": "settingsButton", "controlType": "button" }
        },
        {
          "type": "settle",
          "timeout": 3000,
          "condition": "Settings panel is fully loaded"
        },
        { "type": "capture", "name": "settings-general" },
        {
          "type": "invoke",
          "target": { "automationId": "appearanceTab", "controlType": "tab" }
        },
        {
          "type": "settle",
          "timeout": 2000
        },
        { "type": "capture", "name": "settings-appearance" }
      ]
    }
  ],
  "customMappings": {
    "main-navigation": {
      "windows": {
        "automationId": "NavHost",
        "controlType": "Pane",
        "className": "NavigationView"
      },
      "macos": {
        "role": "AXGroup",
        "subrole": "AXNavigationBar",
        "identifier": "MainNavigation"
      }
    }
  },
  "captureConfig": {
    "outputDir": "visual-tests/baselines/layer-2/journeys/",
    "format": "png",
    "fullWindow": true
  }
}
```

### Field Reference

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `$schema` | string | Yes | Schema version identifier. Must be `"journey-manifest-v1"`. |
| `generatedBy` | string | Yes | The tool that generated the manifest. Typically `"arn-spark-visual-test-engineer"`. |
| `generatedAt` | string | Yes | ISO 8601 timestamp of when the manifest was generated. |
| `journeys` | array | Yes | Array of journey objects. Each journey defines a complete user interaction flow. |
| `journeys[].name` | string | Yes | Unique identifier for the journey. Used in reporting and file organization. |
| `journeys[].description` | string | Yes | Human-readable description of what the journey tests. |
| `journeys[].preconditions` | array | Yes | List of application state requirements that must be true before the journey starts. |
| `journeys[].steps` | array | Yes | Ordered array of step objects. Each step is one of: `capture`, `invoke`, `setValue`, `settle`. |
| `customMappings` | object | No | Maps logical component names to platform-specific selectors. See Custom Mappings section. |
| `captureConfig` | object | Yes | Configuration for screenshot capture. |
| `captureConfig.outputDir` | string | Yes | Directory where captured screenshots are saved. Relative to project root. |
| `captureConfig.format` | string | Yes | Image format for captures. Must be `"png"`. |
| `captureConfig.fullWindow` | boolean | Yes | Whether to capture the full application window (`true`) or just the client area (`false`). |
