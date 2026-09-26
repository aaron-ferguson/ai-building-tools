---
id: "0188"
title: Plan a sprint from a develop-ready head, and keep design one sprint ahead of develop
type: feature
next: develop
status: ready
qa_level: unit
close_by: verify
size: l
created: 2026-09-25
source: retro
parent:
blocked_by: []
relates: ["0134", "0159", "0137", "0050"]
expects:
  - skills/sprint/SKILL.md
  - skills/queue/templates/next
  - tests/sprint.test.sh
  - tests/next.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

**A sprint opened on design work because the queue's top row sat at `next: design`, and the
sprint skill lets design run only beside `develop`. The user has stated a wider rule for both.**

In run-20260924T050130Z, `./next --drive --propose` offered a one-ticket design gate, because the
queue's top row was a design row. The user's rule (2026-09-24, recorded by that run's supervisor):

1. **A sprint is planned from the top row, and that row should be `develop ready`.** The gate takes
   every related ticket. Related tickets that still need design are designed in parallel within the
   same sprint and then built.
2. **The plan also looks at where the queue will stand after the sprint**, and designs the ticket or
   tickets that will head the *next* sprint, so design stays ahead of develop. This is the next
   sprint's head only, not every design row.
3. **Design is research, so it may run beside develop, verify, or another design session**, provided
   its files do not conflict with what the running sessions touch. The supervisor checks the design
   ticket's scope against the running sessions' files, and what accepting its outcome would change,
   before dispatching. Retro and queue always run alone.

Checked 2026-09-25: `skills/sprint/SKILL.md` *Design alongside develop* opens with "the one stage
that may run beside another, and only beside `develop`", and `tests/sprint.test.sh` guards that
section. The proposal section has no rule about where the queue will stand afterwards.

## Functional requirements

- **FR1** — The proposal is planned from the first `develop ready` row, and a design row above it
  is not the gate.
- **FR2** — The proposal names the design rows it will run in parallel: the gate's related tickets
  that need design, and the head of the next sprint.
- **FR3** — *Design alongside develop* is widened to develop, verify and design, under a stated
  file-conflict check. Retro and queue stay alone.
- **FR5** — `--drive` given `--scope` steps over a takeable `design` row the scope does not name,
  and dispatches every in-scope `design ready` row before any develop gate: design first, then build.
- **FR6** — The file-conflict check is one relation, enforced by `--drive`: a design row's
  `expects:` against a develop session's files. A design candidate that overlaps an in-progress
  develop row's `touches:` is stepped over; a develop gate whose `expects:` overlaps an in-progress
  design row's `expects:` is not dispatched, and `--drive` exits a new code `6` (**wait**) naming the
  design row. Design beside design or verify is never a conflict.
- **FR4** — Every guard that pins the old "only beside `develop`" wording is rewritten, not deleted.
  Its comment says the rule was widened on the user's call (2026-09-24).

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Concurrency | A design session never runs beside retro or queue, and never beside a session whose files overlap its own | a fixture run log with a design dispatch open during a retro, which the design-windows check passes | `references/CONCURRENCY.md` |

## Acceptance criteria

- [ ] AC1 — Given a queue ranked `0001 design ready`, `0002 develop ready` with no shared file or parent, when `./next --drive --propose` runs, then the block reads `PROPOSE   develop | 1 ticket(s)` with `TICKET    0002`, it prints `DESIGN    0001 | heads the next sprint`, and the decision line is still `DISPATCH  design 0001` (design goes first).
- [ ] AC2 — Given a queue with no takeable `develop` row, when `--drive --propose` runs, then it proposes the top design row exactly as today (`PROPOSE   design`).
- [ ] AC3 — Given a `waiting` or `next: queue` row ranked above the first develop row, when `--drive --propose` runs, then it still exits 4 on that row; only `design ready` rows are passed on the way to the head.
- [ ] AC4 — Given `0002 develop`, `0003 design ready`, `0004 develop`, all naming `a.md` in `expects:`, when `--drive --propose` runs, then the gate is `0002 0004` and the block prints `DESIGN    0003 | related to this gate`; a joining design row no longer ends the proposed gate.
- [ ] AC5 — Given a `design ready` row ranked above the head that shares the head's `parent:`, when `--drive --propose` runs, then it is named `DESIGN    <id> | related to this gate`, not as the next head.
- [ ] AC6 — Given two unrelated `design ready` rows above the head, when `--drive --propose` runs, then only the higher one is named `heads the next sprint` and the lower is named nowhere; and given the first row left after the scope is a `develop` row, then no `heads the next sprint` line is printed.
- [ ] AC7 — Given `--drive --scope 0002` over `0001 design ready` (out of scope) above `0002 develop ready`, when it runs, then it prints a `NOTE` stepping over 0001 as outside the confirmed scope and exits 0 with `DISPATCH  develop 0002`. Without `--scope` the output is unchanged from today.
- [ ] AC8 — Given `--drive --scope 0002 --scope 0003` with `0003 design ready` ranked below `0002 develop ready`, when it runs, then it exits 0 with `DISPATCH  design 0003` before any develop gate.
- [ ] AC9 — Given in-scope `0003 design ready` with `expects: a.md`, and `0002` in-progress at `next: develop` with `touches: a.md`, when `--drive --scope 0003` runs, then 0003 is stepped over with a `NOTE` naming 0002 and the files; with disjoint files it is dispatched.
- [ ] AC10 — Given the develop gate `0002` naming `a.md`, and `0003` in-progress at `next: design` with `expects: a.md`, when `--drive` runs, then it exits `6` with a `WAIT      ` line naming 0002, 0003 and `a.md`; with disjoint files it exits 0 with `DISPATCH  develop 0002`.
- [ ] AC11 — Given an in-progress row at `next: design` or `next: verify` whose `expects:` overlaps an in-scope design candidate, when `--drive` runs, then the candidate is still dispatched: design beside design or verify is never a conflict.
- [ ] AC12 — `./next --help` lists exit `6` as wait, and the sprint skill's Step 2 routes it: wait for the named session's outcome, then re-call with `--completed`, never dispatch past it.
- [ ] AC13 — The sprint skill's *Design alongside develop* section is renamed *Design beside other stages*, every cross-reference to it is updated, and it states that design may run beside develop, verify or design, that the check is FR6's relation and `--drive` enforces it, and that retro and queue run alone.
- [ ] AC14 — The proposal section replaces "Where a `next: design` row outside the scope outranks the gate, name it as where the run will stop" with the FR1/FR2 rule: plan from the first develop-ready row, and take the related design rows and the next sprint's head, nothing else.
- [ ] AC15 — Every guard in `tests/sprint.test.sh` pinning the old wording (at least the `DSEC` heading, "except a design session alongside a develop session" in Step 8, and the 0134 AC9 scope's-edge guard) is rewritten to the new rule, each carrying a comment that the rule was widened on the user's call (2026-09-24).
- [ ] AC16 — Given a fixture run log with a `design` dispatch for 0003 and no outcome, then a `retro` dispatch, when the design-windows check runs, then it prints `open 0003`, the condition Step 6 refuses the tail on.
- [ ] AC17 — `tests/next.test.sh`, `tests/sprint.test.sh` and `tests/item-ac-form.test.sh` pass, and the rest of `tests/*.test.sh` is no redder than the baseline.

## QA plan

Unit: `tests/next.test.sh` fixtures for `--propose` over a queue headed by a design row;
`tests/sprint.test.sh` for the widened section.

## Out of scope

- Parallel develop sessions: `0137` declines them, and nothing here reopens that.

## Notes & decisions

- 2026-09-25 — filed by retro from two 2026-09-24 supervisor findings (run-20260924T050130Z). Both
  record rules the user stated, so the rules are not in question here, only their mechanism.

- 2026-09-26 — **design decided** (session a16a). What was asked: what `--propose` computes and what
  the proposal says so that (a) a design-headed queue is planned from its first develop-ready row,
  (b) the design rows taken are the gate's related rows and the next sprint's head only, and (c)
  what a design session's file conflict is checked against.
  - **(a) The head.** The plan walks the rank as `--drive` does, but passes `design ready` rows on
    the way to the first takeable `develop` row instead of stopping at them. `waiting` and
    `next: queue` rows still stop it, because those need a person and rule 1 does not change that.
    The *decision* line is unchanged: the top design row is always in the plan (either related or
    the next head, see (b)), so `DISPATCH  design <top>` is the plan's first step. That keeps the
    0134 AC9 premise guard true and changes only the `PROPOSE` block. No develop row at all → the
    proposal is today's design proposal.
  - **(b) Which design rows.** *Related* means `gate_admits`, the join that already builds gates:
    a shared `expects:` file with the gate's accumulated scope, or a shared `parent:`. That covers
    the design rows passed above the head and those inside the gate's rank extent, where a joining
    design row is now passed rather than ending the gate. A design row that does not join still
    ends the gate (0158: a join decides batching, never selection). The *next sprint's head* is the
    first row the walk would reach once this sprint's scope is removed, named only if it is
    `design ready`. It is one row: the user said the head only. Every other design row is named
    nowhere.
  - **Order: design first, then build.** Under `--scope`, `--drive` dispatches in-scope design rows
    before any develop gate, and steps over out-of-scope design rows instead of halting on them.
    `--scope` already reaches the script (0168), so this reverses the old "the run stops at the
    scope's edge" rule. A related row then comes out of design at `develop ready` and joins the
    gate. That makes one develop session and one startup floor, not a build and then a rebuild.
  - **(c) The check is one relation: a design row's `expects:` against a develop session's files.**
    A design session writes only its own item file and a `QUEUE.md` row, under the lock, so its
    *writes* cannot conflict with anything. The real hazard is the user's second clause, "what
    accepting its outcome would change": the design reads, and cites line by line, files that a
    running develop is editing. Its citations go stale under it, which is what design Step 2.4
    exists to prevent. Develop is the only stage that changes those files, so:
    design candidate `expects:` ∩ in-progress develop `touches:` → step over the design (it is off
    the critical path). Develop gate `expects:` ∩ in-progress design `expects:` → **wait**, exit 6.
    It does not step over, because stepping over the head would build rank-2 work ahead of it.
    Design beside design, or beside verify: never a conflict, since both write only their own
    item. Two designs over one file get reconciled by the one develop gate that later builds both.
    Retro and queue stay alone (design-windows check, unchanged).
  - **Rejected.** *Running rows' `expects:`/`touches:` uniformly, for every stage*: this reads the
    unseeded `touches:` of a design or verify claim as "all held" (`CONCURRENCY.md`), so it forbids
    every parallel design, the opposite of rule 3. *The design row's `expects:` against everything*:
    this blocks design beside design and verify for writes that cannot collide. *Checking in
    supervisor prose*: it is mechanically checkable, so the script enforces it. *Develop first,
    then design the related rows beside it*: they conflict by construction (a file join is an
    overlap), so this serialises anyway and pays a second develop floor.
  - **Trade-off accepted.** A related row sharing a file with the gate delays the gate by one
    design session of wall-clock (exit 6). The cost moves to time and saves a develop floor.
    Parent-only related rows share no file, so they run in parallel with the gate at no delay.
  - **Does not depend on 0050.** This reuses whatever unit `expects:`/`touches:` carry. If 0050
    makes that unit smaller than a file, this check inherits the finer grain and gets fewer
    false conflicts. In this repo, where most rows name one `SKILL.md`, exit 6 will be common
    until then. 0050 relieves that; this decision does not wait on it.
  - **Criteria accounting.** FR1–FR4 are confirmed. FR3 is sharpened by the new FR6, the relation
    and where it is enforced. FR5 is added (scope-aware stepping, design first). The ACs are
    authored new, since the ticket had none. Size m → l: the change spans the plan, the scope-aware
    walk, a new exit code and the skill rewrite. `expects:` is unchanged and still accurate.
