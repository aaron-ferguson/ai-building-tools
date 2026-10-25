#!/bin/sh
#
# Guard for the acceptance-criteria digest (0195): `./next --ac-digest`, the `--drift` class it
# feeds, `close`'s refusal, and the prose that tells each stage what to do with it.
#
# A ticket's criteria are its contract, and `verify` checks them literally against whatever text is
# on disk — so a criterion rewritten by the stage being held to it passes as written. The digest is
# stamped by the author's write path (`queue`, `design`) and recomputed from the file bytes at every
# gate that reads the contract. This suite builds its own fixture backlog rather than growing
# tests/next.test.sh, whose run is already past a tool timeout.
#
# Fixture ids are 99xx so no line of output can be mistaken for a real backlog row.
#
# Usage:  tests/ac-digest.test.sh
#
# Requires: git, sh, awk, cksum. No runner — this project has none.

set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
TEMPLATES="$ROOT/skills/queue/templates"
for s in next close reopen; do
  [ -f "$TEMPLATES/$s" ] || { echo "no $s template at $TEMPLATES/$s" >&2; exit 2; }
done

PASS=0
FAIL=0
FIX=""

ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }

cleanup() { [ -n "$FIX" ] && rm -rf "$FIX"; return 0; }
trap cleanup EXIT INT TERM

BL=".claude/backlog"

# --- fixture ----------------------------------------------------------------------------------
# scaffold <row…> — each row is "<id> <next> <status>"; every row gets an item via mkitem.
scaffold() {
  cleanup
  FIX="$(mktemp -d)"
  mkdir -p "$FIX/$BL/items"
  git -C "$FIX" init -q
  git -C "$FIX" config user.email test@example.invalid
  git -C "$FIX" config user.name "ac-digest test"
  {
    printf '# Backlog\n\n| ID | Title | Next | Status | Parent |\n|----|-------|------|--------|--------|\n'
    for r in "$@"; do
      set -- $r
      printf '| %s | Fixture %s | %s | %s | |\n' "$1" "$1" "$2" "$3"
    done
  } > "$FIX/$BL/QUEUE.md"
  {
    printf '# Done — completed tickets, newest first\n\n'
    printf '| ID | Title | Type | QA | Closed | Item |\n'
    printf '|------|-------|------|----|--------|------|\n'
  } > "$FIX/$BL/DONE.md"
  for s in next close reopen; do
    cp "$TEMPLATES/$s" "$FIX/$BL/$s"
    chmod +x "$FIX/$BL/$s"
  done
}

# mkitem <id> <next> <status> <token> — criteria AC1 and AC2, AC2 reading "a player at 5 VP".
mkitem() {
  cat > "$FIX/$BL/items/$1-fixture.md" <<ITEM
---
id: "$1"
title: Fixture $1
type: chore
next: $2
status: $3
qa_level: verify
created: 2026-08-01
blocked_by: []
claimed_by: $4
claimed_at:
touches:
---

## Acceptance criteria

Given / when / then. Template prose above the first label.

- [ ] AC1 — Given a board, when a road is built, then the longest road is recomputed.
- [ ] AC2 — Given a player at 5 VP, when they build a City over a Settlement, then the game ends.

## QA evidence

Conventions: ../conventions
ITEM
}

commit_all() { git -C "$FIX" add -A >/dev/null && git -C "$FIX" commit -q -m "${1:-fixture}"; }

item_of() { printf '%s' "$FIX/$BL/items/$1-fixture.md"; }

digest() { "$FIX/$BL/next" --ac-digest "$1"; }

key_of() { printf '%s' "$1" | tr ' ' '\n' | sed -n "s/^$2=//p"; }

# stamp <id> — writes `ac_digest:` from the computed digest, as queue's write path would.
stamp() {
  line="$(digest "$1")"
  f="$(item_of "$1")"
  awk -v line="$line" 'NR > 1 && /^---$/ && !done { print line; done = 1 } { print }' "$f" > "$f.tmp"
  mv "$f.tmp" "$f"
}

edit() { f="$(item_of "$1")"; sed "$2" "$f" > "$f.tmp" && mv "$f.tmp" "$f"; }

