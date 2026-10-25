#!/bin/sh
#
# Guard for 0169: every tests/*.test.sh announces an abort instead of exiting silently.
#
# Under `set -eu` a file that dies mid-run prints the passes it reached and no tally, so a reader
# sees a short green list and nothing saying the run ended early — and a death with status 0
# (0119's collided self-mutating guard) reads as a pass to the suite loop as well. There is no
# shared runner to notice the missing tally, so each file announces its own.
#
# A suite here is self-contained and sources nothing (`CLAUDE.md`), so the announcing block is
# copied into every file rather than sourced, and this guard is what keeps the copies one
# definition: each must be byte-identical to the block in this file.
#
# Three parts, one per criterion:
#   AC2 — every file installs it: carries the block directly after `set -eu`, routes every EXIT
#         trap through `announce_abort`, and sets TALLIED=1 between its tally and its status.
#   AC1 — every file, copied into a scratch mirror of the repo with an abort injected once its
#         setup is done, prints ABORTED with its count so far and exits non-zero — including when
#         the injected death has status 0.
#   AC3 — the normal path is untouched: a tallied run keeps its own status and prints no ABORTED.
#
# The injection point is the substitution recorded in 0169's notes: "after its first assertion" is
# not a location a script can find in 35 differently-shaped files, so the abort lands where every
# file has finished its setup — after its first EXIT trap, or after `FAIL=0` where it has none — and
# counts one assertion by hand first, so "contains a count" is a count the file actually reached.
#
# Usage:  tests/abort-announce.test.sh
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
SELF="$ROOT/tests/abort-announce.test.sh"

PASS=0
FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }

FIX="$(mktemp -d)"
cleanup() { rm -rf "$FIX"; }
trap 'announce_abort cleanup' EXIT
trap cleanup INT TERM

