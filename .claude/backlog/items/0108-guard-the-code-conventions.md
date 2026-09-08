---
id: "0108"
title: Guard the code conventions this repo's suite does not check
type: debt
next: develop
status: ready
qa_level: unit
qa_manual:
size: s
created: 2026-09-07
source: agent
parent:
blocked_by: []
relates: []
expects:
  - tools/validate-json-schema.py    # the file that shipped unhinted
  - tests/                           # a new guard belongs here
claimed_by:
claimed_at:
touches:
---
## Problem

**This repo's first standalone `.py` shipped with no type hints, and no guard in a 22-file suite
could have said so.**

`tools/validate-json-schema.py` (new in `0039`) carried no annotations on any of its three
functions, against `CONVENTIONS_CORE.md`'s *"Python with full type hints"* — which is a **principle**,
not a preference, and so not subject to any project override. It reached a QA pass and was caught
only by a human-shaped read of the diff in `verify` Step 4's always-on convention pass: no AC and no
NFR row covered it, and the suite greps prose rather than parsing code.

That file is fixed. The general shape is not: **this repo's suite enforces its prose conventions and
none of its code ones.** The pre-existing embedded python in `tools/*.sh` is unhinted too.

A convention that is both a **principle** and mechanically checkable should have a guard rather than
a reviewer — a reviewer catches it on the diff they happen to read, and holds it for exactly one
file.

## Functional requirements

- **FR1** — A guard asserts that every `def` in every tracked `.py` carries annotated arguments and
  a return type. `python3 -c` over `ast` does this in about ten lines.
- **FR2** — The guard derives its subjects from the tree, never from a list. A guard enumerating the
  files it checks is green by construction on the next one added, which is the moment it is most
  needed (`testing-conventions.md`).
- **FR3** — The embedded python in `tools/*.sh` is either brought under FR1 or explicitly excluded
  with the reason recorded where the exclusion lives.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Dependencies | No new dependency. `ast` is in the standard library; this repo has no runner and adds none | `dependency-conventions.md` |
| Documentation | The guard's header names the principle it holds and the file whose miss bought it | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given a tracked `.py` whose function lacks an argument annotation, when the guard runs,
  then it reds and names the file and the function.
- [ ] AC2 — Given a tracked `.py` whose function lacks a return annotation, when the guard runs,
  then it reds and names the file and the function.
- [ ] AC3 — Given a fully annotated tree, when the guard runs, then it passes **and reports how many
  files it scanned**, so a run that scanned nothing cannot read as a pass.
- [ ] AC4 — Given a new unannotated `.py` added anywhere in the tree, when the guard runs, then it
  reds without the guard being edited.
- [ ] AC5 — Given the embedded python in `tools/*.sh`, when the guard runs, then it is either checked
  or excluded with a recorded reason, and which of the two is unambiguous from the guard's output.

## QA plan

- **Level:** unit — this repo's whole suite.
- **Why this level:** the deliverable is a guard, and its own falsifiability is the deliverable's
  whole point.
- **Specific checks:** feed the detector each defect directly — a missing arg annotation, a missing
  return annotation, a clean file — rather than only running it over the live tree, since a filter
  matching nothing is green precisely when its subject has gone missing
  (`testing-conventions.md`). Assert the scanned-file count is non-zero.

## Out of scope

- Type-checking. This is an annotation-presence guard, not `mypy`; adding a type checker is a
  dependency decision and a separate row.
- The other code conventions in `CONVENTIONS_CORE.md`. Types are the one that has already been
  missed here; widening the guard on speculation is YAGNI.

## Notes & decisions

- 2026-09-07 — Filed by `retro`. The finding's own framing is the reason this is a guard and not a
  note: the rule was in force, findable, and a principle, and a reviewer still had to be the one to
  catch it.
