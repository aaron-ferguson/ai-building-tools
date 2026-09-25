---
id: "0187"
title: Decide whether a sprint dispatch pins a concrete model or records the one that answered
type: bug
next: design
status: ready
qa_level: unit
close_by: verify
size: s
created: 2026-09-25
source: retro
parent:
blocked_by: []
relates: ["0149", "0186"]
expects:
  - skills/sprint/SKILL.md
  - tests/sprint.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

**`skills/sprint/SKILL.md` Step 3 requires `--model opus` on every dispatch. That pins an alias, and
the alias resolved to two different models inside one sprint.**

Measured across run-20260922T031109Z's transcripts (parked 2026-09-23): the develop and verify gates
ran `claude-opus-5`; the retro's resumed legs ran 50 turns of `claude-opus-5-5` beside 29 of
`claude-opus-5`; the queue sweep ran `claude-opus-5-5` for all 42 turns. The alias is resolved
server-side and moved between two dispatches of one run. Every per-session cost comparison in
`MEASUREMENT.md` assumes it does not, and nothing in the run log records which model answered.

## Open design question

Given that `--model opus` can resolve differently between dispatches of one run, which does a
sprint dispatch do: **pin a concrete model id** (and then, where does that id live so it is not a
second copy of a moving fact), or **keep the alias and record the model that answered** in the run
log from the transcript? The answer must say which `MEASUREMENT.md` comparisons remain valid under
it.

## Functional requirements

- **FR1** — Step 3 states the chosen rule and the failure it prevents, citing this run.
- **FR2** — Whichever is chosen, a run log carries enough to name each stage session's model after
  the fact, without re-reading transcripts by hand.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Measurement | A cost comparison across sessions can tell whether the sessions ran on one model | a run log of two dispatches, one per model, from which the guard cannot tell the models apart | `measurement-conventions.md` |

## Acceptance criteria

To be written by design against the answer; FR1 and FR2 are the floor.

## QA plan

Unit, in `tests/sprint.test.sh`, against whatever the decision names.

## Out of scope

- Pricing an unlisted model in the harvest: that is `0186`.
- Model tiering per stage: that is `0149`.

## Notes & decisions

- 2026-09-25 — filed by retro from the 2026-09-23 supervisor finding (run-20260922T031109Z tail).
