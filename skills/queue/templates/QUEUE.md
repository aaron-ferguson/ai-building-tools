# Backlog — <Project>

**Stack ranked. Line order is the rank.** The first row is the next item to work on — there is
no priority column, because a priority column and a position can disagree and then nothing is
unambiguous. To reprioritise, move the line.

There is **no position number** either. Line order already carries the rank, and a `#` column
would have to be renumbered on every insert and every close — turning each one-row change into
a full-file rewrite, which is how two sessions working this backlog at once silently overwrite
each other. Do not add one.

**Two columns, because they answer different questions.** `Next` is the *stage* — which skill
acts on this row: `queue` (not specified enough for any stage to take it — captured half-baked,
or found stale by a later stage) · `design` (a decision has to be settled before acceptance
criteria can exist) · `develop` (specified, build it) · `verify` (built, QA it). `Status` is the
*state* — whether anything can act at all: `ready` · `waiting` · `blocked` · `in-progress`.
Merged into one column a reader cannot filter for "work I can start" without already knowing
which values are stages and which are states.

**`waiting` is not `blocked`, and the difference is who clears it.** `waiting` means a **person**
is needed — an answer, a decision, an access grant — and only that person can clear it.
`blocked` means an open `blocked_by`, and it clears when the ticket it names closes. One value
for both would mean opening the ticket to find out which kind of stuck it is, and there is
nothing a session could do about either without knowing.

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

A `design` row keeps its rank. The work is worth what it was worth, and sinking it would mean
rediscovering why it mattered later.

The remaining columns are `ID`, `Title` and `Parent`. There is no `Type`, `Size`, `QA` or `Item`
column: none of them changes a reader's behaviour at read time, and the ticket the reader is
about to take is a file they open anyway. **The `ID` resolves to `items/<id>-*.md` by glob**, so
the path is not worth a column — it was the bulk of every row.

| ID | Title | Next | Status | Parent |
|------|-------|------|--------|--------|
|  |  |  |  |  |

`develop` takes the topmost row that is `next: develop` and takeable — `ready`, or `blocked` with
nothing left open in `blocked_by`, since the column is only a cache of the graph. If a higher row
is `waiting`, genuinely blocked, or at another stage, it says so and takes the next takeable row
rather than silently reordering — a `design` row has no acceptance criteria to build against, so
taking it would mean inventing them.

Concurrency rules for anything writing this file: `CONCURRENCY.md` in the `ai-building-tools`
plugin (`references/CONCURRENCY.md` at its root).
