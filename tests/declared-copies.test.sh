#!/bin/sh
#
# Guard for 0146: every declared copy is identical, and no copy goes undeclared.
#
# A backlog script sources nothing by install contract, so shared code cannot be extracted and a
# helper two scripts need is a copy. A copy whose divergence would be silent — both still run and
# pass their own tests while answering differently — is DECLARED by wrapping each copy in a marker
# pair on lines of their own, `copy-begin: <name>` and `copy-end: <name>` behind a `# `, the name
# shared by every copy. This suite is the guard the markers name:
#
#   FR2 — over skills/queue/templates/* and tests/*.test.sh, every begin has its end (no nesting),
#         every name has at least two copies, and every copy is byte-identical between its markers.
#   FR3 — over skills/queue/templates/* only, a function defined in two or more files has EVERY
#         definition inside a marked block. One unmarked definition beside marked ones is the
#         undeclared copy `reopen` once carried. Tests are exempt: each defines `ok` and `bad`.
#   FR6 — it reads source-tree files only, never the installed copies under the backlog directory:
#         tests/backlog-scripts-installed.test.sh compares a whole template against its installed
#         copy, this compares blocks across different files, and neither subsumes the other.
#
# Usage:  tests/declared-copies.test.sh            the repo tree, plus this suite's own fixtures
#         tests/declared-copies.test.sh <root>     only the tree at <root>; non-zero on any finding
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
SELF="$ROOT/tests/declared-copies.test.sh"
TARGET="${1:-$ROOT}"
[ -d "$TARGET" ] || { echo "no directory at $TARGET" >&2; exit 2; }

PASS=0
FAIL=0
FIX=""
cleanup() { [ -n "$FIX" ] && rm -rf "$FIX"; return 0; }
trap 'announce_abort cleanup' EXIT
trap cleanup INT TERM

ok()  { PASS=$((PASS + 1)); echo "  ok   — $1"; }
bad() { FAIL=$((FAIL + 1)); echo "  FAIL — $1"; }

# --- the scan ---------------------------------------------------------------------------------
# One awk pass over every scanned file, printing one tab-separated record per finding:
#   BLOCK <name> <copies> <files>   a name that passed, for the report
#   FAIL  <message>                 anything else
# A marker is a whole line, so a phrase quoted mid-line — as in this header — never counts as one.
scan_tree() {
  root="$1"
  set --
  for f in "$root"/skills/queue/templates/* "$root"/tests/*.test.sh; do
    [ -f "$f" ] && set -- "$@" "$f"
  done
  [ "$#" -gt 0 ] || { printf 'FAIL\tno template or test file under %s\n' "$root"; return 0; }
  awk -v root="$root/" '
    function rel(p) { return index(p, root) == 1 ? substr(p, length(root) + 1) : p }
    function close_file() {
      if (open != "") printf "FAIL\tblock %s opened at %s:%d has no copy-end\n", open, file, openline
      open = ""
    }
    FNR == 1 { close_file(); file = rel(FILENAME); template = (file ~ /^skills\/queue\/templates\//) }
    /^# copy-begin: [a-z0-9-]+$/ {
      name = substr($0, 15)
      if (open != "") { printf "FAIL\tblock %s begins at %s:%d inside open block %s\n", name, file, FNR, open; next }
      open = name; openline = FNR
      k = ++count[name]; where[name, k] = file; start[name, k] = FNR; len[name, k] = 0
      next
    }
    /^# copy-end: [a-z0-9-]+$/ {
      name = substr($0, 13)
      if (open == "")        printf "FAIL\tblock %s ends at %s:%d but was never begun\n", name, file, FNR
      else if (name != open) printf "FAIL\tblock %s ends at %s:%d while %s is open\n", name, file, FNR, open
      else open = ""
      next
    }
    template && /^[A-Za-z_][A-Za-z0-9_]*\(\) *\{/ {
      fn = $0; sub(/\(.*/, "", fn)
      if (!((fn, file) in defined)) { defined[fn, file] = 1; deffiles[fn] = deffiles[fn] " " file; ndef[fn]++ }
      if (open == "") unmarked[fn] = unmarked[fn] " " file
    }
    open != "" { k = count[open]; body[open, k, ++len[open, k]] = $0 }
    END {
      close_file()
      for (name in count) {
        if (count[name] < 2) {
          printf "FAIL\tblock %s has one copy, in %s — a declared copy needs at least two\n", name, where[name, 1]
          continue
        }
        same = 1
        for (k = 2; k <= count[name]; k++) {
          n = len[name, 1] > len[name, k] ? len[name, 1] : len[name, k]
          for (i = 1; i <= n; i++) {
            a = (i <= len[name, 1]) ? body[name, 1, i] : "<end of block>"
            b = (i <= len[name, k]) ? body[name, k, i] : "<end of block>"
            if (a != b || (i > len[name, 1]) != (i > len[name, k])) {
              printf "FAIL\tblock %s differs between %s:%d and %s:%d\n    %s\n    %s\n", name, where[name, 1], start[name, 1] + i, where[name, k], start[name, k] + i, a, b
              same = 0; break
            }
          }
        }
        if (!same) continue
        files = ""
        for (k = 1; k <= count[name]; k++) files = files " " where[name, k]
        printf "BLOCK\t%s\t%d\t%s\n", name, count[name], files
      }
      for (fn in ndef)
        if (ndef[fn] >= 2 && unmarked[fn] != "")
          printf "FAIL\tfunction %s is defined in%s and is outside a marked block in%s\n", fn, deffiles[fn], unmarked[fn]
    }
  ' "$@"
}

