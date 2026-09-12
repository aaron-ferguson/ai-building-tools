---
id: "0134"
title: Dispatch a sprint's design sessions alongside develop instead of stopping for them
type: feature
next: develop
status: blocked
qa_level: verify
close_by: verify
size: m
created: 2026-09-09
source: user
parent: "0128"
blocked_by: ["0150"]
relates: ["0050", "0137"]
expects:
  - skills/sprint/SKILL.md
  - tests/sprint.test.sh
  - tools/sprint-ledger.sh          # widened by design 2026-09-12 — the DESIGN line (FR7, FR8)
  - tests/sprint-ledger.test.sh
  - .claude/backlog/LEDGER.md       # "How to read a block" gains the DESIGN line
claimed_by:
claimed_at:
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
- FR7 — Every `design` session a sprint dispatches carries its ticket id on its `dispatch` event,
  and `tools/sprint-ledger.sh record` writes one `DESIGN` line per such session: observed USD from
  `harvest-usage.sh` over that one session id, beside `MEASUREMENT.md`'s design per-session mean as
  the prediction — each side with its own source and stamp, as `GATE` does.
- FR8 — That line says `concurrent` or `sequential`, derived from the run log alone: `concurrent`
  when the design session's dispatch-to-outcome window intersects any `develop` session's window,
  windows paired by stage and ticket id. No new field is trusted from the supervisor for this.
- FR9 — Where a `next: design` row outside the confirmed scope outranks the scope's develop gate,
  the proposal names that row as where the run will stop, before the person confirms. The run still
  halts there; it is reported as the scope's edge, not dispatched for (FR3) and not refused.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Performance | The claim is token-neutrality, **declared before the build**: a concurrent design session costs no more than a sequential one. Checked from the ledger's `DESIGN` lines (FR7, FR8). Baseline is `MEASUREMENT.md`'s design mean — **n = 1 session, USD 2.32**, re-read 2026-09-12 — so it is a prior, not a control; the verdict is reported as counts, and read as *consistent with* until the ledger holds at least 5 concurrent design sessions | `measurement-conventions.md` |
