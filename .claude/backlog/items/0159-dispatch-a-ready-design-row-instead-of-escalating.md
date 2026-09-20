---
id: "0159"
title: Dispatch a ready design row instead of escalating it to a person
type: bug
next: develop
status: in-progress
qa_level: unit
close_by: verify
size: m
created: 2026-09-13
source: user
parent:
blocked_by: []
relates: ["0134", "0154", "0150", "0158"]
expects:
  - skills/queue/templates/next
  - .claude/backlog/next
  - tests/next.test.sh
  - skills/sprint/SKILL.md
  - tests/sprint.test.sh
claimed_by: "1150"
claimed_at: 2026-09-20T22:51:04Z
touches:
  - skills/queue/templates/next
  - .claude/backlog/next
  - tests/next.test.sh
  - skills/sprint/SKILL.md
  - tests/sprint.test.sh
---

## Problem

**`./next --drive` treats `next: design, status: ready` as a person's decision (exit 4), so every
driven sprint halts at the first design row.** Design is autonomous work: `/design` settles the
question and writes the answer. Only `status: waiting` needs a person.

Parked from run-20260913T034946Z, verbatim:

> `next: design, status: ready` routes as "a person decides" (exit 4), but a person is needed only at
> `status: waiting`. Design is autonomous work; `--drive` should dispatch `design` on a ready row and
> escalate only `waiting`, and the depth line should not report a ready design row as where the run
> runs dry.

Where it happens in `skills/queue/templates/next`:

- the rank walk's `design)` arm: `ESCALATE  <id> is at next: design and outranks everything below
  it — a person decides`;
- the completed-stage block: `ESCALATE  <id> is at next: design after <stage> — a person decides`,
  and `--completed design:<id>` falls to *which no routing rule covers*;
- `depth_stopper`: `design|queue) printf '%s (next: %s — a person decides)'`.

`skills/sprint/SKILL.md` builds on the escalation in four places:

- Step 1's example: *"runs dry at 0080, which is `next: design` and needs a person"*.
- *Design alongside develop*: *"Exit 4 on an in-scope design row is a dispatch, not a halt"*, and
  *"A design finish is never reported through `--completed`"*.
- Step 8's `next: design` bullet.
- Step 9's `ESCALATED — next: /design 0080` example.

## Functional requirements

- FR1 — The rank walk's `design` arm, on a row that is `ready`, unheld and has no open blocker, runs
  `findings_gate` exactly as the `develop` arm does. It then prints `DISPATCH  design <id>` with the
  `DISPATCH` exit code, carries the item's design-question line, and sets `PROPOSE_STAGE=design`
  and `PROPOSE_IDS=<id>`. This lands in both copies of `next`.
- FR2 — The completed-stage block no longer escalates a row that is `next: design, status: ready`
  after any stage: it prints a `NOTE` and continues to the rank walk. `--completed design:<id>` whose
  row is now `next: develop, status: ready` also prints a `NOTE` and continues to the rank walk. A row
  still `next: design` after `--completed design:<id>` keeps today's same-stage escalation.
- FR3 — `depth_stopper` does not stop at a `ready` design row; `queue` rows and `waiting` rows keep
  their current stopper wording.
- FR4 — `status: waiting` at any stage still exits with the escalate code and prints its
  `## Waiting on` line. That is unchanged, and it becomes the only person-held state `--drive`
  reports.
- FR5 — `skills/sprint/SKILL.md` matches FR1–FR3:
  - Step 1's depth example names no ready design row as needing a person.
  - *Design alongside develop* reads a `DISPATCH  design` line rather than exit 4, and routes a
    design finish through `--completed design:<id>`.
  - Step 8's escalation bullet names only `waiting` rows, `next: queue` rows and design rows
    **outside the confirmed scope**.
  - Step 9's example no longer shows a design row as an escalation.
- FR6 — The existing guards that pin the old behaviour are rewritten to assert the new behaviour,
  not deleted: `tests/next.test.sh` case `0038 AC9`, the `depth_stopper` design-arm wording under
  `0038 AC28`/`AC29`, and 0154's FR3 case.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Documentation | Sprint's prose and `next`'s output agree: no sprint sentence describes a ready design row as an escalation | AC7's absence assertion | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given a fixture `0101 design ready` with an `## Open design question`, when `next --drive`
  runs, then it exits 0 and prints `DISPATCH  design 0101`. Red: today's template exits 4 with
  `ESCALATE`.
- [ ] AC2 — Given `0101 design waiting` with a `## Waiting on` section, when `next --drive` runs, then
  it exits 4 and prints the waiting question. Red: a design arm that dispatches regardless of status.
- [ ] AC3 — Given `0101 design ready` held by a claim and `0102 develop ready`, when `next --drive`
  runs, then it prints `DISPATCH  develop 0102` and no `DISPATCH  design`. Red: the design arm
  dispatching a held row.
- [ ] AC4 — Given `0101` now `next: design, status: ready` and `0102 develop ready` below it, when
  `next --drive --completed develop:0101` runs, then it exits 0, prints no `ESCALATE`, and prints
  `DISPATCH  design 0101`. Red: today's `after develop — a person decides` escalation.
- [ ] AC5 — Given `0101` now `next: develop, status: ready`, when `next --drive --completed
  design:0101` runs, then it exits 0 and prints `DISPATCH  develop 0101`. Red: today's *no routing
  rule covers* escalation.
- [ ] AC6 — Given `0101 develop ready`, `0102 design ready`, `0103 queue ready`, when `next --drive`
  runs, then the depth line contains `runs dry at 0103 (next: queue` and not `0102 (next: design`.
  Red: today's `depth_stopper` stops at 0102.
- [ ] AC7 — Given `skills/sprint/SKILL.md`, when `tests/sprint.test.sh` runs, then the file contains
  `DISPATCH  design` and contains neither `Exit 4 on an in-scope design row` nor `needs a person."*`.
  Red: the sections left as they are.
- [ ] AC8 — Given `0101 design ready` and a `FINDINGS.md` holding at least `findings_threshold`
  entries, when `next --drive` runs, then it exits 5 and dispatches no design. Red: a design arm that
  skips `findings_gate`.

## QA plan

- **Why that level:** fixture-driven cases for a shell script plus prose guards; `commands.unit`
  runs both suites.
- **Specific checks:** AC1–AC6 and AC8 in `tests/next.test.sh`; AC7 in `tests/sprint.test.sh`;
  `tests/backlog-scripts-installed.test.sh` for the copy.

## Out of scope

- `next: queue` rows: re-specifying stays an escalation here.
- Whether a design session may run alongside develop, which 0134 already settled; unchanged.
- Rank contiguity of gates — 0158.
- `skills/design/SKILL.md`'s own `design waiting` hand-off, which already sets `status: waiting`
  when a person is needed.

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

## Notes & decisions

- **2026-09-13 — filed by a `queue` sweep of FINDINGS.md** (run-20260913T034946Z). Routed to
  `develop`: the user stated the rule ("design tickets are not human-dependent; only status: waiting
  needs a person"), so no decision is open.
- **Supersedes 0154 FR3.** 0154 made `--propose` on a design row name the develop gate *below* it,
  because the run was going to stop there. Once the row is dispatched, the proposal names the design
  dispatch itself. 0154 is re-verified against its own contract first, since it ranks above this
  ticket, so this ticket rewrites that guard rather than re-specifying 0154.
- **`findings_gate` on the design arm (FR1/AC8)** because a design dispatch is new work exactly as a
  develop gate is, and the gate exists to stop new work once the buffer crosses.
