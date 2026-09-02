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
#   2. WHAT WAS WRITTEN DOWN — each claim the ticket requires, asserted against the STRUCTURE that
#      carries it: the table row, the section body, the line. The likely failure is a run that
#      produces figures and no verdict, and giving AC5 (the verdict) and AC8 (what was not held
#      constant) their own assertions is NOT on its own what catches it — that was this header's
#      claim until 0042 and it was false. Both were document-wide greps for a word, so AC8's
#      required heading `## What the two runs did not hold constant` contains "did not" and AC8
#      passing guaranteed AC5 passing; deleting the entire verdict left the suite green. Separate
#      assertions are necessary and the scope is what makes them sufficient. Each of the three
#      repaired assertions names, beside itself, the mutation that reds it — re-run those before
#      trusting any of them (`testing-conventions.md`, anchor to the claim not the document).
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
PROJECT="$ROOT/.claude/backlog/items/0009-one-skill-per-session.md"

# README's `modelled` count BEFORE this ticket, measured 2026-08-23. The assertion is that the
# count went DOWN: a stale "modelled" left in place next to a new observed figure is the quiet
# failure, and an absolute zero would be satisfied by deleting the section instead of updating it.
PRE_MODELLED=1

# How many sessions the published run excludes from its date window (0051). The window returns 42
# sessions and $170.17 today against a published 30 and $114.27, so the id set is the only thing
# pinning it and the recipe has to carry every one of them.
PINNED_EXCLUSIONS=12

PASS=0
FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }

# present <label> <file> <fixed-string>
# `--` before the pattern: an asserted string that starts with a dash (a CLI flag, which AC4
# asserts) is otherwise read by grep as its own option and the assertion errors instead of running.
present() {
  if [ -f "$2" ] && grep -qF -- "$3" "$2"; then ok "$1"; else bad "$1 — expected to find in $(basename "$2"): $3"; fi
}
# presenti <label> <file> <fixed-string> — case-insensitive; for a word whose capitalisation
# depends only on where it lands in a sentence.
presenti() {
  if [ -f "$2" ] && grep -qiF -- "$3" "$2"; then ok "$1"; else bad "$1 — expected to find in $(basename "$2"): $3"; fi
}
# absent <label> <file> <fixed-string>
absent() {
  if [ -f "$2" ] && grep -qF "$3" "$2"; then bad "$1 — expected NOT to find in $(basename "$2"): $3"; else ok "$1"; fi
}

FIX=""
SCOPE=""
cleanup() {
  [ -n "$FIX" ] && rm -rf "$FIX"
  [ -n "$SCOPE" ] && rm -rf "$SCOPE"
  return 0
}
trap cleanup EXIT INT TERM

# Structural scopes for the AC1 and AC5 assertions below.
#
# Both were document-wide greps for a word, and both were green against the deletion they exist to
# catch, because the word survives elsewhere in the same document (0042). An assertion is anchored
# to the claim, not to the document that contains it (`testing-conventions.md`): match the row, the
# line or the section body. These extractions are those scopes, and an extraction that comes back
# empty is reported as the failure it is -- never skipped, since a scope that matches nothing turns
# every assertion over it green precisely when the thing it guards has gone missing.
SCOPE="$(mktemp -d)"
VERDICT="$SCOPE/verdict"
TABLE="$SCOPE/table"
COSTPER="$SCOPE/cost-per-ticket"
RERUN="$SCOPE/rerun"
CMD="$SCOPE/rerun-command"
PINNED="$SCOPE/pinned"
if [ -f "$REC" ]; then
  awk '/^## Verdict$/{s=1;next} s&&/^## /{exit} s' "$REC" > "$VERDICT"
  awk '/^\|[[:space:]]*Skill[[:space:]]*\|/{s=1} s&&/^[[:space:]]*$/{exit} s' "$REC" > "$TABLE"
  awk '/^### Cost per closed ticket$/{s=1;next} s&&/^#+ /{exit} s' "$REC" > "$COSTPER"
  awk '/^## Re-running this$/{s=1;next} s&&/^## /{exit} s' "$REC" > "$RERUN"
  awk '/^```/{f=!f;next} f' "$RERUN" > "$CMD"
  awk '/^## How the figures here are pinned$/{s=1;next} s&&/^## /{exit} s' "$REC" > "$PINNED"
