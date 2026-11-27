---
id: "0245"
title: Mint the claim token with od, so ./claim works on a host without xxd
type: bug
next:
status: done
qa_level: unit
close_by: verify
qa_manual:
size: s
created: 2026-11-27
source: user
parent:
blocked_by: []
relates: []
expects:
  - skills/queue/templates/claim
  - .tickets/claim
  - references/CONCURRENCY.md
  - tests/claim.test.sh
claimed_by:
claimed_at:
touches:
slice:
ac_digest: AC1=c5169689 AC2=d1073b86 AC3=2f2123a3 AC4=aa8e8c42
closed: 2026-11-27
---

## Problem

`./claim <id>` with no token argument mints the token itself, and
`skills/queue/templates/claim:149` (byte-identical in the installed `.tickets/claim`) does it as:

```
[ -n "$TOKEN" ] || TOKEN="$(head -c2 /dev/urandom | xxd -p)"
```

`xxd` ships with vim. It is not in coreutils and not in POSIX, and it is missing from the Linux cloud
image these sessions run on. Without it the assignment fails under `set -eu` and the script dies before
the lock. Nothing is written and no lock is left, but the only output is the shell's error, so a session
cannot tell "refused" from "crashed":

```
.tickets/claim: 149: xxd: not found
```

Seven sessions hit it between 2026-11-18 and 2026-11-27 (develop 0231, develop 0234 S1 and S6, queue
minting 0232/0233, sprint run-20261127T024025Z develop `bf64` and `be4c`, verify `357a`). An older
build reported it as `claim: 102`. Each one worked round it by passing a token by hand, minted as
`od -An -N2 -tx1 /dev/urandom | tr -d ' \n'` or with a `python3 secrets.token_hex(2)` one-liner.
`references/CONCURRENCY.md` *Claim tokens* prescribes the same `xxd` form
(`CLAIM=$(head -c2 /dev/urandom | xxd -p)`), so a session following the reference by hand fails the
same way (`xxd: command not found`, exit 127).

`od` is POSIX. `od -An -N2 -tx1 /dev/urandom | tr -d ' \n'` prints four lowercase hex digits, the
same shape `xxd -p` prints for two bytes.

## Functional requirements

- FR1 — `skills/queue/templates/claim` mints its default token with
  `od -An -N2 -tx1 /dev/urandom | tr -d ' \n'` (or another POSIX-only form that yields four lowercase
  hex digits), and no longer calls `xxd`.
- FR2 — The installed `.tickets/claim` is re-copied from the template so the two stay byte-identical,
  per `queue` Step 0. The existing installed-copy guard (`tests/backlog-scripts-installed.test.sh`)
  holds them equal.
- FR3 — `references/CONCURRENCY.md` *Claim tokens* shows the same `od` form in place of
  `head -c2 /dev/urandom | xxd -p`.
- FR4 — `tests/claim.test.sh` gains a behaviour case that runs `./claim <id>` with no token on a `PATH`
  holding no `xxd`. One way is a fixture directory that symlinks every tool the script needs except
  `xxd`. The case asserts that the claim succeeds and that the minted token is four hex digits.
- FR5 — No other shipped script under `skills/*/templates/` calls `xxd`. Today only `claim` does
  (checked 2026-11-27 with `grep -rn xxd skills references`). The develop session re-checks this on
  claim and converts any new caller the same way.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Dependencies | The token mint depends only on POSIX utilities (`od`, `tr`), not on an editor's companion binary | FR4's case: with `xxd` restored to the template, the run on an `xxd`-free `PATH` dies at `xxd: not found` and the case reds | `dependency-conventions.md` |
| Documentation | The by-hand snippet in `CONCURRENCY.md` *Claim tokens* matches what the script runs | prose only — no artifact yet (a prose grep would be a new guard over prose, which `CLAUDE.md` *Tests* forbids); verify reads it | `documentation-conventions.md` |

## Acceptance criteria

- [x] AC1 — Given a fixture backlog with one `ready` develop row and a `PATH` that resolves no `xxd`,
  when `./claim <id>` runs with no token, then it exits 0, prints `claimed <id> with token <tok>`,
  and `<tok>` matches `^[0-9a-f]{4}$`. Guard: the new no-`xxd` case in `tests/claim.test.sh`. It reds
  when line 149 is put back to `xxd -p`, because the run then dies at `xxd: not found`.
- [x] AC2 — Given the same fixture, when the claim succeeds, then the item's `claimed_by:` and the
  commit subject `Claim <id> [<tok>]` carry the same four-hex token. Guard: the same case. It reds if
  the mint leaves whitespace or a newline in the token (for example, with the `tr -d` dropped), because
  the frontmatter value and the subject then differ from `^[0-9a-f]{4}$`.
