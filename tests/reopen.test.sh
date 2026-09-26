#!/bin/sh
#
# Behavioural guard for skills/queue/templates/reopen (0161).
#
# Reopening a closed ticket for another verify pass was the one lifecycle transition with no
# script. The first time it was needed (2026-09-13, commit ecc6a60) a `queue` session composed it
# by hand inside one locked shell call: row DONE.md -> QUEUE.md, `next: verify`, `status: ready`,
# `closed:` removed, ACs unticked, QA evidence kept, a dated reason appended. Every one of those is
# a step a session under load can drop, and a dropped one is invisible afterwards.
#
# So, as in tests/handoff.test.sh, the assertions are about the RESULTING STATE and every refusal
# is asserted on its message AND on the fixture being byte-for-byte unchanged — `exits non-zero`
# alone is satisfied by a refusal that half-edited a file first (`testing-conventions.md`).
#
# Usage:  tests/reopen.test.sh
#
# Requires: git, sh, awk. No runner — this project has none.

set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
# The TEMPLATE copy runs here, never .claude/backlog/reopen: a mutation applied to the installed
# copy lands a real diff and reddens nothing.
REOPEN_SRC="$ROOT/skills/queue/templates/reopen"
NEXT_SRC="$ROOT/skills/queue/templates/next"
[ -f "$REOPEN_SRC" ] || { echo "no reopen script at $REOPEN_SRC" >&2; exit 2; }

PASS=0
FAIL=0
FIX=""

cleanup() { [ -n "$FIX" ] && rm -rf "$FIX"; return 0; }
trap cleanup EXIT INT TERM

# --- assertions -------------------------------------------------------------------------------
# The shape tests/handoff.test.sh carries: every assertion reports what it matched against, always
# on FAIL and on a pass only under SHOW_MATCHED. A suite here is self-contained and sources nothing.
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

assert_eq() {
  if [ "$2" = "$3" ]; then ok "$1"; saw_on_pass "$2"; else
    bad "$1"; echo "         expected exactly: $3"; saw "$2"; fi
}

assert_rc() {
  if [ "$2" -eq "$3" ]; then ok "$1"; saw_on_pass "$4"; else
    bad "$1"; saw "wanted exit $3, got exit $2
$4"; fi
}

assert_rc_nonzero() {
  if [ "$2" -ne 0 ]; then ok "$1"; saw_on_pass "$3"; else
    bad "$1"; saw "wanted any exit but 0
$3"; fi
}

BL() { printf '%s' "$FIX/.claude/backlog"; }

# A refusal that edits half a file and then exits non-zero satisfies "refuses"; it does not
# satisfy "changes nothing". Fingerprint every backlog file, the lock directory included.
fingerprint() { find "$(BL)" -type f | sort | xargs cksum; }

assert_unchanged() {
  if [ "$2" = "$(fingerprint)" ]; then ok "$1"; else
    bad "$1"; saw "the backlog changed:
$(cd "$FIX" && git status --porcelain)"; fi
}

# The table's data rows, header and separator excluded — "the first table row" in AC1's words.
data_rows() { awk '/^\|/ { n++; if (n > 2) print }' "$(BL)/$1"; }

# One `## ` section's body, heading excluded, up to the next `## ` heading or EOF.
section() {
  awk -v h="$2" 'index($0, h) == 1 { f = 1; next } f && /^## / { exit } f' "$1"
}

# --- fixture ----------------------------------------------------------------------------------
QHEAD='| ID | Title | Next | Status | Parent |'
QSEP='|------|-------|------|--------|--------|'
DHEAD='| ID | Title | Type | QA | Closed | Item |'
DSEP='|------|-------|------|----|--------|------|'

