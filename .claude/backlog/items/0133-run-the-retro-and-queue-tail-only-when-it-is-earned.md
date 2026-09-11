---
id: "0133"
title: Close a sprint with a retro and a queue sweep only when the findings earn it
type: feature
next: develop
status: in-progress
qa_level: verify
close_by: verify
size: m
created: 2026-09-09
source: user
parent: "0128"
blocked_by: ["0060"]
relates: ["0016", "0036", "0111"]
expects:
  - skills/orchestrate/SKILL.md
  - .claude/backlog/config.yml
  - .claude/backlog/next
  - skills/queue/templates/next
  - skills/queue/templates/config.yml
claimed_by: "9265"
claimed_at: 2026-09-11T21:34:50Z
touches:
  - skills/sprint/SKILL.md
  - .claude/backlog/config.yml
  - .claude/backlog/next
  - skills/queue/templates/next
  - skills/queue/templates/config.yml
  - tests/sprint.test.sh
  - tests/next.test.sh
---

## Problem

**A sprint should end by learning from itself, and today the trigger for that is a gate that cannot
be satisfied.** `0060` records the defect: `findings_threshold` counts *every* entry in
`FINDINGS.md`, but `retro` can only clear the lesson half — the 2026-08-25 retro processed 16 of
~100 and correctly left the rest, which only a `queue` sweep can take. So a driver crossing the
threshold is diverted into a retro that reads the remainder again and finds nothing new, and no
number of retros reduces the count.

That makes the number the sprint would gate on the wrong number, and it is why this row is blocked
rather than merely careful. Raising a threshold does not fix a gate that counts what the gated stage
cannot move.

**The tail is not free and should not fire on an empty buffer.** Measured per session in
`MEASUREMENT.md`: retro **$2.51**, queue **$4.24** — a tail of roughly **$6.75**, against a
one-ticket sprint that may itself cost less. Aaron, 2026-09-08: *"at almost $7 per run, we should
really wait to do a Retro until there's enough to make it worth it."*

**The cost argument does not, however, support batching — and the analysis matters because it points
somewhere else.** The tail is mostly **variable**, not fixed: retro's cost scales with the buffer it
reads and queue's with the rows it writes. The 2026-09-09 retro annotated eight items, created ten
item files, edited `config.yml` and `QUEUE.md` and drained the buffer, which is far more than the
23-turn session behind the $2.51 mean. What batching actually saves is two session startup floors,
once — on the order of **$0.70–$1.10 per skipped tail**, or roughly **$0.09 per finding** at a
threshold of 16. That is not a reason to change anything.

**The reason to batch is pattern detection, which is a quality argument, and this project ranks
quality first.** A four-finding retro sees incidents; a fifteen-finding retro sees a recurrence.
This repo already committed to that in `0016`, *"Make retro a batch process over many sessions"*.
Aaron: *"One larger retro seems more valuable to me because there's more opportunity to find
recurring patterns."*

**And a calendar-day staleness window would protect nothing.** The gate is only ever evaluated when
a sprint ends. If the project goes dormant, no sprint runs, so no window fires — and a calendar rule
and a sprint-count rule fire identically on the next sprint whenever it comes. Measured on this
repo: 21 active days in the 25 calendar days to 2026-09-08, longest idle gap two days. Deriving a
window from commit cadence adds a knob, a derivation and a failure mode, and covers nothing the
simpler unit misses.

## Functional requirements

Written against whatever `0060` settles for *what is counted*; these hold regardless of that shape.

- FR1 — A sprint runs no retro and no queue sweep unless the gate is crossed. A sprint that parks
  nothing ends without a tail.
- FR2 — The gate is crossed when the count reaches the configured threshold **or** when any
  unprocessed finding has survived a configured number of completed sprints, whichever comes first.
- FR3 — Age is measured in **completed sprints**, not calendar days, and the reason is recorded
  beside the setting.
- FR4 — Both settings live in `config.yml` with their derivation beside them, as
  `lock_stale_seconds` and `stage_budget_usd` already do, and the same defaults reach
  `skills/queue/templates/config.yml`.
- FR5 — When the gate is crossed the sprint dispatches `retro`, and then `queue`, **each with no
  other stage session running**. Both rewrite the skills and backlog scripts every other session is
  executing.
- FR6 — When the gate is not crossed, the findings carry forward untouched, to be swept by a later
  sprint together with that sprint's own.
- FR7 — The gate is evaluated once per sprint. A completed retro does not re-arm it — `retro` parks
  what surprised itself, so a stateless re-derivation afterwards reads a count and dispatches again.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Performance | The threshold's effect on cost per closed ticket is recorded by `0135` rather than asserted here; the figures above are read from `MEASUREMENT.md` and stamped, never cached into this file | `observability-conventions.md` |
| Documentation | The derivation for both settings lives beside them in `config.yml`, so raising one later is an argument rather than a preference | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given a sprint that parks no findings and a buffer below the threshold, when the sprint
      ends, then no retro and no queue session is dispatched. **Red if** the tail is unconditional,
      which spends about $6.75 on a buffer with nothing in it.
- [ ] AC2 — Given a buffer at the threshold, when the sprint ends, then `retro` is dispatched and
      then `queue`, and no other stage session is running during either. **Red if** they run
      concurrently with a stage, or with each other.
