---
name: retro
description: >
  Review the findings many sessions parked in FINDINGS.md and land the lessons where they will be
  read again: the skills that were used, the conventions that were cited, the project's own docs,
  or the backlog. Use when the user says "retro", "run a retro", "post-mortem", "session review",
  "what did we learn", "what could have gone better", or invokes /retro. Runs in its own session on
  a cadence, never as part of the per-ticket lifecycle — no other skill invokes it. Decides *where*
  a lesson belongs rather than defaulting to CLAUDE.md, and carries a change through to durable —
  committed, and for a skill, released.
---

# /retro

Turn what many sessions learned into edits in the places that get read again.

**One skill per session.** Run this skill in its own conversation; the backlog carries the handoff — the
ticket's `next` field and `FINDINGS.md`, never a conversation. Measured **2026-08-22**: **85% of USD 15.11
went on context handling** at **191,752 tokens per turn**, modelling to **~USD 5.09** isolated. **No standard
is relaxed** — the rigour is all in the 15% that was output.

**The finding is not the deliverable — the edit is.** A lesson that reaches only a report dies with the
conversation, and dies expensively: the next session re-derives it with none of the context that produced
it. Knowing *where* each kind of lesson belongs, and what makes an edit durable, is itself a thing to be
remembered.

| | the lifecycle skills | `/retro` |
|---|---|---|
| Question | did this ticket get built, checked and closed? | what did many sessions teach, and where does it go? |
| Scope | one ticket, one session | the buffer, across every session that filled it |
| Trigger | the ticket's `next` field | a cadence — the buffer's size, or a week |
| Output | working code, a closed row | edits to skills, conventions, project docs, and new rows |

**Its input is `FINDINGS.md` across many sessions, not one session's memory**, and there is no live session
left to review. It narrows to what genuinely needs that cross-session view: **recognising several sessions
hit the same thing**, choosing destinations, and making the edits. One session's observation is a parked
line; the same line from three sessions is a rule. **The system learns *more* under this shape, not less**
— before, a lesson survived only if a retro happened to run after the session that noticed it, and two of
four findings in the measured run existed only in conversation.

**It runs on a cadence, and it is not a lifecycle stage.** `retro` is not a `next` value, no skill invokes
it, and it is not part of the per-ticket loop. Run it when **`FINDINGS.md` holds
`findings_threshold` entries or more** — the key in the backlog's `config.yml`, defaulted to about eight
and read by `./next --findings`, so the number lives in one place rather than here as well — or
**weekly** if the buffer fills slower, whichever comes first. Only the count is mechanical; "or weekly"
has no reading and stays your judgement. Running after
every ticket would mostly find nothing, and the cheapest nothing is the one not run: measured, `retro` cost
**USD 5.50**, 36% of the run, at the lowest output per turn of any phase, because it ran last where context
was largest.

**This skill takes the lessons; `queue` takes the units of work.** Two sweepers, one file, neither waiting
for the other — an entry that is both is taken by both. Leave the work entries where they are.

**Most of the value is on disk before this runs.** `documentation-conventions.md` fires on *discovery* —
the mechanism is written down in the same change as the code. What reaches the buffer is the half with no
file to live in: the deferrals, the reds proved not to be theirs, the skill that misled someone, the row
nobody has written. **Match the effort to it**: three stale lines deserve one pass and a one-line report,
the same thing three times earns the full treatment.

**This skill states no standards of its own.** What is worth documenting, where it belongs, and what must
never be documented are defined by `documentation-conventions.md` and cited, never restated. Resolve the
conventions per `references/CONVENTIONS.md` at the plugin root **before Step 1**, and stop if none resolve. **It reviews what
sessions recorded, not the decisions taken in them** — a choice the user already made is not a finding.

---

## Step 1 — Read the buffer

`.claude/backlog/FINDINGS.md` is the input. Sessions parked these as they hit them,
which is cheaper and more reliable than reconstructing them afterwards — the context was hot at the time,
and a parked entry survives compaction, an interrupted session, and the gap between sessions.

**Where that path resolves, in order.** A bare relative path reads nothing at all when the session
stands in a workspace root rather than a project root — which is where these sessions start, and is
what made the 2026-09-07 pass sweep four sibling backlogs it was never told to touch.

1. **The git repository root** containing the working directory — its `.claude/backlog/FINDINGS.md`.
2. **The nearest `.claude/backlog/` at or above the working directory**, for a backlog that does not
   sit at its own repo root.