else
  : > "$VERDICT"; : > "$TABLE"; : > "$COSTPER"; : > "$RERUN"; : > "$CMD"; : > "$PINNED"
fi

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
# MUTATION THAT REDS THIS: delete the `| verify | 10 | ... |` line from the isolated-run table in
# MEASUREMENT.md. Before 0042 these were `present "$REC" "verify"` and friends over the whole
# record, and that mutation left 40/40 passing -- `queue`, `develop`, `verify`, "per turn" and
# "context" all occur in the record's surrounding prose, so the guard pinned vocabulary rather than
# the breakdown. What is asserted now is the ROW: the skill's name at the head of a table line
# followed by six populated cells. Deliberately no figures -- 0051 is due to move them, and a guard
# that reds on a corrected number teaches everyone to discount its reds.
if [ ! -s "$TABLE" ]; then
  bad "AC1 — no isolated-run table in MEASUREMENT.md: no line matching '| Skill |' to scope to"
else
  ok "the isolated-run table is present, so the row assertions below have a scope"
fi
# row <label> <skill> — that skill has a line in the isolated-run table carrying all six data cells.
row() {
  if grep -qE "^\\|[[:space:]]*$2[[:space:]]*\\|([^|]*[0-9][^|]*\\|){6}" "$TABLE"; then
    ok "$1"
  else
    bad "AC1 — no populated table row for '$2' in the isolated-run table (six data cells expected)"
  fi
}
row "queue has a row in the isolated-run table" "queue"
row "develop has a row in the isolated-run table" "develop"
row "verify has a row in the isolated-run table" "verify"
present "the table reports cost per turn" "$TABLE" "Cost per turn"
present "the table reports context per turn" "$TABLE" "Context per turn"

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
absent "0009's Outcome no longer says the figure is unobserved" "$PROJECT" "remains modelled rather than observed"
n=$(grep -ci "modelled" "$RME" || true)
if [ "$n" -lt "$PRE_MODELLED" ]; then
  ok "README's 'modelled' count fell from $PRE_MODELLED to $n"
else
  bad "AC4 — README still says 'modelled' $n time(s), was $PRE_MODELLED before this ticket"
fi
presenti "develop carries an observed figure" "$DEV" "observed"
presenti "verify carries an observed figure" "$VER" "observed"
present "0009 points at the record that holds the observed figures" "$PROJECT" "MEASUREMENT.md"

echo "AC5 — the verdict is stated explicitly, against the modelled figure"
present "the record names the modelled figure it is judged against" "$REC" "5.09"
# MUTATION THAT REDS THIS: delete the whole `## Verdict` section from MEASUREMENT.md. Before 0042
# this grepped the WHOLE record for materialised|partly|did not, and that mutation left it green --
# the section heading `## What the two runs did not hold constant` carries "did not", and AC8 below
# requires that heading to exist, so AC8 passing GUARANTEED this passing. Only the separate 5.09
# check reddened. A second mutation reds it too, which the section scope alone would not catch:
# delete just the verdict sentence and keep the section, since "The model's premise did not hold"
# lives further down the same section. Hence the first non-blank line, which is where a verdict is
# stated, rather than anywhere in the body.
VERDICT_LINE="$(grep -m1 '[^[:space:]]' "$VERDICT" || true)"
if [ -z "$VERDICT_LINE" ]; then
  bad "AC5 — MEASUREMENT.md has no '## Verdict' section body, so it states no verdict"
