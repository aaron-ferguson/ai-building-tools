#!/bin/sh
#
# Guard for the sprint estimate ledger (0135).
#
# WHY THIS EXISTS:
#
# Every cost figure in this repo is an ACTUAL. An estimate that is never scored against an outcome
# cannot improve, so the proposal `0130` introduced would have stayed a guess indefinitely. This
# ticket adds the other half -- an estimate recorded BEFORE the work, paired with the actual, and
# read back to derive the next estimate -- and this guard is what keeps the pairing honest.
#
# WHAT IT CHECKS, AND WHAT EACH CHECK CANNOT SEE:
#
#   arithmetic  tools/sprint-ledger.sh is fed GENERATED fixtures -- a run log with known UTC
#               timestamps and a transcript store with known token counts -- and the derived
#               figures are asserted exactly. Fixtures are authored, never a copy of the live
#               ledger (testing-conventions.md, the fixture rule), so a live run cannot turn an
#               assertion green by accident.
#
#   the pairing  a recorded sprint block must hold an ESTIMATE and an ACTUAL for all four figures.
#               Anchored to the row, not to the document: "tickets" and "usd" both occur in the
#               ledger's own preamble, so a document-wide grep for either is satisfied by prose
#               that survives the block being deleted.
#
#   provenance   every figure carries the source it was read from and the stamp it was true at,
#               and both sides of every ratio carry one. Checked structurally -- a RATIO line must
#               be followed by a numerator and a denominator line, each carrying an `@` stamp --
#               because the failure this repairs is a pinned numerator over a live denominator,
#               which is invisible to any check on the ratio's own line.
#
#   Blind spot: nothing here can tell a CORRECT prior from a plausible one. What is checkable is
#   that a figure with no prior is LABELLED, and that is anchored to the label rather than to the
#   number, so a future prior for wall-clock turns this red rather than silently passing.
#
# Usage:  tests/sprint-ledger.test.sh
#
# Requires: sh, grep, awk, python3. No runner -- this project has none.

set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
TOOL="$ROOT/tools/sprint-ledger.sh"
HARVEST="$ROOT/tools/harvest-usage.sh"
LEDGER="$ROOT/.claude/backlog/LEDGER.md"
SKILL="$ROOT/skills/sprint/SKILL.md"
MEAS="$ROOT/MEASUREMENT.md"
CONF="$ROOT/.claude/backlog/config.yml"

PASS=0
FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }

FIX=""
cleanup() { [ -n "$FIX" ] && rm -rf "$FIX"; return 0; }
trap cleanup EXIT INT TERM
FIX="$(mktemp -d)"

# says <file> <section> <fixed-string> -- the section unwrapped to one logical line, so an
# assertion about a CLAIM is not broken by where the prose happens to wrap. `tests/batching.test.sh`
# learned this the hard way: a line-based grep makes every rewrap a breaking change.
says() {
  awk -v s="## $2" '
    index($0, s) == 1 { inw = 1; next }
    inw && /^## / { exit }
    inw { printf "%s ", $0 }
  ' "$1" | grep -qF -- "$3"
}

# ---------------------------------------------------------------------------------------------
echo "the tool is committed and runnable"
if [ -x "$TOOL" ]; then
  ok "tools/sprint-ledger.sh exists and is executable"
else
  bad "no executable script at tools/sprint-ledger.sh"
fi

echo "the ledger file exists and is the one the skill names"
if [ -f "$LEDGER" ]; then
  ok ".claude/backlog/LEDGER.md is committed"
else
  bad "no ledger at .claude/backlog/LEDGER.md"
fi

