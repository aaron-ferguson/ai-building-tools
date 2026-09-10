#!/bin/sh
#
# The findings buffer's mechanics: what the gate counts, how an entry is marked on its way out, and
# what each sweeper does with a buffer holding more than one pass can finish (0060).
#
# WHY THESE ARE PROSE GUARDS. The buffer is emptied by two skills and counted by one script, and
# only the script can be tested by running it — `tests/next.test.sh` does that. Everything else here
# is an instruction a session follows, so the artifact under test IS the prose, and the failure each
# case prevents is a rule silently going missing in a rewrite (`CLAUDE.md`, *Tests*).
#
# EVERY ASSERTION IS SCOPED TO A WINDOW, never to a whole file. "buffer", "entry", "sweep" and
# "retro" are ordinary words throughout these skills, so a file-level grep would pin vocabulary
# rather than the claim, and deleting the rule would leave the word behind somewhere else
# (`testing-conventions.md`, *Anchor an assertion to the claim, not to the document*).
#
# AND EVERY PHRASE SITS WITHIN ONE LINE AS THE FILE IS WRAPPED. `window_has` matches a substring
# against text that still holds its newlines, so a phrase straddling a wrap matches nothing and
# reads as absent. Rewrapping a guarded paragraph here is a breaking change.
#
# Usage:  tests/findings-buffer.test.sh
# Requires: sh, awk, grep. No runner — this project has none.

set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
QUEUE_SKILL="$ROOT/skills/queue/SKILL.md"
RETRO_SKILL="$ROOT/skills/retro/SKILL.md"
HEADER_T="$ROOT/skills/queue/templates/FINDINGS.md"
HEADER_L="$ROOT/.claude/backlog/FINDINGS.md"
ITEM_T="$ROOT/skills/queue/templates/item.md"
REPORTING="$ROOT/references/REPORTING.md"
NEXT_T="$ROOT/skills/queue/templates/next"

for f in "$QUEUE_SKILL" "$RETRO_SKILL" "$HEADER_T" "$HEADER_L" "$ITEM_T" "$REPORTING" "$NEXT_T"; do
  [ -f "$f" ] || { echo "no file at $f" >&2; exit 2; }
done

SAW_LINES=12
PASS=0
FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }

saw() {
  printf '%s\n' "$1" | sed 's/^/         | /' | head -"$SAW_LINES"
  n="$(printf '%s\n' "$1" | wc -l | tr -d ' ')"
  [ "$n" -gt "$SAW_LINES" ] && printf '         | ... (%s lines in the window)\n' "$n"
  return 0
}
saw_on_pass() { [ -n "${SHOW_MATCHED:-}" ] && saw "$1"; return 0; }

# window <file> <start-fixed-string> <end-regex> — from the line holding the opening phrase to the
# line before the next match of the end pattern. Empty when the opening phrase is gone, which every
# case reports rather than passing over.
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
    bad "$1 — expected in the window: $3"; saw "$2"
  fi
}

not_in_window() {
  if [ -z "$2" ]; then
    bad "$1 — the window is EMPTY; its opening phrase is gone, so nothing was searched"
    return 0
  fi
  if window_has "$2" "$3"; then
    bad "$1 — still present in the window: $3"; saw "$2"
  else
    ok "$1"
  fi
}

# ---------------------------------------------------------------------------------------------
# AC11 — the counter's premise, in both halves.
#
# The count is every entry, and that is only satisfiable because `retro` removes every entry it
# reads. The comment says so where the counting happens; the sentence it depends on lives in
# another file and another repo's reader, so it is guarded here.
#
# THE SECOND ASSERTION DUPLICATES ONE IN tests/retro-tool-edit.test.sh DELIBERATELY. That one
# asserts the sentence as part of Step 4's four dispositions — the claim is "the step names
# terminal outcomes". This one asserts it as `count_findings`'s premise — the claim is "the gate is
# satisfiable by the stage it dispatches". Same words, different claims: deleting either guard
# leaves one of the two claims unheld, which is why this is not a redundant copy to tidy away.
# ---------------------------------------------------------------------------------------------

