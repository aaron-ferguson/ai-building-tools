---
id: "0222"
title: Re-anchor numeric needles a larger figure can satisfy
type: bug
next: develop
status: ready
qa_level: unit
size: m
created: 2026-10-27
source: agent
parent:
blocked_by: []
relates: ["0089", "0223", "0224"]
expects:
  - tests/sprint-ledger.test.sh
  - tests/measurement.test.sh
  - tests/cost-by-category.test.sh
  - tests/close-by.test.sh
  - tests/sprint.test.sh
claimed_by:
claimed_at:
touches:
ac_digest: AC1=7b20bd62 AC2=94965f42 AC3=10ac3c59 AC4=ced66047
---

## Problem

A numeric needle inside a glob — `*2.00*`, `*10.00*`, `*"30.00"*`, `*0.2550*` — is satisfied by any
larger figure that contains it, so the assertion stays green when the figure it is about is wrong.
It closed `0085` green: `*10000*` was a substring of `100000`. The `0089` sweep's 2026-10-25 slice
proved it twice more by mutation (`*"GROWTH"*1500*` green on `15000`, `*"TURNS"*2.0*` green on
`2.00`, both in `tests/sprint.test.sh`, both re-anchored in `4766607`) and ran the class's loop:
`grep -nE '^\s*\*[^)]*[0-9]{2,}[^)]*\*\)' tests/*.test.sh` found ~40 hits outside
`tests/sprint.test.sh`, densest in `tests/sprint-ledger.test.sh`, `tests/measurement.test.sh`,
`tests/cost-by-category.test.sh` and `tests/close-by.test.sh`.

Two named instances parked against `0089` belong to this class: the sprint stage-budget guard
checks that the comment above `stage_budget_usd:` cites `MEASUREMENT.md`'s per-stage means and
nothing relates that comment to the value (setting `retro: 99.00` with its `2.51` citation intact
stayed green on 2026-09-08); and `paired()` was satisfied by a default estimate the tool forges
rather than the source figure (2026-09-12).

## Functional requirements

- FR1 — Every hit of the numeric-needle grep above is examined, except hits inside a
  `case "$out"` block, which are `0089`'s. Each needle is re-anchored so no larger figure the same
  output carries can satisfy it — an exact compare on an extracted field, or delimiters on both
  sides — or deleted with its reason recorded in *Notes & decisions*.
- FR2 — The two named instances are each checked still true at the current tree first; one still
  true is re-anchored (the stage-budget value asserted from its cited mean, `paired()` anchored on
  the source rather than the figure), one already discharged is recorded with the commit that
  discharged it.
- FR3 — Each re-anchored assertion is **mutation-proved**: per file, the change to the subject
  that turned it red, and that it went green on revert. No mutation found → deleted, not kept.
- FR4 — The grep is run and its hit list recorded before the first edit, and the files examined are
  recorded, so an examined-clean file reads differently from an unexamined one.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The per-file mutation evidence from FR3 is written into this item as the sweep runs, not reconstructed at the end. Reds if any re-anchored file lacks an entry (AC2) | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given the sweep is complete, when the numeric-needle grep is run, then for every hit
  outside a `case "$out"` block, prefixing or suffixing a digit to the figure the subject prints
  (`2.00` → `12.00`) turns that assertion red. Red if any such hit stays green under that change.
- [ ] AC2 — Given each file the sweep re-anchored, when this item's *Notes & decisions* is read,
  then it names for that file the mutation applied and the assertion that went red under it. Red if
  any re-anchored file has no such entry.
- [ ] AC3 — Given the stage-budget guard, when a stage's `stage_budget_usd:` value is changed to
  `99.00` with its cited mean left intact, then the suite reports a named failure for that stage —
  or *Notes & decisions* names the commit that already made it red. Red if the suite stays `0 failed`
  and no such commit is named.
- [ ] AC4 — Given the whole suite after the sweep, when `for t in tests/*.test.sh; do "$t" || true;
  done` is run against an unmodified tree, then every file reports `0 failed`. Red if any assertion
  was re-anchored onto a figure the code does not actually print.

## QA plan

- **Why that level:** the assertions are the deliverable, so the runner that exercises them is the
  suite; `unit` is this project's whole suite (`config.yml`).
- **Specific checks:** run the suite file-by-file rather than through the fail-fast `unit` line,
  then re-apply two of the FR3 mutations at random and confirm the named assertion reddens.

## Out of scope

- `case "$out"` blocks (`0089`), whole-file and section-scoped prose guards (`0223`), the standing
  guard (`0224`).
- The stage-budget rounding granularity in the comment's prose — assert against the shipped values
  (all three caps are mean × 1.5 rounded to the nearest five cents); restating the rule in
  `skills/**` is not this row's.
- Writing new coverage for figures nothing checks.

## Notes & decisions

- Split out of `0089` on 2026-10-27 by `queue` (sprint run-20261027T185815Z, on the person's
answer to the escalation), after two develop sessions released `0089` partly done and both
recommended one row per class. The evidence that motivates it is `0089`'s *Notes & decisions*;
read it before claiming rather than re-deriving it. Routed to `develop`: the corrective shape is named by
  `testing-conventions.md` and demonstrated in `4766607`, so no decision blocks the criteria.
  Ranked directly below `0089`: same tier and the same sweep, `0089` first by capture order.