# The closed item under test. Two ticked ACs, a QA evidence body, notes, and a stale token — the
# last because closed items in this repo's own backlog do carry one, and a reopened ticket that
# kept it would read as held.
write_done_item() {
  cat > "$(BL)/items/0101-fixture.md" <<'ITEM'
---
id: "0101"
title: Fixture closed ticket
type: feature
next:
status: done
qa_level: unit
parent: "0100"
blocked_by: []
claimed_by: "old1"
claimed_at: 2026-09-01T00:00:00Z
touches:
  - src/one.ts
closed: 2026-09-10
---

## Problem

A fixture.

## Acceptance criteria

- [x] AC1 — the first criterion.
- [x] AC2 — the second criterion.

## QA evidence

- AC1 — ran `tests/one.test.sh`: 3 passed.
- [x] a ticked line outside the criteria, which must survive untouched.

## Notes & decisions

- 2026-09-01 — built.
ITEM
}

# $1 status, $2 blocked_by (inline list), $3 claimed_by (bare, empty for none), $4 id
write_dep_item() {
  by=""
  [ -z "$3" ] || by="\"$3\""
  cat > "$(BL)/items/$4-fixture.md" <<ITEM
---
id: "$4"
title: Dependent $4
type: feature
next: develop
status: $1
qa_level: unit
blocked_by: $2
claimed_by: $by
claimed_at:
touches:
---

## Problem

A dependent.
ITEM
}

# $@ the QUEUE.md data rows
scaffold() {
  cleanup
  FIX="$(mktemp -d)"
  mkdir -p "$(BL)/items"
  git -C "$FIX" init -q
  git -C "$FIX" config user.email test@example.invalid
  git -C "$FIX" config user.name "reopen test"

  {
    printf '# Backlog\n\n%s\n%s\n' "$QHEAD" "$QSEP"
    for r in "$@"; do printf '%s\n' "$r"; done
  } > "$(BL)/QUEUE.md"
  {
    printf '# Done\n\n%s\n%s\n' "$DHEAD" "$DSEP"
    printf '%s\n' '| 0101 | Fixture closed ticket | feature | unit | 2026-09-10 | [items/0101-fixture.md](items/0101-fixture.md) |'
    printf '%s\n' '| 0099 | An older close | bug | unit | 2026-09-01 | [items/0099-fixture.md](items/0099-fixture.md) |'
  } > "$(BL)/DONE.md"
  write_done_item

  cp "$REOPEN_SRC" "$(BL)/reopen"; chmod +x "$(BL)/reopen"
  cp "$NEXT_SRC" "$(BL)/next"; chmod +x "$(BL)/next"
}

commit_fixture() { git -C "$FIX" add -A; git -C "$FIX" commit -q -m "fixture"; }

run_reopen() { (cd "$FIX" && .claude/backlog/reopen "$@" 2>&1); }

# --- AC1 — a closed ticket goes back to verify, in one committed invocation ---------------------
echo "AC1 — reopen moves the row, resets the item, keeps the evidence, and commits three files"
scaffold '| 0102 | Another row | develop | ready |  |'
write_dep_item ready '[]' "" 0102
commit_fixture
QA_BEFORE="$(section "$(BL)/items/0101-fixture.md" '## QA evidence')"
out="$(run_reopen 0101 top "fixture reason")" && rc=0 || rc=$?
assert_rc "exits 0" "$rc" 0 "$out"
assert_eq "the first table row of QUEUE.md is 0101 at verify | ready" \
  "$(data_rows QUEUE.md | head -1)" '| 0101 | Fixture closed ticket | verify | ready | 0100 |'
assert_eq "the row that was first is now second" "$(data_rows QUEUE.md | sed -n 2p)" '| 0102 | Another row | develop | ready |  |'
assert_not_contains "DONE.md has no 0101 row" "$(data_rows DONE.md)" '| 0101 |'
assert_contains "DONE.md keeps its other rows" "$(data_rows DONE.md)" '| 0099 |'
ITEM="$(cat "$(BL)/items/0101-fixture.md")"
assert_contains "the item reads next: verify" "$ITEM" '
next: verify
'
assert_contains "the item reads status: ready" "$ITEM" '
status: ready
'
assert_not_contains "the item carries no closed: line" "$ITEM" 'closed:'
assert_not_contains "no - [x] remains under ## Acceptance criteria" \
  "$(section "$(BL)/items/0101-fixture.md" '## Acceptance criteria')" '- [x]'