# --- the fixtures -----------------------------------------------------------------------------
# A run log whose UTC timestamps bracket the run at exactly five hours, carrying two stage
# sessions: a develop gate of three tickets and one batched verify over the same three. The
# timestamps are the ONLY source of wall-clock (FR2, no new instrumentation), so the fixture pins
# a figure nothing else in the repo can produce.
RUNLOG="$FIX/r-fixture.jsonl"
SID_DEV="aaaaaaaa-0000-0000-0000-000000000000"
SID_VER="bbbbbbbb-0000-0000-0000-000000000000"
cat > "$RUNLOG" <<JSON
{"ts":"2026-09-06T09:00:00Z","run":"r-fixture","event":"run_started"}
{"ts":"2026-09-06T09:01:00Z","run":"r-fixture","event":"scope_confirmed","tickets":["0101","0102","0103"]}
{"ts":"2026-09-06T09:02:00Z","run":"r-fixture","event":"dispatch","stage":"develop","session_id":"$SID_DEV","tickets":["0101","0102","0103"]}
{"ts":"2026-09-06T11:00:00Z","run":"r-fixture","event":"outcome","stage":"develop","session_id":"$SID_DEV","findings_parked":3,"tickets":[{"id":"0101"},{"id":"0102"},{"id":"0103"}]}
{"ts":"2026-09-06T11:05:00Z","run":"r-fixture","event":"dispatch","stage":"verify","session_id":"$SID_VER","tickets":["0101","0102","0103"]}
{"ts":"2026-09-06T13:55:00Z","run":"r-fixture","event":"outcome","stage":"verify","session_id":"$SID_VER","findings_parked":2,"tickets":[{"id":"0101"},{"id":"0102"},{"id":"0103"}]}
{"ts":"2026-09-06T14:00:00Z","run":"r-fixture","event":"sprint_ended"}
JSON

# Two transcript sessions with known token counts, priced at the Opus 5 rates harvest-usage.sh
# states. Output-only turns keep the arithmetic readable: 25.00 USD per million output tokens.
#   develop session: 400,000 output tokens -> USD 10.00, context 0
#   verify  session: 240,000 output tokens -> USD  6.00, context 0
# A THIRD session sits in the same store and belongs to NO run. It is what makes FR3's claim
# falsifiable: a date window would sweep it in, an id set does not.
mkdir -p "$FIX/store"
u() { printf '{"input_tokens":0,"cache_read_input_tokens":0,"cache_creation_input_tokens":0,"output_tokens":%s}' "$1"; }
mk_session() {
  printf '{"type":"user","timestamp":"2026-09-06T09:02:00.000Z","message":{"role":"user","content":"<command-name>/ai-building-tools:%s</command-name>"}}\n' "$2"
  printf '{"type":"assistant","timestamp":"2026-09-06T09:03:00.000Z","message":{"id":"msg_%s","model":"claude-opus-5","content":[{"type":"text","text":"SENTINELPROSE the quick brown fox"}],"usage":%s}}\n' "$2" "$(u "$3")"
}
mk_session "$SID_DEV" develop 400000 > "$FIX/store/$SID_DEV.jsonl"
mk_session "$SID_VER" verify  240000 > "$FIX/store/$SID_VER.jsonl"
mk_session "cccccccc-0000-0000-0000-000000000000" queue 800000 > "$FIX/store/cccccccc-0000-0000-0000-000000000000.jsonl"

# --- FR3 -- the harvest selects by session id, never by a date window --------------------------
echo "FR3 -- token and dollar actuals are read over a session-id set, not a date window"
if [ -x "$HARVEST" ]; then
  H_ALL="$("$HARVEST" "$FIX/store" 2>&1 || true)"
  H_SEL="$("$HARVEST" "$FIX/store" --session "$SID_DEV" --session "$SID_VER" 2>&1 || true)"
else
  H_ALL=""; H_SEL=""
fi
case "$H_ALL" in
  *"36.00"*) ok "the whole store totals USD 36.00, so the unrelated session is really in it" ;;
  *) bad "FR3 -- fixture store did not total 36.00; got: $(printf '%s' "$H_ALL" | tr '\n' ' ' | cut -c1-200)" ;;
esac
case "$H_SEL" in
  *"16.00"*) ok "--session over the run's two ids totals USD 16.00, excluding the third session" ;;
  *) bad "FR3 -- --session did not select the id set; expected 16.00, got: $(printf '%s' "$H_SEL" | tr '\n' ' ' | cut -c1-200)" ;;
esac
case "$H_SEL" in
  *"36.00"*) bad "FR3 -- --session was accepted and ignored: the unrelated session is still counted" ;;
  *) ok "the unrelated session does not reach the selected total" ;;
esac

