---
id: "0046"
title: Make the README guard list provably complete
type: bug
next: develop
status: ready
qa_level: unit
size: s
created: 2026-08-25
source: agent
parent:
blocked_by: []
relates: ["0027", "0028"]
expects:
  - README.md
  - tests/citations.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

`README.md`'s *Testing* section offers a block as "Run every guard". It lists **8 suites; `tests/`
holds 11**. Missing: `backlog-scripts-installed.test.sh`, `citations.test.sh` and
`graph-fields.test.sh`. A contributor who runs the block believes they ran the suite and did not —
including the guard that proves the installed backlog scripts still match their templates, which is
the one whose whole job is catching a drift nobody would otherwise see.

The list is hand-maintained and nothing checks it against the directory, so it has drifted three
times without a single red. The finding that noticed it named one missing file and was itself
already out of date by two more, which is the shape of the defect: each new suite is added beside
its neighbours in `tests/` and the README is a second place nobody is reminded of.

## Functional requirements

- FR1 — `README.md`'s guard block names every `tests/*.test.sh` present in the repo.
- FR2 — A guard fails when a file matching `tests/*.test.sh` is not named in `README.md`'s guard
  block, reporting the missing filename.
- FR3 — That guard also fails when the block names a `tests/*.test.sh` that does not exist,
  reporting the stale name — the same staleness from the other direction.
- FR4 — The guard lives in an existing suite rather than a twelfth file, and `README.md`'s block is
  updated in the same change so the suite is green when it lands.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The README's own claim is what is being repaired; the one-line comment beside each suite is part of the list and is written for the three being added, not left blank | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given `README.md`, when its guard block is compared against `ls tests/*.test.sh`, then
  every file is named.
- [ ] AC2 — Given the new guard, when a name is removed from `README.md`'s block, then the suite
  fails reporting that filename.
- [ ] AC3 — Given the new guard, when a name for a non-existent suite is added to the block, then
  the suite fails reporting that name.
- [ ] AC4 — Given each of the three newly-added lines, when read, then it carries a one-line
  description in the same shape as the eight already there.
- [ ] AC5 — Given the whole suite, when `for t in tests/*.test.sh; do "$t" || exit 1; done` runs,
  then every suite passes.

## QA plan

- **Level:** unit — the deliverable is an executable guard, and this project's `unit` command runs
  every `tests/*.test.sh`.
- **Why this level:** both AC2 and AC3 are a one-line mutation of `README.md` followed by a run.
- **Specific checks:** drive AC2 and AC3 one at a time against a copy of `README.md` taken before
  the edit, reverting between. Then the full suite.

## Out of scope

- Adding a runner. `CLAUDE.md` states the suite is the shell loop and there is no framework;
  this ticket does not change that.
- Auditing the eight existing descriptions for accuracy.

## Notes & decisions

- Routed to `develop`: the defect is a set difference between a directory and a list, and the fix
  is the assertion of that set difference. Nothing to settle.
- FR3 matters as much as FR2. A list checked in one direction only is the same defect 0043
  describes in the size gates, and there is no reason to ship the second instance of it knowingly.
