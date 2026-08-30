#!/bin/sh
#
# Reporting-rule guard (0074).
#
# WHY THIS EXISTS:
#
# Six stage skills each ended with a closing step that enumerated, in its own words, what to put
# on the screen. Six copies of one rule is six things to drift, and nothing said where the content
# that did NOT belong on the screen should go instead — so a diagnosis a session had already made
# was written to the audience and died with the conversation.
#
# references/REPORTING.md is now the single statement of that rule and every stage skill cites it.
# This guard is what makes "cited, never restated" checkable: a rule about what a skill says,
# verified only by reading the skill that says it, verifies its own documentation (0074 FR5).
#
# WHAT IT CHECKS, AND WHAT EACH CHECK CANNOT SEE:
#
#   citation      each stage skill's report step names references/REPORTING.md exactly once, and
#                 the file names it exactly once in total. Cardinality is the contract here rather
#                 than an incidental count: FR1 is "stated in exactly one place and cited, never
#                 restated", so a second copy in a skill file is the defect, not a sibling's
#                 addition. Blind spot: it cannot tell a citation from a mention.
#
#   no restating  no skill's report step repeats a kind label from REPORTING.md's routing table.
#                 The labels are READ from that table, so renaming one there moves this check with
#                 it. Blind spot, stated because it is real: a skill that re-enumerates the same
#                 four kinds IN ITS OWN WORDS is not seen. That is the same limit citations.test.sh
#                 records for anchoring, and widening the match cannot fix it without reporting
#                 ordinary prose as a restatement.
#
#   destinations  REPORTING.md's routing table gives every row an explicit destination, and exactly
#                 four rows route to the screen — FR7's four kinds, no fifth admitted quietly.
#
#   no budget     no numeric or verbal size budget anywhere in REPORTING.md. FR6 forbids one on
#                 evidence: human-facing narration measured 4.6% of output tokens, so a budget buys
#                 1.7% of a session and misses the routing point entirely.
#
#   no flag       no verbosity flag, mode or trigger phrase in REPORTING.md. FR9's expansion path
#                 IS the durable artifact, and a skill file cannot implement a flag in any case.
#                 So REPORTING.md states that prohibition WITHOUT using the forbidden literals —
#                 if it wrote "no --verbose flag", this check could not tell it from the defect.
#
#   two channels  REPORTING.md names 0036 FR13's machine outcome as the other channel and says the
#                 two carry the same facts (FR4). Scoped to the markdown PARAGRAPH, not to a line:
#                 a line-scoped match reds when someone rewraps the sentence, which this project's
#                 CLAUDE.md names as the standing hazard of grepping prose, and it was confirmed
#                 here by rewrapping the sentence in a scratch copy before the scope was widened.
#                 A paragraph boundary is the document's own and cannot drift.
#
# Every case below runs against an AUTHORED fixture tree, never a copy of references/ or skills/
# (testing-conventions.md, the fixture rule). A fixture copied from a file under test reds on
# unrelated growth, and a guard whose reds can be artefacts teaches everyone to discount its reds.
#
# Usage:  tests/reporting.test.sh
#
# Requires: sh, awk, grep, sed. No runner — this project has none.

set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

RULE="references/REPORTING.md"
SKILLS="design develop prototype queue retro verify"

PASS=0
FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }

FIX=""
cleanup() { [ -n "$FIX" ] && rm -rf "$FIX"; return 0; }
trap cleanup EXIT INT TERM

# ---------------------------------------------------------------------------
# The guard. Every function takes the tree root as a parameter, so the fixture
# cases drive this code rather than a copy of it.
# ---------------------------------------------------------------------------

# report_section <root> <skill> — the body of that skill's closing report step, from its heading
# to the next `## ` or end of file. A skill's closing step is the one whose heading TEXT ends in
# "Report" or "Verdict"; verify's is titled Verdict because a verdict is what it produces, and
# renaming it to Report would have been a change to verify made by this ticket's guard.
report_section() {
  root="${1:?report_section needs a tree root}"
  skill="${2:?report_section needs a skill name}"
  awk '
    /^## / { inside = ($0 ~ /(Report|Verdict)[[:space:]]*$/) }
    inside { print }
  ' "$root/skills/$skill/SKILL.md" 2>/dev/null || true
}

