---
id: "0192"
title: Stop an unpriced session reading as free in the sprint ledger and the harvest
type: bug
next: develop
status: ready
qa_level: unit
close_by: verify
size: s
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
- **FR5** — 0186 FR3 stands: no rate is added for `claude-opus-5-5` without a published source cited
  above `RATES`.

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

## Notes & decisions

- **2026-10-06 (retro, run-20261004T232135Z tail).** Filed from five FINDINGS.md entries dated
  2026-09-25..10-07. One row because they share two files and one defect class: an unpriced figure
  printed as zero, or a guard too small to tell counts apart.
