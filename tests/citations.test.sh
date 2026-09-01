#!/bin/sh
#
# Citation guard: CONCURRENCY.md rule names (0033), and conventions filenames (0052).
#
# TWO KINDS, one file, because both answer "does this citation still resolve?" — the first against
# the rule headings of references/CONCURRENCY.md, the second against the conventions directory
# config.yml points at. The second exists because these skills cite a SEPARATE REPO: a conventions
# file renamed or dropped there leaves a citation here that reads perfectly and resolves to nothing.
#
# WHAT THE CONVENTIONS CHECK DOES NOT DO, stated because 0052 found the gap by assuming it did.
# It resolves the FILENAME, never the rule phrase inside it. Checking the phrase needs a citation
# marker this repo does not have: italics carry emphasis all over these files, so reading an
# italicised span after a conventions filename as a rule name reports three existing spots that are
# emphasis rather than citations. Introducing that marker is a decision, not detail, and is parked
# in FINDINGS.md rather than guessed at here. So: a citation whose FILE is gone is caught; one whose
# cited RULE has been reworded inside a file that still exists is not.
#
# WHY THIS EXISTS:
#
# CONCURRENCY.md names its rules rather than numbering them, and tells every reader to cite by
# name. Nothing checked that a cited name still existed. Retitling *The two scripts* to
# *The three scripts* on 2026-08-23 broke two citations in CONCURRENCY-INCIDENTS.md, and a wrong
# rule name reads exactly like a correct one — the reader follows it, finds no such rule, and
# either guesses which rule was meant or writes the reference off as stale.
#
# Renaming a rule is never a one-file edit. This guard is the durable form of that sentence.
#
# HOW A CITATION IS RECOGNISED — read this before adding a citation the guard does not see:
#
# Italics carry emphasis all over these files, so "an italicised span" on its own would report
# most of the prose in the repo as a rule name. A citation is therefore an ANCHORED span:
#
#   anchor      a mention of CONCURRENCY.md / CONCURRENCY-INCIDENTS.md, the `rule:` marker used
#               in CONCURRENCY-INCIDENTS.md headings, or the `(*` of a bare parenthesised
#               self-reference inside CONCURRENCY.md itself
#   span        *single-asterisk emphasis*, or 'a single-quoted Capitalised phrase' — the form
#               the shell scripts use, where markdown emphasis would be noise
#   gap         at most GAP characters of connective text between the anchor and the span, so
#               "`CONCURRENCY.md`, *X*", "`CONCURRENCY.md`'s *X*" and "CONCURRENCY.md — 'X'" all
#               read as citations while a mention followed by a sentence of prose does not
#   chain       a further span joined by exactly " and ", for "*X* and *Y*" after one anchor
#
# Scoped to the markdown PARAGRAPH, never to a line count. A count cannot know where the
# paragraph ends, so it either stops short or reads into the next one — the adjacent-measurement
# failure 0032 was raised for. The paragraph boundary is the document's own, and cannot drift.
#
# The consequence to know, in both directions: an UNANCHORED rule name in running prose is not
# seen, by design.
#
#   What that buys — FR5. CONCURRENCY-INCIDENTS.md discusses a DELETED rule by name in narrative
#   ("*`verify` never writes the queue* made `verify` read-only..."). Anchoring is what spares it
#   without an exemption list; nothing else can tell it from a live citation.
#
#   What it costs — a genuine citation written with no anchor is not checked either.
#   CONCURRENCY-INCIDENTS.md has one: "The guard consulted the one place *Claim tokens* says
#   ownership does not live." Telling that from the emphasis three lines above it needs the very
#   answer the guard is computing, so widening the anchor cannot fix it. The cover this still
#   gives is what matters: renaming *The three scripts* was checked against a copy of the tree on
#   2026-08-24 and fired on 5 anchored citations across 4 files, which is more than enough to
#   send the author looking. Anchor a citation you want checked.
#
# Usage:  tests/citations.test.sh
#
# Requires: sh, awk, grep. No runner — this project has none.

