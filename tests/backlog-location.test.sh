#!/bin/sh
#
# Guard for where the backlog lives (0182): `.backlog/` at the repo root, `.claude/backlog/` legacy.
#
# WHY THIS EXISTS. The harness refuses writes under any `.claude` path segment as a "sensitive
# file", and every stage writing a backlog there improvised a route around it while holding the
# lock. The fix is to move the backlog, so what has to stay true is mechanical: the scripts work at
# both locations and say which one they are at, a repo holding both is refused, `migrate` moves one
# as a single commit or refuses changing nothing, and the legacy path names nowhere but the places
# allowed to name it. The scripts are RUN against authored fixture repos; the prose is grepped.
#
# Usage:  tests/backlog-location.test.sh
#
# Requires: sh, git, awk, grep. No runner — this project has none.

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
TEMPLATES="$ROOT/skills/queue/templates"
CONC="$ROOT/references/CONCURRENCY.md"
SKILL_SPRINT="$ROOT/skills/sprint/SKILL.md"
SCRIPTS="claim close handoff next reopen"
LEGACY_NOTE='legacy .claude/backlog/'

PASS=0
FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }

WORK="$(mktemp -d)"
cleanup() { rm -rf "$WORK"; return 0; }
trap 'announce_abort cleanup' EXIT
trap cleanup INT TERM

# section <file> <heading> — the body under that `## ` heading, line structure kept.
section() {
  awk -v want="## $2" 'index($0, want) == 1 { on = 1; next } on && /^#{1,2} / { exit } on' "$1"
}

# mk_repo <dir> <backlog path relative to the repo> — a committed repo with one takeable row and
# one closed row, every script installed at that location.
mk_repo() {
  rm -rf "$1"; mkdir -p "$1/$2/items"
  git -C "$1" init -q
  git -C "$1" config user.email test@example.invalid
  git -C "$1" config user.name "location test"
  b="$1/$2"
  printf '# Backlog\n\n| ID | Title | Next | Status | Parent |\n|------|-------|------|--------|--------|\n| 0001 | Fixture row | develop | ready |  |\n' > "$b/QUEUE.md"
  printf '# Done\n\n| ID | Title | Closed | Commit |\n|----|-------|--------|--------|\n' > "$b/DONE.md"
  printf 'project: fixture\nnext_id: 2\nfindings_threshold: 8\nlock_stale_seconds: 900\n' > "$b/config.yml"
  : > "$b/FINDINGS.md"
  cat > "$b/items/0001-fixture.md" <<'ITEM'
---
id: "0001"
title: Fixture row
type: bug
next: develop
status: ready
qa_level: unit
size: s
blocked_by: []
relates: []
expects:
claimed_by:
claimed_at:
touches:
---

## Problem

Fixture.

## Notes & decisions
ITEM
  for s in $SCRIPTS migrate; do cp "$TEMPLATES/$s" "$b/$s"; chmod +x "$b/$s"; done
  printf '%s/.lock/\n%s/runs/\n' "$2" "$2" > "$1/.gitignore"
  git -C "$1" add -A
  git -C "$1" commit -q -m fixture
}

# run_in <repo> <backlog path> <script> [args...] — sets RC, OUT (stdout), ERR (stderr).
run_in() {
  r="$1"; p="$2"; s="$3"; shift 3
  if (cd "$r" && "./$p/$s" "$@" >"$WORK/out" 2>"$WORK/err"); then RC=0; else RC=$?; fi
  OUT="$(cat "$WORK/out")"; ERR="$(cat "$WORK/err")"
}
legacy_lines() { printf '%s\n' "$ERR" | grep -cF "$LEGACY_NOTE" || true; }

# exercise <repo> <backlog path> — every script once, through the paths that need no closable row.
# Echoes one line per script: "<script> <rc> <legacy-line count> <refused-two-backlogs 0|1>".
exercise() {
  run_in "$1" "$2" next develop;           echo "next $RC $(legacy_lines) $(printf '%s' "$ERR" | grep -c 'two backlogs' || true) $(printf '%s' "$OUT" | grep -c '^TAKE *0001' || true)"
  run_in "$1" "$2" claim 0001 ab12;        echo "claim $RC $(legacy_lines) $(printf '%s' "$ERR" | grep -c 'two backlogs' || true) 1"
  run_in "$1" "$2" handoff 0001 ab12 verify; echo "handoff $RC $(legacy_lines) $(printf '%s' "$ERR" | grep -c 'two backlogs' || true) 1"
  run_in "$1" "$2" close 0001 zz99;        echo "close $RC $(legacy_lines) $(printf '%s' "$ERR" | grep -c 'two backlogs' || true) 1"
  run_in "$1" "$2" reopen 0001 top 'a fixture reason'; echo "reopen $RC $(legacy_lines) $(printf '%s' "$ERR" | grep -c 'two backlogs' || true) 1"
}

