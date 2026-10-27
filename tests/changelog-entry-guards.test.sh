#!/bin/sh
#
# Guard that no test reads the `## Unreleased` section of the repo's own changelog (0221).
#
# WHY THIS EXISTS. `tools/release --bump` moves every `## Unreleased` entry under the version it
# bumps (0041 AC13), so a check reading the repo's real `## Unreleased` for a ticket's note passes
# only until the first release after that ticket closes — `b63e23c` reddened 0182 AC9 exactly so.
# A note is asserted by locating the entry, under any heading. A fixture CHANGELOG a test builds
# (`$FIX/CHANGELOG.md`, `$CO2/CHANGELOG.md`) never releases, so it is out of reach by construction.
#
# Usage:  tests/changelog-entry-guards.test.sh            self-test, then scan this repo's tests/
#         tests/changelog-entry-guards.test.sh <dir>      scan <dir> only; exit 1 on any hit
#
# Requires: sh, awk, grep. No runner — this project has none.

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
SELF="$ROOT/tests/changelog-entry-guards.test.sh"
SECTION_WORD='Unreleased'

# repo_changelog_unreleased_hits <dir> — `<dir name>/<file>:<line>: <text>` for each line of a
# <dir>/*.test.sh that names the section word and the repo's own changelog: through `$ROOT` in any
# quoting, or as a literal path (bare, `./`, `../`, absolute). A path through any other variable is
# a fixture the test built, and is stripped before the literal-path check.
repo_changelog_unreleased_hits() {
  dir_name="$(basename -- "$1")"
  for f in "$1"/*.test.sh; do
    [ -f "$f" ] || continue
    awk -v word="$SECTION_WORD" -v where="$dir_name/$(basename -- "$f")" '
      index($0, word) == 0 { next }
      {
        line = $0
        if (gsub(/\$\{?ROOT\}?"?\/CHANGELOG\.md/, "", line) > 0) { print where ":" NR ": " $0; next }
        gsub(/\$\{?[A-Za-z_][A-Za-z0-9_]*\}?"?\/CHANGELOG\.md/, "", line)
        if (index(line, "CHANGELOG.md") > 0) print where ":" NR ": " $0
      }' "$f"
  done
}

if [ "$#" -gt 0 ]; then
  HITS="$(repo_changelog_unreleased_hits "$1")"
  if [ -n "$HITS" ]; then printf '%s\n' "$HITS"; fi
  TALLIED=1
  [ -z "$HITS" ]
  exit 0
fi

PASS=0
FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }

FIX="$(mktemp -d)"
cleanup() { rm -rf "$FIX"; }
trap 'announce_abort cleanup' EXIT
trap cleanup INT TERM

# The broken line is assembled, so this file never carries it whole and never trips its own scan.
REPO_CL='$ROOT/CHANGELOG.md'
BROKEN_LINE="UNREL=\"\$(section \"$REPO_CL\" \"$SECTION_WORD\")\""

echo "AC5 — a fixture tests/ holding the b63e23c line is refused, by file:line"
mkdir -p "$FIX/tests"
printf '#!/bin/sh\nset -eu\n%s\n' "$BROKEN_LINE" > "$FIX/tests/broken.test.sh"
if out="$("$SELF" "$FIX/tests")"; then
  bad "0221 AC5 — the scan passes a tests/ reading the repo CHANGELOG's $SECTION_WORD"
elif printf '%s\n' "$out" | grep -qF 'tests/broken.test.sh:3:'; then
  ok "the scan fails and names tests/broken.test.sh:3"
else
  bad "0221 AC5 — the scan fails without naming tests/broken.test.sh:3: $out"
fi

echo "the scan reaches every way of naming the repo's CHANGELOG, and no fixture's"
for form in '"${ROOT}/CHANGELOG.md"' '"$ROOT"/CHANGELOG.md' 'CHANGELOG.md' '../CHANGELOG.md'; do
  rm -f "$FIX/tests"/*.test.sh
  printf 'awk "/%s/" %s\n' "$SECTION_WORD" "$form" > "$FIX/tests/form.test.sh"
  if "$SELF" "$FIX/tests" >/dev/null; then bad "0221 FR4 — the scan passes $SECTION_WORD read from $form"
  else ok "the scan refuses $SECTION_WORD read from $form"; fi
done
for form in '"$FIX/CHANGELOG.md"' '"$CO2"/CHANGELOG.md' '"${WORK}/CHANGELOG.md"'; do
  rm -f "$FIX/tests"/*.test.sh
  printf 'awk "/%s/" %s\n' "$SECTION_WORD" "$form" > "$FIX/tests/form.test.sh"
  if out="$("$SELF" "$FIX/tests")"; then ok "the scan leaves a fixture CHANGELOG, $form, alone"
  else bad "0221 FR4 — the scan refuses a fixture CHANGELOG, $form: $out"; fi
done

echo "AC5 — this repo's tests/ reads no CHANGELOG ## $SECTION_WORD of its own"
REAL_HITS="$(repo_changelog_unreleased_hits "$ROOT/tests")"
if [ -z "$REAL_HITS" ]; then ok "no tests/*.test.sh line reads the repo CHANGELOG's $SECTION_WORD"
else
  while IFS= read -r hit; do bad "0221 FR4 — $hit"; done <<EOF
$REAL_HITS
EOF
fi

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
TALLIED=1
[ "$FAIL" -eq 0 ]