3. **Nothing resolved → stop**, and report every directory searched. That is
   `references/CONVENTIONS.md` rung 3's refusal, cited rather than restated so the two cannot drift.

**The order walks upward only, and it never descends.** A buffer is resolved, never discovered — do
not search the filesystem for a backlog that looks right (`CONVENTIONS.md` rung 3, the same
prohibition). Exactly one buffer comes out of the order, so a sibling project's buffer under the same
workspace is unreachable by construction rather than by a rule anyone has to remember.

**The privacy boundary sits here, at the order, and not in a distant section.** Buffers under one
workspace do not share a classification, and holding a company-tracked project's findings and a
public repo's in one context is one step from writing either into the other. **A backlog carrying no
`routing:` block is treated as company-tracked**, never as `company: none` — absence is the common
case, so reading it as "no company" fails open on exactly the buffers this clause exists to catch.
Unknown classification takes the stricter handling, never the looser (`data-privacy-conventions.md`).

**Check the resolved backlog's own `QUEUE.md` for a retirement banner before reading its buffer**, and
stop if there is one — a retired backlog's entries describe work nobody will do. This detects
retirement in the resolved backlog and in no other, which is acceptable only because the order above
never reaches another: retirement carries no signal a backlog is obliged to publish, so detecting it
across arbitrary backlogs would fail open.

**Running in a project that consumes these tools, read the tools repo's buffer as well** — parks
routed there by subject are invisible in the local one, so a retro reading only locally would never
see them again. That repo is *resolved*, never discovered — see `references/CONVENTIONS.md`,
*Routing a finding to the repo it is about*. Sweep only what a rule names; a buffer that is merely
nearby is not an input.

**A second buffer is read only when a rule names it**, never because it was nearby — the paragraph
above is the one such rule, and it *resolves* that repo rather than finding it. The single-buffer
order is not a ban on it.

**Two modes, and which you are in decides what you reach for before reading a single entry.** An
**end-of-run retro** closes a supervised session: small buffer, one session, context still hot, so
*landed* and *filed* are cheap and almost always right. A **cadence retro** fires on the threshold or
the week: cold and cross-session, most entries already have rows, so *absorbed* and *deferred* dominate.

**Expire what has gone stale.** Anything older than about two weeks is dropped rather than processed, with
the reason stated. **If the file has grown far past the cadence threshold, that is itself a finding** —
retros are not running, or not emptying.

**And far past the threshold changes how this skill runs, not only what it reports.** A buffer at nine
times the threshold cannot be drained in one pass, and forcing it is the wrong trade: effectiveness
first, across as many passes as it takes. Work in ranked slices — **read fewer entries and finish
each**, rather than reading all and marking most. `FINDINGS.md` is **transit, not residence**: an entry
you never reached waits untouched; one you *read* leaves in that pass, per Step 4. What must never
happen is a later pass re-deriving triage an earlier one already did.

**A deferral records what was established, never what was guessed.** It hands the next pass the
expensive judgment — lesson, unit of work, or both — so that pass buys only the writing. It must not
carry an unverified destination: Step 3's grep fires only for findings that survive the gate, so a
deferral's destination is the one choice nothing checks, and it then reads exactly like a landed
finding. Measured: three entries deferred to an item scoped to a different question entirely, which the
next retro re-derived at full price before noticing the pointer resolved to nothing. Name a destination
you have opened, or write that none exists yet — a wrong one is worse than none.

**An entry may already carry a marker from the other sweeper** — *"filed as item 0108; kept for the
lesson, do not re-file"*. That is `queue` handing you the lesson half of an entry whose work half is
done: take the lesson and remove the entry, and do not re-open the work.

Then read *across* the entries rather than down them, because that is the view no single session had:

- **The same thing hit more than once.** Three sessions tripping on one template step is a rule; one
  session tripping on it is a line in a buffer. This is what a per-session review structurally cannot
  produce, and it is why the cadence exists.
- **What cost the most work for what it returned** — work built and thrown away, the same question asked
  twice, a file read whole to learn one fact. **The fix is nearly always upstream of the cost**: the cheap
  finding is "cache this", the real one is "we should not have built that yet". Say which, and route it.
- **Anything a tool, skill, or convention made harder than it needed to be** — including this one.
- **Anything re-derived that an earlier session already knew.** A documentation gap with a receipt.
- **Anything the entries show was *invalidated*.** A sentence elsewhere that this work made false is more
  dangerous than a missing one: a stale rule reads as current, gets followed, and gets the change reverted
  by someone who believes they are fixing a regression.

