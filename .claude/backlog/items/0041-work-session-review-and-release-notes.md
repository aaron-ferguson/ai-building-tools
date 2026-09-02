---
id: "0041"
title: Write release notes for what a work session delivered
type: feature
next: design
status: ready
qa_level: unit
size: m
created: 2026-08-25
source: user
parent:
blocked_by: []
relates: ["0016", "0026", "0036", "0039", "0037"]
expects:
  - tools/harvest-usage.sh
  - tools/classify-turns.sh
  - tools/cost-by-category.sh
  - tests/measurement.test.sh
  - README.md
  - MEASUREMENT.md
  - skills/retro/SKILL.md
  - skills/orchestrate/SKILL.md
  - .claude-plugin/plugin.json
claimed_by:
claimed_at:
touches:
---

## Problem

**Nothing in the suite reports what a work session delivered or what it cost, and the moment to do it
is while the run is fresh.** Aaron's request, verbatim, 2026-08-25:

> We have a retro skill whose goal is to understand what happened during the work sessions and
> improve our process. We should also add a Sprint Review whose purpose is to:
> - Review which tickets were done in the work session
> - compile release notes to a file that can be shared. Eventually we should also automate sending
>   an email with these updates.
> - include metrics like average time to complete a context window, total time to complete the work
>   session, average cost (in tokens and dollars) to complete a context window (also broken down by
>   which agent was run in the context window), and total cost for the work session.
>
> I don't know if this should be its own skill or be included with another like retro.

Four gaps, each verifiable on disk today rather than inferred:

1. **`retro` deliberately does not do this.** Its own text: *"Its input is `FINDINGS.md` across many
   sessions, not one session's memory, and there is no live session left to review."* It reviews
   process, not delivery. A run's shipped work and its cost reach nothing.
2. **`0036` will produce the data and then deliberately not read it.** FR10 adds an append-only
   JSON-line log under `.claude/backlog/runs/` — every stage started, every outcome, every gate
   decision, timestamped, with a `cost` field in each stage envelope — and 0036's *Out of scope*
   says in as many words: *"A dashboard or reporting UI. FR10's log is on disk and read by a
   session."* That session is this ticket.
3. **The measurement exists once, as history, not as a habit.** `MEASUREMENT.md` and
   `tools/harvest-usage.sh` (0026) compute cost and context tokens per turn per skill, and record a
   verdict for the run of 2026-08-23/24. Re-running that per work session is nobody's job.

   **Amended 2026-09-02 — most of this gap has since been filled, and the figures quoted here were
   stale.** `tools/classify-turns.sh` (0073), `tools/cost-by-category.sh` and
   `tools/floor-probe.sh` (0085) are all committed and guarded, and between them they compute cost
   and context per turn per skill, per category, and the startup floor's composition, over any
   window. The cost half of this ticket is now *running committed scripts over a boundary*, not
   building a measurement. The baseline pair this item quoted — **$6.01 whole-run and $4.45 across
   the two closing gates** — is the stale cache `MEASUREMENT.md` names this ticket by ID for
   holding: the live pair is **$5.71 and $4.23**, and it is read from `MEASUREMENT.md` rather than
   copied here, precisely so it cannot go stale a second time.
4. **Two of the requested figures are computed nowhere.** `harvest-usage.sh` emits cost, tokens and
   context per turn; it emits **no elapsed wall-clock time**, so neither "time to complete a context
   window" nor "total time for the work session" is derivable from what the repo has.

And there are no release notes of any kind. `DONE.md` is a list of closed ticket rows, which is
provenance rather than notes — `launch-conventions.md` requires notes that say what changed, who it
is for, what to do, and what did not change.

## Functional requirements

The requirements below are the **content** of the review, and they hold whichever placement the
design question settles. **Design adds the FRs that name the invocation, the output path and the
file that implements them** — see *Open design question*.

- **FR1 — Report the tickets the work session closed.** ID, title, and the verdict that closed each
  one, read from the record on disk — `DONE.md` and the FR10 run log — never from a session's memory.
