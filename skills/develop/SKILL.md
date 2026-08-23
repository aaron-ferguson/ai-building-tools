---
name: develop
description: >
  Pull the next item off the project's stack-ranked backlog, implement it TDD per conventions,
  leave the tree green, and stop at `next: verify` for a QA session to check and close.
  Use this skill when the user says "let's
  work on the next thing", "pick up the next item", "what's next — do it", "work the backlog",
  "develop 0007", "start on the top item", or invokes /develop. Also use when the user has
  tokens/time to spend and asks what to do next with intent to actually do it. Reads
  .claude/backlog/ — created by the queue skill.
---

# /develop

Take the top `ready` item off `.claude/backlog/QUEUE.md` and build it: implemented, committed,
the tree left green, and the ticket set to `next: verify` so a QA session can check it against the
written ACs and close it. One item per invocation unless told otherwise.

**This skill does not close the ticket.** `verify` does, because the stage holding the verdict is
the stage that should act on it — there is then no window in which a green goes stale, and no
verdict has to survive a session boundary in conversation. Your last act is the implementation
commit plus `next: verify, status: ready`.

**Another session may be working this same backlog** — commonly a second window capturing
feedback and running QA. Read `references/CONCURRENCY.md` at the plugin root
(`../../references/CONCURRENCY.md` from this file) before touching any backlog file.

**This skill states no standards of its own.** How to build, test, commit, and review is
defined by the project's conventions and cited here, never restated. Resolve them per
`references/CONVENTIONS.md`.

---

## Where work is tracked, and where cost is recorded

Two optional blocks in `.claude/backlog/config.yml` change what this skill does at claim
and at close. Both are **off unless configured** — a solo project needs neither, and
this skill never prompts to set them up.

Read `references/TRACKER.md` before acting on either. In short:

- **`tracker:`** — an external issue tracker the backlog **mirrors to, one way**. The
  local item stays the source of truth: it holds the FRs, NFR citations, acceptance
  criteria, and QA level a ticket does not, and an agent must never be blocked on the
  network. **Which** tracker, project, and issue types is a company-profile question,
  not a question this skill answers; the config block records what the profile resolved
  to. If a mirror call fails, log it in the item's notes and carry on — a tracker
  outage must not block a close.
- **`cost_tracking:`** — record what this session spent on the item before it stops. Only
  the session that did the work knows which item its tokens belonged to, so this is the
  only place the attribution can be captured; `verify` appends its own share when it
  closes. Aggregate spend can always be recovered later; the attribution cannot.

---

## Step 1 — Select and claim the item

**If the backlog has a `./next` script, run it instead of reading `QUEUE.md`.** It prints the
first takeable row for your stage — `next: develop`, `status: ready`, no open `blocked_by` — with
its `size` and `qa_level`, plus the files every in-progress item has claimed. That is the whole of
what this step needs, in a fixed handful of lines however long the queue grows. `QUEUE.md` is the
file both windows edit most, so it is also the one a session re-reads most; reading it whole to
learn one row is the largest avoidable context cost in the backlog. Read the file itself only when
the question is about *order* — a re-rank, a themes pass, or where a new item belongs. Otherwise:

```bash
.claude/backlog/next develop      # the row to take, its size, and what it expects to touch
```

If there is no such script, read `.claude/backlog/QUEUE.md`.

- No argument → the **topmost row that is `next: develop` and `status: ready`**. Two columns,
  two questions: `Next` is the stage that acts, `Status` is whether anything can. The rank is
  not a suggestion.
- Argument is an ID (`/develop 0007`) → that item, but say so if you're skipping higher rows
  and why you believe that's intended.
- Row 1 is `blocked` or `waiting` → report which, and what clears it — a named ticket for
  `blocked`, and for `waiting` the question in the item's `## Waiting on` section, which
  `./next --waiting` prints without opening the ticket. Then take the next takeable row. Never
  reorder to make your choice look correct.
