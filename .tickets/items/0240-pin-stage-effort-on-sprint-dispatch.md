---
id: "0240"
title: Pin each stage's effort on its sprint dispatch and record it in the run log
type: chore
next: develop
status: ready
qa_level: unit
close_by: verify
size: m
created: 2026-11-26
source: user
parent: "0128"
blocked_by: []
relates: ["0149", "0192"]
expects:
  - tools/sprint-ledger.sh
  - tests/sprint-ledger.test.sh
  - skills/sprint/SKILL.md
  - skills/queue/templates/config.yml
  - .tickets/config.yml
  - CHANGELOG.md
ac_digest: AC1=a189a364 AC2=c596ad7d AC3=f32163d4 AC4=42c38151 AC5=e1970d71 AC6=15d3aab7 AC7=786e7dcb AC8=1cb16db0
claimed_by:
claimed_at:
touches:
---

## Problem

`/sprint` Step 3 pins every stage's **model** on the dispatch (`--model "$RUN_MODEL"`) and logs it on
every `dispatch` event, because an unpinned model once let a whole run drift to claude-sonnet-4-6
(run-20260913T034946Z). It pins no **effort**. The dispatch passes `--setting-sources user,project`,
so each stage inherits whatever `effortLevel` the dispatching host's settings hold — on the host
that recorded the current ledger, `~/.claude/settings.json` carries `"effortLevel": "medium"`
(read 2026-11-26). Step 3 says a stage's settings should be "a property of the dispatch and not of
whatever shell the supervisor happened to start in"; for effort they are a property of the shell.

Two consequences, both found during the 2026-11-26 model-tiering review (0149):

- **The same sprint costs differently on two hosts and nothing records why.** Effort controls
  thinking depth and token spend within a model; a host whose settings say `high` runs every stage
  above the ledger's priors, and the ledger, the run log and `harvest-usage.sh` carry no effort field
  to explain the gap.
- **No effort comparison is possible.** The cheapest quality-preserving lever ahead of any model
  change is the same model at a different effort (the claude-api skill's cost guidance: measure the
  strongest model at lower effort before building a multi-model cascade, and caches are per model).
  Nothing can be compared while effort is unpinned and unrecorded.

`claude --help` (2026-11-26): `--effort <level>  Effort level for the current session (low, medium,
high, xhigh, max)`.

## Functional requirements

- **FR1** — `config.yml` carries a `stage_effort:` block beside `stage_budget_usd:`, one key per
  stage (`develop`, `verify`, `queue`, `design`, `retro`), each a level the CLI accepts. Both the
  shipped template (`skills/queue/templates/config.yml`) and this repo's `.tickets/config.yml` carry
  it, every stage at `medium`, with a comment saying `medium` is the level the ledger's figures were
  recorded at and that pinning a model's default effort costs nothing in cache.
- **FR2** — `tools/sprint-ledger.sh effort --stage <stage> --config <config.yml>` prints the level
  `stage_effort:` names for that stage and exits 0. It is ledger-free, like `tail-cap`.
- **FR3** — Where `stage_effort:` is present, `effort` refuses — non-zero exit, nothing on stdout, a
  stderr line naming the stage and the accepted levels — when the stage has no key or its value is
  not one of `low`, `medium`, `high`, `xhigh`, `max`.
- **FR4** — Where `config.yml` has no `stage_effort:` block at all, `effort` prints `inherit`, exits
  0, and says on stderr which key would pin it. A project that has not adopted the block keeps
  today's behaviour rather than having every sprint refused.
- **FR5** — `skills/sprint/SKILL.md` Step 3's dispatch passes `--effort <level>` from FR2 and omits
  the flag on `inherit`; Step 7's `--resume` passes the same level the session was dispatched at;
  Step 5's `dispatch` event carries `effort` (the level, or `inherit`), as it already carries `model`.
- **FR6** — `tools/sprint-ledger.sh record`'s window table gains an `Effort` column read from each
  window's `dispatch` event, printing `unrecorded` for a window whose event carries no `effort`.
- **FR7** — `CHANGELOG.md` `## Unreleased` gains one entry naming the new `stage_effort:` key and that
  a project without it dispatches exactly as before.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Observability | Every dispatch's effort is on its run-log event and in the ledger's window table, so a cost difference between two sessions can be attributed to effort or ruled out | AC5: drop the column read and the `unrecorded` window shows the column missing | `observability-conventions.md` |
