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
# examples and niche cases. So: over the goal is allowed, and must be RECORDED with a reason that
# says what was considered relocating and why it was rejected — not merely why the file is long.
# The reason is what a reviewer argues with; the number only decides when that argument has to
# happen, and a reason that names no rejected alternative is one nobody can argue with.
#
# WHEN RELOCATION IS THE ANSWER — the payback test (0035). The first move for a file over the goal
# is usually a POINTER rather than a cut: detail that only some runs need belongs in a
# conditionally-read file (references/), so it costs nothing on the runs that don't. "Usually" is
# doing work there. Relocation has a price, and three separate things decide whether it is worth
# paying. This is the test; apply it before moving anything, and record the answer either way.
#
#   THE ARITHMETIC. A block of B bytes carried inside a skill file is paid for once as a cache
#   WRITE and then re-read on every later turn of the session. Following a pointer instead is paid
#   for once, as one extra turn. So for an N-turn session:
#
#       carry = (B / 4.038) x ($6.25 + (N-1) x $0.50) / 1e6      fetch = $0.1028
#
#   Setting them equal gives B0, the block size at which one skipped fetch exactly pays for one
#   carried block:
#
#       N = 37 turns per session  ->  $6.25 + 36 x $0.50  = $24.25 per MTok carried
#                                 ->  $0.1028 / $24.25 x 1e6 = 4,239 tokens
#                                 ->  x 4.038 bytes/token     = ~17,000 bytes = B0
#
#   Every figure is measured and lives in MEASUREMENT.md: 4.038 bytes/token, $6.25/MTok cache write
#   at the 5-minute TTL, $0.50/MTok cache read, $0.1028 per turn, and 1,112 turns across 30 sessions
#   = ~37 turns per session. RECOMPUTE B0 rather than trusting it whenever the rates or the
#   turns-per-session figure move — the derivation is the durable part and the constant is an
#   output. It is not a sensitive number: a develop session averages 39 turns, which gives ~16,400,
#   and no answer below changes. 0035's design pass read "30 sessions" as 30 turns and published
#   20,000; the correction moved the constant and left every conclusion standing.
#
#   WHAT B0 MEANS. It is most of the whole goal, so relocation NEVER pays on size alone — a block
#   big enough to matter is a block nearly as big as the file. What it pays on is the share of runs
#   that never follow the pointer, and the break-even share is
#
#       p = 1 / (1 + B/17,000)
#
#   Relocate only if the estimated share of runs that skip the branch clears p.
#
#   TWO CONDITIONS THAT ARE NOT ABOUT COST, and the second outranks the arithmetic:
#     (a) the share of runs skipping the branch clears p, above; and
#     (b) the content is not MANDATORY once its branch is taken. A mandatory step behind a pointer
#         is a step that gets skipped, and no byte count buys that. Where (b) fails, (a) is moot.
#
#   THE WORKED INSTANCE that passes both. references/CONCURRENCY.md -> CONCURRENCY-INCIDENTS.md:
#   the rules and the failure each prevents stayed, the narrative, the reasoning and the live
#   procedure moved, and the moved half is read only when a rule is argued with or a conflict is
#   live — well under p. The compression rule it yields, stated for reuse: KEEP RULE + FAILURE IN
#   ONE CLAUSE, MOVE THE STORY. A rule whose failure has been relocated is a rule the next session
#   argues with, which is why the test can reject a cut as well as a move.
#
# A RECORDED REASON HAS A BOUND — the argued-at size, and MARGIN (0190). A reason is true of the
# file it was argued against and of nothing larger: 0040 argued the sprint skill a tenth over the
# goal, and the file tripled under that reason with this guard green. So every recorded file also
# carries the byte size it was argued at, as a separate field the guard reads — argued_at() below,
# never written into a reason, because a number in prose goes stale silently (0035 FR6) while a
# number the guard reads reds. A recorded file more than MARGIN bytes past its argued-at size fails
# until its reason is re-argued at the new size, both fields updated together, or relocation brings
# the file back inside the margin. Moving the number without re-arguing the reason is the silent
# drift this bound exists to stop.
#
#   MARGIN = 5,000 bytes, absolute. Derivation: a quarter of the goal, ~1,240 tokens. Growth smaller
#   than that is a block whose relocation would need p = 1/(1 + 5,000/17,000), ~77% of runs, to skip
#   it, so a re-argument would rarely find anything; at the observed growth (0180 alone added ~2,600)
#   it asks every two or three growing tickets rather than every one. Never a share of the argued-at
#   size: rent is paid per byte, and a proportional margin gives the largest files the most slack.
#   Rejected: B0 as the margin (nearly the whole goal, so a file could grow most of the way to the
#   sprint skill's size unexamined), and no margin (every growing ticket re-argues, which trains
#   sessions to rubber-stamp).
#
#   GRANDFATHERED by 0190, 2026-10-25: the argued-at sizes of every recorded file except the sprint
#   skill are their sizes on 0190's build commit, not the sizes their reasons were argued at, which
#   nobody recorded. That is a re-blessing, not a re-argument — those reasons stand unexamined until
#   each is next re-argued, and the first ticket to grow one past its margin is the one that does it.
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

