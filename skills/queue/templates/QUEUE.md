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

A `design` row keeps its rank. The work is worth what it was worth, and sinking it would mean
rediscovering why it mattered later.

The remaining columns are `ID`, `Title` and `Parent`. There is no `Type`, `Size`, `QA` or `Item`
column: none of them changes a reader's behaviour at read time, and the ticket the reader is
about to take is a file they open anyway. **The `ID` resolves to `items/<id>-*.md` by glob**, so
the path is not worth a column — it was the bulk of every row.

| ID | Title | Next | Status | Parent |
|------|-------|------|--------|--------|
|  |  |  |  |  |

`develop` takes the topmost row that is `next: develop` and `status: ready`. If a higher row is
`waiting`, `blocked`, or at another stage, it says so and takes the next takeable row rather than
silently reordering — a `design` row has no acceptance criteria to build against, so taking it
would mean inventing them.

Concurrency rules for anything writing this file: `CONCURRENCY.md` in the `ai-building-tools`
plugin (`references/CONCURRENCY.md` at its root).
