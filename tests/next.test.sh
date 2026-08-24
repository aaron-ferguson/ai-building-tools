#!/bin/sh
#
# Behavioural guard for skills/queue/templates/next.
#
# `next` is a reader over a markdown table plus the item frontmatter behind it, so its only real
# contract is what it prints and what it exits for a given pair of those. Each case scaffolds a
# throwaway git repo holding one table and its items, runs `next`, and asserts on the exit code and
# the message. Fixtures are removed on the way out, including on failure.
#
# The defect this exists to catch (0024): `blocked_by` and the Status column are two answers to
# "is this blocked?", and nothing kept them in step — a ticket closed and four rows naming it sat
# at `blocked` for the rest of the session with nothing left blocking them. Exit codes are pinned
# separately from output on every drift case: a drift report that prints but exits zero is
# invisible to anything scripted around it, which is the same silent failure this ticket removes.
#
# Usage:  tests/next.test.sh
#
# Requires: git, sh, awk. No runner — this project has none.

set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
NEXT_SRC="$ROOT/skills/queue/templates/next"
[ -f "$NEXT_SRC" ] || { echo "no next script at $NEXT_SRC" >&2; exit 2; }

PASS=0
FAIL=0
FIX=""

cleanup() { [ -n "$FIX" ] && rm -rf "$FIX"; return 0; }
trap cleanup EXIT INT TERM

# --- fixture ----------------------------------------------------------------------------------
scaffold() {
  cleanup
  FIX="$(mktemp -d)"
  mkdir -p "$FIX/.claude/backlog/items"
  git -C "$FIX" init -q
  git -C "$FIX" config user.email test@example.invalid
  git -C "$FIX" config user.name "next test"

  {
    printf '# Backlog\n\n'
    printf '| ID | Title | Next | Status | Parent |\n'
    printf '|------|-------|------|--------|--------|\n'
  } > "$FIX/.claude/backlog/QUEUE.md"

  cp "$NEXT_SRC" "$FIX/.claude/backlog/next"
  chmod +x "$FIX/.claude/backlog/next"
}

# $1 id, $2 title, $3 next, $4 status, $5 parent
add_row() {
  printf '| %s | %s | %s | %s | %s |\n' "$1" "$2" "$3" "$4" "$5" >> "$FIX/.claude/backlog/QUEUE.md"
}

# $1 id, $2 status, $3 blocked_by as an inline list, e.g. '["0002"]' or '[]'
add_item() {
  cat > "$FIX/.claude/backlog/items/$1-fixture.md" <<ITEM
---
id: "$1"
title: Fixture $1
next: develop
status: $2
qa_level: unit
size: s
blocked_by: $3
expects:
  - some/file.md
claimed_by:
claimed_at:
touches:
---

## Problem
ITEM
}

# A held item whose frontmatter lists are written out verbatim, so a case can put a YAML comment,
# a quoted path or a comment-only entry where a real session would. `add_item`'s fixed blocks
# cannot express any of those, and the comment handling is the whole subject of 0031.
#
# $1 id, $2 status, $3 blocked_by value (inline, e.g. '[]'), $4 the touches block body — a
# leading newline then `  - ` entries, or empty for none.
add_item_lists() {
  cat > "$FIX/.claude/backlog/items/$1-fixture.md" <<ITEM
---
id: "$1"
title: Fixture $1
next: develop
status: $2
qa_level: unit
size: s
blocked_by: $3
expects:
  - some/file.md
claimed_by: "aa11"
claimed_at: 2026-08-24T00:00:00Z
touches:$4
---

## Problem
ITEM
}

# The same, with `blocked_by` written as a block so an entry can carry an inline comment.
# $1 id, $2 status, $3 the blocked_by block body.
add_item_blocked_block() {
  cat > "$FIX/.claude/backlog/items/$1-fixture.md" <<ITEM
---
id: "$1"
title: Fixture $1
next: develop
status: $2
qa_level: unit
size: s
blocked_by:$3
expects:
  - some/file.md
claimed_by:
claimed_at:
touches:
---

## Problem
ITEM
}

seal() {
  git -C "$FIX" add -A
  git -C "$FIX" commit -q -m "fixture"
}

run_next() { (cd "$FIX" && .claude/backlog/next "$@" 2>&1); }

# --- assertions -------------------------------------------------------------------------------
ok()  { PASS=$((PASS + 1)); echo "  ok   — $1"; }
bad() { FAIL=$((FAIL + 1)); echo "  FAIL — $1"; }

assert_contains() {
  case "$2" in
    *"$3"*) ok "$1" ;;
    *)      bad "$1"; echo "         expected to contain: $3"; echo "         got: $2" ;;
  esac
}

