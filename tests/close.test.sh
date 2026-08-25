#!/bin/sh
#
# Behavioural guard for skills/queue/templates/close.
#
# Same shape as claim.test.sh, and for the same reason: the script edits markdown tables, so its
# only real contract is what it does to a file of a given shape. Each case scaffolds a throwaway
# git repo, runs `close` against it, and asserts on the exit code, the message, and the resulting
# files. Fixtures are removed on the way out, including on failure.
#
# What this exists to catch is the close half of the failure that made `claim` a script: a close
# that edits QUEUE.md and DONE.md but does not commit inside the lock leaves both dirty in a shared
# working tree, so the next window carries the close off under its own message.
#
# Refusals are asserted on the *message* and on *files unchanged*, never on the exit status alone —
# `exits non-zero` is satisfied by the silent refusal the rule exists to forbid
# (`testing-conventions.md`).
#
# Usage:  tests/close.test.sh
#
# Requires: git, sh, awk. No runner — this project has none.

set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
CLOSE_SRC="$ROOT/skills/queue/templates/close"
[ -f "$CLOSE_SRC" ] || { echo "no close script at $CLOSE_SRC" >&2; exit 2; }

PASS=0
FAIL=0
FIX=""

cleanup() { [ -n "$FIX" ] && rm -rf "$FIX"; return 0; }
trap cleanup EXIT INT TERM

BL=".claude/backlog"

# --- fixture ----------------------------------------------------------------------------------
# scaffold <header> <separator> <rows…>  — one argument per data row.
scaffold() {
  cleanup
  FIX="$(mktemp -d)"
  mkdir -p "$FIX/$BL/items"
  git -C "$FIX" init -q
  git -C "$FIX" config user.email test@example.invalid
  git -C "$FIX" config user.name "close test"

  head="$1"; sep="$2"; shift 2
  { printf '# Backlog\n\n'; printf '%s\n%s\n' "$head" "$sep"; for r in "$@"; do printf '%s\n' "$r"; done; } \
    > "$FIX/$BL/QUEUE.md"

  {
    printf '# Done — completed tickets, newest first\n\n'
    printf '| ID | Title | Type | QA | Closed | Item |\n'
    printf '|------|-------|------|----|--------|------|\n'
  } > "$FIX/$BL/DONE.md"

  cp "$CLOSE_SRC" "$FIX/$BL/close"
  chmod +x "$FIX/$BL/close"
}

# mkitem <id> <next> <status> <token> <blocked_by-yaml-list>
mkitem() {
  cat > "$FIX/$BL/items/$1-fixture.md" <<ITEM
---
id: "$1"
title: Fixture $1
type: chore
next: $2
status: $3
qa_level: verify
created: 2026-08-01
blocked_by: $5
claimed_by: $4
claimed_at: 2026-08-01T00:00:00Z
touches:
  - some/reserved/file.md
---

## Acceptance criteria

- [ ] AC1 — first criterion
- [ ] AC2 — second criterion

## Notes & decisions

- [ ] this box is not an AC and must stay unticked
ITEM
}

commit_fixture() { git -C "$FIX" add -A && git -C "$FIX" commit -q -m "fixture"; }

run_close() { (cd "$FIX" && "$BL/close" "$@" 2>&1); }

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

# Whole-line matching against the file, never a cell this harness looked up itself: a harness that
# reimplements the parser under test passes and fails with it (`testing-conventions.md`).
assert_line() {
  rows="$(sed -n '/^|/p' "$FIX/$BL/$3")"
  if grep -Fxq "$2" "$FIX/$BL/$3"; then ok "$1"; saw_on_pass "$3 holds:
$rows"; else
    bad "$1"; echo "         expected line: $2"; saw "$3 holds:
$rows"
  fi
}

refute_contains() {
  case "$2" in
    *"$3"*) bad "$1"; echo "         expected NOT to contain: $3"; saw "$2" ;;
    *)      ok "$1"; saw_on_pass "$2" ;;
  esac
}

refute_line() {
  rows="$(sed -n '/^|/p' "$FIX/$BL/$3")"
  if grep -Fxq "$2" "$FIX/$BL/$3"; then
    bad "$1"; echo "         expected NOT to find: $2"; saw "$3 holds:
$rows"
  else ok "$1"; saw_on_pass "$3 holds:
$rows"; fi
}

assert_clean() {
  dirty="$(git -C "$FIX" status --porcelain)"
  if [ -z "$dirty" ]; then ok "$1"; saw_on_pass "the tree is clean"; else
    bad "$1"; saw "still dirty:
$dirty"
  fi
}

