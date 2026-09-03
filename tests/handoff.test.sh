#!/bin/sh
#
# Behavioural guard for skills/queue/templates/handoff (0081).
#
# The hand-off is the third lifecycle transition and was the only one done by hand. Two defects
# put it here, both measured in AetherWorks and both invisible in the git record afterwards:
#
#   1. A hand-off commit set the token, the timestamp and `touches:` but NOT `next` and `status`,
#      because the edit was written against `status: ready` while the item read
#      `status: in-progress`. It no-oped, and the commit proceeded anyway — leaving a row reading
#      `verify | ready` over an item reading `develop | in-progress`, which is precisely the drift
#      `./next --drift` exists to catch, produced by the prescribed procedure (item 0087).
#   2. A stage released its claim BEFORE its last write, so for 29 seconds a row read takeable
#      while its holder was still committing to it (item 0051, commits 39b858b and 844d328).
#
# So the assertions here are about the RESULTING STATE, never about whether an edit ran: a no-op
# is the defect, and a no-op that reports success is indistinguishable from a real hand-off
# unless something reads the file back. Every refusal is asserted on its MESSAGE and on the
# fixture being byte-for-byte unchanged — `exits non-zero` is satisfied by the silent refusal the
# rule forbids (`testing-conventions.md`).
#
# Defect 2 has no runtime form: ordering is prose, so the last cases grep the skills and
# references/CONCURRENCY.md for the rule and its reason.
#
# Usage:  tests/handoff.test.sh
#
# Requires: git, sh, awk. No runner — this project has none.

set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
HANDOFF_SRC="$ROOT/skills/queue/templates/handoff"
NEXT_SRC="$ROOT/skills/queue/templates/next"
[ -f "$HANDOFF_SRC" ] || { echo "no handoff script at $HANDOFF_SRC" >&2; exit 2; }

PASS=0
FAIL=0
FIX=""

cleanup() { [ -n "$FIX" ] && rm -rf "$FIX"; return 0; }
trap cleanup EXIT INT TERM

# --- assertions -------------------------------------------------------------------------------
# The same pair tests/claim.test.sh, tests/close.test.sh and tests/next.test.sh carry: every
# assertion reports what it matched against, always on FAIL and on a pass only under SHOW_MATCHED,
# so a green run stays one line per case. A suite here is self-contained and sources nothing
# (`CLAUDE.md`). Change one, change all four.
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

# Match the whole row rather than looking a cell up by index: a harness that reimplements the
# parser under test passes and fails with it (the defect tests/claim.test.sh records).
assert_row() {
  table="$(sed -n '/^|/p' "$FIX/.claude/backlog/QUEUE.md")"
  if grep -Fxq "$2" "$FIX/.claude/backlog/QUEUE.md"; then
    ok "$1"; saw_on_pass "$table"
  else
    bad "$1"; echo "         expected row: $2"; saw "$table"
  fi
}

assert_item_line() {
  body="$(cat "$FIX/.claude/backlog/items/$ID_UNDER_TEST-fixture.md")"
  if printf '%s\n' "$body" | grep -Fxq "$2"; then
    ok "$1"; saw_on_pass "$body"
  else
    bad "$1"; echo "         expected line: $2"; saw "$body"
  fi
}

assert_no_item_line() {
  body="$(cat "$FIX/.claude/backlog/items/$ID_UNDER_TEST-fixture.md")"
  if printf '%s\n' "$body" | grep -Fxq "$2"; then
    bad "$1"; echo "         expected NO line: $2"; saw "$body"
  else
    ok "$1"; saw_on_pass "$body"
  fi
}

# A refusal that edits half a file and then exits non-zero satisfies "refuses"; it does not
# satisfy "changes nothing". Fingerprint every backlog file, not just the two the script writes.
fingerprint() { find "$FIX/.claude/backlog" -type f ! -path '*/.lock/*' | sort | xargs cksum; }

