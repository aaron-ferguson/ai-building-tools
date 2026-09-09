#!/bin/sh
#
# The prose half of 0086: `close_by`'s two branches in `develop`, and the `review` level in
# `verify`. Plus the record in `docs/decisions/`.
#
# WHY THIS FILE EXISTS, AND WHAT IT CANNOT DO:
#
# FR8-FR12 land partly in skill prose, and a rule only a reader enforces is the class of guard this
# repo has been bitten by twice. This file is what goes red when a branch is deleted from the
# instructions. It is NOT the assertion that the review level works: the mechanical guard behind
# the whole prose half is `close` refusing a `## Review checklist` of bullets with not one box
# ticked (tests/close.test.sh, 0086 AC5) — that one fires on the real failure, an unperformed
# review closing as a clean one, and it is asserted on the COUNT OF TICKED BOXES rather than on the
# section's presence. A grep over instructions can only tell you the instruction is still written.
#
# EVERY CASE IS WINDOWED TO A SECTION, never matched over the whole file. A phrase found SOMEWHERE
# in a 20,000-byte instruction file is no evidence it is attached to the step under test, and both
# skills discuss `close_by` in more than one place. Each window is bounded by a NAMED heading, and
# the scoping is itself proved falsifiable at the bottom: a fixture with the phrase present OUTSIDE
# the window must not be reported, and a deleted heading must be a named failure rather than a
# vacuous pass.
#
# PHRASES SIT ON ONE SOURCE LINE. `grep` and this matcher are line-based, so an asserted phrase
# straddling a line break cannot be matched at all — rewrapping a guarded paragraph is a breaking
# change here (`CLAUDE.md`).
#
# Usage:  tests/close-by.test.sh
#         SHOW_MATCHED=1 tests/close-by.test.sh   # print the window each case matched in
#
# Requires: sh, awk. No runner — this project has none.

set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
DEVELOP="$ROOT/skills/develop/SKILL.md"
VERIFY="$ROOT/skills/verify/SKILL.md"
QUEUE="$ROOT/skills/queue/SKILL.md"
ITEM="$ROOT/skills/queue/templates/item.md"
CONFIG="$ROOT/skills/queue/templates/config.yml"
D002="$ROOT/docs/decisions/002-matching-rigour-to-stakes.md"
D003="$ROOT/docs/decisions/003-who-may-close-a-ticket.md"
for f in "$DEVELOP" "$VERIFY" "$QUEUE" "$ITEM" "$CONFIG" "$D002"; do
  [ -f "$f" ] || { echo "no file at $f" >&2; exit 2; }
done

SAW_LINES=12
PASS=0
FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }

FIX=""
cleanup() { [ -n "$FIX" ] && rm -rf "$FIX"; return 0; }
trap cleanup EXIT INT TERM

saw() {
  printf '%s\n' "$1" | sed 's/^/         | /' | head -"$SAW_LINES"
  n="$(printf '%s\n' "$1" | wc -l | tr -d ' ')"
  [ "$n" -gt "$SAW_LINES" ] && printf '         | ... (%s lines in the window)\n' "$n"
  return 0
}
saw_on_pass() { [ -n "${SHOW_MATCHED:-}" ] && saw "$1"; return 0; }

# window <file> <start-fixed-string> <end-regex> — from the line holding the opening phrase to the
# line before the next line matching <end-regex>. Empty when the opening phrase is gone, which
# every case reports as a named failure rather than passing over.
window() {
  awk -v start="$2" -v endre="$3" '
    !inw && index($0, start) { inw = 1 }
    inw && $0 ~ endre && !first { exit }
    inw { print; first = 0 }
  ' "$1"
}

window_has() {
  [ -n "$1" ] || return 1
  case "$1" in *"$2"*) return 0 ;; *) return 1 ;; esac
}

in_window() {
  if [ -z "$2" ]; then
    bad "$1 — the window is EMPTY; its opening phrase is gone, so nothing was searched"
    return 0
  fi
  if window_has "$2" "$3"; then ok "$1"; saw_on_pass "$2"
  else bad "$1 — expected in the section: $3"; saw "$2"; fi
}

