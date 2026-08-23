# Backlog — ai-building-tools

**Stack ranked. Line order is the rank.** The first row is the next ticket to work on — there is
no priority column, because a priority column and a position can disagree and then nothing is
unambiguous. To reprioritise, move the line.

There is **no position number** either. Line order already carries the rank, and a `#` column
would have to be renumbered on every insert and every close — turning each one-row change into
a full-file rewrite, which is how two sessions working this backlog at once silently overwrite
each other. Do not add one.

**Only tasks appear here.** A ticket with children is an *effort*: it holds the outcome, the
scope, the measure and the coupling, and it is never ranked, claimed, or built. A ticket with no
children is a *task*, and tasks are where all the work lives. A task becomes an effort the moment
it gains a child, and its row leaves this file.

**Two columns, because they answer different questions.** `Next` is the *stage* — which skill
acts on this row: `queue` (not specified enough for any stage to take it) · `design` (a decision
has to be settled before acceptance criteria can exist) · `develop` (specified, build it) ·
`verify` (built, QA it). `Status` is the *state* — whether anything can act at all: `ready`
(passes the readiness gate) · `waiting` · `blocked` · `in-progress` (a session holds a claim).
Merged into one column a reader cannot filter for "work I can start" without already knowing
which values are stages and which are states. Completed tickets move to `DONE.md`; dormant
scheduled ones live in `SCHEDULED.md`.

**`waiting` is not `blocked`, and the difference is who clears it.** `waiting` means a **person**
is needed — an answer, a decision, an access grant — and only that person can clear it.
`blocked` means an open `blocked_by`, or an external blocker named in the ticket, and it clears
when that resolves. One value for both would mean opening the ticket to find out which kind of
stuck it is.

**A task with an open blocker is never `ready`.** That is derived from the graph, not a judgement
call, and `develop` refuses the row even if the status says otherwise.

The other columns are `ID`, `Title` and `Parent`, and there are no more. `Type`, `Size` and `QA`
changed no reader's behaviour at read time, and `Item` duplicated `ID` at the cost of most of the
row's width: **the `ID` resolves to `items/<id>-*.md` by glob.**

Ownership is not a column either. A claim is the directory `claims/<id>/`, created with `mkdir` —
which either succeeds or fails, so claiming needs no lock. **A claim you did not create in this
conversation belongs to another session.**

| ID | Title | Next | Status | Parent |
|------|-------|------|--------|--------|
| 0022 | Fix claim's fixed-index column parsing against the pared table | develop | ready | 0002 |
| 0014 | Queue sweeps FINDINGS.md for units of work | develop | blocked | 0009 |
| 0015 | Remove cross-skill invocation | develop | blocked | 0009 |
| 0016 | Make retro a batch process over many sessions | develop | blocked | 0009 |
| 0017 | Document one skill per session, with the measurement | develop | blocked | 0009 |
| 0018 | Queue routes to design rather than design screening everything | develop | ready | 0009 |
| 0019 | Design asks on taste, decides on fact, and writes the ticket itself | develop | ready | 0009 |
| 0020 | Split CONCURRENCY.md into rules and incidents | develop | blocked | 0009 |
| 0021 | Hold the skills to the conventions' own context-rent rule | develop | blocked | 0009 |
| 0005 | Add the graph fields to the ticket template and QUEUE.md | develop | ready | 0002 |
| 0007 | Replace the Owner column with claim directories | develop | blocked | 0002 |
| 0006 | Rewrite next to parse by header name and walk ancestors | develop | blocked | 0002 |
| 0008 | Add the graph rules to queue, develop, and verify | develop | blocked | 0002 |
| 0003 | Phase 2 — the readiness gate and outcome reviews | develop | blocked | 0001 |
| 0004 | Phase 3 — extend tracker mirroring with hierarchy and standards | develop | blocked | 0001 |

`develop` takes the topmost row that is `next: develop` and `status: ready`. If a higher row is
`waiting`, `blocked`, or at another stage, it says so and takes the next takeable row rather than
silently reordering.

Concurrency rules for anything writing this file: `CONCURRENCY.md` in the `ai-building-tools`
plugin (`references/CONCURRENCY.md` at its root).