assert_unchanged() {
  if [ "$2" = "$(fingerprint)" ]; then ok "$1"; else
    bad "$1"; saw "the backlog changed:
$(cd "$FIX" && git status --porcelain)"; fi
}

# --- fixture ----------------------------------------------------------------------------------
# $1 header, $2 separator, $3 the data row, $4 id, $5 item `next:`, $6 item `status:`,
# $7 item `claimed_by:` (bare, unquoted, empty for none).
scaffold() {
  cleanup
  FIX="$(mktemp -d)"
  ID_UNDER_TEST="$4"
  mkdir -p "$FIX/.claude/backlog/items"
  git -C "$FIX" init -q
  git -C "$FIX" config user.email test@example.invalid
  git -C "$FIX" config user.name "handoff test"

  {
    printf '# Backlog\n\n'
    printf '%s\n%s\n%s\n' "$1" "$2" "$3"
  } > "$FIX/.claude/backlog/QUEUE.md"

  by=""
  [ -z "$7" ] || by="\"$7\""

  cat > "$FIX/.claude/backlog/items/$4-fixture.md" <<ITEM
---
id: "$4"
title: Fixture
type: feature
next: $5
status: $6
qa_level: unit
blocked_by: []
expects:
  - src/one.ts
claimed_by: $by
claimed_at: 2026-09-01T00:00:00Z
touches:
  - src/one.ts
  - src/two.ts
---

## Problem

A fixture.
ITEM

  cp "$HANDOFF_SRC" "$FIX/.claude/backlog/handoff"
  chmod +x "$FIX/.claude/backlog/handoff"
  [ ! -f "$NEXT_SRC" ] || { cp "$NEXT_SRC" "$FIX/.claude/backlog/next"; chmod +x "$FIX/.claude/backlog/next"; }
  git -C "$FIX" add -A
  git -C "$FIX" commit -q -m "fixture"
}

run_handoff() { (cd "$FIX" && .claude/backlog/handoff "$@" 2>&1); }

FIVE_HEAD='| ID | Title | Next | Status | Parent |'
FIVE_SEP='|------|-------|------|--------|--------|'

# --- AC1 — a row and its item move between stages, committed, in one invocation ---------------
echo "AC1 — develop -> verify moves both files and commits inside the lock"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0001 | A held row | develop | in-progress | 0000 |' 0001 develop in-progress tok0
out="$(run_handoff 0001 tok0 verify)" && rc=0 || rc=$?
assert_rc "exits 0" "$rc" 0 "$out"
assert_row "the row reads verify | ready" '| 0001 | A held row | verify | ready | 0000 |'
assert_item_line "the item's next: is the new stage" 'next: verify'
assert_item_line "the item's status: is ready" 'status: ready'
assert_item_line "claimed_by: is cleared" 'claimed_by:'
assert_item_line "claimed_at: is cleared" 'claimed_at:'
assert_item_line "touches: is cleared" 'touches:'
assert_no_item_line "the touches: list entries are gone" '  - src/two.ts'
assert_item_line "expects: is left alone" '  - src/one.ts'
assert_contains "the hand-off is committed" "$(git -C "$FIX" log -1 --format=%s)" 'Hand off 0001 to verify [tok0]'
assert_contains "nothing is left uncommitted" "clean$(git -C "$FIX" status --porcelain)" 'clean'
assert_not_contains "the lock is released" "$(ls -a "$FIX/.claude/backlog")" '.lock'

# --- FR2 — the fourth positional is the status; waiting is a legal destination -----------------
echo "FR2 — an explicit status is honoured, so verify's waiting branch has a command"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0002 | Needs a person | verify | in-progress | 0000 |' 0002 verify in-progress tok0
out="$(run_handoff 0002 tok0 develop waiting)" && rc=0 || rc=$?
assert_rc "exits 0" "$rc" 0 "$out"
assert_row "the row reads develop | waiting" '| 0002 | Needs a person | develop | waiting | 0000 |'
assert_item_line "the item's status: is waiting" 'status: waiting'

