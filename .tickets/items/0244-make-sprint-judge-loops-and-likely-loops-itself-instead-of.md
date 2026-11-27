---
id: "0244"
title: Make sprint judge loops and likely loops itself, instead of ending a run on a bounce count
type: feature
next: design
status: ready
qa_level: unit
close_by: verify
size: l
created: 2026-11-27
source: user
parent:
blocked_by: []
relates: ["0242", "0234", "0231", "0243", "0036"]
expects:
  - skills/queue/templates/next
  - .tickets/next
  - tests/next.test.sh
  - tests/sprint.test.sh
  - skills/sprint/SKILL.md
  - skills/queue/templates/config.yml
  - .tickets/config.yml
  - references/CONCURRENCY.md
  - CHANGELOG.md
claimed_by:
claimed_at:
touches:
slice:
ac_digest: AC1=e30a2ec4 AC2=ea81c612 AC3=2c800f49 AC4=96492c03 AC5=dec41c2b
---

## Outcome

In the person's words (answer 6, sprint run-20261127T024025Z, `.tickets/runs/s13-answer.md`):

> "The bounce limit is a tool. We added it in to help keep track of runaway sessions and to identify
> potential loops. The sprint tool needs the ability to be smart, to look at what is happening and make
> good decisions on its own. when there is a loop or a potential loop identified then it should escalate
> to me so that I can intervene and fix the thing before we go off the rails, but we want to build sprint
> in a way that maximizes its own ability to identify those possible loops and address them on its own.
> A hard bounce limit is less important to me than designing and building a system that understands the
> goal and has the autonomy to move us toward that outcome effectively."

Done means: the supervisor identifies loops and likely loops itself, addresses what it can, escalates
only those to the person, and `bounce_max` stops being the rule that ends a run.

## Problem

Today a run ends on a count. `skills/queue/templates/next` has one `past_bound` arm per re-entry kind
(`went back to next: design`, `bounced from <stage>` for queue, `bounced from verify`), each escalating
with "the loop is not converging, and whether to go round again is a person's call" once the
supervisor's `--bounces` count passes `bounce_max` (default 2, `config.yml`). The count cannot tell a
ticket that is converging slice by slice from one going round the same failure.

And a hand-off that no count governs escalates as if it were a stalled contract. In this run, after
design `213b` committed `b5af0c5` (*Hand off 0242 to queue*) on the person's own decision, `--drive`
exited 4 on the arm at `skills/queue/templates/next` (the `elif [ "$lnext" = "queue" ]` catch-all):

    ESCALATE  0242 went back to next: queue after design — the contract is stale, and respecifying it is a person's call

The person had approved that hand-off minutes earlier (`.tickets/runs/s13-answer.md`; run log
`.tickets/runs/run-20261127T024025Z.jsonl`, `escalation_answered` at 15:41:13Z, `scope_amended` naming
"queue pass on 0242 after the S13 design"). The supervisor had to dispatch this queue pass by hand.
0242 FR72 adds `design` to the in-scope queue-dispatch arm, but deliberately under the same `bounce_max`
bound, and names this ticket as what replaces it.

**Source.** Toolkit work the user asked for in sprint run-20261127T024025Z, so `CLAUDE.md`'s
held-finding rule (*Where toolkit work comes from*) does not apply.

## Open design question

- **Question:** (1) what counts as a loop and a likely loop — e.g. the same ticket back at the same stage
  with an unchanged `ac_digest:` and no slice ticked, the same verify diagnosis twice, a design ↔ queue
  oscillation with no criterion change, spend growing with no slice ticked; (2) which of those the
  supervisor addresses on its own (re-dispatch with the prior diagnosis, route to `queue` or `design`,
  reorder, narrow nothing) and which it escalates; (3) where the judgement lives — `--drive` is
  stateless, so it supplies evidence (history, digests, slice ticks) and the supervising session
  judges, or `--drive` derives a verdict from a run log it is given; (4) what becomes of `bounce_max`:
  removed, or kept as a non-ending signal or a runaway backstop the person sets.
- **Why it blocks specification:** every AC below needs (1)–(3) to name its fixture and its output, and
  (2) is a judgement about what the person wants decided without them.
- **Settle it with:** `/design`, reading `skills/sprint/SKILL.md` (routing, escalation), the
  `past_bound` arms and `bounce_count` in `skills/queue/templates/next`, 0234's notes (why `bounce_max`
  was added) and this run's log as the worked example.

## Functional requirements

Fixed whatever the answer; design adds the rest and may sharpen these, never narrow them.