# ------------------------------------------------------------------------------------------------
echo "AC1 — at .backlog/ every script works and none prints the legacy line"
NEW="$WORK/new"
mk_repo "$NEW" .backlog
exercise "$NEW" .backlog > "$WORK/ex-new"
while read -r s rc n two take; do
  case "$s" in
    next|claim|handoff) want_rc=0 ;;
    *) want_rc=nonzero ;;   # close and reopen refuse this row on its merits, which is today's behaviour
  esac
  if [ "$n" = 0 ] && [ "$two" = 0 ] && { [ "$want_rc" = nonzero ] || [ "$rc" = 0 ]; } && [ "$take" = 1 ]; then
    ok "$s at .backlog/: exit $rc, no legacy line"
  else
    bad "0182 AC1 — $s at .backlog/: exit $rc, $n legacy line(s), two-backlogs refusal $two, TAKE $take"
  fi
done < "$WORK/ex-new"
if git -C "$NEW" log --oneline | grep -q 'Hand off 0001\|0001.*verify'; then
  ok "the claim and the hand-off committed at .backlog/"
else
  bad "0182 AC1 — no hand-off commit at .backlog/: $(git -C "$NEW" log --oneline | tr '\n' '|')"
fi

echo "AC2 — at .claude/backlog/ every script still works and prints exactly one legacy line"
OLD="$WORK/old"
mk_repo "$OLD" .claude/backlog
exercise "$OLD" .claude/backlog > "$WORK/ex-old"
while read -r s rc n two take; do
  case "$s" in next|claim|handoff) want_rc=0 ;; *) want_rc=nonzero ;; esac
  if [ "$n" = 1 ] && [ "$two" = 0 ] && { [ "$want_rc" = nonzero ] || [ "$rc" = 0 ]; } && [ "$take" = 1 ]; then
    ok "$s at .claude/backlog/: exit $rc, exactly one legacy line"
  else
    bad "0182 AC2 — $s at .claude/backlog/: exit $rc, $n legacy line(s), two-backlogs refusal $two, TAKE $take"
  fi
done < "$WORK/ex-old"
run_in "$OLD" .claude/backlog next develop
if printf '%s\n' "$ERR" | grep -F "$LEGACY_NOTE" | grep -qF './migrate' && \
   printf '%s\n' "$ERR" | grep -F "$LEGACY_NOTE" | grep -qF '2026-12-31'; then
  ok "the legacy line names ./migrate and 2026-12-31"
else
  bad "0182 AC2 — the legacy line does not name ./migrate and 2026-12-31: $ERR"
fi
# `close` runs `next` inside itself and shows its output; the exported note is what stops the line
# printing twice there. Asserted on the mechanism, since reaching that call needs a closable row.
if (cd "$OLD" && BACKLOG_LEGACY_NOTED=1 ./.claude/backlog/next develop 2>&1) | grep -qF "$LEGACY_NOTE"; then
  bad "0182 AC2 — next prints the legacy line again inside a call that already printed it"
else
  ok "a nested call, under the exported note, prints no second legacy line"
fi
# The case above sets the variable by hand, so it proves `next` honours the note and never that the
# block EXPORTS it: dropping `export BACKLOG_LEGACY_NOTED` left the whole suite green while `close`
# printed the line twice (0182 verify, token 1166). So `close` itself is driven, without the
# variable, into its nested `"$DIR/next" --ac-digest --check` call — a stale `ac_digest:` is the
# cheapest refusal that reaches it — and the legacy lines in its stderr are counted.
NEST="$WORK/nest"
mk_repo "$NEST" .claude/backlog
NEST_ITEM="$NEST/.claude/backlog/items/0001-fixture.md"
awk '/^qa_level:/ { print; print "ac_digest: AC1=00000000"; next }
     /^## Notes & decisions/ { print "## Acceptance criteria"; print ""; print "- [ ] AC1 — Given a fixture, when it is closed, then it closes."; print "" }
     { print }' "$NEST_ITEM" > "$WORK/nest-item" && cat "$WORK/nest-item" > "$NEST_ITEM"