not_in_window() {
  if [ -z "$2" ]; then
    bad "$1 — the window is EMPTY; its opening phrase is gone, so nothing was searched"
    return 0
  fi
  if window_has "$2" "$3"; then bad "$1 — the section still says: $3"; saw "$2"
  else ok "$1"; saw_on_pass "$2"; fi
}

# in_window_i — as in_window, case-INSENSITIVELY. Emphasis capitals are a prose decision, so a
# matcher that pins them reds a correct file the day a phrase is capitalised for stress
# (`testing-conventions.md`, a presence grep pins one casing).
in_window_i() {
  if [ -z "$2" ]; then
    bad "$1 — the window is EMPTY; its opening phrase is gone, so nothing was searched"
    return 0
  fi
  if printf '%s\n' "$2" | grep -qiF "$3"; then ok "$1"; saw_on_pass "$2"
  else bad "$1 — expected in the section: $3"; saw "$2"; fi
}

# has <label> <file> <fixed-string> — whole-file, for a claim about a file with no sections to
# window (the frontmatter template, the config template).
has() {
  if grep -qF "$3" "$2"; then ok "$1"; else bad "$1 — expected to find: $3"; fi
}
hasnt() {
  if grep -qF "$3" "$2"; then bad "$1 — expected NOT to find: $3"; else ok "$1"; fi
}

# ---------------------------------------------------------------------------
# AC7 — develop Step 5 branches on close_by, and BOTH branches are asserted,
# each on its own line. One assertion covering "the step mentions close_by"
# would be green with either branch deleted.
# ---------------------------------------------------------------------------
DW="$(window "$DEVELOP" '### Then stop, in this order' '^## Step 6')"

echo "AC7 — Step 5 reads close_by before it decides how to stop"
in_window "AC7 — the step is gated on the field at all" \
  "$DW" 'read the item'"'"'s `close_by:`'

echo "AC7 — branch one: verify, or absent, is the unchanged ending"
in_window "AC7 — absent is named as the default branch"   "$DW" 'Absent or'
in_window "AC7 — and it still goes to a QA session"        "$DW" 'the ticket goes to a QA session'

echo "AC7 — branch two: develop closes, and calls close rather than handoff"
in_window "AC7 — the develop branch closes here"           "$DW" 'this session closes it'
in_window "AC7 — by calling ./close, not ./handoff"        "$DW" 'in place of `./handoff`'
in_window "AC7 — and reports the close, not /verify"       "$DW" 'Report the close, not'

echo "AC7 — the raise is stated, and its direction both ways"
in_window "AC7 — raising from develop to verify is permitted" \
  "$DW" 'may RAISE `close_by` from `develop` to `verify`'
in_window "AC7 — lowering into the tier is not" \
  "$DW" 'may never set or lower it to'
in_window "AC7 — and says why qa_level's own rule does not reach it" \
  "$DW" 'a different field from `qa_level`'

echo "AC7 — the hand-off line has a verdict for the case where this stage closed"
LW="$(window "$DEVELOP" '`BUILT` is not `done` and the line is what stops it' '^## Step 6')"
in_window "AC7 — CLOSED is the light tier's last line" "$LW" 'CLOSED'
in_window "AC7 — and it is a claim about ./close returning zero, not about a suite you read" \
  "$LW" 'returned zero, never about a suite you ran'

echo "FR4 — the light close runs the same gate as every other ticket, never a lower one"
in_window "FR4 — the whole suite and the checklist, both, before the close" \
  "$DW" 'the same one every ticket gets, never a lower one'
in_window "FR4 — and says why, citing the record rather than restating it" \
  "$DW" 'uses fewer sessions, not because it tests less'

echo "FR7 — a DRIVEN light close has a verdict word in the outcome schema"
# Not an FR of 0086, and found only by asking what a driven run does with the new ending: the
# schema's `verdict` enum had no member for it, so a perfectly good stage would have read as a
# schema failure and `orchestrate` Step 4 escalates on those. One word, additive.
SCHEMA="$ROOT/skills/orchestrate/outcome.schema.json"
if [ ! -f "$SCHEMA" ]; then
  bad "FR7 — no outcome schema at $SCHEMA"