set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

# Widest real connective in the corpus is "` at the plugin root, " at 22 characters
# (skills/verify/SKILL.md). 24 leaves room to phrase one differently without leaving the clause.
GAP=24

# A rule name is a heading, and the longest is 45 characters. The cap exists so a stray unpaired
# asterisk cannot pair across half a paragraph and report it as a citation.
MAXNAME=90

PASS=0
FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }

FIX=""
cleanup() { [ -n "$FIX" ] && rm -rf "$FIX"; return 0; }
trap cleanup EXIT INT TERM

# ---------------------------------------------------------------------------
# The guard itself. Every function takes the tree root as a parameter so the
# fixture cases below drive the real code path rather than a copy of it.
# ---------------------------------------------------------------------------

# rule_definitions <root> — one normalised rule name per line, from the ## and ### headings of
# references/CONCURRENCY.md. ### is included because "A pathspec is necessary but not sufficient"
# is a real rule at that depth and is cited by name; the `# Part N` h1s are not rules.
rule_definitions() {
  root="${1:?rule_definitions needs a tree root}"
  awk '/^###? /{ n = $0; sub(/^#+ +/, "", n); gsub(/[`*]/, "", n); print n }' \
    "$root/references/CONCURRENCY.md" 2>/dev/null || true
  # A missing or unreadable file yields nothing rather than an error on purpose: audit's
  # zero-definitions check turns that into a loud, named failure, and one report is clearer
  # than two.
}

# cited_files <root> — every file that cites by name, per FR2.
cited_files() {
  root="${1:?cited_files needs a tree root}"
  for f in "$root"/references/*.md "$root"/skills/*/SKILL.md "$root"/skills/queue/templates/* \
           "$root/.claude/backlog/QUEUE.md"; do
    [ -f "$f" ] && printf '%s\n' "$f"
  done
  return 0
}

# rule_citations <root> — "<path><TAB><name>" per citation found, per the recognition rule in
# this file's header. Records are markdown PARAGRAPHS (RS=""), so an anchor at the end of one
# paragraph can never reach a span at the start of the next.
#
# Q carries the apostrophe in as a variable: the single-quoted-span form is one of the two the
# guard recognises, and a literal apostrophe cannot appear inside a single-quoted awk program.
rule_citations() {
  root="${1:?rule_citations needs a tree root}"
  cited_files "$root" | while IFS= read -r file; do
    awk -v GAP="$GAP" -v MAXNAME="$MAXNAME" -v Q="'" '
      BEGIN { RS = ""; SPAN = "\\*[^*]+\\*|" Q "[A-Z][^" Q "]*" Q }

      # Prints every citation reachable from one anchor and leaves what follows them in REST.
      # A cursor-advancing scanner has to hand its position back somehow; a global keeps the
      # caller flat, which a second nested loop would not.
      function emit_spans(text, file,    first, gap, name) {
        first = 1
        while (match(text, SPAN)) {
          gap = substr(text, 1, RSTART - 1)
          if (first && length(gap) > GAP) break
          if (!first && gap != " and ") break
          name = substr(text, RSTART, RLENGTH)
          text = substr(text, RSTART + RLENGTH)
          gsub("^[*" Q "]|[*" Q "]$", "", name)
          gsub(/`/, "", name)
          sub(/^ +/, "", name); sub(/ +$/, "", name)
          if (length(name) > MAXNAME) break
          print file "\t" name
          first = 0
        }
        REST = text
      }

      {
        para = $0
        gsub(/\n/, " ", para)
        # Drop the bold DELIMITERS and keep their text, rather than dropping bold spans whole:
        # these files nest an italic inside a bold ("...row as *its files are held***"), and
        # removing the span whole would leave that unpaired asterisk to pair with the next one.
        gsub(/\*\*/, "", para)
        gsub(/[ \t]+/, " ", para)
        scan = para
        while (match(scan, /CONCURRENCY(-INCIDENTS)?\.md|rule:|\(\*/)) {
          # "(*" opens the span itself, so leave it for the span match; the other anchors do not.
          keep = (substr(scan, RSTART, 2) == "(*") ? 2 : 0
          emit_spans(substr(scan, RSTART + RLENGTH - keep), FILENAME)
          scan = REST
        }
      }
    ' "$file"
  done
}

