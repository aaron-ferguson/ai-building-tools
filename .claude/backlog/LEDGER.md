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
