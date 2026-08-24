#!/bin/sh
#
# Guard for the recorded measurement (0026).
#
# The deliverable is figures and prose in MEASUREMENT.md plus the harvest script that produced
# them, so this guard does two different jobs and keeps them apart:
#
#   1. ARITHMETIC — tools/harvest-usage.sh is fed a GENERATED fixture with known token counts and
#      the totals are asserted exactly. The one that matters is deduplication: a single API
#      response is written to the transcript as SEVERAL lines, each repeating the same full
#      `usage` object, so summing lines overcounts cost by roughly 2.2x. A fixture with a
#      three-line response is the only thing that catches that regressing.
#
#   2. WHAT WAS WRITTEN DOWN — each claim the ticket requires, asserted on its own line so a
#      reflow cannot red it, and so a run that produces figures and no verdict fails. That is the
#      likely failure and the one this ticket exists to prevent, which is why AC5 (the verdict)
#      and AC8 (what was not held constant) are asserted separately from AC1 (the figures).
#
# Usage:  tests/measurement.test.sh
#
# Requires: sh, grep, python3. No runner — this project has none.

set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
REC="$ROOT/MEASUREMENT.md"
HARVEST="$ROOT/tools/harvest-usage.sh"
DEV="$ROOT/skills/develop/SKILL.md"
VER="$ROOT/skills/verify/SKILL.md"
RME="$ROOT/README.md"
EFFORT="$ROOT/.claude/backlog/items/0009-one-skill-per-session.md"

# README's `modelled` count BEFORE this ticket, measured 2026-08-23. The assertion is that the
# count went DOWN: a stale "modelled" left in place next to a new observed figure is the quiet
# failure, and an absolute zero would be satisfied by deleting the section instead of updating it.
PRE_MODELLED=1

PASS=0
FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }

# present <label> <file> <fixed-string>
present() {
  if [ -f "$2" ] && grep -qF "$3" "$2"; then ok "$1"; else bad "$1 — expected to find in $(basename "$2"): $3"; fi
}
# presenti <label> <file> <fixed-string> — case-insensitive; for a word whose capitalisation
# depends only on where it lands in a sentence.
presenti() {
  if [ -f "$2" ] && grep -qiF "$3" "$2"; then ok "$1"; else bad "$1 — expected to find in $(basename "$2"): $3"; fi
}
# absent <label> <file> <fixed-string>
absent() {
  if [ -f "$2" ] && grep -qF "$3" "$2"; then bad "$1 — expected NOT to find in $(basename "$2"): $3"; else ok "$1"; fi
}

FIX=""
cleanup() { [ -n "$FIX" ] && rm -rf "$FIX"; return 0; }
trap cleanup EXIT INT TERM

echo "AC9 — the harvest script is committed and runnable"
if [ -x "$HARVEST" ]; then
  ok "tools/harvest-usage.sh exists and is executable"
else
  bad "AC9 — no executable script at tools/harvest-usage.sh"
fi

echo "AC9 — the arithmetic, against a generated fixture with known token counts"
FIX="$(mktemp -d)"
mkdir -p "$FIX/store"
# One `develop` session. The first response is written across THREE lines carrying the same usage
# — the shape the real transcripts have — so a script that sums lines reports 3x its cost.
# Priced at the Opus 5 rates the record states: in $5, out $25, cache read 0.1x, 5m write 1.25x,
# 1h write 2x, all per million tokens.
#   turn 1: in 1,000,000 -> $5.00 | read 1,000,000 -> $0.50 | 1h write 1,000,000 -> $10.00
#           5m write 1,000,000 -> $6.25 | out 1,000,000 -> $25.00                 = $46.75
#   turn 2: out 1,000,000 -> $25.00                                                = $25.00
#   total $71.75 over 2 turns = $35.875/turn
#   context = in + read + creation = 1,000,000 + 1,000,000 + 2,000,000 = 4,000,000 on turn 1,
#             0 on turn 2 -> 4,000,000 over 2 turns = 2,000,000 per turn
U1='{"input_tokens":1000000,"cache_read_input_tokens":1000000,"cache_creation_input_tokens":2000000,"cache_creation":{"ephemeral_1h_input_tokens":1000000,"ephemeral_5m_input_tokens":1000000},"output_tokens":1000000}'
U2='{"input_tokens":0,"cache_read_input_tokens":0,"cache_creation_input_tokens":0,"cache_creation":{"ephemeral_1h_input_tokens":0,"ephemeral_5m_input_tokens":0},"output_tokens":1000000}'
{
  printf '{"type":"user","timestamp":"2026-08-23T01:00:00.000Z","message":{"role":"user","content":"<command-name>/ai-building-tools:develop</command-name>"}}\n'
  for _ in 1 2 3; do
    printf '{"type":"assistant","timestamp":"2026-08-23T01:00:01.000Z","message":{"id":"msg_fixture_one","model":"claude-opus-5","content":[{"type":"text","text":"SENTINELPROSE the quick brown fox"}],"usage":%s}}\n' "$U1"
  done
  printf '{"type":"assistant","timestamp":"2026-08-23T01:00:02.000Z","message":{"id":"msg_fixture_two","model":"claude-opus-5","content":[{"type":"text","text":"SENTINELPROSE again"}],"usage":%s}}\n' "$U2"
} > "$FIX/store/aaaaaaaa-0000-0000-0000-000000000000.jsonl"

