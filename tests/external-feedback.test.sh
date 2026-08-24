#!/bin/sh
#
# Notion is out of the base suite (0030).
#
# Notion was wired in as though it were a default: named in `queue`'s description metadata, given
# its own row and procedure in Step 5, and shipped as `references/NOTION.md` at the plugin root.
# Every project scaffolded by this suite therefore inherited one person's answer to "where does
# other people's feedback live". That is a PREFERENCE, and CONVENTIONS_CORE.md puts preferences
# behind a profile. The capability was not withdrawn — the extension point is documented in
# references/EXTERNAL-FEEDBACK.md and a profile wires a product into it.
#
# This guard exists because the removal is only ever one helpful edit from being undone: the
# integration is useful, so a later session re-adding "e.g. Notion" as an illustration is the
# likely regression, not a deliberate reversal. Naming a specific product is the thing being
# guarded, so the check is a grep for the product name rather than for a config key.
#
# Usage:  tests/external-feedback.test.sh
#
# Requires: sh, grep. No runner — this project has none.

set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

# The one file allowed to name a product, because its whole job is to tell a profile author what
# to wire in, and an extension point with no worked example of a source is an abstraction nobody
# can implement against.
EXEMPT="references/EXTERNAL-FEEDBACK.md"

PASS=0
FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }

FIX=""
cleanup() { [ -n "$FIX" ] && rm -rf "$FIX"; return 0; }
trap cleanup EXIT INT TERM

# mentions <root> <exempt-relative-path> — prints one "path:line:text" per Notion mention in the
# shipped tree, excluding the exempt file. The exempt path is a parameter so the fixture cases can
# drive both the caught and the allowed path without depending on the real tree.
#
# Scope is the SHIPPED tree only: skills/, references/, README.md. The backlog under .claude/ is
# this repo's own working record — ticket 0030 argues about Notion at length and must go on being
# able to, and a guard that reds on its own ticket teaches sessions to discount it.
mentions() {
  root="$1"
  exempt="${2:?mentions needs an exempt path}"
  # -r over a fixed file list rather than the whole root: a temp dir under test holds no .git to
  # skip, but the real root does, and grep -r would walk it.
  for target in skills references README.md; do
    [ -e "$root/$target" ] || continue
    grep -rin notion "$root/$target" 2>/dev/null | while IFS= read -r hit; do
      rel="${hit#"$root"/}"
      case "$rel" in "$exempt":*) continue ;; esac
      echo "$rel"
    done
  done
}

echo "AC1 — no shipped file names Notion outside the extension-point reference"
found="$(mentions "$ROOT" "$EXEMPT")"
if [ -z "$found" ]; then
  ok "skills/, references/ and README.md name no specific feedback product"
else
  OLDIFS="$IFS"; IFS='
'
  for line in $found; do bad "names Notion: $line"; done   # in this shell, so each breach counts
  IFS="$OLDIFS"
fi

echo "AC1 — the extension point itself exists"
if [ -f "$ROOT/$EXEMPT" ]; then
  ok "$EXEMPT is present"
else
  bad "AC1 — $EXEMPT is missing; the exemption above would then excuse nothing"
fi

echo "FR4 — references/NOTION.md no longer ships"
if [ -f "$ROOT/references/NOTION.md" ]; then
  bad "FR4 — references/NOTION.md still ships in the base suite"
else
  ok "references/NOTION.md is gone from the base suite"
fi

echo "AC2 — the shipped config template carries no external-feedback block"
if grep -qi 'notion' "$ROOT/skills/queue/templates/config.yml" 2>/dev/null; then
  bad "AC2 — templates/config.yml still carries a notion: block"
else
  ok "templates/config.yml carries no notion: key"
fi

echo "AC3 — the skill's description metadata names no product"
# The frontmatter only: a mention in the body is AC1's business, and conflating them would report
# one breach twice under two different requirements.
desc="$(awk '/^---$/{n++; next} n==1' "$ROOT/skills/queue/SKILL.md")"
case "$desc" in
  *[Nn]otion*) bad "AC3 — queue's frontmatter description still names Notion" ;;
  *)           ok "queue's frontmatter names no specific product" ;;
esac

echo "AC6 — the item template's source: field uses a generic external example"
src="$(grep -n '^source:' "$ROOT/skills/queue/templates/item.md" || true)"
case "$src" in
  *notion*) bad "AC6 — source: still uses notion:<page-id> as its example — $src" ;;
  "")       bad "AC6 — no source: line found in templates/item.md" ;;
  *)        ok "source: reads ${src#*:}" ;;
esac

# The cases below prove the guard can fail. A guard only ever seen passing is indistinguishable
# from one wired to nothing, so each feeds it the exact breach it exists to catch.
FIX="$(mktemp -d)"
mkdir -p "$FIX/references" "$FIX/skills/queue"

echo "FR4 — a reintroduced mention is caught, and named with its path"
printf 'Import reported feedback from Notion when configured.\n' > "$FIX/skills/queue/SKILL.md"
out="$(mentions "$FIX" "$EXEMPT")"
case "$out" in
  *"skills/queue/SKILL.md"*) ok "a reintroduced mention is reported with its path" ;;
  "") bad "FR4 — a reintroduced mention was NOT reported; the guard is wired to nothing" ;;
  *)  bad "FR4 — reported something else: $out" ;;
esac

echo "FR5 — the extension-point file may name a product; nothing else may"
printf 'A source such as Notion provides a query and a stable id.\n' > "$FIX/$EXEMPT"
rm -f "$FIX/skills/queue/SKILL.md"
out="$(mentions "$FIX" "$EXEMPT")"
if [ -z "$out" ]; then
  ok "the exempt file naming a product is allowed"
else
  bad "FR5 — the exempt file was reported: $out"
fi

echo "FR5 — the exemption is one named path, not any file mentioning it"
printf 'See Notion for the mapping.\n' > "$FIX/references/OTHER.md"
out="$(mentions "$FIX" "$EXEMPT")"
case "$out" in
  *"references/OTHER.md"*)
    case "$out" in
      *EXTERNAL-FEEDBACK*) bad "FR5 — the exempt file was reported alongside it: $out" ;;
      *) ok "a second reference file is caught while the exempt one is not" ;;
    esac ;;
  *) bad "FR5 — the non-exempt file was not reported: ${out:-<nothing>}" ;;
esac

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" = 0 ]
