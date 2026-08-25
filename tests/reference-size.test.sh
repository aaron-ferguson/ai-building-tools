#!/bin/sh
#
# Size guard for references/*.md (0028).
#
# WHY THE NUMBER IS SOFT — and the reversal it records:
#
# 0020 FR4 and 0023 AC7 both asserted a HARD ceiling of 1,500 tokens on references/CONCURRENCY.md.
# That ceiling is RETIRED, on Aaron's call, 2026-08-23: "A hard character or token ceiling does not
# make sense because if there are more principles than fit, then we need to hold those principles."
# Both tickets are closed and stay closed; what they asserted is no longer the standard. The
# equivalent reversal for skills/*/SKILL.md landed the same day in tests/skill-size.test.sh.
#
# Two facts made the hard number untenable rather than merely strict. It was already breached before
# the ticket obliged to hold it — a ceiling with no gate is enforced by whichever ticket happens to
# cite it, which is arbitrary. And both ways it had ever been paid were spent: restated
# justifications, then relocating the incidents out. The next rule that had to change could only
# have bought its words from another rule.
#
# So the goal below is a prompt to relocate, never a mandate to delete. The full reasoning for this
# shape lives in tests/skill-size.test.sh's header and is not restated here.
#
# WHAT THIS GATE ACTUALLY DOES:
#
#   over the goal + a recorded reason  -> passes, and the pass line names the file, size and reason
#   over the goal + no reason          -> FAILS, naming the file and its overage in bytes
#   under the goal + a recorded reason -> FAILS, so the stale entry is removed
#
# Measured in bytes, absolutely (0021's reason): a percentage of a moving baseline is un-auditable,
# and a decoded character count undercounts these files' multi-byte em-dashes.
#
# Usage:  tests/reference-size.test.sh
#
# Requires: sh, wc, awk. No runner — this project has none, and adding one is not this gate's job.

set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

# The retired hard ceiling was 1,500 tokens. Converted at the 4.038 bytes/token ratio this repo
# measured (0021), that is 6,057 bytes — the same line, now soft. Stating the ratio is the point:
# a token figure is a model's arithmetic, a byte figure is `wc -c`, and only one of them is checkable.
GOAL=6057

# RELOCATE FIRST — but only where it pays, and WHEN IT PAYS IS DECIDED BY THE PAYBACK TEST IN
# tests/skill-size.test.sh. That header holds the arithmetic, the break-even share and the two
# conditions that are not about cost; this file does not restate any of it, because two guards
# stating one rule is two rules that drift, silently, with nothing to red when they disagree.
#
# What belongs here is the worked instance, because it is a references/ file and this is the
# references/ guard: CONCURRENCY.md -> CONCURRENCY-INCIDENTS.md is the split that passes the test.
# The rules and the failure each prevents stayed; the incidents, the reasoning and the live-conflict
# procedure moved, and the moved half is read only when a rule is argued with or a conflict is live.
# Record a reason only once relocation has been considered and rejected — and say what was
# considered, so the next reader argues with a judgement rather than re-deriving it.
RELOCATE='relocate detail only some runs need to a pointer file, or record a justification naming what you considered relocating'

# justification <relative-path> — echoes why this file is over the goal, or nothing if it is not
# recorded as over it. One line per file, naming the ticket that accepted the cost.
justification() {
  case "$1" in
    references/CONCURRENCY.md)
      echo "0028 — read before every backlog write, so each rule here is rent on every session; the incidents, the reasoning and the live-conflict procedure already relocated to CONCURRENCY-INCIDENTS.md, and what remains is the rule statements themselves" ;;
    references/CONCURRENCY-INCIDENTS.md)
      echo "0028 — this file IS the relocation target, read only when a rule is argued with or a conflict is live; growth here is the pointer mechanism working, and relocating out of it would only need a third file" ;;
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

