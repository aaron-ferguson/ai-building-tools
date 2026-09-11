#!/bin/sh
#
# Guard for the sprint skill and the stage outcome schema (0039).
#
# WHY THIS EXISTS:
#
# The supervisor's failure mode is SILENTLY DRIVING THE WRONG THING, and prose cannot be red. Two
# halves of this file answer that in different ways, and neither covers the other.
#
#   the schema, behaviourally    A stage's outcome is the supervisor's ONLY input from it, so a
#                                shape that admits a dropped ticket admits a dropped verdict. The
#                                envelope-over-array cases below are the whole of AC2 and AC3:
#                                three tickets with three different verdicts must survive, and a
#                                SINGULAR object -- the shape a schema written for one ticket
#                                would have -- must be refused rather than read as one ticket.
#
#   the invocation, as prose     Everything else the supervisor does is an instruction to a
#                                session, and the only reachable property of an instruction is
#                                that it is present. These cases are greps, and they are honest
#                                about being greps: they prove the rule is written down, never
#                                that a session obeyed it.
#
# THE ONE CASE THAT IS NEITHER -- AC22's probe. It launches a real `claude -p --json-schema` and
# asserts the fixed object comes back. That is the untested premise under AC1 (can this repo's
# own tooling dispatch a nested session at all), and it is the only case here that exercises the
# REAL validator rather than tools/validate-json-schema.py. It costs about three seconds and a
# fraction of a cent. Where no CLI is present it SKIPS LOUDLY with a named reason and the file
# still exits zero -- a skip that reads as a pass is the failure AC22 exists to catch, arriving
# from inside the guard.
#
# WHAT THE SCHEMA CASES CANNOT SEE. They run against tools/validate-json-schema.py, which
# implements the JSON Schema subset this schema uses and nothing more. A document it accepts is
# not thereby proven to pass the CLI's own validator; the probe is what touches that. The
# mutation cases below are what stop the validator itself from being wired to nothing.
#
# Every fixture is AUTHORED here, never copied from a real outcome or a real backlog
# (testing-conventions.md, the fixture rule).
#
# Usage:  tests/sprint.test.sh
#
# Requires: sh, python3, grep. `claude` optional -- the probe skips loudly without it.

set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

SKILL="$ROOT/skills/sprint/SKILL.md"
SCHEMA="$ROOT/skills/sprint/outcome.schema.json"
VALIDATE="$ROOT/tools/validate-json-schema.py"
README="$ROOT/README.md"
VERIFY="$ROOT/skills/verify/SKILL.md"

PASS=0
FAIL=0
SKIP=0
ok()   { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }
skip() { SKIP=$((SKIP+1)); printf '  SKIP %s\n' "$1"; }

FIX=""
cleanup() { [ -n "$FIX" ] && rm -rf "$FIX"; return 0; }
trap cleanup EXIT INT TERM
FIX="$(mktemp -d)"

# valid <document-file> — 0 when the document satisfies the schema, 1 when it does not.
#
# Exit 2 is the validator's USAGE/UNREADABLE code and is deliberately not folded into either
# answer. Folding it in is how the first run of this file passed: with no schema on disk every
# "is refused" case saw a non-zero exit and read it as a correct refusal, so the whole refusal
# half was green against a schema that did not exist. A harness failure has to be loud in the
# harness's own terms (testing-conventions.md, a helper that establishes a precondition).
valid() {
  python3 "$VALIDATE" "$SCHEMA" "$1" >/dev/null 2>&1
  case $? in
    0) return 0 ;;
    1) return 1 ;;
    *) printf '  HARNESS the validator could not run against %s: %s\n' "$1" "$(why "$1")" >&2
       FAIL=$((FAIL+1))
       return 0 ;;   # never report a harness failure as a refusal
  esac
}

# why <document-file> — the validator's reasons, for a failure message that says what was wrong.
why() { python3 "$VALIDATE" "$SCHEMA" "$1" 2>&1 || true; }

# section <file> <heading-text> — the body under that `## ` heading, up to the next `## `, with
# all whitespace flattened to single spaces.
#
# TWO DEFECTS, ONE HELPER, and the second is why it flattens.
#
# SCOPE. A criterion written about one step of the skill is not satisfied by the phrase appearing
# in some other step. Three cases here asserted with a whole-file grep and so measured something
# NEXT TO the defect they name (the 2026-09-06 QA pass): AC21's `findings-parked count` occurs
# three times, twice in Step 4 describing the schema envelope, so deleting it from the report step -- the
# report step the criterion is written about -- left the suite green. Same for AC16's citation,
# which Step 7 also carries. Extracting the section first is the fix, and AC20's guard below was
# already doing it.
#
# FLATTENING. `grep` is line-based, so an asserted phrase that straddles a line break cannot be
# matched AT ALL, and reflowing a paragraph is then a breaking change to a guard (CLAUDE.md).
# AC20's comment records that arriving as a red against a correct implementation. Flattening the
# section before matching removes the whole class: the assertion is about what the section SAYS,
# and where the words wrap is not part of the criterion.
section() {
  awk -v want="$2" '
    index($0, "## " want) == 1 { inside = 1; next }
    /^## / { inside = 0 }
    inside
  ' "$1" 2>/dev/null | tr '\n' ' ' | tr -s ' '
}

# says <file> <heading-text> <phrase> — 0 when that section states that phrase.
says() { section "$1" "$2" | grep -qF -- "$3"; }

# The same, case-insensitively, for a phrase that may open a sentence or a bolded bullet.
#
# WHY A SECOND HELPER. A presence grep pins one casing, so an assertion written before the prose it
# will match reds a guard whose subject is present and correct — `how many tickets` against a bullet
# opening `**How many tickets**`, which is 0130 AC3 failing on a correct skill
# (testing-conventions.md, the mirror of the absence-grep casing trap). Normalise in the MATCHER,
# never by choosing the prose to suit the guard.
says_ci() { section "$1" "$2" | grep -qiF -- "$3"; }

# ------------------------------------------------------------------------------------------------
echo "AC2 — the schema is a single committed file that parses"

if [ -f "$SCHEMA" ]; then
  ok "skills/sprint/outcome.schema.json exists"
else
  bad "skills/sprint/outcome.schema.json is missing — FR13's single source has no file"
fi

if [ -f "$SCHEMA" ] && python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$SCHEMA" 2>/dev/null; then
  ok "the schema parses as JSON"
else
  bad "the schema does not parse as JSON — the CLI would reject it at dispatch"
fi

# The schema lives in exactly one file. A second copy is the divergence FR13 exists to prevent,
# and it is found by looking for the envelope's own field names outside that file rather than by
# a hand-written list of places to check (testing-conventions.md, a guard that enumerates its
# own subjects cannot notice a new one).
echo "FR13 — the schema shape is written down exactly once"
copies="$(grep -rl '"findings_parked"' "$ROOT/skills" "$ROOT/references" 2>/dev/null || true)"
case "$(printf '%s\n' "$copies" | grep -c .)" in
  0) bad "FR13 — no file declares the envelope at all" ;;
  1) case "$copies" in
       *"skills/sprint/outcome.schema.json") ok "only the schema file declares the envelope" ;;
       *) bad "FR13 — the envelope is declared in $copies, not in the schema file" ;;
     esac ;;
  *) bad "FR13 — the envelope shape is declared in more than one file:
$copies" ;;
esac

# ------------------------------------------------------------------------------------------------
echo "AC2 — a gate of three tickets with three different verdicts validates, and none is dropped"

cat > "$FIX/gate-of-three.json" <<'JSON'
{
  "stage": "develop",
  "session_id": "6f1b0c22-0000-4000-8000-000000000001",
  "commits": ["1111111", "2222222"],
  "cost_usd": 1.42,
  "findings_parked": 2,
  "conventions_resolved": "../ai-building-conventions",
  "escalation": null,
  "tickets": [
    {"id": "0101", "verdict": "built",   "next": "verify",  "status": "ready",   "detail": "items/0101-a.md#notes--decisions"},
    {"id": "0102", "verdict": "blocked", "next": "design",  "status": "ready",   "detail": "items/0102-b.md#open-design-question"},
    {"id": "0103", "verdict": "red",     "next": "develop", "status": "ready",   "detail": "items/0103-c.md#notes--decisions"}
  ]
}
JSON

if valid "$FIX/gate-of-three.json"; then
  ok "an envelope over three differing verdicts validates"
else
  bad "AC2 — a legitimate three-ticket gate was REFUSED: $(why "$FIX/gate-of-three.json")"
fi

# The point of the array is that all three survive. Asserted on the parsed document rather than
# on the schema, so it is a statement about what a supervisor would actually read back.
count="$(python3 -c 'import json,sys; print(len(json.load(open(sys.argv[1]))["tickets"]))' "$FIX/gate-of-three.json" 2>/dev/null || echo 0)"
verdicts="$(python3 -c 'import json,sys; print(",".join(t["verdict"] for t in json.load(open(sys.argv[1]))["tickets"]))' "$FIX/gate-of-three.json" 2>/dev/null || echo "")"
if [ "$count" = 3 ] && [ "$verdicts" = "built,blocked,red" ]; then
  ok "all three tickets and all three verdicts are readable from the envelope"
else
  bad "AC2 — the envelope yielded $count tickets and verdicts [$verdicts]"
fi

echo "AC2/AC3 — a SINGULAR object does not validate"

# The shape a schema written for one ticket would have. It has to be refused rather than read as
# one ticket, because the failure it causes is silent: two of three verdicts vanish.
cat > "$FIX/singular.json" <<'JSON'
{
  "stage": "develop",
  "session_id": "6f1b0c22-0000-4000-8000-000000000002",
  "commits": ["1111111"],
  "cost_usd": 0.51,
  "findings_parked": 0,
  "conventions_resolved": "../ai-building-conventions",
  "escalation": null,
  "id": "0101",
  "verdict": "built",
  "next": "verify",
  "status": "ready",
  "detail": "items/0101-a.md"
}
JSON

if valid "$FIX/singular.json"; then
  bad "AC2/AC3 — a singular object VALIDATED; the schema would silently drop every ticket but one"
else
  ok "a singular object is refused"
fi

echo "AC3 — a stray field is refused, on the envelope and on a ticket entry"

# The singular case above is refused for MISSING `tickets`, not for the twelve fields it carries
# that do not belong — so on its own it says nothing about `additionalProperties`. Mutating that
# keyword to `true` left the whole file green, which is the wired-but-adjacent failure
# `testing-conventions.md` describes. These two cases are the ones that actually reach it: a
# COMPLETE envelope, plus one field that should not be there.
python3 - "$FIX/gate-of-three.json" "$FIX" <<'INNER'
import json, sys
out = sys.argv[2]
doc = json.load(open(sys.argv[1]))
doc["verdict"] = "built"          # a per-ticket field smuggled onto a complete envelope
json.dump(doc, open(f"{out}/stray-envelope-field.json", "w"))
doc = json.load(open(sys.argv[1]))
doc["tickets"][0]["cost_usd"] = 0.5   # an envelope field smuggled onto a complete ticket entry
json.dump(doc, open(f"{out}/stray-ticket-field.json", "w"))
INNER