elif printf '%s\n' "$VERDICT_LINE" | grep -qE 'materialised|partly|did not'; then
  ok "the Verdict section opens with a verdict"
else
  bad "AC5 — the Verdict section opens with no verdict (none of materialised, partly, did not): $VERDICT_LINE"
fi
present "the record says what the run caught" "$REC" "caught"
present "the record says what it missed" "$REC" "missed"

echo "AC6 — cost per closed ticket"
present "the record carries cost per closed ticket" "$REC" "per closed ticket"

# 0051. The numerator was pinned and the denominator was not: $114.27 was fixed by an --exclude
# list while the closed-ticket count was re-read from a live DONE.md, so the published quotient
# decayed on its own. Every assertion below is scoped to the SECTION, never the record -- "per
# closed ticket" also appears in the verdict prose and in AC6 above, so a document-wide grep stays
# green with the whole section deleted (the 0042 lesson, applied to the figure 0042 left alone).
echo "0051 AC1 — the closed-ticket denominator is pinned, like the numerator over it"
# MUTATION THAT REDS THIS: delete the `### Cost per closed ticket` section from MEASUREMENT.md.
if [ ! -s "$COSTPER" ]; then
  bad "0051 AC1 — no '### Cost per closed ticket' section in MEASUREMENT.md to scope to"
else
  ok "the cost-per-closed-ticket section is present, so the assertions below have a scope"
fi
# MUTATION THAT REDS THIS: drop the `as at <date>` clause and leave the count bare.
if grep -qE 'as at 20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]' "$COSTPER"; then
  ok "the denominator carries an as-at stamp"
else
  bad "0051 AC1 — the section states no 'as at <ISO date>' stamp for its live denominator"
fi
# MUTATION THAT REDS THIS: delete the `closed on <date> and <date>` clause and leave the count
# bare. Two separate `present` greps for the two dates did NOT catch that -- both dates recur in
# the section's closing paragraph, so the bound could vanish with the assertions green. The bound
# has to be asserted AS a bound: one line, attached to the word it bounds.
if grep -qE 'closed on 20[0-9][0-9]-[0-9][0-9]-[0-9][0-9] and 20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]' "$COSTPER"; then
  ok "the count names the date bound that produced it, on the line that states it"
else
  bad "0051 AC1 — the section states no 'closed on <date> and <date>' bound for its count"
fi
present "the section names the live file the count was read from" "$COSTPER" "DONE.md"

echo "0051 AC2 — the published figure recomputes from its own numerator and denominator"
# Each claim is written "$<numerator> over <denominator> is **$<quotient> per closed ticket**", and
# this recomputes every one of them. It is the assertion the old record could not have passed: a
# corrected numerator beside a stale quotient reds here and nowhere else.
ARITH="$(python3 - "$COSTPER" <<'PY'
import re, sys
body = open(sys.argv[1]).read()
trip = re.findall(r'\$([0-9]+\.[0-9]{2}) over ([0-9]+) is \*\*\$([0-9]+\.[0-9]{2})', body)
if len(trip) < 2:
    print("FEWER THAN TWO recomputable claims in the section: %d" % len(trip))
    raise SystemExit
wrong = ["%s/%s = %.2f but the record publishes %s" % (n, d, round(float(n) / int(d), 2), q)
         for n, d, q in trip if abs(round(float(n) / int(d), 2) - float(q)) > 0.005]
print("BAD " + "; ".join(wrong) if wrong else "OK %d claims recompute" % len(trip))
PY
)"
case "$ARITH" in
  OK*) ok "every 'X over N is Y per closed ticket' claim recomputes — $ARITH" ;;
  *)   bad "0051 AC2 — $ARITH" ;;
esac

