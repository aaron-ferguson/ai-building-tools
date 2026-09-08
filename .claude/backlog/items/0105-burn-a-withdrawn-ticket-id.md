---
id: "0105"
title: Burn a withdrawn ticket's ID, and make an item-ID citation resolvable
type: bug
next: develop
status: in-progress
qa_level: unit
qa_manual:
size: s
created: 2026-09-07
source: agent
parent:
blocked_by: []
relates: []
expects:
  - .claude/backlog/config.yml       # the counter, and the comment that documents it as monotonic
  - skills/queue/SKILL.md            # the withdrawal path that currently recycles
  - tests/citations.test.sh          # where an item-ID citation check belongs
claimed_by: "61a6"
claimed_at: 2026-09-08T14:25:41Z
touches:
  - .claude/backlog/config.yml
  - skills/queue/SKILL.md
  - skills/queue/templates/item.md
  - tests/citations.test.sh
  - tests/retro-tool-edit.test.sh
  - tests/skill-size.test.sh
---
## Problem

**Ticket ID `0104` has been issued to two different tickets and was about to be issued to a third.**

The first `0104` — *"Give every findings entry a terminal disposition"* — landed 2026-09-05 at
commit `b9a5ee0` and is cited by ID in five places across two guards: four `0104 AC*` case labels
in `tests/retro-tool-edit.test.sh:118-146`, and the recorded over-goal justification for
`skills/retro/SKILL.md` in `tests/skill-size.test.sh:91`. Its row is in **neither** `QUEUE.md` nor
`DONE.md`, and no `items/0104-*.md` exists — so all five citations already resolve to nothing.

The ID was then reissued to *"verify in-window fix for test-side-only reds"* and withdrawn at
`3b72d38`, which deleted that item **and reset `next_id` from 105 back to 104**. A third issue was
therefore queued up, at which point those five citations would have silently started pointing at an
unrelated ticket. `config.yml`'s own comment documents `next_id` as **monotonic**, and the
withdrawal path breaks that invariant while looking like tidy-up.

`CONVENTIONS_CORE.md` names stable identifiers among the decisions that cannot be retrofitted once
anything cites one. Five things cite this one.

**The 2026-09-07 retro burned `0104`** — it set `next_id` to 111 and issued 0105-0110, so the ID is
now permanently unissued and the five citations resolve to nothing *durably* rather than
re-pointing. That removes the urgency and none of the defect: the withdrawal path is unchanged.

## Functional requirements

- **FR1** — Withdrawing a ticket never decreases `next_id`. The ID is burned, not recycled.
- **FR2** — A withdrawal leaves a record that the ID was issued and withdrawn, so a citation to it
  resolves to *that* rather than to nothing.
- **FR3** — A guard checks every item-ID citation in `tests/` against the union of `QUEUE.md`,
  `DONE.md` and `items/`, and reds on one that resolves to nothing. `tests/citations.test.sh` is
  the existing home for citation checking.
- **FR4** — `queue`'s withdrawal path states FR1 and FR2 and says why, naming the stable-identifier
  rule it is holding.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | `config.yml`'s `next_id` comment says the counter only ever rises, and what a withdrawal does instead | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given a withdrawal, when it completes, then `next_id` is unchanged or higher, never lower.
- [ ] AC2 — Given a citation in `tests/` naming an item ID that is in neither table nor `items/`,
  when the citation guard runs, then it reds and names the ID and the citing file.
- [ ] AC3 — Given the five existing `0104` citations, when the guard runs, then it reds on them —
  proving the guard sees the live instance rather than a fixture only.
- [ ] AC4 — Given the guard, when a fixture citing a resolvable ID is checked, then it passes, so
  the guard is not green-by-filter.
- [ ] AC5 — Deleting the burn sentence from `queue`'s withdrawal path turns a guard red.

## QA plan

- **Level:** unit — this repo's whole suite, run per-file for attribution per `config.yml`.
- **Why this level:** the deliverable is a shell guard plus prose, which is what this suite tests.
- **Specific checks:** run the new citation case; then mutate — point a fixture citation at a
  burned ID, confirm red and that the message names both the ID and the file; restore and confirm
  green. Count the asserted phrase **within the guard's own scope** before trusting it, per
  `testing-conventions.md`.

## Out of scope

- Renumbering or re-homing the first `0104`'s work. It shipped; only its ID is unresolvable.
- Rewriting the five existing citations. FR3's guard is what makes them visible; deciding what each
  should say instead is the claiming session's call, informed by the guard's output.

## Notes & decisions

- 2026-09-07 — Filed by `retro` from `FINDINGS.md`. The ID burn was executed by that retro (see
  Problem); the counter now stands at 111 with 0104 unissued. Verified before filing: `next_id: 104`,
  `0104` absent from `QUEUE.md` and `DONE.md`, no `items/0104-*`, five citations in two test files.
