---
id: "0110"
title: Decide the shape of a ticket whose first requirement can kill the rest
type: chore
next: design
status: ready
qa_level: verify
qa_manual:
size: m
created: 2026-09-07
source: agent
parent:
blocked_by: []
relates: []
expects:
  - skills/queue/templates/item.md   # Functional requirements, and a field for a kill result
  - skills/queue/SKILL.md            # Step 2
claimed_by:
claimed_at:
touches:
---
## Problem

**A ticket whose first requirement is a gate that can kill the rest of it has no shape in
`item.md`, and the template quietly assumes every FR ships.**

The withdrawn `0104` (preserved at commit `7764732`) had FR1 as a measurement with written kill
criteria; FR2-FR6 existed only if it cleared. The honest close on a kill was *"MEASUREMENT.md
records the negative result and nothing else changed"*.

Nothing in the template or in `queue` Step 2 provides for a conditional FR, so the condition had to
be written inline into each dependent FR — *"and only if FR1 clears"* — and a whole acceptance
criterion was spent asserting the **killed** state, so that `verify` could not read a kill as an
unfinished ticket.

`discovery-conventions.md` carries the kill-criteria discipline and the item template has no field
for its result. So every gated ticket re-invents this, and a later reader cannot tell a killed FR
from a skipped one — which is the reading that matters, because one is a recorded verdict and the
other is abandoned work.

## Open design question

Two shapes, and they are not equivalent.

**A — a conditional-FR form in the template.** One ticket holds the gate and its dependents, with a
declared condition and a field for the kill result. Keeps the measurement and what it decides in one
place, which is where a reader looks. Costs the template a form that most tickets never use, and
leaves `verify` needing to distinguish three terminal states rather than two.

**B — `queue` splits the gate into its own ticket, and the dependents `blocked_by` it.** No new
template form: a killed gate simply closes with its recorded verdict, and its dependents are
withdrawn or re-scoped by whatever reads that. Uses machinery that already exists. Costs the
separation of a measurement from the thing it was measuring, and needs a rule for what happens to
the dependents on a kill — which is the part `blocked_by` does not express, since it means "wait
for", not "exists only if".

**What must be true either way:** a killed FR is distinguishable from a skipped one, and
`measurement-conventions.md`'s requirement that the verdict is recorded even when it is "it didn't
work" is satisfied without a session inventing a place to put it.

## Functional requirements

Written after the design question is settled — that is what `next: design` means here.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | Whichever shape wins is stated once, and the decision record says why the other was rejected | `documentation-conventions.md` |

## Acceptance criteria

Written after the design question is settled.

## QA plan

- **Level:** verify — the deliverable is a decision plus prose, and the check is whether a gated
  ticket can now be written without inventing a form.
- **Why this level:** no runner can assert that a template shape is sufficient; writing one against
  it can.
- **Specific checks:** to be written with the ACs, once the shape is chosen.

## Out of scope

- Re-issuing the withdrawn `0104`. Its ID is burned (`0105`) and its subject shipped separately.
- Changing `discovery-conventions.md`. The kill-criteria discipline is correct; what is missing is a
  place in the backlog to record its result.

## Notes & decisions

- 2026-09-07 — Filed by `retro` at `next: design` rather than deferred in the buffer. The choice
  between A and B is a real decision with a real trade-off, and the queue has a stage for that;
  leaving it parked would have meant the next retro paying to re-derive the same two options.
