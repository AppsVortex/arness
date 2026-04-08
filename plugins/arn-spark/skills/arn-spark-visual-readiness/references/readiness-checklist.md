# Visual Readiness Checklist

Evaluation guide used by `arn-spark-visual-readiness` during Step 3 (Check Activation Criteria). The skill reads this checklist and matches each deferred layer's activation criteria text against the common patterns below, then executes the concrete checks to collect evidence for promotion decisions.

## Common Activation Criteria Patterns

### Build Success

Use when the activation criteria mention building, compiling, packaging, or producing an executable.

- [ ] Build command completes without errors (exit code 0)
- [ ] Build output exists at the expected path
- [ ] Build output is executable or launchable
- [ ] Build output version matches the current project version (if applicable)

**How to check:**
1. Run the project's build command from the project root (e.g., `npm run build`, `cargo build --release`, `npm run tauri build`)
2. Verify exit code is 0
3. Check for build output at the expected path (e.g., `ls -la dist/`, `ls -la target/release/`)
4. Attempt to launch the built artifact briefly to confirm it starts (if safe to do so)

**Evidence to collect:** Build command output (last 20 lines), build output file path and size, launch confirmation (if tested).

### Platform Access

Use when the activation criteria mention a specific OS, cross-platform file access, WSL2-to-Windows, or running on a target machine.

- [ ] Target OS is accessible from the development environment
- [ ] File transfer mechanism works (e.g., WSL2 <-> Windows via `/mnt/c/`, SSH/SCP to remote machine)
- [ ] Required tools are installed on the target platform
- [ ] Network connectivity exists between environments (if needed for dev server access)

**How to check:**
1. Test file write to the cross-platform path (e.g., `touch /mnt/c/temp/visual-test-probe && rm /mnt/c/temp/visual-test-probe`)
2. Verify target platform tool availability (e.g., run `powershell.exe -Command "Get-Command nircmd"` from WSL2)
3. If remote: test SSH connection and file transfer round-trip
4. If network: test connectivity to dev server from the target environment

**Evidence to collect:** File transfer test output, tool version output from target platform, connectivity test results.

### Tool Availability

Use when the activation criteria mention specific screenshot tools, image comparison libraries, browsers, or runtimes.

- [ ] Screenshot capture tool is installed and accessible
- [ ] Image comparison library is installed
- [ ] Required browser or runtime is available
- [ ] Tool version meets minimum requirements (if specified)

**How to check:**
1. Run `which [tool]` or `[tool] --version` for each required tool
2. For Node.js tools: check `npx [tool] --version` or verify in `node_modules/`
3. For system tools: check the system package manager or standard install paths
4. For browsers: verify Playwright browsers are installed (`npx playwright install --dry-run`)

**Evidence to collect:** Version output from each tool, install path, any version warnings.

### CI Configuration

Use when the activation criteria mention CI pipelines, GitHub Actions runners, or automated visual test execution.

- [ ] CI workflow file exists at the expected path (e.g., `.github/workflows/visual-tests.yml`)
- [ ] OS matrix includes the required platform for this layer
- [ ] Visual test step is defined in the workflow
- [ ] Required secrets or environment variables are configured (if applicable)

**How to check:**
1. Read the CI workflow file and verify it contains the visual test job
2. Check the `runs-on` field for the required OS (e.g., `windows-latest` for native Windows capture)
3. Verify the visual test step references the correct scripts
4. Check for required environment variables in the workflow

**Evidence to collect:** Workflow file path, relevant job/step configuration, OS matrix values.

### Dev Server Availability

Use when the activation criteria mention a running development server, hot-reload, or local URL access from the capture environment.

- [ ] Dev server starts successfully
- [ ] Dev server is accessible from the capture environment
- [ ] Dev server serves the expected content (not an error page)
- [ ] Dev server port is not conflicting with other services

**How to check:**
1. Start the dev server (e.g., `npm run dev`)
2. Verify it responds at the expected URL (e.g., `curl -s -o /dev/null -w "%{http_code}" http://localhost:5173`)
3. If cross-environment: verify the URL is accessible from the target platform
4. Check for port conflicts before starting

**Evidence to collect:** Dev server start output, HTTP response code, content verification.

### UIA Availability

Use when the activation criteria mention UI automation, accessibility APIs, UIA, NSAccessibility, interaction testing, or native element inspection.

- [ ] Platform automation framework loads (Windows: `Add-Type -AssemblyName UIAutomationClient` succeeds in PowerShell; macOS: `osascript -e 'tell application "System Events" to get name of first process'` succeeds)
- [ ] Accessibility tree is inspectable -- can enumerate top-level UI elements of a running application
- [ ] Target application exposes automation IDs on key interactive elements (buttons, inputs, menus, navigation)

