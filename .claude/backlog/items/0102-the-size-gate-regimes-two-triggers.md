---
id: "0102"
title: Decide what happens when the size-gate regime's two deferred triggers fire
type: debt
next: design
status: ready
qa_level: verify
size: s
created: 2026-09-05
source: agent
parent:
blocked_by: []
relates: ["0028", "0043"]
expects:
  - tests/skill-size.test.sh
  - tests/reference-size.test.sh
  - references/TRACKER.md
claimed_by:
claimed_at:
touches:
---

## Problem

`0028` replaced the reference files' hard ceiling with a soft goal and a gate, and deliberately
deferred two things. Both are now close enough to fire that they will be met by whoever happens to
be editing something else, at a red, with no reason recorded.

1. **`references/TRACKER.md` is 6,022 bytes against a `GOAL` of 6,057** (`reference-size.test.sh:42`)
   — **35 bytes under**. The next sentence added to it reds the gate under whatever unrelated ticket
   is open at the time. That is the gate doing its job, not a defect. But it means a third reference
   file is about to need either a relocation or a recorded justification, and the choice is better
   made deliberately than at a red by an author mid-way through something else.

2. **`tests/reference-size.test.sh` is the second copy of the `offenders` / `pad` / `ok` / `bad`
   shape**, `tests/skill-size.test.sh` being the first. `coding-conventions.md`'s Tier-2 rule fires
   on the **third** instance, so `0028`'s *Out of scope* ruling — *"duplicating ~40 lines of `sh` is
   acceptable here"* — is right today and expires the moment a third prose directory earns a goal.
   The two copies have already diverged in one way worth keeping: the reference gate carries an AC7
   grep the skill gate has no equivalent of. So the extraction is not a pure lift.

## Open design question

- **Question 1:** when `TRACKER.md` next exceeds the goal, does it relocate content, take a recorded
  justification, or does the goal move — and which of the three is the *default* the gate's message
  should recommend for a file in its position?
- **Question 2:** does the shared `offenders`/`pad`/`ok`/`bad` shape get extracted now, at two
  copies, or does the Tier-2 trigger stand and the extraction wait for a third — and if it is
  extracted, what happens to the divergence the reference gate has earned?
- **Why it blocks specification:** no acceptance criterion can be written for either. Question 1's
  criterion is a statement about what the gate should say and what `TRACKER.md` should become, and
  those are the same answer. Question 2's criterion is either "one helper exists and both gates use
  it" or "nothing moves and the ruling is re-recorded with its expiry" — opposite artifacts, and
  `0035` is the precedent that "nothing moves, and what ships is the test that says so" is a real
  outcome here.
- **Settle it with:** `/design`. The inputs are `0035`'s payback arithmetic, `0028`'s recorded
  ruling, and `coding-conventions.md`'s Tier-2 trigger — all readable. Nothing needs to be seen.

## Functional requirements

- FR1 — The answer to Question 1 is recorded in this item's *Notes & decisions*, and whatever the
  gate must say differently is stated as an FR the design pass adds.
- FR2 — The answer to Question 2 is recorded the same way, including what becomes of the reference
  gate's AC7 grep under an extraction.
- FR3 — Whichever way each goes, the ruling names its **expiry condition** — the observation that
  would reopen it — so the next session meeting it at a red can tell a live decision from a stale
  one. `0028`'s ruling lacked this, which is why it needed a findings entry to stay visible.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The ruling is recorded where the gate fires — in the guard's own justification mechanism — not only in this item, since a session meeting the red will not be reading the backlog | `documentation-conventions.md` |

## Acceptance criteria

*Written by the design pass, per `0028`'s precedent that "nothing moves and what ships is the test
that says so" is a permitted outcome. FR3 is the one criterion that holds either way: whatever is
decided carries an expiry condition.*

## Out of scope

- `0043`, which makes the two gates fail on a registry entry that no longer resolves. That is a
  defect in the gates; this is a decision about the regime they enforce.
- Adding a size gate to a third prose directory. If that becomes wanted, it is the event that fires
  Question 2's trigger, not part of answering it.
- `CLAUDE.md`, which no gate covers.

## Notes & decisions

- Routed to `design` on trigger 1 — a decision blocks writing acceptance criteria — and not on
  trigger 2; nothing here has a surface. Both questions were deferred by `0028` with the deferral
  recorded, so this is the deferral coming due rather than a new discovery.
- Filed as one ticket: both questions are `0028`'s regime, both are answered by the same reading of
  `0035` and `coding-conventions.md`, and answered separately two sessions would very likely give
  one regime two philosophies — which is the argument `0035` itself made for merging its own two
  sub-questions.
- Ranked Tier 5. Nothing is degrading; what is accruing is only the chance that the answer is given
  at a red by someone who did not intend to give it.
