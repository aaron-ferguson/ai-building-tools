---
id: "0198"
title: Decide how verify names the pattern behind a surviving mutation and what an FR-level survivor means
type: feature
next: design
status: ready
qa_level: unit
close_by: verify
qa_manual:
size: s
created: 2026-10-09
source: agent
parent:
blocked_by: []
relates: ["0161"]
expects:
  - skills/verify/SKILL.md
claimed_by:
claimed_at:
touches:
---

## Problem

Two findings from quantum-catan 0003, one cause.

- 2026-10-08, the owner's ask: verify FAILED 0003 on two survivors (AC1 `METROPOLIS_COUNT = 3`; the
  AC10 reshuffle order). Both came from tests deriving expected values from the constants the code
  uses. A supervisor sweep of every value in `constants.ts` found two more survivors verify did not
  name (City cost `ore: 2`, Metropolis cost `wool: 2`, both `82 passed`). A develop fixing only the
  named cases fails the next verify. **Owner's requirement:** on a narrow failure, verify names the
  general pattern, mutates every member of that class in the evidence set, and writes the class with
  every instance into the QA evidence.
- 2026-10-07: the class sweep then found 7 survivors against FR rules no AC names (e.g. win at 6 VP
  against FR9's "≥ 7"). Every AC held, and Step 3's gap test is phrased for prose ("the phrase … no
  longer occurs in that section"), so the only defensible reading was PASS-and-publish, with the
  survivors filed as quantum-catan 0009.

## Open design question

Does a surviving mutation on an FR that no AC clause names FAIL the ticket, PASS with a filed follow-up
(what happened), or bounce to `queue` for ACs that under-sample their FRs? And how far does the class
sweep reach — the files the AC touches, or every member of the class in the package? The owner's
requirement above is settled; only these two are open.

## Acceptance criteria

To be written by design.

## Notes & decisions

- 2026-10-09 — Filed by retro, merging two tools `FINDINGS.md` entries (2026-10-07, 2026-10-08) that
  share one cause. quantum-catan 0009 is the follow-up the PASS reading produced.
