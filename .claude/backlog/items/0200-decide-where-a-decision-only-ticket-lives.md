---
id: "0200"
title: Decide where queue puts an owner decision that blocks several tickets and builds nothing
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
relates: []
expects:
  - skills/queue/SKILL.md
claimed_by:
claimed_at:
touches:
---

## Problem

Parked 2026-10-08 from quantum-catan's UI capture: six owner decisions (chat, idle-turn rule, identity,
call-back, odds wording, component library) each needed a home. A `next: design` ticket must leave
design with FRs and ACs, which a decision-only ticket does not have, and `waiting` needs a ticket to
hang on. The session folded each decision into the open design question of the first ticket it blocks
(quantum-catan 0013 *Notes*). That works, but a decision shared by two tickets hides in one of them.

## Open design question

Should `queue` Step 2 ("Set next now") name this case — keep folding into the first blocked ticket
and cross-reference from the others, or allow a decision-only row that `design` closes with a decision
record instead of ACs? One instance so far; decide whether it earns a rule at all.

## Acceptance criteria

To be written by design.

## Notes & decisions

- 2026-10-09 — Filed by retro from the tools `FINDINGS.md` entry of 2026-10-08.