# --- AC2 -- the first sprint's wall-clock figure is labelled as having no prior ----------------
echo "AC2 -- a figure with no prior is labelled rather than presented as derived"
EMPTY="$FIX/empty-ledger.md"
printf '# Sprint ledger\n\nNo sprint has been recorded yet.\n' > "$EMPTY"
if [ -x "$TOOL" ]; then
  EST1="$("$TOOL" estimate --ledger "$EMPTY" --measurement "$MEAS" --config "$CONF" --tickets 3 --develop-gates 1 --verify-sessions 1 2>&1 || true)"
else
  EST1=""
fi
WALLLINE="$(printf '%s\n' "$EST1" | grep '^ESTIMATE  *wall_clock_min' || true)"
if [ -n "$WALLLINE" ]; then
  ok "the estimate names a wall_clock_min figure"
else
  bad "AC2 -- no wall_clock_min line in the estimate; got: $(printf '%s' "$EST1" | tr '\n' ' ' | cut -c1-200)"
fi
case "$WALLLINE" in
  *"no prior"*) ok "and marks it as having no prior when no sprint has been recorded" ;;
  *) bad "AC2 -- the wall-clock figure is not marked as having no prior: $WALLLINE" ;;
esac
# The dollar figure DOES have a prior, and the criterion is that the two are distinguishable.
USDLINE="$(printf '%s\n' "$EST1" | grep '^ESTIMATE  *usd' || true)"
case "$USDLINE" in
  *"no prior"*) bad "AC2 -- the dollar figure is marked as having no prior; MEASUREMENT.md is its prior" ;;
  *MEASUREMENT.md*) ok "while the dollar figure cites MEASUREMENT.md, so the two are distinguishable" ;;
  *) bad "AC2 -- the dollar figure names no source: $USDLINE" ;;
esac

# --- AC3 -- with a history, the estimate comes from the ledger and not from the priors ---------
echo "AC3 -- the third sprint's estimate is derived from two recorded actuals"
HIST="$FIX/two-sprints.md"
cat > "$HIST" <<'MD'
# Sprint ledger

## sprint r-one -- ended 2026-09-01T14:00:00Z

| Figure | Estimate | Actual | Estimate source |
|---|---|---|---|
| tickets | 2 | 2 | confirmed scope @ 2026-09-01T09:00:00Z |
| wall_clock_min | no prior | 200 | none @ 2026-09-01T09:00:00Z |
| tokens | 1000000 | 1200000 | MEASUREMENT.md per-skill table, recorded 2026-08-24 @ 2026-09-01T09:00:00Z |
| usd | 10.00 | 12.00 | MEASUREMENT.md per-skill table, recorded 2026-08-24 @ 2026-09-01T09:00:00Z |

## sprint r-two -- ended 2026-09-03T14:00:00Z

| Figure | Estimate | Actual | Estimate source |
|---|---|---|---|
| tickets | 2 | 2 | confirmed scope @ 2026-09-03T09:00:00Z |
| wall_clock_min | no prior | 400 | none @ 2026-09-03T09:00:00Z |
| tokens | 1000000 | 800000 | MEASUREMENT.md per-skill table, recorded 2026-08-24 @ 2026-09-03T09:00:00Z |
| usd | 10.00 | 8.00 | MEASUREMENT.md per-skill table, recorded 2026-08-24 @ 2026-09-03T09:00:00Z |
MD
if [ -x "$TOOL" ]; then
  EST3="$("$TOOL" estimate --ledger "$HIST" --measurement "$MEAS" --config "$CONF" --tickets 2 --develop-gates 1 --verify-sessions 1 2>&1 || true)"
else
  EST3=""
fi
W3="$(printf '%s\n' "$EST3" | grep '^ESTIMATE  *wall_clock_min' || true)"
case "$W3" in
  *"no prior"*) bad "AC3 -- wall-clock still has no prior after two recorded sprints: $W3" ;;
  *LEDGER*|*ledger*) ok "wall_clock_min is now derived from the ledger rather than labelled unsourced" ;;
  *) bad "AC3 -- wall_clock_min names no ledger source after two sprints: $W3" ;;
