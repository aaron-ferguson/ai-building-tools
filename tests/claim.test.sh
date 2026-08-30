#!/bin/sh
#
# Behavioural guard for skills/queue/templates/claim.
#
# The script edits a markdown table, so its only real contract is what it does to a file of a
# given shape — there is nothing to unit test underneath that. Each case therefore scaffolds a
# throwaway git repo with one table shape, runs `claim` against it, and asserts on the exit code,
# the message, and the resulting row. Fixtures are removed on the way out, including on failure.
#
# The defect this exists to catch (0022): `claim` read Status by fixed column index, so the
# five-column table 0010 introduced made every row read as empty and every claim was refused —
# silently, with a message blaming the row. A shape it cannot read must be an error, never a
# refusal that looks like a full backlog.
#
# Usage:  tests/claim.test.sh
#
# Requires: git, sh, awk. No runner — this project has none.

set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
CLAIM_SRC="$ROOT/skills/queue/templates/claim"
[ -f "$CLAIM_SRC" ] || { echo "no claim script at $CLAIM_SRC" >&2; exit 2; }

PASS=0
FAIL=0
FIX=""

cleanup() { [ -n "$FIX" ] && rm -rf "$FIX"; return 0; }
trap cleanup EXIT INT TERM

# --- fixture ----------------------------------------------------------------------------------
# $1 header row, $2 separator row, $3 the single data row, $4 the id that row carries.
scaffold() {
  cleanup
  FIX="$(mktemp -d)"
  mkdir -p "$FIX/.claude/backlog/items"
  git -C "$FIX" init -q
  git -C "$FIX" config user.email test@example.invalid
  git -C "$FIX" config user.name "claim test"

  {
    printf '# Backlog\n\n'
    printf '%s\n%s\n%s\n' "$1" "$2" "$3"
  } > "$FIX/.claude/backlog/QUEUE.md"

  cat > "$FIX/.claude/backlog/items/$4-fixture.md" <<ITEM
---
id: "$4"
title: Fixture
status: ready
claimed_by:
claimed_at:
---

## Problem
ITEM

  cp "$CLAIM_SRC" "$FIX/.claude/backlog/claim"
  chmod +x "$FIX/.claude/backlog/claim"
  git -C "$FIX" add -A
  git -C "$FIX" commit -q -m "fixture"
}

run_claim() { (cd "$FIX" && .claude/backlog/claim "$1" tok0 2>&1); }

# --- assertions -------------------------------------------------------------------------------
# Every assertion reports the text it matched against: always on FAIL, and on a pass only when
# SHOW_MATCHED is set in the environment. A green run therefore stays one line per case plus the
# tally (`testing-conventions.md`, lean by default), and a mutation sweep sets SHOW_MATCHED=1 for
# one run to see what a case that stayed green matched instead — the question this harness could
# not answer before, so each sweep hand-built a fixture outside the suite to ask it.
#
# tests/next.test.sh, tests/close.test.sh and tests/claim.test.sh each carry this pair, because a
# suite here is self-contained and sources nothing (`CLAUDE.md`). Change one, change all three.
saw()         { printf '%s\n' "$1" | sed '1s/^/         saw: /; 1!s/^/              /'; }
saw_on_pass() { [ -n "${SHOW_MATCHED:-}" ] && saw "$1"; return 0; }

ok()   { PASS=$((PASS + 1)); echo "  ok   — $1"; }
bad()  { FAIL=$((FAIL + 1)); echo "  FAIL — $1"; }

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

