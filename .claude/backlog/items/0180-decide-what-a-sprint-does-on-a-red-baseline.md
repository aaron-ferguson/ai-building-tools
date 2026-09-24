---
id: "0180"
title: Decide what a sprint does on a red baseline, and which stage may fix a red no ticket owns
type: bug
next: design
status: in-progress
qa_level: unit
close_by: verify
size: m
created: 2026-09-23
source: retro
parent:
blocked_by: []
relates: ["0176", "0178", "0054", "0093"]
expects:
  - skills/sprint/SKILL.md
  - tests/sprint.test.sh
  - skills/develop/SKILL.md
claimed_by: "8254"
claimed_at: 2026-09-24T13:07:53Z
touches:
---

## Problem

**`/sprint` Step 1 has no "is the suite green" check.** It runs three checks before the first
dispatch — the CLI probe, the supervisor marker, the depth read — and none looks at the tests. Run
run-20260922T031109Z proposed, confirmed and dispatched a six-ticket develop gate while
`tests/item-ac-form.test.sh` AC1 was already red on `0178` (introduced by `68c132a` the day before).
For the whole run a new red was indistinguishable from the old one without a by-hand comparison, and
the develop stage spent reasoning separating them.

**The author's objection is the requirement:** *"if there is a pre-existing red, then we shouldn't
have started work and should have started with making sure that the suite is green."*

**Underneath it is a question no skill answers: which stage may fix a red owned by no ticket?**
Today none may — *A stage writes only the ticket it holds* forbids touching another item, and the
detector is out of every ticket's scope. So it either deadlocks or is done off the books. It was done
off the books this time: the author decided the fix inline and it landed as `da524ce` under `0176`'s
claim with no row, so `0176`'s diff carries an unrelated test file and nothing in the backlog records
the defect existed.

## Requirements for design to carry through

- **FR1** — `sprint` Step 1 runs `commands.unit` (per file, not fail-fast — `config.yml` explains
  why) and reports the tally on the same line as the depth, so the proposal quotes an honest
  baseline.
- **FR2** — Decide whether a red *ends* the run or blocks the proposal until a person waives it.
- **FR3** — Name the path for a red no ticket owns: a row minted on the spot and led first, or a
  permitted out-of-scope repair recorded somewhere durable. Whichever, a repair like `da524ce` must
  leave a backlog trace.

## Notes & decisions

- 2026-09-23 — filed by retro (session edf44941-de11-48ca-92b8-093a50099f9b) from two FINDINGS
  entries (sprint supervisor, run-20260922T031109Z; develop 0176, token db06), merged because FR3 is
  the question FR2 cannot be answered without.
