---
id: "0208"
title: Make the prototype template's render keep focus and play enter animations once
type: bug
next: queue
status: ready
qa_level: verify
close_by: verify
qa_manual:
size: s
created: 2026-10-10
source: agent
parent:
blocked_by: []
relates: []
expects:
  - skills/prototype/assets/prototype-template.html
claimed_by:
claimed_at:
touches:
---

## Problem

Filed by retro 2026-10-10 (tail of quantum-catan run-20261010T212209Z) from this repo's buffer.
The level-2 template re-renders everything on every state change, which replays enter animations and
drops keyboard focus: in a sheet with steppers each tap re-ran the slide-in and lost focus. quantum-catan
0014 needed a one-shot `sheetFresh` flag, focus restore by `data-key`, and autofocus only when a layer
opens (quantum-catan `prototypes/turn-loop/index.html`, `render`/`restoreFocus`).

## Established, not yet specified

- Any template-built prototype with a modal plus live controls hits it; the quantum-catan file is a
  working reference implementation. Focus loss is an accessibility defect, not only polish.

## Notes & decisions