# An exit code carries no evidence of its own, so both helpers take the captured output as an
# optional trailing argument and report it the same way every other assertion does. The inline
# `[ "$rc" -eq 0 ] && ok … || bad …` form these replace printed `got:` on three cases and nothing
# at all on the other two — a third debugging interface in the suite FR4 exists to keep to one.
assert_rc() {
  seen="exit $2"
  if [ $# -ge 4 ]; then seen="$seen
$4"; fi
  if [ "$2" -eq "$3" ]; then ok "$1"; saw_on_pass "$seen"; else
    bad "$1"; saw "wanted exit $3
$seen"; fi
}

assert_rc_nonzero() {
  seen="exit $2"
  if [ $# -ge 3 ]; then seen="$seen
$3"; fi
  if [ "$2" -ne 0 ]; then ok "$1"; saw_on_pass "$seen"; else
    bad "$1"; saw "wanted any exit but 0
$seen"; fi
}

# Match the whole line rather than looking a cell up by index: a harness that reimplements the
# parser under test passes and fails with it, and this one did — it reported a correct claim as a
# missing row because it was still finding the id in column 2.
assert_row() {
  table="$(sed -n '/^|/p' "$FIX/.claude/backlog/QUEUE.md")"
  if grep -Fxq "$2" "$FIX/.claude/backlog/QUEUE.md"; then
    ok "$1"
    saw_on_pass "$table"
  else
    bad "$1"
    echo "         expected row: $2"
    saw "$table"
  fi
}

FIVE_HEAD='| ID | Title | Next | Status | Parent |'
FIVE_SEP='|------|-------|------|--------|--------|'
EIGHT_HEAD='| ID | Title | Type | Size | QA | Status | Owner | Item |'
EIGHT_SEP='|------|-------|------|------|----|--------|-------|------|'

# --- AC1 — five-column table, ready row ------------------------------------------------------
echo "AC1 — five-column ready row is claimed, written and committed"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0001 | A fixture row | develop | ready | 0000 |' 0001
out="$(run_claim 0001)" && rc=0 || rc=$?
assert_rc "exits 0" "$rc" 0 "$out"
assert_row "row is set in-progress" '| 0001 | A fixture row | develop | in-progress | 0000 |'
assert_contains "item records the token" "$(cat "$FIX/.claude/backlog/items/0001-fixture.md")" 'claimed_by: "tok0"'
assert_contains "the claim is committed" "$(git -C "$FIX" log -1 --format=%s)" 'Claim 0001 [tok0]'
assert_contains "nothing is left uncommitted" "clean$(git -C "$FIX" status --porcelain)" 'clean'

# --- AC2 — five-column table, blocked row ----------------------------------------------------
echo "AC2 — a blocked row is refused by its actual status"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0002 | A blocked row | develop | blocked | 0000 |' 0002
out="$(run_claim 0002)" && rc=0 || rc=$?
assert_rc_nonzero "exits non-zero" "$rc" "$out"
assert_contains "names the actual status" "$out" 'blocked'
assert_not_contains "does not report an empty status" "$out" "is ''"
assert_not_contains "does not read ownership from a column" "$out" 'owner'
assert_row "the row is untouched" '| 0002 | A blocked row | develop | blocked | 0000 |'

# --- AC3 — pre-0010 eight-column table -------------------------------------------------------
echo "AC3 — a pre-0010 eight-column table still claims"
scaffold "$EIGHT_HEAD" "$EIGHT_SEP" '| 0003 | An old row | bug | s | unit | ready | — | items/0003.md |' 0003
out="$(run_claim 0003)" && rc=0 || rc=$?
assert_rc "exits 0" "$rc" 0 "$out"
assert_row "the Status cell is the one that changed" '| 0003 | An old row | bug | s | unit | in-progress | — | items/0003.md |'

# --- AC4 — a table with no Status column -----------------------------------------------------
echo "AC4 — a table with no Status column is an explicit error"
scaffold '| ID | Title | Next | Parent |' '|------|-------|------|--------|' '| 0004 | No status column | develop | 0000 |' 0004
out="$(run_claim 0004)" && rc=0 || rc=$?
assert_rc_nonzero "exits non-zero" "$rc" "$out"
assert_contains "quotes the header it found" "$out" 'ID | Title | Next | Parent'
assert_contains "says what is missing" "$out" 'Status'
assert_row "the row is untouched" '| 0004 | No status column | develop | 0000 |'

# --- FR1 — column order is not a contract ----------------------------------------------------
# Neither AC pins order-independence, and AC1 and AC3 alone are satisfiable by any parser that
# happens to try both indices. Status first is the cheapest case that only a by-name parser passes.
echo "FR1 — a reordered table claims by name, not by index"
scaffold '| Status | ID | Title | Next | Parent |' '|--------|------|-------|------|--------|' '| ready | 0005 | Reordered | develop | 0000 |' 0005
out="$(run_claim 0005)" && rc=0 || rc=$?
assert_rc "exits 0" "$rc" 0 "$out"
assert_row "the Status cell is the one that changed" '| in-progress | 0005 | Reordered | develop | 0000 |'

# --- result -----------------------------------------------------------------------------------
echo
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
