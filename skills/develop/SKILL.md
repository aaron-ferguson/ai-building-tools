---
name: develop
description: >
  Pull the next item off the project's stack-ranked backlog and implement it end to end —
  TDD per conventions, then QA, then close it out. Use this skill when the user says "let's
  work on the next thing", "pick up the next item", "what's next — do it", "work the backlog",
  "develop 0007", "start on the top item", or invokes /develop. Also use when the user has
  tokens/time to spend and asks what to do next with intent to actually do it. Reads
  .claude/backlog/ — created by the capture skill.
---

# /develop

Take the top `ready` item off `.claude/backlog/QUEUE.md` and finish it: implemented, tested,
QA'd, committed, and moved to `DONE.md`. One item per invocation unless told otherwise.

**Another session may be working this same backlog** — commonly a second window capturing
feedback and running QA. Read `references/CONCURRENCY.md` at the plugin root
(`../../references/CONCURRENCY.md` from this file) before touching any backlog file.

**This skill states no standards of its own.** How to build, test, commit, and review is
defined by the project's conventions and cited here, never restated. Resolve them per
`references/CONVENTIONS.md`.

---

## Step 1 — Select and claim the item

Read `.claude/backlog/QUEUE.md`.

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
   you expect to edit — into the item file's frontmatter.
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

Work FR by FR, committing each logical unit as it completes rather than one commit at the end,
in the commit format the conventions define, referencing the item ID (`0007`).

**Every commit contains this session's work and nothing else.** The index is shared and unguarded
— another window can commit whatever you leave staged, and has (`CONCURRENCY.md` Rule 7). So:
stage explicit paths, never `git add .` / `-A` and never `git commit -a`; stage and commit in the
same turn rather than staging before a long test run; and read back `git diff --cached
--name-only` before each commit, unstaging anything that is not yours.

Respect the item's **Out of scope** section. If you find adjacent problems, don't fix them
here — capture them as new backlog items and keep going. That's what the queue is for.

Append anything non-obvious you learn to the item's **Notes & decisions** as you learn it —
a disproved theory, a mechanism that surprised you, a rule that misled you.

---

## Step 5 — Hand off to QA

Invoke the `qa` skill with the item ID. Do not self-certify — the point of a separate pass is
that it checks the written ACs rather than what you remember building.

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
4. Commit the backlog change alongside the code change, staging the specific files and checking
   `git diff --cached --name-only` first. A second window is editing this repo too, and a swept
   index — `git add .`, or `git commit -a` — takes its in-flight work into your commit.
   Also clear `touches:` from the item's frontmatter as you close it: the scope is a live claim
   on files, and a closed item must not keep reserving them.
5. Anything you learned that belongs in the project's `CLAUDE.md` or a convention file goes in
   the same change, unprompted.

**Do not push** unless the project's `CLAUDE.md` or `git-conventions.md` says an item close
should push, or the user asks. The default is to leave the commits local and say so — closing an
item is not authority to publish it.

---

## Step 7 — Report

Item closed, what changed, what QA ran and its result, anything new you captured, and what's
now at the top of the queue.
