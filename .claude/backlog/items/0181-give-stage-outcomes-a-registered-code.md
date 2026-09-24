---
id: "0181"
title: Decide whether stage outcomes carry a registered code that guards match instead of English
type: feature
next: design
status: ready
qa_level: unit
close_by: verify
size: l
created: 2026-09-23
source: user
parent:
blocked_by: []
relates: ["0063", "0123", "0159"]
expects:
claimed_by:
claimed_at:
touches:
---

## Problem

**Guards assert English sentences about facts that are enumerable, and the two come apart.**
`0159` AC7 asserted the absence of `needs a person."*` as a proxy for *no sentence describes a ready
design row as a person's call*; `0159`'s own change rewrote that sentence to name a `next: queue`
row — which genuinely does need a person — so the criterion reddened correct prose and verify closed
it against a substituted assertion. `0063` is the same defect from the other side: a phrase that
straddles a line break cannot be matched at all.

**The precedent exists and stops short of the skills.** `./next --drive` exits 0/3/4/5 and
`skills/sprint/SKILL.md` requires *"Route on the exit code, never on your own reading of the
queue."* Stage outcomes and the prose describing them carry no such code.

**The author's proposal (2026-09-21):** a code per stage/skill outcome, emitted in the summary line
— one token, so wrap-proof and reword-proof — and AC7 becomes `no line carries D-NEEDS-PERSON`.
Shape to decide deliberately: numeric *classes* aligned to the existing exit codes (2xx proceed, 4xx
needs-a-person, 5xx broken) plus a symbolic token. **The registry is where the value is**: it makes
testable that every emitted code is registered and every registered code is emitted somewhere.

**Limits:** retrofit across 11 suites; a code proves emission, not that the surrounding prose is
accurate; it fits enumerable things (outcomes, routing decisions, refusal reasons), not "the skill
explains why X". `CONVENTIONS_CORE.md` *Prefer enforcement over instruction* supports it — "a rule
broken twice was never enforceable as prose".

## Requirements for design to carry through

- **FR1** — Decide the code shape and where the registry lives.
- **FR2** — Decide whether this absorbs part of `0063` rather than sitting beside it.
- **FR3** — Decide how it interacts with `0123`'s rule for withdrawing a criterion.

## Notes & decisions

- 2026-09-23 — filed by retro (session edf44941-de11-48ca-92b8-093a50099f9b) from a FINDINGS entry
  recording the author's proposal (sprint supervisor, run-20260920T222013Z).