# --- FR2 — a status this script must never author ----------------------------------------------
# `blocked` is derived from `blocked_by` and never typed; `done` belongs to `./close`; nothing
# hands a ticket off INTO `in-progress`. Each would produce a row that lies about takeability.
echo "FR2 — blocked, done and in-progress are refused as destinations"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0003 | A held row | develop | in-progress | 0000 |' 0003 develop in-progress tok0
before="$(fingerprint)"
for s in blocked done in-progress; do
  out="$(run_handoff 0003 tok0 verify "$s")" && rc=0 || rc=$?
  assert_rc_nonzero "refuses status '$s'" "$rc" "$out"
  assert_contains "names the status it refused ('$s')" "$out" "$s"
done
assert_contains "says why blocked in particular is not writable" "$(run_handoff 0003 tok0 verify blocked 2>&1 || true)" 'derived'
assert_unchanged "nothing changed across the three refusals" "$before"

# --- FR3/AC3 — a stage this script does not recognise ------------------------------------------
echo "FR3 — an unrecognised destination stage is refused, not written"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0004 | A held row | develop | in-progress | 0000 |' 0004 develop in-progress tok0
before="$(fingerprint)"
out="$(run_handoff 0004 tok0 retro)" && rc=0 || rc=$?
assert_rc_nonzero "exits non-zero" "$rc" "$out"
assert_contains "names the stage it was given" "$out" 'retro'
assert_contains "lists the stages it knows" "$out" 'verify'
assert_unchanged "the backlog is untouched" "$before"

# --- AC2 — the 0087 case: the item's status is not what the edit expects ------------------------
echo "AC2 — an item whose status: is not in-progress is refused, naming the mismatch"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0005 | Half applied | develop | in-progress | 0000 |' 0005 develop ready tok0
before="$(fingerprint)"
out="$(run_handoff 0005 tok0 verify)" && rc=0 || rc=$?
assert_rc_nonzero "exits non-zero" "$rc" "$out"
assert_contains "names the status the item actually reads" "$out" 'ready'
assert_contains "names the status it required" "$out" 'in-progress'
assert_unchanged "the backlog is untouched" "$before"

# The same mismatch from the other side — the row half-applied, the item intact. 0087 produced
# exactly this pair, so a guard that catches only one direction catches half the defect.
echo "AC2 — the mismatch is caught from the row's side too"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0006 | Half applied | develop | ready | 0000 |' 0006 develop in-progress tok0
before="$(fingerprint)"
out="$(run_handoff 0006 tok0 verify)" && rc=0 || rc=$?
assert_rc_nonzero "exits non-zero" "$rc" "$out"
assert_contains "names the row's status" "$out" 'ready'
assert_unchanged "the backlog is untouched" "$before"

# --- AC3 — a token that does not hold the claim ------------------------------------------------
echo "AC3 — a token that is not the one holding the claim is refused"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0007 | Someone else has it | develop | in-progress | 0000 |' 0007 develop in-progress f0c3
before="$(fingerprint)"
out="$(run_handoff 0007 tok0 verify)" && rc=0 || rc=$?
assert_rc_nonzero "exits non-zero" "$rc" "$out"
assert_contains "names the token that does hold it" "$out" 'f0c3'
assert_contains "names the token it was given" "$out" 'tok0'
assert_not_contains "does not confuse this with a status mismatch" "$out" 'in-progress, not'
assert_unchanged "the backlog is untouched" "$before"

echo "AC3 — an item nothing holds is refused rather than handed off"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0008 | Unclaimed | develop | in-progress | 0000 |' 0008 develop in-progress ''
before="$(fingerprint)"
out="$(run_handoff 0008 tok0 verify)" && rc=0 || rc=$?
assert_rc_nonzero "exits non-zero" "$rc" "$out"
assert_contains "says nothing holds it" "$out" 'claimed_by'
assert_unchanged "the backlog is untouched" "$before"

