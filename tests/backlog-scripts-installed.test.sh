#!/bin/sh
#
# Guard for the script install in this repo's own backlog (0027).
#
# This repo ships next, claim, close and handoff as skills/queue/templates/ and instantiates them
# into a *new* project's backlog at queue Step 0. This backlog predates that step, so the one
# project developing the scripts was the only project without them — six sessions hit it on
# 2026-08-23.
#
# What this guards is not what the scripts do (they have their own suites) but that the copies
# exist, run, and have not drifted from the templates. The fix direction is one-way: a divergence
# is a defect in the template, fixed there and re-copied. A local edit to a copy is the
# two-conventions defect 0024 exists to forbid, and it is invisible without this check.
#
# Drift in the *table* is deliberately not asserted here. `./next --drift` is the gate on that,
# and it reads live backlog state — a suite assertion over it would go red on any ticket's
# unrelated close.
#
# Usage:  tests/backlog-scripts-installed.test.sh
#
# Requires: sh, diff, grep. No runner — this project has none.

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
BACKLOG="$ROOT/.claude/backlog"
TEMPLATES="$ROOT/skills/queue/templates"

[ -d "$BACKLOG" ]   || { echo "no backlog at $BACKLOG" >&2; exit 2; }
[ -d "$TEMPLATES" ] || { echo "no templates at $TEMPLATES" >&2; exit 2; }

