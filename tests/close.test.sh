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


# The same item, but with `touches:` written as a block sequence at the SAME indentation as its key.
# YAML permits it, `item.md` does not forbid it, and the skiplist that clears the block required
# leading whitespace — so a closed ticket went on naming files every other window must read as held
# (`CONCURRENCY.md`, *The working tree is shared too*). Flush-left is the whole point of the
# fixture: indent these two entries and the case can no longer fail (0090 FR1).
# mkitem_flush_touches <id> <next> <status> <token>
mkitem_flush_touches() {
  cat > "$FIX/$BL/items/$1-fixture.md" <<ITEM
---
id: "$1"
title: Fixture $1
type: chore
next: $2
status: $3
qa_level: verify
created: 2026-08-01
blocked_by: []
claimed_by: $4
claimed_at: 2026-08-01T00:00:00Z
touches:
- src/a.ts
- src/b.ts
---

## Acceptance criteria

- [ ] AC1 — first criterion
- [ ] AC2 — second criterion
ITEM
}
# An item whose acceptance criteria carry NO checkbox — the `- **AC1** —` form real tickets have
# been written in. `close` ticks nothing here, and 0044 FR5 makes that a refusal rather than a
# success the reader cannot tell from a real one.
# mkitem_plain_acs <id> <next> <status> <token>
mkitem_plain_acs() {
  cat > "$FIX/$BL/items/$1-fixture.md" <<ITEM
---
id: "$1"
title: Fixture $1
type: chore
next: $2
status: $3
qa_level: verify
created: 2026-08-01
blocked_by: []
claimed_by: $4
claimed_at: 2026-08-01T00:00:00Z
touches:
---

## Acceptance criteria

- **AC1** — Given a criterion with no checkbox, when close runs, then it cannot be ticked
- **AC2** — And neither can this one
ITEM
}

# An item with an empty acceptance-criteria section. Nothing to tick is not the same defect as
# criteria that cannot be ticked, and the refusal must tell them apart.
# mkitem_no_acs <id> <next> <status> <token>
mkitem_no_acs() {
  cat > "$FIX/$BL/items/$1-fixture.md" <<ITEM
---
id: "$1"
title: Fixture $1
type: chore
next: $2
status: $3
qa_level: verify
created: 2026-08-01
blocked_by: []
claimed_by: $4
claimed_at: 2026-08-01T00:00:00Z
touches:
---

## Acceptance criteria

## Notes & decisions
ITEM
}

# An item whose acceptance criteria are a NUMBERED list. Six real items were captured in this
# form against a template stating one form only, and the `- ` counter read them as an empty
# section — so `close` reported success having ticked none of them, in the same words as a real
# close. The refusal counts any list marker, so every non-checkbox form reaches it.
# mkitem_numbered_acs <id> <next> <status> <token>
mkitem_numbered_acs() {
  cat > "$FIX/$BL/items/$1-fixture.md" <<ITEM
---
id: "$1"
title: Fixture $1
type: chore
next: $2
status: $3
qa_level: verify
created: 2026-08-01
blocked_by: []
claimed_by: $4
claimed_at: 2026-08-01T00:00:00Z
touches:
---

## Acceptance criteria

1. AC1 — Given criteria written as a numbered list, when close runs, then none can be ticked
2. AC2 — And neither can this one
3. AC3 — Nor this one
ITEM
}

# --- 0086 fixtures: the light tier ------------------------------------------------------------
# A `close_by: develop` item is closed by the session that BUILT it, so its fixture row sits at
# `next: develop` rather than `next: verify`. Eligibility is that every AC cites a committed
# assertion, so the fixture repo has to contain the file each AC names — `commit_fixture` does
# `git add -A`, which is what makes the cited path genuinely tracked rather than merely present.
mkguard() {
  mkdir -p "$FIX/tests"
  printf '#!/bin/sh\necho "1 passed, 0 failed"\n' > "$FIX/tests/guard.test.sh"
  chmod +x "$FIX/tests/guard.test.sh"
}

