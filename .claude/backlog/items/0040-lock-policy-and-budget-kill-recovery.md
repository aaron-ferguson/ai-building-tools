---
id: "0040"
title: Harden the supervised loop against a held lock and a budget-killed stage
type: feature
next: develop
status: blocked
qa_level: unit
size: m
created: 2026-08-25
source: agent
parent: "0036"
blocked_by: ["0039"]
expects:
  - skills/orchestrate/SKILL.md
  - tests/orchestrate.test.sh
  - .claude/backlog/config.yml
  - skills/queue/templates/config.yml
claimed_by:
claimed_at:
touches:
---

## Problem

0039 delivers a loop that launches stage processes unattended. Two of its failure modes strand the
whole repository, and 0036's first draft mentioned neither.

**The lock.** `claim` and `close` take `.claude/backlog/.lock/`, and the supervisor's entire job is
launching processes that take it. **A stage killed holding the lock blocks every future claim and
close in the repo** — not just the run's. Two entries already in `FINDINGS.md` say the busy-lock
procedure strands a close and that the protocol cannot be satisfied by hand. Nothing in 0039 says
what the supervisor may do about a lock, and the tempting answer — break it and carry on — has a
driver silently stealing a lock from a stage that is still working.

**The spend cap.** `--max-budget-usd` is the blast-radius control AC19 requires, and it **creates**
the nastiest failure in the design: a stage killed mid-work leaves a claim held, a tree dirty,
possibly the lock taken, and a ticket half-built. 0039's AC16 covers the *supervisor* being killed,
which is a different and easier case — there the tree is clean. **Orphan detection is not enough on
its own: a dirty tree is not something `./next --drift` can see.** And the cap itself, guessed
rather than derived, is the thing that fires: this repo's observed figures are **$4.45–$6.01 per
closed ticket** (`MEASUREMENT.md`), so a gate of three tickets under a $1 cap is a stage killed by
arithmetic on its first run.

This is hardening on a loop that has to exist first, which is why it is the third slice rather than
folded into 0039.

## Functional requirements

**FR numbers are 0036's**, kept rather than renumbered so the review amendment in the parent still
resolves.

- **FR15 — The lock has a policy, and the supervisor never breaks it.** The supervisor takes the
  lock **never**, breaks it **never**, and **escalates on a lock older than a stated age**, naming
  the process that should have held it from 0039's FR10 log and dispatching nothing. The age is a
  key in `config.yml`, alongside the findings threshold, so it is one place rather than a number
  inside a skill.
- **FR16 — A stage killed by its own spend cap is a recoverable state, not a discovered one.**
  Three parts, each of which is a way for the cap to make things worse rather than safer:
  - **The cap is set from `cost_tracking:` history rather than guessed** — per stage and per gate
    size — and **the derivation is stated where the number is**, so the next person to change it
    knows what it was derived from rather than rounding it.
  - **An over-budget exit is one of the escalations**, routed like any other rather than read as a
    crash.
  - **The escalation names the claim token, the dirty paths and the lock state.** A human following
    it needs no information that exists only in the dead stage's transcript.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Security | The recovery path acquires no authority the loop did not already have: the supervisor does not remove a lock, does not release another session's claim, and does not clean a working tree it did not dirty. Every one of those is a human's action, and the escalation is what hands it over | `security-conventions.md` |
| Observability | The escalation lands on disk with a timestamp before it reaches the user, carrying the claim token, the dirty paths and the lock's age and holder. The supervising conversation is what dies; an escalation that reached only the transcript is unrecoverable | `observability-conventions.md` |

## Acceptance criteria

**AC numbers are 0036's.**

- [ ] **AC25 — the supervisor never takes or breaks the lock.** Given a run at any point, when
  `.claude/backlog/.lock/` is inspected, then it was never created by the supervisor and never
  removed by it. **Given a lock older than the configured age with no live stage process**, when
  the supervisor acts, then it escalates, naming the lock's age and the process from the FR10 log
  that should have held it — and dispatches nothing. **Given a lock younger than that age**, then
  it waits rather than escalating, because a lock in use is the normal case and it is held for
  seconds.
- [ ] **AC26 — a stage killed by its spend cap leaves a state the escalation describes.** Given a
  stage dispatched with a cap it exceeds mid-work, when it is killed, then the supervisor escalates
  with the ticket's claim token, the dirty paths and the lock state named — and starts nothing
  further. Given that escalation, when a human follows it, then no information needed to recover is
  only in the dead stage's transcript. **And the cap itself is derived, not guessed:** it is set
  from `cost_tracking:` history for the stage and gate size, and the derivation is stated where the
  number is.

## QA plan

- **Level:** unit — this project's suite is the shell scripts in `tests/`, each self-contained
  (`config.yml`).
- **Why this level:** both requirements are about *state on disk that the supervisor reads and
  refuses to change*, and disk state is exactly what a fixture is. A stale `.lock/` directory with
  a written `held-by`, a claimed row whose process is gone, and a dirty tree are all constructible
  in a test; nothing here needs a real budget kill to exercise the response to one.
- **Specific checks:** the whole suite (`for t in tests/*.test.sh`), and specifically —
  - **An aged-lock fixture and a fresh-lock fixture** (AC25), asserting escalate-and-dispatch-
    nothing in the first and wait in the second, plus an assertion that no code path in
    `skills/orchestrate/` removes `.lock` — a scripted grep, matched on a phrase short enough to
    stay on one line.
  - **A killed-stage fixture** — claim held, tree dirty, lock taken — asserting the escalation text
    names all three (AC26).
  - **A derivation assertion**: the cap in `config.yml` is accompanied by the `cost_tracking:`
    figures it was derived from, so a bare number fails (AC26).
  - **The pre-existing suite unchanged**, since nothing here alters what a hand-driven session does.

## Out of scope

- **Recovering the state itself** — releasing the claim, cleaning the tree, removing the lock.
  Every one of those is a human's action; this ticket makes the escalation sufficient to take it.
  Automating recovery is a separate decision, and the Security NFR is why.
- **Changing `claim`, `close` or the lock protocol.** The supervisor lives with the lock as built.
  If the protocol itself needs to change, that is a ticket against `CONCURRENCY.md`, not this one.
- **Setting the cap** — 0039's AC19 does that. This ticket makes it *derived* rather than guessed,
  and owns what happens when it fires.
- **Concurrent stage sessions**, which would make the lock a contention problem rather than a
  stranding one. Out of scope for the whole project; see 0036.

## Notes & decisions

- **The reasoning behind both requirements is in
  `items/0036-orchestrate-the-stage-sessions.md`, *Notes & decisions*, review amendment of
  2026-08-24** — the four things nobody had thought through — and is not restated here.
- **Third of three slices, and it stays third.** Both requirements are responses to a loop's
  behaviour, and neither is testable before the loop exists. But it should not be allowed to drift:
  0039 shipped without this is a runnable unattended loop with no lock policy, which is exactly the
  hazard FR15 exists for. It is ranked directly below 0039 for that reason and not merely by
  dependency order.
