---
id: "0244"
title: Make sprint judge loops and likely loops itself, instead of ending a run on a bounce count
type: feature
next: develop
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
ac_digest: AC1=59f07451 AC2=83a7a2ba AC3=729acd33 AC4=11a144c3 AC5=9bc207d6 AC6=1e44df79 AC7=ca21624e AC8=c972eec3 AC9=93ec846d AC10=fb878eed
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

## Functional requirements

FR1–FR6 are the outcome-level requirements queue wrote, kept. FR3 was reshaped (see *Notes & decisions*,
2026-11-28 design `936a`). FR7 onward are what the decision added.

- FR1 — `bounce_max` is not the rule that ends a run: no `--drive` arm escalates on a re-entry count
  alone. The arms this replaces are every `past_bound` escalation in `skills/queue/templates/next`,
  including 0242 FR72's design → queue arm.
- FR2 — The supervisor identifies loops and likely loops from what the run shows (FR8–FR11), and the
  signals are computed by a script (`tools/sprint-ledger.sh loops`, FR7), not re-derived in prose each run.
- FR3 — On a loop it can address, the supervisor addresses it and records what it did in the run log
  as a `loop_addressed` event (FR16). It escalates only a loop or likely loop it cannot address, naming
  the ticket, the evidence and what it tried. **Which response fits a given signal is the supervising
  session's judgement, stated as default guidance in `skills/sprint/SKILL.md` (FR15), not as a ladder.**
  The script tests the recorded half (FR11's `ADDRESSED` line). The judgement half is prose and stays
  unguarded (`CLAUDE.md`, *Tests*).
- FR4 — A hand-off a person approved, or one that moves the ticket forward (a slice ticked, criteria
  changed), is never escalated or signalled as a loop. The `b5af0c5` design → queue hand-off is the case.
  In `--drive` (FR14), no count is read at all. In `loops` (FR9), such a hand-off counts as progress.
- FR5 — `skills/sprint/SKILL.md` states which loops the supervisor addresses and which it escalates,
  and `--drive`'s usage text matches it: `--drive` routes every re-entry and never counts, and the loop
  judgement belongs to the supervisor.
- FR6 — `CHANGELOG.md` `## Unreleased` names the change, one line per behaviour a session now sees
  differently: the new `loops` subcommand (S1); `--drive` no longer escalating on a count, `--bounces`
  ignored, and `bounce_max:`'s new meaning, so a consuming project knows its key is kept and what it now
  does (S2).

### S1 — the loop signals, by script

- FR7 — `tools/sprint-ledger.sh loops --run <run-log.jsonl> [--repo <checkout>] [--config <config.yml>]`
  is read-only. `--repo` defaults to the current directory. `--config` defaults to
  `<repo>/.tickets/config.yml`, and an absent file means defaults. **The signals never decide anything,
  and they never set the exit code.** The script exits 0 whenever it read the log, whatever it found. It
  exits 1 on an unreadable or malformed log, a `--repo` that is not a git checkout, or a malformed
  `bounce_max`, naming the key. It exits 2 on a usage error. The usage block in the file's header comment
  gains the subcommand, as its siblings have.
- FR8 — A **re-entry** is an `outcome` event's ticket entry whose `next` names an earlier stage than the
  outcome's `stage`, in the order queue < design < develop < verify < done. This is the definition
  `skills/sprint/SKILL.md` already gives `--bounces` today. **A ticket's window** starts at its last
  verify `pass` outcome in the log, or at the start of the run when it has none. Everything below counts
  within the window.
- FR9 — **Progress** between a ticket's outcome and its previous one in the window is any of:
  (a) the item's `ac_digest:` frontmatter value differs;
  (b) the set of ticked `- [x] S<n>` lines under `## Progress` grew;
  (c) between the two outcomes, a run-log event `escalation_answered` or `scope_amended` names the ticket
  in its `tickets` array.
  The item is read with `git show <sha>:<path>` at the last sha in the outcome's `commits`. An outcome
  with no commits reads as unchanged from the ticket's previous outcome. A ticket's first outcome in the
  window is compared with the item at the parent of that outcome's first commit. With no commits, it
  counts as no progress. The item path is found by id under `.tickets/items/` at that sha.
- FR10 — A **no-progress re-entry** is a re-entry with no progress (FR9) since the ticket's previous
  outcome. A **likely loop** is two or more consecutive no-progress re-entries for one ticket from the
  same `stage`, where "consecutive" is counted over that ticket's re-entries. A design ↔ queue
  oscillation is the case of `stage: design` twice: the queue outcome between them is not a re-entry.
  Spend is summed (`cost_usd` over the ticket's outcomes since its last progress) and reported, and it
  never produces a likely loop on its own.
- FR11 — Output, one line per finding, in the order the tickets first appear in the log, with these
  exact prefixes:
  - `TICKET <id> reentries=<n> no_progress=<n> usd_since_progress=<x.xx> window=<pass|run-start>`. One
    line for every ticket with at least one re-entry in its window.
  - `LIKELY-LOOP <id> from <stage> to next: <next> x<n> — no criterion change, no slice ticked; details: <detail> | <detail> …`.
    `<n>` is the length of the run of no-progress re-entries, and every `detail` pointer in that run is
    listed in order. The supervisor compares the diagnoses those pointers lead to: they are prose, which
    the script does not judge.
  - `PROGRESS <id> <ac_digest changed | S<n> ticked | approved by <event>> at <ts>`. One line, for the
    ticket's most recent progress in the window.
  - `ADDRESSED <id> <ts> <action>`. One line for each `loop_addressed` event naming the ticket in its
    window (FR16).
  - `REVIEW <id> reentries <n> > bounce_max <m>`. Printed when the window's re-entries exceed
    `bounce_max` (FR12).
  A log with no re-entries prints `NO-LOOPS` and nothing else.
- FR12 — **`bounce_max:` keeps its name and its default, 2, and changes meaning.** It is now the
  re-entry count past which `loops` prints a `REVIEW` line: a mark for the supervisor's attention that
  counts all re-entries, progress or not. It never ends a run. `0` marks every re-entry. The validation
  `--drive` does today moves here: a value that is not a whole number exits 1, naming the key.
- FR13 — `loops` keeps the ledger's privacy invariant (the file's header): it prints ids, stage names,
  verdict-derived words, `detail` pointers, timestamps and sums, and no other field of any event.

### S2 — `--drive` stops counting; the supervisor judges

- FR14 — `--drive` reads no count. `bounce_count`, `past_bound`, `read_bounce_max` and `BOUNCE_MAX` are
  removed from `skills/queue/templates/next`, and every former `past_bound` arm routes as it does today
  below the bound:
  - design re-entry: a NOTE, then on to the rank walk.
  - in-scope `next: queue` after verify, develop or design: `DISPATCH  queue <id>`.
  - verify → develop: `dispatch_leg`.
  No NOTE prints an `(n of m)`. `--bounces <id>=<n>` is still accepted, so a supervisor running an older
  `skills/sprint/SKILL.md` does not stop. It prints one
  `NOTE      --bounces is ignored since 0244 — loop judgement is the supervisor's (tools/sprint-ledger.sh loops)`
  and has no other effect. Malformed `--bounces` input no longer exits 2. The stale-contract catch-all
  (`elif [ "$lnext" = "queue" ]`) is unchanged: it still escalates an out-of-scope row, a call with no
  `--scope`, and `--completed queue:<id>`, because those turn on scope, a person's, not on a count. The
  usage text drops the bound's description and says the above (FR5). `.tickets/next` is updated to
  match the template.
- FR15 — `skills/sprint/SKILL.md`, in the routing paragraph that today begins *A bounce is routed, not
  escalated, up to `bounce_max`*, and in the escalation section (Step 8):
  - After every outcome, the supervisor runs `tools/sprint-ledger.sh loops --run <run log>` and reads
    what it says about the tickets it is about to dispatch.
  - **Judgement is the default**, as default guidance rather than a ladder:
    - On a `LIKELY-LOOP`, address it. Re-dispatch with every listed diagnosis and the loop evidence in
      the prompt, or route the ticket to `queue` (the contract is wrong) or to `design` (the question
      was never settled), whichever the diagnoses point to.
    - Escalate a likely loop that recurs after an `ADDRESSED` for that ticket, unless the supervisor can
      name what will make the next attempt differ.
    - Escalate any loop whose only remaining fix is a person's: a narrowed contract, a design question
      on taste, a scope change.
    - Weigh `REVIEW` and spend, and never treat either as an ending by itself.
  - Every escalation names the ticket, the evidence lines and what was tried.
  - **A fixed rule the person states** (in the scope confirmation or the project's `CLAUDE.md`, e.g.
    "escalate any ticket past three re-entries") is followed. Fixed rules are allowed where they earn
    their place, and they are not the default.
  - The `--bounces` instruction is deleted.
- FR16 — `skills/sprint/SKILL.md`'s run-log section names three events with a `tickets` array of ids,
  because `loops` reads them:
  - `loop_addressed`: `ticket`-scoped, with `signal`, `action` and `reason`. The supervisor writes it
    whenever it acts on a signal.
  - `escalation_answered`.
  - `scope_amended`.
  The last two already appear in run logs (`.tickets/runs/run-20261127T024025Z.jsonl`, machine-local)
  with no shape the skill names.
- FR17 — `skills/queue/templates/config.yml`'s `bounce_max:` comment states FR12's meaning: attention,
  not a cap. It says the key is read by `tools/sprint-ledger.sh loops` and no longer by `./next`. This
  repo's `.tickets/config.yml` sets no `bounce_max:` (checked 2026-11-28) and needs no change.

## Acceptance criteria

- [ ] AC1 — Given a `tests/next.test.sh` fixture with an in-scope row bounced from verify to
  `next: develop` / `ready`, `bounce_max: 2`, and `--completed verify:<id> --bounces <id>=3`, when
  `./next --drive` runs, then it exits 0, prints `DISPATCH  develop <id>` and the `--bounces is ignored`
  NOTE, and prints no ESCALATE line; and with the row instead at `next: design` / `ready` it exits 0
  with no ESCALATE line. Red: today's `past_bound` arms exit 4.
- [ ] AC2 — Given a `tests/sprint-ledger.test.sh` fixture (a scratch git repo with an item, plus a run
  log) in which ticket 0901 has two consecutive `stage: verify` outcomes to `next: develop`, a develop
  outcome between them that changes neither `ac_digest:` nor a ticked slice, and distinct `detail`
  pointers, when `tools/sprint-ledger.sh loops --run <log> --repo <fixture>` runs, then it exits 0 and
  prints `LIKELY-LOOP 0901 from verify to next: develop x2` naming both `detail` pointers in order. Red:
  no `loops` subcommand.
- [ ] AC3 — Given 0242's case, a `--completed design:<id>` hand-off to `next: queue` / `ready` in scope
  with `--bounces <id>=3` and `bounce_max: 2`, when `./next --drive` runs, then it dispatches `queue`
  and prints no ESCALATE line. The same row out of scope, with no `--scope`, or after `--completed
  queue:<id>` still exits 4 on the stale-contract line. Red: 0242 FR72's bounded arm (0242 AC87's
  past-bound case).