# audit <root> — the whole verdict for a tree, as lines the callers assert on directly:
#   FAIL  …   a defect: a stale citation, or an empty set on either side
#   INFO  …   a rule defined and cited nowhere — not a defect (FR4), but how a rule quietly
#             stops being load-bearing
#   COUNT …   how many of each were extracted
audit() {
  root="${1:?audit needs a tree root}"
  defs="$(rule_definitions "$root")"
  cites="$(rule_citations "$root")"
  ndef="$(printf '%s' "$defs" | grep -c . || true)"
  ncite="$(printf '%s' "$cites" | grep -c . || true)"

  # FR6 — an empty set on either side makes every comparison below pass, so it is reported as a
  # defect in its own right rather than being allowed to look like a clean tree.
  [ "$ndef" -eq 0 ] &&
    echo "FAIL  no rule definitions extracted from references/CONCURRENCY.md — the heading recognition stopped matching"
  [ "$ncite" -eq 0 ] &&
    echo "FAIL  no citations extracted from any covered file — the citation recognition stopped matching"
  if [ "$ndef" -eq 0 ] || [ "$ncite" -eq 0 ]; then
    echo "COUNT $ndef definitions, $ncite citations"
    return 0
  fi

  printf '%s\n' "$cites" | while IFS='	' read -r file name; do
    [ -n "$name" ] || continue
    printf '%s\n' "$defs" | grep -qxF "$name" ||
      echo "FAIL  ${file#$root/} cites \"$name\", which is not a rule in CONCURRENCY.md"
  done

  printf '%s\n' "$defs" | while read -r name; do
    [ -n "$name" ] || continue
    printf '%s\n' "$cites" | cut -f2 | grep -qxF "$name" ||
      echo "INFO  rule \"$name\" is defined and cited nowhere"
  done

  echo "COUNT $ndef definitions, $ncite citations"
}

# ---------------------------------------------------------------------------
# 0052 — conventions filenames resolve in the conventions directory
# ---------------------------------------------------------------------------

