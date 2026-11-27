#!/bin/sh
#
# Behavioural guard for skills/queue/templates/drain (0242 S11: FR1–FR4, FR10, FR56; AC13, AC14).
#
# A sweeper draining FINDINGS.md removed, marked or held entries by hand, finding them with the
# regex the buffer's header gives — and that regex also matches the header's own fenced example,
# which is how this repo's own buffer lost its example line (0227). `drain` acts only on an entry
# `./next --findings-list` names, by its line number, so the header is never a candidate.
#
# As in tests/withdraw.test.sh, assertions are about the RESULTING STATE, and every refusal is
# asserted on its message AND on the fixture being byte-for-byte unchanged.
#
# Usage:  tests/drain.test.sh
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
# The TEMPLATE copies run here, never .tickets/drain: a mutation applied to the installed copy
# lands a real diff and reddens nothing.
DRAIN_SRC="$ROOT/skills/queue/templates/drain"
NEXT_SRC="$ROOT/skills/queue/templates/next"
BUFFER_SRC="$ROOT/skills/queue/templates/FINDINGS.md"
[ -f "$DRAIN_SRC" ] || { echo "no drain script at $DRAIN_SRC" >&2; exit 2; }

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
BUF() { printf '%s' "$FIX/repo/.tickets/FINDINGS.md"; }
HELD() { printf '%s' "$FIX/repo/.tickets/FINDINGS-HELD.md"; }
fingerprint() { (cd "$(BL)" && find . -path ./.lock -prune -o -type f -print | sort | xargs cksum; ls -d .lock 2>/dev/null || true); }
commits() { git -C "$FIX/repo" rev-list --count HEAD; }
committed_paths() { git -C "$FIX/repo" show --name-only --format= HEAD | sort | tr '\n' ' '; }
# The preamble: every line up to and including the `---` rule, which is where entries begin.
header_of_buf() { awk '{ print } /^---$/ { exit }' "$1"; }

run() { # run <args...> — the drain under test, from the repo root; sets RC, OUT, ERR
  if (cd "$FIX/repo" && ./.tickets/drain "$@" >"$FIX/out" 2>"$FIX/err"); then RC=0; else RC=$?; fi
  OUT="$(cat "$FIX/out")"; ERR="$(cat "$FIX/err")"
}

# The real entries. E1 shares its date with the header's fenced example; E2 has a continuation line;
# E3 is already marked.
E1='- 2026-09-05 — **the real one.** it shares a date with the example (pointer: 0060)'
E2='- 2026-09-06 — **a two-line entry.** whose second line'
E2b='  is part of it (pointer: tests/drain.test.sh)'
E3='- 2026-09-07 [->none] — **already read.** no destination yet'

# A fixture backlog whose buffer is the SHIPPED template, so the header is the one every project
# carries, fenced example included, plus the three entries above.
fresh() {
  [ -z "$FIX" ] || rm -rf "$FIX"
  FIX="$(mktemp -d)"
  mkdir -p "$(BL)/items"
  git -C "$FIX/repo" init -q -b main
  git -C "$FIX/repo" config user.email fixture@example.com
  git -C "$FIX/repo" config user.name fixture
  cp "$DRAIN_SRC" "$NEXT_SRC" "$(BL)/"
  chmod +x "$(BL)/drain" "$(BL)/next"
  printf '# config\nnext_id: 61\nfindings_threshold: 20\n' > "$(BL)/config.yml"
  printf '# Backlog\n\n| ID | Title | Next | Status | Parent |\n|------|-------|------|--------|--------|\n| 0060 | Sixty | develop | ready |  |\n' > "$(BL)/QUEUE.md"
  printf -- '---\nid: "0060"\ntitle: Sixty\nnext: develop\nstatus: ready\nblocked_by: []\nclaimed_by:\n---\n' > "$(BL)/items/0060-sixty.md"
  { cat "$BUFFER_SRC"; printf '%s\n%s\n%s\n%s\n' "$E1" "$E2" "$E2b" "$E3"; } > "$(BUF)"
  git -C "$FIX/repo" add -A
  git -C "$FIX/repo" commit -q -m fixture
}

# --- the fixture is what AC13 says it is ---------------------------------------------------------
echo "fixture — the shipped header carries the fenced example the AC names"
fresh
assert_contains "the header holds '- 2026-09-05 [->0060] — '" "$(header_of_buf "$(BUF)")" "- 2026-09-05 [->0060] — "
assert_eq "./next --findings-list names three entries, none of them in the header" \
  "$("$(BL)/next" --findings-list | wc -l | tr -d ' ')" 3

