---
id: "0164"
title: Record active and elapsed time and interruptions in the sprint ledger, and estimate them
type: feature
next: develop
status: ready
qa_level: unit
close_by: verify
size: m
created: 2026-09-13
source: user
parent:
blocked_by: []
relates: ["0135", "0152", "0162"]
expects:
  - tools/sprint-ledger.sh
  - tests/sprint-ledger.test.sh
  - skills/sprint/SKILL.md
  - tests/sprint.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

**The ledger counts a session-limit wait as work, and neither the estimate nor the ledger knows that
interruptions happen.** On this repo they are routine, because tokens run out mid-session on local
unpushed work.

Parked from run-20260913T034946Z, verbatim:

> Ledger wall-clock is first-to-last run-log event, so a session-limit wait counts as work: 646 min
> recorded. The run log needs limit-hit and resumed events, and the ledger needs active and elapsed
> time as separate figures.

> The sprint estimate has no term for a mid-session stop, which re-pays a session's context on
> resume. Stops will be routine here, so the estimate should price expected interruptions and the
> ledger should record how many occurred.

The run-log half is done: `a666012` gave sprint Step 7 `limit_hit` and `resumed` events. The ledger
half is not:

- `wall_clock_minutes()` in `tools/sprint-ledger.sh` still returns the last event minus the first.
- `FIGURES` has no interruption count.
- `estimate()` emits one `wall_clock_min` line.

## Functional requirements

- FR1 — `record` computes three figures:
  - `elapsed_min`: last event − first event.
  - `active_min`: elapsed, minus every interval from a `limit_hit` event to the next `resumed`
    event. An unmatched `limit_hit` runs to the last event.
  - `interruptions`: the count of `limit_hit` events.
- FR2 — A recorded block's figures are `tickets`, `active_min`, `elapsed_min`, `interruptions`,
  `tokens`, `usd`, replacing `wall_clock_min`.
- FR3 — `read_ledger` reads a legacy block's `wall_clock_min` as `elapsed_min` and never as
  `active_min`.
- FR4 — `estimate` emits `active_min`, `elapsed_min` and `interruptions`, each as per-ticket history
  mean × tickets, or `no-prior` where no recorded block holds that figure.
- FR5 — The cost of a resume's context re-pay reaches the estimate through history: `tokens`/`usd`
  history is harvested by session id, covering both legs of a resumed session. On the priors path
  (no history), the `usd` source line says it excludes resume re-pay.
- FR6 — `record`'s `--estimate-wall` flag becomes `--estimate-active` and `--estimate-elapsed`, plus
  `--estimate-interruptions`, each accepting `no-prior`. `skills/sprint/SKILL.md`'s `record` and
  `estimate` invocations, and its Step 5 description of the ledger's actuals, match.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Observability | Waiting time is never reported as active time | AC1 | `measurement-conventions.md` |
| Migration / schema | Existing `LEDGER.md` blocks stay readable without rewriting them | AC3 | `migration-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given a fixture run log with a first event at 00:00, `limit_hit` at 00:30, `resumed` at
  01:30 and a last event at 01:40, when `record` runs, then the block reads `active_min` 40,
  `elapsed_min` 100, `interruptions` 1. Red: today's single `wall_clock_min` 100.
- [ ] AC2 — Given a run log with events at 00:00 and 00:20 and a last event that is a `limit_hit` at
  00:30, when `record` runs, then `active_min` is 20 and `interruptions` is 1. Red: an unmatched
  `limit_hit` ignored.
- [ ] AC3 — Given a `LEDGER.md` with one legacy block (`wall_clock_min` 60 over 2 tickets) and one new
  block (`active_min` 20, `elapsed_min` 50 over 1 ticket), when `estimate --tickets 2` runs, then
  `elapsed_min` is 73 ((60 + 50) / 3 × 2) and `active_min` is 40 (20 / 1 × 2). Red: the legacy block
  ignored prints `elapsed_min` 100; the legacy figure read as active prints `active_min` 53.
- [ ] AC4 — Given a ledger holding no `interruptions` figure, when `estimate` runs, then its
  `interruptions` line reads `no-prior`. Red: an invented default.
- [ ] AC5 — Given `skills/sprint/SKILL.md`, when `tests/sprint.test.sh` runs, then it contains
  `--estimate-active` and no `--estimate-wall`. Red: the old invocation left in place.

## QA plan

- **Why that level:** `tools/sprint-ledger.sh` is fixture-tested; the skill invocation is a prose
  guard.
- **Specific checks:** AC1–AC4 in `tests/sprint-ledger.test.sh`; AC5 in `tests/sprint.test.sh`.

## Out of scope

- An unpriced harvest — 0162.
- Pricing a resume from `MEASUREMENT.md` priors. No prior records the resume re-pay, so the estimate
  labels the omission (FR5) rather than inventing a figure.
- Rewriting committed `LEDGER.md` blocks.

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

## Notes & decisions

- **2026-09-13 — filed by a `queue` sweep of FINDINGS.md** (run-20260913T034946Z). Two entries became
  one ticket: both read the same `limit_hit`/`resumed` events and change the same `FIGURES` list.
  Routed to `develop`.
- **AC3's figures were chosen so the rules disagree.** Each wrong reading gives a different number
  from the right one on the figure it corrupts: 100 against 73 for elapsed, 53 against 40 for
  active.
