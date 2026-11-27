#!/bin/sh
#
# Behavioural guard for skills/queue/templates/withdraw (0242 S10: FR1–FR4, FR8, FR56; AC11).
#
# queue's Withdraw was a by-hand status: and next: edit, a dated note, the row removed and every
# blocked_by: naming the id re-pointed, under a by-hand lock. `withdraw` is that as one call.
#
# As in tests/capture.test.sh, assertions are about the RESULTING STATE, and every refusal is
# asserted on its message AND on the fixture being byte-for-byte unchanged — `exits non-zero` alone
# is satisfied by a refusal that half-edited a file first (`testing-conventions.md`).
#
# Usage:  tests/withdraw.test.sh
#
# Requires: git, sh, awk. No runner — this project has none.

set -eu
# Announce an abort instead of exiting silently (0169): a death under `set -eu` otherwise prints the
# passes reached and no tally. TALLIED=1 follows the tally; exiting without it says ABORTED and never
# exits 0. Byte-identical in every tests/*.test.sh, which tests/abort-announce.test.sh asserts.
TALLIED=""
announce_abort() {
  abort_status=$?
  if [ -z "$TALLIED" ]; then
    printf '\nABORTED before the tally: %s passed, %s failed so far (exit %s)\n' \
      "${PASS:-0}" "${FAIL:-0}" "$abort_status"
    [ "$abort_status" -ne 0 ] || abort_status=1
  fi
  if [ "$#" -gt 0 ]; then "$@" || true; fi
  exit "$abort_status"
}
trap announce_abort EXIT
# copy-begin: saw-prefix
# A declared copy: tests/declared-copies.test.sh reds unless every copy of this block is identical.
saw()         { printf '%s\n' "$1" | sed '1s/^/         saw: /; 1!s/^/              /'; }
# copy-end: saw-prefix
# copy-begin: saw-on-pass
# A declared copy: tests/declared-copies.test.sh reds unless every copy of this block is identical.
saw_on_pass() { [ -n "${SHOW_MATCHED:-}" ] && saw "$1"; return 0; }
# copy-end: saw-on-pass


ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
# The TEMPLATE copies run here, never .tickets/withdraw: a mutation applied to the installed copy
# lands a real diff and reddens nothing.
WITHDRAW_SRC="$ROOT/skills/queue/templates/withdraw"
NEXT_SRC="$ROOT/skills/queue/templates/next"
[ -f "$WITHDRAW_SRC" ] || { echo "no withdraw script at $WITHDRAW_SRC" >&2; exit 2; }

PASS=0
FAIL=0
FIX=""

cleanup() { [ -n "$FIX" ] && rm -rf "$FIX"; return 0; }
trap 'announce_abort cleanup' EXIT
trap cleanup INT TERM

ok()   { PASS=$((PASS + 1)); echo "  ok   — $1"; }
bad()  { FAIL=$((FAIL + 1)); echo "  FAIL — $1"; }

assert_contains() {
  case "$2" in
    *"$3"*) ok "$1"; saw_on_pass "$2" ;;
    *)      bad "$1"; echo "         expected to contain: $3"; saw "$2" ;;
  esac
}
assert_not_contains() {
  case "$2" in
    *"$3"*) bad "$1"; echo "         expected NOT to contain: $3"; saw "$2" ;;
    *)      ok "$1"; saw_on_pass "$2" ;;
  esac
}
assert_eq() {
  if [ "$2" = "$3" ]; then ok "$1"; saw_on_pass "$2"; else
    bad "$1"; echo "         expected exactly: $3"; saw "$2"; fi
}
assert_nonzero() {
  if [ "$2" -ne 0 ]; then ok "$1"; else bad "$1"; saw "wanted any exit but 0
$3"; fi
}


