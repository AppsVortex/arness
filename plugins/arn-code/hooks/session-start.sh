#!/usr/bin/env bash
# SessionStart: one status line about the Arness config, and after a compaction
# a pointer to the plan in progress so the session can pick up where it was.

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib-hook.sh"

arn_hook_read_input
arn_hook_enter_project || exit 0
arn_hook_enabled session || exit 0

reason=$(bash "$ARN_LIB_DIR/cache-check.sh" 2>&1 >/dev/null)
if [ -z "$reason" ]; then
  msg="Arness (arn-code $(arn_plugin_version)): config cache valid."
else
  msg="Arness (arn-code $(arn_plugin_version)): ${reason}. Entry-point skills will run the full config check at Step 0."
fi

if [ "$(arn_hook_json source)" = "compact" ]; then
  plans=$(arn_config_field "Plans directory")
  plans="${plans:-.arness/plans}"
  latest=""
  if [ -d "$plans" ]; then
    latest=$(find "$plans" -name PROGRESS_TRACKER.json -mtime -7 2>/dev/null | while IFS= read -r f; do
      printf '%s\t%s\n' "$(stat -c %Y "$f" 2>/dev/null || stat -f %m "$f" 2>/dev/null || echo 0)" "$f"
    done | sort -rn | head -1 | cut -f2)
  fi
  if [ -n "$latest" ]; then
    dir=$(dirname "$latest")
    msg="$msg
Context was compacted. The most recently updated Arness plan is $dir. Before continuing implementation work, re-read $dir/PROGRESS_TRACKER.json and $dir/TASKS.md to find the current phase and next task."
  fi
fi

arn_hook_context SessionStart "$msg"
