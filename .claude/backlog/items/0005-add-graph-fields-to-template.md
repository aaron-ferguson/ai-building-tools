---
id: "0005"
title: Add the graph fields to the ticket template and QUEUE.md
type: chore
next: verify
status: in-progress
qa_level: verify
size: s
created: 2026-08-18
parent: "0002"
blocked_by: []
relates: []
touches: skills/queue/templates/item.md, tests/graph-fields.test.sh
claimed_by: "bb6e"
claimed_at: 2026-08-24T05:34:51Z
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

- **Built 2026-08-24** (token `cae7`). FR1, FR2 and FR4 all land in **one comment block above
  `parent:`** rather than in a separate prose section. The effort/task rule and the derived-children
  rule are what `parent:` *means* — a reader who has the field without them ranks an effort — and a
  template that documents fourteen keys is read key by key, not front to back.

- **AC3 and AC4 were already satisfied and needed no edit.** No `epics/` or `EPICS.md` has ever
  existed, and 0010 had already removed the `Owner` column from `README.md`. This matters beyond
  bookkeeping: **`README.md` is inside 0026's held file scope right now**, so a ticket whose
  Documentation NFR names the README turned out to require no write to it. AC4 is asserted rather
  than produced. The suite carries both assertions so a later edit cannot quietly undo them.

- **The template contradicted itself and the change had to fix that, not just add to it.** The
  `status:` comment described an effort as a *container ticket*, wording the project moved off when
  `QUEUE.md` settled on effort/task. Adding `parent:` with the effort/task rule while leaving
  "container" in place would have left one file naming the same concept two ways. Reconciled in the
  same commit per `documentation-conventions.md`; the suite greps for the retired wording.

- **Both FR2 phrases passed against the *unmodified* template on the first run of the new test** —
  `never ranked, claimed, or built` matched the old `container ticket` comment, and `goes stale`
  matched the `expects:` comment, which is about `expects:` going stale and nothing to do with
  reverse edges. A whole-file grep over a file this dense is close to vacuous. Every phrase
  assertion was rescoped to the **comment block above the key that must carry it**, and the scoping
  was then proved by mutation: moving the effort/task sentence into the `type:` comment — still
  present in the file — reds four assertions. This is the `testing-conventions.md` "wired and still
  cannot fail" case, and the file's own density is what produced it.

- **A phrase that wraps across a comment line cannot be grepped.** `never its dependents` split
  over two `# ` lines and the assertion red on text that was plainly there. Assertions against
  wrapped prose have to sit inside one line; the fix was rewrapping the sentence, not loosening the
  check.

- **FR3 and AC2 handed to 0010** (2026-08-23). 0010 splits `Status` into `Next` + `Status` and
  pares the table in the same edit, so the header row has one owner rather than two tickets
  setting it to different shapes. Nothing else in this ticket changes: the frontmatter fields,
  the container/task prose, the derived-children rule and the no-`epics/` rule are untouched and
  0010 depends on none of them.