if valid "$FIX/stray-envelope-field.json"; then
  bad "AC3 — a complete envelope carrying a stray 'verdict' validated; additionalProperties is not pinned"
else
  ok "a stray field on a complete envelope is refused"
fi
if valid "$FIX/stray-ticket-field.json"; then
  bad "AC3 — a complete ticket entry carrying a stray 'cost_usd' validated; additionalProperties is not pinned"
else
  ok "a stray field on a complete ticket entry is refused"
fi

echo "AC3 — a partial object is refused rather than proceeded on"

python3 - "$FIX/gate-of-three.json" "$FIX" <<'PY'
import json, sys
doc = json.load(open(sys.argv[1]))
out = sys.argv[2]
# One file per dropped envelope field, so the failure message names which field went missing.
for field in ("stage", "session_id", "commits", "cost_usd", "findings_parked",
              "conventions_resolved", "escalation", "tickets"):
    partial = {k: v for k, v in doc.items() if k != field}
    json.dump(partial, open(f"{out}/missing-{field}.json", "w"))
# And one per dropped per-ticket field.
for field in ("id", "verdict", "next", "status", "detail"):
    partial = json.loads(json.dumps(doc))
    del partial["tickets"][1][field]
    json.dump(partial, open(f"{out}/ticket-missing-{field}.json", "w"))
PY

for field in stage session_id commits cost_usd findings_parked conventions_resolved escalation tickets; do
  if valid "$FIX/missing-$field.json"; then
    bad "AC3 — an envelope missing '$field' validated; the supervisor would proceed on a partial object"
  else
    ok "an envelope missing '$field' is refused"
  fi
done

for field in id verdict next status detail; do
  if valid "$FIX/ticket-missing-$field.json"; then
    bad "AC3 — a ticket entry missing '$field' validated"
  else
    ok "a ticket entry missing '$field' is refused"
  fi
done

echo "AC3 — a verdict, stage or status outside the vocabulary is refused"

python3 - "$FIX/gate-of-three.json" "$FIX" <<'PY'
import json, sys
doc = json.load(open(sys.argv[1]))
out = sys.argv[2]
for name, mutate in (
    ("stage",  lambda d: d.__setitem__("stage", "sprint")),
    ("verdict", lambda d: d["tickets"][0].__setitem__("verdict", "done-ish")),
    ("next",    lambda d: d["tickets"][0].__setitem__("next", "released")),
    ("status",  lambda d: d["tickets"][0].__setitem__("status", "greenish")),
    ("id",      lambda d: d["tickets"][0].__setitem__("id", "101")),
):
    bad = json.loads(json.dumps(doc))
    mutate(bad)
    json.dump(bad, open(f"{out}/off-vocab-{name}.json", "w"))
PY

for name in stage verdict next status id; do
  if valid "$FIX/off-vocab-$name.json"; then
    bad "AC3 — an out-of-vocabulary '$name' validated; the supervisor would route on a value no stage means"
  else
    ok "an out-of-vocabulary '$name' is refused"
  fi
done

echo "AC2 — a stage that holds no row returns an empty ticket array, not a missing one"

# `retro` handles no ticket. That is a legitimate outcome and has to be expressible, or the one
# stage FR4 ends the run with cannot report at all.
python3 - "$FIX/gate-of-three.json" "$FIX" <<'PY'
import json, sys
doc = json.load(open(sys.argv[1]))
doc["stage"] = "retro"
doc["tickets"] = []
json.dump(doc, open(sys.argv[2] + "/retro-empty.json", "w"))
PY

if valid "$FIX/retro-empty.json"; then
  ok "a retro outcome with an empty ticket array validates"
else
  bad "AC2 — retro cannot report: $(why "$FIX/retro-empty.json")"
fi

echo "AC3 — a negative cost and an empty detail pointer are refused"

# Both keywords are enforced by the CLI's own validator whether or not ours implements them, so a
# schema keyword the offline cases cannot see is a divergence between the two authorities rather
# than a harmless omission. These are what keep the two in step.
python3 - "$FIX/gate-of-three.json" "$FIX" <<'INNER'
import json, sys
out = sys.argv[2]
doc = json.load(open(sys.argv[1]))
doc["cost_usd"] = -1.0
json.dump(doc, open(f"{out}/negative-cost.json", "w"))
doc = json.load(open(sys.argv[1]))
doc["findings_parked"] = -2
json.dump(doc, open(f"{out}/negative-findings.json", "w"))
doc = json.load(open(sys.argv[1]))
doc["tickets"][0]["detail"] = ""
json.dump(doc, open(f"{out}/empty-detail.json", "w"))
INNER

for case in negative-cost negative-findings empty-detail; do
  if valid "$FIX/$case.json"; then
    bad "AC3 — '$case' validated; the schema keyword is not enforced by the offline validator"
  else
    ok "'$case' is refused"
  fi
done

echo "AC3 — an escalation is a string or null, and both are legitimate"

python3 - "$FIX/gate-of-three.json" "$FIX" <<'PY'
import json, sys
out = sys.argv[2]
doc = json.load(open(sys.argv[1]))
doc["escalation"] = "0102 needs a design decision before it can be built"
json.dump(doc, open(f"{out}/escalated.json", "w"))
doc["escalation"] = 17
json.dump(doc, open(f"{out}/escalation-number.json", "w"))
PY

if valid "$FIX/escalated.json"; then
  ok "an escalation string validates"
else
  bad "AC3 — an escalation string was refused: $(why "$FIX/escalated.json")"
fi
if valid "$FIX/escalation-number.json"; then
  bad "AC3 — a numeric escalation validated; the field's type is not pinned"
else
  ok "a numeric escalation is refused"
fi

# ------------------------------------------------------------------------------------------------
# The validator is itself under test. Every case above is evidence about the schema only if the
# validator can actually fail, and a validator that returns 0 unconditionally would print the same
# green as a correct one for every REFUSED case above (testing-conventions.md, prove a new guard
# fails). These feed it a schema and a document whose verdict is not in doubt.
echo "the validator can fail — three controls, no reference to the schema under test"

cat > "$FIX/control.schema.json" <<'JSON'
{"type":"object","additionalProperties":false,"required":["a"],
 "properties":{"a":{"type":"string","enum":["x"]},"b":{"type":"array","minItems":1,"items":{"type":"integer"}}}}
JSON

printf '{"a":"x","b":[1,2]}\n'   > "$FIX/control-good.json"
printf '{"a":"y","b":[1]}\n'     > "$FIX/control-enum.json"
printf '{"b":[1]}\n'             > "$FIX/control-missing.json"
printf '{"a":"x","c":1}\n'       > "$FIX/control-extra.json"

if python3 "$VALIDATE" "$FIX/control.schema.json" "$FIX/control-good.json" >/dev/null 2>&1; then
  ok "the validator accepts a document that satisfies a control schema"
else
  bad "the validator rejects a valid control document — every refusal above is meaningless"
fi
for case in enum missing extra; do
  if python3 "$VALIDATE" "$FIX/control.schema.json" "$FIX/control-$case.json" >/dev/null 2>&1; then
    bad "the validator ACCEPTED the '$case' breach — it is wired to nothing"
  else
    ok "the validator catches the '$case' breach"
  fi
done

# ------------------------------------------------------------------------------------------------
# The invocation. These are greps over prose, and they are honest about it: they prove the rule is
# written down, never that a session obeyed it.

echo "AC1/AC19 — the disqualifying flags appear in no invocation"

# ANCHORED TO THE STATE, NOT THE VOCABULARY. The rule is "--bare is never invoked", and correct
# prose is free to SAY SO -- the skill explains at length why --bare is disqualifying, and a plain
# absence grep reds exactly the file that documents the rule best (testing-conventions.md, a
# negative assertion anchors to a state). So the flags are looked for where an invocation lives:
# inside a fenced code block. The prose is then checked SEPARATELY, and positively.
#
# fenced <file> — the contents of every ``` fenced block in that file, and nothing else.
fenced() {
  awk '/^```/ { infence = !infence; next } infence { print }' "$1" 2>/dev/null || true
}

for flag in -\-bare -\-dangerously-skip-permissions; do
  hits="$(fenced "$SKILL" | grep -F -- "$flag" || true)"
  if [ -z "$hits" ]; then
    ok "no code block in the skill invokes $flag"
  else
    bad "AC1/AC19 — the skill's own invocation carries $flag:
$hits"
  fi
done

echo "AC1/AC19 — and the prose says why, so the rule survives a rewrite of the block"
if grep -q -- '`--bare` is disqualifying' "$SKILL"; then
  ok "the skill states that --bare is disqualifying"
else
  bad "AC1 — the skill no longer says --bare is disqualifying; only the code block would carry it"
fi
if grep -qF -- 'CLAUDE.md auto-discovery' "$SKILL" || grep -qF -- 'no conventions' "$SKILL"; then
  ok "the skill names what --bare actually costs"
else
  bad "AC1 — the skill bans --bare without saying it means no conventions; a rule with no failure named is one nobody argues with"
fi
if grep -q -- '`--dangerously-skip-permissions` appears nowhere' "$SKILL"; then
  ok "the skill states that --dangerously-skip-permissions appears nowhere"
else
  bad "AC19 — the skill does not state the permissions rule"
fi

echo "AC19 — a dispatch is capped and scoped"

# ASSERTED PER DISPATCH BLOCK, for the reason the `< /dev/null` case below records: `fenced`
# concatenates EVERY fenced block before grepping, so a flag present in one invocation satisfies
# the check on another. Measured (2026-09-06 QA pass): deleting `--max-budget-usd` from the Step 3
# dispatch left the suite at 97 passed / 0 failed, because Step 1's probe carries a cap of its
# own. The other four reddened only by the accident of appearing in one block.
#
# WHAT IDENTIFIES A DISPATCH, and why it is not any of the five flags. Anchoring the set on a flag
# under test makes the check vacuous exactly when it should red: delete `--allowed-tools` and the
# block stops being a dispatch, so nothing is left to fail. Identity comes from the PROMPT instead
# -- a dispatch is the invocation whose prompt is a stage's slash command, which is what makes it
# a dispatched stage in AC19's sense. Derived, so a second dispatch block added later is under the
# rule the day it lands.
dispatch_blocks() {
  awk '
    /^```/ { if (infence) { if (body ~ /claude -p/ && body ~ /'"'"'\/(develop|verify|queue|design|prototype|retro)/) print NR
                            infence = 0; body = "" }
             else { infence = 1 } ; next }
    infence { body = body "\n" $0 }
  ' "$1" 2>/dev/null || true
}
# probe_blocks — the Step 1 no-op. Counted only to prove the partition below is exhaustive.
probe_blocks() {
  awk '
    /^```/ { if (infence) { if (body ~ /claude -p/ && body ~ /"probe"/) print NR
                            infence = 0; body = "" }
             else { infence = 1 } ; next }
    infence { body = body "\n" $0 }
  ' "$1" 2>/dev/null || true
}