# An annotated token — `develop` Step 1 invites an inline note, and the naive reader returns
# `tok0" # mine`, refusing the holder's own hand-off. `close` carries the same decommenter.
echo "AC3 — a YAML comment on claimed_by: does not refuse the holder"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0009 | Annotated | develop | in-progress | 0000 |' 0009 develop in-progress tok0
sed 's/^claimed_by: "tok0"$/claimed_by: "tok0" # mine/' "$FIX/.claude/backlog/items/0009-fixture.md" > "$FIX/x" && mv "$FIX/x" "$FIX/.claude/backlog/items/0009-fixture.md"
git -C "$FIX" commit -q -m annotate -- .claude/backlog/items/0009-fixture.md
out="$(run_handoff 0009 tok0 verify)" && rc=0 || rc=$?
assert_rc "exits 0" "$rc" 0 "$out"
assert_row "the row moved" '| 0009 | Annotated | verify | ready | 0000 |'

# --- AC3 — the row's stage and the item's stage disagree ---------------------------------------
echo "AC3 — a row not at the stage the item says is refused, with its own message"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0010 | Stage drift | verify | in-progress | 0000 |' 0010 develop in-progress tok0
before="$(fingerprint)"
out="$(run_handoff 0010 tok0 verify)" && rc=0 || rc=$?
assert_rc_nonzero "exits non-zero" "$rc" "$out"
assert_contains "names the row's stage" "$out" 'verify'
assert_contains "names the item's stage" "$out" 'develop'
assert_unchanged "the backlog is untouched" "$before"

# --- AC3 — a table shape it cannot read --------------------------------------------------------
echo "AC3 — a table with no Next column is an explicit error, never a refusal"
scaffold '| ID | Title | Status | Parent |' '|------|-------|--------|--------|' '| 0011 | No next column | in-progress | 0000 |' 0011 develop in-progress tok0
before="$(fingerprint)"
out="$(run_handoff 0011 tok0 verify)" && rc=0 || rc=$?
assert_rc_nonzero "exits non-zero" "$rc" "$out"
assert_contains "says which column is missing" "$out" 'Next'
assert_contains "quotes the header it found" "$out" 'ID | Title | Status | Parent'
assert_unchanged "the backlog is untouched" "$before"

echo "AC3 — a row that is not in the table at all"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0012 | Present | develop | in-progress | 0000 |' 0012 develop in-progress tok0
before="$(fingerprint)"
out="$(run_handoff 0099 tok0 verify)" && rc=0 || rc=$?
assert_rc_nonzero "exits non-zero" "$rc" "$out"
assert_contains "names the id it could not find" "$out" '0099'
assert_unchanged "the backlog is untouched" "$before"

# --- FR2 — all five fields land, or nothing does -----------------------------------------------
# The 0087 defect exactly: an edit that does not apply, and a commit that proceeds regardless. An
# item with no `next:` key has nothing for the edit to replace, so the script must read the result
# back and fail rather than commit a half-applied hand-off.
echo "FR2 — an item missing one of the five keys fails and commits nothing"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0013 | No next key | develop | in-progress | 0000 |' 0013 develop in-progress tok0
grep -v '^next: develop$' "$FIX/.claude/backlog/items/0013-fixture.md" > "$FIX/x" && mv "$FIX/x" "$FIX/.claude/backlog/items/0013-fixture.md"
git -C "$FIX" commit -q -m "drop next:" -- .claude/backlog/items/0013-fixture.md
before="$(fingerprint)"
out="$(run_handoff 0013 tok0 verify)" && rc=0 || rc=$?
assert_rc_nonzero "exits non-zero" "$rc" "$out"
assert_contains "names the field that did not apply" "$out" 'next'
assert_unchanged "neither file was written" "$before"
assert_contains "no commit was made" "$(git -C "$FIX" log -1 --format=%s)" 'drop next:'