`documentation-conventions.md` defines *when* a discovery must be written down, and its triggers are the
authority rather than this list. It also names what must **not** be documented, which is what stops a
retro turning findings into clutter.

Then, for each finding, ask the question that decides everything downstream:

> **What would have had to be written down, and where, for that session to have gone differently?**

A finding that cannot answer that is an observation. Drop it rather than finding it a home — a rule nobody
would have read is rent with no return.

---

## Step 2 — Propose, then wait

**The gate comes before the destination work, not after.** Present the findings you propose to act
on, each with a one-line reason and a *provisional* destination — and what you propose to drop, with
its reason. Then wait.

This order is deliberate: checking a destination properly means greps, reading the file that would
change, and comparing against the installed copy of a skill. All of that is wasted on a finding the
user was never going to accept, and a rejected finding should cost nothing to have proposed. A menu
of options hands the judgement back to the user, which is the opposite of the point — recommend.

**A retro is allowed to find nothing, and saying so is a complete result.** If the buffer held only
stale or dropped entries, the honest report is one line saying you read it and there was nothing
worth writing. **Do not manufacture a finding to justify the pass.** An invented lesson costs more
than a skipped one: it goes into a file every later session pays to read, and it dilutes the rules
that were earned.

---

## Step 3 — Check the destination, then choose it

Only for the findings that survived the gate.

**Grep the destination before writing anything.** One command, and the difference between sharpening a
rule and duplicating it. Where something related exists, **sharpen it in place**: an adjacent second
bullet is how a file grows without getting better.

**Fetch every repo it will edit before the first grep, and stop if you are behind.** A check
against a stale tree is not evidence — it reads as one, which is what makes it expensive. On
2026-09-01 a pass ran every grep in this step 47 commits behind `origin/main`, re-ran all of them
after the pull, and had by then written a commit somebody else had already pushed four days
earlier; it surfaced as a rebase conflict whose resolution meant choosing between two of the
author's own commits. So `git fetch` then `git status -sb`, per repo, read-only.
**Behind the remote stops the pass**, and **the pull is the user's call** because that choice is
theirs (`git-conventions.md`). The repos are the ones already resolved — the conventions ladder and
`tools.path` — and **never the plugin install** (`references/CONVENTIONS.md`, *Routing a finding to
the repo it is about*): the marketplace clone beside it reads as a working checkout and reports a
stale divergence in the direction that looks safe.

Three traps, each of which has cost a real session:

- **You may be running an older copy of a skill than the source.** A session resolves its skills once, at
  start, from the installed copy. The checkout can be several versions ahead, and the rule you are about
  to add may already be there — along with the fix for the problem you just hit. Compare first.
- **A rule that exists but did not fire is not a missing rule.** If the guidance was there and was not
  followed, the finding is about *reach* — wrong file, wrong step, buried under something louder — or
  someone simply erred. Say which; a second copy of an ignored rule weakens both.
- **Check what was *invalidated*, not just what is missing.** If a decision was reversed, grep the
  conventions, the project's docs and any guard test's prose for the rule it overturned — **including any
  note saying not to do the thing that was just done** — and correct it where it lives. Say it was
  reversed and on whose call, so the next reader can tell a decision from an erosion.

### Where it goes

**CLAUDE.md is almost never the right answer, and reaching for it first is the most common way a retro
makes a project worse.** It loads into *every* session on that project, including every session doing
something unrelated, so each line is paid for repeatedly and forever by work it cannot help.
`documentation-conventions.md` sets the bar: durable facts only, never current state, with the test that
*if it stops being true without anyone editing CLAUDE.md, it does not belong there*. Most findings fail
it. A finding has to be something a session would be **wrong to act without** before it goes here.

Work down this ladder and stop at the first rung that fits:

1. **A comment in the file it governs.** A mechanical, project-specific fact — a port, a flag, the reason
   behind a constant — belongs where someone changing that thing reads it, and costs nothing globally.
2. **A test that fails when the rule is broken.** Strictly better than prose wherever possible, because it
   cannot be read past.
3. **The skill that was used.** If the workflow misled — a step in the wrong order, a missing check, a
   guarantee that did not hold — fix the skill. Most often missed, because the skill is not part of the
   project being worked on.
4. **The convention that was cited.** A lesson that would hold on someone else's codebase, in the
   satellite file that governs it — loaded only when that kind of work is happening.
5. **An always-loaded file** — the project's `CLAUDE.md`, or the conventions core. The rung to argue
   yourself *out* of; if it truly belongs here, keeping the file's total size flat is part of the change.

