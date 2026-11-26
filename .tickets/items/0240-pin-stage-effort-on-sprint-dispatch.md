---
id: "0240"
title: Make a sprint's cost measured, estimated and tunable
type: chore
next: develop
status: blocked
qa_level: unit
close_by: verify
size: l
created: 2026-11-26
source: user
parent: "0128"
blocked_by: ["0192"]
relates: ["0149", "0192", "0241", "0135", "0152", "0162", "0164", "0160"]
expects:
  - tools/sprint-ledger.sh
  - tests/sprint-ledger.test.sh
  - skills/sprint/SKILL.md
  - skills/queue/templates/config.yml
  - .tickets/config.yml
  - CHANGELOG.md
  - tools/harvest-usage.sh
  - tests/sprint.test.sh
  - skills/develop/SKILL.md
  - skills/verify/SKILL.md
  - references/MEASUREMENT.md
ac_digest: AC1=a189a364 AC2=c596ad7d AC3=f32163d4 AC4=42c38151 AC5=e1970d71 AC6=15d3aab7 AC7=786e7dcb AC8=1cb16db0 AC9=117a7eee AC10=51817b22 AC11=7d84aa21 AC12=8be356b8 AC13=15aee5b2 AC14=abdbd457 AC15=b92b78a5 AC16=a961f540 AC17=a5943396 AC18=b7aded44 AC19=f54d39aa AC20=29d9e309 AC21=3783a942
claimed_by:
claimed_at:
touches:
---

## Problem

**Outcome (merged 2026-11-26, at the user's direction):** every sprint's cost is priced for every model it ran on, attributed to effort and to real working time, and estimated from that record, and its avoidable per-session overhead is decided. A cheaper configuration can then be tried and scored instead of guessed.

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

### Absorbed 2026-11-26: 0241 — Price Sonnet 5.5 and Haiku 5.5 turns in the harvest, Haiku at its long-prompt rate above 100K

`RATES` in `tools/harvest-usage.sh` (as at `4cff5b5`) lists `claude-opus-5-5`, `claude-opus-5`, three
Opus 4.x, `claude-sonnet-5`, `claude-sonnet-4-6` and `claude-haiku-4-5`. It has no `claude-sonnet-5-5`
and no `claude-haiku-5-5`, so every turn on either is an **unpriced** turn. That is the failure the
comment above `RATES` already cites: run-20260913T034946Z recorded USD 0.00 for two real sessions on
an unlisted model.

The 2026-11-26 model-tiering review (0149) needs those two models priced before any trial of them can
be scored. Any trial run today reads as unpriced in the harvest and the ledger.

Haiku 5.5 cannot be one `RATES` row as it stands. The claude-api skill's model table (cached
2026-11-03) and `shared/models.md` price it at **USD 0.10 / 0.50 per MTok when the prompt is 100K
tokens or fewer and 0.50 / 2.50 above that**. A stage session's context averages above 100K
(`MEASUREMENT.md`, 106,139 per turn), so pricing every turn at the short rate would understate it by
about 5x on exactly the sessions a trial would run. The same sources give Sonnet 5.5 as USD 2.00 /
10.00 with cache reads at 0.10. Neither source states Haiku 5.5's cache-read or cache-write rate.

### Absorbed 2026-11-26: 0164 — Record active and elapsed time and interruptions in the sprint ledger, and estimate them

**The ledger counts a session-limit wait as work, and neither the estimate nor the ledger knows that
interruptions happen.** On this repo they are routine, because tokens run out mid-session on local
unpushed work.

Parked from run-20260913T034946Z, verbatim:

> Ledger wall-clock is first-to-last run-log event, so a session-limit wait counts as work: 646 min
> recorded. The run log needs limit-hit and resumed events, and the ledger needs active and elapsed
> time as separate figures.

> The sprint estimate has no term for a mid-session stop, which re-pays a session's context on
> resume. Stops will be routine here, so the estimate should price expected interruptions and the
> ledger should record how many occurred.

The run-log half is done: `a666012` gave sprint Step 7 `limit_hit` and `resumed` events. The ledger
half is not:

- `wall_clock_minutes()` in `tools/sprint-ledger.sh` still returns the last event minus the first.
- `FIGURES` has no interruption count.
- `estimate()` emits one `wall_clock_min` line.

### Absorbed 2026-11-26: 0149 — Audit sprint efficiency — suite-check dedup, per-agent overhead, and model tiering

A sprint dispatches develop and verify as sequential sessions, each paying the full per-session
startup cost before doing any work. Three categories of redundancy are worth examining before
the sprint skill is considered finished:

**Suite-check redundancy.** `develop` Step 5 runs the project's whole test suite to leave the tree
green before handing off to verify. In a sprint, verify guarantees the tree is green when it
closes a ticket, so the *next* develop session's pre-handoff suite run is checking a tree whose
greenness is already guaranteed by the previous cycle. A sprint could run the suite once before
dispatching the first develop session and rely on the dev/verify invariant for every subsequent
one — but the mechanism for signalling develop to skip that check (and the risk if the invariant
does not hold) is an open design question.

**Per-agent overhead.** Each develop and verify session independently performs steps that are
either shared-cost across a gate (conventions loading, git fetch, staleness greps) or are
pre-conditions that a sprint could establish once. No catalogue of these steps against sprint's
dispatch model exists, so it is unknown how many are actually skippable without changing the
independence property the two-stage model relies on.

**Model tiering.** The sprint supervisor's own work is routing: read an outcome, call `./next
--drive`, log an event, dispatch the next session. That is qualitatively different from the
thoughtful implementation work develop does. If the supervisor's sessions could run on a cheaper
model (haiku), and if any stage is mechanical enough that haiku handles it without quality loss,
the per-sprint token cost could fall without changing what the run produces. The mechanism
(a `--model` flag on the dispatch) and the cost differential are uncharacterised.

The user asked for this research before work on 0132–0135 finishes, so the findings can
inform whether any of those tickets need adjustment.


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
- **FR8** *(was 0241 FR1)* — `RATES` gains `claude-sonnet-5-5` at input 2.00, output 10.00, cache read 0.10, with
  the source and the date it was read cited in the comment above `RATES`.
- **FR9** *(was 0241 FR2)* — A `claude-haiku-5-5` turn is priced by its **prompt size**, meaning input + cache read +
  cache creation tokens. A prompt of 100,000 tokens or fewer is priced at 0.10 / 0.50; above that,
  0.50 / 2.50.
- **FR10** *(was 0241 FR3)* — Haiku 5.5's cache-read rate for each tier comes from Anthropic's published pricing page,
  the Pricing row of the claude-api skill's `shared/live-sources.md`, cited in the comment with the
  date it was read. **A figure the page does not publish is not invented.** If the tier boundary or a
  cache rate cannot be read, `develop` hands the ticket off as `waiting`, saying which figure is
  missing.
- **FR11** *(was 0241 FR4)* — The harvest's `RATES per million:` header, derived from `RATES` since 0192 FR7, names
  `claude-sonnet-5-5` and both Haiku 5.5 tiers.
- **FR12** *(was 0241 FR5)* — `CHANGELOG.md` `## Unreleased` gains one entry naming the two newly priced models.
- FR13 *(was 0164 FR1)* — `record` computes three figures:
  - `elapsed_min`: last event − first event.
  - `active_min`: elapsed, minus every interval from a `limit_hit` event to the next `resumed`
    event. An unmatched `limit_hit` runs to the last event.
  - `interruptions`: the count of `limit_hit` events.
- FR14 *(was 0164 FR2)* — A recorded block's figures are `tickets`, `active_min`, `elapsed_min`, `interruptions`,
  `tokens`, `usd`, replacing `wall_clock_min`.
- FR15 *(was 0164 FR3)* — `read_ledger` reads a legacy block's `wall_clock_min` as `elapsed_min` and never as
  `active_min`.
- FR16 *(was 0164 FR4)* — `estimate` emits `active_min`, `elapsed_min` and `interruptions`, each as per-ticket history
  mean × tickets, or `no-prior` where no recorded block holds that figure.
- FR17 *(was 0164 FR5)* — The cost of a resume's context re-pay reaches the estimate through history: `tokens`/`usd`
  history is harvested by session id, covering both legs of a resumed session. On the priors path
  (no history), the `usd` source line says it excludes resume re-pay.
- FR18 *(was 0164 FR6)* — `record`'s `--estimate-wall` flag becomes `--estimate-active` and `--estimate-elapsed`, plus
  `--estimate-interruptions`, each accepting `no-prior`. `skills/sprint/SKILL.md`'s `record` and
  `estimate` invocations, and its Step 5 description of the ledger's actuals, match.
- FR19 *(was 0149 FR1)* — The design session must produce a documented decision on suite-check dedup: whether a
  sprint can run the suite once before the first dispatch and signal develop sessions to skip the
  baseline check within a sprint, including the mechanism for that signal and any conditions under
  which the guarantee would not hold.
