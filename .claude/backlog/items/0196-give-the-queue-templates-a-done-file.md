---
id: "0196"
title: Ship a DONE.md template so a freshly scaffolded backlog can close a ticket
type: bug
next: verify
status: in-progress
qa_level: unit
close_by: verify
qa_manual:
size: s
created: 2026-10-09
source: agent
parent:
blocked_by: []
relates: ["0161"]
expects:
  - skills/queue/templates/DONE.md
claimed_by: "7074"
claimed_at: 2026-10-25T22:58:23Z
touches:
---

## Problem

Parked 2026-10-08 from quantum-catan's first scaffold: `skills/queue/SKILL.md` Step 0 says to scaffold
"by copying every template above" and lists `DONE.md` in the storage layout and among the project-owned
files seeded at scaffold, but `skills/queue/templates/` has no `DONE.md`. `./close` then exits "no
DONE.md … nowhere to move the row to", and needs a table header with an `ID` cell. The capturing
session had to invent one, reading the columns off `close`'s awk (ID, Title, Type, QA, Closed).

## Functional requirements

- FR1 — `skills/queue/templates/DONE.md` exists with a header table whose columns are exactly the ones
  `templates/close` writes, read from `close`, not restated from this ticket.
- FR2 — A test scaffolds a backlog from `skills/queue/templates/` alone into a temp repo, captures a
  row, and `./close` moves it into `DONE.md` with exit 0.

## Acceptance criteria

- [ ] AC1 — FR2's test passes. Red: delete `templates/DONE.md` → `close` exits non-zero naming DONE.md.
- [ ] AC2 — Red: change one header cell in `templates/DONE.md` that `close` keys on → the test fails.

## QA plan

Unit: the configured suite.

## Out of scope

- Migrating backlogs that already invented their own `DONE.md`.

## Notes & decisions

- 2026-10-09 — Filed by retro from the tools `FINDINGS.md` entry of 2026-10-08.

- 2026-10-24 — Absorbed by retro (second leg of AetherWorks run-20261024T195310Z's tail): parked again 2026-10-19: `close` line ~88 refuses with no `DONE.md`, and `skills/queue/templates/` still has none. No new evidence beyond the Problem section.

- 2026-10-25 — Built [da05], develop. `skills/queue/templates/DONE.md` carries
  `| ID | Title | Type | QA | Closed | Item |`, read off `templates/close`'s DONE.md writer (the
  `v == "ID"` … `v == "Item"` arms), the same six this repo's own `DONE.md` uses. `Closed` chosen over
  its aliases `Completed`/`Date` to match this repo. FR2 is `tests/scaffold-close.test.sh` (new): it
  `cp`s `skills/queue/templates/*` and nothing else into a temp repo, appends one QUEUE row under the
  template header (the template's blank placeholder row left in place; close tolerates it), writes
  the item by heredoc, closes, and asserts exit 0 plus the whole DONE row cell for cell. **The whole
  row, not "a row with the id", is what makes AC2 falsifiable**: close fills an unrecognised column
  blank, prints a `note:` and still exits 0, so a renamed `Closed`/`Title`/`Type`/`QA`/`Item` shows
  only as an empty cell. Fixture id 9901, titled "Scaffold fixture row".
- Mutations, all **run** against committed `40bcc52`, each restored with `git checkout --`, control
  green after (3/0), tree clean:

  | AC clause | mutation | result |
  |---|---|---|
  | AC1 "delete `templates/DONE.md` → `close` exits non-zero naming DONE.md" | `mv` the template away | red, 2 fails; close says `no DONE.md at …` |
  | AC2 "change one header cell … that `close` keys on" | rename `ID` → `XID` | red, 2 fails (close: no table header) |
  | AC2, same | rename `Title`, `Type`, `QA`, `Closed`, `Item` each to `X<name>` | red, 2 fails each (exit 0, cell blank) |

- Whole suite: one red, mine — `tests/citations.test.sh` (0046) requires README.md's guard block to
  list every suite; added the line in `4b6306c`, citations then 51/0. All other suites green.
- Review checklist: the test is one flat sequence, no nesting beyond a case/if; abort block copied
  byte-identical from `close.test.sh`. Nothing surprised me beyond the README guard, which is an
  existing documented guard rather than a finding.