# --- AC1: tick and rewrap are not edits; a changed criterion moves its own key only ----------
echo "AC1 — tick state and whitespace are normalised; keys are per criterion"
scaffold "9901 verify ready"
mkitem 9901 verify ready ""
base="$(digest 9901)"
case "$base" in
  "ac_digest: AC1="*" AC2="*) ok "one line, one key per criterion: $base" ;;
  *) bad "unexpected digest line: $base" ;;
esac
edit 9901 's/^- \[ \] AC1/- [x] AC1/'
ticked="$(digest 9901)"
[ "$ticked" = "$base" ] && ok "ticking AC1 leaves the digest unchanged" || bad "ticking AC1 changed the digest: $ticked"
edit 9901 's/^\(- \[ \] AC2 — Given a player at 5 VP,\) \(when they build\)/\1\
  \2/'
rewrapped="$(digest 9901)"
grep -q '^  when they build' "$(item_of 9901)" || bad "fixture: the rewrap did not land"
[ "$rewrapped" = "$base" ] && ok "rewrapping AC2 leaves the digest unchanged" || bad "rewrapping AC2 changed the digest: $rewrapped"
edit 9901 's/5 VP/6 VP/'
changed="$(digest 9901)"
b1="$(key_of "${base#ac_digest: }" AC1)"; b2="$(key_of "${base#ac_digest: }" AC2)"
c1="$(key_of "${changed#ac_digest: }" AC1)"; c2="$(key_of "${changed#ac_digest: }" AC2)"
[ -n "$b2" ] && [ "$c2" != "$b2" ] && ok "changing 5 VP to 6 VP moves AC2's key" || bad "AC2's key did not move ($b2 → $c2)"
[ -n "$b1" ] && [ "$c1" = "$b1" ] && ok "AC1's key is unchanged by an AC2 edit" || bad "AC1's key moved with AC2's ($b1 → $c1)"

# --- AC2: the prose above the first label is not the contract --------------------------------
echo "AC2 — prose above the first ACn label is excluded"
scaffold "9902 verify ready"
mkitem 9902 verify ready ""
base="$(digest 9902)"
edit 9902 's/Template prose above the first label./Entirely different instructions now./'
after="$(digest 9902)"
[ "$after" = "$base" ] && ok "editing the section's preamble leaves the digest unchanged" || bad "preamble edit changed the digest: $after"

# --- AC3 / AC4: --drift reports a changed criterion; --drive escalates on it -----------------
echo "AC3 — --drift names the changed criterion"
scaffold "9903 verify ready"
mkitem 9903 verify ready ""
stamp 9903
commit_all
edit 9903 's/5 VP/6 VP/'
set +e; out="$("$FIX/$BL/next" --drift 2>&1)"; rc=$?; set -e
[ "$rc" -eq 1 ] && ok "--drift exits 1" || bad "--drift exited $rc: $out"
n="$(printf '%s\n' "$out" | grep -c '^DRIFT     9903 ' || true)"
[ "$n" -eq 1 ] && ok "one DRIFT line for 9903" || bad "expected one DRIFT line for 9903, got $n: $out"
dline="$(printf '%s\n' "$out" | grep '^DRIFT     9903 ' || true)"
case "$dline" in *AC2*) ok "the line names AC2" ;; *) bad "the line does not name AC2: $dline" ;; esac
case "$dline" in *AC1*) bad "the line names AC1, which did not change: $dline" ;; *) ok "the line does not name AC1" ;; esac

echo "AC4 — --drive exits 4 on the same drift"
set +e; dout="$("$FIX/$BL/next" --drive 2>&1)"; rc=$?; set -e
[ "$rc" -eq 4 ] && ok "--drive exits 4" || bad "--drive exited $rc: $dout"
printf '%s\n' "$dout" | grep -qF "$dline" && ok "--drive prints the AC3 drift line" || bad "--drive did not print the drift line: $dout"

