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
# touches this repo, never pushes anywhere real, and never shells out to `claude`. The 0114 cases
# below run the WHOLE chain, push included; the push goes to the fixture's own bare remote, and
# `claude` is kept out of reach by filtering every PATH entry that holds it -- asserted, so a
# filter that failed refuses the case rather than running the real install chain.
#
# Usage:  tests/release.test.sh
#
# Requires: sh, git, grep, sed. No runner -- this project has none.

set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
TOOL="$ROOT/tools/release"
PROJ="$ROOT/CLAUDE.md"
ME_RELEASE="release"   # the prefix `tools/release` puts on its own messages

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
# passing implementation. Caught by this file's own first green run. The number moved from 7 to 8
# when 0114 inserted the authorisation step ahead of the tests; it is the push step that is meant.
case "$GOUT" in
  *"step 8"*) bad "AC3 — the push step ran; the refusal must come before it" ;;
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

# --- 0114: the release is authorised BEFORE anything is written ---------------------------------
#
# WHY THESE CASES. `retro` Step 5 tells every session to run this chain, and an agent session has
# no terminal to answer on. The old step 7 tested `[ -r /dev/tty ]`, which is TRUE in an agent
# shell -- the device node exists and `access(2)` succeeds on every macOS process -- so the run
# took the PROMPT branch, printed a question nobody could answer, and died from the failing
# redirect under `set -e`: exit 1, no message, over a version bump step 6 had already committed.
# A half-released tree and an unexplained status. The fix is not a better terminal test but an
# earlier decision: authorisation is settled while `plugin.json` is unedited and HEAD is where it
# started, so every refusal leaves nothing behind.
#
# EACH CASE GETS ITS OWN FIXTURE. The 0084 cases above mutate one shared checkout in sequence and
# assert on its HEAD; a case here that commits and pushes would silently break them from a
# distance. `mk_case` is also the only fixture whose `tests/noop.test.sh` is executable, because
# these are the only cases that reach the suite step.

mk_case() { # <dir> -> CO2 REMOTE2 INST2 REC2 SHA2, local 1.2.3, installed 1.2.3, remote at 1.2.3
  _d="$1"
  CO2="$_d/checkout"; REMOTE2="$_d/remote.git"; INST2="$_d/install"; REC2="$_d/record.json"
  mkdir -p "$CO2/.claude-plugin" "$CO2/skills/demo" "$CO2/tests" "$INST2"
  printf '{\n  "name": "demo-plugin",\n  "version": "1.2.3"\n}\n' > "$CO2/.claude-plugin/plugin.json"
  printf 'alpha\n' > "$CO2/skills/demo/SKILL.md"
  printf 'beta\n'  > "$CO2/README.md"
  printf '#!/bin/sh\nexit 0\n' > "$CO2/tests/noop.test.sh"
  chmod +x "$CO2/tests/noop.test.sh"
  git init -q -b main "$CO2"
  git -C "$CO2" config user.email fixture@example.invalid
  git -C "$CO2" config user.name fixture
  git -C "$CO2" config commit.gpgsign false
  git -C "$CO2" add .claude-plugin/plugin.json skills/demo/SKILL.md README.md tests/noop.test.sh
  git -C "$CO2" commit -q -m "fixture"
  SHA2="$(git -C "$CO2" rev-parse HEAD)"
  git init -q --bare "$REMOTE2"
  git -C "$CO2" remote add origin "$REMOTE2"
  git -C "$CO2" push -q origin main
  git -C "$CO2" branch -q --set-upstream-to=origin/main main 2>/dev/null || true
  git -C "$CO2" archive "$SHA2" | tar -x -C "$INST2"
  cat > "$REC2" <<REC
{
  "version": 2,
  "plugins": {
    "$KEY": [
      {
        "scope": "user",
        "installPath": "$INST2",
        "version": "1.2.3",
        "installedAt": "2026-09-01T00:00:00.000Z",
        "lastUpdated": "2026-09-01T00:00:00.000Z",
        "gitCommitSha": "$SHA2"
      }
    ]
  }
}
REC
}