esac
# 200 and 400 minutes over two ticket-pairs is 150 minutes per ticket; two tickets is 300.
case "$W3" in
  *" 300 "*|*" 300"*) ok "and its value is the recorded mean per ticket, 300 minutes for two" ;;
  *) bad "AC3 -- wall-clock was not derived from the recorded actuals (expected 300): $W3" ;;
esac
U3="$(printf '%s\n' "$EST3" | grep '^ESTIMATE  *usd' || true)"
case "$U3" in
  *LEDGER*|*ledger*) ok "and the dollar estimate is taken from the ledger, not from MEASUREMENT.md" ;;
  *) bad "AC3 -- the ledger is written but never read; the dollar estimate still cites the priors: $U3" ;;
esac

# --- record ------------------------------------------------------------------------------------
OUTLEDGER="$FIX/out-ledger.md"
cp "$EMPTY" "$OUTLEDGER"
# One string, so the refusal cases below feed `record` exactly what the happy path feeds it and a
# difference between the two cannot be what makes a case pass. It carries an `@` stamp because FR8
# requires one and `paired()` now asserts it.
EST_SOURCE="MEASUREMENT.md per-skill table, recorded 2026-08-24 @ 2026-09-06T09:01:00Z"
if [ -x "$TOOL" ]; then
  REC="$("$TOOL" record --ledger "$OUTLEDGER" --run "$RUNLOG" --transcripts "$FIX/store" \
         --measurement "$MEAS" --config "$CONF" --estimate-tickets 3 --estimate-wall no-prior \
         --estimate-tokens 1200000 --estimate-usd 20.00 \
         --estimate-source "$EST_SOURCE" 2>&1 || true)"
else
  REC=""
fi
BLOCK="$FIX/block"
awk '/^## sprint /{s=1} s' "$OUTLEDGER" > "$BLOCK" 2>/dev/null || : > "$BLOCK"

echo "AC1 -- the recorded sprint holds an estimate AND an actual for all four figures"
if [ -s "$BLOCK" ]; then
  ok "record appended a sprint block to the ledger"
else
  bad "AC1 -- no '## sprint ' block in the ledger after record; got: $(printf '%s' "$REC" | tr '\n' ' ' | cut -c1-200)"
fi
# Anchored to the ROW and to both cells being populated: a document-wide grep for "tickets" is
# satisfied by the ledger's own preamble and survives the whole block being deleted.
#
# AND ANCHORED TO THE SOURCE COLUMN, which is the half a default cannot forge. "The cell is
# populated" is not "a figure was estimated": defaulting --estimate-usd to 0.0 leaves every
# populated-cell assertion green while the estimate column holds a figure nobody supplied. FR8's
# actual claim is that every figure carries the source it was read from AND the stamp it was true
# at, so the fourth cell must carry an `@` stamp -- which `unsourced`, the string that default
# once wrote, does not and cannot.
paired() {
  if grep -qE "^\|[[:space:]]*$1[[:space:]]*\|[^|]*[^|[:space:]][^|]*\|[^|]*[0-9][^|]*\|[^|]*@[^|]*\|" "$BLOCK"; then
    ok "$1 carries an estimate, an actual, and a stamped estimate source"
  else
    bad "AC1/FR8 -- $1 has no row carrying an estimate, a numeric actual and an @-stamped source: $(grep -E "^\|[[:space:]]*$1[[:space:]]*\|" "$BLOCK" || echo 'no such row')"
  fi
}
paired tickets
paired wall_clock_min
paired tokens
paired usd

# --- AC1/FR8 -- `record` REFUSES a missing estimate rather than defaulting one -------------------
# The red AC1 names and `paired()` above cannot see: `parse()` once defaulted --estimate-usd to
# 0.0 and --estimate-source to the literal `unsourced`, so an omitted flag appended a committed
# block reading `| usd | 0.00 | 16.00 | unsourced |` -- a figure nobody estimated, a source that is
# an admission of having none, and no stamp -- and exited 0. `paired()` is green on that, because
# a populated cell is not an estimated figure.
#
# THE SUBJECT LIST IS DERIVED FROM THE TOOL, never enumerated here: a fifth estimate figure added
# to `parse()`'s defaults joins this list the day it is added, which is the moment the rule most
# needs a guard (`testing-conventions.md`, a guard that enumerates its own subjects cannot notice
# a new one). `--estimate-wall` is subtracted deliberately and that exception is pinned by its own
# case below: its default `no prior` is the explicit declaration AC2 asks for, not a forged figure.
REQUIRED_EST="$(sed -n '/^def parse(/,/^    i = 0$/p' "$TOOL" \
  | grep -o '"estimate_[a-z_]*"' | tr -d '"' | sort -u \
  | grep -v '^estimate_wall$' | sed 's/^estimate_/--estimate-/')"

