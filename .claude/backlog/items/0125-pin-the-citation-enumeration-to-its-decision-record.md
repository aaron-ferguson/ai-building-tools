---
id: "0125"
title: Pin the citation enumeration to its decision record so widening one cannot leave the other stale
type: bug
next: develop
status: ready
qa_level: unit
close_by: verify
qa_manual:
size: s
created: 2026-09-09
source: retro
parent:
blocked_by: []
relates: ["0089"]
expects:
  - tests/close-by.test.sh
  - docs/decisions/003-who-may-close-a-ticket.md
  - skills/queue/templates/close
claimed_by:
claimed_at:
touches:
---

## Problem

**The citation enumeration is authored in two places and nothing pins them together.** `close`'s
`path_is_conventional_guard` and `docs/decisions/003`'s *A citation has to name an assertion* both
spell out the same list — `tests`/`spec`/`__tests__` directories, `*.test.*` / `*_test.*` /
`*.spec.*` / `*_spec.*` / `test_*`, or mode `100755`.

`003` is right to record what shipped — FR14 asked for exactly that — so **this is not a restatement
to delete.** The gap is narrower: `tests/close-by.test.sh` asserts that `003` mentions `close_by`
and the eligibility *rule*, and never that its enumeration still matches the script's. Widening the
`case` in `close` leaves `003` stale and the suite green.

The fix shape already exists in this repo: `tests/cost-by-category.test.sh` was reanchored to assert
a **relationship** between two figures rather than either literal, which is what survives a change to
the thing being described.

`0089` was opened and is not the home for this: that ticket sweeps for assertions that *cannot* fail.
This assertion can fail — it just asserts the wrong thing.

## Functional requirements

- FR1 — a guard asserts that `003`'s enumeration and `close`'s `case` describe the same set.
- FR2 — the assertion is a relationship between the two sources, not a third copy of the list.
- FR3 — widening `close`'s `case` without updating `003` reds the suite.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | `003` keeps recording what shipped; this ticket does not delete the record | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — given a new extension added to `close`'s `path_is_conventional_guard` and not to `003`,
  when the suite runs, then it fails and names both files; red by reverting the new guard.
- [ ] AC2 — given the same extension added to both, when the suite runs, then it passes — the
  control that AC1 tracks agreement rather than pinning today's list.
- [ ] AC3 — given an entry removed from `003` only, when the suite runs, then it fails; red the
  same way, and this is the direction AC1 does not cover.
- [ ] AC4 — the guard contains no third copy of the enumeration; red by writing one, which AC2
  would otherwise let through.

## QA plan

- **Why that level:** a shell guard over two tracked files; every criterion is a mutation of one of
  them and a run.
- **Specific checks:** `tests/close-by.test.sh`, and the whole suite for the mode-`100755` case,
  which is checked differently from the extension cases and is the likeliest thing to be missed.

## Out of scope

Changing what `close` accepts. Sweeping other guards (`0089`).

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

## Notes & decisions

- 2026-09-09 (retro) — filed from `FINDINGS.md`, parked 2026-09-09 and deferred once by this retro
  before being filed properly. The entry noted this is the same shape as a `queue`/`close`
  near-verbatim pair flagged 2026-09-08 and still open.
