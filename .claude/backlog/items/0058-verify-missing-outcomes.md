---
id: "0058"
title: Give verify the outcomes its steps assume can never happen
type: bug
next: develop
status: ready
qa_level: verify
size: m
created: 2026-08-25
source: agent
parent:
blocked_by: []
relates: ["0005", "0026", "0027", "0050"]
expects:
  - skills/verify/SKILL.md
  - references/CONCURRENCY.md
  - tests/citations.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

Four cases `verify` meets in practice and has no written outcome for. Each was resolved by
inference, and inference is what the skill exists to remove.

**Every row at the stage is already held.** `./next verify` offered `TAKE 0026`; ninety seconds
later all five `next: verify` rows were held by a single batched pass that minted one token per row.
Nothing was at risk — `./next` degraded well and `./claim` re-reads under the lock and refuses an
`in-progress` row — but Step 1 reads as though a row is always waiting. It covers refusing a row at
the *wrong stage*, and having *no backlog at all*, and this is neither. Stopping and reporting is
the only correct move and it is inferred, not written. The harder the suite pushes batching, the
more often a second verify session opens onto nothing.

**Step 3 tells you to mutate files the ticket does not hold, and `CONCURRENCY.md` forbids exactly
that.** 0005's AC4 asserts on `README.md`, which is not in 0005's `touches:` — so proving that AC
meant editing and reverting a file another live session listed in its `expects:`. No work was lost,
by luck of timing. The two rules give no way to satisfy both.

**Exercising a write-script has no safe method while another session holds the backlog.** 0027's
AC5 asks for a live `./claim` on "a scratch row", which means inserting and removing a row in the
shared `QUEUE.md` — while a `develop` session was mid-ticket on 0028 in the same table. Neither
Step 2 nor Step 5 covers it. Resolved by cloning the repo to the scratchpad and exercising `claim`
and `close` there, which tests the same bytes without touching a live table.

**A verdict that quotes the string it is failing the ticket for re-publishes it.** 0026 failed its
privacy NFR for two transcript-store slugs at named lines; explaining the failure quoted both again,
so the leak became four occurrences and the two the verdict itself added sat in the section a reader
trusts most. Redacting only the lines it named would have left the repo failing its own guard.
Describing a leaked value — "one for this repository, one for the parent workspace" — identifies the
defect exactly as precisely as quoting it.

## Functional requirements

- FR1 — Step 1 names the outcome for "every row at my stage is held": stop and report, distinct from
  the wrong-stage refusal and from having no backlog.
- FR2 — Step 3 states what to do when an AC asserts on a file outside the ticket's `touches:` —
  either add the file to `touches:` before mutating it, or verify by direct observation instead of
  by mutation — and cites `CONCURRENCY.md` *A stage writes only the ticket it holds*.
- FR3 — Step 3 names the method for exercising a write-script that mutates shared state: a clone in
  a scratch directory, never a live row in the shared table.
- FR4 — The verdict step states that a leaked value is **described, never quoted**, so the verdict
  does not republish what it is failing the ticket for.
- FR5 — Every rule added cites its convention rather than restating it, and each citation resolves
  under `tests/citations.test.sh`.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Privacy & data | FR4 is the privacy rule itself; the change must be written without reproducing either leaked slug, and checked with a `git grep` over the whole change including this item file — a ticket's own prose sits outside every guard the ticket writes | `data-privacy-conventions.md` |
| Documentation | FR2 cites the concurrency rule rather than copying it | `documentation-conventions.md` |
| Progressive delivery | This skill ships to every machine installing the plugin | `progressive-delivery-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given Step 1, when read, then it names the every-row-held outcome separately from the
  wrong-stage and no-backlog cases.
- [ ] AC2 — Given Step 3, when read, then it states how to verify an AC asserting on a file outside
  `touches:`.
- [ ] AC3 — Given Step 3, when read, then it names the scratch-clone method for exercising a
  write-script.
- [ ] AC4 — Given the verdict step, when read, then it says a leaked value is described rather than
  quoted.
- [ ] AC5 — Given the whole change, when `git grep` is run over every file it touches — this item
  file included — for a transcript-store path segment, then none is present.
- [ ] AC6 — Given every citation added, when `tests/citations.test.sh` runs, then each resolves.
- [ ] AC7 — Given the whole suite, when it runs, then every suite passes.

## QA plan

- **Level:** verify — the deliverable is prose in two files and no test runner applies; the
  scripted assertions are the scoped greps below plus the citation guard and AC5's `git grep`.
- **Why this level:** nothing executable changes.
- **Specific checks:** each grep **scoped to the step it asserts on**, matching a phrase short
  enough to sit on one source line. AC5 runs over the full change, not the deliverable alone. Then
  `tests/citations.test.sh` and the full suite.

## Out of scope

- **The batching rule's breadth**, which is what makes the every-row-held case common. That is
  0059; FR1 is worth landing whatever that decides.
- **Whether Step 3's mutation requirement should exist at all.** It should; FR2 only makes it
  satisfiable alongside the ownership rule.
- Automating the scratch clone.

## Notes & decisions

- Routed to `develop`: each case has a method that was used successfully and recorded. FR2 offers
  two acceptable resolutions because which applies depends on the AC, and both satisfy the
  ownership rule — that is a build-time choice, not an open decision.
- FR4 is stated as a rule about the verdict rather than about privacy generally, because the failure
  was specific: the leak arrived from the direction of *explaining* it, in the one section written
  to be trusted.