# --- an explicit root: check that tree and nothing else ----------------------------------------
if [ "$#" -gt 0 ]; then
  echo "declared copies under $TARGET"
  FIX="$(mktemp -d)"
  scan_tree "$TARGET" > "$FIX/scan"
  while IFS= read -r line; do
    case "$line" in
      BLOCK*) ok "$(printf '%s' "$line" | awk -F'\t' '{ printf "%s: %s copies, identical", $2, $3 }')" ;;
      FAIL*)  bad "$(printf '%s' "$line" | cut -f2-)" ;;
      *)      echo "$line" ;;
    esac
  done < "$FIX/scan"
  echo
  echo "declared-copies: $PASS passed, $FAIL failed"
  TALLIED=1
  [ "$FAIL" -eq 0 ]
  exit
fi

# --- no argument: the repo, then this suite's own fixtures --------------------------------------
FIX="$(mktemp -d)"

# Marker lines are built from these, never written literally at the start of a line here: a literal
# one in this file would be read as a marker of this file's own.
BEGIN_X="# copy-begin: x"
END_X="# copy-end: x"

run_on() { out="$("$SELF" "$1" 2>&1)" && rc=0 || rc=$?; }
expect_red() {
  label="$1"; shift
  if [ "$rc" -eq 0 ]; then bad "$label — exited 0"; printf '%s\n' "$out" | sed 's/^/         /'; return; fi
  for want in "$@"; do
    case "$out" in
      *"$want"*) ;;
      *) bad "$label — output does not name '$want'"; printf '%s\n' "$out" | sed 's/^/         /'; return ;;
    esac
  done
  ok "$label"
}
mkroot() { rm -rf "$FIX/$1"; mkdir -p "$FIX/$1/skills/queue/templates" "$FIX/$1/tests"; }

echo "AC5 — the repo tree's declared copies are all present and identical"
run_on "$ROOT"
if [ "$rc" -eq 0 ]; then ok "the repo tree passes"; else bad "the repo tree passes"; printf '%s\n' "$out" | sed 's/^/         /'; fi
for want in 'decomment: 4 copies' 'fm-value: 3 copies' 'fm-list: 3 copies' 'read-cell: 3 copies' \
            'column-in: 2 copies' 'header-of: 2 copies' 'column-named: 2 copies' 'scope-block: 2 copies'; do
  case "$out" in *"$want, identical"*) ok "reports $want" ;; *) bad "reports $want" ;; esac
done
for name in saw-on-pass saw-prefix; do
  n="$(printf '%s\n' "$out" | sed -n "s/.*ok   — $name: \([0-9]*\) copies, identical.*/\1/p")"
  if [ -n "$n" ] && [ "$n" -ge 2 ]; then ok "reports $name with $n copies"; else bad "reports $name with at least two copies"; fi
done

echo "AC1 — two copies differing in one character red, naming the block, both files and the line"
mkroot ac1
printf '%s\n' "$BEGIN_X" 'one' 'two' "$END_X" > "$FIX/ac1/skills/queue/templates/a"
printf '%s\n' "$BEGIN_X" 'one' 'twO' "$END_X" > "$FIX/ac1/skills/queue/templates/b"
run_on "$FIX/ac1"
expect_red "differing copies red" 'block x differs' 'skills/queue/templates/a:3' 'skills/queue/templates/b:3' 'twO'

echo "AC2 — a begin with no end reds, naming the block and its file"
mkroot ac2
printf '%s\n' "$BEGIN_X" 'one' "$END_X" > "$FIX/ac2/skills/queue/templates/a"
printf '%s\n' "$BEGIN_X" 'one' > "$FIX/ac2/skills/queue/templates/b"
run_on "$FIX/ac2"
expect_red "an unclosed block reds" 'block x opened at skills/queue/templates/b:1 has no copy-end'

