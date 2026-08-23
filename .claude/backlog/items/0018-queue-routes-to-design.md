---
id: "0018"
title: Queue routes to design rather than design screening everything
type: chore
status: blocked
qa_level: verify
size: s
created: 2026-08-23
parent: "0009"
blocked_by: ["0010"]
relates: []
touches:
---

## Problem

With `next` as a field, something has to set it. The obvious reading — every ticket starts at
`design`, which decides whether there is design work — pays a full session's startup on every
ticket to mostly answer "nothing to do". All five tickets in the measured jury-config backlog
are pure parsing logic with no interface at all.

Queue is better placed and it costs nothing extra there. Deciding whether acceptance criteria
can be written *is* the design question, queue already has to answer it to know whether to write
ACs, and it answers it with the code already open.

## Functional requirements

- FR1 — Queue sets `next: design` or `next: develop` on every ticket it writes, and records the
  reason in *Notes & decisions*.
- FR2 — The skill states the two distinct triggers for `design`: a decision that blocks writing
  acceptance criteria, or a surface a person will look at.
- FR3 — The skill gives the negative case as concretely as the positive one — a parser, a
  migration, a schema or an API contract routes to `develop`.
- FR4 — `develop` gains a return path: a session that meets an unanswered design question sets
  `next: design` and stops, rather than guessing the answer.
- FR5 — `verify` gains the same return path to `next: queue` for a ticket whose acceptance
  criteria no longer match reality.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The routing reason is recorded on the ticket, so a later reader can tell a considered skip from an oversight. | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given `skills/queue/SKILL.md`, when read, then it requires `next` to be set at
      capture time and the reason recorded.
- [ ] AC2 — Given that file, when read, then both triggers in FR2 are stated and at least three
      examples of the `develop` case are given.
- [ ] AC3 — Given `skills/develop/SKILL.md`, when read, then it describes setting `next: design`
      and stopping rather than deciding.
- [ ] AC4 — Given `skills/verify/SKILL.md`, when read, then it describes setting `next: queue`
      for a stale contract.

## QA plan

- **Level:** verify — skill prose.
- **Scripted assertion:** `grep -n 'next: design' skills/queue/SKILL.md skills/develop/SKILL.md`
  returns a line in each, and `grep -n 'next: queue' skills/verify/SKILL.md` returns a line.
  Asserted per file rather than across the tree, because a rule present in one skill and absent
  in its neighbour is the uncovered-caller case `coding-conventions.md` names.

## Out of scope

- What design does once routed there — 0019.
- `prototype`. It remains human-invoked and is not a routing target.

## Notes & decisions

- The safety valve in FR4 and FR5 is what makes it safe for queue to be wrong occasionally. A
  mis-route costs one stop-and-redirect; pre-screening every ticket costs a session every time.
