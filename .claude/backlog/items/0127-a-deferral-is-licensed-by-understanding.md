---
id: "0127"
title: Say that a deferral is licensed by understanding and never by writing
type: bug
next: develop
status: ready
qa_level: verify
close_by: develop
qa_manual:
size: s
created: 2026-09-09
source: retro
parent:
blocked_by: []
relates: ["0060", "0080", "0100"]
expects:
  - skills/retro/SKILL.md
  - tests/retro-dispositions.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

**`retro` never states the limit that licenses a deferral, and read as written it reads as a fifth
disposition a pass may choose whenever writing is expensive.**

Step 4 names four — *landed*, *absorbed*, *filed*, *dropped* — and says of the third that *"a pure
unit of work is filed, not handed back: you have paid to understand it and `queue` would pay
again."* Deferral appears only in the tail of that same bullet — *"Beyond what this pass can
specify, defer it per Step 1"* — while Step 1 gives it a paragraph of its own about recording what
was established. So the reader meets deferral twice, in neither place beside the four, and with no
statement anywhere of **what** exhausts a pass. *"Beyond what this pass can specify"* is read as
capacity, and capacity is mostly typing.

**Measured, and it took a person to catch.** The retro pass of 2026-09-09 deferred seven entries
with verified destinations. Every one was a unit of work that pass had **fully understood** — the
case Step 4's own sentence forbids. The deferral was economy on *writing*, and it survived until the
user pushed back. What it bought the next pass is nothing, and what it costs is the failure Step 1
already names in the abstract: *"What must never happen is a later pass re-deriving triage an
earlier one already did."* Seven entries' judgement, bought once and thrown away, in a buffer
already at four times its threshold.

The rule the pass needed is one sentence, and it is nowhere: a deferral is for a lesson this pass
could not finish **understanding**, never one it could not finish **writing up**.

## Functional requirements

- FR1 — `retro` states that limit explicitly: understanding, not writing, is what a deferral
  records as exhausted.
- FR2 — The rule has **one** home, beside the four dispositions in Step 4 where the choice is
  actually made, and Step 1's deferral paragraph points at it rather than carrying a second copy.
  Two copies of a rule this repo has already drifted once is the defect `0126` exists for.
- FR3 — Step 4 says what a pass does with an entry it has understood and cannot finish writing —
  the case the deferral no longer covers — so removing the wrong answer does not leave the reader
  with none.
- FR4 — A guard executes FR1 and FR2 against Step 4's and Step 1's windows, not the file: *defer*
  and *understand* are ordinary words throughout this skill.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The rule states the failure it prevents — judgement bought twice — and not the reasoning that convinced anyone of it | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given `skills/retro/SKILL.md` Step 4's disposition window, when
  `tests/retro-dispositions.test.sh` reads it, then it states that a deferral records understanding
  a pass could not finish and not writing it could not finish. Red-making mutation: deleting that
  sentence, which returns the step to today's text.
- [ ] AC2 — Given Step 1's deferral paragraph, when `tests/retro-dispositions.test.sh` reads it,
  then it does not restate FR1's limit and instead points at Step 4. Red-making mutation: pasting
  FR1's sentence into Step 1 as well, which is the plausible belt-and-braces edit FR2 rejects.
- [ ] AC3 — Given Step 4's disposition window, when `tests/retro-dispositions.test.sh` reads it,
  then it names an answer for an entry understood but not written up. Red-making mutation: deleting
  that clause, which leaves FR3's case unanswered while AC1 stays green.
- [ ] AC4 — Given a fixture carrying every asserted phrase **outside** both windows, when
  `tests/retro-dispositions.test.sh` runs against it, then it fails. Red-making input: widening
  either window to the whole file, which turns that fixture green.
- [ ] AC5 — Given the edited skill, when `tests/citations.test.sh` and `tests/skill-size.test.sh`
  run, then each reports `0 failed`. Red-making change: adding the rule as a new paragraph rather
  than in place, pushing the file past its size goal with no recorded reason.

## QA plan

- **Why that level:** the artifact is two windows of skill prose; every criterion is a scoped grep
  and this project has no runner that reaches skills.
- **Specific checks:** run `tests/retro-dispositions.test.sh`, `tests/citations.test.sh` and
  `tests/skill-size.test.sh` individually rather than through the fail-fast `unit` command
  (`config.yml`).

## Out of scope

- **What the gate counts and whether an entry can carry a marker.** That is `0060`'s open design
  question and this item must not pre-empt it: FR3's answer is what a pass *does*, never a change to
  the entry format.
- Removing a lesson half independently of a work half (`0080`).
- The greppable form of the two findings markers (`0100`).
- `retro`'s cadence, and Step 1's slicing rule at volume — the second is recorded in `0060`.

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

## Notes & decisions

- Routed to `develop`: the rule is already decided by Step 4's own *"a pure unit of work is filed,
  not handed back"*. What is missing is the sentence that makes it operable, and there is no surface
  and no open decision — only an omission the same step's existing sentence implies.
- **Why this is not folded into `0060`.** `0060` decides what the gate counts and whether an entry
  is marked — a change to the buffer's format and to `./next`. This is a change to what a pass may
  choose, provable by grep, and it holds whatever `0060` decides. Bundled, it would wait on a design
  pass it does not need.
- `close_by: develop` because every criterion is a scoped grep the build session commits and proves
  red first; none is a reading.
- 2026-09-09 (queue, from `FINDINGS.md` parked the same day).
