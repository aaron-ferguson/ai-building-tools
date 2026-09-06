#!/bin/sh
#
# Argument-substitution guard for skill instruction files.
#
# WHY THIS EXISTS:
#
# A `$` immediately followed by a digit in a skill's prose is replaced by that skill's invocation
# argument before the session ever sees the file. Reported 2026-09-03: `/verify 0085` delivered
# skills/verify/SKILL.md's cost sentence as "a `verify` turn is the suite's cheapest at 0085.0946
# and 97,965 context tokens, against a baseline 0085.1203", where the file on disk reads $0.0946
# and $0.1203. Nothing in the delivered text marks the substitution, so the session reads two
# corrupted figures as the file's own -- and both sit in the one paragraph that justifies that
# stage's rigour.
#
# The exposure was not one file. Every stage skill opens on a measured cost sentence, and the
# shared "One skill per session" preamble carries two more figures into design, prototype, queue
# and retro, so all six instruction files were affected at once. Money is written `USD 0.0946`
# here for that reason, and this guard is what keeps it that way: the defect is invisible in the
# repo -- the file on disk is correct, every figure resolves, and only the delivered copy is wrong.
#
# WHAT IT CHECKS, AND WHAT EACH CHECK CANNOT SEE:
#
#   sweep       every `skills/**/*.md` is matched for `$` followed by a digit, and each hit is
#               reported with its file, line number and the text. Derived from `find`, not from a
#               hand-written list, so a skill added later is under the check the day it lands
#               (testing-conventions.md, a guard that enumerates its own subjects cannot notice
#               a new one).
#
#   Blind spots, both of which are the reason the rule is written as an absence rather than as a
#   format:
#     - It cannot see the substitution itself. Nothing in this repo can: the corruption happens in
#       the harness between the file and the session, so the only reachable property is that no
#       `$<digit>` is present to be substituted. A future harness that stops substituting would
#       leave this guard passing and pointless rather than failing.
#     - `$0` is the digit the reported case confirms. The others are covered because the mechanism
#       is positional argument substitution, not because each has been observed -- `$15.11` reaches
#       the file through `$1`. That is an inference, and it is why the rule bans the whole class
#       rather than the one confirmed character.
#
# The rule is an absence, so it is anchored to the STATE (no `$<digit>` in the tree) and never to
# vocabulary such as the word "USD" -- correct prose is free to discuss dollars without carrying
# one (testing-conventions.md, a negative assertion anchors to a state).
#
# Every fixture case below runs against an AUTHORED tree, never a copy of skills/
# (testing-conventions.md, the fixture rule).
#
# Usage:  tests/money-in-skill-prose.test.sh
#
# Requires: sh, find, grep, sed. No runner -- this project has none.

set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

PASS=0
FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }

FIX=""
cleanup() { [ -n "$FIX" ] && rm -rf "$FIX"; return 0; }
trap cleanup EXIT INT TERM

# audit <root> -- every offending line in that tree's skill markdown, then a COUNT line.
# Written to return 0 on the clean path: `[ -n "$x" ] && echo ...` as the last statement of a
# function exits non-zero when the test is false, which `set -e` turns into a truncated audit for
# every caller -- the guard reporting a partial result exactly when nothing is wrong
# (tests/reference-size.test.sh records the same trap).
audit() {
  root="${1:?audit needs a tree root}"
  n=0

  if [ ! -d "$root/skills" ]; then
    echo "FAIL  $root/skills does not exist -- the tree this guard covers has moved"
    echo "COUNT 0 files"
    return 0
  fi

  files="$(find "$root/skills" -name '*.md' | sort)"
  for f in $files; do
    n=$((n+1))
    hits="$(grep -n '\$[0-9]' "$f" || true)"
    [ -z "$hits" ] && continue
    OLDIFS="$IFS"; IFS='
'
    for h in $hits; do
      echo "FAIL  ${f#$root/}:${h%%:*} carries a \$ before a digit, which the harness replaces with the invocation argument"
    done
    IFS="$OLDIFS"
  done

  echo "COUNT $n files"
  return 0
}

# ---------------------------------------------------------------------------
# The shipped tree
# ---------------------------------------------------------------------------

echo "AC1 -- no skill instruction file carries a \$ before a digit"
out="$(audit "$ROOT")"
counts="$(printf '%s\n' "$out" | grep '^COUNT ' || true)"
defects="$(printf '%s\n' "$out" | grep '^FAIL ' || true)"
if [ -z "$defects" ]; then
  ok "no defects across ${counts#COUNT }"
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
  mkdir -p "$dir/skills/alpha" "$dir/skills/beta/templates"
  cat > "$dir/skills/alpha/SKILL.md" <<'FIXTURE'
