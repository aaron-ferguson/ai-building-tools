---
id: "0088"
title: Re-measure the protocol turn saving 0085 predicted, and record the verdict either way
type: chore
next: verify
status: scheduled
wake: 2026-10-31
qa_level: verify
size: s
created: 2026-09-03
source: agent
parent:
blocked_by: []
relates: ["0085", "0073", "0009", "0036"]
expects:
  - MEASUREMENT.md
  - docs/decisions/001-one-command-per-stage-boundary.md
claimed_by:
claimed_at:
touches: []
---

## Problem

`0085` predicted a turn and dollar saving **before** the change, which is what
`measurement-conventions.md` asks for and what `0009` — a modelled 66% that came in at 14.5% —
is the cautionary history for. The prediction is recorded; the verdict is not, and cannot be
until enough sessions have run under the new protocol.

This ticket was `0085`'s **AC6**. It was split out on 2026-09-03 because it structurally could
not close: it names a `verify` session classified by `tools/classify-turns.sh`, and
`MEASUREMENT.md`, *Re-running this*, pins that classification to `--until 2026-10-31`. Held
inside `0085` it blocked a ticket that was green on every other criterion, and `.claude/backlog/close`
ticks every `- [ ] AC` line unconditionally — so closing `0085` with AC6 still in it would have
silently recorded an unrun measurement as verified (the `0044` failure mode, arriving by the
other door).

## Decision

Settled by `0085`: `docs/decisions/001-one-command-per-stage-boundary.md`. Nothing to decide
here — this ticket runs a measurement that already has its command, its pin and its budget.

## Functional requirements

- FR1 — Re-run `tools/classify-turns.sh` over sessions since the protocol changed, using the
  re-measurement pin in `MEASUREMENT.md`, *Re-running this* (`--since 2026-08-25 --until
  2026-10-31`), not the reproduction pin beside it. The two are different commands and only the
  second answers this.
- FR2 — Compare turns per session per stage against the budget in `MEASUREMENT.md`,
  *The turn budget*: develop 30, verify 28, queue 28, design 20, retro 22.
- FR3 — Re-run `tools/cost-by-category.sh` on the same set, since `0085`'s prediction is stated in
  dollars as well as turns (develop −20.6%, verify −29.9%, queue −20.4%, design −26.3%,
  retro −6.3%; per ticket $7.66 → $5.74, −25.1%).
- FR4 — **Record the verdict whichever way it comes out**, including "the prediction was wrong",
  and say which of the two outcomes `0085`'s record distinguishes: *the turns were removed* versus
  *the tokens were saved*.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Measurement | The verdict is recorded even when it refutes the prediction, against the figure declared up front rather than one chosen afterwards. | `measurement-conventions.md` |
| Correctness | The re-measurement pin, not the reproduction pin. Using the pinned 2026-08-23/24 set answers a different question and would report no change by construction. | `measurement-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given a `verify` session run after FR7 landed, when its transcript is classified, then
      the advisory dirty-path intersection costs it no turn of its own. *(This is `0085`'s AC6
      verbatim. Note the Step 7 wording changed again on 2026-09-03 — it now takes a fresh capture
      **fused onto the last evidence-gathering command**, so the claim under test is still "no turn
      of its own", not "no git command".)*
- [ ] AC2 — Given the re-measurement, when turns per session per stage are compared to the budget,
      then each stage is at or under it, or the shortfall is stated per stage with a reason.
- [ ] AC3 — Given `MEASUREMENT.md`, when read after this ticket, then it carries the observed
      figures beside the predicted ones and a verdict sentence that survives being wrong.
- [ ] AC4 — Given the mechanism composition, when read, then the `lock` line is at 0.0% of mechanism
      turns, which is the falsifiable form `0085` FR3 committed to.

## QA plan

- **Level:** verify — the deliverable is a measurement and a recorded verdict. The scripts it runs
  are guarded by their own suites (`tests/measurement.test.sh`, `tests/cost-by-category.test.sh`).
- **Specific checks:** that the re-measurement pin was used and not the reproduction pin; that the
  verdict is stated even if it refutes the prediction.

## Out of scope

- Changing the protocol further in response to the result. That is a new ticket, and `0036`'s
  orchestration slices are the other half of the plan.

## Notes & decisions

- Split out of `0085` on 2026-09-03 at Aaron's direction so `0085` could close on the criteria a
  session can actually reach. `0085`'s notes carry three passes' worth of reasoning that this was
  the honest shape; this is that split.
- `0085` is **not** listed in `blocked_by`: this ticket depends on `0085`'s change having shipped,
  not on its row being open, and a `blocked_by` naming a closed ticket blocks nothing anyway.
