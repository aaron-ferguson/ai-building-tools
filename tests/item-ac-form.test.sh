#!/bin/sh
#
# State guard: every item's acceptance criteria are in the one form `close` can tick.
#
# WHY THIS EXISTS:
#
# `skills/queue/templates/item.md` states "ONE form: every criterion is a `- [ ] ACn — ` checkbox".
# Six of 102 items were nonetheless captured as a NUMBERED list from a single capture, and `close`'s
# refusal — the guard that exists to catch exactly this — counted only `- ` bullets, so it read them
# as an EMPTY criteria section and closed reporting success with nothing ticked. The counter is
# fixed; this file is the other half, because the counter fires at close time and by then the
# ticket is the last place anyone looks. Catching the form at capture time is what stops it.
#
# WHY IT IS NOT ASSERTED IN backlog-scripts-installed.test.sh: that file deliberately leaves live
# backlog state alone, because a suite assertion over Status or the table goes red on any ticket's
# unrelated close. AC *form* is not volatile in that way — an item's criteria do not change shape
# while other work proceeds, so this guard is quiet until someone writes an item in a shape `close`
# cannot tick, which is the moment it should speak.
#
# SUBJECTS ARE DERIVED, NEVER ENUMERATED (`testing-conventions.md`). A guard listing the items it
# checks is green by construction on the 103rd — which is the one that most needs checking. The
# list comes from the glob, so writing an item is what puts it under the check.
#
# Usage:  tests/item-ac-form.test.sh
#
# Requires: sh, awk. No runner — this project has none.

set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
ITEMS="$ROOT/.claude/backlog/items"
[ -d "$ITEMS" ] || { echo "no items directory at $ITEMS" >&2; exit 2; }

PASS=0
FAIL=0
FIX=""

cleanup() { [ -n "$FIX" ] && rm -rf "$FIX"; return 0; }
trap cleanup EXIT INT TERM

ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }

# Report the offending markers in an item's acceptance-criteria section, one per line, or nothing.
# The marker class matches `close`'s: every list form, so no non-checkbox shape slips past.
offenders() {
  awk '
    /^## / { in_ac = ($0 ~ /^## Acceptance criteria/); next }
    in_ac {
      if ($0 ~ /^[ \t]*$/) next
      if ($0 ~ /^- \[[ xX]\]/) next
      if ($0 ~ /^([-*+]|[0-9]+[.)])[ \t]/) print "    " $0
    }
  ' "$1"
}

# --- AC1 — every OPEN item is in the checkbox form ---------------------------------------------
# A `done` item is exempt, and 0035 is why the exemption exists rather than being a convenience.
# 0035 is the original victim — `close` ticked zero of its eight `- **AC1** —` criteria, closed
# anyway, and reported success in the same words as a real close (which is what bought the
# refusal in the first place). Its form cannot be corrected now: `- [ ]` would claim the criteria
# are pending on a ticket closed in August, and `- [x]` would claim someone checked them, which
# is the precise lie the defect told. So a closed item's shape is a historical record of a defect
# already suffered, not a future silent close, and only OPEN items are under this guard.
echo "AC1 — every open item's criteria are checkboxes close can tick"
checked=0
skipped=0
for item in "$ITEMS"/*.md; do
  [ -f "$item" ] || continue
  case "$(awk -F': *' '/^status:/ { print $2; exit }' "$item")" in
    done) skipped=$((skipped + 1)); continue ;;
  esac
  checked=$((checked + 1))
  bad_lines="$(offenders "$item")"
  if [ -n "$bad_lines" ]; then
    bad "$(basename "$item") — non-checkbox criteria close would read as an empty section:"
    printf '%s\n' "$bad_lines"
  fi
done
[ "$checked" -gt 0 ] || { echo "  FAIL no open items matched the glob — this guard checked nothing" >&2; exit 2; }
ok "$checked open items scanned ($skipped closed, exempt)"

# --- AC2 — the guard can red -------------------------------------------------------------------
# A filter that matches nothing is green precisely when its subject has gone missing
# (`testing-conventions.md`), so the detector is fed the exact defect it exists to catch.
echo "AC2 — the detector reds on the shape it exists to catch"
FIX="$(mktemp -d)"

cat > "$FIX/numbered.md" <<'FIXTURE'
## Acceptance criteria

1. AC1 — a numbered criterion
2. AC2 — and another

## Notes & decisions
FIXTURE
if [ -n "$(offenders "$FIX/numbered.md")" ]; then
  ok "a numbered list is reported"
else
  bad "a numbered list was NOT reported — every case above proves nothing"
fi

cat > "$FIX/plain.md" <<'FIXTURE'
## Acceptance criteria

- **AC1** — a bolded criterion with no box
FIXTURE
if [ -n "$(offenders "$FIX/plain.md")" ]; then
  ok "a plain bullet is reported"
else
  bad "a plain bullet was NOT reported"
fi

cat > "$FIX/good.md" <<'FIXTURE'
## Acceptance criteria

- [ ] AC1 — an unticked criterion
- [x] AC2 — a ticked one

## Notes & decisions

1. A numbered list here is prose, not criteria, and must not be reported.
FIXTURE
if [ -z "$(offenders "$FIX/good.md")" ]; then
  ok "the checkbox form passes, and a list outside the section is not read as criteria"
else
  bad "a correct item was reported — the guard would red on every clean ticket"
fi

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" = 0 ]
