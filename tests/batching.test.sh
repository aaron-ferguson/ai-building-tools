#!/bin/sh
#
# Behavioural guard for the batching rule in skills/develop/SKILL.md and skills/verify/SKILL.md (0025).
#
# These skills are prose, so their contract is what a session reading them is told. The failure this
# guards is specific and was the likely half-done outcome: adding the batching permission while
# leaving the "One item per invocation" prohibition in place, so one file says both and a careful
# reader follows the expensive half. Presence and absence are therefore asserted separately.
#
# Each case asserts on a named string in a named file — never on a grep exit status alone, since
# "some match somewhere" is satisfied by the prose this rule exists to replace.
#
# Usage:  tests/batching.test.sh
#
# Requires: sh, grep. No runner — this project has none.

set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
DEV="$ROOT/skills/develop/SKILL.md"
VER="$ROOT/skills/verify/SKILL.md"
for f in "$DEV" "$VER"; do
  [ -f "$f" ] || { echo "no skill file at $f" >&2; exit 2; }
done

PASS=0
FAIL=0

ok()   { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }

# present <label> <file> <fixed-string>
present() {
  if grep -qF "$3" "$2"; then ok "$1"; else bad "$1 — expected to find: $3"; fi
}

# absent <label> <file> <fixed-string>
absent() {
  if grep -qF "$3" "$2"; then bad "$1 — expected NOT to find: $3"; else ok "$1"; fi
}

# counted <label> <file> <fixed-string> <n>
counted() {
  n=$(grep -cF "$3" "$2" || true)
  if [ "$n" = "$4" ]; then ok "$1"; else bad "$1 — expected $4 occurrence(s) of '$3', found $n"; fi
}

# The batching paragraph itself, not the whole file: every assertion below about the *test* for
# batchability has to hold inside that paragraph, or it passes on unrelated prose elsewhere.
#
# The window ends on the paragraph's own blank line, never on a line count — do not "simplify" it
# back to a count. A count is a guess at how long the prose is, and it goes wrong silently in both
# directions: too short and the assertions scan a window missing the lines they exist to pin, too
# long and every "present" assertion can be satisfied by the paragraph that follows, which this
# guard does not govern. The second was live here until 0032 — a 15-line count over a 13-line
# paragraph read three lines of the next one. A blank line is where the paragraph actually ends,
# so it cannot drift as the prose is edited.
PARA="$(mktemp)"
trap 'rm -f "$PARA"' EXIT INT TERM
awk '/one gate per session/{f=1} f && /^[[:space:]]*$/{exit} f{print}' "$DEV" > "$PARA"

if [ ! -s "$PARA" ]; then
  echo "extraction failed: no line matching /one gate per session/ in $DEV" >&2
  echo "every assertion scoped to the paragraph would then pass or fail for the wrong reason" >&2
  exit 2
fi

echo "Window integrity — the extraction is the batching paragraph and nothing adjacent"
WIN_START=$(grep -nF 'one gate per session' "$DEV" | head -1 | cut -d: -f1)
WIN_LEN=$(wc -l < "$PARA" | tr -d ' ')
WIN_AFTER=$((WIN_START + WIN_LEN))
DEV_LEN=$(wc -l < "$DEV" | tr -d ' ')
if grep -q '^[[:space:]]*$' "$PARA"; then
  bad "the window holds a blank line, so it has run past its own paragraph into the next"
else
  ok "the window holds no blank line, so it cannot reach a neighbouring paragraph"
fi
if [ "$WIN_AFTER" -gt "$DEV_LEN" ] || [ -z "$(sed -n "${WIN_AFTER}p" "$DEV" | tr -d '[:space:]')" ]; then
  ok "the window ends where the paragraph ends — the next line of develop is blank or EOF"
else
  bad "the window stops short or overruns — line $WIN_AFTER of develop is non-blank, not the paragraph break"
fi

echo "AC1 — develop states the batching case and its test"
counted "the rule appears exactly once, lowercase, as the QA plan greps for" \
  "$DEV" "one gate per session" 1
present "the shared-file-scope half of the test, in the paragraph" "$PARA" "expects:"
present "the shared-slice half of the test, in the paragraph" "$PARA" "parent slice"
present "unrelated projects do not batch" "$PARA" "Tickets from unrelated projects do not batch"

echo "AC2 — the prohibition is replaced, not annotated"
absent "no 'One item per invocation' left in develop" "$DEV" "One item per invocation"

echo "AC3 — the two guardrails batching needs"
present "claim and close each ticket individually" "$DEV" "Claim and close each ticket individually"
present "stop the batch on a wrong contract" "$DEV" "Stop at the first ticket whose contract turns out wrong"

echo "AC4 — the statement carries a dated figure"
if grep -qE '20[0-9][0-9]-[0-9][0-9]' "$PARA"; then
  ok "a dated figure sits inside the batching paragraph"
else
  bad "AC4 — no 20NN-NN date within the batching paragraph"
fi
present "0026 named as the source of the develop-side figure" "$PARA" "0026"

echo "AC5 — verify says each ticket in a batch closes on its own ACs"
present "verify carries the batching case" "$VER" "one gate per session"
present "no shared verdict across a batch" "$VER" "own acceptance criteria"

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" = 0 ]
