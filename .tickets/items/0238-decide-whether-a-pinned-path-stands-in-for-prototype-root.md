---
id: "0238"
title: Make prototype levels 2 and 3 work inside a consuming project
type: chore
next: design
status: ready
qa_level: verify
close_by: verify
qa_manual:
size: m
created: 2026-11-18
source: agent
parent:
blocked_by: []
relates: ["0208"]
expects:
  - skills/prototype/SKILL.md
  - skills/prototype/assets/prototype-template.html
ac_digest: 
claimed_by:
claimed_at:
touches:
slice:
---

## Problem

**Outcome (merged 2026-11-26, at the user's direction):** a consuming project gets a level-3 prototype on the real component its ticket pins, and a level-2 mockup that keeps focus and plays its enter animations once, without inventing configuration.

AetherWorks item 0027 required real-component fidelity on `src/ui/screens/HowToPlay.tsx`. With no
`prototype:` block, `skills/prototype/SKILL.md`'s configuration table says level 3 **stops** — though
nothing would have been invented: the ticket pins the file, and the stack is the repo the skill runs
in. The session proceeded on a throwaway branch instead.

### Absorbed 2026-11-26: 0208 — Make the prototype template's render keep focus and play enter animations once

Filed by retro 2026-10-10 (tail of quantum-catan run-20261010T212209Z) from this repo's buffer.
The level-2 template re-renders everything on every state change, which replays enter animations and
drops keyboard focus: in a sheet with steppers each tap re-ran the slide-in and lost focus. quantum-catan
0014 needed a one-shot `sheetFresh` flag, focus restore by `data-key`, and autofocus only when a layer
opens (quantum-catan `prototypes/turn-loop/index.html`, `render`/`restoreFocus`).


## Open design question

Does a ticket-pinned path in the current repo stand in for `prototype.root` at level 3 — and what
then stands in for `routes_file`, `build_command` and `serve_url`, which the level-3 steps also read?
Or does the stop stay, with the message naming the minimal block to add?

## Functional requirements

- FR1 — The configuration table and the level-3 section agree on the answer, and the case
  (base product = this repo, ticket names the file) is named explicitly.

## Progress

**One outcome is one ticket, even across many sessions**; its slices are worked in order, each about
one develop session's work (`product-definition-conventions.md` → "Slice Vertically and Thinly").

- [ ] S1 — decide whether a ticket-pinned path in the current repo stands in for `prototype.root` at level 3 — unspecified
- [ ] S2 — the level-2 template keeps focus and plays enter animations once (0208) — unspecified


## Notes & decisions

- 2026-11-18 (retro) — filed from a consuming project's finding in `.tickets/FINDINGS.md`.
- **2026-11-26 (queue): merged by outcome, at the user's direction.** The 2026-11-26 consolidation grouped the backlog by outcome so a whole outcome is worked in one ticket and its context is paid for once. Absorbed and withdrawn, each id burned and each item file kept as the record:
  - `0208` (Make the prototype template's render keep focus and play enter animations once): no FRs, no ACs (an unspecified slice)
  Each absorbed ticket's Problem is quoted verbatim above, and its FRs, ACs, NFR rows, QA plan, Out of scope and Notes are carried below with `*(was NNNN FRn)*` tags. **Bare FR and AC numbers inside the carried text were renumbered to this ticket's.** A reference to another ticket's criterion not written as `NNNN ACn` may have been renumbered too, and the withdrawn file holds the original. An unspecified slice sends this ticket to `design` when it is next; its open question is below.

### Open questions for the unspecified slices

**Established, not yet specified (it was at next: queue), from 0208 — Make the prototype template's render keep focus and play enter animations once:**

- Any template-built prototype with a modal plus live controls hits it; the quantum-catan file is a
  working reference implementation. Focus loss is an accessibility defect, not only polish.

### Carried notes of the absorbed tickets

### From 0208 — Make the prototype template's render keep focus and play enter animations once


