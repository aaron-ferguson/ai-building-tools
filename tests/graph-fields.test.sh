#!/bin/sh
#
# The ticket template carries the graph fields (0005).
#
# A ticket's place in the graph — what it belongs to, what must close first, what merely relates —
# had no slot in `templates/item.md`, so both facts lived only in the head of whoever queued the
# work. 0006 parses these fields and 0008 writes rules citing them; neither can be built against a
# shape that does not exist.
#
# What this guards is not "the key is there" but the two things that go wrong once it is:
#
#   * A field with no stated DIRECTION is a field two sessions fill in opposite ways. `parent:`
#     pointing up and `blocked_by:` naming what must close FIRST are not deducible from the names,
#     and a backlog holding both readings is unparseable by anything. So each case asserts on the
#     comment's direction words, never on the bare key.
#   * The reverse edge gets stored. Writing `children:` is the obvious next helpful edit, and it is
#     the one that rots: two places to update, and the derived one is always the stale one.
#
# The effort/task rule is asserted in the same file because it is what `parent:` MEANS — a ticket
# with children is never ranked or claimed, and a template that adds the field without the rule
# invites a session to rank an effort.
#
# Usage:  tests/graph-fields.test.sh
#
# Requires: sh, grep. No runner — this project has none.

set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
ITEM="$ROOT/skills/queue/templates/item.md"
QUEUE="$ROOT/skills/queue/templates/QUEUE.md"
README="$ROOT/README.md"
for f in "$ITEM" "$QUEUE" "$README"; do
  [ -f "$f" ] || { echo "no file at $f" >&2; exit 2; }
done

PASS=0
FAIL=0

ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }

# present <label> <file> <fixed-string>
present() {
  if grep -qF "$3" "$2"; then ok "$1"; else bad "$1 — expected to find: $3"; fi
}

# absent <label> <file> <fixed-string>
absent() {
  if grep -qF "$3" "$2"; then bad "$1 — expected NOT to find: $3"; else ok "$1"; fi
}

# frontmatter <file> — the text between the first two `---` lines, so a key demonstrated in the
# template's PROSE is never mistaken for a key the frontmatter declares.
frontmatter() {
  awk 'BEGIN{n=0} /^---$/{n++; if(n==2) exit; next} n==1' "$1"
}

FM="$(frontmatter "$ITEM")"

# comment_block <key> — the contiguous `#` comment block immediately above <key>: in the
# frontmatter, empty if the key is absent. Every assertion below reads a block rather than the
# whole file: a phrase found SOMEWHERE in a template that documents fourteen keys is no evidence
# it is attached to the one under test. Both FR2 phrases already matched the old template's
# `status:` and `expects:` comments before any of this was written.
comment_block() {
  printf '%s\n' "$FM" | awk -v key="$1" '
    /^#/ { block = block $0 "\n"; next }
    $0 ~ "^" key ":" { printf "%s", block; exit }
    { block = "" }
  '
}

# in_block <label> <block> <phrase> — case-insensitive fixed match, so the emphasis capitals the
# template uses on the direction words are not what a case changes red.
in_block() {
  if printf '%s\n' "$2" | grep -qiF "$3"; then ok "$1"; else bad "$1 — not in the block: $3"; fi
}

PARENT="$(comment_block parent)"
BLOCKED="$(comment_block blocked_by)"
RELATES="$(comment_block relates)"

echo "AC1/FR1 — the three graph fields, each with its direction stated on its own comment"
for pair in "parent:$PARENT" "blocked_by:$BLOCKED" "relates:$RELATES"; do
  key="${pair%%:*}"
  [ -n "${pair#*:}" ] || bad "AC1 — no \`$key:\` with a comment block in the frontmatter"
done
in_block "parent: points UP at the ticket this one belongs to" \
  "$PARENT" "the ticket this one belongs to"
in_block "parent: takes 0 or 1 id, not a list" "$PARENT" "0 or 1 id"
in_block "blocked_by: names the tickets that must close FIRST" \
  "$BLOCKED" "must close first"
in_block "blocked_by: holds dependencies, never dependents" "$BLOCKED" "never its dependents"
in_block "relates: is undirected and carries no scheduling meaning" \
  "$RELATES" "no scheduling meaning"

echo
echo "FR2 — the effort/task rule, in \`parent:\`'s own block, so the field is not added without what it means"
in_block "a ticket with children is an effort" "$PARENT" "a ticket with children is an effort"
in_block "an effort is never ranked, claimed, or built" "$PARENT" "never ranked, claimed, or built"
in_block "an effort holds the outcome and the scope" "$PARENT" "holds the outcome"
in_block "a ticket with no children is a task" "$PARENT" "a ticket with no children is a task"

echo
echo "FR4 — children are derived, never stored, and \`parent:\`'s block says why"
in_block "children are derived by one grep" "$PARENT" "one \`grep\`"
in_block "the reverse edge is never stored" "$PARENT" "never stored"
in_block "the why: a second place to update goes stale" "$PARENT" "goes stale"
absent   "no \`children:\` key was added alongside \`parent:\`" "$ITEM" "children:"

echo
echo "FR2 — and the template does not still call an effort a container"
absent "the superseded \`container ticket\` wording is gone" "$ITEM" "container ticket"

echo
echo "NFR migration — additive only: no pre-existing frontmatter key was dropped"
for key in id title type next status qa_level size created source expects claimed_by claimed_at touches; do
  if printf '%s\n' "$FM" | grep -q "^$key:"; then
    ok "\`$key:\` survives"
  else
    bad "NFR migration — \`$key:\` was dropped from the frontmatter"
  fi
done

echo
echo "FR5/AC3 — no epics/, no EPICS.md, no second template for efforts"
found=""
for d in "$ROOT/skills" "$ROOT/references" "$ROOT/tests"; do
  [ -d "$d" ] || continue
  hit="$(find "$d" \( -iname 'epics' -o -iname 'EPICS.md' -o -iname 'effort.md' \) -print 2>/dev/null || true)"
  [ -n "$hit" ] && found="$found $hit"
done
if [ -z "$found" ]; then
  ok "one items/ directory and one file format covers both states"
else
  bad "FR5 — a separate effort container exists:$found"
fi

echo
echo "AC4 — the README's storage-layout block shows the shipped shape"
absent "no \`epics/\` directory in the README" "$README" "epics/"
absent "no \`Owner\` column in the README" "$README" "| Owner"
present "the QUEUE template still carries the Parent column" "$QUEUE" "| Parent |"
absent  "the QUEUE template carries no Owner column" "$QUEUE" "| Owner"

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" = 0 ]
