---
id: "0005"
title: Add the graph fields to the ticket template and QUEUE.md
type: chore
next: develop
status: in-progress
qa_level: verify
size: s
created: 2026-08-18
parent: "0002"
blocked_by: []
relates: []
touches:
claimed_by: "cae7"
claimed_at: 2026-08-24T05:25:50Z
---

## Problem

The ticket template has no way to say that one ticket belongs to another or depends on another,
so both facts live only in the head of whoever queued the work. `QUEUE.md` has an `Owner` column
that 0007 removes and no `Parent` column, so a reader cannot see groupings at all.

Nothing downstream can be built until the shape exists: 0006 parses it, 0007 changes the same
header, and 0008 writes rules that cite it.

## Functional requirements

- FR1 — `templates/item.md` frontmatter carries `parent:` (0 or 1 id), `blocked_by:` (list),
  and `relates:` (list), each with a comment stating the stored direction.
- FR2 — The template's prose states the container/task rule: a ticket with children is an effort,
  is never ranked or claimed, and holds outcome and scope; a ticket without children is a task.
- FR3 — *Struck. The header row is now set by 0010, which pares the table to
  `ID | Title | Next | Status | Parent` as part of splitting `Status` into two fields. Both
  tickets rewrite the same line, and to contradictory contracts; one owner avoids writing it
  twice. This ticket keeps the `Parent` column requirement only insofar as 0010 preserves it.*
- FR4 — The template's prose states that children are derived (one `grep`), never stored, and why:
  a stored reverse edge is a second place to update and the one that goes stale.
- FR5 — `epics/`, `EPICS.md`, and any separate effort template are explicitly *not* introduced.
  One `items/` directory and one file format covers both states.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Migration / schema | Additive only. An existing backlog with no `parent:` and a seven-column table stays valid and readable; nothing is rewritten in place. | `migration-conventions.md` |
| Documentation | The README's "What lands in your project" block matches the new shape in the same change. | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given `templates/item.md`, when the frontmatter is read, then `parent`, `blocked_by`,
  and `relates` are present with direction comments.
- [ ] AC2 — *Struck with FR3 — 0010 asserts the header row.*
- [ ] AC3 — Given the plugin tree, when `epics/` or `EPICS.md` is searched for, then neither exists.
- [ ] AC4 — Given `README.md`, when the storage-layout block is read, then it shows no `epics/`
  directory and no `Owner` column.

## QA plan

- **Level:** verify — no test runner applies; this is templates and prose.
- **Why this level:** the change is file content, and every criterion above is a grep.
- **Specific checks:**
  - `grep -c '^parent:\|^blocked_by:\|^relates:' skills/queue/templates/item.md` returns 3
  - `grep 'Parent' skills/queue/templates/QUEUE.md` matches; `grep 'Owner'` does not
  - `test ! -e skills/queue/templates/epics && test ! -e skills/queue/templates/EPICS.md`

## Out of scope

Any behaviour. This ticket ships the shape; 0006 reads it and 0008 enforces it.

## Notes & decisions

- **FR3 and AC2 handed to 0010** (2026-08-23). 0010 splits `Status` into `Next` + `Status` and
  pares the table in the same edit, so the header row has one owner rather than two tickets
  setting it to different shapes. Nothing else in this ticket changes: the frontmatter fields,
  the container/task prose, the derived-children rule and the no-`epics/` rule are untouched and
  0010 depends on none of them.
