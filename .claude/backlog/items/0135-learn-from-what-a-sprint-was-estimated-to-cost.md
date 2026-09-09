---
id: "0135"
title: Record what a sprint was estimated to cost against what it did, and estimate from that
type: feature
next: develop
status: ready
qa_level: verify
close_by: verify
size: m
created: 2026-09-09
source: user
parent: "0128"
blocked_by: []
relates: ["0041", "0026", "0130", "0133"]
expects:
  - skills/orchestrate/SKILL.md
  - tools/harvest-usage.sh
  - .claude/backlog/config.yml
  - MEASUREMENT.md
claimed_by:
claimed_at:
touches:
---

## Problem

**`0130` requires the proposal to carry an estimate in time, tokens and dollars, and two of those
three have a prior while the third has none.** `MEASUREMENT.md` gives per-session means — develop
$4.03 over ~39 turns, verify $3.63 over ~38, retro $2.51 over 23, queue $4.24 over 36 — and
`tools/harvest-usage.sh` recomputes them over any window. It emits **no elapsed wall-clock time**,
a gap `0041` records independently: *"neither 'time to complete a context window' nor 'total time
for the work session' is derivable from what the repo has."* So the first sprint's time estimate has
no basis at all.

**Nothing anywhere compares an estimate to an outcome.** Every figure in the repo is an actual. An
estimate that is never scored cannot improve, and the proposal `0130` introduces would stay a guess
indefinitely. Aaron, 2026-09-08: *"let's build in the ability to estimate and learn from past
estimations. That way, we can get this to be more accurate."*

**Two model assumptions are currently unvalidated and one of them can destroy work.**
`config.yml` models a gate as `base + per_extra_ticket × (n−1)`, derived from means measured on
**single-ticket sessions** and never checked against a large gate. On the thirteen-ticket gate
`--drive` proposed on 2026-09-09 it predicts a $54.41 develop cap. If the real curve is superlinear
the cap fires partway through — and a stage killed by `--max-budget-usd` is the worst outcome the
design has: a held claim, a dirty tree and possibly a taken lock, all of which the skill's own Step 7
says a human must clear. With `0128` declining a sprint budget, these caps are the only spend limit
left, which makes validating them load-bearing rather than tidy.

The second unvalidated assumption is `0132`'s: that batching verify saves session floors in
proportion to batch size.

## Functional requirements

- FR1 — Each sprint records its **estimate** — tickets, wall-clock, tokens, dollars — before the
  first dispatch, and its **actuals** for the same four at the end, in one durable record per sprint.
- FR2 — Wall-clock is derived from the run log's existing UTC timestamps, which already bracket every
  stage. No new instrumentation.
- FR3 — Token and dollar actuals are read from `tools/harvest-usage.sh` over the sprint's own
  session-id set, not a date window. A date window is not a pin on a live store — `MEASUREMENT.md`
  records the window that once selected 30 sessions now returning 42.
- FR4 — The next sprint's estimate is derived from the recorded history where one exists, and from
  `MEASUREMENT.md`'s priors where none does. A figure with no prior is **labelled as having none**
  rather than presented as derived.
- FR5 — The ledger records **findings parked per sprint**, and for each retro the count it consumed
  against the rows it produced. These are the numbers `0133`'s interim threshold and age limit are
  replaced from.
- FR6 — The ledger records the observed cost of a develop gate against `stage_budget_usd`'s linear
  prediction for that ticket count, so the model in `config.yml` is checkable rather than assumed.
- FR7 — The ledger records verify cost per ticket for batched and unbatched sessions, which is the
  measurement `0132`'s performance NFR commits to.
- FR8 — Every figure carries the source it was read from and the stamp it was true at, and both
  sides of any division carry one. A pinned numerator over a live denominator decays silently —
  the defect `MEASUREMENT.md` shipped and `0051` repaired.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Privacy & data | The ledger is committed to a public repo, so like `harvest-usage.sh` it holds only aggregate numbers, skill names and session-id prefixes — never message text, file contents or paths it was not given | `data-privacy-conventions.md` |
| Performance | The ledger is written from data the sprint already has — the run log and one scripted read — and adds no per-cycle supervisor turn | `observability-conventions.md` |
| Documentation | Where the estimate came from is recorded with it, so a later reader can tell a prior from a measurement | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given a completed sprint, when its record is read, then it holds an estimate and an
      actual for tickets, wall-clock, tokens and dollars. **Red if** any of the four is recorded as
      an actual only, which is what every existing figure in the repo is.
- [ ] AC2 — Given the very first sprint, when its proposal is produced, then the wall-clock figure is
      marked as having no prior. **Red if** it is printed like the dollar figure, which does have
      one — the two are indistinguishable to a reader otherwise.
- [ ] AC3 — Given two completed sprints, when the third is proposed, then its estimate is derived
      from the recorded actuals rather than from `MEASUREMENT.md`'s priors. **Red if** the ledger is
      written but never read, which is the failure that makes an estimate never improve.
- [ ] AC4 — Given a develop gate of more than one ticket, when the sprint ends, then the record holds
      the observed cost beside `stage_budget_usd`'s prediction for that count. **Red if** only the
      observed cost is recorded, which leaves the linear model unfalsifiable.
- [ ] AC5 — Given the ledger, when `grep` runs over it for a message-text sentinel planted in a
      fixture transcript, then nothing matches. **Red if** the ledger writes anything but aggregates
      — the same assertion `tests/measurement.test.sh` already makes for `harvest-usage.sh`.
- [ ] AC6 — Given any ratio in the ledger, when it is read, then its numerator and denominator each
      carry a source and a stamp. **Red if** either is bare — the shape that went stale in
      `MEASUREMENT.md` once already.

## QA plan

- **Why that level:** no runner applies; the artefact is a record file and a set of derivations, and
  every criterion is a `grep`, a schema check on the record, or a fixture run.
- **Specific checks:** two fixture sprint records for AC3; a fixture transcript carrying a sentinel
  string for AC5, mirroring `tests/measurement.test.sh`; `grep` assertions for AC2 and AC6.

## Out of scope

- Computing the cost figures themselves. `tools/harvest-usage.sh`, `tools/classify-turns.sh` and
  `tools/cost-by-category.sh` already do that, and `0041` owns reporting them for a session. This
  ticket stores the **estimate**, pairs it with the actual, and feeds the next estimate.
- The session review's content and placement — `0041`.
- Choosing `0133`'s final threshold. This supplies the data; the decision is made when there is some.

## Notes & decisions

- **2026-09-09 — deliberately not folded into `0041`.** `0041` reports what a session delivered and
  what it cost, all of it actuals. The learning loop — an estimate recorded before the work, scored
  against the outcome, feeding the next estimate — is a different artefact with a different
  lifetime, and folding it in would have made `0041` unclosable until the loop existed.
