#!/bin/sh
#
# Behavioural guard for skills/queue/templates/park (0242 S9: FR1–FR4, FR6, FR56; AC6, AC7, AC8).
#
# Every stage's *Park what surprised you* step was a by-hand lock, append, commit and unlock, with
# the entry's head shape and the public-repo privacy bar (0118) checked by nobody at that moment.
# `park` is that composition as one call.
#
# As in tests/capture.test.sh, assertions are about the RESULTING STATE, and every refusal is
# asserted on its message AND on both fixture repos being byte-for-byte unchanged.
#
# NO HOME PATH IS WRITTEN LITERALLY IN THIS FILE. The repo is public and tests/measurement.test.sh
# guards every tracked file against one, so the real-shaped samples are ASSEMBLED from pieces, as
# that file's own falsification control does.
#
# Usage:  tests/park.test.sh
#
# Requires: git, sh, awk. No runner — this project has none.

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
# copy-begin: saw-prefix
# A declared copy: tests/declared-copies.test.sh reds unless every copy of this block is identical.
saw()         { printf '%s\n' "$1" | sed '1s/^/         saw: /; 1!s/^/              /'; }
# copy-end: saw-prefix
# copy-begin: saw-on-pass
# A declared copy: tests/declared-copies.test.sh reds unless every copy of this block is identical.
saw_on_pass() { [ -n "${SHOW_MATCHED:-}" ] && saw "$1"; return 0; }
# copy-end: saw-on-pass

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
# The TEMPLATE copies run here, never .tickets/park: a mutation applied to the installed copy lands
# a real diff and reddens nothing.
PARK_SRC="$ROOT/skills/queue/templates/park"
NEXT_SRC="$ROOT/skills/queue/templates/next"
[ -f "$PARK_SRC" ] || { echo "no park script at $PARK_SRC" >&2; exit 2; }

PASS=0
FAIL=0
FIX=""

cleanup() { [ -n "$FIX" ] && rm -rf "$FIX"; return 0; }
trap 'announce_abort cleanup' EXIT
trap cleanup INT TERM

ok()   { PASS=$((PASS + 1)); echo "  ok   — $1"; }
bad()  { FAIL=$((FAIL + 1)); echo "  FAIL — $1"; }

assert_contains() {
  case "$2" in
    *"$3"*) ok "$1"; saw_on_pass "$2" ;;
    *)      bad "$1"; echo "         expected to contain: $3"; saw "$2" ;;
  esac
}
assert_not_contains() {
  case "$2" in
    *"$3"*) bad "$1"; echo "         expected NOT to contain: $3"; saw "$2" ;;
    *)      ok "$1"; saw_on_pass "$2" ;;
  esac
}
assert_eq() {
  if [ "$2" = "$3" ]; then ok "$1"; saw_on_pass "$2"; else
    bad "$1"; echo "         expected exactly: $3"; saw "$2"; fi
}
assert_nonzero() {
  if [ "$2" -ne 0 ]; then ok "$1"; else bad "$1"; saw "wanted any exit but 0
$3"; fi
}

# The real-shaped samples, assembled (see the header). Each is a path a real machine would carry.
U='U'; H='h'
MAC_PATH="/${U}sers/alice/Documents/notes"
LINUX_PATH="/${H}ome/alice/src/app"
SLUG_PATH="-${U}sers-alice-Documents-AI"
REDACTED="/${U}sers/<name>/Documents/notes"

# Every file under a backlog, the lock directory included: a refusal that half-wrote one, or left a
# .lock, changes this.
fingerprint() { (cd "$1/.tickets" && find . -path ./.lock -prune -o -type f -print | sort | xargs cksum; ls -d .lock 2>/dev/null || true); }
commits() { git -C "$1" rev-list --count HEAD; }
TODAY="$(date -u +%Y-%m-%d)"