# claude_blocks — every fenced invocation, the universe the partition below is taken over.
claude_blocks() {
  awk '
    /^```/ { if (infence) { if (body ~ /claude -p/) print NR; infence = 0; body = "" }
             else { infence = 1 } ; next }
    infence { body = body "\n" $0 }
  ' "$1" 2>/dev/null || true
}

n_dispatch="$(dispatch_blocks "$SKILL" | grep -c . || true)"
n_probe="$(probe_blocks "$SKILL" | grep -c . || true)"
n_claude_blocks="$(claude_blocks "$SKILL" | grep -c . || true)"

if [ "$n_dispatch" -ge 1 ]; then
  ok "the skill carries $n_dispatch stage-dispatch invocation(s) for the flag rules to bind to"
else
  bad "AC19 — no stage-dispatch invocation found in the skill; every flag check below would pass vacuously"
fi

# THE PARTITION. Without it, renaming the prompt drops a block out of BOTH sets and the flag loop
# goes quiet rather than red. Every `claude -p` in the file is either the probe or a dispatch;
# an invocation that is neither is an unclassified one escaping the rule, and it is loud.
if [ "$((n_dispatch + n_probe))" = "$n_claude_blocks" ]; then
  ok "every claude -p invocation is classified ($n_dispatch dispatch, $n_probe probe)"
else
  bad "AC19 — $n_claude_blocks claude -p invocations but only $((n_dispatch + n_probe)) classified; one is under no flag rule"
fi

for want in -\-max-budget-usd -\-allowed-tools -\-add-dir -\-session-id -\-setting-sources; do
  missing_flag="$(awk -v want="$want" '
    /^```/ { if (infence) { if (body ~ /claude -p/ && body ~ /'"'"'\/(develop|verify|queue|design|prototype|retro)/ && index(body, want) == 0) print ++n
                            infence = 0; body = "" }
             else { infence = 1 } ; next }
    infence { body = body "\n" $0 }
  ' "$SKILL" | grep -c . || true)"
  if [ "$missing_flag" = 0 ] && [ "$n_dispatch" -ge 1 ]; then
    ok "every dispatch block carries $want"
  else
    bad "AC19/AC1 — $missing_flag of $n_dispatch dispatch block(s) do not carry $want"
  fi
done

echo "AC1 — EVERY invocation redirects stdin, not merely one of them"

# `< /dev/null` is guarded because it is a real defect this ticket hit rather than a tidiness rule:
# without it the nested CLI waits on stdin and then prints "Warning: no stdin data received in 3s"
# INTO the stream the supervisor parses as JSON, so a good stage reads as a schema failure.
#
# IT IS ASSERTED PER BLOCK, and that is the whole point. Written as one more entry in the sweep
# above -- which concatenates every fenced block in the file -- deleting the redirect from the
# DISPATCH left the guard green, because the probe block still carried one. A check that filters
# for a set and then asserts over the set cannot see a member go missing
# (testing-conventions.md). The subjects are DERIVED: every fenced block invoking `claude -p` is
# under the rule, so a third invocation added later is covered the day it lands.
blocks_missing_stdin() {
  awk '
    /^```/ { if (infence) { if (body ~ /claude -p/ && body !~ /< \/dev\/null/) print ++n; infence = 0; body = "" }
             else { infence = 1 } ; next }
    infence { body = body "\n" $0 }
  ' "$1" 2>/dev/null || true
}
n_claude="$(awk '/^```/ { if (infence) { if (body ~ /claude -p/) n++; infence = 0; body = "" } else infence = 1; next } infence { body = body "\n" $0 } END { print n + 0 }' "$SKILL")"
missing="$(blocks_missing_stdin "$SKILL" | grep -c . || true)"

if [ "$n_claude" -ge 2 ]; then
  ok "the skill carries $n_claude claude -p invocations, so a per-block check has something to compare"
else
  bad "AC1 — only $n_claude claude -p invocation found; the per-block check cannot distinguish one from all"
fi
if [ "$missing" = 0 ]; then
  ok "every claude -p invocation redirects stdin"
else
  bad "AC1 — $missing of $n_claude claude -p invocations do not redirect stdin; one of them will parse a warning as JSON"
fi

echo "AC2 — the skill points at the schema file rather than restating the shape"
if grep -qF 'skills/sprint/outcome.schema.json' "$SKILL"; then
  ok "the skill names the schema file"
else
  bad "AC2 — the skill does not name the schema file it dispatches with"
fi

echo "AC8 — the run never pushes, bumps, installs or restarts on its own authority"
if grep -qF 'Ship it' "$SKILL" && grep -qiE 'never (push|bump)' "$SKILL"; then
  ok "the skill states the no-push rule and that an earlier \"ship it\" is not that approval"
else
  bad "AC8 — the skill does not state the no-push rule with its \"ship it\" exclusion"
fi

echo "AC15 — the supervisor claims nothing"
if grep -qE 'never (claims a row|mints)' "$SKILL"; then
  ok "the skill states that it claims no row and mints no token"
else
  bad "AC15 — the skill does not state that it holds no row"
fi

echo "AC6/AC7 — the findings gate fires once, and the run ends at the retro as a checklist"
if grep -qF 'once per run' "$SKILL"; then
  ok "the skill states the gate is evaluated once per run"
else
  bad "AC6 — the skill does not state that the findings gate fires once per run"
fi
if grep -qF 'checklist' "$SKILL" && grep -qF 'marked' "$SKILL"; then
  ok "the release chain is handed over as a checklist with each step marked"
else
  bad "AC7 — the skill does not hand the release chain over as a marked checklist"
fi

echo "AC12 — the supervisor stays answerable and does not poll"
if grep -qiE 'do not poll|never poll' "$SKILL"; then
  ok "the skill forbids polling a running stage"
else
  bad "AC12 — the skill does not forbid polling; a turn spent on no change is the cost driver"
fi

echo "AC27 — the depth report precedes the first dispatch"
# Anchored to ORDER, which is the whole criterion: a depth line printed after the first stage has
# already been launched satisfies every word of the requirement and none of its point. Compared by
# line number, so moving the dispatch above it reds.
depth_line="$(grep -n 'takeable gates deep\|how many takeable gates' "$SKILL" | head -1 | cut -d: -f1)"
dispatch_line="$(grep -n '^## Step 3 — How a stage is dispatched' "$SKILL" | head -1 | cut -d: -f1)"
if [ -n "$depth_line" ] && [ -n "$dispatch_line" ] && [ "$depth_line" -lt "$dispatch_line" ]; then
  ok "the depth report is stated before the dispatch step (line $depth_line before $dispatch_line)"
else
  bad "AC27 — the depth report is not stated before the dispatch step (depth ${depth_line:-absent}, dispatch ${dispatch_line:-absent})"
fi

echo "AC22 — the fallback where no CLI can be dispatched is named"
if grep -qiE 'fall back to naming the commands' "$SKILL"; then
  ok "the skill degrades to naming the commands for a person"
else
  bad "AC22 — the skill does not state the degraded fallback"
fi

echo "Dependencies NFR — the claude CLI is NAMED as a requirement, not merely handled"

# WHY THIS IS AN NFR CASE AND NOT AN AC CASE. The Dependencies row asks for TWO conjuncts:
# "Name it, AND say what the suite does where it is unavailable". AC22 above is the whole of the
# second -- the probe, and the stated fallback. NOTHING covered the first, and no AC does, which
# is how the one binary this suite depends on stayed unnamed through two QA passes that each read
# that row and each scored it (⚠️ on 2026-09-06, ❌ on 2026-09-07). An NFR with no criterion has
# no guard unless one is written against the row itself.
#
# SECTION-ANCHORED, because `claude` is not a rare word in this README: it is in the `/plugin`
# commands, in `~/.claude/` paths, and in the plugin's own lineage. A whole-file grep for it is
# green by construction and would measure something next to the defect rather than the defect
# (testing-conventions.md -- anchor an assertion to the claim, not to the document that contains
# it). Five conjuncts, each one phrase, so each reddens on its own deletion.
req="$(section "$README" "Requirements")"
if [ -n "$req" ]; then
  ok "README has a Requirements section"
else
  bad "Dependencies NFR — README has no Requirements section; nothing tells an installer what the suite needs"
fi
if printf '%s' "$req" | grep -qiE 'claude.{0,2}cli'; then
  ok "the Requirements section names the claude CLI"
else
  bad "Dependencies NFR — README's Requirements section does not name the claude CLI; /sprint's one binary dependency is unnamed"
fi
if printf '%s' "$req" | grep -qF 'PATH'; then
  ok "the Requirements section says the CLI has to be on PATH"
else
  bad "Dependencies NFR — README does not say the claude CLI must be on PATH; 'requires the CLI' is not an installable statement"
fi
if printf '%s' "$req" | grep -qF 'sprint'; then
  ok "the requirement is attributed to /sprint, not to the whole suite"
else
  bad "Dependencies NFR — README's Requirements section does not say which skill needs the CLI, so it reads as a requirement of all seven"
fi
if printf '%s' "$req" | grep -qiF 'hand-driven'; then
  ok "the Requirements section states what happens where the CLI is unavailable"
else
  bad "Dependencies NFR — README names the dependency without saying what the suite does without it; the row asks for both conjuncts"
fi

echo "AC24 — README describes the supervised loop alongside the hand-driven one"
sec="$(awk '/^## One skill per session/ { inside = 1; next } /^## / { inside = 0 } inside' "$README")"
if printf '%s' "$sec" | grep -qF 'sprint'; then
  ok "README's One skill per session names the sprint loop"
else
  bad "AC24 — README's One skill per session does not mention the supervised loop; it still implies a person types every command"
fi

echo "AC20 — verify writes its evidence table into the item file"

# Anchored to the MECHANISM -- the named destination section and the instruction to write there --
# rather than to a sentence. The first version of this case matched "evidence table" and "item
# file" on one line, and reddened a correct implementation whose sentence wrapped between them:
# grep is line-based, so a phrase that straddles a break cannot be matched at all (CLAUDE.md).
if grep -qF 'into the item file' "$VERIFY"; then
  ok "verify is instructed to write the table into the item file"
else
  bad "AC20 — verify still writes the evidence table only to the screen; a closed ticket keeps no QA record"
fi
if grep -qF '## QA evidence' "$VERIFY"; then
  ok "verify names the section the table goes in"
else
  bad "AC20 — verify names no destination section, so every pass invents its own"
fi
# The ordering half. Written after ./close, the table needs a second commit on a released row.
if grep -qE 'before Step 5 closes|before .*close.* or hands off' "$VERIFY"; then
  ok "verify writes the table BEFORE the close, while it still holds the claim"
else
  bad "AC20 — verify does not say the table is written before the close; after it, the row is takeable"
fi
if grep -qF '## QA evidence' "$ROOT/skills/queue/templates/item.md"; then
  ok "the item template carries the QA evidence section, so a new ticket has somewhere to put it"
else
  bad "AC20 — templates/item.md has no QA evidence section"
fi

# ------------------------------------------------------------------------------------------------
echo "AC18 — a second supervisor refuses, and a stale marker is takeable"

# The marker is a DIRECTORY because mkdir is atomic on POSIX -- the same reasoning the backlog lock
# uses. This case proves the mechanism the skill names is actually exclusive; it cannot prove a
# session obeyed it, which is why the prose is checked too.
RUNS="$FIX/runs"
mkdir -p "$RUNS"
if mkdir "$RUNS/.active" 2>/dev/null; then
  ok "the first supervisor takes the marker"
else
  bad "AC18 — the first mkdir of a fresh marker failed"
fi
if mkdir "$RUNS/.active" 2>/dev/null; then
  bad "AC18 — a SECOND supervisor took the same marker; the run is double-driven"
else
  ok "a second supervisor is refused by the same mkdir"
fi
rm -rf "$RUNS/.active"
if mkdir "$RUNS/.active" 2>/dev/null; then
  ok "a released marker is takeable again"
else
  bad "AC18 — a released marker could not be retaken"
fi

if grep -qF 'mkdir .claude/backlog/runs/.active' "$SKILL"; then
  ok "the skill names the atomic marker it takes"
else
  bad "AC18/FR12 — the skill does not name the single-instance marker"
fi

# The marker's PARENT has to exist first, and this is not pedantry. On a backlog that has never
# been driven there is no runs/ directory, so `mkdir …/runs/.active` fails on the missing parent
# and `|| echo busy` reports that ANOTHER SUPERVISOR HOLDS THE RUN — the wrong diagnosis, on the
# first run, with no second supervisor anywhere. The rule is that a busy marker and an absent
# parent are distinguishable, and the fixture is a backlog with neither.
echo "AC18 — an absent runs/ directory is not reported as a busy marker"
FRESH="$FIX/fresh/.claude/backlog"
mkdir -p "$FRESH"
if mkdir "$FRESH/runs/.active" 2>/dev/null; then
  bad "AC18 — the fixture is wrong: mkdir succeeded with no parent, so this case proves nothing"
else
  ok "a bare mkdir of the marker does fail when runs/ is absent (the case can fire)"
fi
mkdir -p "$FRESH/runs"
if mkdir "$FRESH/runs/.active" 2>/dev/null; then
  ok "with runs/ created first, the marker is taken"
else
  bad "AC18 — the marker could not be taken even with its parent present"
fi
if grep -qF 'mkdir -p .claude/backlog/runs' "$SKILL"; then
  ok "the skill creates runs/ before reaching for the marker"
else
  bad "AC18 — the skill takes the marker without creating runs/ first; on a fresh backlog the first supervisor is told the run is busy"
fi
if grep -qiE 'pid is no longer alive|stale' "$SKILL"; then
  ok "the skill says what a stale marker is and that it may be taken over"
else
  bad "AC18 — a crashed supervisor's marker would block every later run with no way named to clear it"
fi

# ------------------------------------------------------------------------------------------------
echo "AC16 — a killed supervisor leaves a backlog a hand-driven session can pick up"

# Built as a real backlog and driven through the real ./next, because the criterion is about what a
# hand-driven session is OFFERED, and only the script can answer that.
BL="$FIX/bl/.claude/backlog"
mkdir -p "$BL/items"
cp "$ROOT/.claude/backlog/next" "$BL/next" 2>/dev/null || true
cat > "$BL/config.yml" <<'CFG'
project: fixture
conventions:
  path: ../conventions
next_id: 3
findings_threshold: 8
routing:
  default: local
  company: none
CFG
: > "$BL/FINDINGS.md"
cat > "$BL/QUEUE.md" <<'Q'
| ID | Title | Next | Status | Parent |
|------|-------|------|--------|--------|
| 0001 | A ticket a killed stage was holding | develop | in-progress |  |
| 0002 | A ticket nobody holds | develop | ready |  |
Q
cat > "$BL/items/0001-held.md" <<'IT'
---
id: "0001"
title: A ticket a killed stage was holding
next: develop
status: in-progress
qa_level: unit
size: s
blocked_by: []
relates: []
expects:
  - src/a.ts
claimed_by: dead
claimed_at: 2026-09-06T00:00:00Z
touches:
  - src/a.ts
---
## Problem
Held by a session that is gone.
IT
cat > "$BL/items/0002-free.md" <<'IT'
---
id: "0002"
title: A ticket nobody holds
next: develop
status: ready
qa_level: unit
size: s
blocked_by: []
relates: []
expects:
  - src/b.ts
claimed_by:
claimed_at:
touches:
---
## Problem
Takeable.
IT

if [ -x "$BL/next" ]; then
  out="$(cd "$FIX/bl" && .claude/backlog/next --drift 2>&1)"; code=$?
  if [ "$code" = 0 ]; then
    ok "./next --drift exits zero over a killed supervisor's backlog"
  else
    bad "AC16 — ./next --drift exited $code: $out"
  fi

  out="$(cd "$FIX/bl" && .claude/backlog/next develop 2>&1 || true)"
  case "$out" in
    *0002*) ok "a hand-driven session is offered the free row (0002), not the held one" ;;
    *)      bad "AC16 — ./next develop did not offer the free row: $out" ;;
  esac
  case "$out" in
    "TAKE      0001"*) bad "AC16 — the orphaned claim on 0001 was offered as takeable" ;;
    *) ok "the orphaned claim on 0001 is not offered" ;;
  esac
