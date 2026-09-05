#!/bin/sh
#
# Guard: the QA level is written in ONE place, and the template does not hand you a second.
#
# WHY THIS EXISTS:
#
# `queue` says it plainly — *"write it exactly once, in the frontmatter"* — because an item can
# otherwise carry two answers, `qa_level: e2e` in its frontmatter and `**Level:** integration` in
# its own QA plan, both written by the same pass and differing by a multi-minute suite. `verify`
# was taught to survive that: run the frontmatter's level and report the disagreement as drift.
#
# **The template was producing exactly what the rule forbids.** Its QA plan section shipped a
# `- **Level:** <verify | unit | integration | e2e>` line, so every item written from it wrote the
# level twice, and the rule was one edit from being broken in every project at once. Measured on
# the AetherWorks backlog on 2026-09-05: 107 of 119 items carried the line and two had gone
# genuinely inconsistent — one of them item 0093, which is the incident `verify`'s own prose cites.
#
# So the defect had been patched at the READER and never at the WRITER. That is the shape this
# file guards against returning: `verify`'s tolerance stays (items written before the fix still
# carry the line, and it must keep resolving them), while the template stops creating new ones.
#
# THE ABSENCE ASSERTION IS SCOPED TO A WINDOW, NEVER TO THE FILE. `**Level:**` is ordinary prose
# elsewhere, and a file-wide absence grep would go red on a paragraph that merely discusses the
# rule — the direction that trains people to delete the guard. The window is taken between the
# document's own headings, and the scoping is itself proved falsifiable below: a fixture with the
# phrase present OUTSIDE the window must NOT be reported.
#
# PHRASES ARE SHORT ENOUGH TO SIT ON ONE SOURCE LINE. `grep` is line-based, so an asserted phrase
# straddling a line break cannot be matched at all, and rewrapping a guarded paragraph is
# therefore a breaking change here (`CLAUDE.md`).
#
# Usage:  tests/qa-level-once.test.sh
#         SHOW_MATCHED=1 tests/qa-level-once.test.sh   # print the window each case matched in
#
# Requires: sh, awk. No runner — this project has none.

set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
ITEM="$ROOT/skills/queue/templates/item.md"
QUEUE="$ROOT/skills/queue/SKILL.md"
VERIFY="$ROOT/skills/verify/SKILL.md"
for f in "$ITEM" "$QUEUE" "$VERIFY"; do
  [ -f "$f" ] || { echo "no file at $f" >&2; exit 2; }
done

SAW_LINES=10

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
    bad "$1 — expected in the section: $3"; saw "$2"
  fi
}

not_in_window() {
  if [ -z "$2" ]; then
    bad "$1 — the window is EMPTY; its opening phrase is gone, so nothing was searched"
    return 0
  fi
  if window_has "$2" "$3"; then
    bad "$1 — the section restates the level: $3"; saw "$2"
  else
    ok "$1"; saw_on_pass "$2"
  fi
}

# ---------------------------------------------------------------------------
# The shipped tree
# ---------------------------------------------------------------------------

# The section's own heading matches `^## `, and `window` exits on the first line matching its end
# regex — so bounding on the generic heading pattern would close the window on the line it opened.
# The next heading is named instead.
IW="$(window "$ITEM" '## QA plan' '^## Out of scope')"

echo "AC1 — the template's QA plan does not restate the level"
not_in_window "AC1 — no second Level: line to fill in" "$IW" '**Level:**'

echo "AC2 — and says where the level does live, so AC1 is not satisfied by deleting the section"
in_window "AC2 — the section names the frontmatter field" "$IW" '`qa_level:` in the frontmatter'
in_window "AC2 — and says it is not restated"             "$IW" 'is not restated here'

echo "AC3 — the section still asks for the reasoning and the checks, which are its job"
in_window "AC3 — why that level"   "$IW" '**Why that level:**'
in_window "AC3 — specific checks"  "$IW" '**Specific checks:**'

echo "AC4 — queue still carries the rule the template now obeys"
QW="$(window "$QUEUE" 'Set `qa_level` now, at queue time' '^\*\*Write `qa_manual:`')"
in_window "AC4 — written exactly once, in the frontmatter" "$QW" 'exactly once, in the frontmatter'

echo "AC5 — verify still resolves an item that already carries both"
# The pipe is escaped: `^| Level` is an alternation matching every line, which would close the
# window immediately and report every case below it as an empty-window failure.
VW="$(window "$VERIFY" 'The frontmatter field is the authority when an item disagrees with itself' '^\\| Level')"
in_window "AC5 — the frontmatter wins"        "$VW" 'frontmatter field is the authority'
in_window "AC5 — and the drift is reported"   "$VW" 'report the disagreement as drift'

# ---------------------------------------------------------------------------
# The falsifiability probes. The fixtures drive the same matcher as the cases
# above, so a scoping bug reds here rather than passing silently up there.
# ---------------------------------------------------------------------------

FIX="$(mktemp -d)"

echo "FR — a Level: line INSIDE the QA plan is caught"
cat > "$FIX/inside.md" <<'FIXTURE'
## QA plan

- **Level:** e2e
- **Specific checks:** the suite

## Out of scope
FIXTURE
W="$(window "$FIX/inside.md" '## QA plan' '^## Out of scope')"
if window_has "$W" '**Level:**'; then
  ok "the matcher sees a restated level in the section it guards"
else
  bad "FR — a Level: line inside the QA plan was NOT seen; AC1 cannot fail and proves nothing"
  saw "$W"
fi

echo "FR — a Level: line OUTSIDE the QA plan is not the template's business"
cat > "$FIX/outside.md" <<'FIXTURE'
## Acceptance criteria

- [ ] AC1 — the report prints a **Level:** row for each ticket.

## QA plan

- **Specific checks:** the suite

## Out of scope
FIXTURE
W="$(window "$FIX/outside.md" '## QA plan' '^## Out of scope')"
if window_has "$W" '**Level:**'; then
  bad "FR — the window leaked past its own heading; AC1 would red on unrelated prose"
  saw "$W"
else
  ok "the guard is scoped to the section, not to the file"
fi

echo "FR — a deleted heading is an empty window, reported rather than silently green"
cat > "$FIX/gone.md" <<'FIXTURE'
## Out of scope

The QA plan heading was deleted wholesale.
FIXTURE
W="$(window "$FIX/gone.md" '## QA plan' '^## Out of scope')"
if [ -n "$W" ]; then
  bad "FR — the window found text after its heading was deleted: $W"
elif window_has "$W" 'anything at all'; then
  bad "FR — an empty window matched; every case above it would prove nothing"
else
  ok "an empty window is a named failure, never a vacuous pass"
fi

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" = 0 ]