mkrepo() { # mkrepo <dir> [claude-md-text] — a repo on main holding a backlog with a findings buffer
  mkdir -p "$1/.tickets"
  git -C "$1" init -q -b main
  git -C "$1" config user.email fixture@example.com
  git -C "$1" config user.name fixture
  printf '# config\nnext_id: 1\nfindings_threshold: 20\n' > "$1/.tickets/config.yml"
  printf '# Backlog\n\n| ID | Title | Next | Status | Parent |\n|------|-------|------|--------|--------|\n' > "$1/.tickets/QUEUE.md"
  printf '# Findings\n\nFormat: `- YYYY-MM-DD — **what happened.** why it might matter (pointer: file, item id)`\n\n```\n- 2026-09-05 [->0060] — **what happened.** why\n```\n\n---\n\n- 2026-11-01 — **an older entry.** kept as it is (pointer: x)\n' > "$1/.tickets/FINDINGS.md"
  [ -z "${2:-}" ] || printf '%s\n' "$2" > "$1/CLAUDE.md"
  git -C "$1" add -A
  git -C "$1" commit -q -m fixture
}

fresh() { # fresh [claude-md-for-repo] [claude-md-for-other]
  [ -z "$FIX" ] || rm -rf "$FIX"
  FIX="$(mktemp -d)"
  mkrepo "$FIX/repo" "${1:-}"
  cp "$PARK_SRC" "$NEXT_SRC" "$FIX/repo/.tickets/"
  chmod +x "$FIX/repo/.tickets/park" "$FIX/repo/.tickets/next"
  git -C "$FIX/repo" add -A
  git -C "$FIX/repo" commit -q -m scripts
  mkrepo "$FIX/other" "${2:-}"
}

run() { # run <args...> — the park under test, from the first repo's root; sets RC, OUT, ERR
  if (cd "$FIX/repo" && ./.tickets/park "$@" >"$FIX/out" 2>"$FIX/err"); then RC=0; else RC=$?; fi
  OUT="$(cat "$FIX/out")"; ERR="$(cat "$FIX/err")"
}

PUBLIC_MD='# other

## Profile
- collaboration: solo
- company: none

This repo is public, so no private path reaches it.

## Tests'
PRIVATE_MD='# other

## Profile
- collaboration: solo
- company: none

## Where it lives
This file is public knowledge, but the repo is private.'

# --- AC6 ----------------------------------------------------------------------------------------
echo "0242 AC6 — one line in the header's shape, today's UTC date, one commit naming only FINDINGS.md"
fresh
B="$FIX/repo/.tickets/FINDINGS.md"
cp "$B" "$FIX/before"
before="$(commits "$FIX/repo")"
run "what happened"
assert_eq "exits 0" "$RC" 0
assert_eq "appends exactly one line" "$(wc -l < "$B" | tr -d ' ')" "$(( $(wc -l < "$FIX/before") + 1 ))"
assert_eq "and every line before it is unchanged" "$(head -n "$(wc -l < "$FIX/before")" "$B" | cksum)" "$(cksum < "$FIX/before")"
assert_eq "the line is '- <today, UTC> — what happened'" "$(tail -n 1 "$B")" "- $TODAY — what happened"
assert_contains "./next --findings-list counts it as an entry, by the reader every sweeper uses" \
  "$(cd "$FIX/repo" && ./.tickets/next --findings-list 2>&1 || true)" "FINDINGS.md:$(wc -l < "$B" | tr -d ' ')  - $TODAY — what happened"
assert_contains "and --findings now counts two" "$(cd "$FIX/repo" && ./.tickets/next --findings 2>&1 || true)" "FINDINGS  2 entries;"
assert_eq "makes exactly one commit" "$(commits "$FIX/repo")" "$((before + 1))"
assert_eq "the commit names only FINDINGS.md" \
  "$(git -C "$FIX/repo" show --name-only --format= HEAD)" ".tickets/FINDINGS.md"