BL() { printf '%s' "$FIX/repo/.tickets"; }
# Every file under the backlog, the lock directory included: a refusal that half-wrote one, or left
# a .lock, changes this.
fingerprint() { (cd "$(BL)" && find . -path ./.lock -prune -o -type f -print | sort | xargs cksum; ls -d .lock 2>/dev/null || true); }
commits() { git -C "$FIX/repo" rev-list --count HEAD; }
data_ids() { awk -F'|' '/^\|/ { n++; if (n > 2) { v = $2; gsub(/ /, "", v); printf "%s ", v } }' "$(BL)/QUEUE.md"; }
fm() { awk -v k="$2" 'NR == 1 { next } /^---$/ { exit } index($0, k ":") == 1 { v = substr($0, length(k) + 2); sub(/^ /, "", v); print v; exit }' "$(BL)/items/$1-"*.md; }
row_status() { awk -F'|' -v id="$1" '/^\|/ { v = $2; gsub(/ /, "", v); if (v == id) { s = $5; gsub(/ /, "", s); print s } }' "$(BL)/QUEUE.md"; }

run() { # run <args...> — the withdraw under test, from the repo root; sets RC, OUT, ERR
  if (cd "$FIX/repo" && ./.tickets/withdraw "$@" >"$FIX/out" 2>"$FIX/err"); then RC=0; else RC=$?; fi
  OUT="$(cat "$FIX/out")"; ERR="$(cat "$FIX/err")"
}

item_md() { # item_md <id> <title> <next> <status> <blocked_by> [claimed_by]
  printf -- '---\nid: "%s"\ntitle: %s\nnext: %s\nstatus: %s\nparent:\nblocked_by: %s\nclaimed_by: %s\nclaimed_at:\ntouches:\n---\n\n## Acceptance criteria\n\n- [ ] AC1 — %s\n\n## Notes & decisions\n\n- 2026-11-01 — filed.\n' \
    "$1" "$2" "$3" "$4" "$5" "${6:-}" "$2"
}

# 0004 is blocked by nothing; 0005 is blocked by 0004; 0006 is open and will absorb it; 0007 is
# blocked by 0004 AND 0003 (done); 0002 is done and also names 0004.
fresh() {
  [ -z "$FIX" ] || rm -rf "$FIX"
  FIX="$(mktemp -d)"
  mkdir -p "$(BL)/items"
  git -C "$FIX/repo" init -q -b main
  git -C "$FIX/repo" config user.email fixture@example.com
  git -C "$FIX/repo" config user.name fixture
  cp "$WITHDRAW_SRC" "$NEXT_SRC" "$(BL)/"
  chmod +x "$(BL)/withdraw" "$(BL)/next"
  printf '# config\nnext_id: 8\nfindings_threshold: 20\n' > "$(BL)/config.yml"
  printf '# Backlog\n\n| ID | Title | Next | Status | Parent |\n|------|-------|------|--------|--------|\n| 0004 | Four | develop | %s |  |\n| 0005 | Five | develop | blocked |  |\n| 0006 | Six | develop | ready |  |\n| 0007 | Seven | design | blocked |  |\n' "${1:-ready}" > "$(BL)/QUEUE.md"
  item_md 0002 Two '' done '["0004"]' > "$(BL)/items/0002-two.md"
  item_md 0003 Three '' done '[]' > "$(BL)/items/0003-three.md"
  item_md 0004 Four develop "${1:-ready}" '[]' "${2:-}" > "$(BL)/items/0004-four.md"
  item_md 0005 Five develop blocked '["0004"]' > "$(BL)/items/0005-five.md"
  item_md 0006 Six develop ready '[]' > "$(BL)/items/0006-six.md"
  item_md 0007 Seven design blocked '["0003", "0004"]' > "$(BL)/items/0007-seven.md"
  git -C "$FIX/repo" add -A
  git -C "$FIX/repo" commit -q -m fixture
}