# --- FR2 — touches: entries at column 0 ---------------------------------------------------------
# YAML allows a block sequence at the SAME indentation as its key, so this is a legal `touches:`.
# A skiplist requiring leading whitespace leaves the entries behind: the ticket reads handed off
# and still reserves two files, which `CONCURRENCY.md` says the other window must read as held.
echo "FR2 — touches: entries written at column 0 are cleared too"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0018 | Flat list | develop | in-progress | 0000 |' 0018 develop in-progress tok0
sed 's/^  - src\/two.ts$/- src\/two.ts/' "$FIX/.claude/backlog/items/0018-fixture.md" > "$FIX/x" && mv "$FIX/x" "$FIX/.claude/backlog/items/0018-fixture.md"
git -C "$FIX" commit -q -m flatten -- .claude/backlog/items/0018-fixture.md
out="$(run_handoff 0018 tok0 verify)" && rc=0 || rc=$?
assert_rc "exits 0" "$rc" 0 "$out"
assert_no_item_line "the column-0 entry is gone" '- src/two.ts'

# --- FR2 — the read-back is what catches an edit that does not apply ----------------------------
# The only mutation that reaches it. Every refusal above has already established that the five keys
# are present and that the row and the item agree, so a well-formed input cannot get here — which
# is what makes this case, rather than a fixture, the proof the guard is wired to something. Break
# the editor's `status` line in a COPY of the script and assert the read-back's own message: the
# 0087 defect was an edit written against the wrong value, and nothing but reading the result back
# can see it (`testing-conventions.md`, prove a new guard fails).
echo "FR2 — an editor that silently skips a field is caught by the read-back, not committed"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0019 | Read back | develop | in-progress | 0000 |' 0019 develop in-progress tok0
sed 's|if ($0 ~ /\^status:/)     { print "status: " st;  next }|if (0) { next }|' \
  "$FIX/.claude/backlog/handoff" > "$FIX/broken" && mv "$FIX/broken" "$FIX/.claude/backlog/handoff"
chmod +x "$FIX/.claude/backlog/handoff"
if grep -q 'if (0) { next }' "$FIX/.claude/backlog/handoff"; then
  ok "the mutation landed in the copy the harness runs"
else
  bad "the mutation did not apply — the case below proves nothing"
fi
git -C "$FIX" commit -q -m "break the editor" -- .claude/backlog/handoff
before="$(fingerprint)"
out="$(run_handoff 0019 tok0 verify)" && rc=0 || rc=$?
assert_rc_nonzero "exits non-zero" "$rc" "$out"
assert_contains "the read-back names the field that did not apply" "$out" 'did not apply to: status'
assert_unchanged "neither file was written" "$before"
assert_contains "no hand-off was committed" "$(git -C "$FIX" log -1 --format=%s)" 'break the editor'

# --- FR2 — a body line is not a frontmatter key -------------------------------------------------
# `grep -q "^touches:"` is satisfied by a *Notes & decisions* line that happens to start that way,
# and the key the edit needs is still absent. Both readings refuse; only one of them says which
# field is missing, and the other blames the script.
echo "FR2 — a key that exists only in the body is reported as missing from the frontmatter"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0021 | Body key | develop | in-progress | 0000 |' 0021 develop in-progress tok0
ITEM21="$FIX/.claude/backlog/items/0021-fixture.md"
grep -v '^touches:$' "$ITEM21" | grep -v '^  - src/two.ts$' | sed 's|^  - src/one.ts$||' > "$FIX/x"
printf '\ntouches: mentioned in prose, not a key\n' >> "$FIX/x"
mv "$FIX/x" "$ITEM21"
git -C "$FIX" commit -q -m "body key" -- .claude/backlog/items/0021-fixture.md
before="$(fingerprint)"
out="$(run_handoff 0021 tok0 verify)" && rc=0 || rc=$?
assert_rc_nonzero "exits non-zero" "$rc" "$out"
assert_contains "names the field missing from the frontmatter" "$out" "frontmatter has no: touches"
assert_unchanged "the backlog is untouched" "$before"

