#!/bin/sh
#
# Behavioural guard for skills/queue/templates/capture (0242 S8: FR1–FR5, FR9, FR56).
#
# queue Step 2's Add was the largest by-hand backlog write left: mint an id, bump next_id, write the
# item, insert the row, stamp ac_digest, append to RANKING.md, commit by pathspec, release the lock.
# `capture` is that composition as one call, and `capture --restamp` is the Re-specify path's stamp.
#
# As in tests/reopen.test.sh, assertions are about the RESULTING STATE, and every refusal is
# asserted on its message AND on the fixture being byte-for-byte unchanged — `exits non-zero` alone
# is satisfied by a refusal that half-edited a file first (`testing-conventions.md`).
#
# Usage:  tests/capture.test.sh
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
# The TEMPLATE copies run here, never .tickets/capture: a mutation applied to the installed copy
# lands a real diff and reddens nothing.
CAPTURE_SRC="$ROOT/skills/queue/templates/capture"
NEXT_SRC="$ROOT/skills/queue/templates/next"
[ -f "$CAPTURE_SRC" ] || { echo "no capture script at $CAPTURE_SRC" >&2; exit 2; }

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

run() { # run <args...> — the capture under test, from the repo root; sets RC, OUT, ERR
  if (cd "$FIX/repo" && ./.tickets/capture "$@" >"$FIX/out" 2>"$FIX/err"); then RC=0; else RC=$?; fi
  OUT="$(cat "$FIX/out")"; ERR="$(cat "$FIX/err")"
}

item_md() { # item_md <id> <title> <next> <status> [claimed_by]
  printf -- '---\nid: "%s"\ntitle: %s\ntype: bug\nnext: %s\nstatus: %s\nparent:\nblocked_by: []\nclaimed_by: %s\n---\n\n## Acceptance criteria\n\n- [ ] AC1 — %s first\n- [ ] AC2 — %s second\n\n## Notes & decisions\n' \
    "$1" "$2" "$3" "$4" "${5:-}" "$2" "$2"
}

# A fixture whose next_id (5) LAGS the disk (0007 is on it), which is the drift AC1 is about.
fresh() {
  [ -z "$FIX" ] || rm -rf "$FIX"
  FIX="$(mktemp -d)"
  mkdir -p "$(BL)/items"
  git -C "$FIX/repo" init -q -b main
  git -C "$FIX/repo" config user.email fixture@example.com
  git -C "$FIX/repo" config user.name fixture
  cp "$CAPTURE_SRC" "$NEXT_SRC" "$(BL)/"
  chmod +x "$(BL)/capture" "$(BL)/next"
  printf '# config\nnext_id: 5\nfindings_threshold: 20\n' > "$(BL)/config.yml"
  printf '# Backlog\n\n| ID | Title | Next | Status | Parent |\n|------|-------|------|--------|--------|\n| 0001 | One | develop | ready |  |\n| 0003 | Three | develop | ready |  |\n' > "$(BL)/QUEUE.md"
  printf '# Ranking\n\nstanding text\n' > "$(BL)/RANKING.md"
  item_md 0001 One develop ready > "$(BL)/items/0001-one.md"
  item_md 0003 Three develop ready > "$(BL)/items/0003-three.md"
  printf -- '---\nid: "0007"\ntitle: Old\nnext:\nstatus: done\n---\n' > "$(BL)/items/0007-old.md"
  for i in 0001 0003; do
    d="$("$(BL)/next" --ac-digest "$i")"
    f="$(ls "$(BL)/items/$i-"*.md)"
    awk -v l="$d" 'NR > 1 && /^---$/ && !s { print l; s = 1 } { print }' "$f" > "$FIX/t" && cat "$FIX/t" > "$f"
  done
  git -C "$FIX/repo" add -A
  git -C "$FIX/repo" commit -q -m fixture
  item_md NNNN 'Make the thing work, properly' develop ready > "$FIX/draft.md"
}

# --- AC1 ----------------------------------------------------------------------------------------
echo "0242 AC1 — mint from the disk, correct next_id, insert above the anchor, one commit"
fresh
before="$(commits)"
run "$FIX/draft.md" above:0003
assert_eq "exits 0" "$RC" 0
written="$(ls "$(BL)/items" | grep '^0008-' || true)"
assert_eq "writes items/0008-<slug>.md" "$written" "0008-make-the-thing-work-properly.md"
assert_contains "the item carries id 0008" "$(cat "$(BL)/items/0008-"*.md 2>/dev/null)" 'id: "0008"'
assert_eq "sets next_id: 9" "$(grep '^next_id:' "$(BL)/config.yml")" "next_id: 9"
assert_eq "inserts the row directly above 0003" "$(data_ids)" "0001 0008 0003 "
assert_eq "makes exactly one commit" "$(commits)" "$((before + 1))"
assert_eq "the commit names only QUEUE.md, config.yml and the item" \
  "$(git -C "$FIX/repo" show --name-only --format= HEAD | sort | tr '\n' ' ')" \
  ".tickets/QUEUE.md .tickets/config.yml .tickets/items/0008-make-the-thing-work-properly.md "
