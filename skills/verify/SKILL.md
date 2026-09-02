---
name: verify
description: >
  Verify a change against a backlog item's acceptance criteria and non-functional requirements
  at the QA level the item declares — unit, integration, or end-to-end. Use when the user says
  "QA this", "verify it", "check it works", "run the e2e tests on this", "does this meet the
  criteria", or invokes /verify. Runs in its own session on a ticket `develop` left at
  `next: verify`, and is the stage that closes it. Reads .claude/backlog/items/ for the
  acceptance criteria and QA plan.
---

# /verify

Verify that a change satisfies what was promised. `/code-review` hunts defects in a diff; this checks a
change against a **written contract**.

**One skill per session.** Run this skill in its own conversation; the backlog carries the handoff — the
ticket's `next` field and `FINDINGS.md`, never a conversation. **Observed 2026-08-23/24** over 30 isolated
sessions: a `verify` turn is the suite's cheapest at **$0.0946 and 97,965 context tokens**, against a
baseline $0.1203 at 151,669 (`MEASUREMENT.md`). **No standard is relaxed** — the rigour is all in the
fifth of spend that is output.

**One gate per invocation, not one ticket.** The same batching case applies for the same reason:
**one gate per session, not one ticket per session** — tickets that share a file scope or a parent
slice are checked in one session, since the conventions, this file and the suite's startup are a
shared cost paid once however many verdicts come out of it. **A batch does not license one verdict
covering several tickets.** Each ticket closes on its **own acceptance criteria** at its own declared
`qa_level`, and a failing AC fails that ticket alone — never the batch, and never the reverse: one
green ticket does not carry its neighbours. Claim and close each row individually
(`CONCURRENCY.md`, *A stage writes only the ticket it holds*). The dated figure is capture-side,
**2026-08-22**; the recorded 2026-08-23/24 run held no batched session, so the figure for this side of
the gate is still unmeasured (`MEASUREMENT.md`).

**`verify` closes the ticket.** On green it ticks the ACs, sets it done, moves the row to `DONE.md` and
releases its claim. `develop` closes nothing: a verdict that must travel from the session producing it
to the session acting on it has nowhere to travel once each skill runs alone.

**What keeps two sessions off one ticket is the `next` field, not a read-only rule** — this skill acts
only on tickets whose `next` is `verify`, and nothing is developing those, so **refuse anything
addressed to another stage** (Step 1). Read `references/CONCURRENCY.md` at the plugin root, *A stage
writes only the ticket it holds*, first.

**This skill states no standards of its own** — secure, private, accessible and adequately tested are
cited from the project's conventions, never restated. Resolve them per `references/CONVENTIONS.md`. A unit
of work you notice goes to `queue`; an unplaceable finding goes in `FINDINGS.md` (Step 6).

---

## Step 1 — Get the contract, refuse what is not yours, then claim it

With an ID: read `.claude/backlog/items/<id>-*.md` and take the **Acceptance criteria**,
**Non-functional requirements** and **QA plan**. With no argument, `./next verify` prints the topmost
`next: verify` / `status: ready` row.

Without the scripts, read `QUEUE.md` and apply the same rules by hand — and note that
**`blocked_by` decides takeability, never the `Status` column**, which only caches it. Claim by hand
under the lock, committed before you release it. The project that *ships* these scripts is the one
most likely not to have them installed.

**Refuse a ticket whose `next` is not `verify`, and name what you found instead.** A `develop` row is not
built yet; a `design` row has no acceptance criteria, so a verdict would be issued against a contract you
invented; a `queue` row is not specified enough for any stage. Checking one anyway means QA-ing work
another session is mid-way through, where a red means "unfinished" and looks like "broken".

No backlog ticket at all: verify against whatever the user stated as the goal, saying explicitly that
an unwritten contract is weaker. Nothing is closed on that path.

**Then claim the row, because this stage writes.** `./claim <id>` locks, edits the row, writes the token
into the frontmatter, commits and unlocks as one step. By hand only without a script, and **commit inside
the lock** (`CONCURRENCY.md`, *A claim must be durable the moment it is made*).

Read `config.yml` for the project's real commands and resolve the conventions per
`references/CONVENTIONS.md`. If none resolve, stop — a verdict against no standard is indistinguishable
from a real one, which is the failure this whole design prevents.

---

## Step 2 — Check whose tree you are testing, then run the declared level

