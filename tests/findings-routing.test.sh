#!/bin/sh
#
# Guard: a parked finding is routed by what it is ABOUT, not by which repo the session stands in
# (0078).
#
# WHY THIS EXISTS:
#
# Every stage skill's *park what surprised you* step wrote to the LOCAL project's `FINDINGS.md`
# whatever the finding was about, so a finding about a skill, a reference file, a backlog script or
# a convention had no route to the repo that owns it. From there the project's `/queue` writes rows
# to the PROJECT's queue, where a skill defect does not belong, and `CONCURRENCY.md`'s *A stage
# writes only the ticket it holds* forbids a stage from authoring a row anywhere else — so the only
# thing that ever crossed the boundary was `/retro`, which makes edits and never rows.
#
# Measured, not feared: AetherWorks' buffer on 2026-09-01 held 44 entries over ten days, 25 of them
# pointing at a skill, a convention file or a backlog script, while 0 of its 34 queue rows did. Two
# entries recurred verbatim while waiting, and one was re-measured a third time before anyone was
# permitted to act on it.
#
# THE RESOLUTION HALF IS THE PART THAT FAILS QUIETLY, which is why AC2 and AC3 are separate cases.
# A session that DERIVES the tools repo from the plugin machinery lands somewhere that reads as
# success: measured 2026-09-09, the install directory is not a git repository at all, while the
# marketplace clone beside it IS one — correct `origin`, identical `HEAD`, a complete backlog with
# `FINDINGS.md` and the scripts — so it looks exactly like a working checkout. It also reported
# `ahead 213` of its own stale `origin/main` while being level with it, so a session standing there
# gets a confidently wrong answer to "am I behind" as well. Hence: resolved from config, never
# derived, and a destination that is not a writable checkout gets a MARKED local park instead.
#
# THE ASSERTIONS ARE SCOPED TO THE PARK STEP'S WINDOW, NEVER TO THE FILE. `FINDINGS.md`, `subject`
# and `local` are ordinary words elsewhere in these skills, and a file-wide grep would stay green on
# a rule moved out of the step that has to obey it — `testing-conventions.md`, *anchor an assertion
# to the claim, not to the document that contains it*. The scoping is itself proved falsifiable
# below: a fixture carrying every phrase OUTSIDE the window must fail, not pass.
#
# THE WINDOW IS FOUND BY HEADING TEXT, NOT BY STEP NUMBER. The park step is Step 5 in `design`,
# Step 6 in `retro` and `verify`, Step 7 in `develop` and `queue` and Step 8 in `prototype`, and
# those numbers move whenever a step is inserted. Keying on the number would red these cases on an
# edit that did not touch the rule.
#
# PHRASES ARE SHORT ENOUGH TO SIT ON ONE SOURCE LINE. `grep` is line-based, so an asserted phrase
# straddling a line break cannot be matched at all, and rewrapping a guarded paragraph is therefore
# a breaking change here (`CLAUDE.md`).
#
# Usage:  tests/findings-routing.test.sh
#         SHOW_MATCHED=1 tests/findings-routing.test.sh   # print the window each case matched in
#
# Requires: sh, awk. No runner — this project has none.

set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
CONV="$ROOT/references/CONVENTIONS.md"
[ -f "$CONV" ] || { echo "no file at $CONV" >&2; exit 2; }

# Every skill with a park step. FR1 says EVERY stage skill routes by subject, so all six are
# asserted; the item's ACs name three of them and a rule half-applied across six files is the drift
# the NFR table exists to stop.
SKILLS='design develop prototype queue retro verify'

PARK='Park what surprised you'
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

# window <file> <heading-substring> — from the `##` heading holding that text to the line before
# the next `##` heading. Empty when the heading is gone, which every case reports rather than
# passing over.
window() {
  awk -v want="$2" '
    !inw && /^## / && index($0, want) { inw = 1; print; next }
    inw && /^## / { exit }
    inw { print }
  ' "$1"
}

window_has() {
  [ -n "$1" ] || return 1
  case "$1" in *"$2"*) return 0 ;; *) return 1 ;; esac
}

in_window() {
  if [ -z "$2" ]; then
    bad "$1 — the window is EMPTY; its heading is gone, so nothing was searched"
    return 0
  fi
  if window_has "$2" "$3"; then
    ok "$1"; saw_on_pass "$2"
  else
    bad "$1 — expected in the step: $3"; saw "$2"
  fi
}

