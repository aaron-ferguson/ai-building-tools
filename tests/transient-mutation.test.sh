#!/bin/sh
#
# Behavioural guard for the transiently-mutated file rule in skills/develop/SKILL.md (0106 FR4).
#
# `touches:` had three readings and this is the one nothing covered. Step 1 defines the field as
# "what you will actually open" and adds a rule for a file you will CREATE; a file you break on
# purpose and put back is neither, because the committed diff never shows it. But it is the
# sharpest kind of hold there is: proving a guard red means the suite is deliberately red while the
# mutation is live, so a concurrent whole-suite run collects failures that belong to nobody, cannot
# be reproduced a moment later, and point at a file its own ticket never touched.
#
# Step 5 already tells the ARRIVING session to check for a live run. The half with no owner was the
# session holding the mutation, so both halves are asserted here — that the file is declared, and
# what the mutating session owes.
#
# Every assertion is scoped to the paragraph, never to the whole file: `skills/develop/SKILL.md`
# says "pgrep" elsewhere for the arriving session's rule, so a file-wide grep for it is satisfied by
# prose this rule does not govern (`testing-conventions.md`, anchor an assertion to the claim, not
# to the document that contains it).
#
# Usage:  tests/transient-mutation.test.sh
#
# Requires: sh, awk, grep. No runner — this project has none.

set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
DEV="$ROOT/skills/develop/SKILL.md"
[ -f "$DEV" ] || { echo "no skill file at $DEV" >&2; exit 2; }

PASS=0
FAIL=0

ok()  { PASS=$((PASS + 1)); printf '  ok   — %s\n' "$1"; }
bad() { FAIL=$((FAIL + 1)); printf '  FAIL — %s\n' "$1"; }

# The paragraph, ending on its own blank line rather than on a line count — a count is a guess at
# how long the prose is and goes wrong silently in both directions (0032).
PARA="$(mktemp)"
trap 'rm -f "$PARA"' EXIT INT TERM
awk '/break on purpose/ { f = 1 } f && /^[[:space:]]*$/ { exit } f { print }' "$DEV" > "$PARA"

present() {
  if grep -qF "$2" "$PARA"; then ok "$1"; else
    bad "$1 — expected the paragraph to contain: $2"
    printf '         paragraph:\n'; sed 's/^/           /' "$PARA"
  fi
}

echo "0106 AC6 — Step 1 covers the file that is mutated and restored"
if [ -s "$PARA" ]; then ok "the rule has a paragraph of its own"; else
  bad "the rule has a paragraph of its own — nothing in $DEV mentions breaking a file on purpose"
fi

echo "0106 AC6 — it says whether such a file is declared"
present "the answer is yes, and it is an instruction" 'Declare it'
present "and it says how, so the field still reads as one thing" 'transient'

echo "0106 AC6 — and what the mutating session owes a concurrent whole-suite run"
present "the mutating session checks for a live run before breaking anything" 'pgrep'
present "the window is bounded" 'one turn'
present "and it never survives the hand-off" 'hand-off'

echo
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
