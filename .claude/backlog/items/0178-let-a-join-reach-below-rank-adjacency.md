---
id: "0178"
title: Let a join reach below rank adjacency, and bound the gate by something other than rank
type: bug
next: design
status: ready
qa_level: unit
close_by: verify
size: l
created: 2026-09-21
source: user
parent:
blocked_by: []
relates: ["0158", "0174", "0130", "0136", "0154"]
expects:
  - skills/queue/templates/next
  - .claude/backlog/next
  - tests/next.test.sh
  - skills/sprint/SKILL.md
  - skills/develop/SKILL.md
  - tests/sprint.test.sh
  - tests/batching.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

**A develop gate stops at the first row that does not join, and that is the wrong bound.** Since
`0158` closed on 2026-09-21, `gate_contiguous` in `skills/queue/templates/next` walks down from the
lead and ends the gate at the first pool row that neither joins nor is one the rank walk would step
over. So a row that shares the lead's file scope but sits below an unrelated row is excluded from the
session that is about to edit exactly its files, and is later worked in a session of its own.

**The user's correction, stated 2026-09-21:**

> Rank adjacency should PRIORITISE rows into a gate, not LIMIT which rows may join one. Where the
> most cost-efficient way to make a high-quality change includes a lower-ranked row that shares the
> file scope, including it is correct. Every ticket has to get done eventually, so pulling one
> forward into a gate it shares files with costs nothing and saves a session floor.

Two halves of the rank rule survive the correction unchanged, and they are what stops this becoming
`gate_from`'s old free-for-all:

- **Rank still decides which gate leads.** The lead is the topmost takeable row, always.
- **Rank still forbids leaving a takeable higher-ranked row unstarted while work proceeds below
  it.** That is a property of the *lead*, not of the gate's membership, which is why admitting a
  lower-ranked joiner does not violate it.

What the correction costs is the bound. Contiguity was doing two jobs at once in `0158` — keeping
selection honest, and keeping a gate small enough to dispatch — and only the first was the rule.
Removed with nothing in its place, `gate_contiguous` degenerates to `gate_from`, and `0158`'s own
evidence is what that produced: from rank-1 `0151` a gate of 45 rows, spanning ranks 1 to 97, held
together by `skills/sprint/SKILL.md`. The user has separately called ten rows joining through one
`SKILL.md` a grouping artefact rather than a theme (`skills/sprint/SKILL.md`, the proposal
section). A 45-row gate is also unrunnable against `config.yml`'s `stage_budget_usd`: at
`develop: 6.05` plus `per_extra_ticket.develop: 4.03` it prices at about USD 183 for one session.

### What this does to 0158

This item **supersedes `0158` FR1, FR2 and FR4** — the contiguity bound on new gates, its
application at every new-gate site, and the two prose sentences asserting it. It **keeps `0158`
FR3**: `verify_batch` recovers a membership already fixed and stays unbounded in rank, and it keeps
`0158`'s underlying finding that selection must not follow a join. Nothing here reopens what counts
as a join (shared `expects:` path or shared `parent:`).

The two rules must not be left standing together. Today four places assert contiguity and cite
`0158`: the comment above `gate_contiguous`, `skills/sprint/SKILL.md`'s proposal section, that
file's *dispatch unit is a gate* paragraph, and `skills/develop/SKILL.md`'s gate definition.

## Functional requirements

These four are settled by the user's rule and do not wait on the design question below. The bound
and the prioritisation are FR5, and `design` writes it.

- FR1 — The lead of every new develop gate is the topmost takeable row. Unchanged in behaviour, and
  stated as its own requirement because it is the half of the rank rule that survives: no gate is
  dispatched while a takeable row ranked above its lead is unstarted.
- FR2 — A pool row that joins the accumulating gate scope is admissible **however many non-joining
  rows separate it from the lead**. Implemented in `skills/queue/templates/next` and its
  byte-identical copy `.claude/backlog/next`. This is the removal of `gate_contiguous`'s two
  terminating `return 0` arms as the gate's bound; whether the function survives at all is FR5's.
- FR3 — `verify_batch` is unaffected, and the two builders still differ on rank alone (`gate_admits`
  stays the single definition of a join).
- FR4 — The prose says the new rule once each, and no surviving sentence asserts the old one:
  `skills/sprint/SKILL.md`'s proposal section and its *dispatch unit is a gate* paragraph,
  `skills/develop/SKILL.md`'s gate definition, and the comment above the gate builder in
  `skills/queue/templates/next`. Each cites this item rather than `0158` for the bound, and `0158`'s
  item file gains a dated line naming which of its FRs this supersedes.
- FR5 — **Pending the design question.** What bounds a gate's membership, and how rank adjacency
  orders the candidates within that bound. Implemented at every new-gate site `0158` FR2 enumerates:
  the rank walk's `develop` arm, the `design`-row proposal arm, and `depth_line`'s gate count.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Documentation | The change leaves exactly one rule standing in the four places that assert a gate's rank bound, and `0158` records that part of it was superseded rather than reversed by drift | FR4's guards in `tests/sprint.test.sh` and `tests/next.test.sh`; the `0158` note is prose only — no artifact yet | `documentation-conventions.md` |
