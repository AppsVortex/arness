# Template Setup Procedure

This procedure covers copying report templates to a project and generating checksums for version tracking. It is performed during arn-code-init (Step 7) when the user chooses default or custom templates.

## Default Templates

1. Create the directory: `mkdir -p .arness/templates`
2. Copy **all** JSON templates from the plugin's default template directory to the project:
   ```
   cp ${CLAUDE_PLUGIN_ROOT}/skills/arn-code-save-plan/report-templates/default/*.json .arness/templates/
   ```
   This uses glob-based copying so that new templates added in future plugin versions are automatically included without maintaining a hardcoded list.
3. Generate checksums via Bash (handle both Linux and macOS):
   ```
   sha256sum .arness/templates/*.json 2>/dev/null || shasum -a 256 .arness/templates/*.json
   ```
4. Read the plugin version from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`
5. Write `.arness/templates/.checksums.json`:
   ```json
   {
     "plugin_version": "<version>",
     "files": {
       "<filename>": "<sha256-hash>",
       ...
     }
   }
   ```
6. Set template path to `.arness/templates`

## Custom Templates

1. Show defaults from `${CLAUDE_PLUGIN_ROOT}/skills/arn-code-save-plan/report-templates/default/` as starting point
2. Ask: "What would you change? Which fields do you need or don't need?"
3. Iterate until satisfied
4. Save custom templates to `.arness/templates/` (or user-chosen path)
5. Generate checksums and `.checksums.json` (same as Default steps 3-5)
6. Set template path to the chosen location

## Template Updates Preference

After template setup, ask: "How should Arness handle template updates when the plugin is updated?"
- **"Ask me each time"** (default) -- set `Template updates: ask`
- **"Update automatically if I haven't customized them"** -- set `Template updates: auto`
- **"Never -- I'll manage templates myself"** -- set `Template updates: manual`