if [ -x "$HARVEST" ]; then
  OUT="$("$HARVEST" "$FIX/store" 2>&1 || true)"
else
  OUT=""
fi

case "$OUT" in
  *"71.75"*) ok "cost deduplicated by message id: 71.75, not 3x the first response" ;;
  *"163.25"*) bad "AC9 — cost summed per LINE not per response: the dedup by message id is gone" ;;
  *) bad "AC9 — expected a total cost of 71.75 in the output; got: $(echo "$OUT" | tr '\n' ' ' | cut -c1-200)" ;;
esac

case "$OUT" in
  *"35.87"*) ok "cost per turn is 35.87 — two turns, not four lines" ;;
  *) bad "AC9 — expected a per-turn cost of 35.87; got: $(echo "$OUT" | tr '\n' ' ' | cut -c1-200)" ;;
esac

case "$OUT" in
  *"2000000"*|*"2,000,000"*) ok "context per turn is 2,000,000 — input plus cache read plus cache creation" ;;
  *) bad "AC9 — expected a per-turn context of 2,000,000; got: $(echo "$OUT" | tr '\n' ' ' | cut -c1-200)" ;;
esac

case "$OUT" in
  *develop*) ok "the session is attributed to develop from its command marker" ;;
  *) bad "AC9 — the develop session was not attributed to a skill: $(echo "$OUT" | tr '\n' ' ' | cut -c1-200)" ;;
esac

# The real transcripts put <command-message> BEFORE <command-name> for a plugin skill, and open
# with /clear on its own message. Anchoring the marker at the start of the message silently
# attributed all 30 recorded sessions to `unmarked` — a whole harvest with no per-skill figures
# and nothing failing. Both orderings, and the /clear-then-skill sequence, get their own fixture.
mkdir -p "$FIX/store2"
{
  printf '{"type":"user","timestamp":"2026-08-23T02:00:00.000Z","message":{"role":"user","content":"<command-name>/clear</command-name>\\n<command-message>clear</command-message>\\n<command-args></command-args>"}}\n'
  printf '{"type":"user","timestamp":"2026-08-23T02:00:00.000Z","message":{"role":"user","content":"<command-message>ai-building-tools:verify</command-message>\\n<command-name>/ai-building-tools:verify</command-name>"}}\n'
  printf '{"type":"assistant","timestamp":"2026-08-23T02:00:01.000Z","message":{"id":"msg_fixture_three","model":"claude-opus-5","content":[{"type":"text","text":"SENTINELPROSE"}],"usage":%s}}\n' "$U2"
  printf '{"type":"user","timestamp":"2026-08-23T02:00:02.000Z","message":{"role":"user","content":[{"type":"text","text":"a pasted line mentioning <command-name>/ai-building-tools:queue</command-name> inside prose"}]}}\n'
  printf '{"type":"assistant","timestamp":"2026-08-23T02:00:03.000Z","message":{"id":"msg_fixture_four","model":"claude-opus-5","content":[{"type":"text","text":"SENTINELPROSE"}],"usage":%s}}\n' "$U2"
} > "$FIX/store2/bbbbbbbb-0000-0000-0000-000000000000.jsonl"

if [ -x "$HARVEST" ]; then OUT2="$("$HARVEST" "$FIX/store2" 2>&1 || true)"; else OUT2=""; fi
case "$OUT2" in
  *verify*) ok "a marker written message-then-name, after a /clear, attributes the session to verify" ;;
  *) bad "AC9 — the plugin-skill marker ordering was not recognised: $(echo "$OUT2" | tr '\n' ' ' | cut -c1-200)" ;;