**Before running anything**, `git status --porcelain`. A second window mid-edit means the suite covers a
file set that never existed as a coherent state: its red may belong to work half-written, its green may
be luck.

- Changes confined to the ticket → proceed.
- Changes outside it → **still run**, and **record the unrelated paths as a set**. The label is not
  decided here: Step 7 derives it against the paths the verdict actually rested on, because at this
  point the pass does not yet know which files its ACs rest on.
  **Do not stash, revert or check out to tidy** — destroying another session's work is far worse than an
  imprecise verdict — and a pathspec on a `stash` does not make it safe (`CONCURRENCY.md`).

**At `qa_level: e2e` the working tree cannot be the subject at all** — the evidence set is the whole
application, so Step 7's intersection is never empty and no such ticket could close here. Verify a
named commit in a worktree and report its SHA: `CONCURRENCY.md`, *The working tree is shared too*.
- `in-progress` under a token **you did not mint in this conversation** → another session's. Say whose
  it seems to be and stop; Step 1's refusal normally prevents this, so reaching here means the field
  and the claim disagree.
- **Dirty paths with no `in-progress` row at all are still not necessarily yours.** A skill holding no
  ticket writes without a claim — `retro` does so by design, editing skills and conventions mid-pass —
  so the row-and-token check reads perfectly clean while the tree is not. `git status` is the authority
  here and the row is not; a clean queue is not evidence about the tree.

**And check which *copy* you are executing, when the change under test is a skill or a plugin file.**
Skills run from the pinned install under `~/.claude/plugins/cache/<plugin>/<version>/`, not from this
repo, so an edit committed here is not live until the version is bumped and the install updated
(`SOURCE`). The session verifying a skill change is therefore the least likely to be running it: treat
the repo copy as the authority, and say which copy executed.

The `qa_level` was set at queue time. Run **that** level and everything below it — levels are
cumulative, on the pyramid in `testing-conventions.md`.

| Level | Run |
|---|---|
| `verify` | the scripted assertion the QA plan names, plus lint/typecheck if present. It must be *executed* and its output shown — read-and-eyeballed is not verified |
| `unit` | lint, typecheck, unit suite scoped to the change |
| `integration` | the above, plus the integration suite across the seams touched |
| `e2e` | the above, plus the journeys the QA plan names |


**If the declared level has no command in `config.yml`, stop and say so** — substituting a lower level is
the silent downgrade the per-ticket declaration exists to prevent.

**A configured level with no tests yet is an empty set, not a red.** Levels being cumulative, an
`integration` ticket on a young project runs a unit command over an empty directory, and most runners
exit non-zero on "no test files found" — failing-looking when nothing failed. Report `no tests at this
level`. The genuine red is the opposite: a level that *had* tests and now collects none.

Scope to the change and keep output lean. **For e2e:** drive the real entry point against a local or
staging target with synthetic data — never production credentials — and stop every server, container or
browser you started, this same turn.

---

## Step 3 — Check the acceptance criteria literally

Walk each AC and record how you verified it — which test, which behaviour, which screenshot — **and
where**: the repo paths that verification read or executed, the files asserted over, the fixture, the
script run. Those paths are the run's **evidence set**, and Step 7 derives the advisory label from
them; **a path in doubt is in the set**, because a missed one costs a re-run and the other direction is
a wrong close. "Looks right" is not a verification, and an AC you cannot verify is a **fail**.

**Never trust a tick you did not write.** A ticket that has been round the loop arrives with ACs
already ticked by an earlier pass — but a tick is evidence about the contract *as it then stood*, and
anything that sent the ticket back changed either the contract or the code under it. Re-check every AC
and re-tick from your own evidence. The opposite reading, that verified stays verified, is how a real
regression closes unchecked, and `verify` closes on ticked ACs.

**A green check is only evidence if it could have been red, and confirming that is your job rather than
the implementer's** — they have already convinced themselves, and distrusting that is why this pass is
separate. For each AC resting on an automated check, break the behaviour it exists to catch, confirm it
goes red, then restore it **by the path you mutated and no other** (`git checkout -- <that path>`); a
bare `git checkout -- .` destroys the other window's uncommitted work in the tree Step 2 warned
about.

