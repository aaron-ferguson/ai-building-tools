---
id: "0029"
title: Reconcile close's definition of held with CONCURRENCY.md's
type: bug
next: verify
status: ready
blocked_by:
  - "0028"
qa_level: verify
size: s
created: 2026-08-23
source: agent
expects:
  - skills/queue/templates/close
  - references/CONCURRENCY.md
  - skills/verify/SKILL.md
  - tests/close.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

Two paths close a ticket, and they disagree about which dependents they may write.

`CONCURRENCY.md` (*A stage writes only the ticket it holds*) and `verify` Step 5's hand-close both
define *held* as a **non-empty `claimed_by:` in the item**, and 0023 deliberately removed the row
clause from both — `CONCURRENCY.md`'s *Claim tokens* puts ownership in the item, not the row.

`skills/queue/templates/close` still treats an `in-progress` row carrying **no token** as held as
well, via an `||`, citing *The working tree is shared too*.

So the script is stricter than the rule: a hand-close following the documented fallback writes a
dependent the script leaves alone. Both directions are defensible — the script's extra caution has
a real justification, and the rule's narrowness is what 0023 decided — but *two paths differing* is
not, and it is the exact shape of the defect 0023's first verify pass failed on.

This was parked rather than fixed because correcting it in the rule costs words the then-current
1,500-token ceiling had no margin for. 0028 removes that constraint, which is why this ticket is
blocked on it rather than on anything technical.

## Functional requirements

- FR1 — one definition of *held* exists, and it is stated in `CONCURRENCY.md` as the single source.
  The decision is recorded with its reasoning: either an `in-progress` row with an empty `touches:`
  and no token counts as held, or it does not.
- FR2 — `skills/queue/templates/close`'s reconcile guard implements exactly that definition, with no
  additional condition of its own.
- FR3 — `verify` Step 5 item 3's hand-close describes exactly that definition, so the documented
  fallback and the script write the same set of dependents.
- FR4 — `tests/close.test.sh` asserts the chosen definition directly, in both directions: a
  dependent that *is* held is reported and not written, and a dependent that is not held is
  written. A test asserting only the current `||` would pass on either definition.
- FR5 — whichever way FR1 goes, the losing side's reasoning is recorded rather than deleted. If the
  row clause goes, `CONCURRENCY-INCIDENTS.md` keeps why it was ever there; a rule that looks
  arbitrary gets re-added by the next session that meets the case.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | Three places state this rule (the reference, the skill, the script). One is the source and the other two cite it; a third copy of the definition is what produced the mismatch | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given `references/CONCURRENCY.md`, when *A stage writes only the ticket it holds* is
  read, then *held* has exactly one definition and it states whether a tokenless `in-progress` row
  counts.
- [ ] AC2 — Given `skills/queue/templates/close`, when its reconcile guard is read, then its
  condition matches AC1's definition with no extra clause.
- [ ] AC3 — Given `skills/verify/SKILL.md` Step 5 item 3, when it is read, then its description of
  *held* matches AC1's definition word for word in substance.
- [ ] AC4 — Given a backlog where a dependent's item has an empty `claimed_by:` and its row reads
  `in-progress`, when `close` runs on its blocker, then the dependent is treated per AC1's
  definition, and `tests/close.test.sh` asserts that outcome explicitly.
- [ ] AC5 — Given a backlog where a dependent's item has a non-empty `claimed_by:`, when `close`
  runs on its blocker, then the dependent is reported and not written.
- [ ] AC6 — Given `tests/close.test.sh`, when the reconcile guard's condition is mutated to the
  *other* definition, then the suite goes red — and the mutation is diffed first to confirm it
  landed (`testing-conventions.md`).
- [ ] AC7 — Given `for t in tests/*.test.sh; do "$t" || exit 1; done`, when it runs, then all
  suites pass.

## QA plan

- **Level:** verify — shell script plus prose, no runner.
- **Why this level:** the behaviour under test already has a scripted suite
  (`tests/close.test.sh`), and the rest is a three-way text agreement checkable by reading.
- **Specific checks:** `tests/close.test.sh` executed; the AC6 mutation diffed and run; the three
  statements read side by side and quoted in the verdict.

## Out of scope

- Retiring the token ceiling that parked this. That is 0028, and this ticket is blocked on it.
- Replacing the ownership mechanism with claim directories. That is 0007, which will rewrite this
  guard again; the point here is that the two paths agree *now*, whatever 0007 later changes them to.

## Notes & decisions

- Recommended resolution, for the session that takes this: keep the rule's narrow definition
  (`claimed_by:` only) and drop the script's `||`. The row is a cache; ownership lives in the item.
  A tokenless `in-progress` row is drift, and 0024 built `./next --drift` precisely so drift is
  reported rather than silently honoured by every other reader. Record the counter-argument in
  `CONCURRENCY-INCIDENTS.md` per FR5.

### What this session found

- **The decision went as the note recommended**: *held* is a non-empty `claimed_by:` in the item and
  nothing else. `close`'s `||` row clause is gone, `CONCURRENCY.md` now states the definition
  explicitly (including that a tokenless `in-progress` row does *not* count), and `verify` Step 5
  item 3 now **cites** that rule by name instead of carrying a third copy — which is what the NFR
  asked for and what AC3 checks.
- **The row clause's window has closed on its own, which is the argument the ticket did not have.**
  It guarded a session that had flipped the row but not yet written its token. `./claim` now writes
  the row *and* the token under one lock in one commit, so no live session passes through that state
  — it is only ever drift. That, not the "one definition beats two" argument, is what makes dropping
  it safe rather than merely tidier. Recorded in `CONCURRENCY-INCIDENTS.md` per FR5.
- **A fourth use of the word *held* existed and was not in the FRs.** *The working tree is shared
  too* reads an empty `touches:` on an `in-progress` row as "held" — that is about **files**, not the
  row, so it was never in conflict, but leaving both senses unqualified would have made AC1's "exactly
  one definition" false on a plain reading. Disambiguated in place, six words.
- **`skills/queue/templates/close` is not the only copy.** 0027 instantiated the three scripts into
  this repo's own `.claude/backlog/`, and `tests/backlog-scripts-installed.test.sh` asserts the copy is
  byte-identical to the template. A template fix is two files, and forgetting the second turns a green
  suite red in a file the ticket never named. `touches:` carried both.
- **AC6's mutation was run and diffed**: re-adding the `||` clause made 5 assertions fail
  (58 passed, 5 failed), so the suite pins the definition rather than the current spelling.

### Full-suite result

Nine of ten suites green. `tests/next.test.sh` is red (30 passed, 9 failed) and it is **not this
ticket's**: it holds another window's uncommitted red-first tests for 0031 (YAML comments in
`fm_list`). Proven rather than assumed — the committed `next.test.sh` passes 21/21 in throwaway
worktrees both at this ticket's HEAD and at the commit before this work began. Deterministic fixture
suite, no re-rolled input, so one run a side is a valid comparison. Worktrees removed in the same turn.
