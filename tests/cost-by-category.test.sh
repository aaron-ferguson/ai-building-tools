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

# One cell of one row of the bucket table, by bucket name and column number, or ABSENT when that
# bucket has no row at all. Every assertion below reads through this rather than grepping the
# output whole, because three of them used to grep the output whole and could not be made red:
# `*work*`, `*protocol*` and `*git*` are each satisfied by text the tool prints unconditionally.
#
# `NF==8` is what scopes it to the bucket table. The "what removing one turn saves" table prints
# rows under the same bucket names with four columns, so a `grep "^work"` matches two lines.
#   columns: 1 bucket  2 turns  3 turn%  4 $ total  5 $ %  6 $/turn  7 ctx/turn  8 marg/turn
cell() { # <tool-output> <bucket> <column-number>
  printf '%s\n' "$1" | awk -v b="$2" -v c="$3" \
    '$1==b && NF==8 { print $c; got=1 } END { if (!got) print "ABSENT" }'
}

FIX="$(mktemp -d)"
trap 'rm -rf "$FIX"' EXIT INT TERM
mkdir -p "$FIX/store"

echo "0085 — the tool exists and runs"
if [ -x "$TOOL" ]; then ok "tools/cost-by-category.sh is present and executable"
else bad "tools/cost-by-category.sh missing or not executable"; fi

# --- the fixture -------------------------------------------------------------------------------
# Four turns with a context and an output chosen so that every published figure is an exact
# decimal. THREE buckets, not four: turn 4 edits a skill file, and an edit is `work` however
# orientation-shaped its target, which is the whole of AC8. The line below used to read
# `Read .../SKILL.md  orient`, describing a fixture this file has never had — and a comment
# asserting the opposite of the behaviour under test is how AC8 came to be guarded by a bare
# `*work*`, which turn 3 satisfies on its own.
#
# turn 1  ./claim 0007            protocol   ctx 100000  out 100   $0.0525
# turn 2  git status              git        ctx 110000  out 200   $0.0600
# turn 3  tests/thing.test.sh     work       ctx 120000  out 300   $0.0675
# turn 4  Edit .../SKILL.md       work       ctx 130000  out 400   $0.0750
#                                                          TOTAL   $0.2550
#
# The contexts climb UNIFORMLY here, which is deliberate and is also why AC10 cannot be read off
# this fixture. See the second one below.
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

# --- the second fixture, for AC10 only ----------------------------------------------------------
# AC10 is about WHICH turn a context rise is attributed to, and the fixture above cannot answer
# it: its contexts climb uniformly by 10,000, so crediting a rise to the turn that appended it and
# crediting it to the turn that followed both yield 10,000 and differ only in which bucket carries
# it. This one climbs UNEVENLY, which makes the two attributions separable by value.
#
# turn 1  ./claim 0007         protocol   ctx 100000  appended 10000
# turn 2  git status           git        ctx 110000  appended 30000
# turn 3  tests/thing.test.sh  work       ctx 140000  appended 50000
# turn 4  Read .../SKILL.md    orient     ctx 190000  appended 0 — nothing follows it
#
# Correct attribution:  protocol 10000  git 30000  work 50000  orientation 0
# The off-by-one:       protocol     0  git 10000  work 30000  orientation 50000
# Every one of the four cells moves, and the last turn is where the off-by-one is starkest: it
# appended nothing and would be charged the largest rise in the fixture.
mkdir -p "$FIX/ac10"
turnb() { # <n> <ctx> <out> <content-json> — fixture 2, its own message ids and hours
  printf '{"type":"assistant","timestamp":"2026-08-23T1%s:00:00.000Z","message":{"id":"msg_ac10_%s","model":"claude-opus-5","content":%s,"usage":%s}}\n' \
    "$1" "$1" "$4" "$(u "$2" "$3")"
}
{
  printf '{"type":"user","timestamp":"2026-08-23T10:00:00.000Z","message":{"role":"user","content":[{"type":"text","text":"<command-name>/ai-building-tools:develop</command-name>"}]}}\n'
  turnb 1 100000 100 '[{"type":"tool_use","name":"Bash","input":{"command":".claude/backlog/claim 0007 # SENTINELCMD"}}]'
  turnb 2 110000 200 '[{"type":"tool_use","name":"Bash","input":{"command":"git status # SENTINELCMD"}}]'
  turnb 3 140000 300 '[{"type":"tool_use","name":"Bash","input":{"command":"tests/thing.test.sh # SENTINELCMD"}}]'
  turnb 4 190000 400 '[{"type":"tool_use","name":"Read","input":{"file_path":"/x/skills/develop/SKILL.md"}}]'
} > "$FIX/ac10/eeeeeeee-0000-0000-0000-00000000ac10.jsonl"

OUT10="$("$TOOL" "$FIX/ac10" 2>&1 || true)"

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
# WRITE_TOOLS is tested before ORIENT in `category_of_call`, so turn 4 — an Edit of a SKILL.md —
# is `work`. This assertion exists because the obvious reading of the rule list gets it backwards,
# and a session did.
#
# ANCHORED TO TURN 4's OWN CONTRIBUTION, not to the word `work` appearing somewhere. The former
# assertion was `case "$OUT" in *"work"*`, which turn 3 satisfies through TESTS whatever turn 4
# does: reordering `category_of_call` to test ORIENT before WRITE_TOOLS moved turn 4 into a new
# `orientation` bucket and the guard still printed 19 passed, 0 failed. Turn 4 costs 0.0750 and
# turn 3 costs 0.0675, so the `work` row's `$ total` says which of the two are in it.
#   Reds by: `category_of_call` testing ORIENT before WRITE_TOOLS in tools/cost-by-category.sh —
#   and note that mutating `category_of_command`'s order instead is a no-op, because an Edit tool
#   call never reaches it. That is the copy-the-harness-runs trap in testing-conventions.md.
if [ "$(cell "$OUT" work 4)" = "0.1425" ]; then
  ok "work totals 0.1425 — turn 3 at 0.0675 plus turn 4 at 0.0750, so the skill-file Edit is in it"
