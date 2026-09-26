---
id: "0161"
title: Give a closed ticket a scripted path back to verify
type: feature
next: develop
status: in-progress
qa_level: unit
close_by: verify
size: m
created: 2026-09-13
source: user
parent:
blocked_by: []
relates: ["0160", "0105"]
expects:
  - skills/queue/templates/reopen
  - .claude/backlog/reopen
  - tests/reopen.test.sh
  - tests/backlog-scripts-installed.test.sh
  - skills/queue/SKILL.md
  - references/CONCURRENCY.md
  - tests/citations.test.sh
claimed_by: "31d3"
claimed_at: 2026-09-26T04:39:19Z
touches:
  - skills/queue/templates/reopen  # new
  - .claude/backlog/reopen  # new, installed copy
  - tests/reopen.test.sh  # new
  - tests/backlog-scripts-installed.test.sh
  - skills/queue/SKILL.md
  - references/CONCURRENCY.md
  - references/CONCURRENCY-INCIDENTS.md  # heading citation 'The four scripts'
  - skills/verify/SKILL.md  # heading citation
  - skills/queue/templates/close  # heading citation in header comment
  - skills/queue/templates/handoff  # heading citation in header comment
  - .claude/backlog/close  # installed copy
  - .claude/backlog/handoff  # installed copy
  - tests/handoff.test.sh  # asserts the heading
---

## Problem

**No operation reopens a closed ticket, so re-verifying one is a by-hand write under a by-hand lock.**
`references/CONCURRENCY.md` and `CONCURRENCY-INCIDENTS.md` document that shape as leaking silently.

It was needed on 2026-09-13. Four tickets (0151–0154) had been closed by a verify pass the user did
not trust (see 0160), and the `queue` session that reopened them had to compose the move itself
(commit `ecc6a60`), all inside one locked shell call:

- moved each row from `DONE.md` back into `QUEUE.md`;
- set `next: verify` and `status: ready`, and removed `closed:`;
- unticked the acceptance criteria;
- kept `## QA evidence` as history;
- appended a dated reason to *Notes & decisions*.

The `queue` skill's Step 1 table has no row for this. `claim`, `close` and `handoff` cover every
other transition.

## Functional requirements

- FR1 — A new script `skills/queue/templates/reopen <id> <top|above:<row-id>> <reason>`, installed as
  `.claude/backlog/reopen` byte-identical. Under the backlog lock and in one invocation, it:
  - moves `<id>`'s row from `DONE.md` into `QUEUE.md` at the given position, with `Next` = `verify`
    and `Status` = `ready`;
  - sets the item's `next: verify` and `status: ready`, and removes `closed:`;
  - unticks every `- [x]` in `## Acceptance criteria`, and leaves `## QA evidence` byte-for-byte;
  - appends a dated line carrying `<reason>` to `## Notes & decisions`;
  - commits those three paths by pathspec, then releases the lock.
- FR2 — `reopen` refuses, changing nothing and releasing the lock, when any of these holds:
  - the item is not `status: done`;
  - `DONE.md` holds no row for it, or `QUEUE.md` already holds one;
  - `QUEUE.md`/`DONE.md` are dirty;
  - `<reason>` is empty;
  - `above:<row-id>` names no row in `QUEUE.md`;
  - the lock is busy.
- FR3 — `reopen` reconciles dependents as `close` does, in reverse: an unheld ticket naming `<id>` in
  `blocked_by` whose row reads `ready` becomes `blocked`, row and item, in the same commit. A held
  dependent makes it refuse, naming the dependent.
- FR4 — `skills/queue/SKILL.md` Step 1's operation table gains a row, for re-verifying a closed
  ticket, that runs `./reopen`. `references/CONCURRENCY.md`'s scripts section lists it. If that
  section's heading count changes, every citation of the heading changes in the same commit.