echo "0051 AC3 — README repeats the same denominator, so the two files cannot disagree"
DENOM="$(grep -oE '\$[0-9]+\.[0-9]{2} over [0-9]+' "$COSTPER" | head -1 | awk '{print $3}')"
if [ -z "$DENOM" ]; then
  bad "0051 AC3 — no denominator in the cost-per-closed-ticket section to compare README against"
elif grep -qE "closed \*{0,2}$DENOM\*{0,2} tickets" "$RME"; then
  ok "README states the same closed-ticket denominator, $DENOM"
else
  bad "0051 AC3 — MEASUREMENT.md divides by $DENOM but README does not say 'closed $DENOM tickets'"
fi

echo "0051 AC4 — the re-run recipe carries the session-id set, not a date window"
# MUTATION THAT REDS THIS: replace the command block with the bare
# `--since 2026-08-23 --sessions` it used to print. That command now returns 42 sessions and
# $170.17 against a published 30 and $114.27, and nothing in the record said so.
if [ ! -s "$RERUN" ]; then
  bad "0051 AC4 — no '## Re-running this' section in MEASUREMENT.md to scope to"
else
  ok "the re-running section is present, so the assertions below have a scope"
fi
if [ ! -s "$CMD" ]; then
  bad "0051 AC4 — the re-running section prints no fenced command to check"
else
  ok "the re-running section prints a command"
fi
NEX="$(grep -o -- '--exclude' "$CMD" | wc -l | tr -d ' ')"
if [ "$NEX" -ge "$PINNED_EXCLUSIONS" ]; then
  ok "the printed command pins the harvest with $NEX --exclude flags"
else
  bad "0051 AC4 — the printed command carries $NEX --exclude flags; the pinned set needs $PINNED_EXCLUSIONS"
fi
present "the printed command bounds the window at its far end too" "$CMD" "--until"
present "the recipe states the session count it reproduces" "$RERUN" "30 sessions"
present "the recipe states the total it reproduces" "$RERUN" "114.27"

echo "0051 FR6 — the record no longer asserts a pin it does not carry"
absent "the false claim to carry its own pin is gone" "$REC" "pin the exclusions and record them"

echo "0051 FR1/documentation — the as-at convention is stated once, where a new figure is read"
# MUTATION THAT REDS THIS: delete the `## How the figures here are pinned` section. Scoped, not a
# document-wide grep for "as at": the stamps themselves carry that phrase, so the convention could
# vanish while every figure still passed AC1.
if [ ! -s "$PINNED" ]; then
  bad "0051 FR1 — no '## How the figures here are pinned' section stating the convention once"
else
  ok "the as-at convention has a section of its own"
fi
present "the convention names the failure it exists to prevent" "$PINNED" "both sides"

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

# ---------------------------------------------------------------------------------------------
# 0073 — where a stage session's turns go
#
# Same two jobs as above, on the second measurement this record carries: the ARITHMETIC of
# tools/classify-turns.sh against a fixture whose category for every turn is known by
# construction, and WHAT WAS WRITTEN DOWN about it. Each prose assertion is scoped to the
# section that carries the claim, for the reason 0042 recorded: a document-wide grep for
# `mechanism` or `estimate` stays green when the section holding the figure is deleted, because
# both words survive in the ticket-shaped prose around it.
# ---------------------------------------------------------------------------------------------

CLASSIFY="$ROOT/tools/classify-turns.sh"

TURNS="$SCOPE/turns"
BUDGET="$SCOPE/budget"
GROWTH="$SCOPE/growth"
AIM="$SCOPE/aim"
if [ -f "$REC" ]; then
  awk '/^## Where a session.s turns go$/{s=1;next} s&&/^## /{exit} s' "$REC" > "$TURNS"
  awk '/^### The turn budget$/{s=1;next} s&&/^#+ /{exit} s' "$REC" > "$BUDGET"
  awk '/^### What the context is made of$/{s=1;next} s&&/^#+ /{exit} s' "$REC" > "$GROWTH"
  awk '/^### Where the reduction aims$/{s=1;next} s&&/^#+ /{exit} s' "$REC" > "$AIM"
