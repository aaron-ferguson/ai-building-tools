---
id: "0206"
title: Decide whether a verify bounce carrying a precise test-only constraint routes back to develop
type: chore
next: queue
status: ready
qa_level: verify
close_by: verify
qa_manual:
size: s
created: 2026-10-10
source: agent
parent:
blocked_by: []
relates: []
expects:
  - skills/sprint/SKILL.md
  - tools/next
claimed_by:
claimed_at:
touches:
---

## Problem

Filed by retro 2026-10-10 (tail of quantum-catan run-20261010T212209Z) from this repo's buffer.
`--drive` exits 4 on every verify bounce. quantum-catan 0007 failed one AC1 clause and verify named the
exact fix; the owner authorised the supervisor to send develop back toward the declared criteria, and
the re-develop with verify's constraint in its prompt cost USD 1.02 and passed (verify USD 0.97).
(quantum-catan run-20261010T144315Z, item 0007 Notes.)

## Established, not yet specified

- `sprint` decides nothing by design, so an automatic re-develop is a product call, not a bug fix.
  A narrowed contract must still escalate; the candidate is to route only a bounce whose verify
  constraint stays inside the declared ACs.
- One instance, with an explicit owner authorisation for that run.

## Notes & decisions