- [ ] AC3 — Given a buffer below the threshold holding one finding older than the configured number
      of sprints, when the sprint ends, then the tail runs. **Red if** only the count is checked,
      which strands an old finding indefinitely on a low-yield project.
- [ ] AC4 — Given a buffer below both limits, when the sprint ends, then every finding is still in
      `FINDINGS.md` and the next sprint's gate counts them alongside its own. **Red if** the sprint
      drains or marks entries it did not process.
- [ ] AC5 — Given a completed retro within a sprint, when the sprint re-evaluates, then it does not
      dispatch a second retro. **Red if** the gate is re-derived statelessly after the retro, which
      reads the entries the retro itself parked and fires again.
- [ ] AC6 — Given `config.yml`, when the two settings are read, then each carries its derivation.
      **Red if** either is a bare number — the shape `lock_stale_seconds` and `stage_budget_usd`
      were both written to avoid.

## QA plan

- **Why that level:** the behaviour is a dispatch decision plus two config values; no runner covers
  it, and every criterion is a `grep` or a fixture-driven run.
- **Specific checks:** fixture buffers at, below and above the threshold, and one holding a finding
  aged past the sprint limit; `grep` over `config.yml` and the shipped template for both settings
  and their derivations; `tests/sprint.test.sh` for FR5's serialisation and FR7's once-per-sprint
  rule.

## Out of scope

- Deciding what the gate counts, or how an entry records that one sweeper has finished with it —
  both are `0060`, and this ticket consumes that decision.
- Choosing the final threshold and age numbers from data. They ship as interim values with their
  provisional status recorded; `0135` supplies the yield figures that replace them.
- Any change to what `retro` or `queue` do once dispatched.

## Notes & decisions

- **2026-09-09 — interim values are 12 findings and 2 sprints, and both are explicitly placeholders.**
  They must be set together or one goes dead: if sprints park about six findings each, the two
  coincide, which is the intent. The parking rate is not yet known — the buffer's history is too
  lumpy to compute one — so `0135` records findings-parked-per-sprint and retro yield, and these
  numbers are re-derived from that rather than defended.
- **2026-09-09 — a git-derived staleness window was considered and rejected**, with the reasoning in
  the Problem section. It is recorded because the idea is a natural one to have twice.
- **2026-09-11 — `expects:` named `skills/orchestrate/SKILL.md`, which `0128` had renamed to
  `skills/sprint/`.** Corrected in `touches:` at claim. Nothing else in the ticket went stale with
  it: `0060` settled the count as *every entry* with `retro` as terminal sweeper, and this ticket's
  FRs were written to hold regardless of that shape, which they did.
- **2026-09-11 — where "completed sprints" is recorded, and why it is not a counter in
  `config.yml`.** FR3 fixes the unit and not the ledger, and the obvious home — a monotonic counter
  beside `next_id`, which is the repo's own precedent for state in `config.yml` — is **closed to the
  supervisor**: `sprint` Step 7 forbids it the backlog lock, and `CONCURRENCY.md` requires the lock
  for every write to that directory. The only durable record a supervisor may write is its own
  per-run log, which is single-writer and needs none. So a **completed sprint is a run log carrying
  a `sprint_ended` event** — not a run log *file*, because a supervisor killed mid-run offered the
  buffer no opportunity to be swept, and counting files would score that as one.
- **2026-09-11 — that made Step 5's "the log is not state" false, and it was narrowed rather than
  left standing.** The age limit reads `runs/` across the whole history, so *"delete the log between
  two sessions and the next action does not change at all"* no longer holds for the gate. What still
  holds is the claim the sentence exists for: a resuming supervisor places itself from `--drive` and
  `--findings` and reads no log to do it. The exception is named beside the claim and guarded
  (`tests/sprint.test.sh` AC17), because an unnamed one reads correctly on its own while the next
  reader acts on it. Deleting the history resets the age half only, and errs toward a tail that
  fires late rather than one that fires on nothing.
- **2026-09-11 — the same-day comparison is an acknowledged over-strictness, not an oversight.** An
  entry carries a date and a run an instant, so on a shared day nothing says which came first. A
  sprint ending the day an entry was parked is therefore not counted: that delays the gate by at
  most one sprint, where counting it would fire the whole tail on a finding parked minutes earlier.
  Guarded as its own case so the choice cannot be silently reversed.
- **2026-09-11 — `findings_threshold` was left at 8 here rather than raised to the note's interim
  12.** The key's own comment records why this repo holds it at retro's stated cadence, `0100` puts
  moving it out of scope, and raising it is a judgement `0135`'s yield figures should settle. At 8
  the count crosses first on this repo and the age half rarely fires — which is correct for a
  project whose rate is inflated because its tickets are *about* the tooling.
- **2026-09-11 — a cost figure in skill prose is constrained twice, by guards nothing sends you
  to.** `**$6.75**` broke `tests/money-in-skill-prose.test.sh` (a `$` before a digit is substituted
  by the harness as an invocation argument), and rewriting it as `**USD 6.75**` then broke
  `tests/sprint.test.sh` AC14, which reconciles every *bolded* USD figure in the skill against
  `MEASUREMENT.md`'s cost-per-closed-ticket column — a set this figure does not belong to. Both are
  correct; neither is reachable from "I am about to quote a number". Parked.
