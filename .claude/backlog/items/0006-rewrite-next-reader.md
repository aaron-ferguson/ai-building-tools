---
id: "0006"
title: Rewrite next to parse by header name and walk ancestors
type: chore
next: develop
status: blocked
qa_level: verify
size: m
created: 2026-08-18
parent: "0002"
blocked_by: ["0005", "0007"]
relates: ["0007", "0022", "0023", "0024", "0026"]
expects:
  - skills/queue/templates/next
  - skills/queue/templates/claim
  - skills/queue/templates/close
  - skills/queue/SKILL.md
  - .claude/backlog/next
  - .claude/backlog/claim
  - .claude/backlog/close
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
- FR8 — **This project's own backlog runs all three scripts, not just ships them.** `next`, `claim`
  and `close` are instantiated into `.claude/backlog/` from the templates and made executable, so a
  close here reconciles its dependents automatically instead of by hand. The template is still the
  authority: the local copies are copies, and a divergence between them is a defect in whichever
  drifted, not a local variant. FR7 is unchanged by this — instantiating is the develop session
  copying a file, never `next` acquiring the power to write.

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
- [ ] AC8 — Given this repo after the change, when each of `.claude/backlog/next`, `claim` and
  `close` is tested with `test -x`, then all three exist and are executable, and `diff` against the
  corresponding `skills/queue/templates/` file reports no difference.
- [ ] AC9 — Given a fixture backlog where ticket B has `blocked_by: ["A"]` and A is at
  `next: verify` under a held claim, when `close` is run on A, then B's item frontmatter and its
  `QUEUE.md` row both read `ready`, and both edits are in `close`'s own commit.

## QA plan

- **Level:** verify — no test runner exists in this project, and adding one for a POSIX shell
  script is not warranted.
- **Why this level:** every criterion is a scripted assertion against a fixture backlog. Fixtures
  live in `skills/queue/templates/fixtures/`, and the assertion script is committed with them so
  the check is repeatable rather than a one-off.
- **Specific checks:** run `next` and `next --check` against each fixture, diffing against expected
  output files; `wc -l` comparison for AC7; `test -x` plus `diff` against the templates for AC8; a
  throwaway fixture backlog exercised through `claim` then `close` for AC9, asserting on the
  dependent's status in both files and on `git show --stat` for the commit's paths.

## Out of scope

Any writing *by `next`*. It stays a reader — that guarantee is why it is safe to run in a second
window, and FR8 does not touch it: `claim` and `close` write, `next` does not, and instantiating all
three changes which scripts exist here rather than what any one of them may do.

Backfilling the reconcile the hand-closes already missed. Only 0026 drifted and it is already
reconciled; a sweep for historical misses is `./next --drift` on the day the scripts land, not work
this ticket owns.

## Notes & decisions

- 2026-08-23 — **FR8 folded in here rather than given its own ticket**, on Aaron's call. The
  reconcile hook already exists in `skills/queue/templates/close` and is well guarded; nothing was
  missing from the design, only from this backlog, which has never had the three scripts
  instantiated. Every hand-close therefore skips the reconcile — that is how closing 0022 left 0026
  reading `blocked` for three subsequent closes with nothing reporting it (parked in `FINDINGS.md`).
- 2026-08-23 — **0006 is the first point where all three can be instantiated coherently**, which is
  the substantive argument for folding rather than a separate ticket. `claim` and `close` test
  ownership by the `claimed_by:` frontmatter token; this backlog's `QUEUE.md` and FR6 both say a
  claim is the directory `claims/<id>/`. Those are two live protocols (parked twice in
  `FINDINGS.md`), and the one that settles it is 0007 — already in this ticket's `blocked_by`. So
  the instantiation lands after the collision is resolved, and a separate ticket would have had to
  be blocked on 0007 anyway.
- 2026-08-23 — **The cost of folding, stated plainly:** the reconcile does not start working here
  until 0006 clears, and 0006 sits behind 0005 and then 0007. Closes in this backlog stay by-hand
  until then, so `./next --drift` cannot be the safety net either — it is one of the files being
  instantiated. Until 0006 lands, a hand-close must reconcile its dependents in the same commit by
  reading `blocked_by` across `items/`, which is what this session did for 0026.
- 2026-08-23 — **Rejected: naming the blocking ticket in `QUEUE.md`'s `Status` column** (asked in the
  same conversation). It widens the cache the whole of 0024 exists to distrust, does not fit the
  multi-blocker rows (0006 itself, 0004), forces `close`'s whole-cell status replace to compute a set
  difference, and changes no reader's behaviour at read time — the test that removed `Type`, `Size`,
  `QA` and `Item`. The real need underneath it was seeing the dependency *shape*, and FR4 `--tree`
  and FR5 `--check` already cover it.
