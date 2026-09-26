---
id: "0158"
title: Make --drive select a gate by rank, and let a join decide only batching
type: bug
next:
status: done
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
claimed_by:
claimed_at:
touches:
closed: 2026-09-21
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

- [x] AC1 — Given a fixture queue `0101 develop ready expects a/x.md`, `0102 develop ready expects
  b/y.md`, `0103 develop ready expects a/x.md`, when `next --drive` runs, then it prints
  `DISPATCH  develop 0101` and that line does not contain `0103`. Red: today's template prints
  `DISPATCH  develop 0101 0103`.
- [x] AC2 — Given `0101 a/x.md`, `0102 a/x.md`, `0103 b/y.md`, all develop ready, when `next --drive`
  runs, then it prints `DISPATCH  develop 0101 0102`. Red: a stop rule that ends the gate at the
  lead regardless of join.
- [x] AC3 — Given `0101 a/x.md` ready, `0102 b/y.md` develop ready with `blocked_by: ["0104"]` open,
  `0103 a/x.md` ready, when `next --drive` runs, then it prints `DISPATCH  develop 0101 0103`. Red: a
  stop rule that ends the gate at a row the rank walk steps over.
- [x] AC4 — Given `0101 develop a/x.md`, `0102 verify ready c/z.md` not built by this run, `0103
  develop a/x.md`, when `next --drive` runs, then the dispatch line is `DISPATCH  develop 0101` with
  no `0103`. Red: a stop rule that only considers develop rows.
- [x] AC5 — Given the AC1 fixture, when `next --drive` runs, then it prints `DEPTH     3 develop
  gate(s)`. Red: today's template prints `DEPTH     2`.
- [x] AC6 — Given a gate developed as `0101 0103` with `0102 develop ready` ranked between them, both
  now `next: verify, status: ready`, when `next --drive` runs with the started-set form the 0132
  cases use, then it prints `DISPATCH  verify 0101 0103`. Red: FR1's rule applied inside
  `verify_batch`.
- [x] AC7 — Given `skills/develop/SKILL.md` and `skills/sprint/SKILL.md`, when `tests/sprint.test.sh`
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

**Verdict: PASS** — verify session 2026-09-20, token 6640.

Conventions: `../ai-building-conventions` (`config.yml` `conventions.path`; `CONVENTIONS_CORE.md`
plus `documentation-conventions.md`, `testing-conventions.md`).
Level `unit`, run as `config.yml`'s `commands.unit` in the reporting form that file prescribes:
`for t in tests/*.test.sh; do "$t" || true; done` — 31 files, every tally `0 failed`
(`tests/next.test.sh` 485 passed, `tests/sprint.test.sh` 257 passed,
`tests/batching.test.sh` 39 passed, `tests/backlog-scripts-installed.test.sh` 37 passed).
Copy executed: the repo copy `skills/queue/templates/next` (the harness and this session's
fixtures both run the template; `.claude/backlog/next` is held byte-equal by
`tests/backlog-scripts-installed.test.sh`).

| Criterion | How it was checked | Result |
|---|---|---|
| AC1 | Fresh fixture backlog (`0101 a/x.md`, `0102 b/y.md`, `0103 a/x.md`, all develop/ready) driven through `./next --drive`: `DISPATCH  develop 0101`, no `0103` | pass |
| AC2 | Fixture `0101 a/x.md`, `0102 a/x.md`, `0103 b/y.md`: `DISPATCH  develop 0101 0102` | pass |
| AC3 | Fixture with `0102` carrying an open `blocked_by: ["0104"]` and column `blocked`: `DISPATCH  develop 0101 0103` — the walk's step-over arm passed, not stopped | pass |
| AC4 | Fixture with `0102` at `verify ready` between the two joined develop rows: `DISPATCH  develop 0101` | pass |
| AC5 | AC1 fixture: `DEPTH     3 develop gate(s) takeable` | pass |
| AC6 | Fixture `0101`/`0103` at `verify ready` with `0102 develop ready` between, `--drive --started 0101 --started 0103 --completed develop:0101`: `DISPATCH  verify 0101 0103` — `verify_batch` not narrowed | pass |
| AC7 | `grep -n 'never selection'` hits `skills/develop/SKILL.md:53` and `skills/sprint/SKILL.md:136`; both guards in `tests/sprint.test.sh` | pass |
| NFR Documentation | The comment block above `gate_contiguous` (`skills/queue/templates/next`) states the contiguity bound and why the stop set is the walk's own, beside the two bounds named above `gate_from`. Checked against `documentation-conventions.md`; **unguarded by construction** — prose only, as the row itself declares | pass, unguarded |

**Mutations run** (committed tree, mutated, red confirmed, restored by path, control green):

1. `gate_contiguous`'s two `return 0` stops → `continue` (contiguity removed). AC1 fixture then
   printed `DISPATCH  develop 0101 0103` at `DEPTH     2`, AC4's fixture `DISPATCH  develop 0101
   0103`; `tests/next.test.sh` 482 passed, 3 failed — *the gate is the lead alone*, *the verify row
   ends the gate*, *counts three gates*. AC6 stayed green, which is FR3's point. Restored; control
   run reproduced AC1–AC6 exactly.
2. AC7's sentence reworded in both files (`A join decides batching and never selection` → `A join
   decides how rows batch together`). `tests/sprint.test.sh` 255 passed, 2 failed — both 0158 FR4
   guards. Restored; control 257 passed, 0 failed. **The build note recorded these two as
   "reasoned, not run"; they are now run.**

AC2 and AC3 do not redden under mutation 1 (they assert the gate still forms and still steps over
a passed row, which an unbounded builder also satisfies) — they are the complementary direction and
are pinned by their own fixtures above.

Dirty set at Step 2 and at verdict: `.claude/backlog/runs/` (untracked). Intersection with this
run's evidence set (`skills/queue/templates/next`, `skills/develop/SKILL.md`,
`skills/sprint/SKILL.md`, `tests/next.test.sh`, `tests/sprint.test.sh`) is empty — not advisory.

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

- **2026-09-21 (queue) - FR1, FR2 and FR4 of this item are SUPERSEDED by 0178; FR3 stands.** The
  user corrected the model the day this closed: rank adjacency should prioritise rows into a gate,
  not limit which rows may join one, so a joining row below the first non-joining row is admissible
  after all. What survives here is the finding - selection must never follow a join, the lead is
  always the topmost takeable row - and what is replaced is the mechanism, contiguity. 0178 carries
  the open question of what bounds a gate instead, since contiguity was also doing that job and the
  correction names only the other one. Read the two together; do not implement this item's FR1.
- **2026-09-26 — `0178` supersedes this item's FR1, FR2 and FR4, and keeps FR3.** A new develop
  gate is now bounded by `gate_max_rows` (default 5, `config.yml`), admitted nearest-in-rank first,
  instead of by rank contiguity; `gate_contiguous` and `walk_steps_over` are gone. FR3 stands:
  `verify_batch` still recovers membership with `gate_from`, unbounded. The finding stands too — the
  lead is the topmost takeable row and a join decides batching and never selection. This item's
  AC1, AC4 and AC5 cases in `tests/next.test.sh` were amended in place as `0178` AC2, AC3 and AC4.