assert_contains "the commit carries the trailer" "$(git -C "$FIX/repo" log -1 --format=%B)" "Co-Authored-By: "
assert_eq "prints the line it wrote last" "$(printf '%s\n' "$OUT" | tail -1)" "- $TODAY — what happened"
assert_eq "no .lock is left" "$(ls -d "$FIX/repo/.tickets/.lock" 2>/dev/null || true)" ""
assert_eq "the tree is clean after it" "$(git -C "$FIX/repo" status --porcelain)" ""
run "**bolded head.** why it matters (pointer: tests/park.test.sh)"
assert_eq "a bolded entry is written after the date, outside the bold" \
  "$(tail -n 1 "$B")" "- $TODAY — **bolded head.** why it matters (pointer: tests/park.test.sh)"

echo "0242 FR2 — another session's staged path stays staged and out of the park commit"
fresh
printf 'theirs\n' > "$FIX/repo/other.txt"
git -C "$FIX/repo" add other.txt
run "what happened"
assert_eq "exits 0" "$RC" 0
assert_not_contains "other.txt is absent from the park commit" \
  "$(git -C "$FIX/repo" show --name-only --format= HEAD)" "other.txt"
assert_eq "and is still staged afterwards" "$(git -C "$FIX/repo" diff --cached --name-only)" "other.txt"

# --- AC7 ----------------------------------------------------------------------------------------
echo "0242 AC7 — --repo lands the entry and its commit in the second repo, and the first is unchanged"
fresh
fp="$(fingerprint "$FIX/repo")"; before="$(commits "$FIX/repo")"; before_o="$(commits "$FIX/other")"
run "about a skill" --repo "$FIX/other"
assert_eq "exits 0" "$RC" 0
assert_eq "the entry is the second repo's last buffer line" \
  "$(tail -n 1 "$FIX/other/.tickets/FINDINGS.md")" "- $TODAY — about a skill"
assert_eq "one commit in the second repo" "$(commits "$FIX/other")" "$((before_o + 1))"
assert_eq "naming only its FINDINGS.md" \
  "$(git -C "$FIX/other" show --name-only --format= HEAD)" ".tickets/FINDINGS.md"
assert_eq "the first repo's backlog is byte-identical" "$(fingerprint "$FIX/repo")" "$fp"
assert_eq "and the first repo has no new commit" "$(commits "$FIX/repo")" "$before"
assert_eq "and the first repo's tree is clean" "$(git -C "$FIX/repo" status --porcelain)" ""
assert_eq "no .lock is left in the second repo" "$(ls -d "$FIX/other/.tickets/.lock" 2>/dev/null || true)" ""
run "from a subdirectory" --repo "$FIX/other/.tickets"
assert_eq "a --repo inside the checkout resolves to its root's backlog" \
  "$(tail -n 1 "$FIX/other/.tickets/FINDINGS.md")" "- $TODAY — from a subdirectory"

# --- AC8 ----------------------------------------------------------------------------------------
echo "0242 AC8 — a public second checkout refuses an entry holding a real home path, by shape"
fresh "" "$PUBLIC_MD"
for case_ in "mac:$MAC_PATH:macOS home path" "linux:$LINUX_PATH:Linux home path" "slug:$SLUG_PATH:dash form"; do
  label="${case_%%:*}"; rest="${case_#*:}"; sample="${rest%%:*}"; shape="${rest#*:}"
  fp="$(fingerprint "$FIX/repo")"; fpo="$(fingerprint "$FIX/other")"
  before="$(commits "$FIX/repo")"; before_o="$(commits "$FIX/other")"
  run "**leak.** the log showed $sample in it" --repo "$FIX/other"
  assert_nonzero "$label: exits non-zero" "$RC" "$ERR"
  assert_contains "$label: names the failing shape" "$ERR" "$shape"
  assert_contains "$label: and the redaction that passes" "$ERR" "<name>"
  assert_eq "$label: writes nothing in the second repo" "$(fingerprint "$FIX/other")" "$fpo"
  assert_eq "$label: nor in the first" "$(fingerprint "$FIX/repo")" "$fp"
  assert_eq "$label: and commits nothing in either" "$(commits "$FIX/repo") $(commits "$FIX/other")" "$before $before_o"
