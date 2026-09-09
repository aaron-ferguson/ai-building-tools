#!/bin/sh
#
# Guard: a session that will edit a tool repo anchors itself to the remote — before its first
# check, and again at the version bump (0075).
#
# WHY THIS EXISTS:
#
# On 2026-09-01 a retro edited this repo 47 commits behind `origin/main` and did not know it. Two
# costs, both measured. The same job was done twice four days apart — local `13a4e81` and upstream
# `ec650cd` are the same commit written by two sessions that could not see each other — and it
# surfaced only as a rebase conflict, whose resolution meant choosing between two of the author's
# own commits. And the version bump was picked by reading the local `plugin.json` and adding one,
# landing on a `0.9.6` upstream had already released.
#
# THE DESTINATION CHECK IS THE EXPENSIVE HALF, WHICH IS WHY IT IS ASSERTED SEPARATELY. Every grep
# `retro` Step 3 makes — does this rule already exist, was it invalidated — ran against stale files
# and had to be re-run after the pull. A stale check is worse than no check because it reads as
# evidence: a green "the rule is not there yet" is indistinguishable from a real one.
#
# THE FETCH IS READ-ONLY AND THE STOP IS THE POINT. Resolving divergence can mean choosing between
# two of the author's own commits, so no step here pulls, merges or rebases (`git-conventions.md`).
# `behind stops the session` is therefore asserted as its own case: a rule that only warns is the
# one the 2026-09-01 pass would have read past.
#
# WHICH CHECKOUT IS NOT OBVIOUS, AND THE WRONG ANSWER LOOKS RIGHT. Measured 2026-09-09: the plugin
# install directory is not a git repository at all, while the marketplace clone beside it IS one —
# correct `origin`, identical `HEAD`, a whole backlog — and it reported `ahead 278` of its own stale
# `origin/main` while being level with it. A session standing there gets a confidently wrong answer
# to "am I behind", in the direction that reads as safe. Hence the `never the plugin install` case.
#
# THE ASSERTIONS ARE SCOPED TO THE STEP THAT HAS TO OBEY THE RULE, NEVER TO THE FILE. `fetch`,
# `remote` and `behind` are ordinary words throughout both skills, and a file-wide grep would stay
# green on a rule moved out of the step that reads it — `testing-conventions.md`, *anchor an
# assertion to the claim, not to the document that contains it*. The scoping is itself proved
# falsifiable below: a fixture carrying every phrase OUTSIDE the window must fail, not pass.
#
# PHRASES ARE SHORT ENOUGH TO SIT ON ONE SOURCE LINE. `grep` is line-based, so an asserted phrase
# straddling a line break cannot be matched at all, and rewrapping a guarded paragraph is therefore
# a breaking change here (`CLAUDE.md`).
#
# Usage:  tests/remote-anchor.test.sh
#         SHOW_MATCHED=1 tests/remote-anchor.test.sh   # print the window each case matched in
#
# Requires: sh, awk. No runner — this project has none.

set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
RETRO="$ROOT/skills/retro/SKILL.md"
DEVELOP="$ROOT/skills/develop/SKILL.md"
for f in "$RETRO" "$DEVELOP"; do
  [ -f "$f" ] || { echo "no file at $f" >&2; exit 2; }
done

SAW_LINES=14

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

# The step that greps the destination is the step the fetch has to precede, so the window opens on
# Step 3's own heading and closes on Step 4's.
RSTEP3='## Step 3 — Check the destination, then choose it'
REND3='^## Step 4'
W3="$(window "$RETRO" "$RSTEP3" "$REND3")"

echo "AC1 — retro fetches every repo it will edit before the destination checks"
in_window "AC1 — the fetch covers every repo the pass will edit"   "$W3" 'every repo it will edit'
in_window "AC1 — a check against a stale tree is not evidence"     "$W3" 'stale tree is not evidence'
in_window "AC1 — being behind stops the pass rather than warning it" "$W3" 'Behind the remote stops the pass'
in_window "AC1 — the fetch is read-only; the pull is the user's call" "$W3" 'the pull is the user'
in_window "AC1 — and the checkout is the resolved one, never the plugin install" "$W3" 'never the plugin install'

# The step that owns the release chain is the step that has to say where the chain starts and what
# the version is derived from.
RSTEP5='## Step 5 — Make it durable'
REND5='^## Step 6'
W5="$(window "$RETRO" "$RSTEP5" "$REND5")"

echo "AC2 — the release chain in Step 5 names the fetch as its first step"
in_window "AC2 — the chain begins with a fetch" "$W5" 'chain begins with a fetch'

echo "AC3 — the bump derives from the remote, and the collision that forced it is named"
in_window "AC3 — the next version comes from the remote's plugin.json" "$W5" "remote's \`plugin.json\`"
in_window "AC3 — never from the local file alone"                      "$W5" 'never the local file'
in_window "AC3 — and the collision is named, not merely implied"       "$W5" 'collided with a version already released'

# FR1 reaches every session that edits a tool repo, not only `retro`. `develop` works this backlog
# by editing the skills in it, and its Step 2 staleness greps and Step 3 guard greps are damaged by
# a stale tree in exactly the way Step 3 of `retro` is.
DSTEP1='## Step 1 — Select and claim the item'
DEND1='^## Step 2'
WD1="$(window "$DEVELOP" "$DSTEP1" "$DEND1")"

echo "FR1 — develop anchors to the remote before it claims"
in_window "FR1 — the fetch precedes the claim"                     "$WD1" 'Fetch before you claim'
in_window "FR1 — a check against a stale tree is not evidence"     "$WD1" 'stale tree is not evidence'
in_window "FR1 — being behind stops the session rather than warning it" "$WD1" 'Behind the remote stops the session'