echo "0060 AC11 — the counter records why counting every entry is safe"
WC="$(window "$NEXT_T" 'THE COUNT IS EVERY ENTRY' '^count_findings\(\)')"
in_window "AC11 — the comment names retro as the terminal sweeper"   "$WC" 'TERMINAL SWEEPER'
in_window "AC11 — and states the consequence the count rests on"     "$WC" 'every entry left'
in_window "AC11 — it cites the sentence rather than restating it"    "$WC" 'no entry survives the pass that read it'
in_window "AC11 — and names the guard that holds that sentence"      "$WC" 'tests/findings-buffer.test.sh'

echo "0060 AC11 — the sentence the count depends on still stands in retro Step 4"
W4="$(window "$RETRO_SKILL" '## Step 4 — Write it, and empty what you processed' '^## Step 5')"
in_window "AC11 — retro removes every entry it read" "$W4" 'no entry survives the pass that read it'

# ---------------------------------------------------------------------------------------------
# AC6 / FR2 — retro's own procedure for a buffer past what one pass can finish.
#
# The rule it replaces told a pass to read fewer entries and finish each, which is unrunnable: the
# cross-entry read is what tells you which entries are one lesson, so there is no cheap basis for
# choosing a slice before it. A pass at 32 entries read all 32 and dispositioned every one, which
# was the opposite of the instruction and the only honest option.
#
# THE ABSENCE ASSERTION IS ANCHORED TO THE OLD RULE'S OWN WORDING, not to vocabulary. "read" and
# "slice" both survive in the replacement and must — a negative assertion on either would red a
# correct rewrite (`testing-conventions.md`, *a negative assertion has to be anchored to a state*).
# ---------------------------------------------------------------------------------------------

echo "0060 AC6 — retro Step 1 slices the writing, never the reading"
W1="$(window "$RETRO_SKILL" '## Step 1 — Read the buffer' '^## Step 2')"
in_window     "AC6 — reading is cheap and only writing is sliced"     "$W1" 'reading is cheap and only writing is sliced'
in_window     "AC6 — the slice is chosen after the cross-entry read"  "$W1" 'after the cross-entry read'
# ANCHORED TO A FRAGMENT THAT SITS WITHIN ONE LINE AS THE FILE IS WRAPPED. Written against the
# rule's full wording — `read fewer entries and finish each` — this assertion passed while the rule
# was still there, because the phrase straddled a wrap and matched nothing: a negative assertion
# that could not fail, green for the one reason that proves nothing.
not_in_window "AC6 — the unrunnable instruction is gone"              "$W1" 'read fewer entries and finish'

# ---------------------------------------------------------------------------------------------
# AC2 / AC5 / AC8 — queue Step 5, the other sweeper.
# ---------------------------------------------------------------------------------------------

W5="$(window "$QUEUE_SKILL" '## Step 5 — Surface work that was parked somewhere else' '^## Step 6')"

echo "0060 AC2 — queue Step 5 says what a sweep does when it cannot finish the buffer"
in_window "AC2 — the entries are clustered after they are read"   "$W5" 'cluster them after reading'
in_window "AC2 — an entry and a ticket are not one-to-one"        "$W5" 'not one-to-one'
in_window "AC2 — and what was left behind is named in the report" "$W5" 'name what you left behind'

echo "0060 AC5 — a bundled ticket's removal list comes from its FRs"
in_window "AC5 — the removal list is derived from the ticket's FRs" "$W5" 'removal list comes from the ticket'
in_window "AC5 — and not from the cluster that produced it"         "$W5" 'never the cluster'