else
  : > "$TURNS"; : > "$BUDGET"; : > "$GROWTH"; : > "$AIM"
fi

echo "0073 FR2 — the classifier is committed and runnable"
if [ -x "$CLASSIFY" ]; then
  ok "tools/classify-turns.sh exists and is executable"
else
  bad "0073 FR2 — no executable script at tools/classify-turns.sh"
fi

echo "0073 AC3 — the classification, against a fixture whose every turn has a known category"
# Six turns, one per category outcome, in a session marked `develop`:
#   1 no tool call                          -> narration
#   2 reads the skill file                  -> orientation
#   3 runs the claim script                 -> mechanism
#   4 an Edit tool call                     -> work
#   5 runs the suite                        -> work
#   6 a shell command matching no rule      -> other
# So turns/session is 6.0, work is 33.3%, and each of the other four is 16.7%.
#
# Context is built so the own-turn estimator has one arithmetic answer: context per turn climbs
# 100 -> 200 -> ... -> 600, so growth over the five deltas is 500, and each turn emits 50 output
# tokens, so the five prior-turn outputs total 250 -- exactly 50.0% of the growth.
mkdir -p "$FIX/store3"
cu() { printf '{"input_tokens":%d,"cache_read_input_tokens":0,"cache_creation_input_tokens":0,"output_tokens":50}' "$1"; }
asst() { # asst <n> <context> <content-json>
  printf '{"type":"assistant","timestamp":"2026-08-23T03:00:0%s.000Z","message":{"id":"msg_cls_%s","model":"claude-opus-5","content":%s,"usage":%s}}\n' \
    "$1" "$1" "$3" "$(cu "$2")"
}
bash_call() { printf '[{"type":"tool_use","id":"t%s","name":"Bash","input":{"command":"%s"}}]' "$1" "$2"; }
{
  printf '{"type":"user","timestamp":"2026-08-23T03:00:00.000Z","message":{"role":"user","content":"<command-name>/ai-building-tools:develop</command-name>"}}\n'
  asst 1 100 '[{"type":"text","text":"SENTINELPROSE no tool call here"}]'
  asst 2 200 "$(bash_call 2 'cat skills/develop/SKILL.md')"
  asst 3 300 "$(bash_call 3 './.claude/backlog/claim 0073')"
  asst 4 400 '[{"type":"tool_use","id":"t4","name":"Edit","input":{"file_path":"MEASUREMENT.md","old_string":"SENTINELPROSE","new_string":"b"}}]'
  asst 5 500 "$(bash_call 5 'tests/measurement.test.sh')"
  asst 6 600 "$(bash_call 6 'echo SENTINELPROSE')"
} > "$FIX/store3/cccccccc-0000-0000-0000-000000000000.jsonl"

if [ -x "$CLASSIFY" ]; then OUT3="$("$CLASSIFY" "$FIX/store3" 2>&1 || true)"; else OUT3=""; fi

# check3 <label> <needle> <what-a-miss-means>
check3() {
  case "$OUT3" in
    *"$2"*) ok "$1" ;;
    *) bad "0073 AC3 — $3; got: $(printf '%s' "$OUT3" | tr '\n' ' ' | cut -c1-240)" ;;
  esac
}
check3 "turns per session is 6.0" "6.0" "expected a turns-per-session figure of 6.0"
check3 "work is 33.3% of turns — the Edit and the suite run" "33.3" "expected work to be 33.3% of turns"
check3 "the four single-turn categories are 16.7% each" "16.7" "expected a 16.7% share for the single-turn categories"
check3 "own prior turns account for 50.0% of context growth" "50.0" "expected the own-turn share of growth to be 50.0%"
check3 "the fixture session is attributed to develop" "develop" "the fixture session was not attributed to develop"

