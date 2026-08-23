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

Turn what a session learned into edits in the places that get read again.

**The finding is not the deliverable — the edit is.** A lesson that reaches only the final report
dies with the conversation, and it dies expensively: the next session re-derives it with none of
the context that produced it. This skill exists because knowing *where* each kind of lesson
belongs, and what makes an edit durable, is itself a thing to be remembered.

**This skill states no standards of its own.** What is worth documenting, where it belongs, and
what must never be documented are defined by `documentation-conventions.md` and cited here, never
restated. Resolve the conventions per `references/CONVENTIONS.md`, **read that file before Step 1**,
and stop if none resolve — a retro with no standard to write against produces opinions, not rules.

**One skill per session.** Run this skill in its own conversation and let the backlog carry the
handoff — the ticket's `next` field and `FINDINGS.md`, never a conversation. A measured
end-to-end run on **2026-08-22** spent **85% of $15.11 on context handling** at an average of
**191,752 tokens per turn**; isolated, the same work models at **~$5.09**. **No standard is
relaxed by this** — the rigour that caught a zip-bomb vulnerability every acceptance criterion
passed over is in the 15% that was output.

**Its input is `FINDINGS.md` across many sessions, not one session's memory.** Each skill parks
what surprised it as it happens, so by the time this runs the observations are already on disk —
which is the only thing that survives a session boundary. There is no live session left to review:
the sessions that produced these findings have already ended, and anything they did not park is
gone.

**It runs on a cadence, and it is not a lifecycle stage.** `retro` is not a `next` value, no skill
invokes it, and it is not part of the per-ticket loop. Run it when **`FINDINGS.md` holds about
eight entries or more**, or **weekly** if the buffer fills slower than that — whichever comes
first. Running after every ticket would mostly find nothing, and the cheapest nothing is the one
not run: measured on 2026-08-22, `retro` cost **$5.50** — 36% of the run — at the lowest output per
turn of any phase, because it ran last where context was largest.

**The system learns *more* under this shape, not less.** Before, a lesson survived only if a retro
happened to run after the session that noticed it; two of four findings in that run existed only in
conversation and would have been lost. Now every session contributes whether a retro ever runs or
not.

**It reviews what sessions recorded, not the decisions taken in them.** A choice the user already
made is not a finding. Re-opening settled calls is how a retro becomes a second argument.

---

## What this owns, and what it does not

The lifecycle skills build one ticket and close it. This owns everything about *learning*, and
narrows to the part that genuinely needs the cross-session view: **recognising that several
sessions hit the same thing**, choosing destinations, and making the edits. A single session's
observation is a parked line; the same line from three sessions is a rule.

| | the lifecycle skills | `/retro` |
|---|---|---|
| Question | did this ticket get built, checked and closed? | what did many sessions teach, and where does it go? |
| Scope | one ticket, one session | the buffer, across every session that filled it |
| Trigger | the ticket's `next` field | a cadence — the buffer's size, or a week |
| Output | working code, a closed row | edits to skills, conventions, project docs, and new rows |

**This skill takes the lessons; `queue` takes the units of work.** Two sweepers, one file, and
neither waits for the other — an entry that is both is taken by both. Leave the work entries where
they are; `queue`'s sweep specifies and ranks them, which is a job this skill would do badly and in
the wrong session.

**Most of the value is on disk before this runs.** `documentation-conventions.md` fires on
*discovery* — the mechanism gets written down in the same change as the code, while the file is
open. That is the cheap half and it does not need this skill. What reaches the buffer is the half
with no file to live in: the deferrals, the reds proved not to be theirs, the skill that misled
someone, the row nobody has written.

**Match the effort to the buffer.** A buffer of three stale lines deserves one pass and a one-line
report. A buffer showing the same thing three times, from three sessions, earns the full treatment.
Reading a thin buffer in detail, to produce nothing, is itself the waste this skill is supposed to
catch.

---

## Step 1 — Read the buffer

