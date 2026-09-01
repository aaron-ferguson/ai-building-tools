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
  printf '%s\n' "$1" | sed 's/^/         | /' | head -8
  n="$(printf '%s\n' "$1" | wc -l | tr -d ' ')"
  [ "$n" -gt 8 ] && printf '         | ... (%s lines in the window)\n' "$n"
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

# in_window <label> <window-text> <fixed-string>
in_window() {
  if [ -z "$2" ]; then
    bad "$1 — the window is EMPTY; its opening phrase is gone, so nothing was searched"
    return 0
  fi
  case "$2" in
    *"$3"*) ok "$1"; saw_on_pass "$2" ;;
    *)      bad "$1 — expected in the step: $3"; saw "$2" ;;
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
before=$FAIL
in_window "probe" "$W" 'Name what would make each AC red' >/dev/null 2>&1
if [ "$FAIL" -gt "$before" ]; then
  FAIL=$before
  ok "a step without the rule is reported as a failure"
else
  bad "FR8 — a step missing the rule passed; this guard is wired to nothing"
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
if [ -z "$W" ]; then
  before=$FAIL
  in_window "probe" "$W" 'anything at all' >/dev/null 2>&1
  if [ "$FAIL" -gt "$before" ]; then
    FAIL=$before
    ok "an empty window is a named failure, never a vacuous pass"
  else
    bad "FR8 — an empty window passed; every case below it would prove nothing"
  fi
else
  bad "FR8 — the window found text after its opening phrase was deleted: $W"
fi

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" = 0 ]
