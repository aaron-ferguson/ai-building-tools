---
id: "0042"
title: Anchor the vocabulary-pinning guards to the claims they make
type: bug
next: develop
status: in-progress
qa_level: unit
size: m
created: 2026-08-25
source: agent
parent:
blocked_by: []
relates: ["0026", "0032", "0051"]
expects:
  - tests/measurement.test.sh
  - tests/batching.test.sh
claimed_by: "7085"
claimed_at: 2026-08-30T15:58:21Z
touches:
  - tests/measurement.test.sh
  - tests/batching.test.sh
  # Mutated transiently to prove each repaired assertion reds, then reverted in the same turn.
  # Not edited by this ticket -- its Out of scope forbids it -- but dirty under my hand meanwhile.
  - MEASUREMENT.md
  - skills/develop/SKILL.md
---

## Problem

Three shipped guards run, assert, and cannot fail against the defect they were written for. All
three grep a *document* for a word that also occurs in that document's prose, so they pin
vocabulary rather than structure. Each was found by mutation and each stayed green.

**`tests/measurement.test.sh` AC5 — the verdict check.** It asserts the verdict with
`grep -qE 'materialised|partly|did not'` over `MEASUREMENT.md`. The record's own section heading
*What the two runs did not hold constant* contains "did not", and **AC8's assertion in the same
file requires that heading to exist** — so AC8 passing guarantees AC5 passing. Proved by deleting
the entire `## Verdict` section: `grep -c materialised` went to 0 and the suite still reported
`ok the record states a verdict`; only the separate `5.09` presence check reddened. The test's own
header comment claims the opposite — "a run that produces figures and no verdict fails … which is
why AC5 … [is] asserted separately from AC1".

**`tests/measurement.test.sh` AC1 — the per-skill breakdown.** Checked with `present … "verify"`
and friends. The words `queue`, `develop`, `verify`, "cost per turn" and "context tokens per turn"
all occur in the surrounding prose, so deleting the `| verify | 10 | … |` row from the isolated
table left 40/40 passing.

**`tests/batching.test.sh` AC4 — the dated figure.** Asserts the batching statement "carries a
dated figure" with `grep -qE '20[0-9][0-9]-[0-9][0-9]' "$PARA"` over the whole paragraph, so *any*
date anywhere in it satisfies it. The paragraph currently holds two (`**2026-08-22**` on the
figure, and `2026-08-23/24` in the sentence about 0026), so stripping the figure's own date leaves
the guard green — confirmed by driving 0032's AC4 mutation and watching the suite still report
13 passed. It gets weaker every time the paragraph gains a date, and 0026 is due to add one.

This is the same defect three times, and `testing-conventions.md` now names it after the last
retro landed the lesson. What has not happened is the fix to the guards themselves.

## Functional requirements

- FR1 — `tests/measurement.test.sh`'s AC5 assertion is scoped to the body of `MEASUREMENT.md`'s
  `## Verdict` section, or matches the verdict word and its subject on one line, so that deleting
  the verdict reds it.
- FR2 — `tests/measurement.test.sh`'s AC1 assertions match **table rows** in the isolated-run
  table — the row shape, not the skill name — so that deleting any one row reds it.
- FR3 — `tests/batching.test.sh`'s AC4 assertion binds the date to the figure it dates, so that a
  second date elsewhere in the paragraph cannot satisfy it and stripping the figure's own date
  reds it.
- FR4 — Each of the three rewritten assertions carries a comment naming the mutation that proves
  it can fail, so a later reader can re-run the proof without re-deriving it.
- FR5 — The header comment of `tests/measurement.test.sh` is corrected where it currently claims
  AC5 catches figures-with-no-verdict, since that claim is what made the defect invisible.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The corrected header comment and the per-assertion mutation notes are written in the same change as the fix, not afterwards | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given the repaired suite, when the `## Verdict` section is deleted from
  `MEASUREMENT.md`, then `tests/measurement.test.sh` reports a failure naming the verdict.
- [ ] AC2 — Given the repaired suite, when the `| verify | … |` row is deleted from the
  isolated-run table in `MEASUREMENT.md`, then `tests/measurement.test.sh` reports a failure.
- [ ] AC3 — Given the repaired suite, when the date is stripped from the batching figure in
  `skills/develop/SKILL.md` while the paragraph's other date is left in place, then
  `tests/batching.test.sh` reports a failure.
- [ ] AC4 — Given each of the three repaired assertions, when the file is read, then a comment
  beside it names the mutation that reds it.
- [ ] AC5 — Given `tests/measurement.test.sh`'s header, when it is read, then it no longer claims
  AC5 catches a run that produces figures and no verdict by a document-wide match.
- [ ] AC6 — Given the whole suite, when `for t in tests/*.test.sh; do "$t" || exit 1; done` runs on
  an unmutated tree, then every suite passes.

## QA plan

- **Level:** unit — the deliverable is executable guards, and this project's `unit` command runs
  every `tests/*.test.sh`.
- **Why this level:** each AC is a mutation-and-observe on a real file, which is what the suite
  already does; nothing here crosses a seam or needs a build.
- **Specific checks:** run the three mutations in AC1–AC3 one at a time, confirming the mutation
  landed by diffing against a copy taken before the edit rather than against HEAD, and reverting
  each before the next. Then the full suite clean.

## Out of scope

- **Repairing `MEASUREMENT.md`'s figures.** The record's live denominator and its unreproducible
  re-run recipe are 0051, which depends on this ticket landing first: fixing the record while
  these guards cannot fail leaves no evidence the fix held.
- Auditing every other guard in `tests/` for the same shape. Three are named here with proof; a
  sweep is a separate ticket and a different size.
- Changing what `MEASUREMENT.md` or the batching paragraph *say*. This ticket changes only what
  the suite asserts about them.

## Notes & decisions

- Routed to `develop` rather than `design`: each FR names the file, the assertion and the mutation
  that must red it, so there is no decision left to settle — only the writing.
- `testing-conventions.md` already carries the rule ("Anchor an assertion to the claim, not to the
  document that contains it"), landed by the 2026-08-25 retro. This ticket is the code half; the
  ticket verifies the guards, not the convention.