- **FR2 — Write release notes to a shareable file.** Per `launch-conventions.md`: what changed, who
  it is for, what to do, and what did **not** change. A ticket ID is provenance, not a release note;
  an entry whose only description of a change is its ID does not satisfy this.
- **FR3 — The figures come from the committed scripts, and this ticket writes no arithmetic of its
  own.** `tools/harvest-usage.sh` for cost and context per turn per skill, `tools/classify-turns.sh`
  for turns per session, `tools/cost-by-category.sh` for where the money went. The report states
  which script produced each figure and over what window, so every number is re-runnable by the
  reader — 0026's FR3 precedent, discharged by citation rather than by new code.
- **FR4 — Elapsed wall-clock time, which is the one figure no script emits.** Per context window and
  per work session. This is the only measurement work left in this ticket, and it is the part of
  Aaron's original ask that nothing since has delivered.
- **FR5 — Cost per closed ticket, read from `MEASUREMENT.md` rather than copied into this ticket.**
  A run reads as better or worse against the record's current pair; an item that hard-codes the pair
  is a second cache of a live figure, which is the defect `0051` repaired and which this item was
  itself named for holding.
- **FR6 — The report names the boundary it counted over, and how that boundary was derived** — a run
  id, a date range, or a marker. A total whose scope a reader has to guess cannot be compared with
  the next one.
- **FR7 — Degrade honestly where there is no run log.** The plugin is public and installed on
  backlogs that will never run a supervisor. Where the session boundary or an attribution cannot be
  established, the report says what it could not attribute and does not present a partial total as a
  complete one.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Privacy & data | The computation reads full conversation transcripts and its output is **written to be shared**, and eventually emailed. It emits only aggregate figures, skill names, session-id prefixes and ticket titles the project already tracks — no message text, no file contents, no path outside the project. On a `routing.company` project the notes can carry customer-identifying ticket content, so the output path and its audience are the project's to declare and not this ticket's to assume | `data-privacy-conventions.md` |
| Security | The review reads and writes locally and sends nothing. Any outward-facing send is a separate, separately approved step — see *Out of scope* | `security-conventions.md` |
| Measurement | Figures carry their date, their rate card and what was not held constant, and the report states the verdict its numbers imply rather than only the numbers — including an unflattering one | `measurement-conventions.md` |
| Compatibility | Every signal the review reads is a contract between the stages and the reviewer. Adding it must not change what a hand-driven session does | `api-conventions.md` |
| Dependencies | Runs on what the repo already has — POSIX `sh` plus the `python3` already on the machine. Reading one directory of JSON earns no package, and outbound mail is out of scope precisely because it would earn one | `dependency-conventions.md` |
| Documentation | `README.md` is the canonical statement of how this suite is run. If this adds an invocation, that section changes in the same change | `documentation-conventions.md` |

## Open design question

- **Question:** Where does the work-session review live — **its own skill**, a **second mode of
  `retro`**, a **step in `orchestrate`'s FR4 ending**, or a **`tools/` script** that whichever
  session needs it runs?

- **Why it blocks specification:** FR2's output path, FR7's implementing file, and the invocation
  every AC would name are all determined by the answer. It also decides whether this ticket gains
  `blocked_by: "0039"`, which changes when it can be built at all.

- **Five sub-questions, each with a decidable answer:**
  1. Skill, `retro` mode, `orchestrate` step, or `tools/` script? **Weigh this against a smaller
     ticket than the one first written** — with the cost tooling already built and guarded, the
     deliverable is release notes plus a wrapper, which makes a seventh skill harder to justify.
  2. Does the review **require** 0039's run log, or does it work today from `DONE.md` dates plus
     transcript timestamps? If it requires it, design records the `blocked_by`.
  3. Are the release notes and the metrics **one artifact or two**? They have different audiences —
     the notes are shareable and eventually emailed; the cost figures are internal.
  4. Which clock is authoritative for elapsed time — **transcript turn timestamps** or **run-log
     event timestamps** — and does `harvest-usage.sh` grow the timing, or does a sibling own it?
     This is now the ticket's only unbuilt measurement, per FR4.
  5. If the answer is a new skill: does a seventh skill in the suite **pay its rent**, against
     `retro`'s own argument that the cheapest nothing is the one not run, and against 0021's trim?

