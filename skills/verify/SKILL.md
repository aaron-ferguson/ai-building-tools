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
ticket's `next` field and `FINDINGS.md`, never a conversation. Measured **2026-08-22**: **85% of $15.11
went on context handling** at **191,752 tokens per turn**, modelling to **~$5.09** isolated. **No standard
is relaxed** — the rigour is all in the 15% that was output.

**`verify` closes the ticket.** On green it ticks the ACs, sets it done, moves the row to `DONE.md` and
releases its claim. `develop` closes nothing: a verdict that must travel from the session producing it
to the session acting on it has nowhere to travel once each skill runs alone.

**What keeps two sessions off one ticket is the `next` field, not a read-only rule** — this skill acts
only on tickets whose `next` is `verify`, and nothing is developing those, so **refuse anything
addressed to another stage** (Step 1). Read `references/CONCURRENCY.md`, *A stage writes only the ticket
it holds*, first.

**This skill states no standards of its own** — secure, private, accessible and adequately tested are
cited from the project's conventions, never restated. Resolve them per `references/CONVENTIONS.md`. A unit
of work you notice goes to `queue`; an unplaceable finding goes in `FINDINGS.md` (Step 6).

---

## Step 1 — Get the contract, refuse what is not yours, then claim it

With an ID: read `.claude/backlog/items/<id>-*.md` and take the **Acceptance criteria**,
**Non-functional requirements** and **QA plan**. With no argument, `./next verify` prints the topmost
`next: verify` / `status: ready` row.

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
- Changes outside it → **still run**, but label the result **advisory** and name the unrelated paths.
  **Do not stash, revert or check out to tidy** — destroying another session's work is far worse than an
  imprecise verdict.
- `in-progress` under a token **you did not mint in this conversation** → another session's. Say whose
  it seems to be and stop; Step 1's refusal normally prevents this, so reaching here means the field
  and the claim disagree.

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

Walk each AC and record how you verified it — which test, which behaviour, which screenshot. "Looks right"
is not a verification, and an AC you cannot verify is a **fail**.

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

For each filled NFR row, confirm the requirement holds and **load the cited convention file** — the row
says what this ticket must satisfy, the convention says what the rule is, and you check against the
rule.

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
verdict file exists or is needed.

**On green, close it with `./close`** — one step, and the supported path:

```bash
.claude/backlog/close 0007 8a04        # lock → re-read → tick ACs → move row → reconcile → commit → unlock
```

It does the whole sequence below under the lock and **commits it**, which is the step a session under
load forgets (`CONCURRENCY.md`, *The three scripts*). It refuses rather than guessing on three grounds:
a table shape it cannot read, a row not at `next: verify`, and a token that is not the one holding the
claim — you pass the token because ownership is memory and no script can check memory.

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
   a closed ticket; and a dependent anything holds is reported, not written, where *held* means a
   non-empty `claimed_by:` in the item, `CONCURRENCY.md`'s *Claim tokens* being where ownership lives.
   Skip anything whose own `status:` does not read `blocked`. Then run `./next --drift` and expect
   zero **for the rows you reconciled**, not for the file:
   drift an earlier close left behind names no ticket you hold, so reconciling it is forbidden and a
   non-zero exit here can be entirely someone else's. Diff the report before and after your reconcile,
   and report what was already there rather than owning it.

   **This reverses the previous rule that a close touches "nothing else".** That rule was narrower
   writes, which `CONCURRENCY.md` is right to want — but it left the only event that can clear a
   `blocked` row unable to clear it, and a closed ticket once left four rows unavailable for a whole
   session with nothing blocking them. Narrow writes lost to a queue that lies. You still hold the
   lock, and you write nothing that is held — leave a claimed dependent alone and say so in your
   report; its own session will see the drift.
4. **Commit by pathspec**, **then** release the lock. The order matters: the lock guards the commit,
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

If Step 2 found unrelated changes, mark it **advisory** and name what made it so. **An advisory PASS does
not close the ticket** — leave the row at `next: verify, status: ready`, release the claim, and say what
has to be clean.

A partial pass is a FAIL with a list. Never soften a red or report a skipped check as though it ran. State
what Step 5 did — closed, or sent back to `develop` or `queue` — and name the commit. Unrelated problems
go to `queue` as new tickets.
