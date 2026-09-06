#!/bin/sh
#
# Guard: retro runs the target repo's suite before it commits a tool edit (0076).
#
# WHY THIS EXISTS:
#
# `retro` edits skills, scripts and conventions, and until 0076 no step in it ran a test. Step 4
# writes the edits and Step 5 commits and releases them, so the session that changes a tool was the
# one least likely to learn it had broken that tool — and the break is invisible until another
# session trips on it. The AetherWorks retro of 2026-09-01 ran this repo's suite unprompted and
# found a shell-quoting defect already committed: an apostrophe inside `close`'s single-quoted
# `awk` program closed the quote, and `close.test.sh` failed in a way that reads as broken
# reconcile logic and names nothing about quotes.
#
# Two traps make "just run the suite" insufficient as advice, which is why AC2 exists alongside
# AC1. This repo's suite COMMITS INSIDE THE LIVE REPO, so running it over uncommitted edits
# produces failures that look like logic errors and are tree pollution; telling that apart from a
# real red needs the worktree comparison `develop` Step 5 prescribes. And a guard that rejects the
# edit — the size guard rejected that pass's draft twice — is an editor rather than a gate: both
# rejections forced a rule into a better home, so relocation is the first answer and an exemption
# the second.
#
# THE ASSERTIONS ARE SCOPED TO STEP 5's WINDOW, NEVER TO THE FILE. `worktree` and `suite` are
# ordinary words elsewhere in this skill, and a file-wide grep would stay green on a rule moved out
# of the step that has to obey it — `testing-conventions.md`, *anchor an assertion to the claim,
# not to the document that contains it*. The scoping is itself proved falsifiable below: a fixture
# carrying every phrase OUTSIDE the window must fail, not pass.
#
# PHRASES ARE SHORT ENOUGH TO SIT ON ONE SOURCE LINE. `grep` is line-based, so an asserted phrase
# straddling a line break cannot be matched at all, and rewrapping a guarded paragraph is therefore
# a breaking change here (`CLAUDE.md`).
#
# Usage:  tests/retro-tool-edit.test.sh
#         SHOW_MATCHED=1 tests/retro-tool-edit.test.sh   # print the window each case matched in
#
# Requires: sh, awk. No runner — this project has none.

set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
RETRO="$ROOT/skills/retro/SKILL.md"
[ -f "$RETRO" ] || { echo "no file at $RETRO" >&2; exit 2; }

SAW_LINES=12

PASS=0
FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }

FIX=""
cleanup() { [ -n "$FIX" ] && rm -rf "$FIX"; return 0; }
trap cleanup EXIT INT TERM

saw() {
  printf '%s\n' "$1" | sed 's/^/         | /' | head -"$SAW_LINES"
  n="$(printf '%s\n' "$1" | wc -l | tr -d ' ')"
  [ "$n" -gt "$SAW_LINES" ] && printf '         | ... (%s lines in the window)\n' "$n"
  return 0
}
saw_on_pass() { [ -n "${SHOW_MATCHED:-}" ] && saw "$1"; return 0; }

# window <file> <start-fixed-string> <end-regex> — from the line holding the opening phrase to the
# line before the next matching heading. Empty when the opening phrase is gone, which every case
# reports rather than passing over.
window() {
  awk -v start="$2" -v endre="$3" '
    !inw && index($0, start) { inw = 1 }
    inw && $0 ~ endre && !first { exit }
    inw { print; first = 0 }
  ' "$1"
}

window_has() {
  [ -n "$1" ] || return 1
  case "$1" in *"$2"*) return 0 ;; *) return 1 ;; esac
}

in_window() {
  if [ -z "$2" ]; then
    bad "$1 — the window is EMPTY; its opening phrase is gone, so nothing was searched"
    return 0
  fi
  if window_has "$2" "$3"; then
    ok "$1"; saw_on_pass "$2"
  else
    bad "$1 — expected in the step: $3"; saw "$2"
  fi
}

