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
relates: ["0023", "0027", "0044", "0081", "0085"]
expects:
  - skills/queue/templates/
  - skills/queue/SKILL.md
  - skills/design/SKILL.md
  - skills/develop/SKILL.md
  - references/CONCURRENCY.md
  - .claude/backlog/RANKING.md
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
between, and it names the case where dropping the trap is right instead.

**The stage handoff is no longer open here.** `0081` gives it a fourth script,
`./handoff <id> <token>`, with its own incidents behind it (AetherWorks items 0087 and 0051) —
settling FR2 below by superseding it. What is left is the row insert, which turns out to have a
sibling write this Problem section did not originally name: Step 3 also writes the placement
reasoning into `RANKING.md`, by hand, in the same turn, whenever the new row displaces existing
rows — the same "no exemptions" question applies to it. What is unresolved is whether this one
site — the row insert and the `RANKING.md` write beside it — should be by hand at all.

## Open design question

- **Question:** Whether `queue`'s row insert — and the `RANKING.md` placement-reasoning write Step
  3 makes beside it — becomes a script, and what that script's contract is. The candidate shapes
  are a script (a mode on an existing one, such as `./claim --insert`, or a new one), or neither,
  with the skill instead carrying a mandatory one-tool-call form covering both files. (The stage
  handoff, the other site this question originally covered, is settled: `0081` gives it a fourth
  script, `./handoff <id> <token>`, so it is no longer part of this decision.)
- **Why it blocks specification:** no acceptance criterion can be written until the shape is
  chosen. "The insert writes both files atomically" is an AC about a script; "the skill states the
  locked one-call form" is an AC about prose; and whether `queue`'s insert takes the lock at all is
  the open disagreement between `skills/queue/SKILL.md` Step 3 and `CONCURRENCY.md` — one of the
  two is wrong and it is not obvious which. `Edit`'s fail-on-mismatch may be the intended
  substitute for the lock on a single row, in which case it is *CONCURRENCY.md*'s "no exemptions"
  that needs the caveat, not the skill. Whether the `RANKING.md` write shares that same lock turn
  or needs its own is part of the same question, since today it is unlocked by the same skill step
  that inserts the row.
- **Settle it with:** `/design` — every input is a rule in a file, and the decision is which rule
  governs. Nothing here needs to be seen.

## Functional requirements

Written after the design question is settled. What is fixed regardless:

- FR1 — `skills/queue/SKILL.md` Step 3 and `references/CONCURRENCY.md` *Lock every write to
  `QUEUE.md`* agree about whether a capture-time row insert takes the lock, whichever way the
  answer goes.
- FR2 — Whatever performs the insert writes the `QUEUE.md` row and, whenever Step 3 also records
  placement reasoning, the `RANKING.md` entry such that the two cannot be left disagreeing about
  what was decided and why. *(Renumbered from the former FR2, which was the stage handoff — that
  is now `0081`'s, see Out of scope.)*
- FR3 — Wherever `claimed_by:` is written and wherever it is matched, one quoting form is used, so
  an anchored edit cannot silently match zero times.
- FR4 — If the answer adds a script, `references/CONCURRENCY.md` *The three scripts* is renamed and
  restated for the new count, and `tests/backlog-scripts-installed.test.sh` covers the new file.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The decision and its reasoning are recorded in *Notes & decisions* by the design pass, since the next reader's question will be why the row insert and its `RANKING.md` write were answered the way they were | `documentation-conventions.md` |
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
- **The stage handoff.** Originally one of this ticket's two open sites; `0081` now specifies it in
  full (`./handoff <id> <token>`, refuses on a status mismatch, releases as the stage's final act).
  This ticket does not re-decide it.

## Notes & decisions

- Routed to `design` on trigger 1: a decision blocks writing acceptance criteria. There is no
  surface here and no one will look at anything, so trigger 2 does not apply.
- The general rule this repo keeps rediscovering — that a multi-field, multi-file mutation wants a
  script — is not in question. What is in question is the scope and the shape, and guessing those
  to avoid the stage is how a ticket gets built to a contract nobody agreed to.
- **Narrowed 2026-09-01 by `0085`'s queue pass.** `0081` settled the stage-handoff half
  independently (a fourth script, `./handoff <id> <token>`), so the former FR2 is retired to Out of
  scope and the open design question now covers only `queue`'s row insert — widened, not narrowed,
  in one respect: it now explicitly includes the `RANKING.md` placement-reasoning write Step 3
  makes beside the row insert, which this ticket's Problem section had not named before.
- **FR3 re-checked and kept as-is.** It is not tied to either open-question branch — the
  quoting-consistency defect it names is in `./claim` itself, independent of which site this ticket
  decides on — so narrowing the question does not narrow it.
- **Size re-checked and kept at `l`.** Losing the handoff half shrinks the decision, but the
  `RANKING.md` write adds a second file to the one remaining site with the same "is it locked"
  question outstanding, so the decision is not obviously smaller than before.
