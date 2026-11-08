---
id: "0138"
title: Decide whether idea capture is a lighter-weight skill than queue's Add, and what triggers it
type: chore
next: design
status: ready
qa_level: verify
size: m
created: 2026-09-09
source: user
parent:
blocked_by: []
relates: ["0059", "0057", "0128"]
expects:
  - skills/queue/SKILL.md
  - skills/queue/templates/item.md
claimed_by:
claimed_at:
touches:
---

## Problem

Aaron asked how to adopt "intent.md" — a lightweight, pre-specification idea-capture convention —
against a toolkit that already turns a described idea into a fully specified, ranked ticket in one
`queue` pass. Two moments turn out to need different things from a capture step, and `queue`
currently serves only one of them well.

**A ready-to-build report and a not-yet-decided idea are not the same event.** `queue`'s Add writes
FRs, an NFR table, `qa_level`/`close_by`, and a rank in the same session the Problem section is
written, on the stated ground that "reading the source material is a shared cost paid once." That
is right when the reporter already knows what they want built. It is the wrong shape for an idea
someone wants to write down, sharpen, and possibly have reviewed *before* anyone commits to sizing
or ranking it — there, the FR/AC/`qa_level` machinery is work spent on a decision (build this at
all?) that has not been made yet.

**The cost of the heavier path is measured, not assumed.** `queue` records itself at **191,752
tokens/turn, 85% of cost in context handling**. Most of a `queue` session's ~620-line `SKILL.md` —
ranking tie-breakers, `qa_level`/`close_by` taxonomy, AC red/green heuristics, concurrency locking —
is irrelevant to writing down four sentences. A session that only wants to park an idea pays that
whole tax today; Step 5 already shows the alternative is possible (a Problem-only item, no FRs, no
rank, left out of `QUEUE.md`), but that path exists only for findings a session notices mid-work,
not as a front door for a freshly described idea.

**Whether splitting helps depends on an axis `queue` has not settled on itself.** `0059` shows the
"batch related work into one session" rationale currently argues for the *largest* batch available,
not for keeping capture and specification coupled per item — the condition and the reason disagree
today. This ticket's question is a different axis (splitting one item's capture from its
specification, not batching several items' verification), but the two are close enough that a
reader deciding one should see the other.

**The shape also has to answer "how big is this idea" before it can pick a template.** `0128`
demonstrates the project shape (parent, children carrying the stages) is already real and used
without waiting for `0057`'s formal template — so a captured idea that turns out to be a whole
workflow, not a single feature, needs to route to that shape rather than to a single task file.
Nothing today distinguishes those at the point of capture.

## Open design question

- **Question:** Should idea capture be a separate, lighter-weight skill (or an explicit lightweight
  mode of `queue`) that runs before `queue`'s Add — writing only Problem / Why / Constraints / Open
  questions into an `items/`-numbered file at `next: queue`, `status: ready`, untouched in
  `QUEUE.md`, exactly mirroring Step 5's parked-finding shape — and if so, what specifically triggers
  it instead of going straight to `queue`'s Add? Two live candidates: **(a)** a new skill (its own
  `SKILL.md`, small, no ranking/QA/concurrency-taxonomy content, citing `references/CONCURRENCY.md`
  rather than restating it); **(b)** a documented lightweight mode inside `queue` itself, reached
  when the reporter states outright that sizing/ranking isn't wanted yet.
- **Why it blocks specification:** the acceptance criteria differ by which candidate wins — (a)
  needs a new file to exist and pass the skill-size gate; (b) needs a Step 1 table row and no new
  file. Whether the promotion step (parked idea → real ticket) reuses `queue`'s existing "a ticket
  sits at `next: queue`" re-specify row, or needs its own, also depends on the answer.
- **A known defect in that reuse path, regardless of the answer:** Step 1's re-specify row states
  the ticket being re-specified "already has a rank and keeps it," which is true for a ticket
  bounced back from a later stage but false for one parked at capture time and never ranked at all —
  see the `FINDINGS.md` entry filed alongside this ticket. Whatever this design settles, the
  promotion path needs Step 3 to run for a never-ranked item.
- **Settle it with:** `/design` — the inputs are `queue`'s own Step 2/Step 5 text, the measured cost
  breakdown, and `0059`'s unresolved batching question. Nothing needs to be seen.

## Functional requirements

Written after the design question is settled. What is fixed regardless:

- FR1 — Whichever shape wins, the resulting artifact is stored in the existing `items/` directory
  under the existing id sequence (`max(items on disk) + 1`) — no second numbering scheme, no separate
  `intent/` folder.
- FR2 — The frontmatter it writes is a strict subset of `templates/item.md`'s fields (`id`, `title`,
  `next: queue`, `status: ready`, `created`, `source`); every other field stays blank for `queue` to
  fill at specification time, not invented early.
- FR3 — The promotion path (captured idea → specified, ranked ticket) is named explicitly, and
  states whether it runs Step 3's ranking walk (it must, for an item that was never ranked) —
  correcting Step 1's re-specify row rather than leaving the new path to inherit its wrong premise.
- FR4 — Whatever locking/commit mechanics the resulting skill needs are cited from
  `references/CONCURRENCY.md`, never restated.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | Whichever shape wins is a shipped artefact read by every project installing this plugin, so it is written generically, not for this repo's instance | `documentation-conventions.md` |
| Progressive delivery | Ships to every machine on the next version bump and install | `progressive-delivery-conventions.md` |

## Acceptance criteria

Cannot be written until the design question is settled.

## QA plan

- **Level:** verify — provisional. Both candidate shapes are prose/skill-file changes with no test
  runner in this project; the checks will be scoped greps and a path check, matching how `0057` and
  similar prose-and-template tickets in this backlog are checked.
- **Why this level:** shared across both candidates.
- **Specific checks:** settled by the design pass; `tests/skill-size.test.sh` and
  `tests/citations.test.sh` apply regardless if a new skill file is the outcome.

## Out of scope

- **Resolving `0059`'s batching question.** Related, not this ticket's to settle — cite its verdict
  once it lands rather than re-deriving it here.
- **Shipping `0057`'s project template.** This ticket only needs the project *shape* to exist as
  precedent (`0128`), not the formal template landed.
- **Any change to how `queue` ranks or specifies a ticket once it's already at `next: queue` and has
  FRs.** Only the pre-specification moment is in scope.

## Notes & decisions

- Routed to `design` on trigger 1: which shape wins (new skill vs. mode of `queue`) is a real
  decision with incompatible downstream ACs, not a detail discoverable by reading code.
- Checked for overlap before filing: no existing item names idea/intent capture, a lightweight front
  door, or the id/name field question — the latter needed no ticket, since `templates/item.md`
  already separates `id` from `title` and this ticket's own shape just follows that precedent.
- `relates`: `0059` (the batching axis this is adjacent to but distinct from), `0057` (the project
  template this depends on for the workflow-vs-feature split), `0128` (live evidence the project
  shape already works informally, ahead of `0057` landing).
