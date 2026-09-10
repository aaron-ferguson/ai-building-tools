---
id: "0146"
title: Decide when a required duplication earns a drift guard, and guard the copies that qualify
type: debt
next: design
status: ready
qa_level: verify
size: m
created: 2026-09-09
source: agent
parent:
blocked_by: []
relates: ["0106", "0027"]
expects:
  - tests/close.test.sh
  - skills/queue/templates
  - references/CONCURRENCY.md
claimed_by:
claimed_at:
touches:
---

## Problem

**Four "change one, change all" duplications live in these scripts and exactly one of them has a drift
guard.** The install contract makes copying the only option — a backlog script sources nothing, so
shared code cannot be extracted — which means the question is not how to stop duplicating but **when a
copy earns a guard**, and that has been decided per ticket four times with three different answers:

| duplication | copies | guard |
|---|---|---|
| the `saw`/`saw_on_pass` helper | four test suites | none |
| the `DECOMMENT` awk block | three scripts | none |
| the `fm_value` reader | three scripts | none |
| the scope-comparison block (`0106`) | `close`, `handoff` | byte-for-byte comparison |

Each carries a comment saying to change them together, which is a rule with nothing enforcing it.
`0106` wrote a comparison for its own copy and the other three were left, so the repo's answer today is
"whichever ticket happened to think of it" — and a comment is exactly the artefact
`documentation-conventions.md` now warns ages without reddening.

## Open design question

**What makes a required copy worth a drift guard, and what shape should that guard take?**

What has to be settled before acceptance criteria can exist:

- The **trigger**. Candidates: every copy, any copy of more than N lines, any copy whose divergence
  would be silent (as against one that would fail loudly the first time it ran), any copy crossing the
  template/installed boundary. The third is the most principled and the hardest to apply mechanically.
- The **shape**. A byte-for-byte comparison is what `0106` used and it forbids legitimate local
  difference; a normalised comparison permits it and is a second thing to keep correct. Which applies
  may depend on the copy.
- Whether the rule belongs to this repo or to `testing-conventions.md`. The install contract that
  forces the copy is this repo's, so the *trigger* is probably local — but "a copied block needs a
  guard or it diverges" holds on anyone's codebase.
- Whether the three unguarded duplications are then guarded under this row or under their own, given
  the `saw` helper spans four test files and is the largest of them.

Constraints the decision may not break: a backlog script sources nothing and that is not under review
(`0027`); and the guard must not make the template/installed comparison in
`tests/backlog-scripts-installed.test.sh` redundant or contradictory.

## Out of scope

- Extracting shared code into a library. Forbidden by the install contract, named above.
- Reviewing whether the four duplications should exist.

## Notes & decisions

- **2026-09-09 (retro)** — Filed from a park that enumerated all four duplications and framed the
  question as when a copy earns a guard rather than how to avoid copying. Routed to `design` because
  every part of it is a trigger to be chosen, not a defect to be fixed.
