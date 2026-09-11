#!/bin/sh
#
# Prose guard for the falsifiability rules in skills/queue/SKILL.md, skills/verify/SKILL.md and
# skills/queue/templates/item.md (0052).
#
# WHY THIS EXISTS:
#
# `verify` Step 3 already refuses a check that cannot be made to fail. Nothing upstream asked the
# same question, and six live instances got through: an AC whose tolerance was wider than the effect
# it measured, an AC asserting a cardinality over a set its ticket did not own, an AC prescribing a
# mutation on the far side of the boundary under test, an absence assertion built on an estimated
# wrong answer, a QA plan contradicting a shipped guard, and — the other direction — Step 3
# over-condemning three mutation-silent branches that differed only in their message.
#
# The rules themselves are `testing-conventions.md`'s. What this file guards is that the LIFECYCLE
# STEPS still ask, because a rule nobody is asked about is a rule that stops being applied.
#
# EVERY CASE IS SCOPED TO THE STEP, NEVER TO THE FILE (0042). A document-wide grep for these words
# pins vocabulary rather than structure: "cardinality" and "mutation" appear in this repo's prose
# all over, so a file-wide match stays green with the step deleted. The window is taken between the
# document's own boundaries — a named opening phrase and the next heading — so it cannot drift the
# way a line count does. The scoping itself is proved falsifiable below: a fixture with the phrase
# present OUTSIDE the window must report a miss.
#
# PHRASES ARE SHORT ENOUGH TO SIT ON ONE SOURCE LINE. `grep` is line-based, so an asserted phrase
# straddling a line break cannot be matched at all, and rewrapping a guarded paragraph is therefore
# a breaking change here (`CLAUDE.md`).
#
# Usage:  tests/falsifiable-acs.test.sh
#         SHOW_MATCHED=1 tests/falsifiable-acs.test.sh   # print the window each case matched in
#
# Requires: sh, awk, grep. No runner — this project has none.

set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
QUEUE="$ROOT/skills/queue/SKILL.md"
VERIFY="$ROOT/skills/verify/SKILL.md"
ITEM="$ROOT/skills/queue/templates/item.md"
for f in "$QUEUE" "$VERIFY" "$ITEM"; do
  [ -f "$f" ] || { echo "no file at $f" >&2; exit 2; }
done

SAW_LINES=8            # a step body runs to thirty-odd lines; enough to orient, not enough to bury

PASS=0
FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }

FIX=""
cleanup() { [ -n "$FIX" ] && rm -rf "$FIX"; return 0; }
trap cleanup EXIT INT TERM

# The window a case matched: always shown on a FAIL, and on a pass only when SHOW_MATCHED is set,
# so a green run stays one line per case plus the tally (`testing-conventions.md`, lean by default).
# Capped: a step body runs to thirty-odd lines, and a failure that reprints all of it buries the
# one line saying what was expected. The count is printed so a truncated window is never mistaken
# for the whole of it.
saw() {
  printf '%s\n' "$1" | sed 's/^/         | /' | head -"$SAW_LINES"
  n="$(printf '%s\n' "$1" | wc -l | tr -d ' ')"
  [ "$n" -gt "$SAW_LINES" ] && printf '         | ... (%s lines in the window)\n' "$n"
  return 0
}
saw_on_pass() { [ -n "${SHOW_MATCHED:-}" ] && saw "$1"; return 0; }

# ---------------------------------------------------------------------------
# The matcher. Takes its text as a parameter so the fixture cases below drive
# this exact code path rather than a reimplementation of it.
# ---------------------------------------------------------------------------

# window <file> <start-fixed-string> <end-regex> — the step body, from the line holding the opening
# phrase to the line before the next matching heading. Empty when the opening phrase is gone, which
# every case below reports rather than passing over.
window() {
  awk -v start="$2" -v endre="$3" '
    !inw && index($0, start) { inw = 1 }
    inw && $0 ~ endre && !first { exit }
    inw { print; first = 0 }
  ' "$1"
}