for cat in mechanism orientation work narration other; do
  case "$OUT3" in
    *"$cat"*|*"$(printf '%s' "$cat" | tr 'a-z' 'A-Z')"*) ok "the output names the $cat category" ;;
    *) bad "0073 FR2 — the classifier output does not name the $cat category" ;;
  esac
done

echo "0073 AC3 — a response split across lines is classified by ALL of its blocks"
# THE DEFECT THIS CAUGHT, and the reason it is a fixture and not a review note. A single API
# response is written to the transcript as several lines, one per content block -- the fact
# tools/harvest-usage.sh dedupes cost by message id to survive. The text block comes first and the
# tool calls follow on later lines, so a classifier that keeps only the FIRST line of each id sees
# no tool call at all and reports the turn as narration. Run against the real pinned set that read
# 84.5% narration and 0.0% mixed, and both figures were plausible enough to publish. The fixture
# above cannot catch it: it puts every block of a turn on one line, which no real response does.
#
# Two turns, blocks split across lines, same ids:
#   turn A: a text block, then a read of the skill file   -> orientation, not mixed
#   turn B: an Edit, then a read of the skill file        -> work by precedence, and mixed
# So narration is 0.0%, orientation and work are 50.0% each, and mixed is 50.0%.
mkdir -p "$FIX/store4"
line4() { # line4 <msg-id> <context> <content-json>
  printf '{"type":"assistant","timestamp":"2026-08-23T04:00:00.000Z","message":{"id":"msg_split_%s","model":"claude-opus-5","content":%s,"usage":%s}}\n' \
    "$1" "$3" "$(cu "$2")"
}
{
  printf '{"type":"user","timestamp":"2026-08-23T04:00:00.000Z","message":{"role":"user","content":"<command-name>/ai-building-tools:verify</command-name>"}}\n'
  line4 a 100 '[{"type":"text","text":"SENTINELPROSE about to look at the skill"}]'
  line4 a 100 "$(bash_call a1 'cat skills/verify/SKILL.md')"
  line4 b 200 '[{"type":"tool_use","id":"tb1","name":"Edit","input":{"file_path":"MEASUREMENT.md","old_string":"SENTINELPROSE","new_string":"b"}}]'
  line4 b 200 "$(bash_call b2 'cat skills/verify/SKILL.md')"
} > "$FIX/store4/dddddddd-0000-0000-0000-000000000000.jsonl"

if [ -x "$CLASSIFY" ]; then OUT4="$("$CLASSIFY" "$FIX/store4" 2>&1 || true)"; else OUT4=""; fi
# `NF >= 10` and `exit` scope every extraction to the FIRST table. The growth table below it
# opens its rows with the same stage name, so a bare /^verify/ returns two values and every
# comparison against one of them fails on a string that is two numbers.
cell4() { printf '%s\n' "$OUT4" | awk -F'|' -v c="$1" '/^verify/ && NF >= 10 {gsub(/[ %]/,"",$c); print $c; exit}'; }
TURNS4="$(cell4 3)"
NARR4="$(cell4 8)"
MIXED4="$(cell4 10)"
if [ "$TURNS4" = "2" ]; then
  ok "the two split responses count as two turns, not four"
else
  bad "0073 AC3 — expected 2 turns from two split responses; got: ${TURNS4:-nothing}"
fi
if [ "$NARR4" = "0.0" ]; then
  ok "a turn whose tool calls are on later lines is not counted as narration"
else
  bad "0073 AC3 — narration is ${NARR4:-nothing}%, not 0.0%: the classifier is reading only the first line of each response"
fi
if [ "$MIXED4" = "50.0" ]; then
  ok "a turn spanning two categories across two lines is reported as mixed"
else
  bad "0073 AC3 — mixed is ${MIXED4:-nothing}%, not 50.0%: blocks on later lines are not reaching the precedence rule"
