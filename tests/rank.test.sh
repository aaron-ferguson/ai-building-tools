#!/bin/sh
#
# Behavioural guard for skills/queue/templates/rank (0242 S10: FR1–FR4, FR7, FR56; AC9, AC10).
#
# queue Step 4's Rerank was two single-line Edits to QUEUE.md under a by-hand lock, an append to
# RANKING.md and a commit by pathspec. `rank` is that composition as one call.
#
# As in tests/capture.test.sh, assertions are about the RESULTING STATE, and every refusal is
# asserted on its message AND on the fixture being byte-for-byte unchanged — `exits non-zero` alone
# is satisfied by a refusal that half-edited a file first (`testing-conventions.md`).
#
# Usage:  tests/rank.test.sh
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
# The TEMPLATE copy runs here, never .tickets/rank: a mutation applied to the installed copy lands a
# real diff and reddens nothing.
RANK_SRC="$ROOT/skills/queue/templates/rank"
[ -f "$RANK_SRC" ] || { echo "no rank script at $RANK_SRC" >&2; exit 2; }

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

run() { # run <args...> — the rank under test, from the repo root; sets RC, OUT, ERR
  if (cd "$FIX/repo" && ./.tickets/rank "$@" >"$FIX/out" 2>"$FIX/err"); then RC=0; else RC=$?; fi
  OUT="$(cat "$FIX/out")"; ERR="$(cat "$FIX/err")"
}

item_md() { # item_md <id> <title> <status> [claimed_by]
  printf -- '---\nid: "%s"\ntitle: %s\nnext: develop\nstatus: %s\nblocked_by: []\nclaimed_by: %s\n---\n\n## Acceptance criteria\n\n- [ ] AC1 — %s\n' \
    "$1" "$2" "$3" "${4:-}" "$2"
}

# Rows A (0001), B (0002), C (0003), with prose and a trailing line around the table, so "every
# other line unchanged" has lines to lose.
fresh() {
  [ -z "$FIX" ] || rm -rf "$FIX"
  FIX="$(mktemp -d)"
  mkdir -p "$(BL)/items"
  git -C "$FIX/repo" init -q -b main
  git -C "$FIX/repo" config user.email fixture@example.com
  git -C "$FIX/repo" config user.name fixture
  cp "$RANK_SRC" "$(BL)/"
  chmod +x "$(BL)/rank"
  printf '# config\nnext_id: 4\n' > "$(BL)/config.yml"
  printf '# Backlog\n\nLine order is the rank.\n\n| ID | Title | Next | Status | Parent |\n|------|-------|------|--------|--------|\n| 0001 | Alpha | develop | ready |  |\n| 0002 | Bravo | develop | %s |  |\n| 0003 | Charlie | design | ready |  |\n\ntrailing prose\n' "${1:-ready}" > "$(BL)/QUEUE.md"
  printf '# Ranking\n\nstanding text\n' > "$(BL)/RANKING.md"
  item_md 0001 Alpha ready > "$(BL)/items/0001-alpha.md"
  item_md 0002 Bravo "${1:-ready}" "${2:-}" > "$(BL)/items/0002-bravo.md"
  item_md 0003 Charlie ready > "$(BL)/items/0003-charlie.md"
  git -C "$FIX/repo" add -A
  git -C "$FIX/repo" commit -q -m fixture
}

# --- AC9 ----------------------------------------------------------------------------------------
echo "0242 AC9 — ./rank C above:A gives C, A, B with every other line unchanged, in one commit"
fresh
before="$(commits)"
cp "$(BL)/QUEUE.md" "$FIX/queue.before"
run 0003 above:0001
assert_eq "exits 0" "$RC" 0
assert_eq "the order is C, A, B" "$(data_ids)" "0003 0001 0002 "
assert_eq "every other line of QUEUE.md is unchanged, in its order" \
  "$(grep -v '^| 0003 ' "$(BL)/QUEUE.md")" "$(grep -v '^| 0003 ' "$FIX/queue.before")"
