---
name: develop
description: >
  Pull the next item off the project's stack-ranked backlog and implement it end to end —
  TDD per conventions, then QA, then close it out and capture what the work surfaced.
  Use this skill when the user says "let's
  work on the next thing", "pick up the next item", "what's next — do it", "work the backlog",
  "develop 0007", "start on the top item", or invokes /develop. Also use when the user has
  tokens/time to spend and asks what to do next with intent to actually do it. Reads
  .claude/backlog/ — created by the capture skill.
---

# /develop

Take the top `ready` item off `.claude/backlog/QUEUE.md` and finish it: implemented, tested,
QA'd, committed, and moved to `DONE.md` — then leave the backlog in a state the next session can
pick up cold. One item per invocation unless told otherwise.

**Closing the row is not the end of the job.** An item is finished when the work it *created* has
somewhere to live too: the deferrals, the reds you proved were not yours, the thing you noticed
and moved past. That is Step 7, it is not optional, and it is the step this skill most often gets
skipped — the documentation habit holds because the item file is open, while the
project-management half quietly leaves with the conversation.

**Another session may be working this same backlog** — commonly a second window capturing
feedback and running QA. Read `references/CONCURRENCY.md` at the plugin root
(`../../references/CONCURRENCY.md` from this file) before touching any backlog file.

**This skill states no standards of its own.** How to build, test, commit, and review is
defined by the project's conventions and cited here, never restated. Resolve them per
`references/CONVENTIONS.md`.

---

## Step 1 — Select and claim the item

**If the backlog has a `./next` script, run it instead of reading `QUEUE.md`.** It prints row 1,
the first row whose status is `ready`, the ready/total counts, and the files every in-progress
item has claimed — the whole of what this step needs, in a fixed handful of lines however long
the queue grows. `QUEUE.md` is the file both windows edit most, so it is also the one a session
re-reads most; reading it whole to learn one row is the largest avoidable context cost in the
backlog. Read the file itself only when the question is about *order* — a re-rank, a themes
pass, or where a new item belongs. Otherwise:

```bash
.claude/backlog/next
```

If there is no such script, read `.claude/backlog/QUEUE.md`.

- No argument → the **topmost row with status `ready`**. The rank is not a suggestion.
- Argument is an ID (`/develop 0007`) → that item, but say so if you're skipping higher rows
  and why you believe that's intended.
- Row 1 is `blocked` → report the blocker, take the next `ready` row. Never reorder to make
  your choice look correct.
- Row is `in-progress` → **it belongs to another session unless you minted its `Owner` token in
  this conversation.** Skip it and take the next `ready` row, naming the token you skipped. Do
  not take it over because the work looks stalled or the tree looks like nobody is on it; ask.
- No backlog directory → tell the user and offer `capture` to start one. Don't invent work.

**On size:** the rank is absolute and you do not get to skip row 1 because it's an `l` and the
session is short. If row 1 is bigger than the budget, say so and let the user choose — take it
and stop at a clean commit boundary, or explicitly drop to a smaller item this once. Silently
picking something easier is how the important expensive item never gets done.

**Claim it under the lock.** `ready` → `in-progress` is a read-modify-write: two sessions that
both read `ready` before either writes will both take the item, and you will not find out until
you collide in the working tree.

```bash
BACKLOG=".claude/backlog"
mkdir "$BACKLOG/.lock" 2>/dev/null || { cat "$BACKLOG/.lock/held-by"; }   # busy → see CONCURRENCY.md
CLAIM=$(head -c2 /dev/urandom | xxd -p)
```

**Check the file scope before you claim.** Read the `touches:` of every `in-progress` item. If
your candidate's files overlap one, **take the next `ready` row whose scope is clear instead**,
and name the row you stepped over and the scope it hit. Two sessions in one file is the failure
this prevents, and there is no merge protocol to fall back on (`CONCURRENCY.md` Rule 6). If every
`ready` row collides, say that there is nothing safe to develop right now rather than taking one
anyway.

Inside the lock, in this order:

1. **Re-read the row.** It may have changed since you chose it. If it is no longer `ready`,
   release the lock and pick again — do not proceed on the version you read a minute ago.
2. Set the row's status to `in-progress` and write `$CLAIM` into its `Owner` column, as one
   single-line `Edit`.
3. Write `claimed_by: <token>`, `claimed_at: <ISO-8601 UTC>`, and `touches:` — the paths or globs
   you expect to edit — into the item file's frontmatter. **List paths that exist**: `ls` the
   directories first rather than writing the filename the item's prose implies. A `touches:`
   naming a file that is not there reserves nothing, and the other window cannot tell the
   difference between a path you invented and one you are about to create.
