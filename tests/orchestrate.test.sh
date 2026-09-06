#!/bin/sh
#
# Guard for the orchestrate skill and the stage outcome schema (0039).
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
# Usage:  tests/orchestrate.test.sh
#
# Requires: sh, python3, grep. `claude` optional -- the probe skips loudly without it.

set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

SKILL="$ROOT/skills/orchestrate/SKILL.md"
SCHEMA="$ROOT/skills/orchestrate/outcome.schema.json"
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

# ------------------------------------------------------------------------------------------------
echo "AC2 — the schema is a single committed file that parses"

if [ -f "$SCHEMA" ]; then
  ok "skills/orchestrate/outcome.schema.json exists"
else
  bad "skills/orchestrate/outcome.schema.json is missing — FR13's single source has no file"
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
       *"skills/orchestrate/outcome.schema.json") ok "only the schema file declares the envelope" ;;
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
    ("stage",  lambda d: d.__setitem__("stage", "orchestrate")),
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

echo "AC19/AC1 — a dispatch is capped, scoped, and does not block on stdin"
# `< /dev/null` is in this sweep because it is a real defect this ticket hit rather than a
# tidiness rule: without it the nested CLI waits on stdin and prints its warning INTO the stream
# the supervisor parses as JSON, so a good stage reads as a schema failure and Step 4 escalates.
for want in -\-max-budget-usd -\-allowed-tools -\-add-dir -\-session-id -\-setting-sources '< /dev/null'; do
  if fenced "$SKILL" | grep -qF -- "$want"; then
    ok "the dispatch block carries $want"
  else
    bad "AC19/AC1 — the dispatch block does not carry $want"
  fi
done

echo "AC2 — the skill points at the schema file rather than restating the shape"
if grep -qF 'skills/orchestrate/outcome.schema.json' "$SKILL"; then
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

echo "AC24 — README describes the supervised loop alongside the hand-driven one"
sec="$(awk '/^## One skill per session/ { inside = 1; next } /^## / { inside = 0 } inside' "$README")"
if printf '%s' "$sec" | grep -qF 'orchestrate'; then
  ok "README's One skill per session names the orchestrate loop"
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

if grep -qF 'Claim tokens' "$SKILL"; then
  ok "the skill routes an orphaned claim to CONCURRENCY.md's ownership rule rather than taking it over"
else
  bad "AC16 — the skill does not say what to do with a claim a killed stage left behind"
fi

# ------------------------------------------------------------------------------------------------
# AC22 — the probe, and the only case here that touches the REAL validator.
echo "AC22 — a real nested dispatch returns the fixed object"

if ! command -v claude >/dev/null 2>&1; then
  skip "AC22 — no \`claude\` on PATH; the nested-dispatch premise under AC1 is UNVERIFIED in this run"
elif [ -n "${ORCHESTRATE_SKIP_PROBE:-}" ]; then
  skip "AC22 — ORCHESTRATE_SKIP_PROBE is set; the nested-dispatch premise under AC1 is UNVERIFIED in this run"
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
lines.append({"type": "user", "message": {"content": "<command-name>/orchestrate</command-name>"}})
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

echo "AC21 — the report carries what the run learned"
if grep -qF 'findings-parked count' "$SKILL"; then
  ok "the report carries the findings-parked count"
else
  bad "AC21 — the report carries no findings-parked count; nothing shows the run is learning anything"
fi

echo "AC23 — the plugin still declares its skill set, and this one is in it"
for f in .claude-plugin/plugin.json .claude-plugin/marketplace.json; do
  if python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$ROOT/$f" 2>/dev/null; then
    ok "$f parses"
  else
    bad "AC23 — $f no longer parses; the plugin would not load at all"
  fi
  if grep -qF 'orchestrate' "$ROOT/$f"; then
    ok "$f names the orchestrate skill"
  else
    bad "AC24 — $f does not name the orchestrate skill"
  fi
done
sec="$(awk '/^\| Skill \| Does \| Phase \|/ { inside = 1 } inside && /^\|/ { print } inside && !/^\|/ { inside = 0 }' "$README")"
if printf '%s' "$sec" | grep -qF '/orchestrate'; then
  ok "README's skill table lists /orchestrate"
else
  bad "AC24 — README's skill table does not list /orchestrate"
fi

printf '\n%s passed, %s failed, %s skipped\n' "$PASS" "$FAIL" "$SKIP"
[ "$FAIL" = 0 ]
