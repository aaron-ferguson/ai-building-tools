#!/bin/sh
#
# Guard for design holding its row (0150).
#
# `design` used to reason over a row nobody held and learn who else was on it only at Step 4, when
# it went to write: `./next design` offered 0134 as TAKE, a whole Step 2-3 pass was spent on it, and
# the row turned out `in-progress` under another session. A sprint dispatching design beside develop
# has the same hole from the other side — unless the design session's row reads held, `--drive`
# exits 4 on it and the supervisor starts a second design session on one ticket (0134 FR5).
#
# No script changed for this: `claim`, `next` and `handoff` already accept a `next: design` row.
# The behavioural cases pin that they go on doing so; the prose cases pin that the skill tells a
# design session to use them. The fixture scripts come from skills/queue/templates, the copy every
# install scaffolds from, never from .claude/backlog.
#
# Each prose grep is scoped to its step's section and matches a phrase short enough to sit on one
# line — `grep` is line-based, so an asserted phrase that straddles a rewrap cannot match (CLAUDE.md).
#
# Usage:  tests/design-hold.test.sh
#
# Requires: git, sh, awk. No runner — this project has none.

set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
SKILL="$ROOT/skills/design/SKILL.md"
CLAIM_SRC="$ROOT/skills/queue/templates/claim"
NEXT_SRC="$ROOT/skills/queue/templates/next"
HANDOFF_SRC="$ROOT/skills/queue/templates/handoff"
for f in "$SKILL" "$CLAIM_SRC" "$NEXT_SRC" "$HANDOFF_SRC"; do
  [ -f "$f" ] || { echo "missing $f" >&2; exit 2; }
done

PASS=0
FAIL=0
FIX=""

cleanup() { [ -n "$FIX" ] && rm -rf "$FIX"; return 0; }
trap cleanup EXIT INT TERM

# --- assertions -------------------------------------------------------------------------------
# The same reporting shape as tests/claim.test.sh and tests/handoff.test.sh: what each assertion
# matched against is printed on FAIL always, and on a pass only under SHOW_MATCHED.
saw()         { printf '%s\n' "$1" | sed '1s/^/         saw: /; 1!s/^/              /'; }
saw_on_pass() { [ -n "${SHOW_MATCHED:-}" ] && saw "$1"; return 0; }

ok()  { PASS=$((PASS + 1)); echo "  ok   — $1"; }
bad() { FAIL=$((FAIL + 1)); echo "  FAIL — $1"; }

assert_contains() {
  case "$2" in
    *"$3"*) ok "$1"; saw_on_pass "$2" ;;
    *)      bad "$1"; echo "         expected to contain: $3"; saw "$2" ;;
  esac
}

assert_not_contains() {
  case "$2" in
    *"$3"*) bad "$1"; echo "         expected NOT to contain: $3"; saw "$2" ;;
    *)      ok "$1"; saw_on_pass "$2" ;;
  esac
}

assert_rc() {
  if [ "$2" -eq "$3" ]; then ok "$1"; saw_on_pass "exit $2
$4"; else
    bad "$1"; saw "wanted exit $3, got exit $2
$4"; fi
}

assert_rc_nonzero() {
  if [ "$2" -ne 0 ]; then ok "$1"; saw_on_pass "exit $2
$3"; else
    bad "$1"; saw "wanted any exit but 0
$3"; fi
}

assert_eq() {
  if [ "$2" = "$3" ]; then ok "$1"; saw_on_pass "$2"; else
    bad "$1"; echo "         expected exactly: $3"; saw "$2"; fi
}

# --- the skill, one section at a time -----------------------------------------------------------
# From the heading that starts with $1 up to the next `## ` heading, exclusive.
section() {
  awk -v want="$1" '
    /^## / { inside = (index($0, want) == 1) }
    inside { print }
  ' "$SKILL"
}

# --- fixture ----------------------------------------------------------------------------------
# Row 1 is a design row, row 2 a develop row beneath it, so `--drive` has something to step to.
DESIGN_ID=0001
DEVELOP_ID=0002

add_ticket() {
  cat > "$FIX/.claude/backlog/items/$1-fixture.md" <<ITEM
---
id: "$1"
title: Fixture $1
type: feature
next: $2
status: ready
qa_level: unit
size: s
parent:
blocked_by: []
expects:
  - src/$1.ts
claimed_by:
claimed_at:
touches:
---

## Problem

A fixture.
ITEM
}

scaffold() {
  cleanup
  FIX="$(mktemp -d)"
  mkdir -p "$FIX/.claude/backlog/items"
  git -C "$FIX" init -q
  git -C "$FIX" config user.email test@example.invalid
  git -C "$FIX" config user.name "design-hold test"

  {
    printf '# Backlog\n\n'
    printf '| ID | Title | Next | Status | Parent |\n'
    printf '|------|-------|------|--------|--------|\n'
    printf '| %s | A design row | design | ready |  |\n' "$DESIGN_ID"
    printf '| %s | A develop row | develop | ready |  |\n' "$DEVELOP_ID"
  } > "$FIX/.claude/backlog/QUEUE.md"
  add_ticket "$DESIGN_ID" design
  add_ticket "$DEVELOP_ID" develop

  for s in claim next handoff; do
    cp "$ROOT/skills/queue/templates/$s" "$FIX/.claude/backlog/$s"
    chmod +x "$FIX/.claude/backlog/$s"
  done
  git -C "$FIX" add -A
  git -C "$FIX" commit -q -m "fixture"
}