assert_not_contains() {
  case "$2" in
    *"$3"*) bad "$1"; echo "         expected NOT to contain: $3"; echo "         got: $2" ;;
    *)      ok "$1" ;;
  esac
}

assert_rc() {
  if [ "$2" -eq "$3" ]; then ok "$1"; else bad "$1 (got $2, wanted $3)"; fi
}

assert_rc_nonzero() {
  if [ "$2" -ne 0 ]; then ok "$1"; else bad "$1 (got 0)"; fi
}

# --- AC1 — a cleared blocker does not hide the row ---------------------------------------------
echo "AC1 — a row whose only blocker is done is offered by ./next develop"
scaffold
add_row 0001 'A dependent row' develop ready 0000
add_item 0001 ready '["0002"]'
add_item 0002 done '[]'
seal
out="$(run_next develop)" && rc=0 || rc=$?
assert_rc "exits 0" "$rc" 0
assert_contains "offers the row" "$out" 'TAKE      0001'
assert_not_contains "does not skip it as blocked" "$out" 'SKIP'

# --- AC2 — written blocked, derived ready ------------------------------------------------------
echo "AC2 — the drift mode names a row written blocked whose blocker is done"
scaffold
add_row 0001 'A dependent row' develop blocked 0000
add_item 0001 blocked '["0002"]'
add_item 0002 done '[]'
seal
out="$(run_next --drift)" && rc=0 || rc=$?
assert_rc_nonzero "exits non-zero" "$rc"
assert_contains "names the row" "$out" '0001'
assert_contains "says the column is written blocked" "$out" 'written blocked'
assert_contains "says the graph derives it clear" "$out" 'derived ready'

# --- AC3 — written ready, derived blocked ------------------------------------------------------
echo "AC3 — the drift mode names a row written ready whose blocker is open"
scaffold
add_row 0001 'A dependent row' develop ready 0000
add_item 0001 ready '["0002"]'
add_item 0002 ready '[]'
seal
out="$(run_next --drift)" && rc=0 || rc=$?
assert_rc_nonzero "exits non-zero" "$rc"
assert_contains "names the row" "$out" '0001'
assert_contains "says the column is written ready" "$out" 'written ready'
assert_contains "says the graph derives it blocked" "$out" 'derived blocked'
assert_contains "names the open blocker" "$out" '0002'

# --- AC4 — no drift ----------------------------------------------------------------------------
# Two rows that agree, one in each direction, so a mode that simply never reports cannot pass this
# alongside AC2 and AC3.
echo "AC4 — the drift mode says so plainly and exits zero when nothing disagrees"
scaffold
add_row 0001 'An open row' develop ready 0000
add_row 0003 'A truly blocked row' develop blocked 0000
add_item 0001 ready '[]'
add_item 0003 blocked '["0002"]'
add_item 0002 ready '[]'
seal
out="$(run_next --drift)" && rc=0 || rc=$?
assert_rc "exits 0" "$rc" 0
assert_contains "says there is no drift" "$out" 'no drift'
assert_not_contains "names no row" "$out" 'DRIFT'

# --- FR1 — the column is not the authority -----------------------------------------------------
# Neither AC pins this: AC1's row already reads `ready`, so it passes against a reader that still
# treats the column as the authority. FR1 makes `blocked` derived, which means a stale `blocked`
# must not hide takeable work — the asymmetric half of the defect, the one nobody notices.
echo "FR1 — a stale blocked column does not hide a derived-ready row"
scaffold
add_row 0001 'A stale-blocked row' develop blocked 0000
add_item 0001 blocked '["0002"]'
add_item 0002 done '[]'
seal
out="$(run_next develop)" && rc=0 || rc=$?
assert_rc "exits 0" "$rc" 0
assert_contains "offers the row anyway" "$out" 'TAKE      0001'
assert_contains "flags the drift while doing so" "$out" 'DRIFT'

# --- FR2 — a genuinely open blocker is still not offered ---------------------------------------
echo "FR2 — a row with an open blocker is still skipped by ./next develop"
scaffold
add_row 0001 'A blocked row' develop ready 0000
add_item 0001 ready '["0002"]'
add_item 0002 ready '[]'
seal
out="$(run_next develop)" && rc=0 || rc=$?
assert_rc "exits 0" "$rc" 0
assert_contains "skips it" "$out" 'SKIP      0001'
assert_not_contains "offers nothing" "$out" 'TAKE'

# --- 0031 — fm_list and YAML comments ----------------------------------------------------------
# The overlap check that keeps two windows out of one file runs on these lists, so prose returned
# as a path is not cosmetic: `develop` Step 1 compares `expects:` against every in-progress
# `touches:`, and a comment or a trailing space makes a real collision compare unequal.

