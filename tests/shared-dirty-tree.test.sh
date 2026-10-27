#!/bin/sh
#
# Prose guard for a result taken over a shared dirty tree (0054).
#
# develop Step 5's falsified/exposed fork assumes the tree under test is a state that exists as a
# commit. With several sessions in one checkout it routinely is not, and four failures followed:
# a red that was another session's uncommitted rename, a red another session was deliberately
# holding mid-TDD, a measurement whose subject moved mid-run, and a ticket handed to verify with
# part of its own work still uncommitted. This file asserts the rules that answer each, plus the
# receiving side in verify Step 2 and the touches: limitation in CONCURRENCY.md.
#
# Every assertion is scoped to the paragraph (or, for verify and CONCURRENCY.md, the named step or
# rule) that carries the rule, never to the whole file: these files say "git status" and "worktree"
# in a dozen other places, so a file-wide grep is satisfied by prose this rule does not govern
# (`testing-conventions.md`, anchor an assertion to the claim, not to the document that contains it).
# Each phrase is short enough to sit on one source line — grep is line-based.
#
# Usage:  tests/shared-dirty-tree.test.sh
#
# Requires: sh, awk, grep. No runner — this project has none.

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
DEV="$ROOT/skills/develop/SKILL.md"
VER="$ROOT/skills/verify/SKILL.md"
CON="$ROOT/references/CONCURRENCY.md"
for f in "$DEV" "$VER" "$CON"; do [ -f "$f" ] || { echo "missing $f" >&2; exit 2; }; done

PASS=0
FAIL=0

ok()  { PASS=$((PASS + 1)); printf '  ok   — %s\n' "$1"; }
bad() { FAIL=$((FAIL + 1)); printf '  FAIL — %s\n' "$1"; }

SCOPE="$(mktemp)"
STEP5="$(mktemp)"
trap 'announce_abort rm -f "$SCOPE" "$STEP5"' EXIT
trap 'rm -f "$SCOPE" "$STEP5"' INT TERM

# The paragraph whose first matching line contains $2, ending on its own blank line rather than on a
# line count — a count is a guess at how long the prose is and goes wrong silently (0032).
para() {
  awk -v a="$2" 'index($0, a) { f = 1 } f && /^[[:space:]]*$/ { exit } f { print }' "$1" > "$SCOPE"
}

# The section from the heading line starting $2 up to the next heading of level two.
section() {
  awk -v h="$2" 'index($0, h) == 1 { f = 1; print; next } f && /^## / { exit } f { print }' "$1" > "$SCOPE"
}

present() {
  if grep -qF -- "$2" "$SCOPE"; then ok "$1"; else
    bad "$1 — expected the scoped text to contain: $2"
    if [ -s "$SCOPE" ]; then printf '         scope:\n'; sed 's/^/           /' "$SCOPE"
    else printf '         scope: (empty — the anchor was not found)\n'; fi
  fi
}

# Every develop rule is asserted inside Step 5 — AC1's Given — so prose moved to another step reds.
awk 'index($0, "## Step 5") == 1 { f = 1 } f && /^## Step 6/ { exit } f { print }' "$DEV" > "$STEP5"

echo "0054 AC1 — develop Step 5 requires git status before a full-suite result is believed"
para "$STEP5" 'before believing any whole-suite result'
present "the rule has a paragraph of its own" 'before believing any whole-suite result'
present "and it names the command" 'git status --porcelain'

echo "0054 AC2 — it names three causes outside the falsified/exposed fork"
present "it sets them against the existing fork" 'falsified or exposed'
present "another session's uncommitted work" "another session's uncommitted work"
present "another session's deliberate red" "another session's deliberate red"
present "a measurement whose subject moved" 'a measurement whose subject moved'

echo "0054 AC3 — it names the worktree-at-your-last-commit remedy, and when it pays"
para "$STEP5" 'worktree at your own last commit'
present "the remedy has a paragraph" 'worktree at your own last commit'
present "it says why: a verdict about a tree that exists" 'a tree that exists'
present "it says when it is worth the cost" 'Worth its cost'
present "it names the conventions directory as what the worktree needs here" 'conventions directory'

echo "0054 FR3 — a red the tree is supposed to have carries its evidence into the hand-off"
para "$STEP5" 'supposed to have is attributed with evidence'
present "the case is named" 'supposed to have is attributed with evidence'
present "the evidence travels with the ticket" 'carried into the hand-off'

echo "0054 AC4 — a machine-measuring ticket pins and records its snapshot"
para "$STEP5" 'measurement of the machine it runs on'
present "the case is named" 'measurement of the machine it runs on'
present "the snapshot is pinned" 'pins its snapshot'
present "and the pin is recorded" 'records the pin'

echo "0054 AC5 — develop's hand-off requires the session's own paths committed first"
para "$STEP5" 'Commit the code by pathspec in or before that same step'
present "the hand-off step names the check" 'git status --porcelain'
present "and scopes it to the session's own paths" 'none of your own paths'

echo "0054 AC6 — verify Step 2 points at that requirement from the receiving side"
section "$VER" '## Step 2'
present "verify Step 2 names develop's hand-off requirement" 'own paths committed before the hand-off'

echo "0054 AC7 — CONCURRENCY.md says a touches: collision warns neither session"
section "$CON" '## The working tree is shared too'
present "the limitation is stated in the named rule" 'collision warns neither session'

echo
echo "$PASS passed, $FAIL failed"
TALLIED=1
[ "$FAIL" -eq 0 ] || exit 1
