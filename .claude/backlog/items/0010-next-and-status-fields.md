---
id: "0010"
title: Split Status into Next and Status, and pare QUEUE.md
type: chore
next:
status: done
closed: 2026-08-23
qa_level: verify
size: m
created: 2026-08-23
parent: "0009"
blocked_by: []
relates: ["0005"]
claimed_by: "1b2e"
claimed_at: 2026-08-23T14:57:10Z
touches:
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
- FR3 — `skills/queue/templates/QUEUE.md` header is `ID | Title | Next | Status | Parent`, with no `Type`,
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

- [x] AC1 — Given `skills/queue/templates/item.md`, when it is read, then `next:` and `status:` are separate
      fields and each lists its permitted values in a comment.
- [x] AC2 — Given `skills/queue/templates/QUEUE.md`, when the header row is read, then it is exactly
      `| ID | Title | Next | Status | Parent |`.
- [x] AC3 — Given the five `SKILL.md` files, when grepped for `needs-qa` and for `status: design`,
      then there are no matches.
- [x] AC4 — Given this repo's `QUEUE.md`, when it is read after the change, then every row has a
      `Next` value from FR1 and a `Status` value from FR1, and no row has more or fewer than five
      cells.
- [x] AC5 — Given the template's prose, when read, then it distinguishes `waiting` from `blocked`
      in terms of who clears it.

## QA plan

- **Level:** verify — documentation and template changes; no runtime.
- **Scripted assertion:** one check per AC, run from the repo root. There is no `templates/` at
  the root — the templates live in `skills/queue/templates/`, so a single `grep -rn` over
  `skills/` covers both the skills and the templates.
  - AC1 — `grep -qE '^next: .*queue.*design.*develop.*verify' skills/queue/templates/item.md`
    and the same for `^status: .*ready.*waiting.*blocked.*in-progress`
  - AC2 — `grep -m1 '^| ID' skills/queue/templates/QUEUE.md` equals
    `| ID | Title | Next | Status | Parent |` exactly
  - AC3 — `grep -rn 'needs-qa\|status: design\|^Statuses:' skills/` returns nothing.
    **The pattern must not match `design` as a stage** — an earlier draft grepped for
    `` `design` ( `` and failed on the correct new prose describing the `design` stage.
  - AC4 — `awk -F'|' '/^\| [0-9]/ {if (NF!=7) exit 1}' .claude/backlog/QUEUE.md` for the cell
    count, plus an awk pass asserting `$4` is a valid `Next` and `$5` a valid `Status`
  - AC5 — `skills/queue/templates/QUEUE.md` prose names `waiting` and ties it to a person

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
  written on every insert. That obligation is recorded in project 0009.

### What this item ran into

- **FR3 and *Out of scope* contradicted each other, and FR3 won.** *Out of scope* deferred
  removing the `Owner` column to 0007 on the grounds that "this repo's table already has none" —
  true of `.claude/backlog/QUEUE.md`, false of the shipped `skills/queue/templates/QUEUE.md`,
  which still had `Owner` and no `Parent`. FR3 and AC2 pin the header string exactly, so the
  template lost the column here. What was *not* done is 0007's actual work: the claim-directory
  mechanism is untouched, and the token's home is now stated as the item's `claimed_by:`.
- **This landed 0005's `grep 'Owner'` AC as a side effect**, consistent with 0010 having taken
  over 0005's FR3. 0005 keeps its frontmatter fields and its container/task prose.
- **FR1's four status values were not all of them.** `develop` Step 6 writes `status: done`,
  containers carry `active`, and `SCHEDULED.md` rows carry `scheduled`. Enumerating four would
  have made the template false about three files in this repo, so the comment names the terminal
  value and the two off-rank ones. A container's `next:` stays empty — no stage acts on it.
- **FR7 said "six existing rows"; there were 18.** The 0009 capture (commit 322ae25) landed twelve
  more after the ticket was written. All 18 migrated; every one is `next: develop`, since each
  already carries ACs.
- **The first version of the AC3 assertion was wrong, not the code.** It grepped for
  `` `design` ( `` as a proxy for "design used as a status" and false-positived on the correct new
  prose describing the `design` *stage*. Fixed in the assertion; the QA plan above now says why the
  pattern is narrow.
- **Both shipped scripts read status by fixed column index (`$7`) and are broken by the pared
  table.** `next` is deferred to 0011 by this item's *Out of scope*; `claim` is owned by no ticket
  at all. Parked in `FINDINGS.md` rather than fixed here, along with the 0006/0011 overlap on the
  same reader and 0006's now-stale fixture shapes.
- **`references/CONCURRENCY.md` was corrected in the same change**, per
  `documentation-conventions.md`: it said `develop` "writes it in the `Owner` column", which this
  ticket made false. Two further prose references — `verify` Step 2 and `queue`'s rerank rule —
  were corrected the same way.
- **`.claude/backlog/FINDINGS.md` was seeded from its shipped template** so the findings above had
  somewhere to go. 0012 still owns the skill-side rule that every session parks what surprised it.