# --- FR2 — the read-back sees a surviving touches: list ------------------------------------------
# The second mutation that reaches the read-back. An emptied `touches:` key over a list that
# survived still reserves files, and `fm_value` cannot tell the two apart — the value it reads is
# the empty string either way. Break the editor's skiplist in the copy the harness runs.
echo "FR2 — an editor that empties touches: but leaves its entries is caught"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0022 | Stale scope | develop | in-progress | 0000 |' 0022 develop in-progress tok0
sed 's|if (skiplist && $0 ~ /\^\[ .t\]\*- /) { next }|if (0) { next }|' \
  "$FIX/.claude/backlog/handoff" > "$FIX/broken" && mv "$FIX/broken" "$FIX/.claude/backlog/handoff"
chmod +x "$FIX/.claude/backlog/handoff"
if grep -q 'if (0) { next }' "$FIX/.claude/backlog/handoff"; then
  ok "the mutation landed in the copy the harness runs"
else
  bad "the mutation did not apply — the case below proves nothing"
fi
git -C "$FIX" commit -q -m "break the skiplist" -- .claude/backlog/handoff
before="$(fingerprint)"
out="$(run_handoff 0022 tok0 verify)" && rc=0 || rc=$?
assert_rc_nonzero "exits non-zero" "$rc" "$out"
assert_contains "the read-back names the surviving list" "$out" 'touches.entries'
assert_unchanged "neither file was written" "$before"

# --- FR1 — the lock is held THROUGH the commit, not merely around the edit -----------------------
# `CONCURRENCY.md`, *Lock every write to `QUEUE.md`*: hold it for the read, the write AND the
# commit. Releasing after the edit and before the commit passes every other assertion here — the
# files are right and the commit lands — so nothing but observing the lock at commit time can tell
# the two apart. A pre-commit hook is that observation.
echo "FR1 — the lock is still held at the moment the commit runs"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0020 | Locked through | develop | in-progress | 0000 |' 0020 develop in-progress tok0
cat > "$FIX/.git/hooks/pre-commit" <<'HOOK'
#!/bin/sh
if [ -d "$(git rev-parse --show-toplevel)/.claude/backlog/.lock" ]; then
  echo held > "$(git rev-parse --show-toplevel)/.lock-witness"
else
  echo released > "$(git rev-parse --show-toplevel)/.lock-witness"
fi
exit 0
HOOK
chmod +x "$FIX/.git/hooks/pre-commit"
out="$(run_handoff 0020 tok0 verify)" && rc=0 || rc=$?
assert_rc "exits 0" "$rc" 0 "$out"
assert_contains "the lock was held when the commit ran" "$(cat "$FIX/.lock-witness" 2>/dev/null || echo MISSING)" 'held'
assert_not_contains "the lock does not survive the run" "$(ls -a "$FIX/.claude/backlog")" '.lock'

# --- FR1 — column order is not a contract ------------------------------------------------------
echo "FR1 — a reordered table hands off by column name, not by index"
scaffold '| Status | ID | Next | Title | Parent |' '|--------|------|------|-------|--------|' '| in-progress | 0014 | develop | Reordered | 0000 |' 0014 develop in-progress tok0
out="$(run_handoff 0014 tok0 verify)" && rc=0 || rc=$?
assert_rc "exits 0" "$rc" 0 "$out"
assert_row "the Next and Status cells are the ones that changed" '| ready | 0014 | verify | Reordered | 0000 |'

# --- FR1 — the lock ----------------------------------------------------------------------------
echo "FR1 — a busy lock is reported as the script's stderr, not stepped over"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0015 | Locked out | develop | in-progress | 0000 |' 0015 develop in-progress tok0
mkdir "$FIX/.claude/backlog/.lock"
echo "close 0099 by ffff" > "$FIX/.claude/backlog/.lock/held-by"
before="$(fingerprint)"
out="$(run_handoff 0015 tok0 verify)" && rc=0 || rc=$?
assert_rc_nonzero "exits non-zero" "$rc" "$out"
assert_contains "says who holds the lock" "$out" 'ffff'
assert_unchanged "the backlog is untouched" "$before"
rm -rf "$FIX/.claude/backlog/.lock"