The failure mode is not a check wired to nothing, which is obvious. It is a check that runs, asserts,
and measures something *adjacent* to the defect — a drag ending off the element under test, so the click
never lands there and it passes against deliberately broken code. Budget this for the checks you would
cite when closing; **a check that cannot be made to fail leaves its AC unverified.**

**And a check can only see what its runner can represent** — a headless browser has no compositor and
no finger, a fake clock has no drift. If the defect lives in what the runner *substitutes*, no result
counts in either direction: fall back to the level that can observe it, even when that is a human on a
device. **A higher test level is not automatically stronger**, and promoting a ticket to one that
structurally cannot see the bug buys a green light meaning nothing.

---

## Step 4 — Check the NFRs that the ticket declared

**First, ask what the change made newly *reachable*.** The ACs enumerate what the change must do;
nothing in them covers a path the change **creates**, because there was nothing to write an AC about
when the ticket was queued. Any change to routing, visibility, permissions, or the conditions under
which a screen or endpoint is offered adds previously unreachable states — and a destructive or
privileged action on one is now available by a route nobody reviewed. Walk those states against the
rules the project holds elsewhere — one change put an unconfirmed discard one tap away this way, with
every written AC passing.

**A probe written to answer that is scaffolding**: put it where the project says throwaway specs go
and remove it in the same turn, as Step 3 restores a mutation by the path it mutated. **One worth
keeping is not deleted — it is the guard the gap called for**: say so and queue it.

For each filled NFR row, confirm the requirement holds and **load the cited convention file** — the row
says what this ticket must satisfy, the convention says what the rule is, and you check against the
rule. Record each checked row's paths into Step 3's evidence set on the same terms.

Then the always-on pass regardless of the table: **read `CONVENTIONS_CORE.md` for the current always-on
rules and check the diff against them.** This skill deliberately does not list them; a copy here would
drift and you would check the stale version.

The privacy pass in `data-privacy-conventions.md` runs on any change adding or moving a log field, an
analytics event, or an egress destination, row or no row. A change touching auth, credentials or data
visibility with no Security row is a **gap in the ticket** — flag it and run `security-conventions.md`
anyway; same for a UI change with no Accessibility row. A missing row is an oversight at queue time,
not permission to skip the check.

---

## Step 5 — Act on the verdict

This is the stage that closes, and it happens in the session that produced the verdict — so no durable
verdict file exists or is needed. **Banking one was considered and rejected**: a banked verdict is a
tick the next session did not write, and a file hash certifies which bytes were read, never that the
earlier pass mutated the right behaviour and saw it go red.

**On green, close it with `./close`** — one step, and the supported path:

```bash
.claude/backlog/close 0007 8a04        # lock → re-read → tick ACs → move row → reconcile → commit → unlock
```

It does the whole sequence below under the lock and **commits it**, which is the step a session under
load forgets (`CONCURRENCY.md`, *The three scripts*). It refuses rather than guessing on four grounds:
a table shape it cannot read, a row not at `next: verify`, a token that is not the one holding the
claim — you pass the token because ownership is memory and no script can check memory — and **an
acceptance-criteria list it cannot tick**. That last one is yours to fix before you can close:
`close` ticks `- [ ] AC1 — …` and nothing else, so a ticket whose criteria are written
`- **AC1** —` once closed with zero of eight ticked, and the record that each criterion was checked
was simply absent. Rewrite them in the checkbox form and close again — never hand-tick around it,
because the tick is the evidence your run produced.

By hand, under the lock, committed before you release it — the fallback where the script is not
installed:

1. Tick the ACs, set `status: done` with the date, clear `touches:` — a closed ticket must not keep
   reserving files — and clear `claimed_by:` / `claimed_at:`.
2. Re-read `QUEUE.md` — another window has had the whole QA run to insert rows — then delete your row
   with a single `Edit` and append it to `DONE.md`, newest first.