echo "AC1/FR8 -- record refuses an omitted estimate flag instead of defaulting it"
if [ -n "$REQUIRED_EST" ]; then
  ok "the required-estimate list was derived from the tool ($(printf '%s' "$REQUIRED_EST" | tr '\n' ' '))"
else
  bad "AC1/FR8 -- the derivation over parse()'s defaults matched nothing, so every case below would loop zero times and pass"
fi

# A value per flag. An unrecognised one is a LOUD failure rather than a skip: a new estimate figure
# whose fixture value nobody supplied is exactly the case the derivation exists to surface.
est_value() {
  case "$1" in
    --estimate-tickets) printf '3' ;;
    --estimate-wall)    printf 'no-prior' ;;
    --estimate-tokens)  printf '1200000' ;;
    --estimate-usd)     printf '20.00' ;;
    --estimate-source)  printf '%s' "$EST_SOURCE" ;;
    *) return 1 ;;
  esac
}

# `record` over the standard fixtures with $1 and its value left out. Every other flag is passed,
# so a refusal naming a flag other than $1 is a failure of this case and not a pass by luck.
record_without() {
  rw_drop="$1"
  rw_out="$FIX/refuse-ledger.md"
  cp "$EMPTY" "$rw_out"
  set -- record --ledger "$rw_out" --run "$RUNLOG" --transcripts "$FIX/store" \
      --measurement "$MEAS" --config "$CONF"
  for rw_f in $REQUIRED_EST --estimate-wall; do
    [ "$rw_f" = "$rw_drop" ] && continue
    set -- "$@" "$rw_f" "$(est_value "$rw_f")"
  done
  "$TOOL" "$@" 2>&1
}

for f in $REQUIRED_EST; do
  if ! est_value "$f" >/dev/null; then
    bad "AC1/FR8 -- no fixture value for the derived flag $f; this guard cannot exercise it"
    continue
  fi
  OUT="$(record_without "$f" || true)"
  RC=0; record_without "$f" >/dev/null 2>&1 || RC=$?
  # The message, not the status: `exits non-zero` is satisfied by a silent refusal, which is the
  # half of this rule a reader cannot act on (`testing-conventions.md`).
  if [ "$RC" -ne 0 ]; then
    ok "record without $f exits non-zero"
  else
    bad "AC1/FR8 -- record without $f exited 0; a figure nobody estimated was appended to the ledger"
  fi
  case "$OUT" in
    *"$f"*) ok "and the refusal names $f" ;;
    *)      bad "AC1/FR8 -- record without $f refused without naming it; got: $(printf '%s' "$OUT" | tr '\n' ' ' | cut -c1-160)" ;;
  esac
  # And nothing was appended. A tool that dies AFTER writing has already committed the fabrication.
  if grep -q '^## sprint ' "$FIX/refuse-ledger.md"; then
    bad "AC1/FR8 -- record without $f appended a sprint block before refusing"
  else
    ok "and appended no sprint block"
  fi
done

# THE EXCEPTION, pinned so it cannot be widened by drift. --estimate-wall omitted is accepted, and
# the figure is LABELLED `no prior` rather than given a number: there is no prior to read, which is
# a different fact from an estimate the caller failed to supply.
echo "AC2/FR8 -- --estimate-wall is the one estimate flag whose omission is a declaration"
OUT="$(record_without --estimate-wall 2>&1 || true)"
RC=0; record_without --estimate-wall >/dev/null 2>&1 || RC=$?
if [ "$RC" -eq 0 ]; then
  ok "record without --estimate-wall is accepted"
else
  bad "AC2/FR8 -- record refused an omitted --estimate-wall; its default is an explicit declaration, not a forged figure. Got: $(printf '%s' "$OUT" | tr '\n' ' ' | cut -c1-160)"
