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
written ACs and close it.

**This skill does not close the ticket.** `verify` does, because the stage holding the verdict is
the stage that should act on it — there is then no window in which a green goes stale, and no
verdict has to survive a session boundary in conversation. Your last act is the implementation
commit plus `next: verify, status: ready`.

**One skill per session.** Run this skill in its own conversation; the backlog carries the handoff —
the ticket's `next` field and `FINDINGS.md`, never a conversation. **Observed 2026-08-23/24** over 30
isolated sessions: a `develop` turn costs **$0.1044 at 109,750 context tokens**, against a baseline
$0.1203 at 151,669 — context per turn down 30%, cost 14.5%, short of the projected two-thirds
(`MEASUREMENT.md`). **No standard is relaxed** — the rigour is all in the fifth of spend that is output.

**One gate per invocation, not one ticket.** The unit is a gate: **one gate per session, not one
ticket per session** — a set of tickets that share a file scope (their `expects:` overlap) or share a
parent slice, all `next: develop` and takeable. Tickets from unrelated projects do not batch, because
what a batch saves is the startup a session pays before it writes a line — the conventions, the
project's `CLAUDE.md`, `CONCURRENCY.md`, this file, the orientation in the code — and that is only
shared where the files are. Two guardrails, both of which a real eleven-ticket run needed:
**Claim and close each ticket individually** — the row is the unit of ownership whatever the session
is, and a batch holding rows it is not yet working on is the scope reservation `CONCURRENCY.md`
forbids — and **Stop at the first ticket whose contract turns out wrong** rather than carrying a bad
assumption into the rest of the batch. The figure behind this is capture-side and dated
**2026-08-22**: five related tickets in one session cost measurably less per ticket than five
sessions would have. **0026** looked for the develop-side figure in the 2026-08-23/24 sessions and
found no batched session to measure; producing it needs a run designed for it.

**Another session may be working this same backlog.** Read `references/CONCURRENCY.md` at the plugin root
(`../../references/CONCURRENCY.md` from this file) before touching any backlog file.

**This skill states no standards of its own.** How to build, test, commit, and review is
defined by the project's conventions and cited here, never restated. Resolve them per
`references/CONVENTIONS.md`.

---

## Where work is tracked, and where cost is recorded

Two optional `config.yml` blocks change what this skill does at claim and at stop. Both are **off
unless configured**, and this skill never prompts to set them up. Read `references/TRACKER.md` before
acting on either.

- **`tracker:`** — an external tracker the backlog **mirrors to, one way**. The local item stays the
  source of truth: it holds the FRs, NFR citations, ACs and QA level a ticket does not, and an agent
  must never be blocked on the network. *Which* tracker is a company-profile question, not this
  skill's. A failed mirror call is logged in the notes and does not block.
- **`cost_tracking:`** — record what this session spent before it stops. Only the session that did
  the work knows which ticket its tokens belonged to; `verify` appends its own share. Aggregate spend
  is recoverable later, the attribution is not.

---

## Step 1 — Select and claim the item

**Run `./next develop` rather than reading `QUEUE.md`.** It prints the first takeable row — `next:
develop`, nothing still open in `blocked_by` — with its `size`, `qa_level` and `expects:`, plus the
files every in-progress ticket has claimed. Reading the queue whole to learn one row is the largest
avoidable context cost in the backlog; open the file only for questions about *order*.

```bash
.claude/backlog/next develop
```

Without the script, read `QUEUE.md` and apply the same rules:

- **No argument → the topmost takeable `next: develop` row.** The rank is not a suggestion.
- **An ID (`/develop 0007`)** → that ticket, but say so if you are skipping higher rows and why you
  believe that is intended.
- **`blocked` or `waiting`** → report which and what clears it: a named ticket, or for `waiting` the
  question in its `## Waiting on` section (`./next --waiting`). Then take the next takeable row.
  Never reorder to make your choice look correct.
- **`blocked_by` decides takeability, never the `Status` column** — `blocked` is derived, and the
  column only caches it. A row still naming an open ticket is not takeable however green the column
  looks, and a row written `blocked` whose `blocked_by` entries are all `done` **is** takeable: take
  it, say the column was stale, and fix it in your claim edit. Skipping it is how four rows sat
  unavailable for a whole session. `./next --drift` lists every disagreement between column and
  graph, in both directions, and exits non-zero if it finds any.