assert_no_lock() {
  if [ -d "$FIX/$BL/.lock" ]; then
    bad "$1"; saw "$BL/.lock is held by: $(cat "$FIX/$BL/.lock/held-by" 2>/dev/null || echo '<no held-by file>')"
  else ok "$1"; saw_on_pass "no $BL/.lock directory"; fi
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

FIVE_HEAD='| ID | Title | Next | Status | Parent |'
FIVE_SEP='|------|-------|------|--------|--------|'

# --- AC1 — the whole close, in one step -------------------------------------------------------
echo "AC1 — a claimed next:verify row is closed, moved, and committed"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0001 | A fixture row | verify | in-progress | 0000 |'
mkitem 0001 verify in-progress '"ab12"' '[]'
commit_fixture
out="$(run_close 0001 ab12)" && rc=0 || rc=$?
assert_rc "exits 0" "$rc" 0 "$out"
refute_line "the row is gone from QUEUE.md" '| 0001 | A fixture row | verify | in-progress | 0000 |' QUEUE.md
assert_line "the row is in DONE.md" '| 0001 | A fixture row | chore | verify | '"$(date -u +%Y-%m-%d)"' | [items/0001-fixture.md](items/0001-fixture.md) |' DONE.md
item="$(cat "$FIX/$BL/items/0001-fixture.md")"
assert_contains "the item is done"          "$item" 'status: done'
assert_contains "the close date is written" "$item" "closed: $(date -u +%Y-%m-%d)"
assert_contains "AC1 is ticked"             "$item" '- [x] AC1'
assert_contains "AC2 is ticked"             "$item" '- [x] AC2'
assert_contains "a non-AC box is untouched" "$item" '- [ ] this box is not an AC'
assert_contains "the claim is released"     "$item" 'claimed_by:
claimed_at:
touches:'
assert_contains "the close is committed" "$(git -C "$FIX" log -1 --format=%s)" 'Close 0001 [ab12]'
paths="$(git -C "$FIX" log -1 --name-only --format= | grep . | sort | tr '\n' ' ')"
expect="$BL/DONE.md $BL/QUEUE.md $BL/items/0001-fixture.md "
if [ "$paths" = "$expect" ]; then ok "commits exactly the three paths"; saw_on_pass "$paths"; else
  bad "commits exactly the three paths"; echo "         expected: $expect"; saw "$paths"; fi

# --- AC2 — the lock is gone and nothing is left dirty -----------------------------------------
echo "AC2 — the commit precedes the release, and the lock is gone"
assert_no_lock "the lock directory is removed"
assert_clean   "nothing is left uncommitted"

# --- AC3 — a row at another stage --------------------------------------------------------------
echo "AC3 — a row whose next is not verify is refused"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0002 | Still building | develop | in-progress | 0000 |'
mkitem 0002 develop in-progress '"ab12"' '[]'
commit_fixture
out="$(run_close 0002 ab12)" && rc=0 || rc=$?
assert_rc_nonzero "exits non-zero" "$rc" "$out"
assert_contains "names the stage it found" "$out" 'develop'
assert_contains "names the stage required" "$out" 'verify'
assert_line  "the row is untouched"     '| 0002 | Still building | develop | in-progress | 0000 |' QUEUE.md
refute_line  "DONE.md is untouched"     '| 0002 | Still building | chore | verify | '"$(date -u +%Y-%m-%d)"' | [items/0002-fixture.md](items/0002-fixture.md) |' DONE.md
assert_clean "no file was changed"
assert_no_lock "the lock is released on refusal"

# --- AC4 — someone else's claim ---------------------------------------------------------------
echo "AC4 — a mismatched claim token is refused"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0003 | Another window has it | verify | in-progress | 0000 |'
mkitem 0003 verify in-progress '"ab12"' '[]'
commit_fixture
out="$(run_close 0003 ff99)" && rc=0 || rc=$?
assert_rc_nonzero "exits non-zero" "$rc" "$out"
assert_contains "names the token it was given" "$out" 'ff99'
assert_contains "names the token that holds it" "$out" 'ab12'
assert_line  "the row is untouched" '| 0003 | Another window has it | verify | in-progress | 0000 |' QUEUE.md
assert_clean "no file was changed"
assert_no_lock "the lock is released on refusal"

# --- AC5 — a shape it cannot read -------------------------------------------------------------
echo "AC5 — a table missing a column it needs is an error, not a refusal"
scaffold '| ID | Title | Status | Parent |' '|------|-------|--------|--------|' '| 0004 | No Next column | in-progress | 0000 |'
mkitem 0004 verify in-progress '"ab12"' '[]'
commit_fixture
out="$(run_close 0004 ab12)" && rc=0 || rc=$?
assert_rc_nonzero "exits non-zero" "$rc" "$out"
assert_contains "says which column is missing" "$out" 'Next'
assert_contains "quotes the header it found"   "$out" 'ID | Title | Status | Parent'
assert_line  "the row is untouched" '| 0004 | No Next column | in-progress | 0000 |' QUEUE.md
assert_clean "no file was changed"
assert_no_lock "the lock is released on an error"

# --- AC6 — the trap, on a failure between the edit and the commit -----------------------------
echo "AC6 — a commit that cannot run releases the lock and says so"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0005 | Uncommittable | verify | in-progress | 0000 |'
mkitem 0005 verify in-progress '"ab12"' '[]'
commit_fixture
out="$( (cd "$FIX" && GIT_DIR=/nonexistent-close-test "$BL/close" 0005 ab12 2>&1) )" && rc=0 || rc=$?
assert_rc_nonzero "exits non-zero" "$rc" "$out"
assert_contains "says the edits are uncommitted" "$out" 'uncommitted'
# Not just any refusal: the retry loop's "git busy" also contains "uncommitted", and is a lie when
# the repository is simply absent. Assert the reason, not only that something was said.
assert_contains "names the real reason, not a false 'git busy'" "$out" 'not a git repository'
assert_no_lock  "the trap released the lock"

# --- FR1 — column order is not a contract -----------------------------------------------------
# No AC pins order-independence, and the ACs above are all satisfiable by a fixed-index parser.
# This is the defect 0022 found in claim, and a second parser is a second chance to repeat it.
echo "FR1 — a reordered table closes by name, not by index"
scaffold '| Next | ID | Status | Title | Parent |' '|------|------|--------|-------|--------|' '| verify | 0006 | in-progress | Reordered | 0000 |'
mkitem 0006 verify in-progress '"ab12"' '[]'
commit_fixture
out="$(run_close 0006 ab12)" && rc=0 || rc=$?
assert_rc "exits 0" "$rc" 0 "$out"
refute_line "the row is gone" '| verify | 0006 | in-progress | Reordered | 0000 |' QUEUE.md
assert_line "the title came from the Title cell, not a position" \
  '| 0006 | Reordered | chore | verify | '"$(date -u +%Y-%m-%d)"' | [items/0006-fixture.md](items/0006-fixture.md) |' DONE.md

# --- AC8 — the close reconciles its dependents ------------------------------------------------
# 0024: `blocked` is derived, and the close is the only event that can clear a row naming this
# ticket. A close that skips it leaves the queue lying about what is takeable.
echo "AC8 — closing reconciles every row that named this ticket in blocked_by"
scaffold "$FIVE_HEAD" "$FIVE_SEP" \
  '| 0007 | The blocker | verify | in-progress | 0000 |' \
  '| 0008 | Freed by the close | develop | blocked | 0000 |' \
  '| 0009 | Still blocked by another | develop | blocked | 0000 |' \
  '| 0010 | Blocked by a ticket with no item file | develop | blocked | 0000 |'
mkitem 0007 verify in-progress '"ab12"' '[]'
mkitem 0008 develop blocked '' '["0007"]'
mkitem 0009 develop blocked '' '["0007", "0099"]'
mkitem 0099 develop ready '' '[]'
# 0404 has no item file at all. Unrecognised is not the safe default: a blocker the script cannot
# read counts as open, so freeing this row would be the wrong direction to fail in.
mkitem 0010 develop blocked '' '["0007", "0404"]'
commit_fixture
out="$(run_close 0007 ab12)" && rc=0 || rc=$?
assert_rc "exits 0" "$rc" 0 "$out"
assert_line "the freed row is set ready"          '| 0008 | Freed by the close | develop | ready | 0000 |' QUEUE.md
assert_line "the still-blocked row is untouched"  '| 0009 | Still blocked by another | develop | blocked | 0000 |' QUEUE.md
assert_contains "the freed item is ready"         "$(cat "$FIX/$BL/items/0008-fixture.md")" 'status: ready'
assert_contains "the still-blocked item is blocked" "$(cat "$FIX/$BL/items/0009-fixture.md")" 'status: blocked'
assert_line "a row blocked by an unreadable ticket stays put" '| 0010 | Blocked by a ticket with no item file | develop | blocked | 0000 |' QUEUE.md
assert_contains "the reconcile is reported"       "$out" '0008'
assert_clean "the reconcile landed in the close commit"

# --- AC9/AC10 — a dependent with no QUEUE.md row -----------------------------------------------
# The reconcile's only ownership guard was a `QUEUE.md` row, so a dependent with no row was
# rewritten unconditionally. Both states below are reachable and neither is visible to AC8, whose
# three dependents all have rows. `blocked_by` is never cleared at close, so a closed ticket names
# its blockers for ever — selecting on `blocked_by` alone resurrects it.
echo "AC9/AC10 — a rowless dependent is neither resurrected nor overwritten"
scaffold "$FIVE_HEAD" "$FIVE_SEP" \
  '| 0020 | The blocker | verify | in-progress | 0000 |' \
  '| 0021 | Freed by the close | develop | blocked | 0000 |' \
  '| 0024 | Row says in-progress, item carries no token | develop | in-progress | 0000 |'
mkitem 0020 verify in-progress '"ab12"' '[]'
mkitem 0021 develop blocked '' '["0020"]'
# Closed months ago, still naming the blocker it was closed under, and long gone from QUEUE.md.
mkitem 0022 develop done '' '["0020"]'
# Held by another session, and likewise rowless. Ownership lives in the item's claimed_by:, which
# is the one place the old guard did not look (CONCURRENCY.md, 'Claim tokens').
mkitem 0023 develop in-progress '"ff99"' '["0020"]'
# An `in-progress` row over an item carrying no token is DRIFT, not ownership (0029). `held` has
# one definition — a non-empty `claimed_by:` — so this dependent is freed like any other, and
# `./next --drift` is what reports the stale cell. Asserted below in the same run as 0023, so the
# suite pins both directions of the definition against each other.
mkitem 0024 develop blocked '' '["0020"]'
# Already unblocked and still naming this ticket: there is nothing to free, so it must not be
# rewritten, reported, or dragged into the close commit. This is what makes the guard an allowlist
# on `blocked` rather than a denylist on `done`.
mkitem 0025 develop ready '' '["0020"]'
commit_fixture
out="$(run_close 0020 ab12)" && rc=0 || rc=$?
assert_rc "exits 0" "$rc" 0 "$out"
assert_line "the rowed dependent is still freed" '| 0021 | Freed by the close | develop | ready | 0000 |' QUEUE.md
done_dep="$(cat "$FIX/$BL/items/0022-fixture.md")"
assert_contains  "AC9 — the closed dependent stays done"    "$done_dep" 'status: done'
refute_contains  "AC9 — it is not reported as freed"        "$out" '0022'
held_dep="$(cat "$FIX/$BL/items/0023-fixture.md")"
assert_contains  "AC10/0029 AC5 — the held dependent is not rewritten" "$held_dep" 'status: in-progress'
assert_contains  "AC10/0029 AC5 — its claim is intact"                 "$held_dep" 'claimed_by: "ff99"'
assert_contains  "AC10/0029 AC5 — it is reported, not silently skipped" "$out" 'left alone'
assert_contains  "AC10/0029 AC5 — the report names it"                  "$out" '0023'
rowdrift_dep="$(cat "$FIX/$BL/items/0024-fixture.md")"
assert_contains  "AC4 — a tokenless dependent is freed however its row reads" "$rowdrift_dep" 'status: ready'
assert_line "AC4 — and its stale in-progress cell is corrected" '| 0024 | Row says in-progress, item carries no token | develop | ready | 0000 |' QUEUE.md
refute_contains  "AC4 — it is not reported as held"  "$(printf '%s' "$out" | grep 'left alone' || true)" '0024'
assert_contains  "AC4 — it is reported as reconciled" "$(printf '%s' "$out" | grep 'reconciled' || true)" '0024'
unblocked_dep="$(cat "$FIX/$BL/items/0025-fixture.md")"
assert_contains  "FR7 — an already-unblocked dependent is untouched"     "$unblocked_dep" 'status: ready'
refute_contains  "FR7 — and not reported as freed"                       "$(printf '%s' "$out" | grep 'reconciled' || true)" '0025'
paths="$(git -C "$FIX" log -1 --name-only --format= | grep . | sort | tr '\n' ' ')"
expect="$BL/DONE.md $BL/QUEUE.md $BL/items/0020-fixture.md $BL/items/0021-fixture.md $BL/items/0024-fixture.md "
[ "$paths" = "$expect" ] && ok "commits only the row it closed and the rows it freed" || {
  bad "commits only the row it closed and the rows it freed"; echo "         expected: $expect"; echo "         got:      $paths"; }
assert_clean "nothing is left uncommitted"

# --- result -----------------------------------------------------------------------------------
echo
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