backlog() { (cd "$FIX" && ".claude/backlog/$@" 2>&1); }
design_row() { grep "^| $DESIGN_ID |" "$FIX/.claude/backlog/QUEUE.md" || true; }
design_item_line() { grep "^$1:" "$FIX/.claude/backlog/items/$DESIGN_ID-fixture.md" || true; }

# --- AC1 — Step 1 names ./claim ------------------------------------------------------------------
echo "AC1 — Step 1 takes the row with ./claim"
assert_contains "Step 1 names ./claim" "$(section '## Step 1')" './claim'

# --- AC5 — Step 4 releases with ./handoff, and the by-hand stage write is gone -------------------
echo "AC5 — Step 4 releases with ./handoff and no longer commits a stage change by hand"
step4="$(section '## Step 4')"
assert_contains     "Step 4 names ./handoff"                   "$step4" './handoff'
assert_contains     "Step 4 releases an undecided pass to design ready" "$step4" 'design ready'
assert_not_contains "Step 4 no longer says 'commit by'"        "$step4" 'commit by'

# --- AC6 — an ad-hoc question takes no claim ---------------------------------------------------
echo "AC6 — the skill says an ad-hoc question takes no claim"
assert_contains "the sentence is present" "$(cat "$SKILL")" 'An ad-hoc question takes no claim'

# --- FR4 — the intro tells held-by-you from held-by-another ------------------------------------
echo "FR4 — How to tell distinguishes held by you from held by another"
intro="$(awk '/^## Step 1/ { exit } { print }' "$SKILL")"
assert_contains "names held by you"     "$intro" 'held by you'
assert_contains "names held by another" "$intro" 'held by another'

# --- AC2 — control: an unclaimed design row stops --drive --------------------------------------
# Without this case the next one could pass on a fixture `--drive` would have stepped past anyway.
echo "AC2 control — an unclaimed design row is where --drive stops"
scaffold
out="$(backlog next --drive)" && rc=0 || rc=$?
assert_rc           "exits 4 on the unheld design row" "$rc" 4 "$out"
assert_not_contains "does not step over it"            "$out" 'stepping over it'

# --- AC2 — a claimed design row is stepped over ------------------------------------------------
echo "AC2 — a claimed design row is stepped over and drive names the develop row"
scaffold
out="$(backlog claim "$DESIGN_ID" tok0)" && rc=0 || rc=$?
assert_rc       "./claim takes the design row"      "$rc" 0 "$out"
assert_contains "the row reads in-progress"          "$(design_row)" '| design | in-progress |'
out="$(backlog next --drive)" && rc=0 || rc=$?
assert_rc       "drive dispatches"                   "$rc" 0 "$out"
assert_contains "drive names the develop row"        "$out" "$DEVELOP_ID"
assert_contains "drive steps over the design row"    "$out" "$DESIGN_ID is in-progress"
assert_contains "and says so"                        "$out" 'stepping over it'

# --- AC3 — a second claim on the held design row refuses ---------------------------------------
echo "AC3 — a second ./claim on the held design row refuses and changes no owner"
held_by="$(design_item_line claimed_by)"
out="$(backlog claim "$DESIGN_ID" tok1)" && rc=0 || rc=$?
assert_rc_nonzero "the second claim refuses"          "$rc" "$out"
assert_contains   "because the row is not ready"      "$out" 'not ready'
assert_eq         "claimed_by: is unchanged"          "$(design_item_line claimed_by)" "$held_by"
assert_contains   "and still names the first token"   "$held_by" 'tok0'

# --- AC4 — all three releases -------------------------------------------------------------------
release_case() {
  label="$1"; stage="$2"; status="$3"
  echo "AC4 — ./handoff releases a held design row to $label"
  scaffold
  backlog claim "$DESIGN_ID" tok0 >/dev/null
  if [ "$status" = ready ]; then
    out="$(backlog handoff "$DESIGN_ID" tok0 "$stage")" && rc=0 || rc=$?
  else
    out="$(backlog handoff "$DESIGN_ID" tok0 "$stage" "$status")" && rc=0 || rc=$?
  fi
  assert_rc       "exits 0"                          "$rc" 0 "$out"
  assert_eq       "claimed_by: is cleared"           "$(design_item_line claimed_by)" 'claimed_by:'
  assert_eq       "the item's next: is $stage"       "$(design_item_line next)" "next: $stage"
  assert_eq       "the item's status: is $status"    "$(design_item_line status)" "status: $status"
  assert_contains "the row reads $stage | $status"   "$(design_row)" "| $stage | $status |"
}

release_case "develop"        develop ready
release_case "design waiting" design  waiting
release_case "design ready"   design  ready

echo
echo "design-hold: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