# --- AC11 ---------------------------------------------------------------------------------------
echo "0242 AC11 — ./withdraw 0004 \"merged\" --into 0006 keeps the record and re-points 0005"
fresh
before="$(commits)"
cfg="$(cksum < "$(BL)/config.yml")"
run 0004 "merged" --into 0006
assert_eq "exits 0" "$RC" 0
assert_eq "0004's item file stays" "$(ls "$(BL)/items" | grep -c '^0004-')" 1
assert_eq "0004 is status: withdrawn" "$(fm 0004 status)" withdrawn
assert_eq "0004's next: is empty" "$(grep '^next:' "$(BL)/items/0004-four.md")" "next:"
assert_eq "0004 carries a dated note with the reason, last in Notes & decisions" \
  "$(tail -1 "$(BL)/items/0004-four.md")" "- $(date -u +%Y-%m-%d) — **Withdrawn** by \`./withdraw\`: merged — absorbed into 0006"
assert_contains "the earlier note is kept" "$(cat "$(BL)/items/0004-four.md")" "- 2026-11-01 — filed."
assert_eq "its row is gone" "$(data_ids)" "0005 0006 0007 "
assert_eq "0005's blocked_by: names 0006" "$(fm 0005 blocked_by)" '["0006"]'
assert_eq "next_id is unchanged (config.yml byte-identical)" "$(cksum < "$(BL)/config.yml")" "$cfg"
assert_eq "one commit" "$(commits)" "$((before + 1))"
assert_eq "the commit names QUEUE.md and the three items it wrote" \
  "$(git -C "$FIX/repo" show --name-only --format= HEAD | sort | tr '\n' ' ')" \
  ".tickets/QUEUE.md .tickets/items/0004-four.md .tickets/items/0005-five.md .tickets/items/0007-seven.md "
assert_contains "the commit carries the trailer" "$(git -C "$FIX/repo" log -1 --format=%B)" "Co-Authored-By: "
assert_eq "leaves no lock" "$(ls -d "$(BL)/.lock" 2>/dev/null || true)" ""

echo "FR8 — the other dependents, and what is left alone"
assert_eq "0007 names 0003 and 0006, in order" "$(fm 0007 blocked_by)" '["0003", "0006"]'
assert_eq "0007 stays blocked, item and row" "$(fm 0007 status) $(row_status 0007)" "blocked blocked"
assert_eq "0005 stays blocked (0006 is open), item and row" "$(fm 0005 status) $(row_status 0005)" "blocked blocked"
assert_eq "0002 (done) is history and still names 0004" "$(fm 0002 blocked_by)" '["0004"]'
"$(BL)/next" --drift > "$FIX/drift" 2>&1 && drc=0 || drc=$?
assert_eq "./next --drift reports nothing afterwards" "$drc $(grep -c '^DRIFT' "$FIX/drift" || true)" "0 0"

echo "FR8 — no --into removes the entry, and re-derives blocked as ready, item and row"
fresh
run 0004 "not doing it"
assert_eq "exits 0" "$RC" 0
assert_eq "0005's blocked_by: is empty" "$(fm 0005 blocked_by)" '[]'
assert_eq "0005 is ready, item and row" "$(fm 0005 status) $(row_status 0005)" "ready ready"
assert_eq "0007 keeps only 0003" "$(fm 0007 blocked_by)" '["0003"]'
assert_eq "0007 is ready (0003 is done), item and row" "$(fm 0007 status) $(row_status 0007)" "ready ready"
assert_eq "the note carries no absorbed-into" "$(tail -1 "$(BL)/items/0004-four.md")" "- $(date -u +%Y-%m-%d) — **Withdrawn** by \`./withdraw\`: not doing it"
"$(BL)/next" --drift > "$FIX/drift" 2>&1 && drc=0 || drc=$?
assert_eq "./next --drift reports nothing afterwards" "$drc $(grep -c '^DRIFT' "$FIX/drift" || true)" "0 0"