# --- AC13 ---------------------------------------------------------------------------------------
echo "0242 AC13 — ./drain 2026-09-05 removed removes the real entry and leaves the header byte-identical"
fresh
hdr="$(header_of_buf "$(BUF)" | cksum)"
before="$(commits)"
run 2026-09-05 removed
assert_eq "exits 0" "$RC" 0
assert_eq "the header is byte-identical" "$(header_of_buf "$(BUF)" | cksum)" "$hdr"
assert_contains "the header's fenced example is still there" "$(cat "$(BUF)")" "- 2026-09-05 [->0060] — **what happened.**"
assert_not_contains "the real 2026-09-05 entry is gone" "$(cat "$(BUF)")" "$E1"
assert_contains "the other entries stay" "$(cat "$(BUF)")" "$E2
$E2b
$E3"
assert_eq "one commit" "$(commits)" "$((before + 1))"
assert_eq "the commit names only FINDINGS.md" "$(committed_paths)" ".tickets/FINDINGS.md "
assert_contains "the commit carries the trailer" "$(git -C "$FIX/repo" log -1 --format=%B)" "Co-Authored-By: "
assert_eq "leaves no lock" "$(ls -d "$(BL)/.lock" 2>/dev/null || true)" ""
assert_eq "the tree is clean" "$(git -C "$FIX/repo" status --porcelain)" ""

echo "FR10 — removing an entry removes its continuation lines with it"
fresh
run 2026-09-06 removed
assert_eq "exits 0" "$RC" 0
assert_not_contains "the first line is gone" "$(cat "$(BUF)")" "$E2"
assert_not_contains "the continuation line is gone" "$(cat "$(BUF)")" "$E2b"
assert_eq "two entries are left" "$("$(BL)/next" --findings-list | wc -l | tr -d ' ')" 2

# --- AC14 ---------------------------------------------------------------------------------------
echo "0242 AC14 — ./drain <date> held moves the entry verbatim to FINDINGS-HELD.md in one commit"
fresh
printf '# Findings held\n\n- 2026-08-01 — an older held entry\n' > "$(HELD)"
git -C "$FIX/repo" add -A; git -C "$FIX/repo" commit -q -m "held file"
before="$(commits)"
run 2026-09-06 held
assert_eq "exits 0" "$RC" 0
assert_not_contains "the entry is absent from FINDINGS.md" "$(cat "$(BUF)")" "$E2"
assert_not_contains "its continuation is absent from FINDINGS.md" "$(cat "$(BUF)")" "$E2b"
assert_eq "it is present verbatim, last, in FINDINGS-HELD.md" "$(tail -2 "$(HELD)")" "$E2
$E2b"
assert_contains "the held file's earlier content is kept" "$(cat "$(HELD)")" "- 2026-08-01 — an older held entry"
assert_eq "one commit" "$(commits)" "$((before + 1))"
assert_eq "both changes are in it" "$(committed_paths)" ".tickets/FINDINGS-HELD.md .tickets/FINDINGS.md "
assert_eq "the tree is clean" "$(git -C "$FIX/repo" status --porcelain)" ""

echo "FR10 — held with no FINDINGS-HELD.md yet creates and commits it"
fresh
run 2026-09-05 held
assert_eq "exits 0" "$RC" 0
assert_eq "the held file ends with the entry" "$(tail -1 "$(HELD)")" "$E1"
assert_eq "the commit carries both files" "$(committed_paths)" ".tickets/FINDINGS-HELD.md .tickets/FINDINGS.md "
assert_eq "the tree is clean" "$(git -C "$FIX/repo" status --porcelain)" ""

# --- marked -------------------------------------------------------------------------------------
echo "FR10 — marked:<row-id> writes the head token after the date, in place"
fresh
run 2026-09-05 marked:0060
assert_eq "exits 0" "$RC" 0
assert_contains "the entry carries [->0060] after its date" "$(cat "$(BUF)")" \
  "- 2026-09-05 [->0060] — **the real one.** it shares a date with the example (pointer: 0060)"
assert_eq "the entry stays where it was (line count unchanged)" "$(wc -l < "$(BUF)" | tr -d ' ')" \
  "$(git -C "$FIX/repo" show HEAD~1:.tickets/FINDINGS.md | wc -l | tr -d ' ')"
assert_eq "the commit names only FINDINGS.md" "$(committed_paths)" ".tickets/FINDINGS.md "

echo "FR10 — marked <row-id> (the trailing form) and marked:none replace an existing token"
fresh
run 2026-09-07 marked 0060
assert_eq "exits 0" "$RC" 0
assert_contains "[->none] becomes [->0060]" "$(cat "$(BUF)")" "- 2026-09-07 [->0060] — **already read.**"
assert_not_contains "no doubled token" "$(cat "$(BUF)")" "[->0060] [->none]"
fresh
run 2026-09-05 marked:none
assert_eq "marked:none exits 0" "$RC" 0
assert_contains "the entry carries [->none]" "$(cat "$(BUF)")" "- 2026-09-05 [->none] — **the real one.**"

