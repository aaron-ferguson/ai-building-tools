---
id: "0096"
title: Make the frontmatter path lists checkable to read and safe to edit
type: bug
next: develop
status: ready
qa_level: unit
size: m
created: 2026-09-05
source: agent
parent:
blocked_by: []
relates: ["0045"]
expects:
  - skills/queue/templates/next
  - .claude/backlog/next
  - skills/queue/templates/item.md
  - skills/develop/SKILL.md
  - tests/next.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

Two independent defects in the same two frontmatter fields, `expects:` and `touches:`.

1. **A path that never matched any file is never reported.** `0085`'s `expects:` listed
   `.claude/backlog/items/0048-remaining-backlog-write-sites.md` and
   `.claude/backlog/items/0066-three-wrong-answers-in-the-scripts.md`. Neither is a real filename —
   the files are `0048-scripts-for-the-remaining-write-sites.md` and
   `0066-backlog-script-ergonomics.md` — so a session opening `0085` and reading its `expects:`
   verbatim gets *"file does not exist"* for both. Both were title-guessed slugs that drifted from
   the real ones at the moment they were written. `expects:` is triage, not protection, so this cost
   one failed read rather than anything worse; but a field whose whole job is pointing a later
   session at the right files is silently wrong from birth and nothing catches it. `touches:` is the
   same field shape with a higher price — it is what another window reads as *held*.

2. **A substring edit anchored on the lists' shared last entry writes the wrong block.**
   `expects:` and `touches:` usually end with the same entry, and `expects:` is the block that abuts
   `claimed_by:`. Widening a `touches:` list with an `Edit` matching
   `"  - tests/claim.test.sh\nclaimed_by:"` therefore appended to `expects:` instead — the anchor was
   unique and wrong. It committed cleanly and read correctly in isolation. The safe anchor is the key
   that **follows** the block (`---` for `touches:`), never a shared entry.

## Functional requirements

- FR1 — `./next` gains a check that reports any `expects:` or `touches:` entry in a live item that
  matches no file in the repository, naming the item and the entry. It is a report, not a refusal:
  the fields are advisory and a stale entry must not make a row untakeable.
- FR2 — The check runs in an existing mode rather than a new one — `--drift`, which already exists to
  report where a cached fact and the truth disagree — so a session gets it without knowing to ask.
- FR3 — `skills/queue/templates/item.md` states the anchoring rule for both fields: anchor a
  frontmatter list edit on the key that **follows** the block, never on an entry the two lists may
  share.
- FR4 — `develop` Step 1, which is where `touches:` is widened, states the same rule by citation
  rather than by copy.
- FR5 — `tests/next.test.sh` asserts FR1 and FR2 against a fixture item carrying one resolvable and
  one unresolvable path.
- FR6 — The change lands in both `skills/queue/templates/next` and `.claude/backlog/next`, so
  `tests/backlog-scripts-installed.test.sh` stays green.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | FR3's rule states the failure it prevents — that the wrong block is written and the commit reads correctly — not just the correcting form | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given a live item whose `expects:` names `items/0048-remaining-backlog-write-sites.md`,
  when `./next --drift` runs, then it names that item and that entry. Red-making input: today's
  `next`, which reports nothing.
- [ ] AC2 — Given a live item whose `expects:` entries all resolve, when `./next --drift` runs, then
  it reports nothing about that item. Red-making mutation: matching on the literal string rather than
  testing the path, which would report every entry.
- [ ] AC3 — Given the item from AC1, when `./next develop` runs, then that row is still offered.
  Red-making mutation: turning FR1's report into a refusal, which makes an advisory field
  load-bearing.
- [ ] AC4 — Given `skills/queue/templates/item.md`, when the `expects:`/`touches:` comments are read,
  then the anchoring rule names the following key as the anchor. Red-making mutation: replacing
  "follows" with "precedes", which the guard asserting the rule reddens.
- [ ] AC5 — Given `skills/develop/SKILL.md` Step 1, when it is searched for the anchoring rule, then
  it cites `item.md` and does not restate it. Red if both files carry the full rule — that is the
  drift FR4 forbids.
- [ ] AC6 — Given both copies of `next`, when `tests/backlog-scripts-installed.test.sh` runs, then it
  reports `0 failed`.

## QA plan

- **Why that level:** FR1, FR2, FR5 and FR6 are a script change with an existing suite. FR3 and FR4
  are prose, covered by the greps AC4 and AC5 name and run in the same pass.
- **Specific checks:** `tests/next.test.sh` and `tests/backlog-scripts-installed.test.sh`
  individually, then the whole suite file-by-file. AC3 matters most — confirm a row with an
  unresolvable `expects:` is still offered by `./next develop`.

## Out of scope

- Crossing the take loop against the held file set — that is `0045`, and this item reports on a
  field's entries rather than on what they collide with.
- Fixing `0085`'s two wrong entries. `0085` is closed; nobody will read it, and a closed item is the
  trap `CONCURRENCY.md` names under *A session with no ticket writes only what is unheld*.
- Making `queue` verify `expects:` at write time. That would put a filesystem check in the one step
  where the files may not exist yet.

## Notes & decisions

- Routed to `develop`: `--drift` already exists and already means "cache and truth disagree", so the
  home for FR1 follows from a settled contract rather than an open one.
- Filed as one ticket because both defects are in the same two fields and the same template comment
  block, and a session fixing either is already reading the other.
