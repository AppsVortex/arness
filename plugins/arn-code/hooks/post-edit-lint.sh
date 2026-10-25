#!/usr/bin/env bash
# PostToolUse (Edit|Write|MultiEdit): fast lint and format check on the edited
# file, using the project's own commands from <code-patterns-dir>/tooling.json.
# Advisory only: findings are added to Claude's context, the edit is never blocked.
# Runs only when "Linting: enabled", tooling.json is approved (tooling-approve.sh),
# and the project does not already own these checks ("owner": "project").
# Language-neutral: which commands run is decided entirely by tooling.json.

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib-hook.sh"

arn_hook_read_input
file=$(arn_hook_json tool_input.file_path)
[ -n "$file" ] || exit 0
arn_hook_enter_project || exit 0
arn_hook_enabled lint || exit 0
[ "$(arn_config_field Linting)" = "enabled" ] || exit 0

tooling="$(arn_patterns_dir)/tooling.json"
[ -f "$tooling" ] || exit 0
[ -f .arness/tooling.local.sha ] || exit 0
[ "$(arn_hash_file "$tooling")" = "$(cat .arness/tooling.local.sha)" ] || exit 0
command -v python3 >/dev/null 2>&1 || exit 0

# Compare physical paths: the project root or the edited path may go through a symlink.
root=$(pwd -P)
fdir=$(cd "$(dirname "$file")" 2>/dev/null && pwd -P) || exit 0
file="$fdir/$(basename "$file")"
case "$file" in "$root"/*) rel="${file#"$root"/}" ;; *) exit 0 ;; esac
[ -f "$rel" ] || exit 0

# Pick the deepest service whose path contains the file and whose extensions
# match; print its file-level check commands, one per line, {files} filled in.
cmds=$(python3 -I - "$tooling" "$rel" <<'PY'
import json, os, shlex, sys
try:
    data = json.load(open(sys.argv[1]))
except Exception:
    sys.exit(0)
rel = sys.argv[2]
ext = os.path.splitext(rel)[1]
best = None
for svc in data.get("services", []):
    p = (svc.get("path") or ".").strip("/")
    if p not in ("", ".") and not (rel == p or rel.startswith(p + "/")):
        continue
    exts = svc.get("extensions") or []
    if exts and ext not in exts:
        continue
    depth = 0 if p in ("", ".") else p.count("/") + 1
    if best is None or depth > best[0]:
        best = (depth, svc)
if best is None or best[1].get("owner") == "project":
    sys.exit(0)
for key in ("lintFiles", "formatCheckFiles"):
    c = best[1].get(key)
    if c and "{files}" in c:
        print(c.replace("{files}", shlex.quote(rel)))
PY
)
[ -n "$cmds" ] || exit 0

report=""
while IFS= read -r c; do
  [ -n "$c" ] || continue
  if command -v timeout >/dev/null 2>&1; then
    out=$(timeout 60 bash -c "$c" 2>&1); rc=$?
  else
    out=$(bash -c "$c" 2>&1); rc=$?
  fi
  if [ $rc -ne 0 ]; then
    report="$report
\$ $c (exit $rc)
$(printf '%s\n' "$out" | head -40)"
  fi
done <<< "$cmds"

[ -n "$report" ] || exit 0
arn_hook_context PostToolUse "Arness lint check (advisory) found issues in $rel. Fix them before finishing the task:$report"
