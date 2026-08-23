# Backlog concurrency protocol

Read by every skill before it touches a backlog file. **Rules are named, not numbered** — cite by
name. **`CONCURRENCY-INCIDENTS.md` holds each rule's incident, its reasoning, and what to do in a live
conflict**; read it then, or to argue with a rule. **Part 1 applies everywhere; Part 2 only to the
`QUEUE.md` backend**, since a tracker's API write is the whole transaction.

---

# Part 1 — Two sessions, one repository

## The git index is shared, and it is the easiest thing to lose work to

One staging area per repository, no lock, no token: any session can commit what another staged.

- **Commit by pathspec — `git commit -m "…" -- <paths>`.** Bare `git commit` writes the whole index,
  so `git add <mine> && git commit` still takes their work. Never `-a`, `add .`, `add -A`. A file git
  does not know yet needs **`git add -N` first**, or the pathspec fails.
- **Stage and commit in one turn** — staged work is exposed until it lands — and **read back**
  (`git diff --cached --name-only`), then `git restore --staged` anything not yours.
- **Never bare `git stash`**; it takes their uncommitted work. **Your message on their change → report,
  never rewrite history.**

### A pathspec is necessary but **not sufficient**, and this is the part that surprises people

It limits the commit to the paths you name, **not to the changes you made** — their edits to those
paths go too, and **nothing you do prevents it**. Prefer single-writer files, and know **the shared
ones are more than the queue**: the project's own docs are written by every session as it commits.

## The working tree is shared too, so claim files as well as rows

A row claim owns the *work*, not the *files*: two sessions can hold different rows and still spend an
hour in one component, unwarned.

- **Compare your candidate's `expects:` against every `in-progress` `touches:` before claiming.**
  Overlap means pick differently: take the next clear `ready` row, name the one you stepped over. All
  rows collide → nothing is developable right now.
- **`queue` writes `expects:`** (predicted, code open); **`develop` writes `touches:` on claim**
  (actual, checked against the code, never copied). Why two fields: `CONCURRENCY-INCIDENTS.md`.
- **Widen `touches:` as the work reaches further**, and read an **empty `touches:` on an `in-progress`
  row as "held"** — silence is not permission.
- **`verify` marks its verdict advisory** on changes outside the ticket: a suite over a file set that
  never existed means nothing either way.

## A claim must be durable the moment it is made

A claim only you can see reads as taken to you and free to everyone else, and both proceed. **Durable
= visible to the other session with no further act by you.** Tracker-backed, the API write is it.
Local file, **only once committed** — inside the lock, same turn, or the next session to commit the
file carries it off under its own message.

## A stage writes only the ticket it holds

**Replaces *`verify` never writes the queue***, which guarded a hazard one-skill-per-session removed.

- **Write nothing another session reads for coordination while it holds the ticket.** Claim the row
  you write; write only that row and its item file. **One exception, and it is narrow:** closing a
  ticket also reconciles the rows that named it in `blocked_by`, in the closing commit. `blocked` is
  derived from the graph, so the close is the only event that can clear those rows — leaving them is
  a queue that lies about what is takeable, which cost a whole session once. Reconcile no row another
  session holds `in-progress`; report it instead, and `./next --drift` will show its own session.
- **A stage finding a ticket at another stage refuses it** — `develop` skips `next: design`, `verify`
  refuses anything not `next: verify`. That field keeps two stages off one ticket.
- **`verify` owns closing**, holding the verdict when it acts, so no green goes stale.

---

# Part 2 — When the queue is a local file

## Never rewrite `QUEUE.md` by hand

`Edit` the one row you are changing. Never `Write`, never read-rebuild-write: a full-file write from a
copy read a minute ago clobbers every row touched since, with no conflict and no error. Hence **no `#`
column** — renumbering *is* that rewrite; count rows to learn a rank. Different rows need no
coordination. **`./claim` is the one exception**, earning it by holding the lock while it rebuilds.

## Re-read immediately before you write

Read the row again right before the `Edit`. `Edit` fails rather than guessing when `old_string` stops
matching — that is information, not an obstacle to route around.

## Lock every write to `QUEUE.md`

**Every write, no exemptions**: claiming an ID (`queue`), claiming a row (`develop`, `verify`), closing
a row (`verify`). Closing was once exempt — true of the *row*, false of the *file*, since the commit
takes the whole file.

**Hold it for the read, the write and the commit, then release in the same turn** — including where you
decide *not* to change anything; scripts release on failure paths via a `trap`. It guards a two-second
operation, never an implementation.

**The lock is `.claude/backlog/.lock/`, a directory, because `mkdir` is atomic on POSIX.** Put `$CLAIM`
and a UTC timestamp in `.lock/held-by`, so a busy lock says who holds it and since when; release with
`rm -rf`, never commit it. **Snippet and the busy/stale paths: `CONCURRENCY-INCIDENTS.md`.**

## Claim tokens: how a session knows what is its own

No ambient session id, so ownership is a minted token — `CLAIM=$(head -c2 /dev/urandom | xxd -p)` — in
the item's `claimed_by:` with `claimed_at:` (ISO-8601 UTC). **That is the token's home** — the pared
`QUEUE.md` has no ownership column. The row reads `in-progress`; report the token to the user.

**Ownership is memory, not inference: a ticket is yours only if you minted its token in this
conversation.** An unfamiliar token is the other window's — say so and ask, never take it over. A
`claimed_at` hours old with no matching work is a dead session: report it and offer to release it.

## The two scripts

Each encodes a rule above that is otherwise a matter of remembering. **`./claim <id> [token]`** does
the whole claim under the lock and **commits it** — the commit is the point, and a script cannot forget
it. **`./next`** only reads; `--help` lists its modes. Both refuse rather than guess.
