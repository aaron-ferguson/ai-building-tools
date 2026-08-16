# Backlog — <Project>

**Stack ranked. Line order is the rank.** The first row is the next item to work on — there is
no priority column, because a priority column and a position can disagree and then nothing is
unambiguous. To reprioritise, move the line.

There is **no position number** either. Line order already carries the rank, and a `#` column
would have to be renumbered on every insert and every close — turning each one-row change into
a full-file rewrite, which is how two sessions working this backlog at once silently overwrite
each other. Do not add one.

Statuses: `design` (cannot be specified yet — see below) · `ready` (pick it up) ·
`in-progress` (a session has it) · `blocked` (see item file) · `needs-qa` (built, not verified).
Completed items move to `DONE.md`.

**`design` is not `blocked`.** Blocked means something external must happen first. Design means
the item cannot yet have acceptance criteria written, because a question has to be settled —
which pattern, which flow, what the empty state is. It keeps its rank: the work is worth what
it was worth, and sinking it would mean rediscovering why it mattered later.

`Owner` holds the claim token of the session working the row, or `—`. **A row whose token you
did not mint belongs to another session** — leave it alone and take the next `ready` row.

| ID | Title | Type | Size | QA | Status | Owner | Item |
|------|-------|------|------|----|--------|-------|------|
|  |  |  |  |  |  | — |  |

`develop` takes the topmost row whose status is `ready`. If the first row is `blocked` or
`design`, it says so and takes the next `ready` row rather than silently reordering — a `design`
row has no acceptance criteria to build against, so taking it would mean inventing them.

Concurrency rules for anything writing this file: `CONCURRENCY.md` in the `ai-building-tools`
plugin (`references/CONCURRENCY.md` at its root).