# --- usage -------------------------------------------------------------------------------------
echo "FR1 — a missing argument is a usage error, not a guess"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0016 | Usage | develop | in-progress | 0000 |' 0016 develop in-progress tok0
before="$(fingerprint)"
out="$(run_handoff 0016 tok0)" && rc=0 || rc=$?
assert_rc "a missing stage exits 2" "$rc" 2 "$out"
assert_contains "prints the usage line" "$out" 'usage: handoff <id> <token> <stage>'
assert_unchanged "the backlog is untouched" "$before"

# --- AC4 — ./next --drift reads zero for the row that moved -------------------------------------
echo "AC4 — ./next --drift exits zero for the row after a hand-off"
scaffold "$FIVE_HEAD" "$FIVE_SEP" '| 0017 | Drift free | develop | in-progress | 0000 |' 0017 develop in-progress tok0
if [ -f "$FIX/.claude/backlog/next" ]; then
  out="$(run_handoff 0017 tok0 verify)" && rc=0 || rc=$?
  assert_rc "the hand-off succeeds" "$rc" 0 "$out"
  drift="$( (cd "$FIX" && .claude/backlog/next --drift 2>&1) )" && drc=0 || drc=$?
  assert_rc "--drift exits zero" "$drc" 0 "$drift"
  assert_not_contains "no DRIFT line names the row" "$drift" '0017'
else
  bad "AC4 — no next template to check drift with"
fi

# --- AC5 — the script parses, and the installed copy matches ------------------------------------
echo "AC5 — the template parses under /bin/sh"
if sh -n "$HANDOFF_SRC" 2>/dev/null; then ok "sh -n passes on the template"; else
  bad "sh -n failed on $HANDOFF_SRC"; fi
if [ "$(head -n 1 "$HANDOFF_SRC")" = "#!/bin/sh" ]; then ok "declares #!/bin/sh"; else
  bad "does not declare #!/bin/sh"; fi
# The byte-identical install is tests/backlog-scripts-installed.test.sh's gate; assert here only
# that it has been told about the fourth script, since a guard that lists three cannot see a
# fourth diverge.
assert_contains "the install guard covers handoff" \
  "$(cat "$ROOT/tests/backlog-scripts-installed.test.sh")" 'SCRIPTS="next claim close handoff"'

# --- AC6 — develop and verify name the script and keep the fallback -----------------------------
echo "AC6 — both stages name ./handoff as the supported path, and keep the by-hand fallback"
DEV="$(cat "$ROOT/skills/develop/SKILL.md")"
VER="$(cat "$ROOT/skills/verify/SKILL.md")"
assert_contains "develop names the command" "$DEV" '.claude/backlog/handoff'
assert_contains "develop keeps a by-hand fallback" "$DEV" 'By hand'
assert_contains "verify names the command" "$VER" '.claude/backlog/handoff'
assert_contains "verify keeps a by-hand fallback" "$VER" 'By hand'

# --- AC7 / FR4 — the release is the stage's final act -------------------------------------------
# Defect 2 is an ORDERING, so it has no runtime assertion. The rule and the incident that produced
# it are asserted where a session reads them.
echo "AC7 — CONCURRENCY.md states that the release is a stage's final act, with its reason"
CON="$(cat "$ROOT/references/CONCURRENCY.md")"
assert_contains "the rule is named" "$CON" 'The release is the final act'
assert_contains "the 29-second window is the reason given" "$CON" '29 seconds'
assert_contains "it says a lock cannot see this" "$CON" 'No lock can see this'
assert_contains "develop states the ordering" "$DEV" 'release is the final act'
assert_contains "verify states the ordering" "$VER" 'release is the final act'

echo "AC7 — the section that enumerates the scripts counts four"
assert_contains "CONCURRENCY.md heads it 'The four scripts'" "$CON" '## The four scripts'
assert_contains "and describes handoff there" "$CON" './handoff <id> <token> <stage>'

# --- result -------------------------------------------------------------------------------------
echo
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