untouched() { # <checkout> <sha> -> true when HEAD is still <sha> and plugin.json is unedited
  [ "$(git -C "$1" rev-parse HEAD)" = "$2" ] && git -C "$1" diff --quiet -- .claude-plugin/plugin.json
}

# --- 0114 AC1: no --yes and a device that cannot be read ---------------------------------------
echo "0114 AC1 — a bump due, no --yes, and an unreadable confirm device: refused, tree untouched"
A1="$FIX/ac1"; mkdir -p "$A1"; mk_case "$A1"
A1ST=0
A1OUT="$("$TOOL" --bump --record "$REC2" --plugin "$KEY" --checkout "$CO2" \
          --confirm-device "$A1/there-is-no-device-here" 2>&1)" || A1ST=$?
if [ "$A1ST" -ne 0 ]; then ok "the run refuses when it cannot ask for the release"
else bad "AC1 — the run released without an answer; the confirmation is not wired to anything"; fi
case "$A1OUT" in
  *--yes*) ok "the refusal names --yes as the way to carry an approval already granted" ;;
  *) bad "AC1 — the refusal never names --yes, which is the whole recovery: $A1OUT" ;;
esac
# The bug this ticket is about was a NON-ZERO EXIT WITH NO MESSAGE, so a case asserting only the
# status would have passed on it unchanged.
case "$A1OUT" in
  *"$ME_RELEASE:"*) ok "the refusal says something, rather than dying silently under set -e" ;;
  *) bad "AC1 — the run exited with no message of its own, which is the defect verbatim: $A1OUT" ;;
esac
if untouched "$CO2" "$SHA2"; then
  ok "the refusal left HEAD unmoved and plugin.json unedited"
else
  bad "AC1 — the refusal stopped between the bump and the push: the state that needs a human"
fi

# --- 0114 AC2: the device answers n ------------------------------------------------------------
echo "0114 AC2 — a readable device answering n declines, and likewise leaves the tree as it was"
A2="$FIX/ac2"; mkdir -p "$A2"; mk_case "$A2"
printf 'n\n' > "$A2/answer"
A2ST=0
A2OUT="$("$TOOL" --bump --record "$REC2" --plugin "$KEY" --checkout "$CO2" \
          --confirm-device "$A2/answer" 2>&1)" || A2ST=$?
if [ "$A2ST" -ne 0 ]; then ok "an answered n refuses the release"
else bad "AC2 — the run released over an n; the answer is read but not acted on"; fi
case "$A2OUT" in
  *declin*) ok "the refusal says the release was declined" ;;
  *) bad "AC2 — the refusal does not say the release was declined: $A2OUT" ;;
esac
if untouched "$CO2" "$SHA2"; then
  ok "the decline left HEAD unmoved and plugin.json unedited"
else
  bad "AC2 — the decline fired after the bump was committed, which is the half-released state"
fi

# --- 0114 FR2: the third case -- a device that answers y --------------------------------------
# AC1 and AC2 drive two of the three outcomes FR2 requires to be distinguishable. Asserting only
# those two would leave a `confirm_release` that treats every readable answer as a refusal green,
# which is the same class of unfalsifiable guard the negative cases above avoid.
echo "0114 FR2 — a readable device answering y authorises, and the run proceeds past step 5"
A2Y="$FIX/ac2-yes"; mkdir -p "$A2Y"; mk_case "$A2Y"
printf 'y\n' > "$A2Y/answer"
A2YOUT="$("$TOOL" --bump --record "$REC2" --plugin "$KEY" --checkout "$CO2" \
           --confirm-device "$A2Y/answer" 2>&1)" || true
case "$A2YOUT" in
  *"step 6"*) ok "an answered y carries the run past the authorisation step" ;;
  *) bad "FR2 — a y was read and the run still stopped at step 5: $A2YOUT" ;;
esac
case "$A2YOUT" in
  *"$A2Y/answer"*) ok "the run names the device the answer came from" ;;
  *) bad "FR2 — the run does not say where the answer was read: $A2YOUT" ;;
esac

