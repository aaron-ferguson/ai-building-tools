---
id: "0192"
title: Stop an unpriced session reading as free in the sprint ledger and the harvest
type: bug
next: develop
status: ready
qa_level: unit
close_by: verify
size: m
created: 2026-10-06
source: retro
relates: ["0186", "0162", "0135"]
expects:
  - tools/sprint-ledger.sh
  - tools/harvest-usage.sh
  - tests/sprint-ledger.test.sh
  - skills/sprint/SKILL.md
parent:
blocked_by: []
claimed_by:
claimed_at:
touches:
---

## Problem

**0186 stopped the harvest's session rows printing USD 0.00 for an unpriced session; three other
readers of the same figures still do, and three sessions hit them independently.**

- `tools/sprint-ledger.sh record`, run-20260925T203345Z: every turn ran on a model missing from
  `RATES` (301 unpriced turns). The summary rows print `unpriced`, but every GATE, RATIO and DESIGN
  line prints `observed USD 0.00` — an unpriced session reads as a free one (`LEDGER.md`).
- `tools/harvest-usage.sh` per-SKILL table (develop 0186): a skill whose every turn is unpriced — the
  `queue` sweep of run-20260922T031109Z — has no skill row; its turns show only in the global
  UNPRICED line.
- `sprint` Step 7's session-limit resume caps the resumed leg at "stage cap less what a harvest of
  that session id already shows spent". Paused verify 0178 ran wholly unpriced (8 turns), the harvest
  said 0.00, and the supervisor subtracted a 1.00 allowance by hand.
- verify 0186: `tests/sprint-ledger.test.sh` 0186 AC2's fixture has one unpriced turn in one unpriced
  session, so mutations `% r["unpriced"]` → `% 1` and `merged["unpriced"] = unpriced` →
  `= unpriced_total` both stay 137/0.
- sprint run-20261008T021734Z (FINDINGS.md, 2026-10-08, "`harvest-usage.sh` has no rate for
  `claude-opus-5-5`"): `claude-opus-5-5`, now the default model, matched no `RATES` entry (154
  unpriced turns), so quantum-catan's three LEDGER.md rows (run-20261008T021734Z, …T023251Z,
  …T031454Z) recorded USD and tokens as `unpriced` and the develop GATE as observed USD 0.00. The
  harvest header also printed `RATES per million: opus 5 in 5.00 out 25.00, cache read 0.1x …` —
  a literal restated beside `RATES` (line ~465), which named a model the run never used.
- Published price for `claude-opus-5-5` (the claude-api skill's model table, cached 2026-10-06, and
  its `shared/prompt-caching.md` "Economics", both read 2026-10-08): input USD 4.00 and output
  USD 20.00 per million tokens; **cache read USD 0.20 per million = 0.05x input, not the 0.1x the
  script applies to every model**; cache writes 1.25x input at 5m and 2x at 1h, as elsewhere.
- develop 6ed0: `record` assigns `log_src = "<run log> event timestamps"` (line ~595) and never writes
  it, dead since `a3f5a7a` (0135), so no ledger line says the wall clock comes from run-log stamps.

## Functional requirements

- **FR1** — A GATE, RATIO or DESIGN line whose sessions include unpriced turns says so with the
  count; one whose sessions are wholly unpriced prints `unpriced`, never `USD 0.00`.
- **FR2** — The harvest's per-skill table has a row for every skill that ran, whether or not any turn
  was priced; a wholly unpriced skill shows its unpriced turn count and no USD figure.
- **FR3** — `sprint` Step 7 states what the resume cap is when the harvest shows the paused session
  wholly or partly unpriced, and that the run log records that the subtraction could not be made.
  Retro's recommendation, open to the build: resume at the full stage cap rather than a guessed
  allowance.
- **FR4** — The `wall_clock_min` ledger row cites `log_src` as its source; the dead assignment goes.
- **FR5** — 0186 FR3 stands, and is now met: `RATES` in `tools/harvest-usage.sh` gains
  `claude-opus-5-5` at input 4.00 / output 20.00, with the source and the date it was read cited in
  the comment above `RATES`.
- **FR6** — The cache-read rate is per model, held in `RATES` beside that model's input and output
  rates: 0.05x for `claude-opus-5-5`, 0.1x for every model already listed. `cost_of` reads it from
  there; the global `CACHE_READ_MULT` no longer prices a turn. Cache-write multipliers stay global
  (1.25x at 5m, 2x at 1h — the same for every listed model).