# --- AC5: absent is unverifiable, never drift and never a match ------------------------------
echo "AC5 — an item with no ac_digest: is not drift, and closes as unverifiable"
scaffold "9905 verify in-progress"
mkitem 9905 verify in-progress f00d
commit_all
set +e; out="$("$FIX/$BL/next" --drift 2>&1)"; rc=$?; set -e
[ "$rc" -eq 0 ] && ok "--drift exits 0" || bad "--drift exited $rc: $out"
printf '%s\n' "$out" | grep -q '9905' && bad "--drift reported 9905: $out" || ok "--drift prints no line for 9905"
set +e; out="$(cd "$FIX" && "$BL/close" 9905 f00d 2>&1)"; rc=$?; set -e
[ "$rc" -eq 0 ] && ok "close closes it" || bad "close exited $rc: $out"
printf '%s\n' "$out" | grep 'ac_digest absent' | grep -q 'unverifiable' \
  && ok "close prints 'ac_digest absent' … 'unverifiable'" || bad "no absent/unverifiable line: $out"

# --- AC6: close refuses a mismatch and leaves everything as it was ---------------------------
echo "AC6 — close refuses a mismatch: nothing moved, nothing committed, lock released"
scaffold "9906 verify in-progress"
mkitem 9906 verify in-progress f00d
stamp 9906
commit_all
edit 9906 's/5 VP/6 VP/'
git -C "$FIX" commit -q -m "edit AC2 under the claim" -- "$BL/items/9906-fixture.md"
head_before="$(git -C "$FIX" rev-parse HEAD)"
set +e; out="$(cd "$FIX" && "$BL/close" 9906 f00d 2>&1)"; rc=$?; set -e
[ "$rc" -ne 0 ] && ok "close exits non-zero" || bad "close exited 0 over a changed criterion: $out"
printf '%s\n' "$out" | grep -q 'AC2' && ok "the refusal names AC2" || bad "the refusal does not name AC2: $out"
grep -q '^| 9906 ' "$FIX/$BL/QUEUE.md" && ok "the row is still in QUEUE.md" || bad "the row left QUEUE.md"
grep -q '^| 9906 ' "$FIX/$BL/DONE.md" && bad "the row reached DONE.md" || ok "the row is not in DONE.md"
[ "$(git -C "$FIX" rev-parse HEAD)" = "$head_before" ] && ok "no commit was made" || bad "HEAD moved"
[ ! -e "$FIX/$BL/.lock" ] && ok ".lock/ does not exist afterwards" || bad ".lock/ left behind"

# --- AC7: a matching stamp closes, and a reopen's untick does not read as drift --------------
echo "AC7 — a matching digest closes; after reopen, --drift is silent"
scaffold "9907 verify in-progress"
mkitem 9907 verify in-progress f00d
stamp 9907
commit_all
set +e; out="$(cd "$FIX" && "$BL/close" 9907 f00d 2>&1)"; rc=$?; set -e
[ "$rc" -eq 0 ] && ok "close succeeds on a matching digest" || bad "close refused a matching digest ($rc): $out"
grep -q '^- \[x\] AC2' "$(item_of 9907)" && ok "fixture: close ticked the criteria" || bad "fixture: nothing was ticked"
set +e; rout="$(cd "$FIX" && "$BL/reopen" 9907 top "ac-digest fixture" 2>&1)"; rc=$?; set -e
[ "$rc" -eq 0 ] || bad "fixture: reopen failed ($rc): $rout"
grep -q '^- \[ \] AC2' "$(item_of 9907)" && ok "fixture: reopen unticked the criteria" || bad "fixture: reopen left the criteria ticked"
set +e; out="$("$FIX/$BL/next" --drift 2>&1)"; rc=$?; set -e
printf '%s\n' "$out" | grep -q '^DRIFT     9907 .*ac_digest' && bad "--drift reports 9907 after reopen: $out" \
  || ok "--drift reports no digest line for 9907 after reopen"