- **A row with an open `blocked_by` is never takeable, whatever its status column says.** That is
  derived from the graph, not read from the table, because the two disagree the moment a blocker
  closes and nobody edits the rows it was blocking. `./next <stage>` applies it for you and prints
  a `SKIP` line naming the blocker; applying it yourself is the fallback when there is no script.
- Row is `next: design` → **skip it**, name it, and say what its open question is. The item has no
  acceptance criteria yet by definition, so building it means inventing the contract you would
  then be verified against. Settle it with `/design` or `/prototype` first. Do not "just start"
  on a design row because the title reads clearly — the title is not the spec.
- Argument is an ID whose `next` is `design` → say so and stop rather than proceeding. Offer to
  settle the question first. Same for `next: queue`: it is not specified enough for any stage to
  take it, so hand it back to `queue` rather than inventing the missing half.
- Row is `in-progress` → **it belongs to another session unless you minted its claim token in
  this conversation.** Skip it and take the next takeable row, naming the token you skipped. Do
  not take it over because the work looks stalled or the tree looks like nobody is on it; ask.
- No backlog directory → tell the user and offer `queue` to start one. Don't invent work.

**On size:** the rank is absolute and you do not get to skip row 1 because it's an `l` and the
session is short. If row 1 is bigger than the budget, say so and let the user choose — take it
and stop at a clean commit boundary, or explicitly drop to a smaller item this once. Silently
picking something easier is how the important expensive item never gets done.

**Claim it under the lock.** `ready` → `in-progress` is a read-modify-write: two sessions that
both read `ready` before either writes will both take the item, and you will not find out until
you collide in the working tree.

**If the backlog has a `./claim` script, use it** — it does the whole claim as one step and is the
supported path:

```bash
.claude/backlog/claim 0007          # lock → re-read → edit row → frontmatter → commit → unlock
```

**The commit is the part that matters, and it is why this is a script.** A claim edits `QUEUE.md`;
until something commits that edit, the claim is visible only in your working tree, and the next
session to commit that file carries it off under their own message. That has happened. See
`CONCURRENCY.md`, *A claim must be durable the moment it is made* — and note that on a
tracker-backed backlog the API write is the durability and none of this applies.

Without the script, do it by hand, and **commit the row before releasing the lock**:

```bash
BACKLOG=".claude/backlog"
mkdir "$BACKLOG/.lock" 2>/dev/null || { cat "$BACKLOG/.lock/held-by"; }   # busy → see CONCURRENCY.md
CLAIM=$(head -c2 /dev/urandom | xxd -p)
```

**Check the file scope before you claim.** Read the `touches:` of every `in-progress` item, and
compare it against your candidate's `expects:` — the predicted scope `queue` recorded while the
code was open. That comparison is why `expects:` exists: without it you would have to research
every candidate yourself just to find out whether you may take it, and again for the next one
down. Trust it for *triage* and nothing else — it is advisory, it ages, and you verify it for
real in step 3 below. A candidate with no `expects:` at all is the case that still costs a look.

If your candidate's files overlap an in-progress scope, **take the next `ready` row whose scope
is clear instead**, and name the row you stepped over and the scope it hit. Two sessions in one file is the failure
this prevents, and there is no merge protocol to fall back on (`CONCURRENCY.md`, *The working
tree is shared too*). If every
`ready` row collides, say that there is nothing safe to develop right now rather than taking one
anyway.

Inside the lock, in this order:

1. **Re-read the row.** It may have changed since you chose it. If it is no longer `ready`,
   release the lock and pick again — do not proceed on the version you read a minute ago.
2. Set the row's `Status` to `in-progress`, as one single-line `Edit`. The token's home is the
   item's `claimed_by:` — the pared table has no ownership column; write `$CLAIM` into one only
   where a project's table still carries it.
