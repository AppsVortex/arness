#!/usr/bin/env bash
# arn-code-ensure-config shared helpers.
#
# Sourced by cache-check.sh, cache-write.sh, plugin-version.sh and the plugin
# hooks so that every reader and writer computes fingerprints the same way.
# Bash 3.2 compatible (macOS default). Required: sha256sum or shasum, awk.

ARN_PLUGIN_NAME="arn-code"
ARN_SHORT_NAME="code"
ARN_CACHE_SCHEMA_VERSION=2
ARN_EXPECTED_LABELS="arness-backlog arness-bug-issue arness-feature-issue arness-priority-high arness-priority-low arness-priority-medium arness-rejected arness-security"

ARN_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Script dir: <plugin-root>/skills/arn-code-ensure-config/scripts
ARN_PLUGIN_ROOT="$(cd "$ARN_LIB_DIR/../../.." && pwd)"   # own location; CLAUDE_PLUGIN_ROOT may name another plugin

# Move to the project root so relative paths (CLAUDE.md, .arness/) resolve
# even when Claude's cwd is a subdirectory.
arn_cd_project_root() {
  local root
  if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -d "$(arn_unix_path "$CLAUDE_PROJECT_DIR")" ]; then
    root=$(arn_unix_path "$CLAUDE_PROJECT_DIR")
  else
    root=$(git rev-parse --show-toplevel 2>/dev/null) || root="$(pwd)"
  fi
  cd "$root" || return 1
}

# arn_python: print the command of a working Python 3, or nothing. On Windows,
# "python3" is often a Microsoft Store stub that only prints a message; Python is "python".
arn_python() {
  local p
  for p in python3 python; do
    command -v "$p" >/dev/null 2>&1 || continue
    "$p" -c 'import sys; sys.exit(sys.version_info[0] < 3)' >/dev/null 2>&1 && { printf '%s' "$p"; return 0; }
  done
  return 1
}

# arn_unix_path <path>: turn a Windows path (C:\x\y or C:/x/y) into the form Git Bash
# uses (/c/x/y). Other paths are printed unchanged.
arn_unix_path() {
  case "$1" in
    [A-Za-z]:[\\/]*|[A-Za-z]:)
      if command -v cygpath >/dev/null 2>&1; then cygpath -u "$1"
      else printf '%s' "$1" | awk '{ gsub(/\\/, "/"); print "/" tolower(substr($0, 1, 1)) substr($0, 3) }'
      fi ;;
    *) printf '%s' "$1" ;;
  esac
}

arn_sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 | awk '{print $1}'
  else
    echo "ERROR: neither sha256sum nor shasum available" >&2
    return 2
  fi
}

arn_hash_str() {
  printf '%s' "$1" | arn_sha256
}

arn_hash_file() {
  if [ ! -f "$1" ]; then
    echo "MISSING"
    return 0
  fi
  arn_sha256 < "$1"
}

# Print the body of the "## Arness" section of CLAUDE.md, CR stripped.
arn_arness_section() {
  [ -f CLAUDE.md ] || return 1
  awk '{sub(/\r$/, "")} /^## Arness$/{flag=1; next} /^## /{flag=0} flag' CLAUDE.md
}

# Read one "- **Field:** value" line from the ## Arness section.
arn_config_field() {
  arn_arness_section 2>/dev/null | awk -v key="$1" '
    index($0, "- **" key ":**") == 1 {
      sub(/^- \*\*[^*]+:\*\*[ \t]*/, ""); sub(/[ \t]+$/, ""); print; exit
    }'
}

# Resolve the installed plugin version. Order:
#   1. version in plugin.json (if a future release sets it)
#   2. marketplace.json next to the plugin (local / relative-path installs)
#   3. the installed cache directory name: ~/.claude/plugins/cache/<mkt>/<plugin>/<version>
# Prints an empty string when none resolves.
arn_plugin_version() {
  local v="" mj base
  if [ -f "$ARN_PLUGIN_ROOT/.claude-plugin/plugin.json" ]; then
    v=$(awk -F'"' '/"version"[ \t]*:/{print $4; exit}' "$ARN_PLUGIN_ROOT/.claude-plugin/plugin.json")
  fi
  if [ -z "$v" ]; then
    mj="$(cd "$ARN_PLUGIN_ROOT/../.." 2>/dev/null && pwd)/.claude-plugin/marketplace.json"
    if [ -f "$mj" ]; then
      v=$(awk -v name="$ARN_PLUGIN_NAME" -F'"' '
        $2 == "name" && $4 == name {hit=1; next}
        hit && $2 == "version" {print $4; exit}
        hit && $2 == "name" {hit=0}' "$mj")
    fi
  fi
  if [ -z "$v" ]; then
    base=$(basename "$ARN_PLUGIN_ROOT")
    case "$base" in
      [0-9]*.[0-9]*.[0-9]*) v="$base" ;;
    esac
  fi
  printf '%s' "$v"
}

# The fingerprint keys, in a fixed order. Values come from arn_fingerprint.
ARN_FINGERPRINT_KEYS="claudeMdArnessSection agentModelsCodeMd agentModelsChecksums templatesChecksums userProfile profileOverride gitignoreContent"

arn_fingerprint() {
  case "$1" in
    claudeMdArnessSection)
      if [ -f CLAUDE.md ]; then arn_hash_str "$(arn_arness_section)"; else echo "MISSING"; fi ;;
    agentModelsCodeMd)    arn_hash_file ".arness/agent-models/${ARN_SHORT_NAME}.md" ;;
    agentModelsChecksums) arn_hash_file ".arness/agent-models/.checksums.json" ;;
    templatesChecksums)   arn_hash_file ".arness/templates/.checksums.json" ;;
    userProfile)          arn_hash_file "$HOME/.arness/user-profile.yaml" ;;
    profileOverride)      arn_hash_file ".claude/arness-profile.local.md" ;;
    gitignoreContent)     arn_hash_file ".gitignore" ;;
  esac
}

# Read a flat string value from the cache JSON without jq.
# Works for the keys this plugin writes (no nested quotes in values).
arn_json_get() {
  awk -v key="$2" -F'"' '{for (i = 2; i < NF; i++) if ($i == key) {print $(i + 2); exit}}' "$1"
}

# List the expected labels that are missing on the GitHub repo.
# Prints nothing when all are present. Returns 3 when gh cannot answer.
arn_missing_labels() {
  local have l missing=""
  have=$(gh label list --limit 500 --json name --jq '.[].name' 2>/dev/null) || return 3
  for l in $ARN_EXPECTED_LABELS; do
    printf '%s\n' "$have" | grep -qx "$l" || missing="$missing $l"
  done
  printf '%s' "${missing# }"
}

# True when the current directory is an Arness project.
arn_is_arness_project() {
  [ -f CLAUDE.md ] && grep -q '^## Arness' CLAUDE.md 2>/dev/null
}