assert_eq "prints the new id last" "$(printf '%s\n' "$OUT" | tail -1)" "0008"
assert_contains "the commit carries the trailer" "$(git -C "$FIX/repo" log -1 --format=%B)" "Co-Authored-By: "
assert_eq "no .lock is left" "$(ls -d "$(BL)/.lock" 2>/dev/null || true)" ""

# --- AC2 ----------------------------------------------------------------------------------------
echo "0242 AC2 — the stamp equals ./next --ac-digest over the written item"
stamped="$(grep '^ac_digest:' "$(BL)/items/0008-"*.md || true)"
computed="$("$(BL)/next" --ac-digest 0008)"
assert_eq "the item's ac_digest: line is ./next --ac-digest 0008's output" "$stamped" "$computed"
assert_contains "and it stamps both criteria" "$stamped" "AC1="
assert_contains "and it stamps both criteria (AC2)" "$stamped" "AC2="

# --- the other positions, and --ranking --------------------------------------------------------
echo "0242 FR5 — top, below:, and --ranking's text appended to RANKING.md"
fresh
run "$FIX/draft.md" top
assert_eq "top puts the row first" "$(data_ids)" "0008 0001 0003 "
item_md NNNN 'Second' design ready > "$FIX/draft2.md"
printf 'why 0009 sits below 0001\n' > "$FIX/rank.txt"
run "$FIX/draft2.md" below:0001 --ranking "$FIX/rank.txt"
assert_eq "exits 0" "$RC" 0
assert_eq "below:0001 puts the row directly under 0001, and the id climbs to 0009" "$(data_ids)" "0008 0001 0009 0003 "
assert_eq "next_id follows to 10" "$(grep '^next_id:' "$(BL)/config.yml")" "next_id: 10"
assert_eq "the row carries the draft's next: and status:" \
  "$(grep '^| 0009 ' "$(BL)/QUEUE.md")" "| 0009 | Second | design | ready |  |"
assert_eq "RANKING.md ends with the --ranking text" "$(tail -1 "$(BL)/RANKING.md")" "why 0009 sits below 0001"
assert_contains "and the commit carries RANKING.md" "$(git -C "$FIX/repo" show --name-only --format= HEAD)" ".tickets/RANKING.md"

# --- AC3 ----------------------------------------------------------------------------------------
echo "0242 AC3 — a draft with no AC1 line is refused and changes nothing"
fresh
grep -v 'AC1 —' "$FIX/draft.md" > "$FIX/noac.md"
fp="$(fingerprint)"; before="$(commits)"
run "$FIX/noac.md" above:0003
assert_nonzero "exits non-zero" "$RC" "$ERR"
assert_contains "names what is wrong" "$ERR" "no '- [ ] AC1 —' line"
assert_eq "writes no file, leaves QUEUE.md and config.yml byte-identical, leaves no .lock" "$(fingerprint)" "$fp"
assert_eq "makes no commit" "$(commits)" "$before"
for bad_case in 'title' 'next' 'status'; do
  case "$bad_case" in
    title)  sed 's/^title: .*/title:/' "$FIX/draft.md" > "$FIX/bad.md"; want="no title:" ;;
    next)   sed 's/^next: .*/next: build/' "$FIX/draft.md" > "$FIX/bad.md"; want="next: is 'build'" ;;
    status) sed 's/^status: .*/status: in-progress/' "$FIX/draft.md" > "$FIX/bad.md"; want="status: is 'in-progress'" ;;
  esac
  run "$FIX/bad.md" top
  assert_contains "a draft with a bad $bad_case is refused by name" "$ERR" "$want"
  assert_eq "and changes nothing" "$(fingerprint)" "$fp"
done

# --- AC4 ----------------------------------------------------------------------------------------
echo "0242 AC4 — another session's staged path stays staged and out of the capture commit"
fresh
printf 'theirs\n' > "$FIX/repo/other.txt"
git -C "$FIX/repo" add other.txt
run "$FIX/draft.md" top
assert_eq "exits 0" "$RC" 0
assert_not_contains "other.txt is absent from the capture commit" \
  "$(git -C "$FIX/repo" show --name-only --format= HEAD)" "other.txt"
assert_eq "and is still staged afterwards" "$(git -C "$FIX/repo" diff --cached --name-only)" "other.txt"

# --- AC5 ----------------------------------------------------------------------------------------
echo "0242 AC5 — an anchor that is no row is refused before minting"
fresh
fp="$(fingerprint)"; before="$(commits)"
run "$FIX/draft.md" above:9999
assert_nonzero "exits non-zero" "$RC" "$ERR"
assert_contains "names the anchor" "$ERR" "above:9999 names no row in QUEUE.md"
assert_eq "changes no file and leaves no .lock" "$(fingerprint)" "$fp"
assert_eq "makes no commit" "$(commits)" "$before"
assert_eq "and leaves nothing staged" "$(git -C "$FIX/repo" diff --cached --name-only)" ""
run "$FIX/draft.md" sideways
assert_contains "a position it cannot parse is refused by name" "$ERR" "'sideways' is not a position"