git -C "$NEST" add .claude/backlog/items
git -C "$NEST" commit -q -m "stale digest"
run_in "$NEST" .claude/backlog claim 0001 ab12
run_in "$NEST" .claude/backlog handoff 0001 ab12 verify
run_in "$NEST" .claude/backlog claim 0001 ab12
unset BACKLOG_LEGACY_NOTED
run_in "$NEST" .claude/backlog close 0001 ab12
n="$(legacy_lines)"
if [ "$RC" -ne 0 ] && printf '%s\n' "$ERR" | grep -qF 'ac_digest differs' && [ "$n" = 1 ]; then
  ok "close, through its nested next call, prints exactly one legacy line"
else
  bad "0182 AC2 — close on a stale-digest legacy fixture: exit $RC, $n legacy line(s) in stderr, expected 1 and the ac_digest refusal: $ERR"
fi

echo "AC3 — a repo holding both locations is refused from either, and nothing is written"
BOTH="$WORK/both"
mk_repo "$BOTH" .claude/backlog
mkdir -p "$BOTH/.backlog"
cp -R "$BOTH/.claude/backlog/." "$BOTH/.backlog/"
git -C "$BOTH" add -A
git -C "$BOTH" commit -q -m "both"
for p in .backlog .claude/backlog; do
  run_in "$BOTH" "$p" next develop
  if [ "$RC" != 0 ] && printf '%s' "$ERR" | grep -qF "$BOTH/.backlog" && printf '%s' "$ERR" | grep -qF "$BOTH/.claude/backlog" \
     && [ -z "$(git -C "$BOTH" status --porcelain)" ] && [ ! -d "$BOTH/$p/.lock" ]; then
    ok "from $p: exit $RC naming both paths, nothing written"
  else
    bad "0182 AC3 — from $p: exit $RC, stderr '$ERR', status '$(git -C "$BOTH" status --porcelain | tr '\n' ' ')'"
  fi
done
run_in "$BOTH" .backlog claim 0001 ab12
if [ "$RC" != 0 ] && [ -z "$(git -C "$BOTH" status --porcelain)" ]; then
  ok "and claim is refused there too, before any write"
else
  bad "0182 AC3 — claim ran in a repo holding two backlogs (exit $RC)"
fi

echo "AC4 — migrate moves a legacy backlog as one commit, and a second run says it is done"
MIG="$WORK/mig"
mk_repo "$MIG" .claude/backlog
mkdir -p "$MIG/.claude/backlog/runs" && printf '{"event":"x"}\n' > "$MIG/.claude/backlog/runs/r.jsonl"
BEFORE="$(git -C "$MIG" rev-list --count HEAD)"
run_in "$MIG" .claude/backlog migrate
if [ "$RC" = 0 ] && [ -f "$MIG/.backlog/QUEUE.md" ] && [ -f "$MIG/.backlog/items/0001-fixture.md" ] && [ ! -e "$MIG/.claude/backlog" ]; then
  ok ".backlog/ holds the tree and .claude/backlog/ is gone"
else
  bad "0182 AC4 — migrate exit $RC: $ERR; .backlog/QUEUE.md $( [ -f "$MIG/.backlog/QUEUE.md" ] && echo present || echo absent), .claude/backlog $( [ -e "$MIG/.claude/backlog" ] && echo present || echo gone)"
fi
if [ -f "$MIG/.backlog/runs/r.jsonl" ] && [ ! -d "$MIG/.backlog/.lock" ]; then
  ok "the machine-local runs/ moved with it, and the lock is released at its new path"
else
  bad "0182 AC4 — runs/ did not move, or the lock was left held"
fi
if grep -qF '.backlog/.lock/' "$MIG/.gitignore" && ! grep -qF '.claude/backlog/' "$MIG/.gitignore"; then
  ok "the root .gitignore names .backlog/ paths"
else
  bad "0182 AC4 — .gitignore: $(tr '\n' ' ' < "$MIG/.gitignore")"
fi
AFTER="$(git -C "$MIG" rev-list --count HEAD)"
STATUS_LINES="$(git -C "$MIG" log -1 --name-status --format= | grep -c . || true)"
ODD="$(git -C "$MIG" log -1 --name-status --format= | grep -vE '^R[0-9]*	\.claude/backlog/[^	]+	\.backlog/|^M	\.gitignore$' || true)"
if [ "$AFTER" = $((BEFORE + 1)) ] && [ "$STATUS_LINES" -gt 1 ] && [ -z "$ODD" ]; then
  ok "one commit, holding only the renames and the .gitignore change"