# conventions_dir <root> — the conventions path from config.yml, resolved against the root. Prints
# nothing when the key or the directory is absent, which conventions_audit reports by name rather
# than skipping silently: a check that quietly stops running is the failure this suite exists for.
conventions_dir() {
  root="${1:?conventions_dir needs a tree root}"
  cfg="$root/.claude/backlog/config.yml"
  [ -f "$cfg" ] || return 0
  # The key is nested under `conventions:`, so match the indented `path:` inside that block only —
  # a document-wide grep for `path:` would take any other block's.
  rel="$(awk '/^conventions:/{inb=1; next} /^[^[:space:]#]/{inb=0} inb && $1=="path:"{print $2; exit}' "$cfg")"
  [ -n "$rel" ] || return 0
  case "$rel" in
    /*) [ -d "$rel" ] && printf '%s\n' "$rel" ;;
    *)  [ -d "$root/$rel" ] && (CDPATH= cd -- "$root/$rel" && pwd) ;;
  esac
  return 0
}

# conventions_mentions <root> — "<path><TAB><filename>" for every *-conventions.md named in a cited
# file. Deliberately NOT anchor-scoped: a bare filename in prose is still a claim that the file
# exists, and unlike a rule name there is no emphasis it can be confused with.
conventions_mentions() {
  root="${1:?conventions_mentions needs a tree root}"
  cited_files "$root" | while IFS= read -r file; do
    grep -oE '[a-z][a-z-]*-conventions\.md' "$file" 2>/dev/null | sort -u | while read -r name; do
      [ -n "$name" ] && printf '%s\t%s\n' "$file" "$name"
    done
  done
  return 0
}

# conventions_audit <root> — FAIL / SKIP / COUNT lines, in audit()'s shape.
conventions_audit() {
  root="${1:?conventions_audit needs a tree root}"
  dir="$(conventions_dir "$root")"
  mentions="$(conventions_mentions "$root")"
  nmention="$(printf '%s' "$mentions" | grep -c . || true)"

  if [ -z "$dir" ]; then
    echo "SKIP  no conventions directory resolved from config.yml — filename resolution not checked"
    echo "COUNT $nmention mentions, 0 checked"
    return 0
  fi
  # An empty mention set makes every comparison below pass, so it is a defect in its own right
  # rather than a clean tree (the same reasoning as audit()'s FR6 branch).
  if [ "$nmention" -eq 0 ]; then
    echo "FAIL  no conventions filenames extracted from any covered file — the recognition stopped matching"
    echo "COUNT 0 mentions, 0 checked"
    return 0
  fi

  printf '%s\n' "$mentions" | while IFS='	' read -r file name; do
    [ -n "$name" ] || continue
    [ -f "$dir/$name" ] ||
      echo "FAIL  ${file#$root/} cites \"$name\", which is not a file in $dir"
  done

  echo "COUNT $nmention mentions, $nmention checked"
}

echo "0052 AC6 — every conventions filename cited resolves in the conventions directory"
cout="$(conventions_audit "$ROOT")"
ccounts="$(printf '%s\n' "$cout" | grep '^COUNT ' || true)"
cstale="$(printf '%s\n' "$cout" | grep '^FAIL ' || true)"
cskip="$(printf '%s\n' "$cout" | grep '^SKIP ' || true)"
if [ -n "$cskip" ]; then
  # Reported as a failure, not a skip: this repo HAS a conventions path, so an unresolved one here
  # means the config or the sibling checkout moved, and every case below it proves nothing.
  bad "${cskip#SKIP  }"
elif [ -z "$cstale" ]; then
  ok "every conventions filename resolves — ${ccounts#COUNT }"
else
  OLDIFS="$IFS"; IFS='
'
  for l in $cstale; do bad "${l#FAIL  }"; done
  IFS="$OLDIFS"
fi

# ---------------------------------------------------------------------------
# AC1 — the shipped tree
# ---------------------------------------------------------------------------

echo "AC1 — the shipped tree has no stale citations, and both sets are non-empty"
out="$(audit "$ROOT")"
counts="$(printf '%s\n' "$out" | grep '^COUNT ' || true)"
stale="$(printf '%s\n' "$out" | grep '^FAIL ' || true)"
info="$(printf '%s\n' "$out" | grep '^INFO ' || true)"
if [ -z "$stale" ]; then
  ok "no stale citations — ${counts#COUNT }${info:+
$(printf '%s\n' "$info" | sed 's/^INFO  /       /')}"
else
  OLDIFS="$IFS"; IFS='
'
  for l in $stale; do bad "${l#FAIL  }"; done   # in this shell, so each stale citation counts
  IFS="$OLDIFS"
fi

# ---------------------------------------------------------------------------
# Fixture cases. Authored trees, never a copy of references/ — a guard that mutates the files it
# also measures reds on unrelated edits, and a guard whose reds can be artefacts trains everyone
# to discount its reds (testing-conventions.md).
# ---------------------------------------------------------------------------

FIX="$(mktemp -d)"

# mkfix <dir> — a minimal tree with two rules, both cited once.
mkfix() {
  dir="${1:?mkfix needs a target directory}"
  rm -rf "$dir"
  mkdir -p "$dir/references" "$dir/skills/develop" "$dir/skills/queue/templates" "$dir/.claude/backlog"
  cat > "$dir/references/CONCURRENCY.md" <<'FIXTURE'
# Fixture protocol

# Part 1 — fixture rules

## The first fixture rule

Body of the first rule.

## The second fixture rule

Body of the second rule.
FIXTURE
  cat > "$dir/skills/develop/SKILL.md" <<'FIXTURE'
# Fixture skill

Do the thing under the lock (`CONCURRENCY.md`, *The first fixture rule*).

Then do the other thing (`CONCURRENCY.md`, *The second fixture rule*).
FIXTURE
}

# mutate <file> <sed-script> <label> — applies the mutation and proves it landed (AC6). A
# mutation that silently failed to apply reads exactly like a guard that holds.
mutate() {
  cp "$1" "$FIX/.before"
  sed "$2" "$FIX/.before" > "$1"
  if diff "$FIX/.before" "$1" >/dev/null; then
    bad "AC6 — mutation \"$3\" produced no diff; the case below would prove nothing"
    return 1
  fi
  ok "AC6 — mutation \"$3\" landed (diff is non-empty)"
}

echo "AC2 — a renamed rule with its citations left alone fails, naming every stale citation"
mkfix "$FIX/t"
mutate "$FIX/t/references/CONCURRENCY.md" 's/## The first fixture rule/## The renamed fixture rule/' "rename a rule heading"
out="$(audit "$FIX/t")"
case "$out" in
  *'FAIL  skills/develop/SKILL.md cites "The first fixture rule", which is not a rule'*)
    ok "the stale citation is reported with its file and the name it used" ;;
  *) bad "AC2 — expected a stale-citation FAIL, got: ${out:-<nothing>}" ;;
esac

echo "AC3 — a citation of a rule that never existed fails, naming that citation"
mkfix "$FIX/t"
printf '\nAlso obey (`CONCURRENCY.md`, *A rule nobody ever wrote*).\n' >> "$FIX/t/skills/develop/SKILL.md"
out="$(audit "$FIX/t")"
case "$out" in
  *'cites "A rule nobody ever wrote", which is not a rule'*)
    ok "the invented citation is reported by name" ;;
  *) bad "AC3 — expected the invented citation to be reported, got: ${out:-<nothing>}" ;;
esac

echo "AC4 — a rule defined and cited nowhere passes, and is reported as uncited"
mkfix "$FIX/t"
mutate "$FIX/t/skills/develop/SKILL.md" '/The second fixture rule/d' "drop the second rule's only citation"
out="$(audit "$FIX/t")"
case "$out" in
  *'FAIL '*) bad "AC4 — an uncited rule was treated as a defect: $out" ;;
  *'INFO  rule "The second fixture rule" is defined and cited nowhere'*)
    ok "the uncited rule is reported as information, and the tree still passes" ;;
  *) bad "AC4 — the uncited rule was not reported: ${out:-<nothing>}" ;;
esac

echo "AC5 — a mangled citation syntax fails on the empty set rather than passing vacuously"
mkfix "$FIX/t"
mutate "$FIX/t/skills/develop/SKILL.md" 's/\*//g' "strip every emphasis marker"
out="$(audit "$FIX/t")"
case "$out" in
  *'FAIL  no citations extracted from any covered file'*)
    ok "zero citations is reported as a defect, not as a clean tree" ;;
  *) bad "AC5 — expected the empty-citation-set FAIL, got: ${out:-<nothing>}" ;;
