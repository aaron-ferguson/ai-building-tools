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

Verify that a change actually satisfies what was promised. Distinct from `/code-review`, which
hunts for defects in a diff — this one checks a change against a **written contract** and
returns pass or fail.

**`verify` closes the ticket.** On green it ticks the ACs, sets the ticket done, moves the row to
`DONE.md` and releases its claim. `develop` stops at `next: verify` and closes nothing, because a
verdict that has to travel from the session that produced it to the session that acts on it has
nowhere to travel once each skill runs alone.

**What keeps two sessions off one ticket is the `next` field, not a read-only rule.** This skill
acts only on tickets whose `next` is `verify` — and nothing is developing those, because `develop`
released the claim before setting the field. So **refuse anything addressed to another stage**
(Step 1) rather than checking it anyway. See `references/CONCURRENCY.md` at the plugin root
(`../../references/CONCURRENCY.md` from this file), *A stage writes only the ticket it holds*, and
read it before touching any backlog file.

A unit of work you notice along the way goes to `queue` as a row, not into this ticket. A finding
you cannot yet place goes in `.claude/backlog/FINDINGS.md` (Step 6).

**This skill states no standards of its own.** What counts as secure, private, accessible, or
adequately tested is defined by the project's conventions and cited here, never restated.
Resolve them per `references/CONVENTIONS.md`.

---

## Step 1 — Get the contract, refuse what is not yours, then claim it

With an item ID: read `.claude/backlog/items/<id>-*.md` and take the **Acceptance criteria**,
**Non-functional requirements**, and **QA plan** sections. With no argument, take the topmost row
whose `next` is `verify` and whose `status` is `ready` — `./next verify` prints it.

**Refuse a ticket whose `next` is not `verify`, and name what you found instead.** A `develop` row
has not been built yet, so there is nothing to check; a `design` row has no acceptance criteria to
check against, so a verdict on it would be issued against a contract you invented; a `queue` row
is not specified enough for any stage. Say which of those it is and stop. This refusal is what
keeps two stages off one ticket now that no read-only rule does — checking it anyway means QA-ing
work another session is mid-way through, where a red means "unfinished" and looks like "broken".

Without an ID and without a backlog item at all: verify against whatever the user stated as the
goal — and say explicitly that you are verifying an unwritten contract, which is weaker. Nothing
is closed on that path; there is no row to close.

**Then claim the row, because this stage writes.** `./claim <id>` locks, edits the row to
`in-progress`, writes the token into the item's frontmatter, commits and unlocks as one step. Do
it by hand only if the project has no script, and **commit the row inside the lock** — an
uncommitted claim is visible to nobody but you (`CONCURRENCY.md`, *A claim must be durable the
moment it is made*).

Read `.claude/backlog/config.yml` for the project's real commands, and resolve the conventions
per `references/CONVENTIONS.md`. If none resolve, stop — a verdict issued against no standard
is indistinguishable from one issued against a real one, and that is the failure mode this
whole design exists to prevent.

---

## Step 2 — Check whose tree you are testing, then run the declared level

**Before running anything**, see what else is in flight:

```bash
git status --porcelain
```

A second window developing another item means the suite you are about to run covers a file set
that never existed as a coherent state. Its red may belong to work half-written, and its green
may be luck.

- Changes confined to the item under test → proceed normally.
- Changes outside it → **still run**, but say so in the verdict and label the result
  **advisory**: name the unrelated paths, and state that a confident PASS needs a clean tree.
  Do not stash, revert, or check out anything to tidy it — that is another session's work and
  destroying it is far worse than an imprecise verdict.
- The item under test is `in-progress` under a claim token **you did not mint in this
  conversation** → it is another session's. Do not check it; say whose it appears to be and stop.
  Step 1's refusal normally prevents this, so reaching it means the field and the claim disagree.