# --- FR1 / FR2 / FR56 -------------------------------------------------------------------------
echo "0242 FR1 — a busy lock is retried, then refused, and never broken"
fresh
mkdir "$(BL)/.lock" && printf 'claim 0001 by cd34\n' > "$(BL)/.lock/held-by"
BACKLOG_LOCK_TRIES=1; export BACKLOG_LOCK_TRIES
run "$FIX/draft.md" top
unset BACKLOG_LOCK_TRIES
assert_nonzero "exits non-zero" "$RC" "$ERR"
assert_contains "names the holder" "$ERR" "backlog is locked by: claim 0001 by cd34"
assert_eq "the other session's lock is still there" "$(cat "$(BL)/.lock/held-by")" "claim 0001 by cd34"
assert_eq "and no item was written" "$(ls "$(BL)/items" | grep -c '^0008-' || true)" "0"
rm -rf "$(BL)/.lock"
( sleep 1; rm -rf "$(BL)/.lock" ) &
mkdir "$(BL)/.lock"
BACKLOG_LOCK_TRIES=5; export BACKLOG_LOCK_TRIES
run "$FIX/draft.md" top
unset BACKLOG_LOCK_TRIES
wait
assert_eq "a lock released while it waits is taken, and the capture lands" "$RC" 0

echo "0242 FR2 — uncommitted changes to a file the commit names are refused, not carried"
fresh
printf '\nsomeone else\n' >> "$(BL)/QUEUE.md"
fp="$(fingerprint)"
run "$FIX/draft.md" top
assert_nonzero "exits non-zero" "$RC" "$ERR"
assert_contains "names the file" "$ERR" "QUEUE.md"
assert_eq "and changes nothing" "$(fingerprint)" "$fp"

echo "0242 FR56 — refused up front off the shared branch"
fresh
git -C "$FIX/repo" switch -q -c feature
fp="$(fingerprint)"
run "$FIX/draft.md" top
assert_nonzero "exits non-zero" "$RC" "$ERR"
assert_contains "names both branches" "$ERR" "this checkout is on 'feature', and the backlog is shared on 'main'"
assert_eq "and changes nothing" "$(fingerprint)" "$fp"

echo "0242 FR4 — --help prints usage and exits zero"
run --help
assert_eq "exits 0" "$RC" 0
assert_contains "documents the capture form" "$OUT" "capture <draft> <top|above:<row-id>|below:<row-id>> [--ranking <file>]"
assert_contains "documents the restamp form" "$OUT" "capture --restamp <id>"

# --- AC12 ---------------------------------------------------------------------------------------
echo "0242 AC12 — --restamp re-stamps an edited, unclaimed item so --drift reports no mismatch"
fresh
sed 's/AC2 — Three second/AC2 — Three second, sharpened/' "$(BL)/items/0003-three.md" > "$FIX/t"
cat "$FIX/t" > "$(BL)/items/0003-three.md"
drift_before="$("$(BL)/next" --drift 2>&1 || true)"
assert_contains "control: before the restamp --drift reports 0003's AC2 changed" "$drift_before" "0003"
assert_contains "control: and names the digest" "$drift_before" "AC2"
before="$(commits)"
run --restamp 0003
assert_eq "exits 0" "$RC" 0
drift_after="$("$(BL)/next" --drift 2>&1 || true)"
assert_not_contains "after it, --drift reports no digest mismatch for 0003" "$drift_after" "0003"
assert_eq "--check agrees" "$("$(BL)/next" --ac-digest 0003 --check)" "0003: ac_digest matches"
assert_eq "one commit" "$(commits)" "$((before + 1))"
assert_eq "naming only the item, its edit included" \
  "$(git -C "$FIX/repo" show --name-only --format= HEAD)" ".tickets/items/0003-three.md"
assert_eq "the tree is clean after it" "$(git -C "$FIX/repo" status --porcelain)" ""

echo "0242 FR9 — --restamp refuses a claimed item"
fresh
item_md 0003 Three develop in-progress ab12 > "$(BL)/items/0003-three.md"
git -C "$FIX/repo" commit -q -m hold -- .tickets/items/0003-three.md
fp="$(fingerprint)"; before="$(commits)"
run --restamp 0003
assert_nonzero "exits non-zero" "$RC" "$ERR"
assert_contains "names the holder" "$ERR" "claimed by [ab12]"
assert_eq "and changes nothing" "$(fingerprint)" "$fp"
assert_eq "and commits nothing" "$(commits)" "$before"

echo
echo "capture: $PASS passed, $FAIL failed"
TALLIED=1
[ "$FAIL" -eq 0 ]
