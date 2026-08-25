---
id: "0041"
title: Report what a work session delivered and what it cost
type: feature
next: design
status: ready
qa_level: unit
size: l
created: 2026-08-25
source: user
parent:
blocked_by: []
relates: ["0016", "0026", "0036", "0039", "0037"]
expects:
  - tools/harvest-usage.sh
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
   verdict for the run of 2026-08-23/24. Re-running that per work session is nobody's job, and the
   figures that make a run readable — **cost per closed ticket, $6.01 whole-run and $4.45 across the
   two closing gates** — are recorded for one historical run and computed for no later one.
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
- **FR3 — Per-context-window metrics.** For each context window in the session: elapsed wall-clock
  time, tokens, dollar cost, and the skill that ran in it.
- **FR4 — Work-session totals and averages.** Total elapsed time, total cost, average elapsed time
  per context window, average cost per context window.
- **FR5 — Cost per closed ticket, stated against the recorded baseline.** `MEASUREMENT.md`'s
  observed $6.01 whole-run and $4.45 develop-plus-verify figures are the comparison, so a run can be
  read as better or worse rather than only as a number.
- **FR6 — Every figure is re-computable.** The rate card, its source, the token counts and the
  boundary are all stated, per 0026's FR3 precedent. A dollar figure whose arithmetic cannot be
  re-run is not a measurement.
- **FR7 — The computation is a committed, re-runnable script.** Not arithmetic done inside a
  transcript: `tools/harvest-usage.sh` extended, or a sibling under `tools/`, with its guard in
  `tests/`. This is the requirement that keeps FR3–FR6 from being a description of a mechanism with
  no code behind it, and it is the same argument 0026's FR10 made.
- **FR8 — The report names the boundary it counted over, and how that boundary was derived** — a run
  id, a date range, or a marker. A total whose scope a reader has to guess cannot be compared with
  the next one.
- **FR9 — Degrade honestly where there is no run log.** The plugin is public and installed on
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
  1. Skill, `retro` mode, `orchestrate` step, or `tools/` script?
  2. Does the review **require** 0039's run log, or does it work today from `DONE.md` dates plus
     transcript timestamps? If it requires it, design records the `blocked_by`.
  3. Are the release notes and the metrics **one artifact or two**? They have different audiences —
     the notes are shareable and eventually emailed; the cost figures are internal.
  4. Which clock is authoritative for elapsed time — **transcript turn timestamps** or **run-log
     event timestamps** — and does `harvest-usage.sh` grow the timing, or does a sibling own it?
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
      alongside `MEASUREMENT.md`'s recorded $6.01 whole-run and $4.45 develop-plus-verify figures.
- [ ] AC6 — Given the same output, when the rate card and the token counts in it are read, then every
      dollar figure can be recomputed from them by hand.
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
  holds the recorded per-skill figures and the $6.01 / $4.45 per-closed-ticket baseline.
- **Not `blocked_by: "0039"` today, deliberately.** `DONE.md` carries a `closed:` date per ticket and
  the transcripts carry per-turn timestamps, so a date-bounded review is computable with no run log —
  which is also what FR9 requires for the installed-elsewhere case. Sub-question 2 is design's to
  settle, and if it concludes the run log is required, design records the `blocked_by` then rather
  than this ticket asserting a dependency it has not established.
