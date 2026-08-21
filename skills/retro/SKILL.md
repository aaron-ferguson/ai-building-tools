---
name: retro
description: >
  Review the work a session just did — the items it closed and the session around them — and land
  the lessons where they will be read again: the skills that were used, the conventions that were
  cited, the project's own docs, or the backlog. Use when the user says "retro", "run a retro",
  "post-mortem", "session review", "what did we learn", "what could have gone better", or invokes
  /retro. Invoked by `develop` when an item closes, and worth running on its own after any long or
  painful session. Decides *where* a lesson belongs rather than defaulting to CLAUDE.md, and
  carries a change through to durable — committed, and for a skill, released.
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

**It reviews the session, not the decisions taken in it.** A choice the user already made is not
a finding. Re-opening settled calls is how a retro becomes a second argument.

---

## What this owns, and what it does not

`develop` builds one item and closes it. This runs after that — or standalone — and owns
everything about *learning*, so that neither skill does half a job:

| | `develop` | `/retro` |
|---|---|---|
| Question | did this item get built and verified? | what did this teach, and where does it go? |
| Scope | one item | the items closed, plus the session around them |
| Output | working code, a closed row | edits to skills, conventions, project docs, and new rows |

`queue` remains the only thing that writes a *new backlog item*. When a finding is a unit of work,
this skill hands it there rather than describing it in a report.

**Run it even when everything went well.** A session with no friction still produces findings —
the non-obvious thing that worked, the rule that held under pressure — and "nothing surfaced that
is not already written down" is a claim worth making explicitly, because it is what makes a
skipped retro visible.

---

## Step 1 — Gather the findings

Two passes. Do both; they surface different things.

**The items.** For each item closed or worked this session:

- **Anything ruled out of scope.** That was a decision to defer, not to drop.
- **Every red or skipped check left unfixed**, including ones proved pre-existing. "Not mine" is
  a statement about authorship, never about ownership.
- **Anything handed to another item.** That is a claim about that item's scope and costs one grep
  to check — an unverified hand-off is indistinguishable from dropping the finding, except that it
  also sounds resolved.
- **Anything the item predicted that reality contradicted** — a prerequisite that never landed, an
  assumption gone stale, a rank now wrong.
- **Anything fixed that another row owns.** The mirror of the hand-off, and easier to miss: say so
  on that row, or the queue keeps ranking work that no longer exists.

**The session.** These are the ones a per-item review structurally cannot reach:

- **What cost the most time**, whether or not it produced anything. Rank by cost, not by interest.
- **Anything you got wrong and corrected mid-session.** The correction is the finding.
- **Anything the user had to correct you on.** They paid attention so a future session would not
  have to — the highest-value input available, and the one a self-assessment omits by nature.
- **A rule you followed that was incomplete or misleading.** Not only missing rules: a rule that
  is right about its own case and silent about the neighbouring one reads as complete, which is
  what makes it dangerous.
- **Anything a tool, skill, or convention made harder than it needed to be** — including this one.
- **Anything re-derived that an earlier session already knew.** A documentation gap with a receipt.

**`documentation-conventions.md` defines *when* a discovery must be written down** — and its
triggers are the authority, not this list. Walk them alongside the two passes above; it also names
what must *not* be documented, which is what stops a retro turning findings into clutter.

Then, for each finding, ask the question that decides everything downstream:

> **What would have had to be written down, and where, for this session to have gone differently?**

A finding that cannot answer that is an observation. Say so and drop it rather than finding it a
home — a rule nobody would have read is rent with no return.

---

## Step 2 — Check it is not already written down

**Grep the destination before proposing anything.** One command, and it is the difference between
sharpening a rule and duplicating it. Where something related exists, **sharpen it in place**: an
adjacent second bullet is how a file grows without getting better.

Three traps, each of which has cost a real session:

- **You may be running an older copy of a skill than the source.** A session resolves its skills
  once, at start, from the installed copy. The checkout can be several versions ahead, and the
  rule you are about to add may already be there — along with the fix for the problem you just
  hit. Compare before you write.
- **A rule that exists but did not fire is not a missing rule.** If the guidance was there and was
  not followed, the finding is about *reach* — wrong file, wrong step, buried under something
  louder — or it is simply that you erred. Say which. A second copy of an ignored rule weakens
  both.
- **Check what the session *invalidated*, not just what it added.** The sentence elsewhere that
  this work just made false is more dangerous than a missing one: a stale rule reads as current,
  gets followed, and gets the change reverted by someone who believes they are fixing a
  regression. If a decision was reversed, grep the conventions, the project's docs and any guard
  test's prose for the rule it overturned — **including any note saying not to do the thing that
  was just done** — and correct it where it lives. Say it was reversed and on whose call, so the
  next reader can tell a decision from an erosion.

---

## Step 3 — Choose the destination

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

## Step 4 — Recommend, then write

Present the findings with **a recommendation, not a survey**: each one, its destination, and a
single line of why — plus what you propose *not* to write, and the reason. A menu of options hands
the judgement back to the user, which is the opposite of the point.

Then wait. These are edits to files that shape every later session, and the user gets to disagree
before they land — frequently about the destination rather than the finding.

Once agreed, write them. Match each file's existing voice and structure; a rule that reads as a
foreign insertion is a rule that gets skipped. State the failure the rule prevents, not the
reasoning that convinced you of it.

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

Verify the installed copy matches the source afterwards. A silent no-op here is exactly the trap
Step 2 warns about, one layer further in.

---

## Step 6 — Report

Per finding: where it landed, and in one clause, why there. Then the three things the user cannot
see for themselves:

- What was proposed and deliberately **not** written, with the reason.
- Anything left uncommitted, unpushed, or unreleased.
- **Whether a restart is required** for any skill change to take effect.

If nothing surfaced, say that plainly.