else
  bad "AC8 — work totals $(cell "$OUT" work 4), not 0.1425: turn 4's Edit of a SKILL.md is not classified work"
fi
if [ "$(cell "$OUT" orientation 4)" = "ABSENT" ]; then
  ok "no orientation bucket exists — nothing in this fixture reads a file, so turn 4 cannot hide there"
else
  bad "AC8 — an orientation bucket appeared at $(cell "$OUT" orientation 4): turn 4 was classified orientation"
fi

echo "0085 AC9 — mechanism is split into protocol and git, which are different fixes"
# ANCHORED TO THE TWO BUCKET ROWS, each by the single fixture turn it should contain. The former
# assertions were `*protocol*` and `*git*` over the whole output, and both words appear in the
# unconditional header line two lines above the table — so collapsing `mechanism_split` to return
# "protocol" always left both green, and the collapse was caught only collaterally, by AC7.
#   Reds by: `mechanism_split` returning "protocol" unconditionally — the git row goes ABSENT and
#   protocol totals turn 1 plus turn 2 at 0.1125.
if [ "$(cell "$OUT" protocol 4)" = "0.0525" ]; then
  ok "a protocol row of its own, holding turn 1 alone at 0.0525"
else
  bad "AC9 — protocol totals $(cell "$OUT" protocol 4), not turn 1's 0.0525: mechanism is not split as published"
fi
if [ "$(cell "$OUT" git 4)" = "0.0600" ]; then
  ok "a git row of its own, holding turn 2 alone at 0.0600 — the share this backlog cannot remove"
else
  bad "AC9 — git totals $(cell "$OUT" git 4), not turn 2's 0.0600: mechanism unsplit cannot aim a reduction (0073 FR5)"
fi

echo "0085 AC10 — the marginal footprint is attributed to the turn that APPENDED it"
# Read off the SECOND fixture, whose contexts climb unevenly, and out of the `marg/turn` cell of
# each bucket row. The former assertion was `*10000*` over the whole output of the first fixture,
# and could not be red on any defect: that fixture's `ctx/turn` column prints 100000, 110000,
# 120000 and 130000, each of which contains `10000` as a substring. Zeroing the accumulator
# outright — `r["marg"] += rise` to `+= 0` — gave a marg/turn of 0 in every bucket and the guard
# printed 19 passed, 0 failed.
#   Reds by: zeroing that accumulator, or attributing `rise` to `turns[i + 1]` instead of `t`.
ac10() { # <label> <bucket> <expected marg/turn>
  got="$(cell "$OUT10" "$2" 8)"
  if [ "$got" = "$3" ]; then ok "$1"
  else bad "AC10 — $2 reports a marginal footprint of $got, not the $3 it appended: $1"; fi
}
ac10 "protocol appended 10000 and is charged 10000" protocol 10000
ac10 "git appended 30000 and is charged 30000, not protocol's 10000" git 30000
ac10 "work appended 50000 and is charged 50000, not git's 30000" work 50000
ac10 "orientation is last, appended nothing, and is charged 0 rather than work's 50000" orientation 0

echo "0085 — privacy: this tool reads command strings and edit payloads, so it could publish one"
OUT="$OUT
$OUT10"   # both fixtures, so a second run cannot be the one that leaks
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

# --- FR7: the change this ticket made to the verify skill ---------------------------------------
#
# FR7 is the one piece of work 0085 kept for itself rather than routing to a sibling: `verify`'s
# advisory dirty-path intersection was costing the session a second `git status` at verdict time,
# 20.5% of verify's mechanism turns against a 15.7% mean. The fix was prose — Step 2 captures the
# status in the same tool call as the first level command and holds it, Step 7 reuses that and
# issues no git command of its own.
#
# NOTHING ASSERTED IT. Reverting both hunks to the pre-FR7 wording left all fifteen guards green,
# so a develop pass's entire deliverable could be undone by an edit that read as a tidy-up. In a
# repo whose guards grep prose, an unguarded prose change is an unguarded change.
#
# Anchored to the four claims rather than to the sections carrying them, and each phrase sits
# within one line of the source: `grep` is line-based, so a phrase straddling a line break cannot
# be matched at all, which is why rewrapping a guarded paragraph here is a breaking change
# (CLAUDE.md). Reds by reverting either hunk.
VER="$ROOT/skills/verify/SKILL.md"

echo "0085 FR7 — verify pays no turn of its own for the dirty-path intersection"
fr7() { # <label> <fixed-string that must survive in skills/verify/SKILL.md>
  if grep -qF -- "$2" "$VER"; then ok "$1"
  else bad "FR7 — skills/verify/SKILL.md no longer says \"$2\": the turn 0085 removed comes back"; fi
}
fr7 "Step 2 fuses the status capture into the first level command, not a turn of its own" \
    "in the same tool call as the first"
fr7 "Step 2 holds that output for Step 7 instead of leaving it to be re-read" \
    "Hold the output for Step 7"
fr7 "Step 7 intersects the set Step 2 already captured" \
    "Step 2's captured dirty set"
fr7 "Step 7 issues no git command of its own" \
    "Issue no new git command here"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
