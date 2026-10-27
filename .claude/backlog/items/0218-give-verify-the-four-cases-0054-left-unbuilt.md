---
id: "0218"
title: Give verify the four dirty-tree cases 0054 carried in its notes and did not build
type: chore
next: queue
status: ready
qa_level: verify
close_by: verify
qa_manual:
size: s
created: 2026-10-27
source: agent
parent:
blocked_by: []
relates: []
expects:
  - skills/verify/SKILL.md
claimed_by:
claimed_at:
touches:
---

## Problem

Filed by retro 2026-10-27 (tail of run-20261025T215324Z), from a FINDINGS.md park.
0054 built its seven FRs and closed; four cases its retro-absorbed *Notes & decisions* carry were never FRs, so the close buried them (develop 0054, 8705). Source: `.claude/backlog/items/0054-verdicts-over-a-shared-dirty-tree.md` *Notes & decisions*.

## Established, not yet specified

- (1) `verify` Step 7 should re-take the dirty-set label immediately before `./close`, not trust Step 2's snapshot — 0085 FR7's "clean throughout or Step 2 said so" was falsified mid-pass.
- (2) Step 7's fresh-read promise does not separate *they reverted / moved to a worktree* from *I destroyed their work*; the discriminator is the session's own command log.
- (3) A repo-wide guard, and a path an NFR cites only for documentation, should not widen the advisory evidence set on the same terms as an executed path.
- (4) A backgrounded mutation sweep must run in a worktree: its `git checkout` lands on the foreground's uncommitted edits.

## Notes & decisions