- [ ] AC4 — Given `skills/sprint/SKILL.md`, `skills/queue/templates/config.yml` and `./next --help` after
  the change, when verify reads the routing, escalation and run-log sections, then they state FR3, FR5,
  FR15, FR16 and FR17, no sentence ends a run on a bounce count, and the `--bounces` instruction is gone.
  A reading, not a guard (`CLAUDE.md`, *Tests*).
- [ ] AC5 — Given the tree after S2, when `for t in tests/*.test.sh; do "$t" || exit 1; done` runs, then
  it exits 0. The 0234 and 0242 AC87 fixtures that asserted a `bounce_max` ESCALATE now assert the
  dispatch. Red: a fixture left asserting the escalation.
- [ ] AC6 — Given AC2's fixture with progress between the two verify outcomes, run once per kind (the
  develop outcome's commit ticks `S2`; queue restamps `ac_digest:`; an `escalation_answered` event
  naming 0901 sits between them), when `loops` runs, then it prints no `LIKELY-LOOP` for 0901, and its
  `PROGRESS 0901` line names that kind. Red: a loop reported across real progress.
- [ ] AC7 — Given AC2's fixture followed by a verify `pass` outcome for 0901 and then one more verify →
  develop re-entry, when `loops` runs, then 0901's `TICKET` line reads `reentries=1` and
  `window=pass`, and it has no `LIKELY-LOOP` line. Red: counts carried across a pass.
