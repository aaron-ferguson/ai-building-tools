---
id: "0041"
title: Write release notes for what a work session delivered
type: feature
next: develop
status: ready
qa_level: unit
size: l
created: 2026-08-25
source: user
parent: "0128"
blocked_by: []
relates: ["0016", "0026", "0036", "0039", "0037", "0135"]
expects:
  - CHANGELOG.md
  - .claude/backlog/close
  - tests/close.test.sh
  - skills/verify/SKILL.md
  - tools/release
  - tests/release.test.sh
  - tools/harvest-usage.sh
  - tests/measurement.test.sh
  - tools/sprint-ledger.sh
  - tests/sprint-ledger.test.sh
  - .claude/backlog/LEDGER.md
  - skills/sprint/SKILL.md
  - README.md
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
  *(Design, 2026-09-12: this lands in the `LEDGER.md` block per FR9, and it lists the IDs the run
  log's `outcome` events closed.)*
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

**Placement FRs — added by design, 2026-09-12.** There are two artifacts with different audiences.
Neither is a new skill, a `retro` mode, or new work in the sprint tail. See *Notes & decisions*.

- **FR8 — Release notes are `CHANGELOG.md` at the repo root, and the stage that closes a ticket
  writes its entry.** `./close` takes an optional `--note <text>` and appends it under
  `## Unreleased` in the **same locked commit** that moves the row to `DONE.md`. If no note is given,
  nothing is appended: a ticket with no observable change records none and never pads the file.
  `verify` Step *close* writes the note, voiced as *what a session running these skills will do
  differently*, in plain language, leading with the behaviour and not the ticket ID. The ID may
  follow in parentheses as provenance.
- **FR9 — `tools/release` promotes `## Unreleased` to `## <version> — <date>`** in the same commit
  as the version bump. **It refuses before step 5's authorisation** (so it writes nothing) when
  `## Unreleased` is empty, unless it is given `--no-behaviour-change`. That flag writes the explicit
  line `No behaviour change — internal guards and records only.` in its place. The version section
  ends with a `### Did not change` line, and the release session writes it, because only a
  whole-release view can say what did not change.
- **FR10 — The metrics are the sprint's `LEDGER.md` block, which `tools/sprint-ledger.sh record`
  already writes, extended rather than duplicated.** It gains the closed-ticket list (FR1), and **a
  per-context-window table** with one row per session id: stage, first-to-last turn elapsed
  minutes, context tokens and USD. Totals and per-window averages are computed from those rows.
  Cost per closed ticket against `MEASUREMENT.md`'s pair is read at record time, with its as-at
  stamp (FR5).
- **FR11 — Per-window elapsed time is the first-to-last turn timestamp in the transcript, and
  `tools/harvest-usage.sh` owns it.** It gains a `--by-session` table (session-id prefix, skill,
  turns, elapsed minutes, context, USD) de-duplicated by `message.id` as today, and
  `sprint-ledger.sh` consumes it. Run-log timestamps keep bracketing the **sprint** total, which is
  unchanged from 0135.
- **FR12 — No run log, no ledger block; the notes are unaffected.** A hand-driven backlog still gets
  `CHANGELOG.md` from FR8–FR9. Its metrics are `tools/harvest-usage.sh --by-session --since/--until`,
  whose output names the date boundary and states that it attributes no run and no closed tickets
  (FR7).

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Privacy & data | The computation reads full conversation transcripts and its output is **written to be shared**, and eventually emailed. It emits only aggregate figures, skill names, session-id prefixes and ticket titles the project already tracks — no message text, no file contents, no path outside the project. On a `routing.company` project the notes can carry customer-identifying ticket content, so the output path and its audience are the project's to declare and not this ticket's to assume | `data-privacy-conventions.md` |
| Security | The review reads and writes locally and sends nothing. Any outward-facing send is a separate, separately approved step — see *Out of scope* | `security-conventions.md` |
| Measurement | Figures carry their date, their rate card and what was not held constant, and the report states the verdict its numbers imply rather than only the numbers — including an unflattering one | `measurement-conventions.md` |
| Compatibility | Every signal the review reads is a contract between the stages and the reviewer. Adding it must not change what a hand-driven session does | `api-conventions.md` |
| Dependencies | Runs on what the repo already has — POSIX `sh` plus the `python3` already on the machine. Reading one directory of JSON earns no package, and outbound mail is out of scope precisely because it would earn one | `dependency-conventions.md` |
| Documentation | `README.md` is the canonical statement of how this suite is run. If this adds an invocation, that section changes in the same change | `documentation-conventions.md` |

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

**Placement ACs — added by design, 2026-09-12.** AC1, AC3–AC6 and AC8 are confirmed and now name
their file, the `LEDGER.md` block written by `tools/sprint-ledger.sh record`. AC2 is changed: its
release-notes file is `CHANGELOG.md`, checked per version section (AC13). AC7 is confirmed and made
concrete by AC16. AC9 and AC10 are confirmed for `--by-session`.

- [ ] AC11 — Given a claimed ticket, when `./close <id> <token> --note "<text>"` runs, then
      `CHANGELOG.md` gains `<text>` under `## Unreleased` and `DONE.md` gains the row, both in
      **one** commit.
- [ ] AC12 — Given a claimed ticket, when `./close <id> <token>` runs with no `--note`, then
      `CHANGELOG.md` is unchanged, byte for byte.
- [ ] AC13 — Given `CHANGELOG.md` with entries under `## Unreleased`, when `tools/release --bump`
      completes, then those entries sit under `## <new version> — <date>`, `## Unreleased` is
      present and empty, and that edit is in the bump commit.
- [ ] AC14 — Given an empty `## Unreleased`, when `tools/release --bump` runs without
      `--no-behaviour-change`, then it exits non-zero before step 5 and nothing is committed,
      pushed or edited. With the flag, the version section carries the explicit no-change line.
- [ ] AC15 — Given a fixture transcript whose session's first and last turns are 42 minutes apart,
      when `tools/harvest-usage.sh --by-session` runs, then that session's row reads 42 elapsed
      minutes, alongside its skill, turns, context and USD.
- [ ] AC16 — Given a fixture run log and transcripts, when `tools/sprint-ledger.sh record` runs,
      then the appended block holds one per-window row per dispatched session id, the closed-ticket
      list, total and average elapsed time and cost, and cost per closed ticket beside
      `MEASUREMENT.md`'s pair with its as-at stamp.
- [ ] AC17 — Given `skills/verify/SKILL.md`, when grepped, then its close step instructs a `--note`
      voiced as what a session will do differently, plain language and ID not leading, and it
      instructs **no note** for a ticket with no observable change.

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

- **2026-09-09 — adopted as a child of `0128`.** The sprint project's capture session found this
  ticket already specifying what it was about to write a duplicate of: the Problem here quotes the
  original request for a *"Sprint Review"* with release notes and per-agent cost, which is the
  sprint record and the notes half of that project. Two decisions taken in the 2026-09-08 design
  conversation belong to this ticket's open design question and are recorded here rather than in a
  new row:
  - **The notes answer "what will a session running these skills do differently?"** This repo's users
    are sessions and other machines, so the generic product-changelog voice produces nothing. A
    ticket with no observable behaviour change is recorded as having none and never padded; a sprint
    whose notes read *"no behaviour change — internal guards only"* is an informative result.
  - **Notes are keyed to a released version, not to a sprint.** `deploy ≠ release ≠ launch`, and in
    this repo the release is the version bump plus the install, so a sprint does not necessarily
    release. The proposed shape is a `CHANGELOG.md` accumulating under an `Unreleased` heading which
    `tools/release` promotes to the version it bumps — which also gives the release chain a natural
    gate: refuse to release on an empty `Unreleased` section with no explicit no-change line.
  This is input to the design question, which stays open: where the review lives, and whether it is
  its own skill, is still undecided.

- **2026-09-12 — design settled the placement. There are two artifacts and no new skill.**
  - **Facts re-verified today.** `0135` closed 2026-09-12 and shipped `tools/sprint-ledger.sh`, and
    its `record` mode already derives sprint wall-clock from the run log's first and last stamps
    and cost over the run's session ids into a committed `LEDGER.md`. Most of FR3–FR6 therefore
    already has a home. The only unbuilt measurement is **per-window** elapsed time
    (`sprint-ledger.sh` has no per-session time; `harvest-usage.sh` reads `timestamp` only as a
    date, `[:10]`). `0039` is closed, so it cannot block. `DONE.md` carries dates, not times, which
    is why a sub-day boundary needs the run log. `.claude/backlog/runs/` does not exist in this
    repo yet: no sprint has run. `CHANGELOG.md` does not exist.
  - **Sub-question 1 — a `tools/` extension plus a note at close, not a skill.** The notes are
    written by `verify` through `./close --note`, and the metrics extend `sprint-ledger.sh`. The
    alternatives lose as follows.
    - A **seventh skill** would pay per-invocation instruction rent to wrap two scripts.
    - A **`retro` mode** would add the work to the most expensive turn in the suite, and couple a
      delivery report to a process review that only runs when the findings gate fires (0133).
    - A **sprint-tail step** would miss every hand-driven backlog, which FR7 requires this to serve.
    - **Generating notes at release from `DONE.md` or commits** would write them at the moment
      context is thinnest. `launch-conventions.md` requires notes *drafted in advance* in plain
      language, and a commit subject is neither.
    - `verify` has just read the ACs and evidence for exactly that change. This is the cheapest
      moment the "what will a session do differently" answer exists.
  - **Sub-question 2 — the run log is required for the metrics' sprint attribution, not for the
    notes.** No `blocked_by`, because 0039 and 0135 are both closed. Without a log, FR12 applies.
  - **Sub-question 3 — two artifacts.** `CHANGELOG.md` is keyed to a released version and
    shareable; the future email sender reads that one file. `LEDGER.md` is keyed to a sprint and is
    internal. This adopts the 2026-09-08 shape above as proposed.
  - **Sub-question 4 — transcript turn timestamps per window; run-log stamps for the sprint total.**
    Transcripts are the only clock present with no run log, and `harvest-usage.sh` already opens
    those files and de-duplicates turns. A sibling script would re-implement both.
  - **Sub-question 5 — no, so it does not arise.**
  - **Trade-offs accepted.**
    - Every `verify` close gains one sentence of work, and verify's instruction file grows by a
      paragraph.
    - Notes written per ticket can read as a list rather than a narrative. The release session's
      `### Did not change` line is the only whole-release prose.
    - First-to-last-turn elapsed time excludes process start-up and the wait before the first turn.
      That is an undercount the ledger must label, not hide.
  - **`size` raised `m` → `l`, and `expects:` rewritten** to the files the placement names. The
    work spans `close`, `release`, `harvest-usage`, `sprint-ledger` and `verify`. It splits cleanly
    into a notes half (FR8–FR9, AC11–AC14, AC17) and a timing half (FR10–FR11, AC15–AC16), with no
    shared file. If `queue` or `develop` finds `l` too big for one pass, split it along that line.