GOAL=20190             # ~5,000 tokens at the 4.038 bytes/token ratio this repo measured
MARGIN=5000            # bytes a recorded file may grow past its argued-at size — derived in the header

# Asked for in the same words as tests/reference-size.test.sh, deliberately: a guard that asks only
# for "a reason" gets a reason, and a reason that does not say what was considered is one nobody can
# argue with. The two guards state one demand; the arithmetic behind it lives only in this file.
RELOCATE='relocate detail only some runs need to a pointer file, or record a justification naming what you considered relocating'

# justification <relative-path> — echoes why this file is over the goal, or nothing if it is not
# recorded as over it. One line per file, naming the ticket that accepted the cost — or, where the
# work had no ticket, the commit that landed it. A file over the goal with no entry here fails; an
# entry on a file back under the goal fails so it gets removed.
#
# NAME SOMETHING THAT RESOLVES. The retro entry below named an id no ticket held, later issued to
# unrelated work and withdrawn. tests/citations.test.sh now reds on an item id that resolves to
# nothing, which is why a commit is the right citation for work that had no ticket.
justification() {
  case "$1" in
    skills/prototype/SKILL.md) echo "0035 — considered relocating Step 5's level-2, level-3 and field-reference branches, over half the file; rejected on both conditions: the level split is unmeasured so nothing shows it clears p, and every byte is mandatory once its level is picked" ;;
    skills/queue/SKILL.md)     echo "0035 — considered relocating the specification rules; rejected on (a), because every other stage reads them and p is zero — there is no branch here that any run skips" ;;
    skills/develop/SKILL.md)   echo "0035 — considered relocating its worked anecdotes; rejected on both: they are already the one-clause statement of the failure each rule prevents, so moving them leaves a rule with no failure named, and they are read on every run" ;;
    skills/retro/SKILL.md)     echo "b9a5ee0 — considered relocating Step 4's four dispositions and Step 1's two modes; rejected on both: a run reaches them before it can triage a single entry, so p is zero, and each is mandatory the moment the buffer is non-empty" ;;
    skills/sprint/SKILL.md)    echo "0190 — considered relocating Step 7's lock and cap-kill recovery and the design-beside rule, the only two branches a run can skip; rejected on both conditions: Step 7 is mandatory the moment a lock is met, and behind a pointer it is skipped exactly then, so a driver steals a working stage's lock; the design-beside rule is taken on most runs now design runs a sprint ahead, and it is what stops the supervisor overriding the step-over that --drive decides, so design cites files a running develop is editing; every other section is on every run's main path, so p is zero" ;;
    skills/verify/SKILL.md)    echo "0052 — considered relocating Step 3's mutation guidance to a pointer file; rejected on (b), because it is mandatory the moment an AC rests on an automated check, and a mandatory step behind a pointer is a step that gets skipped" ;;
    *) return 0 ;;
  esac
}

# argued_at <relative-path> — echoes the byte size the file's justification was argued at, or nothing.
# A field of its own, never part of the reason (header, 0190). Re-argue the reason and update this
# together; moving this number alone is the drift the bound exists to catch.
argued_at() {
  case "$1" in
    skills/prototype/SKILL.md) echo 25361 ;;   # grandfathered by 0190
    skills/queue/SKILL.md)     echo 48538 ;;   # grandfathered by 0190
    skills/develop/SKILL.md)   echo 50862 ;;   # grandfathered by 0190
    skills/retro/SKILL.md)     echo 30034 ;;   # grandfathered by 0190
    skills/sprint/SKILL.md)    echo 60813 ;;   # argued by 0190
    skills/verify/SKILL.md)    echo 45522 ;;   # grandfathered by 0190
    *) return 0 ;;
  esac
}

PASS=0
FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }

FIX=""
cleanup() { [ -n "$FIX" ] && rm -rf "$FIX"; return 0; }
trap 'announce_abort cleanup' EXIT
trap cleanup INT TERM

# offenders <root> <justification-lookup-fn> <argued-at-lookup-fn> — prints one line per file that
# is over the goal with no recorded reason, recorded while under it, recorded with no argued-at size,
# or grown more than MARGIN past that size; nothing when every file is accounted for. The lookups are
# parameters so the fixture cases can drive every path whatever the real tree holds.
offenders() {
  root="$1"
  lookup="${2:?offenders needs a justification-lookup function}"
  sizes="${3:?offenders needs an argued-at-lookup function}"
  for f in "$root"/skills/*/SKILL.md; do
    [ -f "$f" ] || continue
    rel="skills/$(basename "$(dirname "$f")")/SKILL.md"
    bytes="$(wc -c < "$f" | tr -d ' ')"
    if [ -n "$("$lookup" "$rel")" ]; then
      # Recorded. Bounded by its argued-at size plus MARGIN (0190). Written as a full `if` rather
      # than `[ ... ] &&`: a short-circuit as the last command in this loop makes the function exit
      # non-zero on a legitimately-fine file, which `set -e` turns into a silent, empty result for
      # every caller.
      argued="$("$sizes" "$rel")"
      if [ "$bytes" -le "$GOAL" ]; then
        echo "$rel is $bytes bytes, under the $GOAL goal — remove its stale justification"
      elif [ -z "$argued" ]; then
        echo "$rel is recorded over the goal but is missing its argued-at size — add it to argued_at() at the size its reason was argued at"
      elif [ "$bytes" -gt $((argued + MARGIN)) ]; then
        echo "$rel is $bytes bytes, $((bytes - argued)) past the $argued bytes its reason was argued at, over the $MARGIN margin — re-argue its reason or relocate"
      fi
    elif [ "$bytes" -gt "$GOAL" ]; then
      echo "$rel is $bytes bytes, over the $GOAL goal by $((bytes - GOAL)) — $RELOCATE"
    fi
  done
}

echo "AC1 — every skill file is within the goal, or over it with a recorded reason"
found="$(offenders "$ROOT" justification argued_at)"
if [ -z "$found" ]; then
  # Name the recorded files with their sizes rather than reporting a clean sweep: an accepted cost
  # is still a cost, and a pass line hiding it reads as "everything is within the goal".
  over=""
  for f in "$ROOT"/skills/*/SKILL.md; do
    rel="skills/$(basename "$(dirname "$f")")/SKILL.md"
    if [ -n "$(justification "$rel")" ]; then
      over="$over
         $rel ($(wc -c < "$f" | tr -d ' ') bytes, argued at $(argued_at "$rel")) — $(justification "$rel")"
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
out="$(offenders "$FIX" justification argued_at)"
case "$out" in
  *"skills/padded/SKILL.md is $((GOAL + 500)) bytes, over the $GOAL goal by 500"*)
    ok "unrecorded file over the goal reported with its overage" ;;
  "") bad "AC4 — file over the goal was NOT reported; the guard is wired to nothing" ;;
  *)  bad "AC4 — reported something else: $out" ;;
esac

# 0035 AC5 — two further claims about that same printed line, asserted separately so a failure says
# which half is missing. A guard that asks only for "a reason" gets a reason, and a reason naming no
# rejected alternative is one nobody can argue with — which is what the soft goal exists to avoid.
case "$out" in
  *"relocate detail only some runs need to a pointer file"*)
    ok "the over-goal message names relocation before it asks for a reason" ;;
  *) bad "0035 AC5/FR4 — the over-goal message does not name relocation first: $out" ;;
esac
case "$out" in
  *"naming what you considered relocating"*)
    ok "the over-goal message asks what was considered relocating" ;;
  *) bad "0035 AC5 — the over-goal message does not ask what was considered relocating: $out" ;;
esac

echo "AC4 — a file within the goal passes"
rm -rf "$FIX/skills"; mkdir -p "$FIX/skills/plain"
pad "$FIX/skills/plain/SKILL.md" $((GOAL - 1))
out="$(offenders "$FIX" justification argued_at)"
if [ -z "$out" ]; then
  ok "file one byte under the goal reported nothing"
else
  bad "AC4 — compliant file was reported: $out"
fi

