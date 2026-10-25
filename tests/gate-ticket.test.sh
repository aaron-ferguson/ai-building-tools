#!/bin/sh
#
# Guard for the gate-ticket shape (0110, decision 004).
#
# A ticket whose first requirement is a measurement that can kill the rest had no shape in
# `item.md`: the withdrawn 0104 wrote "only if FR1 clears" into each dependent FR and spent an AC
# asserting the killed state. Decision 004 settles it — the gate is its own ticket with a
# `## Kill criteria` section, and the work it decides is not filed until it clears. This guards the
# two places that shape is stated: the template's section and `queue` Step 2's rule.
#
# Every assertion is scoped to the section or paragraph that has to carry it, never to the file —
# "verdict", "clears" and `blocked_by` are ordinary words in both files. Each phrase sits on one
# source line, because `grep` is line-based and a rewrap would hide it (`CLAUDE.md`).
#
# Usage:  tests/gate-ticket.test.sh
#
# Requires: sh, awk. No runner — this project has none.

set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
ITEM="$ROOT/skills/queue/templates/item.md"
QUEUE="$ROOT/skills/queue/SKILL.md"
for f in "$ITEM" "$QUEUE"; do
  [ -f "$f" ] || { echo "no file at $f" >&2; exit 2; }
done

PASS=0
FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }

# window <file> <start-fixed-string> <end-regex> — from the line holding the opening phrase to the
# line before the next line matching end-regex. `first` is set on the opening line so an end regex
# that also matches the heading does not close the window before it opens.
window() {
  awk -v start="$2" -v endre="$3" '
    !inw && index($0, start) { inw = 1; first = 1 }
    inw && $0 ~ endre && !first { exit }
    inw { print; first = 0 }
  ' "$1"
}

has() {
  label="$1"; win="$2"; phrase="$3"
  if [ -z "$win" ]; then
    bad "$label — the window is EMPTY; its opening phrase is gone, so nothing was searched"
  elif printf '%s\n' "$win" | grep -qF -- "$phrase"; then
    ok "$label"
  else
    bad "$label — expected: $phrase"
  fi
}

lacks() {
  label="$1"; win="$2"; phrase="$3"
  if [ -z "$win" ]; then
    bad "$label — the window is EMPTY; nothing was searched"
  elif printf '%s\n' "$win" | grep -qF -- "$phrase"; then
    bad "$label — found: $phrase"
  else
    ok "$label"
  fi
}

KILL="$(window "$ITEM" '## Kill criteria' '^## ')"
RULE="$(window "$QUEUE" '**Where work should exist only if a measurement clears' '^$')"

echo "AC1 — item.md carries a Kill criteria section, only on a gate ticket"
has "AC1 — the section heading is marked only for a gate ticket" "$KILL" '## Kill criteria  *(only on a gate ticket)*'
has "AC1 — it holds a Verdict line"                              "$KILL" '**Verdict:**'
has "AC1 — it holds an If-it-clears line"                        "$KILL" '**If it clears:**'
has "AC1 — the outline is prose, never FRs or checkbox criteria" "$KILL" 'never FRs or checkbox criteria'

echo "AC2 — queue Step 2: the decided work is not filed, and why"
has "AC2 — the decided work is not filed"                        "$RULE" 'The work it decides is not filed'
has "AC2 — neither as FRs nor as a blocked_by dependent"         "$RULE" 'neither as FRs in the gate ticket nor as a ticket `blocked_by` it'
has "AC2 — the reason: close frees a dependent whatever the verdict" "$RULE" '`close` frees a dependent whatever the verdict'

echo "AC3 — a gate ticket's criteria are satisfiable either way"
has "AC3 — criteria assert the verdict was recorded"             "$RULE" 'assert the verdict was recorded'
has "AC3 — never that it was favourable"                         "$RULE" 'never that it was favourable'

echo "AC4 — the clear path uses the buffer, and the rule cites 004"
has "AC4 — on cleared, one FINDINGS.md entry"                    "$RULE" 'on `cleared`, one `FINDINGS.md` entry'
has "AC4 — the rule cites decision 004"                          "$RULE" 'docs/decisions/004'

echo "NFR — the rejected alternatives live only in 004"
lacks "NFR — Step 2's rule does not restate the conditional-FR alternative" "$RULE" 'conditional FR'
lacks "NFR — Step 2's rule does not restate the third-terminal reasoning"   "$RULE" 'third terminal'

echo "scope — the rule is asserted in Step 2, not anywhere in the file"
STEP2="$(window "$QUEUE" '## Step 2 — Add an item' '^## Step 3')"
has "scope — the rule's opening sits inside Step 2" "$STEP2" '**Where work should exist only if a measurement clears'

printf '\ngate-ticket: %s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
