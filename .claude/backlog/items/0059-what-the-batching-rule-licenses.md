---
id: "0059"
title: Decide what the batching rule actually licenses
type: chore
next: design
status: ready
qa_level: unit
size: m
created: 2026-08-25
source: agent
parent:
blocked_by: []
relates: ["0025", "0026", "0050", "0058"]
expects:
  - skills/verify/SKILL.md
  - skills/develop/SKILL.md
  - tests/batching.test.sh
claimed_by:
claimed_at:
touches:
---

## Problem

The batching rule says tickets that **share a file scope or a parent slice** are checked in one
session, justified by the conventions, the skill and the suite's startup being "a shared cost paid
once however many verdicts come out of it". The stated condition and the stated reason point in
opposite directions, and nothing reconciles them.

**The rationale argues for the largest batch available.** What is amortised is startup, paid once
whatever the batch size — so on its own reasoning, two rows sharing nothing should still be taken
together. 0034 (`skills/verify/SKILL.md`, `references/CONCURRENCY.md`) and 0035 (`tests/*.test.sh`)
share neither scope nor parent, and a session reading the condition literally splits them across
two sessions to no benefit. They were taken as one gate and each closed on its own ACs.

**The condition, meanwhile, cannot be checked set-wide, because overlap chains.** One session took
all five `next: verify` rows in a single pass — licensed by `verify`'s own "one gate per session,
not one ticket per session". Checked against the stated condition, by declared `touches:` **no two
of the five share a parent** (only 0026 has one at all), and by exact file the batch is a *chain*
rather than a set: 0032–0026 via `skills/develop/SKILL.md`, 0026–0029 via `skills/verify/SKILL.md`,
0029–0033 via `references/CONCURRENCY.md`, and 0031 attached only at directory level, sharing no
file with any of them. 0026 and 0033 share nothing; 0026 and 0031 share nothing. So the constraint
is satisfied pairwise and transitively but never set-wide — and because overlap chains, any starting
row reaches the entire stage. `./next <stage>` selects by stage regardless, so the only
row-selection tool does not implement the condition at all.

**And the rule does not name its own hazard: Step 3.** Verifying an AC requires deliberately
breaking the check behind it to prove it can red. In a batch those mutations land in the working
tree the other tickets' passes share, with no ordering or isolation rule given — so a suite run for
ticket B while ticket A's mutation is live reads as B's red. 0026's notes already record the
*inter*-session form of exactly this ("a full-suite run taken while another window is mid-edit is a
verdict about a tree that never existed as a commit") and settle on a throwaway worktree; a batch
reproduces it *intra*-session, where there is no other window and that note does not reach.

## Open design question

- **Question:** What is the batching rule's condition? Three shapes: **the gate itself** — any rows
  at `next: verify` are one session, with scope-sharing merely the common case; **the stated
  condition, made checkable** — a definition of what "shares a file scope" means for a set rather
  than a pair, implemented by `./next` so the tool and the rule agree; or **the condition is
  advisory** and the real limit is something else, such as how many verdicts one session can hold
  without the evidence going stale. And separately: what isolates one ticket's Step 3 mutation from
  another ticket's suite run inside the same session?
- **Why it blocks specification:** the acceptance criteria are incompatible between them. "Any rows
  at the stage" is prose plus a change to `./next`'s selection. "Checkable set-wide" is an algorithm
  — and a chaining one, so it needs a definition before it can be asserted. "Advisory" is a rewrite
  of the rationale. The mutation-isolation half may be a worktree per ticket, an ordering rule, or a
  statement that batched tickets are verified one at a time with the tree clean between — and which
  one determines whether this is a prose change or a tooling change.
- **Settle it with:** `/design` — the inputs are the rule, its rationale, the observed batch and how
  `./next` selects. Nothing needs to be seen.

## Functional requirements

Written after the design question is settled. What is fixed regardless:

- FR1 — The batching statement's condition and its rationale agree, in both `skills/verify/SKILL.md`
  and `skills/develop/SKILL.md`, whichever way the answer goes.
- FR2 — The rule names the intra-session Step 3 mutation hazard and states what isolates it.
- FR3 — `tests/batching.test.sh` asserts the settled condition rather than the current wording, and
  its assertions are anchored to the claim rather than to the paragraph containing it.

## Non-functional requirements

| Dimension | Requirement for this item | Convention |
|---|---|---|
| Documentation | Both skills carry the statement today and `tests/batching.test.sh` asserts on both, so the decision lands in both or the guard reds | `documentation-conventions.md` |
| Progressive delivery | Both skills ship to every machine installing the plugin | `progressive-delivery-conventions.md` |

## Acceptance criteria

Cannot be written until the design question is settled. These hold regardless:

- [ ] AC1 — Given the batching statement in both skills, when read, then the condition it states and
  the reason it gives do not license different batch sizes.
- [ ] AC2 — Given the batching statement, when read, then it names what isolates one ticket's Step 3
  mutation from another ticket's run in the same session.
- [ ] AC3 — Given `tests/batching.test.sh`, when it runs, then it passes against the settled
  wording.

## QA plan

- **Level:** unit — provisional, argued across the candidate shapes: a prose answer is `verify` with
  a named scripted assertion and a `./next` answer is `unit`, and this project's `unit` command runs
  every `tests/*.test.sh`, so `unit` subsumes both.
- **Why this level:** the level is the same across every candidate.
- **Specific checks:** settled by the design pass. `tests/batching.test.sh` runs in every case, and
  0042 is repairing its AC4 assertion — coordinate rather than duplicate.

## Out of scope

- **Whether the stage stalls when rows collide.** That is 0050. This ticket is about a rule that
  deliberately takes several rows at once; that one is about rows that cannot be taken at all.
- `./next`'s take-loop selection against held files, which is 0045.
- Changing the "one skill per session" rule the batching rule sits inside.

## Notes & decisions

- Routed to `design` on trigger 1: the three shapes have incompatible acceptance criteria, and the
  chaining property means "make the condition checkable" is not a small implementation detail — it
  needs a definition first.
- Note the asymmetry worth carrying into the design pass: `develop` Step 1 *does* write down the
  every-row-collides outcome, and `verify` Step 1 does not. Whatever is decided here, the two
  skills' statements are asserted by one test file and must move together.