# window_has <window-text> <fixed-string> — true when the window is non-empty AND holds the string.
# A predicate rather than an assertion, so the falsifiability probes below can ask the question
# without reporting a case; nothing here touches the counters.
window_has() {
  [ -n "$1" ] || return 1
  case "$1" in *"$2"*) return 0 ;; *) return 1 ;; esac
}

# in_window <label> <window-text> <fixed-string>
in_window() {
  if [ -z "$2" ]; then
    bad "$1 — the window is EMPTY; its opening phrase is gone, so nothing was searched"
    return 0
  fi
  if window_has "$2" "$3"; then
    ok "$1"; saw_on_pass "$2"
  else
    bad "$1 — expected in the step: $3"; saw "$2"
  fi
}

# ---------------------------------------------------------------------------
# 0107's matcher. `in_window` above is line-based, which makes every reflow of a guarded paragraph
# a breaking change even when the claim never moved. An assertion about a CLAIM is made against the
# window unwrapped to one logical line instead (`CLAUDE.md`, *Tests*; 0059's build notes, where a
# line-based grep reddened an untouched phrase the moment its paragraph rewrapped).
# ---------------------------------------------------------------------------

# flatten <text> — the window as one logical line.
flatten() { printf '%s' "$1" | tr '\n' ' ' | tr -s ' '; }

# count_in <flattened-text> <fixed-string> — non-overlapping occurrences. Counted on FLATTENED text
# because a line-based count returns one for a phrase that wraps, and so under-reports exactly the
# phrases most likely to be repeated in flowing prose (`testing-conventions.md`).
count_in() {
  printf '%s\n' "$1" | awk -v s="$2" '
    { n = 0; t = $0
      while (t != "" && (i = index(t, s)) > 0) { n++; t = substr(t, i + length(s)) }
      print n }'
}

# says <label> <window-text> <fixed-string> — the claim is in the step, unwrapped, EXACTLY ONCE.
# Uniqueness is counted INSIDE THE WINDOW and never over the file: a phrase occurring twice in the
# very section a guard extracts is as unfalsifiable as one occurring twice in the file
# (`testing-conventions.md`, and 0107's QA plan, which asks for this count explicitly).
says() {
  if [ -z "$2" ]; then
    bad "$1 — the window is EMPTY; its opening phrase is gone, so nothing was searched"
    return 0
  fi
  n="$(count_in "$(flatten "$2")" "$3")"
  case "$n" in
    1) ok "$1"; saw_on_pass "$2" ;;
    0) bad "$1 — expected in the step: $3"; saw "$2" ;;
    *) bad "$1 — found $n times inside the step, so it pins nothing: $3"; saw "$2" ;;
  esac
}

# ---------------------------------------------------------------------------
# The shipped tree
# ---------------------------------------------------------------------------

QW="$(window "$QUEUE" 'Write acceptance criteria as given/when/then' '^### ')"

echo "AC1 — queue's acceptance-criteria step requires each AC to name what would make it red"
in_window "AC1 — the step asks for what would make an AC red" "$QW" 'Name what would make each AC red'
in_window "AC1 — and refuses one for which nothing can be named" "$QW" 'is not a criterion yet'

echo "AC2 — that step names the three shapes that read as criteria and are not"
in_window "AC2 — the tolerance-too-wide shape" "$QW" 'A tolerance wider than the effect it measures'
in_window "AC2 — the cardinality shape"        "$QW" 'A cardinality claim over a set the ticket does not own'
in_window "AC2 — the wrong-side-mutation shape" "$QW" 'on the far side of the boundary under test'

echo "AC3/FR4 — that step governs a QA plan's absence assertions"
in_window "AC3 — absence assertions checked against shipped guards" "$QW" \
  "Check a QA plan's absence assertions against the guards already shipped"
in_window "FR4 — an absence assertion's wrong answer is computed, not estimated" "$QW" \
  'from the fixture rather than estimating it'

echo "FR7 — the step cites testing-conventions.md rather than restating it"
in_window "FR7 — queue's step cites the convention" "$QW" 'testing-conventions.md'

