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
# The harness runs the TEMPLATE copy below, never .claude/backlog/<script>: a mutation applied to
# the installed copy lands a real diff and reddens nothing.
NEXT_SRC="$ROOT/skills/queue/templates/next"
[ -f "$NEXT_SRC" ] || { echo "no next script at $NEXT_SRC" >&2; exit 2; }

PASS=0
FAIL=0
FIX=""

cleanup() { [ -n "$FIX" ] && rm -rf "$FIX"; return 0; }
trap cleanup EXIT INT TERM

# --- fixture ----------------------------------------------------------------------------------
# $1, optional: the header cells for a table that is NOT the canonical five, e.g.
# 'Status | ID | Owner | Next | Title'. With no argument the canonical header is written byte for
# byte as before, so every pre-0038 case scaffolds exactly the table it always did.
scaffold() {
  cleanup
  FIX="$(mktemp -d)"
  mkdir -p "$FIX/.claude/backlog/items"
  git -C "$FIX" init -q
  git -C "$FIX" config user.email test@example.invalid
  git -C "$FIX" config user.name "next test"

  {
    printf '# Backlog\n\n'
    if [ $# -eq 0 ]; then
      printf '| ID | Title | Next | Status | Parent |\n'
      printf '|------|-------|------|--------|--------|\n'
    else
      printf '| %s |\n' "$1"
      printf '%s|\n' "$(printf '%s' "$1" | awk -F'|' '{ for (i = 1; i <= NF; i++) printf "|------" }')"
    fi
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

# add_item_close_by <id> <status> <blocked_by> <close_by-line>
# The line is passed WHOLE so a case can hand in the empty string and get an item with no
# `close_by:` key at all — which is the default-reading half of 0086 AC8.
add_item_close_by() {
  cat > "$FIX/.claude/backlog/items/$1-fixture.md" <<ITEM
---
id: "$1"
title: Fixture $1
next: develop
status: $2
qa_level: unit
$4
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

# An item whose scalar `claimed_by:` carries a trailing YAML comment. `add_item_lists` writes a
# bare token, and 0031 taught only the LIST reader to strip comments — so the scalar asymmetry
# 0044 removes was never fed to this suite (0044 FR2).
#
# $1 id, $2 status, $3 the claimed_by value written verbatim, e.g. '"aa11" # mine'
add_item_commented_scalar() {
  cat > "$FIX/.claude/backlog/items/$1-fixture.md" <<ITEM
---
id: "$1"
title: Fixture $1
next: develop
status: $2
qa_level: unit
size: s   # one sitting
blocked_by: []
expects:
  - some/file.md
claimed_by: $3
claimed_at: 2026-08-24T00:00:00Z
touches:
  - held/file.md
---

## Problem
ITEM
}

# --- 0038 fixtures ----------------------------------------------------------------------------
# The helpers above hardwire `next: develop` in the frontmatter and one `expects:` entry, which the
# routing cases cannot use: `--drive` routes on the Next column and groups a gate by `parent:` and
# `expects:`, so every one of those has to vary per row.

# $1 id, $2 next, $3 status, $4 blocked_by inline (e.g. '[]'), $5 parent, $6 one expects path
add_ticket() {
  cat > "$FIX/.claude/backlog/items/$1-fixture.md" <<ITEM
---
id: "$1"
title: Fixture $1
next: $2
status: $3
qa_level: unit
size: s
parent: "$5"
blocked_by: $4
expects:
  - $6
claimed_by:
claimed_at:
touches:
---

## Problem
ITEM
}

# The same, with `expects:` written as a block so a fixture can name more than one path. A gate is
# formed by comparing those lists, so a case about how the comparison chains needs a row that
# names two files — `add_ticket`'s single path cannot express the middle of a chain (0136).
#
# $1 id, $2 next, $3 status, $4 blocked_by inline, $5 parent, $6 the expects block body — a
# leading newline then `  - ` entries.
add_ticket_expects() {
  cat > "$FIX/.claude/backlog/items/$1-fixture.md" <<ITEM
---
id: "$1"
title: Fixture $1
next: $2
status: $3
qa_level: unit
size: s
parent: "$5"
blocked_by: $4
expects:$6
claimed_by:
claimed_at:
touches:
---

## Problem
ITEM
}

# The same, carrying a live claim. A row reading `in-progress` over an item with an EMPTY
# `claimed_by:` is drift (0115 class 5, 0140's definition of *held*), so a case whose subject is
# "another session holds this row" has to scaffold the token as well — otherwise it is a case about
# drift wearing the words of a case about ownership, and since 0142 `--drive` routes it as drift.
#
# $1 id, $2 next, $3 status, $4 blocked_by inline, $5 parent, $6 one expects path, $7 the
# claimed_by value written verbatim.
add_ticket_held() {
  cat > "$FIX/.claude/backlog/items/$1-fixture.md" <<ITEM
---
id: "$1"
title: Fixture $1
next: $2
status: $3
qa_level: unit
size: s
parent: "$5"
blocked_by: $4
expects:
  - $6
claimed_by: $7
claimed_at: 2026-09-09T00:00:00Z
touches:
---

## Problem
ITEM
}

# $1 id, $2 the section body including its `## ` heading line
append_section() {
  printf '\n%s\n' "$2" >> "$FIX/.claude/backlog/items/$1-fixture.md"
}

# A project: an item with no row, `next:` blank and `status: active` — the shape a ticket takes the
# moment it gains a child and its row leaves QUEUE.md.
add_project() {
  cat > "$FIX/.claude/backlog/items/$1-fixture.md" <<ITEM
---
id: "$1"
title: Project $1
next:
status: active
qa_level: unit
size: l
blocked_by: []
---

## Problem
ITEM
}

# $1 id — one DONE.md row, so a closed ticket can be told from a vanished one.
add_done() {
  if [ ! -f "$FIX/.claude/backlog/DONE.md" ]; then
    printf '# Done\n\n| ID | Title | Type | QA | Closed | Item |\n|------|-------|------|----|--------|------|\n' \
      > "$FIX/.claude/backlog/DONE.md"
  fi
  printf '| %s | Fixture %s | feature | unit | 2026-01-01 | items/%s-fixture.md |\n' "$1" "$1" "$1" \
    >> "$FIX/.claude/backlog/DONE.md"
}

# $1 the whole findings body, appended under the preamble's `---` rule.
add_findings() {
  {
    printf '# Findings\n\nPreamble, which holds no entries.\n\n---\n\n'
    printf '%s\n' "$1"
  } > "$FIX/.claude/backlog/FINDINGS.md"
}

# $1 the threshold value, written verbatim so a case can supply a non-number.
set_threshold() {
  printf 'project: Fixture\nfindings_threshold: %s\n' "$1" > "$FIX/.claude/backlog/config.yml"
}

# One `| a | b | c |` row, cells verbatim, for a table whose columns are not the canonical five.
add_row_cells() { printf '| %s |\n' "$1" >> "$FIX/.claude/backlog/QUEUE.md"; }

seal() {
  git -C "$FIX" add -A
  git -C "$FIX" commit -q -m "fixture"
}

run_next() { (cd "$FIX" && .claude/backlog/next "$@" 2>&1); }

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

ok()  { PASS=$((PASS + 1)); echo "  ok   — $1"; }
bad() { FAIL=$((FAIL + 1)); echo "  FAIL — $1"; }

assert_contains() {
  case "$2" in
    *"$3"*) ok "$1"; saw_on_pass "$2" ;;
    *)      bad "$1"; echo "         expected to contain: $3"; saw "$2" ;;
  esac
}

assert_eq() {
  if [ "$2" = "$3" ]; then ok "$1"; saw_on_pass "$2"; else
    bad "$1"; echo "         expected exactly: $3"; saw "$2"; fi
}

assert_not_contains() {
  case "$2" in
    *"$3"*) bad "$1"; echo "         expected NOT to contain: $3"; saw "$2" ;;
    *)      ok "$1"; saw_on_pass "$2" ;;
  esac
}

