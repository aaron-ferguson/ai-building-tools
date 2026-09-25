---
id: "0189"
title: Make the citations guard resolve the conventions path from a worktree outside the checkout's parent
type: bug
next: develop
status: ready
qa_level: unit
close_by: verify
size: s
created: 2026-09-25
source: retro
parent:
blocked_by: []
relates: ["0180", "0083"]
expects:
  - tests/citations.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

**`tests/citations.test.sh` goes red in a worktree that is not a sibling of the checkout, because
`config.yml`'s `conventions.path: ../ai-building-conventions` is resolved from the worktree root.**

Measured by verify 0180 (token eb65) at 9f0cf0c: `git worktree add --detach` under a temp directory
gave `45 passed, 1 failed` (`FAIL no conventions directory resolved from config.yml`); the checkout
and a sibling worktree (`../<name>`) both gave `46 passed, 0 failed`. 0180's sprint Step 1 baseline
runs the suite "in a throwaway worktree" without saying where. A baseline placed in a temp directory
therefore reports a red that no ticket owns, and *repair first* then mints a row for it.

## Functional requirements

- **FR1** — `tests/citations.test.sh` resolves a relative `conventions.path` against the main
  worktree's root (`git rev-parse --path-format=absolute --git-common-dir`, then its parent), so
  the result does not depend on where the worktree sits.
- **FR2** — Run from the checkout itself, the resolution is unchanged.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Testing | The suite's verdict does not depend on the worktree's location | the test run from a worktree under a temp directory reports a failure the checkout does not | `testing-conventions.md` |

## Acceptance criteria

- [ ] **AC1** — Given a detached worktree created under a temp directory, `tests/citations.test.sh` run
  there reports the same tally as in the checkout.
- [ ] **AC2** — Given the checkout, the tally is unchanged from before the fix.

## QA plan

Unit: a guard that creates a detached worktree under `mktemp -d`, runs the test there, compares the
tally, and removes the worktree in the same run. Proved red against the current test first.

## Out of scope

- Whether sprint Step 1 should name a worktree location. With FR1 it no longer needs to.

## Notes & decisions

- 2026-09-25 — filed by retro from verify 0180's finding (token eb65). Of the two fixes the finding
  offered, this row takes the resolution fix. It removes the hazard for every caller, where a named
  location would only instruct one caller.