# The scripts are every executable on EITHER side, derived rather than listed (0089): a hardcoded
# list let `reopen` drop out of every check below with the suite green, 45 checks falling to 37.
# The union is the point — a script missing from one side is still in the list, and reds there.
executables_in() { for f in "$1"/*; do [ -f "$f" ] && [ -x "$f" ] && basename "$f"; done; return 0; }
SCRIPTS="$( { executables_in "$TEMPLATES"; executables_in "$BACKLOG"; } | sort -u | tr '\n' ' ')"
[ -n "$SCRIPTS" ] || { echo "no executable script found in $TEMPLATES or $BACKLOG" >&2; exit 2; }

PASS=0
FAIL=0

ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }

echo "AC1 — all five are installed and executable"
for s in $SCRIPTS; do
  if [ -f "$BACKLOG/$s" ]; then ok "$s exists"; else bad "$s missing from this repo's backlog ($BACKLOG)"; fi
  if [ -x "$BACKLOG/$s" ]; then ok "$s is executable"; else bad "$s is not executable (chmod +x)"; fi
done

echo "AC5 — every script parses under /bin/sh, template and installed copy"
# A copy that has diverged is caught below; a copy that is byte-identical to a template with a
# syntax error is not, and the first thing either would do is fail at the moment a session is
# mid-hand-off. `sh -n` is the cheapest check that the shipped bytes are runnable at all (0081).
#
# Both sides are parsed, and this runs BEFORE the byte-identical comparison (0077). The hazard it
# exists for is an apostrophe inside one of the single-quoted `awk` programs these scripts embed:
# it closes the quoting around the whole program, errors nowhere at the edit, and surfaces as
# behaviour — `close.test.sh` once failed 20 of 63 cases reporting an empty reconcile list, naming
# nothing about quotes. A template broken that way and copied faithfully diverges from nothing, so
# AC2 is silent; reported after AC2 the same defect on one side alone reads as drift, sending the
# reader to diff two files rather than to the quote. So: parse first, and say `syntax`.
for s in $SCRIPTS; do
  for side in "$TEMPLATES/$s" "$BACKLOG/$s"; do
    label="${side#"$ROOT/"}"
    if [ ! -f "$side" ]; then
      bad "$s — cannot parse, $label is missing"
    elif sh -n "$side" 2>/dev/null; then
      ok "$label parses"
    else
      bad "$s has a syntax error — $label is not valid /bin/sh (this is not a divergence): $(sh -n "$side" 2>&1 | head -3)"
    fi
  done
done

echo "AC8 — no apostrophe closes an embedded awk program early, template and installed copy"
# AC5 above catches only the apostrophes that leave the file unparseable, and that is a minority of
# them. Measured 2026-09-09: `# it\047s the criteria block` inside `close`s `ac_counts` awk program
# is accepted by `sh -n` (/bin/sh here is bash 3.2) while `close.test.sh` fails 83 cases — a live
# broken script under a fully green guard, which is the state this whole file exists to make
# impossible. Under the interpreter that runs the script the file IS valid; the breakage is
# semantic, awk receiving a program that stops early. So no parse check of that same shell can
# ever see it, and the check has to be a positive one over the scripts own text.
#
# What it asserts: a single-quoted region spanning more than one line is an embedded program, and
# the quote that closes it must be the first thing on its line, bar whitespace and the awk block
# enders `)`, `}`, `]`. A stray apostrophe in prose closes the region mid-comment, which fails that
# test wherever the shell happens to recover. The scanner walks characters in the states the shell
# does -- unquoted, single-quoted, double-quoted -- honouring backslash escapes, shell comments,
# heredoc bodies and `$(...)`, inside which the shell re-enters unquoted parsing (the scripts open
# every awk program as `x="$(awk ...)"`, so a scanner without that last part sees none of them).
#
# Only the first violation per file is reported: once a region closes early every later quote is
# displaced, so the rest of the list is cascade rather than evidence.
#
# Deliberately strict on one shape, measured 2026-09-09. A region closing on its own opening line
# after a comment start is reported whether or not the program continues onto later lines -- the
# two cases are `awk '/^x/ {  # it's the row` (broken; the program body follows) and
# `awk '{ print }  # a note'` (fine; a real awk comment), and nothing available at the close
# tells them apart without lookahead. Reporting both was chosen over missing the first, because
# AC2 is the whole ticket and the convention in references/CONCURRENCY.md already asks that these
# programs carry no prose comments. Neither shape exists in the five scripts today. A future
# legitimate trailing awk comment trips this: move it above the assignment, where it belongs.
#
# Two more clauses, for an apostrophe at the HEAD of a body line (0139). There it sits exactly where
# a real terminator sits, with no `#` before it, so neither test above can fire, `sh -n` accepts the
# file, and it re-pairs to EOF: measured on 2026-10-25, 20 such mutants in `close` broke it under a
# green guard. What gives it away is the rest of its line, which is awk text where a terminator has
# shell. So:
#   after — the closing line of a multi-line region carries, after its quote, nothing, a `)`
#           straight after the quote, or whitespace and then a `"`. Every real terminator in the
#           scripts takes one of those forms: `'`, `}')"`, `' "$item")"`, `' "$QUEUE" > "$tmp"`.
#   head  — no line strictly inside a multi-line region begins, bar whitespace, with `"` or `)`.
#           Those are the only body lines an apostrophe at their head would turn into a terminator
#           `after` allows, so this keeps `after` exact.
# What stays uncaught is an apostrophe alone on a blank body line: it is byte-identical to a bare
# terminator. Each hit prints its kind, the line the region opened on, the line, and its text.
early_close() {
  awk '
    BEGIN { Q = "\047"; state = 0; depth = 0; hd = "" }
    # True when SEG -- the region text preceding a closing quote, on that quote\047s own line --
    # already opened an awk comment. That is what an apostrophe in prose does: the quote it closes
    # sits inside a `#` comment rather than at the program\047s end. Reported on the opening line
    # too, where the prefix test above cannot fire because a one-line program legitimately closes
    # after non-whitespace. The `/` and `"` parity keeps a `#` inside an awk regex or string --
    # `/^#/`, `/^## /` -- from counting as a comment start.
    function awk_comment(seg,   p, before) {
      for (p = 1; p <= length(seg); p++) {
        if (substr(seg, p, 1) != "#") continue
        if (p > 1 && substr(seg, p-1, 1) != " " && substr(seg, p-1, 1) != "\t") continue
        before = substr(seg, 1, p-1)
        if (gsub(/\//, "", before) % 2) continue
        before = substr(seg, 1, p-1)
        if (gsub(/"/, "", before) % 2) continue
        return 1
      }
      return 0
    }
    {
      if (hd != "") { t = $0; sub(/^[ \t]+/, "", t); if (t == hd) hd = ""; next }
      head_bad = (state == 1 && NR != sq_line && $0 ~ /^[ \t]*[")]/)
      i = 1; n = length($0)
      while (i <= n) {
        c = substr($0, i, 1)
        if (state == 1) {
          if (c == Q) {
            state = 0
            seg = substr($0, (NR == sq_line ? sq_start : 1), i - (NR == sq_line ? sq_start : 1))
            if ((NR != sq_line && substr($0, 1, i-1) !~ /^[ \t)}\]]*$/) || awk_comment(seg)) {
              printf "early\t%d\t%d\t%s\n", sq_line, NR, $0
              exit
            }
            rest = substr($0, i+1)
            if (NR != sq_line && rest !~ /^[ \t]*$/ && rest !~ /^\)/ && rest !~ /^[ \t]+"/) {
              printf "after\t%d\t%d\t%s\n", sq_line, NR, $0
              exit
            }
          }
          i++; continue
        }
        if (c == "\\") { i += 2; continue }
        if (c == "$" && substr($0, i+1, 1) == "(") {
          depth++; stack[depth] = state; state = 0; i += 2; continue
        }
        if (state == 0) {
          if (c == ")" && depth > 0) { state = stack[depth]; depth--; i++; continue }
          if (c == Q) { state = 1; sq_line = NR; sq_start = i + 1; i++; continue }
          if (c == "\"") { state = 2; i++; continue }
          if (c == "#" && (i == 1 || substr($0, i-1, 1) == " " || substr($0, i-1, 1) == "\t")) break
          i++; continue
        }
        if (c == "\"") { state = 0; i++; continue }
        i++
      }
      if (head_bad && state == 1 && sq_line < NR) {
        printf "head\t%d\t%d\t%s\n", sq_line, NR, $0
        exit
      }
      if (state == 0 && match($0, /<<-?["\047]?[A-Za-z_][A-Za-z0-9_]*/)) {
        d = substr($0, RSTART, RLENGTH); sub(/^<<-?["\047]?/, "", d); hd = d
      }
    }
  ' "$1"
}
for s in $SCRIPTS; do
  for side in "$TEMPLATES/$s" "$BACKLOG/$s"; do
    label="${side#"$ROOT/"}"
    if [ ! -f "$side" ]; then
      bad "$s — cannot scan, $label is missing"
      continue
    fi
    hit="$(early_close "$side")"
    if [ -z "$hit" ]; then
      ok "$label closes every embedded awk program at its own terminator"
    else
      kind="$(printf '%s' "$hit" | cut -f1)"
      opened="$(printf '%s' "$hit" | cut -f2)"
      at="$(printf '%s' "$hit" | cut -f3)"
      text="$(printf '%s' "$hit" | cut -f4-)"
      case "$kind" in
        head)  bad "$s has a quote hazard, not a divergence — line $at, inside the awk program opened at $label:$opened, is a body line beginning with \" or ): $text — a body line may not begin with \" or ), so rewrap or reorder it (references/CONCURRENCY.md, 'The five scripts')" ;;
        after) bad "$s has a quote defect, not a divergence — the awk program opened at $label:$opened is closed by a quote on line $at with awk text after it: $text — a terminator is followed only by ), whitespace and a double-quoted argument, or nothing; an apostrophe at the head of a body line looks like this (references/CONCURRENCY.md, 'The five scripts')" ;;
        *)     bad "$s has a quote defect, not a divergence — the awk program opened at $label:$opened is closed early by a quote on line $at: $text — prose inside these single-quoted programs takes no apostrophe (references/CONCURRENCY.md, 'The five scripts')" ;;
      esac
    fi
  done
