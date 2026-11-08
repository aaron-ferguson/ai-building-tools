---
id: "0156"
title: Let handoff record a blocker without leaving drift that stops a driver
type: bug
next: develop
status: ready
qa_level: unit
close_by: verify
size: s
created: 2026-09-12
source: agent
parent:
blocked_by: []
relates: ["0142", "0115", "0141"]
expects:
  - skills/queue/templates/handoff
  - .claude/backlog/handoff
  - skills/queue/templates/next
  - .claude/backlog/next
  - tests/handoff.test.sh
  - tests/next.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

**The documented hand-off for a blocked develop stage produces drift, and since 0142 that drift
stops `--drive`.** A develop stage that cannot get green and adds a `blocked_by` entry leaves its row at
`ready`: `handoff` rejects `blocked` as "derived from blocked_by and never authored", and `develop`
Step 5 says the same. `./next --drift` calls that class 2 drift, and `--drive` escalates on it. 0142's
*Out of scope* reserves the class list to 0115 and 0141, so neither settled it (develop 0142).

## Functional requirements

- FR1 — after `./handoff <id> <token> develop` on an item whose `blocked_by` names an open ticket, the row and item carry `blocked`, written as the derived cache rather than authored, and `--drift` is silent for that row.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Testing | The case runs the real hand-off then `--drift`, in fixture. | Two separately-built fixtures that never meet. | `testing-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given a held fixture item whose `blocked_by` names an open ticket, when `./handoff` runs and then `./next --drift`, then drift reports nothing for that row and `--drive` does not escalate on it. Red-making input: today's handoff.

## QA plan

- **Why that level:** `unit` — fixture cases in the handoff and next suites.
- **Specific checks:** `tests/handoff.test.sh`, `tests/next.test.sh`, `tests/backlog-scripts-installed.test.sh`.

## Out of scope

- Rewriting the drift class list beyond this one reconciliation.

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

## Notes & decisions

- **Filed by a retro pass 2026-09-12 from FINDINGS.md.** One buffer entry, filed because the tooling's own documented shape is what stops a sprint.
