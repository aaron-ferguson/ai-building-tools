#!/bin/sh
#
# Guard: a change that touches every file has a stated shape — the exclusive claim (0067).
#
# WHY THIS EXISTS:
#
# Renaming the container ticket type effort -> project (`267d13f`, 2026-08-23) touched 30 files:
# QUEUE.md, RANKING.md, SCHEDULED.md, the item template, two skills, three test suites and 20 item
# files, 9 of which belonged to tickets already closed. Every concurrency mechanism this repo has —
# `expects:`, `touches:`, the lock, the claim token — is PER-ROW, and that change had no row. So it
# was invisible to all of them, and it reddened 0005's held guard mid-pass: the rename rewrote a
# file 0005 had committed in `touches:`, against a contract 0005 never agreed to.
#
# The danger is not that the mechanisms are missing. It is that they READ AS COMPLETE, so the next
# cross-cutting change gets started by a session that checked `expects:` against `touches:`, found
# nothing, and concluded it was safe.
#
# THE ASSERTIONS ARE SCOPED TO THE RULE'S SECTION, NEVER TO THE FILE. `touches:`, `one commit` and
# `held` are ordinary words throughout CONCURRENCY.md, and a file-wide grep would stay green on a
# rule deleted from the section that has to carry it — `testing-conventions.md`, *anchor an
# assertion to the claim, not to the document that contains it*. The scoping is itself proved
# falsifiable below: a fixture carrying every phrase OUTSIDE the section must fail, not pass.
#
# PHRASES ARE SHORT ENOUGH TO SIT ON ONE SOURCE LINE. `grep` is line-based, so an asserted phrase
# straddling a line break cannot be matched at all, and rewrapping a guarded paragraph is therefore
# a breaking change here (`CLAUDE.md`).
#
# Usage:  tests/cross-cutting-change.test.sh
#         SHOW_MATCHED=1 tests/cross-cutting-change.test.sh   # print the section each case matched
#
# Requires: sh, awk. No runner — this project has none.

set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
CONC="$ROOT/references/CONCURRENCY.md"
INC="$ROOT/references/CONCURRENCY-INCIDENTS.md"
[ -f "$CONC" ] || { echo "no file at $CONC" >&2; exit 2; }
[ -f "$INC" ]  || { echo "no file at $INC" >&2; exit 2; }

# The heading text each window is found by. Keyed on WORDS, not on position: a section's place in
# the file moves whenever another rule is inserted, and keying on order would red these cases on an
# edit that did not touch the rule.
RULE='exclusive claim'
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
  [ "$n" -gt "$SAW_LINES" ] && printf '         | ... (%s lines in the section)\n' "$n"
  return 0
}
saw_on_pass() { [ -n "${SHOW_MATCHED:-}" ] && saw "$1"; return 0; }

# window <file> <level> <heading-substring> — from the heading at that level holding the text to
# the line before the next heading at the SAME level. Empty when the heading is gone, which every
# case reports rather than passing over.
window() {
  awk -v want="$3" -v lvl="$2" '
    BEGIN { pat = "^" lvl " " }
    !inw && $0 ~ pat && index($0, want) { inw = 1; print; next }
    inw && $0 ~ pat { exit }
    inw { print }
  ' "$1"
}

window_has() {
  [ -n "$1" ] || return 1
  case "$1" in *"$2"*) return 0 ;; *) return 1 ;; esac
}

in_window() {
  if [ -z "$2" ]; then
    bad "$1 — the section is EMPTY; its heading is gone, so nothing was searched"
    return 0
  fi
  if window_has "$2" "$3"; then
    ok "$1"; saw_on_pass "$2"
  else
    bad "$1 — expected in the section: $3"; saw "$2"
  fi
}

WR="$(window "$CONC" '##' "$RULE")"

echo "AC1 — the section says a whole-tree change is not expressible in the per-row mechanisms"
in_window "AC1 — the scope is named as inexpressible"      "$WR" 'not expressible in'
in_window "AC1 — and it names expects, touches and the lock" "$WR" 'the per-row lock'

echo "AC2 — a session meeting the change mid-flight claims nothing and holds its verdict"
in_window "AC2 — it claims nothing while the claim stands" "$WR" 'claims nothing while an exclusive claim stands'
in_window "AC2 — an unexplained red is not evidence about its own ticket" "$WR" 'not evidence about its own ticket'