echo "FR7 — a recorded reason is bounded by its argued-at size, and goes stale under the goal"
justification_fixture() {
  case "$1" in skills/recorded/SKILL.md|skills/unsized/SKILL.md) echo "0099 — fixture reason" ;; *) return 0 ;; esac
}
# The recorded fixture is argued at one byte over the goal, so every size below is relative to a
# number this script chose, never to the tree.
FIX_ARGUED=$((GOAL + 1))
argued_at_fixture() {
  case "$1" in skills/recorded/SKILL.md) echo "$FIX_ARGUED" ;; *) return 0 ;; esac
}
rm -rf "$FIX/skills"; mkdir -p "$FIX/skills/recorded"

pad "$FIX/skills/recorded/SKILL.md" $((GOAL + 1))
out="$(offenders "$FIX" justification_fixture argued_at_fixture)"
if [ -z "$out" ]; then
  ok "a recorded file just over the goal passes"
else
  bad "FR7 — recorded file was reported: $out"
fi

# 0190 AC4 — this case once asserted the opposite: a recorded file far over the goal passed, because
# the reason was the only control. That is how the sprint skill tripled under a stale reason.
pad "$FIX/skills/recorded/SKILL.md" $((FIX_ARGUED + 30000))
out="$(offenders "$FIX" justification_fixture argued_at_fixture)"
case "$out" in
  *"skills/recorded/SKILL.md"*"re-argue its reason or relocate"*)
    ok "0190 AC4 — a recorded file 30,000 bytes past its argued-at size fails" ;;
  *) bad "0190 AC4 — a recorded file 30,000 bytes past its argued-at size was not reported: ${out:-<nothing>}" ;;
esac

pad "$FIX/skills/recorded/SKILL.md" $((GOAL - 1))
out="$(offenders "$FIX" justification_fixture argued_at_fixture)"
case "$out" in
  *"remove its stale justification"*) ok "a justification on a file back under the goal fails" ;;
  *) bad "FR7 — stale justification was not reported: ${out:-<nothing>}" ;;
esac

echo "0190 AC3 — the margin is inclusive at S + MARGIN and breached at one byte more"
pad "$FIX/skills/recorded/SKILL.md" $((FIX_ARGUED + MARGIN))
out="$(offenders "$FIX" justification_fixture argued_at_fixture)"
if [ -z "$out" ]; then
  ok "0190 AC3 — a recorded file exactly MARGIN past its argued-at size passes"
else
  bad "0190 AC3 — a file exactly at the margin was reported: $out"
fi
pad "$FIX/skills/recorded/SKILL.md" $((FIX_ARGUED + MARGIN + 1))
out="$(offenders "$FIX" justification_fixture argued_at_fixture)"
want="skills/recorded/SKILL.md is $((FIX_ARGUED + MARGIN + 1)) bytes, $((MARGIN + 1)) past the $FIX_ARGUED bytes its reason was argued at"
case "$out" in
  *"$want"*"re-argue its reason or relocate"*)
    ok "0190 AC3 — one byte past the margin fails, naming the file, its size, the argued-at size and the remedy" ;;
  *) bad "0190 AC3 — one byte past the margin did not report as expected: ${out:-<nothing>}" ;;
esac

echo "0190 AC2 — a recorded file with no argued-at size fails, named"
rm -rf "$FIX/skills"; mkdir -p "$FIX/skills/unsized"
pad "$FIX/skills/unsized/SKILL.md" $((GOAL + 1))
out="$(offenders "$FIX" justification_fixture argued_at_fixture)"
case "$out" in
  *"skills/unsized/SKILL.md"*"missing its argued-at size"*)
    ok "0190 AC2 — a recorded file missing its argued-at size is reported by name" ;;
  *) bad "0190 AC2 — a recorded file with no argued-at size was not reported: ${out:-<nothing>}" ;;
esac

echo "FR7 — an unrecorded file is judged by the goal, not by a neighbour's reason"
rm -rf "$FIX/skills"; mkdir -p "$FIX/skills/recorded" "$FIX/skills/other"
pad "$FIX/skills/recorded/SKILL.md" $((GOAL + 5000))
pad "$FIX/skills/other/SKILL.md" $((GOAL + 5000))
out="$(offenders "$FIX" justification_fixture argued_at_fixture)"
case "$out" in
  *"skills/other/SKILL.md"*)
    case "$out" in
      *"skills/recorded/SKILL.md"*) bad "FR7 — the recorded file was reported too: $out" ;;
      *) ok "the unrecorded file of the pair is the only one reported" ;;
    esac ;;
  *) bad "FR7 — the unrecorded file was not reported: ${out:-<nothing>}" ;;
esac