fi
if grep -qE "^\|[[:space:]]*wall_clock_min[[:space:]]*\|[[:space:]]*no prior[[:space:]]*\|" "$FIX/refuse-ledger.md"; then
  ok "and the wall-clock estimate reads 'no prior'"
else
  bad "AC2/FR8 -- an omitted --estimate-wall did not record 'no prior'; got: $(grep -E '^\|[[:space:]]*wall_clock_min' "$FIX/refuse-ledger.md" || echo 'no wall_clock_min row')"
fi

echo "FR2 -- wall-clock is derived from the run log's own UTC timestamps"
# 09:00:00Z to 14:00:00Z is 300 minutes, and nothing else in the repo emits it.
if grep -qE "^\|[[:space:]]*wall_clock_min[[:space:]]*\|[^|]*\|[[:space:]]*300[[:space:]]*\|" "$BLOCK"; then
  ok "the actual wall-clock is 300 minutes, bracketed by the log's first and last event"
else
  bad "FR2 -- wall-clock actual is not 300: $(grep wall_clock_min "$BLOCK" | tr '\n' ' ' | cut -c1-160)"
fi

echo "FR3/AC1 -- the dollar actual is the run's own sessions, not the whole store"
if grep -qE "^\|[[:space:]]*usd[[:space:]]*\|[^|]*\|[[:space:]]*16\.00[[:space:]]*\|" "$BLOCK"; then
  ok "the actual spend is USD 16.00 -- the run's two sessions, not the store's 36.00"
else
  bad "FR3 -- the dollar actual is not 16.00: $(grep '| usd' "$BLOCK" | tr '\n' ' ' | cut -c1-160)"
fi

echo "AC4 -- a multi-ticket develop gate records the predicted cost beside the observed one"
GATELINE="$(grep '^GATE ' "$BLOCK" || true)"
if [ -n "$GATELINE" ]; then
  ok "the block carries a GATE line for the develop gate"
else
  bad "AC4 -- no GATE line; the linear model in config.yml stays unfalsifiable"
fi
case "$GATELINE" in
  *predicted*) ok "and it names a predicted cost" ;;
  *) bad "AC4 -- the GATE line records no prediction: $GATELINE" ;;
esac
case "$GATELINE" in
  *observed*) ok "beside the observed cost" ;;
  *) bad "AC4 -- the GATE line records no observed cost: $GATELINE" ;;
esac
# config.yml's model is base + per_extra x (n-1): 6.05 + 4.03 x 2 = 14.11 for three tickets.
case "$GATELINE" in
  *14.11*) ok "and the prediction is config.yml's model evaluated at three tickets, 14.11" ;;
  *) bad "AC4 -- the prediction is not config.yml's model at n=3 (expected 14.11): $GATELINE" ;;
esac
case "$GATELINE" in
  *10.00*) ok "against the gate session's observed USD 10.00" ;;
  *) bad "AC4 -- the observed gate cost is not the develop session's 10.00: $GATELINE" ;;
esac

echo "FR7 -- verify cost per ticket is recorded for a batched session"
VLINE="$(grep '^RATIO  *verify_usd_per_ticket' "$BLOCK" || true)"
if [ -n "$VLINE" ]; then
  ok "the block carries a verify cost-per-ticket ratio"
else
  bad "FR7 -- no verify_usd_per_ticket ratio; 0132's performance claim stays unmeasured"
fi
case "$VLINE" in
  *batched*) ok "and says whether the session was batched" ;;
  *) bad "FR7 -- the ratio does not distinguish batched from unbatched: $VLINE" ;;
esac
case "$VLINE" in
  *2.00*) ok "USD 6.00 over three tickets is 2.00 each" ;;
  *) bad "FR7 -- the per-ticket figure is not 2.00: $VLINE" ;;
esac

echo "FR5 -- findings parked per sprint, and what the retro consumed against what it produced"
if grep -q '^FINDINGS ' "$BLOCK"; then ok "the block records findings parked"; else bad "FR5 -- no FINDINGS line"; fi
case "$(grep '^FINDINGS ' "$BLOCK" || true)" in
  *" 5"*) ok "and the count is the run's own outcomes summed, 3 plus 2" ;;
  *) bad "FR5 -- findings parked is not 5: $(grep '^FINDINGS ' "$BLOCK" || true)" ;;
