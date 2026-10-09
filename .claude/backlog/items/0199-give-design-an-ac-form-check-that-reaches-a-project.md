---
id: "0199"
title: Make the AC form check that design Step 4 names read the consuming project's items
type: bug
next: develop
status: ready
qa_level: unit
close_by: verify
qa_manual:
size: s
created: 2026-10-09
source: agent
parent:
blocked_by: []
relates: ["0052"]
expects:
  - tests/item-ac-form.test.sh
  - skills/design/SKILL.md
claimed_by:
claimed_at:
touches:
---

## Problem

Parked 2026-10-09 from quantum-catan 0014: `skills/design/SKILL.md` Step 4 says to run
`tests/item-ac-form.test.sh` before handoff, but `ROOT` comes from the script's own directory
(`tests/item-ac-form.test.sh:30`) and it skips items at `design`, so on a consuming project it read
none of that project's items and printed "8 passed" — a guard passing vacuously. The only real check
was a manual grep.

## Functional requirements

- FR1 — The check accepts a backlog root (argument or env var) and, given one, reads that project's
  items, including the item design just rewrote.
- FR2 — Given a root with zero items in scope it fails, never reports a pass over nothing.
- FR3 — design Step 4 names the invocation with the project's root.

## Acceptance criteria

- [ ] AC1 — Given a fixture project with one item whose AC is malformed, the check run with that root
  fails naming the item. Red: ignore the root → it passes.
- [ ] AC2 — Given a root with no items in scope, it exits non-zero.
- [ ] AC3 — Run with no root, it still checks this repo's own items as today.

## QA plan

Unit: the configured suite.

## Out of scope

- Changing which AC forms are valid.

## Notes & decisions

- 2026-10-09 — Filed by retro from the tools `FINDINGS.md` entry of 2026-10-09.
