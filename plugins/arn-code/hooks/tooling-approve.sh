#!/usr/bin/env bash
# Records that the user approved the commands in <code-patterns-dir>/tooling.json.
# Hooks only run commands from an approved tooling.json; editing the file
# (or cloning a repo with a different one) requires a new approval.

set -u

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib-hook.sh"

arn_cd_project_root || { echo "tooling-approve: cannot resolve project root" >&2; exit 1; }
f="$(arn_patterns_dir)/tooling.json"
[ -f "$f" ] || { echo "tooling-approve: $f not found" >&2; exit 1; }
mkdir -p .arness
arn_hash_file "$f" > .arness/tooling.local.sha
echo "approved: $f"
