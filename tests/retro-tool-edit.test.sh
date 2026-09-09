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
RELEASE="$ROOT/tools/release"
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
# 0114 — the step that names the release chain is the step that has to make it
# finishable by the session it is written for.
#
# `tools/release` asked for the push at the push, having already committed the version bump, and
# decided whether it could ask with `[ -r /dev/tty ]` — true in an agent shell. An agent-run retro
# therefore printed a prompt nobody could answer and died on the failing redirect: exit 1, no
# message, over a committed bump. The script side is fixed in `tests/release.test.sh`; what is
# asserted HERE is the half only prose can carry — who is asked, before what, and what the session
# does when there is nobody to ask.
#
# AC6 AND AC7 ARE ASSERTED AS A PAIR ON PURPOSE. A change that merely adds `--yes` to the
# instruction satisfies "the chain finishes" and quietly removes `git-conventions.md`'s per-push
# confirmation; requiring the step to also NAME where the approval is evidenced is what stops that
# being the silent answer.
#
# SCOPED TO STEP 5's WINDOW, like every case above: "release", "push" and "ask" are ordinary words
# throughout this skill, and the falsifiability probes at the foot of this file prove the scoping.
# ---------------------------------------------------------------------------

echo "0114 AC6 — the release approval is evidenced by the session's own ask, and --yes never stands in"
in_window "AC6 — the session asks the user before invoking the chain" "$W" 'asks the user before the invocation'
in_window "AC6 — and --yes carries an approval, never substitutes for one" "$W" 'never stands in for one'

echo "0114 AC7 — the step and the script's usage line name the same invocation"
in_window "AC7 — Step 5 names --bump and --yes together" "$W" 'tools/release --bump --yes'
if [ -f "$RELEASE" ] && grep -qF 'tools/release --bump --yes' "$RELEASE"; then
  ok "AC7 — the script's own usage line documents that same invocation"
else
  bad "AC7 — tools/release does not document \`tools/release --bump --yes\`, so the instruction and the script disagree about what to run"
fi

echo "0114 AC5 — the step that owns the chain says how to recover a bump that never reached the remote"
in_window "AC5 — the half-released state is named"      "$W" 'bump committed and unpushed'
in_window "AC5 — and the signal to look for is named"   "$W" 'origin/<branch>..HEAD'
in_window "AC5 — re-running the same invocation is the recovery" "$W" 're-bumps nothing'

echo "0114 AC8 — with nobody to ask, the chain is not invoked and the release is reported outstanding"
in_window "AC8 — the chain is not invoked when there is nobody to ask" "$W" 'does not invoke the chain'
in_window "AC8 — and the remaining steps go on that run's checklist" "$W" "outstanding on that run's checklist"

# ---------------------------------------------------------------------------
# b9a5ee0 — the buffer has no residents. Step 4 gives every entry it read a terminal
# disposition; Step 1 says which disposition a pass should be reaching for before
# it reads anything, and what a deferral is allowed to claim.
#
# CITED BY COMMIT, NOT BY TICKET ID, because this work had no ticket: a retro landed it
# directly. These four labels named an id that no ticket held when they were written, and
# which was afterwards issued to unrelated work and withdrawn — so they resolved to nothing,
# and were one reissue away from resolving to the wrong thing. A commit resolves permanently
# and cannot be reissued. See tests/citations.test.sh, which now reds on the same mistake.
# ---------------------------------------------------------------------------

STEP4='## Step 4 — Write it, and empty what you processed'
END4='^## Step 5'
W4C="$(window "$RETRO" "$STEP4" "$END4")"

echo "b9a5ee0 AC1 — the step that empties the buffer names four terminal dispositions"
in_window "AC1 — the four dispositions are named together" "$W4C" 'landed, absorbed, filed or dropped'
in_window "AC1 — and every one removes the entry"          "$W4C" 'no entry survives the pass that read it'

echo "b9a5ee0 AC2 — landing now is the default, and the test against filing is stated"
in_window "AC2 — the land-or-file test is completeness in this session" "$W4C" 'complete in this session'
in_window "AC2 — absorbed is not silent: the row is named and written to"  "$W4C" 'names the row and appends'

STEP1='## Step 1 — Read the buffer'
END1='^## Step 2'
W1C="$(window "$RETRO" "$STEP1" "$END1")"

echo "b9a5ee0 AC3 — Step 1 names the two modes, so a pass knows what it is reaching for"
in_window "AC3 — the end-of-run mode is named" "$W1C" 'end-of-run retro'
in_window "AC3 — the cadence mode is named"    "$W1C" 'cadence retro'