else
  skip "AC16 — .claude/backlog/next is not installed in this checkout, so the fixture cannot be driven"
fi

# SCOPED TO STEP 5, and anchored to the RULE rather than to the citation. Asserted as a whole-file
# grep for `Claim tokens` it could not fail on the defect it names: Step 7 cites the same rule for
# an unrelated reason, so deleting Step 5's "never a row to take over" -- the sentence that IS the
# criterion -- left the suite green (2026-09-06 QA pass). The falsifiable half is what the
# supervisor is told to DO with the claim, which is nothing.
if says "$SKILL" "Step 5" 'never a row to take over'; then
  ok "Step 5 says an orphaned claim is reported, never taken over"
else
  bad "AC16 — Step 5 does not say what to do with a claim a killed stage left behind; a supervisor that adopts it holds a row it is not working"
fi
if says "$SKILL" "Step 5" 'Claim tokens'; then
  ok "Step 5 routes it to CONCURRENCY.md's ownership rule"
else
  bad "AC16 — Step 5 states the rule without citing where ownership is defined"
fi

# ------------------------------------------------------------------------------------------------
# AC22 — the probe, and the only case here that touches the REAL validator.
echo "AC22 — a real nested dispatch returns the fixed object"

if ! command -v claude >/dev/null 2>&1; then
  skip "AC22 — no \`claude\` on PATH; the nested-dispatch premise under AC1 is UNVERIFIED in this run"
elif [ -n "${SPRINT_SKIP_PROBE:-}" ]; then
  skip "AC22 — SPRINT_SKIP_PROBE is set; the nested-dispatch premise under AC1 is UNVERIFIED in this run"
else
  probe_schema='{"type":"object","properties":{"probe":{"type":"string"}},"required":["probe"],"additionalProperties":false}'
  # `< /dev/null` is not tidiness. Without it the nested CLI waits on stdin and then prints
  # "Warning: no stdin data received in 3s" INTO the output being parsed, so a supervisor reading
  # stdout as JSON gets a warning line first and concludes the stage failed the schema.
  got="$(claude -p --json-schema "$probe_schema" --max-budget-usd 0.25 \
          'Return the object with probe set to the string ok. Nothing else.' \
          < /dev/null 2>/dev/null || true)"
  case "$got" in
    '{"probe":"ok"}')
      ok "a nested claude -p returned exactly the fixed object" ;;
    *)
      bad "AC22 — the probe did not return the fixed object; a supervisor on this host would drive nothing. Got: $got" ;;
  esac
fi

# ------------------------------------------------------------------------------------------------
# AC13 — the bound is measured as three figures, not as a ratio.
#
# WHY NOT A RATIO. Supervisor spend over stage spend cannot go red: a longer run improves it while
# the supervisor gets steadily worse, so the one number that looks like a bound is the one number
# that never reports one. Floor, growth and turns-per-cycle each can.
#
# The fixture is GENERATED with known counts rather than read from the live transcript store: the
# store grows, and a guard that reads it goes red for reasons that have nothing to do with the code
# (testing-conventions.md). Context climbs 20000 -> 24500 in steps of 900 over six turns, across
# THREE dispatches of which only two returned an outcome. So the floor is 20000, the growth is
# (24500-20000)/3 = 1500 per cycle, and turns per cycle is 6/3 = 2.0.
#
# THE UNEQUAL DISPATCH AND OUTCOME COUNTS ARE THE POINT. The first version of this fixture had two
# of each, so a script counting outcomes instead of dispatches produced identical numbers and the
# mutation came back green -- a fixture that cannot tell the two apart, guarding the one line that
# chooses between them. Counting outcomes here yields 2250 and 3.0 instead, and both cases red. It
# is also the honest shape: a run killed with a stage in flight is exactly the run whose figures
# matter most, and it never has equal counts.
echo "AC13 — harvest-usage reports floor, growth and turns per cycle over a run log"

HARVEST="$ROOT/tools/harvest-usage.sh"
RUNDIR="$FIX/harvest"
mkdir -p "$RUNDIR/transcripts"

python3 - "$RUNDIR" <<'INNER'
import json, sys
root = sys.argv[1]
lines = []
lines.append({"type": "user", "message": {"content": "<command-name>/sprint</command-name>"}})
for i, ctx in enumerate((20000, 20900, 21800, 22700, 23600, 24500)):
    lines.append({
        "type": "assistant",
        "message": {
            "id": f"msg_{i}",
            "model": "claude-opus-5",
            "usage": {"input_tokens": ctx, "cache_read_input_tokens": 0,
                      "cache_creation_input_tokens": 0, "output_tokens": 100},
        },
        "timestamp": f"2026-09-06T0{i}:00:00Z",
    })
