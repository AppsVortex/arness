#!/usr/bin/env bash
# arn-code-ensure-config cache-write.sh
#
# Writes .arness/arn-code-ensure-config.local.json after a successful full
# validation (ensure-config Layer 4). Uses the same fingerprint functions as
# cache-check.sh, so a cache written here is read back as a hit.
#
# Exit 0 on success, non-zero with a stderr reason on failure.

set -u

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

arn_cd_project_root || { echo "cache write: cannot resolve project root" >&2; exit 1; }
mkdir -p .arness || { echo "cache write: cannot create .arness/" >&2; exit 1; }

CACHE_FILE=".arness/${ARN_PLUGIN_NAME}-ensure-config.local.json"
TMP_FILE="${CACHE_FILE}.tmp"

{
  printf '{\n'
  printf '  "schemaVersion": %s,\n' "$ARN_CACHE_SCHEMA_VERSION"
  printf '  "validatedAt": "%s",\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf '  "pluginVersion": "%s",\n' "$(arn_plugin_version)"
  printf '  "fingerprints": {\n'
  sep=""
  for key in $ARN_FINGERPRINT_KEYS; do
    printf '%s    "%s": "%s"' "$sep" "$key" "$(arn_fingerprint "$key")"
    sep=$',\n'
  done
  printf '\n  },\n'
  printf '  "validationStatus": "pass"\n'
  printf '}\n'
} > "$TMP_FILE" || { echo "cache write: cannot write $TMP_FILE" >&2; exit 1; }

mv "$TMP_FILE" "$CACHE_FILE" || { echo "cache write: cannot move cache into place" >&2; exit 1; }
echo "cache written: $CACHE_FILE"
