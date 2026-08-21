# Backlog concurrency protocol

Read by `queue`, `develop`, and `verify`. The backlog is designed to be worked by **two or more
sessions at once** — typically one window developing while another queues feedback and verifies.
These rules are what make that safe. They are not optional; a session that ignores them silently
destroys another session's work.

**The rules are named, not numbered.** Inserting one in the middle would renumber every citation
elsewhere, which is the same failure the queue table avoids by having no position column. Cite a
rule by its name.

The file is in two parts, and **which part applies depends on where the queue lives**:

- **Part 1 — Two sessions, one repository.** Applies to *every* project. Two agent sessions
  sharing a working tree contend over git itself, whatever the backlog is stored in.
- **Part 2 — When the queue is a local file.** Applies only to the `QUEUE.md` backend. A project
  whose backlog lives in Jira or Notion can skip it entirely: there is no lock, no row editing and
  no commit, because the tracker is the store and its API write is the whole transaction.

Mixing the two is a real cost, not a tidiness point — it tells a tracker-backed project to take a
directory lock it has no use for, and buries the rules it does need.

---

# Part 1 — Two sessions, one repository

Applies to every project regardless of where the queue lives.

## The git index is shared, and it is the easiest thing to lose work to

The queue has locks and tokens. The index has neither: it is one staging area per repository, and
any session can commit what another session has staged.

**This is not hypothetical.** A window running `queue` committed with the index swept whole and
carried off a developing window's staged file deletion, so that deletion is recorded in a commit
about an unrelated backlog entry. Nothing errored. Neither session noticed until afterwards.

- **Commit by pathspec: `git commit -m "…" -- <paths>`.** `git commit` writes the *whole index*,
  not the paths you staged a moment ago, so even a disciplined `git add <my files> && git commit`
  carries off anything the other window left staged. `git commit -a` and `git add .` / `-A` are
  worse again.
- **Stage and commit in the same turn.** Staged work is exposed until it lands, so staging before
  a long test run and committing after it holds the window open for exactly the loss above.
- **Read back what you are about to commit.** `git diff --cached --name-only` before every commit;
  if a path in it is not yours, `git restore --staged <path>` instead of committing it.
- **Never bare `git stash`** — it takes the other window's uncommitted work with it. Scope it to
  your own paths (`git stash push -u <path>…`), or do not stash at all.
- A commit describes the work of the session that made it. If you find another session's change
  already committed under your message, say so plainly in your report — do not rewrite their
  history to tidy it.

### A pathspec is necessary but **not sufficient**, and this is the part that surprises people

A pathspec limits the commit to the paths you name. It does **not** limit it to the *changes you
made*: it commits the entire current state of those paths, including edits another session made to
the same file.

For a file only you are touching, those are the same thing, which is why the rule reads as
airtight. For a file both windows edit — and on the local-file backend that is the queue, every
time — they are not. **No discipline on your side prevents it**, because the other session's edit
was already in the file before you opened it. There is no moment at which the file contains only
your change, so there is nothing to time correctly.

Two consequences:

- **Prefer single-writer files.** Most files are naturally one session's at a time; a shared one
  is a hazard to be minimised, not managed. Where a shared file is unavoidable, keep the window in
  which it is dirty as short as possible — see *A claim must be durable the moment it is made*.
- **When it happens anyway, report it; do not rebase.** The other session may already be building
  on the commit. Their rows land correctly under your message, which is the whole cost, and it is
  cheaper than rewritten history.

## The working tree is shared too, so claim files as well as rows

The queue is not the only thing two windows contend over. A second window running the test suite
while the first is mid-edit is testing a file set that never existed, and its red — or its green —
means nothing.

`verify` checks `git status --porcelain` before running anything and says plainly when the tree
carries changes outside the item under test. It still runs; it labels the result advisory rather
than pretending to a confident verdict. See `verify` Step 2.

**A row-level claim says who owns the *work*, not who owns the *files*.** Two sessions can hold
different rows, obey every rule above, and still spend an hour editing the same component — and
nothing so far would have warned either of them. So a claim carries a file scope:

- On claim, `develop` writes `touches:` into the item's frontmatter — the paths or globs it
  expects to edit, read off the item's own description. It is a declaration, not a lock.
- **Before claiming, read the `touches:` of every `in-progress` item.** If your candidate overlaps
  one, do not take it: take the next `ready` row whose scope is clear, and name the row you
  stepped over and the scope it collided with. Overlap is a reason to pick differently, never
  something to negotiate around.
- If the work reaches further than declared, widen `touches:` the moment you know. A scope that
  silently grows is worse than none, because the other window is trusting it.
- Nothing rescues an overlap taken anyway. There is no merge protocol here; the whole design is to
  keep two sessions out of the same files in the first place.

**The shape this protects is one developing window plus one queueing or verifying window.** Two
windows both running `develop` is the mode where this rule earns its keep — and if every `ready`
row collides with an in-progress scope, the honest answer is that there is nothing to develop right
now, not that the collision is acceptable.

## A claim must be durable the moment it is made

A claim that only you can see is worse than no claim at all: it reads as taken to you and as free
to everyone else, and both sessions proceed confidently.

**Durable means visible to the other session without any further act by you.** What satisfies that
depends on the backend, and the difference is not cosmetic:

- **Tracker-backed (Jira, Notion, …)** — the API write *is* the durability. When the call returns,
  the claim is visible to every session and every human. Nothing further is required, and none of
  Part 2 applies.
- **Local file** — the edit is durable only once **committed**. An uncommitted row edit lives in
  one working tree; the other session cannot see it, and the next session to commit that file
  carries it off under their own message. Commit it inside the lock, in the same turn as the edit.

**This was learned the expensive way.** A claim was written to `QUEUE.md` and left uncommitted for
the life of the item, because nothing in this protocol said to commit it. The window that closed
the *next* item committed the queue and swept both pending claims into a commit about something
else. Everything worked; the history is simply wrong, and the sweep was invisible until someone
read the diff afterwards.

## `verify` never writes the queue

`verify` reads `QUEUE.md`, the item file, and `config.yml`, and writes **none of them**. Its output
is a verdict to its caller. This is what makes it safe to run in a second window against an item
the first window is developing, and it is why `develop` — not `verify` — owns closing an item.

If verify notices something worth recording, it hands it to `queue` rather than editing the item
itself.

---

# Part 2 — When the queue is a local file

Applies only to the `QUEUE.md` backend. Skip this part entirely on a tracker-backed project.

The whole of it rests on one idea: **make the common operations touch one line, and serialise every
write to the file.**

## Never rewrite `QUEUE.md` by hand

Use `Edit` on the single row you are changing. Never `Write` the file, never "read it, rebuild it,
write it back" in a tool call. A full-file write from a copy read thirty seconds ago clobbers every
row another session touched in between, and the loss is silent — no conflict, no error, the row is
just gone.

This is why **the table has no `#` column.** Line order is the rank; a position column would have to
be renumbered on every insert and every close, which turns every edit into a full-file rewrite and
re-creates exactly the collision this protocol exists to prevent. Do not add one back. To learn an
item's rank, count the rows.

Two sessions editing *different* rows with `Edit` do not conflict, and need no coordination at all.

**`./claim` is the one exception, and it earns it by holding the lock.** It rebuilds the file, which
is safe only because every other writer serialises behind the same lock — see *Lock every write*.

## Re-read immediately before you write

Between reading a row and editing it, another session may have changed it. Read the file again right
before the `Edit`, and confirm the row still says what you think. If it changed, stop and re-decide
— do not force your version over it.

`Edit` helps you here: it fails rather than guessing when its `old_string` no longer matches. Treat
that failure as information, not an obstacle to route around.

## Lock every write to `QUEUE.md`

**This rule was narrowed once and has been widened back.** It used to lock only the two operations
that are literal read-modify-writes — claiming an id and claiming a row — and exempted closing a row
on the reasoning that a close is "a single-line edit to a row only you hold."

