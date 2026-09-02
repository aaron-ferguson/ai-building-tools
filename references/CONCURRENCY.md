# Backlog concurrency protocol

Read by every skill before it touches a backlog file. **Rules are named, not numbered** — cite by
name. **`CONCURRENCY-INCIDENTS.md` holds each rule's incident, its reasoning, and what to do in a live
conflict**; read it then, or to argue with a rule. **Part 1 applies everywhere, Part 2 only to the
`QUEUE.md` backend**, since a tracker's API write is the whole transaction.

---

# Part 1 — Two sessions, one repository

## The git index is shared

One staging area per repository, no lock, no token: any session can commit what another staged.

- **Commit by pathspec — `git commit -m "…" -- <paths>`, carrying the `Co-Authored-By` trailer
  every AI-assisted commit takes (`git-conventions.md`).** Bare `git commit` writes the whole index,
  so `git add <mine> && git commit` still takes their work. Never `-a`, `add .`, `add -A`. A file git
  does not know yet needs **`git add -N` first**, or the pathspec fails.
- **Stage and commit in one turn**, and **read back** (`git diff --cached --name-only`), then
  `git restore --staged` anything not yours.
- **Never bare `git stash`** — and **`git stash push -- <paths>` is not the safe form**: like a
  pathspec on a commit, it limits the files and not the authorship, so it takes their uncommitted
  work under those paths. It looks equivalent to the throwaway worktree the skills recommend for
  "did this red pre-exist?" and it is not; the worktree is the answer. **Your message on their change → report,
  never rewrite history.**

### A pathspec is necessary but **not sufficient**

It limits the commit to the paths you name, **not to the changes you made** — their edits to those
paths go too, and **nothing you do prevents it**. Prefer single-writer files; **the shared ones are
more than the queue** — the project's own docs are written by every session.

## The working tree is shared too

A row claim owns the *work*, not the *files*: two sessions can hold different rows and spend an hour
in one component, unwarned.

- **Compare your candidate's `expects:` against every `in-progress` `touches:` before claiming.**
  Overlap means pick differently: take the next clear `ready` row, name the one you stepped over. All
  rows collide → nothing is developable right now.
- **`queue` writes `expects:`** (predicted, code open); **`develop` writes `touches:` on claim**
  (actual, checked against the code, never copied). Why two fields: `CONCURRENCY-INCIDENTS.md`.
- **Widen `touches:` as the work reaches further**, and read an **empty `touches:` on an `in-progress`
  row as *its files are held*** — silence is not permission. That is a statement about file scope; who
  holds the *row* is the item's token alone (*A stage writes only the ticket it holds*).
- **`verify` derives *advisory*** from the dirty paths that intersect the evidence its verdict rested
  on — dirty **under test**, not dirty anywhere. Empty intersection: a plain PASS that closes.
- **At `qa_level: e2e` that intersection can never be empty**, because the runner builds and serves
  the whole application and so collects every foreign path. Read literally, no `e2e` ticket ever
  closes in a project running two sessions. The answer is not to relax the rule but to give it a
  state it can describe: **verify a named commit in a `git worktree`, remove it the same turn, and
  report the SHA in the verdict.** A verdict pinned to "the tree" is pinned to nothing where
  `git status` answers differently minute to minute and `HEAD` advances mid-pass — both observed.
  Such a worktree may run tests and **must never claim, close or hand off**: the lock and the queue
  it would write are per-checkout, so a claim made there is invisible to every other session.

## A claim must be durable the moment it is made

**Durable = visible to the other session with no further act by you.** A claim only you can see
reads as free to everyone else. Tracker-backed, the API write is it; local file, **only once
committed** — inside the lock, same turn, or the next session to commit the file carries it off under
its own message. **A directory is not a file:** git records no empty directory, so a `mkdir`-based
claim stays invisible until something is written inside it.

## A stage writes only the ticket it holds

- **Write nothing another session reads for coordination while it holds the ticket.** Claim the row
  you write; write only that row and its item file. **One narrow exception:** closing a ticket also
  reconciles the tickets naming it in `blocked_by`, in the closing commit — `blocked` is derived, so
  the close is the only event that can clear them. Reconcile only a dependent whose `status:` is
  `blocked`, never one that is **held** — and this is the one place *held* is defined: **a non-empty
  `claimed_by:` in the item, and nothing else.** A row reading `in-progress` over a tokenless item is
  drift, not ownership — `./next --drift` reports it, and no reader treats it as a claim. Report every
  dependent you skip.
