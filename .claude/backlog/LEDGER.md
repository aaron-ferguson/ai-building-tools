# Sprint ledger — what each sprint was estimated to cost, against what it did

Every other cost figure in this repo is an **actual**. An estimate that is never scored against an
outcome cannot improve, so this file holds the other half: the estimate recorded **before** the
first dispatch, paired with the actual recorded at the end of the run, and read back to derive the
next sprint's estimate.

`tools/sprint-ledger.sh` writes and reads it. `skills/sprint/SKILL.md` is what calls it — at the
proposal, and again before the run ends.

**This is not the run log.** `.claude/backlog/runs/<run-id>.jsonl` is provenance and is deletable:
delete it and the next action does not change. Delete this file and every estimate goes back to
being a guess, permanently. That is the difference, and it is why one is committed and the other is
not.

## How to read a block

Each `## sprint` block carries one table and a few derived lines.

| Figure | What it is |
|---|---|
| `tickets` | how many tickets the sprint expected to work, against how many it actually touched |
| `wall_clock_min` | elapsed minutes, bracketed by the run log's own first and last UTC timestamps |
| `tokens` | context tokens over the run's own session ids — **summed per turn**, so cached context is counted once for every turn it survives. A sprint in the tens of millions is ordinary and is not a count of fresh input; `MEASUREMENT.md` prices it at USD 0.50 per million per turn survived |
| `usd` | spend over the same session ids |

- `GATE develop <n> ticket(s) …` pairs `config.yml`'s linear prediction — `base + per_extra × (n−1)`
  — with what the gate observably cost. The model was derived from means measured on
  **single-ticket** sessions and has never been checked against a large gate; a cap that fires
  partway through a stage leaves a held claim, a dirty tree and possibly a taken lock, so this line
  is load-bearing rather than tidy.
- `RATIO …` is written as **three** lines — the ratio, then a stamped numerator, then a stamped
  denominator.
- `DESIGN <id> session <prefix> <concurrency>: predicted … observed …` is one line per `design`
  session the sprint dispatched (`0134`), `MEASUREMENT.md`'s design mean beside what that one
  session cost. `concurrent` means its dispatch-to-outcome window overlapped a `develop` window,
  `sequential` that it did not; both are read from the run log, never from the supervisor.
  `concurrency not measured` is a session with no outcome, or one beside an unanswered develop
  window, and it belongs to neither population. The claim these lines check is that `concurrent`
  costs no more than `sequential`; read it as *consistent with* until at least 5 are `concurrent`.
- An observed figure on a `GATE`, `RATIO` or `DESIGN` line whose session ran turns on a model with
  no published rate reads `unpriced` when nothing was priced, or keeps its figure followed by
  `partial: <n> unpriced turn(s)`. It never reads `USD 0.00`, which is a measured zero (`0192`).
- `FINDINGS parked` and `RETRO consumed … produced …` are the yield figures that replace `0133`'s
  interim threshold and age limit once there is enough of them.

## Every figure carries a source and a stamp, and both sides of every ratio carry one

A pinned numerator over a live denominator decays **silently**: the arithmetic on the page stays
self-consistent and every citation still resolves. That is the defect `MEASUREMENT.md` shipped and
`0051` repaired, and it is why a ratio here is never one line.

**A figure with no prior is labelled `no prior`, never presented as derived.** As at 2026-09-10
wall-clock is exactly that figure — `MEASUREMENT.md` records no elapsed time at all — so the first
sprint's time estimate is an admission rather than a number, and it stays one until this file has a
recorded actual to derive from.

## Privacy

This file is committed to a **public** repo, and `tools/sprint-ledger.sh` reads full conversation
transcripts to produce it. Like `tools/harvest-usage.sh`, it emits only aggregate numbers, stage
names, session-id prefixes and paths it was given — never message text, file contents, or any path
it was not handed. `tests/sprint-ledger.test.sh` asserts that against a fixture transcript carrying
a sentinel string.

---

*No sprint has been recorded yet. The first `## sprint` block is appended by
`tools/sprint-ledger.sh record`.*

## sprint run-20260913T034946Z -- ended 2026-09-13T14:37:59Z

| Figure | Estimate | Actual | Estimate source |
|---|---|---|---|
| tickets | 4 | 4 | confirmed scope @ 2026-09-13T15:10:05Z |
| wall_clock_min | no prior | unmeasured: 646 elapsed, mostly an account session-limit wait | MEASUREMENT.md per-skill table, recorded 2026-08-24; wall-clock: none -- MEASUREMENT.md records no elapsed time and LEDGER.md holds no recorded actual |
| tokens | 31985507 | 19112608 | MEASUREMENT.md per-skill table, recorded 2026-08-24; wall-clock: none -- MEASUREMENT.md records no elapsed time and LEDGER.md holds no recorded actual |
| usd | 30.63 | not an Opus prior: 9.80 at claude-sonnet-4-6 rates | MEASUREMENT.md per-skill table, recorded 2026-08-24; wall-clock: none -- MEASUREMENT.md records no elapsed time and LEDGER.md holds no recorded actual |

GATE develop 4 ticket(s) session 64921e84: predicted USD 18.14 (config.yml stage_budget_usd, as at 2026-08-30 @ 2026-09-13T15:10:05Z) observed USD 8.18 (harvest-usage.sh over 1 session id(s) @ 2026-09-13T15:10:05Z)
RATIO verify_usd_per_ticket batched session 433a37e3 = 0.41
  numerator USD 1.62 (harvest-usage.sh over 1 session id(s) @ 2026-09-13T15:10:05Z)
  denominator 4 ticket(s) (run-20260913T034946Z.jsonl outcome events @ 2026-09-13T15:10:05Z)
RATIO verify_usd_per_ticket batched session 00000000 = 0.00
  numerator USD 0.00 (harvest-usage.sh over 1 session id(s) @ 2026-09-13T15:10:05Z)
  denominator 4 ticket(s) (run-20260913T034946Z.jsonl outcome events @ 2026-09-13T15:10:05Z)
FINDINGS parked 0 (run-20260913T034946Z.jsonl outcome events @ 2026-09-13T15:10:05Z)
NOTE Re-recorded after 75bec41 priced sonnet-4-6; the first record read USD 0.00. Two actuals are
  written as text so read_ledger skips them rather than averaging them into a prior: wall-clock
  includes a ~10h session-limit wait (active time is not yet separable), and every stage ran on
  claude-sonnet-4-6, so its dollars understate an Opus run. Tokens stay a number. USD covers stage
  sessions only; the supervisor's own spend is not in it. The 00000000 session is the placeholder
  id verify returned in place of 433a37e3, not a real session. Develop's 8.18 spans both legs of
  session 64921e84, stopped by a session limit and resumed.

## sprint run-20260913T151122Z -- ended 2026-09-13T21:06:16Z