3. Write `claimed_by: <token>`, `claimed_at: <ISO-8601 UTC>`, and `touches:` into the item file's
   frontmatter. **`touches:` is `expects:` checked against the code, never copied from it.** Grep
   for the symbols this item will alter and include what comes back — an item written weeks ago
   names the modules the work is *about*, and cannot name everything that *exercises* the
   behaviour being changed. Correct `expects:` where it was wrong rather than silently diverging
   from it; the next capture is calibrated by whether it turns out right. **`ls` the directories
   first rather than writing the filename the prose implies** — a path you guessed at reserves
   nothing, and the other window cannot tell it from one you are about to create. **A file this
   item will create is declared the same way**, because the field reserves scope rather than
   describing the tree; on a greenfield item every path is one of those, and saying so inline is
   what tells the other window which kind it is looking at.
4. **Commit the claim by pathspec** — `git commit -m "Claim 0007 [$CLAIM]" -- <queue> <item>`.
   Skipping this is what leaves the claim invisible to the other window and strands it in
   someone else's commit later.
5. `rm -rf "$BACKLOG/.lock"` — in this same turn, before any implementation work.

Widen `touches:` the moment the work reaches further than you declared: the other window is
reading it to decide what it may safely take.

**Then mirror the claim, if a tracker is configured** (`references/TRACKER.md`). Outside the
lock — a network call must never be made while holding it. If the item has no `tracker_key`
yet, create the ticket and write the key into the item's frontmatter; if it has one,
transition it to the in-progress equivalent. Note the key in your report so the user can
find it. A failure here is logged in the item's notes and does not stop the work.

Report the token to the user, so the other window's output is legible to them. Then read the
full item file before doing anything else.

---

## Step 2 — Restate the contract before writing code

Out loud, in three or four lines: the FRs you're satisfying, the NFR rows that apply, the ACs
you'll be held to, and the QA level. This is the last cheap moment to catch a
misunderstanding.

**If the item's real acceptance is a look, get something to look at in front of the author before
you build it properly** — and that includes an item whose *written* acceptance is entirely
numeric. A correctness fix that changes an appearance as a side effect has an unwritten AC only
the author can settle, and nothing in the item will flag it: one item's ACs were all contrast
ratios, so this rule never fired, and a complete implementation was built, tested and committed
before the author saw the new look and rejected it in one line. Ask what the change *looks* like,
not only what it must measure.

An AC that only a human can settle — does this feel right, does it read as
a place, is this the shape we meant — is not verified by any amount of implementation, and every
test written against a *guessed* look is thrown away with the guess. One item spent three complete
implementations, each with its own suite, before the author saw anything; the first two were
discarded whole. Build the cheapest thing that answers the question — `prototype` exists for this
— and only then implement to the full standard against an answer you have.

Two habits follow from the same arithmetic, and they are what makes the loop cheap:

- **Show a batch, not a guess.** When you are tuning something perceptual, put the candidates in
  front of them together — variants side by side in one image or one page. A round trip per guess
  costs the same as a round trip per batch and answers a fraction as much.
- **Look once per round.** Rendering a screenshot to check each parameter in turn is the same
  mistake pointed at yourself: composite the variants into a single sheet and read that.

**If the item is underspecified — no FRs, no ACs, or a stale problem statement — stop and fix
the item first** (and if what is missing is a design decision rather than detail, that is a
`design` item, not a fixable one — set the status and hand it back), then proceed. An item that can't be restated can't be verified. Update the
item file so the next reader gets the improved version.

If the item's assumptions have gone stale since it was queued (the code moved, the bug is already
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
— another window can commit whatever you leave staged, and has (`CONCURRENCY.md`, *The git index
is shared*). So:

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
here — queue them as new backlog items and keep going. That's what the queue is for. Note
them as you go; the `/retro` hand-off in Step 6 is the backstop that gets them written down, not
the place to start remembering them.

Append anything non-obvious you learn to the item's **Notes & decisions** as you learn it —
a disproved theory, a mechanism that surprised you, a rule that misled you.

**What has no home yet goes in `.claude/backlog/FINDINGS.md`, one dated line, as you hit it.** A
skill that misled you, a cost pattern, a fragility you are not fixing here: parking it costs a line
now and saves reconstructing it at the end, when the context has gone. Anything whose home *is*
obvious — a mechanism, a rule, a unit of work — goes to that home instead, not here.

---