- [ ] AC8 — Given a fixture with three re-entries for one ticket, each with progress, and `bounce_max: 2`
  in `--config`, when `loops` runs, then it exits 0 with `REVIEW <id> reentries 3 > bounce_max 2` and no
  `LIKELY-LOOP`. With `bounce_max: 0` and one re-entry it prints `REVIEW`. With `bounce_max: x` it exits
  1 naming `bounce_max`. Red: `REVIEW` absent, or a malformed value accepted.
- [ ] AC9 — Given a log with a `loop_addressed` event naming 0901, when `loops` runs, then it prints
  `ADDRESSED 0901 <ts> <action>`. A log with no re-entries prints `NO-LOOPS`. A malformed log line exits
  1, `--repo` at a non-git directory exits 1, and a missing `--run` exits 2.
- [ ] AC10 — Given a fixture log whose events carry a sentinel string in a field FR13 does not list
  (e.g. an `escalation` sentence or a `prompt`), when `loops` runs, then the sentinel is absent from its
  output. Red: an event echoed whole.

## Progress

**One outcome is one ticket, even across many sessions**; its slices are worked in order, each about
one develop session's work (`product-definition-conventions.md` → "Slice Vertically and Thinly").

- [ ] S1 — the loop signals, computed by `tools/sprint-ledger.sh loops` from the run log and the items at each outcome's commits; additive, so `--drive` still counts until S2 (FR7–FR13, FR6's S1 line) — discharges AC2, AC6, AC7, AC8, AC9, AC10
- [ ] S2 — the switch: `--drive` stops counting and ignores `--bounces`, `skills/sprint/SKILL.md` makes judgement the default and names the run-log events, `bounce_max:`'s comment and the CHANGELOG (FR1, FR3–FR5, FR6's S2 line, FR14–FR17) — discharges AC1, AC3, AC4, AC5

