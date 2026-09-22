---
id: "0166"
title: Make sprint-ledger estimate count tail sessions once, guard each tail stage, and label only the history it used
type: bug
next: verify
status: in-progress
qa_level: unit
close_by: verify
qa_manual:
size: m
created: 2026-09-17
source: agent
parent:
blocked_by: []
relates: ["0135", "0152", "0162", "0163", "0164"]
expects:
  - tools/sprint-ledger.sh
  - tests/sprint-ledger.test.sh
  - skills/sprint/SKILL.md
claimed_by: "bcb7"
claimed_at: 2026-09-22T14:52:19Z
touches:
---

## Problem

Three defects in `tools/sprint-ledger.sh estimate`, each parked separately on 2026-09-13/14, verbatim:

> **May now count tail cost twice on a ledger with history.** Since 0152 it adds retro/queue sessions
> from MEASUREMENT.md on top of the ledger per-ticket mean, but `record` sums a recorded sprint's
> tokens and usd over *every* session id in its run log, tail included, so a sprint that ran a tail
> already folds tail cost into that mean. Separating tail sessions out of the recorded actuals would
> need its own row.

> **No guard reds when `estimate` stops pricing `--retro`.** Mutation `tail = []` in place of the
> retro entry left `tests/sprint-ledger.test.sh` at 106 passed, 0 failed: 0152's re-verification
> guards compare retro+queue against retro alone, so a missing retro cancels out on both sides.

> **`estimate` labels its source "LEDGER.md 2 recorded sprint(s) over 4 ticket(s)" when one of the
> two blocks is excluded from the per-ticket means.** `read_ledger` counts every block with any
> numeric figure as a sprint, while the means use only blocks whose `tickets` is numeric, so the
> label overstates what the figure rests on.

Confirmed against the code: `estimate()` builds `ledger_src` from `len(sprints)` while `hist` uses
only blocks carrying `tickets`.

## Functional requirements

- FR1 — `record` writes the tokens and USD of sessions whose outcome `stage` is `retro` or `queue` as
  two figures of their own, `tail_tokens` and `tail_usd`, and leaves them out of the `tokens` and
  `usd` actuals.
- FR2 — `read_ledger` reads `tail_tokens` and `tail_usd`, and `estimate`'s per-ticket means are
  computed from `tokens` and `usd` alone.
- FR3 — A block recorded before FR1 (no `tail_*` figure) still contributes to the means, and the
  source label names how many used blocks predate the split, as `N predate the tail split`.
- FR4 — The source label's sprint and ticket counts are those of the blocks the means actually used;
  a block excluded for having no numeric `tickets` is counted as excluded in the label, never as a
  recorded sprint.
- FR5 — `tests/sprint-ledger.test.sh` carries a guard comparing `--retro` against no tail flag, for
  `tokens` and `usd`, so a retro that stops being priced reds on its own.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Observability | No session's cost enters an estimate twice, and a source label never names history the figure did not use | AC2, AC3 | `measurement-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given a fixture run log with one develop, one verify, one retro and one queue session of
  known, distinct usage, when `record` runs, then the block's `usd` actual is the develop+verify sum
  and `tail_usd` is the retro+queue sum. Red: summing every session id into `usd`, as today.
- [ ] AC2 — Given a `LEDGER.md` fixture with one block of `tickets 2`, `usd 10.00`, `tail_usd 6.00`,
  when `estimate --tickets 1 --retro --queue` runs, then `usd` equals 5.00 plus the fixture
  MEASUREMENT retro and queue means. Red: a mean read over `usd + tail_usd` (8.00 plus the same).
- [ ] AC3 — Given a `LEDGER.md` fixture with two blocks, one carrying `tickets 2` and one carrying no
  `tickets` figure, when `estimate` runs, then the label reads `1 recorded sprint(s) over 2
  ticket(s)` and names one excluded block. Red: today's `len(sprints)`, printing `2 recorded sprint(s)`.
- [ ] AC4 — Given a pre-split block (no `tail_*` figures) among the used blocks, the label contains
  `1 predate the tail split`. Red: the clause dropped.