# The block runs from the line after the first `set -eu` to the first `trap announce_abort EXIT`.
# $1 file. Prints the block, or nothing when the line after `set -eu` does not open it.
block_of() {
  awk 'started { print; if ($0 == "trap announce_abort EXIT") exit; next }
       /^set -eu$/ { getline; if ($0 !~ /^# Announce an abort/) exit; started = 1; print }' "$1"
}
CANON="$FIX/canonical-block"
block_of "$SELF" > "$CANON"
[ -s "$CANON" ] || { echo "no announce block after set -eu in $SELF" >&2; exit 2; }

# --- AC2 — every file installs it ---------------------------------------------------------------
echo "AC2 — every tests/*.test.sh installs the announce-on-abort trap"
for f in "$ROOT"/tests/*.test.sh; do
  name="tests/$(basename "$f")"
  block_of "$f" > "$FIX/block"
  if cmp -s "$FIX/block" "$CANON"; then ok "$name carries the announce block, byte-identical, directly after set -eu"
  else bad "$name does not carry the announce block byte-identical directly after set -eu"; fi

  unrouted="$(grep -n '^ *trap .*EXIT' "$f" | grep -v 'announce_abort' || true)"
  if [ -z "$unrouted" ]; then ok "$name routes every EXIT trap through announce_abort"
  else bad "$name installs an EXIT trap that replaces announce_abort: $unrouted"; fi

  # The tally is the second-last non-blank line and the status check the last, in every file, so
  # TALLIED=1 must sit between them — anywhere earlier would hide an abort after it.
  tail_shape="$(awk 'NF { prev2 = prev1; prev1 = $0 } END { print prev2 }' "$f")"
  if [ "$tail_shape" = "TALLIED=1" ]; then ok "$name sets TALLIED=1 between its tally and its status"
  else bad "$name does not set TALLIED=1 on the line before its final status check (saw: $tail_shape)"; fi
done

# --- AC1 — an injected abort is announced, with a count, and exits non-zero --------------------
# A scratch mirror: every top-level entry of the repo symlinked except .git (an aborting copy must
# have no index to write) and tests/, which is real so the mutated copy's ROOT resolves to the mirror.
MIRROR="$FIX/root"
mkdir -p "$MIRROR/tests"
for e in "$ROOT"/* "$ROOT"/.[!.]*; do
  [ -e "$e" ] || continue
  case "$(basename "$e")" in .git|tests) continue ;; esac
  ln -s "$e" "$MIRROR/$(basename "$e")"
done

# $1 file, $2 the line to inject. Prints the copy's path. The block's own trap is skipped: an abort
# injected there would run before the file has set PASS, so it could not show a count it reached.
inject() {
  copy="$MIRROR/tests/$(basename "$1")"
  at="$(grep -n '^trap .*EXIT' "$1" | grep -v ':trap announce_abort EXIT$' | head -1 | cut -d: -f1)"
  [ -n "$at" ] || at="$(grep -n '^FAIL=0$' "$1" | head -1 | cut -d: -f1)"
  awk -v at="$at" -v line="$2" '{ print } NR == at { print line }' "$1" > "$copy"
  chmod +x "$copy"
  printf '%s' "$copy"
}

echo "AC1 — an abort injected into each file is announced with its count and exits non-zero"
for f in "$ROOT"/tests/*.test.sh; do
  name="tests/$(basename "$f")"
  for death in 'false' 'exit 0'; do
    copy="$(inject "$f" "PASS=\$((PASS+1)); $death")"
    out="$("$copy" 2>&1)" && rc=0 || rc=$?
    rm -f "$copy"
    case "$out" in
      *'ABORTED before the tally: 1 passed, 0 failed so far'*) ok "$name, killed by '$death', announces ABORTED with its count" ;;
      *) bad "$name, killed by '$death', printed no ABORTED line with its count: $(printf '%s' "$out" | tail -3)" ;;
    esac
    if [ "$rc" -ne 0 ]; then ok "$name, killed by '$death', exits non-zero ($rc)"
    else bad "$name, killed by '$death', exited 0"; fi
  done
done

# --- AC3 — the normal path keeps its tally and its status --------------------------------------
echo "AC3 — a tallied run is left alone"
# $1 the final status the fixture ends on. A fixture shaped like every real file: the block, a
# cleanup trap through it, tally, TALLIED=1, status.
tallied_fixture() {
  { printf '#!/bin/sh\nset -eu\n'
    cat "$CANON"
    printf 'PASS=3\nFAIL=%s\n' "$1"
    printf '%s\n' 'cleanup() { echo "cleanup ran"; }' \
      "trap 'announce_abort cleanup' EXIT" \
      'printf "\n%s passed, %s failed\n" "$PASS" "$FAIL"' \
      'TALLIED=1' \
      '[ "$FAIL" = 0 ]'
  } > "$MIRROR/tests/fixture.sh"
  chmod +x "$MIRROR/tests/fixture.sh"
}

for fails in 0 1; do
  tallied_fixture "$fails"
  out="$("$MIRROR/tests/fixture.sh" 2>&1)" && rc=0 || rc=$?
  want=0; [ "$fails" = 0 ] || want=1
  case "$out" in
    *ABORTED*) bad "a tallied run with $fails failed printed ABORTED: $out" ;;
    *"3 passed, $fails failed"*) ok "a tallied run with $fails failed prints its own tally and no ABORTED" ;;
    *) bad "a tallied run with $fails failed lost its tally: $out" ;;
  esac
  if [ "$rc" -eq "$want" ]; then ok "a tallied run with $fails failed keeps its exit status ($rc)"
  else bad "a tallied run with $fails failed exited $rc, wanted $want"; fi
  case "$out" in
    *'cleanup ran'*) ok "a tallied run with $fails failed still runs its own cleanup" ;;
    *) bad "a tallied run with $fails failed skipped its cleanup: $out" ;;
  esac
done
rm -f "$MIRROR/tests/fixture.sh"

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
TALLIED=1
[ "$FAIL" = 0 ]