fi
case "$OUT4" in
  *SENTINELPROSE*) bad "0073/privacy — content from the split-response fixture reached the output" ;;
  *) ok "no content from the split-response fixture reaches the output" ;;
esac

echo "0073 FR3 — the startup floor is reported beside the climb"
# The climb is only half the question. A session also pays a FLOOR before it does anything -- the
# system prompt, the tool definitions, the skill file, the conventions -- and "load only what is
# needed" acts on the floor while "fewer turns" acts on the climb. Publishing one without the
# other invites a reduction aimed at whichever half happens to be smaller. The fixture climbs
# 100 -> 600 across its six turns, so the floor is 100 and the climb is 500.
case "$OUT3" in
  *"STARTUP FLOOR"*) ok "the classifier reports the startup floor" ;;
  *) bad "0073 FR3 — the classifier reports no startup floor, only the climb" ;;
esac
FLOOR3="$(printf '%s\n' "$OUT3" | awk -F'|' '/^develop/ && NF == 6 {gsub(/[ %]/,"",$3); print $3; exit}')"
CLIMB3="$(printf '%s\n' "$OUT3" | awk -F'|' '/^develop/ && NF == 6 {gsub(/[ %]/,"",$5); print $5; exit}')"
if [ "$FLOOR3" = "100" ]; then
  ok "the floor is the first turn's context, 100"
else
  bad "0073 FR3 — expected a floor of 100; got: ${FLOOR3:-nothing}"
fi
if [ "$CLIMB3" = "500" ]; then
  ok "the climb is the rise from first turn to last, 500"
else
  bad "0073 FR3 — expected a climb of 500; got: ${CLIMB3:-nothing}"
fi

echo "0073 FR5 — the largest category is broken down far enough to aim a reduction at"
# `mechanism` being the largest category is not on its own a target: it spans the backlog protocol
# and the git bookkeeping around it, and those are two different fixes. The fixture's turn 3 runs
# the claim script, so the composition table must attribute one turn to it.
case "$OUT3" in
  *"MECHANISM COMPOSITION"*) ok "the classifier breaks the mechanism turns down by what they ran" ;;
  *) bad "0073 FR5 — the classifier publishes no breakdown of the mechanism category" ;;
esac
if printf '%s\n' "$OUT3" | grep -qi 'backlog script'; then
  ok "the composition names the backlog-script share"
else
  bad "0073 FR5 — the composition does not name the backlog-script share the fixture contains"
fi

echo "0073 privacy NFR — the classifier emits no transcript content"
# The classifier is the one script here that READS command strings, so it is the one that could
# publish one. The fixture puts SENTINELPROSE in a message, in an edit payload and inside a shell
# command for exactly that reason.
case "$OUT3" in
  *SENTINELPROSE*) bad "0073/privacy — transcript content from the fixture reached the output" ;;
  *) ok "no fixture message, edit payload or command string reaches the output" ;;
esac
BADLINE3="$(printf '%s\n' "$OUT3" | grep -vn '^[A-Za-z0-9 .,$%|:/-]*$' | head -1 || true)"
if [ -z "$BADLINE3" ]; then
  ok "every classifier output line is within the aggregate-figures character set"
else
  bad "0073/privacy — a classifier output line leaves the aggregate-figures character set: $BADLINE3"
fi

echo "0073 AC1 — the record reports turns per session, per stage"
if [ ! -s "$TURNS" ]; then
  bad "0073 AC1 — no \"## Where a session's turns go\" section in MEASUREMENT.md to scope to"
else
  ok "the turns section is present, so the assertions below have a scope"
fi
present "the section carries a turns-per-session figure" "$TURNS" "Turns per session"

