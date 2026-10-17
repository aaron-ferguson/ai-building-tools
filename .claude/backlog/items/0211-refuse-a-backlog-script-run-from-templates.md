---
id: "0211"
title: Make a backlog script refuse when it is running from the templates directory
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
relates: []
expects:
  - skills/queue/templates/next
claimed_by:
claimed_at:
touches:
---

## Problem

`next` resolves `QUEUE.md` from `dirname $0`, so `sh <plugin>/skills/queue/templates/next --drive
--propose` run from inside a project's backlog read the plugin's own empty template queue, printed
*0 develop gates takeable* and exited 3 (run complete) — a clean, plausible answer about the wrong
file. A `/sprint` supervisor used exactly that call to test whether 0.9.40 could read AetherWorks'
backlog, concluded it could not, and escalated a format incompatibility that did not exist; installed
in place, the same script gave 52 rows and 34 gates (`skills/queue/templates/next` line 27,
AetherWorks commit `789d6b6`).

## Functional requirements

- FR1 — A backlog script whose resolved backlog directory is a `templates/` directory of the plugin
  exits non-zero with a message saying it is the template and naming where an installed copy belongs.
- FR2 — Every script sharing `next`'s resolution (`claim`, `close`, `handoff`, `reopen`) behaves the same.

## Acceptance criteria

- [ ] AC1 — Given `skills/queue/templates/next --drive --propose` invoked by path from a fixture backlog directory, when it runs, then it exits non-zero with a message naming the template, and never exit 3.
- [ ] AC2 — Given the same script copied into the fixture backlog, when it runs, then its output matches HEAD's.
- [ ] AC3 — Given each of `claim`, `close`, `handoff`, `reopen` invoked from the templates directory, when run, then each refuses the same way.

## Notes & decisions

- Filed by retro 2026-10-17 (AetherWorks run-20261017T193821Z). Refusing was chosen over printing
  which `QUEUE.md` was read: a printed path is one more line a supervisor can read past.
