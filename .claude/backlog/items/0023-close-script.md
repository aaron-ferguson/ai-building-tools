---
id: "0023"
title: Add a close script mirroring claim
type: chore
next: develop
status: in-progress
qa_level: verify
size: m
created: 2026-08-23
source: agent
parent: "0002"
blocked_by: []
relates: ["0022"]
expects:
  - skills/queue/templates/close
  - skills/queue/templates/claim
  - skills/queue/SKILL.md
  - skills/verify/SKILL.md
  - references/CONCURRENCY.md
claimed_by: "8a04"
claimed_at: 2026-08-23T20:47:31Z
touches:
  - skills/queue/templates/close      # new
  - tests/close.test.sh               # new
  - skills/queue/SKILL.md
  - skills/verify/SKILL.md
  - references/CONCURRENCY.md
  - README.md
---

## Problem

Closing a ticket is a five-step sequence under the lock — tick the ACs, set `status: done`, delete the
row, append to `DONE.md`, commit, release — and it is done by hand every time. `claim` exists as a script
for exactly this shape of work, and `CONCURRENCY.md` states why: *"the commit is exactly the thing a
session under load forgets, and a script cannot forget."* The close has the same failure mode and no
script.

Measured on 2026-08-23: one session closed eleven tickets, and each close cost roughly four tool calls of
pure mechanism with no information content — about 44 calls across the session. That is the cost. The
*risk* is worse and is the reason this is not merely ergonomics: a hand-close that edits `QUEUE.md` and
`DONE.md` but does not commit inside the lock leaves both files dirty in one working tree, so the next
window to commit either carries the close off under its own message — the identical failure that made
`claim` a script.

The asymmetry is also a readability problem: a reader of `CONCURRENCY.md`'s *The two scripts* sees the
open side automated and is left to infer that the close side is hand-work by choice rather than omission.

## Functional requirements

- FR1 — `templates/close <id>` performs the whole close as one step: lock, re-read the row, tick the ACs
  in the item file, set `status: done` with the date, clear `claimed_by:`/`claimed_at:`/`touches:`, delete
  the row from `QUEUE.md`, append it to `DONE.md` newest-first, **commit by pathspec, then release**.
- FR2 — It refuses rather than guessing, on the same three grounds `claim` refuses: a table shape it
  cannot parse, a row whose `next` is not `verify`, and a row whose `claimed_by:` token was not passed to
  it. The third is the ownership test — a close is only yours if you hold the claim.
- FR3 — A `trap` releases the lock on every failure path, and the commit is retried briefly if
  `.git/index.lock` is held, matching `claim`'s behaviour exactly. Never remove another process's git lock.
- FR4 — It writes the `DONE.md` row from the `QUEUE.md` row plus the item's frontmatter, so the two files
  cannot disagree about a ticket's title.
- FR5 — `verify`'s Step 5 names it as the supported path, the way `develop`'s Step 1 names `claim`, and
  hand-closing under the lock remains documented as the fallback.
- FR6 — `CONCURRENCY.md`'s *The two scripts* becomes three, without growing past 1,500 tokens — the
  ceiling 0020 set. Trade the words for it in that section rather than anywhere else.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The rule each script encodes is stated once, in `CONCURRENCY.md`, and cited by the skills — not restated in three places. | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given a fixture backlog with a `next: verify` row claimed by token `ab12`, when
      `./close 0001 ab12` runs, then the row is absent from `QUEUE.md`, present in `DONE.md`, the item's
      `status` reads `done`, and `git log -1 --name-only` shows exactly those three paths.
- [ ] AC2 — Given the same fixture, when `./close 0001 ab12` runs, then `.lock/` does not exist
      afterwards and the commit precedes its removal (asserted by the commit existing while the working
      tree is clean).
- [ ] AC3 — Given a row whose `next` is `develop`, when `./close` is called on it, then it refuses,
      names what it found, exits non-zero, and leaves both files unchanged.
- [ ] AC4 — Given a row claimed by a different token, when `./close <id> <wrong-token>` runs, then it
      refuses, exits non-zero, and leaves both files unchanged.
- [ ] AC5 — Given a `QUEUE.md` whose header is not `ID/Title/Next/Status/Parent`, when `./close` runs,
      then it errors on the shape rather than editing anything.
- [ ] AC6 — Given a forced failure between the row edit and the commit, when the script exits, then
      `.lock/` has been removed by the `trap`.
- [ ] AC7 — Given `references/CONCURRENCY.md`, when its size is measured, then it is still under 1,500
      tokens.

## QA plan

- **Level:** verify — a shell script with no test runner.
- **Scripted assertion:** a fixture backlog in a temp directory with its own `git init`, driven by a
  shell script asserting on `QUEUE.md`, `DONE.md`, the item frontmatter, `git log --name-only`, the
  existence of `.lock/`, and the exit code. AC3–AC6 pin exit codes and file-unchanged separately from
  output, because "printed a refusal" and "changed nothing" are different claims and only the second one
  protects the queue. AC6 is driven by a deliberately failing `git` — point `GIT_DIR` at a
  non-repository — rather than by editing the script.

## Out of scope

- `claim`'s column-index defect — 0022 owns it. This script must parse by the same mechanism `claim` uses
  once 0022 lands, so **sequence them**: build on 0022's parser rather than writing a third one.
- Any change to *what* closing means. FR1 encodes the sequence `verify` Step 5 already specifies.

## Notes & decisions

- **FR2's third refusal is the one worth arguing about.** `claim` mints the token; `close` has to be
  *given* it, because there is no ambient session id and `CONCURRENCY.md`'s ownership test is memory
  ("yours only if you minted its token in this conversation"). A script cannot check memory, so the token
  argument is how the session proves it. Passing the wrong one must fail loudly rather than close someone
  else's ticket.
- Parented under 0002 rather than 0009: it is scaffold tooling, which is that effort's subject. 0009 is
  finished bar 0021.
