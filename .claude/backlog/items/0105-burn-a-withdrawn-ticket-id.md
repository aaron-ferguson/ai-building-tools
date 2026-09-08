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

- 2026-09-08 — **The Problem section is wrong on a material point, and git is the only thing that
  could say so.** It states the first `0104` "landed 2026-09-05 at commit `b9a5ee0`" as an issued id.
  `git log --all --diff-filter=A -- '.claude/backlog/items/0104-*'` returns exactly ONE addition —
  `7764732`, the withdrawn in-window-verify ticket — and `git log -S'| 0104 |'` finds no other row.
  `b9a5ee0` is a `retro` landing that touched no backlog file at all: no row, no item file, no id
  claim. The five citations therefore named an id that **no ticket held when they were written**,
  and which was afterwards issued to unrelated work. That is worse than the ticket describes, and
  it is not reachable by `develop` Step 2's grep — a grep answers "does this still exist", and the
  claim here was about what once did. For a ticket asserting an id's history, `git log --diff-filter=A`
  over `items/<id>-*` is the check.
- 2026-09-08 — **AC3 and *Out of scope* cannot both be satisfied, and the resolution is FR2's own
  mechanism.** AC3 wants the guard red on the five live citations; Step 5 wants a green tree; *Out
  of scope* forbids rewriting them and then, in its next sentence, calls what they should say "the
  claiming session's call". Taking the second sentence: the citations were repointed at `b9a5ee0`,
  the commit that actually landed the work, which resolves permanently in git and cannot be
  reissued. AC3's live red was observed first and is reproducible — `perl -pi -e 's/b9a5ee0 AC1/0404
  AC1/' tests/retro-tool-edit.test.sh` reds the shipped-tree case naming the file and the id.
- 2026-09-08 — **A tombstone item file was considered for 0104 and rejected.** It would have made
  the citations resolve without touching them, satisfying *Out of scope* literally — but they would
  then have resolved to the **withdrawn in-window-verify ticket**, which is different work. That is
  precisely the silent re-pointing this ticket exists to prevent, arriving through the fix.
- 2026-09-08 — **The guard's first run reported three unresolved citations, not two: the third was
  its own source.** `tests/` is covered, so `tests/citations.test.sh` is covered, so a fixture id
  written there in an anchored form is a real citation of an unissued id. Anchoring spares the
  fixture TREE and not the source that authors it. Fixed with `UNISSUED=0404`, so the literal never
  appears anchored in a covered file; the header says why.
- 2026-09-08 — **FR3's scope was deliberately widened from `tests/` to `cited_files()` plus
  `tests/`.** Probed first: repo-wide the same matcher finds 59 citations and the same single
  unresolved id, so the widening cost nothing and covers the skills and references where an id is
  just as citable. Reusing `cited_files()` also keeps the set derived rather than enumerated.
- 2026-09-08 — **`measurement.test.sh` is red on a privacy NFR that is not this ticket's.** Three
  files publish a home-directory path: `FINDINGS.md:74`, `items/0060:81`, `items/0111:29`, last
  written by `bb9a16c` and `b9d11af`. Reproduced at base commit `0f73d4e` in a throwaway worktree,
  so it pre-dates this work. Left alone; it still needs a row.

- 2026-09-07 — Filed by `retro` from `FINDINGS.md`. The ID burn was executed by that retro (see
  Problem); the counter now stands at 111 with 0104 unissued. Verified before filing: `next_id: 104`,
  `0104` absent from `QUEUE.md` and `DONE.md`, no `items/0104-*`, five citations in two test files.
