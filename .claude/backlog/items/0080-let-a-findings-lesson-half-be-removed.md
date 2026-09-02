---
id: "0080"
title: Let a findings entry's lesson half be removed independently of its work half
type: debt
next: design
status: ready
qa_level: unit
size: m
created: 2026-09-01
source: retro
parent:
blocked_by: []
relates: ["0078"]
expects:
  - skills/retro/SKILL.md
  - skills/queue/SKILL.md
  - skills/queue/templates/FINDINGS.md
claimed_by:
claimed_at:
touches:
---

## Problem

**`FINDINGS.md` says an entry that is both a lesson and a unit of work is taken by both sweepers, but
only one of them can remove it — so a lesson that has been landed is re-read at full price for ever.**

The rule as written: *"`queue` takes the entries that are units of work... `retro` takes the lessons...
An entry that is both is taken by both"*, and *"Each sweeper removes only the entries it processed"*,
and *"removing an unprocessed one is how the other sweeper's half disappears silently."* Those are
individually right and jointly unimplementable: `retro` lands the lesson, cannot remove the entry
without losing `queue`'s half, and leaves it — where the next `retro` pays to read it and re-derive
that nothing is owed.

**Recorded in this repo on 2026-08-25 and swept without being fixed. Recurred 2026-09-01**, measured
against AetherWorks' 44-entry buffer: 15 were pure lessons and removable; of the **29 left, at least
six have had their lesson half landed** — the fold-into-NNNN mechanism, three
guards-that-cannot-fail, and the `qa_level` half of two UI items — and survive only because deleting
them would lose `queue`'s half. Second occurrence, in a second repo, which is what argues for building
the mechanism rather than noting it a third time.

## Open design question

**A marker one sweeper writes and the other reads, or two independently removable halves?**

1. **A marker.** `retro` appends something like `[lesson landed: <commit>]` to the entry; `queue` treats
   a fully-marked entry as its own to remove once it has the row. Cheap; keeps one entry per finding;
   but adds a write to an entry the writing session does not own, which brushes against
   `CONCURRENCY.md`'s *A stage writes only the ticket it holds* — worth checking whether that rule
   reaches a buffer entry at all.
2. **Two halves.** The entry is split at sweep time into a lesson line and a work line, each removable
   by its own sweeper. No shared write; costs a rewrite of the entry and risks the halves drifting.

Also to settle: **whether `./next --findings` should count a marked entry**, since the cadence gate
reads that number, and a buffer full of half-processed entries currently looks neglected when it is not.

## Functional requirements

*(Completed by the design stage.)*

1. A finding that is both a lesson and a work item can have its lesson half discharged without losing
   its work half.
2. A later sweep can tell a half-processed entry from an untouched one without re-deriving it.
3. The cadence count reflects what is genuinely outstanding.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The `FINDINGS.md` header states the mechanism once; the skills cite it. The header is read by every writer, so it pays rent on every park. | `documentation-conventions.md` |
| Testing | Whatever is chosen must be greppable, so a guard can assert a marked entry is handled — the header's own format rule already turns on line shape. | `testing-conventions.md` |

## Acceptance criteria

*(Written by the design stage.)*

## QA plan

- **Level:** unit — this repo's whole suite.
- **Why this level:** the deliverable is prose plus, possibly, a line-shape convention that
  `./next --findings` parses; both are greppable.

## Out of scope

- Changing which sweeper takes what. That split is deliberate and is not what fails here.

## Notes & decisions

- First recorded 2026-08-25 in this repo's own buffer; swept unfixed. Re-recorded 2026-09-01 with the
  AetherWorks measurement above.