`.claude/backlog/FINDINGS.md` is the input, and the only one. Sessions parked these as they hit
them, which is both cheaper and more reliable than reconstructing them afterwards — the context was
hot at the time, and a parked entry survives compaction, an interrupted session, and the gap between
one session and the next.

**Expire what has gone stale.** Anything older than about two weeks is dropped rather than
processed, with the reason stated. A finding nobody acted on in two weeks was not worth acting on,
and saying so plainly beats re-reading it forever. **If the file has grown far past the cadence
threshold, that is itself a finding** — retros are not running, or not emptying.

Then read across the entries rather than down them, because that is the view no single session had:

- **The same thing hit more than once.** Three sessions tripping on one template step is a rule;
  one session tripping on it is a line in a buffer. This is the finding a per-session review
  structurally cannot produce, and it is why the cadence exists.
- **What cost the most work for what it returned** — work built and thrown away, the same question
  asked twice, a file read whole to learn one fact. **The fix is nearly always upstream of the
  cost**: the cheap finding is "cache this", the real one is "we should not have built that yet".
  Say which, and route it — a habit belongs in the skill that governs the work, a one-off belongs
  nowhere.
- **Anything a tool, skill, or convention made harder than it needed to be** — including this one.
- **Anything re-derived that an earlier session already knew.** A documentation gap with a receipt.
- **Anything the entries show was *invalidated*.** A sentence elsewhere that this work made false is
  more dangerous than a missing one: a stale rule reads as current, gets followed, and gets the
  change reverted by someone who believes they are fixing a regression.

`documentation-conventions.md` defines *when* a discovery must be written down, and its triggers are
the authority rather than this list. It also names what must **not** be documented, which is what
stops a retro turning findings into clutter.

Then, for each finding, ask the question that decides everything downstream:

> **What would have had to be written down, and where, for that session to have gone differently?**

A finding that cannot answer that is an observation. Say so and drop it rather than finding it a
home — a rule nobody would have read is rent with no return.

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

**Grep the destination before writing anything.** One command, and it is the difference between
sharpening a rule and duplicating it. Where something related exists, **sharpen it in place**: an
adjacent second bullet is how a file grows without getting better.

Three traps, each of which has cost a real session:

- **You may be running an older copy of a skill than the source.** A session resolves its skills
  once, at start, from the installed copy. The checkout can be several versions ahead, and the rule
  you are about to add may already be there — along with the fix for the problem you just hit.
  Compare before you write.
- **A rule that exists but did not fire is not a missing rule.** If the guidance was there and was
  not followed, the finding is about *reach* — wrong file, wrong step, buried under something
  louder — or it is simply that someone erred. Say which. A second copy of an ignored rule weakens
  both.
- **Check what was *invalidated*, not just what is missing.** If a decision was reversed, grep the
  conventions, the project's docs and any guard test's prose for the rule it overturned —
  **including any note saying not to do the thing that was just done** — and correct it where it
  lives. Say it was reversed and on whose call, so the next reader can tell a decision from an
  erosion.

### Where it goes

**CLAUDE.md is almost never the right answer, and reaching for it first is the most common way a
retro makes a project worse.** It loads into *every* session on that project — including every
session doing something unrelated — so each line is paid for repeatedly, forever, by work it
cannot help. `documentation-conventions.md` sets the bar: durable facts only, never current
state, with the test that *if it stops being true without anyone editing CLAUDE.md, it does not
belong there*. Most findings fail that. A finding has to be something a session would be **wrong
to act without** before it goes here — and even then, check whether a comment or a test says it
better.

Work down this ladder and stop at the first rung that fits:

1. **A comment in the file it governs.** A mechanical, project-specific fact — a port, a flag, the
   reason behind a constant — belongs where someone changing that thing will read it. This is
   almost always right for "we hit a surprising behaviour in X", and it costs nothing globally.
2. **A test that fails when the rule is broken.** Strictly better than prose wherever it is
   possible, because it cannot be read past.