- **`next: design`** → skip it and name its open question. It has no acceptance criteria by
  definition, so building it means inventing the contract you will then be verified against. The
  title is not the spec. Same for **`next: queue`**: hand it back rather than inventing the missing
  half. Given as an explicit ID, say so and stop rather than proceeding.
- **`in-progress`** → another session's, unless you minted its token in this conversation. Skip it
  and name the token. Never take it over because the work looks stalled; ask.
- **No backlog directory** → offer `queue` to start one. Don't invent work.

**On size:** the rank is absolute, so you do not skip row 1 because it is an `l` and the session is
short. Say so and let the user choose — take it and stop at a clean commit boundary, or explicitly
drop down this once. Silently picking something easier is how the important expensive ticket never
gets done.

**Check the file scope before you claim.** Compare your candidate's `expects:` against the `touches:`
of every `in-progress` ticket. Trust it for *triage* and nothing else — advisory, ages, verified for
real below; a candidate with no `expects:` still costs a look. On overlap, take the next clear `ready`
row and name what you stepped over. If every row collides, say there is nothing safe to develop
(`CONCURRENCY.md`, *The working tree is shared too*).

**Claim it with `./claim`** — one step, and the supported path:

```bash
.claude/backlog/claim 0007          # lock → re-read → edit row → frontmatter → commit → unlock
```

**The commit is why this is a script**: until it lands, the claim is visible only in your working
tree and the next session to commit that file carries it off. On a tracker-backed backlog the API
write is the durability instead (`CONCURRENCY.md`, *A claim must be durable the moment it is made*).

By hand, under the lock, in this order — and `ready` → `in-progress` **needs** the lock, being a
read-modify-write two sessions can both win:

1. **Re-read the row.** No longer `ready` → release and pick again.
2. Set `Status` to `in-progress` as one single-line `Edit`.
3. Write `claimed_by:`, `claimed_at:` (ISO-8601 UTC) and `touches:` into the item's frontmatter.
   **`touches:` is `expects:` checked against the code, never copied.** Grep for the symbols this
   ticket will alter: a ticket written weeks ago names what the work is *about* and cannot name
   everything that *exercises* the behaviour. **`ls` the directories rather than writing the filename
   the prose implies** — a guessed path reserves nothing and the other window cannot tell it from one
   you are about to create, so **declare a file you will create the same way and say inline that it
   is new**. Correct `expects:` where it was wrong; the next capture calibrates on it.
4. **Commit by pathspec** — `git commit -m "Claim 0007 [$CLAIM]" -- <queue> <item>`, with the
   `Co-Authored-By` trailer (`git-conventions.md`). A lifecycle commit is not exempt from it.
5. `rm -rf .claude/backlog/.lock` — this same turn, before any implementation work.

Widen `touches:` the moment the work reaches further: the other window reads it to decide what it may
safely take.

**Then mirror the claim if a tracker is configured** (`references/TRACKER.md`), outside the lock — a
network call must never be made while holding it. No `tracker_key` yet → create the ticket and write
the key in; otherwise transition it. Note the key in your report. Failure is logged in the item's
notes and does not stop the work.

Report the token, then read the full item file before doing anything else.

---

## Step 2 — Restate the contract before writing code

Out loud, in three or four lines: the FRs you're satisfying, the NFR rows that apply, the ACs you'll
be held to, and the QA level. This is the last cheap moment to catch a misunderstanding.

**First, though: a ticket that has been round the loop carries a second contract, and it is the
expensive half.** Read *Notes & decisions* for a verdict a previous `verify` wrote — what failed, the
actual output, which AC, usually the suggested fix. On a re-entry **that section is the specification**:
the FRs and ACs are what was thought through before anyone tried it, the verdict is what turned out to
be wrong. A bounced ticket looks identical to a fresh one at Step 1, so nothing but this will tell you
to look, and the cost of missing it is rediscovering a failure someone already diagnosed.

**If the ticket's real acceptance is a look, get something in front of the author before building it
properly** — including when its *written* acceptance is entirely numeric. A correctness fix that
changes an appearance as a side effect has an unwritten AC only the author can settle, and nothing in
the ticket flags it: one ticket's ACs were all contrast ratios, so a complete implementation was
built, tested and committed before the author rejected the new look in one line. Ask what the change
*looks* like, not only what it must measure.