echo "FR8 — a waiting item keeps its status: a person clears waiting, never a script"
fresh
item_md 0007 Seven design waiting '["0004"]' > "$(BL)/items/0007-seven.md"
sed -i 's/^| 0007 | Seven | design | blocked |/| 0007 | Seven | design | waiting |/' "$(BL)/QUEUE.md"
git -C "$FIX/repo" commit -q -am "0007 waiting"
run 0004 "not doing it"
assert_eq "0007's blocked_by: is empty" "$(fm 0007 blocked_by)" '[]'
assert_eq "0007 stays waiting, item and row" "$(fm 0007 status) $(row_status 0007)" "waiting waiting"
"$(BL)/next" --drift > "$FIX/drift" 2>&1 && drc=0 || drc=$?
assert_eq "./next --drift reports nothing afterwards" "$drc $(grep -c '^DRIFT' "$FIX/drift" || true)" "0 0"

echo "FR8 — the absorbing item never names itself, and a block-form list is read"
fresh
item_md 0006 Six develop blocked '' > "$(BL)/items/0006-six.md"
sed -i 's/^blocked_by: $/blocked_by:\n  - "0004"/' "$(BL)/items/0006-six.md"
sed -i 's/^| 0006 | Six | develop | ready |/| 0006 | Six | develop | blocked |/' "$(BL)/QUEUE.md"
git -C "$FIX/repo" commit -q -am "0006 blocked by 0004"
run 0004 "merged" --into 0006
assert_eq "exits 0" "$RC" 0
assert_eq "0006's blocked_by: is empty, not itself" "$(fm 0006 blocked_by)" '[]'
assert_not_contains "the block entry is gone" "$(cat "$(BL)/items/0006-six.md")" '  - "0004"'
assert_eq "0006 is ready, item and row" "$(fm 0006 status) $(row_status 0006)" "ready ready"

echo "FR8 — an entry already naming --into is not duplicated"
fresh
item_md 0005 Five develop blocked '["0004", "0006"]' > "$(BL)/items/0005-five.md"
git -C "$FIX/repo" commit -q -am "0005 also blocked by 0006"
run 0004 "merged" --into 0006
assert_eq "0005 names 0006 once" "$(fm 0005 blocked_by)" '["0006"]'

echo "FR8 — an item with no row is withdrawn, and says so"
fresh
sed -i '/^| 0004 /d' "$(BL)/QUEUE.md"
git -C "$FIX/repo" commit -q -am "0004 has no row"
run 0004 "a project"
assert_eq "exits 0" "$RC" 0
assert_eq "0004 is withdrawn" "$(fm 0004 status)" withdrawn
assert_contains "says it had no row" "$ERR" "had no row"

# --- refusals -----------------------------------------------------------------------------------
echo "FR8 — a claimed item is refused, changing nothing"
fresh in-progress ab12
before="$(commits)"; fp="$(fingerprint)"
run 0004 "merged" --into 0006
assert_nonzero "exits non-zero" "$RC" "$ERR"
assert_contains "names the holder" "$ERR" "[ab12]"
assert_eq "changes no file and leaves no lock" "$(fingerprint)" "$fp"
assert_eq "makes no commit" "$(commits)" "$before"

echo "FR8 — a row in progress is refused even with an empty claimed_by:"
fresh in-progress
fp="$(fingerprint)"
run 0004 "merged"
assert_nonzero "exits non-zero" "$RC" "$ERR"
assert_contains "names why" "$ERR" "in-progress"
assert_eq "changes no file and leaves no lock" "$(fingerprint)" "$fp"

echo "FR8 — a dependent held by another session is refused, changing nothing"
fresh
item_md 0005 Five develop blocked '["0004"]' cd34 > "$(BL)/items/0005-five.md"
git -C "$FIX/repo" commit -q -am "0005 held"
fp="$(fingerprint)"
run 0004 "merged" --into 0006
assert_nonzero "exits non-zero" "$RC" "$ERR"
assert_contains "names the dependent and its holder" "$ERR" "0005 names it in blocked_by: and is claimed by [cd34]"
assert_eq "changes no file and leaves no lock" "$(fingerprint)" "$fp"

