---
id: "0094"
title: Record why a claimed row was put back
type: bug
next: develop
status: ready
qa_level: unit
size: s
created: 2026-09-05
source: agent
parent:
blocked_by: []
relates: ["0081"]
expects:
  - skills/queue/templates/handoff
  - .claude/backlog/handoff
  - skills/develop/SKILL.md
  - skills/verify/SKILL.md
  - tests/handoff.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

A row claimed and then released records no reason, so the next session re-derives it.

Measured: `0086` was claimed by token `f7c0` and handed straight back to `develop | ready` **58
seconds later** (`bdf2cdc` → `6eba29c`), with no note in the item and nothing in the queue. The next
session then spent the same analysis reaching the same answer — `0086`'s `expects:` overlaps
`0081`'s live claim on `skills/develop/SKILL.md` and `skills/verify/SKILL.md`, so the row is not
takeable while `0081` is in flight.

`./handoff` takes a destination stage and no reason, and no step in `develop` requires one when it
**releases** rather than completes. So a row put back untouched is indistinguishable from one never
taken, and the cost is paid again by every session that reaches it — which is exactly the
orientation cost the one-skill-per-session batching rule exists to avoid.

## Functional requirements

- FR1 — `./handoff` accepts a reason and writes it into the item's *Notes & decisions* as a dated,
  token-attributed line, in the same locked commit as the stage and status change. This is the code
  that implements the rule; without it the rule is prose in two skills.
- FR2 — `./handoff` **requires** the reason when the destination stage is the one the row already
  had — the release case — and leaves it optional otherwise, since a completed hand-off already
  records its work in the item.
- FR3 — `develop` and `verify` state that releasing a row without completing it carries a reason,
  and that the reason is what `./handoff` is given rather than something written separately.
- FR4 — The reason line names the overlapping claim or the blocking condition where there is one, so
  the next session can check whether it still holds rather than re-deriving it.
- FR5 — `tests/handoff.test.sh` asserts FR1 and FR2, including the refusal.
- FR6 — The change lands in both `skills/queue/templates/handoff` and `.claude/backlog/handoff`, so
  `tests/backlog-scripts-installed.test.sh` stays green.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The reason is appended to the item, never to the queue row — `QUEUE.md` holds the header and the table and nothing else | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given a row at `next: develop, status: in-progress`, when
  `./handoff <id> <token> develop ready` is run with no reason, then it exits non-zero and changes
  nothing. Red-making input: today's `handoff`, which accepts it and releases the row silently.
- [ ] AC2 — Given the same row, when the same command is run **with** a reason, then the item's
  *Notes & decisions* gains a line carrying the date, the token and that reason, and the row reads
  `develop | ready`. Red-making mutation: dropping the notes append from the script, after which the
  row moves and the item is unchanged.
- [ ] AC3 — Given a row handed **forward** (`develop` → `verify`), when `./handoff` is run with no
  reason, then it succeeds. Red-making mutation: making the reason unconditional, which would break
  every ordinary hand-off.
- [ ] AC4 — Given AC2's item afterwards, when the notes line is read, then it is one line and sits
  under *Notes & decisions*, not under *Problem* or in the frontmatter. Red-making mutation:
  anchoring the append on the frontmatter's closing `---`, which writes it above the body.
- [ ] AC5 — Given `skills/develop/SKILL.md` and `skills/verify/SKILL.md`, when each is searched for
  the release-carries-a-reason rule, then it is present in both. Red-making mutation: deleting it
  from `verify`, which the guard asserting both files names.
- [ ] AC6 — Given both copies of the script, when `tests/backlog-scripts-installed.test.sh` runs,
  then it reports `0 failed`.

## QA plan

- **Why that level:** the deliverable is a script change with an existing suite; the assertions are
  ordinary cases in `tests/handoff.test.sh`.
- **Specific checks:** `tests/handoff.test.sh` and `tests/backlog-scripts-installed.test.sh`
  individually, then the whole suite file-by-file. AC4 needs an item whose *Notes & decisions* is
  the last section, and one where it is not, since the append anchor is where this will break.

## Out of scope

- `./close`, which ends the ticket — its reason is the verdict `verify` already records.
- Making `./claim` refuse a row it will only release. The overlap check belongs to the session
  reading `touches:`, not to the script.
- Backfilling the reason `0086` lost. It is recorded in this item's *Problem* and that is enough.

## Notes & decisions

- Routed to `develop`: this is a CLI argument on an existing script, which `queue`'s routing rule
  names explicitly as a `develop` case — the contract is the argument list and the code decides it.
- FR2's asymmetry is the whole design: making the reason unconditional taxes every ordinary hand-off
  to catch the rare release, and a required field people fill with "done" records nothing.