The item's `qa_level` was set at queue time. Run **that** level and everything below it —
levels are cumulative, sitting on the pyramid defined in `testing-conventions.md`.

| Level | Run |
|---|---|
| `verify` | the scripted assertion named in the item's QA plan, plus lint/typecheck if the project has them. The assertion must be executed and its output shown — a `verify` item read-and-eyeballed is not verified |
| `unit` | lint, typecheck, unit suite scoped to the change |
| `integration` | the above, plus the integration suite across the seams this change touches |
| `e2e` | the above, plus the specific journeys named in the item's QA plan |

**If the declared level has no command in `config.yml`, stop and say so.** Do not substitute a
lower level and call it verified — that is exactly the silent downgrade the per-item declaration
exists to prevent.

**A configured level with no tests yet is an empty set, not a red.** Because levels are
cumulative, an `integration` item on a young project runs a unit command over a directory that
holds nothing — and most runners exit non-zero on "no test files found", which reads as a
failing level when nothing failed. Check whether the run collected zero tests before calling it,
and report it as `no tests at this level` rather than a FAIL. The genuine red to keep is the
opposite case: a level that *had* tests and now collects none, which means they moved or stopped
matching the pattern.

Scope to the change; full-suite runs are for when the user asks. Keep output lean, and raise
verbosity only while investigating a failure.

**For e2e:** drive the real entry point against a local or staging target with synthetic data —
never production, never production credentials. Stop every server, container, or browser you
started, in this same turn. If Playwright is the project's runner, use it.

---

## Step 3 — Check the acceptance criteria literally

Walk each AC one at a time and record how you verified it — which test, which observed
behaviour, which screenshot. "Looks right" is not a verification. An AC you cannot verify is a
**fail**, not a pass with a caveat.

**A green check is only evidence if it could have been red, and confirming that is your job
rather than the implementer's.** They have already convinced themselves; the whole reason this
pass is separate is to distrust that. So for each AC whose verdict rests on an automated check,
break the behaviour the check exists to catch and confirm the check goes red — then restore it,
**by the path you mutated and no other** (`git checkout -- <that path>`). A bare
`git checkout -- .` would destroy the other window's uncommitted work in the tree Step 2 just
warned you about.
The failure mode is not a check wired to nothing, which is obvious; it is a check that runs,
asserts, and measures something *adjacent* to the defect: a UI drag that ends off the element
under test so the click never lands there, a value chosen where the distortion is symmetrical, a
synthetic gesture whose step size clears the very threshold it is testing. Each of those passes
against deliberately broken code.

Budget this for the checks you would cite when closing the item, not for the whole suite. **If a
check cannot be made to fail, the AC is unverified** — that is a `FAIL` under the rule above, not
a pass with a note.

**And a check can only see what its runner can represent.** Before accepting one, ask what the
runner actually simulates: a headless browser has no collapsing chrome, no real compositor and no
finger; a fake clock has no drift. If the defect lives in what the runner *substitutes*, no
result from it counts in either direction — say so, and fall back to the level that can observe
it, even when that level is a human on a device. **A higher test level is not automatically a
stronger one**; it is stronger only if its runner can observe the defect, and promoting an item
to a level that structurally cannot see the bug buys a green light that means nothing.

---

## Step 4 — Check the NFRs that the item declared

**First, ask what the change made newly *reachable*.** The ACs enumerate what the change must
do; nothing in them can cover a path the change **creates**, because there was nothing to write
an AC about when the item was queued. Any change to routing, visibility, permissions, or the
conditions under which a screen or endpoint is offered adds states that were previously
unreachable — and a destructive or privileged action sitting on one of those is now available
by a route nobody reviewed. Walk the newly reachable states and check each against the rules the
project already holds elsewhere. A change that made a menu reachable while a saved document
existed put an unconfirmed discard one tap away, and every written AC passed: the defect was
created by the change rather than verified against it, so only this question finds it.

