---
id: "0013"
title: Verify closes the ticket; develop stops at next verify
type: chore
status: blocked
qa_level: verify
size: m
created: 2026-08-23
parent: "0009"
blocked_by: ["0010"]
relates: []
touches:
---

## Problem

`develop` owns closing and `verify` writes nothing, so a green verdict has to travel from the
skill that produced it to the skill that acts on it. Today that happens in conversation. Across
a session boundary there is no caller to return to, and the verdict is lost.

The rule exists for a real reason — it makes verify safe to run in a second window against an
item another session is developing. But isolation removes that hazard: verify only acts on
tickets whose `next` is `verify`, and nothing is developing those. The constraint is a workaround
for a risk the new architecture does not have.

## Functional requirements

- FR1 — `develop`'s last act is the implementation commit plus setting `next: verify,
  status: ready`. It does not run QA and does not close.
- FR2 — `verify` on a green result ticks the ACs, sets the ticket done, moves the row to
  `DONE.md`, and releases the claim — all under the lock, committed before release.
- FR3 — `verify` on a red result writes **why** into the item's *Notes & decisions* before
  setting `next: develop, status: ready`.
- FR4 — `verify` refuses a ticket whose `next` is not `verify`, naming what it found instead.
- FR5 — The rule that verify writes nothing to the backlog is removed from `CONCURRENCY.md` and
  replaced by what it always meant: verify writes nothing another session reads for coordination
  while that session holds the ticket.
- FR6 — `develop`'s close step is deleted rather than left unreachable.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | `CONCURRENCY.md`'s changed guarantee is corrected at source, not annotated. A stale rule reads as current and gets followed. | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given `skills/develop/SKILL.md`, when read, then it contains no step that closes a
      ticket or moves a row to `DONE.md`.
- [ ] AC2 — Given `skills/verify/SKILL.md`, when read, then it closes on green and specifies the
      lock-and-commit order.
- [ ] AC3 — Given `skills/verify/SKILL.md`, when read, then the red path writes the failure reason
      to the item before changing `next`.
- [ ] AC4 — Given `references/CONCURRENCY.md`, when grepped for "verify never writes the queue"
      and "writes nothing to the backlog", then there are no matches.
- [ ] AC5 — Given `skills/verify/SKILL.md`, when read, then it states the refusal in FR4.

## QA plan

- **Level:** verify — skill prose.
- **Scripted assertion:** `grep -n 'DONE.md' skills/develop/SKILL.md` returns nothing;
  `grep -n 'DONE.md' skills/verify/SKILL.md` returns at least one line;
  `grep -rn 'verify never writes\|writes nothing to the backlog' references/ skills/` returns
  nothing. Each AC is asserted separately rather than as one combined grep, so a partial
  application fails on the specific half that is missing.

## Out of scope

- The QA levels themselves and what verify checks. This ticket moves who closes, not what is
  checked.

## Notes & decisions

- **This deleted a ticket rather than adding one.** The earlier plan had verify writing a durable
  verdict file for develop to read, along with a commit-SHA staleness guard so a stale green could
  not close a changed ticket. Both disappear: verify holds the verdict in the session where it
  acts on it, and there is no window between testing and closing.
- FR3 is the durability half. Flipping the status without the reason means the next develop
  session re-derives the failure, which is the loss this whole gate exists to prevent.