| Figure | Estimate | Actual | Estimate source |
|---|---|---|---|
| tickets | 4 | not a per-ticket prior: 11 touched, 4 re-verified and 7 filed by queue | confirmed scope @ 2026-09-13T21:06:16Z |
| wall_clock_min | no prior | unmeasured: 354 elapsed, includes a session-limit wait | tokens: LEDGER.md 1 recorded sprint(s) over 4 ticket(s); usd: MEASUREMENT.md per-skill table, recorded 2026-08-24; wall-clock: none |
| tokens | 19112608 | 3226414 | tokens: LEDGER.md 1 recorded sprint(s) over 4 ticket(s); usd: MEASUREMENT.md per-skill table, recorded 2026-08-24; wall-clock: none |
| usd | 34.87 | 8.45 | tokens: LEDGER.md 1 recorded sprint(s) over 4 ticket(s); usd: MEASUREMENT.md per-skill table, recorded 2026-08-24; wall-clock: none |

RATIO verify_usd_per_ticket batched session 33d2edfe = 1.06
  numerator USD 4.23 (harvest-usage.sh over 1 session id(s) @ 2026-09-13T21:06:16Z)
  denominator 4 ticket(s) (run-20260913T151122Z.jsonl outcome events @ 2026-09-13T21:06:16Z)
FINDINGS parked 4 (run-20260913T151122Z.jsonl outcome events @ 2026-09-13T21:06:16Z)
NOTE A rerun, not a sprint: one queue session (restaged 0151-0154, filed 0158-0164) and one verify
  session on claude-opus-5 (0151 pass; 0152, 0153, 0154 fail). Tickets is written as text, which
  removes this whole block from the per-ticket priors: its 11 counts filed tickets, and a queue plus
  verify run has no develop cost to divide. Uncorrected, it pulled a three-ticket estimate to 97 min
  and USD 2.30. Wall-clock includes a session-limit stop of verify 33d2edfe, logged as limit_hit and
  resumed. USD is the harvest over every turn in both transcripts (19 distinct assistant messages in
  33d2edfe, no sidechain) and is a lower bound: the two verify legs self-reported 2.15 and 4.06
  against 4.23 harvested. The supervisor carried run-20260913T034946Z in context
  (supervisor_context), and its spend is not in these figures.

## sprint run-20260913T222409Z -- ended 2026-09-18T03:36:20Z

| Figure | Estimate | Actual | Estimate source |
|---|---|---|---|
| tickets | 3 | 3 | confirmed scope @ 2026-09-18T03:36:20Z |
| wall_clock_min | no prior | unmeasured: 6072 elapsed over several days, nearly all of it idle between turns | tokens: LEDGER.md run-20260913T034946Z over 4 tickets; usd: MEASUREMENT.md per-skill table, recorded 2026-08-24; wall-clock: none |
| tokens | 14334456 | 11182501 | tokens: LEDGER.md run-20260913T034946Z over 4 tickets; usd: MEASUREMENT.md per-skill table, recorded 2026-08-24; wall-clock: none |
| usd | 22.98 | 17.81 | tokens: LEDGER.md run-20260913T034946Z over 4 tickets; usd: MEASUREMENT.md per-skill table, recorded 2026-08-24; wall-clock: none |

GATE develop 3 ticket(s) session b03e9ce0: predicted USD 14.11 (config.yml stage_budget_usd, as at 2026-08-30 @ 2026-09-18T03:36:20Z) observed USD 3.78 (harvest-usage.sh over 1 session id(s) @ 2026-09-18T03:36:20Z)
GATE develop 1 ticket(s) session eac85fd6: predicted USD 6.05 (config.yml stage_budget_usd, as at 2026-08-30 @ 2026-09-18T03:36:20Z) observed USD 1.10 (harvest-usage.sh over 1 session id(s) @ 2026-09-18T03:36:20Z)
GATE develop 1 ticket(s) session 4612f9bf: predicted USD 6.05 (config.yml stage_budget_usd, as at 2026-08-30 @ 2026-09-18T03:36:20Z) observed USD 1.24 (harvest-usage.sh over 1 session id(s) @ 2026-09-18T03:36:20Z)
RATIO verify_usd_per_ticket batched session 7d814a75 = 1.05
  numerator USD 3.15 (harvest-usage.sh over 1 session id(s) @ 2026-09-18T03:36:20Z)
  denominator 3 ticket(s) (run-20260913T222409Z.jsonl outcome events @ 2026-09-18T03:36:20Z)
RATIO verify_usd_per_ticket unbatched session 091e8968 = 1.00
  numerator USD 1.00 (harvest-usage.sh over 1 session id(s) @ 2026-09-18T03:36:20Z)
  denominator 1 ticket(s) (run-20260913T222409Z.jsonl outcome events @ 2026-09-18T03:36:20Z)
RATIO verify_usd_per_ticket unbatched session c8367270 = 1.75
  numerator USD 1.75 (harvest-usage.sh over 1 session id(s) @ 2026-09-18T03:36:20Z)
  denominator 1 ticket(s) (run-20260913T222409Z.jsonl outcome events @ 2026-09-18T03:36:20Z)
FINDINGS parked 8 (run-20260913T222409Z.jsonl outcome events @ 2026-09-18T03:36:20Z)
RETRO consumed 0 produced 0 (run-20260913T222409Z.jsonl outcome events @ 2026-09-18T03:36:20Z)
NOTE Three tickets (0152, 0153, 0154), all passing verify, on claude-opus-5 throughout: tokens and
  usd are a fair per-ticket prior and stay numeric. Wall-clock is written as text because the run
  spans several days of a person's working session, nearly all idle between turns, and the ledger
  cannot yet separate active time (0164). 0153 took four develop rounds and three verify rounds:
  three shape-by-shape grep tightenings of one AC, then a guard that executes the snippet, which is
  why the develop gates below are three rows rather than one. The verify rows split for the same
  reason — 7d814a75 batched three tickets, 091e8968 and c8367270 re-verified 0153 alone, and
  c8367270's 1.75 spans both legs of a host memory kill and its resume. The retro (e30dfa9d) and
  the queue sweep (7bc65dbf) are in these figures; RETRO consumed/produced reads 0 because neither
  tail stage returns per-ticket outcomes. Not in these figures: the supervisor's own spend, and the
  supervisor finishing the blocked sweep by hand (0165-0171, 9d30104) after the sweep session was
  refused every write under `.claude/`.

## sprint run-20260920T222013Z -- ended 2026-09-20T23:20:16Z

| Figure | Estimate | Actual | Estimate source |
|---|---|---|---|
| tickets | 4 | 4 | confirmed scope @ 2026-09-20T23:20:25Z |
| wall_clock_min | no prior | 60 | LEDGER.md 3 recorded sprint(s) over 7 ticket(s) @ 2026-09-20T22:00:26Z |
| tokens | 17311491 | 21199117 | LEDGER.md 3 recorded sprint(s) over 7 ticket(s) @ 2026-09-20T22:00:26Z |
| usd | 23.75 | 15.21 | LEDGER.md 3 recorded sprint(s) over 7 ticket(s) @ 2026-09-20T22:00:26Z |

GATE develop 4 ticket(s) session 39c7c2e3: predicted USD 18.14 (config.yml stage_budget_usd, as at 2026-08-30 @ 2026-09-20T23:20:25Z) observed USD 15.21 (harvest-usage.sh over 1 session id(s) @ 2026-09-20T23:20:25Z)
GATE develop 4 ticket(s) session c2435e20: predicted USD 18.14 (config.yml stage_budget_usd, as at 2026-08-30 @ 2026-09-20T23:20:25Z) observed USD 0.00 (harvest-usage.sh over 1 session id(s) @ 2026-09-20T23:20:25Z)
FINDINGS parked 3 (run-20260920T222013Z.jsonl outcome events @ 2026-09-20T23:20:25Z)

