#!/usr/bin/env bash
# Shared helpers for arn-code plugin hooks.
#
# Every hook fails open: when a tool is missing or input cannot be parsed, the
# hook exits 0 and lets Claude Code continue. Hooks only act inside Arness
# projects (CLAUDE.md with a "## Arness" section).
#
# Hooks are off until the user turns them on (ARN_HOOKS_DEFAULT below):
#   "- **Hooks:** on" in the ## Arness section   on for this project (whole team)
#   ARNESS_HOOKS=on                               on for this user (shell or settings "env")
#   ARNESS_HOOKS=off                              off, whatever the project says
#   ARNESS_HOOKS_DISABLE=a,b                      disable some: session, force-push, secrets, lint

. "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/skills/arn-code-ensure-config/scripts/lib.sh"

ARN_HOOK_INPUT=""

arn_hook_read_input() {
  ARN_HOOK_INPUT=$(cat)
}

ARN_HOOKS_DEFAULT=off

# arn_hook_enabled <name>: true when hooks are on and this hook is not disabled.
# Call it after arn_hook_enter_project: it reads the Hooks field of the project.
arn_hook_enabled() {
  case ",${ARNESS_HOOKS_DISABLE:-}," in *",$1,"*) return 1 ;; esac
  local v="${ARNESS_HOOKS:-}"
  [ -n "$v" ] || v=$(arn_config_field Hooks 2>/dev/null)
  [ -n "$v" ] || v=$ARN_HOOKS_DEFAULT
  case "$v" in on|enabled|yes|true) return 0 ;; *) return 1 ;; esac
}

# arn_hook_json <dotted.path>: print a string field from the hook input.
arn_hook_json() {
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$ARN_HOOK_INPUT" | jq -r ".$1 // empty" 2>/dev/null
  elif command -v python3 >/dev/null 2>&1; then
    printf '%s' "$ARN_HOOK_INPUT" | python3 -I -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for k in sys.argv[1].split("."):
    d = d.get(k) if isinstance(d, dict) else None
if isinstance(d, str):
    print(d)
elif d is not None:
    print(json.dumps(d))
' "$1"
  fi
}

# arn_json_escape: stdin -> JSON string body (no surrounding quotes).
arn_json_escape() {
  tr -d '\000-\010\013\014\016-\037' | awk 'BEGIN{ORS=""} {
    gsub(/\\/, "\\\\"); gsub(/"/, "\\\""); gsub(/\t/, "\\t"); gsub(/\r/, "")
    if (NR > 1) printf "\\n"
    printf "%s", $0
  }'
}

# arn_hook_context <event> <text>: add text to Claude's context.
arn_hook_context() {
  printf '{"hookSpecificOutput":{"hookEventName":"%s","additionalContext":"%s"}}\n' \
    "$1" "$(printf '%s' "$2" | arn_json_escape)"
}

# arn_hook_deny <reason>: deny the current PreToolUse call; Claude sees the reason.
arn_hook_deny() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' \
    "$(printf '%s' "$1" | arn_json_escape)"
}

# arn_hook_enter_project: cd to the project root; false if not an Arness project.
arn_hook_enter_project() {
  local cwd
  cwd=$(arn_hook_json cwd)
  if [ -n "$cwd" ] && [ -d "$cwd" ]; then cd "$cwd" 2>/dev/null || true; fi
  arn_cd_project_root || return 1
  arn_is_arness_project
}

# Directory holding pattern docs and tooling.json ("Code patterns" field).
arn_patterns_dir() {
  local d
  d=$(arn_config_field "Code patterns")
  printf '%s' "${d:-.arness}"
}
