#!/bin/sh
#
# Size guard for skills/*/SKILL.md (0021).
#
# Every skill file loads whole into any session that invokes it, and re-loads on re-invocation,
# so length is rent paid repeatedly. CONVENTIONS_CORE.md sets the rule; this file makes it a gate.
#
# The ceiling is ABSOLUTE — bytes, not a percentage of a baseline. 0021's first pass could not
# close because its target was 25% off a baseline that eight sibling tickets moved 18% while it
# waited. A percentage of a moving baseline is un-auditable; a byte count is not.
#
# Measured in bytes with `wc -c`, never a character count: these files are full of multi-byte
# em-dashes and a decoded len() undercounted one of them by ~46.
#
# EXEMPTIONS: a file that cannot reach the ceiling without dropping a rule is exempt at a recorded
# floor, and that is a pass. "No rule is dropped" outranks the ceiling. An exemption is a floor,
# not a waiver — the file must still be at or under the size the exemption records, and an exempt
# file that comes back under the ceiling fails so the stale entry gets removed. The evidence each
# exemption owes (its floor, and every surviving section with its byte count) lives in the ticket
# that granted it, named in the entry.
#
# Usage:  tests/skill-size.test.sh
#
# Requires: sh, wc, awk. No runner — this project has none.

set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

CEILING=20190          # ~5,000 tokens at the 4.038 bytes/token ratio this repo measured

# exemption_floor <relative-path> — echoes the exempt floor in bytes, or nothing if not exempt.
# One line per exemption, naming the ticket that granted it.
exemption_floor() {
  case "$1" in
    skills/prototype/SKILL.md) echo 23394 ;;   # granted by 0021
    skills/queue/SKILL.md)     echo 21789 ;;   # granted by 0021
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

# offenders <root> <floor-lookup-fn> — prints one line per file breaching the ceiling or its
# exemption, nothing when every file is compliant. The lookup is a parameter so the fixture cases
# below can exercise the exemption path whether or not any real file is currently exempt.
offenders() {
  root="$1"
  lookup="${2:?offenders needs a floor-lookup function}"
  for f in "$root"/skills/*/SKILL.md; do
    [ -f "$f" ] || continue
    rel="skills/$(basename "$(dirname "$f")")/SKILL.md"
    bytes="$(wc -c < "$f" | tr -d ' ')"
    floor="$("$lookup" "$rel")"
    if [ -n "$floor" ]; then
      if [ "$bytes" -le "$CEILING" ]; then
        echo "$rel is $bytes bytes, under the $CEILING ceiling — remove its stale exemption"
      elif [ "$bytes" -gt "$floor" ]; then
        echo "$rel is $bytes bytes, over its exempt floor of $floor"
      fi
    elif [ "$bytes" -gt "$CEILING" ]; then
      echo "$rel is $bytes bytes, over the $CEILING ceiling by $((bytes - CEILING))"
    fi
  done
}

echo "AC1 — every skill file is at or under the ceiling, or exempt at a recorded floor"
found="$(offenders "$ROOT" exemption_floor)"
if [ -z "$found" ]; then
  # name the exempt files rather than reporting a clean sweep: an exemption is a known cost, and a
  # pass line that hides it reads as "everything is under the ceiling" when two files are not.
  exempt=""
  for f in "$ROOT"/skills/*/SKILL.md; do
    rel="skills/$(basename "$(dirname "$f")")/SKILL.md"
    [ -n "$(exemption_floor "$rel")" ] && exempt="$exempt $rel"
  done
  if [ -n "$exempt" ]; then
    ok "within the ceiling, except at a recorded floor:$exempt"
  else
    ok "every skill file within the ceiling, none exempt"
  fi
else
  OLDIFS="$IFS"; IFS='
'
  for line in $found; do bad "$line"; done   # in this shell, so each breach counts
  IFS="$OLDIFS"
fi

# The cases below prove the guard can fail. A guard only ever seen passing is indistinguishable
# from one wired to nothing, so each feeds it the exact breach it exists to catch.

echo "AC4 — the guard fails on a padded file, and names it"
FIX="$(mktemp -d)"
mkdir -p "$FIX/skills/padded"
# Start from a compliant file so the only thing under test is the padding.
SMALLEST="$(ls -S "$ROOT"/skills/*/SKILL.md | tail -1)"
cp "$SMALLEST" "$FIX/skills/padded/SKILL.md"
awk 'BEGIN { while (i++ < 30000) printf "x" }' >> "$FIX/skills/padded/SKILL.md"
padded="$(offenders "$FIX" exemption_floor)"
case "$padded" in
  *"skills/padded/SKILL.md is "*"over the $CEILING ceiling"*)
    ok "padded file reported, named, with its overage" ;;
  "") bad "AC4 — padded file was NOT reported; the guard is wired to nothing" ;;
  *)  bad "AC4 — reported something else: $padded" ;;
esac

echo "AC4 — the guard passes on an unpadded copy of the same tree"
rm -rf "$FIX/skills/padded"
mkdir -p "$FIX/skills/plain"
cp "$SMALLEST" "$FIX/skills/plain/SKILL.md"
if [ -z "$(offenders "$FIX" exemption_floor)" ]; then
  ok "compliant copy reported nothing"
else
  bad "AC4 — compliant copy was reported: $(offenders "$FIX" exemption_floor)"
fi

echo "FR6 — the exemption path is wired in both directions"
exemption_floor_fixture() { case "$1" in skills/exempt/SKILL.md) echo 25000 ;; *) return 0 ;; esac; }

rm -rf "$FIX/skills/plain"
mkdir -p "$FIX/skills/exempt"
cp "$SMALLEST" "$FIX/skills/exempt/SKILL.md"
awk 'BEGIN { while (i++ < 14000) printf "x" }' >> "$FIX/skills/exempt/SKILL.md"   # over ceiling, under floor
out="$(offenders "$FIX" exemption_floor_fixture)"
if [ -z "$out" ]; then
  ok "an exempt file over the ceiling but under its floor passes"
else
  bad "FR6 — exempt file within its floor was reported: $out"
fi

awk 'BEGIN { while (i++ < 5000) printf "x" }' >> "$FIX/skills/exempt/SKILL.md"    # now over the floor
out="$(offenders "$FIX" exemption_floor_fixture)"
case "$out" in
  *"over its exempt floor of 25000"*) ok "an exempt file over its floor fails" ;;
  *) bad "FR6 — exempt file over its floor was not reported: ${out:-<nothing>}" ;;
esac

cp "$SMALLEST" "$FIX/skills/exempt/SKILL.md"                                      # back under the ceiling
out="$(offenders "$FIX" exemption_floor_fixture)"
case "$out" in
  *"remove its stale exemption"*) ok "an exemption that is no longer needed fails" ;;
  *) bad "FR6 — stale exemption was not reported: ${out:-<nothing>}" ;;
esac

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" = 0 ]
