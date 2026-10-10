---
id: "0201"
title: Make sprint-ledger.sh refuse an outcome event whose stage fields are nested rather than flat
type: bug
next: queue
status: ready
qa_level: unit
close_by: verify
qa_manual:
size: s
created: 2026-10-10
source: agent
parent:
blocked_by: []
relates: ["0192"]
expects:
  - tools/sprint-ledger.sh
  - skills/sprint/SKILL.md
  - tests/sprint-ledger.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

Filed by retro 2026-10-10 from a park in this repo's buffer (quantum-catan run-20261009T003522Z).
A supervisor that wrote the stage's outcome object nested under an `outcome` key in the `outcome`
event made `sprint-ledger.sh record` report `CLOSED none` and `FINDINGS parked 0` with no error. The
ledger reads `tickets`, `cost_usd` and `findings_parked` flat at the event's top level, and
`skills/sprint/SKILL.md` Step 5 documents the event's `session_id` (line ~583) but not where the
stage's fields sit — so the nested shape is a reasonable reading of the prose and fails silently.

## Established, not yet specified

- The failure is silent: a wrong shape reads as a sprint that closed nothing.
- Two candidate fixes, likely both: (a) `record` fails loudly on an `outcome` event that has no
  top-level `tickets` array (or carries an `outcome` key); (b) Step 5 states the flat shape once.
- Not yet read: `record`'s parsing code in `tools/sprint-ledger.sh`. `queue` specifies FRs from it.

## Notes & decisions
