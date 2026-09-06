---
id: "0097"
title: Record what a transcript cannot say about thinking tokens
type: debt
next: develop
status: ready
qa_level: verify
size: s
created: 2026-09-05
source: agent
parent:
blocked_by: []
relates: []
expects:
  - MEASUREMENT.md
  - tools/harvest-usage.sh
  - tests/measurement.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

Thinking is roughly **70.5% of a session's output tokens** and **its text is not retained in the
transcript**, so the largest output term cannot be measured from the record. Stored `thinking` blocks
carry an empty `thinking` field and a ~3,000-character `signature`, so `0074`'s measurement could
only reach it as a **residual** — output tokens minus estimated text tokens minus tool-input tokens.
For comparison, the same pass put human-facing narration at 4.6% and tool inputs at 24.9%.

`MEASUREMENT.md` records the consequence in one clause — *"Own output includes thinking and the
arguments of every tool call, so it is not a measure of prose"* (`:196`) — but not the number, not
the reason, and not the method. So the next turns-and-tokens breakdown that assumes the transcript
holds what the model wrote will silently attribute **70% of output to nothing**, and it is not
obvious before you look.

This is due to bite: `MEASUREMENT.md` schedules a re-measurement on **2026-10-31**
(`tools/classify-turns.sh --since 2026-08-25 --until 2026-10-31`), and `RANKING.md` names that run
as one of the things that would change the order of this whole backlog.

## Functional requirements

- FR1 — `MEASUREMENT.md` records the caveat as a mechanism: stored `thinking` blocks carry an empty
  `thinking` field and a signature only, so thinking text is unmeasurable from the transcript and
  reachable only as a residual.
- FR2 — It records the residual **method** — output tokens minus estimated text tokens minus
  tool-input tokens — so the figure can be recomputed rather than trusted.
- FR3 — It records the three shares as at the run that produced them, dated: thinking ~70.5%,
  tool inputs 24.9%, human-facing narration 4.6%. Dated because they are a cached figure about a
  moving system, per `develop` Step 2.
- FR4 — A guard asserts FR1's caveat is present, so a later edit cannot quietly remove the one
  sentence that stops the next measurement being wrong by a factor of three.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The figures carry the date and the run they came from, never a bare percentage | `documentation-conventions.md` |
| Observability | The caveat sits with the measurement it qualifies, not in a separate note, so a reader of the table cannot miss it | `observability-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given `MEASUREMENT.md`, when it is searched for the empty-`thinking`-field mechanism,
  then it is stated. Red-making input: today's file, which states only that own output *includes*
  thinking.
- [ ] AC2 — Given `MEASUREMENT.md`, when the residual method is read, then it names all three terms —
  output tokens, text tokens, tool-input tokens. Red-making mutation: deleting the tool-input term,
  which leaves a method that does not reproduce the figure and reddens the guard asserting all three.
- [ ] AC3 — Given `MEASUREMENT.md`, when the three shares are read, then each carries the date of the
  run it came from. Red-making mutation: removing the date from the 70.5% figure.
- [ ] AC4 — Given FR4's guard, when FR1's caveat is deleted from `MEASUREMENT.md`, then the guard
  fails and names the file. Red if it passes.
- [ ] AC5 — Given `MEASUREMENT.md` after the change, when `tests/measurement.test.sh` and
  `tests/money-in-skill-prose.test.sh` run, then each reports `0 failed`.

## QA plan

- **Why that level:** the deliverable is prose in one record plus one guard; no runner applies.
- **Specific checks:** FR4's guard, `tests/measurement.test.sh`, `tests/money-in-skill-prose.test.sh`.
  Apply AC4's deletion, confirm the guard reddens, revert.

## Out of scope

- Re-running the measurement. This item records what the last one learned about its own instrument;
  the 2026-10-31 run is separate and already scheduled in `MEASUREMENT.md`.
- Changing `tools/harvest-usage.sh` to capture thinking text. The transcript does not contain it, so
  there is nothing for the tool to capture.

## Notes & decisions

- Routed to `develop`: the mechanism and the figures are already established by `0074`'s pass. What
  is missing is that they live in a `FINDINGS.md` entry rather than in the record they qualify.
- Ranked above the other Tier 5 rows on tie-breaker 3, knowledge freshness: the residual method is
  reconstructable today from `0074`'s working and would have to be re-derived in a month, and the
  2026-10-31 run is the reader who needs it.