## Step 5 — Leave the tree green, then stop at `next: verify`

**This skill does not run the item's QA level and does not close the ticket.** QA is the declared
`qa_level` checked against the written ACs, and it happens in a `verify` session. Do not
self-certify: the point of a separate pass is that it checks what the ACs *say* rather than what
you remember building, and no amount of care makes the implementing session able to read them that
way.

**What you do run is the project's whole test suite once — every runner it has, not the item's
declared level.** That is not QA. The level says what this item had to *prove*; it does not say
what this item was allowed to *break*, and those are different questions. A `unit` item that
changes a shared default can leave the browser suite red and pass QA, because nothing on its path
ever started a browser. That has happened: an item shipped a model change under `qa_level: unit`
and left four end-to-end specs failing, and it was two items before anything ran them — by which
point the fix was archaeology rather than a one-line correction, and needed a backlog item of its
own. Handing a red tree to a QA session spends that whole session on a diagnosis you already had
the context for.

If the full suite is red in a file this item never touched, **find out whose it is before
touching anything**: `git log -1 -- <path>` and the in-progress rows will usually say. Another
session's red is theirs to fix and yours to report, not to repair silently. If the tree is too
entangled to judge, run it in a throwaway worktree (`git worktree add`) so you are reading your
own work rather than the shared tree, and remove it in the same turn.

**A red in a file you *did* touch still has two owners, and telling them apart is the whole
job.** Your change can have **falsified** a check — it asserts a rule this item deliberately
reverses, and rewriting it is part of the work — or it can have **exposed** one that was already
fragile, where the item merely added load, data or timing the check could not absorb. Both look
identical at the failure: a plausible assertion about behaviour you just changed. The throwaway
worktree separates them — run the check at the commit before your work, under the same
conditions. Green there means it is yours; red there means it was fragile before you arrived.

