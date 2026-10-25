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
# Carriage returns are dropped (jq and Python on Windows end lines with CR LF).
arn_hook_json() {
  local py
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$ARN_HOOK_INPUT" | jq -r ".$1 // empty" 2>/dev/null | tr -d '\r'
  elif py=$(arn_python); then
    printf '%s' "$ARN_HOOK_INPUT" | "$py" -I -c '
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
' "$1" | tr -d '\r'
  else
    printf '%s' "$ARN_HOOK_INPUT" | arn_json_get "$1"
  fi
}

# arn_json_get <dotted.path>: stdin JSON -> the string, number or boolean at the path.
# Plain awk, for machines with neither jq nor Python (common on Windows). Objects and
# arrays print nothing; \u escapes above U+007F stay as written.
arn_json_get() {
  awk -v want=".$1" '
    function ws() { while (p <= n && index(" \t\r\n", substr(s, p, 1))) p++ }
    function str(keep,   out, c, h, i, v) {
      p++; out = ""
      while (p <= n) {
        c = substr(s, p, 1)
        if (c == "\"") { p++; return out }
        if (c == "\\") {
          p++; c = substr(s, p, 1)
          if (c == "u") {
            h = substr(s, p + 1, 4); p += 4; v = 0
            for (i = 1; i <= 4; i++) v = v * 16 + index("0123456789abcdef", tolower(substr(h, i, 1))) - 1
            c = (v >= 32 && v < 127) ? sprintf("%c", v) : "\\u" h
          } else if (c == "n") c = "\n"; else if (c == "t") c = "\t"; else if (c == "r") c = "\r"
          else if (c == "b") c = "\b"; else if (c == "f") c = "\f"
        }
        if (keep) out = out c
        p++
      }
      return out
    }
    function value(path,   c, k, i, v) {
      ws(); c = substr(s, p, 1)
      if (c == "{" || c == "[") {
        p++; i = 0; ws()
        if (substr(s, p, 1) == (c == "{" ? "}" : "]")) { p++; return }
        while (p <= n && !found) {
          ws()
          if (c == "{") { k = str(1); ws(); p++ } else k = i++
          value(path "." k); ws()
          v = substr(s, p, 1); p++
          if (v != ",") return
        }
      } else if (c == "\"") {
        v = str(path == want); if (path == want) { print v; found = 1 }
      } else {
        v = ""
        while (p <= n && !index(",]} \t\r\n", substr(s, p, 1))) { v = v substr(s, p, 1); p++ }
        if (path == want && v != "null") { print v; found = 1 }
      }
    }
    { s = (NR > 1 ? s "\n" : "") $0 }
    END { n = length(s); p = 1; found = 0; value("") }
  '
}

# arn_hook_path <dotted.path>: a path field from the hook input, in Git Bash form on Windows.
arn_hook_path() {
  arn_unix_path "$(arn_hook_json "$1")"
}

# arn_hook_rel_path <file>: print the file's path from the project root (the current
# directory); false when it is outside. Physical paths, so a symlink on either side
# (for example the macOS temp folder) still matches.
arn_hook_rel_path() {
  local root dir
  root=$(pwd -P)
  dir=$(cd "$(dirname "$1")" 2>/dev/null && pwd -P) || return 1
  case "$dir/" in "$root"/*) ;; *) return 1 ;; esac
  dir="${dir#"$root"}"; dir="${dir#/}"
  printf '%s' "${dir:+$dir/}$(basename "$1")"
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
  cwd=$(arn_hook_path cwd)
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
