---
id: "0223"
title: Re-anchor whole-file and section-scoped prose guards that cannot fail
type: bug
next: develop
status: ready
qa_level: unit
size: m
created: 2026-10-27
source: agent
parent:
blocked_by: []
relates: ["0089", "0222", "0224"]
expects:
  - tests/sprint.test.sh
  - tests/batching.test.sh
  - tests/falsifiable-acs.test.sh
  - tests/sprint-ledger.test.sh
  - tests/qa-level-once.test.sh
  - tests/claim.test.sh
  - tests/close.test.sh
claimed_by:
claimed_at:
touches:
ac_digest: AC1=437c3946 AC2=4fb8c5a1 AC3=483508ba AC4=3958b61b AC5=5fad7b36
---

## Problem

A guard that greps a **whole file** — or a filtered stream that selects every block of a kind, or a
section extracted by a helper whose match is looser than it reads — is satisfied by any sentence in
that whole. `testing-conventions.md` names the shape (*anchor an assertion to the claim, not the
document that contains it*). The `0089` sweep has not looped this class yet (2026-10-25 slice:
"FR1's whole-FILE class has not been looped yet"); `0089`'s retro notes record instances of it,
each found by a mutation that did not redden:

- `tests/sprint.test.sh` `section()` matching a heading as a prefix, so an absence assertion over
  an empty extraction is green forever; a `says` token satisfied by a code fence in the same
  section; AC25's lock guard anchored to a literal (`\.lock`) the guarded block does not use
  (`"$LOCK"`), so a fenced `rm -rf "$LOCK"` stayed green.
- `tests/batching.test.sh` `binds()` spanning a sentence break.
- `tests/falsifiable-acs.test.sh` `window()` whose `!first` clause can never fire.
- `tests/sprint-ledger.test.sh` AC6's awk reporting only inside its last branch, so a missing
  denominator is invisible.
- `assert_contains "DISPATCH  verify 0102"` passing on a batch line — a list assertion that should
  be an equality.
- An `assert_contains` on a flag name matched by the prose explaining the flag (`next`'s `usage()`).
- The `grep -c` pre-filter's three blind spots (line-based, filtered streams, file-level counts for
  section-scoped guards) — recorded in `0089`'s 2026-09-07 note; count within the guard's own subject.

## Functional requirements

- FR1 — The sweep builds its worklist from a loop, recorded before the first edit: every assertion
  in `tests/*.test.sh` whose subject is a whole file, a whole-file filtered stream, or a section
  extracted by a helper. The grep(s) used are recorded verbatim.
- FR2 — Each **presence** assertion on the worklist is re-anchored to the line, element or claim it
  is about, or deleted with its reason recorded. Each **absence** assertion keeps a subject at least
  as wide as the claim it protects; one whose subject can be empty (an extraction that matched
  nothing) is made to fail on the empty subject.
- FR3 — Each instance named in the *Problem* is checked still true at the current tree first; one
  still true is fixed under FR2, one already discharged is recorded with the commit that discharged it.
- FR4 — Each re-anchored or fixed assertion is **mutation-proved**: per file, the change to the
  subject that turned it red, and that it went green on revert. Where a behaviour is defended by two
  mechanisms, the mutation breaks both, and says so. No mutation found → deleted, not kept.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The per-file mutation evidence from FR4 is written into this item as the sweep runs. Reds if any re-anchored file lacks an entry (AC2) | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given the recorded worklist grep(s), when they are re-run, then every file they hit is
  listed in *Notes & decisions* as examined. Red if any hit file is absent from that list.
- [ ] AC2 — Given each file the sweep re-anchored, when *Notes & decisions* is read, then it names
  for that file the mutation applied and the assertion that went red under it. Red if any
  re-anchored file has no such entry.
- [ ] AC3 — Given each instance named in the *Problem*, when *Notes & decisions* is read, then it
  carries either a run mutation that now reddens the guard or the commit that already discharged
  it. Red if any named instance has neither.
- [ ] AC4 — Given `tests/sprint.test.sh`'s `section()`, when it is asked for a heading the fixture
  does not carry, then an absence assertion over its result fails rather than passing on the empty
  extraction. Red if it passes.
- [ ] AC5 — Given the whole suite after the sweep, when `for t in tests/*.test.sh; do "$t" || true;
  done` is run against an unmodified tree, then every file reports `0 failed`. Red if any assertion
  was re-anchored onto a claim the prose does not actually make.

## QA plan

- **Why that level:** the assertions are the deliverable, so the runner that exercises them is the
  suite; `unit` is this project's whole suite (`config.yml`).
- **Specific checks:** run the suite file-by-file rather than through the fail-fast `unit` line,
  then re-apply two of the FR4 mutations at random and confirm the named assertion reddens.

## Out of scope

- The rewrap-survival matcher (`0063`); where the two touch the same line, leave the reflow alone.
- `case "$out"` blocks (`0089`), numeric needles (`0222`), the standing guard (`0224`).
- `skills/**` prose, and new coverage for claims nothing checks.
- Fixture-quality instances in `0089`'s 2026-09-12 note that are not assertions which cannot fail
  (a stale *Why that level* rationale, `add_item_blank_scope` setting `claimed_by`, fixture titles,
  low fixture ids) — they stay recorded there; one found to be in class is handled here under FR3.

## Notes & decisions

- Split out of `0089` on 2026-10-27 by `queue` (sprint run-20261027T185815Z, on the person's
answer to the escalation), after two develop sessions released `0089` partly done and both
recommended one row per class. The evidence that motivates it is `0089`'s *Notes & decisions*;
read it before claiming rather than re-deriving it. Routed to `develop`: the corrective shape is named by
  `testing-conventions.md`, so no decision blocks the criteria. Ranked below `0222`: same tier and
  sweep; capture order.
