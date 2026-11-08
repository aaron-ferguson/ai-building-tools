---
id: "0069"
title: Add a live domain-model and decision-record discipline to design and develop
type: feature
next: design
status: ready
qa_level: verify
size: m
created: 2026-08-26
source: agent
parent:
blocked_by: []
relates: ["0070", "0071"]
expects:
  - skills/design/SKILL.md
  - skills/develop/SKILL.md
claimed_by:
claimed_at:
touches:
---

## Problem

Neither `/design` nor `/develop` maintains a running glossary of a project's own domain
vocabulary, or a log of why a hard-to-reverse decision was made a particular way. `/design`
Step 4 records the answer to one question in *Notes & decisions* on the ticket that asked it, but
that record lives inside one item file and is never cross-referenced from the next ticket that
touches the same concept — so a term gets redefined, or a rejected alternative gets proposed
again, with nobody noticing it already happened. `/develop` Step 4 says nothing about checking
whether the code it's about to write agrees with vocabulary the project already settled on.

A comparable external skill (`domain-modeling`, from a third-party skills repo surveyed
2026-08-26) keeps a single `CONTEXT.md` glossary per project (or a `CONTEXT-MAP.md` fanning out to
one per bounded context) and a `docs/adr/` folder, both updated inline the moment a term or
decision resolves, and offers an ADR only when a decision is **hard to reverse**, **surprising
without context**, and **the result of a real trade-off** — all three, or skip it. That three-part
test is worth adopting regardless of where the discipline ends up living, because it is what stops
every `/design` verdict from becoming a written record nobody needed, and every one that *did*
need it from staying only in a chat log.

## Open design question

- **Question:** Does this discipline become part of `/design` (offered whenever Step 4 records a
  standing decision) and `/develop` (checked before Step 4's implementation begins), reusing the
  existing item-file *Notes & decisions* mechanism plus a new project-level `CONTEXT.md` /
  `docs/adr/`? Or does it become a new standalone skill the other two call into, the way the
  surveyed repo splits a `grilling`/`domain-modeling` primitive out from its flow skills? The
  answer decides whether this ticket edits two existing skill files or adds a third.
- **Why it blocks specification:** the acceptance criteria differ by shape — "Step 4 of `/design`
  writes to `CONTEXT.md`" is a different, testable claim than "`/design` calls a separate skill
  that writes to `CONTEXT.md`." Guessing the shape now means `verify` checks a contract nobody
  argued for.
- **Settle it with:** `/design` — the inputs are `skills/design/SKILL.md`, `skills/develop/SKILL.md`,
  and how much this toolkit's "one skill per session" cost discipline tolerates a third skill
  being pulled into the same turn as `/design` or `/develop`. Nothing needs to be seen.

## Functional requirements

Written after the design question is settled. What is fixed regardless:

- FR1 — A project using this toolkit can accumulate a glossary of its own domain terms, updated at
  the moment a term is resolved rather than batched, and the skill(s) doing the updating say where
  the file lives when none exists yet (created lazily, on first resolved term — matching this
  toolkit's own "don't scaffold speculatively" instinct in `queue` Step 0).
- FR2 — An ADR is offered only when a decision is hard-to-reverse, surprising without context, and
  the result of a real trade-off — all three — and the skill states this test explicitly rather than
  leaving "when do we write one of these" to judgement each time.
- FR3 — Whichever skill(s) own this, the location of decision records is either cited against
  `documentation-conventions.md` (if it already governs this) or the ticket records that no such
  convention exists yet and this toolkit's mechanism is the first one.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The glossary/ADR file format and location are specified once, in the skill(s), and not restated per project | `documentation-conventions.md` |

## Acceptance criteria

Cannot be written until the design question is settled.

- [ ] AC1 — Given a project with no `CONTEXT.md`, when a term is resolved during the owning
  skill's run, then the file is created at that point, not scaffolded up front.
- [ ] AC2 — Given a candidate decision that fails any one of the three ADR tests, when the owning
  skill considers offering an ADR, then it does not.
- [ ] AC3 — Given `skills/design/SKILL.md` and `skills/develop/SKILL.md` (or a new skill file,
  depending on the design answer), when read, then the three-part ADR test appears verbatim, once.

## QA plan

- **Level:** verify — provisional; a prose-only answer (folding into the two existing SKILL.md
  files) stays `verify` with the scoped greps in AC3; a new standalone skill file is still `verify`
  since nothing executable is added, but revisit if the design answer adds a script.
- **Why this level:** the deliverable is skill-file prose either way.
- **Specific checks:** scoped greps for the three-part ADR test and for the glossary-creation rule,
  each matched within the owning section so a rewrap doesn't silently defeat the check.

## Out of scope

- Building the glossary/ADR content for any specific project (including this one — `company:
  none` means this repo carries no domain to model beyond its own vocabulary).
- A cross-project search over multiple `CONTEXT.md` files.

## Notes & decisions

- Captured 2026-08-26 from a comparison against a third-party skills repo (`grill-with-docs` /
  `domain-modeling`, github.com/mattpocock/skills). Routed to `design` on trigger 1: which of two
  real shapes this takes changes the acceptance criteria, and neither shape can be ruled out from
  the SKILL.md files alone.
- Relates conceptually to 0071 (decision-map mode) and 0070 (diagnosing-bugs): the surveyed repo
  composes a `grilling` + `domain-modeling` pair from inside its bug-diagnosis and decision-map
  flows, so if 0071 or 0070 land first, revisit whether they should call into whatever this ticket
  produces rather than inventing their own vocabulary-recording step. Not a `blocked_by` — none of
  the three is gated on another's ticket closing, only on being aware of the others when their
  design questions are settled.
