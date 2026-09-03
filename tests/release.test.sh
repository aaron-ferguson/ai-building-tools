#!/bin/sh
#
# Guard for the release chain's verification (0084).
#
# WHAT WENT WRONG, AND WHY A GUARD HERE. On 2026-09-01 `claude plugin update` printed success,
# wrote a fresh `gitCommitSha` into `installed_plugins.json`, and extracted nothing: the cache
# directory is keyed by VERSION, the version had not moved, so the directory already existed. The
# same evening `/reload-plugins` did the mirror image -- fresh bytes under a stale recorded
# version. So neither number in the record is evidence about the bytes, and the two fail
# independently. The verification therefore makes two assertions, and this file proves each can
# fail on its own.
#
# THE ONE THAT MATTERS IS THE BYTE COMPARISON, and `exits non-zero` is not what it is asserted
# on: a silent refusal exits non-zero too, and that is the failure this whole ticket is about
# (`testing-conventions.md` -- assert the message, never the status). Every case below asserts
# the message names the path or the sha.
#
# The fixture is a real git repo with a real bare remote, built at a fixed, stated size. It never
# touches this repo, never pushes anywhere real, and never shells out to `claude`.
#
# Usage:  tests/release.test.sh
#
# Requires: sh, git, grep, sed. No runner -- this project has none.

set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
TOOL="$ROOT/tools/release"
PROJ="$ROOT/CLAUDE.md"

PASS=0
FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }

FIX="$(mktemp -d)"
trap 'rm -rf "$FIX"' EXIT INT TERM

echo "0084 — the tool exists and runs"
if [ -x "$TOOL" ]; then ok "tools/release is present and executable"
else bad "tools/release missing or not executable — the chain has no script"; fi

# --- the fixture --------------------------------------------------------------------------------
# A checkout of four tracked files at version 1.2.3, a bare remote holding the same commit, and an
# install directory extracted from that commit with `git archive` -- which is what "the bytes the
# harness will load" means. The install's own version string is deliberately 9.9.9 and its path
# deliberately unrelated to it, so anything that CONSTRUCTS the install path from the version
# instead of reading `installPath` looks in the wrong place (FR5).
CO="$FIX/checkout"
INST="$FIX/install-dir-not-named-for-any-version"
REMOTE="$FIX/remote.git"
KEY="demo-plugin@demo-plugin"

mkdir -p "$CO/.claude-plugin" "$CO/skills/demo" "$CO/tests"
printf '{\n  "name": "demo-plugin",\n  "version": "1.2.3"\n}\n' > "$CO/.claude-plugin/plugin.json"
printf 'alpha\n' > "$CO/skills/demo/SKILL.md"
printf 'beta\n'  > "$CO/README.md"
printf 'gamma\n' > "$CO/tests/noop.test.sh"

git init -q -b main "$CO"
git -C "$CO" -c user.email=fixture@example.invalid -c user.name=fixture \
  add .claude-plugin/plugin.json skills/demo/SKILL.md README.md tests/noop.test.sh
git -C "$CO" -c user.email=fixture@example.invalid -c user.name=fixture \
  commit -q -m "fixture"
SHA="$(git -C "$CO" rev-parse HEAD)"
OTHER_SHA="0000000000000000000000000000000000000000"

git init -q --bare "$REMOTE"
git -C "$CO" remote add origin "$REMOTE"
git -C "$CO" push -q origin main
git -C "$CO" branch -q --set-upstream-to=origin/main main 2>/dev/null || true

mkdir -p "$INST"
git -C "$CO" archive "$SHA" | tar -x -C "$INST"

# `installed_plugins.json`, in the shape the harness actually writes.
write_record() { # <install-path> <version> <sha>
  cat > "$FIX/record.json" <<REC
{
  "version": 2,
  "plugins": {
    "$KEY": [
      {
        "scope": "user",
        "installPath": "$1",
        "version": "$2",
        "installedAt": "2026-09-01T00:00:00.000Z",
        "lastUpdated": "2026-09-01T00:00:00.000Z",
        "gitCommitSha": "$3"
      }
    ]
  }
}
REC
}

verify() { # extra args -> stdout+stderr, exit status in $VST
  VST=0
  VOUT="$("$TOOL" verify --record "$FIX/record.json" --plugin "$KEY" \
            --checkout "$CO" --commit "$SHA" "$@" 2>&1)" || VST=$?
}

# --- AC4 / FR5: the matching case -------------------------------------------------------------
echo "0084 AC4 — a run where every check passes reports version, commit and the restart"
write_record "$INST" "9.9.9" "$SHA"
verify
if [ "$VST" -eq 0 ]; then ok "identical bytes and a matching record verify clean"
else bad "AC4 — a faithful install failed verification; got status $VST: $VOUT"; fi
case "$VOUT" in
  *"9.9.9"*) ok "the report names the installed version" ;;
  *) bad "AC4 — the success report does not name the version" ;;
