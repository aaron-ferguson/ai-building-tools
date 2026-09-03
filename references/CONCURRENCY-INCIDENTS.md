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

**Three things bite a by-hand lock, and all three fail silently.**

- **Resolve `$BACKLOG` to an absolute path.** A `trap 'rm -rf "$BACKLOG/.lock"' EXIT` resolves against
  the shell's cwd *at trap time*, so a sequence that `cd`s to the repo root — the natural shape, since
  the commit needs repo-relative pathspecs — deletes a `.lock` that isn't there and exits reporting
  success. The lock stays held. One session held it for ~8 minutes across a whole implementation and
  found out only when its own handoff hit a busy lock carrying its own token.
- **A `trap ... EXIT` fires when each shell invocation exits, not when your turn ends.** A lock taken in
  one tool call is already released by the next, so the claim looks held and is not. Either run the whole
  sequence (lock, re-read, row edit, frontmatter, commit, release) in a **single** invocation, or **drop
  the trap** and release with an explicit `rm -rf` at the end. Dropping it is what a `verify` close needs,
  since its row edits go through `Edit` for single-row safety and cannot be one shell call — the cost is
  a lock held for minutes, so keep every edit that is not to `QUEUE.md` outside it.
- **A busy-lock report should say when the holder is you.** It prints the token and timestamp, which
  diagnoses the leak above only if the reader remembers minting that token. Compare it against the token
  you hold and say so.

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

### A backlog with no scripts — rule: *The four scripts*

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

### The reconcile that rewrote tickets it did not hold — rule: *A stage writes only the ticket it holds*

The rule's exception lets a close write rows other than its own, and `close` implemented it by
selecting every item whose `blocked_by` named the ticket being closed. Two things make that
selection wrong, and both were reachable:

**`blocked_by` outlives the close.** Nothing clears it when a ticket closes, so a closed ticket names
its blockers for ever. Closing a blocker later flipped a `done` dependent back to `ready` while it
sat in `DONE.md` — the two files then disagreed about whether it was finished, which is the same
"queue that lies about what is takeable" the exception exists to prevent, in the other direction.

**The ownership guard was a `QUEUE.md` row.** A dependent with no row — closed, or not yet ranked —
was neither skipped nor reported, and had its `status:` rewritten under another session's live
claim, `claimed_by:` left intact. The guard consulted the one place *Claim tokens* says ownership
does not live.

So the rule now selects on the dependent's own `status:` reading `blocked` rather than on
`blocked_by` alone, and tests ownership in the item.

**The row clause it also grew, and why that lost (0029).** The same fix added a second test: an
`in-progress` row carrying no token *also* read as held, on *The working tree is shared too*'s
"silence is not permission" — a session that had edited the row but not yet written its token would
otherwise be written over. That is a real window, and the argument is kept here rather than deleted
because a rule that looks arbitrary gets re-added by the next session that meets the case.

It lost on **one definition beating two**. The rule and `verify`'s hand-close defined *held* as the
item's token alone; only the script carried the extra clause, so the documented fallback wrote a
dependent the script left alone — two paths, one close, different results. That is the defect shape,
whichever half is right. The window it guarded also closed on its own: `./claim` writes the row and
the token under one lock in one commit, so the untokened `in-progress` row is no longer a state a
live session passes through — it is drift, and 0024 built `./next --drift` so drift is reported
rather than silently honoured by every reader in turn.

The wider lesson is about the ACs, not the script. The verification that found this had eight
criteria and all eight passed; every dependent in every fixture had a row, so no criterion could
see the case. **A guard written against one shape of input is verified only against that shape.**

### The parser that reported an empty backlog — rule: *The four scripts*

`./next` and `./claim` read the queue table by fixed column index. When the table was pared to five
columns, `./next` printed "0 ready of 2 rows" and `./claim` refused every row — both without
erroring. The failure was safe but silent, and a reader would conclude the backlog was empty rather
than that the parser was wrong. `./next` now refuses a table shape it cannot parse; that is why
"refuse rather than guess" is stated as a property of both scripts.