with open(f"{root}/transcripts/run.jsonl", "w") as fh:
    for line in lines:
        fh.write(json.dumps(line) + "\n")

events = [
    {"event": "run_started",  "run_id": "r1", "at": "2026-09-06T00:00:00Z"},
    {"event": "dispatch", "run_id": "r1", "stage": "develop", "at": "2026-09-06T00:01:00Z"},
    {"event": "outcome",  "run_id": "r1", "stage": "develop", "at": "2026-09-06T01:00:00Z"},
    {"event": "dispatch", "run_id": "r1", "stage": "verify",  "at": "2026-09-06T02:00:00Z"},
    {"event": "outcome",  "run_id": "r1", "stage": "verify",  "at": "2026-09-06T03:00:00Z"},
    {"event": "dispatch", "run_id": "r1", "stage": "develop", "at": "2026-09-06T04:00:00Z"},
]
with open(f"{root}/run.jsonl", "w") as fh:
    for e in events:
        fh.write(json.dumps(e) + "\n")
INNER

out="$("$HARVEST" "$RUNDIR/transcripts" --run "$RUNDIR/run.jsonl" 2>&1 || true)"

case "$out" in
  *"FLOOR"*20000*) ok "the floor is the FIRST turn's context (20000), not the last or the largest" ;;
  *) bad "AC13 — no FLOOR of 20000 in the output:
$out" ;;
esac
case "$out" in
  *"GROWTH"*1500*) ok "growth is reported as an absolute figure per cycle (1500)" ;;
  *) bad "AC13 — no GROWTH of 1500 per cycle in the output:
$out" ;;
esac
case "$out" in
  *"TURNS"*2.0*) ok "turns per cycle is reported (2.0 over 3 cycles)" ;;
  *) bad "AC13 — no TURNS per cycle of 2.0 in the output:
$out" ;;
esac
case "$out" in
  *"budget"*) ok "turns per cycle is reported against a budget" ;;
  *) bad "AC13 — turns per cycle is reported with nothing to judge it against" ;;
esac

# The floor case above separates a script reading the FIRST turn from one reading the last only
# because the fixture climbs. Assert that it does, or the case proves nothing (testing-conventions.md,
# a throwaway probe needs its own premise asserted).
first="$(python3 -c 'import json,sys
ctxs=[json.loads(l)["message"]["usage"]["input_tokens"] for l in open(sys.argv[1]) if json.loads(l)["type"]=="assistant"]
print(ctxs[0], ctxs[-1])' "$RUNDIR/transcripts/run.jsonl")"
if [ "$first" = "20000 24500" ]; then
  ok "the fixture climbs, so first and last are distinguishable"
else
  bad "AC13 — the fixture does not climb ($first); the FLOOR case cannot fail"
fi

# The second premise, and the one the first version of this fixture failed silently.
disp="$(grep -c '"event": "dispatch"' "$RUNDIR/run.jsonl" || true)"
outc="$(grep -c '"event": "outcome"' "$RUNDIR/run.jsonl" || true)"
if [ "$disp" != "$outc" ]; then
  ok "the fixture records $disp dispatches against $outc outcomes, so the two are distinguishable"
else
  bad "AC13 — the fixture has $disp of each; a script counting outcomes instead of dispatches cannot be caught"
fi

echo "AC13/FR7 — the script's default budget and the skill's stated budget agree"
# Derived from both files rather than restated here: two places carrying the same number silently
# diverge, and the guard that restates it a third time is the one that hides the divergence.
skill_budget="$(grep -oE 'budget of ([a-z]+) turns per cycle' "$SKILL" | head -1 | awk '{print $3}')"
tool_budget="$(grep -oE 'DEFAULT_TURN_BUDGET = [0-9]+' "$HARVEST" | head -1 | awk '{print $3}')"
case "$skill_budget" in
  three) skill_n=3 ;; two) skill_n=2 ;; four) skill_n=4 ;; five) skill_n=5 ;; *) skill_n="" ;;
esac
if [ -n "$skill_n" ] && [ "$skill_n" = "$tool_budget" ]; then
  ok "the skill states $skill_budget turns per cycle and the tool defaults to $tool_budget"
else
  bad "AC13/FR7 — the skill states '${skill_budget:-nothing}' and the tool defaults to '${tool_budget:-nothing}'; they must be the same number"
fi

echo "AC4/AC5 — the dispatch unit is a gate, and verify is a separate process"

if grep -qF 'dispatch unit is a gate' "$SKILL"; then
  ok "the skill states the dispatch unit is a gate rather than a row"
else
  bad "AC4 — the skill does not state that a gate is the dispatch unit; one session per row regresses the saving"
fi
if grep -qiE 'must not self-certify|not self-certify' "$SKILL"; then
  ok "the skill states that a stage must not self-certify, which is why verify is a new process"
else
  bad "AC5 — the skill does not say why verify is dispatched rather than judged here"
fi
if grep -qE 'verifies nothing|runs no test' "$SKILL"; then
  ok "the skill states that the supervisor itself verifies nothing"
else
  bad "AC5 — the skill does not state that the supervisor runs no test and writes no verdict"
fi

echo "AC14 — cost per closed ticket, with the supervisor's own spend in the numerator"
# Case-insensitive: the phrase opens a bullet, and a presence grep that pins one casing reds a
# subject that is present and correct (testing-conventions.md).
if grep -qiF 'cost per closed ticket' "$SKILL"; then
  ok "the skill reports cost per closed ticket rather than total spend"
else
  bad "AC14 — the skill does not name cost per closed ticket; total spend is a figure a longer run always wins"
fi
if grep -qF 'attributes to no ticket' "$SKILL"; then
  ok "the skill states that the supervisor's own spend attributes to no ticket and must be added in"
else
  bad "AC14 — the skill does not say the supervisor's spend is unattributed; a sum over the stages silently omits it"
fi
# The figures a skill quotes about MEASUREMENT.md are a cache of that file, and this pair has gone
# stale once already (0036, 0040 and 0041 still hold the pre-2026-08-30 numbers). The guard reads
# both files and compares, so the next time the denominator moves this reds instead of drifting.
recorded="$(grep -oE '\*\*USD [0-9]+\.[0-9]+\*\*' "$SKILL" | grep -oE '[0-9]+\.[0-9]+' | tr '\n' ' ' | sed 's/ $//')"
source_figs="$(grep -oE 'is \*\*\$[0-9]+\.[0-9]+ per closed ticket\*\*' "$ROOT/MEASUREMENT.md" | grep -oE '[0-9]+\.[0-9]+' | tr '\n' ' ' | sed 's/ $//')"
if [ -n "$recorded" ] && [ "$recorded" = "$source_figs" ]; then
  ok "the skill's quoted figures ($recorded) match MEASUREMENT.md's"
else
  bad "AC14 — the skill quotes [${recorded:-nothing}] where MEASUREMENT.md records [${source_figs:-nothing}]; a quoted figure is a cache and this one has gone stale before"
fi
if grep -qF 'recompute both from `MEASUREMENT.md`' "$SKILL"; then
  ok "the skill tells the reader to recompute rather than quote"
else
  bad "AC14 — the skill quotes figures without saying they are a cache to be recomputed"
fi

echo "AC17 — a resuming supervisor derives its position and does not restore it"
if grep -qF 'It is not state' "$SKILL"; then
  ok "the skill states the log is provenance rather than state"
else
  bad "AC17 — the skill does not say the log is not state; a resuming session would restore from it"
fi
if grep -qF 'Delete the log between two sessions' "$SKILL"; then
  ok "the skill states that deleting the log does not change the next action"
else
  bad "AC17 — the skill does not state the falsifiable half: that the log is not consulted for what to do next"
fi
if grep -qF 'exactly three things' "$SKILL"; then
  ok "the skill enumerates the three things the log IS read for"
else
  bad "AC17 — the skill does not bound what the log is read for"
fi
# 0133 narrowed that bound rather than leaving it false: `findings_max_sprints` counts
# `sprint_ended` events across every run, so the run HISTORY is an input to the findings gate even
# though the supervisor still places itself without reading a log. An unnamed exception is the
# worse artifact — the sentence above reads correctly on its own while a reader acts on it.
if grep -qF 'One fact crosses runs' "$SKILL" && grep -qF 'findings_max_sprints' "$SKILL"; then
  ok "AC17 — and names the one cross-run exception to it"
else
  bad "AC17 — the log's cross-run reader is unnamed, so \"delete the log and nothing changes\" reads as true where it is not"
fi

echo "AC21 — the report carries what the run learned"

# SCOPED TO STEP 8, the report step the criterion is written about. The phrase occurs three times
# in this skill and two of them are Step 4 describing the schema envelope -- so the whole-file
# grep this replaces stayed green with the count deleted from the report itself (2026-09-06 QA
# pass). AC21 is the only guard on FR6's "the run surfaces what it learned", and FR13 removed the
# narrative that would otherwise have carried it, so measuring the wrong section leaves the loop
# free to run smoothly and teach nobody anything.
if says "$SKILL" "Step 9" 'findings-parked count'; then
  ok "the report carries the findings-parked count"
else
  bad "AC21 — Step 9's report carries no findings-parked count; nothing shows the run is learning anything"
fi

echo "AC23 — the plugin still declares its skill set, and this one is in it"
for f in .claude-plugin/plugin.json .claude-plugin/marketplace.json; do
  if python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$ROOT/$f" 2>/dev/null; then
    ok "$f parses"
  else
    bad "AC23 — $f no longer parses; the plugin would not load at all"
  fi
  if grep -qF 'sprint' "$ROOT/$f"; then
    ok "$f names the sprint skill"
  else
    bad "AC24 — $f does not name the sprint skill"
  fi
done
sec="$(awk '/^\| Skill \| Does \| Phase \|/ { inside = 1 } inside && /^\|/ { print } inside && !/^\|/ { inside = 0 }' "$README")"
if printf '%s' "$sec" | grep -qF '/sprint'; then
  ok "README's skill table lists /sprint"
else
  bad "AC24 — README's skill table does not list /sprint"
fi

# ------------------------------------------------------------------------------------------------
# 0040 — FR15/FR16, the two ways an unattended loop strands the whole repository.
#
# BOTH CRITERIA ARE ABOUT STATE ON DISK THE SUPERVISOR READS AND REFUSES TO CHANGE, which is why
# these are not all greps. A `.lock/` directory with a given age, and a config key with or without
# its derivation, are constructible — so the age mechanism and the derivation rule are exercised
# for real, and only the instructions to a session stay prose.
#
# WHY THE AGE MECHANISM IS RUN RATHER THAN READ. `claim` writes `claim <id> by <token>` into
# `.lock/held-by` with NO TIMESTAMP, where `close` and `handoff` both write one — so a lock age
# taken from `held-by` is unavailable on exactly the path that holds the lock most often, and a
# skill prescribing it would read as correct and work in testing against a close-held lock. The
# guard extracts the block the skill actually prescribes and runs it against an aged fixture and a
# fresh one; prescribing the `held-by` read instead reds on the aged fixture.

