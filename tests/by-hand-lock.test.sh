#!/bin/sh
#
# A by-hand backlog write: the park step takes the lock, and the commit inside a by-hand lock proves
# it landed before the lock is released (0091).
#
# WHY THESE ARE PROSE GUARDS. Nothing here is a script — the scripts commit their own fixed paths and
# are immune. What bites is a session writing to the backlog by hand, following prose, so the
# artifact under test IS the prose (`CLAUDE.md`, *Tests*).
#
# EVERY POSITIVE ASSERTION IS SCOPED TO A SECTION, never to a whole file: "lock" and "commit" are
# ordinary words across these files, and a file-level grep pins vocabulary rather than the claim
# (`testing-conventions.md`, *Anchor an assertion to the claim, not to the document*).
#
# MATCHING IS OVER WHITESPACE-FOLDED TEXT, not line by line. Line-based matching is the usual rule
# here (`CLAUDE.md`), and for a NEGATIVE assertion it fails backwards: AC5's red-making input reads
# "Fold it into the" / "boundary commit" across a wrap, so a line-based "is it gone?" reported it gone
# against the very file it exists to red. Folding newlines and runs of spaces into one space lets a
# phrase straddle a wrap in both directions, so a reflow neither hides a deletion nor fakes one.
#
# Usage:  tests/by-hand-lock.test.sh
#         SHOW_MATCHED=1 tests/by-hand-lock.test.sh   # print the window each case matched in
#
# Requires: sh, awk, grep. No runner — this project has none.

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

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
CONC="$ROOT/references/CONCURRENCY.md"
INCID="$ROOT/references/CONCURRENCY-INCIDENTS.md"
DEC001="$ROOT/docs/decisions/001-one-command-per-stage-boundary.md"
for f in "$CONC" "$INCID" "$DEC001"; do
  [ -f "$f" ] || { echo "no file at $f" >&2; exit 2; }
done

# Every skill with a park step — FR1 names all six.
SKILLS='design develop prototype queue retro verify'
PARK='Park what surprised you'
SAW_LINES=12

PASS=0
FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }

saw() {
  printf '%s\n' "$1" | sed 's/^/         | /' | head -"$SAW_LINES"
  n="$(printf '%s\n' "$1" | wc -l | tr -d ' ')"
  [ "$n" -gt "$SAW_LINES" ] && printf '         | ... (%s lines in the window)\n' "$n"
  return 0
}
# copy-begin: saw-on-pass
# A declared copy: tests/declared-copies.test.sh reds unless every copy of this block is identical.
saw_on_pass() { [ -n "${SHOW_MATCHED:-}" ] && saw "$1"; return 0; }
# copy-end: saw-on-pass

# window <file> <heading-substring> — from the markdown heading holding that text to the line before
# the next heading at the same level or above. Empty when the heading is gone, which every case
# reports rather than passing over.
window() {
  awk -v want="$2" '
    function level(s) { match(s, /^#+/); return RLENGTH }
    !inw && /^#+ / && index($0, want) { inw = 1; lv = level($0); print; next }
    inw && /^#+ / && level($0) <= lv { exit }
    inw { print }
  ' "$1"
}

flatten() { printf '%s\n' "$1" | tr '\n\t' '  ' | tr -s ' '; }

window_has() {
  [ -n "$1" ] || return 1
  case "$(flatten "$1")" in *"$2"*) return 0 ;; *) return 1 ;; esac
}

in_window() {
  if [ -z "$2" ]; then
    bad "$1 — the window is EMPTY; its heading is gone, so nothing was searched"
    return 0
  fi
  if window_has "$2" "$3"; then
    ok "$1"; saw_on_pass "$2"
  else
    bad "$1 — expected in the section: $3"; saw "$2"
  fi
}

not_in_window() {
  if [ -z "$2" ]; then
    bad "$1 — the window is EMPTY; its heading is gone, so nothing was searched"
    return 0
  fi
  if window_has "$2" "$3"; then
    bad "$1 — still present in the section: $3"; saw "$2"
  else
    ok "$1"
  fi
}

# FR1 asks for a citation, not a restatement: the assertion is the pointer to the rule's home.
PARK_LOCK='The append takes the backlog lock'
LOCK_RULE='*Lock every write to the backlog directory*'

echo "0091 FR5/AC1 — every park step names the lock and cites the rule rather than restating it"
for s in $SKILLS; do
  f="$ROOT/skills/$s/SKILL.md"
  if [ ! -f "$f" ]; then
    bad "AC1 — no file at skills/$s/SKILL.md"
    continue
  fi
  W="$(window "$f" "$PARK")"
  in_window "AC1 — skills/$s/SKILL.md's park step takes the lock" "$W" "$PARK_LOCK"
  in_window "AC1 — skills/$s/SKILL.md's park step cites the lock rule" "$W" "$LOCK_RULE"
done

WL="$(window "$CONC" '## Lock every write to the backlog directory')"

echo "0091 AC2 — a by-hand commit names every pathspec literally"
in_window "AC2 — the lock rule says never through a variable" "$WL" 'never through a variable'
# AC2 asks for the phrase ON A SINGLE LINE, which the folded match above cannot tell apart from a wrap.
if printf '%s\n' "$WL" | grep -q 'never through a variable'; then
  ok "AC2 — and the phrase sits on one source line"
else
  bad "AC2 — 'never through a variable' is not on one line of the lock rule"
fi

echo "0091 AC3 — the status check comes BEFORE the release"
in_window "AC3 — the lock rule orders the status check before the release" "$WL" \
  'confirmed clean before the release'
not_in_window "AC3 — and never after it" "$WL" 'confirmed clean after the release'

WB="$(window "$INCID" '### A busy or stale lock')"

echo "0091 AC4 — the incidents list carries a commit that fails while the release succeeds"
in_window "AC4 — the list keeps its lead-in" "$WB" 'bite a by-hand lock'
in_window "AC4 — the commit-fails-release-succeeds entry is present" "$WB" \
  'The commit fails while the release succeeds'

echo "0091 AC4 — no count of the ways a by-hand lock leaks, in either file"
COUNT_RE='(one|two|three|four|five|six|seven|eight|nine|ten|[0-9]+) (ways a by-hand lock|things bite a by-hand lock)'
# A negative assertion reads green when the phrase it guards is gone, so each file must still carry
# the uncounted phrase before its count-free reading means anything.
in_window "AC4 — CONCURRENCY.md still points at the ways a by-hand lock leaks" "$WL" \
  'ways a by-hand lock leaks'
for f in "$INCID" "$CONC"; do
  rel="${f#"$ROOT"/}"
  hits="$(flatten "$(cat "$f")" | grep -oEi "$COUNT_RE" || true)"
  if [ -z "$hits" ]; then
    ok "AC4 — $rel states no count"
  else
    bad "AC4 — $rel still counts the ways a by-hand lock leaks or bites"; saw "$hits"
  fi
done

WD="$(window "$DEC001" '### What is not fused, and why')"

echo "0091 AC5 — decision 001 does not fold the FINDINGS.md append into the boundary commit"
not_in_window "AC5 — the fold instruction is gone" "$WD" 'Fold it into the boundary commit'
in_window "AC5 — the append precedes the boundary commit" "$WD" 'before the boundary commit'

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
TALLIED=1
[ "$FAIL" -eq 0 ]