VW="$(window "$VERIFY" '## Step 3 — Check the acceptance criteria literally' '^## Step 4')"

echo "AC4 — verify Step 3 separates an unchanged outcome from an unchanged message"
in_window "AC4 — the two are distinguished" "$VW" 'named outcome, or only the message'
in_window "AC4 — only the unchanged outcome is unverified" "$VW" 'the AC is unverified'
in_window "AC4 — the unchanged message is an assertion to add" "$VW" 'message assertion'
in_window "FR7 — verify's step cites the convention" "$VW" 'testing-conventions.md'

IW="$(window "$ITEM" '## Acceptance criteria' '^## QA plan')"

echo "AC5 — the item template carries the requirement where the criteria are written"
in_window "AC5 — the template asks for what would make it red" "$IW" \
  'Each criterion names what would make it red'
in_window "AC5 — and refuses one for which nothing can be named" "$IW" 'is not a criterion yet'

# ---------------------------------------------------------------------------
# 0107 — the same question, asked of the NFR table. `0052` made an ACCEPTANCE CRITERION name what
# would make it red; nothing asked it of an NFR row, and the measurement in 0107 found a row is
# guarded exactly when an AC happens to cover it — four rows of six on `0039`, with Observability
# unguarded outright and Security half-guarded.
# ---------------------------------------------------------------------------

QN="$(window "$QUEUE" 'Fill the NFR table by elimination' '^\*\*Set ')"

echo "0107 AC2/FR2 — queue's NFR step requires a kept row to name how it would red"
says "AC2 — the step requires it"                   "$QN" 'Each row names how it would red'
says "AC2 — and refuses a row that cannot"          "$QN" 'is not a commitment and does not ship'
says "FR2 — the step says why, from the measurement" "$QN" 'guarded exactly when an AC happens to cover it'
says "AC4/FR4 — the permitted prose form is named"  "$QN" 'prose only — no artifact yet'
says "AC4/FR4 — an empty cell is the other state"   "$QN" 'An empty cell is an unanswered row'

V4="$(window "$VERIFY" '## Step 4 — Check the NFRs that the ticket declared' '^## Step 5')"

echo "0107 AC3/FR3 — verify Step 4 asks the falsifiability question of the TABLE, not only the ACs"
says "AC3 — the question is asked of each row"      "$V4" 'Ask of each filled row how it would red'
says "AC3 — true today is not the same as guarded"  "$V4" 'true today and guarded by nothing'
says "AC6 — an unguarded row is reported"           "$V4" 'flag the row as unguarded'
says "AC4/FR4 — the permitted prose form is honoured" "$V4" 'prose only — no artifact yet'

IN="$(window "$ITEM" '## Non-functional requirements' '^## Waiting on')"

echo "0107 AC1/FR1 — the item template gives every NFR row a place to name how it would red"
says "AC1 — the table carries the column"           "$IN" '| Dimension | Requirement for this item | How it would red | Convention |'
says "AC1 — the preamble requires it"               "$IN" 'Each row names how it would red'
says "AC1 — and refuses a row that cannot"          "$IN" 'is not a commitment and does not ship'
says "AC4/FR4 — the permitted prose form is named"  "$IN" 'prose only — no artifact yet'
says "AC4/FR4 — an empty cell is the other state"   "$IN" 'An empty cell is an unanswered row'

# ---------------------------------------------------------------------------
# The cases below prove the guard can fail. A guard only ever seen passing is indistinguishable
# from one wired to nothing (`testing-conventions.md`). Every fixture is AUTHORED, never copied
# from a file under test: a copy couples the fixture to the tree beside it, so unrelated growth
# reds a case that has nothing to do with it.
# ---------------------------------------------------------------------------

FIX="$(mktemp -d)"

echo "FR8 — a step missing the rule is reported, not passed over"
cat > "$FIX/absent.md" <<'FIXTURE'
## Step 2 — Add an item

Write acceptance criteria as given/when/then; verify checks these literally.

### Set next now

