#!/usr/bin/env bash
# Prints the arness-* GitHub labels that are missing on the current repo, one
# per line. Prints nothing when all are present. Exit 3 when gh cannot answer.

set -u

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

missing=$(arn_missing_labels) || exit 3
for l in $missing; do printf '%s\n' "$l"; done