- [x] AC3 — Given the template and the installed copy, when `tests/backlog-scripts-installed.test.sh`
  runs, then it reports `.tickets/claim` byte-identical to `skills/queue/templates/claim`. It reds if
  only one of the two is changed.
- [x] AC4 — Given `references/CONCURRENCY.md` *Claim tokens*, when a reader follows its snippet on a
  host without `xxd`, then it mints a token. Checked by verify by running the quoted snippet under the
  same `xxd`-free `PATH` that AC1 uses. It reds while the paragraph still quotes `xxd -p`.

## QA plan

Run the suite (`config.yml` `unit`). Mutate line 149 of the template back to `xxd -p` and confirm the
new case reds with `xxd: not found`. Drop the `tr -d` and confirm AC2's token-shape assertion reds. Run
the `CONCURRENCY.md` snippet by hand on the fixture's `xxd`-free `PATH` for AC4.

## Out of scope

- Giving `./claim` a worded refusal for a missing dependency in general. Removing the dependency is the
  fix, and nothing else in the script is known to need a non-POSIX tool.
- The token's length or alphabet. Four hex digits stays the shape.

## Notes & decisions

- 2026-11-27 — Minted at the person's direction in sprint run-20261127T024025Z. `CLAUDE.md`
  *Where toolkit work comes from* holds this repo's own findings until a consumer confirms them "or the
  user asks", and the user asked. Amend-first test: no open row's outcome covers token minting. 0242
  (make every backlog write one script call) is closed and did not touch the mint. So this is a new
  outcome.
- 2026-11-27 — `next: develop`: a script fix and a test, with no surface and no open decision. The
  replacement form is already proven by seven hand-minted tokens.
- 2026-11-27 — `close_by: verify`: AC4 is a reading of a reference paragraph, which no committed
  assertion may discharge here (`CLAUDE.md` *Tests*, no new guard greps prose).
- 2026-11-27 — Absorbed the eight `xxd` entries in `.tickets/FINDINGS-HELD.md` (2026-11-18 develop
  0231, 2026-11-18 queue 0232/0233, 2026-11-27 develop `bf64`, 2026-11-27 driven verify, 2026-11-27
  develop `be4c`, 2026-11-27 verify `357a`, 0234 S6 `65ef`, 2026-11-26 develop 0234 S1). Each entry is
  covered by FR1 (the template) and FR3 (the reference). FR5 covers the 0234 S6 entry's "check the
  other scripts". They were removed from the held buffer.
- 2026-11-27 — Built in `42c2daf` (develop, token `7401`). FR1/FR2: line 149 of
  `skills/queue/templates/claim` and `.tickets/claim` now read
  `TOKEN="$(od -An -N2 -tx1 /dev/urandom | tr -d ' \n')"`, byte-identical (`cmp`). FR3:
  `references/CONCURRENCY.md` *Claim tokens* quotes the same form. FR5 re-checked after the edit:
  `grep -rn xxd skills references` and the installed `.tickets/*` scripts find nothing.
- 2026-11-27 — FR4 mechanism: the case keeps each `PATH` directory holding no `xxd` as it is and
  swaps each one that does for a link directory omitting `xxd`. The first draft symlinked every
  command on the whole `PATH` into one directory, and that broke this host's `rm` wrapper (it finds
  the real `rm` by skipping its own directory, so the link resolved to itself: `rm: command not
  found`, exit 127). This host has no `xxd`, so the swap branch was exercised by hand (run): a stub
  `xxd` in a directory prepended to `PATH` left the case green on the fix, and still red on M1.
  The `claimed_by:` assertion uses distinct empty fallbacks: the first draft passed with both sides
  empty while the claim had died.
- 2026-11-27 — Mutations, all run against committed `42c2daf` and restored with `git checkout`,
  then a control run green (222/0):
  | Mutation | Result |
  |---|---|
  | M1: template line 149 back to `head -c2 /dev/urandom \| xxd -p` | red, 4 FAIL, `.tickets/claim: 149: xxd: not found` (AC1) |
  | M1 with a stub `xxd` on the real `PATH` | red, same 4 FAIL (the case does not depend on the host lacking `xxd`) |
  | M2: `\| tr -d ' \n'` dropped | red, 1 FAIL `prints a four-hex token` (AC2) |
  On M2 the printed token, `claimed_by:` and subject agree with each other (each is ` xx xx`), so
  the red comes from the shape check on the printed token. The other two are held equal to it, so all
  three are shape-checked transitively. AC3 is the existing `tests/backlog-scripts-installed.test.sh`,
  green. AC4 is verify's to run. The quoted snippet printed a four-hex token here, on a host with no
  `xxd` (run).
