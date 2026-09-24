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
