---
id: "0230"
title: Make next say the queue is empty instead of printing a blank ROW 1
type: bug
next:
status: withdrawn
qa_level: unit
close_by: develop
qa_manual:
size: s
created: 2026-11-08
source: user
parent:
blocked_by: []
relates: []
expects:
  - skills/queue/templates/next
  - tests/next.test.sh
  - .tickets/next
ac_digest: AC1=82c0bb0d AC2=1775d0af
claimed_by:
claimed_at:
touches:
---

## Problem

On a queue with no rows, bare `./next` prints a row of empty fields. Observed in `hoa` on
2026-11-08 (0.9.47 and 0.9.48 alike):

```
BY STAGE:  queue 0  design 0  develop 0  verify 0
BY STATUS: ready 0  waiting 0  blocked 0  in-progress 0
ROWS:      0
ROW 1:      |  |  | 
```

The `ROW 1:` line is printed unconditionally from `rows | head -1` (template `next`, the
`./next (no argument)` block), so with nothing to read every field is empty. A reader has to cross
check `ROWS: 0` to know the line is not a malformed row.

## Functional requirements

- FR1 — When the queue holds no rows, the `ROW 1:` line reads exactly
  `ROW 1:     none — the queue holds no rows`.
- FR2 — When it holds at least one row, the line is unchanged.

## Acceptance criteria

- [ ] AC1 — Given a fixture whose `QUEUE.md` holds the header and table header and no rows, when bare `./next` runs, then its `ROW 1:` line is exactly `ROW 1:     none — the queue holds no rows` — `tests/next.test.sh`
- [ ] AC2 — Given a fixture with one row `0001 | Fixture row | develop | ready`, when bare `./next` runs, then its `ROW 1:` line is `ROW 1:     0001 | Fixture row | develop | ready` — `tests/next.test.sh`

Red: AC1 by leaving the unconditional `printf`; AC2 by printing the empty-queue text for every
queue.

## QA plan

- **Why that level:** one script's output against a fixture.
- **Specific checks:** `tests/next.test.sh`, then the whole `unit` command.

## Out of scope

- The `--drive` and `<stage>` modes, which already say when nothing is takeable.

## QA evidence

## Notes & decisions

- 2026-11-08 — Filed at the user's request. Routed to `develop`: no surface, no open decision.
- 2026-11-08 — The line is kept and given text rather than dropped: the script's header says its
  output is a fixed handful of lines whatever the queue holds, and a reader scanning for `ROW 1:`
  should always find it.
- 2026-11-26 — **Withdrawn: merged into `0242`**, carried as FR34–FR35, AC45–AC46, slice S3, in the outcome consolidation the user directed. The work goes on there; this file is the record and the id stays burned.