echo "AC3 — closed tickets are not rewritten, and the substitution is recorded once with a date"
in_window "AC3 — closed tickets' files stand as written" "$WR" 'does not rewrite closed tickets'
in_window "AC3 — the substitution is recorded once, dated" "$WR" 'recorded once, dated'

echo "AC4 — all three preconditions of the exclusive claim are present"
in_window "AC4 — nothing else is held when it is claimed" "$WR" 'nothing else is held'
in_window "AC4 — the change lands in one commit"          "$WR" 'one commit'
in_window "AC4 — green before and after, never between"   "$WR" 'green before it and green after it'

echo "AC8 — the incident is recorded under the rule's name with its verified figures"
WI="$(window "$INC" '###' "$RULE")"
in_window "AC8 — an entry names the rule in its heading" "$WI" 'exclusive claim'
in_window "AC8 — it carries the rename's date"           "$WI" '2026-08-23'
in_window "AC8 — and the file count it touched"          "$WI" '30 files'
in_window "AC8 — and how many item files were closed"    "$WI" '9'

# ---------------------------------------------------------------------------
# The falsifiability probes. These drive the same matcher as the cases above, so a scoping bug reds
# here rather than passing silently up there. A guard only ever seen passing is indistinguishable
# from one wired to nothing.
# ---------------------------------------------------------------------------

FIX="$(mktemp -d)"

# A deletion probe is only evidence if the phrase was THERE to delete. `grep -v` over a file that
# never carried it returns the file unchanged, the section then lacks the phrase, and the case
# reports a clean pass — so the probe would pass identically before and after the rule was written,
# which is the guard-that-cannot-fail shape `testing-conventions.md` names. Asserting presence
# first is what makes the absence afterwards mean something.
probe_delete() {
  # $1 label, $2 the phrase to delete, $3 a phrase that must SURVIVE it
  if ! window_has "$WR" "$2"; then
    bad "AC9 — the real CONCURRENCY.md never carried '$2', so deleting it proves nothing"
    return 0
  fi
  grep -v "$2" "$CONC" > "$FIX/deleted.md"
  WD="$(window "$FIX/deleted.md" '##' "$RULE")"
  if window_has "$WD" "$2"; then
    bad "AC9 — '$2' was deleted and the matcher still saw it; its case proves nothing"
    saw "$WD"
  elif ! window_has "$WD" "$3"; then
    bad "AC9 — deleting '$2' also removed '$3'; one guard is covering two claims"
  else
    ok "$1"
  fi
}

echo "AC9 — each clause reds on its own deletion, independently of the others"
probe_delete "AC9 — the inexpressibility clause reds alone"   'not expressible in'                        'one commit'
probe_delete "AC9 — the claims-nothing clause reds alone"     'claims nothing while an exclusive claim stands' 'one commit'
probe_delete "AC9 — the unexplained-red clause reds alone"    'not evidence about its own ticket'         'one commit'
probe_delete "AC9 — the closed-tickets clause reds alone"     'does not rewrite closed tickets'           'one commit'
probe_delete "AC9 — the dated-substitution clause reds alone" 'recorded once, dated'                      'one commit'
probe_delete "AC9 — the green-before-and-after clause reds alone" 'green before it and green after it'    'one commit'

echo "AC9 — phrases outside the rule's own section do not satisfy the guard"
cat > "$FIX/outside.md" <<'FIXTURE'
## The working tree is shared too

A change touching every file is not expressible in `expects:`, `touches:` or the per-row lock.
It claims nothing while an exclusive claim stands, and a red is not evidence about its own ticket.
It does not rewrite closed tickets, the substitution is recorded once, dated, nothing else is held,
it lands in one commit, and the suite is green before it and green after it.

## A change that touches every file takes an exclusive claim

Something else entirely.

## The next rule
FIXTURE
WO="$(window "$FIX/outside.md" '##' "$RULE")"
if window_has "$WO" 'not expressible in'; then
  bad "AC9 — the section leaked past its own heading; the rule could sit anywhere and pass"
  saw "$WO"
else
  ok "AC9 — the guard is scoped to the rule's section, not to the file"
fi

echo "AC9 — a deleted heading is an empty section, reported rather than silently green"
printf '## Some other rule\n\nNothing here.\n' > "$FIX/gone.md"
WG="$(window "$FIX/gone.md" '##' "$RULE")"
if [ -n "$WG" ]; then
  bad "AC9 — a file with no such heading returned a non-empty section"
else
  ok "AC9 — a missing heading yields an empty section, which every case reports as a failure"
fi

printf '\n  %s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
