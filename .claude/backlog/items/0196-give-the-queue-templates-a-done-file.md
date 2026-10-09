---
id: "0196"
title: Ship a DONE.md template so a freshly scaffolded backlog can close a ticket
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
relates: ["0161"]
expects:
  - skills/queue/templates/DONE.md
claimed_by:
claimed_at:
touches:
---

## Problem

Parked 2026-10-08 from quantum-catan's first scaffold: `skills/queue/SKILL.md` Step 0 says to scaffold
"by copying every template above" and lists `DONE.md` in the storage layout and among the project-owned
files seeded at scaffold, but `skills/queue/templates/` has no `DONE.md`. `./close` then exits "no
DONE.md … nowhere to move the row to", and needs a table header with an `ID` cell. The capturing
session had to invent one, reading the columns off `close`'s awk (ID, Title, Type, QA, Closed).

## Functional requirements

- FR1 — `skills/queue/templates/DONE.md` exists with a header table whose columns are exactly the ones
  `templates/close` writes, read from `close`, not restated from this ticket.
- FR2 — A test scaffolds a backlog from `skills/queue/templates/` alone into a temp repo, captures a
  row, and `./close` moves it into `DONE.md` with exit 0.

## Acceptance criteria

- [ ] AC1 — FR2's test passes. Red: delete `templates/DONE.md` → `close` exits non-zero naming DONE.md.
- [ ] AC2 — Red: change one header cell in `templates/DONE.md` that `close` keys on → the test fails.

## QA plan

Unit: the configured suite.

## Out of scope

- Migrating backlogs that already invented their own `DONE.md`.

## Notes & decisions

- 2026-10-09 — Filed by retro from the tools `FINDINGS.md` entry of 2026-10-08.