else
  ENUM="$(python3 -c 'import json,sys; print(" ".join(json.load(open(sys.argv[1]))["properties"]["tickets"]["items"]["properties"]["verdict"]["enum"]))' "$SCHEMA")"
  case " $ENUM " in
    *" closed "*) ok "FR7 — 'closed' is in the verdict enum" ;;
    *) bad "FR7 — the verdict enum has no 'closed' member, so a driven light close cannot be reported: $ENUM" ;;
  esac
  # The three develop already reached must survive: added BESIDE, never in place of.
  for v in built red blocked; do
    case " $ENUM " in
      *" $v "*) ok "FR7 — develop's existing '$v' verdict survives" ;;
      *) bad "FR7 — '$v' was dropped from the verdict enum: $ENUM" ;;
    esac
  done
fi

# ---------------------------------------------------------------------------
# AC6 — verify refuses `review` where nothing is configured. Anchored to the
# REFUSAL, not to the word "review": the level appears in the table two lines
# above, so a file-wide grep for it would be green with this refusal deleted.
# ---------------------------------------------------------------------------
RW="$(window "$VERIFY" '**If the declared level has no command in `config.yml`, stop and say so**' '^---$')"

echo "AC6 — the refusal reaches review by name, not by implication"
in_window "AC6 — review is named as not exempt"        "$RW" '`review` is not exempt'
in_window "AC6 — with no review: block, verify stops"  "$RW" 'no'
in_window "AC6 — the block is what it looks for"       "$RW" '`review:` block configured, stop'
in_window "AC6 — and says why the exemption is refused, not merely that it is" \
  "$RW" 'a level can legitimately resolve to nothing'

echo "AC6 — and the level is not allowed to mean 'no command needed'"
not_in_window "AC6 — no exemption for a level with no command" "$RW" 'review needs no command'

# ---------------------------------------------------------------------------
# AC11 — additive: `review` is added BESIDE `verify`, and the untouched value
# keeps working. This is AC9's argument on the other field, and the reason it
# is a case rather than an assertion in a note: the schema line dropped
# `verify` while contrasting the two fields, which read as a rename.
# ---------------------------------------------------------------------------
TW="$(window "$VERIFY" '| Level | Run |' '^\*\*`verify` and `review` are two levels')"

echo "AC11 — both rows are in the level table, and each carries its own contract"
in_window "AC11 — the verify row survives"                "$TW" '| `verify` | the scripted assertion the QA plan names'
in_window "AC11 — the review row is added beside it"      "$TW" '| `review` | every line of the checklist'
in_window "AC11 — and review is marked not cumulative"    "$TW" 'Not on the pyramid, so not cumulative'
in_window "AC11 — the four pyramid levels are untouched: unit"        "$TW" '| `unit` |'
in_window "AC11 — integration"                                        "$TW" '| `integration` |'
in_window "AC11 — e2e"                                                "$TW" '| `e2e` |'

echo "AC11 — and the two are told apart in prose, so neither reads as a rename of the other"
SW="$(window "$VERIFY" '**`verify` and `review` are two levels, not one word for the same thing.**' '^\*\*At `qa_level: review`')"
in_window "AC11 — verify is 'a mechanical check does'"  "$SW" 'but a mechanical check does'
in_window "AC11 — review is neither"                    "$SW" 'mechanical check either*, for a repo whose artifact is prose'

echo "AC11 — the template's enum still declares verify alongside review"
has "AC11 — both values in qa_level"   "$ITEM" 'qa_level: verify | review | unit | integration | e2e'
has "AC11 — and close_by is its own key, not a value inside qa_level" "$ITEM" 'close_by: verify | develop'

echo "AC11 — this repo's own config carries NO review: block, which is what AC6 and AC11 rest on"
if grep -q '^review:' "$ROOT/.claude/backlog/config.yml"; then
  bad "AC11 — a review: block was added to THIS project's config; AC6 and AC11 both rest on its absence"
else
  ok "AC11 — no review: block in this project's config"
fi

