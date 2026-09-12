---
id: "0107"
title: Require an NFR row to name how it would red
type: feature
next: verify
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
claimed_by: "7d2d"
claimed_at: 2026-09-12T01:14:46Z
touches:
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

| Dimension | Requirement for this item | How it would red | Convention |
|---|---|---|---|
| Documentation | The template's NFR preamble states the requirement where the table is filled, not elsewhere | `tests/falsifiable-acs.test.sh`, case *AC1 — the preamble requires it*, reds when the sentence is deleted from the template's NFR window — Mutation E below, 32/2 | `documentation-conventions.md` |

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

### 2026-09-10 — Built (token 6a08)

**The rule landed as a fourth column rather than as a sentence, and that is what makes FR4
checkable.** An NFR row had two states before this — filled or deleted — and FR4 asks for a third:
answered, but with prose because no artifact exists yet to assert against. A sentence in the
preamble cannot distinguish those; a column can, because the cell is either empty (unanswered), a
named check, or the literal `prose only — no artifact yet`. This ticket's own Documentation row is
written in the new form above, which is the cheapest demonstration available and the reason the
table was not left for the next ticket to fill.

**`in_window` was the wrong instrument and this ticket did not need to be the one to find that
out — `0059` had already paid for it.** Its build notes record a line-based `present` going red on
untouched prose the moment a rewrapped paragraph split the asserted phrase across a line break, and
`batching.test.sh` grew `says`/`says_not`/`binds` in response. `falsifiable-acs.test.sh` never got
the same treatment, so every case here was one reflow away from a false red. The new `says()` in
this file matches on the window flattened to one logical line, which is the same answer arrived at
independently; the two files now have parallel matchers and neither knows about the other.
**Worth noting for whoever unifies them:** `says()` additionally *counts*, which `batching.test.sh`
does not, because this ticket's QA plan asked for the count explicitly.

**The count is not decoration — it is the half of the QA plan that has teeth.** The plan warned
that a phrase occurring twice inside the extracted section is as unfalsifiable as one occurring
twice in the file. That is not hypothetical here: `verify` Step 4 already contains
*gap in the ticket*, which was the natural phrase for the new unguarded-row clause. Asserting it
would have produced a case that stayed green when the new clause was deleted, because the old
sentence keeps the phrase alive inside the same window. The clause is worded
*flag the row as unguarded* for that reason, and `says()` would have reddened the collision rather
than shipping it silently.

**AC6's two halves need two different mutations, and only the second one tests the claim.** Deleting
the clause from Step 4 reds the guard (3 failures) — but so would a file-wide grep, so that proves
nothing about scoping. The mutation that does is **moving** the clause into Step 5: the file still
contains `flag the row as unguarded` (`grep -c` → 1) and the guard still reds 3. That is the
difference between pinning vocabulary and pinning structure (`testing-conventions.md`, *anchor an
assertion to the claim, not to the document that contains it*).

**Mutations, all against the committed tree at `32fdd42`, each restored by path with a control run
after it** (`develop` Step 5 — `git checkout --` restores to `HEAD`, so the fix is committed before
anything is broken). Control after every restore: `34 passed, 0 failed`, `git status --porcelain`
empty.

| # | Mutation | Result |
|---|---|---|
| A | AC5 — the requirement sentence deleted from `queue`'s NFR step | `32 passed, 2 failed` |
| B | AC6 — the falsifiability clause deleted from `verify` Step 4 | `31 passed, 3 failed` |
| C | AC6 scoping — the same clause **moved** into Step 5, still present in the file | `31 passed, 3 failed` |
| D | AC1 — the template table reverted to three columns | `33 passed, 1 failed` |
| E | AC4/FR4 — the permitted prose form deleted from the template | `32 passed, 2 failed` |

**Whole suite green, 29 files, 0 failed in every tally** — baseline taken before the first edit was
identical except `falsifiable-acs.test.sh` at 17, now 34.

**Not done, and deliberately:** the existing `in_window` cases were left on the line-based matcher
rather than migrated to `says()`. Migrating them is a change to `0052`'s guarded claims with no
ticket behind it, and `0063` — *Give the prose guards a matcher that survives a rewrap* — is already
ranked for exactly that. This ticket adds the matcher that ticket will want; it does not pre-empt
its scope.

**Also not done:** the NFR tables of tickets already queued still have three columns. The template
governs what `queue` writes next, and rewriting other tickets' item files is forbidden to a stage
holding only this one (`CONCURRENCY.md`, *A stage writes only the ticket it holds*).