done

echo "AC2 — each copy is byte-identical to its template"
for s in $SCRIPTS; do
  if [ ! -f "$BACKLOG/$s" ] || [ ! -f "$TEMPLATES/$s" ]; then
    bad "$s — cannot diff, one side is missing"
  elif diff -q "$TEMPLATES/$s" "$BACKLOG/$s" >/dev/null 2>&1; then
    ok "$s matches its template"
  else
    bad "$s has diverged from skills/queue/templates/$s — fix the template and re-copy, never the copy"
  fi
done

echo "AC6 — a transient lock cannot be committed"
if grep -qF '.claude/backlog/.lock/' "$ROOT/.gitignore"; then
  ok ".claude/backlog/.lock/ is ignored (this repo has not migrated, 0182)"
else
  bad ".gitignore does not ignore .claude/backlog/.lock/"
fi

echo "NFR — the copies add no dependency beyond this machine's /bin/sh"
for s in $SCRIPTS; do
  if [ ! -f "$BACKLOG/$s" ]; then
    bad "$s — cannot read shebang, file is missing"
  elif [ "$(head -n 1 "$BACKLOG/$s")" = "#!/bin/sh" ]; then
    ok "$s declares /bin/sh"
  else
    bad "$s does not declare #!/bin/sh — found: $(head -n 1 "$BACKLOG/$s")"
  fi