# --- 0114 AC3: the device test that returns true in the environment it excluded -----------------
# Anchored to the CONSTRUCT, not to a message: the defect is that `[ -r /dev/tty ]` is true in an
# agent shell, so every message-level guard passes while it is still there.
echo "0114 AC3 — whether a terminal can answer is not decided by testing the device node"
if grep -qF '[ -r /dev/tty ]' "$TOOL"; then
  bad "AC3 — tools/release still tests the device node; that test is TRUE in an agent shell, which is how the run reached a prompt nobody could answer"
else
  ok "the device-node test is gone; the read is attempted and its failure handled"
fi
# ... and the grep can fail, or it would pass on a tool that had been deleted.
TTYMUT="$FIX/release-tty-reintroduced"
{ cat "$TOOL"; printf '%s\n' '# elif [ -r /dev/tty ]; then'; } > "$TTYMUT"
if grep -qF '[ -r /dev/tty ]' "$TTYMUT"; then
  ok "reintroducing the construct is caught by that grep"
else
  bad "AC3 — the grep did not see the construct in a file that contains it; the case proves nothing"
fi

# --- 0114 AC4: --yes carries the approval and nothing is asked ---------------------------------
# Driven as a FULL RUN through the push, with `claude` filtered out of PATH so step 9 takes its
# `skipped` branch -- the option the QA plan offered, and the one taken. The fixture's remote is
# the bare repo built above, so nothing is pushed anywhere real and `claude` is never invoked.
# The run's final status is non-zero and that is CORRECT: the fixture's install directory was
# never re-extracted, so the byte comparison legitimately fails against the bump commit. Every
# assertion here is on the message, per this file's own rule.
echo "0114 AC4 — with --yes the run reaches the push without asking anything"
NOCLAUDE=""
OIFS="$IFS"; IFS=:
for d in $PATH; do
  [ -n "$d" ] || d="."
  [ -x "$d/claude" ] && continue
  NOCLAUDE="${NOCLAUDE:+$NOCLAUDE:}$d"
done
IFS="$OIFS"
if PATH="$NOCLAUDE" command -v claude >/dev/null 2>&1; then
  bad "AC4 — could not build a PATH without \`claude\`; the case would have run the real install chain, so it is refused rather than weakened"
else
  A4="$FIX/ac4"; mkdir -p "$A4"; mk_case "$A4"
  A4ST=0
  A4OUT="$(PATH="$NOCLAUDE" "$TOOL" --bump --yes --record "$REC2" --plugin "$KEY" \
            --checkout "$CO2" --confirm-device "$A4/there-is-no-device-here" 2>&1)" || A4ST=$?
  case "$A4OUT" in
    *"[y/N]"*) bad "AC4 — the run prompted despite --yes: $A4OUT" ;;
    *) ok "nothing was prompted for" ;;
  esac
  case "$A4OUT" in
    *"no terminal"*) bad "AC4 — the run refused for want of a terminal despite --yes: $A4OUT" ;;
    *) ok "no refusal was raised for want of a terminal" ;;
  esac
  case "$A4OUT" in
    *"pushed to origin/main"*) ok "the run reached the push" ;;
    *) bad "AC4 — the run never reached the push: $A4OUT" ;;
  esac
  # FR5: the log must not lose where the authorisation came from, since it is now granted
  # earlier than the push rather than at it.
  case "$A4OUT" in
    *authoris*) ok "the run says where the release was authorised" ;;
    *) bad "FR5 — nothing in the run names where the release authorisation came from: $A4OUT" ;;
  esac
  case "$A4OUT" in
    *"no \`claude\` on PATH"*) ok "step 9 took its skipped branch, so no real install was touched" ;;
    *) bad "AC4 — the run did not take the no-claude branch; it may have shelled out for real: $A4OUT" ;;
  esac
  # Both halves matter: the remote must have MOVED (it starts at $SHA2, so an equality check
  # alone passes on a run that did nothing at all) and it must hold exactly what HEAD holds.
  R2="$(git -C "$REMOTE2" rev-parse main)"
  if [ "$R2" != "$SHA2" ] && [ "$R2" = "$(git -C "$CO2" rev-parse HEAD)" ]; then
    ok "the fixture's bare remote advanced to the commit HEAD holds"
  else
    bad "AC4 — the push did not reach the fixture remote"
  fi
fi

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
