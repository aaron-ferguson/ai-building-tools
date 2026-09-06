---
id: "0103"
title: Decide whether the backlog scripts may share a sourced file
type: debt
next: design
status: ready
qa_level: verify
size: m
created: 2026-09-05
source: agent
parent:
blocked_by: []
relates: ["0048", "0090"]
expects:
  - skills/queue/templates/next
  - skills/queue/templates/claim
  - skills/queue/templates/close
  - skills/queue/templates/handoff
  - skills/queue/SKILL.md
  - tests/backlog-scripts-installed.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

**The install contract caps how DRY the backlog scripts can be, and nothing says so.**

`0044` FR2 asked for one `decomment`, *"shared rather than copied a third time"*; the answer had to
be its fallback clause instead. `queue` Step 0 scaffolds a backlog by copying each template into
`.claude/backlog/`, and `tests/backlog-scripts-installed.test.sh` names the installed set
(`SCRIPTS="next claim close handoff"`, `:28`) and forces each **byte-identical** to its template. So
a fifth file the scripts *source* is possible, but it is a change to the install contract, to the
scaffold step and to that guard's `SCRIPTS` list — not a refactor.

The result is one copy of `decomment` per script rather than one per reader, held in step by a
comment in each saying *"change one, change both"*. That was fine at two. It is now in **three**
scripts — `next`, `close` and `handoff` — which is exactly the third instance `coding-conventions.md`'s
Tier-2 rule fires on, and `0081` added the third copy without the trigger being noticed, because the
constraint that forced it is recorded in a findings entry rather than anywhere a session reads.

`0090` is about to edit all three copies of a different shared shape for the same reason.

## Open design question

- **Question:** may the installed backlog scripts source a shared file — and if so, what does the
  install contract become: how does `queue` Step 0 scaffold it, what does
  `tests/backlog-scripts-installed.test.sh` enforce, and what happens to a backlog installed before
  the shared file existed?
- **Why it blocks specification:** the two answers produce opposite artifacts. *Yes* means a new
  file, a changed scaffold step, a changed guard and a migration story for existing backlogs — every
  acceptance criterion is about the install contract. *No* means the duplication is a **recorded,
  justified** exception to the Tier-2 rule, and the criteria are about where that justification lives
  and what would expire it. Nothing can be written until it is chosen.
- **Settle it with:** `/design`. The inputs are the guard, `queue` Step 0, `coding-conventions.md`'s
  Tier-2 rule and this repo's own install-versus-checkout hazard in `CLAUDE.md` — all readable.
  Nothing needs to be seen.

## Functional requirements

- FR1 — The decision is recorded in this item's *Notes & decisions* with its reasoning, and the
  design pass adds the FRs it unblocks.
- FR2 — Whichever way it goes, the constraint stops living only in a findings entry: it is stated
  where a session adding a fourth script or a third copy of a helper will read it — `queue` Step 0
  and the guard's own header are the two candidates.
- FR3 — The ruling names its expiry condition, so a later session can tell a live decision from a
  stale one.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Migration / schema | If the answer is *yes*, an existing `.claude/backlog/` installed without the shared file must keep working or be repaired by the scaffold step — a backlog in another project is data this repo cannot reach | `migration-conventions.md` |
| Documentation | FR2's home is chosen so the constraint is read *before* the duplication is written, not after | `documentation-conventions.md` |

## Acceptance criteria

*Written by the design pass. FR3 is the one criterion that holds either way: the ruling carries an
expiry condition.*

## Out of scope

- **Which** write sites become scripts — that is `0048`, and this item takes the current four as
  given. The two are worth reading together: a session settling `0048` is deciding how many scripts
  there will be, which is the input to how much duplication there is.
- The four contract gaps in `0090`. That item edits three copies deliberately rather than waiting on
  this decision, so that a fail-open path is not held open by a refactoring question.
- The plugin's release chain, which is `0084` and already closed.

## Notes & decisions

- Routed to `design` on trigger 1. The Tier-2 trigger has already fired — three copies of
  `decomment` — so the question is not whether the rule applies but what the install contract
  permits, and that is a decision with two coherent answers.
- `size: m` because the *yes* branch changes the scaffold step, the guard and a migration story for
  backlogs this repo does not own; the *no* branch is small. Sized for the expensive branch.
