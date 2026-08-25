---
id: "0066"
title: Fix the three places the backlog scripts answer the wrong question
type: bug
next: develop
status: ready
qa_level: unit
size: m
created: 2026-08-25
source: agent
parent:
blocked_by: []
relates: ["0027", "0029", "0045"]
expects:
  - skills/queue/templates/claim
  - skills/queue/templates/close
  - skills/queue/templates/next
  - .claude/backlog/claim
  - .claude/backlog/close
  - .claude/backlog/next
  - tests/claim.test.sh
  - tests/close.test.sh
  - tests/next.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

Three defects in the scripts the skills tell every session to use. Two are cosmetic-looking and one
is not.

**`claim`'s success message is stage-blind, and the consequence reaches other sessions.** It tells
every claimant "now set `touches:` … before you open anything" — but a `verify` claim holds no
`touches:`; it reads and runs, it does not open a file scope. The message is wrong for that stage,
and the effect is not cosmetic: `./next` then reports the row to every other session as
`0027 [b8d3] none declared — assume held, ask`, so a **correct** `verify` claim is indistinguishable
from an under-specified `develop` one. `CONCURRENCY.md`'s rule to read an empty `touches:` as held
makes that the safe-but-wrong reading, and it is how a whole stage's rows come to look dangerous.

**`./claim --help` and `./close --help` treat the flag as a ticket id.** `./claim --help` answers
`no row for --help in QUEUE.md`. `./next --help` works and documents every mode, so the
inconsistency reads as "this script has no help" rather than "you passed a bad id" — and these
scripts are the interface the skills tell every session to use.

**A non-takeable row 1 reads as an instruction.** 0026 sat at row 1 as `waiting` for a day and was
read as "the next thing to do"; the user asked why we would run that test now. The rank was correct
— a waiting ticket keeps its rank, deliberately — and `./next develop` correctly stepped over it,
but bare `./next` prints `ROW 1: … | waiting` with no indication that nothing can take it, right
beside the counts. It cost a session to explain rather than a script to answer.

## Functional requirements

- FR1 — `claim`'s success message is stage-aware: it asks for `touches:` where the stage opens a
  file scope and does not where it does not.
- FR2 — Where a claim legitimately holds no `touches:`, `./next`'s claimed-files block distinguishes
  that from an undeclared one, so a correct `verify` claim does not read as an under-specified
  `develop` one.
- FR3 — `./claim --help` and `./close --help` print usage and exit zero, matching `./next --help`.
- FR4 — Bare `./next` prints the topmost **takeable** row alongside row 1 whenever the two differ,
  since that is the question the reader is actually asking.
- FR5 — The three installed copies under `.claude/backlog/` are updated from the templates in the
  same change, per `tests/backlog-scripts-installed.test.sh` AC2.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | FR3's usage text documents every mode each script has, as `./next --help` already does | `documentation-conventions.md` |
| Progressive delivery | The scripts ship to every machine installing the plugin; the release is the version bump and the install | `progressive-delivery-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given a claim on a `next: verify` row, when `./claim` succeeds, then its message does
  not instruct the session to set `touches:`.
- [ ] AC2 — Given a claim on a `next: develop` row, when `./claim` succeeds, then its message does
  instruct the session to set `touches:`.
- [ ] AC3 — Given an `in-progress` row claimed at a stage that holds no file scope, when `./next`
  runs, then its claimed-files block says so rather than `none declared — assume held, ask`.
- [ ] AC4 — Given `./claim --help` and `./close --help`, when each is run, then it prints usage and
  exits zero.
- [ ] AC5 — Given a queue whose row 1 is `waiting` and whose topmost takeable row is lower, when
  bare `./next` runs, then it prints both and marks which is takeable.
- [ ] AC6 — Given a queue whose row 1 **is** the topmost takeable row, when bare `./next` runs,
  then it does not print the row twice.
- [ ] AC7 — Given `.claude/backlog/{claim,close,next}` compared against the templates, when
  `tests/backlog-scripts-installed.test.sh` runs, then it passes.
- [ ] AC8 — Given the whole suite, when it runs, then every suite passes.

## QA plan

- **Level:** unit — the deliverables are three shell scripts, and this project's `unit` command runs
  every `tests/*.test.sh`.
- **Why this level:** every AC is a fixture plus one invocation, which the three suites already do.
- **Specific checks:** `tests/claim.test.sh`, `tests/close.test.sh`, `tests/next.test.sh`, then the
  full suite. Exercise the write-scripts against a **clone in the scratchpad**, never a live row in
  the shared table. Confirm each mutation reached the file the harness runs — `tests/next.test.sh`
  resolves its subject through `NEXT_SRC` — since mutating the backlog's own copy instead returns a
  clean pass, which is what a check that cannot fail also returns.

## Out of scope

- **`./next`'s take loop consulting the held file set.** That is 0045, which explicitly parks FR4's
  readability defect as out of its own scope; the two touch `next` and want sequencing rather than
  merging.
- The frontmatter readers' comment and list handling, which is 0044.
- Adding modes to any script.

## Notes & decisions

- Routed to `develop`: three named defects with named fixes and no competing shapes.
- **FR2 is the half that is not ergonomics.** FR1 alone fixes the message and leaves `./next` still
  reporting every correct `verify` claim as ambiguous — which is the part that reaches other
  sessions and makes rows look unsafe. It depends on 0044's decision about what `claim` writes only
  if that ticket changes the field; today it does not, so this is independent.
- Ranked last of this batch. All three are real, all three are inert — nothing degrades while they
  sit — but each is small and clears the deck.