esac
case "$VOUT" in
  *"$SHA"*) ok "the report names the verified commit sha in full" ;;
  *) bad "AC4 — the success report does not name the commit sha" ;;
esac
case "$VOUT" in
  *[Rr]estart*) ok "the report says a restart is required" ;;
  *) bad "AC4 — the success report never mentions the restart, which is the step that makes the release take effect" ;;
esac
case "$VOUT" in
  *install-dir-not-named-for-any-version*)
    ok "FR5 — the install path came from installPath, not built from the version string" ;;
  *) bad "FR5 — the report does not name the resolved installPath, so nothing shows which directory was compared" ;;
esac

# --- AC1: one differing file ------------------------------------------------------------------
echo "0084 AC1 — one file made to differ is named, and restoring it is what turns it green"
printf 'alpha-tampered\n' > "$INST/skills/demo/SKILL.md"
verify
if [ "$VST" -ne 0 ]; then ok "a single differing file fails the verification"
else bad "AC1 — a differing install verified clean: the byte comparison is not wired to anything"; fi
case "$VOUT" in
  *"skills/demo/SKILL.md"*) ok "the output names the differing path" ;;
  *) bad "AC1 — the failure never names skills/demo/SKILL.md, so the operator cannot act on it: $VOUT" ;;
esac
printf 'alpha\n' > "$INST/skills/demo/SKILL.md"
verify
if [ "$VST" -eq 0 ]; then ok "restoring that one file turns it green again"
else bad "AC1 — restoring the file did not restore the green: $VOUT"; fi

# --- FR2: a missing file is a difference too ---------------------------------------------------
echo "0084 FR2 — a path present in the commit and absent from the install is named as missing"
rm -f "$INST/README.md"
verify
if [ "$VST" -ne 0 ]; then ok "a missing path fails the verification"
else bad "FR2 — a missing file verified clean; this is how references/REPORTING.md went absent unnoticed"; fi
case "$VOUT" in
  *README.md*) ok "the output names the missing path" ;;
  *) bad "FR2 — the failure never names README.md: $VOUT" ;;
esac
git -C "$CO" archive "$SHA" README.md | tar -x -C "$INST"

# --- AC2: bytes match, record lies -------------------------------------------------------------
echo "0084 AC2 — byte equality alone must not pass it"
write_record "$INST" "9.9.9" "$OTHER_SHA"
verify
if [ "$VST" -ne 0 ]; then ok "a stale recorded sha fails even though every byte matches"
else bad "AC2 — byte equality passed a record naming another commit; that field is the one that lied"; fi
case "$VOUT" in
  *"$OTHER_SHA"*) ok "the output names the recorded sha it found" ;;
  *) bad "AC2 — the failure never names the recorded sha: $VOUT" ;;
esac

# --- FR3: the two assertions are independent ---------------------------------------------------
echo "0084 FR3 — the byte check and the record check each report, neither short-circuiting the other"
printf 'alpha-tampered\n' > "$INST/skills/demo/SKILL.md"
verify
case "$VOUT" in
  *"skills/demo/SKILL.md"*"$OTHER_SHA"*|*"$OTHER_SHA"*"skills/demo/SKILL.md"*)
    ok "both failures are reported in one run" ;;
  *) bad "FR3 — one check short-circuited the other; the two failure modes were observed independently and must be diagnosed independently: $VOUT" ;;
esac
printf 'alpha\n' > "$INST/skills/demo/SKILL.md"

# --- AC6: the comparison mutated to unconditional success reds this file ------------------------
# Per `testing-conventions.md`: confirm the mutation LANDED before believing either colour, and
# fail loudly when it did not -- a substitution that quietly missed reads exactly like a guard
# that holds.
echo "0084 AC6 — the byte comparison, mutated to succeed unconditionally, is caught by the cases above"
MUT="$FIX/release-mutated"
sed 's/^paths_that_differ() {$/paths_that_differ() { return 0/' "$TOOL" > "$MUT"
chmod +x "$MUT"
if cmp -s "$TOOL" "$MUT"; then
  bad "AC6 — the mutation did not land; nothing was substituted, so this case proves nothing about the guard"
else
  ok "the mutation landed: paths_that_differ now returns success without comparing anything"
  write_record "$INST" "9.9.9" "$SHA"
  printf 'alpha-tampered\n' > "$INST/skills/demo/SKILL.md"
  MST=0
  MOUT="$("$MUT" verify --record "$FIX/record.json" --plugin "$KEY" \
            --checkout "$CO" --commit "$SHA" 2>&1)" || MST=$?
  if [ "$MST" -eq 0 ]; then
    ok "the mutant passes the differing install, so AC1's case is what carries the guard"
  else
    bad "AC6 — the mutant still failed ($MST), so AC1's red does not come from the byte comparison: $MOUT"
  fi
  printf 'alpha\n' > "$INST/skills/demo/SKILL.md"
