---
id: "0187"
title: Decide whether a sprint dispatch pins a concrete model or records the one that answered
type: bug
next: develop
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

## Functional requirements

- **FR1** — Step 3 states the chosen rule and the failure it prevents, citing run-20260922T031109Z:
  the `opus` alias is resolved **once per run, at the Step 1 probe**, and every stage dispatch and
  every `--resume` of the run passes that **concrete model id**, never the alias.
- **FR2** — A run log carries enough to name each stage session's model after the fact, without
  re-reading transcripts by hand: `scope_confirmed` carries the run's resolved `model`, and every
  `dispatch` event carries the `model` it passed.
- **FR3** — The Step 1 probe dispatches on `--model opus` with a pre-assigned `--session-id`, and
  the resolved id is read from that probe's transcript (the `message.model` of its assistant turns),
  never from anything the probe prints. A probe whose transcript names no model, or more than one,
  stops the run before the first stage, as any other failed probe does.
- **FR4** — The resolved id lives in the run log only. No model id is written into `SKILL.md`,
  `config.yml` or any other committed file as the value to dispatch on; the alias stays the single
  statement of which model is current.
- **FR5** — The Opus floor is unchanged: the id is resolved from `opus`, so a run cannot pin a
  non-Opus model, and the existing "thinking work" reason stays in Step 3.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Measurement | A cost comparison across sessions can tell whether the sessions ran on one model | a run log of two dispatches, one per model, from which the guard cannot tell the models apart | `measurement-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given `skills/sprint/SKILL.md`, when Step 3 is read, then its dispatch block passes
  `--model "$RUN_MODEL"` (the resolved id), not `--model opus`, and the prose names
  run-20260922T031109Z and says the alias moved between dispatches of one run.
- [ ] AC2 — Given the `step-1-probe` block, when it is read, then it passes both `--model opus` and
  `--session-id`, and Step 1 says the resolved id is read from the probe's transcript, not its stdout.
- [ ] AC3 — Given Step 3's `--resume` instruction, when it is read, then it says the resume passes the
  run's resolved id, so a resumed leg cannot re-resolve the alias (the retro legs of
  run-20260922T031109Z ran 50 turns of `claude-opus-5-5` beside 29 of `claude-opus-5`).
- [ ] AC4 — Given Step 5, when it is read, then it says `scope_confirmed` carries `model` and every
  `dispatch` event carries `model`.
- [ ] AC5 — Given a fixture run log of two `dispatch` events, one per model, when the model-per-session
  read Step 5 names is run over it, then it prints two distinct models, one per session id; and given
  the same log with the `model` fields removed, then the guard reds rather than reporting one model.
- [ ] AC6 — Given the probe's resolution, when its transcript names no model or more than one, then
  Step 1 says the run stops before the first stage, as a failed probe does.
- [ ] AC7 — Given `skills/sprint/SKILL.md`, when it is grepped, then no dispatch or probe block
  carries a literal `claude-opus-` id: the pinned id comes from the run, never from the file.
- [ ] AC8 — Given the existing run-20260913T034946Z guard in `tests/sprint.test.sh`, when it runs,
  then it asserts the probe resolves `opus` and Step 3 still says stages are thinking work, instead
  of asserting `--model opus` on the dispatch block.

## QA plan

Unit, in `tests/sprint.test.sh`: AC1–AC4, AC6–AC8 as section greps and block reads against the
existing `dispatch_blocks` / `probe_blocks` helpers; AC5 executes the Step 5 read over a `mktemp`
fixture with ticket ids that cannot be mistaken for backlog rows, and mutates the fixture to confirm
the guard reds. Run `tests/item-ac-form.test.sh` and the whole suite before hand-off.

## Out of scope

- Pricing an unlisted model in the harvest: that is `0186`.
- Model tiering per stage: that is `0149`.

## Notes & decisions

- 2026-09-25 — filed by retro from the 2026-09-23 supervisor finding (run-20260922T031109Z tail).
- 2026-09-26 — **design, decided: resolve the alias once per run and pin the resolved id.** The
  Step 1 probe runs on `--model opus` with a pre-assigned session id; the supervisor reads the
  model from the probe's transcript, logs it in `scope_confirmed`, and passes that concrete id on
  every dispatch and every `--resume` of the run, logging it on each `dispatch` event. The id lives
  in the run log, which is per-run and uncommitted — so it is not a second copy of a moving fact:
  the alias remains the one statement of "current Opus", re-read at every run's start.
  - **Rejected: pin a concrete id in a committed file** (`SKILL.md` or `config.yml`). That is the
    second copy the question warned about. This plugin is installed on other machines, and a
    committed id goes stale silently on each one — a valid but superseded id runs the old model with
    no error, which is the drift this ticket exists to stop, relocated.
  - **Rejected: keep the alias and only record the model that answered.** Satisfies FR2 but lets a
    run mix models, as run-20260922T031109Z did (develop/verify `claude-opus-5`, queue sweep all
    42 turns `claude-opus-5-5`, retro legs 50 + 29 split). It makes a mixed run legible without
    making it comparable; the per-stage and per-gate figures inside one ledger row stay mixed.
  - **Trade-off accepted:** a run that starts just before an alias move runs its whole length on the
    older model. Across runs the model can still differ; the recorded id makes that visible rather
    than preventing it. And one extra read at Step 1. A retired id fails its dispatch loudly, which
    is the right failure.
  - **Facts re-verified 2026-09-26:** `claude --help` says `--model` takes an alias or a model's
    full name. A captured stage stdout (`runs/<run-id>.<session-id>.out`) is the bare structured
    outcome with no model field, so stdout cannot record it. A stage transcript does, per assistant
    turn: stage session `e38994b6` of run-20260925T203345Z read `claude-opus-5-5` on all 30 turns —
    the alias has moved from `claude-opus-5` since the 2026-09-23 measurement.
  - **Which `MEASUREMENT.md` comparisons stay valid:** all of them. The baseline-vs-isolated
    comparison and the cost model state `claude-opus-5` on both sides (*The cost model*, *What the two
    runs did not hold constant*), and the turn-category tables use the same 30 sessions; all predate
    the move first seen in run-20260922T031109Z. The 2026-09-22 slow-guard figure is test wall-clock,
    not model spend. **What does not stay comparable:** any figure spanning the move — `LEDGER.md`
    rows before this lands carry no model, so an estimate derived from pre- and post-move rows mixes
    models without saying so, and run-20260922T031109Z's own retro and queue sweep are not comparable
    with its gates.
  - **Validated against the ticket as filed:** FR1 and FR2 confirmed and sharpened (FR1 names the
    rule; FR2 names the fields). Added FR3 (resolution from the probe transcript, fail-closed),
    FR4 (no committed id) and FR5 (Opus floor unchanged). ACs authored: AC1–AC8. AC8 changes an
    existing guard (`--model opus` on the dispatch block becomes the probe's) rather than adding one.
