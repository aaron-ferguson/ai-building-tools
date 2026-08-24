#!/bin/sh
#
# Size guard for skills/*/SKILL.md (0021).
#
# Every skill file loads whole into any session that invokes it, and re-loads on re-invocation,
# so length is rent paid repeatedly. CONVENTIONS_CORE.md sets the rule; this file makes it a gate.
#
# The goal is SOFT, and deliberately so. A hard cap is paid by deleting whatever fits least well,
# which on a file of rules means deleting a rule — backwards, because "no rule is dropped" outranks
# any byte count. What the goal exists to stop is a generic tool accreting anecdotes, worked
# examples and niche cases. So: over the goal is allowed, and must be RECORDED with a reason. The
# reason is what a reviewer argues with; the number only decides when that argument has to happen.
#
# The first move for a file over the goal is a POINTER, not a cut: detail that only some runs need
# belongs in a conditionally-read file (references/), so it costs nothing on the runs that don't.
#
# It is measured in bytes, absolutely — never a percentage of a baseline. 0021's first pass could
# not close because its target was 25% off a baseline eight sibling tickets moved 18% while it
# waited. Bytes rather than characters: these files are full of multi-byte em-dashes and a decoded
# len() undercounted one of them by ~46.
#
# Usage:  tests/skill-size.test.sh
#
# Requires: sh, wc, awk. No runner — this project has none.

set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

GOAL=20190             # ~5,000 tokens at the 4.038 bytes/token ratio this repo measured

# justification <relative-path> — echoes why this file is over the goal, or nothing if it is not
# recorded as over it. One line per file, naming the ticket that accepted the cost. A file over the
# goal with no entry here fails; an entry on a file back under the goal fails so it gets removed.
justification() {
  case "$1" in
    skills/prototype/SKILL.md) echo "0021 — three build procedures, one used per run; relocating each to a conditional reference is an open design question" ;;
    skills/queue/SKILL.md)     echo "0021 — specification rules read by every other stage" ;;
    skills/develop/SKILL.md)   echo "0027 — carries the re-entry and staleness rules; its anecdotes are the relocation candidates" ;;
    *) return 0 ;;
  esac
}

PASS=0
FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }

FIX=""
cleanup() { [ -n "$FIX" ] && rm -rf "$FIX"; return 0; }
trap cleanup EXIT INT TERM

# offenders <root> <justification-lookup-fn> — prints one line per file that is over the goal with
# no recorded reason, or recorded while under it; nothing when every file is accounted for. The
# lookup is a parameter so the fixture cases can drive both paths whatever the real tree holds.
offenders() {
  root="$1"
  lookup="${2:?offenders needs a justification-lookup function}"
  for f in "$root"/skills/*/SKILL.md; do
    [ -f "$f" ] || continue
    rel="skills/$(basename "$(dirname "$f")")/SKILL.md"
    bytes="$(wc -c < "$f" | tr -d ' ')"
    if [ -n "$("$lookup" "$rel")" ]; then
      # Recorded. No upper bound — the reason is the control, not a second number. Written as a
      # full `if` rather than `[ ... ] &&`: a short-circuit as the last command in this loop makes
      # the function exit non-zero on a legitimately-fine file, which `set -e` turns into a
      # silent, empty result for every caller.
      if [ "$bytes" -le "$GOAL" ]; then
        echo "$rel is $bytes bytes, under the $GOAL goal — remove its stale justification"
      fi
    elif [ "$bytes" -gt "$GOAL" ]; then
      echo "$rel is $bytes bytes, over the $GOAL goal by $((bytes - GOAL)) — relocate detail to a pointer file, or record a justification"
    fi
  done
}

echo "AC1 — every skill file is within the goal, or over it with a recorded reason"
found="$(offenders "$ROOT" justification)"
if [ -z "$found" ]; then
  # Name the recorded files with their sizes rather than reporting a clean sweep: an accepted cost
  # is still a cost, and a pass line hiding it reads as "everything is within the goal".
  over=""
  for f in "$ROOT"/skills/*/SKILL.md; do
    rel="skills/$(basename "$(dirname "$f")")/SKILL.md"
    if [ -n "$(justification "$rel")" ]; then
      over="$over
         $rel ($(wc -c < "$f" | tr -d ' ') bytes) — $(justification "$rel")"
    fi
  done
  if [ -n "$over" ]; then
    ok "within the goal, except where recorded:$over"
  else
    ok "every skill file within the goal, none recorded over it"
  fi
else
  OLDIFS="$IFS"; IFS='
'
  for line in $found; do bad "$line"; done   # in this shell, so each breach counts
  IFS="$OLDIFS"
fi

# The cases below prove the guard can fail. A guard only ever seen passing is indistinguishable
# from one wired to nothing, so each feeds it the exact breach it exists to catch.
#
# Every fixture is built from a base file this script GENERATES at a fixed size, never from a file
# under test. Copying the smallest real skill coupled the fixtures to the tree beside them: the
# padding was sized against the real file, so unrelated growth elsewhere could red a case that has
# nothing to do with it, and a guard whose reds can be artefacts trains sessions to discount them.
FIX="$(mktemp -d)"
BASE="$FIX/base.md"
awk 'BEGIN { while (i++ < 1000) printf "b" }' > "$BASE"
BASE_BYTES="$(wc -c < "$BASE" | tr -d ' ')"

echo "FR6 — the fixture base is independent of the tree under test"
if [ "$BASE_BYTES" = 1000 ]; then
  ok "fixture base is a generated 1000 bytes, not a copy of any skill"
else
  bad "FR6 — fixture base is $BASE_BYTES bytes, expected 1000"
fi

pad() {   # pad <path> <target-bytes> — base plus filler to an exact size
  cp "$BASE" "$1"
  awk -v n="$(($2 - BASE_BYTES))" 'BEGIN { while (i++ < n) printf "x" }' >> "$1"
}

echo "AC4 — an unrecorded file over the goal fails, named, with its overage"
rm -rf "$FIX/skills"; mkdir -p "$FIX/skills/padded"
pad "$FIX/skills/padded/SKILL.md" $((GOAL + 500))
out="$(offenders "$FIX" justification)"
case "$out" in
  *"skills/padded/SKILL.md is $((GOAL + 500)) bytes, over the $GOAL goal by 500"*)
    ok "unrecorded file over the goal reported with its overage" ;;
  "") bad "AC4 — file over the goal was NOT reported; the guard is wired to nothing" ;;
  *)  bad "AC4 — reported something else: $out" ;;
