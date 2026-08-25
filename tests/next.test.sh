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
assert_not_contains "dispatches nothing"        "$out" 'DISPATCH'

echo "0038 AC9 — verify found a stale contract and sent it to queue/ready: escalate"
scaffold
add_row 0101 'A stale contract' queue ready 0091
add_ticket 0101 queue ready '[]' 0091 a/one.md
seal
out="$(run_next --drive --completed verify:0101)" && rc=0 || rc=$?
assert_rc           "exits 4 — escalate"  "$rc" 4
assert_contains     "names next: queue"   "$out" 'queue'
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

echo "0038 AC9 — a row at next: queue escalates"
scaffold
add_row 0101 'An unspecified ticket' queue ready 0091
add_ticket 0101 queue ready '[]' 0091 a/one.md
seal
out="$(run_next --drive)" && rc=0 || rc=$?
assert_rc           "exits 4 — escalate" "$rc" 4
assert_contains     "escalates"          "$out" 'ESCALATE'
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

echo "0038 AC9 — develop gave the ticket a blocked_by: re-derive and take the next takeable row"
scaffold
add_row 0101 'Newly blocked' develop ready 0091
add_row 0102 'Still takeable' develop ready 0092
add_ticket 0101 develop ready '["0199"]' 0091 a/one.md
add_ticket 0102 develop ready '[]' 0092 b/two.md
add_ticket 0199 develop ready '[]' 0093 c/three.md
seal
out="$(run_next --drive --completed develop:0101)" && rc=0 || rc=$?
assert_rc       "exits 0 — dispatch"            "$rc" 0
assert_contains "says 0101 gained a blocker"    "$out" '0101'
assert_contains "dispatches the next row"       "$out" 'DISPATCH  develop 0102'

echo "0038 AC9 — a close reconciled a dependent from blocked to ready: the row is dispatched"
scaffold
add_row 0102 'A stale blocked column' develop blocked 0092
add_ticket 0102 develop blocked '["0101"]' 0092 b/two.md
add_ticket 0101 develop done '[]' 0091 a/one.md
seal
out="$(run_next --drive)" && rc=0 || rc=$?
assert_rc       "exits 0 — dispatch"        "$rc" 0
assert_contains "dispatches the re-derived row" "$out" 'DISPATCH  develop 0102'

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
assert_contains "lists --drive"    "$out" '--drive'
assert_contains "lists --findings" "$out" '--findings'

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

echo "0038 FR8 — an in-progress row is stepped over, not taken"
scaffold
add_row 0101 'Held by another session' develop in-progress 0091
add_row 0102 'Free'                    develop ready       0092
add_ticket 0101 develop in-progress '[]' 0091 a/one.md
add_ticket 0102 develop ready '[]' 0092 b/two.md
seal
out="$(run_next --drive)" && rc=0 || rc=$?
assert_rc       "exits 0 — dispatch"        "$rc" 0
assert_contains "names the held row"        "$out" '0101'
assert_contains "dispatches the free row"   "$out" 'DISPATCH  develop 0102'

# --- result -----------------------------------------------------------------------------------
echo
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
