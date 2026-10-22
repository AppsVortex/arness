#!/usr/bin/env bash
# Per-finding file snapshots for the simplify applier.
#
#   snapshot.sh save <finding-id> <file>...   copy files before the first edit
#   snapshot.sh restore <finding-id>          put those files back exactly
#   snapshot.sh drop <finding-id>             forget a snapshot after success
#
# Only the files named for a finding are saved and restored, so other
# uncommitted work in the tree is never touched. "save" is idempotent: a file
# already saved for this finding keeps its first copy. A file that did not exist
# at save time is deleted on restore. Snapshots live in .arness/.simplify-tmp/
# (project-local, so parallel runs in other worktrees do not collide).

set -u

die() { echo "snapshot: $1" >&2; exit 1; }

root=$(git rev-parse --show-toplevel 2>/dev/null) || root=$(pwd)
cd "$root" || die "cannot enter project root"

cmd="${1:-}"; id="${2:-}"
[ -n "$cmd" ] && [ -n "$id" ] || die "usage: snapshot.sh save|restore|drop <finding-id> [file...]"
case "$id" in *[!A-Za-z0-9._-]*) die "invalid finding id: $id" ;; esac
shift 2

dir=".arness/.simplify-tmp/$id"
manifest="$dir/manifest"

case "$cmd" in
  save)
    mkdir -p "$dir/files" || die "cannot create $dir"
    touch "$manifest"
    for f in "$@"; do
      case "$f" in /*|*..*) die "path must be relative to the project root: $f" ;; esac
      if grep -qxF "E $f" "$manifest" || grep -qxF "N $f" "$manifest"; then continue; fi
      if [ -f "$f" ]; then
        mkdir -p "$dir/files/$(dirname "$f")"
        cp -p "$f" "$dir/files/$f" || die "cannot copy $f"
        printf 'E %s\n' "$f" >> "$manifest"
      else
        printf 'N %s\n' "$f" >> "$manifest"
      fi
    done
    ;;
  restore)
    [ -f "$manifest" ] || die "no snapshot for $id"
    while IFS= read -r line; do
      kind="${line%% *}"; f="${line#* }"
      if [ "$kind" = "E" ]; then
        mkdir -p "$(dirname "$f")"
        cp -p "$dir/files/$f" "$f" || die "cannot restore $f"
      else
        rm -f "$f"
      fi
    done < "$manifest"
    rm -rf "$dir"
    ;;
  drop)
    rm -rf "$dir"
    ;;
  *) die "unknown command: $cmd" ;;
esac