# ---------------------------------------------------------------------------
# FR9/FR10 — the config template documents the block, and says the checklist
# CITES the conventions rather than restating them.
# ---------------------------------------------------------------------------
echo "FR9/FR10 — the config template ships the review: block, unset"
has "FR9 — the key is documented"        "$CONFIG" 'review:'
has "FR9 — with a checklist path"        "$CONFIG" '  checklist:'
has "FR9 — and the refusal is stated"    "$CONFIG" 'A `qa_level: review` ITEM IS REFUSED'
has "FR10 — the checklist cites, never restates" "$CONFIG" 'CITE the conventions rather'
has "FR10 — and the file belongs to the repo being checked" "$CONFIG" 'belongs to THE REPO BEING CHECKED'

# ---------------------------------------------------------------------------
# FR5 — queue is the only skill that may SET close_by, and the eligibility
# rule is stated where the field is written rather than only where it is read.
# ---------------------------------------------------------------------------
QW="$(window "$QUEUE" '**Set `close_by` now too, and this skill is the only one that may.**' '^\*\*Estimate `size`\*\*')"

echo "FR5 — queue states the eligibility rule at the point the field is written"
in_window "FR5 — queue is the only setter"          "$QW" 'the only one that may'
in_window "FR5 — absent means verify"               "$QW" 'an absent field means it'
in_window "FR5 — every AC is a committed assertion" "$QW" 'committed'
in_window "FR5 — named on the AC line"              "$QW" 'named on the AC line'
in_window "FR5 — and no eyeballed criterion"        "$QW" 'a reading, a judgement or an eyeball'
in_window "FR5 — FR12's pair is named here too"     "$QW" 'can never carry'
# The precondition and the gate that enforces it drifted apart once already: `close` admitted any
# tracked path, so a queue session following this section could write a perfectly eligible-looking
# ticket whose criteria cited documents (0086, 2026-09-08). This is the half that keeps the
# instruction honest; `close`'s own refusal carries the enumeration, which is not restated here.
in_window "FR3 — a citation names an assertion, not just a file" "$QW" 'not merely a tracked file'

# ---------------------------------------------------------------------------
# AC10 — the record. `002`'s Light row states the shipped mechanism and the
# corrected saving; `003` exists and cites what shipped.
#
# ANCHORED TO THE ROW, never to the file: `002` discusses the Light tier in its
# prose as well, so a grep for a figure anywhere in it stays green when the
# table row it prices is edited (`testing-conventions.md`, anchor to the claim).
# ---------------------------------------------------------------------------
echo "AC10 — 002's Light row prices the mechanism that shipped"
LIGHTROW="$(awk '/^\| \*\*Light\*\* \|/ { print; exit }' "$D002")"
if [ -z "$LIGHTROW" ]; then
  bad "AC10 — no Light row found in 002; every case below it would prove nothing"
else
  case "$LIGHTROW" in
    *"close_by"*) ok "AC10 — the row names the mechanism, not just the tier"; saw_on_pass "$LIGHTROW" ;;
    *) bad "AC10 — the Light row does not name close_by"; saw "$LIGHTROW" ;;
  esac
  case "$LIGHTROW" in
    *"26%"*) ok "AC10 — the row carries the corrected saving"; saw_on_pass "$LIGHTROW" ;;
    *) bad "AC10 — the Light row does not carry the corrected 26%"; saw "$LIGHTROW" ;;
  esac
  case "$LIGHTROW" in
    *"32%"*) bad "AC10 — the superseded 32% survives in the Light row as a live price"; saw "$LIGHTROW" ;;
    *) ok "AC10 — the superseded 32% is gone from the row" ;;
  esac
  case "$LIGHTROW" in
    *"3.89"*) bad "AC10 — the superseded 3.89 survives in the Light row"; saw "$LIGHTROW" ;;
    *) ok "AC10 — the superseded 3.89 is gone from the row" ;;
  esac
fi

echo "AC10 — and the projected figure is labelled as projected, not published as measured"
PW="$(window "$D002" 'Inline and Light are modelled from the measured stage costs' '^### The finding')"
in_window "AC10 — the −18% is named"                  "$PW" '18%'
in_window_i "AC10 — and marked as not yet measured"   "$PW" 'not yet measured'
in_window "AC10 — and says the measurement has not been run" "$PW" 'has not been run'
in_window "AC10 — so the figure is a forecast, not a price"  "$PW" 'as a forecast until that date'
in_window "AC10 — with the date the measurement is due" "$PW" '2026-10-31'

