---
id: "0153"
title: Give the sprint supervisor marker a liveness signal that outlives one tool call
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
relates: ["0121"]
expects:
  - skills/sprint/SKILL.md
  - tests/sprint.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

**The supervisor marker's `held-by` pid is dead as soon as it is written.** `sprint` Step 1 check 2
records a pid and treats a marker whose pid is not alive as stale and takeable. A supervisor's Bash
calls each run in a fresh shell, so `$$` names a process that already exited, and a second supervisor
following the rule would take over a live run (`.claude/backlog/runs/.active/held-by`,
`run-20260913T021045Z`).

## Functional requirements

- FR1 — staleness of `.active/` is decided by a signal a live supervisor keeps fresh across tool calls (for example a timestamp it rewrites on every dispatch, with a stated age), never by a pid.
- FR2 — the skill names the signal and the age once, and the takeover rule reads it.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Documentation | Step 1 says why a pid cannot serve, in one clause. | Guard on the clause. | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given `skills/sprint/SKILL.md`, when the suite runs, then Step 1's staleness rule does not key on a pid being alive. Red-making change: today's wording.
- [ ] AC2 — Given the rule, when the suite runs, then Step 3's dispatch refreshes the signal the staleness rule reads. Red-making change: a rule naming a signal nothing refreshes.

## QA plan

- **Why that level:** `unit` — prose guards in `tests/sprint.test.sh`.
- **Specific checks:** `tests/sprint.test.sh`; mutate each asserted clause.

## Out of scope

- 0121's timestamp in the backlog lock's `held-by`, a different file.

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

## Notes & decisions

- **Filed by a retro pass 2026-09-12 from FINDINGS.md.** One buffer entry, filed because it would let two supervisors drive one backlog.
