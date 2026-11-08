---
id: "0228"
title: Name the backlog directory .tickets/, since it holds the whole ticket system
type: chore
next: develop
status: in-progress
qa_level: unit
close_by: develop
ac_digest: AC1=58463572 AC2=a7b9b9b5 AC3=cd1abc8a AC4=155352b5 AC5=53da32f0 AC6=55d17add
size: m
created: 2026-11-08
source: user
parent:
blocked_by: []
relates: ["0182"]
expects:
  - "*"
claimed_by: "t228"
claimed_at: 2026-11-08T23:09:22Z
touches:
  - "*"
---

## Problem

0182 moved the backlog out of `.claude/backlog/` to `.backlog/`. The directory holds more than the
backlog — items, the done log, findings, the sprint ledger and the scripts that drive them — so the
user renamed it: **`.tickets/`**. "Backlog" stays the word for the ranked queue (`QUEUE.md`), which
is one part of the ticket system.

Four repos already moved to `.backlog/` on 0.9.47 (ai-building-conventions, hoa, quantum-catan,
AetherWorks), so `.backlog/` becomes a second legacy location rather than vanishing.

## Notes & decisions

- 2026-11-08 — **Decision (user): the directory is `.tickets/`.** Reason given: "we named the new
  directory backlog but that is one part of the larger ticketing system." Directory only; the
  prose word "backlog" for the queue is unchanged.
- 2026-11-08 — `.backlog/` gets the same end date as `.claude/backlog/` (2026-12-31): every repo on
  it is one this user works, and a second date would be a second thing to track.
- 2026-11-08 — Found while migrating AetherWorks: `close` leaves `claimed_by:` set on a closed item,
  so `migrate` refused 21 `status: done` items as "claimed by another token". `migrate` now ignores
  claims on `done`, `withdrawn` and `rejected` items; whether `close` should clear the field is
  left for a separate ticket.

## Requirements

- FR1 — The scripts' shared location block treats `.tickets/` as the location and both
  `.claude/backlog/` and `.backlog/` as legacy, printing one note naming the legacy path,
  `./migrate`, `.tickets/` and the end date. A repo holding more than one is refused, naming each.
- FR2 — `migrate` moves either legacy location to `.tickets/` as one commit, rewriting `.gitignore`
  entries for either, and ignores claims on closed items.
- FR3 — `next` resolves a tools repo's findings buffer at `.tickets/`, then `.backlog/`, then
  `.claude/backlog/`.
- FR4 — Skills, references and README name `.tickets/`. History (CHANGELOG entries for released
  versions, closed items) is not rewritten.

## Acceptance criteria

All in `tests/backlog-location.test.sh`.

- [ ] AC1 — Given a fixture at `.tickets/`, when every script runs, then each works and none prints the legacy line.
- [ ] AC2 — Given a fixture at `.claude/backlog/` or at `.backlog/`, when every script runs, then each works and prints exactly one legacy line naming that path, `./migrate`, `.tickets/` and 2026-12-31.
- [ ] AC3 — Given a repo holding any two of the three locations, when a script runs from either, then it exits non-zero naming both and writes nothing.
- [ ] AC4 — Given a fixture at `.claude/backlog/` or at `.backlog/`, when `migrate` runs, then `.tickets/` holds the tree in one commit carrying only the renames and `.gitignore`, and a second run says it is already migrated.
- [ ] AC5 — Given a pre-existing `.tickets/`, when `migrate` runs, then it refuses changing nothing; given an item `status: done` with `claimed_by:` set, when `migrate` runs, then it proceeds.
- [ ] AC6 — Given a tools root whose buffer is at `.tickets/FINDINGS.md`, when `next --findings` runs with that `tools.path`, then it counts that buffer.
