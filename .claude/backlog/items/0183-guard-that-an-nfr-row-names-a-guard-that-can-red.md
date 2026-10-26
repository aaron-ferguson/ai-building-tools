---
id: "0183"
title: Decide what checks that an NFR row's named guard can actually red on that requirement
type: bug
next: develop
status: in-progress
qa_level: unit
close_by: verify
size: s
created: 2026-09-23
source: retro
parent:
blocked_by: []
relates: ["0089", "0176"]
expects:
  - tests/falsifiable-acs.test.sh
  - skills/verify/SKILL.md
  - skills/queue/templates/item.md
ac_digest: AC1=fc5b06e3 AC2=3a779806 AC3=478021db AC4=9e64bc44 AC5=a8c2f1f5 AC6=57e2eae1 AC7=593ca365
claimed_by: "2672"
claimed_at: 2026-10-26T01:26:32Z
touches:
  - tests/falsifiable-acs.test.sh
  - skills/verify/SKILL.md
  - skills/queue/templates/item.md
---

## Problem

**An NFR row can name a guard that cannot possibly test it, and a filename that exists reads as a
discharged answer.** `0176`'s Documentation row reads *"The fallback is stated once, in Step 3, and
is not restated in the stage skills it dispatches"* with `tests/citations.test.sh` in *How it would
red*. That file resolves citation targets and has no duplication check, so no restatement in a stage
skill could red it. The requirement held at verify (`grep -rln` over `skills/` found only
`skills/sprint/SKILL.md`), so the row was true and pinned by nothing — caught only because the
verifier read the guard.

`tests/falsifiable-acs.test.sh` does this job for acceptance criteria; the NFR table has no
equivalent.

## Functional requirements

- **FR1** — A state guard, `tests/item-nfr-red.test.sh`, scans every item at `next: develop` or
  `next: verify` (subjects derived from the glob, as `tests/item-ac-form.test.sh` does; `design`,
  `queue` and done items are not scanned) and reds on any NFR row whose *Requirement* cell is filled
  and whose *How it would red* cell is either **empty** or **a bare file reference** — nothing left
  once backticked spans and punctuation are removed. Each failure names the item id and the
  dimension.
- **FR2** — A cell naming a case, an `ACn`, a mutation, an observation or `prose only — no artifact
  yet` passes FR1; whether what it names actually reds on *that* requirement stays `verify` Step 4's
  judgement, and Step 4 says so: perform the mutation **of the requirement** (not of the guard), and a
  named check that stays green is recorded as **unguarded**, never ticked — the same verdict as a row
  naming no check.
- **FR3** — `skills/queue/templates/item.md`'s NFR preamble states that a filename alone is not an
  answer: the cell names the case, criterion or mutation within it.
- **FR4** — The guard's one live hit at decision time, `0177`'s Documentation row
  (`tests/citations.test.sh` alone), is re-specified in the same change to name a check that reds on
  its requirement, or `prose only — no artifact yet`. `0177` is another item: take its claim before
  writing it, and if it is held, stop and report rather than shipping a red guard.

## Non-functional requirements

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Testing | The guard is falsifiable: it reds on a bare-file fixture and stays green on a named-case fixture, through the same matcher it applies to items | AC3 and AC4 — the fixture probes run the item matcher, so deleting the bare-file test turns AC3 red | `testing-conventions.md` |
| Documentation | The Step 4 relatedness rule and the template sentence each live once, in their own file, and are pinned by phrase | AC5 and AC6 — deleting either sentence reds its `tests/falsifiable-acs.test.sh` case | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given an item at `next: develop` whose filled NFR row's *How it would red* cell is `` `tests/citations.test.sh` `` and nothing else, when `tests/item-nfr-red.test.sh` runs, then it fails naming that item's id and the row's dimension.
- [ ] AC2 — Given an item at `next: verify` whose filled NFR row's *How it would red* cell is empty, when the guard runs, then it fails naming that item and dimension.
- [ ] AC3 — Given the guard's own fixture of a bare-file cell, when its probe runs the same matcher the item scan uses, then the matcher reports a miss; and with the bare-file check removed from the matcher, that probe fails.
- [ ] AC4 — Given cells reading `` AC8 — `tests/skill-size.test.sh` red ``, `AC1`, `prose only — no artifact yet`, and `` `tests/falsifiable-acs.test.sh`, case *AC1 — the preamble requires it* ``, when the matcher reads each, then none is reported.
- [ ] AC5 — Given `skills/verify/SKILL.md` Step 4, when `tests/falsifiable-acs.test.sh` runs, then a case scoped to Step 4's window asserts the rule that a named check which stays green under a mutation of the requirement is recorded as unguarded, and deleting that sentence reds the case.
- [ ] AC6 — Given `skills/queue/templates/item.md`'s NFR preamble, when `tests/falsifiable-acs.test.sh` runs, then a case scoped to that section asserts that a filename alone is not an answer, and deleting the sentence reds the case.
- [ ] AC7 — Given the live backlog after the change, when `tests/item-nfr-red.test.sh` runs, then it passes, `0177`'s Documentation cell names a check or `prose only — no artifact yet`, and every `tests/*.test.sh` passes.