echo "AC25 — the supervisor never takes or breaks the lock"

LOCKSTEP="Step 7"

if says "$SKILL" "$LOCKSTEP" 'never takes it and never breaks it'; then
  ok "the skill states the supervisor neither takes nor breaks the lock"
else
  bad "AC25 — $LOCKSTEP does not state the lock policy; the tempting answer is to break it and carry on"
fi

# NO DISPATCHABLE PATH REMOVES THE LOCK.
#
# Anchored to STATE, not to vocabulary: correct prose is free to NAME `rm -rf .claude/backlog/.lock`
# in the sentence forbidding it, and an absence grep over the whole file would red that correct
# file (testing-conventions.md, a negative assertion anchors to a state). The reachable state in an
# instruction file is its FENCED BLOCKS — the only text a session copies and runs — so the check
# extracts those and asserts none of them removes the lock.
#
# Derived over every file in skills/sprint/ rather than over a named list, so a second file
# added to that directory is under the check the day it lands (testing-conventions.md, a guard that
# enumerates its own subjects cannot notice a new one).
fenced() {
  awk '/^```/ { inside = !inside; next } inside' "$1"
}
removers=""
for f in "$ROOT"/skills/sprint/*; do
  [ -f "$f" ] || continue
  hit="$(fenced "$f" | grep -nE '(rm|rmdir|unlink)[^|]*\.lock' || true)"
  [ -n "$hit" ] && removers="$removers $(basename "$f"):$hit"
done
if [ -z "$removers" ]; then
  ok "no fenced block in skills/sprint/ removes the lock"
else
  bad "AC25 — a dispatchable path removes the lock:$removers — a driver stealing a lock from a stage that is still working"
fi

# THE AGE MECHANISM, RUN. The skill prescribes one block; the guard finds it by the config key it
# must read, writes it out, and runs it in two authored backlogs. Nothing here is reimplemented —
# a helper that parses the lock the way the skill parses it would pass and fail with it
# (testing-conventions.md, a helper that reimplements the logic under test).
# ONE block, not the union of them. `fenced` concatenates every block in the file with nothing
# between — it drops the fence lines, so two adjacent blocks abut and no separator survives to split
# them on. Extracting "the block containing the token" has to be done at the fence.
agecheck="$FIX/agecheck.sh"
awk -v tok='lock_stale_seconds' '
  /^```/ {
    if (inside) { if (hit) { for (i = 0; i < n; i++) print buf[i]; exit } ; n = 0; hit = 0 }
    inside = !inside; next
  }
  inside { buf[n++] = $0; if (index($0, tok)) hit = 1 }
' "$SKILL" > "$agecheck" 2>/dev/null || true

mkbacklog() {   # mkbacklog <dir> <stale-seconds>
  mkdir -p "$1/.claude/backlog"
  printf 'project: fixture\nlock_stale_seconds: %s\n' "$2" > "$1/.claude/backlog/config.yml"
}

if [ -s "$agecheck" ] && grep -q 'lock_stale_seconds' "$agecheck"; then
  ok "the skill prescribes a runnable lock-age check that reads lock_stale_seconds"

  AGED="$FIX/aged"; mkbacklog "$AGED" 900
  mkdir -p "$AGED/.claude/backlog/.lock"
  # `claim`'s held-by, verbatim in shape: an id and a token, and NO timestamp. A mechanism reading
  # a date out of this file has nothing to read, which is the defect this fixture exists to catch.
  printf 'claim 0001 by ab12\n' > "$AGED/.claude/backlog/.lock/held-by"
  touch -t 202601010000 "$AGED/.claude/backlog/.lock"
  out="$( cd "$AGED" && sh "$agecheck" 2>&1 || true )"
  if printf '%s' "$out" | grep -qi 'aged'; then
    ok "an aged lock is classified aged from the directory itself, with no timestamp in held-by"
  else
    bad "AC25 — the prescribed check did not call a lock from 2026-01-01 aged; it printed [$out]"
  fi

  FRESH="$FIX/fresh"; mkbacklog "$FRESH" 900
  mkdir -p "$FRESH/.claude/backlog/.lock"
  printf 'claim 0002 by cd34\n' > "$FRESH/.claude/backlog/.lock/held-by"
  out="$( cd "$FRESH" && sh "$agecheck" 2>&1 || true )"
  if printf '%s' "$out" | grep -qi 'fresh'; then
    ok "a lock taken a moment ago is classified fresh — the normal case, held for seconds"
  else
    bad "AC25 — the prescribed check did not call a just-taken lock fresh; it printed [$out]"
  fi

  NOLOCK="$FIX/nolock"; mkbacklog "$NOLOCK" 900
  out="$( cd "$NOLOCK" && sh "$agecheck" 2>&1 || true )"
  if [ -z "$out" ]; then
    ok "no lock at all decides nothing and says nothing"
  else
    bad "AC25 — the prescribed check spoke about a lock that does not exist: [$out]"
  fi
else
  bad "AC25 — the skill prescribes no runnable lock-age check naming lock_stale_seconds; the age is then a session's guess"
  bad "AC25 — an aged lock is unclassifiable without that check"
  bad "AC25 — a fresh lock is unclassifiable without that check"
  bad "AC25 — an absent lock is unclassifiable without that check"
fi

# The two branches, separately. An alternation is only as strong as its weakest branch, and here
# the wrong branch is the expensive one: escalating a lock held for two seconds stops a healthy run.
if says "$SKILL" "$LOCKSTEP" 'dispatches nothing'; then
  ok "an aged lock stops dispatch"
else
  bad "AC25 — $LOCKSTEP does not say an aged lock dispatches nothing"
fi
if says "$SKILL" "$LOCKSTEP" 'waits rather than escalating'; then
  ok "a lock younger than the configured age is waited on, not escalated"
else
  bad "AC25 — $LOCKSTEP does not say a young lock is waited on; a lock in use is the normal case"
fi
if says "$SKILL" "$LOCKSTEP" 'run log'; then
  ok "the escalation names the process that should have held it, from the run log"
else
  bad "AC25 — the escalation does not join the lock to the run log; the holder is then unnameable"
fi

if awk '/^lock_stale_seconds:/ { print $2 }' "$ROOT/.claude/backlog/config.yml" | grep -qE '^[0-9]+$'; then
  ok "config.yml carries lock_stale_seconds as a whole number"
else
  bad "AC25 — config.yml has no lock_stale_seconds; the age is a number inside a skill, which is the one place FR15 says it must not be"
fi
if awk '/^lock_stale_seconds:/ { print }' "$ROOT/skills/queue/templates/config.yml" | grep -q .; then
  ok "the queue template ships lock_stale_seconds, so a new backlog has the key"
else
  bad "AC25 — skills/queue/templates/config.yml omits lock_stale_seconds; every new project's driver has no age to read"
fi

# ------------------------------------------------------------------------------------------------
echo "AC26 — a stage killed by its spend cap leaves a state the escalation describes"

# Three separate assertions rather than one alternation: a human following the escalation needs all
# three, and an alternation stays green on whichever branch survives (testing-conventions.md).
# The definite article is load-bearing. `a claim token` occurs in the step listing what the
# supervisor never does, so the bare phrase was green there before this criterion had a section at
# all — a guard measuring something next to the defect it names (testing-conventions.md).
for phrase in 'the claim token' 'the dirty paths' 'the lock state'; do
  if says "$SKILL" "$LOCKSTEP" "$phrase"; then
    ok "the escalation names $phrase"
  else
    bad "AC26 — the escalation does not name $phrase; recovering it needs the dead stage's transcript"
  fi
done
if says "$SKILL" "$LOCKSTEP" 'not read as a crash'; then
  ok "an over-budget exit is routed as an escalation rather than read as a crash"
else
  bad "AC26 — the skill does not route the over-budget exit; the cap's own kill reads as a broken CLI"
fi
if says "$SKILL" "$LOCKSTEP" 'starts nothing further'; then
  ok "the supervisor starts nothing further after a budget kill"
else
  bad "AC26 — the skill does not stop the run after a budget kill; the next stage inherits a held claim and a dirty tree"
fi

# THE DERIVATION, CROSS-READ AGAINST ITS SOURCE.
#
# A bare number is what this rejects: the block of comments directly above the key must carry the
# per-session figures it was derived from, and those figures are read out of MEASUREMENT.md rather
# than restated here — so the day that table moves, this reds instead of drifting. The same shape
# as AC14's guard above, and for the same reason: a figure a file quotes about another file is a
# cache (develop Step 2).
derivation() {
  awk '
    /^stage_budget_usd:/ { print buf; exit }
    /^#/                 { buf = buf " " $0; next }
                         { buf = "" }
  ' "$1" | tr -s ' '
}

CFG="$ROOT/.claude/backlog/config.yml"
if grep -q '^stage_budget_usd:' "$CFG"; then
  ok "config.yml carries the per-stage spend cap"
else
  bad "AC26 — config.yml carries no stage_budget_usd; the cap stays a guess inside a skill"
fi

why_derived="$(derivation "$CFG")"
missing=""
for stage in develop verify retro; do
  # SELECTED BY ITS HEADER, and the column INDEX is read from that header rather than written here.
  # A field count is not a selector: MEASUREMENT.md holds three per-stage tables and two of them
  # are eight pipe-fields wide, so `NF == 8` first returned the context-token table's 74,970 as
  # though it were a dollar figure — a guard reading the wrong table, with every figure resolving.
  # Deriving the index means adding a column to that table cannot silently move what is read.
  fig="$(awk -F'|' -v s=" $stage " '
    /\$\/session/ { for (i = 1; i <= NF; i++) if ($i ~ /\$\/session/) col = i; intable = 1; next }
    !/^\|/         { intable = 0 }
    intable && col && $2 == s { gsub(/[ *]/, "", $col); print $col; exit }
  ' "$ROOT/MEASUREMENT.md")"
  if [ -z "$fig" ]; then
    bad "HARNESS — MEASUREMENT.md's per-stage \$/session table has no row for $stage"
  elif printf '%s' "$why_derived" | grep -qF -- "$fig"; then
    ok "the cap's derivation cites MEASUREMENT.md's $stage figure of USD $fig per session"
  else
    missing="$missing $stage($fig)"
  fi
done
if [ -n "$missing" ]; then
  bad "AC26 — the cap is stated without the figures it came from:$missing — the next person to change it rounds it instead"
fi

# A BARE NUMBER FAILS. Fed the exact defect the rule exists to catch, so the check above is not
# merely wired to a file that happens to be correct (testing-conventions.md, prove a new guard fails).
BARE="$FIX/bare.yml"
printf 'project: fixture\nstage_budget_usd:\n  develop: 6.00\n' > "$BARE"
if [ -z "$(derivation "$BARE")" ]; then
  ok "a cap with no derivation above it is rejected"
else
  bad "HARNESS — the derivation reader accepted a bare cap; every case above is then unfalsifiable"
fi
ANNOTATED="$FIX/annotated.yml"
printf '# derived from MEASUREMENT.md: 4.03 per develop session\nstage_budget_usd:\n  develop: 6.00\n' > "$ANNOTATED"
if printf '%s' "$(derivation "$ANNOTATED")" | grep -qF '4.03'; then
  ok "a cap with its derivation above it is read"
else
  bad "HARNESS — the derivation reader missed a stated derivation; the real check would red a correct config"
fi

# The template has no history to derive from, so it must ship the INSTRUCTION and no number. A
# figure copied into a template is a derivation for somebody else's project.
TPL="$ROOT/skills/queue/templates/config.yml"
if grep -q '^stage_budget_usd:' "$TPL"; then
  ok "the queue template ships the stage_budget_usd key"
else
  bad "AC26 — the template omits stage_budget_usd; a new backlog's driver has no cap to read"
fi
# Written to REQUIRE THE KEY first. Asking only "is there a digit under stage_budget_usd" is green
# when the key is absent entirely — a filter that matches nothing and then asserts over it, green
# precisely when the thing it guards has gone missing (testing-conventions.md).
tpl_state="$(awk '
  /^stage_budget_usd:/ { key = 1; inside = 1; next }
  /^[^ #]/             { inside = 0 }
  inside && /[0-9]/    { fig = 1 }
  END { print (key ? (fig ? "figure" : "instruction-only") : "absent") }
' "$TPL")"
case "$tpl_state" in
  instruction-only) ok "the template ships the key with no cap figure, only the derivation instruction" ;;
  figure)  bad "AC26 — the template ships a cap figure; it has no cost_tracking history, so that number is another project's derivation" ;;
  *)       bad "AC26 — the template has no stage_budget_usd key at all, so there is nothing to ship a figure under" ;;
esac
if derivation "$TPL" | grep -qF 'cost_tracking'; then
  ok "the template tells a project to derive its cap from cost_tracking history"
else
  bad "AC26 — the template does not say where the cap comes from; the first number written there will be a guess"
fi

# ------------------------------------------------------------------------------------------------
# 0130 — the proposal a person confirms before any stage runs.
#
# WHY THESE ARE GREPS AND WHAT THAT BUYS. The mechanical half of 0130 — that the proposal can
# actually name the file a gate is held together by, and how many rows join through it — is asserted
# in tests/next.test.sh against the real `./next --drive --propose` and a fixture backlog. What is
# left here is the supervisor's own obligation, which is an instruction to a session: the only
# reachable property of an instruction is that it is present, and these cases are honest about that.
#
# EVERY ONE IS SECTION-SCOPED. A rule about the proposal is not satisfied by the words appearing in
# Step 1's probe or Step 5's run-log description, both of which talk about the same machinery for
# different reasons — the `section` helper above exists because three earlier cases measured
# something NEXT TO the defect they named.
PROPSEC="The proposal"

echo "0130 AC1 — the proposal section exists and is where the confirmation gate lives"
if [ -n "$(section "$SKILL" "$PROPSEC")" ]; then
  ok "the skill carries a proposal section"
else
  bad "AC1 — the skill has no '## $PROPSEC' section; there is nothing between the depth read and the dispatch"
fi

# AC1 is an ORDERING claim, and the order is the whole criterion: a proposal described after the
# dispatch step satisfies every word of FR1 and none of its point. Anchored to the STAGE dispatch's
# own `--session-id` line rather than to a step heading — Step 1's probe is also a `claude -p`, and
# an ordinal anchor is re-aimed rather than broken when a step is inserted ahead of it
# (testing-conventions.md). The marker line is what an edit moving the dispatch must also move.
prop_at="$(grep -n "^## $PROPSEC" "$SKILL" | head -1 | cut -d: -f1)"
stage_at="$(grep -n '\-\-session-id' "$SKILL" | head -1 | cut -d: -f1)"
marker_at="$(grep -n 'mkdir .claude/backlog/runs/.active' "$SKILL" | head -1 | cut -d: -f1)"
if [ -n "$prop_at" ] && [ -n "$stage_at" ] && [ "$prop_at" -lt "$stage_at" ]; then
  ok "the proposal is stated before the stage dispatch (line $prop_at before $stage_at)"
else
  bad "AC1 — the proposal is not stated before the stage dispatch (proposal ${prop_at:-absent}, dispatch ${stage_at:-absent})"
fi
# And AFTER the three checks, which FR1 says still happen first. Without this half the criterion is
# satisfied by a skill that proposes a scope before it knows whether it can dispatch at all.
if [ -n "$prop_at" ] && [ -n "$marker_at" ] && [ "$marker_at" -lt "$prop_at" ]; then
  ok "and after the supervisor marker is taken (line $marker_at before $prop_at)"
else
  bad "AC1 — the proposal precedes the marker; a scope would be confirmed before the run knows it may drive at all"
fi

if says "$SKILL" "$PROPSEC" 'no stage session'; then
  ok "the section forbids a stage session before confirmation"
else
  bad "AC1 — the section does not say that no stage runs before a person confirms"
fi

# AC3 — FIVE SEPARATE ASSERTIONS, because the criterion says so in as many words: "checked as five
# separate assertions, not one, so a proposal missing only the estimate still fails". One grep over
# a conjunction would be satisfied by any single element surviving.
echo "0130 AC3 — the proposal's five elements are each required, checked one by one"
prop_element() {
  if says_ci "$SKILL" "$PROPSEC" "$2"; then
    ok "the proposal must carry $1"
  else
    bad "AC3 — the proposal does not have to carry $1 (looked for: $2)"
  fi
}
prop_element "how many tickets"              'how many tickets'
prop_element "which tickets, by id and title" 'by id and title'
prop_element "a line of work per ticket"      'drawn from the ticket'
prop_element "why these tickets"              'why these'
prop_element "a three-part estimate"          'time, tokens and dollars'

# AC3's estimate half again, from the side the ticket actually cares about. FR6 does not ask for an
# estimate, it asks for one whose unsourced parts are LABELLED -- and on 2026-09-10 the wall-clock
# part has no prior at all, because MEASUREMENT.md records none and 0135 has not landed. A skill
# that presents three derived figures where one is a guess is worse than one that shows two.
echo "0130 AC3/FR6 — a figure with no prior is labelled rather than presented as derived"
if says "$SKILL" "$PROPSEC" 'no prior'; then
  ok "the section requires an unsourced figure to be labelled as having no prior"
else
  bad "AC3/FR6 — nothing says what to do with a figure the repo cannot source; wall-clock has no prior today"
fi
# A quoted figure is a cache of another file, and this repo has shipped one that went stale. The
# estimate's inputs are config.yml and MEASUREMENT.md, so the section has to send a reader there
# rather than carrying a number of its own.
if says "$SKILL" "$PROPSEC" 'MEASUREMENT.md'; then
  ok "and sources the figures from MEASUREMENT.md rather than quoting them"
else
  bad "AC3/FR6 — the section names no source for the estimate; the first number written there is a guess"
fi

echo "0130 AC4 — a partly-taken gate names what it left behind, and what resuming costs"
if says "$SKILL" "$PROPSEC" 'rows left behind'; then
  ok "the section requires the remainder to be named"
else
  bad "AC4 — an amended scope can be proposed with no mention of the rows it displaced"
fi
if says "$SKILL" "$PROPSEC" 'session floor'; then
  ok "and states the resume cost as one additional session floor"
else
  bad "AC4/FR7 — the remainder is named with no cost attached; the trade-off a person is making is unpriced"
fi

echo "0130 AC5 — declining ends the run and releases the marker"
if says "$SKILL" "$PROPSEC" 'decline'; then
  ok "declining is one of the three answers"
else
  bad "AC5/FR9 — the section offers no way to decline; a proposal that can only be accepted is not a gate"
fi
# Anchored to the marker PATH, not to the word "release": correct prose is free to mention releasing
# for other reasons, and Step 1 already does. The path is what an edit dropping the release must
# also drop.
if says "$SKILL" "$PROPSEC" '.claude/backlog/runs/.active'; then
  ok "and the decline path names the marker it removes"
else
  bad "AC5 — nothing says the supervisor marker is removed on a decline; the next sprint reports the backlog as held"
fi
if says "$SKILL" "$PROPSEC" 'amend'; then
  ok "amending the scope is the third answer"
else
  bad "FR9 — a person may only accept or decline, so a scope that is nearly right costs the whole run"
fi

echo "0130 AC6 — the confirmed scope reaches the run log BEFORE the first dispatch"
if says "$SKILL" "$PROPSEC" 'before the first dispatch'; then
  ok "the section states the ordering"
else
  bad "AC6/FR8 — the scope is not required to be logged before the dispatch; the ordering that loses it is the one where the first stage kills the supervisor"
fi
# The event has a NAME, so a resuming supervisor can find it and this suite can anchor to it. A
# rule written only as prose about "the scope" is a rule whose artifact nobody can grep for.
if says "$SKILL" "Step 5" 'scope_confirmed'; then
  ok "the run log's event vocabulary carries the confirmed scope"
else
  bad "AC6/FR8 — the run log section does not name the scope event; a resuming supervisor has nothing to read"
fi

# The ordering, as a property of a run log rather than of the prose. Two fixtures, one of each
# ordering, so the check can fail in both directions: asserted green on the good log and RED on the
# bad one, which is what stops this being a reader wired to nothing.
echo "0130 AC6 — the ordering is decidable from a run log, and both orderings are distinguishable"
scope_first() {
  awk '
    /"event": *"scope_confirmed"/ { if (!dispatched) { good = 1 } ; seen = 1 }
    /"event": *"stage_started"/   { dispatched = 1 }
    END { print (seen ? (good ? "ok" : "late") : "absent") }
  ' "$1"
}
cat > "$FIX/run-good.jsonl" <<'LOG'
{"ts":"2026-09-10T09:00:00Z","run":"r1","event":"depth","gates":2}
{"ts":"2026-09-10T09:01:00Z","run":"r1","event":"scope_confirmed","tickets":["0101","0102"]}
{"ts":"2026-09-10T09:02:00Z","run":"r1","event":"stage_started","stage":"develop"}
LOG
cat > "$FIX/run-late.jsonl" <<'LOG'
{"ts":"2026-09-10T09:00:00Z","run":"r1","event":"depth","gates":2}
{"ts":"2026-09-10T09:02:00Z","run":"r1","event":"stage_started","stage":"develop"}
{"ts":"2026-09-10T09:03:00Z","run":"r1","event":"scope_confirmed","tickets":["0101","0102"]}
LOG
cat > "$FIX/run-none.jsonl" <<'LOG'
{"ts":"2026-09-10T09:00:00Z","run":"r1","event":"depth","gates":2}
{"ts":"2026-09-10T09:02:00Z","run":"r1","event":"stage_started","stage":"develop"}
LOG
for pair in "run-good.jsonl:ok" "run-late.jsonl:late" "run-none.jsonl:absent"; do
  lf="${pair%%:*}"; want="${pair#*:}"
  got="$(scope_first "$FIX/$lf")"
  if [ "$got" = "$want" ]; then
    ok "$lf reads as $want"
  else
    bad "AC6 — $lf read as '$got', wanted '$want'; the ordering rule cannot tell the two logs apart"
  fi
done

echo "0130 — the proposal is one call, not a new turn in the cycle"
# The Performance NFR: built from the --drive call the skill makes anyway. A second read would be a
# turn, and the turn count is the only term the supervisor's cost model can move.
if says "$SKILL" "$PROPSEC" '--propose'; then
  ok "the section names the flag that produces it"
else
  bad "Performance NFR — the section does not name --propose, so the proposal has no stated source and the obvious one is a second read"
fi
# The skill states no routing rules of its own (references/CONVENTIONS.md), and the gate's
# composition is --drive's answer. A section that recomputed the grouping here would be the second
# copy of a rule that then diverges from the script with neither being wrong.
if says "$SKILL" "$PROPSEC" 'once per run'; then
  ok "and says the proposal is made once per run, not once per cycle"
else
  bad "Performance NFR — nothing bounds the proposal to one call; a block re-sent every cycle is the cost this skill exists to hold down"
fi

echo "0131 — the cycle names the input that keeps started work from going unverified"
# The property the supervisor RELIES ON, never the routing rule itself: which row wins is
# --drive's answer and the skill states no routing rules of its own (references/CONVENTIONS.md).
# What has to be written here is the input, because only the supervisor can compose it — the
# script cannot see a run log it is not handed.
if says "$SKILL" "Step 2" '--started'; then
  ok "Step 2 names --started"
else
  bad "0131 AC11 — Step 2 does not name --started, so the supervisor never sends it and the rule fails open in silence"
fi
# Cumulative over the RUN, not over the last call: a gate whose non-lead ticket goes unverified is
# two calls old by the time the rank walk would step over it, so a supervisor sending only what it
# just dispatched loses exactly the ticket the rule exists for.
if says_ci "$SKILL" "Step 2" 'cumulative'; then
  ok "and says the set is cumulative over the run"
else
  bad "0131 AC11 — nothing says --started is cumulative over the whole run; sent per-call it drops the ticket the rule exists to protect"
fi


echo "0129 — the skill is /sprint, and the retired command still resolves while it is deprecated"
# THE RETIRED WORD IS ASSEMBLED, NEVER WRITTEN. A guard whose subject is a string is a match for
# its own sweep, and excluding this file from AC2 instead would make the one file most likely to
# carry a stale citation the one file the sweep cannot see (testing-conventions.md, a check that
# filters for a set and then asserts over it).
OLD="orch""estrate"
ALIAS="$ROOT/commands/$OLD.md"

# AC1 — MOVED, not copied. The `! -e` half is the whole criterion: a copy leaves the old skill
# registered under its own name, which reads as a successful rename from the new directory alone.
if [ -f "$ROOT/skills/sprint/SKILL.md" ] && [ -f "$ROOT/skills/sprint/outcome.schema.json" ]; then
  ok "AC1 — skills/sprint/ carries the skill and its outcome schema"
else
  bad "AC1 — skills/sprint/SKILL.md or its outcome.schema.json is missing, so the move did not land"
fi
if [ -e "$ROOT/skills/$OLD" ]; then
  bad "AC1 — skills/$OLD still exists: the directory was copied rather than moved and both names are registered"
else
  ok "AC1 — the old skill directory is gone"
fi

# AC2 — a SWEEP of the live surface, never a list of the files that happened to cite the old name
# when this was written: a guard enumerating its own subjects is green by construction the day a
# new citation is added outside the list (testing-conventions.md). Two homes are allowed, and
# README.md is allowed only LINE BY LINE — allowing the whole file would let a stale mention of
# the retired command anywhere in it pass under cover of the deprecation notice.
stale=""
for f in $(cd "$ROOT" && grep -rl -i -- "$OLD" skills tests references tools commands README.md .claude-plugin 2>/dev/null | sort); do
  case "$f" in
    "commands/$OLD.md") ;;
    README.md)
      # every matching line must be about the deprecation itself
      if grep -i -- "$OLD" "$ROOT/README.md" | grep -qvi 'deprecat'; then stale="$stale README.md"; fi ;;
    *) stale="$stale $f" ;;
  esac
done
if [ -z "$stale" ]; then
  ok "AC2 — the live surface names the retired skill only where the deprecation is recorded"
else
  bad "AC2 — the retired name is still cited as live in:$stale"
fi

# AC3 — the alias itself, carrying the two facts deprecation-conventions.md requires be recorded
# the moment a deprecation is announced: the replacement path, and a named owner with a date.
# Asserted on the alias rather than on a release note, because the machine that still has the old
# command installed is the one reading this file.
if [ -f "$ALIAS" ]; then
  ok "AC3 — /$OLD still resolves: commands/$OLD.md is present"
  alias_text="$(tr '\n' ' ' < "$ALIAS" | tr -s ' ')"
  for want in '/sprint' 'skills/sprint/SKILL.md' 'Deprecated' '2026-12-10' 'Aaron Ferguson'; do
    if printf '%s' "$alias_text" | grep -qF -- "$want"; then
      ok "  the alias states $want"
    else
      bad "AC3 — the alias does not state $want, so the command resolves without naming its replacement, its owner or its removal date"
    fi
  done
else
  bad "AC3 — commands/$OLD.md is absent: /$OLD resolves to nothing on every machine that has it installed"
fi

# --- 0133 — the tail is earned, and it is two stages -------------------------------------------
#
# WHAT THESE CASES ARE. The two config cases are behavioural: they read the real files and the
# script's own default, and a bare number or a drifted template reds them. The rest are greps over
# Step 6, honest about being greps — they prove the rule is written down, never that a supervisor
# obeyed it. That split is this file's own convention, stated in its header.

echo "0133 AC6 — both findings limits carry their derivation, in both copies of config.yml"

# The contiguous comment block immediately above $2 in $1, and nothing else. Extracting the block
# is what makes this falsifiable: delete the reasoning and the key becomes the bare number AC6
# exists to forbid, with the assertion reading empty rather than reading the file's other prose.
comment_above() {
  awk -v key="$2" '
    /^#/   { if (!started) { started = 1; block = "" } ; block = block $0 "\n"; next }
    /^$/   { started = 0; block = ""; next }
    $0 ~ "^" key ":" { printf "%s", block; exit }
    { started = 0; block = "" }
  ' "$1"
}

for cfg in "$ROOT/.claude/backlog/config.yml" "$ROOT/skills/queue/templates/config.yml"; do
  cfgname="${cfg#$ROOT/}"
  for key in findings_threshold findings_max_sprints; do
    if awk -v k="$key" '$0 ~ "^" k ":" { found = 1 } END { exit !found }' "$cfg"; then
      ok "$cfgname carries $key"
    else
      bad "0133 AC6 — $cfgname has no $key; a driver then gates on a number no project can see"
    fi
    block="$(comment_above "$cfg" "$key")"
    if [ -n "$block" ]; then
      ok "  and states where the number came from"
    else
      bad "0133 AC6 — $key in $cfgname is a bare number: raising it later is a preference rather than an argument"
    fi
  done
done

echo "0133 FR4 — the template ships the script's own default, not a second opinion"
# DERIVED FROM THE SCRIPT, never restated. A literal here would guard the day it was written and
# nothing after: the two could drift apart and this case would hold at every value of either.
script_default="$(awk -F= '/^MAX_SPRINTS=/ { print $2; exit }' "$ROOT/skills/queue/templates/next")"
template_value="$(awk '/^findings_max_sprints:/ { v = $2; sub(/#.*/, "", v); print v; exit }' \
  "$ROOT/skills/queue/templates/config.yml")"