esac
case "$OUT2" in
  *queue*) bad "AC9 — a command tag quoted inside prose was read as a real invocation" ;;
  *) ok "a command tag quoted inside prose is not read as an invocation" ;;
esac
case "$OUT2" in
  *unmarked*) bad "AC9 — turns after a recognised marker were left unmarked" ;;
  *) ok "no turn after the marker is left unmarked" ;;
esac

echo "AC9 — the harvest emits no transcript content"
case "$OUT" in
  *SENTINELPROSE*) bad "AC9/privacy — message text from the fixture reached the output" ;;
  *) ok "the fixture's message text is absent from the output" ;;
esac

# Every line within the aggregate-figures character set. Prose fails this: it needs apostrophes,
# parentheses or em-dashes long before it says anything.
BADLINE="$(printf '%s\n' "$OUT" | grep -vn '^[A-Za-z0-9 .,$%|:/-]*$' | head -1 || true)"
if [ -z "$BADLINE" ]; then
  ok "every output line is within the aggregate-figures character set"
else
  bad "AC9 — output line outside the aggregate-figures character set: $BADLINE"
fi

echo "AC1 — the record breaks the isolated run down by skill"
present "the record exists and names queue" "$REC" "queue"
present "the record names develop" "$REC" "develop"
present "the record names verify" "$REC" "verify"
present "the record reports cost per turn" "$REC" "per turn"
present "the record reports context tokens per turn" "$REC" "context"

echo "AC1/documentation — every figure is dated"
if [ -f "$REC" ] && grep -qE '20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]' "$REC"; then
  ok "the record carries an ISO date"
else
  bad "AC1 — no 20NN-NN-NN date in the record"
fi

echo "AC2 — the baseline side, and how it was matched"
present "the record names the 2026-08-22 baseline" "$REC" "2026-08-22"
present "the record states how the baseline session was matched to the published figures" "$REC" "matched"
present "the published figure it is matched against" "$REC" "15.11"

echo "AC3 — the cost model is stated and re-runnable"
present "the input rate" "$REC" "5.00"
present "the output rate" "$REC" "25.00"
present "the cache read multiplier" "$REC" "0.1"
present "the cache write multiplier" "$REC" "1.25"

echo "AC4 — every place the claim was made now carries the observed figure"
absent "develop no longer defers the develop-side figure to this ticket" "$DEV" "fold it in when it lands"
absent "verify no longer defers its figure to this ticket" "$VER" "produces the one for this side of the gate"
absent "the READMEs modelled sentence is gone" "$RME" "Modelled at a 60k average"
absent "0009's Outcome no longer says the figure is unobserved" "$EFFORT" "remains modelled rather than observed"
n=$(grep -ci "modelled" "$RME" || true)
if [ "$n" -lt "$PRE_MODELLED" ]; then
  ok "README's 'modelled' count fell from $PRE_MODELLED to $n"
else
  bad "AC4 — README still says 'modelled' $n time(s), was $PRE_MODELLED before this ticket"
fi
presenti "develop carries an observed figure" "$DEV" "observed"
presenti "verify carries an observed figure" "$VER" "observed"
present "0009 points at the record that holds the observed figures" "$EFFORT" "MEASUREMENT.md"

echo "AC5 — the verdict is stated explicitly, against the modelled figure"
present "the record names the modelled figure it is judged against" "$REC" "5.09"
if [ -f "$REC" ] && grep -qE 'materialised|partly|did not' "$REC"; then
  ok "the record states a verdict"
else
  bad "AC5 — the record carries no verdict: none of materialised, partly, did not"
fi
present "the record says what the run caught" "$REC" "caught"
present "the record says what it missed" "$REC" "missed"

echo "AC6 — cost per closed ticket"
present "the record carries cost per closed ticket" "$REC" "per closed ticket"

echo "AC7 — the per-gate batching figure, or its stated absence and the run that would produce it"
if [ -f "$REC" ] && grep -qE 'per-gate|batch' "$REC"; then
  ok "the record addresses the per-gate batching figure"
else
  bad "AC7 — the record says nothing about the per-gate batching figure"
fi

echo "AC8 — what the two runs did not hold constant"
present "the record names what was not held constant" "$REC" "not held constant"
if [ -f "$REC" ]; then
  n=$(grep -c '^- ' "$REC" || true)
  if [ "$n" -ge 2 ]; then
    ok "the record lists $n bulleted items, at least two of which the section above requires"
  else
    bad "AC8 — the record has $n bulleted items; at least two differences must be named"
  fi
fi

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" = 0 ]