esac

echo "AC4 — a file within the goal passes"
rm -rf "$FIX/skills"; mkdir -p "$FIX/skills/plain"
pad "$FIX/skills/plain/SKILL.md" $((GOAL - 1))
out="$(offenders "$FIX" justification)"
if [ -z "$out" ]; then
  ok "file one byte under the goal reported nothing"
else
  bad "AC4 — compliant file was reported: $out"
fi

echo "FR7 — a recorded reason carries no upper bound, and goes stale under the goal"
justification_fixture() {
  case "$1" in skills/recorded/SKILL.md) echo "0099 — fixture reason" ;; *) return 0 ;; esac
}
rm -rf "$FIX/skills"; mkdir -p "$FIX/skills/recorded"

pad "$FIX/skills/recorded/SKILL.md" $((GOAL + 1))
out="$(offenders "$FIX" justification_fixture)"
if [ -z "$out" ]; then
  ok "a recorded file just over the goal passes"
else
  bad "FR7 — recorded file was reported: $out"
fi

pad "$FIX/skills/recorded/SKILL.md" $((GOAL + 30000))
out="$(offenders "$FIX" justification_fixture)"
if [ -z "$out" ]; then
  ok "a recorded file far over the goal passes — the reason is the control, not a second number"
else
  bad "FR7 — recorded file far over the goal was reported: $out"
fi

pad "$FIX/skills/recorded/SKILL.md" $((GOAL - 1))
out="$(offenders "$FIX" justification_fixture)"
case "$out" in
  *"remove its stale justification"*) ok "a justification on a file back under the goal fails" ;;
  *) bad "FR7 — stale justification was not reported: ${out:-<nothing>}" ;;
esac

echo "FR7 — an unrecorded file is judged by the goal, not by a neighbour's reason"
rm -rf "$FIX/skills"; mkdir -p "$FIX/skills/recorded" "$FIX/skills/other"
pad "$FIX/skills/recorded/SKILL.md" $((GOAL + 5000))
pad "$FIX/skills/other/SKILL.md" $((GOAL + 5000))
out="$(offenders "$FIX" justification_fixture)"
case "$out" in
  *"skills/other/SKILL.md"*)
    case "$out" in
      *"skills/recorded/SKILL.md"*) bad "FR7 — the recorded file was reported too: $out" ;;
      *) ok "the unrecorded file of the pair is the only one reported" ;;
    esac ;;
  *) bad "FR7 — the unrecorded file was not reported: ${out:-<nothing>}" ;;
esac

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" = 0 ]
