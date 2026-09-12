---
id: "0134"
title: Dispatch a sprint's design sessions alongside develop instead of stopping for them
type: feature
next: design
status: in-progress
qa_level: verify
close_by: verify
size: m
created: 2026-09-09
source: user
parent: "0128"
blocked_by: []
relates: ["0050", "0137"]
expects:
  - skills/sprint/SKILL.md
  - tests/sprint.test.sh
claimed_by: "d08c"
claimed_at: 2026-09-12T21:07:46Z
touches:
---

## Problem

**A `next: design` row is exit code 4 and stops the run.** On the 2026-09-09 backlog it is also
where the queue runs dry: *"runs dry at 0080 (next: design — a person decides)"*, with nine further
design rows below it. A sprint that needs one of them stops, a person answers, and the run is
restarted — even though the design session was going to be its own session either way.

**Parallel *design* is a different proposition from parallel *develop*, and the difference is
where the cost is.** `0137` declines parallel develop because splitting work that could have shared
one session's context re-pays the roughly 20k-token startup floor per split — it spends tokens to buy
wall-clock, inverting the priority order. A design session pays that floor whether it runs
concurrently or after. Running it alongside splits nothing, so it is **token-neutral and
time-positive**, which is the only shape of parallelism this project's priorities permit.

**Its conflict surface is also much smaller.** `design` writes an item file and a `QUEUE.md` row,
both already protected by the lock and the claim scripts; it does not touch the code tree, which is
the thing two develop sessions cannot share. `0050` — how file scope works when the prose files are
the product — remains the open question for the *general* case, and this ticket does not answer it;
it stays inside the case where the two sessions touch disjoint kinds of file.

**The risk that is real is scope movement.** A design decision can widen its ticket's `expects:`. If
that widened scope then overlaps a running develop gate, the follow-on develop simply waits, which
is correct. What is not correct is the sprint silently absorbing the newly-unblocked ticket into a
scope a person already confirmed — the estimate they approved would no longer describe the run.

## Functional requirements

- FR1 — A sprint may run one or more `design` sessions concurrently with its develop session.
- FR2 — Design runs concurrently with **develop only**. It never runs alongside `retro` or `queue`,
  which rewrite the skills and scripts every other session is executing (`0133` FR5).
- FR3 — A design session is dispatched only for a ticket the confirmed sprint scope intends to
  develop. Speculative design for rows the sprint will not reach is not dispatched.
- FR4 — A design outcome feeds the **next** proposal, never the current commitment. A ticket
  unblocked mid-sprint is offered, not absorbed.
- FR5 — Two design sessions never hold the same ticket, and each claims its row through `claim` like
  any other stage.
- FR6 — The skill states that concurrency here is permitted because the sessions touch disjoint file
  kinds, and cites `0050` as the open general question rather than implying it is settled.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Performance | The claim is token-neutrality, and `0135`'s ledger records design cost per session under concurrent and sequential dispatch so the claim is checkable rather than asserted | `observability-conventions.md` |
| Documentation | The three guards and their reason are in the skill, since a later reader will otherwise generalise this permission to develop | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given a confirmed scope naming a `next: design` row and a develop gate, when the sprint
      runs, then both sessions are running at once and the design row's outcome does not stop the
      run. **Red if** the design row still returns exit 4 and halts, which is today's behaviour.
- [ ] AC2 — Given a sprint whose gate has been crossed, when the tail runs, then no design session
      is running during `retro` or `queue`. **Red if** FR2 is written as guidance rather than
      enforced at dispatch.
- [ ] AC3 — Given a `next: design` row outside the confirmed scope, when the sprint runs, then no
      design session is dispatched for it. **Red if** the sprint dispatches every takeable design
      row, which spends sessions on work it will not reach.
- [ ] AC4 — Given a design session that sets its ticket to `next: develop` mid-sprint, when the
      sprint continues, then that ticket is not added to the running gate and is named in the report
      as available for the next sprint. **Red if** it is absorbed — the confirmed estimate then
      describes a scope that no longer exists.
- [ ] AC5 — Given a design session and a develop session running together, when both write to the
      backlog, then each write is taken under the lock and both land. **Red if** either writes
      unlocked; the failure is silent and shows up as a lost row rather than an error.

