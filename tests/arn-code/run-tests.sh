#!/usr/bin/env bash
# Shell tests for arn-code scripts and hooks. Bash 3.2 compatible (macOS).
# Run from anywhere:  bash tests/arn-code/run-tests.sh

set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export CLAUDE_PLUGIN_ROOT="$REPO/plugins/arn-code"
unset CLAUDE_PROJECT_DIR ARNESS_HOOKS ARNESS_HOOKS_DISABLE
CFG="$CLAUDE_PLUGIN_ROOT/skills/arn-code-ensure-config/scripts"
HOOKS="$CLAUDE_PLUGIN_ROOT/hooks"
SNAP="$CLAUDE_PLUGIN_ROOT/skills/arn-code-simplify/scripts/snapshot.sh"
SAVE="$CLAUDE_PLUGIN_ROOT/skills/arn-code-save-plan/scripts/save_plan.sh"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/arn-code-tests.XXXXXX")
trap 'rm -rf "$WORK"' EXIT
export HOME="$WORK/home"; mkdir -p "$HOME"
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t

pass=0; fail=0
ok()   { pass=$((pass + 1)); echo "ok   - $1"; }
nok()  { fail=$((fail + 1)); echo "FAIL - $1"; }
check() { if [ "$2" = "$3" ]; then ok "$1"; else nok "$1 (expected '$3', got '$2')"; fi; }

json_str() { python3 -I -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$1"; }
hook_input() { printf '{"cwd":%s,"source":%s,"tool_input":{"command":%s,"file_path":%s}}' \
  "$(json_str "$1")" "$(json_str "$2")" "$(json_str "$3")" "$(json_str "$4")"; }
decision() { if [ -n "$1" ]; then echo deny; else echo allow; fi; }

new_project() {
  local d="$WORK/$1"
  mkdir -p "$d" && cd "$d" && git init -q
  printf '# P\r\n\r\n## Arness\r\n\r\n- **Plans directory:** .arness/plans\r\n- **Code patterns:** .arness\r\n- **Linting:** %s\r\n- **Platform:** none\r\n\r\n## Other\r\n' "$2" > CLAUDE.md
  git add -A && git commit -qm init
}

# ---------------- cache ----------------
new_project cache skip
bash "$CFG/cache-check.sh" 2>/dev/null; check "cache: miss without a cache file" "$?" 1
bash "$CFG/cache-write.sh" >/dev/null; check "cache: write succeeds" "$?" 0
bash "$CFG/cache-check.sh" 2>/dev/null; check "cache: hit right after write (CRLF CLAUDE.md)" "$?" 0
mkdir -p sub && (cd sub && bash "$CFG/cache-check.sh" 2>/dev/null); check "cache: hit from a subdirectory" "$?" 0
printf 'extra\n' >> CLAUDE.md
bash "$CFG/cache-check.sh" 2>/dev/null; check "cache: edit outside ## Arness keeps the hit" "$?" 0
awk '{sub(/Linting:\*\* skip/, "Linting:** none")} {print}' CLAUDE.md > c && mv c CLAUDE.md
bash "$CFG/cache-check.sh" 2>/dev/null; check "cache: edit inside ## Arness misses" "$?" 1
check "version: resolved from marketplace.json" "$(bash "$CFG/plugin-version.sh")" \
  "$(python3 -I -c 'import json,sys; print([p for p in json.load(open(sys.argv[1]))["plugins"] if p["name"]=="arn-code"][0]["version"])' "$REPO/.claude-plugin/marketplace.json")"

# ---------------- snapshot ----------------
new_project snap skip
echo base > keep.txt; echo b > "sp ace.txt"; git add -A && git commit -qm files
echo "uncommitted work" >> keep.txt
bash "$SNAP" save SIM-1 "sp ace.txt" new.txt
echo changed > "sp ace.txt"; echo created > new.txt
bash "$SNAP" restore SIM-1
check "snapshot: restores the edited file" "$(cat "sp ace.txt")" b
check "snapshot: removes a file that did not exist" "$([ -e new.txt ] && echo yes || echo no)" no
check "snapshot: leaves other uncommitted work alone" "$(tail -1 keep.txt)" "uncommitted work"
bash "$SNAP" save ../x a 2>/dev/null; check "snapshot: rejects a bad id" "$?" 1

# ---------------- save_plan ----------------
new_project save skip
mkdir -p plans
bash "$SAVE" ../evil plans >/dev/null; check "save_plan: rejects path in project name" "$?" 1
bash "$SAVE" p plans >/dev/null; check "save_plan: no preview is an error" "$?" 1
echo "# A" > plans/PLAN_PREVIEW_a.md
bash "$SAVE" a plans >/dev/null; check "save_plan: single preview is used" "$?" 0
echo "# B" > plans/PLAN_PREVIEW_b.md
bash "$SAVE" b plans >/dev/null; check "save_plan: several previews need an explicit file" "$?" 1
bash "$SAVE" a plans plans/PLAN_PREVIEW_b.md >/dev/null; check "save_plan: no silent overwrite" "$?" 1
bash "$SAVE" a plans plans/PLAN_PREVIEW_b.md --force >/dev/null; check "save_plan: --force overwrites" "$(cat plans/a/SOURCE_PLAN.md)" "# B"

# ---------------- hooks: outside Arness ----------------
mkdir -p "$WORK/plain" && cd "$WORK/plain" && git init -q
check "hooks: silent outside Arness projects" \
  "$(hook_input "$WORK/plain" "" "git push --force" "" | bash "$HOOKS/pre-bash.sh")" ""

# ---------------- hooks: off by default ----------------
new_project hooks enabled
check "hooks: off by default" "$(decision "$(hook_input "$PWD" "" "git push --force" "" | bash "$HOOKS/pre-bash.sh")")" allow
check "hooks: ARNESS_HOOKS=on turns them on" "$(decision "$(hook_input "$PWD" "" "git push --force" "" | ARNESS_HOOKS=on bash "$HOOKS/pre-bash.sh")")" deny
awk '/^## Other/{print "- **Hooks:** on"; print ""} {print}' CLAUDE.md > c && mv c CLAUDE.md
check "hooks: the Hooks field turns them on for the project" "$(decision "$(hook_input "$PWD" "" "git push --force" "" | bash "$HOOKS/pre-bash.sh")")" deny
check "hooks: ARNESS_HOOKS=off wins over the Hooks field" "$(decision "$(hook_input "$PWD" "" "git push --force" "" | ARNESS_HOOKS=off bash "$HOOKS/pre-bash.sh")")" allow
check "hooks: session start is silent when off" "$(hook_input "$PWD" startup "" "" | ARNESS_HOOKS=off bash "$HOOKS/session-start.sh")" ""
git add -A && git commit -qm hooks-on

# ---------------- hooks: session start ----------------
out=$(hook_input "$PWD" startup "" "" | bash "$HOOKS/session-start.sh")
case "$out" in *'"additionalContext"'*Arness*) ok "session-start: adds a status line" ;; *) nok "session-start: adds a status line ($out)" ;; esac
mkdir -p .arness/plans/feat-x && echo '{}' > .arness/plans/feat-x/PROGRESS_TRACKER.json
out=$(hook_input "$PWD" compact "" "" | bash "$HOOKS/session-start.sh")
case "$out" in *feat-x/PROGRESS_TRACKER.json*) ok "session-start: points at the plan after compaction" ;; *) nok "session-start: compaction pointer ($out)" ;; esac