3. **Reconcile every ticket that named this one in `blocked_by`, in this same commit.** `blocked` is
   derived, not authored: the ticket you just closed *is* what clears those rows, and nothing else
   will. Grep the items for your ID, and for each one whose remaining `blocked_by` entries are all
   `done`, set its row and its item `status:` to `ready` (or `waiting`, if its `## Waiting on` section
   says a person is needed). **Two of those you must not write**, and neither has to have a row —
   `blocked_by` is never cleared, so a `done` dependent still names you and reconciling it resurrects
   a closed ticket; and a dependent that is held is reported, not written — *held* is defined
   once, in `CONCURRENCY.md`'s *A stage writes only the ticket it holds*, and a row reading
   `in-progress` over a tokenless item is not it.
   Skip anything whose own `status:` does not read `blocked`. Then run `./next --drift` and expect
   zero **for the rows you reconciled**, not for the file:
   drift an earlier close left behind names no ticket you hold, so reconciling it is forbidden and a
   non-zero exit here can be entirely someone else's. Diff the report before and after your reconcile,
   and report what was already there rather than owning it. **Across a batch, "already there" is
   measured from the session, not the close** — the second close's before-report contains the first
   close's effects, which are yours; take the first close's before-report as the session's baseline, or
   the rule stops separating your drift from anyone else's exactly where a batch made it likely.

   **This reverses the previous rule that a close touches "nothing else".** That rule was narrower
   writes, which `CONCURRENCY.md` is right to want — but it left the only event that can clear a
   `blocked` row unable to clear it, and a closed ticket once left four rows unavailable for a whole
   session with nothing blocking them. Narrow writes lost to a queue that lies. You still hold the
   lock, and you write nothing that is held — leave a claimed dependent alone and say so in your
   report; its own session will see the drift.
4. **Commit by pathspec** — with the `Co-Authored-By` trailer (`git-conventions.md`) — **then**
   release the lock. The order matters: the lock guards the commit,
   not just the edit, because the commit takes `QUEUE.md` whole (`CONCURRENCY.md`, *Lock every write to
   `QUEUE.md`*).
5. Record this session's cost share if `cost_tracking:` is configured, and mirror the close if a
   tracker is (`references/TRACKER.md`) — outside the lock, since a network call must never be made
   while holding it. Failure is logged in the notes, never a blocker.

**On red**, the failure reason goes in the item's *Notes & decisions* **before** you touch any field:
what failed, the actual output, which AC. Then `next: develop, status: ready`, claim released, under the
lock, committed. Flipping the field without the reason makes the next `develop` session re-derive the
failure from nothing — the half most easily skipped, because the red is still fresh in a conversation
about to end.

**On a stale contract** — the ACs no longer describe reality, so neither pass nor fail is honest —
write why in the notes and set `next: queue, status: ready`. Do not re-specify it yourself.

**On ACs only a person can clear, `status: waiting`** — the fourth branch, routinely forced into one
of the three above. A ticket green on its scripted half whose rest needs a device or the author's
eye is not closeable (those ACs are unmet), not `develop` (no code is owed, so that session reruns
the suite and hands it back), not `queue` (the contract is fine). Set `status: waiting`, `next` to
the stage that resumes, and **write the item's `## Waiting on` section naming who must do what**.
Tick the ACs you cleared, then release the claim.

**Do not push** unless the project's conventions say a close should, or the user asks.

---

## Step 6 — Park what surprised you

Before reporting, park what surprised you in `.claude/backlog/FINDINGS.md` — one dated line, while the
context is still hot.

Triggers: **a template or skill step that had no correct answer for your case**, a configured command that
behaved unexpectedly, a scaffolding step you had to invent.

**An explicit "nothing surprised me" is a complete result** — never manufacture one, since an invented
entry is paid for by every later session. **Commit it in the same turn you write it, by pathspec**;
uncommitted it is one `git stash` from gone. Anything whose home is obvious goes there instead.

---

## Step 7 — Verdict

State **PASS** or **FAIL** plainly, then the evidence table: each AC and NFR row, how it was checked, the
result, with the actual failure output for anything red.

**Advisory is derived, never authored:** intersect Step 2's dirty set with Step 3's evidence set. No
session applies the label as a judgement about whether the dirt *looks* relevant.

- **Empty intersection → not advisory.** A plain PASS, closing by Step 5's normal path. The verdict
  names the dirty paths it excluded and states that the intersection was empty.
- **Non-empty intersection → advisory, and it does not close the ticket.** Leave the row at `next:
  verify, status: ready`, release the claim, and name the intersecting paths. **"I checked both the
  committed and the working copy and they agreed" is not grounds to close** — agreement across two
  snapshots is not independence, because the other session's edit is unfinished and the state it will
  commit does not exist yet.

A partial pass is a FAIL with a list. Never soften a red or report a skipped check as though it ran. State
what Step 5 did — closed, or sent back to `develop` or `queue` — and name the commit. Unrelated problems
go to `queue` as new tickets.
