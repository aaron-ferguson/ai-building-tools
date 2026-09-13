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