# offenders <root> <justification-lookup-fn> — prints one line per file over the goal with no
# recorded reason, or recorded while under it; nothing when every file is accounted for. The lookup
# is a parameter so the fixture cases can drive both paths whatever the real tree holds.
offenders() {
  root="$1"
  lookup="${2:?offenders needs a justification-lookup function}"
  for f in "$root"/references/*.md; do
    [ -f "$f" ] || continue
    rel="references/$(basename "$f")"
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
      echo "$rel is $bytes bytes, over the $GOAL goal by $((bytes - GOAL)) — $RELOCATE"
    fi
  done
}

echo "AC1 — every reference file is within the goal, or over it with a recorded reason"
found="$(offenders "$ROOT" justification)"
if [ -z "$found" ]; then
  # Name the recorded files with their sizes rather than reporting a clean sweep: an accepted cost
  # is still a cost, and a pass line hiding it reads as "everything is within the goal".
  over=""
  for f in "$ROOT"/references/*.md; do
    rel="references/$(basename "$f")"
    if [ -n "$(justification "$rel")" ]; then
      over="$over
         $rel ($(wc -c < "$f" | tr -d ' ') bytes) — $(justification "$rel")"
    fi
  done
  if [ -n "$over" ]; then
    ok "within the goal, except where recorded:$over"
  else
    ok "every reference file within the goal, none recorded over it"
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
# under test (testing-conventions.md, the fixture rule). Copying a real reference file would size
# the padding against whatever that file happens to be today, so unrelated growth could red a case
# that has nothing to do with it — and a guard whose reds can be artefacts trains sessions to
# discount its reds.
FIX="$(mktemp -d)"
BASE="$FIX/base.md"
awk 'BEGIN { while (i++ < 1000) printf "b" }' > "$BASE"
BASE_BYTES="$(wc -c < "$BASE" | tr -d ' ')"

echo "AC6 — the fixture base is independent of the tree under test"
if [ "$BASE_BYTES" = 1000 ]; then
  ok "fixture base is a generated 1000 bytes, not a copy of any reference file"
else
  bad "AC6 — fixture base is $BASE_BYTES bytes, expected 1000"
fi

pad() {   # pad <path> <target-bytes> — base plus filler to an exact size
  cp "$BASE" "$1"
  awk -v n="$(($2 - BASE_BYTES))" 'BEGIN { while (i++ < n) printf "x" }' >> "$1"
}

echo "AC2 — an unrecorded file over the goal fails, named, with its overage in bytes"
rm -rf "$FIX/references"; mkdir -p "$FIX/references"
pad "$FIX/references/PADDED.md" $((GOAL + 500))
out="$(offenders "$FIX" justification)"
case "$out" in
  *"references/PADDED.md is $((GOAL + 500)) bytes, over the $GOAL goal by 500"*)
    case "$out" in
      *"relocate detail only some runs need to a pointer file"*)
        ok "unrecorded file over the goal reported with its overage, relocation named first" ;;
      *) bad "AC2/FR6 — reported the overage without naming relocation: $out" ;;
    esac ;;
  "") bad "AC2 — file over the goal was NOT reported; the guard is wired to nothing" ;;
  *)  bad "AC2 — reported something else: $out" ;;
esac

echo "AC2 — a file within the goal passes"
rm -rf "$FIX/references"; mkdir -p "$FIX/references"
pad "$FIX/references/PLAIN.md" $((GOAL - 1))
out="$(offenders "$FIX" justification)"
if [ -z "$out" ]; then
  ok "file one byte under the goal reported nothing"
else
  bad "AC2 — compliant file was reported: $out"
fi

echo "AC3/AC4 — a recorded reason carries no upper bound, and goes stale under the goal"
justification_fixture() {
  case "$1" in references/RECORDED.md) echo "0099 — fixture reason" ;; *) return 0 ;; esac
}
rm -rf "$FIX/references"; mkdir -p "$FIX/references"

pad "$FIX/references/RECORDED.md" $((GOAL + 1))
out="$(offenders "$FIX" justification_fixture)"
if [ -z "$out" ]; then
  ok "a recorded file just over the goal passes"
else
  bad "AC3 — recorded file was reported: $out"
fi

pad "$FIX/references/RECORDED.md" $((GOAL + 30000))
out="$(offenders "$FIX" justification_fixture)"
if [ -z "$out" ]; then
  ok "a recorded file far over the goal passes — the reason is the control, not a second number"
else
  bad "AC3 — recorded file far over the goal was reported: $out"
fi

pad "$FIX/references/RECORDED.md" $((GOAL - 1))
out="$(offenders "$FIX" justification_fixture)"
case "$out" in
  *"remove its stale justification"*) ok "a justification on a file back under the goal fails as stale" ;;
  *) bad "AC4 — stale justification was not reported: ${out:-<nothing>}" ;;
esac

echo "AC2 — an unrecorded file is judged by the goal, not by a neighbour's reason"
rm -rf "$FIX/references"; mkdir -p "$FIX/references"
pad "$FIX/references/RECORDED.md" $((GOAL + 5000))
pad "$FIX/references/OTHER.md" $((GOAL + 5000))
out="$(offenders "$FIX" justification_fixture)"
case "$out" in
  *"references/OTHER.md"*)
    case "$out" in
      *"references/RECORDED.md"*) bad "AC2 — the recorded file was reported too: $out" ;;
      *) ok "the unrecorded file of the pair is the only one reported" ;;
    esac ;;
  *) bad "AC2 — the unrecorded file was not reported: ${out:-<nothing>}" ;;
esac

echo "AC7 — no live prose asserts the retired hard ceiling"
if grep -rn "1,500\|1500 token" "$ROOT/references" "$ROOT/skills" >/dev/null 2>&1; then
  bad "AC7 — the retired 1,500-token ceiling is still asserted: $(grep -rn "1,500\|1500 token" "$ROOT/references" "$ROOT/skills")"
else
  ok "no file under references/ or skills/ asserts the retired hard ceiling"
fi

# 0035 — the RELOCATE block cites the payback test rather than carrying a second copy of it. Two
# guards stating one rule is two rules that drift, and the drift is silent: nothing reds when the
# copies disagree, and the author reads whichever file they opened.

echo "0035 AC3 — the RELOCATE block names where the test lives and does not restate it"
RELOCATE_BLOCK="$(awk '/^# RELOCATE FIRST/ { on = 1 } on { print } /^RELOCATE=/ { if (on) exit }' "$ROOT/tests/reference-size.test.sh")"
case "$RELOCATE_BLOCK" in
  *"tests/skill-size.test.sh"*) ok "the RELOCATE block names tests/skill-size.test.sh as where the test lives" ;;
  *) bad "0035 AC3/FR3 — the RELOCATE block does not say where the payback test lives" ;;
esac
for copied in 'p = 1 /' '4.038' '$6.25' '$0.1028' '17,000'; do
  case "$RELOCATE_BLOCK" in
    *"$copied"*) bad "0035 AC3/FR3 — the RELOCATE block restates $copied; cite the test, do not copy it" ;;
    *) ok "the RELOCATE block does not restate $copied" ;;
  esac
done

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" = 0 ]
