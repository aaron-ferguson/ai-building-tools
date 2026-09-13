---
id: "0152"
title: Price and cap a sprint's retro and queue tail
type: bug
next: develop
status: ready
qa_level: unit
close_by: verify
size: m
created: 2026-09-12
source: agent
parent:
blocked_by: []
relates: ["0135", "0133"]
expects:
  - tools/sprint-ledger.sh
  - tests/sprint-ledger.test.sh
  - .claude/backlog/config.yml
  - skills/sprint/SKILL.md
claimed_by:
claimed_at:
touches:
---

## Problem

**A tail-only sprint is priced at zero and cannot run without asking for caps.** On
`run-20260913T021045Z` (the `--drive` exit 5 case, the whole run being `retro` then `queue`),
`tools/sprint-ledger.sh estimate --tickets 0 --develop-gates 0 --verify-sessions 0` returned 0 tokens and
USD 0.00, labelled as derived from `MEASUREMENT.md`, whose per-session means put the tail near
USD 6.75. `config.yml` `stage_budget_usd` has no `queue` cap although Step 6 dispatches `queue` in every
tail, and Step 7 forbids the supervisor choosing one, so the run stopped to ask. The user set `queue`
12.72 (4.24 × 3) and raised `retro` from 3.75 to 11.25 because that buffer held 71 entries, about 9× the
threshold. A fixed cap fires mid-sweep on exactly the runs that most need the tail.

## Functional requirements

- FR1 — `estimate` accepts the tail stages as inputs and prices them from `MEASUREMENT.md`'s per-session means, never returning a derived-looking zero for a run that dispatches a stage.
- FR2 — `config.yml` `stage_budget_usd` carries a `queue` cap, derived the way the file's other caps are.
- FR3 — the `retro` and `queue` caps scale with the findings count relative to `findings_threshold`, by a rule written once in `config.yml`'s comment and read by the supervisor.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Observability | Every estimated figure names its source row, as the existing figures do. | A tail figure with no source clause. | `measurement-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given `estimate` with zero tickets and a tail, when it runs, then the USD figure is non-zero and cites its source. Red-making input: today's script with `--tickets 0 --develop-gates 0 --verify-sessions 0`.
- [ ] AC2 — Given `.claude/backlog/config.yml`, when the suite runs, then `stage_budget_usd` has a `queue` key. Red-making change: deleting it.
- [ ] AC3 — Given a findings count of 9× the threshold in a fixture, when the tail cap is computed, then it exceeds the base cap by the configured rule. Red-making change: returning the base cap.

## QA plan

- **Why that level:** `unit` — the estimator and cap rule are exercised in `tests/sprint-ledger.test.sh` over fixtures.
- **Specific checks:** `tests/sprint-ledger.test.sh`, `tests/sprint.test.sh`.

## Out of scope

- The schema defect (0151) and marker liveness (0153).

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

## Notes & decisions

- **Filed by a retro pass 2026-09-12 from FINDINGS.md.** Two buffer entries from the same run, one row because both are the tail's cost model. The caps the user chose on that run are recorded above and not written into `config.yml` by this pass — setting a cap is the user's call.
