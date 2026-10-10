---
id: "0205"
title: Decide what may join a develop gate, and whether a related design row in flight holds it
type: chore
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
  - skills/sprint/SKILL.md
  - tools/next
claimed_by:
claimed_at:
touches:
---

## Problem

Filed by retro 2026-10-10 (tail of quantum-catan run-20261010T212209Z) from this repo's buffer.
Two parks from quantum-catan run-20261010T144315Z. (1) A gate joined 0008 to 0007/0006 through a shared
`packages/engine/README.md` plus parent 0001 alone; the owner ruled (quantum-catan, 2026-10-10) that only
tickets sharing **code** files batch, and the supervisor overrode the gate by hand. (2) `--drive` named
the develop gate while design 0030, labelled "related to this gate" by the proposal, was still running,
so 0030 needed its own develop gate; exit 6 waits only on file overlap. Candidate: an in-scope design
row tagged related holds the gate (exit 6) until its outcome.

## Established, not yet specified

- The owner's code-files-only rule is one project's ruling; whether it is the tool default is the
  design question. The ledger's evidence for develop batching is thin: a 4-ticket gate cost USD 1.55 per
  ticket against USD 1.43 for a single ticket.
- Gate composition was last changed by 0178 (`gate_max_rows`) and 0188 (design beside develop).

## Notes & decisions
