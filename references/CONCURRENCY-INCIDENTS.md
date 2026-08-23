# Concurrency — incidents, reasoning, and live-conflict procedures

**Not part of the always-read set.** `CONCURRENCY.md` states every rule and the failure it prevents;
this file holds the incident that produced each one, the reasoning behind the design, and the
procedure for a conflict that is actually happening right now.

Read it when: a lock is busy or looks stale, a scope overlap turns up, a sweep has already happened,
or you want to argue with a rule. Otherwise skip it — re-reading a narrative on every cycle to teach
something already learned is the cost that split this file in two.

**Every entry names the rule it justifies**, so a rule and its evidence stay findable from either
end. Rule names are the headings in `CONCURRENCY.md`.

---

## Live-conflict procedures

### A busy or stale lock — rule: *Lock every write to `QUEUE.md`*

```bash
BACKLOG=".claude/backlog"
if mkdir "$BACKLOG/.lock" 2>/dev/null; then
  printf '%s\t%s\n' "$CLAIM" "$(date -u +%FT%TZ)" > "$BACKLOG/.lock/held-by"
else
  cat "$BACKLOG/.lock/held-by"   # who has it, and since when
fi
```

Busy? Wait a couple of seconds and retry, up to about three times — it is only ever held for a
moment, so a genuine holder will be gone. Still held, then read `held-by`:

- **Under 5 minutes** → another session is mid-claim. Report it to the user and stop. **Do not break
  it.**
- **Over 5 minutes** → stale; a session almost certainly ended between `mkdir` and `rmdir`. Say so,
  name the timestamp, `rm -rf "$BACKLOG/.lock"`, and continue.

Always release with `rm -rf` in the turn you took it, including on the path where you decide *not* to
make the change. A script releases on its failure paths via a `trap`.

### A scope overlap — rule: *The working tree is shared too*

Take the next `ready` row whose scope is clear, and name both the row you stepped over and the scope
it collided with. **Nothing rescues an overlap taken anyway** — there is no merge protocol here; the
whole design is to keep two sessions out of the same files. If every `ready` row collides, the honest
answer is that there is nothing to develop right now, not that the collision is acceptable.

An `in-progress` row with an empty `touches:` means either "not declared yet" or "released as it
closes", and nothing visible from outside distinguishes them. Ask, or take a row that does not depend
on the answer.

### A sweep that already happened — rule: *The git index is shared*

If you find another session's change already committed under your message: **report it plainly and do
not rebase.** They may already be building on the commit. Their rows land correctly under your
message, which is the whole cost, and it is cheaper than rewritten history.

If you find source paths already staged when you arrive, they are the other window's. `git restore
--staged <path>` takes them out of *your* commit without touching their working tree.

### A backlog with no scripts — rule: *The three scripts*

A project may predate `./claim` and `./next`. Hand-editing under the lock is still correct, just
easier to get wrong: the step most often forgotten is the commit inside the lock.

---

## The incidents

### The index sweep — rule: *The git index is shared*

A window running `queue` committed with the index swept whole and carried off a developing window's
staged file deletion, so that deletion is recorded in a commit about an unrelated backlog entry.
Nothing errored. Neither session noticed until afterwards.

### The documentation sweep — rule: *A pathspec is necessary but not sufficient*

A pathspec commits the entire current state of the paths it names, including edits another session
made to the same file. For a file only you touch these are the same thing, which is why the rule
reads as airtight; for a shared file they are not, and there is no moment at which the file contains
only your change, so there is nothing to time correctly.

The paragraph in the rule about the project's own documentation exists because **the session that
wrote that rule swept the other window's `CLAUDE.md` edits into the very commit that introduced the
fix.** Both windows write the docs, at exactly the moment they are also committing, and neither
expects the other to.

### The uncommitted claim — rule: *A claim must be durable the moment it is made*

A claim was written to `QUEUE.md` and left uncommitted for the life of the ticket, because nothing in
the protocol said to commit it. The window that closed the *next* ticket committed the queue and
swept both pending claims into a commit about something else. Everything worked; the history is
simply wrong, and the sweep was invisible until someone read the diff afterwards.

This is why `./claim` is a script rather than a rule in a document: the commit is exactly the thing a
session under load forgets, and a script cannot forget.

### The four files that became nine — rule: *The working tree is shared too*

**Why two fields rather than one.** `expects:` is written by `queue` while the code is already open,
and `touches:` by `develop` on claim, checked against the code rather than copied.

They fail differently, and that is what justifies keeping both. A wrong `expects:` costs one
suboptimal pick, so it may be a best guess and it may age. A wrong `touches:` costs two sessions in
one file, which has no merge protocol behind it. Holding one field to both standards forces a choice
between a scope nobody can trust and a scope nobody can afford to write.

**Predict at capture, verify at claim.** Without the prediction, a session choosing what to take has
to research each candidate just to learn whether it may take it — and again for the next row down,
which is the cost that makes the collision check get skipped. Without the verification, the prose
leads: one ticket declared four implementation files and went on to edit three specs, a shared test
helper and the runner's config, because a change that alters what a behaviour **means** reaches every
test that drives it.

### The rule that was narrowed and widened back — rule: *Lock every write to `QUEUE.md`*

The rule once locked only the two literal read-modify-writes — claiming an ID and claiming a row —
and exempted closing a row on the reasoning that a close is "a single-line edit to a row only you
hold."

That reasoning is true about the *row* and false about the *file*. The edit is single-line; the
**commit that follows takes the whole file**, and `./claim` rebuilds the whole file. Both operate at
file granularity, so the exemption let a close interleave with a claim.

### The rule that was deleted, not narrowed — rule: *A stage writes only the ticket it holds*

*`verify` never writes the queue* made `verify` read-only so it was safe to run in a second window
against a ticket the first was developing. Real hazard, real guard — but a workaround for a risk the
one-skill-per-session architecture does not have: `verify` acts only on tickets whose `next` is
`verify`, and nothing is developing those.

An earlier plan had `verify` writing a durable verdict file for `develop` to read, with a commit-SHA
staleness guard so a stale green could not close a changed ticket. Both disappeared when `verify`
took over closing: it holds the verdict in the session where it acts on it, so there is no window for
a green to go stale in. **That deleted a ticket from the plan rather than adding one.**

### The parser that reported an empty backlog — rule: *The three scripts*

`./next` and `./claim` read the queue table by fixed column index. When the table was pared to five
columns, `./next` printed "0 ready of 2 rows" and `./claim` refused every row — both without
erroring. The failure was safe but silent, and a reader would conclude the backlog was empty rather
than that the parser was wrong. `./next` now refuses a table shape it cannot parse; that is why
"refuse rather than guess" is stated as a property of both scripts.
