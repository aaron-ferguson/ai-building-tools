---
id: "0169"
title: Make a test file announce an abort instead of exiting silently under set -eu
type: bug
next: develop
status: in-progress
qa_level: unit
close_by: develop
qa_manual:
size: m
created: 2026-09-17
source: agent
parent:
blocked_by: []
relates: ["0119"]
expects:
  - tests/abort-announce.test.sh
  - tests/sprint.test.sh
  - tests/next.test.sh
claimed_by: "9fa0"
claimed_at: 2026-10-25T19:42:30Z
touches:
  - "tests/*.test.sh"  # all 34: each sources the helper and sets TALLIED after its tally
  - tests/lib/announce-abort.sh  # new
  - tests/abort-announce.test.sh  # new
  - CLAUDE.md  # Tests: one paragraph naming the block
---

## Problem

Parked 2026-09-13, verbatim:

> Under `set -eu`, a guard that captures `grep` into a variable without `|| true` aborts the test
> file on the exact input it exists to catch.

The conventions half landed in `testing-conventions.md` (conventions repo `4a0d086`). The harness
half did not: a file that dies mid-run prints whatever it had printed so far and no tally, so a
reader sees a short list of passes and nothing that says the run ended early. `0119` recorded the
same shape from a different cause — a collided self-mutating guard returning rc=0 with no tally.
Every file in `tests/` prints its own `N passed, M failed` line and there is no shared harness, so
nothing else can notice the absence.

## Functional requirements

- FR1 — Every `tests/*.test.sh` prints a line containing `ABORTED` and its counts so far when it
  exits before its tally, and exits non-zero.
- FR2 — A guard file that completes normally prints its tally unchanged, and its exit status is
  unchanged.
- FR3 — A committed guard asserts FR1 holds for every file in `tests/`, so a new file cannot omit
  it.

## Acceptance criteria

- [ ] AC1 — Given any `tests/*.test.sh` copied to a scratch dir with an early `exit 1` injected
  after its first assertion, when it runs, then stdout contains `ABORTED`, contains a count, and
  the exit status is non-zero. Guard: `tests/abort-announce.test.sh`. Red: today's bare `set -eu`.
- [ ] AC2 — Given every file in `tests/`, an assertion that each installs the announce-on-abort
  trap passes. Guard: `tests/abort-announce.test.sh`. Red: removing the trap from one file.
- [ ] AC3 — Given the unmodified suite, every file still prints its own tally and the whole-suite
  command still exits 0. Guard: `tests/abort-announce.test.sh` plus the suite itself. Red: a trap
  that fires on the normal path.

## QA plan

- **Why that level:** `unit` — every criterion runs a guard file and reads its output.
- **Specific checks:** `tests/abort-announce.test.sh` with each red proved by reverting the trap in
  one file, then the whole suite.

## Out of scope

Fixing the individual unguarded `grep` captures that cause aborts, and `0119`'s collided-mutation
case, which has its own row.

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

## Notes & decisions

- 2026-09-17 — filed from `FINDINGS.md` by the sprint supervisor rather than a `queue` session; the
  sweep that planned it (session 7bc65dbf) could not write under `.claude/` unattended. Its review
  list ranked this below `0089` and related it to `0119`. `close_by: develop`: every criterion is a
  committed assertion in a named guard.
- 2026-10-25 (develop, 9fa0) — **Built inline, not as a sourced helper.** The first build put the
  block in `tests/lib/announce-abort.sh` and sourced it; it was reverted before commit because
  `CLAUDE.md` and five suites state the house rule *a suite here is self-contained and sources
  nothing*, and reversing that is the author's call. So every `tests/*.test.sh` carries the same
  15-line block directly after `set -eu`, and `tests/abort-announce.test.sh` asserts each copy is
  byte-identical to its own — the duplication is enforced as one definition, the same way
  `claim`/`close`/`next.test.sh` keep their shared helpers in step. `CLAUDE.md` *Tests* gains one
  paragraph saying a new file copies the block (`touches:` widened to it).
- **Mechanism.** `announce_abort` reads `$?` first, prints `ABORTED before the tally: N passed, M
  failed so far (exit S)` unless `TALLIED` is set, forces a 0 status to 1, runs any cleanup passed
  as arguments, then exits with the status. A file's own EXIT cleanup is installed as
  `trap 'announce_abort cleanup' EXIT` (INT/TERM keep the bare cleanup), and `TALLIED=1` sits
  between the tally line and the final status check in all 35 files.
- **QA-plan substitution (AC1).** "An early `exit 1` injected after its first assertion" is not a
  location a script can find in 35 differently-shaped files. The guard injects at the end of each
  file's setup — after its first EXIT trap other than the block's own, else after `FAIL=0` — the
  line `PASS=$((PASS+1)); <death>`, for both `false` (a `set -e` death) and `exit 0` (`0119`'s
  silent-success shape), and asserts `ABORTED before the tally: 1 passed, 0 failed so far` plus a
  non-zero exit. The copy runs in a scratch mirror (every top-level repo entry symlinked except
  `.git`, `tests/` real) so its `ROOT` resolves and setup completes.
- **Trap found while building:** injecting after the *last* `^trap .*EXIT` line recursed without
  bound — the guard's own AC3 fixture then held a column-0 trap line inside a heredoc, so its copy
  re-ran the whole sweep. Fixture is now built with `printf`, and injection takes the first trap.
- **Clause table and sweep — every row RUN** against `a956a20`, each mutation restored from `HEAD`,
  control green (251/0):

  | AC clause | Mutation | Result |
  |---|---|---|
  | AC2 "each installs the … trap" — block present | block deleted from `tests/graph-fields.test.sh` | red, 4 failed |
  | AC2 — trap installed, not replaced | `tests/claim.test.sh` trap made `trap cleanup EXIT` | red, 4 failed |
  | AC2/AC3 — tally marks the normal path | `TALLIED=1` deleted from `tests/external-feedback.test.sh` | red, 1 failed; the file itself then prints `ABORTED … 9 passed` and exits 1 |
  | AC1 "the exit status is non-zero" | forced-non-zero line deleted, all files | red, 35 failed (`exit 0` rows) |
  | AC1 "contains a count" | counts dropped from the ABORTED line, all files | red, 70 failed |
  | AC1 "stdout contains `ABORTED`" | covered by the same row as the count: one assertion matches the whole line | red (above) |
  | AC3 "a trap that fires on the normal path" | `TALLIED` check replaced by `true`, all files | red, 3 failed |
  | AC3 — own cleanup still runs | cleanup call removed from the block, all files | red, 2 failed |
  | AC3 "the whole-suite command still exits 0" | the suite itself | 35 files green, each printing its own tally |

  Red before the build, also run: the guard against the untouched 34 files read 51 passed,
  200 failed.