echo "FR3 — malformed input is refused before the lock, changing nothing"
fresh
fp="$(fingerprint)"; before="$(commits)"
for args in "44|merged" "0004| " "0004|merged|--into|0004" "0004|merged|--into|66" "0004|merged|--into|0009" \
            "0004|merged|--into|0003" "0003|again" "0009|no such" "0004|merged|--sideways"; do
  old_ifs="$IFS"; IFS='|'
  # shellcheck disable=SC2086
  run $args
  IFS="$old_ifs"
  assert_nonzero "'$args' exits non-zero" "$RC" "$ERR"
  assert_eq "'$args' changes nothing and leaves no lock" "$(fingerprint)" "$fp"
done
assert_eq "no commit across them" "$(commits)" "$before"
run 0004 "two
lines"
assert_nonzero "a reason holding a line break exits non-zero" "$RC" "$ERR"
assert_eq "changes nothing" "$(fingerprint)" "$fp"

echo "FR3 — a file it would write, uncommitted, is refused"
fresh
printf '\nedit\n' >> "$(BL)/items/0005-five.md"
fp="$(fingerprint)"
run 0004 "merged" --into 0006
assert_nonzero "a dirty dependent exits non-zero" "$RC" "$ERR"
assert_contains "names it" "$ERR" "0005-five.md"
assert_contains "and releases the lock" "$ERR" "the lock is released"
assert_eq "changes nothing and leaves no lock" "$(fingerprint)" "$fp"
fresh
printf '\nedit\n' >> "$(BL)/QUEUE.md"
fp="$(fingerprint)"
run 0004 "merged"
assert_nonzero "a dirty QUEUE.md exits non-zero" "$RC" "$ERR"
assert_eq "changes nothing" "$(fingerprint)" "$fp"

# --- FR2 ----------------------------------------------------------------------------------------
echo "FR2 — another session's staged path stays staged and out of the commit"
fresh
printf 'x\n' > "$FIX/repo/other.txt"
git -C "$FIX/repo" add other.txt
run 0004 "merged" --into 0006
assert_eq "exits 0" "$RC" 0
assert_not_contains "the commit does not carry other.txt" "$(git -C "$FIX/repo" show --name-only --format= HEAD)" "other.txt"
assert_eq "other.txt is still staged" "$(git -C "$FIX/repo" diff --cached --name-only)" "other.txt"

# --- FR1 ----------------------------------------------------------------------------------------
echo "FR1 — a busy lock is retried, then refused, and never broken"
fresh
mkdir "$(BL)/.lock"; printf 'claim 0006\n' > "$(BL)/.lock/held-by"
before="$(commits)"
BACKLOG_LOCK_TRIES=2 run 0004 "merged"
assert_nonzero "exits non-zero" "$RC" "$ERR"
assert_contains "names the holder" "$ERR" "claim 0006"
assert_eq "the other session's lock is left in place" "$(cat "$(BL)/.lock/held-by")" "claim 0006"
assert_eq "no commit" "$(commits)" "$before"
assert_eq "0004 is untouched" "$(fm 0004 status)" ready

# --- FR56 ---------------------------------------------------------------------------------------
echo "FR56 — off the shared branch it refuses up front"
fresh
git -C "$FIX/repo" switch -q -c side
fp="$(fingerprint)"
run 0004 "merged"
assert_nonzero "exits non-zero" "$RC" "$ERR"
assert_contains "names both branches" "$ERR" "this checkout is on 'side', and the backlog is shared on 'main'"
assert_contains "takes no lock" "$ERR" "nothing was changed and no lock was taken"
assert_eq "changes nothing" "$(fingerprint)" "$fp"

echo "--help"
fresh
run --help
assert_eq "exits 0" "$RC" 0
assert_contains "prints usage" "$OUT" "usage: withdraw <id> <reason> [--into <absorbing-id>]"

echo
echo "withdraw: $PASS passed, $FAIL failed"
TALLIED=1
[ "$FAIL" -eq 0 ]