Two more calls change the destination. **Rule, or unit of work?** A rule goes on the ladder; work goes to
`queue`, properly specified — "the flaky spec should be fixed" is work, "a fixture encoding a domain
assumption goes stale silently" is a rule, and many are both. **General, or this project's?** A lesson
turning on this project's own choices belongs to the project: generalising early puts a rule in front of
sessions it cannot help, generalising late makes every project rediscover it.

**Workflow versus principle decides between rungs 3 and 4**, and `references/CONVENTIONS.md` gives the
test: *would this still be true if the backlog did not exist?* Yes → a convention. No → a skill.

**A lesson belonging to an existing item goes into that item**, off the ladder — but only where its
`claimed_by:` is empty, per `references/CONCURRENCY.md` *A session with no ticket writes only what is
unheld*. Date-stamp what you append and name where it came from; the claiming session is the first
that may re-verify it, and the first that must. Where the target is **held**, you are blocked: leave
the entry in the buffer and say so in the report — never write that it has been filed.

---

## Step 4 — Write it, and empty what you processed

The findings are agreed and the destinations checked, so this is mechanical. Match each file's existing
voice and structure; a rule reading as a foreign insertion is a rule that gets skipped. State the failure
the rule prevents, not the reasoning that convinced you of it.

If a destination check changed your mind about *where* something goes, say so before writing — that is
the disagreement the user is most likely to have.

**Take the backlog lock for every write inside `.claude/backlog/`.** Draining `FINDINGS.md` and
appending to an item are both inside the boundary, and `retro` holds no claim token that would make its
writes visible otherwise. Read, write, commit and release in **one shell invocation** — a session gets a
fresh shell per tool call, so a `trap ... EXIT` releases the lock the moment that call returns and every
later call runs holding nothing, which reads exactly like a correct lock. See
`references/CONCURRENCY.md` *Lock every write to the backlog directory*, and `CONCURRENCY-INCIDENTS.md`
before writing one by hand.

**Every entry you read gets one of four dispositions — landed, absorbed, filed or dropped — and
`FINDINGS.md` is the home of none of them.** The buffer surfaces a lesson; it never keeps one.

- **Landed** — written into the file that governs it, this session. Report the path.
- **Absorbed** — an existing row already carries the whole lesson. Not a silent drop: the report
  **names the row and appends** one dated line to its *Notes & decisions*, so the session that claims
  it does not re-derive what you established.
- **Filed** — the lesson needs work that does not exist yet, so write the row now while it is fresh.
  **A pure unit of work is filed, not handed back**: you have paid to understand it and `queue` would
  pay again. Beyond what this pass can specify, defer it per Step 1 rather than leave it unmarked.
- **Dropped** — stale, or an observation that cannot answer Step 1's question. Record the reason.

**Land it now unless the change cannot be complete in this session** — a rule this project would
demand a new guard for, or anything touching code. Half-landing strands the row that specified the
other half and leaves it reading as stale.

**Then empty what you read**, and commit in the same turn, by pathspec:
**no entry survives the pass that read it**. Your own Step 6 parks are the next pass's input rather
than residue left by this one, which is why a healthy buffer is rarely empty and never stale.

---

## Step 5 — Make it durable

An edit that is not committed is a draft, and a skill edit that is not released is invisible to the
sessions it was written for.

- **Run the target repo's suite before the commit that carries the edit** — the `unit` command in
  that repo's `config.yml`. A repo with no configured command is said to have none, never skipped in
  silence. The session that changes a tool is the one least likely to learn it broke that tool, and
  the break is invisible until another session trips on it: one retro found a shell-quoting defect
  already committed in `close`, whose failure signature named nothing about quotes (0076).
- **A red is your edit's until proven otherwise.** This repo's suite commits inside the live repo, so
  running it over uncommitted edits produces failures that read as logic errors and are tree
  pollution; the worktree comparison `develop` Step 5 prescribes is what tells the two apart. Remove
  that worktree in the same turn (`testing-conventions.md`, *Stop what you started*).
- **A guard that rejects the edit is an editor, not a gate.** Relocate first, exempt second: a size
  or prose rejection is information about where the rule belongs, and what gets recorded is the
  relocation it forced, never an exemption.