assert_eq "the moved row's own line is byte-identical" \
  "$(grep '^| 0003 ' "$(BL)/QUEUE.md")" "$(grep '^| 0003 ' "$FIX/queue.before")"
assert_eq "the line count is unchanged" "$(wc -l < "$(BL)/QUEUE.md")" "$(wc -l < "$FIX/queue.before")"
assert_eq "makes exactly one commit" "$(commits)" "$((before + 1))"
assert_eq "the commit names only QUEUE.md" "$(git -C "$FIX/repo" show --name-only --format= HEAD)" ".tickets/QUEUE.md"
assert_contains "the commit carries the trailer" "$(git -C "$FIX/repo" log -1 --format=%B)" "Co-Authored-By: "
assert_eq "leaves no lock" "$(ls -d "$(BL)/.lock" 2>/dev/null || true)" ""

echo "FR7 — below:, top and --ranking"
fresh
run 0001 below:0003
assert_eq "below:0003 moves A under C" "$(data_ids)" "0002 0003 0001 "
run 0003 top
assert_eq "top moves C to the first row" "$(data_ids)" "0003 0002 0001 "
printf 'Charlie first: it unblocks the rest.\n' > "$FIX/why.md"
before="$(commits)"
run 0002 top --ranking "$FIX/why.md"
assert_eq "--ranking: exits 0" "$RC" 0
assert_eq "--ranking: one commit" "$(commits)" "$((before + 1))"
assert_eq "--ranking: the text is appended to RANKING.md" "$(tail -1 "$(BL)/RANKING.md")" "Charlie first: it unblocks the rest."
assert_contains "--ranking: the standing text is kept" "$(cat "$(BL)/RANKING.md")" "standing text"
assert_eq "--ranking: the commit names QUEUE.md and RANKING.md" \
  "$(git -C "$FIX/repo" show --name-only --format= HEAD | sort | tr '\n' ' ')" ".tickets/QUEUE.md .tickets/RANKING.md "

echo "FR7 — a row already at its position commits nothing"
fresh
before="$(commits)"; fp="$(fingerprint)"
run 0001 top
assert_eq "exits 0" "$RC" 0
assert_contains "says nothing moved" "$OUT" "already at top"
assert_eq "no commit" "$(commits)" "$before"
assert_eq "no file changed" "$(fingerprint)" "$fp"

# --- AC10 ---------------------------------------------------------------------------------------
echo "0242 AC10 — B in-progress under a token: ./rank B top refuses and changes nothing"
fresh in-progress ab12
before="$(commits)"; fp="$(fingerprint)"
run 0002 top
assert_nonzero "exits non-zero" "$RC" "$ERR"
assert_contains "names why" "$ERR" "in-progress"
assert_eq "changes no file and leaves no lock" "$(fingerprint)" "$fp"
assert_eq "makes no commit" "$(commits)" "$before"
assert_eq "the order is unchanged" "$(data_ids)" "0001 0002 0003 "

echo "AC10 — a token on the item alone is refused too (the cell and claimed_by: are both read)"
fresh ready cd34
fp="$(fingerprint)"
run 0002 top
assert_nonzero "exits non-zero" "$RC" "$ERR"
assert_contains "names the holder" "$ERR" "[cd34]"
assert_eq "changes no file and leaves no lock" "$(fingerprint)" "$fp"

echo "AC10 — moving ANOTHER row past an in-progress one is allowed"
fresh in-progress ab12
run 0003 top
assert_eq "exits 0" "$RC" 0
assert_eq "C moves to the top; B keeps its line" "$(data_ids)" "0003 0001 0002 "

# --- FR3 ----------------------------------------------------------------------------------------
echo "FR3 — malformed input is refused before the lock, changing nothing"
for args in "12 top" "0002 middle" "0002 above:12" "0002 above:0002" "0002 top --sideways"; do
  fresh
  fp="$(fingerprint)"; before="$(commits)"
  # shellcheck disable=SC2086
  run $args
  assert_nonzero "'$args' exits non-zero" "$RC" "$ERR"
  assert_eq "'$args' changes nothing and leaves no lock" "$(fingerprint)" "$fp"
  assert_eq "'$args' makes no commit" "$(commits)" "$before"