# Fixture skill alpha

Measured: a turn costs USD 0.1044 against a baseline USD 0.1203.
FIXTURE
  cat > "$dir/skills/beta/SKILL.md" <<'FIXTURE'
# Fixture skill beta

The run came to USD 15.11 in total, and the dollar figures are all in MEASUREMENT.md.
FIXTURE
  cat > "$dir/skills/beta/templates/item.md" <<'FIXTURE'
# Fixture template

No money here at all.
FIXTURE
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

echo "AC1 -- the fixture tree passes clean, so every red below is the mutation and not the fixture"
mkfix "$FIX/t"
out="$(audit "$FIX/t")"
case "$out" in
  *'FAIL '*) bad "the unmutated fixture already fails: $out" ;;
  *) ok "the unmutated fixture is clean" ;;
esac

echo "AC2 -- a cost figure written with a dollar sign is reported, with its file and line"
mkfix "$FIX/t"
mutate "$FIX/t/skills/alpha/SKILL.md" 's/USD 0\.1044/$0.1044/' "restore alpha's leading dollar sign"
out="$(audit "$FIX/t")"
case "$out" in
  *'FAIL  skills/alpha/SKILL.md:3 carries a $ before a digit'*)
    case "$out" in
      *'skills/beta/SKILL.md'*) bad "AC2 -- an untouched skill was reported too: $out" ;;
      *) ok "the offending file and line are named, and only that one" ;;
    esac ;;
  *) bad "AC2 -- expected the dollar figure to be named, got: ${out:-<nothing>}" ;;
esac

echo "AC3 -- \$1 is caught as well as \$0; the ban is the class, not the one confirmed digit"
mkfix "$FIX/t"
mutate "$FIX/t/skills/beta/SKILL.md" 's/USD 15\.11/$15.11/' "restore beta's \$1-prefixed figure"
out="$(audit "$FIX/t")"
case "$out" in
  *'FAIL  skills/beta/SKILL.md:3 carries a $ before a digit'*)
    ok "a figure reached through \$1 reds, not only one reached through \$0" ;;
  *) bad "AC3 -- expected the \$1-prefixed figure to red, got: ${out:-<nothing>}" ;;
esac

echo "AC4 -- a template markdown file is covered, not just SKILL.md"
mkfix "$FIX/t"
mutate "$FIX/t/skills/beta/templates/item.md" 's/No money here at all\./Budget: $5 per run./' "put a dollar figure in a template"
out="$(audit "$FIX/t")"
case "$out" in
  *'FAIL  skills/beta/templates/item.md:3 carries a $ before a digit'*)
    ok "every skill markdown is swept, not only the instruction file" ;;
  *) bad "AC4 -- expected the template to be reported, got: ${out:-<nothing>}" ;;
esac

echo "AC5 -- a skill added later is covered, because the file list is derived and not hand-written"
mkfix "$FIX/t"
mkdir -p "$FIX/t/skills/gamma"
printf '# Fixture skill gamma\n\nIt cost $9.99.\n' > "$FIX/t/skills/gamma/SKILL.md"
out="$(audit "$FIX/t")"
case "$out" in
  *'FAIL  skills/gamma/SKILL.md:3 carries a $ before a digit'*)
    ok "a skill that did not exist when this guard was written is under it" ;;
  *) bad "AC5 -- expected the new skill to be swept, got: ${out:-<nothing>}" ;;
esac

echo "AC6 -- the word USD is not what is asserted; prose may discuss dollars without carrying one"
mkfix "$FIX/t"
mutate "$FIX/t/skills/alpha/SKILL.md" 's/USD 0\.1044/a tenth of a cent/' "remove a USD marker without adding a dollar sign"
out="$(audit "$FIX/t")"
case "$out" in
  *'FAIL '*) bad "AC6 -- removing the word USD reported a defect; the rule is anchored to vocabulary, not state: $out" ;;
  *) ok "dropping the word USD is not a defect, because the rule is the absence of \$<digit>" ;;
esac

echo "AC7 -- a missing skills tree fails loudly rather than passing with nothing to check"
mkfix "$FIX/t"
rm -rf "$FIX/t/skills"
out="$(audit "$FIX/t")"
case "$out" in
  *'FAIL '*'/skills does not exist'*) ok "the absent tree is the reported defect, not an empty clean sweep" ;;
  *) bad "AC7 -- expected the missing tree to be reported, got: ${out:-<nothing>}" ;;
esac

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" = 0 ]