done

echo "AC7 — queue Step 0 covers a backlog that predates the scripts"
STEP0="$(awk '/^## Step 0/,/^## Step 1/' "$ROOT/skills/queue/SKILL.md")"
# Asserted inside Step 0, not the whole file: the scaffold case already names every script, so
# a file-wide grep passes on the very prose this case exists to sit beside.
if printf '%s' "$STEP0" | grep -qF 'already exists can still be missing the scripts'; then
  ok "Step 0 names the existing-backlog case"
else
  bad "Step 0 covers only scaffolding a new backlog, not retrofitting an existing one"
fi
if printf '%s' "$STEP0" | grep -qF 'a fix flows'; then
  ok "Step 0 states which direction a fix flows"
else
  bad "Step 0 does not say that a fix flows template -> copy, never the reverse"
fi

echo "AC4 — the apostrophe convention is stated where the scripts are documented"
# Anchored to the section body, not the whole file: the hazard is explained in comments inside the
# scripts themselves, so a file-wide grep would pass on prose that is not the stated rule (0077).
SECTION="$(awk '/^## The five scripts/{f=1;next} f&&/^## /{exit} f' "$ROOT/references/CONCURRENCY.md")"
if [ -z "$SECTION" ]; then
  bad "references/CONCURRENCY.md has no 'The five scripts' section to state the rule in"
else
  if printf '%s' "$SECTION" | grep -qF 'takes no apostrophe'; then
    ok "the five-scripts section states the rule"
  else
    bad "references/CONCURRENCY.md, 'The five scripts', does not forbid apostrophes in embedded awk prose"
  fi
  if printf '%s' "$SECTION" | grep -qF 'quoting around the whole program'; then
    ok "and gives the quoting as its reason"
  else
    bad "the rule is stated without its reason — it is the shell quoting, not style"
  fi
  # 0139 FR4: the terminator rule the `after` and `head` clauses enforce, and the one shape they
  # cannot see, are stated where the scan is described.
  if printf '%s' "$SECTION" | grep -qF 'carries only `)` or double-quoted arguments after the quote'; then
    ok "the five-scripts section states what may follow a terminator"
  else
    bad "references/CONCURRENCY.md, 'The five scripts', does not state that a closing line carries only ) or double-quoted arguments after the quote"
  fi
  if printf '%s' "$SECTION" | grep -qF 'An apostrophe alone on a blank line inside a program is not caught'; then
    ok "and names the blank-line apostrophe as the shape the scan does not catch"
  else
    bad "references/CONCURRENCY.md, 'The five scripts', does not name the blank-line apostrophe as uncaught"
  fi
fi

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
TALLIED=1
[ "$FAIL" = 0 ]
