#!/bin/sh
#
# Prose guard for the self-sufficient-refusal rule in skills/develop/SKILL.md Step 4 (0172).
#
# A committed backlog script binds the very next session; a skill binds only after a release and a
# restart. So a refusal a ticket adds to skills/queue/templates/* can reach a session whose skill
# never mentions it, and 0172 decided the refusal must carry its own instruction rather than wait
# on a release. This guard keeps that rule where develop sessions read it.
#
# Every assertion is scoped to Step 4, never to the whole file, and each asserted phrase sits on one
# line of the prose (CLAUDE.md, *Tests*: a rewrapped guarded phrase cannot be matched).
#
# Usage:  tests/self-sufficient-refusal.test.sh

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
DEV="$ROOT/skills/develop/SKILL.md"
[ -f "$DEV" ] || { echo "no skill file at $DEV" >&2; exit 2; }

PASS=0
FAIL=0

ok()  { PASS=$((PASS + 1)); printf '  ok   — %s\n' "$1"; }
bad() { FAIL=$((FAIL + 1)); printf '  FAIL — %s\n' "$1"; }

ANCHOR='a refusal that arrives before its skill'

STEP4="$(mktemp)"
PARA="$(mktemp)"
trap 'announce_abort rm -f "$STEP4" "$PARA"' EXIT
trap 'rm -f "$STEP4" "$PARA"' INT TERM
awk '/^## Step 4/ { f = 1; next } /^## Step 5/ { exit } f { print }' "$DEV" > "$STEP4"
# The rule's paragraph, ending on its own blank line rather than on a line count (0032).
awk -v a="$ANCHOR" 'index($0, a) { f = 1 } f && /^[[:space:]]*$/ { exit } f { print }' "$STEP4" > "$PARA"

present() {
  if grep -qF -- "$2" "$PARA"; then ok "$1"; else
    bad "$1 — expected the rule's paragraph to contain: $2"
  fi
}

echo "0172 AC1/AC3 — Step 4 carries the rule's anchor phrase on exactly one line"
hits="$(grep -cF -- "$ANCHOR" "$STEP4" || true)"
if [ "$hits" -eq 1 ]; then ok "'$ANCHOR' matches one line of Step 4"; else
  bad "'$ANCHOR' matches $hits lines of Step 4 in skills/develop/SKILL.md, expected exactly 1"
fi

echo "0172 AC2 — the rule states FR1's three requirements"
present "it is scoped to a refusal added to a backlog script template" 'skills/queue/templates/'
present "the refusal names what is missing" 'names what is missing'
present "the refusal names the fix, actionable without the skill" 'names the fix'
present "the refusal fires before anything is written" 'before anything is written'

echo "0172 AC2 — the rule states FR2's test requirement"
present "the ticket's test runs the script into the refusal" 'runs the script into the refusal'
present "and asserts its stderr names the fix" 'stderr'

echo "0172 AC2 — the rule cites the case it generalises"
present "it cites 0160" '`0160`'

echo
echo "$PASS passed, $FAIL failed"
TALLIED=1
[ "$FAIL" -eq 0 ] || exit 1