echo "b9a5ee0 AC4 — a deferral records established triage, never an unverified destination"
in_window "AC4 — a deferral records what was established" "$W1C" 'records what was established'
in_window "AC4 — the buffer converges rather than emptying in one pass" "$W1C" 'transit, not residence'

# ---------------------------------------------------------------------------
# 0111 — Step 1 said "`.claude/backlog/FINDINGS.md` is the input" and nothing about what that
# path resolves against. Invoked from a workspace root holding four backlogs and being none of
# them, the 2026-09-07 pass swept all four on freshness and threshold. That was defensible and it
# was invention: no step licensed it, and it puts a company-tracked buffer and this public repo's
# in one context.
#
# AC5 IS THE CASE THE OTHERS DO NOT MAKE. A numbered order can be present and still be a
# discovery — the sweep that produced this ticket would satisfy AC1 unchanged. The upward-only
# half and the do-not-search half are asserted separately for that reason.
#
# ALL SEVEN ARE ANCHORED TO STEP 1's WINDOW (AC3), like the cases above: "resolve", "order" and
# "buffer" are ordinary words throughout this skill, so a file-wide grep would stay green on the
# ladder moved into a step that never reads it. The scoping is proved falsifiable below.
# ---------------------------------------------------------------------------

echo "0111 AC1 — Step 1 states a numbered resolution order, not a bare relative path"
in_window "AC1 — the order is stated as an order"     "$W1C" 'Where that path resolves, in order'
in_window "AC1 — rung 1 is the repo root, walked up to" "$W1C" 'The git repository root'
in_window "AC1 — rung 2 covers a backlog below its repo root" "$W1C" 'nearest `.claude/backlog/`'

echo "0111 AC2 — nothing resolving stops the session and names what was searched"
in_window "AC2 — the last rung is a stop, not a guess" "$W1C" 'Nothing resolved'
in_window "AC2 — and the report names every directory searched" "$W1C" 'report every directory searched'
in_window "AC2 — the refusal is cited, never restated"  "$W1C" 'rung 3'

echo "0111 AC5 — the order resolves upward only, and buffers are never discovered"
in_window "AC5 — the order walks upward only"          "$W1C" 'walks upward only'
in_window "AC5 — a buffer is resolved, never discovered" "$W1C" 'resolved, never discovered'
in_window "AC5 — so a sibling buffer is unreachable by construction" "$W1C" 'unreachable by construction'

echo "0111 AC6 — a retired backlog is not swept as though it were live"
in_window "AC6 — the retirement banner is checked before the buffer is read" "$W1C" 'retirement banner'
in_window "AC6 — checked on the resolved backlog, and no other" "$W1C" "resolved backlog's own"

echo "0111 AC7 — a second buffer is read only when a rule names it"
in_window "AC7 — a naming rule is what admits a second buffer" "$W1C" 'only when a rule names it'

echo "0111 AC4 — the privacy clause sits at the order, and absence is company-tracked"
in_window "AC4 — an absent routing block is treated as company-tracked" "$W1C" 'treated as company-tracked'
in_window "AC4 — because unknown classification takes the stricter handling" "$W1C" 'the stricter handling'

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

echo "FR — AC1 goes red when a disposition is dropped from the list"
sed 's/landed, absorbed, filed or dropped/landed, absorbed or dropped/' "$RETRO" > "$FIX/threeway.md"
W5="$(window "$FIX/threeway.md" "$STEP4" "$END4")"
if window_has "$W5" 'landed, absorbed, filed or dropped'; then
  bad "FR — filing was removed from the list and the matcher still saw four; AC1 proves nothing"
  saw "$W5"
else
  ok "removing a disposition from the list turns AC1 red"
fi

echo "0111 AC5 — deleting the upward-only sentence turns the case red"
grep -v 'walks upward only' "$RETRO" > "$FIX/nodirection.md"
W6="$(window "$FIX/nodirection.md" "$STEP1" "$END1")"
if window_has "$W6" 'walks upward only'; then
  bad "0111 — the sentence was deleted and the matcher still saw it; AC5 proves nothing"
  saw "$W6"
else
  ok "deleting the upward-only sentence turns AC5 red"
fi

# AC3 for 0111. A ladder is exactly the kind of rule that reads sensibly under any heading, so the
# fixture puts every asserted phrase in a NEIGHBOURING step: the guard must stay unsatisfied, or
# the order could live in a step no pass reads before it sweeps.
echo "0111 AC3 — the phrases outside Step 1 do not satisfy the guard"
cat > "$FIX/ladder-outside.md" <<'FIXTURE'
## Step 1 — Read the buffer

