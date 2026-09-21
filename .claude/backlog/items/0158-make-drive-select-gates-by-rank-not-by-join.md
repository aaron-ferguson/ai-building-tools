---
id: "0158"
title: Make --drive select a gate by rank, and let a join decide only batching
type: bug
next: verify
status: in-progress
qa_level: unit
close_by: verify
size: m
created: 2026-09-13
source: user
parent:
blocked_by: []
relates: ["0136", "0130", "0154", "0159"]
expects:
  - skills/queue/templates/next
  - .claude/backlog/next
  - tests/next.test.sh
  - tests/batching.test.sh
  - skills/develop/SKILL.md
  - skills/sprint/SKILL.md
claimed_by: "6640"
claimed_at: 2026-09-21T02:04:58Z
touches:
---

## Problem

**A driven sprint takes low-ranked work ahead of the rows directly below rank 1**, because a gate
is assembled by file or parent join over the *whole* takeable develop pool.

Parked from run-20260913T034946Z, verbatim:

> `--drive --propose` selects a gate by file join, not by queue rank. From rank-1 0151 it pulled
> rank 94–97 rows 0152–0154 (they share `skills/sprint/SKILL.md` and `tests/sprint.test.sh`) plus 41
> others, while ranks 2–93 (0110, and design rows 0145/0146/0139) were jumped; the supervisor then
> offered a theme subset. A join should decide batching, never selection over rank.

The mechanism is `gate_from` in `skills/queue/templates/next`. It walks every id in
`takeable_develop` in rank order and admits any row whose `expects:` overlaps the gate's accumulated
scope, or whose `parent:` matches the lead's. It does that **however many takeable rows it has passed
over to get there**. The rank walk picks the right lead, and the gate then carries rows the rank
says come later.

**The user's rule:** selection respects queue rank. A join may put two *adjacent-in-rank* rows into
one session; it may never promote a row over a takeable row ranked above it.

## Functional requirements

- FR1 — `gate_from` extends a gate only through rank-contiguous rows. Walking down from the lead:
  a row that joins is admitted; a row the rank walk steps over (`in-progress`, an open blocker, held
  by a claim) is passed without stopping; and **the first other row that does not join ends the
  gate**, whatever its stage (`develop`, `verify`, `design`, `queue`) or status (`ready`, `waiting`).
  Implemented in `skills/queue/templates/next` and its byte-identical copy `.claude/backlog/next`.
- FR2 — The same contiguous rule forms every *new* develop gate: the rank walk's `develop` arm, the
  `design`-row proposal arm (0154 FR3, while it exists) and `depth_line`'s gate count.
- FR3 — `verify_batch`, which recovers the membership of a gate **already developed**, is not
  narrowed by FR1: a gate built as `0101 0103` still verifies as one batch when an undeveloped row
  ranks between them.
- FR4 — `skills/develop/SKILL.md`'s gate definition and `skills/sprint/SKILL.md`'s proposal section
  each state that a join decides batching and never selection, in one sentence each.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Documentation | The comment above `gate_from` states the contiguity bound beside the two bounds it already names, so the next editor does not widen it back | AC1 reds if the bound is removed from code; the comment itself is prose only — no artifact yet | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given a fixture queue `0101 develop ready expects a/x.md`, `0102 develop ready expects
  b/y.md`, `0103 develop ready expects a/x.md`, when `next --drive` runs, then it prints
  `DISPATCH  develop 0101` and that line does not contain `0103`. Red: today's template prints
  `DISPATCH  develop 0101 0103`.
- [ ] AC2 — Given `0101 a/x.md`, `0102 a/x.md`, `0103 b/y.md`, all develop ready, when `next --drive`
  runs, then it prints `DISPATCH  develop 0101 0102`. Red: a stop rule that ends the gate at the
  lead regardless of join.
- [ ] AC3 — Given `0101 a/x.md` ready, `0102 b/y.md` develop ready with `blocked_by: ["0104"]` open,
  `0103 a/x.md` ready, when `next --drive` runs, then it prints `DISPATCH  develop 0101 0103`. Red: a
  stop rule that ends the gate at a row the rank walk steps over.
