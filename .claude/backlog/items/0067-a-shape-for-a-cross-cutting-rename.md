---
id: "0067"
title: Decide what shape a cross-cutting rename takes in the backlog
type: chore
next: design
status: ready
qa_level: unit
size: m
created: 2026-08-25
source: agent
parent:
blocked_by: []
relates: ["0001", "0005", "0050"]
expects:
  - references/CONCURRENCY.md
  - references/CONCURRENCY-INCIDENTS.md
  - skills/queue/SKILL.md
claimed_by:
claimed_at:
touches:
---

## Problem

A vocabulary rename has no shape the backlog can hold. Renaming the container ticket type
effort → project touched 27 files across `QUEUE.md`, the item template, two skills, three test
suites and 21 closed tickets. No `touches:` list can usefully declare that, no single ticket owns
it, and `claim` protects one row at a time — so a cross-cutting rename is **invisible to every
concurrency mechanism the repo has**. That is how it reddened `0005`'s held guard mid-pass: the
rename rewrote a file 0005 had committed in `touches:`, turning a held ticket's own guard red
against a contract the ticket never agreed to.

The same event produced the audit-trail defect recorded separately: the rename's commits were
tagged with another ticket's live claim token, and swept 41 lines of that ticket's uncommitted notes
into their own message.

This is not the ordinary file-scope collision. A collision is two tickets wanting one file; a rename
is one change wanting *every* file, including files belonging to tickets that are closed and to
tickets that are held. The mechanisms this repo has — `expects:`, `touches:`, the lock, the claim
token — are all per-row, and a rename has no row.

## Open design question

- **Question:** What shape does a repo-wide vocabulary change take? The candidates named when this
  was found were: **its own convention** — announce it, land it in one commit, re-run the whole
  suite — which makes the rename a declared event other sessions can see; or **a scheduling rule** —
  vocabulary changes only when nothing is claimed — which makes it impossible to collide by
  construction and costs whatever wait that implies. A third is that it is a **project**, in this
  repo's own sense, with a slice per affected area and the coupling recorded in the parent — which
  would use machinery that already exists rather than adding any.
- **Why it blocks specification:** the acceptance criteria are incompatible. A convention is prose
  plus possibly a checklist. A scheduling rule needs a definition of "nothing is claimed" and
  something that can check it — `./next` already knows. A project needs the conversion machinery
  0057 is adding and a statement of how slices that each touch everything avoid the very collision
  the rename causes. And there is a prior question the answer turns on: whether a rename is allowed
  to touch **closed** tickets' files at all, since 21 of the 27 were closed and rewriting them
  changes the record of what was verified.
- **Settle it with:** `/design` — the inputs are the incident, the concurrency mechanisms and what
  `./next` can already see. Nothing needs to be seen.

## Functional requirements

Written after the design question is settled. What is fixed regardless:

- FR1 — `references/CONCURRENCY.md` states that a change touching every file is outside what
  `expects:`, `touches:` and the per-row lock can express, since today the mechanisms read as though
  they cover everything.
- FR2 — Whatever shape is chosen, the rule names what a session does when it *discovers* a
  cross-cutting change is underway — the case 0005 was in, where a held ticket's guard reddened for
  a reason nothing in its own scope explained.
- FR3 — The rule states whether a rename may rewrite closed tickets' files, and if so what that
  means for the record of what was verified.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Migration / schema | A vocabulary rename across 21 closed tickets is a rewrite of historical records; whether that is additive-first or forward-only is part of what FR3 must settle | `migration-conventions.md` |
| Documentation | The rule lands in the concurrency reference and the narrative in `CONCURRENCY-INCIDENTS.md`, per the split 0020 made | `documentation-conventions.md` |

## Acceptance criteria

Cannot be written until the design question is settled. These hold regardless:

- [ ] AC1 — Given `references/CONCURRENCY.md`, when read, then it states that a change touching
  every file is not expressible in `expects:`, `touches:` or the per-row lock.
- [ ] AC2 — Given the settled rule, when read, then it says what a session does on discovering a
  cross-cutting change underway.
- [ ] AC3 — Given the settled rule, when read, then it answers whether closed tickets' files are
  rewritten.

## QA plan

- **Level:** unit — provisional, argued across the candidates: a scheduling rule that `./next` can
  check is `unit`, a convention or project answer is `verify` with a named scripted assertion, and
  this project's `unit` command runs every `tests/*.test.sh`, so `unit` subsumes both.
- **Why this level:** the level is the same across every candidate shape.
- **Specific checks:** settled by the design pass.

## Out of scope

- **The token reuse and the swept notes from the same incident.** That is 0049; the two findings
  came from one event and have different root causes.
- **Ordinary file-scope collisions**, which are 0050.
- Performing any rename.

## Notes & decisions

- Routed to `design` on trigger 1: three candidate shapes with incompatible criteria, plus a prior
  question — whether closed tickets are rewritten — that has to be answered before any of them can
  be specified.
- Ranked in Tier 2 rather than Tier 5 despite no rename being planned. The mechanisms read as
  complete, which is what makes the gap dangerous: the next cross-cutting change will be started by
  a session that has checked `expects:` against `touches:` and concluded it is safe.