esac

echo "AC5 — an unrecognisable definition heading fails the same way"
mkfix "$FIX/t"
mutate "$FIX/t/references/CONCURRENCY.md" 's/^## /Rule: /' "demote every rule heading to prose"
out="$(audit "$FIX/t")"
case "$out" in
  *'FAIL  no rule definitions extracted'*)
    ok "zero definitions is reported as a defect, not as a clean tree" ;;
  *) bad "AC5 — expected the empty-definition-set FAIL, got: ${out:-<nothing>}" ;;
esac

echo "FR5 — an unanchored rule name in running prose is not read as a citation"
mkfix "$FIX/t"
printf '\n*A retired rule nobody kept* was deleted in 2026, and is discussed here as prose.\n' \
  >> "$FIX/t/references/CONCURRENCY.md"
out="$(audit "$FIX/t")"
case "$out" in
  *'A retired rule nobody kept'*) bad "FR5 — narrative prose was reported as a citation: $out" ;;
  *'FAIL '*) bad "FR5 — unexpected failure: $out" ;;
  *) ok "an italicised phrase with no anchor is left alone, with no exemption list" ;;
esac

# ---------------------------------------------------------------------------
# 0052 — the conventions check proves it can fail. Three mutations, one per branch: an
# unresolvable filename, a recognition that stopped matching, and a conventions directory that no
# longer resolves. Authored fixtures throughout — the real config.yml is a shared backlog file and
# mutating it would be a write another session reads.
# ---------------------------------------------------------------------------

