# Backlog concurrency protocol

Read by `capture`, `develop`, and `qa`. The backlog is designed to be worked by **two or more
sessions at once** — typically one window developing while another captures feedback and QAs.
These rules are what make that safe. They are not optional; a session that ignores them
silently destroys another session's work.

The whole protocol rests on one idea: **make the common operations touch one line, and lock
only the two things that genuinely cannot be made single-line.**

---

## Rule 1 — Never rewrite `QUEUE.md` whole

Use `Edit` on the single row you are changing. Never `Write` the file, never "read it, rebuild
it, write it back". A full-file write from a copy read thirty seconds ago clobbers every row
another session touched in between, and the loss is silent — no conflict, no error, the row is
just gone.

This is why **the table has no `#` column.** Line order is the rank; a position column would
have to be renumbered on every insert and every close, which turns every edit into a full-file
rewrite and re-creates exactly the collision this protocol exists to prevent. Do not add one
back. To learn an item's rank, count the rows.

Two sessions editing *different* rows of `QUEUE.md` with `Edit` do not conflict, and need no
coordination at all.

---

## Rule 2 — Re-read immediately before you write

Between reading a row and editing it, another session may have changed it. Read the file again
right before the `Edit`, and confirm the row still says what you think. If it changed, stop and
re-decide — do not force your version over it.

`Edit` helps you here: it fails rather than guessing when its `old_string` no longer matches.
Treat that failure as information, not an obstacle to route around.

---

## Rule 3 — Lock the two real read-modify-writes

Exactly two operations cannot be expressed as a single-line edit, because they read a value and
write back a value derived from it:

- **Claiming an ID** (`capture`) — read `next_id`, use it, write `next_id + 1`.
- **Claiming an item** (`develop`) — read a row's status as `ready`, write it `in-progress`.

Both take the lock. Nothing else does.

The lock is a directory, because `mkdir` is atomic on POSIX — it either creates or fails, with
no window between checking and creating:

```bash
mkdir "$BACKLOG/.lock" 2>/dev/null && echo held || echo busy
```

**Hold it for the read and the write, and release it in the same turn.** It guards a two-second
file operation, never a long one: `develop` releases the lock the moment the item is marked
`in-progress` and does *all* the actual work — code, tests, QA — unlocked. A lock held across
an implementation would block the other window for an hour and be abandoned the first time a
session ended mid-item.

Record who holds it and since when, so a stale one can be diagnosed rather than guessed at:

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
- Held for **over 5 minutes** → it is stale; a session almost certainly ended between `mkdir`
  and `rmdir`. Say so, name the timestamp, remove it with `rm -rf "$BACKLOG/.lock"`, and
  continue.

Always release with `rm -rf "$BACKLOG/.lock"` in the same turn you took it, including on the
path where you decide *not* to make the change.

`.claude/backlog/.lock/` is transient and must never be committed.

---

## Rule 4 — Claim tokens: how a session knows what is its own

There is no ambient session id, so ownership is proved by a token the owning session minted.

When `develop` claims an item, it generates a short token and writes it in the `Owner` column:

```bash
CLAIM=$(head -c2 /dev/urandom | xxd -p)   # 4 hex chars, e.g. 7f3a
```

It also writes `claimed_by: <token>` and `claimed_at: <ISO-8601 UTC>` into the item file's
frontmatter, then reports the token to the user.

**The test for ownership is memory, not inference: an item is yours only if you minted its
token in this conversation.** If you find an `in-progress` row whose token you do not recognise,
it belongs to the other window — even if the work looks like something you would have done, and
even if the working tree contains changes that match it. Never take it over on your own
judgement; say whose it appears to be and ask.

A claim whose `claimed_at` is more than a few hours old, on an item with no matching work in the
tree, is a session that died. Report it and offer to release it — releasing is setting the row
back to `ready` and clearing the token, which is a single-line edit under the lock.

---

## Rule 5 — `qa` never writes the queue

`qa` reads `QUEUE.md`, the item file, and `config.yml`, and writes **none of them**. Its output
is a verdict to its caller. This is what makes it safe to run in a second window against an item
the first window is developing, and it is why `develop` — not `qa` — owns closing an item.

If QA notices something worth recording, it hands it to `capture` rather than editing the item
itself.

---

## Rule 6 — The working tree is shared too

The queue is not the only thing two windows contend over. A second window running the test suite
while the first is mid-edit is testing a file set that never existed, and its red — or its green
— means nothing.

`qa` checks `git status --porcelain` before running anything and says plainly when the tree
carries changes outside the item under test. It still runs; it labels the result advisory rather
than pretending to a confident verdict. See `qa` Step 2.
