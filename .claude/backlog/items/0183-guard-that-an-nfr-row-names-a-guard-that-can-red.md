---
id: "0183"
title: Decide what checks that an NFR row's named guard can actually red on that requirement
type: bug
next: design
status: ready
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
claimed_by:
claimed_at:
touches:
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

## Requirements for design to carry through

- **FR1** — Decide what is mechanically checkable about a *How it would red* cell (file exists;
  cell names a case or pattern, not only a file) and what stays a `verify` Step 4 judgement.
- **FR2** — Whichever is chosen, a row naming a guard unrelated to its requirement must be flagged
  rather than ticked.

## Notes & decisions

- 2026-09-23 — filed by retro (session edf44941-de11-48ca-92b8-093a50099f9b) from a FINDINGS entry
  (verify gate for 0176/0165/0163/0162/0166/0173).