**How to check:**
1. Windows: run `powershell.exe -Command "Add-Type -AssemblyName UIAutomationClient; [System.Windows.Automation.AutomationElement]::RootElement.GetRuntimeId()"` and verify it succeeds
2. macOS: run `osascript -e 'tell application "System Events" to get name of first process'` and verify it returns a process name
3. Launch the target application and inspect its accessibility tree (Windows: `Inspect.exe` or `FlaUI`; macOS: Accessibility Inspector in Xcode)
4. Verify that key interactive elements have non-empty automation IDs or accessibility identifiers

**Evidence to collect:** Automation framework load output, list of discovered automation IDs for the target application, accessibility tree depth (number of levels inspected).

### Journey Runner

Use when the activation criteria mention journey execution, journey runner, journey manifest, interaction test runner, or step-based capture.

- [ ] Runner script exists at the path specified in the `**Journey runner:**` CLAUDE.md field
- [ ] Runner script is executable (`test -x <path>` or file extension matches expected type: `.ps1` for Windows, `.swift` or `.applescript` for macOS)
- [ ] `journey-manifest.json` exists at the path specified in the `**Journey manifest:**` CLAUDE.md field
- [ ] Manifest is valid JSON (`cat <path> | python -m json.tool` or equivalent)
- [ ] Manifest contains at least one journey in the `journeys` array
- [ ] Runner can parse the manifest in dry-run mode (runner loads manifest, resolves selectors, does not execute actions)

**How to check:**
1. Check runner script existence: `test -f <journey-runner-path> && echo "EXISTS" || echo "MISSING"`
2. Check runner script is executable: `test -x <journey-runner-path> && echo "EXECUTABLE" || echo "NOT EXECUTABLE"`
3. Validate manifest JSON: `cat <journey-manifest-path> | python -m json.tool > /dev/null 2>&1 && echo "VALID" || echo "INVALID"`
4. Count journeys in manifest: `python -c "import json; m=json.load(open('<path>')); print(len(m.get('journeys', [])))"`
5. Run the runner in dry-run mode: `<runner-command> --dry-run <manifest-path>` and check for errors
6. Verify that the dry-run output reports resolved selectors for all journey steps

**Evidence to collect:** File existence checks, JSON validation output, journey count, dry-run output showing resolved vs unresolved selectors.

### Accessibility Permissions (macOS)

Use when the activation criteria mention macOS Accessibility permissions, System Events authorization, or terminal accessibility access. This pattern applies only on macOS.

- [ ] Terminal/IDE has been granted Accessibility permission in System Preferences
- [ ] `osascript` accessibility queries succeed without authorization errors

**How to check:**
1. Run: `osascript -e 'tell application "System Events" to get properties of first UI element of first process'`
2. If the command fails with an authorization error (e.g., "Not authorized to send Apple events"), permissions are not granted
3. If the command succeeds and returns UI element properties, permissions are granted

**Evidence to collect:** osascript output (success) or error message (failure).

**User instructions for granting permission:** To grant Accessibility permission: System Preferences > Privacy & Security > Privacy > Accessibility > Add your terminal application (Terminal, iTerm2, VS Code, etc.) and enable the checkbox. You may need to restart the terminal after granting permission.

## Evidence Collection Guidelines

Evidence must be concrete and verifiable. Each check should produce one or more of:

- **Command output:** The stdout/stderr from running a verification command (truncate to relevant lines)
- **File existence:** Path and size of an expected artifact (`ls -la [path]`)
- **Version string:** Output from `[tool] --version` confirming availability
- **Test result:** Pass/fail from a probe command (e.g., file write round-trip, HTTP response code)

Avoid subjective evidence like "it seems to work" or "probably available." Each piece of evidence should be reproducible by running the same command again.

## Promotion Decision Tree

Follow this decision tree for each deferred layer:

```
1. Are ALL activation criteria checklist items passing?
   |
   +-- NO --> Leave layer as DEFERRED
   |          Report which criteria failed with evidence
   |          Suggest remediation steps
   |
   +-- YES --> Proceed to spike validation (Step 4)
               |
               2. Does the spike validation pass?
                  |
                  +-- VALIDATED --> Promote to ACTIVE
                  |                 Update CLAUDE.md Status: active
                  |                 Record validation date and evidence
                  |
                  +-- PARTIALLY VALIDATED --> Present caveats to user
                  |                           Ask: "Promote with caveats, or leave deferred?"
                  |                           If user approves: Promote to ACTIVE with caveats noted
                  |                           If user declines: Leave as DEFERRED
                  |
                  +-- FAILED --> Leave as DEFERRED
                  |              Record failure evidence
                  |              Suggest investigation or alternative approach
                  |
                  +-- DEFERRED --> Leave as DEFERRED
                                   Cannot validate in current environment
                                   Record what is needed to validate
```

## Custom Criteria

If a layer's activation criteria text does not match any common pattern above, evaluate it as a custom criterion:

1. Break the criteria text into individual checkable assertions
2. For each assertion, determine the most direct verification method (command, file check, or user confirmation)
3. Execute the checks and collect evidence
4. If any assertion cannot be verified programmatically, ask the user for confirmation with the context of what was checked and what remains uncertain
