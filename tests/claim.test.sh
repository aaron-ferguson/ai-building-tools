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
# $1 header row, $2 separator row, $3 the single data row, $4 the id that row carries, $5 the
# item's `expects:` block — the whole key, so a case can supply `expects:` bare or with entries
# under it — and $6 the item's `touches:` block, same rule. Both default to bare, which is what
# every case written before 0082 assumed.
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
${5:-expects:}
claimed_by:
claimed_at:
${6:-touches:}
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

# `assert_contains` is satisfied by a string that has *grown*, so it cannot say "unchanged". A
# refusal's second half is exactly that claim (0082 AC4), and asserting it loosely is the shape
# `testing-conventions.md` calls a guard that runs and cannot fail.
assert_eq() {
  if [ "$2" = "$3" ]; then ok "$1"; saw_on_pass "$2"; else
    bad "$1"; echo "         expected exactly:"; saw "$3"; echo "         got:"; saw "$2"; fi
}

# `assert_contains` cannot say "once". AC1's whole claim is that a re-claim does not DUPLICATE a
# path, and a substring match is satisfied by two copies as happily as by one — the exact shape of
# guard `testing-conventions.md` calls one that runs and cannot fail.
# The `touches:` block ALONE, never the whole item. AC1's claim is about duplication inside that
# block, and `expects:` legitimately carries the same paths one key above it — a count over the
# file therefore reads 2 for a correct result, which is a guard anchored to the document rather
# than to the claim (`testing-conventions.md`).
touches_block() {
  awk '
    NR == 1 && /^---$/ { fm = 1; next }
    fm && /^---$/      { exit }
    fm && /^touches:/  { intou = 1; print; next }
    intou && /^[ \t]/ { print; next }
    intou             { exit }
  ' "$FIX/.claude/backlog/items/$1-fixture.md"
}