- **Commit by pathspec**, in the same turn as the edit, per the project's git conventions and
  `references/CONCURRENCY.md` at the plugin root. A retro often edits several repos at once — the
  project, the conventions, the tools — so commit each in its own repo with its own message rather than
  letting one sweep another's staged work. **This skill holds no ticket, so its writes are invisible to
  every ownership check built on rows and claim tokens** — a concurrent `verify` sees a clean queue over
  a dirty tree. Commit promptly rather than accumulating, and name the paths you touched when reporting.
- **Push per each repo's own rules.** A project may treat a push as a release; the conventions and tools
  repos are the source of truth for other machines, so an unpushed edit there is lost at the next install.
- **A skill edit has a release chain — ask for the push, then run `tools/release --bump --yes`
  from the repo root.** It bumps the version, pushes, updates the install, and verifies the bytes
  match before reporting done. Run it rather than performing the steps by hand: `claude plugin
  update` reports success even when it extracts nothing, and `tools/release` is the only step that
  catches that (0084). Skills resolve at session start, so the session that wrote the change is the
  last to receive it. **Report it in one line, not a paragraph** — this fires on most retros, so it
  is a standing cost rather than news: `Skills changed — ran tools/release, restart required.` is
  the whole message. It is a consequence of an edit, never a *finding*: it does not belong in
  `FINDINGS.md`, where it would sit un-triageable and make a healthy buffer look neglected.
- **The push is the release, so the session asks the user before the invocation**, naming the
  branch and that other machines install from it (`git-conventions.md`). That ask is where the
  approval is evidenced; `--yes` carries an approval already granted and
  **never stands in for one** — never a default, and never supplied on the user's behalf.
- **Nobody to ask — an `orchestrate`-dispatched run — does not invoke the chain**, and reports
  every remaining step of it **outstanding on that run's checklist**; `orchestrate` Step 8 forbids
  the push outright, and the two must not contradict. Invoking it with nobody to answer is the one
  outcome to avoid: the run stops before writing anything, so nothing is released and nothing is
  half-released either.
- **A previous run may have left a bump committed and unpushed** — the signal is a `Bump the
  plugin version` commit in `git log origin/<branch>..HEAD`. Re-run the same invocation: the local
  version is already ahead of the installed one, so it **re-bumps nothing**, finds nothing to
  commit, and pushes what is there.
- **That chain begins with a fetch, and the version comes from it.** `tools/release` fetches first
  and derives the next version from the **remote's `plugin.json`**, reporting the observed remote
  version and the derived one — **never the local file**, which is how a bump read off the local
  version and incremented once **collided with a version already released** upstream (2026-09-01).
  A checkout behind the remote refuses before anything is pushed.

---

## Step 6 — Park what surprised you

Before reporting, park what surprised you in `.claude/backlog/FINDINGS.md` — one dated line, while the
context is still hot.

Triggers: **a template or skill step that had no correct answer for your case**, a configured command that
behaved unexpectedly, a scaffolding step you had to invent.

**An explicit "nothing surprised me" is a complete result** — never manufacture one, since an invented
entry is paid for by every later session. **Commit it in the same turn you write it, by pathspec**;
uncommitted it is one `git stash` from gone. Anything whose home is obvious goes there instead.

**Route it by subject, not by where you are standing** — a finding about a skill, a reference file, a
backlog script or a convention belongs in that repo's buffer, not this project's. The destinations, how
each is resolved, the marked-local fallback and the privacy bar on crossing into a public repo are in
`references/CONVENTIONS.md`, *Routing a finding to the repo it is about*.

**This step applies to `retro` too, and it is not a contradiction.** This skill empties the buffer;
it is also a session that can be surprised by its own tooling. Park below what you just cleared,
so the next retro reads it rather than your report.

---

## Step 7 — Report

What belongs on the screen and what belongs on disk is `references/REPORTING.md` at the plugin root.
Per finding, add the clause it cannot supply: **why that destination** — Step 3 chose it, and the
choice is the part of this stage's work that no file records.

Then the three things the user cannot see for themselves, and would not find on disk either:

- What was proposed and deliberately **not** written, with the reason.
- Anything left uncommitted, unpushed, or unreleased.
- **Whether a restart is required** — see Step 5. No explanation unless asked.

If nothing surfaced, say that plainly.

**End on the hand-off line, the very last thing printed:**

```
- — RETRO — next: <command>
```

Example: `- — RETRO — next: restart, then /queue 0107`
Example: `- — RETRO — next: nothing — buffer clear, 4 lessons landed`

The ID slot is a dash and a command stands in for a stage: this skill holds no row. **When Step 5 ran
`tools/release`, the restart belongs here** — nothing this session wrote reaches a session until it
happens, and it is the first thing a long report loses.