| Dependencies | No new one; the gate builder stays POSIX `sh` in the two `next` copies | `tests/backlog-scripts-installed.test.sh` reds if the copies diverge | `dependency-conventions.md` |

## Open design question  *(only while `next: design`)*

- **Question:** Now that a join may reach below rank adjacency, what bounds a develop gate's
  membership, and how does rank adjacency prioritise which joining rows get in? Candidate answers to
  decide between, not a topic: a row cap in `config.yml`; a bound derived from
  `stage_budget_usd` + `per_extra_ticket` so a gate cannot price above the cap it will be dispatched
  under; a bound on how much of the gate a single shared path may explain, which is the
  grouping-artefact case the proposal section already names; nearest-in-rank-first admission up to
  whichever of those applies; or some composition of them.
- **Why it blocks specification:** every acceptance criterion here states a gate's membership on a
  fixture queue, and without the bound there is no membership to assert. Concretely, `0158` AC1's
  own fixture (`0101 a/x.md`, `0102 b/y.md`, `0103 a/x.md`) has two defensible answers under the new
  rule — `0101 0103`, and `0101 0103` only if the bound admits it — and the 45-row gate `0158` was
  filed on has no answer at all until this is settled. FR5 cannot be written; FR1–FR4 can and are
  above.
- **Settle it with:** `/design`. The answer is reasoned from `config.yml`'s cost model and the
  measured startup floor, not looked at; nothing here has a surface.

## Acceptance criteria

Written by `design`, which has FR5 to specify first. FR1–FR4 are the criteria that can already be
drafted and `design` should carry them through rather than re-derive them:

- FR1 — a fixture where the topmost takeable row does not join anything below it dispatches that row
  alone, and a fixture where it does still leads with it.
- FR2 — `0158` AC1's fixture (`0101 a/x.md`, `0102 b/y.md`, `0103 a/x.md`, all develop ready) is the
  discriminating case: today it prints `DISPATCH  develop 0101`, and under the new rule `0103` joins.
  **That case is `0158` AC1 inverted and the existing guard asserting `0101` alone must be amended,
  not left**; the same holds for `0158` AC4 (a `verify` row between two joined develop rows) and
  AC5's `DEPTH     3 develop gate(s)`, which the new rule makes `2`.
- FR3 — `0158` AC6's verify-batch case stays green unchanged.
- FR4 — a phrase guard per file, each matched within one line (`CLAUDE.md`, *rewrapping a guarded
  paragraph is a breaking change*).

## QA plan

- **Why that level:** `next` is a POSIX `sh` script with fixture-driven cases in `tests/next.test.sh`;
  `config.yml`'s `commands.unit` runs every `tests/*.test.sh`. The prose half is greppable in the same
  suite, so nothing here needs `verify` or `review`.
- **Specific checks:** the FR1–FR3 fixtures in `tests/next.test.sh`; FR4's phrase guards in
  `tests/sprint.test.sh`; `tests/backlog-scripts-installed.test.sh` for the two `next` copies;
  `tests/batching.test.sh`, whose window extraction ends on the blank line after `develop`'s gate
  paragraph and which `0158` recorded as sensitive to that paragraph growing; `tests/citations.test.sh`
  for the re-pointed `0158` citations.
- **Mutation note:** `tests/next.test.sh` is 485 cases and runs past a tool timeout on a loaded host.
  Redirect to a file and poll it; do not pipe (`config.yml`, `commands`).
- **Absence assertions:** FR4 removes phrases two `0158` guards currently require
  (`never selection` in both skills, and the contiguity sentences). Those guards are the ones being
  amended — say so in the build note rather than choosing between this ticket and them.

## Out of scope

- What counts as a join. Shared `expects:` path or shared `parent:`, unchanged.
- `verify_batch`'s membership rule (`0158` FR3, kept).
- Whether a ready `design` row is dispatched rather than escalated (`0159`).
- How a proposal presents a gate to a person — that is `0130`'s, and it reads whatever this produces.
- Re-ranking the queue so that today's contiguous bound batches more rows. Done separately on
  2026-09-21 in the same sweep as this capture, and it is a re-rank rather than a requirement here.

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

## Notes & decisions

- **2026-09-21 — filed by `queue` on the user's stated correction.** Routed to **`design`, not
  `develop`**, and this is the part worth arguing with. The *rule* is decided and needs no design
  pass: rank selects the lead, a join batches, and a joining row below the first non-joining row is
  admissible. What is not decided is the bound. `0158`'s contiguity was load-bearing twice over, and
  the user's correction names only one of the two loads; removing it outright restores a 45-row,
  USD-183 gate that `0158`, `0130` and the proposal section's grouping-artefact rule all exist
  because of. No acceptance criterion can state a gate's membership until something says how far a
  join may reach, so the design trigger is met exactly as `queue` defines it — a decision blocking
  the writing of criteria, not unfamiliarity.
- **FR1–FR4 are written here rather than left for `design`** because they follow from the user's rule
  alone, and a `design` pass that has to re-derive them pays for the reading twice.
- **This supersedes `0158` FR1/FR2/FR4 and keeps FR3.** Said here rather than left implicit so two
  rules are not standing: `0158`'s finding (selection must not follow a join) is upheld, and its
  *mechanism* (contiguity) is what is being replaced.
