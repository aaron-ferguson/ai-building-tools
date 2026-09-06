#!/bin/sh
#
# Last-line guard.
#
# WHY THIS EXISTS:
#
# `verify` ended every response with one line naming the outcome, the stage the ticket now sits at
# and its status, so a reader who scrolled nothing still knew what ran next. No other stage did, so
# the answer to "what do I do now" was a paragraph somewhere in the middle of a long report — or was
# not there at all, and the next session opened the backlog to work out what the last one had left.
#
# The shape is stated once in references/REPORTING.md; each stage skill states its own verdict words
# and the values it can legitimately print, because only that skill knows which outcomes it reaches.
# This guard is what makes both halves checkable.
#
# WHAT IT CHECKS, AND WHAT EACH CHECK CANNOT SEE:
#
#   shape       references/REPORTING.md carries the canonical template in a fenced block, and says
#               the ID slot takes a dash when the session holds no row. Blind spot: it cannot tell
#               a template from a worked example that happens to look like one.
#
#   template    each stage skill's closing step carries a fenced block with a `— next:` line — the
#               concrete form THAT stage prints. Blind spot: it does not read the stage values, so
#               a skill naming a stage that does not exist passes here (templates/item.md is the
#               vocabulary, and no guard reads prose against it).
#
#   lastness    each closing step says the line is the very last thing printed. This is the half a
#               grep can reach; whether a session actually puts it last is not in any file, so
#               nothing here can check it — which is exactly why the instruction has to be present
#               and identical in all six, rather than paraphrased per skill.
#
# The asserted phrase is matched on ONE line by design: grep is line-based, so rewrapping a guarded
# paragraph across a break makes the phrase unmatchable (CLAUDE.md, Tests). Keep it unbroken.
#
# Every case below runs against an AUTHORED fixture tree, never a copy of references/ or skills/
# (testing-conventions.md, the fixture rule).
#
# Usage:  tests/last-line.test.sh
#
# Requires: sh, awk, grep, sed. No runner — this project has none.

set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