For each filled row in the item's NFR table, confirm the stated requirement holds. **Load the
cited convention file** — the row states what this item must satisfy, the convention states
what the rule is, and you are checking against the rule. Do not check against the row alone
unless it is self-evidently complete.

Then run the always-on pass regardless of what the table says. **Read `CONVENTIONS_CORE.md` for
the current always-on rules and check the diff against them** — they are non-negotiable, they
apply to every change, and an item does not get a row for them precisely because they are never
optional. This skill deliberately does not list them: a copy here would drift from the source
and you would end up checking the stale version.

The privacy pass in `data-privacy-conventions.md` runs on any change that adds or moves a log
field, an analytics event, or an egress destination, whether or not the item has a Privacy row.

If the change touches auth, credentials, or data visibility and the item has no Security row,
that's a gap in the item — flag it and run the `security-conventions.md` pass anyway. Same for
a UI change with no Accessibility row and `accessibility-conventions.md`. A missing row is an
oversight at queue time, not permission to skip the check.

---

## Step 5 — Act on the verdict

This is the stage that closes. Do it here, in the session that produced the verdict — there is no
window between testing and closing for a green to go stale in, which is why no durable verdict
file exists and none is needed.

**On green**, under the lock, and committed before you release it:

1. Tick the ACs in the item file and set `status: done` with the date. Clear `touches:` — a closed
   ticket must not keep reserving files.
2. Re-read `QUEUE.md` — another window has had the whole QA run to insert rows — then delete your
   row with a single `Edit` and append it to `DONE.md`, newest first. Nothing else in `QUEUE.md` is
   touched; there is no position column to renumber.
3. Release the claim: clear `claimed_by:` and `claimed_at:`.
4. **Commit by pathspec** — `git commit -m "Close <id>: …" -- <queue> <done> <item>` — **then**
   `rm -rf .claude/backlog/.lock`. The order matters: the lock guards the commit, not just the
   edit, because the commit takes `QUEUE.md` whole and an unlocked close can interleave with
   another window's claim (`CONCURRENCY.md`, *Lock every write to `QUEUE.md`*).
5. Record this session's share of the cost if `cost_tracking:` is configured, and mirror the close
   to the tracker if one is (`references/TRACKER.md`) — outside the lock, since a network call must
   never be made while holding it. Tracker failure is logged in the item's notes, never a blocker.

**On red**, the failure reason goes in the item's *Notes & decisions* **before** you touch any
field: what failed, the actual output, and which AC it belongs to. Then set `next: develop,
status: ready` and release the claim, under the lock, committed. Flipping the field without the
reason means the next `develop` session re-derives the failure from nothing, which is the loss
this whole handoff exists to prevent — and it is the half most easily skipped, because the red is
still fresh in a conversation that is about to end.

**On a stale contract** — the ACs no longer describe reality, so neither pass nor fail is honest —
write why in the notes and set `next: queue, status: ready`. Do not re-specify the ticket yourself.

**Do not push** unless the project's `CLAUDE.md` or `git-conventions.md` says a close should push,
or the user asks. Closing a ticket is not authority to publish it.

---

## Step 6 — Park what surprised you

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

## Step 7 — Verdict

State **PASS** or **FAIL** plainly, then the evidence table: each AC and NFR row, how it was
checked, and the result. Include the actual failure output for anything red.

If Step 2 found unrelated changes in the tree, mark the verdict **PASS (advisory)** or
**FAIL (advisory)** and name what made it so. **An advisory PASS does not close the ticket** — it
is a request to re-run against a clean tree, so leave the row at `next: verify, status: ready`,
release the claim, and say what has to be clean.

A partial pass is a FAIL with a list. Never soften a red result, and never report a check you
skipped as though it ran. State plainly what Step 5 did — closed, sent back to `develop`, or sent
back to `queue` — and name the commit.

If QA passes but you noticed unrelated problems along the way, don't fix them here — hand them
to `queue` as new items.