- **FR7** — The harvest's `RATES per million:` header is derived from `RATES` and the cache-write
  constants, naming every listed model with its input, output and cache-read figures, so it cannot
  disagree with the table that prices the turns. No rate figure is written as a literal in that
  print statement.

## Acceptance criteria

- [ ] AC1 — Given a fixture run whose sessions are all unpriced, `record`'s GATE, RATIO and DESIGN
  lines print `unpriced` and no `USD 0.00`. Red: restore the 0.00 formatting.
- [ ] AC2 — Given two wholly unpriced skills with different turn counts, the per-skill table prints
  a row for each with its own count. Red: drop the row, or print the first skill's count for both.
- [ ] AC3 — 0186 AC2's guard uses two unpriced sessions with different counts, and the mutations
  `% r["unpriced"]` → `% 1` and `merged["unpriced"] = unpriced` → `= unpriced_total` each redden it.
- [ ] AC4 — The `wall_clock_min` row names the run log's event timestamps as its source. Red: remove
  `log_src` from that row.
- [ ] AC5 — `skills/sprint/SKILL.md` Step 7 names the unpriced-session resume cap. Red: delete it.
- [ ] AC6 — Given a fixture session of one `claude-opus-5-5` turn with 1,000,000 each of input,
  output, cache-read and 5-minute cache-write tokens, when it is harvested, then the TOTAL row reads
  USD 29.20 (4.00 + 20.00 + 0.20 + 5.00) and no `UNPRICED` line prints. **Write this test first and
  record it red** (today: unpriced, USD 0.00). Red: remove the `RATES` entry (unpriced), price it at
  0.1x cache read (29.40), or alias it to `claude-opus-5`'s rates (36.75) — the three figures differ
  on purpose.
- [ ] AC7 — The same fixture under the date-suffixed id `claude-opus-5-5-20261001` also prices at
  USD 29.20. Red: break the `DATE_SUFFIX` fallback.
- [ ] AC8 — Given 0186 AC3's all-priced store, the harvest's `RATES per million:` line names every
  `RATES` key with its own figures, and editing one rate in `RATES` (in a copy of the script made by
  the test) changes that line. Red: restore the literal header. 0186 AC3's golden output is updated in
  the same commit for this one line only; every other line of it stays byte-for-byte.
- [ ] AC9 — Given 0186 AC3's all-priced store (`claude-opus-5` only), every figure in the harvest
  other than the `RATES` line is unchanged by FR6. Red: change the 0.1x default in `RATES`.

## Notes & decisions

- **2026-10-06 (retro, run-20261004T232135Z tail).** Filed from five FINDINGS.md entries dated
  2026-09-25..10-07. One row because they share two files and one defect class: an unpriced figure
  printed as zero, or a guard too small to tell counts apart.
- **2026-10-09 (queue, amend).** The owner asked for the `claude-opus-5-5` rate to land together
  with FR1's "no USD 0.00 beside unpriced". FR1 already covered that half, so this row was amended
  rather than a second row filed. Added FR6–FR7 and AC6–AC9, FR5 rewritten from a gate into the
  rate itself (the 2026-10-08 FINDINGS.md entry was already absorbed above, at `07f0a96`). Size went s → m. Routed to
  `develop`, not `design`: the price is published and the header's shape is reachable from the code,
  so no decision is open. **TDD order the owner set:** AC6's test goes in red before any `RATES`
  edit. **Out of scope:** `tools/cost-by-category.sh` holds a second, separate `RATES` and
  `CACHE_READ_MULT`, and its `claude-sonnet-5` (3.00/15.00) disagrees with harvest's (2.00/10.00).
  That is a duplicated-knowledge defect of its own, parked in FINDINGS.md, not widened in here.
  Hand-editing quantum-catan's LEDGER.md rows is also out of scope, as are a push, a version bump
  and a reinstall.
- 2026-10-09 — retro, absorbed from tools `FINDINGS.md` (2026-10-08): a fourth instance. quantum-catan
  run-20261008T021734Z ran on `claude-opus-5-5`, which no `RATES` entry matched (154 unpriced turns),
  so `sprint-ledger.sh record` scored the develop gate at observed USD 0.00 against a predicted 0.00
  and the first sprint's USD 7.66 estimate against nothing. FR1 covers the printing; FR5 still governs
  adding a rate.
