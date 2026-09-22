---
id: "0165"
title: Attribute the one-off sprint.test.sh failure and keep its FAIL line visible in a filtered run
type: bug
next: develop
status: in-progress
qa_level: unit
close_by: verify
qa_manual:
size: m
created: 2026-09-17
source: agent
parent:
blocked_by: []
relates: ["0153", "0169", "0170"]
expects:
  - tests/sprint.test.sh
claimed_by: "d98d"
claimed_at: 2026-09-22T03:21:48Z
touches:
  - tests/sprint.test.sh
---

## Problem

Parked from a verify control run, verbatim:

> A control run of `tests/sprint.test.sh` on a clean tree at 0dd303f printed `231 passed, 1 failed`
> and was green on the next run, with no mutation live and only untracked `.claude/backlog/runs/`
> dirty while a sprint run (`run-20260913T151122Z`) was writing there. The FAIL line was lost
> because the verify pass filtered the output to its tally; unattributed.

Two defects. **The failure is unattributed**: nothing says which case failed or why, so every later
red from this file can be waved off as "the flake". Candidates visible in the file today are the
0153 heartbeat cases (wall-clock `sleep 1` sampling, a `sleep 2` "stops changing" check) and any case
reading the real repo rather than `$FIX` while a sprint writes `.claude/backlog/runs/`. **And the
cause was lost to filtering**: the tally is the last line and the `FAIL` lines are hundreds of
lines above it, so a pass reading the tail sees the count and not the case.

## Functional requirements

- FR1 — When `tests/sprint.test.sh` finishes with one or more failures, it re-prints every `FAIL`
  line it emitted, together, immediately above its tally line, so the last N lines of a run name
  every failing case.
- FR2 — The session runs `tests/sprint.test.sh` at least 50 times while two background loads run —
  a CPU-bound loop and a loop writing files into the real repo's `.claude/backlog/runs/` — keeping
  every run's full output, and records in *Notes & decisions* the run count and each FAIL line seen,
  or that none was.
- FR3 — Where FR2 reproduces a failure, the failing case is made independent of the condition that
  caused it (timing, system load, or the real repo's `.claude/backlog/runs/`), and the cause is
  stated in a comment beside the case.
- FR4 — Where FR2 reproduces nothing, the null result is recorded and FR1 is the deliverable; the
  ticket does not guess at a fix.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Testing | A failing case is attributable from the output a filtered read keeps | AC1 | `testing-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given `tests/sprint.test.sh` with one case forced to fail (a `bad` call injected into a
  named case), when it runs and only its last 5 lines are read, then those lines contain that
  case's `FAIL` text. Red: remove the re-print, so the FAIL line sits far above the tally.
- [ ] AC2 — Given no forced failure, when it runs, then no re-print block appears and the tally is
  unchanged in shape (`N passed, 0 failed, M skipped`). Red: a re-print block printed unconditionally.
- [ ] AC3 — Given FR2 reproduced a failure, when the condition *Notes & decisions* names is forced
  deterministically (for example a delay or a concurrent write injected at the named point), then
  the fixed case passes; red: revert the case's fix under the same forced condition. Given FR2
  reproduced nothing, *Notes & decisions* carries the run count, the two loads, and the zero.

## QA plan

- **Why that level:** the artifact is the guard file; each criterion is a run of it.
- **Specific checks:** AC1's injection applied to a copy and restored by path; the whole suite
  afterwards, since FR1 changes the last lines every tally-reading loop reads.

## Out of scope

Re-printing FAIL lines in any other test file, and any file's abort behaviour under `set -eu` —
`0169`. The heartbeat's orphaned `sleep` — `0170`.

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

## Notes & decisions

- 2026-09-17 (queue sweep after retro e30dfa9d) — filed from `FINDINGS.md`. `next: develop`: no
  surface and no open decision; the investigation is bounded (FR2) and both of its outcomes have a
  criterion. Size `m` for the 50-run loop.
