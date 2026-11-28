---
id: "0244"
title: Make sprint judge loops and likely loops itself, instead of ending a run on a bounce count
type: feature
next: design
status: in-progress
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
claimed_by: "936a"
claimed_at: 2026-11-28T01:54:32Z
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

## Waiting on

### Outcome
The sprint supervisor finds loops and likely loops itself, deals with the ones it can, escalates only
the ones it cannot, and `bounce_max` stops being the rule that ends a run (answer 6, quoted above).

### Where it stands
Design `50ef` (sprint run-20261127T234238Z, unattended) read the evidence and stopped short of deciding,
because (3) is an architecture choice and (2) decides what the supervisor may do without you. Nothing
is recorded as decided: no FRs, ACs or `ac_digest` changed. Facts re-checked 2026-11-28:
- The four count-based escalations are in `skills/queue/templates/next`: design re-entry (~L2244),
  in-scope queue dispatch including 0242 FR72's design arm (~L2267), verify → develop (~L2301), plus the
  catch-all `elif [ "$lnext" = "queue" ]` stale-contract ESCALATE (~L2285), which 0242's case hit. That
  last one has no count at all; it fires on `--completed design:<id>` from a ticket out of scope or from
  `queue` itself. `.tickets/next` matches the template.
- **What a script can read.** Run-log `outcome` events carry `stage`, each ticket's `verdict`, `next`,
  `status`, `slice`, `detail`, plus `commits` and `cost_usd` (`.tickets/runs/run-20261127T234238Z.jsonl`).
  They do **not** carry `ac_digest:` or the ticked slices. Those can be read from the item at each
  outcome's last commit (`git show <sha>:<item>`), so every signal in question (1) can be computed
  without any change to what stages emit. "Same diagnosis" is the one exception. The diagnosis is
  prose in *Notes & decisions*. The closest thing a script can compare is the failed AC id plus the
  `detail` anchor.
- The worked example's run log and `s13-answer.md` are not in this checkout (`.tickets/runs/` is
  gitignored, so they exist only on the machine that ran it). `b5af0c5` *Hand off 0242 to queue [213b]*
  is in history. The approval it depended on shows up only as run-log events (`escalation_answered`,
  `scope_amended`), so FR4 needs `--drive` (or the script) to read the run log.

### What needs you
Where the loop judgement lives and how far the supervisor may go on its own: an architecture choice and
an autonomy policy, which an unattended design pass prepares but does not make.

Proposed signals (question 1, a factual matter, ready for you to confirm). Per ticket, since its last
verify `pass`: a **no-progress re-entry** is an outcome sending it to an earlier stage while its
`ac_digest:` and ticked-slice set are unchanged since the previous outcome for it. A **likely loop**
is a second consecutive no-progress re-entry at the same stage, or the same failed AC from verify twice,
or design ↔ queue twice with no criterion change. **Progress resets the count**: a digest change, a
slice ticked, or a hand-off named in a `scope_amended` / `escalation_answered` event (FR4). Spend
growing with no progress is reported next to these signals but never decides anything on its own.

### Options
#### Option A — Script computes the evidence, the supervising session judges
`tools/sprint-ledger.sh loops --run <log>` (the ledger already reads the run log) prints each ticket's
signals. `--drive` stays stateless and drops `--bounces`. `skills/sprint/SKILL.md` gives the supervisor
a rule table for what to do with each signal.
Pros: matches "smart, looks at what is happening". It handles cases no rule foresaw. `--drive` gets
simpler.
Cons: the decision is written as prose and made fresh each run, so two runs can judge one log
differently. It cannot be fixture-tested beyond the signals themselves. FR2 is met but FR3 is only
partly testable.
Wins if: you value judgement on novel cases over runs that give the same answer for the same log.
#### Option B — `--drive --run <log>` derives the verdict itself
`--drive` reads the run log, computes the signals and works a fixed ladder. On a likely loop's first
occurrence it re-dispatches with the prior diagnosis and the loop evidence in the prompt (`NOTE LIKELY-LOOP`).
On the next no-progress re-entry it routes once to the stage above: verify→develop goes to `queue`,
queue↔design goes to `design`. Then it escalates, `ESCALATE LOOP <id>` naming the evidence and both
attempts. `--bounces` is replaced by `--run`.
Pros: deterministic and fully fixture-testable (AC1–AC3 become exact). The supervisor cannot argue
itself past a loop. FR4 is checkable.
Cons: it is still a ladder of rules, only a smarter one than a count. `--drive` gains a run-log
dependency and becomes stateful by input.
Wins if: you want reproducible behaviour, with escalations you can trust to mean a real loop.
#### Option C — B's script verdict, with the supervisor free to act early
As B, but a `LIKELY-LOOP` NOTE is advisory. The supervisor may address it sooner, for example by
rerouting on the first repeat, and records what it did and why in the run log (`loop_addressed`). Only
the script's `LOOP` verdict ends the run.
Pros: the person's "autonomy" with a floor that can be tested. Cons: two places hold loop logic.

### Recommendation
**Option C.** The signals and the verdict that ends a run come from the script, so FR2 and AC1–AC3
are testable. The supervisor keeps room to act sooner than the floor, which is the autonomy answer 6
asks for. **`bounce_max` is kept, under its existing name, but it now means the number of
*no-progress* re-entries before the ladder escalates** (default 2). Progress resets the count, so a
converging sliced epic never reaches it. Consuming projects keep their key, and the CHANGELOG says the
meaning narrowed. Accepted cost: loop logic lives in both the script and the prose. The stale-contract
catch-all stays an ESCALATE only for out-of-scope rows and for `queue`→`queue`.

### What to do
Reply with A, B or C (or edits to the signals or the `bounce_max` meaning). Then
`./next --waiting` clears once someone writes `status: ready` back with `/ai-building-tools:design 0244`.
That pass records your answer and writes the FRs and ACs per slice (S1 signals script, S2 `--drive`
arms, S3 prose, config and CHANGELOG).

### If no answer
0244 waits. 0242 FR72's bounded arm stays as built, so approved design → queue hand-offs past
`bounce_max` keep escalating. Other rows are unaffected.

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
- **2026-11-28 (queue, dispatched after sprint run-20261127T234238Z) — the person answered the
  `## Waiting on` brief: Option A, not the recommended C.** Verbatim:
  > "A. I want sprint to have more autonomy and not get stuck by hard rules that don't always apply."

  Resumed to `next: design`, `status: ready` by hand under the lock (no script takes a row out of
  `waiting`; 0243's Notes record that gap). **For the design pass:** record Option A as the decision.
  The script (`tools/sprint-ledger.sh loops --run <log>`) computes the signals, the supervising
  session judges them, `--drive` drops `--bounces` and stays stateless, and the C recommendation's
  `bounce_max` reinterpretation does not carry over. Decide what `bounce_max` becomes under A and say
  so in the CHANGELOG. Rewrite the FRs/ACs and `## Progress` slices to that shape, and delete
  `## Waiting on` and `## Open design question`. Option A's stated con needs an answer: FR3 is only
  partly testable. Under CLAUDE.md's *No new guard greps prose*, the judgement half stays prose and
  is unguarded, and only the signals get fixture tests. So narrowing or reshaping FR3's criteria is
  the design pass's call, and it must be recorded as such. No FR or AC was changed in this pass and
  `ac_digest` was not restamped.