# ---------------------------------------------------------------------------
# AC4 — the falsifiability probes. The fixtures drive the same matcher as the
# cases above, so a scoping bug reds here rather than passing silently up there.
# ---------------------------------------------------------------------------

FIX="$(mktemp -d)"

echo "AC4 — deleting the fetch sentence turns AC1 red"
grep -v 'every repo it will edit' "$RETRO" > "$FIX/nofetch.md"
WP="$(window "$FIX/nofetch.md" "$RSTEP3" "$REND3")"
if window_has "$WP" 'every repo it will edit'; then
  bad "AC4 — the fetch sentence was deleted and the matcher still saw it; AC1 proves nothing"
  saw "$WP"
else
  ok "deleting the fetch sentence turns AC1 red"
fi

echo "AC4 — deleting the stale-evidence sentence turns AC1 red"
grep -v 'stale tree is not evidence' "$RETRO" > "$FIX/noevidence.md"
WP="$(window "$FIX/noevidence.md" "$RSTEP3" "$REND3")"
if window_has "$WP" 'stale tree is not evidence'; then
  bad "AC4 — the sentence was deleted and the matcher still saw it; AC1 proves nothing"
  saw "$WP"
else
  ok "deleting the stale-evidence sentence turns AC1 red"
fi

echo "AC4 — deleting the chain's first step turns AC2 red"
grep -v 'chain begins with a fetch' "$RETRO" > "$FIX/nochain.md"
WP="$(window "$FIX/nochain.md" "$RSTEP5" "$REND5")"
if window_has "$WP" 'chain begins with a fetch'; then
  bad "AC4 — the sentence was deleted and the matcher still saw it; AC2 proves nothing"
  saw "$WP"
else
  ok "deleting the chain's first step turns AC2 red"
fi

# A warning is the cheap answer to this ticket: `git fetch` in the instruction and nothing about
# what a behind checkout does. That fixture must fail, or the stop is decorative.
echo "AC4 — a fetch that only warns does not satisfy the guard"
cat > "$FIX/warn-only.md" <<'FIXTURE'
## Step 3 — Check the destination, then choose it

Run `git fetch` on every repo it will edit before the first grep, and note how far behind you are.

## Step 4 — Write it
FIXTURE
WP="$(window "$FIX/warn-only.md" "$RSTEP3" "$REND3")"
if window_has "$WP" 'Behind the remote stops the pass' || window_has "$WP" 'stale tree is not evidence'; then
  bad "AC4 — a warn-only instruction satisfied the guard; the stop could be dropped silently"
  saw "$WP"
else
  ok "a fetch that only warns stays red"
fi

echo "AC4 — the phrases outside retro Step 3 do not satisfy the guard"
cat > "$FIX/outside3.md" <<'FIXTURE'
## Step 2 — Propose, then wait

Fetch every repo it will edit before the first grep: a check against a stale tree is not evidence,
so Behind the remote stops the pass and the pull is the user's call. Use the resolved checkout,
never the plugin install.

## Step 3 — Check the destination, then choose it

Grep the destination before writing anything.

## Step 4 — Write it
FIXTURE
WP="$(window "$FIX/outside3.md" "$RSTEP3" "$REND3")"
LEAKED=0
for phrase in 'every repo it will edit' 'stale tree is not evidence' \
              'Behind the remote stops the pass' 'the pull is the user' \
              'never the plugin install'; do
  window_has "$WP" "$phrase" && LEAKED=1
done
if [ "$LEAKED" = 1 ]; then
  bad "AC4 — the window leaked past its own heading; the rule could sit in any step and pass"
  saw "$WP"
else
  ok "the fetch rule is asserted in the step that greps the destination, not across the file"
fi

echo "AC4 — the phrases outside develop Step 1 do not satisfy the guard"
cat > "$FIX/outside1.md" <<'FIXTURE'
## Step 1 — Select and claim the item

Run `./next develop`.

## Step 2 — Restate the contract before writing code

Fetch before you claim: a check against a stale tree is not evidence, and
Behind the remote stops the session.
FIXTURE
WP="$(window "$FIX/outside1.md" "$DSTEP1" "$DEND1")"
LEAKED=0
for phrase in 'Fetch before you claim' 'stale tree is not evidence' \
              'Behind the remote stops the session'; do
  window_has "$WP" "$phrase" && LEAKED=1
done
if [ "$LEAKED" = 1 ]; then
  bad "AC4 — the window leaked past its own heading; the rule could sit in any step and pass"
  saw "$WP"
else
  ok "the develop rule is asserted in the step that claims, not across the file"
fi

echo "AC4 — a deleted heading is an empty window, reported rather than silently green"
cat > "$FIX/gone.md" <<'FIXTURE'
## Step 4 — Write it

Step 3's heading was deleted wholesale.
FIXTURE
WP="$(window "$FIX/gone.md" "$RSTEP3" "$REND3")"
if [ -n "$WP" ]; then
  bad "AC4 — the window found text after its heading was deleted: $WP"
else
  ok "an empty window is a named failure, never a vacuous pass"
fi

# The two retro windows must not be interchangeable, or either step could carry both rules and the
# scoping above would be decorative.
echo "AC4 — Step 5's chain rule is not readable from Step 3's window"
if window_has "$W3" 'chain begins with a fetch'; then
  bad "AC4 — Step 3 also carries the chain rule; the two windows are not distinguishing"
  saw "$W3"
else
  ok "the chain rule is asserted in the step that releases, not the one that greps"
fi

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" = 0 ]