3. **The skill that was used.** If the workflow itself misled — a step in the wrong order, a
   missing check, a guarantee that did not hold — fix the skill. This is the destination most
   often missed, because the skill is not part of the project being worked on.
4. **The convention that was cited.** A lesson that would hold on someone else's codebase belongs
   here, in the satellite file that governs it — loaded only when that kind of work is happening.
5. **An always-loaded file** — the project's `CLAUDE.md`, or the conventions core. The rung to
   argue yourself *out* of. If it truly belongs here, keeping the file's total size flat is part
   of the change: the conventions core says that a file visibly grown by one session's lessons is
   a signal to compress, not to keep.

Two more calls, both of which change the destination:

- **Is it a rule, or a unit of work?** A rule goes somewhere on the ladder. Work goes to `queue`,
  properly specified — not a bullet in a report and not a `TODO` in the code. "The flaky spec
  should be fixed" is work; "a fixture that encodes a domain assumption goes stale silently" is a
  rule. Many findings are both, and then they are both.
- **Is it general, or is it this project's?** A lesson that turns on this project's own choices
  belongs to the project. One that would hold anywhere belongs to the conventions or the skill.
  Generalising early puts a rule in front of sessions it cannot help; generalising late makes
  every project rediscover it.

**Workflow versus principle decides between rungs 3 and 4**, and `references/CONVENTIONS.md` gives
the test: *would this still be true if the backlog did not exist?* Yes → a convention. No → a
skill.

---

## Step 4 — Write it, and empty what you processed

The findings are agreed and the destinations checked, so this step is mechanical. Match each file's
existing voice and structure; a rule that reads as a foreign insertion is a rule that gets skipped.
State the failure the rule prevents, not the reasoning that convinced you of it.

If a destination check changed your mind about *where* something goes, say so before writing — that
is the disagreement the user is most likely to have, and Step 3 is where the evidence for it turned
up.

**Then remove from `FINDINGS.md` only the entries you processed**, and commit in the same turn, by
pathspec. Leave the units of work: `queue`'s sweep specifies and ranks those, and deleting one here
loses it silently. Leaving an entry you *did* process is how the next retro pays to read it again.

---

## Step 5 — Make it durable

An edit that is not committed is a draft, and a skill edit that is not released is invisible to
the sessions it was written for.

- **Commit by pathspec**, in the same turn as the edit, per the project's git conventions and
  `references/CONCURRENCY.md`. A retro often edits several repos at once — the project, the
  conventions, the tools — so commit each in its own repo with its own message rather than
  letting one sweep another's staged work.
- **Push per each repo's own rules.** A project may treat a push as a release; the conventions and
  tools repos are the source of truth for other machines, so an unpushed edit there is lost at the
  next install.
- **A skill edit has a release chain, and every step is silent when skipped**: push, bump the
  plugin version, update the install, then **restart**. Skills resolve at session start, so the
  session that wrote the change is the last one to receive it. Say this in the report rather than
  letting the user assume the change is live.

  **Report it in one line, not a paragraph.** This fires on every retro that touches a skill, which
  is most of them, so it is a standing cost rather than news — `Skills changed — update the plugin
  and restart.` is the whole message. It is also a consequence of an edit, never a *finding*: it
  does not belong in `FINDINGS.md`, where it would sit un-triageable and make a healthy buffer look
  like a neglected one.

Verify the installed copy matches the source afterwards. A silent no-op here is exactly the trap
Step 2 warns about, one layer further in.

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

**This step applies to `retro` too, and it is not a contradiction.** This skill empties the buffer;
it is also a session that can be surprised by its own tooling. Park below what you just cleared,
so the next retro reads it rather than your report.

---

## Step 7 — Report

Per finding: where it landed, and in one clause, why there. Then the three things the user cannot
see for themselves:

- What was proposed and deliberately **not** written, with the reason.
- Anything left uncommitted, unpushed, or unreleased.
- **Whether a restart is required**, in one line — see Step 5. No explanation unless asked.

If nothing surfaced, say that plainly.
