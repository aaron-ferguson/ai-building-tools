---
id: "0014"
title: Queue sweeps FINDINGS.md for units of work
type: chore
next: verify
status: done
qa_level: verify
size: s
created: 2026-08-23
closed: 2026-08-23
parent: "0009"
blocked_by: []
relates: []
touches:
---

## Problem

A session that spots work it should not do now has nowhere to put it. Calling `queue` is the
thing this project removes, and writing a ranked row itself means doing queue's hardest job —
specification and ranking — badly and in the wrong session.

## Functional requirements

- FR1 — `queue` gains a sweep: read `FINDINGS.md`, take the entries that are units of work, and
  specify and rank each one properly per its existing Add flow.
- FR2 — The sweep removes only the entries it processed, and commits in the same turn. `retro`
  does the same for lessons, so two sweepers share one file without contending.
- FR3 — An entry that is both a lesson and a unit of work is taken by both, and the prose says so
  — forcing the classification at write time is friction where it is least wanted.
- FR4 — A surfaced entry is a stub with a Problem section, never a ranked row. Unspecified work
  stays out of `QUEUE.md` so the file every session reads holds only specified, ranked tickets.
- FR5 — The existing Notion import in queue Step 5 is generalised rather than duplicated: one
  flow, with the local buffer as the default source and Notion as an optional one.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The two-sweeper rule is stated in `FINDINGS.md`'s own template, where both sweepers will read it. | `documentation-conventions.md` |

## Acceptance criteria

- [x] AC1 — Given `skills/queue/SKILL.md`, when read, then it has a sweep step naming
      `FINDINGS.md` as a source and requiring full specification of anything it promotes.
- [x] AC2 — Given that step, when read, then it says to remove only processed entries and commit
      in the same turn.
- [x] AC3 — Given `templates/FINDINGS.md`, when read, then it states that queue takes units of
      work, retro takes lessons, and an entry may be both.
- [x] AC4 — Given `skills/queue/SKILL.md`, when read, then the Notion flow and the buffer flow are
      one step with two sources, not two parallel steps.

## QA plan

- **Level:** verify — skill and template prose.
- **Scripted assertion:** `grep -c 'FINDINGS.md' skills/queue/SKILL.md` is at least 1;
  `grep -n 'notion' skills/queue/SKILL.md` shows it inside the same step as the buffer source
  rather than under its own heading — asserted by checking there is exactly one `## Step` heading
  covering import.

## Out of scope

- What retro takes from the same file — 0016.
- A separate inbox file. One buffer, deliberately.

## Notes & decisions

- Queue Step 5 already insists an imported row "is a report, not a work item" that needs FRs,
  NFRs, ACs and a QA level written. That is exactly the treatment a buffer entry needs, so this
  is a generalisation of an existing flow rather than new machinery.
- **FR1 and FR4 are not in tension once read together.** FR1 says specify and rank; FR4 says a
  surfaced entry is never a ranked row. The resolution is the `next: queue` value the template
  already defines: an entry you *can* specify becomes a specified, ranked row, and one you cannot
  becomes an item file with a Problem section and **no row in `QUEUE.md`** until someone finishes
  it. Both halves keep unspecified work out of the file every session reads.
- The two-sweeper rule went into the template *and* into this repo's own live `FINDINGS.md`. The
  template only reaches projects scaffolded after today; the copy in front of the next session
  here is the one that changes behaviour now.
