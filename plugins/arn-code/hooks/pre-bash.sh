#!/usr/bin/env bash
# PreToolUse (Bash): two safety checks inside Arness projects.
#   force-push  deny "git push --force" / "-f" / "+refspec" (--force-with-lease is allowed)
#   secrets     before "git commit", scan what will be committed for private keys
#               and access tokens; deny on a hit
# Language-neutral: secret formats are credential shapes, not project tooling.

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib-hook.sh"

arn_hook_read_input
[ "${ARNESS_HOOKS:-}" = "off" ] && exit 0
cmd=$(arn_hook_json tool_input.command)
[ -n "$cmd" ] || exit 0
case "$cmd" in *git*) ;; *) exit 0 ;; esac
arn_hook_enter_project || exit 0

# Split the command line into simple segments on ; && || | and newlines.
segments=$(printf '%s\n' "$cmd" | awk '{gsub(/&&|\|\||[;|]/, "\n"); print}')

# Print the words of a segment that come after its git subcommand $1.
words_after() {
  printf '%s\n' "$2" | awk -v sub_cmd="$1" '{
    seen_git = 0; seen_sub = 0
    for (i = 1; i <= NF; i++) {
      if (!seen_git) { if ($i == "git" || $i ~ /\/git$/) seen_git = 1; continue }
      if (!seen_sub) { if ($i == sub_cmd) seen_sub = 1; continue }
      print $i
    }
  }'
}

# --- force push ---
if arn_hook_enabled force-push; then
  forced=$(printf '%s\n' "$segments" | while IFS= read -r seg; do
    words_after push "$seg" | awk '
      $0 == "--force" || $0 ~ /^-[A-Za-z]*f[A-Za-z]*$/ || $0 ~ /^\+/ { print "y"; exit }'
  done | head -1)
  if [ "$forced" = "y" ]; then
    arn_hook_deny "Arness blocks force-push in this project. Use --force-with-lease if you must overwrite the remote branch, or ask the user to push manually. (Disable with ARNESS_HOOKS_DISABLE=force-push.)"
    exit 0
  fi
fi

# --- secrets before commit ---
arn_hook_enabled secrets || exit 0
commit_words=$(printf '%s\n' "$segments" | while IFS= read -r seg; do
  if printf '%s\n' "$seg" | awk '{f=0; for(i=1;i<=NF;i++){if($i=="git"||$i~/\/git$/)f=1; else if(f&&$i=="commit"){print "y"; exit}}}' | grep -q y; then
    printf 'COMMIT\n'; words_after commit "$seg"
  fi
done)
case "$commit_words" in *COMMIT*) ;; *) exit 0 ;; esac
case "$commit_words" in *--dry-run*) exit 0 ;; esac

include_worktree=0
printf '%s\n' "$commit_words" | grep -Eqx -- '-[A-Za-z]*a[A-Za-z]*|--all' && include_worktree=1
printf '%s\n' "$segments" | awk '{f=0; for(i=1;i<=NF;i++){if($i=="git"||$i~/\/git$/)f=1; else if(f&&$i=="add"){print "y"; exit}}}' | grep -q y && include_worktree=2

pattern='-----BEGIN ([A-Z]+ )*PRIVATE KEY-----|(AKIA|ASIA)[0-9A-Z]{16}|gh[pousr]_[A-Za-z0-9]{36,}|github_pat_[A-Za-z0-9_]{60,}|glpat-[A-Za-z0-9_-]{20,}|xox[abprs]-[A-Za-z0-9-]{10,}|sk-ant-[A-Za-z0-9_-]{20,}|sk_live_[0-9A-Za-z]{24,}|AIza[0-9A-Za-z_-]{35}'

# Added lines from a unified diff, prefixed with their file name.
added_lines() {
  awk '/^\+\+\+ b\//{file=substr($0, 7); next} /^\+\+\+ /{next} /^\+/{print file ": " substr($0, 2)}'
}

hits=$(
  {
    git diff --cached -U0 --no-color 2>/dev/null | added_lines
    if [ $include_worktree -ge 1 ]; then git diff -U0 --no-color 2>/dev/null | added_lines; fi
    if [ $include_worktree -ge 2 ]; then
      git ls-files --others --exclude-standard -z 2>/dev/null | while IFS= read -r -d '' f; do
        [ -f "$f" ] && [ "$(wc -c < "$f")" -lt 1048576 ] && grep -IH "" "$f" 2>/dev/null | sed 's/^\([^:]*\):/\1: /'
      done
    fi
  } | grep -E -- "$pattern" | grep -v 'arness:allow-secret' | cut -d: -f1 | sort -u | head -10
)

key_files=$(
  {
    git diff --cached --name-only 2>/dev/null
    [ $include_worktree -ge 2 ] && git ls-files --others --exclude-standard 2>/dev/null
  } | grep -E '(^|/)(id_rsa|id_dsa|id_ecdsa|id_ed25519)$|\.(pem|p12|pfx|key)$|(^|/)\.env$' | sort -u | head -10
)

if [ -n "$hits$key_files" ]; then
  list=$(printf '%s\n' "$hits" | sed '/^$/d' | paste -sd, - | sed 's/,/, /g')
  list2=$(printf '%s\n' "$key_files" | sed '/^$/d' | paste -sd, - | sed 's/,/, /g')
  arn_hook_deny "Arness found what looks like a secret in the files being committed. Content matches: ${list:-none}. Key or env files: ${list2:-none}. Do not commit secrets: remove them, add the file to .gitignore, or move the value to an env var. If this is a false positive, add the comment 'arness:allow-secret' on that line, or ask the user to set ARNESS_HOOKS_DISABLE=secrets."
fi
exit 0
