---
id: "0190"
title: Re-argue the sprint skill's size exemption against its current size, or relocate
type: bug
next: design
status: ready
qa_level: unit
close_by: verify
size: s
created: 2026-09-25
source: retro
parent:
blocked_by: []
relates: ["0040", "0035", "0180"]
expects:
  - tests/skill-size.test.sh
  - skills/sprint/SKILL.md
claimed_by:
claimed_at:
touches:
---

## Problem

**`tests/skill-size.test.sh` records `skills/sprint/SKILL.md` as over the goal with a reason argued
from "the ~2,100 bytes that put this file over" (0040), but the file is now about 32,000 bytes
over, and the guard has no upper bound on a recorded file.**

Measured by develop 0180 (token 30db): 49,675 bytes before 0180 (29,485 over the 20,190 goal), and
52,288 after. Checked 2026-09-25: 52,300 bytes, and the retro that filed this row added about 700
more. Every ticket that grows the sprint skill passes against a reason that no longer describes the
file. 0180's design note asked the build not to raise the cap silently, and there is no cap to
raise.

## Open design question

Apply the payback test in the header of `tests/skill-size.test.sh` (0035) to the sprint skill as it
stands. Does any section relocate? And does a recorded exemption carry the size it was argued at, so
that the guard reds when the file outgrows its reason by some stated margin? If so, what is that
margin? The alternative is a reason that stays silently true forever.

## Functional requirements

- **FR1** — The sprint skill's recorded reason is argued against its current size, or the file is
  brought under that reason by relocation.
- **FR2** — Whatever design decides about a size bound, the decision is stated in the test's header
  beside the payback test, so the next over-goal file inherits it.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Documentation | A recorded exemption describes the file it exempts | the sprint skill grown past the size its reason names, with the guard still green | `documentation-conventions.md` |

## Acceptance criteria

To be written by design against the answer; FR1 and FR2 are the floor.

## QA plan

Unit, in `tests/skill-size.test.sh`.

## Out of scope

- The other over-goal skills, except as the rule FR2 states reaches them.

## Notes & decisions

- 2026-09-25 — filed by retro from develop 0180's finding (token 30db).
