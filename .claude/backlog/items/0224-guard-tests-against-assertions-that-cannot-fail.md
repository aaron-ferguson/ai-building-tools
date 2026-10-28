---
id: "0224"
title: Guard tests/ against assertions that cannot fail
type: chore
next: design
status: ready
qa_level: unit
size: s
created: 2026-10-27
source: agent
parent:
blocked_by: []
relates: ["0089", "0222", "0223"]
expects:
  - tests/guards-can-fail.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

`0089`, `0222` and `0223` sweep the existing guards; nothing stops the class returning in the next
test file. `testing-conventions.md` says a suite with a known systematic weakness is swept from a
loop — and a sweep without a standing check is re-run by hand forever. This was `0089`'s FR5 and
AC4 ("a new file `tests/zz-whole-output.test.sh` that matches a substring against a whole command's
output … FR5's guard fails and names that file").

## Functional requirements

- FR1 — A test file in `tests/` refuses, naming the file and line, any assertion of the shapes the
  *Open design question* settles. It runs as part of the normal suite.

## Open design question

**What can the guard mechanically refuse?** `0089`'s re-specification (2026-10-27) made two forms
legitimate that the original FR5 would have banned: an **absence** needle matched over the whole
output, and a **presence** needle that is a complete line the subject prints. So "matches a
substring against a whole command's output" is no longer the rule, and a guard cannot read whether
a phrase is printed unconditionally. Candidate shapes, for `design` to choose between or combine:
(a) refuse a `case`/glob presence needle over a multi-line capture unless it is anchored by a helper
(`grep -q '^…$'` or an extracted field); (b) refuse a numeric needle with a `*` on either side;
(c) refuse a helper called with a pattern beginning `-` and no `--`; (d) an explicit per-line
annotation for the deliberate exceptions. The decision also fixes the fixture AC (the old AC4) and
whether the guard scans its own file (`0089`'s 2026-09-09 note, item 3: a guard scanning the
directory it lives in reads its own fixtures as hits).

**When handing to `develop`, `design` sets `blocked_by: ["0089", "0222", "0223"]`**: the guard
reds the current tree until those three sweeps close. Not set now, so the decision can be taken
while the sweeps run.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Testing | The guard's own fixtures prove each refused shape reds and each permitted shape passes — `design` names them as ACs | `testing-conventions.md` |

## Acceptance criteria

To be written by `design` once the question above is settled.

## QA plan

- **Why that level:** the deliverable is a test file; `unit` is this project's whole suite.

## Out of scope

- Re-anchoring existing assertions — `0089`, `0222`, `0223`.

## Notes & decisions

- Split out of `0089` on 2026-10-27 by `queue` (sprint run-20261027T185815Z, on the person's
answer to the escalation), after two develop sessions released `0089` partly done and both
recommended one row per class. The evidence that motivates it is `0089`'s *Notes & decisions*;
read it before claiming rather than re-deriving it. Routed to `design`: the rule the guard enforces is a decision, not a
  reading of the code — see the open question. Ranked below `0223`: it is the last of the four to
  land, and a prerequisite outranks its dependent.
