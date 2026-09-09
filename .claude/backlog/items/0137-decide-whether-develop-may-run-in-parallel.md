---
id: "0137"
title: Decide whether two develop sessions may run at once, and in what isolation
type: feature
next: design
status: ready
qa_level: verify
size: l
created: 2026-09-09
source: user
parent: "0128"
blocked_by: []
relates: ["0050", "0054", "0059", "0134", "0136"]
expects:
  - skills/orchestrate/SKILL.md
  - references/CONCURRENCY.md
  - .claude/backlog/next
claimed_by:
claimed_at:
touches:
---

## Problem

Aaron, 2026-09-08: *"Orchestrate is welcome to run as many develop sessions at once as it feels
appropriate while avoiding potential conflicts with other agents."* Deferred the same day, after the
cost and safety analysis below, and recorded here rather than dropped.

**Parallel develop buys wall-clock and spends the two things this project ranks above it.** The
stated priority order is quality, then cost, then time. N parallel sessions each re-pay the roughly
20k-token startup floor, so they cost strictly more than the same N tickets sequentially and more
again than one gate holding all N — the saving the suite is built on. It buys only time.

**Three specific hazards, none of them hypothetical:**

- **The conflict predicate is a field the code labels unreliable.** `next`'s own comment: `touches:`
  is the claim verified against the code, while `expects:` is *"the prediction the ticket was written
  with"*. Only the prediction exists before dispatch.
- **Gates are not currently disjoint from each other** — `0136`, which is why this row is blocked on
  it. Dispatching two gates in parallel on today's partition can put two sessions in one file.
- **One working tree, one git index.** `CONVENTIONS_CORE.md` forbids `git add .` precisely because
  *"the index is one shared staging area"*. `config.yml` already records this biting with only
  hand-driven concurrency: verifying `0084`, another session's in-flight work reddened the
  alphabetically-first of seventeen guards and the fail-fast loop meant the guard that verdict rested
  on never ran.

The candidate that makes it sound is **one git worktree per parallel session**, which isolates the
code tree while leaving `.claude/backlog/` shared — and shared is correct there, since `claim`,
`close` and the lock are built for it. That is a subsystem, not a flag.

## Open design question

- **Question:** May two develop sessions run at once, and what isolates their working trees? The
  candidates: **a worktree per session**, with a defined lifecycle and a merge path back; **one tree
  with a stricter, verified scope predicate**, which requires something better than `expects:` before
  dispatch; or **no parallel develop**, keeping the gate as the only concurrency and treating
  wall-clock as the axis that varies.
- **Why it blocks specification:** the acceptance criteria are incompatible. A worktree answer needs
  a lifecycle, a merge protocol, and a statement of what happens when two worktrees both run the
  suite. A stricter-predicate answer needs a definition of verified scope that does not exist. The
  third is prose plus a deliberate non-goal. And there is a prior question the answer turns on:
  whether the suite can be run in two worktrees at once at all, given every guard greps the repo's
  own prose files.
- **Settle it with:** `/design` — the inputs are `references/CONCURRENCY.md`, the `0084` incident in
  `config.yml`, `0136`'s partition, and what `git worktree` costs to set up and tear down.

## Functional requirements

Written after the design question is settled. What is fixed regardless:

- FR1 — Whatever shape is chosen, the skill states the priority order it was chosen under, so a later
  reader does not re-open it on wall-clock grounds alone.
- FR2 — If parallelism is permitted, the rule names what a session does when it discovers another is
  working the same file — the case `0054` covers for a shared dirty tree.
- FR3 — If parallelism is declined, that is recorded as a decision with its reasoning, not left as an
  absence.

## Acceptance criteria

Cannot be written until the design question is settled.

## Out of scope

- Design sessions running in parallel — already permitted by `0134` on the ground that they split no
  shared context.
- The gate partition defect — `0136`.

## Notes & decisions

- **2026-09-09 — deferred, not dropped, at Aaron's direction after the analysis above.** Ranked low
  deliberately: it is the one child of `0128` whose value is wall-clock, which is the axis this
  project is explicitly willing to let vary.
- **2026-09-09 — `0136` is a relation, not a blocker.** It was first written as `blocked_by`, which
  `./next --drift` correctly reported against the row. The block was wrong in substance too: the
  design question can be *decided* on today's partition, and it is only an implementation of
  parallel dispatch that must not ship over a partition that can put two gates in one file. Blocking
  the decision on the fix would have stalled the cheaper half behind the more expensive one.