## QA plan

- **Why that level:** the behaviour is a dispatch rule; no runner applies, and each criterion is
  checkable from a run log fixture plus `grep` assertions over the skill.
- **Specific checks:** a run-log fixture showing overlapping design and develop windows for AC1 and
  non-overlapping tail windows for AC2; `tests/sprint.test.sh` for FR2, FR3, FR4 and FR6 as stated
  rules; a two-writer fixture for AC5.

## Open design question

- **Question:** the Performance NFR requires this item's token-neutrality claim to be checkable
  from `0135`'s ledger, and that ledger cannot answer it — so does `0134` widen to build the
  instrumentation, ship the dispatch rule with the claim unmeasured, or drop the NFR?
- **Why it blocks specification:** the NFR is written as a statement of fact about a file this
  ticket does not own — *"`0135`'s ledger records design cost per session under concurrent and
  sequential dispatch"* — and `tools/sprint-ledger.sh` records per-session cost for `develop`
  (`GATE …`) and `verify` (`RATIO verify_usd_per_ticket …`) only. Nothing emits a design
  per-session figure, and nothing anywhere records whether a dispatch was concurrent or
  sequential, so the two cost populations the claim compares cannot be distinguished even in
  principle. `design` reaches that tool only through the regex reading `MEASUREMENT.md`'s
  per-skill table, which is the estimate side. The three answers are materially different work —
  widening `touches:` into another closed ticket's tool, versus accepting an unmeasurable claim
  against the core convention that *unmeasurable is unfinished*, versus narrowing the contract —
  and only the author may pick.
- **Settle it with:** `/design 0134`. FR1–FR6 and AC1–AC5 need no decision and no script change:
  they are buildable as written once this is answered.

## Out of scope

- Parallel develop sessions — `0137`.
- Deciding how file scope works when the prose files are the product — `0050`.
- Any change to what a `design` session does once dispatched.

## Notes & decisions

- **2026-09-09 — permitted after being challenged on the same ground that rejected parallel
  develop.** The distinguishing fact is that parallelism only costs tokens when it splits a shared
  context; a design session is separate either way, so nothing is re-paid. Recorded because the two
  cases look alike and the wrong generalisation is the expensive one.
- **2026-09-12 — handed back to design by the author on the Performance NFR, with no code written.**
  Two findings from the `develop` pass, both cheap to re-lose. **`expects:` was stale** — it named
  `skills/orchestrate/SKILL.md` and `tests/orchestrate.test.sh`, renamed by `0129`, which `claim`
  also flagged as two reserved paths that do not exist; corrected to the `sprint` names the QA plan
  already used. **The NFR's claim about `0135` is false**, per the *Open design question* above.
- **2026-09-12 — FR1 needs no change to `./next`, which is not obvious and is worth not
  rediscovering.** `--drive`'s rank walk steps over an `in-progress` row and then a held row
  *before* it reaches the `design)` escalate branch, so the whole mechanism is available to the
  skill alone: on exit 4 naming an in-scope design row, dispatch `/design <id>`, wait for that
  claim to land, then re-call `--drive` — which now steps past the held row and names the develop
  gate below it. Both sessions then run at once with `./next` untouched. **The ordering is
  load-bearing:** re-calling before the claim lands returns exit 4 on the same row a second time,
  and a supervisor that dispatches on it starts a second design session on the one ticket, which
  is exactly FR5's failure. So the supervisor must both wait for the row to read held and remember
  the ids it has already dispatched design for.
- **2026-09-12 — AC1's *"still returns exit 4 and halts"* is one criterion, not two.** Exit 4 on a
  design row is correct and stays; what FR1 changes is that it is no longer a halt. A pass reading
  the clause as *exit 4 must stop happening* will go looking for a `./next` change that this item
  does not want, and `Out of scope` does not say so because the script was never in scope to begin
  with.
- **2026-09-12 — Step 8's *"It never runs two stage sessions at once. The loop is sequential by
  decision"* is the sentence FR1 falsifies**, and no guard in `tests/` asserts it, so nothing will
  go red when it is rewritten. FR2, FR3 and FR4 are the three guards the Documentation NFR wants
  written in its place, and they need new assertions rather than amended ones.
