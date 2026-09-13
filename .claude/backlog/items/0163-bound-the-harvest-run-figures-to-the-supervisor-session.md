---
id: "0163"
title: Bound harvest-usage's --run figures to the supervisor's own session
type: bug
next: develop
status: ready
qa_level: unit
close_by: verify
size: s
created: 2026-09-13
source: user
parent:
blocked_by: []
relates: ["0039", "0135", "0162"]
expects:
  - tools/harvest-usage.sh
  - tests/measurement.test.sh
  - skills/sprint/SKILL.md
  - tests/sprint.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

**`harvest-usage.sh <dir> --run <log>` computes the supervisor's floor, growth and turns over every
transcript in the directory**, so the figures describe the whole project's history, not the run.

Parked from run-20260913T034946Z:

> `harvest-usage.sh --run` reported 4249 turns because the bound spans the whole transcript
> directory, not the supervisor's session.

In `report_run_bound`, the only narrowing is `--session`, when it is given. `skills/sprint/SKILL.md`
Step 9 invokes the bound without one. The run log does not record the supervisor's session id
either, although the supervising process has it as `CLAUDE_CODE_SESSION_ID`.

The same entry's other half, a rerun supervised from an earlier run's conversation, was discharged by
commit `a666012` (`supervisor_context` on `scope_confirmed`).

## Functional requirements

- FR1 — `skills/sprint/SKILL.md` Step 5: the `scope_confirmed` event carries `supervisor_session`,
  the supervising process's `CLAUDE_CODE_SESSION_ID`.
- FR2 — `report_run_bound` in `tools/harvest-usage.sh` reads `supervisor_session` from the run log
  and computes floor, growth and turns over that session's transcript only. An explicit `--session`
  still narrows as today and takes precedence.
- FR3 — Where the run log names no `supervisor_session` and no `--session` is given, it prints
  `RUN … no supervisor session named; no bound reported` and reports no bound, the way it already
  reports no bound for a log with no dispatch.
- FR4 — Step 9's bound invocation and the `--run` usage comment match FR2–FR3.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Observability | A bound is either over the supervisor's session or not printed | AC2 | `measurement-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given a fixture directory with two session transcripts and a run log recording one
  dispatch, where session `aaaa…` has 3 turns, session `bbbb…` has 50, and `scope_confirmed` names
  `supervisor_session` `aaaa…`: when `harvest-usage.sh <dir> --run <log>` runs, then it prints
  `RUN BOUND over 1 cycles and 3 turns`. Red: today's script prints 53 turns.
- [ ] AC2 — Given the same fixture with no `supervisor_session` and no `--session`, when it runs, then
  the output contains `no supervisor session named` and no `RUN BOUND` line. Red: today's
  whole-directory bound.
- [ ] AC3 — Given `skills/sprint/SKILL.md`, when `tests/sprint.test.sh` runs, then Step 5 contains
  `supervisor_session` and `CLAUDE_CODE_SESSION_ID`. Red: either absent.

## QA plan

- **Why that level:** `harvest-usage.sh` is fixture-tested by the suite; the skill change is a prose
  guard.
- **Specific checks:** AC1–AC2 wherever the existing `--run` cases live (confirm on claim; recorded
  in the notes); AC3 in `tests/sprint.test.sh`.

## Out of scope

- Stage-session figures and the per-skill table.
- Retro-fitting `supervisor_session` into existing run logs.

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

## Notes & decisions

- **2026-09-13 — filed by a `queue` sweep of FINDINGS.md** (run-20260913T034946Z). Routed to
  `develop`.
- **The id comes from the run log, not a flag.** The log is where the ledger already pins every other
  session id. A bound that depends on a person remembering a flag goes back to spanning the directory
  the first time they forget. `CLAUDE_CODE_SESSION_ID` was observed set in a Claude Code Bash
  environment on 2026-09-13.