# --- AC8: added and removed criteria are named as such ---------------------------------------
echo "AC8 — an added AC3 and a removed AC2 are each named"
scaffold "9908 verify ready" "9918 verify ready"
mkitem 9908 verify ready ""
mkitem 9918 verify ready ""
stamp 9908
stamp 9918
commit_all
edit 9908 's/^\(- \[ \] AC2 — .*\)$/\1\
- [ ] AC3 — Given anything, when it happens, then it is recorded./'
edit 9918 '/^- \[ \] AC2 /d'
set +e; out="$("$FIX/$BL/next" --drift 2>&1)"; set -e
l8="$(printf '%s\n' "$out" | grep '^DRIFT     9908 ' || true)"
l18="$(printf '%s\n' "$out" | grep '^DRIFT     9918 ' || true)"
printf '%s' "$l8" | grep -q 'added: AC3' && ok "9908 names AC3 as added" || bad "9908 does not name AC3 as added: $l8"
printf '%s' "$l18" | grep -q 'removed: AC2' && ok "9918 names AC2 as removed" || bad "9918 does not name AC2 as removed: $l18"

# --- AC9: close has no second definition of the digest ---------------------------------------
echo "AC9 — close invokes next --ac-digest and names no hash tool"
grep -Eq 'next"? --ac-digest' "$TEMPLATES/close" && ok "close invokes next --ac-digest" || bad "close does not invoke next --ac-digest"
grep -Eqw 'cksum|md5|md5sum|shasum|sha1sum|sha256sum|openssl' "$TEMPLATES/close" \
  && bad "close names a hash tool — the normalisation has a second definition" || ok "close names no hash tool"

# --- AC10: the field is declared, and says what absent means ---------------------------------
echo "AC10 — item.md declares ac_digest: with a comment naming unverifiable"
fmblock="$(awk 'NR == 1 && /^---$/ { fm = 1; next } fm && /^---$/ { exit } fm' "$TEMPLATES/item.md")"
printf '%s\n' "$fmblock" | grep -q '^ac_digest:' && ok "ac_digest: is declared in the frontmatter" || bad "ac_digest: is not declared"
# The comment block directly above the key, and nothing further up.
cmt="$(printf '%s\n' "$fmblock" | awk '/^#/ { c = c $0 "\n"; next } /^ac_digest:/ { printf "%s", c; exit } { c = "" }')"
printf '%s' "$cmt" | grep -q 'unverifiable' && ok "its comment names unverifiable" || bad "its comment does not name unverifiable"

# --- AC11-AC13: the prose half -----------------------------------------------------------------
echo "AC11 — queue and design stamp ac_digest from ./next --ac-digest where they write criteria"
grep -q 'write `ac_digest:` from `./next --ac-digest <id>`' "$ROOT/skills/queue/SKILL.md" \
  && ok "queue instructs stamping" || bad "queue does not instruct stamping ac_digest"
grep -q 'write `ac_digest:` from `./next --ac-digest <id>`' "$ROOT/skills/design/SKILL.md" \
  && ok "design instructs stamping" || bad "design does not instruct stamping ac_digest"

echo "AC12 — develop hands a wrong or impossible criterion to queue"
grep -q 'a criterion is wrong or impossible, \*\*stop\*\*' "$ROOT/skills/develop/SKILL.md" \
  && ok "develop says to stop on a wrong or impossible criterion" || bad "develop's stop instruction is missing"
grep -q 'which `ACn`, why, and the proposed text' "$ROOT/skills/develop/SKILL.md" \
  && ok "develop names the ACn and proposed text" || bad "develop does not name the ACn and proposed text"
grep -q '`./handoff <id> <token> queue`. It does not edit the criterion' "$ROOT/skills/develop/SKILL.md" \
  && ok "develop hands it to queue without editing" || bad "develop's hand-off to queue is missing"

echo "AC13 — verify takes the stale-contract branch on a mismatch and records absent as unverifiable"
grep -q 'a digest mismatch is a stale contract' "$ROOT/skills/verify/SKILL.md" \
  && ok "verify routes a mismatch as a stale contract" || bad "verify's mismatch branch is missing"
grep -q 'never passes a criterion whose text the author did not write' "$ROOT/skills/verify/SKILL.md" \
  && ok "verify never passes an unauthored criterion" || bad "verify's never-pass sentence is missing"
grep -q 'record `ac_digest absent — unverifiable`' "$ROOT/skills/verify/SKILL.md" \
  && ok "verify records absent as unverifiable" || bad "verify's absent sentence is missing"

# --- AC14 is tests/backlog-scripts-installed.test.sh, run by the suite ------------------------

echo
echo "ac-digest: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
