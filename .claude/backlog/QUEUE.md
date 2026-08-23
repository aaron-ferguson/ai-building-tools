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

Statuses: `design` (a decision is missing — see the ticket) · `ready` (passes the readiness gate,
pick it up) · `in-progress` (a session holds a claim) · `blocked` (an open `blocked_by`, or an
external blocker named in the ticket) · `needs-qa` (built, not verified). Completed tickets move
to `DONE.md`; dormant scheduled ones live in `SCHEDULED.md`.

**A task with an open blocker is never `ready`.** That is derived from the graph, not a judgement
call, and `develop` refuses the row even if the status says otherwise.

Ownership is not a column. A claim is the directory `claims/<id>/`, created with `mkdir` — which
either succeeds or fails, so claiming needs no lock. **A claim you did not create in this
conversation belongs to another session.**

| ID | Title | Type | Size | QA | Status | Parent | Item |
|------|-------|------|------|----|--------|--------|------|
| 0010 | Split Status into Next and Status, and pare QUEUE.md | chore | m | verify | ready | 0009 | [items/0010-next-and-status-fields.md](items/0010-next-and-status-fields.md) |
| 0012 | Every session ends by parking what surprised it | chore | s | verify | ready | 0009 | [items/0012-park-findings-every-session.md](items/0012-park-findings-every-session.md) |
| 0013 | Verify closes the ticket; develop stops at next verify | chore | m | verify | blocked | 0009 | [items/0013-verify-closes-the-ticket.md](items/0013-verify-closes-the-ticket.md) |
| 0011 | Add the Waiting on section and rewrite next for the new fields | chore | m | verify | blocked | 0009 | [items/0011-waiting-on-and-next-reader.md](items/0011-waiting-on-and-next-reader.md) |
| 0014 | Queue sweeps FINDINGS.md for units of work | chore | s | verify | blocked | 0009 | [items/0014-queue-sweeps-the-findings-buffer.md](items/0014-queue-sweeps-the-findings-buffer.md) |
| 0015 | Remove cross-skill invocation | chore | s | verify | blocked | 0009 | [items/0015-remove-cross-skill-invocation.md](items/0015-remove-cross-skill-invocation.md) |
| 0016 | Make retro a batch process over many sessions | chore | m | verify | blocked | 0009 | [items/0016-retro-as-a-batch-process.md](items/0016-retro-as-a-batch-process.md) |
| 0017 | Document one skill per session, with the measurement | chore | s | verify | blocked | 0009 | [items/0017-document-one-skill-per-session.md](items/0017-document-one-skill-per-session.md) |
| 0018 | Queue routes to design rather than design screening everything | chore | s | verify | blocked | 0009 | [items/0018-queue-routes-to-design.md](items/0018-queue-routes-to-design.md) |
| 0019 | Design asks on taste, decides on fact, and writes the ticket itself | chore | s | verify | blocked | 0009 | [items/0019-design-escalation-and-writes.md](items/0019-design-escalation-and-writes.md) |
| 0020 | Split CONCURRENCY.md into rules and incidents | chore | m | verify | blocked | 0009 | [items/0020-split-concurrency-rules-from-incidents.md](items/0020-split-concurrency-rules-from-incidents.md) |
| 0021 | Hold the skills to the conventions' own context-rent rule | chore | m | verify | blocked | 0009 | [items/0021-trim-the-skills.md](items/0021-trim-the-skills.md) |
| 0005 | Add the graph fields to the ticket template and QUEUE.md | chore | s | verify | ready | 0002 | [items/0005-add-graph-fields-to-template.md](items/0005-add-graph-fields-to-template.md) |
| 0007 | Replace the Owner column with claim directories | chore | s | verify | blocked | 0002 | [items/0007-claim-directories.md](items/0007-claim-directories.md) |
| 0006 | Rewrite next to parse by header name and walk ancestors | chore | m | verify | blocked | 0002 | [items/0006-rewrite-next-reader.md](items/0006-rewrite-next-reader.md) |
| 0008 | Add the graph rules to queue, develop, and verify | chore | m | verify | blocked | 0002 | [items/0008-graph-rules-in-skills.md](items/0008-graph-rules-in-skills.md) |
| 0003 | Phase 2 — the readiness gate and outcome reviews | feature | l | verify | blocked | 0001 | [items/0003-phase-2-readiness-and-outcomes.md](items/0003-phase-2-readiness-and-outcomes.md) |
| 0004 | Phase 3 — extend tracker mirroring with hierarchy and standards | feature | l | verify | blocked | 0001 | [items/0004-phase-3-jira-bridge.md](items/0004-phase-3-jira-bridge.md) |

`develop` takes the topmost row whose status is `ready`. If the first row is `blocked` or
`design`, it says so and takes the next `ready` row rather than silently reordering.

Concurrency rules for anything writing this file: `CONCURRENCY.md` in the `ai-building-tools`
plugin (`references/CONCURRENCY.md` at its root).