else
  bad "0182 AC4 — $((AFTER - BEFORE)) commit(s); entries outside renames and .gitignore: $(printf '%s' "$ODD" | tr '\n' '|')"
fi
if [ -z "$(git -C "$MIG" status --porcelain)" ]; then ok "and the tree is clean"; else bad "0182 AC4 — tree dirty after migrate"; fi
run_in "$MIG" .backlog migrate
if [ "$RC" = 0 ] && printf '%s' "$OUT" | grep -qi 'already migrated' && [ "$(git -C "$MIG" rev-list --count HEAD)" = "$AFTER" ]; then
  ok "a second run exits 0 saying the repo is already migrated, and commits nothing"
else
  bad "0182 AC4 — second run: exit $RC, '$OUT$ERR'"
fi
run_in "$MIG" .backlog next develop
if [ "$RC" = 0 ] && [ "$(legacy_lines)" = 0 ]; then ok "the migrated backlog's next runs with no legacy line"; else bad "0182 AC4 — next after migrate: exit $RC, $ERR"; fi

echo "AC5 — migrate refuses each unsafe state, naming it and changing nothing"
refusal_case() { # <label> <expected phrase> — the fixture at $REF is already set up
  head_before="$(git -C "$REF" rev-parse HEAD)"
  run_in "$REF" .claude/backlog migrate
  if [ "$RC" != 0 ] && printf '%s' "$ERR" | grep -qiF "$2" && [ -z "$(git -C "$REF" status --porcelain)" ] \
     && [ "$(git -C "$REF" rev-parse HEAD)" = "$head_before" ] && [ -f "$REF/.claude/backlog/QUEUE.md" ]; then
    ok "$1: refused naming '$2', status empty, HEAD unchanged"
  else
    bad "0182 AC5 — $1: exit $RC, stderr '$ERR', status '$(git -C "$REF" status --porcelain | tr '\n' ' ')'"
  fi
}
REF="$WORK/ref"
mk_repo "$REF" .claude/backlog
mkdir "$REF/.claude/backlog/.lock" && printf 'claim 0001 by cd34\n' > "$REF/.claude/backlog/.lock/held-by"
refusal_case "a held lock" "lock is held"
if [ -d "$REF/.claude/backlog/.lock" ]; then ok "and the other session's lock is left in place"; else bad "0182 AC5 — migrate removed a lock it did not take"; fi

mk_repo "$REF" .claude/backlog
sed -i.bak 's/^claimed_by:$/claimed_by: ef56/' "$REF/.claude/backlog/items/0001-fixture.md" && rm -f "$REF/.claude/backlog/items/0001-fixture.md.bak"
git -C "$REF" commit -q -am "held by another"
refusal_case "a row claimed by another token" "claimed by another token"
run_in "$REF" .claude/backlog migrate ef56
if [ "$RC" = 0 ] && [ -d "$REF/.backlog" ]; then ok "and given that row's own token, it proceeds"; else bad "0182 FR3 — migrate refused its own token: $ERR"; fi

mk_repo "$REF" .claude/backlog
mkdir -p "$REF/.claude/backlog/runs/.active" && printf 'run-fx-0182 2026-10-25T00:00:00Z\n' > "$REF/.claude/backlog/runs/.active/held-by"
refusal_case "a sprint marker" "sprint marker"

mk_repo "$REF" .claude/backlog
mkdir -p "$REF/.backlog" && printf 'x\n' > "$REF/.backlog/keep"
git -C "$REF" add .backlog/keep && git -C "$REF" commit -q -m "a pre-existing .backlog"
refusal_case "a pre-existing .backlog/" ".backlog already exists"

echo "AC6 — CONCURRENCY.md carries one section on a refused backlog write"
REFUSED="$(section "$CONC" "When a backlog write is refused")"
for phrase in \
  "split a compound call into single commands first" \
  "on the legacy path, \`python3\` is the route that has landed every time" \
  "a lock release never ends on \"refused\"" \
  "quotes the exact refused commands, never a summary"; do
  if printf '%s\n' "$REFUSED" | grep -qiF -- "$phrase"; then
    ok "it says: $phrase"
  else
    bad "0182 AC6 — *When a backlog write is refused* does not say, on one line: $phrase"
  fi
done