- FR5 — `tests/backlog-scripts-installed.test.sh`'s script list includes `reopen`.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Documentation | The by-hand composition in `ecc6a60` is named as what the script replaces, in the script's header comment | prose only — no artifact yet | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given a fixture backlog where `0101` is `status: done` with two ticked ACs, a `## QA
  evidence` body and a `DONE.md` row, when `./reopen 0101 top "fixture reason"` runs, then:
  - it exits 0;
  - the first table row of `QUEUE.md` is `0101` with `verify | ready`, and `DONE.md` has no `0101`
    row;
  - the item reads `next: verify` and `status: ready`, with no `closed:` line and no `- [x]` under
    `## Acceptance criteria`;
  - its `## QA evidence` body is unchanged;
  - the last line of `## Notes & decisions` contains `fixture reason`;
  - `git show --name-only HEAD` lists exactly those three files.

  Red: each clause fails against a script missing that step.
- [ ] AC2 — Given the AC1 fixture with `QUEUE.md` rows `0102`, `0103`, when `./reopen 0101 above:0103
  "r"` runs, then `0101` sits directly above `0103`. Red: a script that ignores the position.
- [ ] AC3 — Given `0101` at `status: ready`, when `./reopen 0101 top "r"` runs, then it exits non-zero
  and `git status --porcelain` over the backlog is empty. Red: the FR2 status guard removed.
- [ ] AC4 — Given `0102` unheld, `status: ready`, `blocked_by: ["0101"]`, when `./reopen 0101 top "r"`
  runs, then `0102`'s row and item read `blocked` and `./next --drift` prints `no drift`. Red: FR3
  omitted.
- [ ] AC5 — Given `.lock/` already present, when `./reopen 0101 top "r"` runs, then it exits non-zero
  and changes nothing. After both a successful and a refused run, no `.lock/` remains that the
  script created. Red: a failure path that returns without releasing the lock.
- [ ] AC6 — Given `skills/queue/SKILL.md`, when the suite runs, then Step 1's table contains
  `./reopen`. Red: the row absent.

## QA plan

- **Why that level:** a backlog script with a fixture test, like `close` and `handoff`.
- **Specific checks:** new `tests/reopen.test.sh` for AC1–AC5; AC6 as a prose guard;
  `tests/backlog-scripts-installed.test.sh`; `tests/citations.test.sh` if the heading moves.

## Out of scope

- Deciding *whether* to reopen, and the rank: the caller passes both.
- Reopening to any stage other than `verify`. A contract that needs changing is a re-specify.
- Detecting an untrusted close — 0160.

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

## Notes & decisions

- **2026-09-13 — filed by a `queue` sweep of FINDINGS.md** (run-20260913T034946Z). Routed to
  `develop`: the by-hand composition in `ecc6a60` is a worked specification of every step.
- **Why a script and not a documented by-hand procedure.** Every other backlog transition is a
  script because a by-hand lock leaks silently (`CONCURRENCY-INCIDENTS.md`). This one also moves
  rows between two tables and rewrites four frontmatter fields, which is more to get wrong than a
  claim.
- **Why the ACs are unticked.** A tick is evidence from the pass being distrusted, and `close`
  re-ticks what the new pass checks. It is the same argument as `queue`'s re-specify rule.