esac

echo "AC6/FR8 -- every ratio carries a source and a stamp on BOTH sides"
# Structural, not vocabulary: a RATIO line must be followed by a numerator line and a denominator
# line, each carrying an `@` stamp. The defect this repairs -- a pinned numerator over a live
# denominator -- is invisible to any assertion made on the ratio's own line.
RATIOBAD="$(awk '
  /^RATIO /   { r = $0; n = 0; d = 0; next }
  /^ *numerator /   { if (r != "" && index($0, "@")) n = 1; next }
  /^ *denominator / { if (r != "" && index($0, "@")) d = 1;
                      if (!n || !d) { print r; } ; r = ""; next }
' "$BLOCK" || true)"
NRATIO="$(grep -c '^RATIO ' "$BLOCK" || true)"
if [ "$NRATIO" -ge 1 ]; then
  ok "the block carries at least one ratio to check"
else
  bad "AC6 -- no RATIO line in the block, so the provenance rule has nothing to bind to"
fi
if [ -z "$RATIOBAD" ]; then
  ok "every ratio carries a stamped numerator and a stamped denominator"
else
  bad "AC6 -- a ratio is missing a stamped side: $RATIOBAD"
fi
# And every figure line names a source. Anchored to the absence of a source, not to a vocabulary.
NOSRC="$(grep -E '^(GATE|FINDINGS|RETRO) ' "$BLOCK" | grep -v '@' || true)"
if [ -z "$NOSRC" ]; then
  ok "every derived line carries an as-at stamp"
else
  bad "FR8 -- a derived line carries no stamp: $NOSRC"
fi

echo "AC5/privacy -- the ledger holds aggregates only"
if grep -q 'SENTINELPROSE' "$OUTLEDGER"; then
  bad "AC5 -- message text from the fixture transcript reached the ledger"
else
  ok "the fixture's message text is absent from the ledger"
fi
# Every generated line inside the aggregate character set. Prose fails this long before it says
# anything; the preamble is authored and is excluded by scoping to the block.
BADLINE="$(grep -vn '^[A-Za-z0-9 .,%|:@/_#()=-]*$' "$BLOCK" | head -1 || true)"
if [ -z "$BADLINE" ]; then
  ok "every generated ledger line is within the aggregate-figures character set"
else
  bad "AC5 -- generated ledger line outside the aggregate-figures character set: $BADLINE"
fi

# --- the skill says so where a supervisor reads it ---------------------------------------------
echo "the sprint skill carries the loop, where a supervisor reads it"
if says "$SKILL" "The proposal — what a person confirms before any stage runs" 'LEDGER.md'; then
  ok "the proposal section names the ledger it derives the estimate from"
else
  bad "FR4 -- the proposal section never names the ledger; the estimate cannot improve"
fi
if says "$SKILL" "Step 5 — The run log" 'LEDGER.md'; then
  ok "the run-log section names the ledger as the durable record"
else
  bad "FR1 -- the run log section does not distinguish the deletable log from the durable ledger"
fi
if grep -qF 'tools/sprint-ledger.sh' "$SKILL"; then
  ok "the skill names the tool that writes and reads it"
else
  bad "FR1 -- the skill names no tool; the ledger would be written by hand or not at all"
fi
# Anchored to the ESTIMATE being written first, never to the phrase "before the first dispatch",
# which the proposal section already carries about a different event -- scope_confirmed. That
# looser assertion was green before a line of this ticket was written.
if says "$SKILL" "The proposal — what a person confirms before any stage runs" 'estimate is written to the ledger before the first dispatch'; then
  ok "the estimate is written to the ledger before the first stage runs"
else
  bad "FR1 -- nothing says the estimate is written before the work, which is what makes it an estimate"
fi
if says "$SKILL" "Step 6 — The findings gate, and the end of the run" 'sprint-ledger.sh record'; then
  ok "and the actuals are recorded against it before the run ends"
else
  bad "FR1 -- the run can end without ever scoring its estimate; an unscored estimate never improves"
fi

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