echo "AC7 — the legacy path appears only where it is allowed, and the copies of its date agree"
WHERE="$(section "$CONC" "Where the backlog lives")"
[ -n "$WHERE" ] || bad "0182 FR1 — references/CONCURRENCY.md has no *Where the backlog lives* section"
# allowed <file> <line number> <line text> — 0 when this hit is in the allowlist.
range_of() { awk -v want="$2" 'index($0, want) == 1 { s = NR; next } s && !e && /^#{1,2} / { e = NR - 1 } END { if (s) print s, (e ? e : NR) }' "$1"; }
WL="$(range_of "$CONC" "## Where the backlog lives")"
RL="$(range_of "$CONC" "## When a backlog write is refused")"
in_range() { [ -n "$2" ] && [ "$1" -ge "${2% *}" ] && [ "$1" -le "${2#* }" ]; }
block_range() { awk '/^# --- where the backlog lives \(0182\)/ { s = NR } /^# --- end of where the backlog lives ---$/ { print s, NR; exit }' "$1"; }
STRAY=""
HITS="$(cd "$ROOT" && grep -rnF '.claude/backlog' skills references || true)"
while IFS= read -r hit; do
  [ -n "$hit" ] || continue
  f="${hit%%:*}"; rest="${hit#*:}"; n="${rest%%:*}"; text="${rest#*:}"
  case "$f" in
    skills/queue/templates/migrate) continue ;;
    references/CONCURRENCY.md) if in_range "$n" "$WL" || in_range "$n" "$RL"; then continue; fi ;;
    skills/queue/templates/claim|skills/queue/templates/close|skills/queue/templates/handoff|skills/queue/templates/next|skills/queue/templates/reopen)
      if in_range "$n" "$(block_range "$ROOT/$f")"; then continue; fi
      case "$f:$text" in *next:*'tbuf="$troot/.claude/backlog/FINDINGS.md"'*) continue ;; esac ;;
  esac
  STRAY="$STRAY
  $f:$n"
done <<HITS
$HITS
HITS
if [ -z "$STRAY" ]; then
  ok "every .claude/backlog in skills/ and references/ is in the allowlist"
else
  bad "0182 AC7 — .claude/backlog outside the allowlist:$STRAY"
fi
FIRST_BLOCK=""
for s in $SCRIPTS; do
  b="$(awk '/^# --- where the backlog lives \(0182\)/,/^# --- end of where the backlog lives ---$/' "$TEMPLATES/$s")"
  if [ -z "$b" ]; then bad "0182 AC7 — $s carries no location block"; continue; fi
  if [ -z "$FIRST_BLOCK" ]; then FIRST_BLOCK="$b"; ok "$s carries the location block"
  elif [ "$b" = "$FIRST_BLOCK" ]; then ok "$s's location block is byte-identical to claim's"
  else bad "0182 AC7 — $s's location block differs from claim's"; fi
done
BLOCK_DATE="$(printf '%s\n' "$FIRST_BLOCK" | sed -n 's/^LEGACY_UNTIL=\([0-9-]*\)$/\1/p')"
DOC_DATES="$(printf '%s\n' "$WHERE" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | sort -u)"
if [ -n "$BLOCK_DATE" ] && [ "$DOC_DATES" = "$BLOCK_DATE" ]; then
  ok "the block's LEGACY_UNTIL ($BLOCK_DATE) is the one date *Where the backlog lives* names"
else
  bad "0182 AC7/FR5 — block date '${BLOCK_DATE:-none}' against section date(s) '$(printf '%s' "$DOC_DATES" | tr '\n' ' ')'"
fi

echo "AC8 — sprint Step 3 cites the shared section and no longer says to cp a backlog file into place"
STEP3="$(section "$SKILL_SPRINT" "Step 3")"
if printf '%s\n' "$STEP3" | grep -qF '*When a backlog write is refused*'; then
  ok "Step 3 cites *When a backlog write is refused*"
else
  bad "0182 AC8 — Step 3 does not cite *When a backlog write is refused*"
fi
if printf '%s\n' "$STEP3" | tr '\n' ' ' | grep -qiE '`?cp`? (it|the file|them) into place'; then
  bad "0182 AC8 — Step 3 still says to cp a backlog file into place"
else
  ok "Step 3 no longer says to cp a backlog file into place"
fi

echo "AC9 — CHANGELOG ## Unreleased names the move, ./migrate, the legacy end and the install order"
UNREL="$(section "$ROOT/CHANGELOG.md" "Unreleased")"
for phrase in '`.backlog/`' '`./migrate`' '2026-12-31' 'install' '`tools/release verify`'; do
  if printf '%s\n' "$UNREL" | grep -qF -- "$phrase"; then ok "Unreleased names $phrase"
  else bad "0182 AC9 — ## Unreleased does not name $phrase"; fi
done

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
TALLIED=1
[ "$FAIL" -eq 0 ]
