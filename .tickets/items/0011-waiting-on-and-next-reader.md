---
id: "0011"
title: Add the Waiting on section and rewrite next for the new fields
type: chore
next: verify
status: done
qa_level: verify
size: m
created: 2026-08-23
closed: 2026-08-23
parent: "0009"
blocked_by: []
relates: ["0006"]
touches:
---

## Problem

A `waiting` row says a human is needed and not what for, so finding out means opening the
ticket — the exact cost the pared table in 0010 exists to remove. And `./next` parses the old
column set, so it stops working the moment 0010 lands.

## Functional requirements

- FR1 — The item template carries a `## Waiting on` section, filled by whoever sets
  `status: waiting`: the specific question, in one or two lines.
- FR2 — `./next <stage>` prints the first row whose `status` is `ready` and whose `next` matches
  the stage, plus that row's `size` read from its item frontmatter.
- FR3 — `./next --waiting` lists every `waiting` row with the first line of its `## Waiting on`
  section, so the set of things needing a person is scannable without opening a ticket.
- FR4 — `./next` with no argument prints the counts by stage and by status.
- FR5 — A row whose `blocked_by` has an open entry is never offered as takeable, whatever its
  status says.
- FR6 — A `waiting` row with no `## Waiting on` section is reported as a defect in the row rather
  than skipped silently.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The reader's modes are discoverable from `./next --help`, not only from this ticket. | `documentation-conventions.md` |

## Acceptance criteria

- [x] AC1 — Given a queue with a `ready`/`develop` row and a `ready`/`design` row, when
      `./next develop` runs, then it prints the develop row and not the design row.
- [x] AC2 — Given a `waiting` row with a `## Waiting on` section, when `./next --waiting` runs,
      then the output contains that section's first line.
- [x] AC3 — Given a `waiting` row with no such section, when `./next --waiting` runs, then it
      names that row as malformed and exits non-zero.
- [x] AC4 — Given a row whose `blocked_by` names an open ticket, when `./next develop` runs, then
      that row is not offered even if its status reads `ready`.
- [x] AC5 — Given no matching row for a stage, when `./next <stage>` runs, then it says so plainly
      and exits zero — an empty stage is not an error.

## QA plan

- **Level:** verify — a shell reader with no test runner.
- **Scripted assertion:** a fixture `QUEUE.md` in a temp directory covering all five ACs, driven
  by a shell script that asserts on stdout and exit code. AC3 and AC5 pin the exit codes
  specifically, because "prints something" and "succeeds" are different claims and only the
  second one callers branch on.

## Out of scope

- The claim-directory awareness 0007 will add. This reader parses fields; it does not yet know
  about claims.

## Notes & decisions

- **Direct collision with 0006**, which rewrites the same script to parse by header name and walk
  ancestors. Both are correct and neither can be applied over the other cleanly. Whichever runs
  second re-reads the first's output rather than its own ticket. Sequence them; do not run both.
- FR2 reading `size` from frontmatter is what allows 0010 to drop the `Size` column: the one row
  a session is about to take is the one row it opens anyway.
- **The reader now refuses a table shape it cannot parse**, rather than printing zero rows. It
  still parses by *position* — header-name parsing is 0006's job and was deliberately not done
  here — but the parked finding against 0010 was about the *silent* failure, not the indices: the
  old script reported "0 ready of 2 rows" against the pared table and a reader would conclude the
  backlog was empty. A loud refusal closes that without taking 0006's scope. **0006 should now be
  re-specified against this shape**: its FR2/AC2 fixtures enumerate seven- and eight-column tables
  that no longer exist.
- **`--waiting` iterates ids, not rows through a pipe.** The first cut set its `bad` counter inside
  a `while read` fed by a pipeline, so the counter died with the subshell and AC3 could never fail.
  Ids carry no whitespace, so a plain `for` keeps the loop in the shell that reads the result.
- The first fixture ranked the blocked-but-`ready` row *below* a takeable one, so the loop broke
  before reaching it and AC4 passed for the wrong reason. A guard about row 1 has to be tested at
  row 1.
- `blocked_by` naming a ticket with **no item file** is treated as open and says so, rather than
  resolving to takeable. A blocker nobody can find is not a blocker anybody cleared.