assert_count() {
  n="$(printf '%s\n' "$2" | grep -cF "$3" || true)"
  if [ "$n" = "$4" ]; then ok "$1"; saw_on_pass "$n occurrence(s) of $3"; else
    bad "$1"; echo "         expected $4 occurrence(s) of: $3"; saw "found $n in:
$2"; fi
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

# --- 0082 AC1, AC2 — a provisional touches: is written from expects: --------------------------
# The defect: `claim` committed the row and the ownership keys and then *printed* an instruction
# to set `touches:` by hand, so the one field the other window reads to decide what is safe to
# take was the only part of the claim that was neither written nor committed. AetherWorks 0091
# ran to completion with none.
echo "0082 AC1 — expects: is written as a provisional touches:, inside the claim commit"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0006 | Has expects | develop | ready | 0000 |' 0006 'expects:
  - src/alpha.ts
  - tests/alpha.test.ts'
out="$(run_claim 0006)" && rc=0 || rc=$?
item="$(cat "$FIX/.claude/backlog/items/0006-fixture.md")"
assert_rc "exits 0" "$rc" 0 "$out"
assert_contains "touches: carries the whole expects list" "$item" 'touches:
  - src/alpha.ts
  - tests/alpha.test.ts
---'
assert_contains "expects: is left as queue wrote it" "$item" 'expects:
  - src/alpha.ts'
# Written is not committed, and committed is the whole reason this is a script. Assert on the
# commit's own diff rather than on the file, so a write left dirty cannot pass.
assert_contains "the provisional scope is IN the claim commit" \
  "$(git -C "$FIX" show --format= -U0 HEAD -- .claude/backlog/items/0006-fixture.md)" \
  '+  - src/alpha.ts'
assert_contains "nothing is left uncommitted" "clean$(git -C "$FIX" status --porcelain)" 'clean'
assert_contains "the report says to narrow it" "$out" 'NARROW it'
assert_not_contains "does not tell the session the field is unset" "$out" 'now set touches:'

# --- 0082 AC3 — no expects: keeps today's behaviour -------------------------------------------
# A provisional scope invented from nothing would be worse than none (FR2), so the bare case has
# to stay bare AND say so — silence here reads as "a scope was written".
echo "0082 AC3 — an item with no expects: claims as it does today, and the report says so"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0007 | No expects | develop | ready | 0000 |' 0007
out="$(run_claim 0007)" && rc=0 || rc=$?
item="$(cat "$FIX/.claude/backlog/items/0007-fixture.md")"
assert_rc "exits 0" "$rc" 0 "$out"
assert_contains "touches: is left empty" "$item" 'touches:
---'
assert_contains "the item is still claimed" "$item" 'claimed_by: "tok0"'
assert_contains "the report says the scope is unset" "$out" 'unset'

# --- 0082 AC4, AC5 — a foreign uncommitted QUEUE.md edit is refused, not narrated --------------
# The defect: `claim` detected another session's uncommitted row edit, said its commit would
# carry it, and committed anyway — AetherWorks 0091's row is attributed to `Claim 0034 [fc89]`.
# A script holding the lock can refuse instead of narrating.
echo "0082 AC4 — a foreign uncommitted QUEUE.md edit is refused and nothing is changed"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0008 | Ready row | develop | ready | 0000 |' 0008
printf '| 0009 | Another session mid-edit | develop | in-progress | 0000 |\n' >> "$FIX/.claude/backlog/QUEUE.md"
before_queue="$(cat "$FIX/.claude/backlog/QUEUE.md")"
before_item="$(cat "$FIX/.claude/backlog/items/0008-fixture.md")"
before_head="$(git -C "$FIX" rev-parse HEAD)"
before_index="$(git -C "$FIX" diff --cached --name-only)"
out="$(run_claim 0008)" && rc=0 || rc=$?
assert_rc_nonzero "exits non-zero" "$rc" "$out"
assert_contains "names the row it would have carried" "$out" '0009 | Another session mid-edit'
assert_contains "says what to do about it" "$out" 'restore'
assert_eq "QUEUE.md is byte-identical" "$(cat "$FIX/.claude/backlog/QUEUE.md")" "$before_queue"
assert_eq "the item is byte-identical" "$(cat "$FIX/.claude/backlog/items/0008-fixture.md")" "$before_item"
assert_eq "the index is untouched" "$(git -C "$FIX" diff --cached --name-only)" "$before_index"
assert_eq "no claim was committed" "$(git -C "$FIX" rev-parse HEAD)" "$before_head"
assert_contains "the lock is not left behind" "none$(ls "$FIX/.claude/backlog/.lock" 2>/dev/null)" 'none'

echo "0082 AC5 — that refusal reads as its own ground, not as one of the other three"
assert_contains "says it is refusing, not warning" "$out" 'refusing to claim'
assert_contains "names the actual cause" "$out" 'uncommitted'
assert_not_contains "is not the stage refusal" "$out" 'not ready'
assert_not_contains "is not the table-shape refusal" "$out" 'Status column'
assert_not_contains "is not the missing-row refusal" "$out" 'no row for'

# --- 0106 AC1, AC2 — a populated touches: is a verified scope and is never overwritten ---------
# The defect: on a RE-claim, `claim` printed `touches:` with the whole `expects:` seed and then
# stopped skipping the old entries at the first line that was not a `- ` bullet — a standalone
# comment. So the previous session's deliberately narrowed list came back BELOW the widened seed,
# with its explanatory comment now annotating the wrong list and every shared path listed twice
# (0039, then 0086, which is what made it systematic rather than a one-off).
#
# The fix is the rule `develop` already states for `expects:` versus `touches:` — a prediction never
# overwrites a verified scope — so the seed applies only where the field is EMPTY.
echo "0106 AC1 — a re-claim leaves a populated touches: exactly as the previous session narrowed it"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0010 | Re-claimed | develop | ready | 0000 |' 0010 'expects:
  - src/alpha.ts
  - src/beta.ts
  - tests/alpha.test.ts' 'touches:
  # narrowed: src/beta.ts is read, never written
  - src/alpha.ts'
out="$(run_claim 0010)" && rc=0 || rc=$?
item="$(cat "$FIX/.claude/backlog/items/0010-fixture.md")"
assert_rc "exits 0" "$rc" 0 "$out"
assert_contains "the narrowed block survives intact, comment and all" "$item" 'touches:
  # narrowed: src/beta.ts is read, never written
  - src/alpha.ts
---'
assert_count "the kept path appears once, not twice" "$(touches_block 0010)" '  - src/alpha.ts' 1
# The ENTRY form, not the bare path: the narrowing comment names src/beta.ts too, so a substring
# match on the path alone fails against a correct result.
assert_not_contains "the seed did not re-add the path the narrowing excluded" "$(touches_block 0010)" '- src/beta.ts'
assert_contains "the item is still claimed" "$item" 'claimed_by: "tok0"'

echo "0106 AC2 — and the report says the field was left alone, and what it kept"
assert_contains "says it was left as the previous session set it" "$out" 'left as the previous session set it'
assert_contains "prints the paths it kept" "$out" 'src/alpha.ts'
assert_not_contains "does not tell the session a fresh seed was written" "$out" 'set provisionally from expects:'

# --- 0106 AC3 — a non-building stage gets no build scope --------------------------------------
# `verify` opens none of the files a build scope names — it writes the item and the queue — so a QA
# claim that seeded `expects:` reserved seven paths against the other window for a pass that touched
# none of them, which is exactly the suboptimal pick `touches:` exists to avoid.
echo "0106 AC3 — a row at next: verify is not seeded from expects:"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0011 | Up for QA | verify | ready | 0000 |' 0011 'expects:
  - src/alpha.ts
  - tests/alpha.test.ts'
out="$(run_claim 0011)" && rc=0 || rc=$?
item="$(cat "$FIX/.claude/backlog/items/0011-fixture.md")"
assert_rc "exits 0" "$rc" 0 "$out"
assert_contains "touches: is left empty" "$item" 'touches:
---'
assert_contains "expects: is left as queue wrote it" "$item" 'expects:
  - src/alpha.ts'
assert_contains "the item is still claimed" "$item" 'claimed_by: "tok0"'
assert_contains "the report names the stage it declined to seed for" "$out" 'verify'
assert_contains "the report says why, not just that" "$out" 'does not build'
assert_not_contains "does not claim a provisional scope was written" "$out" 'set provisionally from expects:'

echo "0106 AC3 — develop is still seeded, so the stage test is a test and not a switch-off"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0012 | To build | develop | ready | 0000 |' 0012 'expects:
  - src/alpha.ts'
out="$(run_claim 0012)" && rc=0 || rc=$?
assert_rc "exits 0" "$rc" 0 "$out"
assert_contains "touches: carries the expects list" "$(cat "$FIX/.claude/backlog/items/0012-fixture.md")" 'touches:
  - src/alpha.ts
---'
assert_contains "the report says to narrow it" "$out" 'NARROW it'

# --- result -----------------------------------------------------------------------------------
echo
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
