#!/bin/sh
#
# A backlog scaffolded from skills/queue/templates/ alone can close a ticket (0196).
#
# `queue` scaffolds by copying every template, and `close` refuses without a DONE.md holding a table
# whose header has an `ID` cell — so a template set with no DONE.md leaves every fresh backlog unable
# to close anything, and the first project to scaffold had to invent the file by reading close's awk.
# This case copies the template directory, nothing else, into a throwaway repo, captures one row and
# closes it. The DONE.md row is asserted whole, every cell, because close leaves a column it does not
# recognise blank and still exits 0: a renamed header cell shows up only as an empty cell.
#
# Usage:  tests/scaffold-close.test.sh
#
# Requires: git, sh, awk. No runner — this project has none.

set -eu
# Announce an abort instead of exiting silently (0169): a death under `set -eu` otherwise prints the
# passes reached and no tally. TALLIED=1 follows the tally; exiting without it says ABORTED and never
# exits 0. Byte-identical in every tests/*.test.sh, which tests/abort-announce.test.sh asserts.
TALLIED=""
announce_abort() {
  abort_status=$?
  if [ -z "$TALLIED" ]; then
    printf '\nABORTED before the tally: %s passed, %s failed so far (exit %s)\n' \
      "${PASS:-0}" "${FAIL:-0}" "$abort_status"
    [ "$abort_status" -ne 0 ] || abort_status=1
  fi
  if [ "$#" -gt 0 ]; then "$@" || true; fi
  exit "$abort_status"
}
trap announce_abort EXIT

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
TEMPLATES="$ROOT/skills/queue/templates"
[ -d "$TEMPLATES" ] || { echo "no templates directory at $TEMPLATES" >&2; exit 2; }

PASS=0
FAIL=0
FIX=""

cleanup() { [ -n "$FIX" ] && rm -rf "$FIX"; return 0; }
trap 'announce_abort cleanup' EXIT
trap cleanup INT TERM

BL=".backlog"

ok()  { PASS=$((PASS + 1)); echo "  ok   — $1"; }
bad() { FAIL=$((FAIL + 1)); echo "  FAIL — $1"; }
saw() { printf '%s\n' "$1" | sed '1s/^/         saw: /; 1!s/^/              /'; }

# --- fixture: the templates, and only the templates -------------------------------------------
FIX="$(mktemp -d)"
git -C "$FIX" init -q
git -C "$FIX" config user.email test@example.invalid
git -C "$FIX" config user.name "scaffold-close test"
mkdir -p "$FIX/$BL/items"
cp "$TEMPLATES"/* "$FIX/$BL/"
chmod +x "$FIX/$BL/close"

# Capture one row: a QUEUE line under the template's header, and its item file.
printf '%s\n' '| 9901 | Scaffold fixture row | verify | in-progress |  |' >> "$FIX/$BL/QUEUE.md"
cat > "$FIX/$BL/items/9901-scaffold-fixture.md" <<'ITEM'
---
id: "9901"
title: Scaffold fixture row
type: chore
next: verify
status: in-progress
qa_level: unit
created: 2026-10-25
blocked_by: []
claimed_by: "fx01"
claimed_at: 2026-10-25T00:00:00Z
touches:
---

## Acceptance criteria

- [ ] AC1 — the only criterion

## QA evidence

Conventions: ../conventions

ITEM
git -C "$FIX" add -A
git -C "$FIX" commit -q -m "fixture"

# --- AC1: close succeeds against the scaffolded DONE.md ---------------------------------------
echo "AC1 — a backlog scaffolded from the templates alone closes a ticket"
out="$( (cd "$FIX" && "$BL/close" 9901 fx01) 2>&1)" && rc=0 || rc=$?
if [ "$rc" -eq 0 ]; then ok "close exits 0"; else bad "close exits 0 (got $rc)"; saw "$out"; fi

# --- AC2: every header cell is one close keys on, so the row is filled cell for cell ----------
echo "AC2 — the DONE.md row carries a value in every column the template declares"
today="$(date -u +%Y-%m-%d)"
row='| 9901 | Scaffold fixture row | chore | unit | '"$today"' | [items/9901-scaffold-fixture.md](items/9901-scaffold-fixture.md) |'
done_rows="$(sed -n '/^|/p' "$FIX/$BL/DONE.md" 2>/dev/null || true)"
if [ -f "$FIX/$BL/DONE.md" ] && grep -Fxq "$row" "$FIX/$BL/DONE.md"; then ok "DONE.md holds the whole row"; else
  bad "DONE.md holds the whole row"; echo "         expected line: $row"; saw "$done_rows"; fi
case "$out" in
  *"left blank"*) bad "close names no column it could not fill"; saw "$out" ;;
  *)              ok  "close names no column it could not fill" ;;
esac

echo
echo "$PASS passed, $FAIL failed"
TALLIED=1
[ "$FAIL" -eq 0 ] || exit 1