4. `rm -rf "$BACKLOG/.lock"` — in this same turn, before any implementation work.

Widen `touches:` the moment the work reaches further than you declared: the other window is
reading it to decide what it may safely take.

Report the token to the user, so the other window's output is legible to them. Then read the
full item file before doing anything else.

---

## Step 2 — Restate the contract before writing code

Out loud, in three or four lines: the FRs you're satisfying, the NFR rows that apply, the ACs
you'll be held to, and the QA level. This is the last cheap moment to catch a
misunderstanding.

**If the item is underspecified — no FRs, no ACs, or a stale problem statement — stop and fix
the item first**, then proceed. An item that can't be restated can't be verified. Update the
item file so the next reader gets the improved version.

If the item's assumptions have gone stale since capture (the code moved, the bug is already
fixed, a dependency changed), say so and ask before building to a spec that no longer matches
reality.

---

## Step 3 — Load the conventions this item actually triggers

Resolve the conventions directory per `references/CONVENTIONS.md` and stop if none resolves —
there is nothing to build against, and guessing at the house standard is exactly what these
tools exist to prevent.

Always: `CONVENTIONS_CORE.md`, plus the project's own `CLAUDE.md` — project overrides beat
universal defaults.

Then read exactly the convention files cited in the item's NFR table, plus the files the core's
index names for coding and testing. Don't read all of them; don't read none.

---

## Step 4 — Build it

Follow the TDD cycle and the commit rules exactly as the conventions core states them — it is
non-negotiable there, and this skill does not restate it. Read it before you write the first
line. For a bug item, the first test reproduces the bug and stays as a permanent guard.

**Read one sibling test in the target directory before writing the first test.** Not for style —
for what is actually wired up. Which matchers exist (a project without `jest-dom` has no
`toBeInTheDocument`), which helpers and fixtures are already there, whether the suite uses
`fireEvent` or `userEvent`, and what the helper functions return. Each of those is a red-to-red
round trip when guessed at, and they come in threes; one file read costs less than the first
wrong guess.

Work FR by FR, committing each logical unit as it completes rather than one commit at the end,
in the commit format the conventions define, referencing the item ID (`0007`).

**Every commit contains this session's work and nothing else.** The index is shared and unguarded
— another window can commit whatever you leave staged, and has (`CONCURRENCY.md` Rule 7). So:

- **Commit by pathspec** — `git commit -m "…" -- path/one path/two`. This is the actual guard.
  `git commit` commits the whole index, so `git add <paths> && git commit` still carries off
  whatever the other window staged in between; naming the paths on the commit does not.
- Never `git add .` / `-A`, never `git commit -a`.
- **Verify first, stage last.** A `git diff --cached --name-only` read-back is worth having, but
  it proves what is staged *at that instant* and nothing about the moment the commit runs. Files
  left staged across a test run are a race you will eventually lose — and the loss is silent.
- Unstage anything that is not yours with `git restore --staged <path>`, which leaves the other
  window's working tree alone. Never `git stash` to tidy: bare `stash` takes their work with it.

Respect the item's **Out of scope** section. If you find adjacent problems, don't fix them
here — capture them as new backlog items and keep going. That's what the queue is for. Note
them as you go; Step 7 is the backstop that gets them written down, not the place to start
remembering them.

Append anything non-obvious you learn to the item's **Notes & decisions** as you learn it —
a disproved theory, a mechanism that surprised you, a rule that misled you.

---

## Step 5 — Hand off to QA

Invoke the `qa` skill with the item ID. Do not self-certify — the point of a separate pass is
that it checks the written ACs rather than what you remember building.

**Before you do, run the project's whole test suite once — every runner it has, not the item's
declared level.** The level says what this item had to *prove*; it does not say what this item
was allowed to *break*, and those are different questions. A `unit` item that changes a shared
default can leave the browser suite red and close green, because nothing on its path ever
started a browser. That has happened: an item shipped a model change under `qa_level: unit` and
left four end-to-end specs failing, and it was two items before anything ran them — by which
point the fix was archaeology rather than a one-line correction, and needed a backlog item of
its own.

If the full suite is red in a file this item never touched, **find out whose it is before
touching anything**: `git log -1 -- <path>` and the in-progress rows will usually say. Another
session's red is theirs to fix and yours to report, not to repair silently. If the tree is too
entangled to judge, verify in a throwaway worktree (`git worktree add`) so you are reading your
own work rather than the shared tree, and remove it in the same turn.

`qa` returns a verdict and writes nothing to the backlog — closing is yours alone. That is also
why it is safe for the other window to run `/qa` while you are mid-item.