# --- refusals: nothing changed, no lock, no commit ----------------------------------------------
refuses() { # refuses <label> <needle> <args...>
  label="$1"; needle="$2"; shift 2
  fp="$(fingerprint)"; c="$(commits)"
  run "$@"
  assert_nonzero "$label: exits non-zero" "$RC" "$ERR"
  assert_contains "$label: says why" "$ERR" "$needle"
  assert_eq "$label: changes nothing and leaves no lock" "$(fingerprint)" "$fp"
  assert_eq "$label: makes no commit" "$(commits)" "$c"
}
echo "FR3/FR10 — it refuses an entry the listing does not name, and malformed input"
fresh
grep -vxF -- "$E1" "$(BUF)" > "$FIX/buf" && cat "$FIX/buf" > "$(BUF)"
git -C "$FIX/repo" commit -q -am "only the header's example is dated 2026-09-05 now"
refuses "a date only the header's example carries" "no findings entry dated 2026-09-05" 2026-09-05 removed
assert_contains "the header's example is untouched" "$(cat "$(BUF)")" "- 2026-09-05 [->0060] — **what happened.**"
fresh
refuses "a date no entry carries" "no findings entry dated 2026-09-08" 2026-09-08 removed
refuses "a date that is not a date" "not a YYYY-MM-DD date" 09/05/2026 removed
refuses "an unknown disposition" "unknown disposition" 2026-09-05 deleted
refuses "a mark naming no id" "not a four-digit row id or none" 2026-09-05 marked:abc
refuses "a mark naming no item" "no item file for 0099" 2026-09-05 marked:0099
refuses "a trailing row-id on a non-mark" "a row id goes with marked only" 2026-09-05 removed 0060
refuses "a --line the listing does not name for that date" "line 3 is not a findings entry dated 2026-09-05" 2026-09-05 removed --line 3
echo "FR10 — two entries on one date need --line, from the listing"
fresh
printf -- '- 2026-09-05 — a second entry that day\n' >> "$(BUF)"; git -C "$FIX/repo" commit -q -am "two that day"
refuses "an ambiguous date" "2 findings entries are dated 2026-09-05" 2026-09-05 removed
ln="$("$(BL)/next" --findings-list | grep 'a second entry that day' | sed 's/^[^:]*:\([0-9]*\) .*/\1/')"
run 2026-09-05 removed --line "$ln"
assert_eq "--line <n> from the listing exits 0" "$RC" 0
assert_not_contains "that entry is gone" "$(cat "$(BUF)")" "a second entry that day"
assert_contains "the other entry that day stays" "$(cat "$(BUF)")" "$E1"

echo "FR2 — a dirty buffer refuses; another session's staged path stays staged and out of the commit"
fresh
printf -- '- 2026-09-09 — uncommitted\n' >> "$(BUF)"
refuses "an uncommitted FINDINGS.md" "holds uncommitted changes" 2026-09-05 removed
fresh
printf 'other\n' > "$FIX/repo/other.txt"; git -C "$FIX/repo" add other.txt
run 2026-09-05 removed
assert_eq "exits 0" "$RC" 0
assert_eq "the commit names only FINDINGS.md" "$(committed_paths)" ".tickets/FINDINGS.md "
assert_eq "other.txt is still staged" "$(git -C "$FIX/repo" diff --cached --name-only)" "other.txt"

echo "FR1 — a busy lock is retried, then refused, and left in place"
fresh
mkdir "$(BL)/.lock"; printf 'claim 0060\n' > "$(BL)/.lock/held-by"
before="$(commits)"; buf="$(cksum < "$(BUF)")"
BACKLOG_LOCK_TRIES=2 run 2026-09-05 removed
assert_nonzero "exits non-zero" "$RC" "$ERR"
assert_contains "names the holder" "$ERR" "claim 0060"
assert_eq "the other session's lock is left in place" "$(cat "$(BL)/.lock/held-by")" "claim 0060"
assert_eq "no commit" "$(commits)" "$before"
assert_eq "the buffer is untouched" "$(cksum < "$(BUF)")" "$buf"

# --- FR56 ---------------------------------------------------------------------------------------
echo "FR56 — off the shared branch it refuses up front"
fresh
git -C "$FIX/repo" switch -q -c side
refuses "off the shared branch" "this checkout is on 'side', and the backlog is shared on 'main'" 2026-09-05 removed
assert_contains "takes no lock" "$ERR" "nothing was changed and no lock was taken"

echo "--help"
fresh
run --help
assert_eq "exits 0" "$RC" 0
assert_contains "prints usage" "$OUT" "usage: drain <date> <removed|marked:<row-id>|held> [<row-id>] [--line <n>]"

echo
echo "drain: $PASS passed, $FAIL failed"
TALLIED=1
[ "$FAIL" -eq 0 ]
