---
id: "0048"
title: Decide which remaining backlog write sites become scripts
type: chore
next: design
status: ready
qa_level: unit
size: l
created: 2026-08-25
source: agent
parent:
blocked_by: []
relates: ["0023", "0027", "0044"]
expects:
  - skills/queue/templates/
  - skills/queue/SKILL.md
  - skills/design/SKILL.md
  - skills/develop/SKILL.md
  - references/CONCURRENCY.md
claimed_by:
claimed_at:
touches:
---

## Problem

`CONCURRENCY.md`'s argument for why claiming and closing are scripts is "a script cannot forget".
Two backlog writes are still by hand, and both have already half-applied.

**The stage handoff.** `./claim` takes a row and `./close` finishes one; the handoff — set `next:`,
set `status:`, clear `claimed_by:`/`claimed_at:`, edit the row, commit, release — is written out
by hand in `design` Step 4 and `develop` Step 5 both. It mutates **four fields across two files**,
twice as many as either existing script. Settling 0036 it half-applied: the `QUEUE.md` row reached
`develop | ready` while the item frontmatter still read `design | in-progress`, with the lock
already released, so for a moment the row and its item disagreed and nobody held either. The
proximate cause was a second defect that a script would not have had — `./claim` writes
`claimed_by: "09e4"` quoted while the template shows it bare, so an edit anchored on the unquoted
spelling matched nothing, and a find-and-replace matching zero times looks identical to one already
in the desired state.

**`queue`'s row insert.** Step 3 inserts a row into `QUEUE.md` with a bare `Edit`. `CONCURRENCY.md`
requires the lock for "every write, no exemptions" and names only three write sites, none of them a
capture-time insert — so the skill and the reference disagree, and a reader following the skill
alone inserts unlocked. It is also the one `QUEUE.md` operation with no script and no candidate.

The narrower version of this problem is already solved: `CONCURRENCY-INCIDENTS.md` now documents
that a by-hand lock must be one tool call from `mkdir` to `git commit`, or the trap releases it in
between, and it names the case where dropping the trap is right instead. What is unresolved is
whether these two sites should be by hand at all.

## Open design question

- **Question:** Which of the two remaining by-hand `QUEUE.md` write sites — the stage handoff and
  `queue`'s row insert — becomes a script, and what is that script's contract? The candidate shapes
  are a fourth script (`./handoff <id> <token> <stage>`), a mode on an existing script (`./close
  --to <stage>`, `./claim --insert`), or neither, with the skills instead carrying a mandatory
  one-tool-call form. They are not obviously the same answer for both sites: the handoff has a
  token and a holder, the insert has neither and happens before the ticket exists in the table.
- **Why it blocks specification:** no acceptance criterion can be written until the shape is
  chosen. "The handoff sets four fields atomically" is an AC about a script; "the skill states the
  locked one-call form" is an AC about prose; and whether `queue`'s insert takes the lock at all is
  the open disagreement between `skills/queue/SKILL.md` Step 3 and `CONCURRENCY.md` — one of the
  two is wrong and it is not obvious which. `Edit`'s fail-on-mismatch may be the intended
  substitute for the lock on a single row, in which case it is *CONCURRENCY.md*'s "no exemptions"
  that needs the caveat, not the skill.
- **Settle it with:** `/design` — every input is a rule in a file, and the decision is which rule
  governs. Nothing here needs to be seen.

## Functional requirements

Written after the design question is settled. What is fixed regardless:

- FR1 — `skills/queue/SKILL.md` Step 3 and `references/CONCURRENCY.md` *Lock every write to
  `QUEUE.md`* agree about whether a capture-time row insert takes the lock, whichever way the
  answer goes.
- FR2 — Whatever performs the handoff sets `next:`, `status:`, `claimed_by:` and `claimed_at:` in
  the item and the row in `QUEUE.md` such that the two cannot be left disagreeing.
- FR3 — Wherever `claimed_by:` is written and wherever it is matched, one quoting form is used, so
  an anchored edit cannot silently match zero times.
- FR4 — If the answer adds a script, `references/CONCURRENCY.md` *The three scripts* is renamed and
  restated for the new count, and `tests/backlog-scripts-installed.test.sh` covers the new file.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The decision and its reasoning are recorded in *Notes & decisions* by the design pass, since the next reader's question will be why the two sites were answered the way they were | `documentation-conventions.md` |
| Progressive delivery | Other machines install this plugin. A new or renamed script reaches them only through the version bump and the install, so the skills must not require a script an installed copy does not have | `progressive-delivery-conventions.md` |

## Acceptance criteria

Cannot be written until the design question is settled — that is what makes this `next: design`
rather than `next: develop`. AC1 is fixed regardless:

- [ ] AC1 — Given `skills/queue/SKILL.md` Step 3 and `references/CONCURRENCY.md`, when both are
  read, then they state the same answer about whether a capture-time row insert takes the lock.

## QA plan

- **Level:** unit — provisional, and argued from what the candidate placements share rather than
  from a known deliverable. A script answer is plainly `unit`; a prose answer would be `verify`
  with a named scripted assertion, and this project's `unit` command runs **every**
  `tests/*.test.sh`, so `unit` subsumes it either way. Where a design ticket's candidates straddled
  levels in the other direction this argument would not be available.
- **Why this level:** the level is the same across all three candidate shapes, so it can be set
  now rather than deferred.
- **Specific checks:** settled by the design pass, which adds them alongside the FRs and ACs.

## Out of scope

- Changing what `./claim` or `./close` already do. 0044 owns `close`'s read and write contract.
- The busy-lock close-time path — that is 0047.
- `./claim --help` and `./close --help` answering `no row for --help in QUEUE.md`.

## Notes & decisions

- Routed to `design` on trigger 1: a decision blocks writing acceptance criteria. There is no
  surface here and no one will look at anything, so trigger 2 does not apply.
- The general rule this repo keeps rediscovering — that a multi-field, multi-file mutation wants a
  script — is not in question. What is in question is the scope and the shape, and guessing those
  to avoid the stage is how a ticket gets built to a contract nobody agreed to.