If QA fails: fix, re-run QA, and record what the failure was in the item's notes. Never close
an item on a red or skipped check, and never report success you haven't seen. If you can't
get it green, set the item back to `ready` (or `blocked` with the reason) and report honestly
what's left — **and clear the `Owner` token and `touches:` when you do**, since you are no longer
holding either the row or its files, and the next session needs to be able to take both.

---

## Step 6 — Close it out

Only after QA is green:

1. Run the review checklist the conventions define for changed code.
2. Tick the ACs in the item file and set `status: done` with the date.
3. Move the item's row out of `QUEUE.md` into `DONE.md` (newest first). **Re-read `QUEUE.md`
   first** — the other window has had the whole implementation to insert rows — then delete
   your row with a single `Edit` and append it to `DONE.md`, dropping the `Owner` token on the
   way. Nothing else in `QUEUE.md` is touched; there is no position column to renumber. No lock
   is needed for this: it is a single-line edit to a row only you hold.
4. **Commit the backlog change alongside the code change, by pathspec.** A second window is
   editing this repo too, and `git commit` commits the *entire index* rather than the paths you
   staged a moment ago — so `git add <paths> && git commit` is not sufficient and has silently
   swept another session's work into an item close. Name the paths on the commit itself:
   `git commit -m "…" -- path/one path/two`. **Verify first and stage last**: a
   `git diff --cached --name-only` read-back proves what is staged at that instant and grants
   nothing about the moment the commit runs, so never leave files staged across a test run.
   Also clear `touches:` from the item's frontmatter as you close it: the scope is a live claim
   on files, and a closed item must not keep reserving them.
5. Anything you learned that belongs in the project's `CLAUDE.md` or a convention file goes in
   the same change, unprompted.

**Do not push** unless the project's `CLAUDE.md` or `git-conventions.md` says an item close
should push, or the user asks. The default is to leave the commits local and say so — closing an
item is not authority to publish it.

---

## Step 7 — Sweep the session into the backlog

**Mandatory, and it runs even when the item closed cleanly.** Step 6 covers what you *learned* —
the documentation half — and that half tends to get done, because writing up a mechanism is
satisfying and the item file is open in front of you. The half that falls through is the
**project-management** one: the work this work created. A finding you mention only in your final
report is lost the moment the conversation ends, and it is lost in the most expensive way,
because the next session re-derives it from scratch with none of the context you had.

Walk these sources explicitly rather than trying to remember:

- **Anything you said "out of scope" to** in Step 4. That was a decision to defer, not to drop.
- **Every red or skipped check you did not fix** — including ones you determined were
  pre-existing. "Not mine" is a statement about authorship, not about ownership.
- **Anything you called someone else's territory.** See the rule below; this is the one that
  bites.
- **Anything you noticed on screen or in output and moved past** — a wrapped label, a slow step,
  a confusing message, a stale comment.
- **Anything the item's own notes predicted and reality contradicted** — a prerequisite that
  never landed, an assumption that went stale, a rank that is now wrong.
- **Anything the tooling or the conventions made harder than it needed to be.** That is a finding
  about the process, and it belongs in the skill or convention file, not only in your head.

Then, for each one, do exactly one of:

1. **Capture it.** Invoke the `capture` skill so it becomes a properly specified, ranked item —
   not a bullet in your report and not a `TODO` in the code. Capture writes the FRs, ACs and QA
   level a cold agent needs; a one-line note does not.
2. **Re-rank an existing item**, when the work you just did changed what something else is worth.
   Say so and do it — a rank that is now wrong is a decision the queue is silently getting wrong
   every time someone reads row 1.
3. **Write it to the project's `CLAUDE.md` or a convention file**, if it is a durable rule rather
   than a unit of work.

**Handing a finding to another item is a claim about that item's scope, and it costs one grep to
check.** Do not write "that belongs to 0054" unless you have read 0054 and confirmed it covers
this. An unverified hand-off is indistinguishable from dropping the finding, except that it also
sounds resolved — to you, to the user, and to the next session that reads your report. This has
happened: a red e2e suite was waved off as another item's territory, that item never mentioned
it, and it stayed unowned through an entire item's life.

**A pre-existing failure still needs an owner.** The value of proving a red check is not yours is
that you may close your item; it is not that the red goes away. If no item claims it, capture it.

Report what came out of this step even when the answer is "nothing" — an explicit "nothing new
surfaced" is a claim you have checked, and it is what makes the step visible when it is skipped.

---

## Step 8 — Report

Item closed, what changed, what QA ran and its result, **what Step 7 captured or re-ranked**, and
what's now at the top of the queue.