That reasoning is true about the *row* and false about the *file*. The edit is single-line; the
**commit that follows it takes the whole file**, and `./claim` rebuilds the whole file. Both operate
at file granularity, so the exemption let a close interleave with a claim. Every write now takes the
lock:

- **Claiming an ID** (`queue`) — read `next_id`, use it, write `next_id + 1`.
- **Claiming a row** (`develop`) — read a row's status as `ready`, write it `in-progress`.
- **Closing a row** (`develop`) — delete the row, append to `DONE.md`.

**Hold it for the read, the write, and the commit, then release in the same turn.** It guards a
two-second file operation, never a long one: `develop` releases the lock the moment the claim is
committed and does *all* the actual work — code, tests, QA — unlocked. A lock held across an
implementation would block the other window for an hour and be abandoned the first time a session
ended mid-item.

The lock is a directory, because `mkdir` is atomic on POSIX — it either creates or fails, with no
window between checking and creating:

```bash
BACKLOG=".claude/backlog"
if mkdir "$BACKLOG/.lock" 2>/dev/null; then
  printf '%s\t%s\n' "$CLAIM" "$(date -u +%FT%TZ)" > "$BACKLOG/.lock/held-by"
else
  cat "$BACKLOG/.lock/held-by"   # who has it, and since when
fi
```

**If the lock is busy:** wait a couple of seconds and retry, up to about three times. It is only
ever held for a moment, so a genuine holder will be gone. If it is still held after that, read
`held-by`:

- Held for **under 5 minutes** → another session is mid-claim. Report that to the user and stop.
  Do not break it.
- Held for **over 5 minutes** → it is stale; a session almost certainly ended between `mkdir` and
  `rmdir`. Say so, name the timestamp, remove it with `rm -rf "$BACKLOG/.lock"`, and continue.

Always release with `rm -rf "$BACKLOG/.lock"` in the same turn you took it, including on the path
where you decide *not* to make the change. A script must release it on its failure paths too, via a
`trap`.

`.claude/backlog/.lock/` is transient and must never be committed.

## Claim tokens: how a session knows what is its own

There is no ambient session id, so ownership is proved by a token the owning session minted.

When `develop` claims an item, it generates a short token and writes it in the `Owner` column:

```bash
CLAIM=$(head -c2 /dev/urandom | xxd -p)   # 4 hex chars, e.g. 7f3a
```

It also writes `claimed_by: <token>` and `claimed_at: <ISO-8601 UTC>` into the item file's
frontmatter, then reports the token to the user.

**The test for ownership is memory, not inference: an item is yours only if you minted its token in
this conversation.** If you find an `in-progress` row whose token you do not recognise, it belongs
to the other window — even if the work looks like something you would have done, and even if the
working tree contains changes that match it. Never take it over on your own judgement; say whose it
appears to be and ask.

A claim whose `claimed_at` is more than a few hours old, on an item with no matching work in the
tree, is a session that died. Report it and offer to release it — releasing is setting the row back
to `ready` and clearing the token, which is a single-line edit under the lock.

## The two scripts

`queue` scaffolds both into `.claude/backlog/`. They are the supported way to touch the queue,
because each encodes a rule above that is otherwise a matter of remembering:

- **`./claim <id> [token]`** — locks, re-reads the row, edits it, writes the item's frontmatter,
  **commits by pathspec**, and unlocks, with a `trap` releasing the lock on every failure path. Use
  it instead of hand-editing a claim. The commit is the point: it is what makes the claim durable
  rather than a dirty file, and a script cannot forget it.
- **`./next`** — a reader, and nothing else. Prints row 1, the first takeable row, the counts, and
  the files every in-progress item has claimed. It also **warns when `QUEUE.md` holds uncommitted
  row changes**, which is the signal that someone's claim is about to be swept into someone else's
  commit.

A project may not have them if its backlog predates them; hand-editing under the lock is still
correct, just easier to get wrong.