# One CLAIMED FILES line, whole, for the given id — asserted entire rather than by cell, so a
# stray comment or an extra space cannot hide behind a substring match.
claimed_line() { printf '%s\n' "$1" | grep "^  $2 \[" || true; }

echo "AC1 — an inline comment on a touches entry is not printed as a claimed file"
scaffold
add_row 0001 'A free row' develop ready 0000
add_row 0002 'A held row' develop in-progress 0000
add_item 0001 ready '[]'
add_item_lists 0002 in-progress '[]' "$(printf '\n  - skills/queue/templates/next # new file')"
seal
out="$(run_next develop)" && rc=0 || rc=$?
assert_rc "exits 0" "$rc" 0
assert_contains     "names the claimed path"      "$(claimed_line "$out" 0002)" 'skills/queue/templates/next'
assert_not_contains "prints no comment marker"    "$(claimed_line "$out" 0002)" '#'
assert_not_contains "prints no comment text"      "$(claimed_line "$out" 0002)" 'new file'

echo "AC2 — a # inside a quoted path is part of the path, not a comment"
scaffold
add_row 0001 'A free row' develop ready 0000
add_row 0002 'A held row' develop in-progress 0000
add_item 0001 ready '[]'
add_item_lists 0002 in-progress '[]' "$(printf '\n  - "docs/a#b.md"')"
seal
out="$(run_next develop)" && rc=0 || rc=$?
assert_rc "exits 0" "$rc" 0
assert_contains "keeps the whole path" "$(claimed_line "$out" 0002)" 'docs/a#b.md'

echo "AC3 — an entry that is only a comment yields no element"
scaffold
add_row 0001 'A free row' develop ready 0000
add_row 0002 'A held row' develop in-progress 0000
add_item 0001 ready '[]'
add_item_lists 0002 in-progress '[]' "$(printf '\n  - # just a note\n  - a/real/path.md')"
seal
out="$(run_next develop)" && rc=0 || rc=$?
assert_rc "exits 0" "$rc" 0
line="$(claimed_line "$out" 0002)"
assert_contains     "keeps the real path"    "$line" 'a/real/path.md'
assert_not_contains "drops the note"         "$line" 'just a note'
# The comment-only entry must vanish, not become an empty element: an empty element shows up as a
# doubled separator, which is invisible to a substring assertion on the path alone.
assert_not_contains "leaves no empty element" "$line" '  a/real/path.md'

echo "AC3b — a standalone comment line inside the block does not truncate the list"
scaffold
add_row 0001 'A free row' develop ready 0000
add_row 0002 'A held row' develop in-progress 0000
add_item 0001 ready '[]'
add_item_lists 0002 in-progress '[]' "$(printf '\n  - a/one.md\n  # a note about the next one\n  - a/two.md')"
seal
out="$(run_next develop)" && rc=0 || rc=$?
line="$(claimed_line "$out" 0002)"
assert_contains "keeps the entry before the note" "$line" 'a/one.md'
assert_contains "keeps the entry after the note"  "$line" 'a/two.md'

echo "AC4 — stripping a comment leaves no trailing whitespace to defeat a path comparison"
scaffold
add_row 0001 'A free row' develop ready 0000
add_row 0002 'A held row' develop in-progress 0000
add_item 0001 ready '[]'
add_item_lists 0002 in-progress '[]' "$(printf '\n  - a/one.md   # a note\n  - a/two.md')"
seal
out="$(run_next develop)" && rc=0 || rc=$?
line="$(claimed_line "$out" 0002)"
# Single space between the two paths. Untrimmed, the line reads `a/one.md   a/two.md`, which still
# contains each path — so only the join pins FR4.
assert_contains "the two paths join on one space" "$line" 'a/one.md a/two.md'

echo "AC5 — an inline comment on a blocked_by entry does not become a phantom open blocker"
scaffold
add_row 0001 'A dependent row' develop ready 0000
add_item_blocked_block 0001 ready "$(printf '\n  - "0002" # the one that has to land first')"
add_item 0002 done '[]'
seal
out="$(run_next --drift)" && rc=0 || rc=$?
assert_rc       "drift exits 0" "$rc" 0
assert_contains "reports no drift" "$out" 'no drift'
out="$(run_next develop)" && rc=0 || rc=$?
assert_rc           "develop exits 0"          "$rc" 0
assert_contains     "offers the row"           "$out" 'TAKE      0001'
assert_not_contains "invents no missing ticket" "$out" 'no item file'

# --- result -----------------------------------------------------------------------------------
echo
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