An AC only a human can settle — does this feel right, does it read as a place — is not verified by any
amount of implementation, and every test written against a *guessed* look is thrown away with the
guess; one ticket spent three implementations, each with its own suite, before the author saw anything.
Build the cheapest thing that answers the question (`prototype` exists for this), then
implement to the full standard against an answer you have. Two habits follow: **show a batch, not a
guess** — variants side by side in one image, since a round trip costs the same either way — and
**look once per round**, compositing variants into a single sheet rather than screenshotting each
parameter in turn.

**If the ticket is underspecified — no FRs, no ACs, or a stale problem statement — fix it first**, and
update the file so the next reader gets the improved version. A ticket that can't be restated can't be
verified.

**But if what is missing is a *decision* rather than detail, do not decide it — set `next: design`,
`status: ready`, write the question into the *Open design question* section, release the claim, and
stop.** Missing detail you sharpen here; a missing decision answered by the session about to build
against it is a contract nobody agreed to, and `verify` is what discovers you invented it. Name the
command: `/design <id>`, in its own session.

If the ticket's assumptions have gone stale (the code moved, the bug is fixed, a dependency changed),
say so and ask before building to a spec that no longer matches reality.

**Staleness also arrives from a sibling ticket, not only from the code.** An FR enumerating how a
mechanism works goes stale when another ticket *changes that mechanism* after this one was written —
every file it names still untouched, so nothing in the diff looks wrong. Check what closed since this
ticket's capture date (`DONE.md`) for anything owning the same mechanism, and treat a literal build of a
superseded FR as the stale contract it is. One ticket enumerated a five-step procedure that a sibling
had since made a six-step one; building it as written would have automated the very defect the sibling
existed to fix.

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

Follow the TDD cycle and the commit rules exactly as the conventions core states them — non-negotiable
there, and not restated here. Read it before the first line. For a bug, the first test reproduces the
bug and stays as a permanent guard.

**Read one sibling test in the target directory before writing the first test.** Not for style — for
what is wired up: which matchers exist (no `jest-dom` means no `toBeInTheDocument`), which helpers and
fixtures are there, `fireEvent` or `userEvent`, what the helpers return. Each is a red-to-red round
trip when guessed at, and they come in threes; one file read costs less than the first wrong guess.

Work FR by FR, committing each logical unit as it completes rather than one commit at the end, in the
conventions' commit format, referencing the ticket ID.

**Every commit contains this session's work and nothing else**, per `CONCURRENCY.md`, *The git index
is shared* — read it there rather than trusting a summary here. One thing is worth repeating:
**`git add <paths> && git commit` is not a substitute for a pathspec**, since `git commit` writes the
whole index.

Respect the ticket's **Out of scope**. Adjacent problems you find get queued as new tickets, not fixed
here. Append anything non-obvious to *Notes & decisions* as you learn it — a disproved theory, a
mechanism that surprised you, a rule that misled you. **What has no home yet goes in
`.claude/backlog/FINDINGS.md`, one dated line, as you hit it**; Step 7 is the backstop, not the place
to start remembering.

---

## Step 5 — Leave the tree green, then stop at `next: verify`

**This skill does not run the ticket's QA level and does not close it.** Do not self-certify: the
point of a separate pass is that it checks what the ACs *say* rather than what you remember
building.

**What you do run is the project's whole test suite once — every runner it has, not the ticket's
declared level.** That is not QA: the level says what this ticket had to *prove*, not what it was
allowed to *break*. A `unit` ticket changing a shared default can leave the browser suite red and
pass QA, because nothing on its path ever started a browser — that happened, and it was two tickets
before anything ran them. Handing a red tree to a QA session spends that session on a diagnosis you already had the context for.

**Red in a file this ticket never touched:** find out whose it is before touching anything
(`git log -1 -- <path>`, the in-progress rows). Another session's red is theirs to fix and yours to
report. If the tree is too entangled to judge, run it in a throwaway worktree (`git worktree add`) and
remove it in the same turn.

**Red in a file you *did* touch has two owners, and telling them apart is the whole job.** Your change
either **falsified** a check — it asserts a rule this ticket deliberately reverses, and rewriting it is
part of the work — or **exposed** one already fragile, where the ticket merely added load, data or
timing it could not absorb. Both look identical: a plausible assertion about behaviour you just
changed. The throwaway worktree separates them — run the check at the commit before your work, under
the same conditions. Green there means it is yours.

