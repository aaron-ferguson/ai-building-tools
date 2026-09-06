---
id: "0098"
title: Disambiguate the FR citations the 0036 split left behind
type: bug
next: develop
status: ready
qa_level: unit
size: s
created: 2026-09-05
source: agent
parent:
blocked_by: []
relates: ["0067"]
expects:
  - references/REPORTING.md
  - tests/citations.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

`references/REPORTING.md` attributes the same requirement numbering to two different tickets, three
sections apart. Line 37 cites *"0039 FR14"* and line 57 cites *"0036 FR13"*. Both FR13 and FR14 are
**defined only in `items/0039`**, which inherited `0036`'s numbering when `0036` was split into
children.

Neither citation is wrong on its own — `0036` does reference both numbers — but a reader chasing one
of them learns that the numbering is ticket-ambiguous, and has no way to tell which list a third
citation means. `0074` AC7 pins the `0036` spelling; nothing pins the other, so the two are free to
drift further.

This is citation drift the `0036` split created, and it is not specific to this file: **any**
reference to an FR number in the `0036`/`0039` pair needs saying which ticket's list it means.

## Functional requirements

- FR1 — Every FR citation in the repository naming a number from the `0036`/`0039` pair resolves to
  the ticket that **defines** that FR, which is `0039`.
- FR2 — Where a citation is deliberately kept in the `0036` spelling because a guard pins it —
  `0074` AC7 is the known case — it says so inline, so the inconsistency reads as a decision rather
  than as the next instance of the drift.
- FR3 — `tests/citations.test.sh` gains a case asserting FR1: an FR number from that pair cited
  against a ticket that does not define it fails the guard. This is the code behind FR1, without
  which the rule holds only until the next edit.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The rule recorded is the general one — a citation names the ticket that defines the FR — not a list of the two lines fixed today | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given `references/REPORTING.md`, when its two FR citations are read, then both name the
  ticket that defines the FR. Red-making input: today's file, where line 37 says `0039 FR14` and line
  57 says `0036 FR13` for numbers defined in the same list.
- [ ] AC2 — Given a file citing `0036 FR13`, when `tests/citations.test.sh` runs, then it fails and
  names the file and the citation. Red-making input: today's suite, which passes on that string.
- [ ] AC3 — Given a file citing `0039 FR13`, when `tests/citations.test.sh` runs, then it passes.
  Red-making mutation: matching on the FR number alone, which would fail every correct citation too.
- [ ] AC4 — Given `0074`'s AC7 and whatever else pins the `0036` spelling, when the repository is
  searched after the change, then each surviving `0036 FR` citation carries an inline note saying
  what pins it. Red if any survives bare.
- [ ] AC5 — Given the whole suite after the change, when it is run file-by-file, then every file
  reports `0 failed`.

## QA plan

- **Why that level:** the deliverable is a guard case plus the citations it forces correct; the
  runner is the suite.
- **Specific checks:** `tests/citations.test.sh` individually, then the whole suite file-by-file.
  AC3 is the one to watch — a guard that fails every citation of FR13 is worse than the drift.

## Out of scope

- The shape a cross-cutting rename takes in the backlog — that is `0067`, and this item fixes one
  instance rather than deciding the general procedure.
- Renumbering `0039`'s FRs. They are correct; what drifted is who is credited with them.
- Any other reference file's citations, unless FR1's guard finds one.

## Notes & decisions

- Routed to `develop`: which ticket defines FR13 and FR14 is a fact discoverable by reading
  `items/0039`, not a decision.
- FR2 exists because the obvious fix — rewrite every `0036 FR` citation — would red `0074` AC7,
  which is another ticket's guard. `queue` Step 2's rule about checking absence assertions against
  the guards already shipped is what caught it.