# kind_labels <root> — the first-column label of every routing-table row in REPORTING.md that
# routes to the screen. Read rather than hard-coded, so a rename in the rule moves the check.
kind_labels() {
  root="${1:?kind_labels needs a tree root}"
  awk -F'|' '
    /^\|/ && NF > 3 {
      label = $2; dest = $3
      gsub(/^[ \t]+|[ \t]+$/, "", label); gsub(/^[ \t]+|[ \t]+$/, "", dest)
      gsub(/\*\*/, "", label); gsub(/`/, "", label)
      if (dest == "screen") print label
    }
  ' "$root/$RULE" 2>/dev/null || true
}

# table_destinations <root> — the destination cell of every routing-table row, one per line,
# excluding the header and its separator.
table_destinations() {
  root="${1:?table_destinations needs a tree root}"
  awk -F'|' '
    /^\|/ && NF > 3 {
      label = $2; dest = $3
      gsub(/^[ \t]+|[ \t]+$/, "", label); gsub(/^[ \t]+|[ \t]+$/, "", dest)
      if (label == "" || label ~ /^-+$/ || dest ~ /^-+$/) next
      if (tolower(label) == "kind") next
      print dest
    }
  ' "$root/$RULE" 2>/dev/null || true
}

# budget_lines <root> — every line of REPORTING.md that states a size budget. Two forms, because a
# budget can be written with a digit or spelled out, and only catching the digit form would leave
# "keep it under two hundred words" invisible.
budget_lines() {
  root="${1:?budget_lines needs a tree root}"
  f="$root/$RULE"
  [ -f "$f" ] || return 0
  {
    # A — a digit ADJACENT to the unit: "200 tokens". Adjacency rather than "somewhere on the same
    # line" on purpose: this file has to be able to write "0036 FR13" beside the word "sentence"
    # without reading as a budget, and a whole-line match cannot tell those apart.
    grep -nEi '[0-9]+[[:space:]]*(token|word|line|sentence|character|byte)s?\b' "$f" || true
    # B — the spelled-out form, which carries no digit at all: "under two hundred words".
    grep -nEi '(under|at most|no more than|fewer than|limited to|budget of|capped at|maximum of)[^.]{0,24}(token|word|line|sentence|character|byte)s?\b' "$f" || true
  } | sort -u
}

# flag_lines <root> — every line of REPORTING.md offering a verbosity flag, mode or trigger phrase.
flag_lines() {
  root="${1:?flag_lines needs a tree root}"
  f="$root/$RULE"
  [ -f "$f" ] || return 0
  grep -nEi -- '--verbose|-v\b|verbose mode|verbosity mode|verbosity flag|just ask|ask me for more|say the word|on request, (i|the session) will' "$f" || true
}

# audit <root> — the whole verdict for a tree, as lines the callers assert on directly:
#   FAIL  …   a defect, named with the file it is in
#   COUNT …   how many skills and kind labels were extracted
audit() {
  root="${1:?audit needs a tree root}"

  if [ ! -f "$root/$RULE" ]; then
    echo "FAIL  $RULE does not exist — the reporting rule has no single home"
    echo "COUNT 0 skills, 0 kinds"
    return 0
  fi

  labels="$(kind_labels "$root")"
  nlabels="$(printf '%s' "$labels" | grep -c . || true)"

  # An empty label set makes every restatement comparison below pass, so it is a defect in its own
  # right rather than something allowed to look like a clean tree.
  #
  # Written as full `if` blocks rather than `[ ... ] && echo`: under `set -e` a short-circuit whose
  # test fails carries that failure out of the function, so the clean case — the one where nothing
  # is wrong — would abort the audit and return a partial result. The same trap is recorded in
  # tests/reference-size.test.sh.
  if [ "$nlabels" -eq 0 ]; then
    echo "FAIL  $RULE has no routing-table row destined for the screen — the table recognition stopped matching"
  elif [ "$nlabels" -ne 4 ]; then
    # Exactly four kinds reach the screen (FR7). A fifth added without argument is the drift this
    # rule exists to prevent, and a fourth quietly dropped is the deletion it exists to forbid.
    echo "FAIL  $RULE routes $nlabels kinds to the screen; FR7 fixes it at four"
  fi

  # Every row has an explicit destination, and it is one of the two that exist.
  table_destinations "$root" | while read -r dest; do
    [ -n "$dest" ] || continue
    case "$dest" in
      screen|disk) ;;
      *) echo "FAIL  $RULE has a routing-table row destined \"$dest\"; every row goes to screen or to disk" ;;
    esac
  done

  budget_lines "$root" | while IFS= read -r line; do
    [ -n "$line" ] || continue
    echo "FAIL  $RULE states a size budget at line ${line%%:*} — FR6 makes this a routing rule, not a verbosity one"
  done

  flag_lines "$root" | while IFS= read -r line; do
    [ -n "$line" ] || continue
    echo "FAIL  $RULE offers a verbosity flag or trigger phrase at line ${line%%:*} — FR9's expansion path is the artifact on disk"
  done

  # FR4 — one line carries both the other channel and the claim about it, so deleting the sentence
  # reds even though "FR13" and "same facts" would each survive elsewhere.
  if ! awk 'BEGIN { RS = "" } /FR13/ && /same facts/ { found = 1 } END { exit !found }' "$root/$RULE"; then
    echo "FAIL  $RULE does not name 0036 FR13's machine outcome as the other channel carrying the same facts"
  fi

  for skill in $SKILLS; do
    file="skills/$skill/SKILL.md"
    if [ ! -f "$root/$file" ]; then
      echo "FAIL  $file does not exist — the skill set this guard covers has moved"
      continue
    fi
    section="$(report_section "$root" "$skill")"
    if [ -z "$section" ]; then
      echo "FAIL  $file has no closing step titled Report or Verdict — nothing to check the citation in"
      continue
    fi

    n="$(printf '%s\n' "$section" | grep -c "$RULE" || true)"
    case "$n" in
      1) ;;
      0) echo "FAIL  $file does not cite $RULE in its report step" ;;
      *) echo "FAIL  $file cites $RULE $n times in its report step; cite it once" ;;
    esac

    total="$(grep -c "$RULE" "$root/$file" || true)"
    if [ "$total" -gt 1 ]; then
      echo "FAIL  $file names $RULE $total times; the rule is cited once and restated nowhere"
    fi

    printf '%s\n' "$labels" | while IFS= read -r label; do
      [ -n "$label" ] || continue
      if printf '%s\n' "$section" | grep -qF "$label"; then
        echo "FAIL  $file restates $RULE's kind \"$label\" in its report step; cite the rule, do not copy it"
      fi
    done
  done

  echo "COUNT $(printf '%s' "$SKILLS" | wc -w | tr -d ' ') skills, $nlabels kinds"
  return 0
}

# ---------------------------------------------------------------------------
# AC1 — the shipped tree
# ---------------------------------------------------------------------------

echo "AC1 — every stage skill cites the reporting rule once, and the rule holds its own shape"
out="$(audit "$ROOT")"
counts="$(printf '%s\n' "$out" | grep '^COUNT ' || true)"
defects="$(printf '%s\n' "$out" | grep '^FAIL ' || true)"
if [ -z "$defects" ]; then
  ok "no defects — ${counts#COUNT }"
else
  OLDIFS="$IFS"; IFS='
'
  for l in $defects; do bad "${l#FAIL  }"; done   # in this shell, so each defect counts
  IFS="$OLDIFS"
fi

# ---------------------------------------------------------------------------
# Fixture cases. Each feeds the guard the exact defect it exists to catch; a guard only ever seen
# passing is indistinguishable from one wired to nothing (testing-conventions.md).
# ---------------------------------------------------------------------------

FIX="$(mktemp -d)"

# mkfix <dir> — a minimal, authored tree that the guard passes clean.
mkfix() {
  dir="${1:?mkfix needs a target directory}"
  rm -rf "$dir"
  mkdir -p "$dir/references"
  cat > "$dir/references/REPORTING.md" <<'FIXTURE'
# Fixture reporting rule

## What goes where

| Kind | Destination | Detail |
|---|---|---|
| **Alpha kind** | screen | first |
| **Beta kind** | screen | second |
| **Gamma kind** | screen | third |
| **Delta kind** | screen | fourth |
| Everything else | disk | the item file |

0036 FR13's outcome is the other channel, and the two carry the same facts.
FIXTURE
  for s in design develop prototype queue retro verify; do
    mkdir -p "$dir/skills/$s"
    cat > "$dir/skills/$s/SKILL.md" <<'FIXTURE'
# Fixture skill

## Step 1 — Do the work

Body.

## Step 2 — Report

`references/REPORTING.md` governs this step.
FIXTURE
  done
}

# mutate <file> <sed-script> <label> — applies the mutation and proves it landed. A mutation that
# silently failed to apply reads exactly like a guard that holds.
mutate() {
  cp "$1" "$FIX/.before"
  sed "$2" "$FIX/.before" > "$1"
  if diff "$FIX/.before" "$1" >/dev/null; then
    bad "mutation \"$3\" produced no diff; the case below would prove nothing"
    return 1
  fi
  ok "mutation \"$3\" landed (diff is non-empty)"
}

echo "AC1 — the fixture tree passes clean, so every red below is the mutation and not the fixture"
mkfix "$FIX/t"
out="$(audit "$FIX/t")"
case "$out" in
  *'FAIL '*) bad "the unmutated fixture already fails: $out" ;;
  *) ok "the unmutated fixture is clean" ;;
esac

echo "AC2 — a stage skill whose citation was deleted fails, naming that skill file"
mkfix "$FIX/t"
mutate "$FIX/t/skills/design/SKILL.md" '/references\/REPORTING.md/d' "delete design's citation"
out="$(audit "$FIX/t")"
case "$out" in
  *'FAIL  skills/design/SKILL.md does not cite references/REPORTING.md in its report step'*)
    case "$out" in
      *'skills/develop/SKILL.md does not cite'*) bad "AC2 — an untouched skill was reported too: $out" ;;
      *) ok "the skill whose citation went is named, and only that one" ;;
    esac ;;
  *) bad "AC2 — expected the missing citation to be named, got: ${out:-<nothing>}" ;;
esac

echo "AC2 — a skill with no closing report step fails rather than being skipped"
mkfix "$FIX/t"
mutate "$FIX/t/skills/prototype/SKILL.md" 's/^## Step 2 — Report/## Step 2 — Handoff/' "retitle prototype's report step"
out="$(audit "$FIX/t")"
case "$out" in
  *'FAIL  skills/prototype/SKILL.md has no closing step titled Report or Verdict'*)
    ok "a missing report step is a named defect, not a silently skipped file" ;;
  *) bad "AC2 — expected the missing report step to be named, got: ${out:-<nothing>}" ;;
esac

echo "FR1 — a skill that names the rule twice fails; the rule is cited once and restated nowhere"
mkfix "$FIX/t"
printf '\nSee also `references/REPORTING.md`.\n' >> "$FIX/t/skills/retro/SKILL.md"
out="$(audit "$FIX/t")"
case "$out" in
  *'skills/retro/SKILL.md cites references/REPORTING.md 2 times in its report step'*)
    ok "a second citation in one skill is reported" ;;
  *) bad "FR1 — expected the duplicate citation to be reported, got: ${out:-<nothing>}" ;;
esac

echo "FR1 — a skill that restates a kind label instead of citing fails, naming the label"
mkfix "$FIX/t"
printf '\nReport the **Gamma kind** and nothing else.\n' >> "$FIX/t/skills/queue/SKILL.md"
out="$(audit "$FIX/t")"
case "$out" in
  *'skills/queue/SKILL.md restates references/REPORTING.md'"'"'s kind "Gamma kind"'*)
    ok "the restated kind is reported with the skill and the label" ;;
  *) bad "FR1 — expected the restatement to be reported, got: ${out:-<nothing>}" ;;
esac

echo "AC5 — a numeric size budget in the rule fails, naming the line"
mkfix "$FIX/t"
printf '\nKeep the report under 200 tokens.\n' >> "$FIX/t/references/REPORTING.md"
out="$(audit "$FIX/t")"
case "$out" in
  *'references/REPORTING.md states a size budget at line'*)
    ok "the digit form of a budget is caught" ;;
  *) bad "AC5 — expected the numeric budget to be caught, got: ${out:-<nothing>}" ;;
esac

echo "AC5 — a spelled-out size budget fails too, so the digit form is not the only one caught"
mkfix "$FIX/t"
printf '\nKeep it under two hundred words.\n' >> "$FIX/t/references/REPORTING.md"
out="$(audit "$FIX/t")"
case "$out" in
  *'references/REPORTING.md states a size budget at line'*)
    ok "the spelled-out form of a budget is caught" ;;
  *) bad "AC5 — expected the spelled-out budget to be caught, got: ${out:-<nothing>}" ;;
esac

echo "AC4 — a verbosity flag in the rule fails, naming the line"
mkfix "$FIX/t"
printf '\nPass `--verbose` for the detail.\n' >> "$FIX/t/references/REPORTING.md"
out="$(audit "$FIX/t")"
case "$out" in
  *'references/REPORTING.md offers a verbosity flag or trigger phrase at line'*)
    ok "a flag offered as the expansion path is caught" ;;
  *) bad "AC4 — expected the flag to be caught, got: ${out:-<nothing>}" ;;
esac

echo "AC4 — a trigger phrase fails the same way"
mkfix "$FIX/t"
printf '\nIf you want the detail, just ask.\n' >> "$FIX/t/references/REPORTING.md"
out="$(audit "$FIX/t")"
case "$out" in
  *'references/REPORTING.md offers a verbosity flag or trigger phrase at line'*)
    ok "a trigger phrase offered as the expansion path is caught" ;;
  *) bad "AC4 — expected the trigger phrase to be caught, got: ${out:-<nothing>}" ;;
esac

echo "AC3 — a routing-table row with no destination fails, naming what it said instead"
mkfix "$FIX/t"
mutate "$FIX/t/references/REPORTING.md" 's/| \*\*Delta kind\*\* | screen |/| **Delta kind** | somewhere |/' "give a row a destination that is neither screen nor disk"
out="$(audit "$FIX/t")"
case "$out" in
  *'has a routing-table row destined "somewhere"'*)
    ok "a row with no real destination is reported with the cell it carried" ;;
  *) bad "AC3 — expected the bad destination to be reported, got: ${out:-<nothing>}" ;;
esac

echo "FR7 — a fifth kind routed to the screen fails; the set is four, not four-or-more"
mkfix "$FIX/t"
mutate "$FIX/t/references/REPORTING.md" 's/^| Everything else | disk |/| **Epsilon kind** | screen |/' "promote a fifth kind to the screen"
out="$(audit "$FIX/t")"
case "$out" in
  *'routes 5 kinds to the screen; FR7 fixes it at four'*)
    ok "a fifth screen kind is reported" ;;
  *) bad "FR7 — expected the fifth kind to be reported, got: ${out:-<nothing>}" ;;
esac

echo "FR7 — a kind quietly dropped fails the same way, from the other side"
mkfix "$FIX/t"
mutate "$FIX/t/references/REPORTING.md" '/| \*\*Delta kind\*\* | screen |/d' "delete a screen kind"
out="$(audit "$FIX/t")"
case "$out" in
  *'routes 3 kinds to the screen; FR7 fixes it at four'*)
    ok "a dropped kind is reported" ;;
  *) bad "FR7 — expected the dropped kind to be reported, got: ${out:-<nothing>}" ;;
esac

echo "AC5/FR6 — an unrecognisable table fails on the empty set rather than passing vacuously"
mkfix "$FIX/t"
mutate "$FIX/t/references/REPORTING.md" 's/^|/ /' "unpipe every table row"
out="$(audit "$FIX/t")"
case "$out" in
  *'has no routing-table row destined for the screen'*)
    ok "zero kinds is reported as a defect, not as a clean tree" ;;
  *) bad "FR6 — expected the empty-kind-set failure, got: ${out:-<nothing>}" ;;
esac

echo "AC7 — dropping the two-channel sentence fails, even though both words survive elsewhere"
mkfix "$FIX/t"
printf '\nFR13 is mentioned on its own here.\n\nThe same facts are claimed far from it.\n' \
  >> "$FIX/t/references/REPORTING.md"
mutate "$FIX/t/references/REPORTING.md" "/0036 FR13's outcome is the other channel/d" "delete the two-channel sentence"
out="$(audit "$FIX/t")"
case "$out" in
  *"does not name 0036 FR13's machine outcome as the other channel"*)
    ok "the claim is anchored to its own line, not to the vocabulary in the file" ;;
  *) bad "AC7 — expected the missing two-channel claim to be reported, got: ${out:-<nothing>}" ;;
esac

echo "AC2 — a missing rule file fails loudly rather than passing with nothing to check"
mkfix "$FIX/t"
rm -f "$FIX/t/references/REPORTING.md"
out="$(audit "$FIX/t")"
case "$out" in
  *'references/REPORTING.md does not exist'*)
    ok "the absent rule file is the reported defect" ;;
  *) bad "AC2 — expected the missing rule file to be reported, got: ${out:-<nothing>}" ;;
esac

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" = 0 ]