- [ ] AC5 — Given the mutation `tail = []` in place of the retro entry in `estimate`, when
  `tests/sprint-ledger.test.sh` runs, then it reports at least one failure. Red: the FR5 guard absent
  (today: 106 passed, 0 failed under that mutation).

## QA plan

- **Why that level:** pure functions of fixture files; every criterion is a script run.
- **Specific checks:** AC5's mutation applied to `tools/sprint-ledger.sh` and restored by path; AC2's
  figures chosen so the double-counting rule and the fixed rule disagree.

## Out of scope

An unpriced harvest recorded as zero — `0162`, which also edits `read_ledger`; whichever lands
second rebases on the other. Bounding `harvest-usage --run` — `0163`. Rewriting existing
`LEDGER.md` blocks to split their tail cost.

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

## Notes & decisions

- 2026-09-17 (queue sweep after retro e30dfa9d) — bundled from three `FINDINGS.md` entries: FR1–FR3
  discharge the tail double count, FR5 the unguarded retro pricing, FR4 the source label. `next:
  develop`: the ledger format is the contract and the right split is discoverable from the code.
  Chosen, not asked: pre-split blocks stay in the means with a labelled count rather than being
  dropped, because dropping them leaves most estimates with no history at all.

- **2026-09-22 (develop, 183a) — AC5 discharged against the exact mutation the ticket names.**
  `tail = [("retro", 1, 0)] if opts["retro"] else []` replaced by `tail = []` previously left the
  suite at *106 passed, 0 failed*; it now reds **2** cases, each naming the cause —
  `--retro did not raise the tokens estimate (15992754 -> 15992754)` and the same for `usd` at
  `15.32 -> 15.32`. The file was restored by path and re-run green. **Run, not reasoned.** The
  reason 0152's guards could not catch it: they compared retro+queue against retro alone, so a
  missing retro subtracted from both sides and cancelled. FR5's guard compares `--retro` against
  **no tail flag at all**, which has nothing to cancel against.
- **2026-09-22 (develop, 183a) — AC2 was green before a line was written, for the wrong reason, and
  is now green for the right one.** Before the change `read_ledger` ignored any row not in
  `FIGURES`, so the fixture's `tail_usd` row was invisible and the mean came to 10.00/2 by accident
  rather than by rule. Mutation-checked rather than accepted: folding the tail back in —
  `sum(s[figure] + s.get("tail_" + figure, 0) for s in have)` — takes the estimate to **14.75** and
  reds AC2 with its own message. Restored and re-run green. **Run, not reasoned.**
- **2026-09-22 (develop, 183a) — an absent tail row and a zero tail row must not collapse, which
  decided a design point no FR states.** The tail rows are written **even when no tail ran**, as a
  measured `0.00`. If they were omitted in that case, "this block predates the tail split" (FR3)
  and "this sprint ran no retro or queue" would be the same observation, and FR3's
  `N predate the tail split` count becomes unknowable. Absence therefore means exactly one thing:
  recorded before FR1 existed.
- **2026-09-22 (develop, 183a) — `tail_tokens`/`tail_usd` are deliberately NOT in `FIGURES`.**
  `record` refuses a missing `--estimate-<figure>` flag (FR8, 0135), so adding them there would
  make every `record` invocation refuse for want of an `--estimate-tail-usd` that nothing supplies.
  They are actuals with no estimate behind them, so their Estimate cell reads `no prior` and they
  live in `LEDGER_FIGURES`, which is what `read_ledger` accepts.
- **2026-09-22 (develop, 183a) — 0162's unpriced labelling was factored into `labelled()` rather
  than copied.** This ticket gave the tail its own harvest, and an unpriced tail is as silent a
  zero as an unpriced gate; two copies of that branch is the duplicated *knowledge*
  `CONVENTIONS_CORE.md` requires fixing on sight. 0162 landed first, so this ticket rebased on it
  as its *Out of scope* section directed.
- **2026-09-22 (develop, 183a) — `skills/sprint/SKILL.md` was declared in `touches:` and not
  edited.** No FR here reaches it: FR1–FR5 are all script and guard. The ledger block gained two
  rows, which a supervisor reads rather than writes, and the skill states no row list to go stale.
  Flagged rather than silently widened — if the author wants the new rows described in Step 9, that
  is a separate row.