**That comparison settles it only for a check that is deterministic, and the failure is
confidently backwards.** Where the check samples anything the runner re-rolls per run — a random
seed, a generated fixture, wall-clock pacing, a port or a worker assignment — one run at each
commit compares two draws rather than two commits, and the likeliest outcome of a 1-in-6 flake is
exactly the one that indicts you: red on your tree, green at the baseline. So before concluding
from a single pair, ask what the check re-rolls; if anything, repeat both sides (`--repeat-each`
or the runner's equivalent) and compare **rates**, not verdicts. A session lost real time to this
after doing the worktree comparison correctly and believing its answer — the spec drew a fresh
random board per page load, and repeating it showed 1 failure in 6 **at the baseline** against 0
in 6 on the working tree.

Fix the first. **Queue the second rather than stabilising it inside this item**, because an item
that adopts every fragile check it brushes against stops being the item that was ranked. This is
not hypothetical: a gesture item correctly re-anchored two specs it had genuinely invalidated,
then spent a comparable stretch chasing a timing coupling that predated it — and the cheap
mitigation it landed (capping the runner's workers) belonged in its own row, which is where the
real fix now sits.

### Then stop, in this order

1. Run the review checklist the conventions define for changed code. This is a build-quality gate,
   not QA — a `verify` session checks the contract, not your diff.
2. **Write down anything you learned while the item file is still open** — a non-obvious
   mechanism, a theory you disproved, a rule that misled you — per the conventions' own
   documentation rules, in the item's *Notes & decisions*. The QA session will not have had the
   context that produced any of it.
3. **Record what the item cost, if `cost_tracking:` is configured** — see `references/TRACKER.md`
   for the fields. This session is the only thing that knows which item its tokens belonged to, so
   it is the only place the attribution can be captured; a `verify` session appends its own share
   when it closes. This is what turns `size: m` from a guess into a calibrated estimate.
4. **Set the ticket to `next: verify` and `status: ready`, and clear `claimed_by:`, `claimed_at:`
   and `touches:`.** You are no longer holding the row or its files, and the QA session claims
   both itself — a `touches:` left behind reserves files nobody is editing, which is the
   ambiguity `CONCURRENCY.md` warns reads as "held". **Take the lock for the row edit and commit
   before releasing it** (`CONCURRENCY.md`, *Lock every write to `QUEUE.md`*).
5. **Commit by pathspec, alongside the code change.** `git commit` commits the *entire index*
   rather than the paths you staged a moment ago — so `git add <paths> && git commit` is not
   sufficient and has silently swept another session's work into a backlog commit. Name the paths
   on the commit itself: `git commit -m "…" -- path/one path/two`. **Verify first and stage last**:
   a `git diff --cached --name-only` read-back proves what is staged at that instant and grants
   nothing about the moment the commit runs. **A pathspec is necessary but not sufficient for a
   file the other window also edits** — it commits that file's whole current state, their rows
   included, and no timing on your side prevents it. When it happens anyway, report it rather than
   rebasing.
6. **Mirror the state, if a tracker is configured** (`references/TRACKER.md`) — transition the
   ticket to its in-review equivalent and comment the commit SHAs, so a human reading the ticket
   can reach the code. Failure is logged in the item's notes, never a blocker.

**If you cannot get the tree green**, set the ticket back to `next: develop` with
`status: ready` — or `blocked`/`waiting` with the reason — clear the claim token and `touches:`,
and report honestly what is left. Never hand a red tree to QA as though it were done.

**Do not push** unless the project's `CLAUDE.md` or `git-conventions.md` says so, or the user
asks. Building an item is not authority to publish it.

**Then stop and report.** The ticket is built and awaiting QA; name the command the next session
runs — `/verify <id>`, in a new session, per *one skill per session*. Do not invoke it here.

---

## Step 6 — Name the retro; do not run it

**Do not invoke `/retro` — a later session does.** Same precedent as `design`'s *"Do not invoke
`/prototype` — the user does"*: pulling another skill into this session re-injects its whole
instruction file into the largest context in the run, and that mechanism is why a measured
end-to-end run averaged 191,752 context tokens per turn.

**What a retro is for has not changed, and none of it is optional.** Step 5 records what you
learned while the item file was open, which is the half that tends to get done. The half that
falls through is the work this work *created*: the deferrals, the reds you proved were not yours,
the thing you noticed and moved past. A finding that reaches only your final report is lost the
moment the conversation ends, and lost in the most expensive way — the next session re-derives it
with none of the context you had.

It is a separate skill for the same reason `verify` is: building an item, checking it, and learning
from it are three jobs, and the last two are the ones that get cut short when one session owns all
three. **What makes that durable now is Step 7, not this step** — anything that surprised you is on
disk in `FINDINGS.md`, so a retro that runs next week still has it.

`/retro` is not a lifecycle stage and not a `next` value; it runs on a cadence over many sessions'
parked findings. Say in your report whether the buffer looks worth sweeping, and name the command:
`/retro`, in its own session.

---

## Step 7 — Park what surprised you

Before reporting, write anything that surprised you into `.claude/backlog/FINDINGS.md` as one
dated line. This is the discovery-time recording `documentation-conventions.md` already requires,
at the one moment the context is still hot.

Triggers, at minimum: **a template or skill step that had no correct answer for your case**; **a
configured command that behaved unexpectedly**; **a scaffolding step you had to invent**.

**An explicit "nothing surprised me" is a complete result.** The habit must not manufacture
findings to justify itself — an invented entry is read, and paid for, by every later session.

**Commit `FINDINGS.md` in the same turn you write it, by pathspec** —
`git commit -m "Park what <skill> hit" -- .claude/backlog/FINDINGS.md`. A finding left uncommitted
until close is one `git stash` from gone, and it is the other window's commit that carries it off.

Anything whose home is already obvious — a mechanism, a rule, a unit of work — goes to that home
instead of here.

---

## Step 8 — Report

What was built, what changed, the full-suite result, anything parked in `FINDINGS.md`, the ticket
now sitting at `next: verify`, and what's next at the top of the queue. The ticket is **not**
closed — say so, and name the two commands a following session runs: `/verify <id>` to close it,
and `/retro` if the buffer is worth sweeping. Each in its own session.
