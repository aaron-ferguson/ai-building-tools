---
id: "0236"
title: Decide whether design may amend unheld sibling items its own FRs name
type: chore
next: design
status: ready
qa_level: verify
close_by: verify
qa_manual:
size: s
created: 2026-11-18
source: agent
parent:
blocked_by: []
relates: []
expects:
  - skills/design/SKILL.md
  - skills/queue/SKILL.md
  - references/CONCURRENCY.md
claimed_by:
claimed_at:
touches:
slice:
---

## Problem

A consuming project's design ticket (written by `queue`) carried "FR4 — amend items B and C to
match, restamp their `ac_digest` in the same commit as the decision". `references/CONCURRENCY.md`,
*A stage writes only the ticket it holds*, forbids it, and `./claim` cannot take B or C (both
`blocked`). The session wrote B and C under the backlog lock after confirming both had empty
`claimed_by:` — the *unheld* test `retro` uses — in one commit with the decision. Handing the edits
back to `queue` costs a round trip and splits the decision from its consequences.

## Open design question

Either name a second narrow exception in *A stage writes only the ticket it holds* (unheld, non-done
items named in the held item's own FRs, under the lock, in the decision's commit), or have `queue`
stop writing FRs that amend other items. Which?

## Functional requirements

- FR1 — Whichever is chosen is stated in `references/CONCURRENCY.md` and in the skill it binds
  (`design` Step 4 or `queue` Step 2), and the other skill does not contradict it.

## Notes & decisions

- 2026-11-18 (retro) — filed from a consuming project's finding. Its other half (a decision-only
  ticket hands to `verify`) landed in `skills/design/SKILL.md` Step 4 the same day.
