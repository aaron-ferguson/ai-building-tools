---
id: "0142"
title: Let the driver see the drift classes that stop a human reader
type: bug
next: verify
status: in-progress
qa_level: unit
size: s
created: 2026-09-09
source: agent
parent:
blocked_by: []
relates: ["0115", "0141", "0131"]
expects:
  - .claude/backlog/next
  - skills/queue/templates/next
  - tests/next.test.sh
claimed_by: "1f54"
claimed_at: 2026-09-11T01:26:15Z
touches:
---

## Problem

**`--drive` performs no drift check, so every drift class is invisible to the only reader that is
never a person.** `./next --drift` exits non-zero on eight classes precisely so that a row
disagreeing with its own item stops the work; `--drive`'s body contains no drift check at all, and
`orchestrate` invokes `./next --drift` nowhere in its loop — only at `:233` as a precondition and
`:271` in passing. Driven on the `0084` drift shape, `./next --drift` exits 1 while `./next --drive`
prints `COMPLETE nothing takeable` and exits 3 over the same queue.

So a drifted backlog reads as a *finished* one to a driver. Worse, `0115`'s own *Notes & decisions*
justify its new classes exiting non-zero by that routing, which means the justification was already
false when it was written — the non-zero reaches a human running `--drift` by hand and nothing else.
`orchestrate:117` described `1` as a drift exit from `--drive`; the 2026-09-09 retro corrected that
sentence and filed this row for the behaviour, because correcting prose to match a gap is not
closing it.

The gap matters most on the `0128` sprint slice, where `0131` makes the driver's stop conditions
load-bearing: a driver that cannot distinguish *nothing takeable* from *the queue is inconsistent*
will end a sprint clean over a backlog that needs a person.

## Functional requirements

- **FR1** — `--drive` runs the same drift check `--drift` runs, before it selects a gate.
- **FR2** — Where that check finds drift, `--drive` reports it and exits with a code the driver
  routes on as *a person decides*, not as *complete*. Which code is an implementation choice between
  reusing `4` (escalate) and a new one; reusing `3` is forbidden, because `3` is what the bug is.
- **FR3** — The drift report `--drive` prints names the same rows and classes `--drift` names, by
  sharing the check rather than restating it. Two copies of the class list is the defect this row's
  `relates` already records twice.
- **FR4** — `orchestrate`'s routing table names the new outcome, and its claim about what `1` means
  stays true.

## Non-functional requirements

- **Compatibility** — a clean queue still exits `0`/`3`/`4`/`5` exactly as today, so no existing
  driver run changes behaviour. How this would red: a case asserting the exit code of `--drive` over
  a drift-free fixture backlog.
- **Documentation** — `skills/orchestrate/SKILL.md`'s routing paragraph is the cache of these codes
  and goes stale silently. How this would red: a guard asserting each code this row can emit appears
  in that paragraph.

## Acceptance criteria

- [ ] AC1 — Given a fixture backlog carrying one drifted row (a `ready` row over an item with an open
  `blocked_by`), when `./next --drive` runs, then it reports the drift, names the row, and exits
  non-zero and not `3`. Red-making input: today's `next`, which exits `3` on that fixture.
- [ ] AC2 — Given a drift-free fixture backlog with one takeable row, when `./next --drive` runs, then
  it dispatches as today and exits `0`. Red-making mutation: running the drift check unconditionally
  fatal, which breaks every clean run.
- [ ] AC3 — Given a fixture backlog with drift and nothing takeable, when `./next --drive` runs, then
  the drift exit wins over `COMPLETE nothing takeable`. Red-making mutation: ordering the drift check
  after the takeability walk, which is the current shape's failure.
- [ ] AC4 — Given `skills/orchestrate/SKILL.md`, when the routing paragraph is read, then every exit
  code `--drive` can emit is named there, including the one FR2 adds. Red-making mutation: deleting
  the new code's clause.
- [ ] AC5 — Given `for t in tests/*.test.sh; do "$t" || true; done`, when it runs, then every file
  reports `0 failed`. Red-making change: editing `skills/queue/templates/next` and not
  `.claude/backlog/next`.

## QA plan

- **Why this level:** `unit` — `next` is a shell script with an existing suite, and every requirement
  is a case in `tests/next.test.sh` over a scaffolded fixture backlog.
- **Specific checks:**
  - Run `tests/next.test.sh`, `tests/orchestrate.test.sh` and
    `tests/backlog-scripts-installed.test.sh` individually first, then the whole suite file-by-file
    with `|| true` per `config.yml`'s note.
  - Mutate each new branch away one at a time, confirming the mutation landed before reading the
    colour.

## Out of scope

- Changing what counts as drift, or adding a class. `0115` and `0141` own the class list.
- Making `orchestrate` act on the new exit beyond naming it — the stop is a person's call.

## Notes & decisions

- **2026-09-09 (retro)** — Filed from a `verify` park on `0115`. The park measured both commands on
  the `0084` drift shape; those figures are in the Problem section. The retro corrected
  `orchestrate:117`'s false sentence in the same pass and deliberately did not try to fix the
  behaviour there, because the skill is not where the check lives.
- **2026-09-10 (develop)** — FR2's implementation choice went to `4`, the escalate code, not a sixth
  one. The outcome is *a person decides*, which is what `4` already means and what `orchestrate`
  already routes; a new code would have needed a new routing rule for an outcome that has one.
- **2026-09-10 (develop)** — FR3 is satisfied by extracting the `--drift` walk into `drift_report()`
  and calling it from both modes. It returns the verdict and prints the report, so `--drive`
  discards neither: the DRIFT lines a driver prints are the same bytes `--drift` prints, asserted
  line for line rather than by wording.
- **2026-09-10 (develop)** — **the check runs on ALL classes, and that reverses two behaviours
  `--drive` had on purpose.** A stale `blocked` cache and a `ready` row over an open blocker were
  both re-derived and dispatched, because the graph is the authority and the column only caches it
  (0024). AC1's own fixture is exactly the second of those and requires a non-zero exit, so the
  ticket settles it: the property splits by reader. `./next develop` still offers such a row — the
  0024 half is asserted alongside the new one in `tests/next.test.sh` — and the DRIVER stops,
  because it is the reader with a person to ask. The two falsified cases say this where they stand.
- **2026-09-10 (develop)** — **and that collides with `handoff`, which is neither this ticket's file
  nor its call.** `handoff` refuses to write `blocked` ("derived from blocked_by and never
  authored"), and `develop` Step 5 tells a stage that cannot go green to add a `blocked_by` entry
  for the same reason. The row is then `ready` over an open blocker — drift class 2 — so the next
  `--drive` call stops a run on a state the tooling produced and gives no way to avoid. Built as
  specified, because 0142's *Out of scope* reserves the class list to 0115 and 0141 and narrowing a
  contract is the author's call. Filed to `FINDINGS.md`; it still needs a row.
- **2026-09-10 (develop)** — three pre-existing cases scaffolded a tokenless `in-progress` row while
  describing a row another session holds. 0140 settled that as unheld and 0115 class 5 as drift, so
  they were cases about drift wearing the words of cases about ownership; nothing red until a reader
  crossed the two. They now carry a token, via a new `add_ticket_held` fixture helper.
