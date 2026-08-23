---
id: "0022"
title: Fix claim's fixed-index column parsing against the pared table
type: bug
next: develop
status: in-progress
qa_level: verify
size: s
created: 2026-08-23
parent: "0002"
blocked_by: []
relates: ["0006", "0010", "0011"]
source: agent
expects:
  - skills/queue/templates/claim
touches:
  - skills/queue/templates/claim
claimed_by: "b7f6"
claimed_at: 2026-08-23T17:13:25Z
---

## Problem

`0010` pared `QUEUE.md` to `ID | Title | Next | Status | Parent`. `skills/queue/templates/claim`
reads the row's status from `$7` and its owner from `$8` by fixed column index, so on a
five-column table both are empty and **every claim is refused**, including a genuinely `ready`
row:

```
$ .claude/backlog/claim 0001
0001 is '' (owner ), not ready — pick another row
```

Verified against a throwaway five-column fixture scaffolded from the new template. The failure is
safe — it never claims a blocked row — but it is silent: nothing errors, and the message blames
the row rather than the parser. A session's honest reading is "the backlog has nothing takeable."

No ticket owns `claim`. `0011` and `0006` both name only `next`, so this would have shipped with
the scaffold unowned. Nothing in flight is broken today: this repo's own backlog has neither
script installed, so the breakage reaches only a newly scaffolded project.

## Functional requirements

- FR1 — `claim` resolves `Status` by matching the header row's cell name, not by index, so it
  works against the five-column table and any future column order.
- FR2 — A table with no `Status` column is an explicit error naming the header it found, never a
  silent refusal of every row.
- FR3 — Ownership is no longer read from a column. `claim` reports the row's `Status` and defers
  to the item's `claimed_by:` for the token, per `references/CONCURRENCY.md`.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The parse-by-name rule is stated in the script's own header comment, where the next editor meets it. | `documentation-conventions.md` |
| Migration | A seven- or eight-column table from a project scaffolded before `0010` still claims correctly; the column set is discovered, not assumed. | `migration-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given a five-column `QUEUE.md` with a `ready` row, when `claim <id>` runs, then the
      row is set `in-progress`, the frontmatter is written, and the change is committed.
- [ ] AC2 — Given that same table with a `blocked` row, when `claim <id>` runs, then it refuses
      and names the actual status (`blocked`), not the empty string.
- [ ] AC3 — Given a pre-`0010` eight-column table, when `claim <id>` runs on a `ready` row, then
      it still succeeds.
- [ ] AC4 — Given a table whose header has no `Status` cell, when `claim` runs, then it exits
      non-zero quoting the header it found.

## QA plan

- **Level:** verify — a shell script with no runner in the project.
- **Scripted assertion:** a throwaway git repo per AC, scaffolded with the relevant table shape,
  running `claim` and asserting on its exit code, its message, and the resulting row. Remove each
  fixture in the same turn it is created.

## Out of scope

- `next`, which has the identical defect at `$7`/`$8`. `0011` owns it, and `0006` re-specifies it
  to parse by header name — this ticket is the same fix for `claim`, which neither covers.
- The claim-directory mechanism itself. `0007` owns that.

## Notes & decisions

- Found while verifying `0010`, by testing the shipped scripts against a fixture rather than by
  any of that item's acceptance criteria — none of which could have covered a file the item did
  not touch. Parked in `FINDINGS.md` at the time.
