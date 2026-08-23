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
ok()  { PASS=$((PASS + 1)); echo "  ok   — $1"; }
bad() { FAIL=$((FAIL + 1)); echo "  FAIL — $1"; }

assert_contains() {
  case "$2" in
    *"$3"*) ok "$1" ;;
    *)      bad "$1"; echo "         expected to contain: $3"; echo "         got: $2" ;;
  esac
}

# Whole-line matching against the file, never a cell this harness looked up itself: a harness that
# reimplements the parser under test passes and fails with it (`testing-conventions.md`).
assert_line() {
  if grep -Fxq "$2" "$FIX/$BL/$3"; then ok "$1"; else
    bad "$1"; echo "         expected line: $2"; echo "         $3 now:"
    sed -n '/^|/p' "$FIX/$BL/$3" | sed 's/^/           /'
  fi
}

refute_line() {
  if grep -Fxq "$2" "$FIX/$BL/$3"; then
    bad "$1"; echo "         expected NOT to find: $2"
  else ok "$1"; fi
}

assert_clean() {
  if [ -z "$(git -C "$FIX" status --porcelain)" ]; then ok "$1"; else
    bad "$1"; echo "         still dirty:"; git -C "$FIX" status --porcelain | sed 's/^/           /'
  fi
}

assert_no_lock() {
  if [ -d "$FIX/$BL/.lock" ]; then bad "$1"; else ok "$1"; fi
}

FIVE_HEAD='| ID | Title | Next | Status | Parent |'
FIVE_SEP='|------|-------|------|--------|--------|'

# --- AC1 — the whole close, in one step -------------------------------------------------------
echo "AC1 — a claimed next:verify row is closed, moved, and committed"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0001 | A fixture row | verify | in-progress | 0000 |'
mkitem 0001 verify in-progress '"ab12"' '[]'
commit_fixture
out="$(run_close 0001 ab12)" && rc=0 || rc=$?
[ "$rc" -eq 0 ] && ok "exits 0" || { bad "exits 0 (got $rc)"; echo "         got: $out"; }
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
[ "$paths" = "$expect" ] && ok "commits exactly the three paths" || {
  bad "commits exactly the three paths"; echo "         expected: $expect"; echo "         got:      $paths"; }

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
[ "$rc" -ne 0 ] && ok "exits non-zero" || bad "exits non-zero (got 0)"
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
[ "$rc" -ne 0 ] && ok "exits non-zero" || bad "exits non-zero (got 0)"
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
[ "$rc" -ne 0 ] && ok "exits non-zero" || bad "exits non-zero (got 0)"
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
[ "$rc" -ne 0 ] && ok "exits non-zero" || bad "exits non-zero (got 0)"
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
[ "$rc" -eq 0 ] && ok "exits 0" || { bad "exits 0 (got $rc)"; echo "         got: $out"; }
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
[ "$rc" -eq 0 ] && ok "exits 0" || { bad "exits 0 (got $rc)"; echo "         got: $out"; }
assert_line "the freed row is set ready"          '| 0008 | Freed by the close | develop | ready | 0000 |' QUEUE.md
assert_line "the still-blocked row is untouched"  '| 0009 | Still blocked by another | develop | blocked | 0000 |' QUEUE.md
assert_contains "the freed item is ready"         "$(cat "$FIX/$BL/items/0008-fixture.md")" 'status: ready'
assert_contains "the still-blocked item is blocked" "$(cat "$FIX/$BL/items/0009-fixture.md")" 'status: blocked'
assert_line "a row blocked by an unreadable ticket stays put" '| 0010 | Blocked by a ticket with no item file | develop | blocked | 0000 |' QUEUE.md
assert_contains "the reconcile is reported"       "$out" '0008'
assert_clean "the reconcile landed in the close commit"

# --- result -----------------------------------------------------------------------------------
echo
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
