---
id: "0095"
title: Hoist the shell short-circuit hazard where a guard author will read it
type: debt
next: develop
status: ready
qa_level: verify
size: s
created: 2026-09-05
source: agent
parent:
blocked_by: []
relates: ["0035", "0089"]
expects:
  - CLAUDE.md
  - tests/reference-size.test.sh
  - tests/reporting.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

Writing `[ "$n" -eq 0 ] && echo "FAIL …"` as a statement inside an audit function makes the function
exit **non-zero on the CLEAN path** — a function's exit status is its last command's, and on the
clean path that command is the failed test. `set -e` then turns it into a truncated result for every
caller, so the guard reports a partial audit exactly when nothing is wrong. That is the direction
that looks fine.

The warning is recorded inside one loop body of `tests/reference-size.test.sh` (`:90`), which is
where it was found. `tests/reporting.test.sh` hit it **twice in fresh code** before that note was
located. Twenty-one shell guards now share the pattern and every one of them starts `set -e`; the
warning lives in one of them, in a comment, three levels of indentation down.

This repo has no test runner (`.claude/backlog/config.yml`), so the guards are the whole safety net,
and a guard-authoring hazard that only the guard which already hit it warns about will be hit again
by the next one.

## Functional requirements

- FR1 — The hazard is stated in this repo's `CLAUDE.md`, in its existing `## Tests` section: the
  `set -e` interaction, that the failure lands on the **clean** path, and the correcting form (a
  full `if`, never `[ ... ] &&` as a function's last statement).
- FR2 — The two existing in-file comments in `tests/reference-size.test.sh` and
  `tests/reporting.test.sh` are replaced by a one-line citation of `CLAUDE.md`, so there is one copy
  and not three.
- FR3 — A guard asserts the hazard note is present in `CLAUDE.md`. It is the code behind FR1: a note
  that can be deleted with nothing noticing is the same failure one level up.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The note explains **why** — that a function's exit status is its last command's — rather than only restating the forbidden form, per *comments explain why, not what* | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given `CLAUDE.md`, when its `## Tests` section is read, then it names `set -e` and the
  clean path. Red-making mutation: deleting the words "clean path", which leaves a note describing
  the mechanism but not the direction that makes it dangerous, and reddens FR3's guard.
- [ ] AC2 — Given `tests/reference-size.test.sh` and `tests/reporting.test.sh`, when each is
  searched for a restatement of the hazard, then neither carries one — each cites `CLAUDE.md`
  instead. Red-making input: today's tree, where `reference-size.test.sh:90` restates it.
- [ ] AC3 — Given FR3's guard, when the hazard note is deleted from `CLAUDE.md`, then the guard fails
  and names the file. Red if it passes.
- [ ] AC4 — Given the whole suite after the change, when it is run file-by-file, then every file
  reports `0 failed`. Red if removing an in-file comment removed a line another guard greps for —
  `tests/citations.test.sh` is the one that would notice.

## QA plan

- **Why that level:** the deliverable is a note plus one guard; no runner applies.
- **Specific checks:** FR3's guard, `tests/citations.test.sh`, then the whole suite file-by-file.
  Apply AC3's deletion, confirm the guard reddens, revert and confirm green.

## Out of scope

- Rewriting the twenty-one guards to a common shape. The note stops the next instance; the existing
  ones already use the correcting form.
- Adding a shell linter — a dependency decision this item does not open.
- The whole-output matcher class, which is `0089`.

## Notes & decisions

- Routed to `develop`, and the destination is named rather than deferred, because `0035` already
  settled the test: a block relocates out of a file only where the share of runs skipping it clears
  `p = 1 / (1 + B/17,000)`. At roughly 250 bytes that is `p ≥ 0.985`, so a separate file never pays
  and the note stays inline. `CLAUDE.md` over a `tests/README.md` because `CLAUDE.md` is loaded into
  every session in this repo and already carries the `## Tests` section describing the suite.
- `CLAUDE.md` is not covered by `tests/skill-size.test.sh` or `tests/reference-size.test.sh`, so
  there is no size gate to argue with here.