- **A criterion belonging to another ticket cannot be filed by the stage that finds it, and saying
  "fold this into item NNNN" in your own notes is not filing it.** The rule above forbids the writing
  session from editing that item, and no step hands the instruction to anyone else — so it survives
  only in a closed ticket's prose, which is the one place the session performing the target will not
  look. Measured once at six items and twelve checks, of which two had gone **false** before anyone
  was permitted to execute them and six had already been discharged by other work. A carried
  criterion is a claim about code it does not own and ages like any cached figure (`develop` Step 2):
  **date-stamp it, name the item it came from, and re-verify it against the source before running
  it** — the claiming session is the first that may, and the first that must.
- **A stage finding a ticket at another stage refuses it** — `develop` skips `next: design`, `verify`
  refuses anything not `next: verify`. That field keeps two stages off one ticket.
- **`verify` owns closing**, holding the verdict when it acts, so no green goes stale.

---

# Part 2 — When the queue is a local file

## Never rewrite `QUEUE.md` by hand

`Edit` the one row you are changing. Never `Write`, never read-rebuild-write: a full-file write from a
copy read a minute ago clobbers every row touched since, with no conflict and no error. Hence **no `#`
column** — renumbering *is* that rewrite. Different rows need no coordination. **`./claim` and
`./close` are the exceptions**, earning it by holding the lock while they rebuild.

## Re-read immediately before you write

Read the row again right before the `Edit`. `Edit` fails rather than guessing when `old_string` stops
matching — that is information, not an obstacle to route around.

## Lock every write to `QUEUE.md`

**Every write, no exemptions**: claiming an ID (`queue`), claiming a row (`develop`, `verify`),
closing a row (`verify`).

**Hold it for the read, the write and the commit, then release in the same turn** — including where you
decide *not* to change anything; scripts release on failure paths via a `trap`. **For an agent, "the
same turn" means the same shell invocation**: a session gets a fresh shell per tool call, so a
`trap ... EXIT` releases the lock the moment that call returns and every later call edits and commits
holding nothing. It is invisible — the sequence reads exactly like a correct lock and every step
succeeds. Run the whole sequence in one call, or drop the trap and `rm -rf` explicitly at the end.
**If you are writing a lock by hand rather than calling `./claim` or `./close`, read
`CONCURRENCY-INCIDENTS.md` first, not after it goes wrong**: it carries three ways a by-hand lock
leaks silently, and this one was written down seven days before a session rediscovered it, because
nothing sends you there until you already have trouble. It guards a two-second
operation, never an implementation.

**The lock is `.claude/backlog/.lock/`, a directory, because `mkdir` is atomic on POSIX.** Put `$CLAIM`
and a UTC timestamp in `.lock/held-by`, so a busy lock says who holds it; release with `rm -rf` at an
**absolute** path, never commit it. **Snippet, the busy/stale paths, and the three ways a by-hand lock
leaks silently: `CONCURRENCY-INCIDENTS.md`.**

## Claim tokens

No ambient session id, so ownership is a minted token — `CLAIM=$(head -c2 /dev/urandom | xxd -p)` — in
the item's `claimed_by:` with `claimed_at:` (ISO-8601 UTC). **That is the token's home** — the pared
`QUEUE.md` has no ownership column. The row reads `in-progress`; report the token to the user.

**Ownership is memory, not inference: a ticket is yours only if you minted its token in this
conversation.** An unfamiliar token is the other window's — say so and ask, never take it over. A
`claimed_at` hours old with no matching work is a dead session: report it and offer to release it.

## The three scripts

Each encodes a rule above that is otherwise a matter of remembering. **`./claim <id> [token]`** and
**`./close <id> <token>`** do the whole claim and the whole close under the lock and **commit** — the
commit is the point, and a script cannot forget it. `close` is *given* its token, not minting one —
ownership is memory. **`./next`** only reads; `--help` lists its modes. All three refuse rather
than guess.
