---
id: "0212"
title: Stop --drive dispatching develop beside a design session holding one of its files
type: bug
next: develop
status: ready
qa_level: unit
close_by: verify
size: s
created: 2026-10-17
source: agent
parent:
blocked_by: []
relates: ["0134", "0188"]
expects:
  - skills/queue/templates/next
claimed_by:
claimed_at:
touches:
---

## Problem

AetherWorks run-20261017T193821Z: design 0100 [a412] was claimed and running when `--drive` printed
`DISPATCH develop 0095 0099` (exit 0). The develop session found `e2e/sheetSections.spec.ts` held by
0100, stood down having done nothing (USD 0.75), and re-calling with `--completed develop:0095` exited
4: *still at next: develop after a completed develop*. Two defects (outcome in AetherWorks
`.claude/backlog/runs/run-20261017T193821Z.3ff0205d-b217-4b27-8e0a-80d5e6669cb8.out`):

1. The design-beside-develop check does not treat a held design row's `touches:`/`expects:` as a
   conflict with a gate's files, so it dispatched instead of waiting (exit 6).
2. The same-ticket-same-stage loop guard cannot tell a stand-down on a held file from a session that
   changed nothing.

## Functional requirements

- FR1 — `--drive` exits 6 (wait) rather than dispatching a develop gate any of whose rows' predicted
  files intersect an in-progress design row's `touches:` or `expects:`.
- FR2 — A `--completed develop:<id>` whose row is unchanged and whose files intersect a held row
  re-enters the wait path rather than the loop escalation.

## Acceptance criteria

- [ ] AC1 — Given a fixture with design row A in-progress touching file F and develop row B expecting F, when `--drive` runs, then it exits 6 naming A, and prints no DISPATCH for B.
- [ ] AC2 — Given the same fixture with A's touches disjoint from B, when `--drive` runs, then it dispatches B as today.
- [ ] AC3 — Given B unchanged after `--completed develop:B` while A still holds F, when `--drive` runs, then it exits 6, not 4.

## Notes & decisions

- Filed by retro 2026-10-17 from the sprint supervisor's own findings entry.
