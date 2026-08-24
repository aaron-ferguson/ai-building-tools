#!/bin/sh
#
# Guard for the script install in this repo's own backlog (0027).
#
# This repo ships next, claim and close as skills/queue/templates/ and instantiates them into a
# *new* project's backlog at queue Step 0. This backlog predates that step, so the one project
# developing the scripts was the only project without them — six sessions hit it on 2026-08-23.
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

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
BACKLOG="$ROOT/.claude/backlog"
TEMPLATES="$ROOT/skills/queue/templates"
SCRIPTS="next claim close"

[ -d "$BACKLOG" ]   || { echo "no backlog at $BACKLOG" >&2; exit 2; }
[ -d "$TEMPLATES" ] || { echo "no templates at $TEMPLATES" >&2; exit 2; }

PASS=0
FAIL=0

ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }

echo "AC1 — all three are installed and executable"
for s in $SCRIPTS; do
  if [ -f "$BACKLOG/$s" ]; then ok "$s exists"; else bad "$s missing from .claude/backlog/"; fi
  if [ -x "$BACKLOG/$s" ]; then ok "$s is executable"; else bad "$s is not executable (chmod +x)"; fi
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
  ok ".claude/backlog/.lock/ is ignored"
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

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" = 0 ]