done
before_o="$(commits "$FIX/other")"
run "**leak.** the log showed $REDACTED in it" --repo "$FIX/other"
assert_eq "the same entry with the name redacted exits 0" "$RC" 0
assert_eq "and is written" "$(tail -n 1 "$FIX/other/.tickets/FINDINGS.md")" "- $TODAY — **leak.** the log showed $REDACTED in it"
assert_eq "and committed there" "$(commits "$FIX/other")" "$((before_o + 1))"
assert_contains "and the report says it was screened" "$OUT" "screened (public per its CLAUDE.md profile)"

echo "0242 FR6 — the screen applies where the destination is public, and only there"
fresh "$PUBLIC_MD" "$PRIVATE_MD"
run "the log showed $LINUX_PATH" --repo "$FIX/other"
assert_eq "a private destination (public said only outside ## Profile) takes the path" "$RC" 0
assert_eq "and writes it" "$(tail -n 1 "$FIX/other/.tickets/FINDINGS.md")" "- $TODAY — the log showed $LINUX_PATH"
assert_not_contains "and does not claim a screen" "$OUT" "screened"
fp="$(fingerprint "$FIX/repo")"
run "the log showed $LINUX_PATH"
assert_nonzero "with no --repo, a public local backlog is screened too" "$RC" "$ERR"
assert_eq "and changes nothing" "$(fingerprint "$FIX/repo")" "$fp"
fresh
run "the log showed $MAC_PATH"
assert_eq "a destination with no CLAUDE.md is not screened" "$RC" 0

echo "0242 FR6 — the screen's pattern is the tracked-tree guard's, byte for byte"
pat_line="$(grep '^HOME_PATH_PAT=' "$PARK_SRC" || true)"
assert_eq "park's HOME_PATH_PAT is tests/measurement.test.sh's" \
  "$pat_line" "$(grep '^HOME_PATH_PAT=' "$ROOT/tests/measurement.test.sh" || echo 'no HOME_PATH_PAT in measurement.test.sh')"

# --- FR3 ----------------------------------------------------------------------------------------
echo "0242 FR3 — malformed input is refused before the lock, and changes nothing"
fresh
fp="$(fingerprint "$FIX/repo")"; fpo="$(fingerprint "$FIX/other")"; before="$(commits "$FIX/repo")"
refused() { # refused <label> <expected stderr> <args...>
  label="$1"; want="$2"; shift 2
  run "$@"
  assert_nonzero "$label: exits non-zero" "$RC" "$ERR"
  assert_contains "$label: names what is wrong" "$ERR" "$want"
  assert_eq "$label: changes nothing and leaves no .lock" "$(fingerprint "$FIX/repo") $(fingerprint "$FIX/other")" "$fp $fpo"
  assert_eq "$label: commits nothing" "$(commits "$FIX/repo")" "$before"
}
refused "an empty entry" "the entry is empty" "   "
refused "a two-line entry" "line break" "one
two"
refused "an entry carrying its own date" "starts with a date" "2026-11-27 — dated twice"
refused "an entry carrying a bolded date" "starts with a date" "**2026-11-27 — dated twice**"
refused "an entry carrying a head token" "head token" "[->0060] — **a sweeper's mark**"
refused "an unknown argument" "unknown argument '--into'" "x" --into 0001
refused "a --repo that is no directory" "names no directory" "x" --repo "$FIX/nowhere"
mkdir -p "$FIX/plain"
refused "a --repo that is no git checkout" "not in a git checkout" "x" --repo "$FIX/plain"
git -C "$FIX/plain" init -q -b main
refused "a --repo holding no backlog" "holds no backlog" "x" --repo "$FIX/plain"
rm -rf "$FIX/plain"
run
assert_eq "no argument at all prints usage and exits 2" "$RC" 2
assert_contains "naming the form" "$ERR" "usage: park"
run --help
assert_eq "--help exits 0" "$RC" 0
assert_contains "--help names --repo" "$OUT" "--repo"

