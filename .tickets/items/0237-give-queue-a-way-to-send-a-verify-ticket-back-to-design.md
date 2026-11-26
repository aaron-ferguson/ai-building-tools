---
id: "0237"
title: Give queue a way to send an open verify ticket back to design
type: feature
next:
status: withdrawn
qa_level: unit
close_by: verify
qa_manual:
size: s
created: 2026-11-18
source: agent
parent:
blocked_by: []
relates: ["0219"]
expects:
  - skills/queue/SKILL.md
  - skills/queue/templates/handoff
  - skills/queue/templates/reopen
claimed_by:
claimed_at:
touches:
slice:
---

## Problem

A consuming project needed a `next: verify` design ticket sent back to `design` when the user
overturned its answer before close. `queue` Step 1 covers re-specify (`next: queue`) and `./reopen`
(done → verify only); `./handoff` can hand to `design` but needs a claim token, which `queue` does
not hold. So the `next:` field and the `QUEUE.md` row were edited by hand under the lock — the
two-file write the scripts exist to make atomic.

## Open design question

Which carries it: a named operation in `queue` Step 1 that claims then `./handoff … design`, an
unclaimed form of `./handoff`, or `./reopen` taking a target stage?

## Functional requirements

- FR1 — An open row at `next: verify` can be moved to `next: design` by one script call that writes
  the item and its `QUEUE.md` row in one locked commit.
- FR2 — `queue` Step 1 names the operation and when it applies (the user reopens a decision).

## Notes & decisions

- 2026-11-18 (retro) — filed from a consuming project's finding in `.tickets/FINDINGS.md`.
- 2026-11-26 — **Withdrawn: merged into `0242`**, carried as FR44–FR45, slice S12, in the outcome consolidation the user directed. The work goes on there; this file is the record and the id stays burned.