- **Why the rank is an argument.** Rank is a `queue` judgement, never a script default.
- 2026-09-23 — Rank raised to row 3, under 0179 and 0180 (`RANKING.md`, 2026-09-23). The failure it recovers from recurred on 2026-09-22: a verify pass closed six tickets on an envelope whose session id was the all-zero placeholder, and the author decided by hand whether to accept them. 0179 FR4 names this operation as one of its outcomes. Contract unchanged.
- **2026-09-25 — build notes (develop, token 31d3).** Built in `65c8f2d`: `skills/queue/templates/reopen`,
  installed byte-identical at `.claude/backlog/reopen`, guarded by `tests/reopen.test.sh` (78 cases).
  - **FR4's heading count did change**: `## The four scripts` is now `## The five scripts`, and every
    citation moved in the same commit — `close`/`handoff` header comments (template and installed),
    `skills/verify/SKILL.md`, `skills/queue/SKILL.md`, `references/CONCURRENCY-INCIDENTS.md` (two),
    `tests/backlog-scripts-installed.test.sh` and `tests/handoff.test.sh` AC7. `handoff.test.sh`
    also pinned the literal `SCRIPTS="next claim close handoff"`; it now asserts the prefix, so it
    still proves `handoff` is listed without reddening on every new script.
  - Two further script enumerations went stale with this and were widened: queue Step 0's
    `chmod +x` list (it already omitted `handoff`) and CONCURRENCY.md's list of the scripts that
    refuse from a linked worktree (`reopen` does too).
  - **Beyond FR3's literal text, deliberately:** a `waiting` dependent is re-blocked as well as a
    `ready` one. `./next --drift` class 2 reports any non-`blocked` row with an open blocker, so
    leaving it `waiting` fails AC4's own `no drift`; and `close` restores `waiting` from the
    dependent's `## Waiting on` section when this ticket closes again, so nothing is lost. A `done`
    dependent is skipped entirely (history, and some carry stale tokens that would otherwise read as
    held and make every reopen refuse).
  - **Also beyond the FRs:** the reopened item's `claimed_by:`/`claimed_at:`/`touches:` are cleared
    (closed items in this backlog do carry stale tokens, and a `ready` ticket keeping one reads as
    held — `./next --drift` class 6); the item file is included in the dirty-tree refusal, since the
    commit names it by pathspec; and a position that is neither `top` nor `above:<id>` is refused.
  - `reopen` takes no token: a done ticket has no holder, so there is nothing to prove ownership of.
  - **Clause table and mutation sweep — run, not reasoned.** Each row mutated the committed template,
    ran `tests/reopen.test.sh`, restored from HEAD; control run after: 78 passed, 0 failed.

    | AC clause | Mutation | Result |
    |---|---|---|
    | AC1 it exits 0 | `exit 3` before the success line | red (5) |
    | AC1 first table row is `0101` with `verify \| ready` | `top` insert never matches | red (22) |
    | AC1 `DONE.md` has no `0101` row | DONE deletion removed | red (24) |
    | AC1 `next: verify` | next line printed unchanged | red (24) |
    | AC1 `status: ready` | status line printed unchanged | red (24) |
    | AC1 no `closed:` line | `closed:` kept | red (24) |
    | AC1 no `- [x]` under `## Acceptance criteria` | untick removed | red (2) |
    | AC1 `## QA evidence` body unchanged | untick applied file-wide | red (1) |
    | AC1 last line of Notes contains the reason | note never printed | red (2) |
    | AC1 `git show --name-only HEAD` exactly three files | DONE.md dropped from the pathspec | red (3) |
    | AC2 `0101` directly above `0103` | `above:` insert never matches | red (2) |
    | AC3 not `status: done` → non-zero, porcelain empty | status guard removed | red (3) |
    | AC4 dependent row and item read `blocked`, `no drift` | re-block skipped | red (6) |
    | AC5 `.lock/` present → non-zero, unchanged | `mkdir -p` (lock never busy) | red (4) |
    | AC5 no `.lock/` remains after a refused run | EXIT trap removed | red (11) |
    | FR2 no DONE row / QUEUE row present / dirty / empty reason / `above:` names no row | each guard removed, one at a time | red (3 / 1 / 6 / 4 / 1) |
    | FR3 held dependent refuses, naming it | HELD refusal removed | red (3) |
    | FR3 done dependent is history | done-skip removed | red (1) |
    | AC6 Step 1's table contains `./reopen` | the row absent (the state before this build) | red (1) |

  - Whole suite (`tests/*.test.sh`, 32 files) green in the checkout after the build. The supervisor's
    baseline red in `citations.test.sh` (0189, worktree-only) did not arise here.
  - Review checklist: header comment names `ecc6a60` (NFR), columns by name, refusals before the
    lock where no re-read is needed and under it otherwise, lock trap set only after `mkdir`
    succeeds, all three files built aside and read back before any is moved (handoff's 0087 lesson).