echo "0242 FR3 — a buffer ./next could not count from, or one already dirty, is refused"
fresh
B="$FIX/repo/.tickets/FINDINGS.md"
grep -vx -- '---' "$B" > "$FIX/t" && cat "$FIX/t" > "$B"
git -C "$FIX/repo" commit -q -m norule -- .tickets/FINDINGS.md
fp="$(fingerprint "$FIX/repo")"; fpo="$(fingerprint "$FIX/other")"; before="$(commits "$FIX/repo")"
refused "a buffer with no --- rule" "has no '---' rule" "x"
fresh
printf -- '- %s — **theirs, uncommitted.**\n' "$TODAY" >> "$FIX/repo/.tickets/FINDINGS.md"
fp="$(fingerprint "$FIX/repo")"; fpo="$(fingerprint "$FIX/other")"; before="$(commits "$FIX/repo")"
refused "a buffer with another session's uncommitted line" "holds uncommitted changes" "x"

# --- FR56 ---------------------------------------------------------------------------------------
echo "0242 FR56 — off the destination's shared branch, park refuses up front"
fresh
git -C "$FIX/repo" switch -q -c side
fp="$(fingerprint "$FIX/repo")"; fpo="$(fingerprint "$FIX/other")"; before="$(commits "$FIX/repo")"
refused "this checkout on another branch" "the backlog is shared on 'main'" "x"
git -C "$FIX/repo" switch -q main
git -C "$FIX/other" switch -q -c side
before_o="$(commits "$FIX/other")"
run "x" --repo "$FIX/other"
assert_nonzero "the --repo destination on another branch: exits non-zero" "$RC" "$ERR"
assert_contains "and names the destination's branch" "$ERR" "this checkout is on 'side'"
assert_eq "and commits nothing there" "$(commits "$FIX/other")" "$before_o"

# --- FR1 ----------------------------------------------------------------------------------------
echo "0242 FR1 — a busy lock is retried, then refused, and never broken"
fresh
mkdir "$FIX/repo/.tickets/.lock"
printf 'claim 0001\n' > "$FIX/repo/.tickets/.lock/held-by"
before="$(commits "$FIX/repo")"
if (cd "$FIX/repo" && BACKLOG_LOCK_TRIES=2 ./.tickets/park "x" >"$FIX/out" 2>"$FIX/err"); then RC=0; else RC=$?; fi
ERR="$(cat "$FIX/err")"
assert_nonzero "exits non-zero" "$RC" "$ERR"
assert_contains "names the holder" "$ERR" "locked by: claim 0001"
assert_eq "the other session's lock is still there" "$(cat "$FIX/repo/.tickets/.lock/held-by")" "claim 0001"
assert_eq "and nothing was committed" "$(commits "$FIX/repo")" "$before"
rm -rf "$FIX/repo/.tickets/.lock"
( sleep 1; rm -rf "$FIX/repo/.tickets/.lock" ) &
mkdir "$FIX/repo/.tickets/.lock"
if (cd "$FIX/repo" && BACKLOG_LOCK_TRIES=5 ./.tickets/park "after the wait" >"$FIX/out" 2>"$FIX/err"); then RC=0; else RC=$?; fi
wait
assert_eq "a lock released within the retries is taken, and the park lands" "$RC" 0
assert_eq "with its line" "$(tail -n 1 "$FIX/repo/.tickets/FINDINGS.md")" "- $TODAY — after the wait"

echo
echo "park: $PASS passed, $FAIL failed"
TALLIED=1
[ "$FAIL" -eq 0 ]