## QA plan

`qa_level: unit`. S1: `tests/sprint-ledger.test.sh` fixtures (a scratch git repo holding an item at
several commits, plus a hand-written run log), AC2 and AC6–AC10. S2: `tests/next.test.sh` fixtures,
AC1 and AC3, with the 0234 and 0242 AC87 bound cases rewritten (AC5). The sprint prose and the usage
text are checked by reading (AC4). No new guard greps prose (`CLAUDE.md`, *Tests*).

## Out of scope

- The per-slice file layout (0243). If 0243 moves slice ticks out of the item, FR9(b) reads them from
  wherever 0243 puts them; the develop session building S1 checks 0243's state first.
- Changing the stages a run may dispatch, or deciding anything a person decides (design questions,
  pushes, releases, narrowed contracts stay escalations).
- Any other `--drive` ESCALATE arm: waiting, held claim, same-stage-with-no-hand-off, drift and the
  out-of-scope stale contract turn on facts, not counts, and stay.

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
- **2026-11-28 (design `936a`, dispatched by a `/sprint` supervisor) — decided: Option A, with the
  person's refinement.** The person chose A over the recommended C: "A. I want sprint to have more
  autonomy and not get stuck by hard rules that don't always apply." They then refined it the same day:
  > "we don't need to prevent hard rules, we just shouldn't default to them."

  So the decision is that **judgement is the default, and the ladder is not**. A script
  (`tools/sprint-ledger.sh loops`, which already reads the run log) computes the signals. The
  supervising session judges them. `--drive` stays stateless and stops counting. A fixed rule stays
  available wherever it earns its place, in two ways. First, the rules that turn on a fact, not a
  count (waiting, held claim, drift, out-of-scope stale contract, same stage with no hand-off), are
  kept. Second, a fixed rule the person states for their project is followed (FR15).
  **Rejected:**
  - B: the ladder becomes the default, which is the thing the person said not to default to.
  - C: two places hold loop logic, and the script's verdict still ends the run, so the floor would be a
    hard rule by default.