echo "0060 AC8 — queue Step 5 carries the absorbed disposition"
in_window "AC8 — the disposition is named"                        "$W5" 'Absorbed'
in_window "AC8 — it is neither a new row nor a next: queue stub"  "$W5" 'not a new row'
in_window "AC8 — the row that already carries the work is named"  "$W5" 'name the row'
in_window "AC8 — one dated line goes into that row's notes"       "$W5" 'one dated line to its *Notes & decisions*'
in_window "AC8 — and the entry is marked with the head token"     "$W5" '[->NNNN]'

# ---------------------------------------------------------------------------------------------
# AC3 / AC4 / FR7 — the buffer header, in BOTH copies.
#
# The header is the specification its writers actually read, and the local buffer's copy is the one
# this repo's own sessions follow. A rule landing in the template alone is a rule this project does
# not have, which is the drift `tests/backlog-scripts-installed.test.sh` exists to catch for the
# scripts and nothing caught for this file.
# ---------------------------------------------------------------------------------------------

for h in "$HEADER_T" "$HEADER_L"; do
  label="$(basename "$(dirname "$h")")/$(basename "$h")"
  WH="$(window "$h" '# Findings' '^---$')"

  echo "0060 AC3 — $label: a cross-reference names an id or a path"
  in_window "AC3 — a sibling is referred to by id or path"     "$WH" 'by item id or file path'
  in_window "AC3 — and never by quoting it"                    "$WH" 'never by quoting it'
  in_window "AC3 — because the quoted entry is removed"        "$WH" 'resolves to nothing'

  echo "0060 AC4 — $label: the date is UTC"
  in_window "AC4 — the date's timezone is stated"              "$WH" 'The date is UTC'
  in_window "AC4 — and matched to the field that already says so" "$WH" 'claimed_at'

  echo "0060 FR7 — $label: the hand-over marker is a head token"
  in_window "FR7 — the token's shape is specified"             "$WH" '[->NNNN]'
  in_window "FR7 — a read with no destination is distinguishable" "$WH" '[->none]'
  in_window "FR7 — it is written on the way out by a sweeper"  "$WH" 'on the way out'
  in_window "FR7 — never by the noticer"                       "$WH" 'never writes the token'
  in_window "FR7 — and it does not change what the gate counts" "$WH" 'counts every entry, marked or not'
  in_window "FR7 — the old form stays readable"                "$WH" 'stays readable'
done

# Opened on the field ABOVE `created:`, because the note sits with the comments that introduce the
# field rather than on the value line — a trailing comment on a frontmatter value is read by every
# script that parses this file, and this rule is not worth that risk. Both halves are asserted so
# the case cannot pass on a window that no longer holds the field at all.
echo "0060 AC4 — the item template states that a written date is UTC"
WI="$(window "$ITEM_T" 'size: s | m | l' '^source:')"
in_window "AC4 — the window still holds the created: field" "$WI" 'created:'
in_window "AC4 — and its date is stated as UTC"             "$WI" 'The date is UTC'

# ---------------------------------------------------------------------------------------------
# AC9 / FR9 — the gate reaches a hand-driven run.
#
# `./next --drive` is the only thing that gated on the count, so a run a person drives filled the
# buffer indefinitely with nothing to say so: a retro found 32 entries against a threshold of 8,
# none of them stale. The rule goes in the file every stage's report step already cites, rather
# than as a paragraph in each of six skills.
# ---------------------------------------------------------------------------------------------

echo "0060 AC9 — a stage report carries the buffer count against the threshold"
# The end pattern must not match the window's OWN heading, or the window closes on the line it
# opened on and every case inside it reports empty.
WR="$(window "$REPORTING" '## The findings buffer' '^## The hand-off line')"
in_window "AC9 — the report carries the count"           "$WR" 'carries the buffer'
in_window "AC9 — the line it comes from is named"        "$WR" './next --findings'
in_window "AC9 — the threshold is what it is read against" "$WR" 'threshold'
in_window "AC9 — and a retro is due at or over it"       "$WR" 'a retro is due'

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
