#!/bin/sh
#
# Guard: retro Step 4 cites the by-hand lock rule rather than restating it (0126).
#
# WHY THIS EXISTS:
#
# `references/CONCURRENCY.md` *Lock every write to the backlog directory* permits two by-hand
# forms: run the whole sequence in one call, or drop the trap and release explicitly at the end.
# Step 4 restated only the first, as "one shell invocation", beside the reference's reason for it —
# a reason that constrains the TRAP, not the number of calls. A retro pass that held a plain
# `mkdir` lock across several reviewable calls was correct under the reference and forbidden by
# the step. An incomplete restatement reads as correct on its own, so nothing reported it.
#
# THE FIX IS A CITATION, AND AC3 MAKES THAT FALSIFIABLE. Pasting the missing clause back in is the
# cheap fix and leaves two copies of one rule to drift again; the guard reds on either form
# appearing in the step.
#
# THE ASSERTIONS ARE SCOPED TO STEP 4's WINDOW, NEVER TO THE FILE. `lock`, `trap` and `invocation`
# are ordinary words elsewhere in this skill — Step 6 cites the same section — so a file-wide grep
# stays green on a rule moved out of the step that must obey it. A fixture carrying every phrase
# OUTSIDE the window must fail, and does, below.
#
# PHRASES ARE SHORT ENOUGH TO SIT ON ONE SOURCE LINE (`CLAUDE.md`: rewrapping a guarded paragraph
# is a breaking change).
#
# Usage:  tests/retro-lock-citation.test.sh
#         SHOW_MATCHED=1 tests/retro-lock-citation.test.sh   # print the window each case matched in
#
# Requires: sh, awk. No runner — this project has none.

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
RETRO="$ROOT/skills/retro/SKILL.md"
[ -f "$RETRO" ] || { echo "no file at $RETRO" >&2; exit 2; }

SAW_LINES=12

PASS=0
FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }

FIX=""
cleanup() { [ -n "$FIX" ] && rm -rf "$FIX"; return 0; }
trap 'announce_abort cleanup' EXIT
trap cleanup INT TERM

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

# window <file> — Step 4's heading to the line before Step 5's. Empty when the heading is gone,
# which every case reports rather than passing over.
STEP4='## Step 4 — Write it, and empty what you processed'
END4='^## Step 5'
window() {
  awk -v start="$STEP4" -v endre="$END4" '
    !inw && index($0, start) { inw = 1 }
    inw && $0 ~ endre && !first { exit }
    inw { print; first = 0 }
  ' "$1"
}

window_has() {
  [ -n "$1" ] || return 1
  case "$1" in *"$2"*) return 0 ;; *) return 1 ;; esac
}

has() {
  if [ -z "$2" ]; then bad "$1 — the window is EMPTY; Step 4's heading is gone"; return 0; fi
  if window_has "$2" "$3"; then ok "$1"; saw_on_pass "$2"; else bad "$1 — expected in Step 4: $3"; saw "$2"; fi
}

lacks() {
  if [ -z "$2" ]; then bad "$1 — the window is EMPTY; Step 4's heading is gone"; return 0; fi
  if window_has "$2" "$3"; then bad "$1 — Step 4 restates: $3"; saw "$2"; else ok "$1"; saw_on_pass "$2"; fi
}

# Every assertion this guard makes, as one function, so the falsifiability probe below drives the
# exact same checks against a fixture instead of a paraphrase of them.
check() {
  W="$(window "$1")"
  echo "AC1 — Step 4 no longer restates the lock as one shell invocation"
  lacks "AC1 — no 'one shell invocation'" "$W" 'one shell invocation'
  echo "AC2 — Step 4 cites the section that owns the by-hand forms"
  has "AC2 — names CONCURRENCY.md"         "$W" 'CONCURRENCY.md'
  has "AC2 — names the section title"      "$W" 'Lock every write to the backlog directory'
  echo "AC3 — Step 4 enumerates neither permitted form"
  lacks "AC3 — no 'in one call'"           "$W" 'in one call'
  lacks "AC3 — no 'drop the trap'"         "$W" 'drop the trap'
  echo "FR2 — what Step 4 keeps is what is true of retro alone"
  has "FR2 — retro holds no claim token"   "$W" 'holds no claim token'
  has "FR2 — draining FINDINGS.md is inside the boundary" "$W" 'Draining `FINDINGS.md`'
  has "FR2 — appending to an unheld item is inside it too" "$W" 'appending to an unheld item'
}

check "$RETRO"

# ---------------------------------------------------------------------------
# AC4 — the falsifiability probes. Each fixture runs the same check() in a subshell, and must FAIL.
# ---------------------------------------------------------------------------

FIX="$(mktemp -d)"

probe() {
  # probe <label> <fixture> — the fixture must red check(); its own output is discarded.
  if ( PASS=0; FAIL=0; check "$2" >/dev/null; [ "$FAIL" = 0 ] ); then
    bad "$1 — the fixture satisfied every case; the guard cannot fail on it"
  else
    ok "$1"
  fi
}

echo "AC4 — every asserted phrase OUTSIDE Step 4's window does not satisfy the guard"
cat > "$FIX/outside.md" <<'FIXTURE'
## Step 3 — Check the destination

Draining `FINDINGS.md` and appending to an unheld item are inside the boundary, and `retro`
holds no claim token. See `references/CONCURRENCY.md` *Lock every write to the backlog directory*.

## Step 4 — Write it, and empty what you processed

Write it.

## Step 5 — Make it durable
FIXTURE
probe "AC4 — the phrases in a neighbouring step leave the guard red" "$FIX/outside.md"

echo "AC2 — deleting the section title, leaving the bare filename, turns the guard red"
sed 's/ \*Lock every write to the backlog directory\*//' "$RETRO" > "$FIX/bare.md"
probe "AC2 — a bare-filename citation is red" "$FIX/bare.md"

echo "AC3 — pasting the cheap fix into the paragraph turns the guard red"
awk -v step="$STEP4" '{ print } index($0, step) { print ""; print "Or drop the trap and rm -rf explicitly at the end." }' \
  "$RETRO" > "$FIX/pasted.md"
probe "AC3 — the restated second form is red" "$FIX/pasted.md"

echo "AC1 — today's restatement turns the guard red"
awk -v step="$STEP4" '{ print } index($0, step) { print ""; print "Read, write, commit and release in **one shell invocation**." }' \
  "$RETRO" > "$FIX/restated.md"
probe "AC1 — the 'one shell invocation' restatement is red" "$FIX/restated.md"

echo "FR3 — a deleted heading is an empty window, reported rather than silently green"
grep -vF "$STEP4" "$RETRO" > "$FIX/gone.md"
probe "FR3 — an empty window is a named failure" "$FIX/gone.md"

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
TALLIED=1
[ "$FAIL" = 0 ]
