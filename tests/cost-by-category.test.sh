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

# --- the durable record of what all this was for ------------------------------------------------
#
# The figures above are useless if the reasoning built on them lives only in a chat log or an
# artifact. Each assertion below is anchored to the CLAIM rather than to the document, because a
# document-wide grep for a word passes while the sentence carrying the claim is deleted — the
# defect 0042 found in tests/measurement.test.sh. Beside each is the mutation that reds it.
ADR1="$ROOT/docs/decisions/001-one-command-per-stage-boundary.md"
ADR2="$ROOT/docs/decisions/002-matching-rigour-to-stakes.md"
RME="$ROOT/README.md"

echo "0085 — the decisions built on the measurement are written down, not only measured"
if [ -f "$ADR1" ]; then ok "001, the protocol decision, is on disk"
else bad "docs/decisions/001-one-command-per-stage-boundary.md is missing"; fi
if [ -f "$ADR2" ]; then ok "002, the rigour-tier decision, is on disk"
else bad "docs/decisions/002-matching-rigour-to-stakes.md is missing"; fi

# The carrying constant. Reds by changing the rate, the per-turn framing, or deleting the line.
# It is the one figure every reduction argument in both records is denominated in.
if grep -qF '$0.50 per million, per turn it survives' "$REC"; then
  ok "MEASUREMENT.md states the carrying constant per turn survived, not per session"
else
  bad "the carrying constant is gone from MEASUREMENT.md — every saving figure in docs/decisions/ is denominated in it"
fi

# The floor decomposition. Reds by dropping the harness split, which is what makes the largest
# lever visible at all; without it the floor reads as one undifferentiated block.
if grep -qF '44,336' "$REC"; then
  ok "the floor is decomposed into harness against this project's prose"
else
  bad "the 44,336-token harness share of the floor is gone — the largest addressable block becomes invisible"
fi

# The load-bearing planning finding, and the one most likely to be softened into vagueness on a
# later edit. Reds by removing either percentage or by rewriting them as 'a lot' and 'a little'.
# Anchored to the two verb phrases, NOT to the bare percentages: `32%` and `87%` also appear in
# the tier table, so grepping the figures alone passed while the sentence carrying the contrast
# was rewritten to "buys a little"/"buys a lot". Caught by mutating this file's own subject.
if grep -qF 'buys 32%' "$ADR2" && grep -qF 'buys 87%' "$ADR2"; then
  ok "002 states both tier savings as numbers: the QA pass against not creating the ticket"
else
  bad "002 no longer contrasts 'buys 32%' (skip QA) with 'buys 87%' (never ticket it) — that contrast IS the decision"
fi

# The closed questions. A cost theory that is re-opened costs a whole session to re-kill, which is
# why they are recorded with their numbers. Reds by deleting the table or any one row.
# Each anchored to the phrase unique to that row rather than to its figure — `+12%` appears twice
# in the record, so a figure-only assertion would survive the table being deleted.
check_killed() { # <label> <fixed-string unique to that row>
  if grep -qF -- "$2" "$ADR2"; then ok "002 keeps the closed question: $1"
  else bad "002 dropped the closed question '$1' — the theory it kills becomes re-openable, at a session each time"; fi
}
check_killed "fusing develop and verify costs more than it saves" "fuse \`develop\` and \`verify\`"
check_killed "splitting prose into load-on-demand files is not token work" "load-on-demand files"
check_killed "cutting narration cannot move a turn count that is 92% tool calls" "one in twenty-six"

# Discoverability. A record nobody is pointed at is a record nobody reads; the README is the only
# entry point a new reader has. Reds by removing the link.
if grep -qF 'docs/decisions/' "$RME"; then
  ok "README points at the decisions directory"
else
  bad "README no longer points at docs/decisions/ — the reasoning is on disk and unreachable"
fi

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