- 2026-11-27 — Whole suite (`tests/*.test.sh`) green at `42c2daf` with a clean `git status`.
- 2026-11-27 — Verified (verify, token `c3f1`): PASS. The verify session's own `./claim 0245`, run
  with no token on this host (no `xxd`), minted `c3f1`, which exercises the fix outside the fixture too.

## QA evidence

Conventions: `../ai-building-conventions` (resolved from `config.yml` `conventions.path`;
`CONVENTIONS_CORE.md` read).
Level: `unit`, the frontmatter value, which agrees with the QA plan. The command was `commands.unit_by_file`, verbatim:
`for t in tests/*.test.sh; do "$t" || true; done`. All 50 files were green with 0 failed, among them `tests/claim.test.sh` with
`222 passed, 0 failed` and `tests/backlog-scripts-installed.test.sh` with `106 passed, 0 failed`.
`git status --porcelain` was empty at Step 2 and after the last check, so the dirty set is empty
and the intersection is empty: not advisory. Copy executed: the repo copies, `skills/queue/templates/claim`
copied into each fixture by `tests/claim.test.sh`, and `.tickets/claim`. The installed plugin is 0.9.51.
`./next --ac-digest 0245 --check` printed `0245: ac_digest matches`.

Clause table:

| AC | Clause | Guarded by |
|---|---|---|
| AC1 | Given a fixture backlog with one `ready` develop row and a `PATH` that resolves no `xxd` | case scaffolds row 0286 and asserts `the fixture PATH resolves no xxd` |
| AC1 | `./claim <id>` runs with no token | case invokes `.tickets/claim 0286` |
| AC1 | exits 0 | `exits 0` (M1 red) |
| AC1 | prints `claimed <id> with token <tok>` | `sed` extraction feeding `prints a four-hex token` (M1 red) |
| AC1 | `<tok>` matches `^[0-9a-f]{4}$` | `prints a four-hex token` (M1, M2 red) |
| AC2 | `claimed_by:` carries the token | `claimed_by: carries that token` (M5 red) |
| AC2 | commit subject `Claim <id> [<tok>]` carries the same token | `the commit subject carries that token` (M4 red) |
| AC2 | four-hex, no whitespace or newline | `prints a four-hex token` with the two equalities (M2 red) |
| AC3 | `.tickets/claim` byte-identical to the template; reds if only one changed | `tests/backlog-scripts-installed.test.sh` (M3 red) |
| AC4 | the `CONCURRENCY.md` *Claim tokens* snippet mints a token without `xxd` | run by hand (below) |

| Check | How | Result |
|---|---|---|
| AC1 | M1: `skills/queue/templates/claim` line 149 put back to `head -c2 /dev/urandom \| xxd -p`, then `tests/claim.test.sh` | red `218 passed, 4 failed`, `.tickets/claim: 149: xxd: not found`; restored by path |
| AC2 | M2: `\| tr -d ' \n'` dropped | red `221 passed, 1 failed` (`prints a four-hex token`) |
| AC2 | M4: line 640 subject `[x$TOKEN]` | red `218 passed, 4 failed`, the 0245 case's `the commit subject carries that token` FAIL |
| AC2 | M5: line 584 writes `claimed_by: "x<tok>"` | red `215 passed, 7 failed`, the 0245 case's `claimed_by: carries that token` FAIL |
| AC3 | M3: a line appended to `.tickets/claim` only | red `105 passed, 1 failed`, `claim has diverged from skills/queue/templates/claim` |
| Control | `tests/claim.test.sh` after all restores | `222 passed, 0 failed`, tree clean, HEAD unmoved |
| AC4 | `command -v xxd` found nothing on this host. The snippet extracted from `references/CONCURRENCY.md` *Claim tokens* (`CLAIM=$(od -An -N2 -tx1 /dev/urandom \| tr -d ' \n')`) was run | printed `d122`, matches `^[0-9a-f]{4}$`. The old `xxd -p` form gave `xxd: not found` and an empty token |
| FR5 | `grep -rn xxd skills references .tickets/{claim,close,next,handoff,park}` | no matches |
| NFR Dependencies | guarded by the AC1 case, M1 red | holds, guarded |
| NFR Documentation | prose only. The snippet matches template line 149 character for character, and AC4 ran it (`documentation-conventions.md`) | holds, unguarded by design (`CLAUDE.md` *Tests*) |
| Always-on (`CONVENTIONS_CORE.md`) | diff `42c2daf` read against Code/Testing/Git/Security | no violation. The commit staged named files and adds no secrets or egress, so no privacy pass is owed |

Evidence set: `skills/queue/templates/claim`, `.tickets/claim`, `tests/claim.test.sh`,
`tests/backlog-scripts-installed.test.sh`, `references/CONCURRENCY.md`.
