---
id: "0006"
title: Rewrite next to parse by header name and walk ancestors
type: chore
status: blocked
qa_level: verify
size: m
created: 2026-08-18
parent: "0002"
blocked_by: ["0005", "0007"]
relates: []
touches:
---

## Problem

`next` reads cells by fixed column index (`$2`–`$8`). Adding `Parent` and removing `Owner` shifts
every field, so the current script silently reports wrong values rather than failing — the worst
failure mode available, since its whole job is telling a session what to work on.

Bumping the indices would fix today and break on the next column. Resolving positions from the
header row by name fixes it permanently and makes the script tolerate both the old seven-column
and new eight-column tables, which matters because this plugin installs from a marketplace and
other people's backlogs will not migrate on our schedule.

The script also cannot answer the questions the graph makes answerable: what is above this ticket,
and is the rank consistent with the dependencies.

## Functional requirements

- FR1 — Column positions resolve from the header row by name. An unknown column is ignored rather
  than shifting the others; a missing expected column degrades that field to empty rather than
  erroring.
- FR2 — Both the seven-column (`Owner`, no `Parent`) and eight-column (`Parent`, no `Owner`) tables
  parse correctly.
- FR3 — Output stays fixed-size regardless of backlog length: `ROW 1`, `TAKE`, `COUNTS`, plus an
  `EFFORT` line for the take row's immediate parent when it has one, and a `DUE` line only when
  `SCHEDULED.md` holds a woken row.
- FR4 — `--tree <id>` prints the subtree of one ticket. This is the only mode whose output grows.
- FR5 — `--check` reports, without writing anything: rank inversions (a blocker ranked below what
  it blocks), `ready` rows with an open blocker, dependency cycles, `Parent` cells disagreeing with
  the ticket's `parent:` frontmatter, and `ships: together` efforts with closed tasks and stranded
  siblings.
- FR6 — Claimed tickets are read from `claims/`, not from a table column.
- FR7 — The script writes nothing, takes no lock, and decides nothing.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Performance | Reverse edges (children, dependents) resolve by `grep` over `items/`, not by a stored index that could drift. Must stay responsive at 300 tickets. | `observability-conventions.md` |
| Migration / schema | FR2 is the migration guarantee: readers tolerate the old shape before any writer produces the new one. | `migration-conventions.md` |
| Documentation | The header comment states why parsing is by name — the next person to add a column needs the reason, not just the rule. | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given a fixture eight-column `QUEUE.md`, when `next` runs, then `ROW 1` and `TAKE`
  report the correct ID, title, size, QA and status.
- [ ] AC2 — Given a fixture seven-column `QUEUE.md` with an `Owner` column, when `next` runs, then
  it reports the same fields correctly and does not error.
- [ ] AC3 — Given a fixture with a column inserted in an unexpected position, when `next` runs,
  then output is unchanged.
- [ ] AC4 — Given a take row whose `parent:` is set, when `next` runs, then an `EFFORT` line names
  the parent and its done/total child counts.
- [ ] AC5 — Given a fixture where a blocker is ranked below the ticket it blocks, when
  `next --check` runs, then the inversion is reported with both IDs.
- [ ] AC6 — Given a fixture with a dependency cycle, when `next --check` runs, then the cycle is
  reported and the script exits non-zero.
- [ ] AC7 — Given a 300-row fixture, when `next` runs, then output line count is identical to the
  6-row fixture's.

## QA plan

- **Level:** verify — no test runner exists in this project, and adding one for a POSIX shell
  script is not warranted.
- **Why this level:** every criterion is a scripted assertion against a fixture backlog. Fixtures
  live in `skills/queue/templates/fixtures/`, and the assertion script is committed with them so
  the check is repeatable rather than a one-off.
- **Specific checks:** run `next` and `next --check` against each fixture, diffing against expected
  output files; `wc -l` comparison for AC7.

## Out of scope

Any writing. `next` stays a reader — that guarantee is why it is safe to run in a second window.

## Notes & decisions