| Guardrail | Supervisor spend per closed ticket (Step 8's figure, supervisor in the numerator) does not rise on sprints that dispatch design concurrently. The wait-for-claim loop the Notes require is where a hidden cost would live | `measurement-conventions.md` |
| Documentation | The three guards and their reason are in the skill, since a later reader will otherwise generalise this permission to develop | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given a confirmed scope naming a `next: design` row and a develop gate, when the sprint
      runs, then both sessions are running at once and the design row's outcome does not stop the
      run — including when that session ends by handing its row to `next: develop`. **Red if** the
      design row still returns exit 4 and halts, which is today's behaviour; or if the supervisor
      reports the finish as `--completed design:<id>`, which reaches `./next`'s `ESCALATE … which no
      routing rule covers` branch and stops the run by another door.
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
      backlog, then each write is taken under the lock and both land, the writer that finds the lock
      busy retrying rather than giving up. **Red if** either writes unlocked; the failure is silent
      and shows up as a lost row rather than an error. The fixture must model the retry: `./claim`
      refuses a busy lock rather than waiting on it, so two claims at once red on the refusal alone.
- [ ] AC6 — Given a run-log fixture with one design session overlapping a develop session and one
      that does not, when `record` runs over a fixture transcript, then the ledger block holds two
      `DESIGN` lines, one `concurrent` and one `sequential`, each with an observed and a predicted
      USD that carry their own source and stamp. **Red if** a design session produces no line —
      today's behaviour, since `record` emits only `GATE develop` and `RATIO verify`.
- [ ] AC7 — Given a design `dispatch` event with no matching `outcome`, when `record` runs, then
      that session's line reads `not measured` for concurrency rather than guessing either value.
      **Red if** an unpaired window is classified — a killed session would then enter the
      comparison as a data point it never was.
- [ ] AC8 — Given an in-scope `next: design` row that a dispatched design session has claimed, when
      the supervisor re-calls `--drive`, then it steps over that row and names the develop gate below
      it, and the supervisor dispatches no second design session for the same id. **Red if** the
      supervisor re-calls `--drive` before the claim lands and acts on the repeated exit 4 — FR5's
      failure. Observed 2026-09-12 in a scratch copy: a claimed design row prints
      `NOTE 0134 is in-progress — another session holds it; stepping over it`.
- [ ] AC9 — Given a fixture backlog where an unscoped `next: design` row ranks above the confirmed
      develop gate, when the sprint prints its proposal, then the proposal names that row as the run's
      stopping point. **Red if** the proposal reports the gate takeable and says nothing, which is the
      observed `4 develop gate(s) takeable` beside an escalation on `0110`.

## QA plan

- **Why that level:** the behaviour is a dispatch rule; no runner applies, and each criterion is
  checkable from a run log fixture plus `grep` assertions over the skill.
- **Specific checks:** a run-log fixture showing overlapping design and develop windows for AC1 and
  non-overlapping tail windows for AC2; `tests/sprint.test.sh` for FR2, FR3, FR4 and FR6 as stated
  rules; a two-writer fixture for AC5; `tests/sprint-ledger.test.sh` with an overlapping and a
  non-overlapping design fixture for AC6 and an unpaired dispatch for AC7, reusing its existing
  fixture transcript and sentinel so the privacy assertion covers the new line too.

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
- **2026-09-12 — design: widen to build the instrumentation, and sharpen what it measures.** The
  handed-back question (widen / ship unmeasured / drop the NFR) was settled on fact, not taste.
  *Ship unmeasured* is excluded by a principle: `measurement-conventions.md`, *Instrumentation Ships
  With the Feature* — "in the same change, not a follow-up ticket" — and a claim nobody can check
  is exactly the one that gets generalised. *Drop the NFR* is excluded because token-neutrality is
  the whole distinction from `0137`; if it is false, this permission should be reversed, so it is a
  measure someone will act on and passes *Don't Instrument What You Won't Look At*. **Widening costs
  little:** `0135` is done, so no claim holds `tools/sprint-ledger.sh`; `record()` already
  harvests per session for `GATE` and `RATIO`, and the run log already has per-stage `dispatch` and
  `outcome` timestamps, so a `DESIGN` line is the same shape as `GATE` (FR7, FR8, AC6, AC7).
  **What changed from the NFR as written:** its "sequential dispatch" population cannot exist inside
  a sprint today — a sprint never dispatches design at all, it halts — so the baseline is
  `MEASUREMENT.md`'s hand-driven design mean, and the ledger grows its own sequential population
  from sprints where the develop gate finished before the design session started. **Trade-off
  accepted:** size `m` carries a second file family, and the baseline is one session, so the claim
  stays *consistent with* for several sprints rather than being settled on day one. **Rejected:**
  a per-sprint `concurrent: true` flag set by the supervisor — it would be a claim about the run
  written by the party being measured, where window overlap is derivable from timestamps it
  already logs. **Guardrail added:** the risk to neutrality is not the design session but the
  supervisor's wait-for-claim loop, which Step 8's per-ticket figure already counts. **Existing
  criteria:** FR1–FR6 and AC1–AC5 are confirmed unchanged; the Performance NFR is rewritten; a
  Guardrail row, FR7–FR8 and AC6–AC7 are added.
- **2026-09-12 — develop (token `4244`): handed back to design before any code, on FR5.** See the
  *Open design question*. Two further facts checked against the source while restating the contract,
  both of which a builder would otherwise meet as a surprise, whichever remedy is chosen:
  **`--completed design:<id>` is not a routing input.** A design row handing off to `next: develop,
  status: ready` reaches `.claude/backlog/next`'s final `ESCALATE … which no routing rule covers`
  branch (the `--completed` block, ~line 1310), so the supervisor must report a design finish some
  other way or a successful design session stops the run — AC1's red arriving by another door.
  **`./claim` refuses a busy lock rather than waiting on it** (`skills/queue/templates/claim`, the
  `mkdir "$LOCK" … exit 1` branch), so AC5's *"both land"* holds only if the losing writer retries;
  a two-writer fixture that runs two claims at once will red on the refusal unless it models that
  retry. **The supervisor's `--started` set only affects verify selection** (`started_verify`,
  `verify_batch`), so a designed id in it does not by itself absorb that ticket into a develop gate;
  what does is `--drive` naming it as the topmost develop row after its design lands, which the
  partial-gate rule in *The proposal* is the nearest existing answer to (AC4).
- **2026-09-12 — design (token `7a94`): the design session holds its own row with `./claim`, taken
  at `design` Step 1; that change is a blocking sibling, not part of this ticket.** Settled on fact.
  All three script paths were run in a scratch copy of this backlog, not read: `./claim` takes a
  `next: design` row (rc 0, and it declines to seed `touches:` because design does not build);
  `--drive` then steps over it (`NOTE … in-progress … stepping over it`); `./handoff <id> <token>
  develop` and `./handoff <id> <token> design waiting` both release it; and a second `./claim` on
  the held row refuses (`is 'in-progress', not ready`), which is FR5's first half enforced by an
  existing script. So the remedy needs **no script change** — only `skills/design/SKILL.md` Step 1
  and Step 4, which is why it is a sibling: it changes a stage, is useful with no sprint running,
  and falls under this ticket's *"Any change to what a design session does once dispatched"*.
  **Rejected:** a supervisor-supplied `--designing <id>` on `./next`, because the hold would live in
  supervisor memory that a hand-driven `/design` cannot see, so FR5's second half stays unmet; and
  the supervisor claiming for the session, which sprint Step 8 forbids (*It never claims a row and
  never mints a claim token*). **The objection that claiming holds rows too long is answered by
  fact:** a `develop` claim already holds a row for a whole session, and `CONCURRENCY.md` *Claim
  tokens* already covers the dead claim. **Trade-off accepted:** 0134 cannot start until the sibling
  ships and is installed; and a design pass that stops without deciding must still release through
  `./handoff … design ready` rather than walking away. **Criteria:** FR1–FR8 and AC1–AC7 confirmed
  unchanged, since FR5 as written becomes true once the sibling lands; AC8 added.
  **For `queue`:** file the sibling and set 0134's `blocked_by:` to it. It is not a new question.
  `0056`'s notes already assign *"whether design claims"* to that ticket, yet none of 0056's FRs
  says so. Adding one there is the alternative to a new row, and which to use is `queue`'s call.
  Either way the open `FINDINGS.md` entries of 2026-09-10 and 2026-09-12 about design reasoning over
  an unheld row close with it. **Routed to `queue` rather than `develop`** because a blocker that
  does not exist cannot be named in `blocked_by:`, and this session writes only the ticket it holds.
- **2026-09-12 — design: an out-of-scope design row ranked *above* the confirmed gate still stops
  the run, even after the sibling lands.** In the same drill, with 0134 held, `--drive` escalated on
  the next design row (`0110 is at next: design and outranks everything below it`) while reporting
  `4 develop gate(s) takeable`. FR3 forbids dispatching for it, so the builder has two choices. The
  proposal can refuse a confirmed scope whose design rows are outranked by an unscoped design row,
  or the halt can be reported as the scope's edge. Do not read this as AC1 failing.
- **2026-09-12 (queue) — Re-specified. No code has been written; the contract changes and the
  stage moves to `develop`, blocked.** Three changes. **The sibling is filed as `0150`** (design
  holds its row with `./claim` from Step 1), and it goes in `blocked_by:` here because FR5 and AC8
  are only true once it ships and is installed. It is a new row rather than an FR on `0056`: that
  ticket is eight prose FRs sized `m`, and blocking this one behind all of them buys nothing.
  **The builder's two choices above are decided, on fact: report the halt as the scope's edge
  (FR9, AC9).** Refusing the scope would refuse almost every sprint on this backlog today, because
  `0110` and `0041` are design rows at ranks 3 and 4, above every develop row except the held
  `0083`. **AC1 and AC5 are sharpened** with the two facts the `4244` develop pass found, which
  were in these notes but in no criterion: a design finish reported through `--completed` stops the
  run, and `./claim` refuses a busy lock rather than waiting on it. FR1–FR8 and AC2–AC4 and AC6–AC8
  are unchanged. Size stays `m`; FR9 is one proposal line over a `--drive` walk the skill already
  makes.
