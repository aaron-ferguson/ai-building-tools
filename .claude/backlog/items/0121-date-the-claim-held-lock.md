---
id: "0121"
title: Make claim write the timestamp CONCURRENCY.md requires in held-by
type: bug
next: develop
status: ready
qa_level: unit
close_by: verify
qa_manual:
size: s
created: 2026-09-09
source: retro
parent:
blocked_by: []
relates: ["0047", "0092"]
expects:
  - .claude/backlog/claim
  - skills/queue/templates/claim
  - tests/claim.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

**`claim` writes `held-by` without the timestamp `CONCURRENCY.md` mandates, and `close` and
`handoff` both write one.** *Lock every write to the backlog directory* says to put `$CLAIM` **and
a UTC timestamp** in `.lock/held-by`. `claim:81` writes `claim <id> by <token>` and stops;
`close:71` and `handoff:112` each `printf` a date.

So **the lock's commonest holder is the one holder whose `held-by` cannot be dated.** Any reader
written against the protocol — `0040`'s driver was the first — works perfectly in testing against a
close-held lock and then silently treats every claim-held lock as ageless. `0040` sidestepped it by
reading the lock **directory's** mtime, which `mkdir` sets on every path, but that is the driver
declining to depend on the field rather than the field being fixed, and the next reader will not
know to decline.

`claim` was *Out of scope* for `0040`. `0092` (proving the lock covers the commit) and `0047` (the
busy-lock procedure's close-time path) were both opened and are about different properties.

## Functional requirements

- FR1 — `claim` writes a UTC timestamp into `.lock/held-by` alongside the token.
- FR2 — the three scripts write the field in **one** format, so a reader can parse it without
  knowing which script is holding the lock.
- FR3 — a guard asserts the shape for all three, rather than for whichever one is being edited.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | `CONCURRENCY.md` already states the requirement; cite it, do not restate it | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — given `.claude/backlog/claim` runs and takes the lock, when `.lock/held-by` is read,
  then it contains an ISO-8601 UTC timestamp; red by reverting the `printf`.
- [ ] AC2 — the same field from `close` and from `handoff` matches AC1's format exactly; red by
  changing any one of the three formats.
- [ ] AC3 — the assertion in AC2 covers all three scripts by iteration, not by three hand-written
  cases; red by adding a fourth lock-taking script with a different format.
- [ ] AC4 — `skills/queue/templates/claim` carries the same change as `.claude/backlog/claim`; red
  by patching only one of the pair.

## QA plan

- **Why that level:** the artifact is three shell scripts; every criterion is a run of one and a
  read of the file it wrote.
- **Specific checks:** `tests/claim.test.sh`, `tests/close.test.sh`, `tests/handoff.test.sh`, and
  `tests/backlog-scripts-installed.test.sh` for the template pair.

## Out of scope

What a reader should *do* with the age (`0047`). Whether the lock covers the commit (`0092`).

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

## Notes & decisions

- 2026-09-09 (retro) — filed from `FINDINGS.md`, parked 2026-09-08. Line numbers were current at
  the park date; re-read the source rather than trusting them.