- FR1 — `bounce_max` is not the rule that ends a run: no `--drive` arm escalates on a re-entry count
  alone. The arms this replaces are every `past_bound` escalation in `skills/queue/templates/next`,
  including 0242 FR72's design → queue arm.
- FR2 — The supervisor identifies loops and likely loops from what the run shows (design's signals),
  and the signals are computed by a script, not re-derived in prose each run.
- FR3 — On a loop it can address, the supervisor addresses it and records what it did in the run log;
  it escalates only a loop or likely loop it cannot address, naming the ticket, the evidence and what
  it tried.
- FR4 — A hand-off a person approved, or one that moves the ticket forward (a slice ticked, criteria
  changed), is never escalated as a loop; the `b5af0c5` design → queue hand-off is the case.
- FR5 — `skills/sprint/SKILL.md` states which loops the supervisor addresses and which it escalates,
  and `--drive`'s usage text matches it.
- FR6 — `CHANGELOG.md` `## Unreleased` names the change and what happens to a consuming project's
  `bounce_max:` key.

## Acceptance criteria

Outcome-level and fixed regardless of the answer; design sharpens their fixtures and adds the rest.

- [ ] AC1 — Given a fixture run whose in-scope ticket re-entered an earlier stage more than
  `bounce_max` times, each re-entry ticking a new slice, when `./next --drive` runs, then it does not
  exit 4 on the count. Red: today's `past_bound` arms.
- [ ] AC2 — Given a fixture run in which one ticket returns to the same stage with an unchanged
  `ac_digest:`, no slice ticked and the same recorded diagnosis, when the loop signal is computed, then
  it names that ticket as a likely loop with that evidence. Red: a re-dispatch with no loop named.
- [ ] AC3 — Given 0242's case — a `--completed design:<id>` hand-off to `next: queue` / `ready` in scope,
  with `--bounces <id>` past `bounce_max` — when `./next --drive` runs, then it dispatches `queue` and
  prints no ESCALATE line. Red: 0242 FR72's bounded arm.
- [ ] AC4 — Given `skills/sprint/SKILL.md` after the change, when verify reads its routing and escalation
  sections, then they state FR3 and FR5 and no sentence ends a run on a bounce count. A reading, not a
  guard (`CLAUDE.md`, *Tests*).
- [ ] AC5 — Given the tree after the change, when `for t in tests/*.test.sh; do "$t" || exit 1; done`
  runs, then it exits 0. Red: a fixture left asserting a `bounce_max` ESCALATE line.

## Progress

**One outcome is one ticket, even across many sessions**; its slices are worked in order, each about
one develop session's work (`product-definition-conventions.md` → "Slice Vertically and Thinly").

- [ ] S1 — the loop signals, computed by script from the run's evidence — unspecified
- [ ] S2 — `--drive` stops escalating on a count; the `past_bound` arms and 0242 FR72's bound go — unspecified
- [ ] S3 — `skills/sprint/SKILL.md`: what the supervisor addresses itself and what it escalates; `bounce_max:` in config and the CHANGELOG — unspecified

## QA plan

Fixture runs in `tests/next.test.sh` and `tests/sprint.test.sh`, at `qa_level: unit`; the sprint prose
is checked by reading (`CLAUDE.md`, *Tests*). Design names the cases per slice.

## Out of scope

- The per-slice file layout (0243), though its slice statuses are an input the loop signals may read.
- Changing the stages a run may dispatch, or deciding anything a person decides (design questions,
  pushes, releases, narrowed contracts stay escalations).

## Notes & decisions

- **2026-11-27 (queue `e782`, sprint run-20261127T024025Z).** Captured on the person's answer 6 and the
  approved recommendation ("6 becomes a second new epic"); the outcome is quoted in their words. Minted,
  not amended: 0242 FR72 touches the same arm but deliberately keeps the bound and names this ticket as
  its replacement, and 0234 (which added `bounce_max`) is closed. An outcome of its own.
- **Routed to `design`** on trigger 1: what counts as a loop, and what the supervisor may address without
  the person, decide every criterion's form.
- **Ranked below 0243**, both directly below 0242 as the dispatch asked. Pairwise: 0243 removes the
  serialisation that cost this run the most sessions, and its slice statuses are evidence this ticket's
  loop signals can read, so 0243 first. The position above 0192 and the rest is the person's
  (the approved recommendation and this run's `scope_amended`), not a tier judgement of this pass;
  `--drive` escalating approved hand-offs costs a person's attention each time. Not `blocked_by` 0242; develop on it
  should follow 0242's S13, which builds the FR72 arm this replaces.
- Interacts with 0242's FR71 reading: if every design pass came to hand to `queue`, FR72's count would
  escalate sliced epics routinely until this lands.
