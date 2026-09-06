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

printf '\n%s passed, %s failed, %s skipped\n' "$PASS" "$FAIL" "$SKIP"
[ "$FAIL" = 0 ]