echo "AC2 — an end with no begin, and a nested begin, red too"
mkroot ac2b
printf '%s\n' "$BEGIN_X" 'one' "$END_X" "$END_X" > "$FIX/ac2b/tests/a.test.sh"
printf '%s\n' "$BEGIN_X" 'one' "$END_X" > "$FIX/ac2b/tests/b.test.sh"
run_on "$FIX/ac2b"
expect_red "an unopened end reds" 'block x ends at tests/a.test.sh:4 but was never begun'
mkroot ac2c
printf '%s\n' "$BEGIN_X" "$BEGIN_X" 'one' "$END_X" > "$FIX/ac2c/tests/a.test.sh"
printf '%s\n' "$BEGIN_X" 'one' "$END_X" > "$FIX/ac2c/tests/b.test.sh"
run_on "$FIX/ac2c"
expect_red "a nested begin reds" 'block x begins at tests/a.test.sh:2 inside open block x'

echo "AC3 — a name marked in exactly one file reds as one copy"
mkroot ac3
printf '%s\n' "$BEGIN_X" 'one' "$END_X" > "$FIX/ac3/skills/queue/templates/a"
run_on "$FIX/ac3"
expect_red "a lone copy reds" 'block x has one copy'

echo "AC4 — a function defined in two templates outside any block reds"
mkroot ac4
printf '%s\n' 'helper() {' '  :' '}' > "$FIX/ac4/skills/queue/templates/a"
printf '%s\n' 'helper() {' '  :' '}' > "$FIX/ac4/skills/queue/templates/b"
run_on "$FIX/ac4"
expect_red "two unmarked definitions red" 'function helper' 'skills/queue/templates/a' 'skills/queue/templates/b'

echo "AC4 — the same two definitions inside identical marked blocks pass"
mkroot ac4m
printf '%s\n' "$BEGIN_X" 'helper() {' '  :' '}' "$END_X" > "$FIX/ac4m/skills/queue/templates/a"
printf '%s\n' "$BEGIN_X" 'helper() {' '  :' '}' "$END_X" > "$FIX/ac4m/skills/queue/templates/b"
run_on "$FIX/ac4m"
if [ "$rc" -eq 0 ]; then ok "two marked definitions pass"; else bad "two marked definitions pass"; printf '%s\n' "$out" | sed 's/^/         /'; fi

echo "AC4 — a third definition pasted unmarked beside two marked ones reds, naming it"
printf '%s\n' 'helper() {' '  :' '}' > "$FIX/ac4m/skills/queue/templates/c"
run_on "$FIX/ac4m"
expect_red "a third unmarked definition reds" 'function helper' 'outside a marked block in skills/queue/templates/c'
case "$out" in
  *"outside a marked block in skills/queue/templates/a"*|*"outside a marked block in skills/queue/templates/b"*)
    bad "only the unmarked file is named as outside a block" ;;
  *) ok "only the unmarked file is named as outside a block" ;;
esac

echo "AC4 — test files are exempt from the undeclared-copy detector"
mkroot ac4t
printf '%s\n' 'ok() { :; }' > "$FIX/ac4t/tests/a.test.sh"
printf '%s\n' 'ok() { :; }' > "$FIX/ac4t/tests/b.test.sh"
run_on "$FIX/ac4t"
if [ "$rc" -eq 0 ]; then ok "a function shared by two test files passes"; else bad "a function shared by two test files passes"; printf '%s\n' "$out" | sed 's/^/         /'; fi

echo "AC7 — one character changed in handoff's scope-block alone reds, naming scope-block"
mkroot ac7
cp "$ROOT"/skills/queue/templates/* "$FIX/ac7/skills/queue/templates/"
cp "$ROOT"/tests/*.test.sh "$FIX/ac7/tests/"
awk '/^# copy-begin: scope-block$/ { f = 1; print; next }
     f == 1 && /^SCOPE_NOTE=""$/ { print "SCOPE_NOTE=\"x\""; f = 2; next }
     { print }' "$ROOT/skills/queue/templates/handoff" > "$FIX/ac7/skills/queue/templates/handoff"
if cmp -s "$ROOT/skills/queue/templates/handoff" "$FIX/ac7/skills/queue/templates/handoff"; then
  bad "the mutation landed in the copy of handoff"
else
  run_on "$FIX/ac7"
  expect_red "a drifted scope-block reds" 'block scope-block differs' 'skills/queue/templates/handoff'
fi

echo "AC10 — next's header-reading helper is renamed, not marked"
if grep -q 'column_named' "$ROOT/skills/queue/templates/next"; then bad "next no longer says column_named"; else ok "next no longer says column_named"; fi

echo
echo "declared-copies: $PASS passed, $FAIL failed"
TALLIED=1
[ "$FAIL" -eq 0 ]
