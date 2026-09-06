---
id: "0100"
title: Give the two findings markers a greppable form and count them
type: feature
next: develop
status: ready
qa_level: unit
size: s
created: 2026-09-05
source: agent
parent:
blocked_by: []
relates: ["0060", "0080"]
expects:
  - skills/retro/SKILL.md
  - skills/queue/SKILL.md
  - skills/queue/templates/next
  - .claude/backlog/next
  - skills/queue/templates/FINDINGS.md
  - tests/next.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

`FINDINGS.md` has two sweepers and two markers a sweeper leaves on an entry it did not fully
discharge:

- **deferred / already filed** — `retro` Step 1 gives it a form: *"filed as item 0108; kept for the
  lesson, do not re-file"*, and `queue` Step 5 names the same convention from the other side.
- **no destination exists** — `retro` Step 1 says only that *"needs a row, none exists"* is a useful
  marker and a wrong one is worse than none. That is prose, not a form.

Draining an 84-entry buffer at 10.5× the threshold, 40 entries resolved to an existing row and **15
did not**. For those 15 the wording was invented on the spot, and the next retro will invent a
different one. Today's `FINDINGS.md` already carries three spellings of the same marker — *"read and
triaged 2026-09-05 by retro: no destination exists yet, needs a row"*, *"This still needs a row; none
exists"*, and a bare *"needs a row"*.

Both markers want to be greppable, because **the count of each is what says whether the retros are
keeping up** — an entry that has waited through three sweeps with no destination is a different
signal from one filed last week. `./next --findings` already counts entries against
`findings_threshold`; it cannot distinguish a fresh entry from one that has been triaged twice.

## Functional requirements

- FR1 — `retro` Step 1 and `queue` Step 5 state one canonical form for each marker, written as a
  form to copy rather than as a description, and neither restates the other's — one states it and
  the other cites.
- FR2 — Both forms are greppable from a line: a fixed leading token, the date, and then free text.
- FR3 — `./next --findings` reports the two marker counts alongside the entry count it already
  gives. This is the code behind FR2; a form nothing counts is a convention with no reader.
- FR4 — `skills/queue/templates/FINDINGS.md`, the header every scaffolded backlog gets, documents
  both forms next to the entry format it already specifies, since that header is what a session
  actually reads before appending.
- FR5 — The three spellings already in this repo's `FINDINGS.md` are normalised to the canonical
  form as part of the change, or the entries carrying them are removed by the sweep that files them.
- FR6 — `tests/next.test.sh` asserts FR3 against a fixture buffer holding one entry of each kind.
- FR7 — The change lands in both `skills/queue/templates/next` and `.claude/backlog/next`.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The form is stated once and cited once, per `CONVENTIONS_CORE.md`'s context-rent rule; two skills carrying two copies is how the wording drifts again | `documentation-conventions.md` |
| Observability | The counts are reported by the tool that already reports the buffer's size, not by a new mode a session has to know to run | `observability-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given a `FINDINGS.md` holding one plain entry, one carrying the filed marker and one
  carrying the no-destination marker, when `./next --findings` runs, then it reports three entries,
  one filed and one with no destination. Red-making input: today's `next`, which reports the count
  only.
- [ ] AC2 — Given the same buffer with the no-destination marker rewritten in one of the three
  spellings now in this repo, when `./next --findings` runs, then that entry is **not** counted as
  marked. Red-making mutation: matching on the word "row" alone, which would count any entry
  mentioning one.
- [ ] AC3 — Given `skills/retro/SKILL.md` and `skills/queue/SKILL.md`, when each is searched for the
  no-destination form, then exactly one states it and the other cites it by name. Red if both state
  it, which is the drift FR1 forbids.
- [ ] AC4 — Given `skills/queue/templates/FINDINGS.md`, when its format section is read, then both
  marker forms appear beside the entry format. Red-making mutation: deleting one of the two, which
  reddens the guard asserting both.
- [ ] AC5 — Given this repo's `.claude/backlog/FINDINGS.md` after the change, when it is searched for
  each of the three legacy spellings, then none is found. Red if any entry still carries one.
- [ ] AC6 — Given both copies of `next`, when `tests/backlog-scripts-installed.test.sh` runs, then it
  reports `0 failed`.

## QA plan

- **Why that level:** FR3, FR6 and FR7 are a script change with an existing suite; the prose FRs are
  covered by the greps AC3 and AC4 name and run in the same pass.
- **Specific checks:** `tests/next.test.sh` and `tests/backlog-scripts-installed.test.sh`
  individually, then the whole suite file-by-file. AC2 is the falsifying one — build the fixture with
  a near-miss spelling, not only with the canonical form.

## Out of scope

- What the counts should *gate*. `0060` is the open decision on how the buffer is emptied and gated,
  and this item supplies the number that decision will want without pre-empting it.
- Removing an entry's lesson half independently of its work half — that is `0080`.
- Raising or lowering `findings_threshold`. `config.yml` records why it sits where it does.

## Notes & decisions

- Routed to `develop`: the two markers already exist and one already has a form. Making the second
  match it, and counting both, is mechanical.
- FR5 exists because this item's own evidence is the three spellings in the live buffer; leaving them
  would make AC1's guard true and the file it guards still unreadable.

### From `FINDINGS.md`, landed 2026-09-05

- **The marker vocabulary this item specifies was superseded on 2026-09-05; re-read FR1 before
  building it.** `retro` Step 4 now defines **four terminal dispositions** — landed, absorbed, filed,
  dropped — and requires that every entry a pass reads leaves the buffer in all four; `queue` Step 5's
  marker was rewritten to hand an entry over rather than park it (`b9a5ee0`). So FR1's *"one canonical
  form for each marker"* is now four dispositions plus the deferral rather than two markers, FR3's
  `./next --findings` counts should follow that same set, and FR5's *"three spellings already in this
  repo's `FINDINGS.md`"* is stale — the sweep of 2026-09-05 drained the file. **The problem this item
  exists for is unchanged and still unbuilt**: the forms are prose, nothing counts them, and the count
  of each is what says whether retros are keeping up.
- **The outcome that was actually missing was *absorbed*** — an existing row already carries the whole
  lesson, so nothing new is written but the row is named and appended to. Without it, eight entries
  marked *"kept for the lesson"* sat through two sweeps because neither sweeper could finish them.
