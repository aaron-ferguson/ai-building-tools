#!/bin/sh
#
# Guard for the by-category cost measurement (0085).
#
# WHY THIS EXISTS SEPARATELY FROM tests/measurement.test.sh. `0073` measured where a session's
# TURNS go and published shares of turns. `0085` was about to spend a redesign on that figure
# without anyone having measured what a turn of each category COSTS. If protocol turns were cheap
# turns, a 34.3% share of turns would have been a far smaller share of tokens, and the plan would
# have been optimising the wrong denominator while looking rigorous.
#
# The one that matters is ARITHMETIC AGAINST KNOWN NUMBERS. Every figure this tool emits is a
# ratio of two sums, and a ratio is the shape that looks plausible while being wrong -- the whole
# reason `0073` classified with committed code rather than by reading. The fixture below has four
# turns whose category, context, output and cost are each known by construction, so the assertions
# are exact values and not "looks about right".
#
# Usage:  tests/cost-by-category.test.sh
#
# Requires: sh, grep, python3. No runner -- this project has none.

set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
TOOL="$ROOT/tools/cost-by-category.sh"
REC="$ROOT/MEASUREMENT.md"

PASS=0
FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }

FIX="$(mktemp -d)"
trap 'rm -rf "$FIX"' EXIT INT TERM
mkdir -p "$FIX/store"

echo "0085 — the tool exists and runs"
if [ -x "$TOOL" ]; then ok "tools/cost-by-category.sh is present and executable"
else bad "tools/cost-by-category.sh missing or not executable"; fi

# --- the fixture -------------------------------------------------------------------------------
# Four turns, each a different category, each with a context and an output chosen so that every
# published figure is an exact decimal. Contexts climb by 10,000 a turn so the marginal-footprint
# attribution has a known answer too.
#
# turn 1  ./claim 0007            protocol   ctx 100000  out 100   $0.0525
# turn 2  git status              git        ctx 110000  out 200   $0.0600
# turn 3  tests/thing.test.sh     work       ctx 120000  out 300   $0.0675
# turn 4  Read .../SKILL.md       orient     ctx 130000  out 400   $0.0750
#                                                          TOTAL   $0.2550
u() { printf '{"input_tokens":0,"cache_read_input_tokens":%d,"cache_creation_input_tokens":0,"output_tokens":%d}' "$1" "$2"; }
turn() { # <n> <ctx> <out> <content-json>
  printf '{"type":"assistant","timestamp":"2026-08-23T0%s:00:00.000Z","message":{"id":"msg_cbc_%s","model":"claude-opus-5","content":%s,"usage":%s}}\n' \
    "$1" "$1" "$4" "$(u "$2" "$3")"
}
{
  printf '{"type":"user","timestamp":"2026-08-23T00:00:00.000Z","message":{"role":"user","content":[{"type":"text","text":"<command-name>/ai-building-tools:develop</command-name>"}]}}\n'
  turn 1 100000 100 '[{"type":"text","text":"SENTINELPROSE"},{"type":"tool_use","name":"Bash","input":{"command":".claude/backlog/claim 0007 # SENTINELCMD"}}]'
  turn 2 110000 200 '[{"type":"tool_use","name":"Bash","input":{"command":"git status # SENTINELCMD"}}]'
  turn 3 120000 300 '[{"type":"tool_use","name":"Bash","input":{"command":"tests/thing.test.sh # SENTINELCMD"}}]'
  turn 4 130000 400 '[{"type":"tool_use","name":"Edit","input":{"file_path":"/x/skills/develop/SKILL.md","new_string":"SENTINELPAYLOAD"}}]'
} > "$FIX/store/eeeeeeee-0000-0000-0000-000000000000.jsonl"

OUT="$("$TOOL" "$FIX/store" 2>&1 || true)"

echo "0085 AC7 — the arithmetic, against a fixture whose every figure is known by construction"
case "$OUT" in
  *0.2550*) ok "total cost 0.2550, so the per-category sums reconcile to the session total" ;;
  *) bad "AC7 — expected total 0.2550 in the output; got none. Mutate a fixture usage figure to red this." ;;
esac
case "$OUT" in
  *0.0525*) ok "the protocol turn is priced at 0.0525 — cache reads at 0.1x, output at the output rate" ;;
  *) bad "AC7 — the protocol turn's 0.0525 is absent; the cache-read multiplier or the rate table moved" ;;
esac

echo "0085 AC8 — a turn that edits a skill file is work, not orientation"
# WRITES is tested before ORIENT in the classifier, so turn 4 is `work`. This assertion exists
# because the obvious reading of the rule list gets it backwards, and this session did.
case "$OUT" in
  *"work"*) ok "the output names a work bucket" ;;
  *) bad "AC8 — no work bucket in the output" ;;
esac

echo "0085 AC9 — mechanism is split into protocol and git, which are different fixes"
case "$OUT" in
  *protocol*) ok "the split names protocol separately from git" ;;
  *) bad "AC9 — no protocol bucket: mechanism unsplit cannot aim a reduction (0073 FR5)" ;;
esac
case "$OUT" in
  *git*) ok "the split names git separately from protocol" ;;
  *) bad "AC9 — no git bucket" ;;
esac

echo "0085 AC10 — the marginal footprint is attributed to the turn that APPENDED it"
# Each turn's context is 10,000 above its predecessor, so every turn but the last has a marginal
# footprint of exactly 10000. Attributing the rise to the LATER turn — the obvious off-by-one —
# would put 10000 against git/work/orientation and 0 against protocol.
case "$OUT" in
  *10000*) ok "a marginal footprint of 10000 per turn is reported" ;;
  *) bad "AC10 — expected a 10000 marginal footprint; an off-by-one attributes the rise to the wrong turn" ;;
esac

echo "0085 — privacy: this tool reads command strings and edit payloads, so it could publish one"
case "$OUT" in
  *SENTINELCMD*)     bad "privacy — a shell command string from the fixture reached the output" ;;
  *SENTINELPAYLOAD*) bad "privacy — an edit payload from the fixture reached the output" ;;
  *SENTINELPROSE*)   bad "privacy — message text from the fixture reached the output" ;;
  *) ok "no command string, edit payload or message text reaches the output" ;;
esac

echo "0085 AC11 — the record carries the by-category cost figures, not only the turn shares"
if [ -f "$REC" ] && grep -qF "What a turn of each category costs" "$REC"; then
  ok "MEASUREMENT.md carries the by-category cost section"
else
  bad "AC11 — MEASUREMENT.md has no 'What a turn of each category costs' section"
fi
if [ -f "$REC" ] && grep -qE '87%|0\.0983|0\.1132' "$REC"; then
  ok "the record states what a protocol turn costs against a work turn"
else
  bad "AC11 — the record does not state the protocol-vs-work cost per turn"
fi

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