if [ -n "$script_default" ] && [ "$script_default" = "$template_value" ]; then
  ok "template findings_max_sprints ($template_value) matches the script default"
else
  bad "0133 FR4 — the template ships '$template_value' against a script default of '$script_default'; a fresh backlog then gates on a number neither file agrees with"
fi

echo "0133 AC1/AC2/AC4/AC5 — Step 6 says when the tail runs, what it is, and what it leaves alone"

# SCOPED TO STEP 6. A file-wide grep for these words pins vocabulary rather than the step that
# carries the rule, and `retro` and `queue` both appear all over this skill.
step6="$(awk '/^## Step 6 /{ inside = 1; next } /^## Step 7 /{ inside = 0 } inside' "$SKILL")"

if printf '%s' "$step6" | grep -qF '`retro`, and then `queue`'; then
  ok "AC2 — the tail is retro and then queue, in that order"
else
  bad "0133 AC2 — Step 6 does not name queue as the tail's second half; retro lands the lesson halves and only a queue sweep takes the work halves"
fi
if printf '%s' "$step6" | grep -qF 'no other stage session running'; then
  ok "AC2 — and each runs with no other stage session running"
else
  bad "0133 AC2 — Step 6 does not serialise the tail against the stages; both rewrite the skills and scripts every other session is executing"
fi
if printf '%s' "$step6" | grep -qF 'findings_max_sprints'; then
  ok "AC3 — Step 6 names the age limit as a way across the gate"
else
  bad "0133 AC3 — Step 6 gates on the count alone, which strands an old finding indefinitely on a low-yield project"
fi
if printf '%s' "$step6" | grep -qF 'carry forward untouched'; then
  ok "AC4 — an uncrossed gate leaves the buffer alone"
else
  bad "0133 AC4 — Step 6 does not say the findings carry forward untouched; a sprint marking entries it did not process makes the next gate read low"
fi
if printf '%s' "$step6" | grep -qF 'dispatches neither'; then
  ok "AC1 — and dispatches neither tail stage"
else
  bad "0133 AC1 — Step 6 does not state that an uncrossed gate runs NO tail, which spends about \$6.75 on a buffer with nothing in it"
fi

printf '\n%s passed, %s failed, %s skipped\n' "$PASS" "$FAIL" "$SKIP"
[ "$FAIL" = 0 ]