| Progressive delivery | A host or project whose `config.yml` lacks `stage_effort:` dispatches with no `--effort`, exactly as before; only a project that sets the block sees pinned effort | AC4: make `effort` refuse or print `medium` on a missing block | `progressive-delivery-conventions.md` |
| Documentation | The key's meaning and its default's provenance live in the `config.yml` comment beside it, and the CHANGELOG names the behaviour | AC6 reads both configs; AC8 is a reading of the entry | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given a fixture `config.yml` whose `stage_effort:` sets `develop: high`, when
  `sprint-ledger.sh effort --stage develop --config <it>` runs, then it prints exactly `high` and exits
  0. Red: make `effort` print a constant `medium`. (`tests/sprint-ledger.test.sh`)
- [ ] AC2 — Given a fixture whose `stage_effort:` sets `develop: extreme`, when `effort --stage develop`
  runs, then it exits non-zero, prints nothing on stdout, and its stderr names `develop` and all five
  accepted levels. Red: remove the value check. (`tests/sprint-ledger.test.sh`)
- [ ] AC3 — Given a fixture whose `stage_effort:` names `develop` but not `verify`, when `effort --stage
  verify` runs, then it exits non-zero naming `verify`. Red: default a missing stage to `medium`.
  (`tests/sprint-ledger.test.sh`)
- [ ] AC4 — Given a fixture `config.yml` with no `stage_effort:` block, when `effort --stage develop`
  runs, then stdout is exactly `inherit`, the exit is 0, and stderr names `stage_effort`. Red: refuse
  on the missing block, or print `medium`. (`tests/sprint-ledger.test.sh`)
- [ ] AC5 — Given a fixture run log with two `dispatch` events, one carrying `"effort":"high"` and one
  carrying no `effort`, when `record` writes its block, then the window table's `Effort` column reads
  `high` for the first window and `unrecorded` for the second. Red: read the column from a constant.
  (`tests/sprint-ledger.test.sh`)
- [ ] AC6 — Given the committed `skills/queue/templates/config.yml` and `.tickets/config.yml`, when
  `effort` runs for each of the five stages against each file, then every call prints `medium`. Red:
  delete one stage's line from either file. (`tests/sprint-ledger.test.sh`)
- [ ] AC7 — Given `skills/sprint/SKILL.md`, when Step 3's dispatch block, Step 7's resume and Step 5's
  `dispatch` event are read, then the dispatch takes `--effort` from `effort --stage`, omits it on
  `inherit`, the resume reuses the dispatched level, and the event names `effort`. A reading, not a
  grep (`CLAUDE.md`, *Tests*). Red: any of the three absent.
- [ ] AC8 — Given `CHANGELOG.md`, when `## Unreleased` is read, then one entry names `stage_effort:` and
  says a project without it dispatches as before. A reading. Red: entry absent.

## QA plan

- **Why that level:** the behaviour is a script's output over fixture configs and a fixture run log;
  `tests/sprint-ledger.test.sh` already builds both for `tail-cap` and `record`.
- **Specific checks:** `tests/sprint-ledger.test.sh` for AC1–AC6, each mutation named on its AC
  applied once; AC7 and AC8 read from the files.

## Out of scope

- Choosing any level other than `medium`. Which stage repays a higher or lower effort is a measured
  trial that needs this ticket and `0241` first (`0149`'s notes).
- Effort on the Step 1 probe, which returns a fixed object and resolves the run's model only.
- The supervisor's own effort: it is the person's session, not a dispatch.
- `harvest-usage.sh`, which reads transcripts and has no effort to read; the effort comes from the
  run log.

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

## Notes & decisions

- **2026-11-26 (queue) — captured on the user's request** during the 0149 model-tiering review, as a
  sibling of 0149 under 0128 rather than its child: a child would make 0149 a project and take its
  row, and two of its three questions are still open design work.
- **Routing: `develop`.** No surface and no open decision: the flag, its accepted values and the
  config shape are all read from the CLI and the existing `stage_budget_usd:` block.
- **Amend-first test applied:** no open ticket's outcome is "pin effort". 0149's is the decision this
  feeds; 0192's is pricing unpriced sessions. Minted.
- **One default chosen here, flagged as a guess for the user to overturn:** a missing block prints
  `inherit` rather than refusing (FR4). Refusing would stop every sprint in a project that has not
  re-scaffolded its `config.yml`, which `queue` Step 0 never overwrites; `inherit` keeps today's
  behaviour and still records the fact on the event.
