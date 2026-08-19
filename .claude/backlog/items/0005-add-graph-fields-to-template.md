---
id: "0005"
title: Add the graph fields to the ticket template and QUEUE.md
type: chore
status: ready
qa_level: verify
size: s
created: 2026-08-18
parent: "0002"
blocked_by: []
relates: []
touches:
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
- FR3 — `templates/QUEUE.md` has a `Parent` column and no `Owner` column, with the header row
  ordered `ID | Title | Type | Size | QA | Status | Parent | Item`.
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
- [ ] AC2 — Given `templates/QUEUE.md`, when the header row is read, then it contains `Parent`
  and does not contain `Owner`.
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
