#!/usr/bin/env bash
# arn-spark-ensure-config cache-check.sh
#
# Returns exit 0 when the cache at .arness/arn-spark-ensure-config.local.json
# is valid (all fingerprints match current state). Returns non-zero with a
# stderr reason on miss.
#
# Cross-platform: works on Linux, Mac, and Windows-via-Git-Bash.
# Required tools: bash, sha256sum or shasum, awk, grep, mv, cat, jq.
# Optional tool: gh (only used for GitHub label count check).

set -u

PLUGIN_NAME="arn-spark"
SHORT_NAME="spark"
SCHEMA_VERSION=1
EXPECTED_LABELS_COUNT=7
CACHE_FILE=".arness/${PLUGIN_NAME}-ensure-config.local.json"

# --- Helper: fail fast with reason ---
miss() {
  echo "cache miss: $1" >&2
  exit 1
}

# --- Helper: cross-platform SHA-256 ---
hash_str() {
  local data="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    printf '%s' "$data" | sha256sum | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    printf '%s' "$data" | shasum -a 256 | awk '{print $1}'
  else
    echo "ERROR: neither sha256sum nor shasum available" >&2
    exit 2
  fi
}

hash_file() {
  local path="$1"
  if [ ! -f "$path" ]; then
    echo "MISSING"
    return 0
  fi
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$path" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$path" | awk '{print $1}'
  else
    echo "ERROR: neither sha256sum nor shasum available" >&2
    exit 2
  fi
}

# --- 1. Cache file present? ---
[ -f "$CACHE_FILE" ] || miss "no cache file at $CACHE_FILE"

# --- 2. jq available for parsing? ---
command -v jq >/dev/null 2>&1 || miss "jq not available (required for cache parsing)"

# --- 3. Schema version matches? ---
cached_schema=$(jq -r '.schemaVersion // empty' "$CACHE_FILE" 2>/dev/null)
[ "$cached_schema" = "$SCHEMA_VERSION" ] || miss "schemaVersion mismatch (cache: ${cached_schema:-empty}, expected: $SCHEMA_VERSION)"

# --- 4. Plugin version matches? ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
MARKETPLACE_JSON="$(cd "$PLUGIN_ROOT/.." && pwd)/.claude-plugin/marketplace.json"

if [ -f "$MARKETPLACE_JSON" ]; then
  current_version=$(jq -r --arg name "$PLUGIN_NAME" '.plugins[] | select(.name==$name) | .version' "$MARKETPLACE_JSON" 2>/dev/null)
  cached_version=$(jq -r '.pluginVersion // empty' "$CACHE_FILE")
  if [ -n "$current_version" ] && [ "$current_version" != "$cached_version" ]; then
    miss "pluginVersion changed (cache: $cached_version, current: $current_version)"
  fi
fi

# --- 5. Compute current fingerprints ---
if [ -f "CLAUDE.md" ]; then
  arness_section=$(awk '/^## Arness$/{flag=1;next} /^## /{flag=0} flag' CLAUDE.md)
  current_arness_section_hash=$(hash_str "$arness_section")
else
  current_arness_section_hash="MISSING"
fi

current_agent_models_hash=$(hash_file ".arness/agent-models/${SHORT_NAME}.md")
current_agent_models_checksums_hash=$(hash_file ".arness/agent-models/.checksums.json")
current_templates_checksums_hash=$(hash_file ".arness/templates/.checksums.json")
current_user_profile_hash=$(hash_file "$HOME/.arness/user-profile.yaml")
current_profile_override_hash=$(hash_file ".claude/arness-profile.local.md")
current_gitignore_hash=$(hash_file ".gitignore")

# --- 6. Compare against cache ---
# Use parallel indexed arrays (bash 3.2 compatible — Mac's default /bin/bash is 3.2,
# associative arrays via 'declare -A' are bash 4+ only).
KEYS=(claudeMdArnessSection agentModelsCodeMd agentModelsChecksums templatesChecksums userProfile profileOverride gitignoreContent)
VALUES=(
  "$current_arness_section_hash"
  "$current_agent_models_hash"
  "$current_agent_models_checksums_hash"
  "$current_templates_checksums_hash"
  "$current_user_profile_hash"
  "$current_profile_override_hash"
  "$current_gitignore_hash"
)

i=0
while [ $i -lt ${#KEYS[@]} ]; do
  key="${KEYS[$i]}"
  current="${VALUES[$i]}"
  cached=$(jq -r ".fingerprints.${key} // empty" "$CACHE_FILE")
  if [ "$cached" != "$current" ]; then
    miss "fingerprint $key changed (cache: ${cached:0:16}..., current: ${current:0:16}...)"
  fi
  i=$((i + 1))
done

# --- 7. GitHub labels check (only if Platform=github AND gh available) ---
if [ -f "CLAUDE.md" ]; then
  platform=$(grep -E '^- \*\*Platform:\*\*' CLAUDE.md 2>/dev/null | head -1 | sed -E 's/.*Platform:\*\*\s*//')
  if [ "$platform" = "github" ] && command -v gh >/dev/null 2>&1; then
    label_count=$(gh label list --json name --jq '.[].name' 2>/dev/null | grep -c '^arness-' || echo 0)
    if [ "$label_count" != "$EXPECTED_LABELS_COUNT" ]; then
      miss "GitHub arness-* label count is $label_count, expected $EXPECTED_LABELS_COUNT"
    fi
  fi
fi

exit 0