- **Inputs to weigh, so design does not re-derive them:** `retro` runs on a cadence and is not a
  lifecycle stage, and 0036 FR4 already ends every supervised run *with* a retro — so the two
  candidates that need no new invocation are a `retro` mode and an `orchestrate` step, and both
  couple a delivery report to a process review that may run on a different rhythm. `retro`'s
  measured cost was **$5.50, 36% of that run**, at the lowest output per turn of any phase, because
  it ran last where context was largest; adding work to it lands in the most expensive turn in the
  suite.

- **Settle it with:** `/design`.

## Acceptance criteria

Placement-independent, so they survive whatever the design question settles. **Design adds the ACs
that name the invocation, the output path and the implementing file.**

- [ ] AC1 — Given a work session whose boundary is stated, when the review runs, then its output
      lists every ticket that closed inside that boundary with ID, title and closing verdict, and
      lists no ticket that closed outside it.
- [ ] AC2 — Given the release-notes file, when read, then it states what changed, who it is for, what
      to do and what did not change, and no entry describes a change only by its ticket ID.
- [ ] AC3 — Given the review's output, when read, then every context window in the session appears
      with its elapsed wall-clock time, its token count, its dollar cost, and the skill that ran in
      it.
- [ ] AC4 — Given the same output, when read, then it reports total elapsed time, total cost, average
      elapsed time per context window and average cost per context window.
- [ ] AC5 — Given the same output, when read, then it reports cost per closed ticket for the session
      alongside the whole-run and develop-plus-verify pair **read from `MEASUREMENT.md` at the time
      the report runs**, with the as-at date it was read — and the file contains no second copy of
      that pair.
- [ ] AC6 — Given the same output, when read, then every figure names the committed script that
      produced it and the window it was computed over, so a reader can re-run it — and no dollar
      figure in the report was computed inside a transcript.
- [ ] AC7 — Given a backlog with no run log present, when the review runs, then it names what it
      could not attribute and does not present its totals as complete.
- [ ] AC8 — Given the same output, when read, then it names the boundary it counted over and how that
      boundary was derived.
- [ ] AC9 — Given a fixture transcript carrying a sentinel string in its message text, when the
      computation runs over it, then the sentinel appears nowhere in the output.
- [ ] AC10 — Given a fixture in which two content-block lines repeat one `message.id`, when the
      computation runs, then that turn is counted once.

## QA plan

- **Level:** `unit` — chosen at queue time.
- **Why this level:** the load-bearing part is arithmetic with a right and a wrong answer — boundary
  selection, per-turn de-duplication by `message.id`, elapsed-time derivation, attribution to a
  skill — and this repo already guards its sibling that way: `tests/measurement.test.sh` covers
  `tools/harvest-usage.sh` with fixtures. The project's `unit` command runs **every**
  `tests/*.test.sh`, so it also carries any scripted prose assertion the placement turns out to
  need, and no separate `verify` level is required. Design may narrow the fixture set; it does not
  lower the level.
- **Specific checks:**
  - Fixture assertions for: boundary selection including and excluding the right sessions; elapsed
    time computed from known timestamps; per-skill attribution; the no-run-log degradation path of
    AC7; the AC9 privacy sentinel; the AC10 repeated-`message.id` turn; and the existing suite's
    character-set assertion, that every output line stays inside a set too narrow for prose.
  - The whole suite: `for t in tests/*.test.sh; do "$t" || exit 1; done`.
  - The release-notes file read end to end against AC2, since a file that satisfies a grep and reads
    as a ticket dump has failed FR2.

## Out of scope

- **Sending the email.** Requested as "eventually" and it needs its own ticket: it adds an egress
  destination and an outbound-mail dependency this suite does not have, and an outward-facing send
  needs explicit approval per `security-conventions.md`. **The design must not preclude it** — the
  notes are a file, and a sender reads that file.