done
fresh
fp="$(fingerprint)"
run 0009 top
assert_nonzero "a row not in QUEUE.md exits non-zero" "$RC" "$ERR"
assert_contains "names it" "$ERR" "no row in QUEUE.md"
assert_eq "changes nothing and leaves no lock" "$(fingerprint)" "$fp"
run 0002 above:9999
assert_nonzero "an anchor that is no row exits non-zero" "$RC" "$ERR"
assert_contains "names the anchor" "$ERR" "above:9999 names no row"
assert_eq "changes nothing and leaves no lock" "$(fingerprint)" "$fp"
: > "$FIX/empty.md"
run 0002 top --ranking "$FIX/empty.md"
assert_nonzero "an empty --ranking exits non-zero" "$RC" "$ERR"
assert_eq "changes nothing" "$(fingerprint)" "$fp"

echo "FR3 — QUEUE.md uncommitted is refused"
fresh
printf '\nedit\n' >> "$(BL)/QUEUE.md"
fp="$(fingerprint)"
run 0003 top
assert_nonzero "exits non-zero" "$RC" "$ERR"
assert_contains "names the dirty file" "$ERR" "QUEUE.md"
assert_eq "changes nothing" "$(fingerprint)" "$fp"

# --- FR2 ----------------------------------------------------------------------------------------
echo "FR2 — another session's staged path stays staged and out of the commit"
fresh
printf 'x\n' > "$FIX/repo/other.txt"
git -C "$FIX/repo" add other.txt
run 0003 top
assert_eq "exits 0" "$RC" 0
assert_not_contains "the commit does not carry other.txt" "$(git -C "$FIX/repo" show --name-only --format= HEAD)" "other.txt"
assert_eq "other.txt is still staged" "$(git -C "$FIX/repo" diff --cached --name-only)" "other.txt"

# --- FR1 ----------------------------------------------------------------------------------------
echo "FR1 — a busy lock is retried, then refused, and never broken"
fresh
mkdir "$(BL)/.lock"; printf 'claim 0001\n' > "$(BL)/.lock/held-by"
before="$(commits)"
BACKLOG_LOCK_TRIES=2 run 0003 top
assert_nonzero "exits non-zero" "$RC" "$ERR"
assert_contains "names the holder" "$ERR" "claim 0001"
assert_eq "the other session's lock is left in place" "$(cat "$(BL)/.lock/held-by")" "claim 0001"
assert_eq "no commit" "$(commits)" "$before"
rm -rf "$(BL)/.lock"
( sleep 1; rm -rf "$(BL)/.lock" ) &
mkdir "$(BL)/.lock"
BACKLOG_LOCK_TRIES=5 run 0003 top
wait
assert_eq "a lock released while retrying is then taken: exits 0" "$RC" 0
assert_eq "and the lock is released afterwards" "$(ls -d "$(BL)/.lock" 2>/dev/null || true)" ""

# --- FR56 ---------------------------------------------------------------------------------------
echo "FR56 — off the shared branch it refuses up front"
fresh
git -C "$FIX/repo" switch -q -c side
fp="$(fingerprint)"
run 0003 top
assert_nonzero "exits non-zero" "$RC" "$ERR"
assert_contains "names both branches" "$ERR" "this checkout is on 'side', and the backlog is shared on 'main'"
assert_contains "takes no lock" "$ERR" "nothing was changed and no lock was taken"
assert_eq "changes nothing" "$(fingerprint)" "$fp"

echo "--help"
fresh
run --help
assert_eq "exits 0" "$RC" 0
assert_contains "prints usage" "$OUT" "usage: rank <id> <top|above:<row-id>|below:<row-id>> [--ranking <file>]"

echo
echo "rank: $PASS passed, $FAIL failed"
TALLIED=1
[ "$FAIL" -eq 0 ]
