---
id: "0008"
title: Add the graph rules to queue, develop, and verify
type: chore
next: develop
status: blocked
qa_level: verify
size: m
created: 2026-08-18
parent: "0002"
blocked_by: ["0005", "0006"]
relates: []
touches:
---

## Problem

Fields and a reader are inert without rules. Until the skills know what `parent:` and
`blocked_by:` mean, a session can rank a blocker below its dependent, build a ticket whose blocker
is open, decompose a ticket and strand work in the parent, or leave a dependent `blocked` forever
after clearing its last blocker.

Each of those fails silently, which is why they belong in the skills rather than in a reader's
advisory output.

## Functional requirements

- FR1 — `queue` refuses to rank a ticket that has children, and says why: a project has no single
  position, and forcing one hides both ends of its range.
- FR2 — `queue` asks the exhaustiveness question at decomposition: *is there anything in this
  ticket that is not in a child?* Work left in a project is never built, because nothing ranks it.
- FR3 — Decomposition removes the parent's row from `QUEUE.md` and ranks each child individually
  against row 1. Decomposing an `in-progress` ticket requires releasing the claim first.
- FR4 — `queue` rejects an edge that would create a cycle, naming the path.
- FR5 — `queue`'s ranking section gains the anti-clustering rule (never group siblings for
  tidiness) and states that `ships: together` groups rank as one unit at the position their outcome
  earns, at the cost of all their tasks.
- FR6 — `develop` refuses a task with an open `blocked_by`, even if the row says `ready`, and names
  the blocker.
- FR7 — `develop` walks `parent:` to the root on claim and reads the chain — outcome, non-goals,
  `ships:`, flag and expiry, sequencing constraints, and NFR rows the ticket cites as `parent:<id>`.
- FR8 — `develop` unblocks dependents on close: every ticket listing the closed one in
  `blocked_by` is re-evaluated, and those with no remaining open blockers flip to `ready` as
  single-row edits.
- FR9 — `develop`'s Step 7 sweep sets `parent:` on anything it queues inside the ancestor's
  territory.
- FR10 — `verify` resolves an NFR row citing `parent:<id>` by reading that ticket, and still
  writes nothing.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | Rules are stated once, in the skill that enforces them, and cited elsewhere. A rule restated in two skills drifts. | `documentation-conventions.md` |
| Migration / schema | A backlog with no `parent:` or `blocked_by:` anywhere behaves exactly as it does today — every rule here is a no-op on a flat backlog. | `migration-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given `skills/queue/SKILL.md`, when the ranking section is read, then it contains the
  anti-clustering rule and the `ships: together` unit rule.
- [ ] AC2 — Given `skills/queue/SKILL.md`, when the decomposition operation is read, then it
  states the exhaustiveness question and the claim-release precondition.
- [ ] AC3 — Given `skills/develop/SKILL.md` Step 1, when it is read, then it refuses a task with an
  open blocker and names the blocker.
- [ ] AC4 — Given `skills/develop/SKILL.md` Step 6, when it is read, then unblocking dependents is
  a numbered step, not a note.
- [ ] AC5 — Given `skills/verify/SKILL.md`, when the NFR resolution section is read, then
  `parent:<id>` is a resolvable citation and the write-nothing guarantee is restated as unchanged.
- [ ] AC6 — Given a flat backlog with no graph fields, when each skill's rules are applied, then
  behaviour is identical to before this change.

## QA plan

- **Level:** verify — skill prose, no test runner.
- **Why this level:** each criterion is the presence of a specific stated rule in a named file,
  which greps.
- **Specific checks:** a committed assertion script greps each SKILL.md for the rule phrases above
  and exits non-zero on a miss, so the check survives a later edit that removes one.

## Out of scope

The readiness gate and anything about owners of declared triggers — that is 0003, and folding it in
here would make this ticket the whole design.

## Notes & decisions
