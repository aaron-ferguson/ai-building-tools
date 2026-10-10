---
id: "0203"
title: Decide where the one model pricing table lives that cost-by-category.sh and harvest-usage.sh both read
type: bug
next: design
status: ready
qa_level: unit
close_by: verify
qa_manual:
size: s
created: 2026-10-10
source: agent
parent:
blocked_by: []
relates: ["0192"]
expects:
  - tools/cost-by-category.sh
  - tools/harvest-usage.sh
claimed_by:
claimed_at:
touches:
---

## Problem

Filed by retro 2026-10-10 from a park in this repo's buffer. `tools/cost-by-category.sh` keeps its
own `RATES` and `CACHE_READ_MULT` (line ~96) and they already disagree with `harvest-usage.sh`:
`claude-sonnet-5` at 3.00/15.00 against harvest's 2.00/10.00, and no `claude-opus-5-5` or its 0.05x
cache-read multiplier. One concept defined twice, which is the divergence `sprint-ledger.sh`'s
`harvest()` shells out to avoid. 0192's amend put this out of its scope.

## The decision

Where the single table lives: (a) a shared data file both scripts read; (b) `cost-by-category.sh`
shells out to `harvest-usage.sh` for prices, as `sprint-ledger.sh` already does; (c) retire
`cost-by-category.sh` if nothing still needs it. Recommendation from the retro, unverified: (b),
because it reuses a pattern already in the repo. Acceptance criteria follow the decision.

## Notes & decisions