### run-20260920T222013Z — completion of the block above

The block above was written when the run escalated after `develop`, and records only that leg. The
run then resumed across a date boundary and ran to a full tail. **Read the two together; do not
count them as two sprints.** One `sprint_ended` event exists, deliberately — see FINDINGS
2026-09-21 on what identifies a sprint across a suspension.

| Figure | Estimate | Actual (whole run) |
|---|---|---|
| tickets closed | 4 | 4 |
| wall_clock_min | no prior | see note — elapsed spans an overnight suspension and is not active time |
| usd | 23.75 | 36.81 |

Per stage, harvested by session id: develop 15.21 · verify 15.04 (one session, three resumes) ·
retro 3.47 (cap 7.50) · queue 3.09 (cap 12.72). Tail caps scaled x2 on a buffer of 9 against a
threshold of 8.

Cost per closed ticket: **USD 9.20** all stages, **USD 7.56** counting develop and verify only.
Neither includes the supervisor's own spend, which is attributed to no ticket.

Estimate was low by 55%, and the whole of the gap is interruption: the verify session was cut three
times (account session limit, the background wrapper's 600s ceiling, host sleep twice) and re-paid
its context floor on each resume. The estimate model has no term for this. Findings buffer 2 -> 9
-> 1 across the run.

## sprint run-20260922T022312Z -- ended 2026-09-22T02:44:42Z

| Figure | Estimate | Actual | Estimate source |
|---|---|---|---|
| tickets | 1 | 1 | confirmed scope @ 2026-09-22T02:44:51Z |
| wall_clock_min | 15 | 9 | LEDGER.md 4 recorded sprint(s) over 11 ticket(s) @ 2026-09-22T02:23:48Z — superseded before dispatch: user redirected the run to a queue session |
| tokens | 4681293 | 3032114 | LEDGER.md 4 recorded sprint(s) over 11 ticket(s) @ 2026-09-22T02:23:48Z — superseded before dispatch: user redirected the run to a queue session |
| usd | 7.80 | 3.40 | LEDGER.md 4 recorded sprint(s) over 11 ticket(s) @ 2026-09-22T02:23:48Z — superseded before dispatch: user redirected the run to a queue session |

FINDINGS parked 1 (run-20260922T022312Z.jsonl outcome events @ 2026-09-22T02:44:51Z)

## sprint run-20260922T031109Z -- ended 2026-09-24T00:00:58Z

| Figure | Estimate | Actual | Estimate source |
|---|---|---|---|
| tickets | 6 | 6 | confirmed scope @ 2026-09-24T00:00:58Z |
| wall_clock_min | 83 | 2689 | LEDGER.md 5 recorded sprint(s) over 12 ticket(s) @ 2026-09-22T03:11:22Z |
| tokens | 27263170 | 48376083 | LEDGER.md 5 recorded sprint(s) over 12 ticket(s) @ 2026-09-22T03:11:22Z — partial: 2 unpriced turn(s) |
| usd | 43.52 | 36.62 | LEDGER.md 5 recorded sprint(s) over 12 ticket(s) @ 2026-09-22T03:11:22Z — partial: 2 unpriced turn(s) |
| tail_tokens | no prior | 808361 | harvest-usage.sh over 1 session id(s) @ 2026-09-24T00:00:58Z — partial: 18 unpriced turn(s) |
| tail_usd | no prior | 1.22 | harvest-usage.sh over 1 session id(s) @ 2026-09-24T00:00:58Z — partial: 18 unpriced turn(s) |

GATE develop 6 ticket(s) session 540d0cb1: predicted USD 26.20 (config.yml stage_budget_usd, as at 2026-08-30 @ 2026-09-24T00:00:58Z) observed USD 22.18 (harvest-usage.sh over 1 session id(s) @ 2026-09-24T00:00:58Z)
GATE develop 1 ticket(s) session dda30e75: predicted USD 6.05 (config.yml stage_budget_usd, as at 2026-08-30 @ 2026-09-24T00:00:58Z) observed USD 3.42 (harvest-usage.sh over 1 session id(s) @ 2026-09-24T00:00:58Z)
RATIO verify_usd_per_ticket batched session e0cf784f = 1.84
  numerator USD 11.02 (harvest-usage.sh over 1 session id(s) @ 2026-09-24T00:00:58Z)
  denominator 6 ticket(s) (run-20260922T031109Z.jsonl outcome events @ 2026-09-24T00:00:58Z)
FINDINGS parked 2 (run-20260922T031109Z.jsonl outcome events @ 2026-09-24T00:00:58Z)

**CORRECTION to run-20260922T031109Z, added 2026-09-23 after the tail completed.** The `tail_tokens` and `tail_usd` figures above (808361 / 1.22) were recorded when the retro had run one leg, and they are NOT the tail's cost. The retro was then resumed twice and the queue sweep ran, and both later legs ran `claude-opus-5-5`, for which `harvest-usage.sh` has no rate. The queue session is absent from the harvest entirely and 50 of the retro's 91 turns are unpriced, so **the true tail cost cannot be computed from the transcripts** and must not be read as 1.22. Do not use this run's tail figures as a prior. Stage self-reports, for what they are worth: retro 1.22 + 2.48 + 3.60, queue 1.26. Parked as a finding 2026-09-23; see also 0162, which is why the gap was visible rather than silent.

## sprint run-20260924T050130Z -- ended 2026-09-25T19:46:56Z

| Figure | Estimate | Actual | Estimate source |
|---|---|---|---|
| tickets | 6 | 9 | confirmed scope @ 2026-09-25T19:46:56Z |
| wall_clock_min | 1504 | 2323 | LEDGER.md 5 recorded sprint(s) over 18 ticket(s), 1 excluded (no ticket count), 4 predate the tail split |
| tokens | 34300808 | unpriced | LEDGER.md 5 recorded sprint(s) over 18 ticket(s), 1 excluded (no ticket count), 4 predate the tail split — unpriced: 492 turn(s) on a model with no published rate |
| usd | 40.56 | unpriced | LEDGER.md 5 recorded sprint(s) over 18 ticket(s), 1 excluded (no ticket count), 4 predate the tail split — unpriced: 492 turn(s) on a model with no published rate |
| tail_tokens | no prior | unpriced | harvest-usage.sh over 3 session id(s) @ 2026-09-25T19:46:56Z — unpriced: 70 turn(s) on a model with no published rate |
| tail_usd | no prior | unpriced | harvest-usage.sh over 3 session id(s) @ 2026-09-25T19:46:56Z — unpriced: 70 turn(s) on a model with no published rate |
NOTE (supervisor, hand-corrected): the harvest priced none of this run's 492 turns (claude-opus-5-5 has no rate, 0186), and `record` wrote each per-session figure as 0.00; those are rewritten above as unpriced, not measured zeros. Stage-reported spend, the sum of the outcome events' cost_usd in run-20260924T050130Z.jsonl, is USD 23.75, excluding the supervisor and the two direct sessions (98eec368, 5a1f13d6), which report no cost.

GATE develop 1 ticket(s) session bb35f8a5: predicted USD 6.05 (config.yml stage_budget_usd, as at 2026-08-30 @ 2026-09-25T19:46:56Z) observed unpriced (harvest-usage.sh over 1 session id(s) @ 2026-09-25T19:46:56Z)
GATE develop 1 ticket(s) session c402c22c: predicted USD 6.05 (config.yml stage_budget_usd, as at 2026-08-30 @ 2026-09-25T19:46:56Z) observed unpriced (harvest-usage.sh over 1 session id(s) @ 2026-09-25T19:46:56Z)
GATE develop 1 ticket(s) session 0c9f365a: predicted USD 6.05 (config.yml stage_budget_usd, as at 2026-08-30 @ 2026-09-25T19:46:56Z) observed unpriced (harvest-usage.sh over 1 session id(s) @ 2026-09-25T19:46:56Z)
GATE develop 1 ticket(s) session bc985dbd: predicted USD 6.05 (config.yml stage_budget_usd, as at 2026-08-30 @ 2026-09-25T19:46:56Z) observed unpriced (harvest-usage.sh over 1 session id(s) @ 2026-09-25T19:46:56Z)
GATE develop 1 ticket(s) session c21b3775: predicted USD 6.05 (config.yml stage_budget_usd, as at 2026-08-30 @ 2026-09-25T19:46:56Z) observed unpriced (harvest-usage.sh over 1 session id(s) @ 2026-09-25T19:46:56Z)
GATE develop 1 ticket(s) session 20a3a642: predicted USD 6.05 (config.yml stage_budget_usd, as at 2026-08-30 @ 2026-09-25T19:46:56Z) observed unpriced (harvest-usage.sh over 1 session id(s) @ 2026-09-25T19:46:56Z)
RATIO verify_usd_per_ticket unbatched session d3e047e6 = unpriced
  numerator unpriced (harvest-usage.sh over 1 session id(s) @ 2026-09-25T19:46:56Z)
  denominator 1 ticket(s) (run-20260924T050130Z.jsonl outcome events @ 2026-09-25T19:46:56Z)
RATIO verify_usd_per_ticket unbatched session 1d3fb920 = unpriced
  numerator unpriced (harvest-usage.sh over 1 session id(s) @ 2026-09-25T19:46:56Z)
  denominator 1 ticket(s) (run-20260924T050130Z.jsonl outcome events @ 2026-09-25T19:46:56Z)
RATIO verify_usd_per_ticket unbatched session 5821ec05 = unpriced
  numerator unpriced (harvest-usage.sh over 1 session id(s) @ 2026-09-25T19:46:56Z)
  denominator 1 ticket(s) (run-20260924T050130Z.jsonl outcome events @ 2026-09-25T19:46:56Z)
RATIO verify_usd_per_ticket unbatched session 8eed6ca8 = unpriced
  numerator unpriced (harvest-usage.sh over 1 session id(s) @ 2026-09-25T19:46:56Z)
  denominator 1 ticket(s) (run-20260924T050130Z.jsonl outcome events @ 2026-09-25T19:46:56Z)
RATIO verify_usd_per_ticket unbatched session 57da099b = unpriced
  numerator unpriced (harvest-usage.sh over 1 session id(s) @ 2026-09-25T19:46:56Z)
  denominator 1 ticket(s) (run-20260924T050130Z.jsonl outcome events @ 2026-09-25T19:46:56Z)
RATIO verify_usd_per_ticket unbatched session 722b5bbe = unpriced
  numerator unpriced (harvest-usage.sh over 1 session id(s) @ 2026-09-25T19:46:56Z)
  denominator 1 ticket(s) (run-20260924T050130Z.jsonl outcome events @ 2026-09-25T19:46:56Z)
RATIO verify_usd_per_ticket unbatched session fa3ec517 = unpriced
  numerator unpriced (harvest-usage.sh over 1 session id(s) @ 2026-09-25T19:46:56Z)
  denominator 1 ticket(s) (run-20260924T050130Z.jsonl outcome events @ 2026-09-25T19:46:56Z)
DESIGN 0179 session d22459cb sequential: predicted USD 2.32 (MEASUREMENT.md per-skill table, recorded 2026-08-24 @ 2026-09-25T19:46:56Z) observed unpriced (harvest-usage.sh over 1 session id(s) @ 2026-09-25T19:46:56Z)
DESIGN 0179 session 3177df94 sequential: predicted USD 2.32 (MEASUREMENT.md per-skill table, recorded 2026-08-24 @ 2026-09-25T19:46:56Z) observed unpriced (harvest-usage.sh over 1 session id(s) @ 2026-09-25T19:46:56Z)
DESIGN 0180 session ee449922 sequential: predicted USD 2.32 (MEASUREMENT.md per-skill table, recorded 2026-08-24 @ 2026-09-25T19:46:56Z) observed unpriced (harvest-usage.sh over 1 session id(s) @ 2026-09-25T19:46:56Z)
DESIGN 0185 session 4476cbc5 concurrent: predicted USD 2.32 (MEASUREMENT.md per-skill table, recorded 2026-08-24 @ 2026-09-25T19:46:56Z) observed unpriced (harvest-usage.sh over 1 session id(s) @ 2026-09-25T19:46:56Z)
DESIGN 0178 session a5c9a0fa sequential: predicted USD 2.32 (MEASUREMENT.md per-skill table, recorded 2026-08-24 @ 2026-09-25T19:46:56Z) observed unpriced (harvest-usage.sh over 1 session id(s) @ 2026-09-25T19:46:56Z)
FINDINGS parked 6 (run-20260924T050130Z.jsonl outcome events @ 2026-09-25T19:46:56Z)
RETRO consumed 0 produced 0 (run-20260924T050130Z.jsonl outcome events @ 2026-09-25T19:46:56Z)

## sprint run-20260925T203345Z -- ended 2026-09-26T13:51:15Z

| Figure | Estimate | Actual | Estimate source |
|---|---|---|---|
| tickets | 5 | 7 | confirmed scope @ 2026-09-26T13:51:15Z |
| wall_clock_min | 1270 | 566 | LEDGER.md 6 recorded sprint(s) over 27 ticket(s), 1 excluded (no ticket count), 5 predate the tail split |
| tokens | 28584006 | unpriced | LEDGER.md 6 recorded sprint(s) over 27 ticket(s), 1 excluded (no ticket count), 5 predate the tail split — unpriced: 301 turn(s) on a model with no published rate |
| usd | 33.80 | unpriced | LEDGER.md 6 recorded sprint(s) over 27 ticket(s), 1 excluded (no ticket count), 5 predate the tail split — unpriced: 301 turn(s) on a model with no published rate |
| tail_tokens | no prior | 0 | harvest-usage.sh over 0 session id(s) @ 2026-09-26T13:51:15Z |
| tail_usd | no prior | 0.00 | harvest-usage.sh over 0 session id(s) @ 2026-09-26T13:51:15Z |

GATE develop 1 ticket(s) session 7afba036: predicted USD 6.05 (config.yml stage_budget_usd, as at 2026-08-30 @ 2026-09-26T13:51:15Z) observed USD 0.00 (harvest-usage.sh over 1 session id(s) @ 2026-09-26T13:51:15Z)
GATE develop 1 ticket(s) session fa2fc40c: predicted USD 6.05 (config.yml stage_budget_usd, as at 2026-08-30 @ 2026-09-26T13:51:15Z) observed USD 0.00 (harvest-usage.sh over 1 session id(s) @ 2026-09-26T13:51:15Z)
GATE develop 2 ticket(s) session 96a22e87: predicted USD 10.08 (config.yml stage_budget_usd, as at 2026-08-30 @ 2026-09-26T13:51:15Z) observed USD 0.00 (harvest-usage.sh over 1 session id(s) @ 2026-09-26T13:51:15Z)
GATE develop 1 ticket(s) session 89ee7d04: predicted USD 6.05 (config.yml stage_budget_usd, as at 2026-08-30 @ 2026-09-26T13:51:15Z) observed USD 0.00 (harvest-usage.sh over 1 session id(s) @ 2026-09-26T13:51:15Z)
RATIO verify_usd_per_ticket unbatched session 1f47886d = 0.00
  numerator USD 0.00 (harvest-usage.sh over 1 session id(s) @ 2026-09-26T13:51:15Z)
  denominator 1 ticket(s) (run-20260925T203345Z.jsonl outcome events @ 2026-09-26T13:51:15Z)
RATIO verify_usd_per_ticket unbatched session 0208c94b = 0.00
  numerator USD 0.00 (harvest-usage.sh over 1 session id(s) @ 2026-09-26T13:51:15Z)
  denominator 1 ticket(s) (run-20260925T203345Z.jsonl outcome events @ 2026-09-26T13:51:15Z)
RATIO verify_usd_per_ticket unbatched session e38994b6 = 0.00
  numerator USD 0.00 (harvest-usage.sh over 1 session id(s) @ 2026-09-26T13:51:15Z)
  denominator 1 ticket(s) (run-20260925T203345Z.jsonl outcome events @ 2026-09-26T13:51:15Z)
RATIO verify_usd_per_ticket unbatched session 9c168ec0 = 0.00
  numerator USD 0.00 (harvest-usage.sh over 1 session id(s) @ 2026-09-26T13:51:15Z)
  denominator 1 ticket(s) (run-20260925T203345Z.jsonl outcome events @ 2026-09-26T13:51:15Z)
DESIGN 0187 session 6c7d50e2 concurrent: predicted USD 2.32 (MEASUREMENT.md per-skill table, recorded 2026-08-24 @ 2026-09-26T13:51:15Z) observed USD 0.00 (harvest-usage.sh over 1 session id(s) @ 2026-09-26T13:51:15Z)
DESIGN 0188 session ee037d50 concurrent: predicted USD 2.32 (MEASUREMENT.md per-skill table, recorded 2026-08-24 @ 2026-09-26T13:51:15Z) observed USD 0.00 (harvest-usage.sh over 1 session id(s) @ 2026-09-26T13:51:15Z)
FINDINGS parked 6 (run-20260925T203345Z.jsonl outcome events @ 2026-09-26T13:51:15Z)

## sprint run-20261004T232135Z -- ended 2026-10-07T04:36:27Z

| Figure | Estimate | Actual | Estimate source |
|---|---|---|---|
| tickets | 5 | 5 | confirmed scope @ 2026-10-07T04:36:41Z |
| wall_clock_min | 1046 | 3183 | LEDGER.md 7 recorded sprint(s) over 34 ticket(s), 1 excluded (no ticket count), 5 predate the tail split @ 2026-10-04T23:27:36Z |
| tokens | 28584006 | unpriced | LEDGER.md 7 recorded sprint(s) over 34 ticket(s), 1 excluded (no ticket count), 5 predate the tail split @ 2026-10-04T23:27:36Z — unpriced: 384 turn(s) on a model with no published rate |
| usd | 33.80 | unpriced | LEDGER.md 7 recorded sprint(s) over 34 ticket(s), 1 excluded (no ticket count), 5 predate the tail split @ 2026-10-04T23:27:36Z — unpriced: 384 turn(s) on a model with no published rate |
| tail_tokens | no prior | unpriced | harvest-usage.sh over 2 session id(s) @ 2026-10-07T04:36:41Z — unpriced: 53 turn(s) on a model with no published rate |
| tail_usd | no prior | unpriced | harvest-usage.sh over 2 session id(s) @ 2026-10-07T04:36:41Z — unpriced: 53 turn(s) on a model with no published rate |

| Window | Stage | Elapsed min | Context tokens | USD |
|---|---|---|---|---|
| 4a8af893 | develop | unpriced | unpriced | unpriced |
| ef438b66 | verify | unpriced | unpriced | unpriced |
| ddf44e82 | queue | unpriced | unpriced | unpriced |
| 94fa35d3 | develop | unpriced | unpriced | unpriced |
| d0572e62 | verify | unpriced | unpriced | unpriced |
| 526d4ea6 | develop | unpriced | unpriced | unpriced |
| 5720f253 | verify | unpriced | unpriced | unpriced |
| 955b4491 | retro | unpriced | unpriced | unpriced |
WINDOWS elapsed is first to last turn per transcript and excludes start-up (harvest-usage.sh --by-session over 8 session id(s) @ 2026-10-07T04:36:41Z)
CLOSED 0187 0188 0174 0041 (run-20261004T232135Z.jsonl outcome events @ 2026-10-07T04:36:41Z)
TICKET 0187 verdict pass title Decide whether a sprint dispatch pins a concrete model or records the one that answered (run-20261004T232135Z.jsonl outcome events, DONE.md @ 2026-10-07T04:36:41Z)
TICKET 0188 verdict pass title Plan a sprint from a develop-ready head, and keep design one sprint ahead of develop (run-20261004T232135Z.jsonl outcome events, DONE.md @ 2026-10-07T04:36:41Z)
TICKET 0174 verdict pass title Say the findings gate is deferred until the run is out of work when no scope was confirmed (run-20261004T232135Z.jsonl outcome events, DONE.md @ 2026-10-07T04:36:41Z)
TICKET 0041 verdict pass title Write release notes for what a work session delivered (run-20261004T232135Z.jsonl outcome events, DONE.md @ 2026-10-07T04:36:41Z)

GATE develop 4 ticket(s) session 4a8af893: predicted USD 18.14 (config.yml stage_budget_usd, as at 2026-08-30 @ 2026-10-07T04:36:41Z) observed USD 0.00 (harvest-usage.sh over 1 session id(s) @ 2026-10-07T04:36:41Z)
GATE develop 1 ticket(s) session 94fa35d3: predicted USD 6.05 (config.yml stage_budget_usd, as at 2026-08-30 @ 2026-10-07T04:36:41Z) observed USD 0.00 (harvest-usage.sh over 1 session id(s) @ 2026-10-07T04:36:41Z)
GATE develop 1 ticket(s) session 526d4ea6: predicted USD 6.05 (config.yml stage_budget_usd, as at 2026-08-30 @ 2026-10-07T04:36:41Z) observed USD 0.00 (harvest-usage.sh over 1 session id(s) @ 2026-10-07T04:36:41Z)
RATIO verify_usd_per_ticket batched session ef438b66 = 0.00
  numerator USD 0.00 (harvest-usage.sh over 1 session id(s) @ 2026-10-07T04:36:41Z)
  denominator 4 ticket(s) (run-20261004T232135Z.jsonl outcome events @ 2026-10-07T04:36:41Z)
RATIO verify_usd_per_ticket unbatched session d0572e62 = 0.00
  numerator USD 0.00 (harvest-usage.sh over 1 session id(s) @ 2026-10-07T04:36:41Z)
  denominator 1 ticket(s) (run-20261004T232135Z.jsonl outcome events @ 2026-10-07T04:36:41Z)
RATIO verify_usd_per_ticket unbatched session 5720f253 = 0.00
  numerator USD 0.00 (harvest-usage.sh over 1 session id(s) @ 2026-10-07T04:36:41Z)
  denominator 1 ticket(s) (run-20261004T232135Z.jsonl outcome events @ 2026-10-07T04:36:41Z)
FINDINGS parked 7 (run-20261004T232135Z.jsonl outcome events @ 2026-10-07T04:36:41Z)
RETRO consumed 0 produced 0 (run-20261004T232135Z.jsonl outcome events @ 2026-10-07T04:36:41Z)

## sprint run-20261025T164527Z -- ended 2026-10-25T21:01:02Z

| Figure | Estimate | Actual | Estimate source |
|---|---|---|---|
| tickets | 5 | 6 | confirmed scope @ 2026-10-25T21:01:32Z |
| wall_clock_min | 1380 | 250 | LEDGER.md 8 recorded sprint(s) over 39 ticket(s), 1 excluded (no ticket count), 6 predate the tail split @ 2026-10-25T16:46:04Z, actual from run-20261025T164527Z.jsonl event timestamps |
| tokens | 28584006 | 37011339 | LEDGER.md 8 recorded sprint(s) over 39 ticket(s), 1 excluded (no ticket count), 6 predate the tail split @ 2026-10-25T16:46:04Z — partial: 4 unpriced turn(s) |
| usd | 33.80 | 17.22 | LEDGER.md 8 recorded sprint(s) over 39 ticket(s), 1 excluded (no ticket count), 6 predate the tail split @ 2026-10-25T16:46:04Z — partial: 4 unpriced turn(s) |
| tail_tokens | no prior | 0 | harvest-usage.sh over 0 session id(s) @ 2026-10-25T21:01:32Z |
| tail_usd | no prior | 0.00 | harvest-usage.sh over 0 session id(s) @ 2026-10-25T21:01:32Z |

| Window | Stage | Elapsed min | Context tokens | USD |
|---|---|---|---|---|
| 910ad043 | design | 2.1 | 744974 | 0.93 |
| ae083246 | develop | 38.7 | 19842719 | 7.46 |
| 0a863faf | verify | 13.2 | 5792432 | 3.05 |
| 9285f1bd | develop | 173.7 | 8961356 | 4.61 |
| e685f1cd | verify | 15.7 | 1669858 | 1.16 |
| total | 5 window(s) | 243.4 | 37011339 | 17.21 |
| average | per window | 48.7 | 7402267 | 3.44 |
WINDOWS elapsed is first to last turn per transcript and excludes start-up (harvest-usage.sh --by-session over 5 session id(s) @ 2026-10-25T21:01:32Z)
CLOSED 0195 0216 0110 0169 0046 (run-20261025T164527Z.jsonl outcome events @ 2026-10-25T21:01:32Z)
TICKET 0195 verdict pass title Stop a criterion changing without its author by digesting it at write and checking it at close (run-20261025T164527Z.jsonl outcome events, DONE.md @ 2026-10-25T21:01:32Z)
TICKET 0216 verdict pass title Decide whether an unattended stage may fast-forward a clean checkout that is only behind (run-20261025T164527Z.jsonl outcome events, DONE.md @ 2026-10-25T21:01:32Z)
TICKET 0110 verdict pass title Decide the shape of a ticket whose first requirement can kill the rest (run-20261025T164527Z.jsonl outcome events, DONE.md @ 2026-10-25T21:01:32Z)
TICKET 0169 verdict closed title Make a test file announce an abort instead of exiting silently under set -eu (run-20261025T164527Z.jsonl outcome events, DONE.md @ 2026-10-25T21:01:32Z)
TICKET 0046 verdict pass title Make the README guard list provably complete (run-20261025T164527Z.jsonl outcome events, DONE.md @ 2026-10-25T21:01:32Z)
PER_TICKET whole-run USD 3.44, develop-and-verify USD 3.26 over 5 closed ticket(s), beside MEASUREMENT.md whole-run USD 5.71, develop-and-verify USD 4.23 as at 2026-08-30 (harvest-usage.sh over 5 session id(s), run-20261025T164527Z.jsonl outcome events, MEASUREMENT.md read @ 2026-10-25T21:01:32Z)

GATE develop 4 ticket(s) session ae083246: predicted USD 18.14 (config.yml stage_budget_usd, as at 2026-08-30 @ 2026-10-25T21:01:32Z) observed USD 7.46 (harvest-usage.sh over 1 session id(s) @ 2026-10-25T21:01:32Z)
GATE develop 2 ticket(s) session 9285f1bd: predicted USD 10.08 (config.yml stage_budget_usd, as at 2026-08-30 @ 2026-10-25T21:01:32Z) observed USD 4.61, partial: 4 unpriced turn(s) (harvest-usage.sh over 1 session id(s) @ 2026-10-25T21:01:32Z)
RATIO verify_usd_per_ticket batched session 0a863faf = 1.02
  numerator USD 3.05 (harvest-usage.sh over 1 session id(s) @ 2026-10-25T21:01:32Z)
  denominator 3 ticket(s) (run-20261025T164527Z.jsonl outcome events @ 2026-10-25T21:01:32Z)
RATIO verify_usd_per_ticket unbatched session e685f1cd = 1.16
  numerator USD 1.16 (harvest-usage.sh over 1 session id(s) @ 2026-10-25T21:01:32Z)
  denominator 1 ticket(s) (run-20261025T164527Z.jsonl outcome events @ 2026-10-25T21:01:32Z)
DESIGN 0216 session 910ad043 sequential: predicted USD 2.32 (MEASUREMENT.md per-skill table, recorded 2026-08-24 @ 2026-10-25T21:01:32Z) observed USD 0.93 (harvest-usage.sh over 1 session id(s) @ 2026-10-25T21:01:32Z)
FINDINGS parked 3 (run-20261025T164527Z.jsonl outcome events @ 2026-10-25T21:01:32Z)

## sprint run-20261025T215324Z -- ended 2026-10-27T18:39:35Z

| Figure | Estimate | Actual | Estimate source |
|---|---|---|---|
| tickets | 14 | 14 | confirmed scope @ 2026-10-27T18:39:35Z |
| wall_clock_min | 3345 | 2650 | LEDGER.md 9 recorded sprint(s) over 45 ticket(s), 1 excluded (no ticket count), 6 predate the tail split @ 2026-10-25T22:05:08Z, actual from run-20261025T215324Z.jsonl event timestamps |
| tokens | 81616361 | 104417592 | LEDGER.md 9 recorded sprint(s) over 45 ticket(s), 1 excluded (no ticket count), 6 predate the tail split @ 2026-10-25T22:05:08Z — partial: 4 unpriced turn(s) |
| usd | 78.30 | 58.91 | LEDGER.md 9 recorded sprint(s) over 45 ticket(s), 1 excluded (no ticket count), 6 predate the tail split @ 2026-10-25T22:05:08Z — partial: 4 unpriced turn(s) |
| tail_tokens | no prior | 4230011 | harvest-usage.sh over 5 session id(s) @ 2026-10-27T18:39:35Z |
| tail_usd | no prior | 4.21 | harvest-usage.sh over 5 session id(s) @ 2026-10-27T18:39:35Z |

| Window | Stage | Elapsed min | Context tokens | USD |
|---|---|---|---|---|
| b7890bf3 | design | 3.1 | 1012785 | 1.16 |
| 31dae04d | design | 2.0 | 835442 | 0.83 |
| 71025dda | design | 5.5 | 1544456 | 1.22 |
| fc9c4282 | design | 2.4 | 1031628 | 0.94 |
| 3246ed02 | design | 3.3 | 1319926 | 1.02 |
| a595272a | design | 3.0 | 1138439 | 1.07 |
| 3ae98a2b | design | 2.6 | 944731 | 0.92 |
| 837b66a2 | design | 5.7 | 1377393 | 1.18 |
| 3e6a9ab4 | develop | 13.7 | 1834578 | 1.19 |
| ca12cbab | verify | 9.4 | 492044 | 0.63 |
| e9c46949 | develop | 149.8 | 8939896 | 4.95 |
| 9e5960ec | queue | 1.3 | 659239 | 0.73 |
| 63d626e9 | verify | 10.5 | 1001807 | 0.89 |
| 0f5d5427 | verify | 10.6 | 872279 | 0.94 |
| 9b76190f | verify | 13.3 | 1320869 | 1.09 |
| f8d25097 | develop | 478.2 | 28155294 | 12.13 |
| 34118469 | queue | 1.0 | 608400 | 0.72 |
| b4f27c5f | verify | 60.0 | 7899330 | 3.58 |
| d54b1ea7 | develop | 34.7 | 10439517 | 4.46 |
| 9d4925e9 | verify | 37.4 | 5251958 | 2.85 |
| 0f9a5a51 | design | 1.8 | 856059 | 0.81 |
| 790ed256 | develop | 22.4 | 7785572 | 3.88 |
| 0cf64845 | verify | 109.0 | 1944614 | 1.73 |
| 9f31f4fe | verify | 12.8 | 1872260 | 1.31 |
| 41c56e5d | queue | 1.2 | 777878 | 0.77 |
| 2291072f | develop | 16.9 | 4974682 | 2.65 |
| 38f959df | verify | 16.2 | 2772796 | 1.78 |
| 8133f167 | develop | 8.8 | 3486500 | 1.89 |
| 3b4aaee2 | verify | 13.4 | 1475093 | 1.26 |
| fe882f49 | develop | 7.3 | 2526202 | 1.55 |
| ca99ee5f | verify | 6.6 | 1311442 | 1.02 |
| 14211325 | retro | 12.3 | 1599061 | 1.41 |
| 7d0d84ef | queue | 0.6 | 585433 | 0.58 |
| total | 33 window(s) | 1076.8 | 108647603 | 63.14 |
| average | per window | 32.6 | 3292351 | 1.91 |
WINDOWS elapsed is first to last turn per transcript and excludes start-up (harvest-usage.sh --by-session over 33 session id(s) @ 2026-10-27T18:39:35Z)
CLOSED none (run-20261025T215324Z.jsonl outcome events @ 2026-10-27T18:39:35Z)

GATE develop 1 ticket(s) session 3e6a9ab4: predicted USD 6.05 (config.yml stage_budget_usd, as at 2026-08-30 @ 2026-10-27T18:39:35Z) observed USD 1.19 (harvest-usage.sh over 1 session id(s) @ 2026-10-27T18:39:35Z)
GATE develop 4 ticket(s) session e9c46949: predicted USD 18.14 (config.yml stage_budget_usd, as at 2026-08-30 @ 2026-10-27T18:39:35Z) observed USD 4.95, partial: 1 unpriced turn(s) (harvest-usage.sh over 1 session id(s) @ 2026-10-27T18:39:35Z)
GATE develop 2 ticket(s) session f8d25097: predicted USD 10.08 (config.yml stage_budget_usd, as at 2026-08-30 @ 2026-10-27T18:39:35Z) observed USD 12.13, partial: 1 unpriced turn(s) (harvest-usage.sh over 1 session id(s) @ 2026-10-27T18:39:35Z)
GATE develop 4 ticket(s) session d54b1ea7: predicted USD 18.14 (config.yml stage_budget_usd, as at 2026-08-30 @ 2026-10-27T18:39:35Z) observed USD 4.46 (harvest-usage.sh over 1 session id(s) @ 2026-10-27T18:39:35Z)
GATE develop 3 ticket(s) session 790ed256: predicted USD 14.11 (config.yml stage_budget_usd, as at 2026-08-30 @ 2026-10-27T18:39:35Z) observed USD 3.88 (harvest-usage.sh over 1 session id(s) @ 2026-10-27T18:39:35Z)
GATE develop 2 ticket(s) session 2291072f: predicted USD 10.08 (config.yml stage_budget_usd, as at 2026-08-30 @ 2026-10-27T18:39:35Z) observed USD 2.65 (harvest-usage.sh over 1 session id(s) @ 2026-10-27T18:39:35Z)
GATE develop 1 ticket(s) session 8133f167: predicted USD 6.05 (config.yml stage_budget_usd, as at 2026-08-30 @ 2026-10-27T18:39:35Z) observed USD 1.89 (harvest-usage.sh over 1 session id(s) @ 2026-10-27T18:39:35Z)
GATE develop 1 ticket(s) session fe882f49: predicted USD 6.05 (config.yml stage_budget_usd, as at 2026-08-30 @ 2026-10-27T18:39:35Z) observed USD 1.55 (harvest-usage.sh over 1 session id(s) @ 2026-10-27T18:39:35Z)
RATIO verify_usd_per_ticket unbatched session ca12cbab = 0.63
  numerator USD 0.63 (harvest-usage.sh over 1 session id(s) @ 2026-10-27T18:39:35Z)
  denominator 1 ticket(s) (run-20261025T215324Z.jsonl outcome events @ 2026-10-27T18:39:35Z)
RATIO verify_usd_per_ticket unbatched session 63d626e9 = 0.89
  numerator USD 0.89 (harvest-usage.sh over 1 session id(s) @ 2026-10-27T18:39:35Z)
  denominator 1 ticket(s) (run-20261025T215324Z.jsonl outcome events @ 2026-10-27T18:39:35Z)
RATIO verify_usd_per_ticket unbatched session 0f5d5427 = 0.94
  numerator USD 0.94 (harvest-usage.sh over 1 session id(s) @ 2026-10-27T18:39:35Z)
  denominator 1 ticket(s) (run-20261025T215324Z.jsonl outcome events @ 2026-10-27T18:39:35Z)
RATIO verify_usd_per_ticket unbatched session 9b76190f = 1.09
  numerator USD 1.09 (harvest-usage.sh over 1 session id(s) @ 2026-10-27T18:39:35Z)
  denominator 1 ticket(s) (run-20261025T215324Z.jsonl outcome events @ 2026-10-27T18:39:35Z)
RATIO verify_usd_per_ticket batched session b4f27c5f = 1.79, partial: 1 unpriced turn(s)
  numerator USD 3.58, partial: 1 unpriced turn(s) (harvest-usage.sh over 1 session id(s) @ 2026-10-27T18:39:35Z)
  denominator 2 ticket(s) (run-20261025T215324Z.jsonl outcome events @ 2026-10-27T18:39:35Z)
RATIO verify_usd_per_ticket batched session 9d4925e9 = 0.95
  numerator USD 2.85 (harvest-usage.sh over 1 session id(s) @ 2026-10-27T18:39:35Z)
  denominator 3 ticket(s) (run-20261025T215324Z.jsonl outcome events @ 2026-10-27T18:39:35Z)
RATIO verify_usd_per_ticket unbatched session 0cf64845 = 1.73, partial: 1 unpriced turn(s)
  numerator USD 1.73, partial: 1 unpriced turn(s) (harvest-usage.sh over 1 session id(s) @ 2026-10-27T18:39:35Z)
  denominator 1 ticket(s) (run-20261025T215324Z.jsonl outcome events @ 2026-10-27T18:39:35Z)
RATIO verify_usd_per_ticket unbatched session 9f31f4fe = 1.31
  numerator USD 1.31 (harvest-usage.sh over 1 session id(s) @ 2026-10-27T18:39:35Z)
  denominator 1 ticket(s) (run-20261025T215324Z.jsonl outcome events @ 2026-10-27T18:39:35Z)
RATIO verify_usd_per_ticket batched session 38f959df = 0.89
  numerator USD 1.78 (harvest-usage.sh over 1 session id(s) @ 2026-10-27T18:39:35Z)
  denominator 2 ticket(s) (run-20261025T215324Z.jsonl outcome events @ 2026-10-27T18:39:35Z)
RATIO verify_usd_per_ticket unbatched session 3b4aaee2 = 1.26
  numerator USD 1.26 (harvest-usage.sh over 1 session id(s) @ 2026-10-27T18:39:35Z)
  denominator 1 ticket(s) (run-20261025T215324Z.jsonl outcome events @ 2026-10-27T18:39:35Z)
RATIO verify_usd_per_ticket unbatched session ca99ee5f = 1.02
  numerator USD 1.02 (harvest-usage.sh over 1 session id(s) @ 2026-10-27T18:39:35Z)
  denominator 1 ticket(s) (run-20261025T215324Z.jsonl outcome events @ 2026-10-27T18:39:35Z)
DESIGN 0175 session b7890bf3 sequential: predicted USD 2.32 (MEASUREMENT.md per-skill table, recorded 2026-08-24 @ 2026-10-27T18:39:35Z) observed USD 1.16 (harvest-usage.sh over 1 session id(s) @ 2026-10-27T18:39:35Z)
DESIGN 0172 session 31dae04d sequential: predicted USD 2.32 (MEASUREMENT.md per-skill table, recorded 2026-08-24 @ 2026-10-27T18:39:35Z) observed USD 0.83 (harvest-usage.sh over 1 session id(s) @ 2026-10-27T18:39:35Z)
DESIGN 0182 session 71025dda sequential: predicted USD 2.32 (MEASUREMENT.md per-skill table, recorded 2026-08-24 @ 2026-10-27T18:39:35Z) observed USD 1.22 (harvest-usage.sh over 1 session id(s) @ 2026-10-27T18:39:35Z)
DESIGN 0190 session fc9c4282 sequential: predicted USD 2.32 (MEASUREMENT.md per-skill table, recorded 2026-08-24 @ 2026-10-27T18:39:35Z) observed USD 0.94 (harvest-usage.sh over 1 session id(s) @ 2026-10-27T18:39:35Z)
DESIGN 0183 session 3246ed02 sequential: predicted USD 2.32 (MEASUREMENT.md per-skill table, recorded 2026-08-24 @ 2026-10-27T18:39:35Z) observed USD 1.02 (harvest-usage.sh over 1 session id(s) @ 2026-10-27T18:39:35Z)
DESIGN 0145 session a595272a sequential: predicted USD 2.32 (MEASUREMENT.md per-skill table, recorded 2026-08-24 @ 2026-10-27T18:39:35Z) observed USD 1.07 (harvest-usage.sh over 1 session id(s) @ 2026-10-27T18:39:35Z)
DESIGN 0146 session 3ae98a2b sequential: predicted USD 2.32 (MEASUREMENT.md per-skill table, recorded 2026-08-24 @ 2026-10-27T18:39:35Z) observed USD 0.92 (harvest-usage.sh over 1 session id(s) @ 2026-10-27T18:39:35Z)
DESIGN 0139 session 837b66a2 concurrent: predicted USD 2.32 (MEASUREMENT.md per-skill table, recorded 2026-08-24 @ 2026-10-27T18:39:35Z) observed USD 1.18 (harvest-usage.sh over 1 session id(s) @ 2026-10-27T18:39:35Z)
DESIGN 0146 session 0f9a5a51 sequential: predicted USD 2.32 (MEASUREMENT.md per-skill table, recorded 2026-08-24 @ 2026-10-27T18:39:35Z) observed USD 0.81 (harvest-usage.sh over 1 session id(s) @ 2026-10-27T18:39:35Z)
FINDINGS parked 0 (run-20261025T215324Z.jsonl outcome events @ 2026-10-27T18:39:35Z)
RETRO consumed 0 produced 0 (run-20261025T215324Z.jsonl outcome events @ 2026-10-27T18:39:35Z)

## sprint run-20261027T185815Z -- ended 2026-10-27T19:04:53Z

| Figure | Estimate | Actual | Estimate source |
|---|---|---|---|
| tickets | 5 | 0 | confirmed scope @ 2026-10-27T19:04:59Z |
| wall_clock_min | 1128 | not measured | LEDGER.md 10 recorded sprint(s) over 59 ticket(s), 1 excluded (no ticket count), 6 predate the tail split, actual from run-20261027T185815Z.jsonl event timestamps |
| tokens | 32148862 | 0 | LEDGER.md 10 recorded sprint(s) over 59 ticket(s), 1 excluded (no ticket count), 6 predate the tail split |
| usd | 25.11 | 0.00 | LEDGER.md 10 recorded sprint(s) over 59 ticket(s), 1 excluded (no ticket count), 6 predate the tail split |
| tail_tokens | no prior | 0 | harvest-usage.sh over 0 session id(s) @ 2026-10-27T19:04:59Z |
| tail_usd | no prior | 0.00 | harvest-usage.sh over 0 session id(s) @ 2026-10-27T19:04:59Z |

| Window | Stage | Elapsed min | Context tokens | USD |
|---|---|---|---|---|
WINDOWS elapsed is first to last turn per transcript and excludes start-up (harvest-usage.sh --by-session over 0 session id(s) @ 2026-10-27T19:04:59Z)
CLOSED none (run-20261027T185815Z.jsonl outcome events @ 2026-10-27T19:04:59Z)

FINDINGS parked 0 (run-20261027T185815Z.jsonl outcome events @ 2026-10-27T19:04:59Z)