# ---------------- hooks: force push ----------------
for c in "git push --force origin main" "git -C . push -f" "git push origin +main"; do
  check "force-push: deny '$c'" "$(decision "$(hook_input "$PWD" "" "$c" "" | bash "$HOOKS/pre-bash.sh")")" deny
done
for c in "git push --force-with-lease origin main" "git push -u origin feat" "git status"; do
  check "force-push: allow '$c'" "$(decision "$(hook_input "$PWD" "" "$c" "" | bash "$HOOKS/pre-bash.sh")")" allow
done
check "force-push: switch turns it off" \
  "$(decision "$(hook_input "$PWD" "" "git push -f" "" | ARNESS_HOOKS_DISABLE=force-push bash "$HOOKS/pre-bash.sh")")" allow

# ---------------- hooks: secrets ----------------
key="AKIA""ABCDEFGHIJKLMNOP"
echo "x = 1" > ok.txt && git add ok.txt
check "secrets: clean commit allowed" "$(decision "$(hook_input "$PWD" "" 'git commit -m ok' "" | bash "$HOOKS/pre-bash.sh")")" allow
echo "k = \"$key\"" > conf.txt && git add conf.txt
check "secrets: staged key denied" "$(decision "$(hook_input "$PWD" "" 'git commit -m c' "" | bash "$HOOKS/pre-bash.sh")")" deny
echo "k = \"$key\"  # arness:allow-secret" > conf.txt && git add conf.txt
check "secrets: allow marker respected" "$(decision "$(hook_input "$PWD" "" 'git commit -m c' "" | bash "$HOOKS/pre-bash.sh")")" allow
git reset -q && rm -f conf.txt
echo "t=ghp_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" > new.txt
check "secrets: untracked key with 'git add .' denied" "$(decision "$(hook_input "$PWD" "" 'git add . && git commit -m x' "" | bash "$HOOKS/pre-bash.sh")")" deny
rm -f new.txt && touch .env
check "secrets: .env with 'git add -A' denied" "$(decision "$(hook_input "$PWD" "" 'git add -A && git commit -m e' "" | bash "$HOOKS/pre-bash.sh")")" deny
rm -f .env

# ---------------- hooks: lint ----------------
cat > .arness/tooling.json <<'EOF'
{"version":1,"services":[
 {"path":".","extensions":[".src"],"lintFiles":"! grep -n BAD {files}","owner":"arness"},
 {"path":"svc/b","extensions":[".src"],"lintFiles":"exit 3","owner":"project"}]}
EOF
mkdir -p svc/b; echo "BAD line" > "a file.src"; echo BAD > svc/b/x.src; echo BAD > notes.txt
lint() { hook_input "$PWD" "" "" "$PWD/$1" | bash "$HOOKS/post-edit-lint.sh"; }
check "lint: silent until tooling.json is approved" "$(lint "a file.src")" ""
bash "$HOOKS/tooling-approve.sh" >/dev/null
case "$(lint "a file.src")" in *advisory*"a file.src"*) ok "lint: reports issues after approval" ;; *) nok "lint: reports issues after approval" ;; esac
check "lint: skips services the project owns" "$(lint svc/b/x.src)" ""
check "lint: skips other extensions" "$(lint notes.txt)" ""
echo " " >> .arness/tooling.json
check "lint: edited tooling.json needs new approval" "$(lint "a file.src")" ""

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