echo "AC10 — 003 exists and cites the shipped mechanism"
if [ ! -f "$D003" ]; then
  bad "AC10 — docs/decisions/003-who-may-close-a-ticket.md does not exist (FR14)"
else
  ok "AC10 — 003 exists"
  has "AC10 — 003 names the field that shipped"        "$D003" 'close_by'
  has "AC10 — and the script that enforces it"         "$D003" '.claude/backlog/close'
  has "AC10 — and the eligibility rule"                "$D003" 'named on the AC line'
  has "AC10 — records the rejected alternatives"       "$D003" 'Rejected'
  has "AC10 — and the residual risk it accepted"       "$D003" 'Residual risk'
  # The gate the record describes has to be the gate that shipped. 003 said only that a citation is
  # checked for being tracked until QA drove a light ticket closed on a prose document
  # (2026-09-08); the narrowing and its remaining hole are both in the record now, and this is what
  # keeps them there.
  has "FR3 — 003 records that a citation must name an assertion" "$D003" 'not merely a tracked file'
  has "FR3 — and that the shape check is a heuristic, not a proof" "$D003" 'shape check is a heuristic'
  hasnt "AC10 — and does not republish the 32% as live" "$D003" 'Light at $3.89'
fi

# ---------------------------------------------------------------------------
# The falsifiability probes. The fixtures drive the SAME matcher as every case
# above, so a scoping bug reds here rather than passing silently up there.
# ---------------------------------------------------------------------------
FIX="$(mktemp -d)"

echo "FR — a phrase inside the window is seen"
cat > "$FIX/inside.md" <<'FIXTURE'
### Then stop, in this order

read the item's `close_by:` first.

## Step 6
FIXTURE
W="$(window "$FIX/inside.md" '### Then stop, in this order' '^## Step 6')"
if window_has "$W" "read the item's \`close_by:\`"; then
  ok "the matcher sees a phrase in the section it guards"
else
  bad "FR — a phrase inside the window was NOT seen; every AC7 case proves nothing"; saw "$W"
fi

echo "FR — a phrase OUTSIDE the window is not the step's business"
cat > "$FIX/outside.md" <<'FIXTURE'
## Step 4

read the item's `close_by:` somewhere else entirely.

### Then stop, in this order

1. Run the review checklist.

## Step 6
FIXTURE
W="$(window "$FIX/outside.md" '### Then stop, in this order' '^## Step 6')"
if window_has "$W" "read the item's \`close_by:\`"; then
  bad "FR — the window leaked past its own heading; a case would pass on unrelated prose"; saw "$W"
else
  ok "the guard is scoped to the section, not to the file"
fi

echo "FR — a deleted heading is an empty window, reported rather than silently green"
cat > "$FIX/gone.md" <<'FIXTURE'
## Step 6

The stop-order heading was deleted wholesale.
FIXTURE
W="$(window "$FIX/gone.md" '### Then stop, in this order' '^## Step 6')"
if [ -n "$W" ]; then
  bad "FR — the window found text after its heading was deleted: $W"
else
  ok "an empty window is a named failure, never a vacuous pass"
fi

echo "FR — the Light-row reader finds the row rather than the word"
cat > "$FIX/tier.md" <<'FIXTURE'
The Light tier is discussed at length here, priced at $3.89 and -32%.

| Tier | What it is | Cost | vs standard |
|---|---|---|---|
| **Light** | close_by: develop | $4.20 | **-26%** |
FIXTURE
R="$(awk '/^\| \*\*Light\*\* \|/ { print; exit }' "$FIX/tier.md")"
case "$R" in
  *"close_by"*)
    case "$R" in
      *"3.89"*) bad "FR — the row reader captured the prose above the table too"; saw "$R" ;;
      *)        ok "the row reader reads the ROW, so prose mentioning the old price cannot rescue it" ;;
    esac ;;
  *) bad "FR — the row reader found no row in a file that has one: $R" ;;
esac

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" = 0 ]