# The step that commits is the step that must have run the suite, so the window opens on Step 5's
# own heading and closes on Step 6's.
STEP5='## Step 5 — Make it durable'
END5='^## Step 6'
W="$(window "$RETRO" "$STEP5" "$END5")"

echo "AC1 — the step that commits requires the target repo's suite to have run first"
in_window "AC1 — the suite runs before the commit that carries the edit" "$W" 'suite before the commit that carries'
in_window "AC1 — and it is that repo's own configured command"           "$W" '`config.yml`'
in_window "AC1 — a repo with no command is said to have none, not skipped" "$W" 'no configured command'

echo "AC2 — a red is the edit's until proven otherwise, and the discriminator is named"
in_window "AC2 — the red belongs to the edit until proven otherwise" "$W" 'until proven otherwise'
in_window "AC2 — the suite commits inside the live repo, which is what pollutes" "$W" 'commits inside the live repo'
in_window "AC2 — the worktree comparison is named as the discriminator" "$W" 'worktree'

# 'in the same turn' alone is satisfied by the Commit-by-pathspec bullet that was already in this
# step, so the assertion would hold with no worktree rule present at all — the guard-that-cannot-fail
# shape `testing-conventions.md` names. The phrase is anchored to the worktree it is about.
echo "FR4 — the worktree is removed in the same turn"
in_window "FR4 — the worktree is removed in the same turn" "$W" 'worktree in the same turn'

echo "AC3 — a rejecting guard is answered by relocating first, exempting second"
in_window "AC3 — relocate first, exempt second"        "$W" 'Relocate first, exempt second'
in_window "AC3 — and the relocation is what gets recorded" "$W" 'never an exemption'

# ---------------------------------------------------------------------------
# The falsifiability probes. The fixtures drive the same matcher as the cases
# above, so a scoping bug reds here rather than passing silently up there.
# ---------------------------------------------------------------------------

FIX="$(mktemp -d)"

echo "FR — AC1 goes red when the suite-run sentence is deleted"
grep -v 'suite before the commit that carries' "$RETRO" > "$FIX/deleted.md"
W2="$(window "$FIX/deleted.md" "$STEP5" "$END5")"
if window_has "$W2" 'suite before the commit that carries'; then
  bad "FR — the sentence was deleted and the matcher still saw it; AC1 proves nothing"
  saw "$W2"
else
  ok "deleting the suite-run sentence turns AC1 red"
fi

echo "FR — the phrases outside Step 5 do not satisfy the guard"
cat > "$FIX/outside.md" <<'FIXTURE'
## Step 4 — Write it

Run that repo's suite before the commit that carries the edit, per `config.yml`; a repo with
no configured command is said to have none. A red is the edit's until proven otherwise, because
this repo's suite commits inside the live repo — use a worktree, removed in the same turn.
Relocate first, exempt second, and record the relocation, never an exemption.

## Step 5 — Make it durable

Commit by pathspec.

## Step 6 — Park what surprised you
FIXTURE
W3="$(window "$FIX/outside.md" "$STEP5" "$END5")"
if window_has "$W3" 'suite before the commit that carries'; then
  bad "FR — the window leaked past its own heading; the rule could sit in any step and pass"
  saw "$W3"
else
  ok "the guard is scoped to the step that commits, not to the file"
fi

echo "FR — a deleted heading is an empty window, reported rather than silently green"
cat > "$FIX/gone.md" <<'FIXTURE'
## Step 6 — Park what surprised you

Step 5's heading was deleted wholesale.
FIXTURE
W4="$(window "$FIX/gone.md" "$STEP5" "$END5")"
if [ -n "$W4" ]; then
  bad "FR — the window found text after its heading was deleted: $W4"
else
  ok "an empty window is a named failure, never a vacuous pass"
fi

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" = 0 ]