# mkitem_light <id> <next> <status> <token> <close_by-line> <qa_level> [extra-section]
# `close_by-line` is passed WHOLE so a case can hand in the empty string and get an item with no
# such line at all — which is 0086 AC9's subject, and the migration NFR's.
mkitem_light() {
  mkguard
  cat > "$FIX/$BL/items/$1-fixture.md" <<ITEM
---
id: "$1"
title: Fixture $1
type: chore
next: $2
status: $3
qa_level: ${6:-unit}
$5
created: 2026-08-01
blocked_by: []
claimed_by: $4
claimed_at: 2026-08-01T00:00:00Z
touches:
---

## Acceptance criteria

- [ ] AC1 — first criterion. Guard: \`tests/guard.test.sh\`, proved red before green.
- [ ] AC2 — second criterion, same guard: \`tests/guard.test.sh\`.
${7:-}
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

# Whole-string equality, for "this file is byte-identical to what it was". assert_contains would
# pass on a file that had merely GROWN, which is the direction a wrongly-carried row moves it.
assert_eq() {
  if [ "$2" = "$3" ]; then ok "$1"; saw_on_pass "$2"; else
    bad "$1"; echo "         expected exactly: $3"; saw "$2"; fi
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
if [ "$paths" = "$expect" ]; then ok "commits only the row it closed and the rows it freed"; saw_on_pass "$paths"; else
  bad "commits only the row it closed and the rows it freed"; echo "         expected: $expect"; saw "$paths"; fi
assert_clean "nothing is left uncommitted"

# --- 0044 AC1 — a dependent whose blocked_by is a block list ------------------------------------
# `close` read `blocked_by` with its scalar reader, which returns only what sits after the colon on
# the key's own line — so the block form parsed as empty, the `case` missed, and the dependent was
# never reconciled. Closing 0028 hit exactly this and left 0029 blocked in both the item and the
# row. `next` has read both forms since 0031; this asserts the two scripts agree.
echo "0044 AC1 — a block-list blocked_by is reconciled like the inline form"
scaffold "$FIVE_HEAD" "$FIVE_SEP" \
  '| 0030 | The blocker | verify | in-progress | 0000 |' \
  '| 0031 | Blocked by a block list | develop | blocked | 0000 |' \
  '| 0032 | Blocked by an inline list | develop | blocked | 0000 |'
mkitem 0030 verify in-progress '"ab12"' '[]'
mkitem 0031 develop blocked '' '
  - "0030"'
mkitem 0032 develop blocked '' '["0030"]'
commit_fixture
out="$(run_close 0030 ab12)" && rc=0 || rc=$?
assert_rc "exits 0" "$rc" 0 "$out"
assert_contains "the block-list dependent is freed" "$(cat "$FIX/$BL/items/0031-fixture.md")" 'status: ready'
assert_line "and its row is freed too" '| 0031 | Blocked by a block list | develop | ready | 0000 |' QUEUE.md
assert_contains "the block-list dependent is reported" "$(printf '%s' "$out" | grep 'reconciled' || true)" '0031'
assert_contains "the inline dependent is freed as before" "$(cat "$FIX/$BL/items/0032-fixture.md")" 'status: ready'
assert_clean "both reconciles landed in the close commit"

# --- 0044 AC1 — a block-list entry that is NOT this ticket still blocks --------------------------
# The cheap way to pass the case above is to treat every dependent as naming the closing ticket,
# which frees every dependent of every close. That mutation survives a fixture whose other blocker
# is merely unresolvable — `other_blockers_all_done` refuses it first and the name match is never
# what held. So 0034's blocker is DONE: nothing but the id comparison stands between it and a
# reconcile it has no business getting.
echo "0044 AC1 — a block list naming another ticket is not freed"
scaffold "$FIVE_HEAD" "$FIVE_SEP" \
  '| 0033 | The blocker | verify | in-progress | 0000 |' \
  '| 0034 | Blocked by someone else entirely | develop | blocked | 0000 |'
mkitem 0033 verify in-progress '"ab12"' '[]'
mkitem 0034 develop blocked '' '
  - "0098"'
mkitem 0098 develop done '' '[]'
commit_fixture
out="$(run_close 0033 ab12)" && rc=0 || rc=$?
assert_rc "exits 0" "$rc" 0 "$out"
assert_contains "the unrelated dependent stays blocked" "$(cat "$FIX/$BL/items/0034-fixture.md")" 'status: blocked'
refute_contains "and is not reported as freed" "$(printf '%s' "$out" | grep 'reconciled' || true)" '0034'

# --- 0044 AC2 — a scalar field carrying a trailing YAML comment ---------------------------------
# `develop` Step 1 tells a session to annotate frontmatter inline, and 0031 taught only the LIST
# reader to cope. A comment on `claimed_by:` made the ownership test compare `ab12" # mine` against
# the token and refuse the holder's own close.
echo "0044 AC2 — a commented claimed_by still matches the bare token"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0040 | Annotated claim | verify | in-progress | 0000 |'
mkitem 0040 verify in-progress '"ab12" # minted this session' '[]'
commit_fixture
out="$(run_close 0040 ab12)" && rc=0 || rc=$?
assert_rc "exits 0" "$rc" 0 "$out"
assert_contains "the item is done" "$(cat "$FIX/$BL/items/0040-fixture.md")" 'status: done'
refute_line "the row is gone from QUEUE.md" '| 0040 | Annotated claim | verify | in-progress | 0000 |' QUEUE.md

# --- 0044 AC2 — and a wrong token is still refused, comment or not ------------------------------
echo "0044 AC2 — a commented claim does not accept the wrong token"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0041 | Annotated claim | verify | in-progress | 0000 |'
mkitem 0041 verify in-progress '"ab12" # minted this session' '[]'
commit_fixture
out="$(run_close 0041 zz99)" && rc=0 || rc=$?
assert_rc_nonzero "exits non-zero" "$rc" "$out"
assert_contains "names the holding token without its comment" "$out" "held by token 'ab12'"
assert_line "the row is untouched" '| 0041 | Annotated claim | verify | in-progress | 0000 |' QUEUE.md
assert_clean "no file was changed"

# --- 0044 AC4 — the closed ticket is no longer due at a stage -----------------------------------
# The script path left `next: verify` on a `status: done` ticket; the by-hand path cleared it. The
# item then says a closed ticket is still due at a stage, which is the disagreement the next/status
# split exists to prevent.
echo "0044 AC4 — close clears next: on the ticket it marks done"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0042 | Closed properly | verify | in-progress | 0000 |'
mkitem 0042 verify in-progress '"ab12"' '[]'
commit_fixture
out="$(run_close 0042 ab12)" && rc=0 || rc=$?
assert_rc "exits 0" "$rc" 0 "$out"
item="$(cat "$FIX/$BL/items/0042-fixture.md")"
assert_contains "status is done"  "$item" 'status: done'
assert_contains "next: is empty"  "$item" 'next:
status: done'
refute_contains "no stage is left on it" "$item" 'next: verify'

# --- 0044 AC5 — criteria that cannot be ticked are a refusal ------------------------------------
# `close` ticked zero of eight on 0035's `- **AC1** —` criteria, closed anyway, and reported
# success in the same words as a real close. `verify` closes on ticked ACs, so the one durable
# record that each criterion was checked was simply absent.
echo "0044 AC5 — a criteria list with no checkbox is refused, not silently closed"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0043 | Criteria with no checkboxes | verify | in-progress | 0000 |'
mkitem_plain_acs 0043 verify in-progress '"ab12"'
commit_fixture
out="$(run_close 0043 ab12)" && rc=0 || rc=$?
assert_rc_nonzero "exits non-zero" "$rc" "$out"
assert_contains "says how many it could not tick" "$out" '2'
assert_contains "names the form it needs" "$out" '- [ ]'
assert_line "the row is untouched" '| 0043 | Criteria with no checkboxes | verify | in-progress | 0000 |' QUEUE.md
refute_line "nothing was written to DONE.md" '| 0043 | Criteria with no checkboxes | chore | verify | '"$(date -u +%Y-%m-%d)"' | [items/0043-fixture.md](items/0043-fixture.md) |' DONE.md
assert_contains "the item is not marked done" "$(cat "$FIX/$BL/items/0043-fixture.md")" 'status: in-progress'
assert_clean "no file was changed"
assert_no_lock "the lock is released on the refusal"

# --- 0044 AC5 — an empty criteria section is not the same defect --------------------------------
# Nothing to tick is not criteria that cannot be ticked. Refusing here would block every chore
# ticket written without ACs, which is a different argument and not this ticket's.
echo "0044 AC5 — an empty criteria section still closes"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0044 | No criteria at all | verify | in-progress | 0000 |'
mkitem_no_acs 0044 verify in-progress '"ab12"'
commit_fixture
out="$(run_close 0044 ab12)" && rc=0 || rc=$?
assert_rc "exits 0" "$rc" 0 "$out"
assert_contains "the item is done" "$(cat "$FIX/$BL/items/0044-fixture.md")" 'status: done'

# --- 0044 AC5 — a NUMBERED criteria list is the same defect through a door the counter missed ---
# The counter was `in_ac && /^- /`, so a `1.`/`2.`/`3.` list yielded zero bullets and fell through
# to the "an empty criteria section still closes" allowance below — a silent close recording that
# nothing was checked. Six of 102 items were captured in this form, three of them at next: verify.
echo "0044 AC5 — a numbered criteria list is refused, not silently closed"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0045 | Criteria as a numbered list | verify | in-progress | 0000 |'
mkitem_numbered_acs 0045 verify in-progress '"ab12"'
commit_fixture
out="$(run_close 0045 ab12)" && rc=0 || rc=$?
assert_rc_nonzero "exits non-zero" "$rc" "$out"
assert_contains "says how many it could not tick" "$out" '3'
assert_contains "names the form it needs" "$out" '- [ ]'
assert_line "the row is untouched" '| 0045 | Criteria as a numbered list | verify | in-progress | 0000 |' QUEUE.md
assert_contains "the item is not marked done" "$(cat "$FIX/$BL/items/0045-fixture.md")" 'status: in-progress'
assert_clean "no file was changed"
assert_no_lock "the lock is released on the refusal"

# --- 0044 AC5 — an asterisk bullet reaches the refusal too -------------------------------------
# `*` is the other list marker CommonMark allows. Counting only `-` and `1.` would leave one more
# door open, and the point of the widened matcher is that NO non-checkbox form closes silently.
echo "0044 AC5 — an asterisk criteria list is refused too"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0046 | Criteria as asterisks | verify | in-progress | 0000 |'
mkitem_numbered_acs 0046 verify in-progress '"ab12"'
sed -i.bak 's/^1\. AC1/* AC1/; s/^2\. AC2/* AC2/; s/^3\. AC3/* AC3/' "$FIX/$BL/items/0046-fixture.md"
rm -f "$FIX/$BL/items/0046-fixture.md.bak"
commit_fixture
out="$(run_close 0046 ab12)" && rc=0 || rc=$?
assert_rc_nonzero "exits non-zero" "$rc" "$out"
assert_contains "says how many it could not tick" "$out" '3'
assert_clean "no file was changed"

# ===============================================================================================
# 0086 — close_by: the light tier. `close` gains a fifth refusal ground, and the ONE stage other
# than `verify` that may close a row.
#
# WHAT THESE CASES CANNOT SEE, stated here because it is the trade-off the ticket accepted rather
# than an omission: `close` checks that each light AC *cites* a committed guard. It cannot check
# that the guard CAN FAIL. That is this repo's known failure mode (`testing-conventions.md`, a
# guard only ever seen passing is indistinguishable from one wired to nothing), and the residual
# risk moves from "nobody checked" to "the builder's own recorded red" — deliberately weaker than
# an independent read, and kept narrow by the eligibility rule alone.
# ===============================================================================================

# --- 0086 AC1 — a light ticket closes from develop ---------------------------------------------
echo "0086 AC1 — close_by: develop closes a next:develop row whose every AC cites a guard"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0050 | A light ticket | develop | in-progress | 0000 |'
mkitem_light 0050 develop in-progress '"ab12"' 'close_by: develop'
commit_fixture
out="$(run_close 0050 ab12)" && rc=0 || rc=$?
assert_rc "exits 0" "$rc" 0 "$out"
refute_line "the row is gone from QUEUE.md" '| 0050 | A light ticket | develop | in-progress | 0000 |' QUEUE.md
assert_line "the row is in DONE.md" '| 0050 | A light ticket | chore | unit | '"$(date -u +%Y-%m-%d)"' | [items/0050-fixture.md](items/0050-fixture.md) |' DONE.md
item="$(cat "$FIX/$BL/items/0050-fixture.md")"
assert_contains "the item is done"      "$item" 'status: done'
assert_contains "AC1 is ticked"         "$item" '- [x] AC1'
assert_contains "AC2 is ticked"         "$item" '- [x] AC2'
assert_contains "the claim is released" "$item" 'claimed_by:
claimed_at:
touches:'
assert_contains "the close is committed" "$(git -C "$FIX" log -1 --format=%s)" 'Close 0050 [ab12]'
assert_clean   "nothing is left uncommitted"
assert_no_lock "the lock is released"

# --- 0086 AC2 — and only where the item says so ------------------------------------------------
# The mirror case, and the one that makes AC1 evidence rather than a widened door: the SAME row at
# the SAME stage, refused because the item does not opt in. A branch written to accept
# `next: develop` unconditionally passes AC1 and reds here.
echo "0086 AC2 — close_by: verify at next:develop is refused on the existing grounds"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0051 | Not a light ticket | develop | in-progress | 0000 |'
mkitem_light 0051 develop in-progress '"ab12"' 'close_by: verify'
commit_fixture
out="$(run_close 0051 ab12)" && rc=0 || rc=$?
assert_rc_nonzero "exits non-zero" "$rc" "$out"
assert_contains "names the stage it found"   "$out" 'develop'
assert_contains "names the stage required"   "$out" 'verify'
assert_line  "the row is untouched" '| 0051 | Not a light ticket | develop | in-progress | 0000 |' QUEUE.md
assert_contains "the item is not marked done" "$(cat "$FIX/$BL/items/0051-fixture.md")" 'status: in-progress'
assert_clean   "no file was changed"
assert_no_lock "the lock is released on the refusal"

echo "0086 AC2/AC9 — and an item with NO close_by: line behaves exactly as today"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0052 | Field absent entirely | develop | in-progress | 0000 |'
mkitem_light 0052 develop in-progress '"ab12"' ''
refute_contains "the fixture really has no close_by: line" "$(cat "$FIX/$BL/items/0052-fixture.md")" 'close_by'
commit_fixture
out="$(run_close 0052 ab12)" && rc=0 || rc=$?
assert_rc_nonzero "exits non-zero" "$rc" "$out"
assert_contains "absent is read as verify, so the stage refusal fires" "$out" 'verify'
assert_clean   "no file was changed"

echo "0086 AC9 — and an item with no close_by: line still closes normally from next:verify"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0053 | Field absent, at verify | verify | in-progress | 0000 |'
mkitem_light 0053 verify in-progress '"ab12"' ''
commit_fixture
out="$(run_close 0053 ab12)" && rc=0 || rc=$?
assert_rc "exits 0" "$rc" 0 "$out"
assert_contains "the item is done" "$(cat "$FIX/$BL/items/0053-fixture.md")" 'status: done'

# --- 0086 AC3 — an AC with no citation is refused, BY NAME -------------------------------------
# Asserted on the criterion's own text, never on the count: "one of two criteria" is satisfied by a
# check that counts the SECTION, which is the implementation this case exists to exclude (FR3).
echo "0086 AC3 — a light AC citing no assertion is refused and named"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0054 | One uncited criterion | develop | in-progress | 0000 |'
mkitem_light 0054 develop in-progress '"ab12"' 'close_by: develop'
# Strip the citation from AC2 ALONE, so AC1 still carries one: a check that gives up at the first
# bullet, or that requires every bullet to fail, cannot tell this fixture from a wholly uncited one.
sed -i.bak 's|^- \[ \] AC2 — second criterion.*|- [ ] AC2 — second criterion, verified by eye.|' "$FIX/$BL/items/0054-fixture.md"
rm -f "$FIX/$BL/items/0054-fixture.md.bak"
commit_fixture
out="$(run_close 0054 ab12)" && rc=0 || rc=$?
assert_rc_nonzero "exits non-zero" "$rc" "$out"
assert_contains "names the criterion that failed"    "$out" 'AC2 — second criterion, verified by eye.'
refute_contains "and does not accuse the cited one"  "$out" 'AC1 — first criterion'
assert_line "the row is untouched" '| 0054 | One uncited criterion | develop | in-progress | 0000 |' QUEUE.md
assert_contains "the item is not marked done" "$(cat "$FIX/$BL/items/0054-fixture.md")" 'status: in-progress'
refute_contains "and no criterion was ticked"  "$(cat "$FIX/$BL/items/0054-fixture.md")" '- [x]'
assert_clean   "the tree is exactly as it was found"
assert_no_lock "the lock is released on the refusal"

# --- 0086 AC3 — a cited path that git does not track is not a citation -------------------------
# "Committed" is the half of FR3 a path check alone cannot see: a guard written this session and
# never added is not evidence anything ran, and the file exists on disk either way.
echo "0086 AC3 — a cited guard that is untracked is refused"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0055 | Cites an uncommitted guard | develop | in-progress | 0000 |'
mkitem_light 0055 develop in-progress '"ab12"' 'close_by: develop'
commit_fixture
# Written AFTER the fixture commit and never added — on disk, unknown to git.
printf '#!/bin/sh\nexit 0\n' > "$FIX/tests/untracked.test.sh"
sed -i.bak 's|tests/guard.test.sh|tests/untracked.test.sh|g' "$FIX/$BL/items/0055-fixture.md"
rm -f "$FIX/$BL/items/0055-fixture.md.bak"
out="$(run_close 0055 ab12)" && rc=0 || rc=$?
assert_rc_nonzero "exits non-zero" "$rc" "$out"
assert_contains "names the criterion"  "$out" 'AC1 — first criterion'
# The two ways a citation fails have different fixes — add the guard, or cite a different file —
# and a message collapsing them sends the reader to the wrong one. Asserted in both directions,
# because a single reason string satisfies either assertion on its own.
assert_contains "says the path is not committed"     "$out" 'names no committed path'
refute_contains "and not that it is the wrong KIND"  "$out" 'is not an assertion'
assert_contains "the item is not marked done" "$(cat "$FIX/$BL/items/0055-fixture.md")" 'status: in-progress'

# --- 0086 AC4 — review and develop cannot be carried together ----------------------------------
# The two fields are orthogonal and their ONE interaction is this refusal. Checked together, or a
# review's judgement calls close on the builder's own reading, which FR3 admits no case of.
echo "0086 AC4 — qa_level: review with close_by: develop is refused"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0056 | A reviewed light ticket | develop | in-progress | 0000 |'
mkitem_light 0056 develop in-progress '"ab12"' 'close_by: develop' review
commit_fixture
out="$(run_close 0056 ab12)" && rc=0 || rc=$?
assert_rc_nonzero "exits non-zero" "$rc" "$out"
assert_contains "names both fields"  "$out" 'review'
assert_contains "and the other one"  "$out" 'close_by: develop'
assert_line "the row is untouched" '| 0056 | A reviewed light ticket | develop | in-progress | 0000 |' QUEUE.md
assert_contains "the item is not marked done" "$(cat "$FIX/$BL/items/0056-fixture.md")" 'status: in-progress'
assert_clean   "no file was changed"
assert_no_lock "the lock is released on the refusal"

echo "0086 AC4 — and qa_level: review with close_by absent is NOT this refusal"
# The mirror that keeps AC4 from being satisfied by refusing every `review` ticket outright.
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0057 | A reviewed normal ticket | verify | in-progress | 0000 |'
mkitem_light 0057 verify in-progress '"ab12"' '' review
commit_fixture
out="$(run_close 0057 ab12)" && rc=0 || rc=$?
assert_rc "exits 0" "$rc" 0 "$out"
assert_contains "the item is done" "$(cat "$FIX/$BL/items/0057-fixture.md")" 'status: done'

# --- 0086 AC5 — an unperformed review checklist is refused -------------------------------------
# The guard for the PROSE half of this ticket, and the reason it is asserted on the count of TICKED
# boxes rather than on the section's presence: a `review` level declared and never performed closes
# with a checklist full of bullets, and DONE.md cannot tell it from a performed one. Applies to
# every close, not only a light one — an unperformed checklist is the same defect at either tier.
#
# TWO REFUSAL CASES, AND THE SECOND IS THE LOAD-BEARING ONE. Plain bullets are refused, and so are
# `- [ ]` boxes with none ticked — which is the input the instructions actually produce, and which
# the first implementation closed on because its counter accepted a space inside the brackets. A
# suite carrying only the plain-bullet case reads as covering this rule and cannot see the defect.
echo "0086 AC5 — a Review checklist of bullets with no checkbox is refused"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0058 | Checklist never performed | verify | in-progress | 0000 |'
mkitem_light 0058 verify in-progress '"ab12"' '' review '
## Review checklist

- Does the rule earn its context rent?
- Is it a principle or a preference, and in the right file for that?
- Does it contradict a rule stated elsewhere?
'
commit_fixture
out="$(run_close 0058 ab12)" && rc=0 || rc=$?
assert_rc_nonzero "exits non-zero" "$rc" "$out"
assert_contains "quotes the count it could not tick" "$out" '3'
assert_contains "names the section"                  "$out" 'Review checklist'
assert_contains "names the form it needs"            "$out" '- [ ]'
assert_line "the row is untouched" '| 0058 | Checklist never performed | verify | in-progress | 0000 |' QUEUE.md
assert_contains "the item is not marked done" "$(cat "$FIX/$BL/items/0058-fixture.md")" 'status: in-progress'
assert_clean   "no file was changed"
assert_no_lock "the lock is released on the refusal"

echo "0086 AC5 — a checklist whose boxes are ticked closes"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0059 | Checklist performed | verify | in-progress | 0000 |'
mkitem_light 0059 verify in-progress '"ab12"' '' review '
## Review checklist

- [x] Does the rule earn its context rent? Yes — it replaces two paragraphs.
- [x] Principle, and it is in the right file.
'
commit_fixture
out="$(run_close 0059 ab12)" && rc=0 || rc=$?
assert_rc "exits 0" "$rc" 0 "$out"
assert_contains "the item is done" "$(cat "$FIX/$BL/items/0059-fixture.md")" 'status: done'

echo "0086 AC5 — and a partly-ticked checklist closes too, the same as the ACs"
# `close` ticks the ACs it is given and refuses only a list it cannot tick AT ALL. A half-performed
# checklist is a verdict a reader can see; refusing it would be a stricter rule than FR11 states,
# and FR11 says "on the same grounds as its fourth refusal for ACs".
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0060 | Checklist half performed | verify | in-progress | 0000 |'
mkitem_light 0060 verify in-progress '"ab12"' '' review '
## Review checklist

- [x] Does the rule earn its context rent?
- [ ] Principle or preference?
'
commit_fixture
out="$(run_close 0060 ab12)" && rc=0 || rc=$?
assert_rc "exits 0" "$rc" 0 "$out"
assert_contains "the item is done" "$(cat "$FIX/$BL/items/0060-fixture.md")" 'status: done'

echo "0086 AC5 — an EMPTY Review checklist section is not this defect"
# Same allowance the AC refusal makes: nothing to tick is not a list that cannot be ticked.
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0061 | Checklist section empty | verify | in-progress | 0000 |'
mkitem_light 0061 verify in-progress '"ab12"' '' unit '
## Review checklist
'
commit_fixture
out="$(run_close 0061 ab12)" && rc=0 || rc=$?
assert_rc "exits 0" "$rc" 0 "$out"
assert_contains "the item is done" "$(cat "$FIX/$BL/items/0061-fixture.md")" 'status: done'

echo "0086 AC5 — a checklist of UNTICKED CHECKBOXES is refused too"
# The input every instruction actually produces, and the one the first implementation closed on.
# FR11, `verify` Step 2 ("record one checkbox per checklist line") and `close`'s own refusal
# message all tell a session to write `- [ ] …` lines, so a session that writes them and then stops
# is the commonest unperformed review there is. The counter that scored them read
# `/^- \[[ xX]\]/` — a class containing a SPACE — so three unticked boxes counted as three boxes
# and the row closed with the checklist unperformed, which is the presence-not-ticked-ness shape
# AC5 exists to exclude. The plain-bullet case above cannot reach this: it is the one input no
# instruction produces.
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0067 | Boxes drawn, none ticked | verify | in-progress | 0000 |'
mkitem_light 0067 verify in-progress '"ab12"' '' review '
## Review checklist

- [ ] Does the rule earn its context rent?
- [ ] Is it a principle or a preference, and in the right file for that?
- [ ] Does it contradict a rule stated elsewhere?
'
commit_fixture
out="$(run_close 0067 ab12)" && rc=0 || rc=$?
assert_rc_nonzero "exits non-zero" "$rc" "$out"
assert_contains "quotes the count it could not tick" "$out" '3'
assert_contains "names the section"                  "$out" 'Review checklist'
assert_contains "says nothing was TICKED, not that nothing is a checkbox" "$out" 'not one of them is ticked'
assert_contains "names the ticked form it wants"     "$out" '- [x]'
assert_line "the row is untouched" '| 0067 | Boxes drawn, none ticked | verify | in-progress | 0000 |' QUEUE.md
assert_contains "the item is not marked done" "$(cat "$FIX/$BL/items/0067-fixture.md")" 'status: in-progress'
refute_contains "and DONE.md did not gain it" "$(cat "$FIX/$BL/DONE.md")" '0067'
assert_clean   "no file was changed"
assert_no_lock "the lock is released on the refusal"

# --- 0086 FR3 — a light ticket with NO criteria is refused, where a verify one closes ----------
# "Every criterion is an assertion" is vacuously true of none, and honouring that reading closes a
# self-certified row having checked nothing — the "self-attested" tier 0086 rejected. The pair of
# cases is the point: the SAME empty section still closes at `close_by: verify`, so this is a rule
# about the tier and not a new restriction on every chore written without ACs.
echo "0086 FR3 — a light ticket with an empty criteria section is refused"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0064 | Light, no criteria | develop | in-progress | 0000 |'
mkitem_light 0064 develop in-progress '"ab12"' 'close_by: develop'
# Empty the criteria section, leaving the heading — the shape a chore ticket has.
sed -i.bak '/^- \[ \] AC[12] —/d' "$FIX/$BL/items/0064-fixture.md"
rm -f "$FIX/$BL/items/0064-fixture.md.bak"
commit_fixture
out="$(run_close 0064 ab12)" && rc=0 || rc=$?
assert_rc_nonzero "exits non-zero" "$rc" "$out"
assert_contains "says the criteria are missing, not that a citation is" "$out" 'no acceptance criteria'
assert_line "the row is untouched" '| 0064 | Light, no criteria | develop | in-progress | 0000 |' QUEUE.md
assert_clean "no file was changed"

echo "0086 FR3 — and the same empty section still closes at close_by: verify"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0065 | Not light, no criteria | verify | in-progress | 0000 |'
mkitem_light 0065 verify in-progress '"ab12"' 'close_by: verify'
sed -i.bak '/^- \[ \] AC[12] —/d' "$FIX/$BL/items/0065-fixture.md"
rm -f "$FIX/$BL/items/0065-fixture.md.bak"
commit_fixture
out="$(run_close 0065 ab12)" && rc=0 || rc=$?
assert_rc "exits 0" "$rc" 0 "$out"
assert_contains "the item is done" "$(cat "$FIX/$BL/items/0065-fixture.md")" 'status: done'

# --- 0086 FR3 — a criterion whose citation is wrapped onto its continuation line ---------------
# This repo's criteria run three and four lines, and a line-based reader judges each fragment
# separately — refusing the wrapped half of a perfectly cited criterion. The guard folds
# continuations into their bullet, and this is the case that proves it does.
echo "0086 FR3 — a citation on a continuation line counts"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0066 | Wrapped citation | develop | in-progress | 0000 |'
mkitem_light 0066 develop in-progress '"ab12"' 'close_by: develop'
python3 - "$FIX/$BL/items/0066-fixture.md" <<'PYEOF'
import sys
p = sys.argv[1]
s = open(p).read()
s = s.replace(
  "- [ ] AC1 — first criterion. Guard: `tests/guard.test.sh`, proved red before green.",
  "- [ ] AC1 — first criterion, whose sentence runs long enough that the guard it names\n      lands on the next source line entirely. Guard: `tests/guard.test.sh`.")
open(p, "w").write(s)
PYEOF
commit_fixture
out="$(run_close 0066 ab12)" && rc=0 || rc=$?
assert_rc "exits 0" "$rc" 0 "$out"
assert_contains "the item is done" "$(cat "$FIX/$BL/items/0066-fixture.md")" 'status: done'

# --- 0086 FR6 — close_by: develop admits develop, and no other stage --------------------------
# FR6 reads "a row whose next is not verify is refused unless its item records close_by: develop",
# which taken literally would let a `next: design` row close on an opted-in item. NARROWED to the
# one stage FR2 names — the session that BUILT it — and asserted, because the literal reading is
# the one a later edit would restore.
echo "0086 FR6 — close_by: develop does not admit next: design"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0062 | Opted in, still at design | design | in-progress | 0000 |'
mkitem_light 0062 design in-progress '"ab12"' 'close_by: develop'
commit_fixture
out="$(run_close 0062 ab12)" && rc=0 || rc=$?
assert_rc_nonzero "exits non-zero" "$rc" "$out"
assert_contains "names the stage it found" "$out" 'design'
assert_clean "no file was changed"

# --- 0086 FR1 — an unrecognised close_by: value is an error, never a fail-open ------------------
echo "0086 FR1 — a close_by value that is neither verify nor develop is an error"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0063 | Nonsense close_by | develop | in-progress | 0000 |'
mkitem_light 0063 develop in-progress '"ab12"' 'close_by: light'
commit_fixture
out="$(run_close 0063 ab12)" && rc=0 || rc=$?
assert_rc_nonzero "exits non-zero" "$rc" "$out"
assert_contains "names the value it could not read" "$out" 'light'
assert_clean "no file was changed"

# --- 0086 FR3 — a citation has to name a GUARD, not merely a tracked file ----------------------
# FR3 admits a light close only where every criterion is "discharged by a committed automated
# assertion". The first implementation checked two of those three words: backticked, contains `/`,
# tracked by git. Nothing asked whether the path was an assertion, so two criteria citing a prose
# document closed a light ticket having executed nothing — option 3, the self-attested tier this
# ticket rejected, reachable in one wrong citation.
#
# `close` cannot know what an arbitrary file does, so the narrowed gate takes the two signals it
# CAN read: a conventional test path, or an executable committed in the index. Both routes are
# asserted, in both directions, because a gate accepting only the first would refuse a perfectly
# good shell guard and a gate accepting only the second would refuse every `.test.ts` in a JS repo.
echo "0086 FR3 — a criterion citing a tracked file that is not an assertion is refused"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0068 | Cites a prose document | develop | in-progress | 0000 |'
mkitem_light 0068 develop in-progress '"ab12"' 'close_by: develop'
mkdir -p "$FIX/docs"
printf 'Notes on the thing. No assertion anywhere in this file.\n' > "$FIX/docs/notes.md"
sed -i.bak 's|tests/guard.test.sh|docs/notes.md|g' "$FIX/$BL/items/0068-fixture.md"
rm -f "$FIX/$BL/items/0068-fixture.md.bak"
commit_fixture
out="$(run_close 0068 ab12)" && rc=0 || rc=$?
assert_rc_nonzero "exits non-zero" "$rc" "$out"
assert_contains "names the criterion"            "$out" 'AC1 — first criterion'
assert_contains "names the path it rejected"     "$out" 'docs/notes.md'
assert_contains "and says WHY, not just that it is uncited" "$out" 'not an assertion'
refute_contains "and does not call a committed file untracked" "$out" 'names no committed path'
assert_line "the row is untouched" '| 0068 | Cites a prose document | develop | in-progress | 0000 |' QUEUE.md
assert_contains "the item is not marked done" "$(cat "$FIX/$BL/items/0068-fixture.md")" 'status: in-progress'
refute_contains "and no criterion was ticked"  "$(cat "$FIX/$BL/items/0068-fixture.md")" '- [x]'
assert_clean   "the tree is exactly as it was found"
assert_no_lock "the lock is released on the refusal"

echo "0086 FR3 — an EXECUTABLE committed script is a guard whatever it is called"
# The route that keeps the narrowing from refusing this repo's own shape of guard the day one lives
# outside `tests/`. `git ls-files -s` is the authority, not the working tree's mode bit: the gate's
# subject is what was COMMITTED.
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0069 | Cites an executable check | develop | in-progress | 0000 |'
mkitem_light 0069 develop in-progress '"ab12"' 'close_by: develop'
mkdir -p "$FIX/bin"
printf '#!/bin/sh\nexit 0\n' > "$FIX/bin/check-the-thing"
chmod +x "$FIX/bin/check-the-thing"
sed -i.bak 's|tests/guard.test.sh|bin/check-the-thing|g' "$FIX/$BL/items/0069-fixture.md"
rm -f "$FIX/$BL/items/0069-fixture.md.bak"
commit_fixture
out="$(run_close 0069 ab12)" && rc=0 || rc=$?
assert_rc "exits 0" "$rc" 0 "$out"
assert_contains "the item is done" "$(cat "$FIX/$BL/items/0069-fixture.md")" 'status: done'

echo "0086 FR3 — and a conventionally named test file is a guard without being executable"
# The mirror: a JS or Python repo commits its guards at mode 100644, and a gate reading only the
# executable bit would refuse every one of them. Proved on a file that is deliberately NOT
# executable, so the two routes cannot be satisfied by the same signal.
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0070 | Cites a .test.ts guard | develop | in-progress | 0000 |'
mkitem_light 0070 develop in-progress '"ab12"' 'close_by: develop'
mkdir -p "$FIX/src"
printf 'it("holds", () => expect(1).toBe(1));\n' > "$FIX/src/thing.test.ts"
chmod 644 "$FIX/src/thing.test.ts"
sed -i.bak 's|tests/guard.test.sh|src/thing.test.ts|g' "$FIX/$BL/items/0070-fixture.md"
rm -f "$FIX/$BL/items/0070-fixture.md.bak"
commit_fixture
assert_contains "the fixture guard really is not executable" \
  "$(git -C "$FIX" ls-files -s -- src/thing.test.ts)" '100644'
out="$(run_close 0070 ab12)" && rc=0 || rc=$?
assert_rc "exits 0" "$rc" 0 "$out"
assert_contains "the item is done" "$(cat "$FIX/$BL/items/0070-fixture.md")" 'status: done'

# --- 0106 AC4, AC5 — declared scope against what the commits actually changed -------------------
# The defect: `touches:` can name a file for an edit that never happens and nothing notices. 0039's
# re-entry declared `.claude-plugin/plugin.json` for a version bump that never occurred, and an
# unused reservation is invisible by construction — `./next --drift` compares Status against
# blocked_by, and nothing had ever compared the declared scope against the diff.
#
# A NOTE, never a gate: over-declaring is legitimate (you widen before you know), and it is the
# under-delivering half — a declared file whose edit never happened, which reads to the next session
# as a completed step — that wants saying out loud. So AC5 asserts the close still succeeds.
#
# The range is anchored to the CLAIM COMMIT for this token, not to a date or a fixed depth: it is
# the only marker in the history that says "this session's work starts here", and it is written by
# `claim` itself.
echo "0106 AC4, AC5 — the close reports both directions of declared-vs-actual"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0080 | Scope reported | verify | in-progress | 0000 |'
mkitem 0080 verify in-progress '"ab12"' '[]'
mkdir -p "$FIX/some/reserved"
printf 'declared and edited\n' > "$FIX/some/reserved/file.md"
commit_fixture
git -C "$FIX" commit -q --allow-empty -m "Claim 0080 [ab12]"
mkdir -p "$FIX/src"
printf 'never declared\n' > "$FIX/src/undeclared.ts"
git -C "$FIX" add -A && git -C "$FIX" commit -q -m "Build 0080 [ab12]"
out="$(run_close 0080 ab12)" && rc=0 || rc=$?
assert_rc "the close still succeeds — this is a note, not a gate" "$rc" 0 "$out"
assert_contains "the item is done" "$(cat "$FIX/$BL/items/0080-fixture.md")" 'status: done'
assert_contains "names the undeclared path as touched but undeclared" "$out" 'touched but undeclared: src/undeclared.ts'
assert_contains "names the unedited path as declared but untouched" "$out" 'declared but untouched: some/reserved/file.md'

echo "0106 AC4 — the backlog's own bookkeeping is not reported as undeclared"
refute_contains "QUEUE.md is not an undeclared touch"  "$out" 'undeclared: '"$BL"'/QUEUE.md'
refute_contains "the item file is not an undeclared touch" "$out" 'undeclared: '"$BL"'/items/0080-fixture.md'

echo "0106 FR3 — a scope that matches says so, rather than saying nothing"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0081 | Scope agrees | verify | in-progress | 0000 |'
mkitem 0081 verify in-progress '"ab12"' '[]'
mkdir -p "$FIX/some/reserved"
printf 'declared\n' > "$FIX/some/reserved/file.md"
commit_fixture
git -C "$FIX" commit -q --allow-empty -m "Claim 0081 [ab12]"
printf 'declared and edited\n' > "$FIX/some/reserved/file.md"
git -C "$FIX" add -A && git -C "$FIX" commit -q -m "Build 0081 [ab12]"
out="$(run_close 0081 ab12)" && rc=0 || rc=$?
assert_rc "exits 0" "$rc" 0 "$out"
assert_contains "says the two agree" "$out" 'scope: touches: and the commits since the claim agree'
refute_contains "and reports neither direction" "$out" 'declared but untouched'

echo "0106 FR3 — no claim commit for this token means no range, and no invented report"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0082 | No claim commit | verify | in-progress | 0000 |'
mkitem 0082 verify in-progress '"ab12"' '[]'
commit_fixture
out="$(run_close 0082 ab12)" && rc=0 || rc=$?
assert_rc "exits 0" "$rc" 0 "$out"
refute_contains "no declared-vs-actual line is printed" "$out" 'declared but untouched'
refute_contains "and none of the agreeing line either" "$out" 'commits since the claim agree'

# --- 0106 FR3 — the duplicated block has not drifted ------------------------------------------
# `close` and `handoff` carry the scope comparison verbatim: a backlog script is a separate file by
# install contract and sources nothing, so a shared implementation is a copy. A copy is only safe
# while something notices it diverging — the comment saying "change one, change both" is the rule,
# and this is the check. Byte-for-byte, because a difference in the awk reader is exactly the kind
# that reads correctly in both files and answers differently.
echo "0106 FR3 — close and handoff carry the same scope block, byte for byte"
extract_block() {
  awk '/^# --- the declared scope against what the commits actually changed/ { f = 1 }
       f { print }
       f && /^scope_note$/ { exit }' "$1"
}
close_block="$(extract_block "$CLOSE_SRC")"
handoff_block="$(extract_block "$ROOT/skills/queue/templates/handoff")"
if [ -z "$close_block" ]; then
  bad "close carries the scope block"
elif [ "$close_block" = "$handoff_block" ]; then
  ok "close and handoff carry an identical scope block"
  saw_on_pass "$(printf '%s\n' "$close_block" | wc -l) lines, identical"
else
  bad "close and handoff carry an identical scope block"
  # No process substitution: this suite is /bin/sh, and `<(...)` is a bash extension that would
  # make the FAILURE branch itself fail — reporting a syntax error where the finding should be.
  cb="$(mktemp)"; hb="$(mktemp)"
  printf '%s\n' "$close_block"   > "$cb"
  printf '%s\n' "$handoff_block" > "$hb"
  saw "$(diff "$cb" "$hb" || true)"
  rm -f "$cb" "$hb"
fi

# --- 0090 FR1 — touches: is cleared in the flush-left form too ---------------------------------
# The skiplist required leading whitespace, so a legal same-indentation block sequence survived the
# close. Asserted on whole lines of the item rather than on "touches: is empty": the entries are
# what must be gone, and a substring check for `touches:` is green either way.
echo "0090 FR1 — a flush-left touches: block sequence is cleared on close"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0090 | Flush-left touches | verify | in-progress | 0000 |'
mkitem_flush_touches 0090 verify in-progress '"ab12"'
commit_fixture
out="$(run_close 0090 ab12)" && rc=0 || rc=$?
assert_rc "exits 0" "$rc" 0 "$out"
item="$(cat "$FIX/$BL/items/0090-fixture.md")"
refute_contains "the first entry is gone" "$item" '
- src/a.ts'
refute_contains "the second entry is gone" "$item" '
- src/b.ts'
assert_contains "the three ownership fields are cleared together" "$item" 'claimed_by:
claimed_at:
touches:
closed: '

# --- 0090 AC3 — close refuses a foreign uncommitted row rather than carrying it ------------------
# Same defect and same fix as AC4 in tests/handoff.test.sh: `close` warned and committed anyway, and
# a pathspec limits a commit to paths and never to authorship (`CONCURRENCY.md`, *A pathspec is
# necessary but not sufficient*). `close` writes two shared files, so both are in the check.
#
# Asserted on the message and on the files, never on the exit status alone (`testing-conventions.md`).
echo "0090 AC3 — a foreign uncommitted QUEUE.md row is refused, not warned about"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0092 | Verified row | verify | in-progress | 0000 |'
mkitem 0092 verify in-progress '"ab12"' '[]'
commit_fixture
printf '| 0093 | Another session mid-edit | develop | in-progress | 0000 |\n' >> "$FIX/$BL/QUEUE.md"
before_head="$(git -C "$FIX" rev-parse HEAD)"
before_queue="$(cat "$FIX/$BL/QUEUE.md")"
before_done="$(cat "$FIX/$BL/DONE.md")"
before_item="$(cat "$FIX/$BL/items/0092-fixture.md")"
out="$(run_close 0092 ab12)" && rc=0 || rc=$?
assert_rc_nonzero "exits non-zero" "$rc" "$out"
assert_contains "says it is refusing, not warning"    "$out" 'refusing to close'
assert_contains "names the cause"                     "$out" 'uncommitted'
assert_contains "names the row it would have carried" "$out" '0093 | Another session mid-edit'
assert_contains "says nothing was changed"            "$out" 'nothing was changed'
refute_contains "does not warn and carry on"          "$out" 'WARNING'
assert_eq "QUEUE.md is byte-identical" "$(cat "$FIX/$BL/QUEUE.md")" "$before_queue"
assert_eq "DONE.md is byte-identical"  "$(cat "$FIX/$BL/DONE.md")"  "$before_done"
assert_eq "the item is byte-identical" "$(cat "$FIX/$BL/items/0092-fixture.md")" "$before_item"
assert_eq "nothing was committed"      "$(git -C "$FIX" rev-parse HEAD)" "$before_head"
assert_line "the row is still in QUEUE.md" '| 0092 | Verified row | verify | in-progress | 0000 |' QUEUE.md
assert_no_lock "the lock does not exist afterwards"

# --- result -----------------------------------------------------------------------------------
echo
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