Route the ticket.
FIXTURE
W="$(window "$FIX/absent.md" 'Write acceptance criteria as given/when/then' '^### ')"
if window_has "$W" 'Name what would make each AC red'; then
  bad "FR8 — a step missing the rule matched anyway; this guard is wired to nothing"
else
  ok "a step without the rule is reported as a failure"
fi

echo "FR8 — the phrase present OUTSIDE the window does not satisfy the check"
cat > "$FIX/outside.md" <<'FIXTURE'
## Step 2 — Add an item

Write acceptance criteria as given/when/then; verify checks these literally.

### Set next now

Name what would make each AC red, somewhere else entirely.
FIXTURE
W="$(window "$FIX/outside.md" 'Write acceptance criteria as given/when/then' '^### ')"
case "$W" in
  *'Name what would make each AC red'*)
    bad "FR8 — the window read past its heading boundary into the next section" ;;
  '') bad "FR8 — the window came back empty on a fixture that holds its opening phrase" ;;
  *)  ok "the window stops at the next heading, so a phrase beyond it is not counted" ;;
esac

echo "FR8 — a deleted opening phrase is an empty window, reported rather than silently green"
cat > "$FIX/gone.md" <<'FIXTURE'
## Step 2 — Add an item

The acceptance-criteria paragraph was deleted wholesale.

### Set next now
FIXTURE
W="$(window "$FIX/gone.md" 'Write acceptance criteria as given/when/then' '^### ')"
if [ -n "$W" ]; then
  bad "FR8 — the window found text after its opening phrase was deleted: $W"
elif window_has "$W" 'anything at all'; then
  bad "FR8 — an empty window matched; every case below it would prove nothing"
else
  ok "an empty window is a named failure, never a vacuous pass"
fi


echo "0107 AC6 — a Step 4 clause present only OUTSIDE the step does not satisfy the check"
cat > "$FIX/step4-outside.md" <<'FIXTURE'
## Step 4 — Check the NFRs that the ticket declared

For each filled NFR row, confirm the requirement holds.

## Step 5 — Act on the verdict

Ask of each filled row how it would red, somewhere else entirely.
FIXTURE
W="$(window "$FIX/step4-outside.md" '## Step 4 — Check the NFRs that the ticket declared' '^## Step 5')"
if [ -z "$W" ]; then
  bad "AC6 — the Step 4 window came back empty on a fixture that holds its heading"
elif window_has "$(flatten "$W")" 'Ask of each filled row how it would red'; then
  bad "AC6 — the Step 4 window read past its boundary into Step 5"
else
  ok "a Step 4 clause beyond the step is not counted, so AC6 is scoped to the step"
fi

echo "0107 — says() reds a claim repeated inside the window, which pins nothing"
cat > "$FIX/twice.md" <<'FIXTURE'
## Non-functional requirements

Each row names how it would red.

Each row names how it would red.

## Waiting on
FIXTURE
W="$(window "$FIX/twice.md" '## Non-functional requirements' '^## Waiting on')"
n="$(count_in "$(flatten "$W")" 'Each row names how it would red')"
if [ "$n" = 2 ]; then
  ok "a claim occurring twice inside the window is counted twice, so says() reds it"
else
  bad "a doubled claim counted $n times; the uniqueness half of says() cannot fail"
fi

echo "0107 — a claim wrapped across a line break is still matched, so a rewrap is not a breaking change"
cat > "$FIX/wrapped.md" <<'FIXTURE'
## Non-functional requirements

Each row names how it
would red.

## Waiting on
FIXTURE
W="$(window "$FIX/wrapped.md" '## Non-functional requirements' '^## Waiting on')"
if window_has "$W" 'Each row names how it would red'; then
  bad "the line-based matcher matched a wrapped claim; this fixture proves nothing"
elif [ "$(count_in "$(flatten "$W")" 'Each row names how it would red')" = 1 ]; then
  ok "a wrapped claim is matched exactly once on the flattened window"
else
  bad "a wrapped claim was not matched on the flattened window"
fi

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" = 0 ]
