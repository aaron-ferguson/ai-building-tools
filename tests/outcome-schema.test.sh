#!/bin/sh
#
# Guard for the `progressed` verdict and its `slice` object in skills/sprint/outcome.schema.json,
# and for the `if`/`then`/`else` support in tools/validate-json-schema.py that makes the schema's
# conditional checkable offline (0231 FR7, AC6).
#
# WHY A CONDITIONAL. A leg that ends with slices remaining reports `progressed`, and the supervisor
# routes the next leg on WHICH slice comes next. A `progressed` outcome without `slice.next` is a
# verdict the supervisor cannot act on, so the schema refuses it — but only for `progressed`: every
# outcome shape that existed before slices still validates unchanged (the NFR Compatibility row).
#
# WHAT THIS CANNOT SEE. Like tests/sprint.test.sh's schema cases, these run against
# tools/validate-json-schema.py, the offline subset. Whether the `claude` CLI's own `--json-schema`
# accepts the conditional was probed by hand against the installed CLI and is recorded in 0231's
# Notes & decisions; tests/sprint.test.sh's AC22 probe exercises the live CLI with this same file.
#
# Every fixture is AUTHORED here, never copied from a real outcome (testing-conventions.md).
#
# Usage:  tests/outcome-schema.test.sh
#
# Requires: sh, python3.

set -eu
# Announce an abort instead of exiting silently (0169): a death under `set -eu` otherwise prints the
# passes reached and no tally. TALLIED=1 follows the tally; exiting without it says ABORTED and never
# exits 0. Byte-identical in every tests/*.test.sh, which tests/abort-announce.test.sh asserts.
TALLIED=""
announce_abort() {
  abort_status=$?
  if [ -z "$TALLIED" ]; then
    printf '\nABORTED before the tally: %s passed, %s failed so far (exit %s)\n' \
      "${PASS:-0}" "${FAIL:-0}" "$abort_status"
    [ "$abort_status" -ne 0 ] || abort_status=1
  fi
  if [ "$#" -gt 0 ]; then "$@" || true; fi
  exit "$abort_status"
}
trap announce_abort EXIT

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
SCHEMA="$ROOT/skills/sprint/outcome.schema.json"
VALIDATE="$ROOT/tools/validate-json-schema.py"
[ -f "$SCHEMA" ] || { echo "no schema at $SCHEMA" >&2; exit 2; }
[ -f "$VALIDATE" ] || { echo "no validator at $VALIDATE" >&2; exit 2; }

PASS=0
FAIL=0

ok()  { PASS=$((PASS + 1)); printf '  ok   — %s\n' "$1"; }
bad() { FAIL=$((FAIL + 1)); printf '  FAIL — %s\n' "$1"; }

WORK="$(mktemp -d)"
trap 'announce_abort rm -rf "$WORK"' EXIT
trap 'rm -rf "$WORK"' INT TERM

# outcome <name> <ticket-json> — one develop outcome envelope around a single ticket entry.
outcome() {
  cat > "$WORK/$1.json" <<EOF
{"stage": "develop", "commits": ["abc1234"], "cost_usd": 1.5, "findings_parked": 0,
 "conventions_resolved": "../conventions", "escalation": null,
 "tickets": [$2]}
EOF
}

# valid <label> <schema> <doc> / invalid <label> <schema> <doc> [reason-substring]
valid() {
  if out="$(python3 "$VALIDATE" "$2" "$3")"; then ok "$1"; else
    bad "$1 — expected valid, the validator said: $out"
  fi
}
invalid() {
  status=0
  out="$(python3 "$VALIDATE" "$2" "$3")" || status=$?
  if [ "$status" -eq 0 ]; then
    bad "$1 — expected the validator to refuse it, it accepted it"
    return
  fi
  if [ "$status" -ne 1 ]; then bad "$1 — expected exit 1 (invalid), got $status: $out"; return; fi
  if [ -n "${4:-}" ] && ! printf '%s\n' "$out" | grep -qF -- "$4"; then
    bad "$1 — refused, but the reason does not name '$4': $out"
    return
  fi
  ok "$1"
}

