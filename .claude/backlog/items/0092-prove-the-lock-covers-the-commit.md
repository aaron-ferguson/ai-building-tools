---
id: "0092"
title: Prove claim and close hold the lock through their commit
type: bug
next: develop
status: ready
qa_level: unit
size: s
created: 2026-09-05
source: agent
parent:
blocked_by: []
relates: ["0089", "0090"]
expects:
  - tests/claim.test.sh
  - tests/close.test.sh
  - tests/handoff.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

`CONCURRENCY.md` (*Lock every write to the backlog directory*) requires the lock to cover the read,
the write **and** the commit. No backlog script is proven to do the last part, and **no ordinary
assertion can prove it**: releasing the lock after the edit and before the commit leaves every
observable identical — correct files, a landed commit, a released lock. The suite is green under the
bug and under the fix alike, which is `0089`'s class of defect on the one property these scripts
exist for.

It was caught once. Mutating the release earlier in `./handoff` kept its whole suite green until a
`pre-commit` hook was added to the fixture to witness the lock at commit time — one hook, four
lines. `tests/handoff.test.sh` now carries that case ("the lock is still held at the moment the
commit runs"); `tests/claim.test.sh` and `tests/close.test.sh` have the same blind spot on scripts
whose commit-inside-the-lock is their entire reason for existing.

## Functional requirements

- FR1 — `tests/claim.test.sh` asserts that `.claude/backlog/.lock/` exists at the moment `claim`'s
  commit runs, witnessed by a `pre-commit` hook installed in the fixture repository.
- FR2 — `tests/close.test.sh` makes the same assertion for `close`.
- FR3 — Both cases are **mutation-proved**: moving the lock release above the commit in the script
  under test reddens the new case and only the new case, and the item records that it did.
- FR4 — The witness is built the way `tests/handoff.test.sh` already builds it, so a reader of the
  three suites sees one shape rather than three.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | FR3's mutation and its result are recorded in this item, since a guard against an unobservable property is exactly the one a later reader will doubt | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given `skills/queue/templates/claim` with its `rm -rf "$LOCK"` moved to immediately
  before the `git commit`, when `tests/claim.test.sh` runs, then the new case **fails** and names the
  lock. Red-making input: today's suite, where that mutation passes.
- [ ] AC2 — Given the same mutation applied to `close`, when `tests/close.test.sh` runs, then its new
  case fails. Red-making input: today's suite, where it passes.
- [ ] AC3 — Given the unmutated scripts, when `tests/claim.test.sh` and `tests/close.test.sh` run,
  then each reports `0 failed`. Red if the hook fires on a commit the script does not make, or if the
  fixture leaves the hook installed for a later case that commits outside the lock.
- [ ] AC4 — Given this item's *Notes & decisions* after the work, when it is read, then it records
  the exact mutation used for AC1 and AC2 and that each reddened only the new case. Red if either
  entry is absent.

## QA plan

- **Why that level:** the deliverable is two test cases; the runner that exercises them is the suite.
- **Specific checks:** `tests/claim.test.sh` and `tests/close.test.sh` individually, then the whole
  suite file-by-file. Re-apply AC1's mutation and confirm exactly one case reddens — a second red
  means the mutation broke something other than the property under test.

## Out of scope

- `handoff`, which already has the case.
- Any change to the scripts themselves. This item adds the proof that the existing behaviour is what
  it claims; if a red is found, that is a separate ticket and this one reports it.
- `next`, which commits nothing and so has no such property.

## Notes & decisions

- Routed to `develop`: the corrective shape is already built and shipped in `tests/handoff.test.sh`.
  There is nothing to decide, only to copy correctly.
- Kept separate from `0090` deliberately. `0090` changes the three scripts' behaviour; this changes
  only what the suite can see, and is takeable while `0090` is blocked on `0082`.