- FR20 *(was 0149 FR2)* — The design session must produce a ranked list of per-agent overhead steps from develop
  and verify that a sprint could absorb or skip, with a token-cost estimate (or qualitative bound)
  for each candidate and a note on whether absorbing it would weaken the two-stage independence
  property.
- FR21 *(was 0149 FR3)* — The design session must produce a recommendation on model tiering: which tasks in the
  sprint supervisor and/or which full stage sessions (develop or verify) are candidates for haiku,
  the dispatch mechanism (`--model` in the `claude -p` call), and an estimated USD saving per
  sprint compared to all-opus, derived from `references/MEASUREMENT.md`'s per-session figures
  rather than invented.


## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Observability | Every dispatch's effort is on its run-log event and in the ledger's window table, so a cost difference between two sessions can be attributed to effort or ruled out | AC5: drop the column read and the `unrecorded` window shows the column missing | `observability-conventions.md` |
| Progressive delivery | A host or project whose `config.yml` lacks `stage_effort:` dispatches with no `--effort`, exactly as before; only a project that sets the block sees pinned effort | AC4: make `effort` refuse or print `medium` on a missing block | `progressive-delivery-conventions.md` |
| Documentation | The key's meaning and its default's provenance live in the `config.yml` comment beside it, and the CHANGELOG names the behaviour | AC6 reads both configs; AC8 is a reading of the entry | `documentation-conventions.md` |
| Observability | (0241) A Sonnet 5.5 or Haiku 5.5 session is priced in the harvest and the ledger, not reported as unpriced or USD 0.00 | AC9–AC11: delete the entry and each fixture prints `UNPRICED` | `observability-conventions.md` |
| Documentation | (0241) Every new figure's source and read date sit in the comment above `RATES`; the CHANGELOG names the models | AC15 and AC16 are readings | `documentation-conventions.md` |
| Observability | (0164) Waiting time is never reported as active time | AC17 | `measurement-conventions.md` |
| Migration / schema | (0164) Existing `LEDGER.md` blocks stay readable without rewriting them | AC19 | `migration-conventions.md` |
| Documentation | (0149) Decisions and recommendations land in *Notes & decisions* before the handoff, in a form a cold session can act on without re-deriving the research | `documentation-conventions.md` |

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
- [ ] AC9 *(was 0241 AC1)* — Given a fixture session of one `claude-sonnet-5-5` turn with 1,000,000 each of input,
  output and cache-read tokens and no cache writes, when the harvest prices it, then its total is USD
  12.10. Red: remove the `RATES` entry, or set cache read to 0.20. (`tests/sprint-ledger.test.sh`)
- [ ] AC10 *(was 0241 AC2)* — Given a `claude-haiku-5-5` turn of 50,000 input and 10,000 output tokens with no cache, when
  it is priced, then the total is USD 0.0100. Red: price every Haiku 5.5 turn at the long rate.
  (`tests/sprint-ledger.test.sh`)
- [ ] AC11 *(was 0241 AC3)* — Given a `claude-haiku-5-5` turn of 150,000 input and 10,000 output tokens with no cache, when
  it is priced, then the total is USD 0.1000. Red: price every Haiku 5.5 turn at the short rate.
  (`tests/sprint-ledger.test.sh`)
- [ ] AC12 *(was 0241 AC4)* — Given two `claude-haiku-5-5` turns with no cache and 0 output, one with a prompt of exactly
  100,000 input tokens and one with 100,001, when each is priced, then the first is USD 0.0100 and the
  second is USD 0.0500005. Red: change the boundary comparison from "or fewer" to "fewer".
  (`tests/sprint-ledger.test.sh`)
- [ ] AC13 *(was 0241 AC5)* — Given a `claude-haiku-5-5` turn of 1,000 input tokens and 120,000 cache-read tokens, when it
  is priced, then it is priced at the long tier. Red: compute the tier from `input_tokens` alone.
  (`tests/sprint-ledger.test.sh`)
- [ ] AC14 *(was 0241 AC6)* — Given AC10's fixture under the id `claude-haiku-5-5-20261001`, when it is priced, then the
  total equals AC10's. Red: look the tiered model up by its exact id only.
  (`tests/sprint-ledger.test.sh`)
- [ ] AC15 *(was 0241 AC7)* — Given an all-priced fixture store, when the harvest prints its `RATES per million:` line,
  then the line names `claude-sonnet-5-5` and both `claude-haiku-5-5` tiers. Red: drop the tier from
  the header derivation. (`tests/sprint-ledger.test.sh`)