**That settles it only for a deterministic check, and the failure is confidently backwards.** Where
the check samples anything the runner re-rolls — a seed, a generated fixture, wall-clock pacing, a
port or worker assignment — one run at each commit compares two draws rather than two commits, and the
likeliest outcome of a 1-in-6 flake is exactly the one that indicts you. Ask what the check re-rolls;
if anything, repeat both sides (`--repeat-each`) and compare **rates**, not verdicts. A session lost real time
on a correct worktree comparison: the spec drew a fresh random board per load, and
repeating showed 1 failure in 6 **at the baseline** against 0 in 6 on the working tree.

Fix the first. **Queue the second rather than stabilising it inside this ticket** — a ticket that
adopts every fragile check it brushes against stops being the ticket that was ranked.

### Then stop, in this order

1. Run the review checklist the conventions define for changed code. A build-quality gate, not QA.
2. **Write down what you learned while the item file is open** — a mechanism, a disproved theory, a
   rule that misled you — per the conventions' documentation rules, in *Notes & decisions*. The QA
   session will not have had the context that produced any of it.
3. **Record the cost if `cost_tracking:` is configured** (`references/TRACKER.md`). This session is
   the only thing that knows which ticket its tokens belonged to; `verify` appends its own share. This
   is what turns `size: m` from a guess into a calibrated estimate.
4. **Set `next: verify`, `status: ready`, and clear `claimed_by:`, `claimed_at:` and `touches:`.** You
   hold neither the row nor its files any more, and the QA session claims both itself — a leftover
   `touches:` reserves files nobody is editing, which `CONCURRENCY.md` says reads as "held". Take the
   lock for the row edit and commit before releasing it.
5. **Commit by pathspec, alongside the code change** (`CONCURRENCY.md`, *The git index is shared*).
6. **Mirror the state if a tracker is configured** — transition to its in-review equivalent, comment
   the commit SHAs. Failure is logged in the notes, never a blocker.

**If you cannot get the tree green**, set `next: develop` with `status: ready` — or `waiting` with the
reason, or a `blocked_by` entry naming the ticket that must land first, since `blocked` is derived and
never typed — clear the claim and `touches:`, and report what is left. Never hand a red tree to QA
as though it were done.

**Do not push** unless the project's `CLAUDE.md` or `git-conventions.md` says so, or the user asks.
Building a ticket is not authority to publish it.

**Then stop and report.** Built and awaiting QA; name the command the next session runs — `/verify
<id>`, in a new session. Do not invoke it here.

---

## Step 6 — Name the retro; do not run it

**Do not invoke `/retro` — a later session does.** Pulling another skill in re-injects its whole
instruction file into the largest context in the run; a measured run averaged 191,752 context tokens
per turn.

**What a retro is for has not changed, and none of it is optional.** Step 5 records what you learned
while the item file was open. The half that falls through is the work
this work *created*: the deferrals, the reds you proved were not yours, the thing you noticed and moved
past. A finding that reaches only your final report dies with the conversation — the next session
re-derives it with none of your context. **Step 7 is what makes it durable**, not this step.

`/retro` is not a lifecycle stage and not a `next` value; it runs on a cadence over many sessions'
findings. Say whether the buffer looks worth sweeping, and name the command —
`/retro`, in its own session.

---

## Step 7 — Park what surprised you

Before reporting, park what surprised you in `.claude/backlog/FINDINGS.md` — one dated line, while the
context is still hot.

Triggers: **a template or skill step that had no correct answer for your case**, a configured command that
behaved unexpectedly, a scaffolding step you had to invent.

**An explicit "nothing surprised me" is a complete result** — never manufacture one, since an invented
entry is paid for by every later session. **Commit it in the same turn you write it, by pathspec**;
uncommitted it is one `git stash` from gone. Anything whose home is obvious goes there instead.

---

## Step 8 — Report

What was built, what changed, the full-suite result, anything parked in `FINDINGS.md`, the ticket
now sitting at `next: verify`, and what's next at the top of the queue. The ticket is **not**
closed — say so, and name the two commands a following session runs: `/verify <id>` to close it,
and `/retro` if the buffer is worth sweeping. Each in its own session.