# $1 label, $2 the exit code seen, $3 the code wanted, $4 optional: the output the run captured.
assert_rc() {
  seen="exit $2"
  if [ $# -ge 4 ]; then seen="$seen
$4"; fi
  if [ "$2" -eq "$3" ]; then ok "$1"; saw_on_pass "$seen"; else
    bad "$1"; saw "wanted exit $3
$seen"; fi
}

# $1 label, $2 the exit code seen, $3 optional: the output the run captured.
assert_rc_nonzero() {
  seen="exit $2"
  if [ $# -ge 3 ]; then seen="$seen
$3"; fi
  if [ "$2" -ne 0 ]; then ok "$1"; saw_on_pass "$seen"; else
    bad "$1"; saw "wanted any exit but 0
$seen"; fi
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

# ==============================================================================================
# 0038 — the --drive and --findings modes
#
# FR8's table is the specification, and every one of its rows is a fixture below. Exit codes are
# asserted alongside the printed decision on every case, because FR9 makes them the contract a
# supervisor routes on: 0 (dispatch) and 3 (run complete) are the pair that used to share one code,
# and a test asserting only the message would pass against exactly that collision.
# ==============================================================================================

# --- AC6 — the findings count and the format guard ---------------------------------------------
# `FINDINGS.md` carries two entry shapes and every count taken off the obvious `^- 2026-` grep is
# low — MEASUREMENT.md published 26 and 28 against a format-tolerant 42. The fixture holds both
# shapes in a ratio where a shape-blind count and a shape-A-only count differ, so a reader that
# sees only the bare-date shape reports 2 rather than 5 and this case fails.
echo "0038 AC6 — --findings counts both entry shapes"
scaffold
set_threshold 3
add_findings "$(printf -- '- 2026-01-02 — a bare-date entry.\n- **2026-01-03 — a bold-date entry.**\n- 2026-01-04 — another bare-date entry.\n- **2026-01-05 — another bold-date entry.**\n- **2026-01-06 — a third bold-date entry.**')"
seal
out="$(run_next --findings)" && rc=0 || rc=$?
assert_rc       "exits 0"                       "$rc" 0
assert_contains "counts all five entries"       "$out" '5'
assert_contains "names the threshold it read"   "$out" '3'
assert_not_contains "does not report the bare-date shape alone" "$out" ' 2 entries'

echo "0038 AC6 — a third entry shape fails the format guard rather than being counted silently"
scaffold
add_findings "$(printf -- '- 2026-01-02 — a bare-date entry.\n- a bullet with no date at all, which neither shape covers.')"
seal
out="$(run_next --findings)" && rc=0 || rc=$?
assert_rc       "exits 1 — the count is not trustworthy" "$rc" 1
assert_contains "names the offending line"               "$out" 'a bullet with no date at all'
assert_contains "calls it malformed"                     "$out" 'MALFORMED'

echo "0038 AC6 — the threshold defaults to retro's stated cadence when config.yml has no key"
scaffold
add_findings "$(printf -- '- 2026-01-02 — one entry.')"
seal
out="$(run_next --findings)" && rc=0 || rc=$?
assert_rc       "exits 0"                    "$rc" 0
assert_contains "defaults the threshold to 8" "$out" '8'

echo "0038 AC6 — a non-numeric threshold fails loudly rather than defaulting"
scaffold
set_threshold 'about eight'
add_findings "$(printf -- '- 2026-01-02 — one entry.')"
seal
out="$(run_next --findings)" && rc=0 || rc=$?
assert_rc       "exits 1"                       "$rc" 1
assert_contains "names the key and the value"   "$out" 'findings_threshold'


# --- 0060 — what the gate counts, and over which buffers ---------------------------------------
# The count is EVERY entry, deliberately and unchanged (0060 FR1). What made that safe is an
# invariant recorded beside `count_findings` rather than a change to it: `retro` is the terminal
# sweeper, so every entry left in the file is work a retro can still do. A marker-aware count that
# skipped dispositioned entries was rejected in design — it goes quiet exactly when deferred
# entries accumulate, which is when the gate's whole job is to be loud.

# $1 the tools.path value, written verbatim so a case can supply one that does not resolve.
set_tools_path() {
  printf 'project: Fixture\nfindings_threshold: %s\ntools:\n  path: %s\n' "${2:-8}" "$1" \
    > "$FIX/.claude/backlog/config.yml"
}

# A second checkout beside the fixture, with its own backlog buffer. $1 dir name, $2 the body.
add_tools_repo() {
  mkdir -p "$FIX/../$1/.claude/backlog"
  {
    printf '# Findings\n\nPreamble, which holds no entries.\n\n---\n\n'
    printf '%s\n' "$2"
  } > "$FIX/../$1/.claude/backlog/FINDINGS.md"
}

echo "0060 AC1 — a buffer a retro has fully dispositioned reports zero and reads as under"
scaffold
set_threshold 8
add_findings ''
seal
out="$(run_next --findings)" && rc=0 || rc=$?
assert_rc       "exits 0"                      "$rc" 0
assert_contains "reports no entries"           "$out" '0 entries'
assert_contains "and says it is under"         "$out" 'under the threshold'

# AC7 — the head token `[->NNNN]` sits between the date and the lead, so both line shapes still
# match and nothing reads as malformed. This is the regression pin for the marker's SHAPE: a
# marker written anywhere ahead of the date would break every reader of this file at once.
echo "0060 AC7 — a head-token entry counts as one and is not malformed, in both shapes"
scaffold
set_threshold 8
add_findings "$(printf -- '- 2026-09-05 [->0060] — **a bare-date entry handed over.** why it matters.\n- **2026-09-06 [->none] — a bold-date entry with no destination yet.**\n- 2026-09-07 — an unmarked entry.')"
seal
out="$(run_next --findings)" && rc=0 || rc=$?
assert_rc           "exits 0 — the token is not a third shape" "$rc" 0
assert_contains     "counts all three entries"                 "$out" '3 entries'
assert_not_contains "reports nothing malformed"                "$out" 'MALFORMED'

echo "0060 AC10 — a resolving tools.path is summed in, and each buffer is named"
scaffold
set_tools_path '../toolsrepo' 8
add_findings "$(printf -- '- 2026-09-05 — a local entry.\n- 2026-09-06 — a second local entry.')"
add_tools_repo toolsrepo "$(printf -- '- 2026-09-05 — a tools entry.\n- **2026-09-06 — a second tools entry.**\n- 2026-09-07 — a third tools entry.')"
seal
out="$(run_next --findings)" && rc=0 || rc=$?
assert_rc       "exits 0"                              "$rc" 0
assert_contains "counts both buffers — 2 + 3"          "$out" '5 entries'
assert_contains "names the local buffer's own count"   "$out" 'local 2'
assert_contains "names the tools buffer's own count"   "$out" 'tools 3'
assert_contains "and where the tools buffer was read"  "$out" 'toolsrepo'

echo "0060 AC10 — with no tools.path the count is the local buffer alone, and the line says so"
scaffold
set_threshold 8
add_findings "$(printf -- '- 2026-09-05 — a local entry.\n- 2026-09-06 — a second local entry.')"
add_tools_repo toolsrepo "$(printf -- '- 2026-09-05 — a tools entry nobody asked for.')"
seal
out="$(run_next --findings)" && rc=0 || rc=$?
assert_rc       "exits 0"                                  "$rc" 0
assert_contains "counts the local buffer alone"            "$out" '2 entries'
assert_contains "and says that is all it counted"          "$out" 'local buffer only'
assert_not_contains "does not reach a buffer no key named" "$out" 'tools 1'

# A configured path that does not resolve falls back to the local buffer and SAYS SO, rather than
# counting silently low. A gate reading low fires late and silently, which is 0038's whole reason
# for the shape guard — the same failure arriving from the resolution step instead.
echo "0060 AC10 — a tools.path that does not resolve counts local alone and names the miss"
scaffold
set_tools_path '../no-such-checkout' 8
add_findings "$(printf -- '- 2026-09-05 — a local entry.')"
seal
out="$(run_next --findings)" && rc=0 || rc=$?
assert_rc       "exits 0 — an absent sibling is not an error"  "$rc" 0
assert_contains "counts the local buffer alone"                "$out" '1 entries'
assert_contains "names the path that did not resolve"          "$out" 'no-such-checkout'
assert_contains "and says it did not resolve"                  "$out" 'did not resolve'

# The gate a driver routes on reads the same total as the line a human reads. Two counts over one
# question is the divergence this ticket opened on, in miniature: the human is told 5 and the
# driver dispatches on 2.
echo "0060 AC10 — --drive gates on the summed count, not the local buffer alone"
scaffold
set_tools_path '../toolsrepo' 4
add_findings "$(printf -- '- 2026-09-05 — a local entry.\n- 2026-09-06 — a second local entry.')"
add_tools_repo toolsrepo "$(printf -- '- 2026-09-05 — a tools entry.\n- 2026-09-06 — a second tools entry.')"
add_row 0101 'A ready ticket' develop ready ''
add_ticket 0101 develop ready '[]' '' a/one.md
seal
out="$(run_next --drive)" && rc=0 || rc=$?
assert_rc       "exits 5 — the findings gate, on 4 summed against 4" "$rc" 5
assert_contains "dispatches retro"                                   "$out" 'retro'

# A malformed entry in the TOOLS buffer is as untrustworthy as one at home, and the report has to
# say which file it was in — otherwise the fix is hunted for in the wrong repo.
echo "0060 AC10 — a malformed entry in the tools buffer fails the count and names its file"
scaffold
set_tools_path '../toolsrepo' 8
add_findings "$(printf -- '- 2026-09-05 — a local entry.')"
add_tools_repo toolsrepo "$(printf -- '- a bullet with no date at all, which neither shape covers.')"
seal
out="$(run_next --findings)" && rc=0 || rc=$?
assert_rc       "exits 1 — the count is not trustworthy" "$rc" 1
assert_contains "calls it malformed"                     "$out" 'MALFORMED'
assert_contains "names the tools buffer it was found in" "$out" 'toolsrepo'

# --- AC9 — every row of FR8's table ------------------------------------------------------------

echo "0038 AC9 — develop wrote verify/ready: dispatch verify"
scaffold
add_row 0101 'A built ticket' verify ready 0091
add_ticket 0101 verify ready '[]' 0091 a/one.md
seal
out="$(run_next --drive --completed develop:0101)" && rc=0 || rc=$?
assert_rc       "exits 0 — dispatch"  "$rc" 0
assert_contains "dispatches verify"   "$out" 'DISPATCH  verify 0101'

echo "0038 AC9 — verify closed the row into DONE.md: dispatch the next gate"
scaffold
add_row 0102 'The next ticket' develop ready 0091
add_ticket 0102 develop ready '[]' 0091 b/two.md
add_ticket 0101 verify done '[]' 0091 a/one.md
add_done 0101
seal
out="$(run_next --drive --completed verify:0101)" && rc=0 || rc=$?
assert_rc       "exits 0 — dispatch"          "$rc" 0
assert_contains "says why 0101 has no row"    "$out" 'closed'
assert_contains "dispatches the next gate"    "$out" 'DISPATCH  develop 0102'

echo "0038 AC9 — verify bounced the ticket back to develop/ready: escalate"
scaffold
add_row 0101 'A bounced ticket' develop ready 0091
add_ticket 0101 develop ready '[]' 0091 a/one.md
seal
out="$(run_next --drive --completed verify:0101)" && rc=0 || rc=$?
assert_rc           "exits 4 — escalate"        "$rc" 4
assert_contains     "escalates"                 "$out" 'ESCALATE'
assert_contains     "names the ticket"          "$out" '0101'
# The reason, not just the outcome: with the bounce branch deleted the final `else` escalates
# anyway, so rc and ESCALATE alone are green against code that has lost this FR8 row entirely.
assert_contains     "names it as the bounce"    "$out" 'bounced from verify'
assert_not_contains "dispatches nothing"        "$out" 'DISPATCH'

echo "0038 AC9 — verify found a stale contract and sent it to queue/ready: escalate"
scaffold
add_row 0101 'A stale contract' queue ready 0091
add_ticket 0101 queue ready '[]' 0091 a/one.md
seal
out="$(run_next --drive --completed verify:0101)" && rc=0 || rc=$?
assert_rc           "exits 4 — escalate"  "$rc" 4
assert_contains     "names next: queue"   "$out" 'queue'
# The substring `queue` matches the ladder's catch-all `else` too ("is at next: queue / ready
# after verify, which no routing rule covers"), so with this FR8 row deleted the three assertions
# above stay green while a fully routed state reports as one no rule covers. The wording is what
# pins the branch.
assert_contains     "names it as the stale contract" "$out" 'the contract is stale'
assert_not_contains "dispatches nothing"  "$out" 'DISPATCH'

# The loop hazard with no precedent in this suite: verify Step 7 leaves an advisory PASS at
# `next: verify, status: ready` deliberately, so a driver routing on `next:` alone re-verifies the
# same ticket forever. The assertion that matters is the absence of the dispatch, not the presence
# of the escalation — an escalation printed alongside `DISPATCH verify 0101` still loops.
echo "0038 AC9 — an advisory PASS left at verify/ready is escalated, not re-verified"
scaffold
add_row 0101 'An advisory PASS' verify ready 0091
add_ticket 0101 verify ready '[]' 0091 a/one.md
seal
out="$(run_next --drive --completed verify:0101)" && rc=0 || rc=$?
assert_rc           "exits 4 — escalate"                "$rc" 4
assert_contains     "escalates"                         "$out" 'ESCALATE'
assert_not_contains "does not print verify 0101 again"  "$out" 'DISPATCH'

echo "0038 AC9 — a row at next: design escalates; a person decides"
scaffold
add_row 0101 'An undecided ticket' design ready 0091
add_ticket 0101 design ready '[]' 0091 a/one.md
append_section 0101 '## Open design question

Should the control live in the toolbar or the sidebar?'
seal
out="$(run_next --drive)" && rc=0 || rc=$?
assert_rc       "exits 4 — escalate"          "$rc" 4
assert_contains "escalates"                   "$out" 'ESCALATE'
assert_contains "carries the design question" "$out" 'toolbar or the sidebar'

# The rank walk's own `queue` arm, which is a different branch from the phase-A one above and
# carries a different reason: there, verify sent a built ticket back and the contract is stale;
# here, a top-ranked row was never specified in the first place. Both are pinned by wording for
# the same reason — the walk's `case` ends in a `*)` that escalates with rc 4 too, so renaming
# this arm away leaves rc, `ESCALATE` and the absent `DISPATCH` all green.
echo "0038 AC9 — a row at next: queue escalates"
scaffold
add_row 0101 'An unspecified ticket' queue ready 0091
add_ticket 0101 queue ready '[]' 0091 a/one.md
seal
out="$(run_next --drive)" && rc=0 || rc=$?
assert_rc           "exits 4 — escalate" "$rc" 4
assert_contains     "escalates"          "$out" 'ESCALATE'
assert_contains     "names the missing acceptance criteria" "$out" 'no acceptance criteria to build against'
assert_not_contains "dispatches nothing" "$out" 'DISPATCH'

echo "0038 AC9 — develop handed the ticket to design: escalate carrying the open design question"
scaffold
add_row 0101 'Handed back by develop' design ready 0091
add_ticket 0101 design ready '[]' 0091 a/one.md
append_section 0101 '## Open design question

Is the threshold per project or per gate?'
seal
out="$(run_next --drive --completed develop:0101)" && rc=0 || rc=$?
assert_rc       "exits 4 — escalate"     "$rc" 4
assert_contains "carries the question"   "$out" 'per project or per gate'

echo "0038 AC9 — develop could not get the tree green and left it at develop/ready: escalate"
scaffold
add_row 0101 'A red tree' develop ready 0091
add_ticket 0101 develop ready '[]' 0091 a/one.md
seal
out="$(run_next --drive --completed develop:0101)" && rc=0 || rc=$?
assert_rc           "exits 4 — escalate"  "$rc" 4
assert_contains     "escalates"           "$out" 'ESCALATE'
# Routed by the same-stage branch, and pinned by its wording for the same reason as the two above:
# with `elif [ "$lnext" = "$lstage" ]` deleted the ladder's final `else` escalates with rc 4 too,
# so this case reports ok three times against code that has lost the branch entirely.
assert_contains     "names it as the same stage twice" "$out" 'same ticket, same stage'
assert_not_contains "dispatches nothing"  "$out" 'DISPATCH'

echo "0038 AC9 — develop left the ticket waiting: escalate carrying the Waiting on question"
scaffold
add_row 0101 'Waiting on a person' develop waiting 0091
add_ticket 0101 develop waiting '[]' 0091 a/one.md
append_section 0101 '## Waiting on

Aaron — which of the two hosts holds the credential?'
seal
out="$(run_next --drive --completed develop:0101)" && rc=0 || rc=$?
assert_rc       "exits 4 — escalate"          "$rc" 4
assert_contains "carries the waiting question" "$out" 'which of the two hosts'

# The same routing decision reached down the other code path. `develop` writing `waiting` is
# routed by the completed-outcome ladder above; a `waiting` row that simply outranks everything
# below it is routed by the rank walk, and only that branch stops a driver from dispatching a
# stage onto a row whose whole state is that a person has been asked a question. Assert the
# absent DISPATCH, not just the present ESCALATE: with the branch deleted the walk falls through
# to the row beneath and `ESCALATE` is merely missing rather than wrong.
echo "0038 AC9 — a waiting top row outranks the rank walk: escalate, with no completed outcome"
scaffold
add_row 0101 'Waiting on a person' develop waiting 0091
add_row 0102 'Takeable underneath' develop ready 0092
add_ticket 0101 develop waiting '[]' 0091 a/one.md
add_ticket 0102 develop ready '[]' 0092 b/two.md
append_section 0101 '## Waiting on

Aaron — which of the two hosts holds the credential?'
seal
out="$(run_next --drive)" && rc=0 || rc=$?
assert_rc           "exits 4 — escalate"           "$rc" 4
assert_contains     "escalates"                    "$out" 'ESCALATE'
assert_contains     "carries the waiting question" "$out" 'which of the two hosts'
assert_not_contains "dispatches nothing"           "$out" 'DISPATCH'

# The column reads `blocked` alongside the new entry, which is what makes this a case about
# RE-DERIVATION rather than about drift: since 0142 a row left at `ready` over an open blocker is
# reported as the stale cache it is and stops the driver, so scaffolding it that way here would
# test that instead, and this branch — the NOTE that reads a new blocker as re-derivable rather
# than as stuck — would never be reached again.
echo "0038 AC9 — develop gave the ticket a blocked_by: re-derive and take the next takeable row"
scaffold
add_row 0101 'Newly blocked' develop blocked 0091
add_row 0102 'Still takeable' develop ready 0092
add_ticket 0101 develop blocked '["0199"]' 0091 a/one.md
add_ticket 0102 develop ready '[]' 0092 b/two.md
add_ticket 0199 develop ready '[]' 0093 c/three.md
seal
out="$(run_next --drive --completed develop:0101)" && rc=0 || rc=$?
assert_rc       "exits 0 — dispatch"            "$rc" 0
assert_contains "says 0101 gained a blocker"    "$out" '0101'
assert_contains "dispatches the next row"       "$out" 'DISPATCH  develop 0102'

# 0024's property, and 0142 splits it by reader. The graph is still the authority and the column
# still only caches it — `./next develop` offers the row exactly as it always did. What changed is
# the DRIVER: a stale cache is drift, and since 0142 a driver stops on it rather than quietly
# re-deriving, because the driver is the reader that has a person to ask. Both halves are asserted
# here, because either alone reads as the whole rule.
echo "0038 AC9 / 0142 — a dependent whose close was never reconciled: offered to a session, drift to a driver"
scaffold
add_row 0102 'A stale blocked column' develop blocked 0092
add_ticket 0102 develop blocked '["0101"]' 0092 b/two.md
add_ticket 0101 develop done '[]' 0091 a/one.md
seal
out="$(run_next develop)" && rc=0 || rc=$?
assert_rc       "./next develop still exits 0"       "$rc" 0 "$out"
assert_contains "and still offers the re-derived row" "$out" 'TAKE      0102'
out="$(run_next --drive)" && rc=0 || rc=$?
assert_rc           "--drive escalates on the stale cache" "$rc" 4 "$out"
assert_contains     "naming the row"                       "$out" 'DRIFT     0102'
assert_not_contains "and dispatching nothing"              "$out" 'DISPATCH'

echo "0038 AC9 — a ticket that became a project left QUEUE.md: not an error and not a loop"
scaffold
add_row 0102 'A child slice' develop ready 0101
add_ticket 0102 develop ready '[]' 0101 b/two.md
add_project 0101
seal
out="$(run_next --drive --completed develop:0101)" && rc=0 || rc=$?
assert_rc           "exits 0 — dispatch"           "$rc" 0
assert_not_contains "does not escalate"            "$out" 'ESCALATE'
assert_contains     "says it became a project"     "$out" 'project'
assert_contains     "dispatches the child slice"   "$out" 'DISPATCH  develop 0102'

echo "0038 AC9 — nothing takeable at develop is run complete, not an escalation"
scaffold
add_row 0102 'Genuinely blocked' develop blocked 0092
add_ticket 0102 develop blocked '["0199"]' 0092 b/two.md
add_ticket 0199 develop ready '[]' 0093 c/three.md
seal
out="$(run_next --drive)" && rc=0 || rc=$?
assert_rc           "exits 3 — run complete" "$rc" 3
assert_contains     "says the run is complete" "$out" 'COMPLETE'
assert_not_contains "does not escalate"        "$out" 'ESCALATE'
assert_not_contains "dispatches nothing"       "$out" 'DISPATCH'

# The general form of the advisory-PASS loop, and the half that stops a naive guard from breaking
# crash recovery: a supervisor killed after dispatch but before the stage claimed leaves the row
# `ready`, and re-deriving must dispatch it rather than escalate. So the guard needs the completed
# outcome, and the same backlog routes two different ways depending on whether one is supplied.
echo "0038 AC9 — the same stage twice needs a completed outcome in between"
scaffold
add_row 0101 'Reached verify twice' verify ready 0091
add_ticket 0101 verify ready '[]' 0091 a/one.md
seal
out="$(run_next --drive --completed verify:0101)" && rc=0 || rc=$?
assert_rc       "with an outcome supplied, exits 4" "$rc" 4
assert_contains "escalates"                          "$out" 'ESCALATE'
assert_contains "names the guard, not the fallback"  "$out" 'same ticket, same stage'
out="$(run_next --drive)" && rc=0 || rc=$?
assert_rc       "with no outcome supplied, exits 0"  "$rc" 0
assert_contains "dispatches rather than escalating"  "$out" 'DISPATCH  verify 0101'

# --- AC10 — anything unrecognised stops -------------------------------------------------------
echo "0038 AC10 — a state matching no routing rule escalates rather than falling through"
scaffold
add_row 0101 'An unknown stage' frobnicate ready 0091
add_ticket 0101 frobnicate ready '[]' 0091 a/one.md
seal
out="$(run_next --drive)" && rc=0 || rc=$?
assert_rc           "exits 4 — escalate"      "$rc" 4
assert_contains     "names the unknown stage" "$out" 'frobnicate'
assert_not_contains "dispatches nothing"      "$out" 'DISPATCH'

echo "0038 AC10 — a completed ticket with neither a row nor an item file escalates"
scaffold
add_row 0102 'A takeable row' develop ready 0092
add_ticket 0102 develop ready '[]' 0092 b/two.md
seal
out="$(run_next --drive --completed develop:0101)" && rc=0 || rc=$?
assert_rc       "exits 4 — escalate" "$rc" 4
assert_contains "names the ticket"   "$out" '0101'

# --- AC11 — the exit codes are the named ones, and both modes are documented -------------------
echo "0038 AC11 — --help lists both new modes"
scaffold
seal
out="$(run_next --help)" && rc=0 || rc=$?
assert_rc       "exits 0"        "$rc" 0
# Anchored to each mode's own line in the listing, never to the bare flag: `--drive` also appears
# in the trailing paragraph explaining the exit codes, so `assert_contains '--drive'` is satisfied
# by prose while `usage()` documents no such mode — a user running --help cannot then discover it
# exists (`testing-conventions.md`, anchor an assertion to the claim, not to the document that
# contains it). The `--findings` twin was genuine when written and carries the same defect shape.
assert_contains "lists --drive as a mode"    "$out" './next --drive'
assert_contains "lists --findings as a mode" "$out" './next --findings'

echo "0038 AC11 — the findings gate has its own code, distinct from a dispatch"
scaffold
set_threshold 2
add_row 0101 'A takeable row' develop ready 0091
add_ticket 0101 develop ready '[]' 0091 a/one.md
add_findings "$(printf -- '- 2026-01-02 — one entry.\n- **2026-01-03 — two entries.**')"
seal
out="$(run_next --drive)" && rc=0 || rc=$?
assert_rc       "exits 5 — the findings gate" "$rc" 5
assert_contains "dispatches retro"            "$out" 'retro'
assert_contains "states the count"            "$out" '2'

# `findings_gate` carries its own shape check, on a different code path from `--findings` mode's:
# AC6's guard fixture exercises the reporting path and reaches none of this. Ungated, a driver
# proceeds on a count the script has already established is low, which is this ticket's Problem
# section arriving through the driver rather than the reporting path.
echo "0038 AC11 — --drive escalates rather than dispatching on a FINDINGS.md shape it cannot count"
scaffold
set_threshold 8
add_row 0101 'A takeable row' develop ready 0091
add_ticket 0101 develop ready '[]' 0091 a/one.md
add_findings "$(printf -- '- 2026-01-02 — a bare-date entry.\n- a bullet with no date at all, which neither shape covers.')"
seal
out="$(run_next --drive)" && rc=0 || rc=$?
assert_rc           "exits 4 — escalate"                  "$rc" 4
assert_contains     "names the unrecognised shape"        "$out" 'an entry shape the count does not recognise'
assert_contains     "points at the offending line"        "$out" 'MALFORMED'
assert_not_contains "dispatches nothing on a bad count"   "$out" 'DISPATCH'

# `--completed <stage>` with no id is the form `usage` documents as `[:<id>]` optional — a stage
# that finished owing no ticket of its own. Ungated, a continuable run stops and asks a person,
# and the message it stops with carries a blank where the ticket id should be.
echo "0038 AC11 — a completed stage with no ticket of its own chooses the next gate"
scaffold
add_row 0101 'A takeable row' develop ready 0091
add_ticket 0101 develop ready '[]' 0091 a/one.md
seal
out="$(run_next --drive --completed develop)" && rc=0 || rc=$?
assert_rc       "exits 0 — dispatch"                "$rc" 0
assert_contains "says the stage owed no ticket"     "$out" 'finished with no ticket of its own'
assert_contains "and dispatches the next gate"      "$out" 'DISPATCH  develop 0101'

# Every pre-existing invocation keeps the code it always returned. `next <stage>` spending 0 on
# "nothing is takeable" is the collision --drive exists to avoid, and it must NOT be corrected
# here: three closed tickets and two scripts read that 0.
echo "0038 AC11 — the pre-existing exit codes are unchanged"
scaffold
add_row 0101 'A verify row' verify ready 0091
add_ticket 0101 verify ready '[]' 0091 a/one.md
seal
out="$(run_next develop)" && rc=0 || rc=$?
assert_rc       "next <stage> still spends 0 on nothing takeable" "$rc" 0
assert_contains "and still says so"  "$out" 'nothing is takeable at stage develop'
out="$(run_next --waiting)" && rc=0 || rc=$?
assert_rc "next --waiting still exits 0 when nothing waits" "$rc" 0
out="$(run_next --drift)" && rc=0 || rc=$?
assert_rc "next --drift still exits 0 when nothing drifted" "$rc" 0
out="$(run_next frobnicate)" && rc=0 || rc=$?
assert_rc "an unknown stage is still a usage error" "$rc" 2
out="$(run_next)" && rc=0 || rc=$?
assert_rc "the no-argument summary still exits 0" "$rc" 0
assert_contains "and still prints the summary" "$out" 'BY STAGE:'

echo "0038 AC11 — --drive rejects an argument it does not know as a usage error"
scaffold
add_row 0101 'A verify row' verify ready 0091
add_ticket 0101 verify ready '[]' 0091 a/one.md
seal
out="$(run_next --drive --frobnicate)" && rc=0 || rc=$?
assert_rc "exits 2 — usage" "$rc" 2
out="$(run_next --drive --completed)" && rc=0 || rc=$?
assert_rc "a --completed with no value is a usage error" "$rc" 2
# The guard needs an intervening outcome, not a history. Accepting a list while reading one element
# of it is a trap for the caller, so a second is refused rather than silently dropped.
out="$(run_next --drive --completed develop:0101 --completed verify:0101)" && rc=0 || rc=$?
assert_rc       "a second --completed is a usage error" "$rc" 2
assert_contains "and says which one it refused"         "$out" 'verify:0101'

# --- AC28 — the new modes survive a column move -----------------------------------------------
# 0006 exists because the pre-existing modes read fixed indices and report wrong values when a
# column moves. This table reorders every column AND adds one the script has never heard of, so an
# index-based reader cannot pass by luck.
echo "0038 AC28 — a reordered table with an extra column gives the same decision"
scaffold 'Status | Owner | ID | Next | Title'
add_row_cells 'ready | nobody | 0101 | verify | A built ticket'
add_ticket 0101 verify ready '[]' 0091 a/one.md
seal
out="$(run_next --drive)" && rc=0 || rc=$?
assert_rc       "exits 0 — the same decision as the canonical shape" "$rc" 0
assert_contains "dispatches verify"  "$out" 'DISPATCH  verify 0101'

echo "0038 AC28 — a table with no Status column fails loudly"
scaffold 'ID | Title | Next | Parent'
add_row_cells '0101 | A built ticket | verify | 0091'
add_ticket 0101 verify ready '[]' 0091 a/one.md
seal
out="$(run_next --drive)" && rc=0 || rc=$?
assert_rc           "exits 1 — malformed"        "$rc" 1
assert_contains     "names the missing column"   "$out" 'Status'
assert_not_contains "reads no row as takeable"   "$out" 'DISPATCH'

# --- AC29 — one read answers depth as well as the decision ------------------------------------
# Two gates rather than two rows: 0101 and 0102 share neither a parent nor a path in `expects:`, so
# they cannot batch, and the design row below them is what the run would halt on.
echo "0038 AC29 — one invocation reports the decision and how deep the backlog is"
scaffold
add_row 0101 'First gate'  develop ready 0091
add_row 0102 'Second gate' develop ready 0092
add_row 0103 'Undecided'   design  ready 0093
add_ticket 0101 develop ready '[]' 0091 a/one.md
add_ticket 0102 develop ready '[]' 0092 b/two.md
add_ticket 0103 design  ready '[]' 0093 c/three.md
append_section 0103 '## Open design question

Where does the control live?'
seal
out="$(run_next --drive)" && rc=0 || rc=$?
assert_rc       "exits 0 — dispatch"                 "$rc" 0
assert_contains "dispatches the first gate"          "$out" 'DISPATCH  develop 0101'
assert_contains "reports the depth"                  "$out" 'DEPTH     2'
assert_contains "names what the run would halt on"   "$out" '0103'
# The id alone does not pin `depth_stopper`'s design|queue arm: with that arm deleted the row
# falls to the unknown-next arm, which prints the same id and a different reason. AC29 asks for
# what stops it, so assert the reason (`testing-conventions.md`, pin a ladder arm by its wording).
assert_contains "and why it halts there"             "$out" "0103 (next: design — a person decides)"

# --- AC29 — the stopper's other arms, each pinned by its wording rather than by the id ---------
echo "0038 AC29 — the depth line halts on a waiting row and says a person holds it"
scaffold
add_row 0101 'A takeable row' develop ready    0091
add_row 0102 'Held for an answer' develop waiting 0092
add_ticket 0101 develop ready   '[]' 0091 a/one.md
add_ticket 0102 develop waiting '[]' 0092 b/two.md
seal
out="$(run_next --drive)" && rc=0 || rc=$?
assert_rc       "exits 0 — dispatch"                    "$rc" 0
assert_contains "the waiting row is not a takeable gate" "$out" 'DEPTH     1'
assert_contains "and it is what the run runs dry at"     "$out" '0102 (waiting on a person)'

echo "0038 AC29 — the depth line halts on a next: value no rule covers, and says so"
scaffold
add_row 0101 'A takeable row' develop     ready 0091
add_row 0102 'An unknown stage' frobnicate ready 0092
add_ticket 0101 develop    ready '[]' 0091 a/one.md
add_ticket 0102 frobnicate ready '[]' 0092 b/two.md
seal
out="$(run_next --drive)" && rc=0 || rc=$?
assert_rc       "exits 0 — dispatch"               "$rc" 0
assert_contains "names the unroutable stage as the stopper" "$out" "0102 (next: 'frobnicate' — no routing rule covers it)"

echo "0038 AC29 — a queue nothing halts on runs dry at its end rather than at a row"
scaffold
add_row 0101 'A takeable row' develop ready 0091
add_row 0102 'A verify row'   verify  ready 0092
add_ticket 0101 develop ready '[]' 0091 a/one.md
add_ticket 0102 verify  ready '[]' 0092 b/two.md
seal
out="$(run_next --drive)" && rc=0 || rc=$?
assert_rc       "exits 0 — dispatch"          "$rc" 0
assert_contains "runs dry at the end, not at a row" "$out" 'runs dry at the end of the queue'

# `depth_stopper` steps over exactly what the rank walk steps over — in-progress and blocked.
# Without these two cases either skip can be deleted and the line then halts on a row no person
# is being asked anything about, naming it as the thing that stops the run.
echo "0038 AC29 — the depth line steps over an in-progress row rather than halting on it"
scaffold
add_row 0101 'A takeable row'    develop ready       0091
add_row 0102 'Held by a session' design  in-progress 0092
add_row 0103 'The real stopper'  design  ready       0093
add_ticket 0101 develop ready       '[]' 0091 a/one.md
add_ticket_held 0102 design in-progress '[]' 0092 b/two.md '"tok9"'
add_ticket 0103 design  ready       '[]' 0093 c/three.md
seal
out="$(run_next --drive)" && rc=0 || rc=$?
assert_rc           "exits 0 — dispatch"                     "$rc" 0
assert_contains     "halts on the row a person can act on"   "$out" 'runs dry at 0103'
assert_not_contains "not on the one another session holds"   "$out" 'runs dry at 0102'

echo "0038 AC29 — the depth line steps over a blocked row rather than halting on it"
scaffold
add_row 0101 'A takeable row'   develop ready   0091
add_row 0102 'Still blocked'    design  blocked 0092
add_row 0103 'The real stopper' design  ready   0093
add_row 0090 'The open blocker' verify  ready   0090
add_ticket 0101 develop ready   '[]'       0091 a/one.md
add_ticket 0102 design  blocked '["0090"]' 0092 b/two.md
add_ticket 0103 design  ready   '[]'       0093 c/three.md
add_ticket 0090 verify  ready   '[]'       0090 d/four.md
seal
out="$(run_next --drive)" && rc=0 || rc=$?
assert_rc           "exits 0 — dispatch"                   "$rc" 0
assert_contains     "halts on the row nothing blocks"      "$out" 'runs dry at 0103'
assert_not_contains "not on the one still blocked"         "$out" 'runs dry at 0102'

# The gate count is the other half of AC29, and the pool it counts is filtered three ways. A row
# another session holds, a row waiting on a person and a row still blocked are all rows this run
# cannot take, so counting any of them reports a depth the driver cannot actually spend.
echo "0038 AC29 — in-progress and waiting rows are not counted as takeable gates"
scaffold
add_row 0101 'A takeable row'    develop ready       0091
add_row 0102 'Held by a session' develop in-progress 0092
add_row 0103 'Held for an answer' develop waiting    0093
add_ticket 0101 develop ready       '[]' 0091 a/one.md
add_ticket_held 0102 develop in-progress '[]' 0092 b/two.md '"tok9"'
add_ticket 0103 develop waiting     '[]' 0093 c/three.md
seal
out="$(run_next --drive)" && rc=0 || rc=$?
assert_rc       "exits 0 — dispatch"               "$rc" 0
assert_contains "counts only the row this run can take" "$out" 'DEPTH     1'

echo "0038 AC29 — a blocked row is not counted as a takeable gate"
scaffold
add_row 0101 'A takeable row'   develop ready   0091
add_row 0102 'Still blocked'    develop blocked 0092
add_row 0090 'The open blocker' verify  ready   0090
add_ticket 0101 develop ready   '[]'       0091 a/one.md
add_ticket 0102 develop blocked '["0090"]' 0092 b/two.md
add_ticket 0090 verify  ready   '[]'       0090 d/four.md
seal
out="$(run_next --drive)" && rc=0 || rc=$?
assert_rc       "exits 0 — dispatch"                     "$rc" 0
assert_contains "counts only the row nothing blocks"     "$out" 'DEPTH     1'

echo "0038 FR8 — tickets sharing a parent are one gate, dispatched together"
scaffold
add_row 0101 'First slice'  develop ready 0091
add_row 0102 'Second slice' develop ready 0091
add_ticket 0101 develop ready '[]' 0091 a/one.md
add_ticket 0102 develop ready '[]' 0091 b/two.md
seal
out="$(run_next --drive)" && rc=0 || rc=$?
assert_rc       "exits 0 — dispatch"       "$rc" 0
assert_contains "dispatches both as one gate" "$out" 'DISPATCH  develop 0101 0102'
assert_contains "counts one gate deep"        "$out" 'DEPTH     1'

echo "0038 FR8 — tickets whose expects overlap are one gate even under different parents"
scaffold
add_row 0101 'One file'      develop ready 0091
add_row 0102 'The same file' develop ready 0092
add_ticket 0101 develop ready '[]' 0091 shared/file.md
add_ticket 0102 develop ready '[]' 0092 shared/file.md
seal
out="$(run_next --drive)" && rc=0 || rc=$?
assert_rc       "exits 0 — dispatch"          "$rc" 0
assert_contains "dispatches both as one gate" "$out" 'DISPATCH  develop 0101 0102'

# --- 0136 — a gate is disjoint from every other gate, not just from its own lead --------------
# The discriminating fixture: 0102 shares `shared/one.md` with the lead and `shared/two.md` with
# 0103, while 0103 shares nothing with the lead. Testing each candidate against the LEAD's
# `expects:` puts 0102 in and leaves 0103 to form a second gate that collides with the first;
# testing against the gate's ACCUMULATED scope pulls 0103 in too. A fixture where the third row
# overlaps the lead cannot tell the two rules apart.
echo "0136 AC1 — a row overlapping a non-lead member joins that member's gate"
scaffold
add_row 0101 'The lead'       develop ready 0091
add_row 0102 'Shares both'    develop ready 0092
add_row 0103 'Shares the second only' develop ready 0093
add_ticket         0101 develop ready '[]' 0091 shared/one.md
add_ticket_expects 0102 develop ready '[]' 0092 '
  - shared/one.md
  - shared/two.md'
add_ticket         0103 develop ready '[]' 0093 shared/two.md
seal
out="$(run_next --drive)" && rc=0 || rc=$?
assert_rc       "exits 0 — dispatch"                        "$rc" 0
assert_contains "dispatches all three as one gate"          "$out" 'DISPATCH  develop 0101 0102 0103'
assert_contains "and counts one takeable gate"              "$out" 'DEPTH     1'

# AC3's negative: accumulation with no termination condition merges everything reachable, and the
# rows below are not reachable from each other at all. Without this case the fix could be written
# as a transitive closure over the whole pool and stay green.
echo "0136 AC3 — rows sharing no file are still two gates"
scaffold
add_row 0101 'First gate'  develop ready 0091
add_row 0102 'Second gate' develop ready 0092
add_ticket 0101 develop ready '[]' 0091 a/one.md
add_ticket 0102 develop ready '[]' 0092 b/two.md
seal
out="$(run_next --drive)" && rc=0 || rc=$?
assert_rc           "exits 0 — dispatch"                "$rc" 0
assert_contains     "dispatches the first row"          "$out" 'DISPATCH  develop 0101'
assert_not_contains "and does not batch the second with it" "$out" '0101 0102'
assert_contains     "and counts two takeable gates"     "$out" 'DEPTH     2'

# The *other* in-progress branch. This one and the case below are two different code paths, the
# same way AC9's two waiting cases are: with a completed outcome supplied, `--drive` reads the row
# the stage just finished (phase A) and a row still in-progress there means the stage never
# released its claim; with none supplied, it walks the rank and steps such a row over as another
# session's. Not an FR8 row, so it owes no AC — but it was the last branch in the ladder with no
# fixture, and the wording is the only thing that pins it: with the branch deleted the final `else`
# escalates too, so rc 4 and ESCALATE alone stay green.
echo "0038 FR8 — a completed stage that never released its claim: escalate"
scaffold
add_row 0101 'Still held' verify in-progress 0091
add_ticket_held 0101 verify in-progress '[]' 0091 a/one.md '"tok9"'
seal
out="$(run_next --drive --completed develop:0101)" && rc=0 || rc=$?
assert_rc           "exits 4 — escalate"              "$rc" 4
assert_contains     "escalates"                       "$out" 'ESCALATE'
assert_contains     "names the unreleased claim"      "$out" 'the claim was never released'
assert_not_contains "dispatches nothing"              "$out" 'DISPATCH'

echo "0038 FR8 — an in-progress row is stepped over, not taken"
scaffold
add_row 0101 'Held by another session' develop in-progress 0091
add_row 0102 'Free'                    develop ready       0092
add_ticket_held 0101 develop in-progress '[]' 0091 a/one.md '"tok9"'
add_ticket 0102 develop ready '[]' 0092 b/two.md
seal
out="$(run_next --drive)" && rc=0 || rc=$?
assert_rc       "exits 0 — dispatch"        "$rc" 0
assert_contains "names the held row"        "$out" '0101'
assert_contains "dispatches the free row"   "$out" 'DISPATCH  develop 0102'

# --- 0044 AC2 — a scalar frontmatter value carrying a trailing comment --------------------------
# `fm()` took everything after `key:` and stripped only surrounding quotes, so an annotated token
# came back as `aa11" # mine`. `close` compares that string against the token it is given before it
# will close anything, and this is the reader both scripts share the shape of.
echo "0044 AC2 — a commented scalar reads as its bare value"
scaffold
add_row 0001 'A free row' develop ready 0000
add_row 0002 'Held with an annotated token' develop in-progress 0000
add_item 0001 ready '[]'
add_item_commented_scalar 0002 in-progress '"aa11" # minted this session'
seal
out="$(run_next develop)" && rc=0 || rc=$?
assert_rc "exits 0" "$rc" 0
assert_contains "prints the bare token" "$out" '0002 [aa11]'
assert_not_contains "not the comment with it" "$out" '#'

# The take line reads `size:` and `qa_level:` through the same scalar reader, so the defect is
# pinned on the row being offered too — not only on the held row's token.
echo "0044 AC2 — and the offered row's own scalars are read the same way"
scaffold
add_row 0003 'A free row with annotated frontmatter' develop ready 0000
add_item_commented_scalar 0003 ready ''
seal
out="$(run_next develop)" && rc=0 || rc=$?
assert_rc "exits 0" "$rc" 0
assert_contains "offers the row" "$out" 'TAKE      0003'
assert_contains "the size is read without its comment" "$out" 'size s | qa unit'
assert_not_contains "no comment reaches the take line" "$out" '#'

# --- 0045 — the take loop crosses itself against the held file set ------------------------------
# `./next <stage>` printed TAKE on a row whose `expects:` was held by another session and printed
# the proof four lines below, in the same output. The loop filtered on stage, `blocked_by` and the
# Status column; `show_claimed` ran afterward and independently, and neither consulted the other.
#
# The collision cases need `expects:` and `touches:` to vary independently per row, which no
# earlier helper offers: `add_ticket` hardwires an empty `touches:`, and `add_item_lists` hardwires
# the same one-line `expects:` on every row it writes.
#
# $1 id, $2 next, $3 status, $4 one expects path, $5 the touches block body — a leading newline
# then `  - ` entries, or empty for none — $6 claimed_by written verbatim, e.g. '"aa11"' or empty.
add_item_scope() {
  cat > "$FIX/.claude/backlog/items/$1-fixture.md" <<ITEM
---
id: "$1"
title: Fixture $1
next: $2
status: $3
qa_level: unit
size: s
parent:
blocked_by: []
expects:
  - $4
claimed_by: $6
claimed_at: 2026-08-24T00:00:00Z
touches:$5
---

## Problem
ITEM
}

# A held row that declares neither field, so the fallback has nothing to fall back to. Written as
# its own helper rather than as `add_item_scope` with an empty path, because `  - ` with nothing
# after it is a list entry, not an absent list, and the two read differently to `fm_list`.
#
# $1 id, $2 next, $3 status
add_item_blank_scope() {
  cat > "$FIX/.claude/backlog/items/$1-fixture.md" <<ITEM
---
id: "$1"
title: Fixture $1
next: $2
status: $3
qa_level: unit
size: s
parent:
blocked_by: []
expects:
claimed_by: "bb22"
claimed_at: 2026-08-24T00:00:00Z
touches:
---

## Problem
ITEM
}

# One COLLIDES line, whole, for the given id — asserted entire for the same reason `claimed_line`
# is: the row, the path and the holder have to appear on one line to be the report FR3 asks for,
# and three separate substring matches over the whole output would pass on three unrelated lines.
collides_line() { printf '%s\n' "$1" | grep "^COLLIDES  $2 " || true; }

# The fixture AC1, AC2 and AC3 all read: a colliding top row, a clear row below it, one holder.
scope_fixture() {
  scaffold
  add_row 0001 'Topmost, and colliding' develop ready 0000
  add_row 0002 'Lower, and clear' develop ready 0000
  add_row 0003 'Held by another session' develop in-progress 0000
  add_item_scope 0001 develop ready     shared/file.md '' ''
  add_item_scope 0002 develop ready     free/file.md   '' ''
  add_item_scope 0003 develop in-progress other/file.md "$(printf '\n  - shared/file.md')" '"aa11"'
  seal
}

echo "0045 AC1 — a row whose expects intersects a held touches is not offered"
scope_fixture
out="$(run_next develop)" && rc=0 || rc=$?
assert_rc "exits 0" "$rc" 0
assert_not_contains "no TAKE on the colliding top row" "$out" 'TAKE      0001'

echo "0045 AC2 — the walk continues to the first row that is clear"
scope_fixture
out="$(run_next develop)" && rc=0 || rc=$?
assert_contains "offers the lower clear row" "$out" 'TAKE      0002'
assert_contains "with its own expects"       "$out" 'EXPECTS   free/file.md'

echo "0045 AC3 — the row stepped over is reported with the path and the holder"
scope_fixture
out="$(run_next develop)" && rc=0 || rc=$?
line="$(collides_line "$out" 0001)"
assert_contains "names the row stepped over" "$line" 'COLLIDES  0001'
assert_contains "names the intersecting path" "$line" 'shared/file.md'
assert_contains "names the row that holds it" "$line" '0003'
# The path that does NOT intersect must not be reported as the reason — a report naming every path
# either row declares is not a report of the collision.
assert_not_contains "does not name the holder's other file" "$line" 'other/file.md'

echo "0045 AC4 — every row colliding reads differently from an empty stage"
scaffold
add_row 0001 'The only develop row, and colliding' develop ready 0000
add_row 0003 'Held by another session' develop in-progress 0000
add_item_scope 0001 develop ready     shared/file.md '' ''
add_item_scope 0003 develop in-progress other/file.md "$(printf '\n  - shared/file.md')" '"aa11"'
seal
out="$(run_next develop)" && rc=0 || rc=$?
assert_rc "exits 0" "$rc" 0
assert_contains     "says the stage is held, not empty" "$out" 'every takeable develop row collides'
assert_not_contains "not the empty-stage wording"       "$out" 'nothing is takeable at stage develop'

echo "0045 AC5 — a held row with no touches falls back to its expects, labelled predicted"
scaffold
add_row 0001 'A free row' develop ready 0000
add_row 0002 'Held, nothing declared' develop in-progress 0000
add_item_scope 0001 develop ready       free/file.md    '' ''
add_item_scope 0002 develop in-progress guessed/file.md '' '"aa11"'
seal
out="$(run_next develop)" && rc=0 || rc=$?
line="$(claimed_line "$out" 0002)"
assert_contains "falls back to the expects entry" "$line" 'guessed/file.md'
assert_contains "labels it as the weaker field"   "$line" 'predicted'
assert_contains "and still says to ask"           "$line" 'assume held, ask'
assert_contains "the free row is still offered"   "$out" 'TAKE      0001'

# The fallback is a display, not a claim, and the case above does not pin that: its free row shares
# no path with the held row under either field, so widening the held set to `touches: + expects:`
# leaves it green. This one separates them — the candidate collides with the held row's PREDICTED
# scope and with nothing it has actually claimed — because which field the filter reads is a real
# decision (0045 FR1) and a wider one would refuse rows on a guess nobody checked against the code.
echo "0045 FR1 — the filter reads touches, not the held row's predicted expects"
scaffold
add_row 0001 'Colliding with a prediction only' develop ready 0000
add_row 0002 'Held, nothing declared' develop in-progress 0000
add_item_scope 0001 develop ready       guessed/file.md '' ''
add_item_scope 0002 develop in-progress guessed/file.md '' '"aa11"'
seal
out="$(run_next develop)" && rc=0 || rc=$?
assert_contains     "the row is offered"                 "$out" 'TAKE      0001'
assert_not_contains "and not refused on the prediction"  "$out" 'COLLIDES  0001'
assert_contains     "the prediction is still surfaced"   "$(claimed_line "$out" 0002)" 'predicted'

echo "0045 AC5 — a held row with neither field keeps the original wording"
scaffold
add_row 0001 'A free row' develop ready 0000
add_row 0002 'Held, and declaring nothing at all' develop in-progress 0000
add_item_scope 0001 develop ready free/file.md '' ''
add_item_blank_scope 0002 develop in-progress
seal
out="$(run_next develop)" && rc=0 || rc=$?
line="$(claimed_line "$out" 0002)"
assert_contains "still says nothing is declared" "$line" 'none declared — assume held, ask'

echo "0045 AC6 — the held set is not filtered by stage: a verify claim counts"
scaffold
add_row 0001 'A develop row' develop ready 0000
add_row 0002 'Held at verify' verify in-progress 0000
add_item_scope 0001 develop ready      shared/file.md '' ''
add_item_scope 0002 verify in-progress other/file.md "$(printf '\n  - shared/file.md')" '"aa11"'
seal
out="$(run_next develop)" && rc=0 || rc=$?
assert_not_contains "no TAKE across a live verify claim" "$out" 'TAKE      0001'
assert_contains     "and the collision is reported"      "$out" 'COLLIDES  0001'


# --- 0067 AC5/AC6 — an exclusive claim collides with every row ---------------------------------
# `touches: "*"` is how a cross-cutting change declares that it holds the whole tree
# (references/CONCURRENCY.md, *A change that touches every file takes an exclusive claim*). Before
# this, `paths_shared` matched path words exactly, so a `"*"` entry collided with nothing at all and
# the change was invisible to the one mechanism that reports scope.
#
# AC5 and AC6 are a PAIR on purpose: the second is what proves the first is testing HELDNESS and not
# the literal string. Without it, a filter that collided on `"*"` wherever it appeared would pass
# AC5 while freezing the stage against a stale `touches:` on an unheld row.

echo "0067 AC5 — a held exclusive claim collides with a row sharing none of its paths"
scaffold
add_row 0001 'A row sharing nothing with the holder' develop ready 0000
add_row 0002 'The cross-cutting change, held' develop in-progress 0000
add_item_scope 0001 develop ready       free/file.md  '' ''
add_item_scope 0002 develop in-progress other/file.md "$(printf '\n  - "*"')" '"aa11"'
seal
out="$(run_next develop)" && rc=0 || rc=$?
assert_rc "exits 0" "$rc" 0
line="$(collides_line "$out" 0001)"
assert_contains     "the row is reported as colliding" "$line" 'COLLIDES  0001'
assert_contains     "naming the holder"                "$line" '0002'
assert_contains     "and its token"                    "$line" 'aa11'
assert_not_contains "and no row is offered"            "$out"  'TAKE      0001'

echo "0067 AC5 — the inline list form declares the same hold"
scaffold
add_row 0001 'A row sharing nothing with the holder' develop ready 0000
add_row 0002 'The cross-cutting change, held' develop in-progress 0000
add_item_scope 0001 develop ready free/file.md '' ''
add_item_lists  0002 in-progress '[]' ' ["*"]'
seal
out="$(run_next develop)" && rc=0 || rc=$?
assert_contains     "the inline form collides too" "$(collides_line "$out" 0001)" 'COLLIDES  0001'
assert_not_contains "and no row is offered"        "$out" 'TAKE      0001'

# A candidate declaring NO paths is the case a path-intersection filter structurally cannot catch:
# there is nothing to intersect, so `paths_shared` is empty however wide the holder's scope is.
echo "0067 AC5 — it collides with a candidate that declares no paths at all"
scaffold
add_row 0001 'A row declaring nothing' develop ready 0000
add_row 0002 'The cross-cutting change, held' develop in-progress 0000
# Written inline rather than via `add_item_blank_scope`, which hardcodes a `claimed_by` — a HELD
# candidate is skipped by the take loop before any collision is computed, so that helper would have
# made this case green for a reason that has nothing to do with the exclusive claim.
cat > "$FIX/.claude/backlog/items/0001-fixture.md" <<'ITEM'
---
id: "0001"
title: Fixture 0001
next: develop
status: ready
qa_level: unit
size: s
parent:
blocked_by: []
expects:
claimed_by:
claimed_at:
touches:
---

## Problem
ITEM
add_item_scope 0002 develop in-progress other/file.md "$(printf '\n  - "*"')" '"aa11"'
seal
out="$(run_next develop)" && rc=0 || rc=$?
assert_contains     "the empty-scope row still collides" "$(collides_line "$out" 0001)" 'COLLIDES  0001'
assert_not_contains "and no row is offered"              "$out" 'TAKE      0001'

echo "0067 AC5 — every row colliding on it reads as held, not as an empty stage"
scaffold
add_row 0001 'The only takeable row' develop ready 0000
add_row 0002 'The cross-cutting change, held' develop in-progress 0000
add_item_scope 0001 develop ready       free/file.md  '' ''
add_item_scope 0002 develop in-progress other/file.md "$(printf '\n  - "*"')" '"aa11"'
seal
out="$(run_next develop)" && rc=0 || rc=$?
assert_contains     "says the stage is held" "$out" 'every takeable develop row collides'
assert_not_contains "not the empty-stage wording" "$out" 'nothing is takeable at stage develop'

echo "0067 AC6 — an unheld row's stale exclusive touches collides with nothing"
scaffold
add_row 0001 'A row sharing nothing' develop ready 0000
add_row 0002 'Not held, with a stale exclusive touches' develop ready 0000
add_item_scope 0001 develop ready free/file.md  '' ''
add_item_scope 0002 develop ready other/file.md "$(printf '\n  - "*"')" ''
seal
out="$(run_next develop)" && rc=0 || rc=$?
assert_rc "exits 0" "$rc" 0
assert_contains     "the top row is offered"   "$out" 'TAKE      0001'
assert_not_contains "and nothing collides"     "$out" 'COLLIDES  0001'
# --- 0086 AC8 — the take line carries close_by ------------------------------------------------
# A develop session reads this one line to decide what it is taking on, and `close_by` decides
# whether that session closes the ticket itself or hands it to a QA pass. Printed unconditionally,
# so the pair of cases below is the point: the DEFAULT is asserted as well as the opted-in value,
# because a conditional print would leave the commonest branch with no case on it at all.
echo "0086 AC8 — the take line prints close_by alongside size and qa"
scaffold
add_row 0001 'A light ticket' develop ready 0000
add_item_close_by 0001 ready '[]' 'close_by: develop'
seal
out="$(run_next develop)" && rc=0 || rc=$?
assert_rc "exits 0" "$rc" 0
assert_contains "the whole take line, in order" "$out" 'TAKE      0001 | A light ticket | size s | qa unit | close develop'

echo "0086 AC8/AC9 — and an item with no close_by: line reads as verify, not as blank"
scaffold
add_row 0001 'An ordinary ticket' develop ready 0000
add_item_close_by 0001 ready '[]' ''
assert_not_contains "the fixture really has no close_by: line" "$(cat "$FIX/.claude/backlog/items/0001-fixture.md")" 'close_by'
seal
out="$(run_next develop)" && rc=0 || rc=$?
assert_rc "exits 0" "$rc" 0
assert_contains "absent prints the default, never an empty field" "$out" 'TAKE      0001 | An ordinary ticket | size s | qa unit | close verify'

# ==============================================================================================
# 0115 — --drift sees a row and its item disagreeing
#
# The defect: `--drift` compared the Status column against `blocked_by` and nothing else, while
# three prose sites told sessions it also caught a row and its item disagreeing. Driven on exactly
# that shape it printed `no drift` and exited 0 — including over a `handoff` with its queue write
# mutated away, which is why tests/handoff.test.sh AC4 was a guard that could not fail.

# `assert_contains` cannot say "once", and AC4's whole claim is a line COUNT for one id: two lines
# for one row both contain it. This is the shape `testing-conventions.md` calls a guard that runs
# and cannot fail.
assert_eq() {
  if [ "$2" = "$3" ]; then ok "$1"; saw_on_pass "$2"; else
    bad "$1"; echo "         expected exactly:"; saw "$3"; echo "         got:"; saw "$2"; fi
}

# How many lines of $1 name $2.
lines_naming() { printf '%s\n' "$1" | grep -c "$2" || true; }

echo "0115 AC1 — a row whose Next cell disagrees with its item's next: is named, with both values"
scaffold
add_row 0001 'A handed-off row' develop ready 0000
add_ticket 0001 verify ready '[]' 0000 a/one.md
seal
out="$(run_next --drift)" && rc=0 || rc=$?
assert_rc_nonzero "exits non-zero" "$rc"
assert_contains "names the row"             "$out" '0001'
assert_contains "says what the row holds"   "$out" 'row Next develop'
assert_contains "says what the item holds"  "$out" 'item next: verify'

echo "0115 AC2 — a row whose Status cell disagrees with its item's status: is named, with both values"
# The item is HELD, so the tokenless check below cannot absorb this case: a fixture with an empty
# `claimed_by:` reds under the same mutation on the adjacent branch's wording instead of this one,
# which is the ladder absorption `testing-conventions.md` says to pin each branch against.
scaffold
add_row 0001 'A half-applied hand-off' develop in-progress 0000
add_item_lists 0001 ready '[]' ''
seal
out="$(run_next --drift)" && rc=0 || rc=$?
assert_rc_nonzero "exits non-zero" "$rc"
assert_contains "names the row"             "$out" '0001'
assert_contains "says what the row holds"   "$out" 'row Status in-progress'
assert_contains "says what the item holds"  "$out" 'item status: ready'

echo "0115 AC3 — a row at in-progress over an item nobody holds is named as tokenless"
# Distinct from AC2: 0029 settled *held* as a non-empty `claimed_by:` and nothing else, so a row
# and its item can agree on in-progress with the ticket held by nobody at all.
scaffold
add_row 0001 'A tokenless row' develop in-progress 0000
add_ticket 0001 develop in-progress '[]' 0000 a/one.md
assert_not_contains "the fixture really leaves claimed_by: empty" \
  "$(cat "$FIX/.claude/backlog/items/0001-fixture.md")" 'claimed_by: '
seal
out="$(run_next --drift)" && rc=0 || rc=$?
assert_rc_nonzero "exits non-zero" "$rc"
assert_contains "names the row"                  "$out" '0001'
assert_contains "says the row reads in-progress" "$out" 'row Status in-progress'
assert_contains "says nobody holds it"           "$out" 'item claimed_by: empty'

echo "0115 AC4 — a stale blocked cache over a disagreeing status is one line, not two"
scaffold
add_row 0001 'A stale-blocked row' develop blocked 0000
add_ticket 0001 develop ready '["0002"]' 0000 a/one.md
add_ticket 0002 develop done '[]' 0000 a/two.md
seal
out="$(run_next --drift)" && rc=0 || rc=$?
assert_rc_nonzero "exits non-zero" "$rc"
assert_contains "the blocked check keeps precedence" "$out" 'written blocked'
assert_eq "the row is reported once" "$(lines_naming "$out" '0001')" 1

echo "0115 AC5 — a row with no item file is named as that, not as a disagreement with the empty string"
scaffold
add_row 0001 'A row whose item vanished' develop ready 0000
seal
out="$(run_next --drift)" && rc=0 || rc=$?
assert_rc_nonzero "exits non-zero" "$rc"
assert_contains     "names the row"                   "$out" '0001'
assert_contains     "says the item does not resolve"  "$out" 'no item file'
assert_not_contains "does not read empty as a stage"  "$out" 'item next:'
assert_not_contains "does not read empty as a status" "$out" 'item status:'

echo "0115 AC6 — a backlog whose rows and items agree, with a real holder, still reads no drift"
scaffold
add_row 0001 'A held row' develop in-progress 0000
add_item_lists 0001 in-progress '[]' ''
add_row 0003 'A ready row' verify ready 0000
add_ticket 0003 verify ready '[]' 0000 a/three.md
seal
out="$(run_next --drift)" && rc=0 || rc=$?
assert_rc "exits 0" "$rc" 0
assert_contains     "says there is no drift" "$out" 'no drift'
assert_not_contains "names no row"           "$out" 'DRIFT'

# ==============================================================================================
# 0140 — a held item under a ready row
#
# The defect: takeability was read off the Status column, and ownership lives in the item's
# `claimed_by:` (references/CONCURRENCY.md, *A stage writes only the ticket it holds*). So a row
# written `ready` over a held item was offered to a second session, `--drift` called it no drift,
# and `--drive` would dispatch an unattended session onto it. Driven on exactly that shape.

# An item carrying a live claim alongside its own status and blocked_by. No existing helper writes
# this pair: `add_item_scope` hardwires `blocked_by: []` and `add_item_lists` hardwires the token.
#
# $1 id, $2 status, $3 blocked_by inline, $4 claimed_by written verbatim, $5 one expects path
add_item_held() {
  cat > "$FIX/.claude/backlog/items/$1-fixture.md" <<ITEM
---
id: "$1"
title: Fixture $1
next: develop
status: $2
qa_level: unit
size: s
parent:
blocked_by: $3
expects:
  - $5
claimed_by: $4
claimed_at: 2026-09-09T00:00:00Z
touches:
---

## Problem
ITEM
}

echo "0140 AC1/AC2 — a ready row over a held item is skipped, naming the id and the token"
scaffold
add_row 0001 'Ready by the column, held by the item' develop ready 0000
add_item_held 0001 ready '[]' '"tok9"' some/file.md
seal
out="$(run_next develop)" && rc=0 || rc=$?
assert_rc           "exits 0"                       "$rc" 0 "$out"
assert_not_contains "does not offer the held row"   "$out" 'TAKE      0001'
skip="$(printf '%s\n' "$out" | grep '^SKIP      0001 ' || true)"
assert_contains     "names the id on a skip line"   "$skip" '0001'
assert_contains     "and names the token holding it" "$skip" 'tok9'

echo "0140 AC3 — a held row ranked above a clear one does not stop the walk"
scaffold
add_row 0001 'Held, and topmost' develop ready 0000
add_row 0002 'Clear, and below it' develop ready 0000
add_item_held 0001 ready '[]' '"tok9"' held/file.md
add_item_scope 0002 develop ready free/file.md '' ''
seal
out="$(run_next develop)" && rc=0 || rc=$?
assert_rc       "exits 0"                      "$rc" 0 "$out"
assert_contains "skips the held row"           "$out" 'SKIP      0001'
assert_contains "and still offers the clear one" "$out" 'TAKE      0002'

echo "0140 AC4 — a row both held and blocked reports once, the open blocker"
scaffold
add_row 0001 'Held and blocked' develop ready 0000
add_item_held 0001 ready '["0002"]' '"tok9"' held/file.md
add_item 0002 ready '[]'
seal
out="$(run_next develop)" && rc=0 || rc=$?
assert_rc       "exits 0"                        "$rc" 0 "$out"
assert_contains "reports the open blocker"       "$out" 'blocked_by still open'
assert_eq       "and reports the row exactly once" "$(lines_naming "$out" '^SKIP      0001 ')" 1

echo "0140 AC5/AC6 — --drift names a ready row over a held item, once, and exits 1"
scaffold
add_row 0001 'Ready by the column, held by the item' develop ready 0000
add_item_held 0001 ready '[]' '"tok9"' some/file.md
seal
out="$(run_next --drift)" && rc=0 || rc=$?
assert_rc       "exits 1"                         "$rc" 1 "$out"
assert_contains "names the id"                    "$out" '0001'
assert_contains "and the token holding it"        "$out" 'tok9'
assert_eq       "one DRIFT line for the row"      "$(lines_naming "$out" '^DRIFT     0001 ')" 1

echo "0140 AC6 — a held row that also disagrees on status: still reports once"
scaffold
add_row 0001 'Ready by the column, in-progress by the item' develop ready 0000
add_item_held 0001 in-progress '[]' '"tok9"' some/file.md
seal
out="$(run_next --drift)" && rc=0 || rc=$?
assert_rc "exits 1"                          "$rc" 1 "$out"
assert_eq "one DRIFT line for the row"       "$(lines_naming "$out" '^DRIFT     0001 ')" 1

# The exit moved from 3 to 4 under 0142 and the claim did not: a `ready` row over a held item is
# drift class 6, and a driver stops on it rather than reading the queue as finished. Which is the
# sharper reading of this very fixture — the row reads takeable while somebody is building it.
echo "0140 AC7 / 0142 — --drive neither dispatches nor counts a held row, and stops on it"
scaffold
add_row 0001 'Held, and the top develop row' develop ready 0000
add_item_held 0001 ready '[]' '"tok9"' some/file.md
seal
out="$(run_next --drive)" && rc=0 || rc=$?
assert_rc           "exits 4 — a person decides" "$rc" 4 "$out"
assert_not_contains "dispatches nothing"         "$out" 'DISPATCH  develop'
assert_contains     "counts no takeable gate"    "$out" 'DEPTH     0 develop gate(s)'
assert_contains     "and names the row as drift" "$out" 'DRIFT     0001'

echo "0140 AC8 — a held row appears in CLAIMED FILES whatever its Status column says"
scaffold
add_row 0001 'Held under a ready column' develop ready 0000
add_item_held 0001 ready '[]' '"tok9"' some/file.md
seal
out="$(run_next develop)" && rc=0 || rc=$?
assert_contains "lists the row with its token" "$(claimed_line "$out" 0001)" '[tok9]'

echo "0140 AC9 — a tokenless in-progress row is not read as a claim"
scaffold
add_row 0001 'A clear candidate' develop ready 0000
add_row 0002 'in-progress with nobody holding it' develop in-progress 0000
add_item_scope 0001 develop ready       shared/file.md '' ''
add_item_scope 0002 develop in-progress other/file.md "$(printf '\n  - shared/file.md')" ''
seal
out="$(run_next develop)" && rc=0 || rc=$?
assert_rc           "exits 0"                          "$rc" 0 "$out"
assert_contains     "the candidate is offered"         "$out" 'TAKE      0001'
assert_not_contains "no collision against a non-claim" "$out" 'COLLIDES  0001'
assert_eq           "and no CLAIMED FILES line for it" "$(claimed_line "$out" 0002)" ''

# `grep -q` reduced to a word rather than asserted on a count: a count assertion reads as exact and
# is satisfied by any number sharing a digit under `assert_contains`, and `assert_eq` against 1 goes
# false the day a second legitimate mention lands. Membership, not cardinality
# (`testing-conventions.md`).
cited() { grep -q "$2" "$1" && echo cited || echo missing; }

echo "0140 AC10 — the held definition lives in CONCURRENCY.md, and next cites it"
conc="$ROOT/references/CONCURRENCY.md"
assert_eq "CONCURRENCY.md owns the definition" \
  "$(cited "$conc" 'the one place \*held\* is defined')" cited
assert_eq "and says no reader offers a held row" \
  "$(cited "$conc" 'No reader offers a held row')" cited
for copy in "$ROOT/skills/queue/templates/next" "$ROOT/.claude/backlog/next"; do
  assert_eq "$copy restates no definition"      "$(grep -c 'non-empty' "$copy" || true)" 0
  assert_eq "$copy cites the section instead" \
    "$(cited "$copy" 'A stage writes only the ticket it holds')" cited
done

# --- 0130 — --drive --propose, the gate made legible before a person approves it ----------------
#
# WHY THESE ARE NOT PROSE CASES. Every other requirement of 0130 is an instruction to a supervisor
# and can only be greped for (tests/sprint.test.sh carries those). AC2 is the exception: it
# says the proposal NAMES the file a gate is held together by and the COUNT of rows joining through
# it, and that is an arithmetic answer about a real backlog. So it is asserted here, against the
# real script.
#
# AGAINST A FIXTURE, NEVER THE LIVE QUEUE, and the ticket says why in as many words: a guard reading
# the real QUEUE.md changes meaning every time a ticket closes. The live gate that motivated 0130
# was thirteen rows on 2026-09-09 and is forty-one today, so a case pinned to either number would
# have been wrong within a day of being written.
#
# The fixture is the SHAPE of that defect rather than a copy of it (testing-conventions.md, the
# fixture rule): one hub file that most of the gate joins through, one pair joining through a
# different file, and one row joining by `parent:` and naming no shared file at all — because the
# gate has two join mechanisms and a proposal that explains only the file one mislabels the other.

# $1 id, $2 the Problem body line. The fixture helpers above end every item at a bare `## Problem`
# heading, and the WORK line is drawn from the first non-empty line UNDER it.
add_problem() {
  printf '\n%s\n' "$2" >> "$FIX/.claude/backlog/items/$1-fixture.md"
}

# A gate of five: 0101 leads, 0102 and 0103 join through hub/shared.md, 0104 joins 0103 through
# edge/other.md (so it is in the gate without naming the hub), and 0105 joins by parent alone.
# 0109 is outside the gate entirely and must not be counted in any denominator.
propose_fixture() {
  scaffold
  add_row 0101 'Lead of the gate'      develop ready 0091
  add_row 0102 'Joins through the hub' develop ready ''
  add_row 0103 'Also the hub, plus an edge' develop ready ''
  add_row 0104 'Joins the edge only'   develop ready ''
  add_row 0105 'Joins by parent only'  develop ready 0091
  add_row 0109 'Nothing to do with any of it' develop ready ''
  add_ticket_expects 0101 develop ready '[]' 0091 '
  - hub/shared.md'
  add_ticket_expects 0102 develop ready '[]' ''     '
  - hub/shared.md'
  add_ticket_expects 0103 develop ready '[]' ''     '
  - hub/shared.md
  - edge/other.md'
  add_ticket_expects 0104 develop ready '[]' ''     '
  - edge/other.md'
  add_ticket_expects 0105 develop ready '[]' 0091   '
  - unrelated/own.md'
  add_ticket_expects 0109 develop ready '[]' ''     '
  - far/away.md'
  # Written across two source lines, because these sections are wrapped prose and `grep` is
  # line-based: a WORK line taken from the first SOURCE LINE cuts mid-sentence, which is what the
  # live backlog produced ("...is invisible to the only reader that is").
  add_problem 0101 '**The lead ticket problem statement**, whose first
paragraph is what WORK carries.'
  add_problem 0102 'A second ticket, with a plain first line.'
}

echo "0130 AC2 — the proposal names the file a gate is held together by, and how many rows join through it"
propose_fixture
seal
out="$(run_next --drive --propose)" && rc=0 || rc=$?
assert_rc       "exits 0 — still a dispatch decision"   "$rc" 0
assert_contains "still prints the decision line"        "$out" 'DISPATCH  develop 0101 0102 0103 0104 0105'
# The count is the CLAIM, so it is asserted as one string with the path. `3 of 5` alone would be
# satisfied by any line carrying those digits, and the path alone says nothing about how much of the
# gate it explains — which is the whole difference between a theme and a grouping artefact.
assert_contains "names the hub file and its share of the gate" "$out" 'JOIN      hub/shared.md | 3 of 5 rows'
assert_contains "names the lesser shared file too"             "$out" 'JOIN      edge/other.md | 2 of 5 rows'
assert_contains "names the parent join as a join"              "$out" 'JOIN      parent 0091 | 2 of 5 rows'
# The denominator is the GATE, not the queue. 0109 is takeable and develop and shares nothing, so a
# proposal counting it has counted the backlog instead of the gate.
assert_not_contains "does not count the row outside the gate" "$out" '0109'
# A file only the lead names explains no grouping, and listing it invites reading a one-row
# coincidence as a theme.
assert_not_contains "says nothing about a file only one row names" "$out" 'unrelated/own.md'

echo "0130 AC3 — the proposal carries the count, the ids, and a line of work per ticket"
propose_fixture
seal
out="$(run_next --drive --propose)" && rc=0 || rc=$?
assert_contains "states how many tickets the gate holds"  "$out" 'PROPOSE   develop | 5 ticket(s)'
assert_contains "names each ticket by id and title"       "$out" 'TICKET    0101 | size s | Lead of the gate'
assert_contains "and the last of them, not only the lead" "$out" 'TICKET    0105 | size s | Joins by parent only'
# FR4 — drawn from the ticket rather than invented. Asserted on the lead's own Problem line, with
# its markdown emphasis stripped, so the assertion cannot be satisfied by the title.
assert_contains "carries a line of work drawn from the item" "$out" 'WORK      The lead ticket problem statement, whose first paragraph is what WORK carries.'

echo "0130 AC2 — the JOIN lines are capped, and the tail is counted rather than dropped"
# The live backlog on 2026-09-10 produced 34 JOIN lines over a 41-row gate, of which the top one
# was the entire story and the other 33 were pairs. A block that long is the unreadable thing FR5
# exists to remove, arriving one level down: a person who has to read 34 lines to find the hub is
# back where the bare count left them. So the block is capped at the files that actually explain
# the gate — and the remainder is COUNTED, never silently dropped, because a proposal that quietly
# stops listing is a proposal whose numbers cannot be reconciled against the gate.
scaffold
i=1
while [ "$i" -le 8 ]; do
  add_row "010$i" "Row $i" develop ready ''
  # Each row names the hub plus a file it shares with exactly one neighbour. That is seven shared
  # pairs (pair/1 … pair/7; pair/0 and pair/8 are named once each and so explain nothing) plus the
  # hub — eight shared files, of which a cap of five must leave three unlisted.
  add_ticket_expects "010$i" develop ready '[]' '' "
  - hub/shared.md
  - pair/$i.md
  - pair/$((i - 1)).md"
  i=$((i + 1))
done
seal
out="$(run_next --drive --propose)" && rc=0 || rc=$?
assert_rc       "exits 0"                          "$rc" 0
assert_contains "the hub leads the block"          "$out" 'JOIN      hub/shared.md | 8 of 8 rows'
assert_contains "counts the shared files it did not list" "$out" 'JOIN      3 further file(s) shared by 2 or more rows, not listed'
# pair/0 and pair/8 are each named by exactly one row, so neither is listed NOR counted in the tail:
# the cap hides shared files, and a file nothing shares was never part of the block.
assert_not_contains "counts no file that only one row names" "$out" 'pair/0.md'
# Ranked by how much of the gate each explains, so the cap keeps the hub and drops a pair — the
# reverse of that ordering keeps five pairs and drops the one line worth reading.
assert_not_contains "drops a pair rather than the hub" "$out" 'pair/7.md'

echo "0130 AC2 — a single-ticket gate is proposed with no JOIN line to explain"
scaffold
add_row 0101 'The only takeable row' develop ready ''
add_ticket 0101 develop ready '[]' '' a/one.md
seal
out="$(run_next --drive --propose)" && rc=0 || rc=$?
assert_rc       "exits 0"                               "$rc" 0
assert_contains "states the count"                      "$out" 'PROPOSE   develop | 1 ticket(s)'
# The negative half of AC2. A proposal that manufactures a grouping reason for a gate of one is
# reporting a theme where there is not even a grouping, and it is the shape that would make every
# JOIN line above unfalsifiable — print one always and the count is the only thing being read.
assert_not_contains "invents no grouping reason for a gate of one" "$out" 'JOIN'

echo "0130 — the proposal is opt-in, so a cycle after the confirmed one pays nothing for it"
propose_fixture
seal
out="$(run_next --drive)" && rc=0 || rc=$?
assert_rc       "exits 0"                            "$rc" 0
assert_contains "still dispatches the same gate"     "$out" 'DISPATCH  develop 0101 0102 0103 0104 0105'
assert_not_contains "prints no proposal unasked"     "$out" 'PROPOSE'
assert_not_contains "and no per-ticket lines"        "$out" 'TICKET'

echo "0130 — --propose describes a verify dispatch too, so the first cycle of any run can be confirmed"
scaffold
add_row 0101 'A built ticket awaiting QA' verify ready ''
add_ticket 0101 verify ready '[]' '' a/one.md
add_problem 0101 'What this ticket was built to do.'
seal
out="$(run_next --drive --propose)" && rc=0 || rc=$?
assert_rc       "exits 0"                          "$rc" 0
assert_contains "states the stage and the count"   "$out" 'PROPOSE   verify | 1 ticket(s)'
assert_contains "names the ticket"                 "$out" 'TICKET    0101 | size s | A built ticket awaiting QA'

echo "0130 — a retro dispatch is proposed too, holding no ticket of its own"
# The findings gate dispatches `retro`, which holds no row. It is still a STAGE SESSION, so it is
# still something a person is being asked to approve — a stage that silently skipped the proposal
# would be the one hole in "no stage runs unconfirmed", and it is the hole nobody would look for.
scaffold
set_threshold 2
add_row 0101 'Work the gate will not reach' develop ready ''
add_ticket 0101 develop ready '[]' '' a/one.md
add_findings "$(printf -- '- 2026-01-02 — one entry.\n- 2026-01-03 — and a second, which reaches the threshold.')"
seal
out="$(run_next --drive --propose)" && rc=0 || rc=$?
assert_rc       "exits 5 — the findings gate"        "$rc" 5
assert_contains "dispatches retro"                   "$out" 'DISPATCH  retro'
assert_contains "proposes the retro as a stage with no ticket" "$out" 'PROPOSE   retro | no ticket of its own'
# The develop gate it displaced is NOT described. A proposal naming tickets beside a retro dispatch
# is a scope a person would approve believing those tickets are about to be built.
assert_not_contains "describes no ticket the retro will not touch" "$out" 'TICKET    0101'

echo "0130 — --propose adds nothing to a decision that dispatches no stage"
scaffold
add_row 0105 'A design question' design ready ''
add_ticket 0105 design ready '[]' '' a/one.md
append_section 0105 '## Open design question

Which of the two shapes does this take?'
seal
out="$(run_next --drive --propose)" && rc=0 || rc=$?
assert_rc       "exits 4 — escalate, unchanged"    "$rc" 4
assert_contains "escalates on the design row"      "$out" 'ESCALATE  0105'
# There is nothing to confirm: no stage would run. A proposal printed here is a scope a person
# could approve that dispatches nothing, which is the one reading of a confirmation that misleads.
assert_not_contains "proposes nothing"             "$out" 'PROPOSE'

echo "0130 — --propose is rejected where it cannot mean anything"
scaffold
add_row 0101 'Anything' develop ready ''
add_ticket 0101 develop ready '[]' '' a/one.md
seal
# Asserted on the MESSAGE, not on the status: a silent refusal exits non-zero too
# (testing-conventions.md).
out="$(run_next --propose)" && rc=0 || rc=$?
assert_rc       "exits 2 — a usage error"          "$rc" 2
assert_contains "names the flag it could not place" "$out" '--propose'
out="$(run_next --drive --propose extra)" && rc=0 || rc=$?
assert_rc       "exits 2 — --propose takes no value" "$rc" 2

echo "0130 — --help lists --propose as a mode of --drive"
scaffold
seal
out="$(run_next --help)" && rc=0 || rc=$?
# Anchored to the usage line rather than the bare flag, the way 0038's own --help case is: the
# explanatory paragraphs below it also name the flag.
assert_contains "the usage line carries it" "$out" '--drive [--propose]'

# --- 0131 — a started ticket is verified before a new develop gate is opened ------------------
# The rule is a STAGE PREFERENCE at the gate, not a re-ranking: rank still decides among verify
# rows and among gates. Each case here pins one half of that, because a rule written as "verify
# always wins" passes the positive case and breaks every run whose backlog carries a stale verify
# row somebody else left behind.

echo "0131 AC1 — a started verify row is dispatched ahead of a new develop gate below it in rank"
scaffold
add_row 0103 'A new develop row' develop ready ''
add_row 0102 'A built ticket'    verify  ready ''
add_ticket 0103 develop ready '[]' '' b/two.md
add_ticket 0102 verify  ready '[]' '' a/one.md
seal
out="$(run_next --drive --started 0102)" && rc=0 || rc=$?
assert_rc           "exits 0 — dispatch"                  "$rc" 0 "$out"
assert_contains     "dispatches the started verify row"   "$out" 'DISPATCH  verify 0102'
assert_not_contains "and not the develop gate above it"   "$out" 'DISPATCH  develop'

echo "0131 AC2 — with no --started, rank decides and the develop gate goes first"
scaffold
add_row 0103 'A new develop row' develop ready ''
add_row 0102 'A built ticket'    verify  ready ''
add_ticket 0103 develop ready '[]' '' b/two.md
add_ticket 0102 verify  ready '[]' '' a/one.md
seal
out="$(run_next --drive)" && rc=0 || rc=$?
assert_rc           "exits 0 — dispatch"                    "$rc" 0 "$out"
assert_contains     "dispatches the develop gate"           "$out" 'DISPATCH  develop 0103'
assert_not_contains "the stale verify row does not jump it" "$out" 'DISPATCH  verify'

echo "0131 AC3 — rank still decides among the started verify rows"
scaffold
add_row 0103 'A new develop row'   develop ready ''
add_row 0102 'The first built one' verify  ready ''
add_row 0104 'The second built one' verify ready ''
add_ticket 0103 develop ready '[]' '' b/two.md
add_ticket 0102 verify  ready '[]' '' a/one.md
add_ticket 0104 verify  ready '[]' '' c/three.md
seal
# Given in the order they would NOT be chosen in, so a reader of the ids rather than of the rank
# dispatches 0104.
out="$(run_next --drive --started 0104 --started 0102)" && rc=0 || rc=$?
assert_rc       "exits 0 — dispatch"                "$rc" 0 "$out"
assert_contains "dispatches the higher-ranked one"  "$out" 'DISPATCH  verify 0102'

echo "0131 AC5 — a started ticket that has left QUEUE.md does not stop the run"
scaffold
add_row 0103 'A new develop row' develop ready ''
add_ticket 0103 develop ready '[]' '' b/two.md
add_ticket 0102 verify done '[]' '' a/one.md
seal
out="$(run_next --drive --started 0102)" && rc=0 || rc=$?
assert_rc       "exits 0 — dispatch"        "$rc" 0 "$out"
assert_contains "dispatches the gate"       "$out" 'DISPATCH  develop 0103'

echo "0131 AC6 — a started id nothing recognises is reported, and the run continues"
scaffold
add_row 0103 'A new develop row' develop ready ''
add_ticket 0103 develop ready '[]' '' b/two.md
seal
out="$(run_next --drive --started 0102)" && rc=0 || rc=$?
assert_rc       "exits 0 — dispatch"          "$rc" 0 "$out"
assert_contains "names the id it could not place" "$out" '0102'
assert_contains "as a NOTE rather than a stop"    "$out" 'NOTE'
assert_contains "and still dispatches the gate"   "$out" 'DISPATCH  develop 0103'

echo "0131 AC7 — a --started value that is not a four-digit id is a usage error"
scaffold
add_row 0103 'A new develop row' develop ready ''
add_ticket 0103 develop ready '[]' '' b/two.md
seal
out="$(run_next --drive --started 12)" && rc=0 || rc=$?
assert_rc       "exits 2 — usage"                 "$rc" 2 "$out"
assert_contains "and says which value it refused" "$out" '12'
out="$(run_next --drive --started)" && rc=0 || rc=$?
assert_rc       "a --started with no value is a usage error too" "$rc" 2 "$out"

echo "0131 AC8 — the preference applies at the gate, so an escalation above it still stops the run"
scaffold
add_row 0105 'A design row'      design  ready ''
add_row 0103 'A new develop row' develop ready ''
add_row 0102 'A built ticket'    verify  ready ''
add_ticket 0105 design  ready '[]' '' d/four.md
add_ticket 0103 develop ready '[]' '' b/two.md
add_ticket 0102 verify  ready '[]' '' a/one.md
seal
out="$(run_next --drive --started 0102)" && rc=0 || rc=$?
assert_rc           "exits 4 — escalate"                  "$rc" 4 "$out"
assert_contains     "escalates on the design row"         "$out" 'ESCALATE  0105'
assert_not_contains "the started verify row does not jump it" "$out" 'DISPATCH'

echo "0131 AC9 — --completed stays singular"
scaffold
add_row 0101 'A verify row' verify ready ''
add_ticket 0101 verify ready '[]' '' a/one.md
seal
out="$(run_next --drive --completed develop:0101 --completed verify:0101)" && rc=0 || rc=$?
assert_rc "a second --completed is still a usage error" "$rc" 2 "$out"

echo "0131 — --help lists --started as a mode of --drive"
scaffold
seal
out="$(run_next --help)" && rc=0 || rc=$?
assert_contains "the usage line carries it"      "$out" '--started <id>'
assert_contains "and says it is cumulative"      "$out" 'cumulative'

# ==============================================================================================
# 0142 — the driver sees the drift classes that stop a human reader
#
# The defect: `--drift` exits non-zero on every class precisely so that a row disagreeing with its
# own item stops the work, and `--drive` — the one reader that is never a person — ran no drift
# check at all. Driven on the 0084 shape, `--drift` exited 1 while `--drive` printed
# `COMPLETE nothing takeable` and exited 3 over the same queue, so a drifted backlog read as a
# FINISHED one to a driver.
#
# The code is 4, the escalate code, reused rather than minted: the outcome is *a person decides*,
# which `sprint` already routes. 3 is forbidden by FR2 — 3 is what the bug is.

echo "0142 AC1 — --drive reports drift, names the row, and exits non-zero and not 3"
scaffold
add_row 0101 'Ready by the column, blocked by the graph' develop ready ''
add_row 0102 'A perfectly takeable row'                  develop ready ''
add_ticket 0101 develop ready '["0102"]' '' a/one.md
add_ticket 0102 develop ready '[]'       '' b/two.md
seal
out="$(run_next --drive)" && rc=0 || rc=$?
assert_rc_nonzero   "exits non-zero"                  "$rc" "$out"
assert_rc           "exits 4 — a person decides"      "$rc" 4 "$out"
assert_contains     "reports the drift"               "$out" 'DRIFT     0101'
dline="$(printf '%s\n' "$out" | grep '^DRIFT     0101 ' || true)"
assert_contains     "and the drift line names the open blocker" "$dline" '0102'
# The dispatch is what a driver would have acted on. A drift report printed beside
# `DISPATCH develop 0102` leaves the run going, which is the same silent failure by a slower route.
assert_not_contains "and dispatches nothing"          "$out" 'DISPATCH'

echo "0142 AC2 — a drift-free backlog with a takeable row dispatches and exits 0 as today"
scaffold
add_row 0101 'A takeable row' develop ready ''
add_ticket 0101 develop ready '[]' '' a/one.md
seal
out="$(run_next --drive)" && rc=0 || rc=$?
assert_rc       "exits 0 — dispatch"     "$rc" 0 "$out"
assert_contains "dispatches the gate"    "$out" 'DISPATCH  develop 0101'
# Running the check unconditionally fatal is the mutation this pins: it would red every clean run.
assert_not_contains "and reports no drift" "$out" 'DRIFT'

echo "0142 AC3 — with drift and nothing takeable, the drift exit wins over COMPLETE"
scaffold
add_row 0101 'Ready by the column, blocked by the graph' develop ready ''
add_row 0102 'Held by another session'                   develop in-progress ''
add_ticket    0101 develop ready '["0102"]' '' a/one.md
add_item_held 0102 in-progress '[]' '"tok9"' b/two.md
seal
out="$(run_next --drive)" && rc=0 || rc=$?
assert_rc           "exits 4, not 3"                    "$rc" 4 "$out"
assert_contains     "reports the drift"                 "$out" 'DRIFT     0101'
# The current shape's failure is ordering the check after the takeability walk, which reaches
# COMPLETE first and exits 3 with the drift never printed.
assert_not_contains "never says the run is complete"    "$out" 'COMPLETE'

echo "0142 FR3 — --drive and --drift name the same rows and classes, because they share the check"
scaffold
add_row 0101 'Ready by the column, blocked by the graph' develop ready ''
add_row 0102 'A row whose Next disagrees with its item'  verify  ready ''
add_row 0103 'A row whose item vanished'                 develop ready ''
add_ticket 0101 develop ready '["0102"]' '' a/one.md
add_ticket 0102 develop ready '[]'       '' b/two.md
seal
drift_out="$(run_next --drift)" || true
drive_out="$(run_next --drive)" || true
assert_eq "the DRIFT lines are identical, line for line"   "$(printf '%s\n' "$drive_out" | grep '^DRIFT ' || true)"   "$(printf '%s\n' "$drift_out" | grep '^DRIFT ' || true)"
# Not vacuous: the fixture really does carry three classes, so an empty-against-empty comparison
# cannot be what passed above.
assert_eq "three rows drifted"  "$(printf '%s\n' "$drift_out" | grep -c '^DRIFT ' || true)" 3

echo "0142 compatibility — a clean queue still spends 3, 4 and 5 exactly as today"
scaffold
add_row 0101 'Held by another session' develop in-progress ''
add_item_held 0101 in-progress '[]' '"tok9"' a/one.md
seal
out="$(run_next --drive)" && rc=0 || rc=$?
assert_rc       "nothing takeable still exits 3" "$rc" 3 "$out"
assert_contains "and still says so"              "$out" 'COMPLETE'
scaffold
add_row 0101 'An undecided ticket' design ready ''
add_ticket 0101 design ready '[]' '' a/one.md
seal
out="$(run_next --drive)" && rc=0 || rc=$?
assert_rc "a design row still escalates with 4" "$rc" 4 "$out"
scaffold
set_threshold 2
add_row 0101 'A takeable row' develop ready ''
add_ticket 0101 develop ready '[]' '' a/one.md
add_findings "$(printf -- '- 2026-01-02 - one entry.\n- 2026-01-03 - two entries.')"
seal
out="$(run_next --drive)" && rc=0 || rc=$?
assert_rc "the findings gate still exits 5" "$rc" 5 "$out"

echo "0142 AC4 — sprint's routing paragraph names every code --drive can emit"
orch="$ROOT/skills/sprint/SKILL.md"
route="$(awk '/Route on the exit code/, /^$/' "$orch")"
assert_contains "names 0 — dispatch"        "$route" '`0`'
assert_contains "names 3 — run complete"    "$route" '`3`'
assert_contains "names 4 — escalate"        "$route" '`4`'
assert_contains "names 5 — the findings gate" "$route" '`5`'
assert_contains "names 1 and 2 as the stops"  "$route" '`1` and `2`'
# The clause this row adds, and the wording is what pins it. A guard on the codes alone stays green
# over the OLD paragraph, which named every one of them while saying --drive checks no drift; and a
# bare `drift` is satisfied by that same sentence. So the assertion is the code the drift outcome
# spends, which the old text could not have carried.
assert_contains     "ties drift to the escalate code"       "$route" 'exits `4` on drift'
assert_not_contains "no longer says it cannot report drift" "$route" 'cannot report it'
assert_not_contains "and no longer says it does not check"  "$route" 'does not check for drift'

# --- 0133 — the findings gate's second limit: an unswept buffer aged past N completed sprints ----
#
# WHY A SECOND LIMIT AT ALL. The count alone strands a low-yield project: a repo parking two
# findings a sprint never reaches a threshold of eight, so its buffer is never swept and the
# lessons in it are never landed. The age half fires on TIME SERVED rather than on volume.
#
# WHY THE UNIT IS COMPLETED SPRINTS AND NOT CALENDAR DAYS (0133 FR3). The gate is only ever
# evaluated when a sprint ends, so a calendar window and a sprint count fire identically on the
# next sprint whenever it comes — and a dormant project's calendar clock runs while nothing is
# there to read it. What a sprint count measures is opportunities missed, which is the thing.
#
# WHERE THE COUNT COMES FROM. `.claude/backlog/runs/<run-id>.jsonl`, one file per run, each
# carrying a `sprint_ended` event when its run finished. That directory is the ONLY durable record
# a supervisor may write: `sprint` Step 7 forbids it the backlog lock, so config.yml — where a
# counter would otherwise live beside `next_id` — is closed to it.

# $1 threshold, $2 max sprints. Both verbatim, so a case can supply a non-number.
set_findings_limits() {
  printf 'project: Fixture\nfindings_threshold: %s\nfindings_max_sprints: %s\n' "$1" "$2" \
    > "$FIX/.claude/backlog/config.yml"
}

# A run that ENDED: $1 the run id, $2 the UTC date of its `sprint_ended` event.
add_ended_run() {
  mkdir -p "$FIX/.claude/backlog/runs"
  printf '{"event":"sprint_ended","at":"%sT12:00:00Z","run":"%s"}\n' "$2" "$1" \
    > "$FIX/.claude/backlog/runs/$1.jsonl"
}

# A run that started and never ended — provenance, and not a completed sprint.
add_open_run() {
  mkdir -p "$FIX/.claude/backlog/runs"
  printf '{"event":"scope_confirmed","at":"%sT12:00:00Z","run":"%s"}\n' "$2" "$1" \
    > "$FIX/.claude/backlog/runs/$1.jsonl"
}

# A backlog with one takeable develop row, so `--drive` has something to dispatch when the gate
# does NOT fire. Without it every case below exits 3 and the two outcomes are indistinguishable.
one_takeable_row() {
  add_row 0001 'Fixture' develop ready ''
  add_item 0001 ready '[]'
}

echo "0133 AC1 — a buffer under both limits runs no tail"
scaffold
set_findings_limits 8 2
one_takeable_row
add_findings "$(printf -- '- 2026-01-02 — one entry.')"
seal
out="$(run_next --findings)" && rc=0 || rc=$?
assert_rc       "exits 0"                          "$rc" 0
assert_contains "reports the age against the limit" "$out" 'findings_max_sprints'
assert_contains "and says it is under it"           "$out" 'under the limit'
out="$(run_next --drive)" && rc=0 || rc=$?
assert_rc           "dispatches the ticket rather than the tail" "$rc" 0 "$out"
assert_not_contains "no retro is dispatched"                     "$out" 'DISPATCH  retro'

echo "0133 AC3 — an entry that has survived the configured number of sprints crosses the gate"
scaffold
set_findings_limits 8 2
one_takeable_row
add_findings "$(printf -- '- 2026-01-02 — one entry.')"
add_ended_run r1 2026-01-03
add_ended_run r2 2026-01-04
seal
out="$(run_next --findings)" && rc=0 || rc=$?
assert_rc       "exits 0"                     "$rc" 0
assert_contains "counts the two sprints"      "$out" '2 completed sprint'
assert_contains "and says it is at the limit" "$out" 'at or over the limit'
out="$(run_next --drive)" && rc=0 || rc=$?
assert_rc       "spends the findings-gate code on age alone" "$rc" 5 "$out"
assert_contains "names the sprints served"                   "$out" 'completed sprint'

echo "0133 AC2/FR5 — the tail the gate dispatches is retro AND THEN queue"
# The count half and the age half both end in a tail, so both lines carry it. A gate naming only
# the retro leaves the buffer's work half unswept, which is 0060's asymmetry arriving as a dispatch.
scaffold
set_findings_limits 2 2
one_takeable_row
add_findings "$(printf -- '- 2026-01-02 — one.\n- 2026-01-03 — two.')"
seal
out="$(run_next --drive)" && rc=0 || rc=$?
assert_rc       "the count half still fires"       "$rc" 5 "$out"
assert_contains "and names both tail stages"       "$out" 'retro, then queue'

echo "0133 FR1 — an empty buffer runs no tail however many sprints have ended"
scaffold
set_findings_limits 8 2
one_takeable_row
add_findings ''
add_ended_run r1 2026-01-03
add_ended_run r2 2026-01-04
add_ended_run r3 2026-01-05
seal
out="$(run_next --drive)" && rc=0 || rc=$?
assert_rc "a sprint that parks nothing ends without a tail" "$rc" 0 "$out"

echo "0133 — a run that never ended is not a completed sprint"
# The falsifiable half of \"completed\": count the FILES and this case is green while a supervisor
# killed mid-run counts as an opportunity the buffer was offered and missed.
scaffold
set_findings_limits 8 2
one_takeable_row
add_findings "$(printf -- '- 2026-01-02 — one entry.')"
add_ended_run r1 2026-01-03
add_open_run  r2 2026-01-04
seal
out="$(run_next --findings)" && rc=0 || rc=$?
assert_contains "counts one, not two" "$out" '1 completed sprint'
out="$(run_next --drive)" && rc=0 || rc=$?
assert_rc "and the gate stays shut" "$rc" 0 "$out"

echo "0133 — a sprint ending the day the entry was parked is not counted"
# An ACKNOWLEDGED OVER-STRICTNESS (testing-conventions.md). An entry carries a date and a run an
# instant, so on the shared day there is no fact saying which came first. Not counting it delays
# the gate by at most one sprint; counting it fires the tail on a finding parked minutes earlier.
scaffold
set_findings_limits 8 1
one_takeable_row
add_findings "$(printf -- '- 2026-01-02 — one entry.')"
add_ended_run r1 2026-01-02
seal
out="$(run_next --findings)" && rc=0 || rc=$?
assert_contains "counts nothing on the shared day" "$out" '0 completed sprint'

echo "0133 — the oldest entry decides, not the newest"
# A buffer that keeps receiving entries would otherwise reset its own clock every sprint, which is
# exactly the low-yield project the age half exists for.
scaffold
set_findings_limits 8 2
one_takeable_row
add_findings "$(printf -- '- 2026-01-02 — old.\n- 2026-01-09 — new.')"
add_ended_run r1 2026-01-03
add_ended_run r2 2026-01-04
seal
out="$(run_next --findings)" && rc=0 || rc=$?
assert_contains "measures from 2026-01-02" "$out" '2026-01-02'
out="$(run_next --drive)" && rc=0 || rc=$?
assert_rc "and the gate is crossed" "$rc" 5 "$out"

echo "0133 — a non-numeric findings_max_sprints fails loudly rather than defaulting"
# The same rule read_threshold already holds to: a driver silently gating on a default where the
# project wrote something else is wrong with nothing to notice it by.
scaffold
set_findings_limits 8 'a couple'
add_findings "$(printf -- '- 2026-01-02 — one entry.')"
seal
out="$(run_next --findings)" && rc=0 || rc=$?
assert_rc       "exits 1"                     "$rc" 1
assert_contains "names the key and the value" "$out" 'findings_max_sprints'


# ==============================================================================================
# 0132 — a verify batch is the develop gate that produced it, and nothing wider
#
# The condition is NOT develop's (0059): a verify batch spends the gate's INDEPENDENCE, which no
# startup saving amortises, so the only thing licensing several tickets in one verify session is
# that a develop gate already fixed the membership. Rows merely sitting at `next: verify` are not
# thereby a batch — that is the halo-and-misattribution risk 0132's Problem records, and AC2's red.
#
# The run's own `--started` set is what carries "this run developed these": it is an INPUT, never
# derived, for 0131 FR5's reason — a stale verify row somebody else left behind must not join a
# batch because it happens to name one of the same files. Within that set the membership is
# recovered by `gate_from`, the same grouping that formed the gate at dispatch, so the two ends of
# the cycle agree by construction rather than by a second rule that can drift from the first.
#
# Every DISPATCH assertion here is an EXACT LINE. `assert_contains "DISPATCH  verify 0102"` is
# satisfied by `DISPATCH  verify 0102 0103 0104`, so it cannot tell a batch from a single row —
# which is the only distinction this whole ticket makes.

dispatch_line() { printf '%s\n' "$1" | grep '^DISPATCH' | head -1; }

echo "0132 AC1 — three tickets developed in one gate are dispatched as one verify session"
scaffold
add_row 0102 'First built'  verify ready 0100
add_row 0103 'Second built' verify ready 0100
add_row 0104 'Third built'  verify ready 0100
add_ticket 0102 verify ready '[]' 0100 a/one.md
add_ticket 0103 verify ready '[]' 0100 b/two.md
add_ticket 0104 verify ready '[]' 0100 c/three.md
seal
out="$(run_next --drive --started 0102 --started 0103 --started 0104)" && rc=0 || rc=$?
assert_rc "exits 0 — dispatch"                      "$rc" 0 "$out"
assert_eq "names all three in one verify session"   "$(dispatch_line "$out")" 'DISPATCH  verify 0102 0103 0104'

echo "0132 AC1 — the same batch is chosen on the --completed hand-off out of develop"
# The path a driven run actually takes: develop reports, and the very next call routes the gate it
# just built. Batching only in the rank walk would leave this branch dispatching one id forever.
scaffold
add_row 0102 'First built'  verify ready 0100
add_row 0103 'Second built' verify ready 0100
add_ticket 0102 verify ready '[]' 0100 a/one.md
add_ticket 0103 verify ready '[]' 0100 b/two.md
seal
out="$(run_next --drive --completed develop:0102 --started 0103)" && rc=0 || rc=$?
assert_rc "exits 0 — dispatch"                    "$rc" 0 "$out"
assert_eq "batches the gate it just developed"    "$(dispatch_line "$out")" 'DISPATCH  verify 0102 0103'

echo "0132 AC2 — rows that merely sit at next: verify are NOT a batch"
# The whole of AC2. Same three rows, same shared parent, no --started: nothing says this run
# developed them, so they are three independent verdicts and get three sessions.
scaffold
add_row 0102 'First built'  verify ready 0100
add_row 0103 'Second built' verify ready 0100
add_row 0104 'Third built'  verify ready 0100
add_ticket 0102 verify ready '[]' 0100 a/one.md
add_ticket 0103 verify ready '[]' 0100 b/two.md
add_ticket 0104 verify ready '[]' 0100 c/three.md
seal
out="$(run_next --drive)" && rc=0 || rc=$?
assert_rc "exits 0 — dispatch"                       "$rc" 0 "$out"
assert_eq "dispatches the topmost row alone"         "$(dispatch_line "$out")" 'DISPATCH  verify 0102'

echo "0132 AC2 — a stale verify row does not join the batch by sharing the gate's files"
# The 0131 FR5 hazard arriving through the new code path. 0104 names the same file as 0103 and
# shares the parent, so `gate_from` over the WHOLE stage would swallow it; it was not started, so
# it is not this run's to verify and must be left where it is.
scaffold
add_row 0102 'First built'   verify ready 0100
add_row 0103 'Second built'  verify ready 0100
add_row 0104 'Somebody else' verify ready 0100
add_ticket 0102 verify ready '[]' 0100 a/one.md
add_ticket 0103 verify ready '[]' 0100 b/two.md
add_ticket 0104 verify ready '[]' 0100 b/two.md
seal
out="$(run_next --drive --started 0102 --started 0103)" && rc=0 || rc=$?
assert_rc "exits 0 — dispatch"                      "$rc" 0 "$out"
assert_eq "batches the started pair and no more"    "$(dispatch_line "$out")" 'DISPATCH  verify 0102 0103'

echo "0132 AC2 — started rows that share neither a parent nor a file are separate gates"
# Two rows this run really did develop, in two different gates. `--started` alone would batch
# them; recovering the membership with `gate_from` is what keeps them apart.
scaffold
add_row 0102 'From gate one' verify ready ''
add_row 0103 'From gate two' verify ready ''
add_ticket 0102 verify ready '[]' '' a/one.md
add_ticket 0103 verify ready '[]' '' c/three.md
seal
out="$(run_next --drive --started 0102 --started 0103)" && rc=0 || rc=$?
assert_rc "exits 0 — dispatch"                       "$rc" 0 "$out"
assert_eq "dispatches the higher-ranked one alone"   "$(dispatch_line "$out")" 'DISPATCH  verify 0102'

echo "0132 FR6 — --propose states the verify batch it selected"
# FR6 is "selects the batch AND states it". A batch a person cannot see is a batch they cannot
# refuse, and the gate block is where 0130 put that.
scaffold
add_row 0102 'First built'  verify ready 0100
add_row 0103 'Second built' verify ready 0100
add_ticket 0102 verify ready '[]' 0100 a/one.md
add_ticket 0103 verify ready '[]' 0100 b/two.md
seal
out="$(run_next --drive --propose --started 0102 --started 0103)" && rc=0 || rc=$?
assert_rc       "exits 0 — dispatch"             "$rc" 0 "$out"
assert_contains "names the stage and the count"  "$out" 'PROPOSE   verify | 2 ticket(s)'
assert_contains "and lists the second ticket"    "$out" 'TICKET    0103'

echo "0132 — the finish-before-start preference dispatches the whole batch, not its lead"
# 0131 put a started verify row ahead of a new develop gate. It picked ONE. Left alone, the
# preference would hand back a single id and the rest of the gate would be re-dispatched one at a
# time on later calls — the session floors this ticket exists to stop being paid anyway.
scaffold
add_row 0105 'A new develop row' develop ready ''
add_row 0102 'First built'       verify  ready 0100
add_row 0103 'Second built'      verify  ready 0100
add_ticket 0105 develop ready '[]' '' z/nine.md
add_ticket 0102 verify  ready '[]' 0100 a/one.md
add_ticket 0103 verify  ready '[]' 0100 b/two.md
seal
out="$(run_next --drive --started 0102 --started 0103)" && rc=0 || rc=$?
assert_rc "exits 0 — dispatch"                        "$rc" 0 "$out"
assert_eq "the preference carries the whole batch"    "$(dispatch_line "$out")" 'DISPATCH  verify 0102 0103'

# --- result -----------------------------------------------------------------------------------
echo
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