echo "0073 AC2 — the categories, their shares, and the code that produced them"
# MUTATION THAT REDS EACH: delete the category's column from the table in that section. A
# document-wide grep would not catch it — every one of these words also appears in FR2 of
# `items/0073-*.md`, which is not what the reader of this record is being promised.
present "the section names the mechanism category" "$TURNS" "echanism"
present "the section names the orientation category" "$TURNS" "rientation"
present "the section names the narration category" "$TURNS" "arration"
present "the section names the classifier that produced the shares" "$TURNS" "classify-turns.sh"
present "the section states the precedence that decides a mixed turn" "$TURNS" "recedence"

echo "0073 AC4 — the context-growth split is published as an estimate, with its estimator"
if [ ! -s "$GROWTH" ]; then
  bad "0073 AC4 — no '### What the context is made of' subsection to scope to"
else
  ok "the context-growth subsection is present"
fi
presenti "the growth figure is labelled an estimate where it is published" "$GROWTH" "estimate"
present "the estimator is stated, not merely claimed to exist" "$GROWTH" "own prior turns"

echo "0073 AC5 — a turn budget per stage, as a number with a date"
if [ ! -s "$BUDGET" ]; then
  bad "0073 AC5 — no '### The turn budget' subsection to scope to"
else
  ok "the turn-budget subsection is present"
fi
if grep -qE '20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]' "$BUDGET"; then
  ok "the turn budget carries a date"
else
  bad "0073 AC5 — the turn budget states no date; a budget without one cannot come due"
fi
for stage in develop verify queue; do
  present "the budget names a figure for $stage" "$BUDGET" "$stage"
done

echo "0073 AC6 — the largest category, and the id of the reduction ticket opened against it"
if [ ! -s "$AIM" ]; then
  bad "0073 AC6 — no '### Where the reduction aims' subsection to scope to"
else
  ok "the reduction-aim subsection is present"
fi
if grep -qE '\b0(0[0-9][0-9]|[1-9][0-9]{2})\b' "$AIM"; then
  ok "the reduction aim names a four-digit backlog id"
else
  bad "0073 AC6 — the reduction aim names no backlog ticket, so nothing carries the reduction"
fi

echo "0073 AC7/FR6 — the classification reproduces from a pinned command, not a date window"
CLSCMD="$SCOPE/classify-command"
awk '/^```/{f=!f;next} f' "$TURNS" > "$CLSCMD"
if [ ! -s "$CLSCMD" ]; then
  bad "0073 AC7 — the turns section prints no fenced command to reproduce it"
else
  ok "the turns section prints a command"
fi
present "the printed command runs the classifier" "$CLSCMD" "classify-turns.sh"
NEX3="$(grep -o -- '--exclude' "$CLSCMD" | wc -l | tr -d ' ')"
if [ "$NEX3" -ge "$PINNED_EXCLUSIONS" ]; then
  ok "the classifier command pins the same session set with $NEX3 --exclude flags"
else
  bad "0073 FR6 — the classifier command carries $NEX3 --exclude flags; the pinned set needs $PINNED_EXCLUSIONS"
fi


echo "Privacy & data NFR — no home-directory path in any tracked file"
# The repo is public, so a path belonging to the machine that built it is an egress of exactly
# what the NFR row puts out of bounds: a path outside this repo. This is a guard rather than a
# review note because 0026 shipped four such strings with all nine of its ACs green.
#
# Two spellings, one rule: the absolute filesystem path, and the dash-separated slug the
# transcript store makes of it. Both platforms are covered — a contributor on Linux leaks the
# same fact. Neither form is written out anywhere in this file, and the pattern puts a bracket
# before the word, so the guard cannot match its own text and report the repo dirty.
HOME_PATH_PAT='[-/](Users|home)[-/]'
if ! git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  bad "Privacy & data NFR — cannot check: $ROOT is not a git repository, so the tracked set is unknown"
elif leaked=$(git -C "$ROOT" grep -nE "$HOME_PATH_PAT"); then
  bad "Privacy & data NFR — a tracked file publishes a home-directory path:
$leaked"
else
  ok "no tracked file publishes a home-directory path, in either spelling"
fi

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" = 0 ]
