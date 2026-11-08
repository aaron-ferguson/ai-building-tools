---
id: "0219"
title: Make reopen leave a ticket that verify can close when it reopens a develop self-close
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
  - skills/queue/templates/reopen
  - skills/queue/templates/close
  - skills/sprint/SKILL.md
claimed_by:
claimed_at:
touches:
---

## Problem

Filed by retro 2026-10-27 (tail of run-20261025T215324Z), from a FINDINGS.md park.
`./reopen` moved 0126, closed by develop under `close_by: develop`, back to `next: verify` but left `close_by: develop`, so `./close` refused the verify session the reopen was for ("the stage that may close it is 'develop'"). The person's answer was to re-verify independently and close on that verdict, which no script path permits; verify 0126 (fa1b) set `close_by: verify` by hand on its held item and recorded why. The re-verify itself was a supervisor misreading `close_by: develop` as self-certification (sprint run-20261025T215324Z, USD 0.99) — that half was landed in `skills/sprint/SKILL.md` by this retro.

## Established, not yet specified

- Options: `reopen` resets `close_by` to `verify` when the reopen is for an independent verify (a flag or a reason class), or `close` accepts a verify close on a reopened row. The first keeps `close`'s refusal simple.

## Notes & decisions