fi

# --- AC3: the version gate refuses before any push ---------------------------------------------
echo "0084 AC3 — a version equal to the installed one exits before any push, and says why"
write_record "$INST" "1.2.3" "$SHA"
GST=0
GOUT="$(cd "$CO" && "$TOOL" --record "$FIX/record.json" --plugin "$KEY" --checkout "$CO" 2>&1)" || GST=$?
if [ "$GST" -ne 0 ]; then ok "the chain refuses when the version cannot take effect"
else bad "AC3 — the chain proceeded at a version equal to the installed one: the push would ship nothing"; fi
case "$GOUT" in
  *"1.2.3"*) ok "the refusal names the version that cannot take effect" ;;
  *) bad "AC3 — the refusal does not name the version: $GOUT" ;;
esac
case "$GOUT" in
  *cache*director*) ok "the refusal names the cache directory as the mechanism" ;;
  *) bad "AC3 — the refusal does not name the version-keyed cache directory, which is the whole reason: $GOUT" ;;
esac
case "$GOUT" in
  *re-extract*) ok "the refusal states that the directory will not be re-extracted" ;;
  *) bad "AC3 — the refusal never says the directory will not be re-extracted: $GOUT" ;;
esac
case "$GOUT" in
  *"1.2.4"*) ok "the refusal names the derived next version, so the operator need not pick one (FR1, 0075)" ;;
  *) bad "FR1 — the refusal does not derive the next version from the remote's plugin.json: $GOUT" ;;
esac
# Anchored to the STEP that did not run and to HEAD, not to the word "push": the correct refusal
# message itself ends "nothing has been committed or pushed", so a grep for the word reds a
# passing implementation. Caught by this file's own first green run.
case "$GOUT" in
  *"step 7"*) bad "AC3 — the push step ran; the refusal must come before it" ;;
  *) ok "the push step was never reached" ;;
esac
if [ "$(git -C "$CO" rev-parse HEAD)" = "$SHA" ] && git -C "$CO" diff --quiet; then
  ok "the refusal committed nothing and left plugin.json alone"
else
  bad "AC3 — the refusal moved HEAD or edited plugin.json; without --bump it may do neither"
fi

# --- NFR git: behind the remote reports and stops, resolving nothing ----------------------------
echo "0084 NFR git — a checkout behind the remote is reported, not resolved"
OTHER="$FIX/other"
git clone -q "$REMOTE" "$OTHER"
printf 'delta\n' > "$OTHER/README.md"
git -C "$OTHER" -c user.email=fixture@example.invalid -c user.name=fixture \
  commit -q -m "remote moved" -- README.md
git -C "$OTHER" push -q origin main
write_record "$INST" "1.2.2" "$SHA"
BST=0
BOUT="$(cd "$CO" && "$TOOL" --record "$FIX/record.json" --plugin "$KEY" --checkout "$CO" 2>&1)" || BST=$?
if [ "$BST" -ne 0 ]; then ok "a checkout behind the remote stops the chain"
else bad "NFR git — the chain ran on a checkout behind the remote, which is how a hand-picked version collided (0075)"; fi
case "$BOUT" in
  *behind*) ok "the report says the checkout is behind" ;;
  *) bad "NFR git — the stop does not say the checkout is behind: $BOUT" ;;
esac
if [ "$(git -C "$CO" rev-parse HEAD)" = "$SHA" ]; then
  ok "the chain resolved nothing itself — HEAD is untouched"
else
  bad "NFR git — the chain moved HEAD; resolving divergence is out of scope for this item"
fi

# --- AC5: the project's own record of the mechanism --------------------------------------------
# Anchored to the CLAIM, not to the document: a file-wide grep for `tools/release` would pass on a
# stray mention while the sentence carrying the warning was deleted.
echo "0084 AC5 — CLAUDE.md's release-chain paragraph names the script and warns about the success line"
if [ -f "$PROJ" ] && grep -qF 'tools/release' "$PROJ"; then
  ok "CLAUDE.md names tools/release"
else
  bad "AC5 — CLAUDE.md does not name tools/release, so the chain's only script is undiscoverable"
fi
if [ -f "$PROJ" ] && grep -qF 'is not evidence the bytes changed' "$PROJ"; then
  ok "CLAUDE.md states that the update's success line is not evidence the bytes changed"
else
  bad "AC5 — CLAUDE.md still lets a reader treat 'updated from x to y' as evidence; that line was true and the bytes were stale"
fi

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