RULE="references/REPORTING.md"
# skills_in <root> — every skill in that tree, derived from the directories rather than listed.
#
# It was a hardcoded list, and the day `orchestrate` landed the list was green by construction:
# a guard that enumerates its own subjects cannot notice a new one, and the moment a rule most
# needs checking is the moment a new member joins the set it governs
# (testing-conventions.md). Taking <root> as a parameter is what lets the fixture cases below
# keep AUTHORED trees — each derives its own six, and the real run derives whatever ships.
skills_in() {
  root="${1:?skills_in needs a tree root}"
  for d in "$root"/skills/*/SKILL.md; do
    [ -f "$d" ] || continue
    basename "$(dirname "$d")"
  done
}
PHRASE="the very last thing printed"

PASS=0
FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }

FIX=""
cleanup() { [ -n "$FIX" ] && rm -rf "$FIX"; return 0; }
trap cleanup EXIT INT TERM

# report_section <root> <skill> — the body of that skill's closing step, from its heading to the
# next `## ` or end of file. Recognised the same way tests/reporting.test.sh recognises it: a
# heading whose text ends in "Report" or "Verdict".
report_section() {
  root="${1:?report_section needs a tree root}"
  skill="${2:?report_section needs a skill name}"
  awk '
    /^## / { inside = ($0 ~ /(Report|Verdict)[[:space:]]*$/) }
    inside { print }
  ' "$root/skills/$skill/SKILL.md" 2>/dev/null || true
}

# fenced_next_lines <text-on-stdin> — every line inside a fenced block that carries the hand-off
# shape: something, an em dash, `next:`. Fenced, so a sentence in prose that mentions a next stage
# is not mistaken for the template a session is meant to print.
fenced_next_lines() {
  awk '
    /^```/ { fence = !fence; next }
    fence && /— next:/ { print }
  '
}

# audit <root> — the whole verdict for a tree, as lines the callers assert on directly.
audit() {
  root="${1:?audit needs a tree root}"

  if [ ! -f "$root/$RULE" ]; then
    echo "FAIL  $RULE does not exist — the hand-off shape has no single home"
    echo "COUNT 0 skills"
    return 0
  fi

  if [ -z "$(fenced_next_lines < "$root/$RULE")" ]; then
    echo "FAIL  $RULE states no hand-off template in a fenced block — the shape every stage prints has no definition"
  fi

  if ! grep -q 'holds no row' "$root/$RULE"; then
    echo "FAIL  $RULE does not say what a session that holds no row puts in the ID slot"
  fi

  for skill in $(skills_in "$root"); do
    file="skills/$skill/SKILL.md"
    if [ ! -f "$root/$file" ]; then
      echo "FAIL  $file does not exist — the skill set this guard covers has moved"
      continue
    fi
    section="$(report_section "$root" "$skill")"
    if [ -z "$section" ]; then
      echo "FAIL  $file has no closing step titled Report or Verdict — nothing to check the last line in"
      continue
    fi

    if [ -z "$(printf '%s\n' "$section" | fenced_next_lines)" ]; then
      echo "FAIL  $file gives no last-line template in its closing step; a reader cannot see the stage it hands to"
    fi

    if ! printf '%s\n' "$section" | grep -qF "$PHRASE"; then
      echo "FAIL  $file does not say its hand-off line is $PHRASE"
    fi
  done

  echo "COUNT $(skills_in "$root" | wc -l | tr -d ' ') skills"
  return 0
}

# ---------------------------------------------------------------------------
# The shipped tree
# ---------------------------------------------------------------------------

echo "AC1 — every stage skill ends on a hand-off line, and the rule holds its shape"
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

mkfix() {
  dir="${1:?mkfix needs a target directory}"
  rm -rf "$dir"
  mkdir -p "$dir/references"
  cat > "$dir/references/REPORTING.md" <<'FIXTURE'
# Fixture reporting rule

## The hand-off line

```
<ID> — <VERDICT> — next: <stage>, status: <status>
```

A session that holds no row writes a dash in the ID slot and names a command.
FIXTURE
  for s in design develop prototype queue retro verify; do
    mkdir -p "$dir/skills/$s"
    cat > "$dir/skills/$s/SKILL.md" <<'FIXTURE'
# Fixture skill

## Step 1 — Do the work

Body.

## Step 2 — Report

End on this line, the very last thing printed:

```
<ID> — FIXED — next: <stage>, status: <status>
```
FIXTURE
  done
}

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

echo "AC2 — a skill whose last-line template went missing fails, naming that skill file"
mkfix "$FIX/t"
mutate "$FIX/t/skills/develop/SKILL.md" '/— next:/d' "delete develop's template line"
out="$(audit "$FIX/t")"
case "$out" in
  *'FAIL  skills/develop/SKILL.md gives no last-line template in its closing step'*)
    case "$out" in
      *'skills/design/SKILL.md gives no last-line template'*) bad "AC2 — an untouched skill was reported too: $out" ;;
      *) ok "the skill whose template went is named, and only that one" ;;
    esac ;;
  *) bad "AC2 — expected the missing template to be named, got: ${out:-<nothing>}" ;;
esac

echo "AC2 — a template outside a fenced block does not count as one"
mkfix "$FIX/t"
mutate "$FIX/t/skills/queue/SKILL.md" 's/^```$//' "unfence queue's template block"
out="$(audit "$FIX/t")"
case "$out" in
  *'FAIL  skills/queue/SKILL.md gives no last-line template in its closing step'*)
    ok "an unfenced line is not read as the template a session prints" ;;
  *) bad "AC2 — expected the unfenced template to be reported, got: ${out:-<nothing>}" ;;
esac

echo "AC3 — a skill that drops the lastness instruction fails, even with its template intact"
mkfix "$FIX/t"
mutate "$FIX/t/skills/retro/SKILL.md" "s/the very last thing printed/somewhere in the report/" "weaken retro's lastness instruction"
out="$(audit "$FIX/t")"
case "$out" in
  *'FAIL  skills/retro/SKILL.md does not say its hand-off line is the very last thing printed'*)
    ok "a template with no lastness instruction is reported" ;;
  *) bad "AC3 — expected the missing lastness instruction to be reported, got: ${out:-<nothing>}" ;;
esac

echo "AC3 — the phrase must survive on one line, because grep cannot see it across a break"
mkfix "$FIX/t"
mutate "$FIX/t/skills/verify/SKILL.md" "s/the very last thing/the very last\nthing/" "rewrap verify's phrase across a line break"
out="$(audit "$FIX/t")"
case "$out" in
  *'FAIL  skills/verify/SKILL.md does not say its hand-off line is the very last thing printed'*)
    ok "a rewrapped phrase reds, which is the warning this project's CLAUDE.md records" ;;
  *) bad "AC3 — expected the rewrapped phrase to red, got: ${out:-<nothing>}" ;;
esac

echo "AC4 — a skill with no closing step fails rather than being skipped"
mkfix "$FIX/t"
mutate "$FIX/t/skills/prototype/SKILL.md" 's/^## Step 2 — Report/## Step 2 — Handoff/' "retitle prototype's report step"
out="$(audit "$FIX/t")"
case "$out" in
  *'FAIL  skills/prototype/SKILL.md has no closing step titled Report or Verdict'*)
    ok "a missing report step is a named defect, not a silently skipped file" ;;
  *) bad "AC4 — expected the missing report step to be named, got: ${out:-<nothing>}" ;;
esac

echo "AC5 — the rule losing its template fails, so the shape cannot drift per skill"
mkfix "$FIX/t"
mutate "$FIX/t/references/REPORTING.md" '/— next:/d' "delete the canonical template"
out="$(audit "$FIX/t")"
case "$out" in
  *'FAIL  references/REPORTING.md states no hand-off template in a fenced block'*)
    ok "the rule with no template is the reported defect" ;;
  *) bad "AC5 — expected the missing canonical template to be reported, got: ${out:-<nothing>}" ;;
esac

echo "AC5 — the rule losing the no-row case fails; a session holding no ticket still ends on a line"
mkfix "$FIX/t"
mutate "$FIX/t/references/REPORTING.md" '/holds no row/d' "delete the no-row fallback"
out="$(audit "$FIX/t")"
case "$out" in
  *'FAIL  references/REPORTING.md does not say what a session that holds no row puts in the ID slot'*)
    ok "the missing no-row case is reported" ;;
  *) bad "AC5 — expected the missing no-row case to be reported, got: ${out:-<nothing>}" ;;
esac

echo "AC5 — a missing rule file fails loudly rather than passing with nothing to check"
mkfix "$FIX/t"
rm -f "$FIX/t/references/REPORTING.md"
out="$(audit "$FIX/t")"
case "$out" in
  *'FAIL  references/REPORTING.md does not exist'*)
    ok "the absent rule file is the reported defect" ;;
  *) bad "AC5 — expected the missing rule file to be reported, got: ${out:-<nothing>}" ;;
esac

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" = 0 ]