T='"id": "0231", "next": "develop", "status": "ready", "detail": ".tickets/items/0231.md"'

# ------------------------------------------------------------------------------------------------
echo "0231 AC6 — a progressed outcome with slice {done: S1, next: S2} validates"
outcome progressed-full "{$T, \"verdict\": \"progressed\", \"slice\": {\"done\": \"S1\", \"next\": \"S2\"}}"
valid "progressed with slice.done and slice.next validates" "$SCHEMA" "$WORK/progressed-full.json"

echo "0231 AC6 — progressed with no slice.next fails"
outcome progressed-no-next "{$T, \"verdict\": \"progressed\", \"slice\": {\"done\": \"S1\"}}"
invalid "progressed with slice.done only is refused, naming next" "$SCHEMA" \
  "$WORK/progressed-no-next.json" "'next'"
outcome progressed-no-slice "{$T, \"verdict\": \"progressed\"}"
invalid "progressed with no slice at all is refused, naming slice" "$SCHEMA" \
  "$WORK/progressed-no-slice.json" "'slice'"

echo "0231 AC6 — an existing built outcome with no slice still validates"
outcome built-plain "{$T, \"verdict\": \"built\"}"
valid "built with no slice validates" "$SCHEMA" "$WORK/built-plain.json"

echo "0231 FR7 — the slice object's own shape"
outcome built-done-only "{$T, \"verdict\": \"built\", \"slice\": {\"done\": \"S6\"}}"
valid "built may report the leg it ended with slice.done alone (a leg handed to verify)" \
  "$SCHEMA" "$WORK/built-done-only.json"
outcome bad-pattern "{$T, \"verdict\": \"progressed\", \"slice\": {\"done\": \"S1\", \"next\": \"slice 2\"}}"
invalid "a slice name off ^S[0-9]+\$ is refused" "$SCHEMA" "$WORK/bad-pattern.json" "does not match"
outcome extra-key "{$T, \"verdict\": \"progressed\", \"slice\": {\"done\": \"S1\", \"next\": \"S2\", \"of\": \"S6\"}}"
invalid "an undeclared key inside slice is refused" "$SCHEMA" "$WORK/extra-key.json" "'of'"

# ------------------------------------------------------------------------------------------------
# The validator's conditional, against a schema authored here and knowing nothing about outcomes,
# so the cases above cannot pass by a validator that ignores `if` and a schema that happens to
# require `slice` unconditionally.
echo "0231 FR7 — tools/validate-json-schema.py applies if/then/else"
cat > "$WORK/cond.schema.json" <<'EOF'
{"type": "object",
 "properties": {"kind": {"enum": ["a", "b", "c"]}, "x": {"type": "string"}, "y": {"type": "string"}},
 "if": {"properties": {"kind": {"enum": ["a"]}}, "required": ["kind"]},
 "then": {"required": ["x"]},
 "else": {"required": ["y"]}}
EOF
printf '{"kind": "a", "x": "1"}\n' > "$WORK/c1.json"
printf '{"kind": "a"}\n'           > "$WORK/c2.json"
printf '{"kind": "b", "y": "1"}\n' > "$WORK/c3.json"
printf '{"kind": "b", "x": "1"}\n' > "$WORK/c4.json"
printf '{"y": "1"}\n'              > "$WORK/c5.json"
valid   "if matches and then holds → valid"                  "$WORK/cond.schema.json" "$WORK/c1.json"
invalid "if matches and then fails → invalid, naming x"      "$WORK/cond.schema.json" "$WORK/c2.json" "'x'"
valid   "if fails and else holds → valid"                    "$WORK/cond.schema.json" "$WORK/c3.json"
invalid "if fails and else fails → invalid, naming y"        "$WORK/cond.schema.json" "$WORK/c4.json" "'y'"
valid   "if's own required is unmet → else applies, holds"   "$WORK/cond.schema.json" "$WORK/c5.json"

echo
echo "$PASS passed, $FAIL failed"
TALLIED=1
[ "$FAIL" -eq 0 ] || exit 1
