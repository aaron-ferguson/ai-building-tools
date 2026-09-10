#!/bin/sh
#
# Behavioural guard for the batching rule in skills/develop/SKILL.md and skills/verify/SKILL.md
# (0025, settled by 0059).
#
# These skills are prose, so their contract is what a session reading them is told. 0059 settled
# that the two stages batch on DIFFERENT conditions, and this guard asserts them per file:
#
#   develop — takeability at the stage: any row `./next develop` hands you. Shared file scope and a
#             shared parent slice are why a batch pays MORE, never a test of entry.
#   verify  — the tickets were developed together in one gate. Rows merely sitting at `next: verify`
#             are not thereby a batch.
#
# The failure this originally guarded is still guarded: adding the batching permission while leaving
# the "One item per invocation" prohibition in place, so one file says both and a careful reader
# follows the expensive half. Presence and absence are therefore asserted separately.
#
# Each case asserts on a named string in a named file — never on a grep exit status alone, since
# "some match somewhere" is satisfied by the prose this rule exists to replace. Assertions are bound
# to the CLAIM rather than to the paragraph containing it (`testing-conventions.md`, anchor an
# assertion to the claim): the condition sentences are matched as spans, so demoting shared scope
# back to a condition cannot leave the check green on the words surviving elsewhere.
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

# says <label> <one-line-text> <fixed-string> — the paragraph unwrapped to one logical line, so an
# assertion no longer depends on where the prose happens to wrap. grep is line-based and these
# claims are sentences, which in flowing prose straddle a line break more often than not.
says() {
  if printf '%s\n' "$2" | grep -qF "$3"; then ok "$1"; else bad "$1 — expected the claim: $3"; fi
}

# says_not <label> <one-line-text> <fixed-string>
says_not() {
  if printf '%s\n' "$2" | grep -qF "$3"; then bad "$1 — expected NOT to say: $3"; else ok "$1"; fi
}

