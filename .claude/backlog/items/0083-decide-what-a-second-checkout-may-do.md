---
id: "0083"
title: Decide what a second checkout may do with the backlog
type: bug
next: design
status: ready
qa_level: unit
size: m
created: 2026-09-01
source: retro
parent:
blocked_by: []
relates: ["0081", "0082"]
expects:
  - references/CONCURRENCY.md
  - references/CONCURRENCY-INCIDENTS.md
  - skills/develop/SKILL.md
  - skills/verify/SKILL.md
  - skills/queue/templates/claim
claimed_by:
claimed_at:
touches:
---

## Problem

**The backlog lock is per-checkout, and nothing detects a second checkout.** `.claude/backlog/.lock/`
is a directory *inside the working tree*, so two clones — or two `git worktree`s — each get their own
lock **and their own `QUEUE.md`**. `./claim` would grant the same row twice with no warning, because
neither invocation can see the other's status cell. `CONCURRENCY.md`'s *A claim must be durable the
moment it is made* is written as though one tree is a given.

**What makes this worth settling now rather than after it bites: two skills actively send sessions into
worktrees.**

- `develop` Step 5 recommends a throwaway worktree for isolating a red that may not be yours, and for
  the deterministic/flaky discrimination.
- `verify` Step 2 — **as of 2026-09-01** — prescribes verifying a named commit in a worktree at
  `qa_level: e2e`, because the advisory intersection can never be empty there.

Both are correct and both are new load on an undefined rule. The 2026-09-01 retro used a worktree three
times in this repo, once to establish that a suite red was tree pollution rather than its own defect.

Today the hazard is **latent, not live** — AetherWorks is one checkout, and its two configured working
directories are the same inode on a case-insensitive volume.

## Open design question

**Do the scripts refuse outside the primary checkout, or does the rule simply say a worktree may run
tests and must never claim, close or hand off?**

1. **Refuse mechanically.** `claim`/`close`/`handoff` detect a linked worktree (`git rev-parse
   --git-common-dir` differing from `--git-dir`) and refuse. Cannot be forgotten; but a second *clone*
   is not a worktree and looks primary to this test, so it catches the case the skills create and not
   the case a person creates.
2. **State the rule and let the scripts stay ignorant.** One sentence in `CONCURRENCY.md`, cited by the
   two skills that send sessions into worktrees. Costs nothing, catches both cases, and fails open.
3. **Both**, with the mechanical check as defence in depth for the shape the tools themselves produce.

Also to settle: **whether `.lock/` should live outside the tree at all** — a lock keyed on the repo's
common git dir would be shared by every worktree of one clone, which would make option 1 unnecessary
for worktrees while still not covering a second clone.

## Functional requirements

*(Completed by the design stage.)*

1. A session in a linked worktree cannot silently claim, close or hand off a row.
2. `develop` Step 5 and `verify` Step 2 state what their prescribed worktree may and may not do, at the
   point they prescribe it.
3. `CONCURRENCY.md` defines it once; the skills cite it.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | Stated once and cited, not restated in three skills. | `documentation-conventions.md` |
| Testing | Any mechanical check is proved able to fail from inside a real linked worktree, not from a simulated path. | `testing-conventions.md` |

## Acceptance criteria

*(Written by the design stage.)*

## QA plan

- **Level:** unit — this repo's whole suite; a mechanical check would extend `claim.test.sh` with a
  case that adds a real `git worktree` and claims from it.

## Out of scope

- Moving the backlog out of the working tree, or to a shared service. A much larger change than the
  hazard warrants.

## Notes & decisions

- Recorded in AetherWorks' buffer 2026-08-25 (item 0051), and re-raised 2026-09-01 when `verify` gained
  a second worktree prescription.
