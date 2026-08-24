---
id: "0034"
title: Give a complete-but-unclosable verify verdict somewhere durable
type: feature
next: design
status: ready
qa_level: verify
size: m
created: 2026-08-23
source: agent
expects:
  - skills/verify/SKILL.md
  - skills/queue/templates/item.md
claimed_by:
claimed_at:
touches:
---

## Problem

`verify` Step 2 labels a run **advisory** when the working tree carries changes outside the ticket,
and Step 7 forbids an advisory PASS from closing. The row returns to `next: verify, status: ready`
carrying **no record that the pass ran at all**.

On 0024 that cost a full re-run: 21 assertions, six mutations and a tree-wide grep, to reach a
verdict that had already been reached. And that pass was not luck — every AC was checked against
**both** the committed and the working-tree copy of every file it rested on, precisely so the dirty
tree could not change the answer. The only thing that actually had to change was a tree nobody in
the pass controlled.

So "advisory" currently conflates two different states:

- *green may be luck* — the run touched files another session is mid-editing, and a different tree
  could give a different answer;
- *green survived both states* — the run was checked against committed and working copies and the
  dirty paths provably cannot affect it.

The second deserves either a close or a durable record. The first deserves neither.

## Open design question

- **Question:** when a `verify` pass completes and its verdict is provably independent of the
  unrelated dirty paths, what happens — does it close, or does it bank a durable verdict the next
  session can accept without re-running?
- **Why it blocks specification:** the acceptance criteria differ completely between the two
  answers. "It closes" needs criteria about *what makes independence provable* and what the close
  commit contains. "It banks" needs a record location, a staleness rule for when the bank expires
  (a later commit to a file the verdict rested on must invalidate it), and criteria for what the
  next session is allowed to skip. Writing either set before the question is settled invents a
  contract.
- **Settle it with:** `/design` — this is a decision about the protocol's trust model, not
  something to look at.

Sub-questions the decision has to answer:

1. Is *provably independent* checkable by a rule a session can follow, or is it a judgement? If it
   is a judgement, banking it hands the next session someone else's judgement, which is what the
   separate QA pass exists to avoid.
2. `CONCURRENCY.md` says a verdict travelling between sessions has nowhere to travel once each
   skill runs alone — that is why `verify` closes rather than `develop`. A banked verdict
   reintroduces exactly that travel. Does the reasoning still hold when the verdict is written to
   the item rather than carried in a conversation?
3. What invalidates a banked verdict? At minimum, any commit touching a file an AC rested on. That
   implies recording *which* files, which the pass knows and currently discards.
4. Does this collapse into "the tree should be clean before QA runs", making the whole state a
   scheduling problem rather than a protocol one?

## Functional requirements

*Written once the design question is answered. The problem statement and the four sub-questions
above are the input; do not build against a guessed answer.*

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | Whichever way this goes, the reasoning is recorded — a future session will meet the same advisory state and needs to know this was decided rather than overlooked | `documentation-conventions.md` |

## Acceptance criteria

*Blocked on the design question. Deliberately empty rather than guessed — `verify` refuses a ticket
with invented criteria, and `queue` routes to `design` exactly so this is not filled in by the
session about to build it.*

## QA plan

- **Level:** verify — the outcome will be prose in `verify` and possibly a field in the item
  template, with no runner behind either.
- **Why this level:** to be re-confirmed once the design lands; if the answer adds a field with
  parsing behind it, the level moves up.
- **Specific checks:** to be written with the ACs.

## Out of scope

- Changing when a run is labelled advisory in the first place. Step 2's trigger is not in question.
- Anything that would have `verify` tidy a dirty tree. Destroying another session's work to get a
  clean verdict is forbidden and stays forbidden.

## Notes & decisions

- Recorded 2026-08-23 from the retro. Aaron's read of the finding was that this might be `verify`
  failing to write its findings to the ticket; it is not — `verify` does write its verdict on red
  and on stale-contract. The gap is specifically the **advisory PASS**, which writes nothing because
  no field exists for "ran completely, passed, could not close".
