---
id: "0085"
title: Collapse the backlog protocol from a third of every session's turns to one command per stage boundary
type: debt
next: design
status: in-progress
qa_level: verify
size: l
created: 2026-09-02
source: agent
parent:
blocked_by: []
relates: ["0047", "0048", "0066", "0073", "0081", "0036"]
expects:
  - skills/develop/SKILL.md
  - skills/verify/SKILL.md
  - skills/queue/SKILL.md
  - references/CONCURRENCY.md
  - .claude/backlog/claim
  - .claude/backlog/close
  - .claude/backlog/next
claimed_by: "6983"
claimed_at: 2026-09-02T04:49:52Z
touches:
---

## Problem

**The backlog protocol costs more turns than the work it protects.** `0073` classified all 1,112
turns of the pinned run by their tool calls, and the figures are in `MEASUREMENT.md`, *Where a
session's turns go*:

| Category | Share of every turn in the suite |
|---|---|
| `mechanism` — the backlog protocol and the git bookkeeping around it | **41.9%** |
| `work` — changing the thing under change, and running a test | 34.0% |
| `orientation` — the skill file, the conventions, the ticket | 15.7% |
| `other` | 4.6% |
| `narration` — a turn that called no tool | 3.8% |

81.8% of the mechanism turns are the protocol itself rather than git, so **34.3% of every turn in
the suite is the backlog protocol** — about 12.8 turns of a develop session's 38.6, and 14.9 of a
verify session's 38.4, against **three durable acts a session actually performs: claim, hand off,
close.** `verify` spends 49.5% of its turns here.

Where those turns go, as a share of the mechanism turns: 22.3% the `claim`/`close`/`next` scripts,
20.0% the lock, 19.3% `QUEUE.md`, 20.2% `DONE.md`/`FINDINGS.md`/`RANKING.md`/`config.yml`, 15.7% git
inspection, 2.6% git writes.

**This ticket exists because the obvious answers are measured and wrong.** Cutting narration reaches
3.8% of turns. Trimming the skill files reaches `orientation` at 15.7% of turns, and every word this
project controls is 10.2% of a session's end-of-session context, so halving all of it buys about 5%.
`0035` reached the same conclusion from the other side, on the cost arithmetic: relocation to a
pointer file does not pay below a ~20,000-byte block. The lever is the number of turns the protocol
takes, and nothing else measured comes close.

Aaron's standing instruction of 2026-08-30 — token efficiency until the sessions are slimmed and
orchestrated — is what this ticket serves, and `MEASUREMENT.md` now carries the turn budget it is
judged against: develop 30, verify 28, queue 28, design 20, retro 22, due **2026-10-31**.

## Why this is `next: design` and not `develop`

There is a real decision under it, and it is the one thing `0073` was careful not to guess: **what
a single command per stage boundary may do on a session's behalf without weakening what the protocol
protects.** Claim, hand-off and close each currently interleave a lock, a `QUEUE.md` edit, a
frontmatter write, a commit and a read-back, and the protocol's rules exist because each of those
failed once — `CONCURRENCY-INCIDENTS.md` holds the incidents. A batching that swallows the read-back
buys turns by removing the check that made the claim durable.

So the decision to settle first: **which of the protocol's steps are separable turns because a
session needs to see the result, and which are only separate because nobody scripted them together.**

## Functional requirements

- FR1 — Decide, per stage boundary (claim, hand off, close), **the minimum number of turns that
  boundary can take while every rule in `CONCURRENCY.md` still holds**, and record the decision with
  the rule each retained turn exists for.
- FR2 — Name the protocol turns that exist only because nothing scripted them together, and route
  each to the ticket that scripts it: `0081` for the hand-off, `0048` for the remaining write sites,
  `0047` for the busy lock's close-time path, `0066` for the three wrong answers. **This ticket does
  not re-do their work** — it gives them a shared target and closes the gaps none of them covers.
- FR3 — Address the **lock** specifically: 20.0% of mechanism turns, and the largest single line in
  the composition after the scripts themselves. State whether a session should ever see the lock as
  its own turn.
- FR4 — Address the **`QUEUE.md` reads**: 19.3% of mechanism turns, against a rule that already says
  to read it with `./next` rather than by eye. Decide whether the rule is unfollowed, insufficient,
  or being paid twice.
- FR5 — State the **expected turn saving per stage** before the change, and the measurement that
  will confirm or refute it — the same script, the same pin. `0009` modelled a 66% saving and
  observed 14.5%; a prediction recorded up front is what makes that visible instead of arguable.
- FR6 — Leave `git` alone, or say explicitly why not. 15.7% of the mechanism turns are git
  inspection that any project pays; it is not this backlog's cost and is out of the 34.3% figure.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Correctness | No rule in `CONCURRENCY.md` is weakened to buy a turn. A batching that removes a read-back removes the check that made a claim durable, and each of those checks has an incident behind it. | `CONCURRENCY-INCIDENTS.md` |
| Measurement | The saving is predicted before the change and re-measured after with `tools/classify-turns.sh` against a pinned set, and the verdict is recorded whichever way it comes out. | `measurement-conventions.md` |
| Testing | Every script change lands with the guard first, and the existing `claim`/`close`/`next` suites stay green. | `testing-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given the decision record, when read, then it states for each of the three stage
      boundaries the minimum turn count and, per retained turn, the `CONCURRENCY.md` rule it serves.
- [ ] AC2 — Given the decision record, when read, then every protocol turn it calls removable names
      the backlog id that removes it, and no removal is left unowned.
- [ ] AC3 — Given the decision record, when read, then it states the predicted turns-per-session
      figure per stage against the budget in `MEASUREMENT.md`, and the command that will test it.
- [ ] AC4 — Given the lock and the `QUEUE.md` read, when the record is read, then each has an
      explicit verdict rather than being folded into a general statement about mechanism.
- [ ] AC5 — Given `tests/claim.test.sh`, `tests/close.test.sh` and `tests/next.test.sh`, when run
      after any change this ticket makes, then all three are green.

## QA plan

- **Level:** verify — the deliverable of this ticket is a decision and a routing of work to existing
  tickets. The script changes it hands off are guarded by their own tickets' suites.
- **Specific checks:** the three script suites green; the decision record's claims read against
  `CONCURRENCY.md` rule names, since a retained turn justified by a rule that does not exist is the
  likely failure.

## Out of scope

- **The reduction to the skill files.** Measured at 10.2% of context for all of this project's prose,
  and `0035` already recorded the arithmetic against relocation. If it is done at all it is done for
  clarity, not for tokens, and it is a different ticket.
- **Cutting narration.** 3.8% of turns. `0074` already decided what a stage tells the human.
- **Orchestration.** `0036` and its slices are the other half of Aaron's instruction and are ranked
  on their own.
- **Re-measuring the fresh project.** That is `0037`.

## Notes & decisions

- Opened by `0073` under its FR5, which required the measurement to name the largest category and
  open the reduction ticket rather than make the reduction itself.
- **The counter-intuitive finding worth keeping:** every theory anyone held before the measurement
  aimed at what a session *says* or *reads*. Narration is 3.8% of turns and this project's whole
  prose is 10.2% of a session's context. The weight is in what the sessions *do* to keep the backlog
  safe for two writers, and that is a design cost, not a verbosity one.