# The one sentence each park step carries. The full rule lives in references/CONVENTIONS.md and is
# CITED here rather than copied — six copies of it is the drift the NFR table forbids — so the
# assertion is deliberately the pointer, not the rule.
ROUTE='Route it by subject, not by where you are standing'

echo "AC1 — every stage skill's park step routes by subject rather than by where the session stands"
for s in $SKILLS; do
  f="$ROOT/skills/$s/SKILL.md"
  if [ ! -f "$f" ]; then
    bad "AC1 — no file at skills/$s/SKILL.md"
    continue
  fi
  W="$(window "$f" "$PARK")"
  in_window "AC1 — skills/$s/SKILL.md routes the park by subject" "$W" "$ROUTE"
done

echo "AC1 — and each park step names the rule's single home rather than restating it"
for s in $SKILLS; do
  W="$(window "$ROOT/skills/$s/SKILL.md" "$PARK")"
  in_window "AC1 — skills/$s/SKILL.md cites the rule instead of copying it" "$W" 'references/CONVENTIONS.md'
done

# ---------------------------------------------------------------------------
# The rule itself. One home, so one window: a section of references/CONVENTIONS.md, which every
# stage already resolves and reads before it acts, so the pointer costs no extra fetch.
# ---------------------------------------------------------------------------

RULE='Routing a finding to the repo it is about'
WR="$(window "$CONV" "$RULE")"

echo "AC1 — the rule names all three destinations, so no finding is left without one"
in_window "AC1 — a convention finding goes to the conventions repo's outside buffer" "$WR" 'gaps found from outside'
in_window "AC1 — a tools finding goes to the tools repo's backlog buffer"            "$WR" "the tools repo's \`.claude/backlog/FINDINGS.md\`"
in_window "AC1 — everything else stays local"                                        "$WR" 'stays in the local'

echo "AC2 — the destination repo is resolved, and nothing resolving is a stop rather than a guess"
in_window "AC2 — the destinations are resolved, never guessed"        "$WR" 'resolved, never guessed'
in_window "AC2 — the tools repo comes from a declared config key"     "$WR" 'tools.path'
in_window "AC2 — and it is resolved the way conventions.path is"      "$WR" 'conventions.path'
in_window "AC2 — nothing resolving stops rather than guessing"        "$WR" 'Nothing resolving is a stop'

# The refusal is only half the rule: a session that DERIVES the repo from the plugin install never
# reaches the refusal at all, because the derivation succeeds. Asserted separately so removing the
# prohibition cannot hide behind the refusal sentence still being present.
echo "AC2 — deriving the repo from the plugin install is named and forbidden"
in_window "AC2 — the plugin install is not a route to the repo"  "$WR" 'Never derive either from the plugin install'
in_window "AC2 — and the reason is that the guess reads as success" "$WR" 'reads as a working checkout'

echo "AC3 — the install-only fallback is a MARKED local park naming its destination"
in_window "AC3 — a non-writable destination falls back to a marked local park" "$WR" 'falls back to a marked local park'
in_window "AC3 — the marker names the repo the entry is for"                   "$WR" '[for <repo>]'
in_window "AC3 — so a later retro forwards it rather than re-deriving it"      "$WR" 'forwards it'

echo "AC4 — the privacy constraint sits at the routing rule, where the crossing is decided"
in_window "AC4 — a finding crossing into a public tool repo carries no company material" "$WR" 'carries no company material'
in_window "AC4 — and an entry that cannot meet the receiving repo's bar stays local"     "$WR" 'stays local'

echo "FR4 — the commit is one per repo, by pathspec, in the same turn"
in_window "FR4 — one commit per repo, by pathspec"       "$WR" 'One commit per repo, by pathspec'
in_window "FR4 — never one commit spanning two repos"    "$WR" 'never one spanning two repos'
in_window "FR4 — and the park takes the receiving backlog's lock" "$WR" 'lock'

# ---------------------------------------------------------------------------
# FR5 — routing writes a tool finding away from the local buffer, so a retro that reads only the
# local buffer would never see it again. The read side is asserted in the step that does the
# reading, not in the step that does the parking.
# ---------------------------------------------------------------------------

