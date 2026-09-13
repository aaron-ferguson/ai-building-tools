---
id: "0157"
title: Make release verify compare the install against the released commit
type: bug
next: develop
status: ready
qa_level: unit
close_by: verify
size: s
created: 2026-09-12
source: agent
parent:
blocked_by: []
relates: ["0084", "0129"]
expects:
  - tools/release
  - tests/release.test.sh
  - CLAUDE.md
claimed_by:
claimed_at:
touches:
---

## Problem

**`tools/release verify` compares the install against `HEAD`, so it goes red on the first backlog
commit after a release.** Three claim commits after a release it reported `FAILED -- the install does
not hold 7726456` over `.claude/backlog/QUEUE.md` and two item files, and `record FAILED --
gitCommitSha is 59d4b2d` where 59d4b2d was the released commit and the record correct. Every
differing path was backlog state. The substitute that answered the real question was
`git worktree add --detach <path> <released-sha>` then `diff -rq` against the install: 230 paths
identical (verify 0129 AC6).

## Functional requirements

- FR1 — `verify` compares against the commit the installed version was released at (the record's `gitCommitSha`, or the bump commit for that version), never `HEAD`.
- FR2 — the comparison excludes `.claude/backlog/` and reports it excluded.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Observability | The report names the commit compared against and why that one. | A report naming only `HEAD`. | `observability-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given a fixture release followed by a commit touching only `.claude/backlog/`, when `tools/release verify` runs, then it passes. Red-making input: today's HEAD comparison.
- [ ] AC2 — Given a fixture release followed by a commit changing `skills/`, not released, when `verify` runs against an install of the released commit, then it passes; and given the install altered, it fails. Red-making change: excluding everything.

## QA plan

- **Why that level:** `unit` — `tests/release.test.sh` already scaffolds fixture releases.
- **Specific checks:** `tests/release.test.sh`.

## Out of scope

- 0061's question of how a session learns the install differs.

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

## Notes & decisions

- **Filed by a retro pass 2026-09-12 from FINDINGS.md.** One buffer entry; filed because the tool the release chain ends on is red within minutes of every release in this repo.
