---
id: "0169"
title: Make a test file announce an abort instead of exiting silently under set -eu
type: bug
next: develop
status: ready
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
claimed_by:
claimed_at:
touches:
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