- [ ] AC16 *(was 0241 AC8)* — Given `tools/harvest-usage.sh` and `CHANGELOG.md`, when the comment above `RATES` and
  `## Unreleased` are read, then every new figure has a source and a read date, and one entry names
  both models. A reading. Red: any figure without a source.
- [ ] AC17 *(was 0164 AC1)* — Given a fixture run log with a first event at 00:00, `limit_hit` at 00:30, `resumed` at
  01:30 and a last event at 01:40, when `record` runs, then the block reads `active_min` 40,
  `elapsed_min` 100, `interruptions` 1. Red: today's single `wall_clock_min` 100.
- [ ] AC18 *(was 0164 AC2)* — Given a run log with events at 00:00 and 00:20 and a last event that is a `limit_hit` at
  00:30, when `record` runs, then `active_min` is 20 and `interruptions` is 1. Red: an unmatched
  `limit_hit` ignored.
- [ ] AC19 *(was 0164 AC3)* — Given a `LEDGER.md` with one legacy block (`wall_clock_min` 60 over 2 tickets) and one new
  block (`active_min` 20, `elapsed_min` 50 over 1 ticket), when `estimate --tickets 2` runs, then
  `elapsed_min` is 73 ((60 + 50) / 3 × 2) and `active_min` is 40 (20 / 1 × 2). Red: the legacy block
  ignored prints `elapsed_min` 100; the legacy figure read as active prints `active_min` 53.
- [ ] AC20 *(was 0164 AC4)* — Given a ledger holding no `interruptions` figure, when `estimate` runs, then its
  `interruptions` line reads `no-prior`. Red: an invented default.
- [ ] AC21 *(was 0164 AC5)* — Given `skills/sprint/SKILL.md`, when `tests/sprint.test.sh` runs, then it contains
  `--estimate-active` and no `--estimate-wall`. Red: the old invocation left in place.


## Progress

**One outcome is one ticket, even across many sessions**; its slices are worked in order, each about
one develop session's work (`product-definition-conventions.md` → "Slice Vertically and Thinly").

- [ ] S1 — pin and log each stage's effort on its dispatch — discharges AC1, AC2, AC3, AC4, AC5, AC6, AC7, AC8
- [ ] S2 — price Sonnet 5.5 and Haiku 5.5 turns, Haiku at its long-prompt rate above 100K (0241) — discharges AC9, AC10, AC11, AC12, AC13, AC14, AC15, AC16
- [ ] S3 — record active and elapsed time and interruptions in the ledger, and estimate them (0164) — discharges AC17, AC18, AC19, AC20, AC21
- [ ] S4 — decide suite-check dedup and which per-agent overhead a sprint may absorb (0149; its model-tiering question is answered in its notes) — unspecified


## QA plan

- **Why that level:** the behaviour is a script's output over fixture configs and a fixture run log;
  `tests/sprint-ledger.test.sh` already builds both for `tail-cap` and `record`.
- **Specific checks:** `tests/sprint-ledger.test.sh` for AC1–AC6, each mutation named on its AC
  applied once; AC7 and AC8 read from the files.

### From 0241

- **Why that level:** pricing is a pure function over fixture transcripts; 0192's AC6–AC17 already
  build such fixtures in `tests/sprint-ledger.test.sh`.
- **Specific checks:** AC9–AC15 there, applying each AC's named mutation once. AC16 is read from the files.

### From 0164

- **Why that level:** `tools/sprint-ledger.sh` is fixture-tested; the skill invocation is a prose
  guard.
- **Specific checks:** AC17–AC20 in `tests/sprint-ledger.test.sh`; AC21 in `tests/sprint.test.sh`.

### From 0149

- **Why review:** the output is documented decisions and recommendations; no runner can check
  whether a recommendation is complete, specific, and derived from current measurement data —
  that is a reading.
- **Specific checks:** per the `review: checklist:` in `config.yml`, applied to the *Notes &
  decisions* section against each AC above.


## Out of scope

