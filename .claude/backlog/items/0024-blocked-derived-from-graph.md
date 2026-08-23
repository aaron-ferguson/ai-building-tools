---
id: "0024"
title: Derive the blocked status from the graph rather than the column
type: bug
next: develop
status: in-progress
qa_level: verify
size: s
created: 2026-08-23
source: agent
parent: "0002"
blocked_by: []
relates: ["0011"]
expects:
  - skills/queue/templates/next
  - skills/queue/templates/QUEUE.md
  - skills/queue/templates/item.md
  - skills/queue/SKILL.md
  - skills/verify/SKILL.md
  - skills/develop/SKILL.md
claimed_by: "63c5"
claimed_at: 2026-08-23T17:22:16Z
touches:
  - skills/queue/templates/next
  - skills/queue/templates/QUEUE.md
  - skills/queue/templates/item.md
  - skills/queue/SKILL.md
  - skills/verify/SKILL.md
  - skills/develop/SKILL.md
  - tests/next.test.sh          # new — the fixture harness AC1-AC4 name
---

## Problem

Nothing clears a `blocked_by` entry when the ticket it names closes, so the `Status` column goes stale
silently and stays stale.

Observed on 2026-08-23: ticket 0010 closed, and **four of effort 0009's tasks sat at `status: blocked`
for the remainder of the session** with nothing left blocking them. They were only found because a
session read every item file by hand. A reader of `QUEUE.md` — which is the file the whole design points
people at — would have concluded that four takeable tickets were not takeable.

0011 fixed half of this: `./next <stage>` now derives takeability from `blocked_by` against each named
ticket's real status, so it offers a `ready`-with-stale-blocker row and prints a `SKIP` line for a row
whose blocker is genuinely open. **The column it reads from still lies.** That leaves the backlog with
two answers to "is this blocked?", one correct and one not, and the wrong one is the one written down.

The failure is asymmetric and that is what makes it worth fixing rather than tolerating: a stale
`blocked` hides available work, which nobody notices, while a stale `ready` is caught by the reader.

## Functional requirements

- FR1 — `blocked` becomes a **derived** value, not an authored one: a row is blocked if and only if its
  item's `blocked_by` names at least one ticket whose `status` is not `done`. Nothing writes `blocked`
  into the `Status` column by hand any more.
- FR2 — `./next` gains a mode that reports every row whose written `Status` disagrees with the derived
  answer, in both directions, so the drift is visible without opening any ticket.
- FR3 — The value written in the column for a graph-blocked row is what a reader can act on. Pick one and
  state the reason in the ticket: either the column carries `blocked` and something reconciles it, or it
  carries the underlying `ready`/`waiting` and readers are told the derived answer comes from `./next`.
  **Do not leave both conventions in the tree.**
- FR4 — Whatever closes a ticket reconciles the rows that named it in `blocked_by`, in the same commit as
  the close. A blocker that clears without touching its dependents is how this defect happens.
- FR5 — `templates/QUEUE.md`'s header and `templates/item.md`'s `status` comment both state that `blocked`
  is derived, since they are the two places a reader learns the vocabulary.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | One convention for the column, stated where the vocabulary is defined. Two conventions in the tree is the defect, not the fix. | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given a fixture where 0002 is `done` and 0001's `blocked_by` names only 0002, when
      `./next develop` runs, then 0001 is offered.
- [ ] AC2 — Given the same fixture with 0001's column reading `blocked`, when the drift mode runs, then
      it names 0001 as written-blocked but derived-ready and exits non-zero.
- [ ] AC3 — Given a fixture where 0001's column reads `ready` and its `blocked_by` names an open ticket,
      when the drift mode runs, then it names 0001 in the opposite direction.
- [ ] AC4 — Given no drift, when the drift mode runs, then it says so plainly and exits zero.
- [ ] AC5 — Given `templates/QUEUE.md` and `templates/item.md`, when read, then both state that `blocked`
      is derived from `blocked_by` and not authored.
- [ ] AC6 — Given the skill that closes a ticket, when read, then it requires reconciling the rows that
      named the closed ticket, in the closing commit.

## QA plan

- **Level:** verify — a shell reader and prose.
- **Scripted assertion:** the 0011 fixture harness extended with a third and fourth fixture for the two
  drift directions. Exit codes are pinned separately from output on AC2–AC4: a drift report that prints
  but exits zero is invisible to anything scripted around it, which is the same class of silent failure
  this ticket exists to remove.

## Out of scope

- `waiting`. It is cleared by a person, not by the graph, and 0011 already surfaces the question via
  `./next --waiting`.
- Container-ticket statuses (`active`, `scheduled`). They sit off the stack rank.

## Notes & decisions

- **FR3 is the real decision and it is deliberately left open.** Reconciling the column keeps `QUEUE.md`
  readable on its own — which the README calls the product — but means every close writes rows it does
  not own, which is precisely what `CONCURRENCY.md` warns about. Not writing it keeps writes narrow but
  makes the file lie by omission. Whoever takes this decides and records why; both are defensible and the
  tree must not end up with one of each.
- Tier 2 rather than Tier 1: nothing is bleeding, but every ticket added to a backlog adds another row
  that can go stale, and the cost is paid by whoever next reads the queue and believes it.
