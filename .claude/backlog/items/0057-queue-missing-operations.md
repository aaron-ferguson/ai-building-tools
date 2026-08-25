---
id: "0057"
title: Add the queue operations that exist in practice and not in the skill
type: bug
next: develop
status: ready
qa_level: verify
size: l
created: 2026-08-25
source: agent
parent:
blocked_by: []
relates: ["0002", "0009", "0026", "0036", "0037", "0041", "0052"]
expects:
  - skills/queue/SKILL.md
  - skills/queue/templates/item.md
  - tests/citations.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

`queue`'s Step 1 table routes four operations. Three of the things sessions actually do are not
among them, and each was composed by hand from precedent.

**Splitting a ticket has no procedure, and it is neither of the two no-new-ID cases.** Step 1 offers
*re-specify* (a bounce-back at `next: queue`, keeps its rank, skips Step 3) and *amend* (a new FR on
an unclaimed ticket, re-check size/ACs/scope). Narrowing a ticket and moving the removed scope to a
new one is **both at once**: an amend on the original with no ID claim and its rank kept, plus a
full Step 2 + Step 3 Add for the remainder — and the two halves have opposite rules about the ID
claim and the rank. Composed by hand for 0026 → 0037; the risk in getting it wrong is re-ranking
the original, which is exactly what both existing cases are careful not to do.

**Turning a task into a project has no step and no template, and it is one of the four things Step 1
routes here.** `templates/item.md` describes a project only as a clause inside the `status:` comment.
There is no template for the Outcome / Why / Slices / Cross-cutting-commitments shape, no statement
that the FRs and ACs **move** rather than copy, and no statement that the parent's row leaves
`QUEUE.md`. All of it was reconstructed from 0009 and 0002 when slicing 0036. `develop` and `verify`
both refuse a project by stage, and 0036's own FR8 table routes "ticket becomes a project; row
leaves `QUEUE.md`" as a real transition — so the shape is load-bearing in three places and specified
in none. The two facts a reconstruction is most likely to get wrong are **move, do not copy** and
**do not renumber**.

**A `design` ticket has no answer for `qa_level`.** The skill is emphatic that the level is chosen
"at queue time, not at develop time" — it calls it the decision that stops QA rigour quietly sliding
— and equally emphatic that design tickets are ranked normally. It never says what a design ticket
does about the field, and the template offers no way to mark it provisional. Capturing 0041, the
open question was *skill, `retro` mode, `orchestrate` step, or `tools/` script*, and those do not
share a level: a script is `unit` with fixtures, skill prose is `verify` with a named assertion. It
was resolved by arguing the level from what is certain **across** all four candidate placements —
which worked only because this project's `unit` command runs every `tests/*.test.sh`, so `unit`
dominated. Where candidates straddle in the other direction there is no answer at all.

**And `expects:` cannot see a coupling that lives in a test file.** `tests/backlog-scripts-installed.test.sh`
AC2 requires `.claude/backlog/{next,claim,close}` to be byte-identical to `skills/queue/templates/`.
So any ticket touching one of those three templates silently owns a second file, or the suite goes
red at Step 5 in a file the ticket never named. 0007's `expects:` named both templates and neither
copy; 0029's named `skills/queue/templates/close` and not the copy. Only a session that happens to
read that suite before claiming learns this, and `queue` has no reason to open it at capture time.

## Functional requirements

- FR1 — Step 1's table gains **split** as its own operation, stating that it is an amend on the
  original (no ID claim, rank kept, ACs and scope re-checked) plus a full Add for the remainder.
- FR2 — The split procedure states explicitly that the original is **not** re-ranked, since that is
  the failure both existing no-new-ID cases are shaped to avoid.
- FR3 — Step 1's table gains **task becomes a project** as its own operation, and `queue` carries a
  template for the project shape — outcome, why, slices, cross-cutting commitments.
- FR4 — That operation states that the FRs and ACs **move** to the slices rather than being copied,
  that IDs are not renumbered, and that the parent's row leaves `QUEUE.md`.
- FR5 — Step 2's `qa_level` instruction states what a `next: design` ticket does: set the level its
  candidate placements share, or record that design must set it — and says which, so a cold session
  does not guess invisibly.
- FR6 — Where FR5's answer is "record that design must set it", `templates/item.md` provides the
  way to record it, since today the field has no provisional form.
- FR7 — Step 2's `expects:` instruction requires a ticket touching a file with a declared identity
  coupling to name both sides, and names the `skills/queue/templates/` ↔ `.claude/backlog/` case as
  the live instance.
- FR8 — Every rule added cites its convention rather than restating it, and each citation resolves
  under `tests/citations.test.sh`.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | The project template is a shipped artefact, so it is written for any project using the suite, not for this repo's instance of it | `documentation-conventions.md` |
| Progressive delivery | The skill and any new template ship to every machine installing the plugin; the release is the version bump and the install | `progressive-delivery-conventions.md` |

## Acceptance criteria

- [ ] AC1 — Given Step 1's operations table, when read, then it contains a **split** row.
- [ ] AC2 — Given the split procedure, when read, then it states the original keeps its rank and
  claims no ID.
- [ ] AC3 — Given Step 1's operations table, when read, then it contains a **task becomes a
  project** row.
- [ ] AC4 — Given that procedure, when read, then it states that FRs and ACs move rather than copy,
  that IDs are not renumbered, and that the parent's row leaves `QUEUE.md`.
- [ ] AC5 — Given the shipped templates directory, when listed, then it contains a project template
  carrying the outcome, slices and cross-cutting-commitments sections.
- [ ] AC6 — Given Step 2's `qa_level` instruction, when read, then it states what a `next: design`
  ticket does about the field.
- [ ] AC7 — Given Step 2's `expects:` instruction, when read, then it requires both sides of a
  declared identity coupling to be named, and names the templates/backlog instance.
- [ ] AC8 — Given every citation added, when `tests/citations.test.sh` runs, then each resolves.
- [ ] AC9 — Given the whole suite, when `for t in tests/*.test.sh; do "$t" || exit 1; done` runs,
  then every suite passes — including `tests/skill-size.test.sh`, with a recorded justification
  naming this ticket if `skills/queue/SKILL.md` goes over its goal.

## QA plan

- **Level:** verify — the deliverable is skill prose plus one new template, and no test runner
  applies; the scripted assertions are the scoped greps below, a path check for the template, and
  the citation and size guards.
- **Why this level:** AC5 is a path check and every other AC is a scoped grep.
- **Specific checks:** each grep **scoped to the step or table it asserts on**, matching a phrase
  short enough to sit on one source line. `tests/citations.test.sh`, `tests/skill-size.test.sh` and
  the full suite.

## Out of scope

- **Converting any existing ticket to the new project template.** 0002, 0009, 0001 and 0036 are the
  precedent the template is derived from and they stay as they are; retro-fitting them is a
  separate ticket with a real migration question.
- **Whether an AC can be falsified.** That is 0052, which also touches this file. The two are kept
  apart because their root causes are unrelated, and the collision is 0050's problem, not a reason
  to merge contracts.
- Any change to the ranking rules in Step 3.

## Notes & decisions

- Routed to `develop`: each operation's shape is reconstructable from precedent already in the repo
  (0026 → 0037 for the split, 0009 and 0002 for the project), and each finding states the two facts
  a reconstruction gets wrong. FR5 is the one that comes closest to a decision, and the finding
  proposes both acceptable answers explicitly — either is a correct close.
- FR7 is here rather than in a concurrency ticket because `expects:` is written by `queue`, at
  capture time, and that is the only moment the coupling can be predicted cheaply.
