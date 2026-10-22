#!/usr/bin/env bash
# arn-code-ensure-config cache-check.sh
#
# Returns exit 0 when the cache at .arness/arn-code-ensure-config.local.json
# is valid (all fingerprints match current state). Returns non-zero with a
# stderr reason on miss.
#
# Cross-platform: works on Linux, Mac, and Windows-via-Git-Bash.
# Required tools: bash, sha256sum or shasum, awk, grep.
# Optional tool: gh (only used for the GitHub label check).

set -u

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

miss() {
  echo "cache miss: $1" >&2
  exit 1
}

arn_cd_project_root || miss "cannot resolve project root"
CACHE_FILE=".arness/${ARN_PLUGIN_NAME}-ensure-config.local.json"

# --- 1. Cache file present? ---
[ -f "$CACHE_FILE" ] || miss "no cache file at $CACHE_FILE"

# --- 2. Schema version matches? ---
cached_schema=$(sed -n 's/.*"schemaVersion"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p' "$CACHE_FILE" | head -1)
[ "$cached_schema" = "$ARN_CACHE_SCHEMA_VERSION" ] || miss "schemaVersion mismatch (cache: ${cached_schema:-empty}, expected: $ARN_CACHE_SCHEMA_VERSION)"

# --- 3. Plugin version matches? ---
current_version=$(arn_plugin_version)
cached_version=$(arn_json_get "$CACHE_FILE" pluginVersion)
if [ -n "$current_version" ] && [ "$current_version" != "$cached_version" ]; then
  miss "pluginVersion changed (cache: ${cached_version:-empty}, current: $current_version)"
fi

# --- 4. Fingerprints match? ---
for key in $ARN_FINGERPRINT_KEYS; do
  current=$(arn_fingerprint "$key")
  cached=$(arn_json_get "$CACHE_FILE" "$key")
  if [ "$cached" != "$current" ]; then
    miss "fingerprint $key changed (cache: $(printf '%.16s' "$cached")..., current: $(printf '%.16s' "$current")...)"
  fi
done

# --- 5. GitHub labels present? (only if Platform=github and gh available) ---
if [ "$(arn_config_field Platform)" = "github" ] && command -v gh >/dev/null 2>&1; then
  missing=$(arn_missing_labels)
  rc=$?
  if [ $rc -eq 0 ] && [ -n "$missing" ]; then
    miss "GitHub labels missing: $missing"
  fi
  # rc 3 = gh could not answer (offline, no auth). Do not fail the cache for that.
fi

exit 0