- Choosing any level other than `medium`. Which stage repays a higher or lower effort is a measured
  trial that needs this ticket and `0241` first (`0149`'s notes).
- Effort on the Step 1 probe, which returns a fixed object and resolves the run's model only.
- The supervisor's own effort: it is the person's session, not a dispatch.
- `harvest-usage.sh`, which reads transcripts and has no effort to read; the effort comes from the
  run log.

### From 0241

- Running any model trial. That is 0149's follow-on, gated on this ticket and on 0240.
- Re-pricing models already in `RATES`, or `tools/cost-by-category.sh`, beyond whatever it inherits
  from `RATES`. `develop` confirms on claim which of the two it is.
- Tiered pricing for any other model. None of the others publishes a tier.

### From 0164

- An unpriced harvest — 0162.
- Pricing a resume from `MEASUREMENT.md` priors. No prior records the resume re-pay, so the estimate
  labels the omission (FR17) rather than inventing a figure.
- Rewriting committed `LEDGER.md` blocks.

### From 0149

- Implementing any of the identified changes (those go in follow-on develop tickets spawned by
  the design session).
- Changing `skills/sprint/SKILL.md`, `skills/develop/SKILL.md`, or `skills/verify/SKILL.md`
  — this ticket only produces decisions.
- Evaluating models other than haiku and opus (the two the user named).


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
- **2026-11-26 (queue): merged by outcome, at the user's direction.** The 2026-11-26 consolidation grouped the backlog by outcome so a whole outcome is worked in one ticket and its context is paid for once. Absorbed and withdrawn, each id burned and each item file kept as the record:
  - `0241` (Price Sonnet 5.5 and Haiku 5.5 turns in the harvest, Haiku at its long-prompt rate above 100K): FR8–FR12, AC9–AC16
  - `0164` (Record active and elapsed time and interruptions in the sprint ledger, and estimate them): FR13–FR18, AC17–AC21
  - `0149` (Audit sprint efficiency — suite-check dedup, per-agent overhead, and model tiering): FR19–FR21, no ACs (an unspecified slice)
  Each absorbed ticket's Problem is quoted verbatim above, and its FRs, ACs, NFR rows, QA plan, Out of scope and Notes are carried below with `*(was NNNN FRn)*` tags. **Bare FR and AC numbers inside the carried text were renumbered to this ticket's.** A reference to another ticket's criterion not written as `NNNN ACn` may have been renumbered too, and the withdrawn file holds the original. An unspecified slice sends this ticket to `design` when it is next; its open question is below.

### Open questions for the unspecified slices

**Criteria 0149 proposed, for design to adopt or replace when it specifies this slice:**

- AC22 — Given the design session completed, when `items/0149-*.md` *Notes & decisions* is
  read, then it contains a go/no-go on suite-check dedup with: the mechanism (if go), the
  conditions under which the invariant fails (if any), and the estimated suite-run saving per
  sprint; red = any of those three fields absent, or no explicit go/no-go.
- AC23 — Given the design session completed, when *Notes & decisions* is read, then it contains
  a ranked list of ≥ 3 per-agent overhead candidates, each with a token-cost estimate or explicit
  "not measurable from current data" and a verdict on whether absorbing it weakens stage
  independence; red = fewer than 3 candidates, or any candidate missing both a cost note and an
  independence verdict.
- AC24 — Given the design session completed, when *Notes & decisions* is read, then it contains
  a haiku recommendation naming: (a) which tasks or stages are candidates, (b) the `--model` flag
  form needed in the `claude -p` dispatch, and (c) an estimated USD saving per sprint derived from
  `MEASUREMENT.md`; red = recommendation absent, or any of (a), (b), (c) missing, or the saving
  figure is not traceable to `MEASUREMENT.md`.

**Open design question, from 0149 — Audit sprint efficiency — suite-check dedup, per-agent overhead, and model tiering:**

Three questions, any of which could produce a follow-on develop ticket:

- **Question 1 (suite-check):** Can sprint guarantee the tree is green between cycles well enough
  that develop sessions may skip the baseline suite run — and if so, what is the mechanism and
  what are the conditions that would make that guarantee fail?
- **Question 2 (per-agent overhead):** Which steps in develop and verify are genuine per-session
  requirements vs. shared pre-conditions a sprint could establish once, and how much token cost
  does each represent?
- **Question 3 (model tiering):** Which tasks in sprint or its dispatched sessions are suitable
  for haiku without quality loss, and what is the estimated cost saving?
- **Why they block specification:** the answers determine which implement tickets to write and
  what their FRs should say; writing implement tickets now would be building to guesses.
- **Settle it with:** `/design` — read the sprint, develop, and verify skills, check
  `references/MEASUREMENT.md` for per-session figures, and write the answers into *Notes &
  decisions*. Then set `next: develop` and add any unblocked FRs and ACs for the implement
  work, or spawn child tickets if the scope warrants it.

### Carried notes of the absorbed tickets

### From 0241 — Price Sonnet 5.5 and Haiku 5.5 turns in the harvest, Haiku at its long-prompt rate above 100K

- **2026-11-26 (queue): captured at the user's request** during the 0149 model-tiering review. It is
  a sibling of 0149 under 0128 for the same reason 0240 is.
- **`blocked_by: 0192`.** 0192 is at `next: verify` and its evidence rests on this same file's
  `RATES` and `cost_of`. Building here first would change the code under a verdict that hasn't been
  given yet (`CONCURRENCY.md`, *The working tree is shared too*, the stricter rule for a row held at
  verify).
- **Routed to `develop`.** No decision is open. The rates are published figures, and FR10 names the
  one gap and what to do if it stays a gap.
- **Amend-first test.** 0192's outcome was pricing what was unpriced as at 2026-10-08, and it is
  built and awaiting verify. Amending a ticket at verify would invalidate its evidence, so this is a
  new ticket.
- **For whoever runs the trial:** Haiku 5.5's tokenizer counts the same text as about 30% more tokens
  (claude-api `shared/models.md`). Compare sessions in dollars, not tokens.

### From 0164 — Record active and elapsed time and interruptions in the sprint ledger, and estimate them

- **2026-09-13 — filed by a `queue` sweep of FINDINGS.md** (run-20260913T034946Z). Two entries became
  one ticket: both read the same `limit_hit`/`resumed` events and change the same `FIGURES` list.
  Routed to `develop`.
- **AC19's figures were chosen so the rules disagree.** Each wrong reading gives a different number
  from the right one on the figure it corrupts: 100 against 73 for elapsed, 53 against 40 for
  active.
- 2026-10-10 — Absorbed by retro (tail of quantum-catan run-20261010T212209Z): a second instance: quantum-catan run-20261010T011031Z logged `limit_hit` then `resumed` around queue session 1419ed92 and the ledger reported wall_clock 311 min (estimate 178) and that window's elapsed as 283.4 min, nearly all of it the reset wait. Print the subtracted minutes when this lands.

- 2026-10-24 — Absorbed by retro (second leg of AetherWorks run-20261024T195310Z's tail): parked again from AetherWorks run-20261018T011502Z: a verify stopped on the session limit, `limit_hit` 02:09Z, `resumed` ~12h later, and `record` logged `wall_clock_min` 901 against an estimate of 147 with ~170 min of work. That actual becomes the next estimate's prior, inflated ~5x — the cost of leaving FR-ledger half unbuilt. `stage_killed`→`resumed` windows are the same shape and should be subtracted too.

### From 0149 — Audit sprint efficiency — suite-check dedup, per-agent overhead, and model tiering

- **2026-09-13 — model tiering, from the run-20260913T034946Z sweep.** FR21's dispatch mechanism now exists: sprint Step 3 passes `--model opus` (commit `a666012`), after every stage of that run silently ran on claude-sonnet-4-6. The same run is the one recorded instance of a cheaper model degrading a stage: its verify session returned `conventions_resolved: null` and a placeholder `session_id` and still closed four tickets (0160). A haiku or sonnet recommendation for any stage should weigh that, not only the price differential.
- **2026-11-26 — model-tiering decision, from the user-requested toolkit efficiency review (queue).** Recorded here so FR21 is not re-derived; `design` still owns the ticket and its two other questions. **No stage moves off Opus**: develop, verify, queue, design and retro stay on the run's resolved Opus id. Sonnet 5.5 would at most halve a stage's spend (USD 2.00/10.00 against 4.00/20.00, claude-api skill table cached 2026-11-03): about USD 14 of run-20261118T074205Z's USD 28.04 develop+verify, if turn counts held. The one recorded downgrade (this file's 2026-09-13 note, 0160) closed four tickets on an untrusted pass, and four reopens plus re-verifies cost about that saving before the person's time. **The supervisor may run on Sonnet, but there is no reason to change it**: about USD 1 a sprint on Opus 5.5 at 3 turns per cycle (an estimate from sprint's cost model, not measured). Haiku is not a fit, because the proposal, briefs and recovery are judgement. **First levers, filed as 0240 (pin and log effort per dispatch; stages inherit `effortLevel` from the host's settings today) and 0241 (price Sonnet 5.5 and Haiku 5.5, which `RATES` lacks).** Then, gated on both: an effort trial (develop/verify at `high` against `medium`, scored on cost per closed ticket including bounces), and one Haiku subagent trial on bulky reading inside a stage, with queue's duplicate search the first candidate. Verify's evidence reading is never delegated.
