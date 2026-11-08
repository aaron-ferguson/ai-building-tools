---
id: "0220"
title: Make --drive name one verify session for rows developed together in one gate
type: bug
next: queue
status: ready
qa_level: verify
close_by: verify
qa_manual:
size: s
created: 2026-10-27
source: agent
parent:
blocked_by: []
relates: []
expects:
  - skills/queue/templates/next
  - skills/sprint/SKILL.md
claimed_by:
claimed_at:
touches:
---

## Problem

Filed by retro 2026-10-27 (tail of run-20261025T215324Z), from a FINDINGS.md park.
0177, 0190 and 0183 were developed together in one gate (session e9c46949, resumed after a session limit), yet `--drive` named three verify sessions, one ticket each, even with `--completed develop:0177` and all three ids in `--started` (sprint run-20261025T215324Z). `skills/sprint/SKILL.md` says rows developed together in one gate share a verify session; `--drive` paid three verify floors instead of one.

## Established, not yet specified

- Not yet established: whether the resume across a session limit lost the gate's membership (it is read from the run log or from `--started`), or `--drive` never batches verify. Read `--drive`'s verify branch before specifying.
- The opposite failure (too wide a verify batch) is in 0058's notes; the rule between them is the gate's membership.

## Notes & decisions