- **`bounce_max` under A:** kept, same name and default (2), meaning changed to an attention mark
  (`REVIEW`) that `loops` prints and the supervisor weighs (FR12, FR17). Removing it would be preventing
  a rule. Keeping it as a cap would be defaulting to one. As an attention threshold it fits the
  refinement, and a consuming project's key keeps working with no edit. C's narrowed meaning, counting
  only *no-progress* re-entries, did not carry over. A no-progress repeat is already its own signal
  (`LIKELY-LOOP`), so `REVIEW` counts every re-entry. That makes it a runaway mark that converging
  work can also trip, which is fine for an attention mark.
- **FR3 reshaped (this pass's call, as the queue note asked).** Option A's stated con was "FR3 is only
  partly testable". Accepted, not engineered around. FR3 now separates two halves. The recorded half is
  the `loop_addressed` event and `loops`' `ADDRESSED` line, which is fixture-tested (AC9). The
  judgement half (which response fits which signal) is default guidance in prose, read by verify
  (AC4), and unguarded per `CLAUDE.md` *No new guard greps prose*. This sharpens FR3 and narrows no
  behaviour.
- **Accounting against the arrived criteria:**
  - AC1: confirmed, with its fixture sharpened to verify → develop and design re-entry with `--bounces`
    past the bound.
  - AC2: changed. "The same recorded diagnosis" is prose a script cannot compare, so the script lists
    every `detail` pointer and the supervisor compares (FR11).
  - AC3: confirmed, with the out-of-scope / after-queue escalations it must keep added.
  - AC4: extended to the config comment and usage text.
  - AC5: confirmed.
  - AC6–AC10: added.
  - FR1, FR2, FR4, FR5, FR6: kept. FR3: reshaped as above. FR7–FR17: added.
  - Slices went from three to two. The old S2 (`--drive`) and S3 (prose) are merged, so the script
    and the skill never disagree about who judges. In an S2 without S3, `--drive` would stop
    escalating before the prose told the supervisor to run `loops`. S1 is purely additive, so the tree
    is safe at every point.
- **Signals, settled on fact (FR8–FR10).** The design ↔ queue oscillation is not a separate kind: it is
  two consecutive no-progress re-entries from `design`, so one rule covers it. "Same diagnosis" is the
  supervisor's comparison of the listed `detail` pointers. Spend never decides. Re-verified 2026-11-28:
  - the `past_bound` arms at `skills/queue/templates/next` ~L2244, ~L2267, ~L2301;
  - the catch-all at ~L2281;
  - `bounce_max:` in `skills/queue/templates/config.yml` L54, and absent from `.tickets/config.yml`;
  - `--bounces` defined in `skills/sprint/SKILL.md` ~L344–L355;
  - `escalation_answered` and `scope_amended` named nowhere in `skills/sprint/`, hence FR16;
  - the ledger's tests in `tests/sprint-ledger.test.sh`, not `tests/sprint.test.sh`.
- **No sibling consequence.** 0242 FR72/AC87 (past-bound escalation) and 0234's bound ACs are `done`.
  This ticket supersedes them, as 0242 FR72 itself anticipated ("written so that epic can delete"). The
  fixtures move under AC5, and no done item is rewritten.
- `qa_level: unit` and `close_by: verify` re-read against AC1–AC10: still right. Every AC is a fixture
  except AC4's reading. `expects:` should gain `tools/sprint-ledger.sh` and `tests/sprint-ledger.test.sh`
  and lose `.tickets/config.yml` and `references/CONCURRENCY.md`. Left for queue, since `expects:` is
  its prediction and the claim script reads it. S2 collides with 0243's expected files, so develop
  follows the claim script's COLLIDES report.
