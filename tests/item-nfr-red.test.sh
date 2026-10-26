#!/bin/sh
#
# State guard: every filled NFR row on an item at develop or verify says how it would red (0183).
#
# WHY THIS EXISTS:
#
# An NFR row can name a guard that cannot possibly test it, and a filename that exists reads as a
# discharged answer. `0176`'s Documentation row required that a fallback "is not restated in the stage
# skills it dispatches" and named `tests/citations.test.sh` to red it — a file that resolves citation
# targets and has no duplication check, so no restatement could ever red it. The row was true at
# verify and pinned by nothing, caught only because the verifier read the guard.
#
# WHAT IS CHECKED, AND WHAT IS DELIBERATELY NOT. A *How it would red* cell fails here when it is
# EMPTY, or when it is a BARE FILE REFERENCE — nothing left once backticked spans and punctuation are
# removed. That shape was the whole observed defect class (design 0183: 3 of 4 file-only rows of 51)
# and is decidable from the cell alone. Whether a named case, criterion or mutation actually reds on
# THAT requirement is judgement, and stays `verify` Step 4's: it mutates the requirement and records a
# check that stays green as unguarded. Rejected, with reasons in 0183's notes: a path-exists check (an
# item at develop names test files its build creates), resolving `ACn` against the item's criteria
# (`ac_digest` already refuses a renumbering at close), and any word-overlap relatedness heuristic.
#
# SCOPE FLOOR, as tests/item-ac-form.test.sh: items at `next: develop` or `next: verify`. An item at
# design or queue has not been specified yet, and a done item is history — rewriting its cells would
# claim a check that never ran when it closed.
#
# Usage:  tests/item-nfr-red.test.sh
#
# Requires: sh, awk. No runner — this project has none.

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
ITEMS="$ROOT/.claude/backlog/items"
[ -d "$ITEMS" ] || { echo "no items directory at $ITEMS" >&2; exit 2; }

PASS=0
FAIL=0
FIX=""

cleanup() { [ -n "$FIX" ] && rm -rf "$FIX"; return 0; }
trap 'announce_abort cleanup' EXIT
trap cleanup INT TERM

ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }

