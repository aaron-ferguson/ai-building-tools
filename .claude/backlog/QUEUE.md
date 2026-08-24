# Backlog — ai-building-tools

**Stack ranked. Line order is the rank.** The first row is the next ticket to work on — there is
no priority column, because a priority column and a position can disagree and then nothing is
unambiguous. To reprioritise, move the line.

There is **no position number** either. Line order already carries the rank, and a `#` column
would have to be renumbered on every insert and every close — turning each one-row change into
a full-file rewrite, which is how two sessions working this backlog at once silently overwrite
each other. Do not add one.

**Only tasks appear here.** A ticket with children is a *project*: it holds the outcome, the
scope, the measure and the coupling, and it is never ranked, claimed, or built. A ticket with no
children is a *task*, and tasks are where all the work lives. A task becomes a project the moment
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
`blocked` means an open `blocked_by`, and it clears when the ticket it names closes. One value
for both would mean opening the ticket to find out which kind of stuck it is.

**`blocked` is DERIVED, never authored.** A row is blocked if and only if its item's `blocked_by`
names at least one ticket that is not `done` — nobody types `blocked` into this column as a
judgement. The column is a *cache* of that answer, kept so the file reads correctly on its own,
and the graph is the authority whenever the two disagree. Two consequences, and neither is
optional: **closing a ticket reconciles every row that named it in `blocked_by`, in the same
commit as the close**, because a blocker that clears without touching its dependents is exactly
how the cache goes stale; and `./next --drift` reports every row where cache and graph disagree,
in both directions, exiting non-zero so a script can gate on it. A stale `blocked` hides takeable
work and no reader ever notices — it once left four rows unavailable for a whole session — which
is why `./next` offers a row on the graph's answer whatever this column says.

Something blocked by anything that is **not** a ticket is not `blocked`: if a person clears it,
the row is `waiting` with the question in its `## Waiting on` section; if an external event does,
capture that event as a ticket and name it in `blocked_by`. There is no third case, because a
`blocked` this column cannot derive is a `blocked` nothing can ever clear.

The other columns are `ID`, `Title` and `Parent`, and there are no more. `Type`, `Size` and `QA`
changed no reader's behaviour at read time, and `Item` duplicated `ID` at the cost of most of the
row's width: **the `ID` resolves to `items/<id>-*.md` by glob.**

Ownership is not a column either. **As built, a claim is the token in the item's `claimed_by:`,
taken under `.lock/` and committed inside it** — `CONCURRENCY.md`, *Claim tokens* and *A claim must
be durable the moment it is made*. **A token you did not mint in this conversation belongs to
another session.**

The `claims/<id>/` directory scheme is **0007's target design and is not built** — do not claim
that way today. `CONCURRENCY.md` warns why the naive form cannot work as stated: git records no
empty directory, so a bare `mkdir` claim stays invisible to the other session and is carried off
by the next commit. This paragraph described that design as current fact and was corrected on
2026-08-23; 0007 owns replacing it.

| ID | Title | Next | Status | Parent |
|------|-------|------|--------|--------|
| 0026 | Measure the isolated workflow from the recorded sessions and record the verdict | verify | ready | 0009 |
| 0029 | Reconcile close's definition of held with CONCURRENCY.md's | develop | in-progress | — |
| 0031 | Strip YAML comments in next and claim's fm_list | develop | in-progress | — |
| 0032 | Terminate batching.test.sh's paragraph window on a blank line | develop | ready | — |
| 0033 | Guard against stale rule-name citations across the references | develop | ready | — |
| 0034 | Derive the advisory label from the paths the verdict rested on | develop | ready | — |
| 0036 | Orchestrate the isolated stage sessions from one supervising session | develop | ready | — |
| 0035 | Decide where conditionally-needed skill detail lives | design | ready | — |
| 0007 | Replace the Owner column with claim directories | develop | ready | 0002 |
| 0006 | Rewrite next to parse by header name and walk ancestors | develop | blocked | 0002 |
| 0008 | Add the graph rules to queue, develop, and verify | develop | blocked | 0002 |
| 0003 | Phase 2 — the readiness gate and outcome reviews | develop | blocked | 0001 |
| 0004 | Phase 3 — extend tracker mirroring with hierarchy and standards | develop | blocked | 0001 |
| 0037 | Run the fresh-project end-to-end exercise against the settled configuration | develop | blocked | 0009 |

`develop` takes the topmost row that is `next: develop` and takeable — `ready`, or `blocked` with
nothing left open in `blocked_by`, since the column is only a cache of the graph. If a higher row
is `waiting`, genuinely blocked, or at another stage, it says so and takes the next takeable row
rather than silently reordering.

Concurrency rules for anything writing this file: `CONCURRENCY.md` in the `ai-building-tools`
plugin (`references/CONCURRENCY.md` at its root).
