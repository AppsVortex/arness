#!/usr/bin/env bash
# Prints the installed arn-code version, or "unknown" when it cannot be resolved.
# plugin.json intentionally has no version; see lib.sh arn_plugin_version.

set -u

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

v=$(arn_plugin_version)
printf '%s\n' "${v:-unknown}"