assert_contains "the criteria are unticked, not deleted" \
  "$(section "$(BL)/items/0101-fixture.md" '## Acceptance criteria')" '- [ ] AC2 — the second criterion.'
assert_eq "the ## QA evidence body is byte-for-byte unchanged" \
  "$(section "$(BL)/items/0101-fixture.md" '## QA evidence')" "$QA_BEFORE"
assert_contains "the last line of ## Notes & decisions carries the reason" \
  "$(section "$(BL)/items/0101-fixture.md" '## Notes & decisions' | grep . | tail -1)" 'fixture reason'
assert_contains "the notes line is dated" \
  "$(section "$(BL)/items/0101-fixture.md" '## Notes & decisions' | grep . | tail -1)" "$(date -u +%Y-%m-%d)"
assert_contains "the earlier note survives" "$ITEM" '- 2026-09-01 — built.'
assert_contains "the stale claimed_by: is cleared" "$ITEM" '
claimed_by:
'
assert_not_contains "the stale touches: entry is gone" "$ITEM" '  - src/one.ts'
assert_eq "git show --name-only HEAD lists exactly the three files" \
  "$(git -C "$FIX" show --name-only --format= HEAD | sort)" \
  "$(printf '%s\n' .claude/backlog/DONE.md .claude/backlog/QUEUE.md .claude/backlog/items/0101-fixture.md)"
assert_contains "the commit names the reopen" "$(git -C "$FIX" log -1 --format=%s)" 'Reopen 0101'
assert_contains "the commit carries the Co-Authored-By trailer" \
  "$(git -C "$FIX" log -1 --format='%(trailers:key=Co-Authored-By,valueonly)')" 'noreply@anthropic.com'
assert_eq "nothing is left uncommitted" "$(git -C "$FIX" status --porcelain)" ''
assert_not_contains "no .lock/ remains after a successful run" "$(ls -a "$(BL)")" '.lock'
assert_contains "./next --drift agrees with the result" "$( (cd "$FIX" && .claude/backlog/next --drift) 2>&1 || true)" 'no drift'

# --- AC2 — above:<row-id> places the row directly above that row --------------------------------
echo "AC2 — above:0103 puts 0101 directly above 0103"
scaffold '| 0102 | Row two | develop | ready |  |' '| 0103 | Row three | develop | ready |  |'
commit_fixture
out="$(run_reopen 0101 above:0103 "r")" && rc=0 || rc=$?
assert_rc "exits 0" "$rc" 0 "$out"
assert_eq "the rows read 0102, 0101, 0103" "$(data_rows QUEUE.md | cut -d'|' -f2 | tr -d ' ' | tr '\n' ' ')" '0102 0101 0103 '

# --- AC3 — a ticket that is not done is refused, and nothing changes ----------------------------
echo "AC3 — 0101 at status: ready is refused"
scaffold
sed 's/^status: done$/status: ready/' "$(BL)/items/0101-fixture.md" > "$FIX/t" && mv "$FIX/t" "$(BL)/items/0101-fixture.md"
commit_fixture
before="$(fingerprint)"
out="$(run_reopen 0101 top "r")" && rc=0 || rc=$?
assert_rc_nonzero "exits non-zero" "$rc" "$out"
assert_contains "names the status it found" "$out" "status: ready"
assert_eq "git status --porcelain over the backlog is empty" "$(git -C "$FIX" status --porcelain -- .claude/backlog)" ''
assert_unchanged "nothing changed" "$before"
assert_not_contains "no .lock/ remains after a refused run" "$(ls -a "$(BL)")" '.lock'

