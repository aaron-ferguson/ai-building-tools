---
id: "0010"
title: Split Status into Next and Status, and pare QUEUE.md
type: chore
next: develop
status: in-progress
qa_level: verify
size: m
created: 2026-08-23
parent: "0009"
blocked_by: []
relates: ["0005"]
claimed_by: "1b2e"
claimed_at: 2026-08-23T14:57:10Z
touches:
  - skills/queue/templates/item.md
  - skills/queue/templates/QUEUE.md
  - skills/design/SKILL.md
  - skills/develop/SKILL.md
  - skills/queue/SKILL.md
  - skills/verify/SKILL.md
  - skills/retro/SKILL.md
  - .claude/backlog/QUEUE.md
  - .claude/backlog/items/   # every item's frontmatter gains next:
---

## Problem

One column is carrying two different facts and they disagree. `design` and `needs-qa` are
*stages* — they say which skill acts next. `ready` and `blocked` are *states* — they say whether
anything can act at all. Merged, a reader cannot filter for "work I can start" without knowing
which values are which, and every new stage adds a value to a list that is already ambiguous.

The same column set carries ranking context that no reader uses at read time. `Type` changes
nobody's behaviour. `Size` is needed only for the row about to be taken, whose file the reader
opens anyway. `QA` is read only by verify, which opens the item for the ACs regardless. `Item`
duplicates `ID`, and the path is the bulk of the row.

This matters because `QUEUE.md` is the file every session reads and every claim and close
rewrites. A row is ~175 characters today and ~95 after; at a hundred rows that is roughly
4,400 tokens per read down to ~2,400, paid back on every one of those operations.

## Functional requirements

- FR1 — The item template carries `next:` (`queue` | `design` | `develop` | `verify`) and
  `status:` (`ready` | `waiting` | `blocked` | `in-progress`) as separate fields.
- FR2 — `waiting` means a **person** is needed; `blocked` means an **open `blocked_by`**. The
  template's prose states the difference and why it is not one value: they are cleared by
  different actions, and merging them forces a ticket read to tell which.
- FR3 — `templates/QUEUE.md` header is `ID | Title | Next | Status | Parent`, with no `Type`,
  `Size`, `QA`, or `Item` column. The ID resolves to `items/<id>-*.md` by glob, and the prose
  says so.
- FR4 — `design` and `needs-qa` no longer exist as statuses. A ticket needing a decision is
  `next: design`; a ticket built and awaiting QA is `next: verify`.
- FR5 — `next: queue` exists and means the ticket is not specified enough for any stage to take
  it — captured half-baked, or found stale by a later stage.
- FR6 — All five skills read and write the two fields, and no skill refers to `design` or
  `needs-qa` as a status.
- FR7 — This repo's own six existing rows are migrated to the new shape in the same change.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The `waiting`/`blocked` distinction and the glob convention are stated where a reader meets them — the template's prose — not only in this ticket. | `documentation-conventions.md` |
| Migration | The existing rows change shape in the same commit as the header that describes them; a header and rows that disagree is a queue no reader can parse. | `migration-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given `templates/item.md`, when it is read, then `next:` and `status:` are separate
      fields and each lists its permitted values in a comment.
- [ ] AC2 — Given `templates/QUEUE.md`, when the header row is read, then it is exactly
      `| ID | Title | Next | Status | Parent |`.
- [ ] AC3 — Given the five `SKILL.md` files, when grepped for `needs-qa` and for `status: design`,
      then there are no matches.
- [ ] AC4 — Given this repo's `QUEUE.md`, when it is read after the change, then every row has a
      `Next` value from FR1 and a `Status` value from FR1, and no row has more or fewer than five
      cells.
- [ ] AC5 — Given the template's prose, when read, then it distinguishes `waiting` from `blocked`
      in terms of who clears it.

## QA plan

- **Level:** verify — documentation and template changes; no runtime.
- **Scripted assertion:**
  `grep -rn 'needs-qa\|status: design' skills/ templates/ && exit 1 || true`, plus
  `head -1 <(grep '^| ID' templates/QUEUE.md)` matching the FR3 string exactly, plus
  `awk -F'|' '/^\| [0-9]/ {if (NF!=7) exit 1}' .claude/backlog/QUEUE.md` for AC4.

## Out of scope

- Removing the `Owner` column. This repo's table already has none; 0007 owns claim tracking, and
  `in-progress` stays a status until it lands.
- The `Parent` column and the `blocked_by` field themselves — 0005 owns those.
- The `./next` reader. It reads the fields this ticket defines and is 0011.

## Notes & decisions

- **This ticket takes over FR3 of 0005.** Both rewrite the same header row, and doing them
  separately means writing that line twice to two contradictory contracts. 0005 keeps its
  frontmatter fields, its container/task prose, its derived-children rule and its no-`epics/`
  rule; its FR3 has been struck with a pointer here.
- **A `Tier` column was considered and rejected.** It is read only when inserting or re-ranking,
  it is already recorded in `RANKING.md`, and that file is read at exactly that moment. Adding a
  permanent column to serve an occasional read is the mistake this ticket is undoing.
- Once this lands the pared table cannot answer a re-rank on its own, so `RANKING.md` must be
  written on every insert. That obligation is recorded in effort 0009.
