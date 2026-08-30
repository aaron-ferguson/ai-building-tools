---
name: design
description: >
  Answer a design question and record the decision — which pattern, where a control belongs,
  what the empty and error states are, whether a flow should be one step or several, whether an
  interaction is accessible. Use when the user asks "should this be a modal or a page", "where
  should this live", "what's the right pattern for X", "how do we handle the empty state", "is
  this accessible", or invokes /design. Also use to settle a backlog item sitting at
  `next: design`. Returns a DECISION with reasoning, checked against the project's design,
  UI, and accessibility conventions and its design system. NOT for building an artifact — if
  the user wants a diagram, a clickable mockup, or a real component to look at, that is
  /prototype. Tell me versus show me is the line.
---

# /design

Answer a design question well enough that nobody has to answer it again. The output is a **decision**,
not an artifact: `/prototype` builds something to look at, this works out what should be built and writes
down why.

**One skill per session.** Run this skill in its own conversation; the backlog carries the handoff — the
ticket's `next` field and `FINDINGS.md`, never a conversation. Measured **2026-08-22**: **85% of $15.11
went on context handling** at **191,752 tokens per turn**, modelling to **~$5.09** isolated. **No standard
is relaxed** — the rigour is all in the 15% that was output.

**This skill states no standards of its own** — usable, accessible and consistent are defined by the
project's conventions and cited, never restated. Resolve them per `references/CONVENTIONS.md`; if none
resolve, stop as that file directs, because a verdict against no standard looks identical to a real
one.

**It writes the ticket it settled, when nobody else holds it.** Handing the answer back to `queue` to be
typed in costs that skill's whole instruction file — measured at 5,699 tokens, five turns and **$0.67**
for one ticket. The rule against writing existed so two sessions could not write one item, so it applies
exactly when one does. **How to tell:** `claimed_by:` set and the row `in-progress`. Unclaimed → you
write it (Step 4). Claimed → hand off.

---

## Step 1 — Get the question, and make it decidable

From a ticket at `next: design`: read its **Open design question** section. That is the contract — answer
*that*, not a broader topic you find more interesting. Ad-hoc: take the question as asked.

**Sharpen it before answering.** A decidable question has a small set of candidate answers and something
that distinguishes them. "Bulk edit UX" is a topic; "modal or full page for bulk edit, given the user
needs the list visible while editing?" is a question. Given a topic, propose the sharper version first —
an unsharpened question produces an answer nobody can act on. If the real answer is "this is three
questions", say so and take them in order.

---

## Step 2 — Look before reasoning

In this order, because each can make the next unnecessary.

1. **Prior art in this codebase.** An answer matching what the product already does beats a better one
   that makes it inconsistent; departing from prior art needs an explicit why.
2. **The design system.** The project's context config (`CLAUDE.md` names `company: <name>` and its
   config directory) declares `design_system`; configured with an MCP server it is the source of truth
   for tokens, components and contrast, so query it rather than reasoning from memory. Search components
   before inventing one — "how should X look" is very often already answered by one that exists. Absent,
   answer from the conventions and the codebase and **say so**, since component names and token values
   are then descriptions rather than citations.
3. **The conventions.** Read the files the core's index names for design, UI and accessibility — read
   them, do not recall them. Cite the file when the answer turns on a rule.

**If the question touches user-facing UI, accessibility is not optional** and does not wait to be asked
about. Check contrast on any colored-text pairing you propose, and confirm the interaction works from the
keyboard and reads to a screen reader. An answer that only works with a mouse is not an answer.

---

## Step 3 — Answer it

The recommendation first, then the reasoning. Not a survey — a decision.

- **Give the real alternatives**, two or three, and what would have to be true for each to win. Every
  conceivable option is a way of avoiding the decision.
- **Name the trade-off you are accepting.** An answer with no stated cost has not been thought about hard
  enough.
- **Say what it depends on.** If the answer flips on a fact you do not have, name that fact rather than
  assuming it quietly.

**When the answer cannot be settled on paper**, say so and stop, then state what a prototype would have
to settle — the specific thing that must be *seen* — which fidelity level settles it, and why a cheaper
one would not. Same discipline as kill criteria before a test: the prototype has a job, and you can tell
afterwards whether it did it.
Do not invoke `/prototype` — the user does.

### When to involve a person: ask on taste, decide on fact

**The test is what the answer turns on, not how important it feels.**

- **It turns on taste** — which of two defensible looks, how formal the voice, whether this reads as a
  place — then no reasoning settles it and you are guessing on someone's behalf. Ask.
- **It turns on fact** — what the data contains, what the code does, what the convention says, what
  component exists — then go and check. **You have standing permission to decide these without asking,
  and using it is the skill working.** A measured design run asked nothing, read the workbook, and found
  all three proposed inputs for a rule did not exist in the data — "ask early" would have made it worse.

**When you do ask, the recommendation and the question go in the same message.** A session that asks
early costs cents; one that assembles the full argument and *then* asks has already spent the budget on
a direction that may be rejected in one line. Lead with what you would do and why, then the one thing
that would change it.

---

## Step 4 — Record it, or it will be re-litigated

A decision living only in a chat log gets decided differently next month by someone with less context.
This step is most of the skill's value.

**Item-scoped, and the ticket is unclaimed** — you write it, here, now:

1. Record the answer and what it rejected in *Notes & decisions*.
2. Write the FRs and given/when/then ACs the answer unblocks. If it unblocks none, it did not settle the
   question — say so rather than moving the stage.
3. Delete the *Open design question* section, set `next: develop` / `status: ready`, and commit by
   pathspec in the same turn.

**Item-scoped, and the ticket is claimed** (`claimed_by:` set, row `in-progress`) — hand `queue` the
answer and the *Notes & decisions* entry, writing nothing yourself. The token is not yours, and two
sessions in one item file has no merge protocol behind it.

**It has to be *seen* rather than decided** — set `status: waiting`, write the ask into the ticket's
`## Waiting on` section (what must be looked at, who can look), and stop; `./next --waiting` surfaces it
without anyone opening the ticket. Still do not invoke `/prototype`.

**Standing** — a pattern beyond this ticket: write a decision record where the project's
`documentation-conventions.md` says they live, with the question, the answer, what was rejected and why,
and the date. What was rejected is what stops the debate reopening.

**Neither** — a one-off: skip the recording rather than manufacturing a document nobody will read.

---

## Step 5 — Park what surprised you

Before reporting, park what surprised you in `.claude/backlog/FINDINGS.md` — one dated line, while the
context is still hot.

Triggers: **a template or skill step that had no correct answer for your case**, a configured command that
behaved unexpectedly, a scaffolding step you had to invent.

**An explicit "nothing surprised me" is a complete result** — never manufacture one, since an invented
entry is paid for by every later session. **Commit it in the same turn you write it, by pathspec**;
uncommitted it is one `git stash` from gone. Anything whose home is obvious goes there instead.

---

## Step 6 — Report

What belongs on the screen and what belongs on disk is `references/REPORTING.md` at the plugin root.
One thing it cannot say, because it is specific to a decision: **never report one as settled when
Step 3 found it depends on a fact you do not have** — a confident answer to an unanswerable question
is worse than an admitted gap, because it gets built. That is a refusal, and it is reported as one.

A prototype the decision now needs is what this session needs from the user, and the command that
builds it is part of saying so.
