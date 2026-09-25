---
id: "0188"
title: Plan a sprint from a develop-ready head, and keep design one sprint ahead of develop
type: feature
next: design
status: ready
qa_level: unit
close_by: verify
size: m
created: 2026-09-25
source: retro
parent:
blocked_by: []
relates: ["0134", "0159", "0137", "0050"]
expects:
  - skills/sprint/SKILL.md
  - skills/queue/templates/next
  - tests/sprint.test.sh
  - tests/next.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

**A sprint opened on design work because the queue's top row sat at `next: design`, and the
sprint skill lets design run only beside `develop`. The user has stated a wider rule for both.**

In run-20260924T050130Z, `./next --drive --propose` offered a one-ticket design gate, because the
queue's top row was a design row. The user's rule (2026-09-24, recorded by that run's supervisor):

1. **A sprint is planned from the top row, and that row should be `develop ready`.** The gate takes
   every related ticket. Related tickets that still need design are designed in parallel within the
   same sprint and then built.
2. **The plan also looks at where the queue will stand after the sprint**, and designs the ticket or
   tickets that will head the *next* sprint, so design stays ahead of develop. This is the next
   sprint's head only, not every design row.
3. **Design is research, so it may run beside develop, verify, or another design session**, provided
   its files do not conflict with what the running sessions touch. The supervisor checks the design
   ticket's scope against the running sessions' files, and what accepting its outcome would change,
   before dispatching. Retro and queue always run alone.

Checked 2026-09-25: `skills/sprint/SKILL.md` *Design alongside develop* opens with "the one stage
that may run beside another, and only beside `develop`", and `tests/sprint.test.sh` guards that
section. The proposal section has no rule about where the queue will stand afterwards.

## Open design question

What does `./next --propose` compute, and what does the proposal section of the sprint skill say, so
that (a) a sprint whose top row is at `next: design` is planned from the first `develop ready` row
rather than opened on design, (b) the design rows it takes are the related tickets of this gate
and the head of the next sprint, and nothing else, and (c) a design session may run beside develop,
verify or design when its files do not overlap? For (c), decide what "files do not conflict" is
checked against. The candidates are the running rows' `expects:`/`touches:`, or the design row's
`expects:`. `0050` holds the open question of file scope when prose files are the product; say
whether this decision depends on it.

## Functional requirements

- **FR1** — The proposal is planned from the first `develop ready` row, and a design row above it
  is not the gate.
- **FR2** — The proposal names the design rows it will run in parallel: the gate's related tickets
  that need design, and the head of the next sprint.
- **FR3** — *Design alongside develop* is widened to develop, verify and design, under a stated
  file-conflict check. Retro and queue stay alone.
- **FR4** — Every guard that pins the old "only beside `develop`" wording is rewritten, not deleted.
  Its comment says the rule was widened on the user's call (2026-09-24).

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Concurrency | A design session never runs beside retro or queue, and never beside a session whose files overlap its own | a fixture run log with a design dispatch open during a retro, which the design-windows check passes | `references/CONCURRENCY.md` |

## Acceptance criteria

To be written by design against the answer; FR1–FR4 are the floor.

## QA plan

Unit: `tests/next.test.sh` fixtures for `--propose` over a queue headed by a design row;
`tests/sprint.test.sh` for the widened section.

## Out of scope

- Parallel develop sessions: `0137` declines them, and nothing here reopens that.

## Notes & decisions

- 2026-09-25 — filed by retro from two 2026-09-24 supervisor findings (run-20260924T050130Z). Both
  record rules the user stated, so the rules are not in question here, only their mechanism.