- **A dashboard or reporting UI.** The same line 0036 already drew.
- **Attributing cost below the context window.** Under one skill per session there is one agent per
  window, so "broken down by agent" *is* the per-skill breakdown — see *Notes & decisions*.
  Sub-agent attribution is a new ticket if sub-agents ever appear inside a stage.
- **Re-running or revising 0026's baseline.** This reports a run against `MEASUREMENT.md`; that
  file's recorded verdict stands.
- **Changing what any stage checks, or what `retro` does with `FINDINGS.md`.**
- **Making the review a lifecycle stage or a `next:` value.** Like `retro`, it reviews a run rather
  than advancing a ticket.

## Notes & decisions

- **Routed to `design` — 2026-08-25.** At Aaron's explicit request, and the trigger is genuine
  (`queue` trigger 1): the placement decides FR2's output path, FR7's file, and every AC that would
  name an invocation, so those acceptance criteria cannot be written until it is settled. The
  content requirements above did not need it and are written.
- **"Broken down by which agent was run in the context window" resolves to per-skill.** One skill per
  session means one agent per context window, so the requested breakdown is the per-skill table
  `harvest-usage.sh` already produces — cost, cost per turn, context per turn and output share, by
  skill. Recording this so design does not treat it as an open modelling question.
- **What already exists, so design does not re-derive it.** `tools/harvest-usage.sh` computes cost,
  tokens and context per turn per skill from `~/.claude/projects/<slug>/*.jsonl`, takes `--since`,
  `--until`, `--sessions` and `--exclude`, and carries 0026's privacy rule and the non-obvious
  mechanism that a turn is a distinct `message.id` because one API response is written as several
  lines each repeating the whole `usage` object. It computes **no elapsed time**. `MEASUREMENT.md`
  holds the recorded per-skill figures and the per-closed-ticket baseline — **$5.71 / $4.23** as at
  2026-09-02, cited rather than copied per FR5.
- **Not `blocked_by: "0039"` today, deliberately.** `DONE.md` carries a `closed:` date per ticket and
  the transcripts carry per-turn timestamps, so a date-bounded review is computable with no run log —
  which is also what FR7 requires for the installed-elsewhere case. Sub-question 2 is design's to
  settle, and if it concludes the run log is required, design records the `blocked_by` then rather
  than this ticket asserting a dependency it has not established.
- **Amended 2026-09-02, before any claim, and the scope narrowed rather than widened.** The cost
  half of this ticket was built underneath it while it sat in the queue: `tools/classify-turns.sh`,
  `tools/cost-by-category.sh` and `tools/floor-probe.sh` all landed on 2026-09-02 with guards, so
  FR3–FR7 as first written would have re-specified working code. What is left that nothing else
  covers is **the release notes** — `DONE.md` is provenance, not notes — plus **elapsed wall-clock
  time**, which no script emits. Re-checked per `queue`'s amend rule: **`size` drops `l` → `m`**
  (the measurement build is gone, the notes and one clock remain); **AC5 and AC6 were
  rewritten** — AC5 cited the stale pair directly and now reads it from `MEASUREMENT.md` with an
  as-at date, AC6 asked for arithmetic reproducible by hand and now asks which script and window
  produced each figure; AC1–AC4 and AC7–AC9 stand; the QA plan is unchanged; *Out of scope* is
  unchanged.
- **The stale figures were corrected in the same pass.** `MEASUREMENT.md`, *Cost per closed ticket*,
  names `0036`, `0040` and `0041` as holding a stale cache of $6.01/$4.45. This item now cites the
  record instead of copying it, which is the only fix that does not decay again.
- **Its rank rests on the token-efficiency instruction, and that claim is now weaker.** This row sits
  above two Tier 1 rows (`0052`, `0046`) by Aaron's standing instruction of 2026-08-30. The part of
  it that served that instruction — measuring what a run costs — is built and published; what
  remains is a reporting feature. `RANKING.md` records that, so the next re-rank argues with a
  current statement rather than a spent one.