Read the buffer.

## Step 2 — Propose, then wait

Where that path resolves, in order. The git repository root, then the
nearest `.claude/backlog/` above it. Nothing resolved → stop, and
report every directory searched, as `CONVENTIONS.md` rung 3 does. The order
walks upward only; a buffer is resolved, never discovered, so a sibling is
unreachable by construction. A backlog with no routing block is
treated as company-tracked, and unknown classification takes
the stricter handling. Check the resolved backlog's own `QUEUE.md` for a
retirement banner. A second buffer is read only when a rule names it.
FIXTURE
W7="$(window "$FIX/ladder-outside.md" "$STEP1" "$END1")"
LEAKED=0
for phrase in 'Where that path resolves, in order' 'report every directory searched' \
              'walks upward only' 'resolved, never discovered' 'treated as company-tracked' \
              'retirement banner' 'only when a rule names it'; do
  window_has "$W7" "$phrase" && LEAKED=1
done
if [ "$LEAKED" = 1 ]; then
  bad "0111 AC3 — the window leaked past its own heading; the order could sit in any step and pass"
  saw "$W7"
else
  ok "the resolution order is asserted in the step that reads the buffer, not across the file"
fi

echo "0114 AC5 — deleting the recovery sentence turns the case red"
grep -v 're-bumps nothing' "$RETRO" > "$FIX/norecovery.md"
W8="$(window "$FIX/norecovery.md" "$STEP5" "$END5")"
if window_has "$W8" 're-bumps nothing'; then
  bad "0114 — the recovery sentence was deleted and the matcher still saw it; AC5 proves nothing"
  saw "$W8"
else
  ok "deleting the recovery sentence turns AC5 red"
fi

# The cheap answer to this ticket is `--yes` in the instruction and silence about the approval.
# That fixture must fail AC6, or the pairing that rules it out is decorative.
echo "0114 AC6 — the instruction with --yes but no named approval does not satisfy the guard"
cat > "$FIX/yes-only.md" <<'FIXTURE'
## Step 5 — Make it durable

- **A skill edit has a release chain — run `tools/release --bump --yes` from the repo root.**
  It bumps the version, pushes, updates the install, and verifies the bytes.

## Step 6 — Park what surprised you
FIXTURE
W9="$(window "$FIX/yes-only.md" "$STEP5" "$END5")"
if window_has "$W9" 'asks the user before the invocation' || window_has "$W9" 'never stands in for one'; then
  bad "0114 AC6 — the --yes-only instruction satisfied the guard; the confirmation could be dropped silently"
  saw "$W9"
else
  ok "adding --yes without naming where the approval is evidenced stays red"
fi

echo "0114 AC8 — the phrases outside Step 5 do not satisfy the guard"
cat > "$FIX/0114-outside.md" <<'FIXTURE'
## Step 4 — Write it

Run `tools/release --bump --yes`; the session asks the user before the invocation, and `--yes`
never stands in for one. A bump committed and unpushed shows in `git log origin/<branch>..HEAD`;
re-running re-bumps nothing. With nobody to ask, this step does not invoke the chain and reports
every remaining step outstanding on that run's checklist.

## Step 5 — Make it durable

Commit by pathspec.

## Step 6 — Park what surprised you
FIXTURE
W10="$(window "$FIX/0114-outside.md" "$STEP5" "$END5")"
LEAKED114=0
for phrase in 'tools/release --bump --yes' 'asks the user before the invocation' \
              'never stands in for one' 'bump committed and unpushed' \
              'origin/<branch>..HEAD' 're-bumps nothing' 'does not invoke the chain' \
              "outstanding on that run's checklist"; do
  window_has "$W10" "$phrase" && LEAKED114=1
done
if [ "$LEAKED114" = 1 ]; then
  bad "0114 — the window leaked past its own heading; the release rules could sit in any step and pass"
  saw "$W10"
else
  ok "the release rules are asserted in the step that owns the chain, not across the file"
fi

echo "FR — Step 4's cases do not read Step 1's window, or either could carry both rules"
if window_has "$W1C" 'landed, absorbed, filed or dropped'; then
  bad "FR — Step 1 also carries the disposition list; the two windows are not distinguishing"
  saw "$W1C"
else
  ok "the disposition list is asserted in the step that empties the buffer, not the one that reads it"
fi

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" = 0 ]
