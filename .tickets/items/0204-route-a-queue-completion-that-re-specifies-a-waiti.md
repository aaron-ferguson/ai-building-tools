---
id: "0204"
title: Route a queue completion that re-specifies a waiting row to develop instead of exiting 4
type: bug
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
  - tools/next
  - tests/next.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

Filed by retro 2026-10-10 (tail of quantum-catan run-20261010T212209Z) from this repo's buffer.
`./next --drive --completed queue:<id>` exits 4 ("at next: develop / ready after queue, which no routing
rule covers") when a queue session re-specified an owner-ruled `waiting` row back to `develop ready`.
Re-calling with no `--completed` routed it normally, so the supervisor drops the flag by hand.
(quantum-catan run-20261010T144315Z, 0008 after queue session 15061e8a.)

## Established, not yet specified

- The rule set has no queue-completion case; the fix is likely one routing rule plus a `tests/next.test.sh`
  section. Not read: which function in `tools/next` holds the completion rules.

## Notes & decisions

- 2026-10-24 — Absorbed by retro (second leg of AetherWorks run-20261024T195310Z's tail): a broader trigger than the Problem names: AetherWorks run-20261024T195310Z dispatched a `queue` stage on the repair-first path for 0130, a fresh row rather than a re-specified `waiting` one, and `./next --drive --completed queue:0130` still exited 4 ("which no routing rule covers"); without `--completed` it gave `DISPATCH develop 0130`. So the fix is routing any `develop | ready` row after `queue`, not only a re-specified waiting row.
