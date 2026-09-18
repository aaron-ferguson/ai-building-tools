---
id: "0168"
title: Defer the findings gate to the end of confirmed scope instead of stopping in-scope work
type: bug
next: develop
status: ready
qa_level: unit
close_by: verify
qa_manual:
size: m
created: 2026-09-17
source: user
parent:
blocked_by: []
relates: ["0133", "0152", "0158"]
expects:
  - skills/queue/templates/next
  - .claude/backlog/next
  - tests/next.test.sh
  - skills/sprint/SKILL.md
  - tests/sprint.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

Parked 2026-09-14 from run-20260913T222409Z, verbatim:

> The findings gate stops in-scope work, but the user requires the retro and queue tail at the very
> end of the working session, whatever the count. `./next --drive` spent exit 5 at 8 of 8 while 0153
> still needed develop and verify; sprint Step 6 says to start no further stage. The user's rule:
> "Retro and queue should always be at the very end of the working session, regardless of how many
> findings are ready. Finish the work, then once everything passes verify we will do the retro." The
> gate should defer the tail until confirmed scope is finished, not stop it.

The retro of 2026-09-13 found no skill-only fix: `findings_gate` in `skills/queue/templates/next` is
called wherever a develop gate forms, ahead of `DISPATCH  develop`, so Step 6 prose cannot honour
the rule until the script defers. Step 6 opens *"The gate stops dispatch and fires once per run"*
and tells the supervisor to start no further stage session.

`--drive` cannot see the confirmed scope today: it is handed only `--completed` and `--started`, and
a scope ticket not yet started is invisible to it.

## Functional requirements

- FR1 — `next --drive` accepts a repeatable `--scope <id>` naming the run's confirmed scope, refused
  with a usage error (exit 2) unless the id is four digits, as `--started` is.
- FR2 — While any `--scope` id has a row at `next: develop` or `next: verify` that the walk could
  dispatch, a crossed findings gate (either limit) does not decide: the dispatch goes ahead, and one
  `NOTE` line says the gate crossed and is deferred until confirmed scope is finished.
- FR3 — Once no `--scope` id can be dispatched, a crossed gate decides exit 5 ahead of any further
  `DISPATCH`, and ahead of `COMPLETE`.
- FR4 — With no `--scope` given, the gate is evaluated only where the walk would otherwise decide
  `COMPLETE`, and a crossed gate exits 5 there instead of 3.
- FR5 — `skills/sprint/SKILL.md` Step 2's `--drive` command passes `--scope` for every confirmed-scope
  id, and Step 6 says the gate defers the tail to the end of confirmed scope rather than stopping
  dispatch. *Once per run* is unchanged.
- FR6 — `--help` documents `--scope`, and `.claude/backlog/next` is re-copied byte-equal from the
  template.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| API contract | The exit-code set and meanings are unchanged; `--scope` is additive, and only when exit 5 is spent moves | AC4, AC5 | `api-conventions.md` |
| Observability | A deferred gate is visible in the drive output, never silent | AC1 | `observability-conventions.md` |

## Acceptance criteria

Fixture ids are `9901`--`9903` so no evidence reads as a real row.

- [ ] AC1 — Given a fixture backlog with 8 findings against a threshold of 8 and rows `9901`, `9902`
  at `develop | ready`, when `--drive --scope 9901 --scope 9902` runs, then it exits 0 with
  `DISPATCH  develop` naming `9901`, and prints a `NOTE` containing `deferred`. Red: today's gate
  placement (exit 5).
- [ ] AC2 — Given the AC1 fixture after `9901` has moved to `verify | ready`, when `--drive --scope
  9901 --scope 9902 --started 9901 --completed develop:9901` runs, then it exits 0 dispatching
  `verify 9901` — re-asserting the deferral on a later call. Red: the gate evaluated before the
  started-verify dispatch.
- [ ] AC3 — Given the fixture with `9901` and `9902` closed and `9903` at `develop | ready` outside
  scope, when `--drive --scope 9901 --scope 9902` runs, then it exits 5 naming `retro, then queue`.
  Red: a deferral that outlives scope (exit 0, `DISPATCH  develop 9903`).
- [ ] AC4 — Given a fixture crossing only `findings_max_sprints` with `9901` in scope and
  dispatchable, then exit 0; with `9901` closed, exit 5. Red: the age limit left undeferred, or
  deferred forever.
- [ ] AC5 — Given no `--scope`, 8 findings of 8 and one `develop | ready` row, then exit 0; with no
  takeable row, exit 5 rather than 3. Red: today's behaviour (5 then 3).
- [ ] AC6 — `--drive --scope 12` exits 2. Red: the id accepted.
- [ ] AC7 — `skills/sprint/SKILL.md` no longer contains `start no further stage session`, and Step 2's
  `--drive` command contains `--scope`, asserted in `tests/sprint.test.sh`. Red: either restored.
- [ ] AC8 — `.claude/backlog/next` is byte-equal to `skills/queue/templates/next`
  (`tests/backlog-scripts-installed.test.sh`). Red: the copy not refreshed.

## QA plan

- **Why that level:** the router is a script over fixture backlogs; every criterion is a run of it.
- **Specific checks:** every existing exit-5 case in `tests/next.test.sh` re-read against FR4 — some
  assert exit 5 with a takeable row and will need `--scope` or a changed expectation, which is this
  ticket's contract change, not a regression; the whole suite.

## Out of scope

Which row a gate selects — `0158`, which edits the same walk; whichever lands second rebases. The
tail after a run that ends on `ESCALATE` with the gate crossed. The thresholds themselves.

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

## Notes & decisions

- 2026-09-17 (queue sweep after retro e30dfa9d) — filed from `FINDINGS.md`. `next: develop`: the
  user's rule settles what; how is discoverable in the script. Chosen, not asked: a new `--scope`
  flag rather than reusing `--started`, because a confirmed ticket not yet started must also hold
  the gate off; and with no `--scope` the gate waits for `COMPLETE`, applying the rule to hand-driven
  runs too.
