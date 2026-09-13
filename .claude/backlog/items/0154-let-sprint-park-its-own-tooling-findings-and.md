---
id: "0154"
title: Let sprint park its own tooling findings, and propose the gate below a design row
type: feature
next: develop
status: ready
qa_level: unit
close_by: verify
size: m
created: 2026-09-12
source: agent
parent:
blocked_by: []
relates: ["0134"]
expects:
  - skills/sprint/SKILL.md
  - .claude/backlog/next
  - skills/queue/templates/next
  - tests/sprint.test.sh
  - tests/next.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

**What a sprint learns about its own tooling is lost when the supervising conversation ends.** Every
other stage parks what surprised it; `sprint` has no such step, and its sections on not writing the
backlog read as forbidding it, so four tooling defects found on `run-20260913T021045Z` reached only the
report until the user asked. Separately, `./next --drive --propose` describes nothing below an unheld
design row: the rank walk escalates on the design row before a gate is formed, so the confirmed scope
holds the next develop gate's ids only by way of `./next develop`'s lead row (develop 2026-09-12, 0134).

## Functional requirements

- FR1 — `sprint` parks findings under the backlog lock like any other writer, at the end of a run and whenever an escalation is about its own tooling rather than a stage's work, routed per `references/CONVENTIONS.md`.
- FR2 — the prohibitions in Steps 8 and 9 name findings parking as permitted, so the two cannot be read as contradicting.
- FR3 — `--propose` with an unheld design row in scope also prints the develop gate beneath it, in both copies of `next`.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Testing | FR3 is a case in `tests/next.test.sh` asserting the whole PROPOSE line by equality. | Containment assertion passing under over-batching. | `testing-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given `skills/sprint/SKILL.md`, when the suite runs, then a step instructs parking findings under the lock. Red-making change: today's skill.
- [ ] AC2 — Given a fixture with an unheld design row above a develop gate, when `./next --drive --propose` runs, then the output names the gate's ids. Red-making input: today's template.

## QA plan

- **Why that level:** `unit` — prose guard plus a fixture case in the existing suites.
- **Specific checks:** `tests/sprint.test.sh`, `tests/next.test.sh`, `tests/backlog-scripts-installed.test.sh`.

## Out of scope

- 0151, 0152, 0153.

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

## Notes & decisions

- **Filed by a retro pass 2026-09-12 from FINDINGS.md.** Two buffer entries about what a sprint run can see and keep.