# --- FR2 — every other refusal changes nothing and releases the lock ----------------------------
echo "FR2 — DONE.md holds no row for it"
scaffold
awk '!/^\| 0101 /' "$(BL)/DONE.md" > "$FIX/t" && mv "$FIX/t" "$(BL)/DONE.md"
commit_fixture
before="$(fingerprint)"
out="$(run_reopen 0101 top "r")" && rc=0 || rc=$?
assert_rc_nonzero "exits non-zero" "$rc" "$out"
assert_contains "says DONE.md has no row" "$out" "DONE.md"
assert_unchanged "nothing changed" "$before"
assert_not_contains "no .lock/ remains" "$(ls -a "$(BL)")" '.lock'

echo "FR2 — QUEUE.md already holds a row for it"
scaffold '| 0101 | Fixture closed ticket | verify | ready |  |'
commit_fixture
before="$(fingerprint)"
out="$(run_reopen 0101 top "r")" && rc=0 || rc=$?
assert_rc_nonzero "exits non-zero" "$rc" "$out"
assert_contains "says QUEUE.md already has the row" "$out" "QUEUE.md already"
assert_unchanged "nothing changed" "$before"
assert_not_contains "no .lock/ remains" "$(ls -a "$(BL)")" '.lock'

for dirty in QUEUE.md DONE.md; do
  echo "FR2 — $dirty is dirty"
  scaffold '| 0102 | Row two | develop | ready |  |'
  commit_fixture
  printf '%s\n' '| 0999 | Another session'"'"'s row | develop | ready |  |' >> "$(BL)/$dirty"
  before="$(fingerprint)"
  out="$(run_reopen 0101 top "r")" && rc=0 || rc=$?
  assert_rc_nonzero "exits non-zero" "$rc" "$out"
  assert_contains "names the uncommitted file" "$out" "uncommitted"
  assert_unchanged "nothing changed" "$before"
  assert_not_contains "no .lock/ remains" "$(ls -a "$(BL)")" '.lock'
done

echo "FR2 — an empty reason"
scaffold
commit_fixture
before="$(fingerprint)"
out="$(run_reopen 0101 top "")" && rc=0 || rc=$?
assert_rc_nonzero "exits non-zero" "$rc" "$out"
assert_contains "says a reason is required" "$out" "reason"
assert_unchanged "nothing changed" "$before"
out="$(run_reopen 0101 top "   ")" && rc=0 || rc=$?
assert_rc_nonzero "a whitespace-only reason is empty too" "$rc" "$out"
assert_unchanged "nothing changed" "$before"

echo "FR2 — above:<row-id> naming no row in QUEUE.md"
scaffold '| 0102 | Row two | develop | ready |  |'
commit_fixture
before="$(fingerprint)"
out="$(run_reopen 0101 above:0103 "r")" && rc=0 || rc=$?
assert_rc_nonzero "exits non-zero" "$rc" "$out"
assert_contains "names the missing row" "$out" "0103"
assert_unchanged "nothing changed" "$before"
assert_not_contains "no .lock/ remains" "$(ls -a "$(BL)")" '.lock'

echo "FR2 — a position that is neither top nor above:<id>"
scaffold
commit_fixture
before="$(fingerprint)"
out="$(run_reopen 0101 bottom "r")" && rc=0 || rc=$?
assert_rc_nonzero "exits non-zero" "$rc" "$out"
assert_contains "names the position it was given" "$out" "bottom"
assert_unchanged "nothing changed" "$before"

# --- AC5 — a busy lock is refused and left alone -------------------------------------------------
echo "AC5 — .lock/ already present"
scaffold
commit_fixture
mkdir "$(BL)/.lock"
printf 'claim 0042 by beef\n' > "$(BL)/.lock/held-by"
before="$(fingerprint)"
out="$(run_reopen 0101 top "r")" && rc=0 || rc=$?
assert_rc_nonzero "exits non-zero" "$rc" "$out"
assert_contains "names the holder" "$out" "claim 0042 by beef"
assert_unchanged "nothing changed, the other holder's lock included" "$before"
assert_eq "the lock it did not create is still there" "$(cat "$(BL)/.lock/held-by")" 'claim 0042 by beef'

