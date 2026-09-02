#!/bin/sh
#
# Behavioural guard for tools/release --verify.
#
# The full release chain (push, plugin update) cannot be driven without a live remote and a real
# Claude CLI, so this file tests only the verification function, which FR6 exposes standalone
# via --verify. Three fixture trees are built in a temp directory and torn down on exit.
#
# AC6 is satisfied structurally: case 2 asserts exit 1 for a differing install. If the byte
# comparison were mutated to return 0 unconditionally, that assertion would fail and the suite
# would go red. The assertion on the path name proves the output is the comparison's, not a
# static message.
#
# Usage:  tests/release.test.sh
#
# Requires: sh, cmp. No runner -- this project has none.

set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
RELEASE="$ROOT/tools/release"

[ -f "$RELEASE" ] || { printf 'no release script at %s\n' "$RELEASE" >&2; exit 2; }
[ -x "$RELEASE" ] || { printf 'release script not executable: %s\n' "$RELEASE" >&2; exit 2; }

PASS=0
FAIL=0
FIX=""

cleanup() { [ -n "$FIX" ] && rm -rf "$FIX"; return 0; }
trap cleanup EXIT INT TERM

# check <label> <expected-exit> <cmd...>
check() {
  label="$1"; want="$2"; shift 2
  got=0; "$@" >/dev/null 2>&1 || got=$?
  if [ "$got" = "$want" ]; then
    PASS=$((PASS + 1)); printf '[pass] %s\n' "$label"
  else
    FAIL=$((FAIL + 1)); printf '[FAIL] %s  (expected exit %s, got %s)\n' "$label" "$want" "$got"
  fi
}

# check_output <label> <pattern> <cmd...>
# Asserts the command's combined stdout+stderr contains pattern. Exit code is not checked.
check_output() {
  label="$1"; pattern="$2"; shift 2
  out="$("$@" 2>&1 || true)"
  if printf '%s\n' "$out" | grep -q "$pattern"; then
    PASS=$((PASS + 1)); printf '[pass] %s\n' "$label"
  else
    FAIL=$((FAIL + 1)); printf '[FAIL] %s  (pattern "%s" not found in: %s)\n' "$label" "$pattern" "$out"
  fi
}

# mk_file <base-dir> <relative-path> <content>
mk_file() {
  mkdir -p "$1/$(dirname "$2")"
  printf '%s\n' "$3" > "$1/$2"
}

# mk_plugins_json <file> <sha>
mk_plugins_json() {
  cat > "$1" <<EOF
{
  "version": 2,
  "plugins": {
    "ai-building-tools@ai-building-tools": [
      {
        "gitCommitSha": "$2"
      }
    ]
  }
}
EOF
}

# --------------------------------------------------------------------------
# AC1 — identical install and checkout exits 0

FIX="$(mktemp -d)"
mk_file "$FIX/install"   "skills/queue/SKILL.md" "queue content"
mk_file "$FIX/install"   "references/REPORTING.md" "reporting content"
mk_file "$FIX/checkout"  "skills/queue/SKILL.md" "queue content"
mk_file "$FIX/checkout"  "references/REPORTING.md" "reporting content"
mk_plugins_json "$FIX/plugins.json" "abc123"

check "AC1: identical install — exits 0" 0 \
  "$RELEASE" --verify \
    --install-path "$FIX/install" \
    --checkout "$FIX/checkout" \
    --expected-sha "abc123" \
    --plugins-json "$FIX/plugins.json"
cleanup

# --------------------------------------------------------------------------
# AC1 — one file differs: exits non-zero and names the differing path

FIX="$(mktemp -d)"
mk_file "$FIX/install"   "skills/queue/SKILL.md" "stale content"
mk_file "$FIX/install"   "references/REPORTING.md" "same"
mk_file "$FIX/checkout"  "skills/queue/SKILL.md" "updated content"
mk_file "$FIX/checkout"  "references/REPORTING.md" "same"
mk_plugins_json "$FIX/plugins.json" "abc123"

check "AC1: differing file — exits non-zero" 1 \
  "$RELEASE" --verify \
    --install-path "$FIX/install" \
    --checkout "$FIX/checkout" \
    --expected-sha "abc123" \
    --plugins-json "$FIX/plugins.json"

check_output "AC1: differing file — names the path" "skills/queue/SKILL.md" \
  "$RELEASE" --verify \
    --install-path "$FIX/install" \
    --checkout "$FIX/checkout" \
    --expected-sha "abc123" \
    --plugins-json "$FIX/plugins.json"
cleanup

# --------------------------------------------------------------------------
# AC2 — bytes match, recorded sha differs: exits non-zero naming sha mismatch

FIX="$(mktemp -d)"
mk_file "$FIX/install"   "skills/develop/SKILL.md" "same content"
mk_file "$FIX/checkout"  "skills/develop/SKILL.md" "same content"
mk_plugins_json "$FIX/plugins.json" "deadbeef00000000000000000000000000000000"

check "AC2: sha mismatch — exits non-zero" 1 \
  "$RELEASE" --verify \
    --install-path "$FIX/install" \
    --checkout "$FIX/checkout" \
    --expected-sha "abc123correctsha" \
    --plugins-json "$FIX/plugins.json"

check_output "AC2: sha mismatch — says SHA MISMATCH" "SHA MISMATCH" \
  "$RELEASE" --verify \
    --install-path "$FIX/install" \
    --checkout "$FIX/checkout" \
    --expected-sha "abc123correctsha" \
    --plugins-json "$FIX/plugins.json"
cleanup
FIX=""

# --------------------------------------------------------------------------
# AC5 — CLAUDE.md names tools/release and says success is not evidence

check_output "AC5: CLAUDE.md names tools/release" "tools/release" \
  cat "$ROOT/CLAUDE.md"

check_output "AC5: CLAUDE.md says success is not evidence" "not evidence" \
  cat "$ROOT/CLAUDE.md"

# --------------------------------------------------------------------------
# AC5 — retro/SKILL.md points to tools/release (not prose steps)

check_output "AC5: retro SKILL.md names tools/release" "tools/release" \
  cat "$ROOT/skills/retro/SKILL.md"

check_output "AC5: CLAUDE.md trigger says to run tools/release when asked" \
  "asked to release" \
  cat "$ROOT/CLAUDE.md"

# --------------------------------------------------------------------------

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