- [ ] AC4 — Given `0101 develop a/x.md`, `0102 verify ready c/z.md` not built by this run, `0103
  develop a/x.md`, when `next --drive` runs, then the dispatch line is `DISPATCH  develop 0101` with
  no `0103`. Red: a stop rule that only considers develop rows.
- [ ] AC5 — Given the AC1 fixture, when `next --drive` runs, then it prints `DEPTH     3 develop
  gate(s)`. Red: today's template prints `DEPTH     2`.
- [ ] AC6 — Given a gate developed as `0101 0103` with `0102 develop ready` ranked between them, both
  now `next: verify, status: ready`, when `next --drive` runs with the started-set form the 0132
  cases use, then it prints `DISPATCH  verify 0101 0103`. Red: FR1's rule applied inside
  `verify_batch`.
- [ ] AC7 — Given `skills/develop/SKILL.md` and `skills/sprint/SKILL.md`, when `tests/sprint.test.sh`
  runs, then each contains the phrase `never selection` on one line. Red: either sentence removed.

## QA plan

- **Why that level:** `next` is a shell script with fixture-driven cases in `tests/next.test.sh`;
  `commands.unit` runs them all.
- **Specific checks:** the AC1–AC6 cases in `tests/next.test.sh`; AC7 in `tests/sprint.test.sh`;
  `tests/backlog-scripts-installed.test.sh` for the copy; every existing 0130/0136 gate case still
  green, amended only where its fixture relied on a join across an unjoined row (say which in the
  notes).

## Out of scope

- Whether a ready `design` row is dispatched rather than escalated — that is 0159. This ticket only
  requires that such a row *ends* a gate below it.
- Changing what counts as a join (shared `expects:` path or shared `parent:`).
- Theme subsets a supervisor offers at proposal time.

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

## Notes & decisions

- **2026-09-13 — filed by a `queue` sweep of FINDINGS.md** (run-20260913T034946Z). Routed to
  `develop`: the user stated the rule (rank selects, a join batches), so no decision is open; the
  code is `gate_from` and the contract is its output on a fixture queue.
- **Why the stop is "any row the walk would not step over", not "any takeable develop row".** The
  rank walk steps over exactly `in-progress`, open-blocker and held rows; everything else either
  dispatches or stops the run. Using the walk's own set means the gate cannot jump anything the walk
  itself would not have jumped, including a waiting or design row below the lead.
- **AC6 exists because `verify_batch` calls `gate_from`** to recover a developed gate's membership.
  Applying contiguity there would split a verify batch around rows that were never part of it.

- **2026-09-20 (develop, b040) — `gate_from` is kept and a second builder added, rather than a flag
  on one function.** `verify_batch` (FR3) needs the unbounded join and every new-gate site needs the
  bounded one, so the difference is a different question, not a parameter. The join test itself is
  factored into `gate_admits`, shared by both, so the two can only ever differ on rank.
- **The stop set is `walk_steps_over`, mirroring the rank walk's three `continue` arms** —
  in-progress, an open blocker, held. Written as its own function so a future arm added to the walk
  has one obvious place to be mirrored; nothing asserts the two stay in step, which is a real gap
  and the cheapest guard for it would be a fixture per arm (AC3 covers the blocker arm only).
- **`tests/batching.test.sh` was in `expects:` and is not in `touches:`.** FR4's sentences went in as
  their own paragraph beside develop's gate paragraph rather than inside it, so that file's window
  extraction is untouched — its window ends on the paragraph's blank line, and growing the guarded
  paragraph would have moved every assertion scoped to it.
- **No existing gate case needed amending** (the QA plan asked which). All 443 `next.test.sh` cases
  were green on the new rule unchanged: 0136 AC1's chain and 0130's six-row propose fixture are both
  already rank-contiguous, so contiguity was invisible to them.
- **AC3's fixture needed `blocked` in the Status column, not `ready`.** An open `blocked_by` over a
  `ready` column is drift, and `--drive` routes drift to exit 4 ahead of any dispatch — so the first
  draft of that case measured the drift reporter rather than the gate.
- **AC7's two guards are pinned by uniqueness, checked not mutated**: `grep -cF 'never selection'`
  is 1 in each file, so deleting either sentence reds. Reasoned, not run.
