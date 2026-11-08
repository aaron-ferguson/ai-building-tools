---
id: "0170"
title: Stop the marker heartbeat leaving an orphaned sleep child
type: bug
next: develop
status: ready
qa_level: unit
close_by: develop
qa_manual:
size: s
created: 2026-09-17
source: agent
parent:
blocked_by: []
relates: ["0153"]
expects:
  - skills/sprint/SKILL.md
  - tests/sprint.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

Parked 2026-09-14, verbatim:

> The supervisor's hand-rolled marker heartbeat, stopped with `kill $BEAT`, left its `sleep 60`
> child orphaned under launchd. Killing the backgrounded subshell does not kill the `sleep` it is
> waiting on; `pkill -P $BEAT` before `kill $BEAT` stopped it cleanly on later dispatches.

Observed on run `run-20260913T222409Z`: a `sleep 60` with ppid 1 outliving the dispatch that
started it. `0153`'s executed guard asserts the loop stops, which it does — the leak is the child
the loop was blocked on, and no criterion looks for it. It is small and self-clearing within one
interval, and it is still a process nobody stops on purpose, in a skill whose conventions say to
stop what you started.

## Functional requirements

- FR1 — The Step 3 heartbeat snippet kills the loop's descendants before the loop itself.
- FR2 — A committed guard asserts no descendant of the heartbeat survives the snippet's own stop.

## Acceptance criteria

- [ ] AC1 — Given the Step 3 snippet extracted and run with a shortened interval, when the stop it
  prescribes has run, then no descendant of the heartbeat's pid remains. Guard:
  `tests/sprint.test.sh`. Red: the snippet as written today, with the kill of the subshell alone.
- [ ] AC2 — Given the same extraction, the timestamp still advances while the stand-in runs, so
  `0153` AC2 is unaffected. Guard: `tests/sprint.test.sh`. Red: a stop that also prevents the
  refresh.

## QA plan

- **Why that level:** `unit` — both criteria execute the snippet and read process state.
- **Specific checks:** `tests/sprint.test.sh`, each red proved by reverting the kill order, then the
  whole suite.

## Out of scope

`0153`'s staleness rule and the heartbeat's interval.

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

## Notes & decisions

- 2026-09-17 — filed from `FINDINGS.md` by the sprint supervisor rather than a `queue` session, for
  the reason recorded in `0168`. The sweep's review list ranked it directly below `0167`.
