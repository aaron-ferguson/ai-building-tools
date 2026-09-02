#!/bin/sh
#
# Guard for the startup-floor probe (the harness-floor measurement in MEASUREMENT.md).
#
# WHAT THIS EXISTS TO CATCH. The probe answers one question -- what does a session's startup floor
# cost under a given tool surface -- and the floor is the FIRST turn's context, not the last and
# not the largest. A probe that read the wrong turn would still print a plausible table, and every
# figure built on it would be wrong in the same direction, which is the failure `0009` already
# shipped once by modelling instead of measuring. The fixture below climbs 1000 -> 5000, so a
# script reading the last turn reports 5000 and a script reading the first reports 1000; nothing
# else separates them.
#
# The arithmetic is asserted against a GENERATED fixture with known counts rather than against the
# live transcript store, because the store grows and a guard that reads it goes red for reasons
# that have nothing to do with the code.
#
# Usage:  tests/floor-probe.test.sh
# Requires: sh, python3. No runner -- this project has none.

set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
PROBE="$ROOT/tools/floor-probe.sh"
REC="$ROOT/MEASUREMENT.md"

PASS=0
FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }

FIX=""
cleanup() { [ -n "$FIX" ] && rm -rf "$FIX"; return 0; }
trap cleanup EXIT INT TERM

echo "the probe is committed and runnable"
if [ -x "$PROBE" ]; then
  ok "tools/floor-probe.sh is present and executable"
else
  bad "tools/floor-probe.sh is missing or not executable — the recorded figures have no committed reproduction"
  printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
  exit 1
fi

# A fixture store: two configurations, two sessions each, floors 1000/1100 and 600/700.
# Each session climbs to 5000 so that reading the last turn is separable from reading the first,
# and each carries SENTINELPROSE in a message, an edit payload and a shell command, because this
# repo is public and an aggregate-figures script must never republish transcript content.
FIX="$(mktemp -d)"
python3 - "$FIX" <<'PY'
import json, os, sys
store = sys.argv[1]
def session(sid, floor):
    lines = []
    ctxs = [floor, floor + 1900, 5000]
    for i, c in enumerate(ctxs):
        lines.append(json.dumps({
            "type": "assistant", "timestamp": "2026-09-02T00:0%d:00Z" % i,
            "message": {"id": "msg_%s_%d" % (sid, i), "role": "assistant",
                        "content": [{"type": "text", "text": "SENTINELPROSE"},
                                    {"type": "tool_use", "name": "Bash",
                                     "input": {"command": "echo SENTINELPROSE"}}],
                        "usage": {"input_tokens": 0, "cache_read_input_tokens": c,
                                  "cache_creation_input_tokens": 0, "output_tokens": 10}}}))
    lines.append(json.dumps({"type": "user", "timestamp": "2026-09-02T00:00:30Z",
                             "message": {"role": "user", "content": "SENTINELPROSE"}}))
    open(os.path.join(store, sid + "-0000-0000-0000-000000000000.jsonl"), "w").write("\n".join(lines) + "\n")
for sid, floor in (("aaaaaaa1", 1000), ("aaaaaaa2", 1100), ("bbbbbbb1", 600), ("bbbbbbb2", 700)):
    session(sid, floor)
PY

echo "the floor is the FIRST turn's context, and configurations are compared against the first"
OUT="$("$PROBE" --read "$FIX" --config baseline:aaaaaaa1,aaaaaaa2 --config trimmed:bbbbbbb1,bbbbbbb2 2>&1)" || true
printf '%s\n' "$OUT" | sed 's/^/    | /'

row() { printf '%s\n' "$OUT" | awk -F'|' -v n="$1" '$0 ~ "^"n {gsub(/[ ,]/,"",$2); print $2; exit}'; }
MEAN_B="$(printf '%s\n' "$OUT" | awk -F'|' '/^baseline/ {gsub(/[ ,]/,"",$3); print $3; exit}')"
MEAN_T="$(printf '%s\n' "$OUT" | awk -F'|' '/^trimmed/  {gsub(/[ ,]/,"",$3); print $3; exit}')"
DELTA_T="$(printf '%s\n' "$OUT" | awk -F'|' '/^trimmed/  {gsub(/[ ,+]/,"",$4); print $4; exit}')"

if [ "$MEAN_B" = "1050" ]; then
  ok "the baseline mean floor is 1050 — the mean of the two FIRST turns"
else
  bad "expected a baseline mean floor of 1050; got: ${MEAN_B:-nothing}. 5000 means the probe is reading the last turn, not the floor."
fi
if [ "$MEAN_T" = "650" ]; then
  ok "the trimmed mean floor is 650"
else
  bad "expected a trimmed mean floor of 650; got: ${MEAN_T:-nothing}"
fi
if [ "$DELTA_T" = "400" ]; then
  ok "the saving is reported against the first configuration, 400 tokens"
else
  bad "expected a reported saving of 400 tokens; got: ${DELTA_T:-nothing} — a probe that prints floors without the delta leaves the reader to do the subtraction the record is about"
fi

echo "the probe refuses an unknown session rather than reporting a floor without it"
# `./claim`, `./close` and `./next` all refuse rather than guess (CONCURRENCY.md, The three
# scripts). A probe that silently drops a session it cannot find publishes a mean over a
# different denominator than the one its recipe names, which is exactly the decay MEASUREMENT.md
# pins its figures against.
if "$PROBE" --read "$FIX" --config baseline:aaaaaaa1,nosuchid >/dev/null 2>&1; then
  bad "the probe accepted a session id matching no transcript and reported a mean anyway"
else
  ok "the probe refuses a session id matching no transcript"
fi

echo "privacy NFR — the probe emits no transcript content"
# This repo is public. The probe reads transcripts that contain prose, edit payloads and shell
# commands, so it is a script that COULD publish one.
case "$OUT" in
  *SENTINELPROSE*) bad "privacy — transcript content from the fixture reached the probe's output" ;;
  *) ok "no fixture message, edit payload or command string reaches the output" ;;
esac
BADLINE="$(printf '%s\n' "$OUT" | grep -vn '^[A-Za-z0-9 .,$%|:/+()-]*$' | head -1 || true)"
if [ -z "$BADLINE" ]; then
  ok "every probe output line is within the aggregate-figures character set"
else
  bad "privacy — a probe output line leaves the aggregate-figures character set: $BADLINE"
fi

echo "the record carries the verdict and a reproduction for it"
# The failure this catches is a run that produces figures and no verdict (0042). Scope each
# assertion to the section that carries the claim, never to the document.
SEC="$(awk '/^## What the harness floor costs, and what trimming it buys$/{s=1;next} s&&/^## /{exit} s' "$REC" 2>/dev/null || true)"
if [ -n "$SEC" ]; then
  ok "the harness-floor section is present, so the assertions below have a scope"
else
  bad "no \"## What the harness floor costs, and what trimming it buys\" section in MEASUREMENT.md"
fi
for claim in "floor-probe.sh" "per closed ticket" "1,000 tickets"; do
  if printf '%s\n' "$SEC" | grep -qF -- "$claim"; then
    ok "the section carries: $claim"
  else
    bad "the harness-floor section does not carry: $claim"
  fi
done
# The verdict must survive deleting everything else in the section: assert the sentence, not a word.
if printf '%s\n' "$SEC" | grep -qiF "the finding, in one line"; then
  ok "the section states its finding in one line, as the record's other measurements do"
else
  bad "the harness-floor section states no one-line finding — a table without a verdict is what 0042 shipped"
fi

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" = 0 ]