## QA plan

`unit`. Run `tests/item-nfr-red.test.sh` and `tests/falsifiable-acs.test.sh`; perform AC3's, AC5's and
AC6's deletions and watch each red; run AC1 and AC2 against fixtures built under a temp directory
(fixture ids unmistakably not real rows), then the whole suite.

## Out of scope

- Checking that a path named in the cell exists (rejected, see below).
- Resolving a bare `ACn` reference against the item's criteria (rejected, see below).
- Rewriting done items' cells (`0174`, `0176`): they are history, and the guard does not scan them.
- Any mechanical test of relatedness — that is the judgement FR2 leaves to `verify`.

## Notes & decisions


- 2026-09-23 — filed by retro (session edf44941-de11-48ca-92b8-093a50099f9b) from a FINDINGS entry
  (verify gate for 0176/0165/0163/0162/0166/0173).
- 2026-10-25 — **design decided (session token a32e).** The row had no *Open design question*; its
  two FRs were the question: what is mechanically checkable about a *How it would red* cell, and how
  a row naming an unrelated guard gets flagged rather than ticked.
  - **Evidence, re-read today** over every item in `.claude/backlog/items/`: 51 filled NFR rows. 40
    name no file at all (an `ACn`, or a described mutation or observation); 3 are `prose only`; 0
    name a path that does not exist; **4 are file-only, and 3 of those 4 are exactly this ticket's
    defect** — `tests/citations.test.sh` standing for a no-restatement requirement on `0174`, `0176`
    and `0177`. The fourth (`0216`, "AC8 — `tests/skill-size.test.sh` red") names an AC and passes.
  - **Decided: mechanical check = non-empty, and not a bare file reference.** That shape is the whole
    observed defect class and is decidable from the cell alone. **Relatedness stays judgement** in
    `verify` Step 4, which already says to run the named check or mutation; what it lacked is that a
    named check which stays green is *unguarded*, the same verdict as no check.
  - **Rejected: path exists.** 0 of 51 failed it, and an item at `next: develop` legitimately names a
    test file its build creates, so it would red on correct tickets.
  - **Rejected: `ACn` resolves to the item's own criteria.** 0 dangling among the 14 open-item AC
    references; a renumbering is already refused by `ac_digest` at `close` (0195); and the obvious
    regex misreads cross-item references (`0148` cites "`0143`'s AC6").
  - **Rejected: a relatedness heuristic** (e.g. the cell must share a word with the requirement): it
    passes `0176`'s row as easily as it fails a good one, and becomes a vocabulary pin.
  - **Trade-off accepted:** a cell naming a real case that does not touch the requirement still passes
    the guard, so FR2's teeth are the verify pass, not the script. The guard removes the one shape that
    *reads* as discharged without saying anything.
  - **Scope floor**, as `tests/item-ac-form.test.sh`: `develop` and `verify` only. The one live hit
    is `0177` (FR4).
  - **Criteria accounting:** the row arrived with no ACs; FR1/FR2 are kept and sharpened, FR3/FR4 and
    AC1–AC7 added. `qa_level: unit` and `close_by: verify` re-read against them and kept. `verify`
    Step 4 already sits near `tests/skill-size.test.sh`'s budget — develop should read that first.
