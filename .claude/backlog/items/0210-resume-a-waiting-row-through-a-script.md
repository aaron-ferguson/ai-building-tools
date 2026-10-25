---
id: "0210"
title: Resume a waiting row through a script once its person has answered
type: feature
next: develop
status: ready
qa_level: unit
close_by: verify
size: s
created: 2026-10-17
source: agent
parent:
blocked_by: []
relates: ["0156"]
expects:
  - skills/queue/templates/claim
  - skills/verify/SKILL.md
claimed_by:
claimed_at:
touches:
---

## Problem

`verify` Step 5's *ACs only a person can clear* branch parks a row at `next: verify, status: waiting`,
and nothing describes the way back: `./claim` refuses it (`0103 is 'waiting', not ready — pick another
row`). Twice on 2026-10-17 in AetherWorks (0095 `b84ec35`, copying the hand edit in `222e421`; 0103
`d31b536`) a session flipped `waiting → ready` in `QUEUE.md` and the item by hand under the lock before
it could claim — the one unscripted backlog write in the waiting loop. Parked independently in both
the AetherWorks and the tools buffer.

## Functional requirements

- FR1 — `./claim --resume <id>` accepts a `waiting` row, sets it `in-progress` with a fresh token in
  `QUEUE.md` and the item in one locked commit, and refuses any row that is not `waiting`.
- FR2 — It takes the person's answer as an argument and appends it, dated, under the item's
  `## Waiting on`, so the answer is on disk before the work resumes.
- FR3 — `verify` Step 5's waiting branch names `./claim --resume` as the way back.

## Acceptance criteria

- [ ] AC1 — Given a fixture backlog with a `waiting` row, when `claim --resume <id> "<answer>"` runs, then the row and item read `in-progress` with the minted token, the answer is appended dated under `## Waiting on`, and exactly one commit was made.
- [ ] AC2 — Given a `ready` row, when `claim --resume` runs on it, then it refuses with a message naming the row's actual status and changes nothing.
- [ ] AC3 — Given a busy lock, when `claim --resume` runs, then it refuses as `claim` does today and leaves no lock behind.
- [ ] AC4 — `skills/verify/SKILL.md` Step 5 names `claim --resume` — checked by grep.

## Notes & decisions

- Filed by retro 2026-10-17 (AetherWorks run-20261017T193821Z) from one entry in each buffer.

- 2026-10-24 — Absorbed by retro (second leg of AetherWorks run-20261024T195310Z's tail): a third instance, AetherWorks 2026-10-18 sprint: a `/design` stage was dispatched onto a `next: design, status: waiting` row whose question the author had just answered in the supervising session; `./claim` refused it and the session flipped `status:` by hand under a by-hand lock. So the resume path is needed for `design` rows too, not only verify's `waiting` branch, and `/sprint` dispatching onto a `waiting` row is the same gap seen from the supervisor.
