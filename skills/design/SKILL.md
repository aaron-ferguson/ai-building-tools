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

Answer a design question well enough that nobody has to answer it again.

The output is a **decision**, not an artifact. `/prototype` builds something to look at; this
skill works out what should be built and writes down why. Most design questions do not need a
prototype — they need the existing pattern found, the convention applied, and the answer
recorded where the next person will hit it.

**One skill per session.** Run this skill in its own conversation and let the backlog carry the
handoff — the ticket's `next` field and `FINDINGS.md`, never a conversation. A measured
end-to-end run on **2026-08-22** spent **85% of $15.11 on context handling** at an average of
**191,752 tokens per turn**; isolated, the same work models at **~$5.09**. **No standard is
relaxed by this** — the rigour that caught a zip-bomb vulnerability every acceptance criterion
passed over is in the 15% that was output.

**This skill states no standards of its own.** What counts as usable, accessible, or consistent
is defined by the project's conventions and cited, never restated. Resolve them per
`references/CONVENTIONS.md`. If none resolve, stop as that file directs — a design verdict
issued against no standard looks identical to one issued against a real standard, and that
silent equivalence is the failure this whole design exists to prevent.

**It writes nothing to the queue.** If the answer changes a backlog item, hand it to `queue`.
Only `queue` and `develop` write item files, which is what makes it safe to run this in one
window while another develops.

**It never invokes `/prototype`.** When a question genuinely cannot be settled on paper, say so
and say what a prototype would have to settle — the user decides whether to build one.

---

## Configuration

Read the context config the project declares (`CLAUDE.md` names `company: <name>` and its config
directory). This skill uses `design_system` only.

- **Configured with an MCP server** → it is the source of truth for tokens, components, and
  contrast. Query it rather than reasoning from memory about what components exist.
- **Absent** → still answer the question from the conventions and the existing codebase, and say
  explicitly that no design system was available, so component names and token values are
  descriptions rather than citations.

---

## Step 1 — Get the question, and make it decidable

From a backlog item at `next: design`: read its **Open design question** section. That is the
contract — answer *that*, not a broader topic you find more interesting.

Ad-hoc: take the question as asked.

**Sharpen it before answering.** A decidable question has a small set of candidate answers and
something that distinguishes them. "Bulk edit UX" is a topic. "Modal or full page for bulk
edit, given the user needs the list visible while editing?" is a question. If what you were
given is a topic, say so and propose the sharper version before proceeding — an unsharpened
question produces an answer nobody can act on.

If the real answer is "this is three questions", say that and take them in order.

---

## Step 2 — Look before reasoning

In this order, because each one can make the next unnecessary:

1. **Prior art in this codebase.** Does this pattern already exist somewhere? An answer that
   matches what the product already does beats a better answer that makes the product
   inconsistent. If you find prior art you are choosing to depart from, say why explicitly.
2. **The design system**, if configured. Search components before inventing one. A question of
   the form "how should X look" is very often already answered by a component that exists.
3. **The conventions.** Read the files the core's index names for design, UI, and accessibility.
   Read them; do not recall them. Cite the file when the answer turns on a rule.

**If the question touches user-facing UI, accessibility is not optional** and does not wait to
be asked about. Check contrast on any colored-text pairing you propose, and confirm the
interaction works from the keyboard and reads correctly to a screen reader. An answer that only
works with a mouse is not an answer.

---

## Step 3 — Answer it

State the recommendation first, then the reasoning. Not a survey — a decision.

- **Give the real alternatives**, briefly, and say what would have to be true for each to win.
  Two or three. A list of every conceivable option is a way of avoiding the decision.
- **Name the trade-off you are accepting.** Every design decision costs something. An answer
  with no stated cost has not been thought about hard enough.
- **Say what it depends on.** If the answer flips on a fact you do not have — how many rows
  typically, whether this is the primary path, who the user actually is — name that fact rather
  than assuming it quietly. Ask if it is cheap to ask.

**When the answer cannot be settled on paper**, say so plainly and stop. Then state:

- what a prototype would have to settle — the specific thing that has to be *seen* to be decided
- which fidelity level would settle it, and why a cheaper one would not

That is the same discipline as writing kill criteria before running a test: the prototype has a
job, and you can tell afterwards whether it did it. Do not invoke `/prototype` — the user does.

---

## Step 4 — Record it, or it will be re-litigated

A decision that lives only in a chat log gets decided differently next month by someone with
less context. This step is most of the value of the skill.

**Item-scoped** — it answers a specific backlog item's open question:
hand `queue` the answer, and the answer to record in the item's **Notes & decisions**. `queue`
writes the FRs and ACs the answer unblocks, deletes the item's *Open design question* section,
and moves it to `next: develop`. Do not write to the item yourself.

**Standing** — it sets a pattern beyond this one item: write a decision record where the
project's `documentation-conventions.md` says decision records live. Include the question, the
answer, what was rejected and why, and the date. What was rejected is the part that stops the
same debate reopening.

**Neither** — a one-off with no reuse: say so and skip the recording rather than manufacturing
a document nobody will read. Not every question deserves a record, and pretending otherwise
devalues the ones that do.

---

## Step 5 — Park what surprised you

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

## Step 6 — Report

Short. The decision, the one-line reason, what it depends on if anything, and where it was
recorded. If a prototype is needed, that plus what it must settle.

Never report a decision as settled when Step 3 found it depends on a fact you do not have —
say what is still open. A confident answer to a question that was not actually answerable is
worse than an admitted gap, because it gets built.
