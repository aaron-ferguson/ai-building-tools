---
id: "0099"
title: Return RANKING.md to current state only
type: debt
next: develop
status: ready
qa_level: unit
size: s
created: 2026-09-05
source: agent
parent:
blocked_by: []
relates: []
expects:
  - .claude/backlog/RANKING.md
  - .claude/backlog/RANKING-HISTORY.md
  - skills/queue/templates/RANKING.md
claimed_by:
claimed_at:
touches:
---

## Problem

`RANKING.md`'s own header says **"Current state only"** and points the dated narrative at
`RANKING-HISTORY.md`, splitting the two the way `CONCURRENCY.md` splits from
`CONCURRENCY-INCIDENTS.md`. The file is accumulating dated sections anyway: three of them sit below
the table — `## 2026-08-26`, `## 2026-09-01` and `## 2026-09-02` — and one had to be marked
superseded the same day it was written.

The consequence is not tidiness. The count in *The shape of this backlog* reads **"Twenty-six of the
thirty-six rows"** against a queue that has since grown well past it, and the buffer that section says is
"empty as of 2026-08-25" is not. A file that mixes current state with history gets read as neither,
and this one is read at exactly the moment its numbers are load-bearing — a re-rank.

## Functional requirements

- FR1 — The three dated sections move to `RANKING-HISTORY.md`, keeping their headings, so the
  `Full argument` column of the current-state table still resolves.
- FR2 — Every count and every claim about the present in `RANKING.md` is recomputed against the
  queue as it stands, including *The shape of this backlog* and *What would change the order*'s
  statement about the findings buffer.
- FR3 — A count in `RANKING.md` that a later session must keep true is either removed or stated so
  that it cannot silently rot — a derived number belongs in `./next`, not in prose.
- FR4 — A guard asserts the split: `RANKING.md` carries no dated `##` section heading, which is what
  its header already promises. This is the code behind FR1; without it the file re-accumulates,
  which is what happened after the split was first made.
- FR5 — `skills/queue/templates/RANKING.md`, the seeded copy every scaffolded backlog gets, states
  the same rule, so a new project starts with the split rather than rediscovering it.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The moved sections keep their headings verbatim, since `RANKING.md`'s table cites them by name and a renamed heading breaks every citation | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given `.claude/backlog/RANKING.md`, when its `##` headings are listed, then none begins
  with a date. Red-making input: today's file, which has three.
- [ ] AC2 — Given `.claude/backlog/RANKING-HISTORY.md`, when it is searched for each of the three
  moved headings, then all three are found. Red-making mutation: moving two and dropping the third,
  which leaves a `Full argument` citation resolving to nothing.
- [ ] AC3 — Given `RANKING.md`'s *The shape of this backlog*, when its row count is compared against
  the number of table rows in `QUEUE.md`, then they agree. Red-making input: today's file, whose
  "thirty-six" has not matched `QUEUE.md` since 2026-09-01.
- [ ] AC4 — Given FR4's guard, when a heading `## 2026-09-06 — a note` is added to `RANKING.md`, then
  the guard fails and names the heading. Red if it passes.
- [ ] AC5 — Given `skills/queue/templates/RANKING.md`, when its header is read, then it states the
  current-state-only rule. Red-making mutation: deleting the sentence, which reddens the guard
  asserting the template carries it.
- [ ] AC6 — Given `RANKING.md`'s table after the change, when each `Full argument` citation is
  resolved against `RANKING-HISTORY.md`, then every one is found. Red if any names a heading that
  exists in neither file.

## QA plan

- **Why that level:** the deliverable is a file split plus a guard; the runner is the suite.
- **Specific checks:** FR4's guard, then the whole suite file-by-file. AC6 is the expensive one and
  the one worth doing by hand: resolve every citation in the table rather than sampling.

## Out of scope

- Re-ranking anything. This item moves prose and corrects counts; the order does not change, and a
  diff to `QUEUE.md` is this ticket exceeding its answer.
- `RANKING-HISTORY.md`'s own structure, which is the narrative file and is allowed to be long.

## Notes & decisions

- Routed to `develop`: the split is already decided and stated in the file's own header. What is
  missing is that nothing enforces it, which FR4 supplies.
- FR3 is the reason this is worth doing at all rather than just editing the number: a hand-maintained
  count in a file read once a week is a fact that is wrong most of the time.
