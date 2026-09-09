---
id: "0117"
title: Stop the item-ID citation matcher reading file modes and clock times as citations
type: bug
next: develop
status: ready
qa_level: unit
close_by: verify
qa_manual:
size: s
created: 2026-09-09
source: retro
parent:
blocked_by: []
relates: ["0089", "0100"]
expects:
  - tests/citations.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

Two defects in the item-ID citation check `0105` shipped, both latent — the tree is green at 59
citations today, and both are one plausible edit away from firing.

**1. The matcher reads any zero-padded four-digit number in an anchored form as an item citation.**
Appending `# chmod 0644 — the mode the lock file gets.` and `# The nightly driver starts at
(0900).` to a covered file produces two `cites item …, which is in no table` failures. The
leading-zero requirement is what correctly keeps years like `(2026)` out, and it is the same rule
that lets file modes and clock times in. The bad shape is the remedy it invites: the cheapest fix
looks like rewording innocent prose rather than fixing a citation. `references/CONCURRENCY.md` is
about lock files, where `0644 —` is an entirely plausible future edit.

**2. The matcher covers `QUEUE.md` but not `DONE.md`, `FINDINGS.md` or `items/`.** Verified by
appending an unresolvable anchored citation to `items/0105-*.md` and to `FINDINGS.md`: both pass.
`0105` FR3 asked for `tests/` and got that plus `cited_files()`, so the shipped scope is within
spec — but item files are where ids are cited most, and the `QUEUE.md`-in / `DONE.md`-out seam
means **a citation stops being checked the moment its row is closed**.

## Functional requirements

- FR1 — a four-digit number that is a file mode or a clock time in an anchored form is not read as
  an item citation, and the discriminator is something other than "reword the prose".
- FR2 — the covered file set includes `items/*.md` and `DONE.md`.
- FR3 — whether `FINDINGS.md` is covered is decided explicitly and the decision recorded, given it
  is transit rather than residence and carries ids that are deliberately unresolved.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The discriminator FR1 lands on is stated in the guard's header | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — given a covered file carrying `# chmod 0644 — the mode the lock file gets.`, when the
  guard runs, then it passes; red by reverting the discriminator, which restores the failure.
- [ ] AC2 — given a covered file carrying `# The nightly driver starts at (0900).`, when the guard
  runs, then it passes; red the same way.
- [ ] AC3 — given a real unresolvable citation in the same file, when the guard runs, then it
  still fails and names the id — the control that proves AC1/AC2 narrowed rather than disabled.
- [ ] AC4 — given an unresolvable anchored citation appended to `items/0105-*.md`, when the guard
  runs, then it fails; red by removing `items/` from the covered set.
- [ ] AC5 — the same for `DONE.md`.

## QA plan

- **Why that level:** the artifact is a shell guard; every criterion is a committed assertion in
  `tests/citations.test.sh` with a mutation that provably reddens it.
- **Specific checks:** `tests/citations.test.sh`, plus the whole suite for the widened file set —
  `items/` and `DONE.md` have never been scanned and may carry live unresolvable citations, which
  is a result to publish rather than a reason to narrow FR2.

## Out of scope

`0100`'s greppable findings markers. Any change to which ids are burned or reissued.

## QA evidence  *(written by `verify`, never by `queue` or `develop`)*

## Notes & decisions

- 2026-09-09 (retro) — filed from two `FINDINGS.md` entries parked 2026-09-08 during `0105`'s
  verification. Both were verified by mutation at the time and left uncovered per `verify` Step 3
  rather than papered over. Expect FR2 to redden on existing content; that is the point.