# ------------------------------------------------------------------------------------------------
# 0035 — the payback test itself is guarded. The NFR that put the test in this header rather than a
# decision record only holds if something notices when it goes missing: an author who deletes the
# arithmetic leaves a guard that says "relocate first" and cannot say when. These cases read this
# file's own header, so the rule and its check live in one place.

SELF="$ROOT/tests/skill-size.test.sh"
HEADER="$(awk '/^set -eu$/ { exit } { print }' "$SELF")"

echo "0035 AC1 — the header states the payback test, every input, and their source"
for want in \
  'p = 1 / (1 + B/' \
  '4.038' \
  '$6.25' \
  '$0.50' \
  '$0.1028' \
  'turns per session' \
  'MEASUREMENT.md'
do
  case "$HEADER" in
    *"$want"*) ok "payback test names $want" ;;
    *) bad "0035 AC1 — the header does not state $want; the test cannot be recomputed without it" ;;
  esac
done

echo "0035 FR4 — the header demands a justification that says what was considered relocating"
case "$HEADER" in
  *"considered relocating"*) ok "the header asks for what was considered relocating, as the message does" ;;
  *) bad "0035 FR4 — the header asks for a reason without asking what was considered relocating" ;;
esac

echo "0035 AC2 — the POINTER sentence is qualified, not unconditional"
case "$HEADER" in
  *"is a POINTER, not a cut: detail that only some runs need"*)
    bad "0035 AC2 — the unconditional 'first move is a POINTER' sentence still stands" ;;
  *"POINTER"*)
    case "$HEADER" in
      *"mandatory"*) ok "the POINTER sentence is qualified by the non-cost conditions" ;;
      *) bad "0035 AC2/FR2 — the POINTER sentence names no mandatory-content condition" ;;
    esac ;;
  *) bad "0035 AC2 — the header no longer names the pointer as the first move at all" ;;
esac

echo "0190 AC5 — the header states the margin, the argued-at field and the grandfathering"
for want in 'MARGIN' 'MARGIN = 5,000 bytes' 'Derivation' 'argued at' 'never written into a reason' 'GRANDFATHERED by 0190'
do
  case "$HEADER" in
    *"$want"*) ok "0190 AC5 — the header names $want" ;;
    *) bad "0190 AC5 — the header does not state $want" ;;
  esac
done

# Every recorded file, read from the justification table itself rather than a hand-kept list: a hand
# list once left the sprint and retro reasons out, and a byte count in the sprint reason went stale
# exactly as FR6 predicted (0190).
echo "0035 AC4/FR6 — every justification names what was considered, and carries no byte count"
RECORDED=""
for f in "$ROOT"/skills/*/SKILL.md; do
  rel="skills/$(basename "$(dirname "$f")")/SKILL.md"
  [ -n "$(justification "$rel")" ] && RECORDED="$RECORDED $rel"
done
case " $RECORDED " in
  *" skills/sprint/SKILL.md "*) ok "0190 AC1 — the loop includes skills/sprint/SKILL.md" ;;
  *) bad "0190 AC1 — the loop leaves skills/sprint/SKILL.md out" ;;
esac
SPRINT_REASON="$(justification skills/sprint/SKILL.md)"
for want in '0190 — ' "Step 7's lock and cap-kill recovery" 'the design-beside rule' 'rejected on both conditions'
do
  case "$SPRINT_REASON" in
    *"$want"*) ok "0190 AC1 — the sprint reason names $want" ;;
    *) bad "0190 AC1 — the sprint reason does not name $want: $SPRINT_REASON" ;;
  esac
done
for rel in $RECORDED; do
  reason="$(justification "$rel")"
  if [ -z "$reason" ]; then
    bad "0035 AC4 — $rel has no recorded justification"
    continue
  fi
  # Drop the leading ticket id so its four digits are not read as a byte count.
  body="${reason#[0-9][0-9][0-9][0-9] }"
  # Commas stripped first: the stale sprint reason wrote its count as "~2,100", which no run of four
  # digits matches, so the check could not see the very number FR6 exists to catch (0190).
  if printf '%s' "$body" | tr -d ',' | grep -Eq '[0-9]{4,}'; then
    bad "0035 FR6 — $rel's justification carries a number that will go stale: $body"
  else
    ok "$rel's justification carries no byte count"
  fi
  case "$body" in
    *relocat*) ok "$rel's justification names what was considered relocating" ;;
    *) bad "0035 AC4/FR4 — $rel's justification does not say what was considered relocating" ;;
  esac
done

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
TALLIED=1
[ "$FAIL" = 0 ]
