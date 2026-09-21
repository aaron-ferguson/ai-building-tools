---
id: "0175"
title: Decide what identifies a sprint across a suspension, and which mechanisms key off it
type: debt
next: design
status: ready
qa_level: verify
size: l
created: 2026-09-21
source: agent
parent:
blocked_by: []
relates: ["0164", "0153", "0152"]
expects:
  - skills/sprint/SKILL.md
  - tools/sprint-ledger.sh
  - tests/sprint.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

**A sprint that spans two days is a normal use case, and four separate mechanisms in `sprint` assume
one continuous run.** `run-20260920T222013Z` was interrupted three times — an account session limit
resetting, then the background wrapper's 600 s ceiling, then the host sleeping mid-response twice —
and resumed across a date boundary. What broke, or would have:

1. **The cap formula.** Step 7 caps a resumed leg at the stage cap less what a harvest already shows
   spent. Every resume re-pays the session's context floor, so the remainder shrinks toward zero
   while the unfinished scope does not: at the third resume the formula gave USD 3.21 for two
   untouched tickets against a two-ticket price of 9.08, and obeying it would have fired mid-verify.
   The floor is a cost of *being interrupted*, not of scope, and nothing subtracts it.
2. **The supervisor marker.** `.active/held-by` is kept fresh by a heartbeat living inside one Bash
   call, and `lock_stale_seconds` is 900 s — so any overnight gap ages the marker out and a
   supervisor resuming its own run next morning reads its own marker as a stale one to take over.
3. **`sprint_ended` and the findings gate.** One interrupted sprint resumed later is one sprint, and
   nothing says so: writing the event at each halt inflates `findings_max_sprints` on a technicality;
   writing it once means a run that never resumes is never counted. This run wrote it once, by hand,
   on the supervisor's judgment.
4. **The ledger.** `record` appends one block per invocation and derives wall-clock from the first
   and last event timestamps, so an overnight gap books as work time and a second invocation
   double-counts the run. `0164` covers the elapsed/active split but not the re-invocation.

## Open design question

**What identifies a sprint across a suspension, and which of the four mechanisms key off that
identity rather than off the process?**

- **Question:** is a suspended-and-resumed run one sprint under one identity — and if so, what
  writes and clears that identity, given the supervisor process is gone between legs?
- **Why it blocks specification:** every mechanism above has a different fix depending on the
  answer. A cap formula that re-grants the context floor per leg needs a leg count; a marker that
  survives a gap needs a resumable identity rather than a liveness heartbeat; `sprint_ended` needs
  to know whether a halt is terminal; the ledger needs an idempotent `record`. None can be specified
  until the identity is.
- **Settle it with:** `/design`

Constraints: `0153` owns the marker's liveness signal and `0164` the elapsed/active split — this
ticket settles the identity those two build against, and must not re-decide either.

## Out of scope

- Preventing the interruptions. They are the environment, not a defect.
- Re-opening `findings_max_sprints` as the right second limit, which `config.yml` argues.

## Notes & decisions

- **2026-09-21 (retro)** — Filed from a park written by the supervisor of
  `run-20260920T222013Z`, which had hit all four in one run. Routed to `design` on the noticer's own
  framing: it is a design question before it is a defect.