# nfr_misses <item> — one line per filled NFR row whose *How it would red* cell is empty or a bare
# file reference: "<id> — <dimension>: <empty|bare file reference>". Nothing when every row answers.
#
# Backticked spans are replaced with a placeholder BEFORE the row is split on `|`, so a pipe inside
# a span — `'playwright test|vitest run'` — cannot shift the columns. The placeholder is then removed
# with the punctuation, which is what makes a cell holding only spans read as a bare reference.
#
# Columns are found by their HEADER, never by position: items written before 0107 carry a
# three-column table whose fourth cell is the Convention, and read by position every one of them
# reports its convention filename as a bare answer. A table with no *How it would red* column has
# nothing for this guard to read; nfr_has_red_column below lets the scan count those rather than
# pass them silently.
nfr_misses() {
  awk '
    /^id:/ && id == "" { v = $0; sub(/^id:[ \t]*/, "", v); gsub(/"/, "", v); id = v }
    /^## / { in_nfr = ($0 ~ /^## Non-functional requirements/); ri = 0; next }
    !in_nfr || $0 !~ /^\|/ { next }
    {
      row = $0
      gsub(/`[^`]*`/, "\001", row)
      n = split(row, c, "|")
      for (k = 1; k <= n; k++) gsub(/^[ \t]+|[ \t]+$/, "", c[k])
      if (c[2] == "Dimension") {
        ri = 0; qi = 0
        for (k = 1; k <= n; k++) {
          if (c[k] == "How it would red") ri = k
          if (c[k] == "Requirement for this item") qi = k
        }
        next
      }
      if (!ri || !qi) next
      dim = c[2]; req = c[qi]; red = c[ri]
      if (dim ~ /^-+$/ || req == "") next
      bare = red
      gsub(/[ \t]/, "", red)
      if (red == "") { print id " — " dim ": empty"; next }
      gsub(/\001/, "", bare); gsub(/—|–/, "", bare); gsub(/[[:punct:][:space:]]/, "", bare)
      if (bare == "") print id " — " dim ": bare file reference"
    }
  ' "$1"
}

# True when the item's NFR table carries the *How it would red* column 0107 added.
nfr_has_red_column() {
  grep -q '^| *Dimension *|.*| *How it would red *|' "$1"
}

# True when an item sits at a stage whose NFR table is a commitment someone is building or checking.
nfr_scanned() {
  case "$(awk -F': *' '/^next:/ { print $2; exit }' "$1")" in
    develop|verify) return 0 ;;
    *) return 1 ;;
  esac
}

# The stage floor and the matcher composed — what the live scan runs, so the fixtures can run it too.
scanned_misses() {
  nfr_scanned "$1" || return 0
  nfr_misses "$1"
}

# --- the live backlog ----------------------------------------------------------------------------
echo "AC7 — every filled NFR row on an item at develop or verify names how it would red"
checked=0
pre0107=0
for item in "$ITEMS"/*.md; do
  [ -f "$item" ] || continue
  nfr_scanned "$item" || continue
  nfr_has_red_column "$item" || { pre0107=$((pre0107 + 1)); continue; }
  checked=$((checked + 1))
  misses="$(nfr_misses "$item")"
  if [ -n "$misses" ]; then
    OLDIFS="$IFS"; IFS='
'
    for m in $misses; do bad "$m — name the case, criterion or mutation, or write 'prose only — no artifact yet'"; done
    IFS="$OLDIFS"
  fi
done
[ "$checked" -gt 0 ] || { echo "  FAIL no item at develop or verify matched the glob — this guard checked nothing" >&2; exit 2; }
# Named rather than passed over: an item with no column has answered nothing, and a pass line hiding
# the count reads as "every open row names how it would red".
ok "$checked items at develop or verify scanned ($pre0107 more carry the pre-0107 table with no How it would red column)"

# --- the matcher can red, and passes what it should ------------------------------------------------
# Fixture ids are unmistakably not backlog rows, so a failure line can never be read as a real ticket.
FIX="$(mktemp -d)"

# nfr_fixture <path> <id> <next> <how-it-would-red cell>
nfr_fixture() {
  cat > "$1" <<FIXTURE
---
id: "$2"
next: $3
status: ready
---

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Documentation | The rule is stated once | $4 | \`documentation-conventions.md\` |
| Security | | | \`security-conventions.md\` |

## Acceptance criteria
FIXTURE
}

echo "AC1 — a bare file reference at develop is reported with the item id and the dimension"
nfr_fixture "$FIX/bare.md" FIXTURE-BARE develop '`tests/citations.test.sh`'
out="$(scanned_misses "$FIX/bare.md")"
case "$out" in
  *"FIXTURE-BARE — Documentation: bare file reference"*) ok "AC1/AC3 — a bare file cell is reported, naming the item and the dimension" ;;
  *) bad "AC1/AC3 — a bare file cell was not reported: ${out:-<nothing>}" ;;
esac

echo "AC2 — an empty cell at verify is reported with the item id and the dimension"
nfr_fixture "$FIX/empty.md" FIXTURE-EMPTY verify ''
out="$(scanned_misses "$FIX/empty.md")"
case "$out" in
  *"FIXTURE-EMPTY — Documentation: empty"*) ok "AC2 — an empty cell is reported, naming the item and the dimension" ;;
  *) bad "AC2 — an empty cell was not reported: ${out:-<nothing>}" ;;
esac

echo "AC4 — a cell naming a case, criterion, mutation or the prose form is not reported"
i=0
for cell in \
  'AC8 — `tests/skill-size.test.sh` red' \
  'AC1' \
  'prose only — no artifact yet' \
  '`tests/falsifiable-acs.test.sh`, case *AC1 — the preamble requires it*'
do
  i=$((i + 1))
  nfr_fixture "$FIX/good-$i.md" "FIXTURE-GOOD-$i" develop "$cell"
  out="$(scanned_misses "$FIX/good-$i.md")"
  if [ -z "$out" ]; then
    ok "AC4 — not reported: $cell"
  else
    bad "AC4 — a named answer was reported as a miss: $cell — $out"
  fi
done

echo "AC4 — a pipe inside a backticked span does not shift the columns"
nfr_fixture "$FIX/pipe.md" FIXTURE-PIPE develop '`pgrep -f '"'"'playwright test|vitest run'"'"'` stays empty'
out="$(scanned_misses "$FIX/pipe.md")"
if [ -z "$out" ]; then
  ok "a pipe inside a span is read as part of the cell"
else
  bad "a pipe inside a span split the row: $out"
fi

echo "Columns by header — a pre-0107 three-column table is not read by position"
cat > "$FIX/pre0107.md" <<'FIXTURE'
---
id: "FIXTURE-PRE0107"
next: develop
---

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The rule is stated once | `documentation-conventions.md` |
FIXTURE
if [ -z "$(scanned_misses "$FIX/pre0107.md")" ] && ! nfr_has_red_column "$FIX/pre0107.md"; then
  ok "a three-column table yields no misses and is counted as having no column"
else
  bad "a three-column table was read by position, or counted as having the column"
fi

echo "Scope floor — design, queue and done items are not read; the floor does not swallow the scan"
for stage in design queue ''; do
  nfr_fixture "$FIX/at-$stage.md" "FIXTURE-AT-${stage:-done}" "$stage" '`tests/citations.test.sh`'
  if [ -z "$(scanned_misses "$FIX/at-$stage.md")" ]; then
    ok "an item at ${stage:-done (empty next)} is not scanned"
  else
    bad "an item at ${stage:-done (empty next)} was scanned"
  fi
done

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
TALLIED=1
[ "$FAIL" = 0 ]