# binds <label> <one-line-text> <ere> — for a claim whose two halves must sit in one sentence. A
# bounded span is what tells "scope is why a batch pays more" from a paragraph that merely contains
# both phrases in unrelated sentences, which is exactly the pre-0059 wording.
binds() {
  if printf '%s\n' "$2" | grep -qE "$3"; then ok "$1"; else bad "$1 — expected the two halves bound: $3"; fi
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
DEVPARA="$(mktemp)"
VERPARA="$(mktemp)"
trap 'rm -f "$DEVPARA" "$VERPARA"' EXIT INT TERM

# extract <file> <anchor-fixed-string> <outfile>
extract() {
  awk -v a="$2" 'index($0,a){f=1} f && /^[[:space:]]*$/{exit} f{print}' "$1" > "$3"
  if [ ! -s "$3" ]; then
    echo "extraction failed: no line containing '$2' in $1" >&2
    echo "every assertion scoped to the paragraph would then pass or fail for the wrong reason" >&2
    exit 2
  fi
}

# window_integrity <label-prefix> <file> <anchor> <parafile>
window_integrity() {
  ws=$(grep -nF "$3" "$2" | head -1 | cut -d: -f1)
  wl=$(wc -l < "$4" | tr -d ' ')
  wa=$((ws + wl))
  fl=$(wc -l < "$2" | tr -d ' ')
  if grep -q '^[[:space:]]*$' "$4"; then
    bad "$1: the window holds a blank line, so it has run past its own paragraph into the next"
  else
    ok "$1: the window holds no blank line, so it cannot reach a neighbouring paragraph"
  fi
  if [ "$wa" -gt "$fl" ] || [ -z "$(sed -n "${wa}p" "$2" | tr -d '[:space:]')" ]; then
    ok "$1: the window ends where the paragraph ends — the next line is blank or EOF"
  else
    bad "$1: the window stops short or overruns — line $wa is non-blank, not the paragraph break"
  fi
}

extract "$DEV" 'one gate per session' "$DEVPARA"
extract "$VER" 'One gate per invocation' "$VERPARA"

echo "Window integrity — each extraction is its own batching paragraph and nothing adjacent"
window_integrity "develop" "$DEV" 'one gate per session' "$DEVPARA"
window_integrity "verify"  "$VER" 'One gate per invocation' "$VERPARA"
counted "develop's anchor is unique, lowercase, on one line, as the QA plan greps for" \
  "$DEV" "one gate per session" 1
counted "verify's anchor is unique" "$VER" "One gate per invocation" 1

DEV1="$(tr '\n' ' ' < "$DEVPARA")"
VER1="$(tr '\n' ' ' < "$VERPARA")"

echo "AC1 — develop's condition is takeability at the stage"
says "any row ./next develop hands you may be worked in the same session" "$DEV1" \
  'any row `./next develop` hands you may be worked in the same session'
# Over-strict on purpose, and 0059 AC1 names this string as its red input. Correct prose is free to
# MENTION shared scope — FR2 requires it to — so the absence is aimed at the conditional
# construction that made scope the test of entry, not at the vocabulary of scope.
says_not "shared scope is no longer offered as the test of batchability" "$DEV1" \
  'tickets that share a file scope'
says_not "nor in develop's older phrasing of the same condition" "$DEV1" \
  'a set of tickets that share a file scope'

echo "AC2 — shared scope and a shared slice are why a batch pays more, not a condition on entry"
says "the shared-file-scope half survives, as a reason" "$DEV1" 'expects:'
says "the shared-slice half survives, as a reason" "$DEV1" 'parent slice'
binds "both halves are bound to the pays-more claim in one sentence" "$DEV1" \
  'expects:.{0,120}parent slice.{0,40}why a batch pays more'
says "and are denied the status of a precondition in terms" "$DEV1" \
  'not a test the rows must pass first'

echo "AC3 — the batch is assembled by repeating ./next develop, never claimed as a set"
says "the assembly mechanism is named" "$DEV1" 'repeating `./next develop` after each close'
says "and selecting a set up front is refused" "$DEV1" 'never by selecting a set up front'
says "nothing is held before it is worked" "$DEV1" 'nothing is held before it is worked'
says "cited to the rule that forbids the reservation" "$DEV1" 'CONCURRENCY.md'

echo "AC4 — develop's surviving guardrails and its one real precondition"
# On the unwrapped paragraph, not the file: all three sit inside the batching statement, and each is
# long enough to straddle a line break as the prose is re-edited. A line-based grep cannot match a
# phrase that wraps at all (`CLAUDE.md`, *Tests*), so at file level these would red on a correct
# document — which is the shape of guard that teaches everyone to discount its reds.
says "unrelated projects do not batch" "$DEV1" "Tickets from unrelated projects do not batch"
says "claim and close each ticket individually" "$DEV1" "Claim and close each ticket individually"
says "stop the batch on a wrong contract" "$DEV1" "Stop at the first ticket whose contract turns out wrong"
absent "no 'One item per invocation' left in develop" "$DEV" "One item per invocation"

echo "AC5 — verify's condition is the develop gate, and the stage alone is not a batch"
says "the tickets were developed together in one gate" "$VER1" 'developed together in one gate'
says "rows merely at the stage are not thereby a batch" "$VER1" 'are not thereby a batch'
says_not "the stage is not offered as the condition" "$VER1" 'any rows at the stage'
says_not "verify does not carry develop's condition either" "$VER1" 'tickets that share a file scope'
present "no shared verdict across a batch" "$VER" "own acceptance criteria"

echo "AC6 — neither statement claims the other's rationale, and each says why they differ"
says_not "verify no longer borrows develop's reason wholesale" "$VER1" \
  'The same batching case applies for the same reason'
says "develop's own rationale is the amortised startup" "$DEV1" 'what a batch saves is the startup'
says "verify's own rationale is the gate's independence" "$VER1" "gate's independence"
says "which verify states is not a startup saving" "$VER1" 'no startup saving amortises'
says "develop points at the other condition rather than exporting its own" "$DEV1" \
  'batches on a different condition'
says "and tells the reader not to carry this one there" "$DEV1" 'Do not carry this rule there'
says "verify says in terms that its condition is not develop's" "$VER1" "and it is not \`develop\`'s"

echo "AC7 — verify names the intra-session Step 3 hazard AND the isolation that answers it"
says "the hazard: another ticket's live mutation reads as this ticket's red" "$VER1" \
  "while ticket A's mutation is live reads as B's red"
says "the isolation: one ticket at a time" "$VER1" 'Verify one ticket at a time'
says "and a clean committed tree before the next ticket's first run" "$VER1" \
  "clean committed state before the next ticket's first run"
says "the cycle completes inside the ticket that opened it" "$VER1" \
  'completes inside the ticket that opened it'

echo "AC4 (develop) — the statement still carries a dated figure"
# MUTATION THAT REDS THIS: strip `**2026-08-22**` from the batching figure in develop, leaving the
# paragraph's other date (`2026-08-23/24`, in the sentence about 0026) in place. Before 0042 this
# was `grep -qE '20[0-9][0-9]-[0-9][0-9]' "$PARA"` over the whole window, so ANY date anywhere in
# the paragraph satisfied it and that mutation left 13/13 passing. The date has to be bound to the
# figure it dates: within four characters of the word that introduces it, which is enough for the
# emphasis markers and not enough to reach across a sentence.
#
# Unwrapping is load-bearing rather than tidy: "dated" ends one line of the prose and the date opens
# the next, so the binding cannot be matched at all against the wrapped window. What unwrapping buys
# is only that THIS assertion no longer depends on where the prose happens to wrap -- it does not
# make the guard rewrap-proof, and do not read it that way: a rewrap that splits an anchor across a
# line break kills the extraction above with exit 2 long before this runs. That is 0063's problem.
binds "the figure's own date is bound to the figure, not merely present in the paragraph" "$DEV1" \
  'dated[^0-9]{0,4}20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]'
says "0026 named as the source of the develop-side figure" "$DEV1" '0026'

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" = 0 ]
