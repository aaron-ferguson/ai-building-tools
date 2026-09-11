---
id: "0107"
title: Require an NFR row to name how it would red
type: feature
next: develop
status: in-progress
qa_level: unit
qa_manual:
size: m
created: 2026-09-07
source: agent
parent:
blocked_by: []
relates: ["0052"]
expects:
  - skills/queue/templates/item.md   # the NFR table
  - skills/queue/SKILL.md            # the step that fills it
  - skills/verify/SKILL.md           # Step 4's always-on convention pass
  - tests/falsifiable-acs.test.sh    # the AC analogue, and the likely home
claimed_by: "6a08"
claimed_at: 2026-09-11T02:58:48Z
touches:
  - skills/queue/templates/item.md   # the NFR table
  - skills/queue/SKILL.md            # the step that fills it
  - skills/verify/SKILL.md           # Step 4's always-on convention pass
  - tests/falsifiable-acs.test.sh    # the AC analogue, and the likely home
---
## Problem

`0052` shipped `tests/falsifiable-acs.test.sh` so the lifecycle asks whether an *acceptance
criterion* can be made to fail. **Nothing asks it of an NFR row**, and no template step requires a
row to name the check that would red it.

Measured across all six NFR rows of `0039` on the pass that closed it:

- **Observability had no guard of any kind.** Deleting Step 5's whole *"One JSON line per event …
  each with a UTC timestamp and the run id"* rule — the requirement verbatim — left the suite at
  105 passed, 0 failed. So did deleting the UTC-timestamp conjunct on its own.
- **Security was half-guarded.** AC8 and AC19 pin the no-push rule and the dispatch flags, but
  *"Authority is the narrowest that works, and it does not outlive the process"* was green when
  deleted.
- **The other four red only because an AC coincidentally covered the same ground** — AC13 for
  Performance, AC24 for Documentation, the suite for Compatibility, and Dependencies only after a
  third re-entry wrote a guard against the row itself.

So the pattern is: **an NFR row is guarded exactly when an AC happens to cover it.** On this ticket
that was four rows of six, and the two left unpinned were the ones whose subject is a runtime
artifact nothing yet produces.

The cost is measurable. `0039`'s Dependencies row asked two things — name the `claude` CLI
dependency, say what happens without it. The naming half was unmet, flagged ⚠️ on 2026-09-06,
carried, then failed ❌ on 2026-09-07. The whole gap was one line of README the entire time, and it
cost two QA passes because an unfalsifiable row is caught only by whichever pass happens to read it
carefully.

**The honest limit, which shapes the fix.** A guard for Observability here would have to assert
*prose*, because no run log exists to assert a format against. That argues the fix is a declared
check at queue time rather than a test per row — the same shape `0052` chose for ACs.

## Functional requirements

- **FR1** — An NFR row states how it would red: the check, mutation or observation that would fail
  if the requirement were not met. A row that cannot name one is not a commitment and does not ship.
- **FR2** — `queue`'s step that fills the NFR table requires FR1 and says why, citing the
  measurement above rather than restating it.
- **FR3** — `verify` Step 4's always-on pass asks the falsifiability question of the **table**, not
  only of the acceptance criteria.
- **FR4** — Where the honest answer is "prose, because the artifact does not exist yet", the row may
  say so explicitly. That is a different state from an unanswered row and must be distinguishable.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The template's NFR preamble states the requirement where the table is filled, not elsewhere | `documentation-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given the item template's NFR table, when read, then each row has a place to name how it
  would red, and the preamble requires it.
- [ ] AC2 — Given `queue`'s NFR step, when read, then it states that a row with no nameable check
  does not ship.
- [ ] AC3 — Given `verify` Step 4, when read, then it asks the falsifiability question of the NFR
  table explicitly, not only of the ACs.
- [ ] AC4 — Given a row whose honest check is prose because the artifact does not exist, when
  written in the permitted form, then it is distinguishable from an unanswered row.
- [ ] AC5 — Deleting the requirement from `queue`'s NFR step turns a guard red.
- [ ] AC6 — Deleting the NFR clause from `verify` Step 4 turns a guard red, scoped to that step and
  not satisfied by the word appearing elsewhere in the file.

## QA plan

- **Level:** unit — this repo's whole suite.
- **Why this level:** the deliverable is prose in two skills and a template; every guard here greps
  prose.
- **Specific checks:** extend `tests/falsifiable-acs.test.sh`, which already scopes each case to the
  *step* rather than the file for exactly this reason. Take the window between the step's named
  opening phrase and the next heading. **Count the asserted phrase inside that window**, not over
  the file — a file-level count answers a different question, and a phrase occurring twice inside
  the extracted section is as unfalsifiable as one occurring twice in the file
  (`testing-conventions.md`). Prove each case reds by deleting the sentence it matches.

## Out of scope

- Writing guards for `0039`'s two unpinned rows. That ticket is closed; this one changes what the
  next ticket is required to do.
- A per-row automated test. The Observability case above is the argument against it.

## Notes & decisions

- 2026-09-07 — Filed by `retro` from two `FINDINGS.md` entries, the second of which measured the
  first across all six of `0039`'s rows and turned "one carelessly-written row" into a pattern.
  `relates: 0052` because that ticket is the AC analogue and its test file is the likely home.

- **2026-09-09 (retro, from `FINDINGS.md`)** — Measured again on `0075`, and this time the gap is in
  `verify` rather than only in the template. `0075`'s Git NFR — read-only, "no automatic pull, merge
  or rebase" — is **unguarded in both skills it was delivered in**, and the whole suite stays green
  when it is broken: replacing `` `git fetch` then `git status -sb`, read-only `` with
  `` `git fetch` then `git pull --rebase` `` in `skills/develop/SKILL.md`, and the equivalent line in
  `skills/retro/SKILL.md`, left all 26 test files at 0 failed in both cases.
  `tests/remote-anchor.test.sh` asserts `the pull is the user` on retro's *other* line, so the
  sentence carrying the actual command is free to instruct a rebase while the paragraph beside it
  still says the pull is the user's call. The ticket's four ACs were all met and none of them is this
  one — an NFR row is a requirement no AC restates. **The addition to this ticket's scope**: nothing
  in `verify` Step 4 asks whether a checked NFR is *guarded* as opposed to merely true today, so a
  template requirement that a row name how it would red is only half the fix if the checking stage
  never asks for it.
