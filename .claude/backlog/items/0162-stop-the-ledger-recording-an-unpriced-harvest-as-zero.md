---
id: "0162"
title: Stop the sprint ledger recording an unpriced harvest as a measured USD 0.00
type: bug
next: develop
status: ready
qa_level: unit
close_by: verify
size: s
created: 2026-09-13
source: user
parent:
blocked_by: []
relates: ["0135", "0152", "0163"]
expects:
  - tools/sprint-ledger.sh
  - tests/sprint-ledger.test.sh
  - tools/harvest-usage.sh
claimed_by:
claimed_at:
touches:
---

## Problem

**`tools/sprint-ledger.sh record` writes `0.00` USD for sessions whose turns simply had no rate.**
That zero then feeds the per-ticket mean of every later estimate.

Parked from run-20260913T034946Z, verbatim:

> `harvest-usage.sh` has no rate for claude-sonnet-4-6, and `sprint-ledger.sh record` wrote USD 0.00
> and 0 tokens for two sessions that committed real work. An all-unpriced harvest is read as a
> measured zero; it should refuse or label the figure unpriced.

Commit `75bec41` added the missing rate, but only for that model. The ledger defect is unchanged:
`harvest()` in `tools/sprint-ledger.sh` parses only the `TOTAL` row. `harvest-usage.sh` prints
`UNPRICED turns on a model with no published rate: N` on a separate line, and `harvest()` never
reads it. The next model id without a rate reproduces the zero.

## Functional requirements

- FR1 — `harvest()` in `tools/sprint-ledger.sh` reads the `UNPRICED turns …: N` line as well as the
  `TOTAL` row.
- FR2 — When the harvest priced no turn and N > 0, `record` writes the `usd` actual as `unpriced`
  and the `tokens` actual as `unpriced`, never `0.00`/`0`, and its source cell names N.
- FR3 — When some turns were priced and N > 0, `record` writes the figures it has and the source
  cell says `partial: N unpriced turn(s)`.
- FR4 — `read_ledger`, which the estimate derives history from, skips an `unpriced` cell rather than
  reading it as zero, and a `partial` figure is read as recorded.
- FR5 — The existing *empty store* case (no turns of the run's sessions at all, no UNPRICED line)
  keeps its current documented behaviour.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Observability | A figure that was not measured is never rendered as a measured one | AC1 | `measurement-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given a fixture transcript directory whose run sessions carry only turns on a model id
  absent from `RATES`, when `sprint-ledger.sh record` runs over it, then the appended block's `usd`
  and `tokens` rows read `unpriced` in the Actual column and contain no `0.00`. Red: today's script,
  which writes `0.00`.
- [ ] AC2 — Given a fixture with one priced and one unpriced turn, when `record` runs, then the `usd`
  Actual is the priced turn's cost and its row contains `partial: 1 unpriced turn(s)`. Red: FR3's
  label omitted.
- [ ] AC3 — Given a `LEDGER.md` fixture with two sprint blocks, one `usd` Actual `unpriced` over 3
  tickets and one `10.00` over 2 tickets, when `estimate --tickets 1` runs, then the `usd` estimate
  is `5.00` (10.00 / 2), not `2.00` (10.00 / 5). Red: FR4 omitted.

## QA plan

- **Why that level:** `tools/sprint-ledger.sh` has a fixture suite, `tests/sprint-ledger.test.sh`.
- **Specific checks:** AC1–AC3 there; the existing empty-store case stays green unmodified.

## Out of scope

- Adding further model rates.
- Re-recording run-20260913T034946Z's committed ledger block.
- The `--run` bound's session scope — 0163.

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

## Notes & decisions

- **2026-09-13 — filed by a `queue` sweep of FINDINGS.md** (run-20260913T034946Z). Commit `75bec41`
  discharged the pricing half of the entry, and this ticket is the half it left. Routed to
  `develop`: the input (`harvest-usage.sh` output) and the output (a `LEDGER.md` block) are the
  contract.
- **Label, not refuse.** A refusal would leave the sprint's other figures unrecorded; the label keeps
  them and marks the one that was not measured.