# --- AC4 / FR3 — dependents are re-blocked, in reverse of close ---------------------------------
echo "AC4 — an unheld ready dependent naming 0101 becomes blocked, row and item"
scaffold '| 0102 | Dependent 0102 | develop | ready |  |' '| 0103 | Dependent 0103 | develop | waiting |  |' '| 0104 | Dependent 0104 | develop | ready |  |'
write_dep_item ready '["0101"]' "" 0102
write_dep_item waiting '["0101"]' "" 0103
printf '\n## Waiting on\n\nThe author.\n' >> "$(BL)/items/0103-fixture.md"
write_dep_item ready '[]' "" 0104
commit_fixture
out="$(run_reopen 0101 top "r")" && rc=0 || rc=$?
assert_rc "exits 0" "$rc" 0 "$out"
assert_contains "0102's row reads blocked" "$(data_rows QUEUE.md)" '| 0102 | Dependent 0102 | develop | blocked |  |'
assert_contains "0102's item reads blocked" "$(cat "$(BL)/items/0102-fixture.md")" '
status: blocked
'
assert_contains "a waiting dependent is re-blocked too — close restores waiting from ## Waiting on" \
  "$(data_rows QUEUE.md)" '| 0103 | Dependent 0103 | develop | blocked |  |'
assert_contains "a row not naming 0101 is left alone" "$(data_rows QUEUE.md)" '| 0104 | Dependent 0104 | develop | ready |  |'
assert_contains "./next --drift prints no drift" "$( (cd "$FIX" && .claude/backlog/next --drift) 2>&1 || true)" 'no drift'
assert_contains "the dependents ride in the same commit" "$(git -C "$FIX" show --name-only --format= HEAD)" 'items/0102-fixture.md'
assert_eq "nothing is left uncommitted" "$(git -C "$FIX" status --porcelain)" ''
assert_contains "reports what it re-blocked" "$out" '0102'

echo "FR3 — a done ticket naming 0101 is history, not a dependent"
scaffold
write_dep_item done '["0101"]' "stale" 0105
commit_fixture
out="$(run_reopen 0101 top "r")" && rc=0 || rc=$?
assert_rc "exits 0, a stale token on a done item notwithstanding" "$rc" 0 "$out"
assert_contains "0105 stays done" "$(cat "$(BL)/items/0105-fixture.md")" '
status: done
'

echo "FR3 — a held dependent makes it refuse, naming the dependent"
scaffold '| 0102 | Dependent 0102 | develop | in-progress |  |'
write_dep_item in-progress '["0101"]' "c0de" 0102
commit_fixture
before="$(fingerprint)"
out="$(run_reopen 0101 top "r")" && rc=0 || rc=$?
assert_rc_nonzero "exits non-zero" "$rc" "$out"
assert_contains "names the held dependent" "$out" "0102"
assert_unchanged "nothing changed" "$before"
assert_not_contains "no .lock/ remains" "$(ls -a "$(BL)")" '.lock'

# --- AC6 — queue Step 1's operation table runs ./reopen ------------------------------------------
echo "AC6 — skills/queue/SKILL.md Step 1's table contains ./reopen"
STEP1="$(awk '/^## Step 1 /{f=1;next} f&&/^## /{exit} f' "$ROOT/skills/queue/SKILL.md")"
assert_contains "a table row in Step 1 runs ./reopen" "$(printf '%s\n' "$STEP1" | grep '^|' || true)" './reopen'

# --- NFR Documentation — the script names what it replaces ---------------------------------------
echo "NFR — the header comment names the by-hand composition it replaces"
assert_contains "the header cites ecc6a60" "$(sed -n '1,/^set /p' "$REOPEN_SRC")" 'ecc6a60'

echo
echo "reopen: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