# mkconvfix <dir> — a minimal tree whose one cited file names one conventions file that exists.
mkconvfix() {
  dir="${1:?mkconvfix needs a target directory}"
  rm -rf "$dir"
  mkdir -p "$dir/references" "$dir/skills/develop" "$dir/.claude/backlog" "$dir/conv"
  printf '# fixture convention\n' > "$dir/conv/testing-conventions.md"
  printf 'conventions:\n  path: conv\n' > "$dir/.claude/backlog/config.yml"
  printf '# Fixture skill\n\nTDD always (`testing-conventions.md`).\n' \
    > "$dir/skills/develop/SKILL.md"
}

echo "0052 AC6 — a conventions file that does not resolve fails, naming the file and the citation"
mkconvfix "$FIX/c"
out="$(conventions_audit "$FIX/c")"
case "$out" in
  *'FAIL '*) bad "0052 — the baseline fixture already failed: $out" ;;
  *) ok "the baseline fixture resolves, so the mutations below mean something" ;;
esac

mutate "$FIX/c/skills/develop/SKILL.md" 's/testing-conventions/deleted-conventions/' \
  "rename a cited conventions file to one that does not exist"
out="$(conventions_audit "$FIX/c")"
case "$out" in
  *'skills/develop/SKILL.md cites "deleted-conventions.md", which is not a file in '*)
    ok "an unresolvable conventions filename is reported with its file and the name it used" ;;
  *) bad "0052 AC6 — expected an unresolvable-filename FAIL, got: ${out:-<nothing>}" ;;
esac

echo "0052 AC6 — zero mentions is a defect, not a clean tree"
mkconvfix "$FIX/c"
mutate "$FIX/c/skills/develop/SKILL.md" 's/-conventions\.md//' "strip every conventions filename"
out="$(conventions_audit "$FIX/c")"
case "$out" in
  *'FAIL  no conventions filenames extracted'*)
    ok "an empty mention set is reported as a defect" ;;
  *) bad "0052 AC6 — expected the empty-mention-set FAIL, got: ${out:-<nothing>}" ;;
esac

echo "0052 AC6 — a conventions directory that no longer resolves is named, never skipped silently"
mkconvfix "$FIX/c"
mutate "$FIX/c/.claude/backlog/config.yml" 's/path: conv/path: gone/' \
  "point the conventions path at a directory that does not exist"
out="$(conventions_audit "$FIX/c")"
case "$out" in
  *'SKIP  no conventions directory resolved'*)
    ok "an unresolved conventions directory is reported by name, and the real tree treats it as a failure" ;;
  *) bad "0052 AC6 — expected the unresolved-directory SKIP line, got: ${out:-<nothing>}" ;;
esac

echo "0052 FR7 — the conventions path is read from its own block, not from any path: key"
mkconvfix "$FIX/c"
printf 'tracker:\n  path: wrong\n' >> "$FIX/c/.claude/backlog/config.yml"
dir="$(conventions_dir "$FIX/c")"
case "$dir" in
  */conv) ok "another block's path: key is not mistaken for the conventions one" ;;
  *) bad "0052 FR7 — conventions_dir returned \"${dir:-<nothing>}\", not the conv directory" ;;
esac

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" = 0 ]