echo "FR5 — retro reads the tools repo's buffer as well as the local one"
W1="$(window "$ROOT/skills/retro/SKILL.md" 'Read the buffer')"
in_window "FR5 — the tools repo's buffer is a second input to Step 1" "$W1" "the tools repo's buffer as well"
in_window "FR5 — resolved by the routing rule, not discovered"        "$W1" 'Routing a finding to the repo it is about'

# ---------------------------------------------------------------------------
# The falsifiability probes. The fixtures drive the same matcher as the cases above, so a scoping
# bug reds here rather than passing silently up there. A guard only ever seen passing is
# indistinguishable from one wired to nothing.
# ---------------------------------------------------------------------------

FIX="$(mktemp -d)"

# A deletion probe is only evidence if the phrase was THERE to delete. `grep -v` over a file that
# never carried it returns the file unchanged, the window then lacks the phrase, and the case
# reports a clean pass — so the probe would pass identically before and after the rule was written,
# which is the guard-that-cannot-fail shape `testing-conventions.md` names. Asserting presence
# first is what makes the absence afterwards mean something.
echo "AC5 — deleting the routing sentence from any one skill turns a case red"
for s in $SKILLS; do
  W_REAL="$(window "$ROOT/skills/$s/SKILL.md" "$PARK")"
  grep -v "$ROUTE" "$ROOT/skills/$s/SKILL.md" > "$FIX/deleted-$s.md"
  W2="$(window "$FIX/deleted-$s.md" "$PARK")"
  if ! window_has "$W_REAL" "$ROUTE"; then
    bad "AC5 — skills/$s/SKILL.md never carried the sentence, so deleting it proves nothing"
  elif window_has "$W2" "$ROUTE"; then
    bad "AC5 — the sentence was deleted from $s and the matcher still saw it; its case proves nothing"
    saw "$W2"
  else
    ok "AC5 — deleting the routing sentence from skills/$s/SKILL.md turns its case red"
  fi
done

echo "AC5 — the fallback and the privacy clause red independently of each other"
grep -v 'falls back to a marked local park' "$CONV" > "$FIX/no-fallback.md"
WF="$(window "$FIX/no-fallback.md" "$RULE")"
if window_has "$WF" 'falls back to a marked local park'; then
  bad "AC5 — the fallback sentence was deleted and the matcher still saw it"
elif window_has "$WF" 'carries no company material'; then
  ok "AC5 — deleting the fallback reds AC3 while leaving AC4 green, so neither covers the other"
else
  bad "AC5 — deleting the fallback also removed the privacy clause; one guard is covering two claims"
fi

grep -v 'carries no company material' "$CONV" > "$FIX/no-privacy.md"
WP="$(window "$FIX/no-privacy.md" "$RULE")"
if window_has "$WP" 'carries no company material'; then
  bad "AC5 — the privacy sentence was deleted and the matcher still saw it"
elif window_has "$WP" 'falls back to a marked local park'; then
  ok "AC5 — deleting the privacy clause reds AC4 while leaving AC3 green"
else
  bad "AC5 — deleting the privacy clause also removed the fallback; one guard is covering two claims"
fi

echo "AC5 — phrases outside the park step do not satisfy the guard"
cat > "$FIX/outside.md" <<'FIXTURE'
## Step 4 — Build it

Route it by subject, not by where you are standing, per `references/CONVENTIONS.md`.

## Step 7 — Park what surprised you

Park what surprised you in `.claude/backlog/FINDINGS.md`, one dated line.

## Step 8 — Report
FIXTURE
W3="$(window "$FIX/outside.md" "$PARK")"
if window_has "$W3" "$ROUTE"; then
  bad "AC5 — the window leaked past its own heading; the rule could sit in any step and pass"
  saw "$W3"
else
  ok "AC5 — the guard is scoped to the park step, not to the file"
fi

echo "AC5 — a deleted heading is an empty window, reported rather than silently green"
cat > "$FIX/gone.md" <<'FIXTURE'
## Step 8 — Report

The park step's heading was deleted wholesale.
FIXTURE
W4="$(window "$FIX/gone.md" "$PARK")"
if [ -n "$W4" ]; then
  bad "AC5 — a missing heading produced a non-empty window: $W4"
else
  ok "AC5 — a missing park heading is an empty window, which every case reports as a failure"
fi

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
