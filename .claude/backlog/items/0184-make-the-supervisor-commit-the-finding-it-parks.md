---
id: "0184"
title: Make the sprint supervisor commit the finding it parks, in the same turn
type: bug
next: develop
status: ready
qa_level: unit
close_by: develop
size: s
created: 2026-09-23
source: agent
parent:
blocked_by: []
relates: ["0154", "0185"]
expects:
  - skills/sprint/SKILL.md
  - tests/sprint.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

**`skills/sprint/SKILL.md` Step 9 tells the supervisor to park a finding with "Take that backlog's
lock, append, release it" and never says commit, so the supervisor leaves its park uncommitted and
the next stage dispatched onto the tree inherits a dirty `FINDINGS.md` it did not write.**

Twice now:

- **2026-09-22** — the supervisor's 0173 park sat uncommitted through a verify gate; commit
  `5ff9dbb` committed it after the fact, and its message records that `tests/findings-buffer.test.sh`
  reads the buffer, so the dirt sat in every ticket's evidence set for that gate.
- **2026-09-23** — the retro for run-20260922T031109Z was dispatched onto
  `M .claude/backlog/FINDINGS.md` (the supervisor's park for that run) and ended up committing the
  supervisor's line on its behalf. Parked by retro session edf44941-de11-48ca-92b8-093a50099f9b.

Every stage skill's park step already requires the commit in the same turn, by pathspec, because
uncommitted it is one `git stash` from gone. Step 9's lock sequence is the one write site that omits
it. The ledger paragraph in the same skill already says **Commit it** for the ledger, so the
supervisor is capable of the commit; it is simply not told to make it here.

Checked still true on 2026-09-23: `grep -n "append, release it" skills/sprint/SKILL.md` finds the
sentence in Step 9 with no commit instruction beside it.

## Functional requirements

- **FR1** — Step 9's supervisor-park paragraph of `skills/sprint/SKILL.md` requires the supervisor to
  commit the park by pathspec (`git commit -- <that FINDINGS.md>`) before releasing the lock, in the
  same turn as the append.
- **FR2** — `tests/sprint.test.sh` carries a guard asserting FR1's commit instruction in Step 9, and
  that guard is proved red before green.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Documentation | The commit is stated once, in Step 9's park paragraph, citing `CONCURRENCY.md` for the lock-and-commit sequence rather than restating it | FR2's guard, reddened by deleting the commit clause | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given `skills/sprint/SKILL.md` Step 9, when `tests/sprint.test.sh` runs, then a guard (`0184 AC1`) asserts the supervisor-park paragraph says to commit the park by pathspec — reddened by deleting that clause from Step 9.
- [ ] AC2 — Given the same file, when `tests/sprint.test.sh` runs, then the same guard asserts the commit comes before the lock is released — reddened by moving the commit clause after the release clause (a guard matching only the word `commit` anywhere in Step 9 stays green under that move and does not satisfy this AC).
- [ ] AC3 — Given the whole suite, when `commands.unit` runs on a clean tree, then it is green — reddened by leaving `skills/sprint/SKILL.md` over its size budget in `tests/skill-size.test.sh` after the addition.

## QA plan

Run `tests/sprint.test.sh`, then `commands.unit`. Prove AC1 and AC2 red by the named mutations,
restore by path, re-run green. Step 9 already contains the ledger's **Commit it**, so AC1's guard must
match inside the park paragraph, not anywhere in the section — otherwise AC1's mutation leaves it
green on the ledger sentence. `section()` collapses newlines, so the phrase is wrap-proof.

## Out of scope

- Whether `.claude/backlog/runs/` is tracked — that is a decision, and it is `0185`.
- The stage skills' own park steps, which already require the commit.
- Any change to `FINDINGS.md`'s header or `tests/findings-buffer.test.sh`.

## Notes & decisions

- 2026-09-23 — Swept from `FINDINGS.md` (the retro's park of 2026-09-23). Routed to `develop`: no
  surface and no open decision; the fix is one clause and one guard. `close_by: develop` because
  every AC is discharged by a committed assertion in `tests/sprint.test.sh` or the suite itself.
  The entry's second half — whether `runs/` is meant to be tracked — is a decision and went to `0185`.
